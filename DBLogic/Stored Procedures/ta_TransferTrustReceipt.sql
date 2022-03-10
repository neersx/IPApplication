-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ta_TransferTrustReceipt
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ta_TransferTrustReceipt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.ta_TransferTrustReceipt.'
	Drop procedure [dbo].[ta_TransferTrustReceipt]
end
Print '**** Creating Stored Procedure dbo.ta_TransferTrustReceipt...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO
Set ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ta_TransferTrustReceipt		
(
	@pnUserIdentityId	int,			    		
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,	
	@pbDebug		bit		= 0,
	@pnItemEntityNo		int,		
	@pnItemTransNo		int,
	@pnTransferFromCaseId	int		= null,	
	@pnLocalValue		decimal(11,2)	= null,		-- Total transfer value in local currency
	@pnForeignValue		decimal(11,2)	= null,		-- Total transfer value in foreign currency
	@pdtTransferDate	datetime,			
	@psTransferToCases	ntext		= null		-- list of transfer cases with transfer amount
)
as
-- PROCEDURE:	ta_TransferTrustReceipt
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Transfer trust fund from debtor level to case level and via versa. Also item can be transferred 
--		from one case to other cases.  Transfer to a different debtor is not allowed.  
--
-- MODIFICATIONS :
-- Date		Who	Change	 	Version	Description
-- -----------	----- 	-------- 	-------	----------------------------------------------- 
-- 6 Sep 2011	DL    	SQA19384 	1	Procedure created.
-- 11 Sep 2014	Dw    	RFC39201 	2	TRUSTHISTORYCASE record had Local Value in Foreign Value column. 
-- 20 Oct 2015  MS      R53933          3       Changed size from decimal(8,4) to decimal(11,4) for rate cols

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF
		
-- Transfer details 
CREATE TABLE #TRANSFERCASES (
	CASEID		int,
	TRANSFERVALUE	decimal(11,2),			-- Transfer value can be local or foreign
	LOCALVALUE	decimal(11,2),			
	FOREIGNVALUE	decimal(11,2)
	)

Declare @nNewTransNo		int
Declare @nErrorCode		int
Declare @TranCountStart		int
Declare @nTHCurrentHistoryLineNo	int
Declare @nDebtorNo		int
Declare @dtCurrentDateTime	datetime
Declare @dtCurrentDateOnly	datetime
Declare @nTransValueLocalNeg	decimal(11,2)
Declare @nTransValueLocalPos	decimal(11,2)
Declare @nTransValueForeignNeg	decimal(11,2)
Declare @nTransValueForeignPos	decimal(11,2)
Declare @nRowCount		int
Declare @nLastARNo		int
Declare @nPostPeriod		int
Declare @nResult		int
Declare @hDoc 			int
Declare @sSql			nvarchar(4000)
Declare @nCountTransferToCases	int	
Declare @nExchRate		decimal(11,4)
Declare @sCurrency		nchar(6)
declare @sCIDescription		nvarchar(254)
declare @sCIItemRefNo		nvarchar(30)
declare @sProfitCodeTrustAccount nvarchar(6)	-- From Control Account Type Trust to be used for creating the Credit journal line
declare @nAccountIdTrustAccount int


Set @nErrorCode=0

