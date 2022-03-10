-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ar_TransferPrepayment
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ar_TransferPrepayment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.ar_TransferPrepayment.'
	Drop procedure [dbo].[ar_TransferPrepayment]
end
Print '**** Creating Stored Procedure dbo.ar_TransferPrepayment...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO
Set ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ar_TransferPrepayment		
(
	@pnUserIdentityId	int,			    		
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,	
	@pbDebug		bit		= 0,
	@pnItemEntityNo		int,		
	@pnItemTransNo		int,
	@pnDebtorNo		int,
	@pnOldCaseId		int		= null,	
	@pnLocalValue		decimal(11,2)	= null,		-- Total transfer value in local currency
	@pnForeignValue		decimal(11,2)	= null,		-- Total transfer value in foreign currency
	@pdtTransDate		datetime,			
	@psReasonCode		nvarchar(4)	= null, 
	@psPropertyType		nchar(2)	= null,
	@psPayForWip		nchar(1)	= null,
	@psTransToCases		ntext		= null		-- list of transfer cases with transfer amount
)
as
-- PROCEDURE:	ar_TransferPrepayment
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Transfer prepayments from debtor level to case level and via versa. Also item can be transferred 
--		from one case to other cases.  Transfer to different debtor is not allowed.  
--
-- MODIFICATIONS :
-- Date		Who	Change	 	Version	Description
-- -----------	----- 	-------- 	-------	----------------------------------------------- 
-- 20 Apr 2010	DL    	SQA9516 	1	Procedure created.
-- 15 Jul 2011	DL	SQA19791	2	Extend variable referencing CONTROLTOTAL.TOTAL to dec(13,2) instead of dec(11,2)
-- 4 Aug 2011	DL	SQA19884	3	Transfer items are not opened and closed properly.
-- 24 Feb 2012	DL	SQA20357	4	Invalid Journal when a prepayment with tax is transferred
-- 05 Feb 2013	DL	SQA21222	5	Prepayment Transfer incorrectly updating the postdate and postperiod of the original prepayment record.
-- 29 Oct 2013	DL	SQA21706	6	Cater for receipt that dissected into multiple debtors.
-- 20 Oct 2015  MS      R53933          7       Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

-- Transfer details 
CREATE TABLE #TRANSFERCASES (
	CASEID		int,
	TRANSFERVALUE	decimal(11,2),			-- Transfer value can be local or foreign
	LOCALVALUE	decimal(11,2),			
	FOREIGNVALUE	decimal(11,2)
	)

Declare @nTransNo		int
Declare @nErrorCode		int
Declare @TranCountStart		int
Declare @nDHCurrentHistoryLineNo	int
Declare @dtCurrentDateTime	datetime
Declare @dtCurrentDateOnly	datetime
Declare @nTransValueLocalNeg	decimal(13,2)
Declare @nTransValueLocalPos	decimal(13,2)
Declare @nTransValueForeignNeg	decimal(11,2)
Declare @nTransValueForeignPos	decimal(11,2)
Declare @nPrevLocalBalance	decimal(13,2)
Declare @nPrevForeignBalance	decimal(13,2)
Declare @nRowCount		int
Declare @nLastARNo		int
Declare @sOpenItem		nvarchar(24)	
Declare @nPostPeriod		int
Declare @nResult		int
Declare @hDoc 			int
Declare @sSql			nvarchar(4000)
Declare @nCountTransferToCases	int	
Declare @nExchRate		decimal(11,4)
Declare @sCurrency		nchar(6)

Set @nErrorCode=0

-- Get transfer to cases
If @nErrorCode = 0 and datalength(@psTransToCases) > 0 
Begin
	Exec @nErrorCode = sp_xml_preparedocument @hDoc OUTPUT, @psTransToCases

	If @nErrorCode = 0
	Begin
		Insert Into #TRANSFERCASES (CASEID, TRANSFERVALUE)
		Select temp.colnCaseId, temp.colnValueOnly
		From OPENXML( @hDoc,  '/tblCaseValue/Row', 2 )
		With	(
			colnCaseId int 'colnCaseId/text()',
			colnValueOnly decimal(11,2) 'colnValueOnly/text()'
			) temp
		where temp.colnCaseId is not null
					
		Set @nErrorCode=@@Error
	End

	Exec sp_xml_removedocument @hDoc

	if @pbDebug=1
	begin
		select * from #TRANSFERCASES
	end		
End