-- Get transfer to cases
If @nErrorCode = 0 and datalength(@psTransferToCases) > 0 
Begin
	Exec @nErrorCode = sp_xml_preparedocument @hDoc OUTPUT, @psTransferToCases

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
		Select @sCurrency=CURRENCY, @nExchRate = EXCHRATE
		from TRUSTITEM 
		Where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo
		Set @nErrorCode=@@Error

		-- calculate local value if it's not passed in
		If isnull(@pnLocalValue, 0)= 0 and isnull(@nExchRate, 0) <> 0
			set @pnLocalValue = round(@pnForeignValue/@nExchRate, 2)
			
		Select	@nTransValueLocalPos = ABS(@pnLocalValue), 
			@nTransValueForeignPos = ABS(@pnForeignValue)
		Select	@nTransValueLocalNeg = @nTransValueLocalPos * -1, 
			@nTransValueForeignNeg = @nTransValueForeignPos * -1
	End
	
	-- Convert foreign currency to local for transfer cases
	If @nErrorCode = 0 
	Begin
		Update #TRANSFERCASES
		set 
		LOCALVALUE	= case when (@sCurrency is null and @nExchRate is null) then ABS(TRANSFERVALUE)  
					else ABS(ROUND(TRANSFERVALUE/@nTransValueForeignPos*@nTransValueLocalPos, 2)) end,		
		FOREIGNVALUE	= case when (@sCurrency is null and @nExchRate is null) then null
					else ABS(TRANSFERVALUE) end
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
	Select @nDebtorNo = TACCTNAMENO, @nTHCurrentHistoryLineNo = HISTORYLINENO
	from TRUSTHISTORY
	Where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo
		and HISTORYLINENO = (	Select max(HISTORYLINENO) 
					from TRUSTHISTORY
					Where ITEMENTITYNO = @pnItemEntityNo
					and ITEMTRANSNO = @pnItemTransNo)
	Set @nErrorCode=@@Error
End


-- Get item posting period
If @nErrorCode = 0
Begin
	Select @nPostPeriod = PERIODID
	from PERIOD 
	where STARTDATE <= @pdtTransferDate
	and ENDDATE >= @pdtTransferDate

	Set @nErrorCode=@@Error
End


-- Get next TRANSNO
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'TRANSACTIONHEADER',
			@pnLastInternalCode	= @nNewTransNo OUTPUT	
End


BEGIN TRANSACTION 

If @nErrorCode = 0
Begin
	-- Note: TRANSTYPE 906 = 'Trust Transfer'
	Insert into TRANSACTIONHEADER (ENTITYNO, TRANSNO, TRANSDATE, TRANSTYPE, USERID,
		ENTRYDATE, TRANSTATUS, SOURCE, IDENTITYID) 
	values (@pnItemEntityNo, @nNewTransNo, @pdtTransferDate, 906, SYSTEM_USER, 
		@dtCurrentDateTime, 0, 64, @pnUserIdentityId )
	Set @nErrorCode=@@Error
End


-- *******************************************************************************
-- * Adjust down old item
-- *******************************************************************************

-- Adjust down TRUSTHISTORY (old item)
If @nErrorCode = 0
Begin
	Insert into TRUSTHISTORY( ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, HISTORYLINENO, ITEMNO, TRANSDATE, 
	POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, COMMANDID, LOCALVALUE, EXCHVARIANCE, FOREIGNTRANVALUE, REFENTITYNO, 
	REFTRANSNO, LOCALBALANCE, FOREIGNBALANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, STATUS, ASSOCLINENO, ITEMIMPACT, 
	DESCRIPTION, LONGDESCRIPTION)
	
	Select ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, 
	@nTHCurrentHistoryLineNo + 1 'HISTORYLINENO',
	ITEMNO, 
	@pdtTransferDate 'TRANSDATE', 
	NULL 'POSTDATE', 
	NULL 'POSTPERIOD', 
	906 'TRANSTYPE', 
	5 'MOVEMENTCLASS', 
	6 'COMMANDID', 
	@nTransValueLocalNeg 'LOCALVALUE', 
	0 'EXCHVARIANCE', 
	@nTransValueForeignNeg 'FOREIGNTRANVALUE',
	REFENTITYNO, 
	@nNewTransNo 'REFTRANSNO', 
	LOCALBALANCE,	-- to be recalcuated when posting
	FOREIGNBALANCE, -- to be recalcuated when posting
	0 'FORCEDPAYOUT', 
	CURRENCY, 
	@nExchRate 'EXCHRATE', 
	0 'STATUS', 
	ASSOCLINENO, 
	NULL 'ITEMIMPACT', 
	DESCRIPTION, LONGDESCRIPTION 
	from TRUSTHISTORY
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo
	and HISTORYLINENO = @nTHCurrentHistoryLineNo
	Set @nErrorCode=@@Error
	
	If @pbDebug=1
	Begin
		select 'TRUSTHISTORY'
		select * from TRUSTHISTORY 
		where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo
	End
End

-- Adjust down TRUSTHISTORYCASE if transfer from a case  
If @nErrorCode = 0 and @pnTransferFromCaseId is not null
Begin
	If @pbDebug = 1 
	Begin
		print 'Adjust down TRUSTHISTORYCASE'
	End

	Insert into TRUSTHISTORYCASE( ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, HISTORYLINENO, CASEID, 
	LOCALVALUE, FOREIGNTRANVALUE)
	Select	@pnItemEntityNo 'ITEMENTITYNO',
		@pnItemTransNo 'ITEMTRANSNO',  
		@pnItemEntityNo 'TACCTENTITYNO',
		@nDebtorNo 'TACCTNAMENO', 
		@nTHCurrentHistoryLineNo + 1 'HISTORYLINENO',
		@pnTransferFromCaseId 'CASEID', 
		@nTransValueLocalNeg  'LOCALVALUE',
		@nTransValueForeignNeg 'FOREIGNTRANVALUE'
	Set @nErrorCode=@@Error
End	



-- *******************************************************************************
-- * Adjust up new item
-- *******************************************************************************

-- Adjust up TRUSTITEM (new item)
If @nErrorCode = 0
Begin
	If @nErrorCode = 0
	Begin	
		Insert into TRUSTITEM( ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, ITEMNO, ITEMDATE, 
		POSTDATE, POSTPERIOD, CLOSEPOSTDATE, CLOSEPOSTPERIOD, ITEMTYPE, EMPLOYEENO, CURRENCY, EXCHRATE, 
		LOCALVALUE, FOREIGNVALUE, LOCALBALANCE, FOREIGNBALANCE, EXCHVARIANCE, STATUS, DESCRIPTION, 
		LONGDESCRIPTION)
		
		Select ITEMENTITYNO, 
		@nNewTransNo 'ITEMTRANSNO',  
		TACCTENTITYNO, TACCTNAMENO, ITEMNO, 
		@pdtTransferDate 'ITEMDATE', 
		NULL 'POSTDATE',		-- tobe be updated when posting
		NULL 'POSTPERIOD',		-- tobe be updated when posting
		NULL 'CLOSEPOSTDATE', 
		NULL 'CLOSEPOSTPERIOD', 
		ITEMTYPE, 
		NULL 'EMPLOYEENO', 
		CURRENCY, 
		@nExchRate 'EXCHRATE', 
		@nTransValueLocalPos 'LOCALVALUE', 
		@nTransValueForeignPos 'FOREIGNVALUE', 
		@nTransValueLocalPos 'LOCALBALANCE', 
		@nTransValueForeignPos 'FOREIGNBALANCE', 
		0 'EXCHVARIANCE', 
		0 'STATUS',			-- tobe updated when posting
		DESCRIPTION, LONGDESCRIPTION 
		from TRUSTITEM	
		where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo

		Set @nErrorCode=@@Error
	End
End


-- Adjust up TRUSTITEMCASE (new item) if transfer to case 
If @nErrorCode = 0 and @nCountTransferToCases > 0
Begin
	If @pbDebug = 1 
		print 'adjust up TRUSTITEMCASE'

	Insert into TRUSTITEMCASE( ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, CASEID, STATUS, 
	LOCALVALUE, FOREIGNVALUE, LOCALBALANCE, FOREIGNBALANCE)
	Select @pnItemEntityNo 'ITEMENTITYNO', 
		@nNewTransNo 'ITEMTRANSNO', 
		@pnItemEntityNo 'TACCTENTITYNO', 
		@nDebtorNo 'TACCTNAMENO', 
		CASEID 'CASEID', 
		0 'STATUS', 
		LOCALVALUE 'LOCALVALUE', 
		FOREIGNVALUE 'FOREIGNVALUE', 
		LOCALVALUE 'LOCALBALANCE', 
		FOREIGNVALUE 'FOREIGNBALANCE'
	from #TRANSFERCASES

	Set @nErrorCode=@@Error