-- Convert transfer value to local currency
If @nErrorCode = 0
Begin
	If @pnForeignValue is null or @pnForeignValue = 0
	Begin 
		Select	@nTransValueLocalPos = ABS(@pnLocalValue), 
			@nTransValueForeignPos = null
		Select	@nTransValueLocalNeg = @nTransValueLocalPos * -1, 
			@nTransValueForeignNeg = null
	End
	else
	Begin
		Select	@nTransValueLocalPos = ABS(@pnLocalValue), 
			@nTransValueForeignPos = ABS(@pnForeignValue)
		Select	@nTransValueLocalNeg = @nTransValueLocalPos * -1, 
			@nTransValueForeignNeg = @nTransValueForeignPos * -1

		Select @sCurrency=CURRENCY, @nExchRate = ROUND(@pnForeignValue/@pnLocalValue, 4)
		from OPENITEM 
		Where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo
		and ACCTDEBTORNO = @pnDebtorNo
		Set @nErrorCode=@@Error
	End
	
	-- Convert foreign currency to local for transfer cases
	-- Also make sure values are negative as they are prepayment (credit)
	If @nErrorCode = 0 
	Begin
		Update #TRANSFERCASES
		set 
		LOCALVALUE	= case when (@sCurrency is null and @nExchRate is null) then ABS(TRANSFERVALUE) * -1 
					else ABS(ROUND(TRANSFERVALUE/@nTransValueForeignPos*@nTransValueLocalPos, 2)) * -1 end,		
		FOREIGNVALUE	= case when (@sCurrency is null and @nExchRate is null) then null
					else ABS(TRANSFERVALUE) * -1 end
		select @nErrorCode=@@Error, @nCountTransferToCases =  @@rowcount 

		if @pbDebug=1
		begin
			print '#TRANSFERCASES with VALUES POPULATED'
			select * from #TRANSFERCASES
		end
	End
End


-- Get the current date
If @nErrorCode = 0
Begin
	Select @dtCurrentDateTime = getdate(), @dtCurrentDateOnly = dbo.fn_DateOnly(getdate())
	Set @nErrorCode=@@Error
End


-- Get current debtor history line
If @nErrorCode = 0
Begin
	Select @nDHCurrentHistoryLineNo = max(HISTORYLINENO) 
	from DEBTORHISTORY
	Where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo
	and ACCTDEBTORNO = @pnDebtorNo
	
	Set @nErrorCode=@@Error
End


-- Get item posting period
If @nErrorCode = 0
Begin
	Select @nPostPeriod = dbo.fn_GetPostPeriod(@pdtTransDate, 4)  -- 4=AR
	Set @nErrorCode=@@Error
End


-- Get next TRANSNO
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'TRANSACTIONHEADER',
			@pnLastInternalCode	= @nTransNo OUTPUT	
End


BEGIN TRANSACTION

If @nErrorCode = 0
Begin
	-- Note: TRANSTYPE 533 = 'Debtors Transfer'
	Insert into TRANSACTIONHEADER (ENTITYNO, TRANSNO, TRANSDATE, TRANSTYPE, USERID,
		ENTRYDATE, TRANSTATUS, SOURCE, IDENTITYID) 
	values (@pnItemEntityNo, @nTransNo, @pdtTransDate, 533, SYSTEM_USER, 
		@dtCurrentDateTime, 0, 4, @pnUserIdentityId )
	Set @nErrorCode=@@Error
End


-- *******************************************************************************
-- * Adjust down old item
-- *******************************************************************************

-- Adjust down DEBTORHISTORY (old item)
If @nErrorCode = 0
Begin
	Insert into DEBTORHISTORY(
	ITEMENTITYNO,ITEMTRANSNO,ACCTENTITYNO,ACCTDEBTORNO,HISTORYLINENO, 
	OPENITEMNO,TRANSDATE,POSTDATE,POSTPERIOD,TRANSTYPE,MOVEMENTCLASS,
	COMMANDID,ITEMPRETAXVALUE,LOCALTAXAMT,LOCALVALUE,EXCHVARIANCE,FOREIGNTAXAMT,
	FOREIGNTRANVALUE,REFERENCETEXT,REASONCODE,REFENTITYNO,REFTRANSNO,REFSEQNO,
	REFACCTENTITYNO,REFACCTDEBTORNO,LOCALBALANCE,FOREIGNBALANCE,TOTALEXCHVARIANCE,
	FORCEDPAYOUT,CURRENCY,EXCHRATE,STATUS,ASSOCLINENO,ITEMIMPACT,LONGREFTEXT,GLMOVEMENTNO)
	select 
	ITEMENTITYNO,ITEMTRANSNO,ACCTENTITYNO,ACCTDEBTORNO,
	@nDHCurrentHistoryLineNo + 1 'HISTORYLINENO', 
	OPENITEMNO,
	@pdtTransDate 'TRANSDATE',
	null 'POSTDATE',
	null 'POSTPERIOD',
	533 'TRANSTYPE',			-- 'Debtors Transfer'
	5 'MOVEMENTCLASS',
	6 'COMMANDID',
	Case when LOCALTAXAMT is not null then ROUND(@nTransValueLocalPos - (LOCALTAXAMT/LOCALVALUE*@nTransValueLocalPos), 2) else @nTransValueLocalPos end 'ITEMPRETAXVALUE',
	Case when LOCALTAXAMT is not null then ROUND(LOCALTAXAMT/LOCALVALUE*@nTransValueLocalPos, 2) else null end 'LOCALTAXAMT',
	@nTransValueLocalPos 'LOCALVALUE',
	0 'EXCHVARIANCE',  
	Case when  (CURRENCY is not null and FOREIGNTAXAMT is not null) then 
		ROUND( (FOREIGNTAXAMT/FOREIGNTRANVALUE) * @nTransValueForeignPos, 2) else NULL end 'FOREIGNTAXAMT',
	Case when  CURRENCY is not null then @nTransValueForeignPos else NULL end 'FOREIGNTRANVALUE',
	REFERENCETEXT,
	@psReasonCode 'REASONCODE',
	REFENTITYNO,
	@nTransNo 'REFTRANSNO',
	NULL 'REFSEQNO', 
	REFACCTENTITYNO, REFACCTDEBTORNO,
	LOCALBALANCE,	-- to be recalcuated when posting
	FOREIGNBALANCE,	-- to be recalcuated when posting
	0 'TOTALEXCHVARIANCE',
	0 'FORCEDPAYOUT',
	CURRENCY,
	@nExchRate 'EXCHRATE',
	0 'STATUS',
	ASSOCLINENO,
	NULL 'ITEMIMPACT',
	LONGREFTEXT, 
	null 'GLMOVEMENTNO'
	from DEBTORHISTORY
	Where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo
		and ACCTDEBTORNO = @pnDebtorNo
		and HISTORYLINENO = 1 -- SQA20357 - Use the create row of the transaction to calculate the proportion without rounding adjusted
	Set @nErrorCode=@@Error
	
	If @pbDebug=1
	Begin
		select 'DEBTORHISTORY'
		select * from DEBTORHISTORY 
		where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo
		and ACCTDEBTORNO = @pnDebtorNo
	End
End

-- Adjust down DEBTORHISTORYCASE if transfer from a case  
If @nErrorCode = 0 and @pnOldCaseId is not null
Begin
	If @pbDebug = 1 
	Begin
		print 'Adjust down DEBTORHISTORYCASE'
	End

	Insert into DEBTORHISTORYCASE (
		ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO, CASEID,
		FOREIGNTRANVALUE, LOCALVALUE)
	Select	@pnItemEntityNo 'ITEMENTITYNO',
		@pnItemTransNo 'ITEMTRANSNO',  
		@pnItemEntityNo 'ACCTENTITYNO',
		@pnDebtorNo 'ACCTDEBTORNO', 
		@nDHCurrentHistoryLineNo + 1 'HISTORYLINENO',
		@pnOldCaseId 'CASEID', 
		@nTransValueForeignPos 'FOREIGNTRANVALUE',
		@nTransValueLocalPos  'LOCALVALUE'
	Set @nErrorCode=@@Error
End	


-- Adjust Down TAXHISTORY if tax exists
If @nErrorCode = 0 
Begin
	Insert into TAXHISTORY(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO,
				TAXCODE, TAXRATE, TAXABLEAMOUNT, TAXAMOUNT, COUNTRYCODE, REFENTITYNO, REFTRANSNO)
	(Select TH.ITEMENTITYNO, TH.ITEMTRANSNO, TH.ACCTENTITYNO, TH.ACCTDEBTORNO, 
		@nDHCurrentHistoryLineNo + 1 'HISTORYLINENO', 
		TH.TAXCODE, 
		TH.TAXRATE, 
		-- SQA20357 Invalid Journal when a prepayment with tax is transferred
		-- tax's sign is reversed the sign of transfer value.  It's NEGATIVE here.
		ROUND(abs((TH.TAXABLEAMOUNT/DH.LOCALVALUE) * @nTransValueLocalPos) * -1, 2) 'TAXABLEAMOUNT' ,
		ROUND(abs((TH.TAXAMOUNT /DH.LOCALVALUE) * @nTransValueLocalPos) * -1, 2) 'TAXAMOUNT',  
		TH.COUNTRYCODE, TH.ITEMENTITYNO, @nTransNo 		
	From TAXHISTORY TH
	join DEBTORHISTORY DH on 
				(DH.ITEMENTITYNO = TH.ITEMENTITYNO
				and DH.ITEMTRANSNO = TH.ITEMTRANSNO
				and DH.ACCTENTITYNO = TH.ACCTENTITYNO
				and DH.ACCTDEBTORNO = TH.ACCTDEBTORNO
				and DH.HISTORYLINENO = TH.HISTORYLINENO)
	where TH.ITEMENTITYNO =  @pnItemEntityNo
	and TH.ITEMTRANSNO = @pnItemTransNo
	and TH.ACCTDEBTORNO = @pnDebtorNo
	and TH.HISTORYLINENO = 1 )	-- SQA20357 - Use the first history row to retrieve the most accurate tax proportion
		
	Set @nErrorCode=@@Error
End