End


-- Adjust up TRUSTHISTORY (new item)
If @nErrorCode = 0
Begin
	Insert into TRUSTHISTORY( ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, HISTORYLINENO, ITEMNO, TRANSDATE, 
	POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, COMMANDID, LOCALVALUE, EXCHVARIANCE, FOREIGNTRANVALUE, REFENTITYNO, 
	REFTRANSNO, LOCALBALANCE, FOREIGNBALANCE, FORCEDPAYOUT, CURRENCY, EXCHRATE, STATUS, ASSOCLINENO, ITEMIMPACT, 
	DESCRIPTION, LONGDESCRIPTION)
	
	Select ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, 
	1 'HISTORYLINENO',
	ITEMNO, 
	ITEMDATE 'TRANSDATE', 
	NULL 'POSTDATE', 
	NULL 'POSTPERIOD', 
	906 'TRANSTYPE', 
	4 'MOVEMENTCLASS', 
	9 'COMMANDID', 
	LOCALVALUE, 
	0 'EXCHVARIANCE', 
	FOREIGNVALUE 'FOREIGNTRANVALUE',
	ITEMENTITYNO 'REFENTITYNO', 
	ITEMTRANSNO 'REFTRANSNO', 
	LOCALBALANCE,	
	FOREIGNBALANCE, 
	0 'FORCEDPAYOUT', 
	CURRENCY, 
	@nExchRate 'EXCHRATE', 
	0 'STATUS', 
	NULL 'ASSOCLINENO', 
	1 'ITEMIMPACT', 
	DESCRIPTION, LONGDESCRIPTION 
	from TRUSTITEM
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @nNewTransNo
	Set @nErrorCode=@@Error
	Set @nErrorCode=@@Error
End


-- Adjust up TRUSTHISTORYCASE if case transfer 
If @nErrorCode = 0 and @nCountTransferToCases > 0 
Begin
	If @pbDebug = 1 
		print 'adjust up TRUSTHISTORYCASE'  

	Insert into TRUSTHISTORYCASE( ITEMENTITYNO, ITEMTRANSNO, TACCTENTITYNO, TACCTNAMENO, HISTORYLINENO, CASEID, 
	LOCALVALUE, FOREIGNTRANVALUE)
	Select	ITEMENTITYNO,
		ITEMTRANSNO, 
		TACCTENTITYNO, 
		TACCTNAMENO, 
		1 'HISTORYLINENO',
		CASEID, 
		LOCALVALUE,
		FOREIGNVALUE		
	from TRUSTITEMCASE
	where ITEMENTITYNO = @pnItemEntityNo 
	and ITEMTRANSNO = @nNewTransNo

	Set @nErrorCode=@@Error
End	



-- *******************************************************************************
-- * POSTING OLD AND NEW ITEMS
-- *******************************************************************************

--------------------------------------------------------------------
-- Posting old item
--------------------------------------------------------------------

-- Posting TRUSTITEM (Old item)
If @nErrorCode = 0
Begin
	Update TRUSTITEM
	Set 	STATUS = 1,
		POSTDATE = @dtCurrentDateTime,
		POSTPERIOD= @nPostPeriod,
		CLOSEPOSTDATE = case when ABS(LOCALBALANCE) = @nTransValueLocalPos then @dtCurrentDateTime else '31-Dec-9999' end,
		CLOSEPOSTPERIOD = case when ABS(LOCALBALANCE) = @nTransValueLocalPos then @nPostPeriod else 999999 end,
	 	LOCALBALANCE = LOCALBALANCE - @nTransValueLocalPos, 
		FOREIGNBALANCE = case when @nTransValueForeignPos is null then null else FOREIGNBALANCE - @nTransValueForeignPos end
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo
	Set @nErrorCode=@@Error