-- SQA20357 - Handling rounding errors if there are multiple tax codes
If @nErrorCode = 0 
Begin
	
	If exists ( Select TH.ITEMENTITYNO,  TH.ITEMTRANSNO,  TH.HISTORYLINENO, count(*) 	 dummy								
			from TAXHISTORY TH
			where TH.ITEMENTITYNO =  @pnItemEntityNo
			and TH.ITEMTRANSNO = @pnItemTransNo
			and TH.ACCTDEBTORNO = @pnDebtorNo
			and TH.HISTORYLINENO = 1 	
			group by TH.ITEMENTITYNO,  TH.ITEMTRANSNO,  TH.HISTORYLINENO
			having count(*) >1 )
	Begin
		Update TH 
		set	TH.TAXABLEAMOUNT = (ABS(TH.TAXABLEAMOUNT) + ADJ.TAXABLEAMOUNT_ADJ) * SIGN(TH.TAXABLEAMOUNT), 
			TH.TAXAMOUNT = (ABS(TH.TAXAMOUNT ) + ADJ.TAXAMOUNT_ADJ ) * SIGN(TH.TAXAMOUNT )
		From TAXHISTORY TH
		join (Select TH.ITEMENTITYNO, TH.ITEMTRANSNO, TH.HISTORYLINENO, MAX(TH.TAXCODE) TAXCODE_MAX,
			ABS(ABS(MAX(DH.ITEMPRETAXVALUE)) - ABS(SUM(TH.TAXABLEAMOUNT))) TAXABLEAMOUNT_ADJ, 
			ABS(ABS(MAX(DH.LOCALTAXAMT)) - ABS(SUM(TH.TAXAMOUNT))) TAXAMOUNT_ADJ

			from TAXHISTORY TH
			join DEBTORHISTORY DH on 
						(DH.ITEMENTITYNO = TH.ITEMENTITYNO
						and DH.ITEMTRANSNO = TH.ITEMTRANSNO
						and DH.ACCTENTITYNO = TH.ACCTENTITYNO
						and DH.ACCTDEBTORNO = TH.ACCTDEBTORNO
						and DH.HISTORYLINENO = TH.HISTORYLINENO)
			group by TH.ITEMENTITYNO, TH.ITEMTRANSNO, TH.HISTORYLINENO) ADJ
							ON (ADJ.ITEMENTITYNO = TH.ITEMENTITYNO
							and ADJ.ITEMTRANSNO = TH.ITEMTRANSNO
							and ADJ.HISTORYLINENO = TH.HISTORYLINENO
							and ADJ.TAXCODE_MAX = TH.TAXCODE)   -- Only adjust the row with the highest taxcode
		where TH.ITEMENTITYNO =  @pnItemEntityNo
		and TH.ITEMTRANSNO = @pnItemTransNo
		and TH.ACCTDEBTORNO = @pnDebtorNo
		and TH.HISTORYLINENO = @nDHCurrentHistoryLineNo + 1 	
			
		Set @nErrorCode=@@Error
	End
End




-- *******************************************************************************
-- * Adjust up new item
-- *******************************************************************************

-- Adjust up OPENITEM (new item)
If @nErrorCode = 0
Begin
	-- Create ACCOUNT entry for the current debtor it account does not exist
	-- Note:  The ACCOUNT table is a parent of OPENITEM, DEBTORYHISTORY and TRANSADJUSTMENT therefore it's must be created before these tables.
	If @nErrorCode = 0 
	Begin
		If not exists (Select 1 from ACCOUNT where NAMENO = @pnDebtorNo AND ENTITYNO = @pnItemEntityNo)
		Begin
			Insert into ACCOUNT (NAMENO, ENTITYNO) 
			values (@pnDebtorNo, @pnItemEntityNo) 
			Set @nErrorCode=@@Error
		End
	End


	-- Construct OPENITEMNO from SPECIALNAME.LASTARNO and DEBTOR_ITEM_TYPE.ABBREVIATION
	-- get LASTARNO
	If @nErrorCode = 0
	Begin	
		Select @nLastARNo = LASTARNO
		from SPECIALNAME WITH (UPDLOCK)  
		where NAMENO = @pnItemEntityNo
		Set @nErrorCode=@@Error

		If @nErrorCode = 0
		Begin	
			Update SPECIALNAME SET LASTARNO = @nLastARNo + 1   
			where NAMENO = @pnItemEntityNo
			Set @nErrorCode=@@Error
		End
	End

	-- OPENITEMNO = SPECIALNAME.LASTARNO + 1 +  DEBTOR_ITEM_TYPE.ABBREVIATION
	If @nErrorCode = 0
	Begin	
		Select @sOpenItem = cast(@nLastARNo+1 as nvarchar(10)) + DIT.ABBREVIATION
		from DEBTOR_ITEM_TYPE DIT
		join OPENITEM OI on OI.ITEMTYPE = DIT.ITEM_TYPE_ID
		where OI.ITEMENTITYNO = @pnItemEntityNo
		and OI.ITEMTRANSNO = @pnItemTransNo
		and OI.ACCTDEBTORNO = @pnDebtorNo
		Set @nErrorCode=@@Error
	End
	
	If @nErrorCode = 0
	Begin	
		Insert into OPENITEM(
		ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, ACTION, OPENITEMNO, ITEMDATE, POSTDATE, POSTPERIOD, 
		CLOSEPOSTDATE, CLOSEPOSTPERIOD, STATUS, ITEMTYPE, BILLPERCENTAGE, EMPLOYEENO, EMPPROFITCENTRE, CURRENCY, 
		EXCHRATE, ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE, FOREIGNTAXAMT, FOREIGNVALUE, LOCALBALANCE, FOREIGNBALANCE, 
		EXCHVARIANCE, STATEMENTREF, REFERENCETEXT, NAMESNAPNO, BILLFORMATID, BILLPRINTEDFLAG, REGARDING, SCOPE, 
		LANGUAGE, ASSOCOPENITEMNO, LONGREGARDING, LONGREFTEXT, IMAGEID, FOREIGNEQUIVCURRCY, FOREIGNEQUIVEXRATE, 
		ITEMDUEDATE, PENALTYINTEREST, LOCALORIGTAKENUP, FOREIGNORIGTAKENUP, REFERENCETEXT_TID, REGARDING_TID, SCOPE_TID, 
		INCLUDEONLYWIP, PAYFORWIP, PAYPROPERTYTYPE, RENEWALDEBTORFLAG, 
		CASEPROFITCENTRE, LOCKIDENTITYID, MAINCASEID)
		Select ITEMENTITYNO, 
			@nTransNo 'ITEMTRANSNO', 
			ACCTENTITYNO, 
			ACCTDEBTORNO, 
			ACTION, 
			@sOpenItem 'OPENITEMNO', 
			@pdtTransDate 'ITEMDATE',   
			null 'POSTDATE', 
			null 'POSTPERIOD', 
			null 'CLOSEPOSTDATE', 
			null 'CLOSEPOSTPERIOD', 
			0 'STATUS',
			ITEMTYPE, BILLPERCENTAGE, 
			NULL 'EMPLOYEENO', 
			NULL 'EMPPROFITCENTRE', 
			CURRENCY, 
			@nExchRate 'EXCHRATE', 
			case when isnull(LOCALVALUE, 0) <> 0 then ROUND(@nTransValueLocalNeg - (LOCALTAXAMT / LOCALVALUE * @nTransValueLocalNeg), 2) else null end 'ITEMPRETAXVALUE', 
			case when isnull(LOCALVALUE, 0) <> 0 then ROUND(LOCALTAXAMT / LOCALVALUE * @nTransValueLocalNeg, 2) else null end 'LOCALTAXAMT', 
			@nTransValueLocalNeg 'LOCALVALUE', 
			case when FOREIGNTAXAMT is not null then ROUND(FOREIGNTAXAMT/FOREIGNVALUE * @nTransValueForeignNeg, 2) else null end 'FOREIGNTAXAMT', 
			@nTransValueForeignNeg 'FOREIGNVALUE', 
			@nTransValueLocalNeg 'LOCALBALANCE', 
			@nTransValueForeignNeg 'FOREIGNBALANCE', 
			0 'EXCHVARIANCE', 
			STATEMENTREF, REFERENCETEXT, NAMESNAPNO, BILLFORMATID, BILLPRINTEDFLAG, 
			REGARDING, SCOPE, LANGUAGE, 
			NULL 'ASSOCOPENITEMNO', 
			LONGREGARDING, LONGREFTEXT, IMAGEID, 
			NULL 'FOREIGNEQUIVCURRCY', 
			NULL 'FOREIGNEQUIVEXRATE', 
			ITEMDUEDATE, 
			NULL 'PENALTYINTEREST', 
			LOCALORIGTAKENUP, FOREIGNORIGTAKENUP, REFERENCETEXT_TID, 
			REGARDING_TID, SCOPE_TID, INCLUDEONLYWIP, 
			@psPayForWip 'PAYFORWIP', 
			@psPropertyType 'PAYPROPERTYTYPE', 
			RENEWALDEBTORFLAG, 
			NULL 'CASEPROFITCENTRE', 
			NULL 'LOCKIDENTITYID', 
			NULL 'MAINCASEID'
		from OPENITEM
		where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo
		and ACCTDEBTORNO = @pnDebtorNo

		Set @nErrorCode=@@Error
	End
End


-- Adjust up OPENITEMCASE (new item) if transfer to case 
If @nErrorCode = 0 and @nCountTransferToCases > 0
Begin
	If @pbDebug = 1 
		print 'adjust up OPENITEMCASE'

	Insert into OPENITEMCASE (
		ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, CASEID, STATUS, 
		LOCALVALUE, FOREIGNVALUE, LOCALBALANCE, FOREIGNBALANCE) 
	select @pnItemEntityNo 'ITEMENTITYNO', 
		@nTransNo 'ITEMTRANSNO', 
		@pnItemEntityNo 'ACCTENTITYNO', 
		@pnDebtorNo 'ACCTDEBTORNO', 
		CASEID 'CASEID', 
		0 'STATUS', 
		LOCALVALUE 'LOCALVALUE', 
		FOREIGNVALUE 'FOREIGNVALUE', 
		LOCALVALUE 'LOCALBALANCE', 
		FOREIGNVALUE 'FOREIGNBALANCE'
	from #TRANSFERCASES

	Set @nErrorCode=@@Error
End