End


-- Posting TRUSTITEMCASE (old item)
If @nErrorCode = 0 and @pnTransferFromCaseId is not null
Begin 
	Update TRUSTITEMCASE
	set	STATUS = 1,
		LOCALBALANCE= LOCALBALANCE - @nTransValueLocalPos,
		FOREIGNBALANCE = case when @nTransValueForeignPos is null then null else FOREIGNBALANCE - @nTransValueForeignPos end
	where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo
	and TACCTNAMENO = @nDebtorNo
	and CASEID = @pnTransferFromCaseId 
	Set @nErrorCode=@@Error
End


-- Posting TRUSTHISTORY (old item)
If @nErrorCode = 0 
Begin 
	Update TRUSTHISTORY 
	set POSTDATE = @dtCurrentDateTime          , 
	POSTPERIOD = @nPostPeriod, 
	STATUS = 1,
	LOCALBALANCE= LOCALBALANCE - @nTransValueLocalPos,
	FOREIGNBALANCE = case when @nTransValueForeignPos is null then null else FOREIGNBALANCE - @nTransValueForeignPos end
	where ITEMENTITYNO = @pnItemEntityNo 
	AND ITEMTRANSNO = @pnItemTransNo
	AND TACCTNAMENO = @nDebtorNo 
	AND TACCTENTITYNO = @pnItemEntityNo 
	AND HISTORYLINENO = @nTHCurrentHistoryLineNo + 1


	Set @nErrorCode=@@Error
End

--------------------------------------------------------------------
-- POSTING NEW ITEM
--------------------------------------------------------------------

-- POSTING TRUSTITEM (New item)
If @nErrorCode = 0
Begin
	Update TRUSTITEM
	Set 	STATUS = 1,
		POSTDATE = getdate(),
		POSTPERIOD= @nPostPeriod,
		CLOSEPOSTDATE = '31-Dec-9999',   -- set to max date to indicate item is opened.
		CLOSEPOSTPERIOD = 999999
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @nNewTransNo
	Set @nErrorCode=@@Error
End


-- Posting TRUSTHISTORY (new item)
If @nErrorCode = 0 
Begin 
	Update TRUSTHISTORY 
	set POSTDATE = @dtCurrentDateTime, 
	POSTPERIOD = @nPostPeriod, 
	STATUS = 1       
	where ITEMENTITYNO = @pnItemEntityNo 
	and ITEMTRANSNO = @nNewTransNo
	and TACCTNAMENO = @nDebtorNo 
	and TACCTENTITYNO = @pnItemEntityNo 
	and HISTORYLINENO = 1
	Set @nErrorCode=@@Error
End

-- Posting TRUSTITEMCASE (new item)
If @nErrorCode = 0 and @nCountTransferToCases > 0 
Begin 
	Update TRUSTITEMCASE
	set	STATUS = 1
	where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @nNewTransNo
	and TACCTNAMENO = @nDebtorNo
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
	and TRANSNO = @nNewTransNo
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
			@pnLedger = 8,					-- TRUST
			@pnCategory = 5,				-- MOVEMENT: 5 = 'Adjust Down'
			@pnType	= 906,					-- Transaction Type: 906='Trust Transfer'
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
			@pnLedger = 8,					-- TRUST 
			@pnCategory = 4,				-- MOVEMENT: 4 = 'Adjust Up'
			@pnType	= 906,					-- Transaction Type: 906='Trust Transfer'
			@pnPeriodId	= @nPostPeriod,
			@pnEntityNo	= @pnItemEntityNo,
			@pnAmountToAdd = @nTransValueLocalPos
	End
End