-- Adjust up DEBTORHISTORY (new item)
If @nErrorCode = 0
Begin
	Insert into DEBTORHISTORY(
		ITEMENTITYNO,ITEMTRANSNO,ACCTENTITYNO,ACCTDEBTORNO,HISTORYLINENO, 
		OPENITEMNO,TRANSDATE,POSTDATE,POSTPERIOD,TRANSTYPE,MOVEMENTCLASS,
		COMMANDID,ITEMPRETAXVALUE,LOCALTAXAMT,LOCALVALUE,EXCHVARIANCE,FOREIGNTAXAMT,
		FOREIGNTRANVALUE,REFERENCETEXT,REASONCODE,REFENTITYNO,REFTRANSNO,REFSEQNO,
		REFACCTENTITYNO,REFACCTDEBTORNO,LOCALBALANCE,FOREIGNBALANCE,TOTALEXCHVARIANCE,
		FORCEDPAYOUT,CURRENCY,EXCHRATE,STATUS,ASSOCLINENO,ITEMIMPACT,LONGREFTEXT,GLMOVEMENTNO)
	select 
		ITEMENTITYNO,
		ITEMTRANSNO,
		ACCTENTITYNO,
		ACCTDEBTORNO,
		1 'HISTORYLINENO', 
		OPENITEMNO,
		ITEMDATE 'TRANSDATE',
		null 'POSTDATE',
		null 'POSTPERIOD',
		533 'TRANSTYPE',
		4 'MOVEMENTCLASS',
		9 'COMMANDID',
		ITEMPRETAXVALUE, 
		LOCALTAXAMT, 
		LOCALVALUE, 
		0 'EXCHVARIANCE',  
		FOREIGNTAXAMT, 
		FOREIGNVALUE 'FOREIGNTRANVALUE', 
		REFERENCETEXT,
		@psReasonCode 'REASONCODE',
		ITEMENTITYNO 'REFENTITYNO',
		ITEMTRANSNO 'REFTRANSNO', 
		NULL 'REFSEQNO', 
		ITEMENTITYNO 'REFACCTENTITYNO', 
		ACCTDEBTORNO 'REFACCTDEBTORNO',
		LOCALBALANCE, 
		FOREIGNBALANCE, 
		0 'TOTALEXCHVARIANCE',  
		0 'FORCEDPAYOUT',
		CURRENCY,
		@nExchRate 'EXCHRATE',
		0 'STATUS',
		NULL 'ASSOCLINENO',
		1 'ITEMIMPACT',
		LONGREFTEXT,
		null 'GLMOVEMENTNO'
		from OPENITEM
		Where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @nTransNo
		and ACCTDEBTORNO = @pnDebtorNo
	Set @nErrorCode=@@Error
End


-- Adjust up DEBTORHISTORYCASE if case transfer 
If @nErrorCode = 0 and @nCountTransferToCases > 0 
Begin
	If @pbDebug = 1 
		print 'adjust up DEBTORHISTORYCASE'  
		
	Insert into DEBTORHISTORYCASE (
		ITEMTRANSNO, ITEMENTITYNO, ACCTDEBTORNO, ACCTENTITYNO, HISTORYLINENO, CASEID,
		FOREIGNTRANVALUE, LOCALVALUE)
	Select	ITEMTRANSNO, 
		ITEMENTITYNO, 
		ACCTDEBTORNO, 
		ACCTENTITYNO, 
		1 'HISTORYLINENO',
		CASEID, 
		FOREIGNVALUE, 
		LOCALVALUE
	from OPENITEMCASE
	where ITEMENTITYNO = @pnItemEntityNo 
	and ITEMTRANSNO = @nTransNo
	and ACCTDEBTORNO = @pnDebtorNo

	Set @nErrorCode=@@Error
End	


-- Adjust up OPENITEMTAX (new item) 
If @nErrorCode = 0 
Begin
	Insert into OPENITEMTAX(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, 
				TAXCODE, TAXRATE, TAXABLEAMOUNT, TAXAMOUNT, COUNTRYCODE)
	(Select TH.ITEMENTITYNO, 
		@nTransNo 'ITEMTRANSNO', 
		TH.ACCTENTITYNO, TH.ACCTDEBTORNO, 
		TH.TAXCODE, 
		TH.TAXRATE, 
		TH.TAXABLEAMOUNT * -1 'TAXABLEAMOUNT',
		TH.TAXAMOUNT * -1 'TAXAMOUNT',
		TH.COUNTRYCODE 
	From TAXHISTORY TH
	where TH.ITEMENTITYNO =  @pnItemEntityNo
	and TH.ITEMTRANSNO = @pnItemTransNo
	and TH.ACCTDEBTORNO = @pnDebtorNo
	and TH.HISTORYLINENO = @nDHCurrentHistoryLineNo + 1 )
		
	Set @nErrorCode=@@Error
End