If (@nErrorCode = 0)
Begin
	If (@pbDebug = 1)
		print 'process GL Interface'
		
	--  Get the default Control Account Type for Trust to record the Credit journal in journal line.
	If @nErrorCode = 0 
	Begin 
		Select @nAccountIdTrustAccount=DA.ACCOUNTID, @sProfitCodeTrustAccount=DA.PROFITCENTRECODE
		from DEFAULTACCOUNT DA
		join LEDGERACCOUNT LA on LA.ACCOUNTID = DA.ACCOUNTID 
		where DA.ENTITYNO = @pnItemEntityNo 
		AND DA.CONTROLACCTYPEID = 8710   -- Control Account Type: Trust 
		and LA.ISACTIVE = 1 
		and not exists (Select 1 from LEDGERACCOUNT LA2
				where LA.ACCOUNTID = LA2.PARENTACCOUNTID) 
		Set @nErrorCode=@@Error
	End


	-- Get Description and Reference for ledger 
	If @nErrorCode = 0 
	Begin 
		Select @sCIDescription=CI.DESCRIPTION , @sCIItemRefNo=CI.ITEMREFNO 
		from TRUSTITEM TI
		JOIN TRUSTITEM TI2 ON TI2.ITEMNO = TI.ITEMNO 
		JOIN CASHITEM CI ON (CI.TRANSENTITYNO = TI2.ITEMENTITYNO
					AND CI.TRANSNO = TI2.ITEMTRANSNO)
		where TI.ITEMENTITYNO= @pnItemEntityNo 
		and TI.ITEMTRANSNO = @pnItemTransNo
		
		Set @nErrorCode=@@Error
	End

	-- Create the LEDGER for the transfer item
	If @nErrorCode = 0 
	Begin 
		Insert into LEDGERJOURNAL (ENTITYNO, TRANSNO, DESCRIPTION,  IDENTITYID, REFENTITYNO, REFTRANSNO, REFERENCE,  
		STATUS, USERID) VALUES (@pnItemEntityNo, @nNewTransNo, @sCIDescription, null, null, null, @sCIItemRefNo, 1, SYSTEM_USER )
		Set @nErrorCode=@@Error
	End


	--  Debit Trust Account
	If @nErrorCode = 0 
	Begin 
		Insert into LEDGERJOURNALLINE (ENTITYNO, TRANSNO, SEQNO, PROFITCENTRECODE, ACCOUNTID, LOCALAMOUNT,  NOTES, 
		ACCTENTITYNO, CURRENCY,  EXCHRATE, FOREIGNAMOUNT ) 
		VALUES ( @pnItemEntityNo, @nNewTransNo, 1, @sProfitCodeTrustAccount, @nAccountIdTrustAccount, @nTransValueLocalPos, @sCIDescription,
		@pnItemEntityNo, @sCurrency, @nExchRate, @nTransValueForeignPos)
		Set @nErrorCode=@@Error
	End


	-- Credit Trust Account
	If @nErrorCode = 0 
	Begin 
		Insert into LEDGERJOURNALLINE (ENTITYNO, TRANSNO, SEQNO, PROFITCENTRECODE, ACCOUNTID, LOCALAMOUNT,  NOTES, 
		ACCTENTITYNO, CURRENCY,  EXCHRATE, FOREIGNAMOUNT ) 
		VALUES ( @pnItemEntityNo, @nNewTransNo, 2, @sProfitCodeTrustAccount, @nAccountIdTrustAccount, @nTransValueLocalNeg, @sCIDescription,
		@pnItemEntityNo, @sCurrency, @nExchRate, @nTransValueForeignNeg)
		Set @nErrorCode=@@Error
	End
	
	-- Update LEDGERJOURNALLINEBALANCE table
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.gl_MaintLJLBalance @pnUserIdentityId, @psCulture, 0, @pbDebug, @pnItemEntityNo, @nNewTransNo
	End
	
End



-- Commit the transaction if it has successfully completed
If @nErrorCode = 0
	COMMIT TRANSACTION
Else
	ROLLBACK TRANSACTION


RETURN @nErrorCode
go

Grant execute on dbo.ta_TransferTrustReceipt to public
GO