-- Adjust Up TAXHISTORY if tax exists
If @nErrorCode = 0 
Begin
	-- SQA20357 Invalid Journal when a prepayment with tax is transferred
	--  ADDED REFENTITYNO, REFTRANSNO
	Insert into TAXHISTORY(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO,
				TAXCODE, TAXRATE, TAXABLEAMOUNT, TAXAMOUNT, COUNTRYCODE,
				REFENTITYNO, REFTRANSNO)
	Select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, 
		1 'HISTORYLINENO', 
		TAXCODE, TAXRATE, 
		TAXABLEAMOUNT,
		TAXAMOUNT,  
		COUNTRYCODE,
		ITEMENTITYNO, ITEMTRANSNO
	from OPENITEMTAX
	where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @nTransNo
	and ACCTDEBTORNO = @pnDebtorNo

	Set @nErrorCode=@@Error
End


-- Add TRANSADJUSTMENT rows for each case being transferred to
/*  
-- todo commented out as not able to record multiple rows in TRANSADJUSTMENT table
-- due to the table only allows one adjustment row per ENTITYNO, TRANSNO

If @nErrorCode = 0 
Begin
	If @nErrorCode = 0 and @nCountTransferToCases > 0
	Begin
		Insert into TRANSADJUSTMENT (ENTITYNO, TRANSNO, ADJENTITYNO, ADJSEQNO, ADJTRANSNO, 
			    REASONCODE, STATUS,  TOACCTENTITYNO, TOACCTNAMENO, TOCASEID, POSTDATE,
			    TRANSVALUE, FOREIGNTRANSVALUE, FOREIGNCURRENCY ) 
		select	@pnItemEntityNo 'ENTITYNO',
			@nTransNo 'TRANSNO', 
			@pnItemEntityNo	'ADJENTITYNO', 
			1 'ADJSEQNO',
			@pnItemTransNo 'ADJTRANSNO', 
			@psReasonCode 'REASONCODE',
			1 'STATUS',
			NULL 'TOACCTENTITYNO',
			NULL 'TOACCTNAMENO',
			TC.CASEID 'TOCASEID',
			getdate() 'POSTDATE',
			TC.LOCALVALUE 'TRANSVALUE', 
			TC.FOREIGNVALUE'FOREIGNTRANSVALUE',
			@sCurrency 'FOREIGNCURRENCY'
		from #TRANSFERCASES TC
		Set @nErrorCode=@@Error
	End
	
	If @nErrorCode = 0 and @pnOldCaseId is not null
	Begin
		Insert into TRANSADJUSTMENT (ENTITYNO, TRANSNO, ADJENTITYNO, ADJSEQNO, ADJTRANSNO, 
			    REASONCODE, STATUS,  TOACCTENTITYNO, TOACCTNAMENO, TOCASEID, POSTDATE,
			    TRANSVALUE, FOREIGNTRANSVALUE, FOREIGNCURRENCY ) 
		select	@pnItemEntityNo 'ENTITYNO',
			@nTransNo 'TRANSNO', 
			@pnItemEntityNo	'ADJENTITYNO', 
			1 'ADJSEQNO',
			@pnItemTransNo 'ADJTRANSNO', 
			@psReasonCode 'REASONCODE',
			1 'STATUS',
			NULL 'TOACCTENTITYNO',
			NULL 'TOACCTNAMENO',
			@pnOldCaseId 'TOCASEID',
			getdate() 'POSTDATE',
			@nTransValueLocalNeg 'TRANSVALUE', 
			@nTransValueForeignNeg 'FOREIGNTRANSVALUE',
			@sCurrency 'FOREIGNCURRENCY'
		Set @nErrorCode=@@Error
	End
End
*/

-- *******************************************************************************
-- * POSTING OLD AND NEW ITEMS
-- *******************************************************************************

--------------------------------------------------------------------
-- Posting old item
--------------------------------------------------------------------

-- Posting OPENITEM (Old item)
If @nErrorCode = 0
Begin
	Update OPENITEM
	Set 	STATUS = 1,
		CLOSEPOSTDATE = case when ABS(LOCALBALANCE) = @nTransValueLocalPos then @dtCurrentDateTime else '31-Dec-9999' end,
		CLOSEPOSTPERIOD = case when ABS(LOCALBALANCE) = @nTransValueLocalPos then  @nPostPeriod  else 999999 end,
	 	LOCALBALANCE = LOCALBALANCE - @nTransValueLocalNeg, 
		FOREIGNBALANCE = case when @nTransValueForeignNeg is null then null else FOREIGNBALANCE - @nTransValueForeignNeg end
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo
	and ACCTDEBTORNO = @pnDebtorNo
	Set @nErrorCode=@@Error
End


-- Posting OPENITEMCASE (old item)
If @nErrorCode = 0 and @pnOldCaseId is not null
Begin 
	Update OPENITEMCASE
	set	STATUS = 1,
		LOCALBALANCE= LOCALBALANCE - @nTransValueLocalNeg,
		FOREIGNBALANCE = case when @nTransValueForeignNeg is null then null else FOREIGNBALANCE - @nTransValueForeignNeg end
	where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo
	and ACCTDEBTORNO = @pnDebtorNo
	and CASEID = @pnOldCaseId 
	Set @nErrorCode=@@Error
End


-- Posting DEBTORHISTORY (old item)
If @nErrorCode = 0 
Begin 
	Update DEBTORHISTORY 
	set POSTDATE = @dtCurrentDateTime          , 
	POSTPERIOD = @nPostPeriod, 
	STATUS = 1,
	LOCALBALANCE= @nPrevLocalBalance - @nTransValueLocalNeg,
	FOREIGNBALANCE = case when @nTransValueForeignNeg is null then null else @nPrevForeignBalance - @nTransValueForeignNeg end
	where ITEMENTITYNO = @pnItemEntityNo 
	AND ITEMTRANSNO = @pnItemTransNo
	AND ACCTDEBTORNO = @pnDebtorNo 
	AND ACCTENTITYNO = @pnItemEntityNo 
	AND HISTORYLINENO = @nDHCurrentHistoryLineNo + 1


	Set @nErrorCode=@@Error
End

--------------------------------------------------------------------
-- POSTING NEW ITEM
--------------------------------------------------------------------
-- POSTING OPENITEM (New item)
If @nErrorCode = 0
Begin
	Update OPENITEM
	Set 	STATUS = 1,
		POSTDATE = GETDATE(),
		POSTPERIOD= @nPostPeriod,
		CLOSEPOSTDATE = '31-Dec-9999',   -- set to max date to indicate item is opened.
		CLOSEPOSTPERIOD = 999999
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @nTransNo
	and ACCTDEBTORNO = @pnDebtorNo
	Set @nErrorCode=@@Error
End


-- Posting DEBTORHISTORY (new item)
If @nErrorCode = 0 
Begin 
	Update DEBTORHISTORY 
	set POSTDATE = @dtCurrentDateTime, 
	POSTPERIOD = @nPostPeriod, 
	STATUS = 1       
	where ITEMENTITYNO = @pnItemEntityNo 
	and ITEMTRANSNO = @nTransNo
	and ACCTDEBTORNO = @pnDebtorNo 
	and ACCTENTITYNO = @pnItemEntityNo 
	and HISTORYLINENO = 1
	Set @nErrorCode=@@Error
End

-- Posting OPENITEMCASE (new item)
If @nErrorCode = 0 and @nCountTransferToCases > 0 
Begin 
	Update OPENITEMCASE
	set	STATUS = 1
	where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @nTransNo
	and ACCTDEBTORNO = @pnDebtorNo
	Set @nErrorCode=@@Error
End

-- Posting TRANSACTIONHEADER (new item)
If @nErrorCode = 0 
Begin 
	Update TRANSACTIONHEADER 
	set GLSTATUS = 0, 
	    TRANPOSTDATE = @dtCurrentDateTime, 
	    TRANPOSTPERIOD= @nPostPeriod, 
	    TRANSTATUS = 1            
	where ENTITYNO = @pnItemEntityNo
	and TRANSNO = @nTransNo
	Set @nErrorCode=@@Error
End


--Handling CONTROLTOTAL
If @nErrorCode = 0
Begin
	-- Adjust Down
	If @nErrorCode = 0
	Begin
		-- Call this procedure to insert/update CONTROLTOTAL as appropriate
		exec @nErrorCode = dbo.acw_UpdateControlTotal
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnLedger = 2,					-- DEBTORS 
			@pnCategory = 5,				-- MOVEMENT: 5 = 'Adjust Down'
			@pnType	= 533,					-- Transaction Type: 533='Debtors Transfer'
			@pnPeriodId	= @nPostPeriod,
			@pnEntityNo	= @pnItemEntityNo,
			@pnAmountToAdd =  @nTransValueLocalNeg
	End

	-- Adjust Up
	If @nErrorCode = 0
	Begin
		-- Call this procedure to insert/update CONTROLTOTAL as appropriate
		exec @nErrorCode = dbo.acw_UpdateControlTotal
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnLedger = 2,					-- DEBTORS 
			@pnCategory = 4,				-- MOVEMENT: 4 = 'Adjust Up'
			@pnType	= 533,					-- Transaction Type: 533='Debtors Transfer'
			@pnPeriodId	= @nPostPeriod,
			@pnEntityNo	= @pnItemEntityNo,
			@pnAmountToAdd = @nTransValueLocalPos
	End
End


-- *******************************************************************************
-- * Process GL Interface
-- *******************************************************************************
If (@nErrorCode = 0)
Begin
	If exists(Select * from SITECONTROL where CONTROLID = 'GL Journal Creation' and COLINTEGER = 1)
	Begin
		If (@pbDebug = 1)
			print 'process GL Interface'

		exec @nErrorCode = dbo.fi_CreateAndPostJournals
		  @pnResult = @nResult OUTPUT,
		  @pnUserIdentityId = @pnUserIdentityId,
		  @psCulture = @psCulture,
		  @pbCalledFromCentura = @pbCalledFromCentura,
		  @pnEntityNo = @pnItemEntityNo,
		  @pnTransNo = @nTransNo,
		  @pnDesignation = 1,
		  @pbIncProcessedNoJournal = 1
	End
End


-- Commit the transaction if it has successfully completed
If @nErrorCode = 0
	COMMIT TRANSACTION

Else
	ROLLBACK TRANSACTION


RETURN @nErrorCode
go

Grant execute on dbo.ar_TransferPrepayment to public
GO
