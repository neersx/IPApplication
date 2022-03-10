-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_ReverseBill] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_ReverseBill]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_ReverseBill].'
	drop procedure dbo.[biw_ReverseBill]
end
print '**** Creating procedure dbo.[biw_ReverseBill]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go
SET CONCAT_NULL_YIELDS_NULL OFF
go 

create procedure dbo.[biw_ReverseBill]
				@pnUserIdentityId		int,				-- Mandatory
				@psCulture				nvarchar(10) 		= null,
				@pbCalledFromCentura	bit					= 0,
				@pnItemEntityNo			int,				-- Mandatory
				@pnItemTransNo			int,				-- Mandatory
				@pnEmployeeNo			int,				-- Mandatory
				@pdtTransDate			datetime,			-- Mandatory
				@pdtPostDate			datetime			-- Mandatory
as
-- PROCEDURE :	biw_ReverseBill
-- VERSION :	23
-- DESCRIPTION:	A procedure that reverses the selected bill.
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATION
-- Date			Who		RFC			Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 03/03/2010	KR	R8299	1	Procedure created
-- 26/08/2010		KR		RFC9280			2	fixed issues with taken up bills not being able to be reversed
-- 15 Jul 2011	DL	19791	3	Extend variable referencing CONTROLTOTAL.TOTAL to dec(13,2) instead of dec(11,2)
-- 09 Aug 2011	MF	R11087	4	Site Control "GL Journal Creation" is an integer not a bit and allows for value 0,1 and 2
-- 07 Feb 2012	AT	R11903	5	Fixed reversing bills with credits taken up.
-- 09 Feb 2012	KR	R11573	6	Update TAXHISTORY with the apprpopriate REFENTITYNO and REFTRANSNO
-- 22 Feb 2012	AT	R11976	7	Fixed reversing Credit Full Bill credit notes.
--				8	Fixed ControlTotal doubling itself.
-- 20 Mar 2012	AT	R12054	9	Fixed reinstatement of Applied Credit Open Item's foreign value.
-- 16 Apr 2012	AT	R12181	10	Fix reversal of inter-entity bills.
-- 18 Apr 2012	AT	R12171	11	Default Post Date to current date, derive Post Period from entered reversal Date (@pdtPostDate).
-- 30 Apr 2012	AT	R12226	12	Fixed debtor history balance calculation.
-- 01 May 2012	AT	R12081	13	Fixed ControlTotal not updating.
-- 06 Feb 2013  DV	R12758	14	Return friendly messsage for in case of foreign key constraing violation
-- 04 Apr 2013  MS      R13346  15      Set GLSTATUS to 1 if GLJournal exists for reversed bill 
-- 11 Sep 2013  vql     DR495	16      Reverse a bill that includes debtor-allocated WIP.
-- 13 Apr 2015	KR	R46258	17	Added logic to reverse any wip payment row if present
-- 29 May 2015	DL	R46258	18	Handle Reverse credit full bill transaction with Cash Accounting
-- 20 Oct 2015  MS      R53933  19      Changed size from decimal(8,4) to decimal(11,4) for ExchRate cols
-- 06 Sep 2016	DL	R63741	20	Fixed bug reverse a multi debtor bill with credit applied from a multi debtor prepayment.
-- 24 Oct 2017	AK	R72645	21	Make compatible with case sensitive server with case insensitive database.
-- 06 Aug 2018  MS      R74731  22      Fix issue where ForeignCurrency is set as 0 rather than null for Reinstated WIP rows
-- 27 Aug 2019  AK	DR-45752	23 pull out the logic to check biw_ReconcileDebtorItems
Set nocount on

--create temp tables

If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPWORKHISTORY')
Begin
	delete from #TEMPWORKHISTORY
End
Else
Begin
	CREATE TABLE #TEMPWORKHISTORY
	(
	[ENTITYNO] [int] NOT NULL,
	[TRANSNO] [int] NOT NULL,
	[WIPSEQNO] [smallint] NOT NULL,
	[HISTORYLINENO] [smallint] NOT NULL,
	[OLDHISTORYLINENO] [smallint] NOT NULL,
	[TRANSDATE] [datetime] NULL,
	[POSTDATE] [datetime] NULL,
	[TRANSTYPE] [smallint] NULL,
	[RATENO] [int] NULL,
	[WIPCODE] [nvarchar](6) collate database_default NULL,
	[CASEID] [int] NULL,
	[ACCTENTITYNO] [int] NULL,
	[ACCTCLIENTNO] [int] NULL,
	[EMPLOYEENO] [int] NULL,
	[TOTALTIME] [datetime] NULL,
	[TOTALUNITS] [smallint] NULL,
	[UNITSPERHOUR] [smallint] NULL,
	[CHARGEOUTRATE] [decimal](11, 2) NULL,
	[ASSOCIATENO] [int] NULL,
	[INVOICENUMBER] [nvarchar](20) collate database_default NULL,
	[FOREIGNCURRENCY] [nvarchar](3) collate database_default NULL,
	[FOREIGNTRANVALUE] [decimal](11, 2) NULL,
	[EXCHRATE] [decimal](11, 4) NULL,
	[LOCALTRANSVALUE] [decimal](11, 2) NULL,
	[REFENTITYNO] [int] NULL,
	[REFTRANSNO] [int] NULL,
	[REFSEQNO] [int] NULL,
	[REFACCTENTITYNO] [int] NULL,
	[REFACCTDEBTORNO] [int] NULL,
	[REASONCODE] [nvarchar](2) collate database_default NULL,
	[BILLLINENO] [smallint] NULL,
	[EMPPROFITCENTRE] [nvarchar](6) collate database_default NULL,
	[CASEPROFITCENTRE] [nvarchar](6) collate database_default NULL,
	[NARRATIVENO] [smallint] NULL,
	[SHORTNARRATIVE] [nvarchar](254) collate database_default NULL,
	[LONGNARRATIVE] [ntext] NULL,
	[ASSOCLINENO] [smallint] NULL,
	[TRANSFERDETAIL] [int] NULL,
	[STATUS] [smallint] NULL,
	[MOVEMENTCLASS] [smallint] NULL,
	[COMMANDID] [smallint] NULL,
	[ITEMIMPACT] [smallint] NULL,
	[POSTPERIOD] [int] NULL,
	[VARIABLEFEEAMT] [decimal](11, 2) NULL,
	[VARIABLEFEETYPE] [smallint] NULL,
	[VARIABLEFEECURR] [nvarchar](3) collate database_default NULL,
	[FEECRITERIANO] [int] NULL,
	[FEEUNIQUEID] [smallint] NULL,
	[GLMOVEMENTNO] [int] NULL,
	[QUOTATIONNO] [int] NULL,
	[EMPFAMILYNO] [smallint] NULL,
	[EMPOFFICECODE] [int] NULL,
	[VERIFICATIONNUMBER] [nvarchar](20) collate database_default NULL,
	[LOCALCOST] [decimal](11, 2) NULL,
	[FOREIGNCOST] [decimal](11, 2) NULL,
	[ENTEREDQUANTITY] [int] NULL,
	[DISCOUNTFLAG] [decimal](1, 0) NULL,
	[NARRATIVE_TID] [int] NULL,
	[COSTCALCULATION1] [decimal](11, 2) NULL,
	[COSTCALCULATION2] [decimal](11, 2) NULL,
	[PRODUCTCODE] [int] NULL,
	[GENERATEDINADVANCE] [decimal](1, 0) NULL,
	[MATCHENTITYNO] [int] NULL,
	[MATCHTRANSNO] [int] NULL,
	[MATCHWIPSEQNO] [int] NULL,
	[MATCHEDTOOPENITEM] [bit] NULL,
	[MATCHEDFULLY] [bit] NULL,
	[MARGINNO] [int] NULL,
        [MARGINFLAG] [bit] NULL,
	[SPLITPERCENTAGE] [decimal](5,2)         
	)
End

If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPDEBTORHISTORY')
Begin
	delete from #TEMPDEBTORHISTORY
End
Else
Begin	
	Create table #TEMPDEBTORHISTORY
	([ITEMENTITYNO] [int] NOT NULL,
	[ITEMTRANSNO] [int] NOT NULL,
	[ACCTENTITYNO] [int] NOT NULL,
	[ACCTDEBTORNO] [int] NOT NULL,
	[HISTORYLINENO] [smallint] NOT NULL,
	[OLDHISTORYLINENO] [smallint] NOT NULL,
	[OPENITEMNO] [nvarchar](12) collate database_default NULL,
	[TRANSDATE] [datetime] NULL,
	[POSTDATE] [datetime] NULL,
	[POSTPERIOD] [int] NULL,
	[TRANSTYPE] [smallint] NULL,
	[MOVEMENTCLASS] [smallint] NULL,
	[COMMANDID] [smallint] NULL,
	[ITEMPRETAXVALUE] [decimal](11, 2) NULL,
	[LOCALTAXAMT] [decimal](11, 2) NULL,
	[LOCALVALUE] [decimal](11, 2) NULL,
	[EXCHVARIANCE] [decimal](11, 2) NULL,
	[FOREIGNTAXAMT] [decimal](11, 2) NULL,
	[FOREIGNTRANVALUE] [decimal](11, 2) NULL,
	[REFERENCETEXT] [nvarchar](254) collate database_default NULL,
	[REASONCODE] [nvarchar](2) collate database_default NULL,
	[REFENTITYNO] [int] NULL,
	[REFTRANSNO] [int] NULL,
	[REFSEQNO] [int] NULL,
	[REFACCTENTITYNO] [int] NULL,
	[REFACCTDEBTORNO] [int] NULL,
	[LOCALBALANCE] [decimal](11, 2) NULL,
	[FOREIGNBALANCE] [decimal](11, 2) NULL,
	[TOTALEXCHVARIANCE] [decimal](11, 2) NULL,
	[FORCEDPAYOUT] [decimal](1, 0) NULL,
	[CURRENCY] [nvarchar](3) collate database_default NULL,
	[EXCHRATE] [decimal](11, 4) NULL,
	[STATUS] [smallint] NULL,
	[ASSOCLINENO] [smallint] NULL,
	[ITEMIMPACT] [smallint] NULL,
	[LONGREFTEXT] [ntext] NULL,
	[GLMOVEMENTNO] [int] NULL)
End
	
Declare		@nErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@sAlertXML nvarchar(400)
Declare		@nTransType int
Declare		@sTransDescription nvarchar(50)
Declare		@nReverseTransType int
Declare		@nPostPeriod int
Declare		@nGLJournalCreation int
Declare		@bFIStopsBillReversal bit
Declare		@nGLStatus	int
Declare		@nSource	int
Declare		@nTransNo int
Declare		@nItemEntityNo int
Declare		@nItemTransNo int
Declare		@nAcctEntityNo int
Declare		@nAcctDebtorNo int
Declare		@nWIPTransType int
Declare		@nWIPSeqNo int
Declare		@nLocalTransValue decimal(12,2)
Declare		@nItemType int
Declare		@nForeignTransValue decimal(12,2)
Declare		@nMovementClass int
Declare		@nExchVariance decimal(12,2)
Declare		@nLocalTaxAmt decimal(12,2)
Declare		@nLocalValue decimal(12,2)
Declare		@nDebtorTransType int
Declare		@nResult int

declare		@nDebug int

Set @nDebug = 0
Set @nErrorCode = 0

-- Entered Date is passed as Post Date.
Set @pdtTransDate = @pdtPostDate
-- Post date should be today's date.
Set @pdtPostDate = getdate()

If @nErrorCode = 0
Begin

	-- get site control values
	
	Set @sSQLString = "
	Select @nGLJournalCreation = isnull(COLINTEGER,0)
	From SITECONTROL
	Where CONTROLID = 'GL Journal Creation'"

	exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nGLJournalCreation	int 			OUTPUT',
	@nGLJournalCreation = @nGLJournalCreation	OUTPUT

	
	if (@nErrorCode = 0)
	Begin		
		Set @sSQLString = "
		Select @bFIStopsBillReversal = isnull(COLBOOLEAN,0)
		From SITECONTROL
		Where CONTROLID = 'FIStopsBillReversal'"
				
		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@bFIStopsBillReversal	bit 			OUTPUT',
		@bFIStopsBillReversal = @bFIStopsBillReversal	OUTPUT
	End
	
	if (@nErrorCode = 0)
	Begin
		Set @nSource = 2
		
		If exists (Select * from GLJOURNAL where ENTITYNO = @pnItemEntityNo and TRANSNO = @pnItemTransNo)
		        Set @nGLStatus = 1
		Else If (@nGLJournalCreation is null)
			Set @nGLStatus = null
		Else
			Set @nGLStatus = 0
		
		If (@bFIStopsBillReversal = 1)
			Set @nGLStatus = null
	End
		
	-- Get Post Period.
	if (@nErrorCode = 0)
	Begin
		Set @sSQLString = "Select @nPostPeriod = dbo.fn_GetPostPeriod(@pdtTransDate, 2) "
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@nPostPeriod int OUTPUT,
				@pdtTransDate DATETIME',
				@nPostPeriod	= @nPostPeriod	output,
				@pdtTransDate = @pdtTransDate
	End
			
				
	if (@nErrorCode = 0)
	Begin	
	
		Set @sSQLString = "Select 
				@nTransType = TRANSTYPE,
				@nReverseTransType = AT.REVERSE_TRANS_TYPE 
			  From TRANSACTIONHEADER TH
			  Join ACCT_TRANS_TYPE AT on (TH.TRANSTYPE= AT.TRANS_TYPE_ID)
			  Where TH.TRANSNO = @pnItemTransNo
			  AND TH.ENTITYNO = @pnItemEntityNo"
		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nTransType	int	OUTPUT,
			  @nReverseTransType		int	OUTPUT,
			  @pnItemTransNo		nvarchar(12),
			  @pnItemEntityNo int',
			  @nTransType = @nTransType	OUTPUT,
			  @nReverseTransType = @nReverseTransType	OUTPUT,
			  @pnItemTransNo = @pnItemTransNo,
			  @pnItemEntityNo = @pnItemEntityNo
	End
	
	
	if (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' begin tran'
		begin transaction
		
		If (@nDebug = 1)
			select ' update trans header'	
		
		 Set @sSQLString = "Update TRANSACTIONHEADER Set GLSTATUS = @nGLStatus 
		 where ENTITYNO = @pnItemEntityNo 
		 and TRANSNO = @pnItemTransNo
		 and TRANSTYPE in (510,516)"
		 
		 exec	@nErrorCode = sp_executesql @sSQLString,
		N'@nGLStatus int,
		  @pnItemEntityNo int,
		  @pnItemTransNo int',
		@nGLStatus = @nGLStatus,
		@pnItemEntityNo = @pnItemEntityNo,
		@pnItemTransNo = @pnItemTransNo
	End
	

		
	if (@nErrorCode = 0)
	Begin

	    exec @nErrorCode = dbo.ip_GetLastInternalCode 
		@pnUserIdentityId	= @pnUserIdentityId,
		@psTable	= 'TRANSACTIONHEADER',
		@pnLastInternalCode = @nTransNo output
	End
	
	if (@nErrorCode = 0)
	Begin
		 Set @sSQLString = "
		 Insert into TRANSACTIONHEADER
		(ENTITYNO, TRANSNO, TRANSDATE, TRANSTYPE, EMPLOYEENO, USERID, ENTRYDATE, SOURCE, TRANSTATUS, TRANPOSTPERIOD,
		 TRANPOSTDATE, GLSTATUS)
		 Values
		 (@pnItemEntityNo, @nTransNo, @pdtTransDate, @nReverseTransType, @pnEmployeeNo, SUSER_SNAME(),GETDATE(), 
		 @nSource, 1, @nPostPeriod, @pdtPostDate,@nGLStatus )"
		 
		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@pnItemEntityNo int,
		  @nTransNo int,
		  @nReverseTransType int,
		  @pnEmployeeNo int,
		  @nSource int,
		  @nPostPeriod int,
		  @pdtTransDate datetime,
		  @pdtPostDate datetime,
		  @nGLStatus int',
		@pnItemEntityNo = @pnItemEntityNo,
		@nTransNo = @nTransNo,
		@nReverseTransType = @nReverseTransType,
		@pnEmployeeNo = @pnEmployeeNo,
		@nSource = @nSource,
		@nPostPeriod = @nPostPeriod,
		@pdtTransDate = @pdtTransDate,
		@pdtPostDate = @pdtPostDate,
		@nGLStatus = @nGLStatus
	End


	--Reinstate deleted WIP
	if (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
		Begin
			select ' insert into work in progress'
			select  WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.TRANSDATE, WH.POSTDATE, 
			WH.RATENO, WH.WIPCODE, WH.CASEID, WH.ACCTENTITYNO, WH.ACCTCLIENTNO, 
			WH.EMPLOYEENO, WH.TOTALTIME, WH.TOTALUNITS, WH.UNITSPERHOUR, 
			WH.CHARGEOUTRATE, WH.ASSOCIATENO, WH.FOREIGNCURRENCY, 
			WH.FOREIGNTRANVALUE, WH.EXCHRATE, WH.LOCALTRANSVALUE,  WH.EMPPROFITCENTRE, WH.EMPFAMILYNO, WH.EMPOFFICECODE, 
			WH.CASEPROFITCENTRE, WH.NARRATIVENO, WH.SHORTNARRATIVE, WH.LONGNARRATIVE, WH.QUOTATIONNO, 
			WH.FEECRITERIANO, WH.FEEUNIQUEID, WH.VARIABLEFEEAMT, WH.VARIABLEFEETYPE, WH.VARIABLEFEECURR,
			0, 0, 1, WH.LOCALCOST, WH.FOREIGNCOST, WH.VERIFICATIONNUMBER, WH.INVOICENUMBER, WH.ENTEREDQUANTITY, 
			WH.DISCOUNTFLAG, WH.COSTCALCULATION1, WH.COSTCALCULATION2, WH.GENERATEDINADVANCE, 
			WH.PRODUCTCODE,  WH.MARGINNO, WH.MARGINFLAG
			from WORKHISTORY WH
			join WORKHISTORY WH1 on (WH.ENTITYNO=WH1.ENTITYNO
						and WH.TRANSNO=WH1.TRANSNO
						and WH.WIPSEQNO=WH1.WIPSEQNO
						and WH1.REFENTITYNO= @pnItemEntityNo
						and WH1.REFTRANSNO= @pnItemTransNo
						and WH1.MOVEMENTCLASS in (2,3,9))
			where WH.ITEMIMPACT = 1
			and NOT EXISTS (Select * from WORKINPROGRESS WIP
						  where WIP.ENTITYNO=WH.ENTITYNO
						  and WIP.TRANSNO=WH.TRANSNO
						  and WIP.WIPSEQNO=WH.WIPSEQNO)
		End
		-- MOVEMENTCLASS = 2 (CONSUME)
		Set @sSQLString = "Insert into WORKINPROGRESS 
		(ENTITYNO, TRANSNO, WIPSEQNO, TRANSDATE, POSTDATE, 
		RATENO, WIPCODE, CASEID, ACCTENTITYNO, ACCTCLIENTNO, 
		EMPLOYEENO, TOTALTIME, TOTALUNITS, UNITSPERHOUR, 
		CHARGEOUTRATE, ASSOCIATENO, FOREIGNCURRENCY, 
		FOREIGNVALUE, EXCHRATE, LOCALVALUE, EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE, 
		CASEPROFITCENTRE, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, QUOTATIONNO, 
		FEECRITERIANO, FEEUNIQUEID, VARIABLEFEEAMT, VARIABLEFEETYPE, VARIABLEFEECURR,
		BALANCE, FOREIGNBALANCE, STATUS, LOCALCOST, FOREIGNCOST, VERIFICATIONNUMBER, INVOICENUMBER, ENTEREDQUANTITY,
		DISCOUNTFLAG, COSTCALCULATION1, COSTCALCULATION2, GENERATEDINADVANCE, 
		PRODUCTCODE, MARGINNO, SPLITPERCENTAGE, MARGINFLAG) 
		select  WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.TRANSDATE, WH.POSTDATE, 
		WH.RATENO, WH.WIPCODE, WH.CASEID, WH.ACCTENTITYNO, WH.ACCTCLIENTNO, 
		WH.EMPLOYEENO, WH.TOTALTIME, WH.TOTALUNITS, WH.UNITSPERHOUR, 
		WH.CHARGEOUTRATE, WH.ASSOCIATENO, WH.FOREIGNCURRENCY, 
		WH.FOREIGNTRANVALUE, WH.EXCHRATE, WH.LOCALTRANSVALUE,  WH.EMPPROFITCENTRE, WH.EMPFAMILYNO, WH.EMPOFFICECODE, 
		WH.CASEPROFITCENTRE, WH.NARRATIVENO, WH.SHORTNARRATIVE, WH.LONGNARRATIVE, WH.QUOTATIONNO, 
		WH.FEECRITERIANO, WH.FEEUNIQUEID, WH.VARIABLEFEEAMT, WH.VARIABLEFEETYPE, WH.VARIABLEFEECURR,
		0, 0, 1, WH.LOCALCOST, WH.FOREIGNCOST, WH.VERIFICATIONNUMBER, WH.INVOICENUMBER, WH.ENTEREDQUANTITY, 
		WH.DISCOUNTFLAG, WH.COSTCALCULATION1, WH.COSTCALCULATION2, WH.GENERATEDINADVANCE, 
		WH.PRODUCTCODE,  WH.MARGINNO, WH.SPLITPERCENTAGE, WH.MARGINFLAG
		from WORKHISTORY WH
		join WORKHISTORY WH1 on (WH.ENTITYNO=WH1.ENTITYNO
					and WH.TRANSNO=WH1.TRANSNO
					and WH.WIPSEQNO=WH1.WIPSEQNO
					and WH1.REFENTITYNO= @pnItemEntityNo
					and WH1.REFTRANSNO= @pnItemTransNo
					and WH1.MOVEMENTCLASS = 2)
		where WH.ITEMIMPACT = 1
		and NOT EXISTS (Select * from WORKINPROGRESS WIP
					  where WIP.ENTITYNO=WH.ENTITYNO
					  and WIP.TRANSNO=WH.TRANSNO
					  and WIP.WIPSEQNO=WH.WIPSEQNO)"
		
		  
		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @pnItemTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo
		
		-- MOVEMENTCLASS = 3 (DISPOSE)
		Set @sSQLString = "Insert into WORKINPROGRESS 
		(ENTITYNO, TRANSNO, WIPSEQNO, TRANSDATE, POSTDATE, 
		RATENO, WIPCODE, CASEID, ACCTENTITYNO, ACCTCLIENTNO, 
		EMPLOYEENO, TOTALTIME, TOTALUNITS, UNITSPERHOUR, 
		CHARGEOUTRATE, ASSOCIATENO, FOREIGNCURRENCY, 
		FOREIGNVALUE, EXCHRATE, LOCALVALUE, EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE, 
		CASEPROFITCENTRE, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, QUOTATIONNO, 
		FEECRITERIANO, FEEUNIQUEID, VARIABLEFEEAMT, VARIABLEFEETYPE, VARIABLEFEECURR,
		BALANCE, FOREIGNBALANCE, STATUS, LOCALCOST, FOREIGNCOST, VERIFICATIONNUMBER, INVOICENUMBER, ENTEREDQUANTITY,
		DISCOUNTFLAG, COSTCALCULATION1, COSTCALCULATION2, GENERATEDINADVANCE, 
		PRODUCTCODE, MARGINNO, SPLITPERCENTAGE, MARGINFLAG) 
		select  WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.TRANSDATE, WH.POSTDATE, 
		WH.RATENO, WH.WIPCODE, WH.CASEID, WH.ACCTENTITYNO, WH.ACCTCLIENTNO, 
		WH.EMPLOYEENO, WH.TOTALTIME, WH.TOTALUNITS, WH.UNITSPERHOUR, 
		WH.CHARGEOUTRATE, WH.ASSOCIATENO, WH.FOREIGNCURRENCY, 
		WH.FOREIGNTRANVALUE, WH.EXCHRATE, WH.LOCALTRANSVALUE,  WH.EMPPROFITCENTRE, WH.EMPFAMILYNO, WH.EMPOFFICECODE, 
		WH.CASEPROFITCENTRE, WH.NARRATIVENO, WH.SHORTNARRATIVE, WH.LONGNARRATIVE, WH.QUOTATIONNO, 
		WH.FEECRITERIANO, WH.FEEUNIQUEID, WH.VARIABLEFEEAMT, WH.VARIABLEFEETYPE, WH.VARIABLEFEECURR,
		0, 0, 1, WH.LOCALCOST, WH.FOREIGNCOST, WH.VERIFICATIONNUMBER, WH.INVOICENUMBER, WH.ENTEREDQUANTITY, 
		WH.DISCOUNTFLAG, WH.COSTCALCULATION1, WH.COSTCALCULATION2, WH.GENERATEDINADVANCE, 
		WH.PRODUCTCODE,  WH.MARGINNO, WH.SPLITPERCENTAGE, WH.MARGINFLAG 
		from WORKHISTORY WH
		join WORKHISTORY WH1 on (WH.ENTITYNO=WH1.ENTITYNO
					and WH.TRANSNO=WH1.TRANSNO
					and WH.WIPSEQNO=WH1.WIPSEQNO
					and WH1.REFENTITYNO= @pnItemEntityNo
					and WH1.REFTRANSNO= @pnItemTransNo
					and WH1.MOVEMENTCLASS = 3)
		where WH.ITEMIMPACT = 1
		and NOT EXISTS (Select * from WORKINPROGRESS WIP
					  where WIP.ENTITYNO=WH.ENTITYNO
					  and WIP.TRANSNO=WH.TRANSNO
					  and WIP.WIPSEQNO=WH.WIPSEQNO)"
		
		  
		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @pnItemTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo
		
		-- MOVEMENTCLASS = 9 (EQALISE)
		Set @sSQLString = "Insert into WORKINPROGRESS 
		(ENTITYNO, TRANSNO, WIPSEQNO, TRANSDATE, POSTDATE, 
		RATENO, WIPCODE, CASEID, ACCTENTITYNO, ACCTCLIENTNO, 
		EMPLOYEENO, TOTALTIME, TOTALUNITS, UNITSPERHOUR, 
		CHARGEOUTRATE, ASSOCIATENO, FOREIGNCURRENCY, 
		FOREIGNVALUE, EXCHRATE, LOCALVALUE, EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE, 
		CASEPROFITCENTRE, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, QUOTATIONNO, 
		FEECRITERIANO, FEEUNIQUEID, VARIABLEFEEAMT, VARIABLEFEETYPE, VARIABLEFEECURR,
		BALANCE, FOREIGNBALANCE, STATUS, LOCALCOST, FOREIGNCOST, VERIFICATIONNUMBER, INVOICENUMBER, ENTEREDQUANTITY,
		DISCOUNTFLAG, COSTCALCULATION1, COSTCALCULATION2, GENERATEDINADVANCE, 
		PRODUCTCODE, MARGINNO, SPLITPERCENTAGE, MARGINFLAG) 
		select  WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.TRANSDATE, WH.POSTDATE, 
		WH.RATENO, WH.WIPCODE, WH.CASEID, WH.ACCTENTITYNO, WH.ACCTCLIENTNO, 
		WH.EMPLOYEENO, WH.TOTALTIME, WH.TOTALUNITS, WH.UNITSPERHOUR, 
		WH.CHARGEOUTRATE, WH.ASSOCIATENO, WH.FOREIGNCURRENCY, 
		WH.FOREIGNTRANVALUE, WH.EXCHRATE, WH.LOCALTRANSVALUE,  WH.EMPPROFITCENTRE, WH.EMPFAMILYNO, WH.EMPOFFICECODE, 
		WH.CASEPROFITCENTRE, WH.NARRATIVENO, WH.SHORTNARRATIVE, WH.LONGNARRATIVE, WH.QUOTATIONNO, 
		WH.FEECRITERIANO, WH.FEEUNIQUEID, WH.VARIABLEFEEAMT, WH.VARIABLEFEETYPE, WH.VARIABLEFEECURR,
		0, 0, 1, WH.LOCALCOST, WH.FOREIGNCOST, WH.VERIFICATIONNUMBER, WH.INVOICENUMBER, WH.ENTEREDQUANTITY, 
		WH.DISCOUNTFLAG, WH.COSTCALCULATION1, WH.COSTCALCULATION2, WH.GENERATEDINADVANCE, 
		WH.PRODUCTCODE,  WH.MARGINNO, WH.SPLITPERCENTAGE, WH.MARGINFLAG
		from WORKHISTORY WH
		join WORKHISTORY WH1 on (WH.ENTITYNO=WH1.ENTITYNO
					and WH.TRANSNO=WH1.TRANSNO
					and WH.WIPSEQNO=WH1.WIPSEQNO
					and WH1.REFENTITYNO= @pnItemEntityNo
					and WH1.REFTRANSNO= @pnItemTransNo
					and WH1.MOVEMENTCLASS = 9)
		where WH.ITEMIMPACT = 1
		and NOT EXISTS (Select * from WORKINPROGRESS WIP
					  where WIP.ENTITYNO=WH.ENTITYNO
					  and WIP.TRANSNO=WH.TRANSNO
					  and WIP.WIPSEQNO=WH.WIPSEQNO)"
		
		  
		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @pnItemTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo
	End
	

	 
	-- Reinstate partially adjusted WIP
	
	if (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' insert into WIP'
		
		Declare cWorkInProgress cursor for
		Select WIP.ENTITYNO, WIP.TRANSNO, WIP.WIPSEQNO, SUM(ISNULL(WH.LOCALTRANSVALUE,0)), SUM(ISNULL(WH.FOREIGNTRANVALUE,0))
		From WORKINPROGRESS WIP
		Join WORKHISTORY WH on 	(WIP.ENTITYNO = WH.ENTITYNO and WIP.TRANSNO = WH.TRANSNO 
								and WIP.WIPSEQNO = WH.WIPSEQNO)
		Where WH.MOVEMENTCLASS in (1,2,3,9)
		and WH.REFENTITYNO = @pnItemEntityNo
		and WH.REFTRANSNO	= @pnItemTransNo
		group by WIP.ENTITYNO, WIP.TRANSNO, WIP.WIPSEQNO
		
		Open cWorkInProgress
		Fetch Next From cWorkInProgress Into @nItemEntityNo, @nItemTransNo, @nWIPSeqNo, @nLocalTransValue, @nForeignTransValue
		
		While @@FETCH_STATUS = 0
		Begin
			Update WORKINPROGRESS Set BALANCE = BALANCE-@nLocalTransValue, 
					FOREIGNBALANCE = CASE WHEN FOREIGNBALANCE-@nForeignTransValue = 0 then null else FOREIGNBALANCE-@nForeignTransValue end
			Where ENTITYNO = @nItemEntityNo
			and TRANSNO	= @nItemTransNo
			and WIPSEQNO = @nWIPSeqNo
			
			Fetch Next From cWorkInProgress Into @nItemEntityNo, @nItemTransNo, @nWIPSeqNo, @nLocalTransValue, @nForeignTransValue
		End
		Close cWorkInProgress
		Deallocate cWorkInProgress
	End
	

	Begin Try
		-- Delete zero balance items
		if (@nErrorCode = 0)
		Begin
			If (@nDebug = 1)
			begin
				select ' complete WIP loop'
				select 'WIP'
				select * from WORKINPROGRESS where
				ENTITYNO = @pnItemEntityNo
				and TRANSNO	= @pnItemTransNo
			end
			Set @sSQLString = "Delete WIP from WORKINPROGRESS WIP
			Join WORKHISTORY WH on (WIP.ENTITYNO = WH.ENTITYNO and WIP.TRANSNO = WH.TRANSNO and WIP.WIPSEQNO = WH.WIPSEQNO )
			Where WIP.BALANCE = 0
			and WH.REFENTITYNO = @pnItemEntityNo
			and WH.REFTRANSNO = @pnItemTransNo"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @pnItemTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo
		End
	End Try
	Begin Catch
		Set @nErrorCode = @@Error
		if @nErrorCode = 547
		Begin			
			Set @sAlertXML = dbo.fn_GetAlertXML('BI27', 'The requested WorkInProgress cannot be deleted as it is essential to other existing information',
						 null, null, null,null,null)
			RAISERROR(@sAlertXML, 12, 1)			
		End
	End Catch
		
	-- Reinstate Work History
	

	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
		Begin
			select ' complete WIP loop'
			select 'WH'
			Select 
			[ENTITYNO] ,[TRANSNO] ,[WIPSEQNO] ,[HISTORYLINENO], [HISTORYLINENO] ,@pdtTransDate ,
			@pdtPostDate ,@nReverseTransType ,[RATENO] ,[WIPCODE] ,[CASEID] ,[ACCTENTITYNO] ,
			[ACCTCLIENTNO] ,[EMPLOYEENO] ,case when [ITEMIMPACT]= 1 then null else [TOTALTIME] end ,
			case when [ITEMIMPACT] = 1 then null else [TOTALUNITS]end ,case when [ITEMIMPACT]=1 then null else [UNITSPERHOUR] end ,
			case when [ITEMIMPACT] = 1 then null else [CHARGEOUTRATE] end,[ASSOCIATENO] ,[INVOICENUMBER] ,[FOREIGNCURRENCY] ,
			case when [FOREIGNCURRENCY] is not null then [FOREIGNTRANVALUE]*-1 else [FOREIGNTRANVALUE] end  ,
			[EXCHRATE] ,[LOCALTRANSVALUE]*-1 ,@pnItemEntityNo ,
			@nTransNo ,[REFSEQNO] ,[REFACCTENTITYNO] ,[REFACCTDEBTORNO] ,
			[REASONCODE] ,[BILLLINENO] ,[EMPPROFITCENTRE],[CASEPROFITCENTRE] ,
			[NARRATIVENO] ,[SHORTNARRATIVE] ,[LONGNARRATIVE] ,[HISTORYLINENO] ,
			[TRANSFERDETAIL] ,1 ,[MOVEMENTCLASS] ,99 ,
			case when [ITEMIMPACT]=1 then 9 else [ITEMIMPACT]end ,@nPostPeriod ,[VARIABLEFEEAMT] ,[VARIABLEFEETYPE] ,
			[VARIABLEFEECURR] ,[FEECRITERIANO] ,[FEEUNIQUEID] ,null ,
			[QUOTATIONNO] ,[EMPFAMILYNO] ,[EMPOFFICECODE] ,[VERIFICATIONNUMBER] ,
			case when [LOCALCOST] is not null then [LOCALCOST]*-1 else [LOCALCOST] end,
			case when [FOREIGNCOST] is not null then [FOREIGNCOST]*-1 else [FOREIGNCOST] end ,[ENTEREDQUANTITY] ,[DISCOUNTFLAG] ,
			[NARRATIVE_TID] ,[COSTCALCULATION1] ,[COSTCALCULATION2] ,[PRODUCTCODE] ,
			[GENERATEDINADVANCE],[MATCHENTITYNO] ,
			[MATCHTRANSNO] ,[MATCHWIPSEQNO] ,[MATCHEDTOOPENITEM] ,[MATCHEDFULLY] ,
			[MARGINNO] From WORKHISTORY
			Where 				
			REFENTITYNO= @pnItemEntityNo
			and REFTRANSNO= @pnItemTransNo
			and ( REASONCODE IS NULL OR REASONCODE != '_E')
		end

		Set @sSQLString = "Insert into #TEMPWORKHISTORY ([ENTITYNO],[TRANSNO],[WIPSEQNO],
		[HISTORYLINENO], [OLDHISTORYLINENO], [TRANSDATE],[POSTDATE],
		[TRANSTYPE],[RATENO],[WIPCODE],[CASEID],
		[ACCTENTITYNO],[ACCTCLIENTNO],[EMPLOYEENO],
		[TOTALTIME],[TOTALUNITS],[UNITSPERHOUR],
		[CHARGEOUTRATE],[ASSOCIATENO],[INVOICENUMBER],
		[FOREIGNCURRENCY],[FOREIGNTRANVALUE],[EXCHRATE],
		[LOCALTRANSVALUE],[REFENTITYNO],[REFTRANSNO],
		[REFSEQNO],[REFACCTENTITYNO],[REFACCTDEBTORNO],
		[REASONCODE],[BILLLINENO],[EMPPROFITCENTRE],
		[CASEPROFITCENTRE],[NARRATIVENO],[SHORTNARRATIVE],
		[LONGNARRATIVE],[ASSOCLINENO],[TRANSFERDETAIL],
		[STATUS],[MOVEMENTCLASS],[COMMANDID],[ITEMIMPACT],
		[POSTPERIOD],[VARIABLEFEEAMT],[VARIABLEFEETYPE],
		[VARIABLEFEECURR],[FEECRITERIANO],[FEEUNIQUEID],
		[GLMOVEMENTNO],[QUOTATIONNO],[EMPFAMILYNO],
		[EMPOFFICECODE],[VERIFICATIONNUMBER],[LOCALCOST],
		[FOREIGNCOST],[ENTEREDQUANTITY],[DISCOUNTFLAG],
		[NARRATIVE_TID],[COSTCALCULATION1],[COSTCALCULATION2],
		[PRODUCTCODE],[GENERATEDINADVANCE],[MATCHENTITYNO],
		[MATCHTRANSNO],[MATCHWIPSEQNO],[MATCHEDTOOPENITEM],
		[MATCHEDFULLY],[MARGINNO],[MARGINFLAG],[SPLITPERCENTAGE])
		(Select 
		[ENTITYNO] ,[TRANSNO] ,[WIPSEQNO] ,[HISTORYLINENO], [HISTORYLINENO] ,@pdtTransDate ,
		@pdtPostDate, @nReverseTransType ,[RATENO] ,[WIPCODE] ,[CASEID] ,[ACCTENTITYNO] ,
		[ACCTCLIENTNO] ,[EMPLOYEENO] ,case when [ITEMIMPACT]= 1 then null else [TOTALTIME] end ,
		case when [ITEMIMPACT] = 1 then null else [TOTALUNITS]end ,case when [ITEMIMPACT]=1 then null else [UNITSPERHOUR] end ,
		case when [ITEMIMPACT] = 1 then null else [CHARGEOUTRATE] end,[ASSOCIATENO] ,[INVOICENUMBER] ,[FOREIGNCURRENCY] ,
		case when [FOREIGNCURRENCY] is not null then [FOREIGNTRANVALUE]*-1 else [FOREIGNTRANVALUE] end  ,
		[EXCHRATE] ,[LOCALTRANSVALUE]*-1 ,@pnItemEntityNo ,
		@nTransNo ,[REFSEQNO] ,[REFACCTENTITYNO] ,[REFACCTDEBTORNO] ,
		[REASONCODE] ,[BILLLINENO] ,[EMPPROFITCENTRE],[CASEPROFITCENTRE] ,
		[NARRATIVENO] ,[SHORTNARRATIVE] ,[LONGNARRATIVE] ,[HISTORYLINENO] ,
		[TRANSFERDETAIL] ,1 ,[MOVEMENTCLASS] ,99 ,
		case when [ITEMIMPACT]=1 then 9 else [ITEMIMPACT]end ,@nPostPeriod ,[VARIABLEFEEAMT] ,[VARIABLEFEETYPE] ,
		[VARIABLEFEECURR] ,[FEECRITERIANO] ,[FEEUNIQUEID] ,null ,
		[QUOTATIONNO] ,[EMPFAMILYNO] ,[EMPOFFICECODE] ,[VERIFICATIONNUMBER] ,
		case when [LOCALCOST] is not null then [LOCALCOST]*-1 else [LOCALCOST] end,
		case when [FOREIGNCOST] is not null then [FOREIGNCOST]*-1 else [FOREIGNCOST] end ,[ENTEREDQUANTITY] ,[DISCOUNTFLAG] ,
		[NARRATIVE_TID] ,[COSTCALCULATION1] ,[COSTCALCULATION2] ,[PRODUCTCODE] ,
		[GENERATEDINADVANCE],[MATCHENTITYNO] ,
		[MATCHTRANSNO] ,[MATCHWIPSEQNO] ,[MATCHEDTOOPENITEM] ,[MATCHEDFULLY] ,
		[MARGINNO], [MARGINFLAG], [SPLITPERCENTAGE] From WORKHISTORY
		Where 				
		REFENTITYNO= @pnItemEntityNo
		and REFTRANSNO= @pnItemTransNo
		and ( REASONCODE IS NULL OR REASONCODE != '_E'))"
		
		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @pnItemTransNo int,
			  @pdtTransDate datetime,
			  @pdtPostDate datetime,
			  @nReverseTransType int,
			  @nPostPeriod int,
			  @nTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo,
			@pdtTransDate = @pdtTransDate,
			@pdtPostDate = @pdtPostDate,
			@nReverseTransType = @nReverseTransType,
			@nPostPeriod = @nPostPeriod,
			@nTransNo = @nTransNo
		
	End
	
	If (@nErrorCode = 0)
	Begin	
		
		Set @sSQLString ="update T
		Set ITEMIMPACT = null
		From #TEMPWORKHISTORY T
		Where ITEMIMPACT = 9 and MOVEMENTCLASS = 2
		and exists (SELECT 1 from WORKINPROGRESS WIP where WIP.ENTITYNO = T.ENTITYNO 
					and WIP.TRANSNO = T.TRANSNO and WIP.WIPSEQNO = T.WIPSEQNO )"
		exec	@nErrorCode = sp_executesql @sSQLString
	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update temp work history history line no'
			
		Set @sSQLString = "Update T
		Set T.HISTORYLINENO = (SELECT MAX(WH.HISTORYLINENO)+T.OLDHISTORYLINENO from WORKHISTORY WH where T.ENTITYNO = WH.ENTITYNO
							and T.TRANSNO = WH.TRANSNO and T.WIPSEQNO = WH.WIPSEQNO)
		From #TEMPWORKHISTORY T
		Join WORKHISTORY WH on  (T.ENTITYNO = WH.ENTITYNO and T.TRANSNO = WH.TRANSNO 
								and T.WIPSEQNO = WH.WIPSEQNO and T.OLDHISTORYLINENO = WH.HISTORYLINENO)"
		exec	@nErrorCode = sp_executesql @sSQLString
	End
	
	
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update work history assoc line no'
		Set @sSQLString = "			
		Update WH
		Set ASSOCLINENO = T.HISTORYLINENO, STATUS = 9									
		From WORKHISTORY WH
		Join #TEMPWORKHISTORY T on  (T.ENTITYNO = WH.ENTITYNO and T.TRANSNO = WH.TRANSNO 
								and T.WIPSEQNO = WH.WIPSEQNO and T.OLDHISTORYLINENO = WH.HISTORYLINENO)"
		exec	@nErrorCode = sp_executesql @sSQLString
	End
	
									
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
		begin
			select ' insert into work history form temp table'
			--select * from #TEMPWORKHISTORY
		end
			
		Set @sSQLString = "	
		Insert Into WORKHISTORY
		([ENTITYNO],[TRANSNO],[WIPSEQNO],
		[HISTORYLINENO], [TRANSDATE],[POSTDATE],
		[TRANSTYPE],[RATENO],[WIPCODE],[CASEID],
		[ACCTENTITYNO],[ACCTCLIENTNO],[EMPLOYEENO],
		[TOTALTIME],[TOTALUNITS],[UNITSPERHOUR],
		[CHARGEOUTRATE],[ASSOCIATENO],[INVOICENUMBER],
		[FOREIGNCURRENCY],[FOREIGNTRANVALUE],[EXCHRATE],
		[LOCALTRANSVALUE],[REFENTITYNO],[REFTRANSNO],
		[REFSEQNO],[REFACCTENTITYNO],[REFACCTDEBTORNO],
		[REASONCODE],[BILLLINENO],[EMPPROFITCENTRE],
		[CASEPROFITCENTRE],[NARRATIVENO],[SHORTNARRATIVE],
		[LONGNARRATIVE],[ASSOCLINENO],[TRANSFERDETAIL],
		[STATUS],[MOVEMENTCLASS],[COMMANDID],[ITEMIMPACT],
		[POSTPERIOD],[VARIABLEFEEAMT],[VARIABLEFEETYPE],
		[VARIABLEFEECURR],[FEECRITERIANO],[FEEUNIQUEID],
		[GLMOVEMENTNO],[QUOTATIONNO],[EMPFAMILYNO],
		[EMPOFFICECODE],[VERIFICATIONNUMBER],[LOCALCOST],
		[FOREIGNCOST],[ENTEREDQUANTITY],[DISCOUNTFLAG],
		[NARRATIVE_TID],[COSTCALCULATION1],[COSTCALCULATION2],
		[PRODUCTCODE],[GENERATEDINADVANCE],[MATCHENTITYNO],
		[MATCHTRANSNO],[MATCHWIPSEQNO],[MATCHEDTOOPENITEM],
		[MATCHEDFULLY],[MARGINNO],[MARGINFLAG],[SPLITPERCENTAGE])
		(Select 
		[ENTITYNO],[TRANSNO],[WIPSEQNO],
		[HISTORYLINENO], [TRANSDATE],[POSTDATE],
		[TRANSTYPE],[RATENO],[WIPCODE],[CASEID],
		[ACCTENTITYNO],[ACCTCLIENTNO],[EMPLOYEENO],
		[TOTALTIME],[TOTALUNITS],[UNITSPERHOUR],
		[CHARGEOUTRATE],[ASSOCIATENO],[INVOICENUMBER],
		[FOREIGNCURRENCY],[FOREIGNTRANVALUE],[EXCHRATE],
		[LOCALTRANSVALUE],[REFENTITYNO],[REFTRANSNO],
		[REFSEQNO],[REFACCTENTITYNO],[REFACCTDEBTORNO],
		[REASONCODE],[BILLLINENO],[EMPPROFITCENTRE],
		[CASEPROFITCENTRE],[NARRATIVENO],[SHORTNARRATIVE],
		[LONGNARRATIVE],[ASSOCLINENO],[TRANSFERDETAIL],
		[STATUS],[MOVEMENTCLASS],[COMMANDID],[ITEMIMPACT],
		[POSTPERIOD],[VARIABLEFEEAMT],[VARIABLEFEETYPE],
		[VARIABLEFEECURR],[FEECRITERIANO],[FEEUNIQUEID],
		[GLMOVEMENTNO],[QUOTATIONNO],[EMPFAMILYNO],
		[EMPOFFICECODE],[VERIFICATIONNUMBER],[LOCALCOST],
		[FOREIGNCOST],[ENTEREDQUANTITY],[DISCOUNTFLAG],
		[NARRATIVE_TID],[COSTCALCULATION1],[COSTCALCULATION2],
		[PRODUCTCODE],[GENERATEDINADVANCE],[MATCHENTITYNO],
		[MATCHTRANSNO],[MATCHWIPSEQNO],[MATCHEDTOOPENITEM],
		[MATCHEDFULLY],[MARGINNO],[MARGINFLAG],[SPLITPERCENTAGE]				
		From #TEMPWORKHISTORY)"
		
		exec	@nErrorCode = sp_executesql @sSQLString
	End

	-- Update the WIP Ledger Control Totals
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update WIP Ledger control total'

		SET @nLocalTransValue = 0

		Declare cWorkHistory cursor for
		Select MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, LOCALTRANSVALUE
		From #TEMPWORKHISTORY
		
		Open cWorkHistory
		Fetch Next From cWorkHistory Into @nMovementClass, @nWIPTransType, @nPostPeriod, @nLocalTransValue
		
		While @@FETCH_STATUS = 0
		Begin
			If (@nErrorCode = 0)
			Begin
				if (@nLocalTransValue != 0 or @nLocalTransValue is not null)
				Begin
				-- Call this procedure to insert/update as appropriate
					exec @nErrorCode = dbo.acw_UpdateControlTotal
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@pbCalledFromCentura = @pbCalledFromCentura,
						@pnLedger = 1,
						@pnCategory	= @nMovementClass,
						@pnType	= @nWIPTransType,
						@pnPeriodId	= @nPostPeriod,
						@pnEntityNo	= @pnItemEntityNo,
						@pnAmountToAdd = @nLocalTransValue
				End
			End
			
			Fetch Next From cWorkHistory Into @nMovementClass, @nWIPTransType, @nPostPeriod, @nLocalTransValue
		End
		Close cWorkHistory
		Deallocate cWorkHistory
	End

	-- 12181 Process the Inter-Entity transfer reversal.
	-- Add inter-entity transfer records if required - xfAddIETransferRecords( puWorkHistory )
	If @nErrorCode = 0
		and exists (Select * from SITECONTROL 
				Where CONTROLID = 'Inter-Entity Billing'
				and COLBOOLEAN = 1)
	Begin
		exec @nErrorCode = dbo.biw_ProcessInterEntityTransfers
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnItemEntityKey	= @pnItemEntityNo,
			@pnItemTransKey		= @nTransNo
	End

	-- Reverse the open item
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update open item'
	
		Set @sSQLString = "update OPENITEM
		Set CLOSEPOSTDATE = @pdtPostDate,
			CLOSEPOSTPERIOD = @nPostPeriod, 
			STATUS = 9,
			LOCALBALANCE = 0, 
			EXCHVARIANCE = 0,
			FOREIGNBALANCE = FOREIGNBALANCE * 0
		Where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnItemEntityNo	int,
						  @pnItemTransNo	int,
						  @pdtPostDate datetime,
						  @nPostPeriod int',
						  @pnItemEntityNo = @pnItemEntityNo,
						  @pnItemTransNo = @pnItemTransNo,
						  @pdtPostDate = @pdtPostDate,
						  @nPostPeriod = @nPostPeriod
						  
	End
	
	
	-- Insert update debtor history
				
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select 'insert into temp debtor history'
	
		Set @sSQLString = "
		Insert into #TEMPDEBTORHISTORY(
		[ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO], [OLDHISTORYLINENO],
		[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
		[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
		[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
		[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
		[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO])
		select 
		[ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO], [HISTORYLINENO],
		[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
		[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
		[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
		[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
		[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO]
		from DEBTORHISTORY
		Where REFENTITYNO = @pnItemEntityNo
			and REFTRANSNO = @pnItemTransNo
		ORDER BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO DESC"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnItemEntityNo	int,
						  @pnItemTransNo	int',
						  @pnItemEntityNo = @pnItemEntityNo,
						  @pnItemTransNo = @pnItemTransNo
	End
	

	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update temp history data with attributes required for reverse if movement class != 4 or Trans Type = 511'
			
		Set @sSQLString = "
		Update T
		Set TRANSDATE = @pdtTransDate,
			POSTDATE = @pdtPostDate,
			POSTPERIOD = @nPostPeriod,
			TRANSTYPE = @nReverseTransType,
			ITEMPRETAXVALUE = ITEMPRETAXVALUE * -1,
			LOCALTAXAMT = LOCALTAXAMT * -1,
			LOCALVALUE = LOCALVALUE * -1,
			EXCHVARIANCE = EXCHVARIANCE * -1,
			FOREIGNTAXAMT = Case when  T.CURRENCY is not null then T.FOREIGNTAXAMT * -1 else T.FOREIGNTAXAMT end,
			FOREIGNTRANVALUE = Case when  T.CURRENCY is not null then T.FOREIGNTRANVALUE * -1 else T.FOREIGNTRANVALUE end,
			LOCALBALANCE = Case when  T.MOVEMENTCLASS =  1 then 0 
							else Case when T.MOVEMENTCLASS =  5 then T.LOCALBALANCE + T.LOCALVALUE * -1
							else T. LOCALBALANCE end end, 
			TOTALEXCHVARIANCE = Case when  T.MOVEMENTCLASS =  1 then 0 
							else Case when T.MOVEMENTCLASS =  5 then 0 
							else TOTALEXCHVARIANCE end end, 
			FOREIGNBALANCE = Case when  T.CURRENCY is not null 
							 then case when T.MOVEMENTCLASS =  1 then 0 
							 else case when T.MOVEMENTCLASS =  5 then T.FOREIGNBALANCE + T.FOREIGNTRANVALUE * -1
							 else T.FOREIGNBALANCE end end end,
			REFENTITYNO = T.ITEMENTITYNO,
			REFTRANSNO = @nTransNo,
			ASSOCLINENO = T.OLDHISTORYLINENO,
			COMMANDID = 99,
			ITEMIMPACT = Case when  T.ITEMIMPACT = 1  then 9 else T.ITEMIMPACT end,
			GLMOVEMENTNO = null
		From #TEMPDEBTORHISTORY T
		--Join TRANSACTIONHEADER TH on (T.ITENENTITYNO = TH.ENTITYNO and T.ITEMTRANSNO = TH.TRANSNO)
		Where T.MOVEMENTCLASS != 4 or @nTransType = 511"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pdtTransDate	datetime,
						  @pdtPostDate	datetime,
						  @nPostPeriod int,
						  @nReverseTransType int,
						  @nTransType int,
						  @nTransNo int',
						  @pdtTransDate = @pdtTransDate,
						  @pdtPostDate = @pdtPostDate,
						  @nPostPeriod = @nPostPeriod,
						  @nReverseTransType = @nReverseTransType,
						  @nTransType = @nTransType,
						  @nTransNo = @nTransNo
	End
	
	
	If (@nErrorCode = 0 and @nTransType != 511)
	Begin
		If (@nDebug = 1)
			select ' update temp history data with attributes required for reverse if movement class = 4 and Trans Type != 511'
			
		Set @sSQLString = "
		Update T
		Set TRANSDATE = @pdtTransDate,
			POSTDATE = @pdtPostDate,
			POSTPERIOD = @nPostPeriod,
			TRANSTYPE = @nReverseTransType,
			ITEMPRETAXVALUE = T.ITEMPRETAXVALUE * -1,
			LOCALTAXAMT = T.LOCALTAXAMT * -1,
			LOCALVALUE = T.LOCALVALUE * -1,
			EXCHVARIANCE = T.EXCHVARIANCE * -1,
			LOCALBALANCE = OI.LOCALBALANCE + T.LOCALVALUE * -1,
			TOTALEXCHVARIANCE = OI.EXCHVARIANCE - T.EXCHVARIANCE,
			FOREIGNBALANCE = Case when  T.CURRENCY is not null 
						then T.FOREIGNBALANCE * -1 else T.FOREIGNBALANCE end,
			FOREIGNTAXAMT = Case when  T.CURRENCY is not null then T.FOREIGNTAXAMT * -1 else T.FOREIGNTAXAMT end,
			FOREIGNTRANVALUE = Case when  T.CURRENCY is not null then T.FOREIGNTRANVALUE * -1 else T.FOREIGNTRANVALUE end,
			REFENTITYNO = TH.ENTITYNO,
			REFTRANSNO = @nTransNo,
			ASSOCLINENO = T.OLDHISTORYLINENO,
			COMMANDID = 99,
			ITEMIMPACT = Case when  T.ITEMIMPACT = 1  then 9 else T.ITEMIMPACT end,
			GLMOVEMENTNO = null
		From #TEMPDEBTORHISTORY T
		Join OPENITEM OI on (OI.ITEMENTITYNO = T.ITEMENTITYNO and OI.ITEMTRANSNO = T.ITEMTRANSNO 
					and OI.ACCTENTITYNO = T.ACCTENTITYNO and OI.ACCTDEBTORNO = T.ACCTDEBTORNO)
		Join TRANSACTIONHEADER TH on (TH.ENTITYNO = T.ITEMENTITYNO and TH.TRANSNO = T.ITEMTRANSNO)
		Where T.MOVEMENTCLASS = 4"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pdtTransDate	datetime,
						  @pdtPostDate	datetime,
						  @nPostPeriod int,
						  @nReverseTransType int,
						  @nTransNo int',
						  @pdtTransDate = @pdtTransDate,
						  @pdtPostDate = @pdtPostDate,
						  @nPostPeriod = @nPostPeriod,
						  @nReverseTransType = @nReverseTransType,
						  @nTransNo = @nTransNo
	End
						  
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update debtor history histroy line nos in temp table'

		Set @sSQLString = "					
		Update T
		Set T.HISTORYLINENO = (SELECT MAX(DH.HISTORYLINENO)+TROW.NEWBASEHISTLINENO
					from DEBTORHISTORY DH 
					where T.ITEMENTITYNO = DH.ITEMENTITYNO
					and T.ITEMTRANSNO = DH.ITEMTRANSNO 
					and T.ACCTENTITYNO = DH.ACCTENTITYNO
					and T.ACCTDEBTORNO = DH.ACCTDEBTORNO)
		From #TEMPDEBTORHISTORY T
		join (SELECT ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO,
			ROW_NUMBER() OVER (PARTITION BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO ORDER BY HISTORYLINENO DESC) AS NEWBASEHISTLINENO
			From #TEMPDEBTORHISTORY) AS TROW ON (TROW.ITEMENTITYNO = T.ITEMENTITYNO
								AND TROW.ITEMTRANSNO = T.ITEMTRANSNO
								AND TROW.ACCTENTITYNO = T.ACCTENTITYNO
								AND TROW.ACCTDEBTORNO = T.ACCTDEBTORNO
								AND TROW.HISTORYLINENO = T.HISTORYLINENO)"
		exec @nErrorCode=sp_executesql @sSQLString		
	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update assoc line of debtor history in temp table'
		
		Set @sSQLString = "		
		Update DH
		Set ASSOCLINENO = T.HISTORYLINENO,
		STATUS = 9
		From DEBTORHISTORY DH
		Join #TEMPDEBTORHISTORY T on (T.ITEMENTITYNO = DH.ITEMENTITYNO
							and T.ITEMTRANSNO = DH.ITEMTRANSNO and T.ACCTENTITYNO = DH.ACCTENTITYNO 
							and T.ACCTDEBTORNO = DH.ACCTDEBTORNO and T.OLDHISTORYLINENO = DH.HISTORYLINENO)"
		
		exec @nErrorCode=sp_executesql @sSQLString
	End
	
	-- Post Debtor History 
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select 'insert into debtor history from temp table'

		Set @sSQLString = "						
		Insert into DEBTORHISTORY
		([ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO],
		[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
		[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
		[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
		[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
		[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO])
		(Select 
		[ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO],
		[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
		[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
		[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
		[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
		[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO]
		from #TEMPDEBTORHISTORY)"
		
		exec @nErrorCode=sp_executesql @sSQLString
	End
	
	-- xfReverseCreditTakenUp
	if (@nErrorCode = 0 and @nTransType != 511)
	Begin
		If (@nDebug = 1)
			select ' update OpenItem for movement class = 4 and transtype != 511'
			
		Set @sSQLString = "Update OI
		Set	OI.EXCHVARIANCE = OI.EXCHVARIANCE - T.EXCHVARIANCE,
			OI.FOREIGNBALANCE = case when OI.CURRENCY is not null then OI.FOREIGNBALANCE + T.FOREIGNTRANVALUE else OI.FOREIGNBALANCE end,
			OI.CLOSEPOSTPERIOD = case when OI.LOCALBALANCE + T.LOCALVALUE = 0 then @nPostPeriod else 999999 end,
			OI.CLOSEPOSTDATE = case when OI.LOCALBALANCE + T.LOCALVALUE = 0 then @pdtPostDate else '9999-12-31' end,
			OI.LOCALBALANCE = OI.LOCALBALANCE + T.LOCALVALUE
		From OPENITEM OI
		Join #TEMPDEBTORHISTORY T on (	T.ITEMENTITYNO = OI.ITEMENTITYNO 
						and T.ITEMTRANSNO = OI.ITEMTRANSNO
						and T.ACCTENTITYNO = OI.ACCTENTITYNO 
						and T.ACCTDEBTORNO = OI.ACCTDEBTORNO)
		Where T.MOVEMENTCLASS = 4"
		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pdtPostDate	datetime,
					  @nPostPeriod int',
					  @pdtPostDate = @pdtPostDate,
					  @nPostPeriod = @nPostPeriod

	End
	
	-- xfReverseOpenItemCase
	 --Reverse any Case level information for MOVEMENTCLASS = 4 and @nTransType != 511
	if (@nErrorCode = 0 and @nTransType != 511)
	Begin
		If (@nDebug = 1)
			select ' update debtor history case for movement class = 4 and transtype != 511'
			
		Set @sSQLString = "INSERT INTO DEBTORHISTORYCASE (ITEMTRANSNO, ITEMENTITYNO, HISTORYLINENO,
				CASEID, ACCTDEBTORNO, ACCTENTITYNO,
				FOREIGNTRANVALUE, LOCALVALUE)
				SELECT REV.ITEMTRANSNO, REV.ITEMENTITYNO, T.HISTORYLINENO,
				REV.CASEID, REV.ACCTDEBTORNO, REV.ACCTENTITYNO,
				REV.FOREIGNTRANVALUE * -1, REV.LOCALVALUE * -1
				FROM DEBTORHISTORYCASE REV
				JOIN #TEMPDEBTORHISTORY T on (T.ITEMENTITYNO = REV.ITEMENTITYNO and 
								T.ITEMTRANSNO = REV.ITEMTRANSNO and
								T.ACCTDEBTORNO = REV.ACCTDEBTORNO and
								T.ACCTENTITYNO = REV.ACCTENTITYNO and
								T.ASSOCLINENO = REV.HISTORYLINENO and
								T.MOVEMENTCLASS = 4)"
			
		exec @nErrorCode=sp_executesql @sSQLString
	End
	
	-- xfReverseOpenItemCase
	If (@nErrorCode = 0 and @nTransType != 511)
	Begin
		If (@nDebug = 1)
			select ' update open item case for movementclass = 4 and trans type != 511'
			
		Set @sSQLString = "UPDATE O
		SET O.LOCALBALANCE = O.LOCALBALANCE + DHC.LOCALVALUE, 
			O.FOREIGNBALANCE = O.FOREIGNBALANCE + DHC.FOREIGNTRANVALUE
		FROM OPENITEMCASE O
		JOIN DEBTORHISTORYCASE DHC on (DHC.ITEMENTITYNO = O.ITEMENTITYNO
						AND 	DHC.ITEMTRANSNO = O.ITEMTRANSNO
						AND 	DHC.ACCTENTITYNO = O.ACCTENTITYNO
						AND 	DHC.ACCTDEBTORNO =  O.ACCTDEBTORNO
						AND	DHC.CASEID = O.CASEID)
		JOIN #TEMPDEBTORHISTORY T on (DHC.ITEMENTITYNO = T.ITEMENTITYNO and DHC.ITEMTRANSNO = T.ITEMTRANSNO and
						DHC.ACCTDEBTORNO = T.ACCTDEBTORNO and DHC.ACCTENTITYNO = T.ACCTENTITYNO and
						DHC.HISTORYLINENO = T.HISTORYLINENO)
		WHERE 	T.MOVEMENTCLASS = 4"

		exec @nErrorCode=sp_executesql @sSQLString
	End
	
	-- Update the Debtor's Ledger Control Totals
	-- xfUpdateDHControlTotals
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update the debtor ledger control totals'
			
		Declare cDebtorHistory cursor for
		Select MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, EXCHVARIANCE, LOCALTAXAMT, LOCALVALUE
		From #TEMPDEBTORHISTORY
		
		Open cDebtorHistory
		Fetch Next From cDebtorHistory Into @nMovementClass, @nDebtorTransType, @nPostPeriod, @nExchVariance, @nLocalTaxAmt, @nLocalValue
		
		While @@FETCH_STATUS = 0
		Begin
			If (@nErrorCode = 0 AND @nLocalValue != 0 AND @nLocalValue IS NOT NULL)
			Begin
				-- Call this procedure to insert/update as appropriate
				exec @nErrorCode = dbo.acw_UpdateControlTotal
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@pbCalledFromCentura = @pbCalledFromCentura,
					@pnLedger = 2,
					@pnCategory	= @nMovementClass,
					@pnType	= @nDebtorTransType,
					@pnPeriodId	= @nPostPeriod,
					@pnEntityNo	= @pnItemEntityNo,
					@pnAmountToAdd = @nLocalValue	
			End
			
			If (@nErrorCode = 0 AND @nExchVariance != 0 AND @nExchVariance IS NOT NULL)
			Begin
					-- Call this procedure to insert/update as appropriate
					exec @nErrorCode = dbo.acw_UpdateControlTotal
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@pbCalledFromCentura = @pbCalledFromCentura,
						@pnLedger = 2,
						@pnCategory	= 9,
						@pnType	= @nDebtorTransType,
						@pnPeriodId	= @nPostPeriod,
						@pnEntityNo	= @pnItemEntityNo,
					@pnAmountToAdd = @nExchVariance	
			End
			
			If (@nErrorCode = 0 and @nLocalTaxAmt != 0 and @nLocalTaxAmt is not null)
				Begin
					If (@nMovementClass = 2 or @nMovementClass = 4)
					Begin
						Set @nLocalTaxAmt = @nLocalTaxAmt * -1
					End
					-- Call this procedure to insert/update as appropriate
					exec @nErrorCode = dbo.acw_UpdateControlTotal
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@pbCalledFromCentura = @pbCalledFromCentura,
						@pnLedger = 3,
						@pnCategory	= @nMovementClass,
						@pnType	= @nDebtorTransType,
						@pnPeriodId	= @nPostPeriod,
						@pnEntityNo	= @pnItemEntityNo,
					@pnAmountToAdd = @nLocalTaxAmt
				End
			
			Fetch Next From cDebtorHistory Into @nMovementClass, @nDebtorTransType, @nPostPeriod, @nExchVariance, @nLocalTaxAmt, @nLocalValue
		End
		Close cDebtorHistory
		Deallocate cDebtorHistory
	End
	
	-- update account
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select 'adjust the account balance'

		Set @sSQLString = "Update A
				Set A.BALANCE = ISNULL(A.BALANCE,0) + ISNULL(T.TOTALADJUSTMENT,0)
				From ACCOUNT A
				JOIN (SELECT SUM(ISNULL(LOCALVALUE,0)) AS TOTALADJUSTMENT, ACCTENTITYNO, ACCTDEBTORNO
					FROM #TEMPDEBTORHISTORY
					GROUP BY ACCTENTITYNO, ACCTDEBTORNO) AS T on (A.ENTITYNO =  T.ACCTENTITYNO 
											and A.NAMENO = T.ACCTDEBTORNO)"

		exec @nErrorCode=sp_executesql @sSQLString
	End
	
		
	-- reinstate associated debtor
	
			
	If (@nErrorCode = 0)
	Begin
		if (@nReverseTransType = 513)
		Begin
			If (@nDebug = 1)
				select ' update open item'
			
			Set @sSQLString = "update OI
			Set LOCALBALANCE = DHTOTAL.LOCALTOTAL,
			FOREIGNBALANCE = DHTOTAL.FOREIGNTOTAL,
			ASSOCOPENITEMNO = null,
			CLOSEPOSTDATE = '31-Dec-9999',
			CLOSEPOSTPERIOD = 999999							
			From OPENITEM OI
			Join OPENITEM OI1 on (OI.OPENITEMNO = OI1.ASSOCOPENITEMNO and OI1.ITEMTRANSNO = @pnItemTransNo and OI1.ITEMENTITYNO = @pnItemEntityNo)
			join (select SUM(ISNULL(LOCALVALUE,0)) AS LOCALTOTAL, SUM(ISNULL(FOREIGNTRANVALUE,0)) AS FOREIGNTOTAL, ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO   
				From DEBTORHISTORY 
				group by ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO ) DHTOTAL	ON (DHTOTAL.ITEMENTITYNO = OI.ITEMENTITYNO 
														and DHTOTAL.ITEMTRANSNO = OI.ITEMTRANSNO
														and DHTOTAL.ACCTENTITYNO = OI.ACCTENTITYNO 
														and DHTOTAL.ACCTDEBTORNO = OI.ACCTDEBTORNO)"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnItemEntityNo	int,
					  @pnItemTransNo	int',
					  @pnItemEntityNo = @pnItemEntityNo,
					  @pnItemTransNo = @pnItemTransNo
		End
		
	End
	
	-- insert tax history
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
				select 'insert tax history'
		
		Set @sSQLString = "	
		Insert into TAXHISTORY(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO,
								TAXCODE, TAXRATE, TAXABLEAMOUNT, TAXAMOUNT, COUNTRYCODE, REFENTITYNO, REFTRANSNO)
		(Select TH.ITEMENTITYNO, TH.ITEMTRANSNO, TH.ACCTENTITYNO,
				TH.ACCTDEBTORNO, DH.HISTORYLINENO,
				TH.TAXCODE, TH.TAXRATE, TH.TAXABLEAMOUNT * -1,
				TH.TAXAMOUNT * -1, TH.COUNTRYCODE,
				@pnItemEntityNo, @nTransNo
		From TAXHISTORY TH
		join DEBTORHISTORY DH on 
					(DH.REFENTITYNO =  @pnItemEntityNo
					AND		DH.REFTRANSNO = @nTransNo
					AND		DH.ITEMENTITYNO = TH.ITEMENTITYNO
					AND		DH.ITEMTRANSNO = TH.ITEMTRANSNO
					AND		DH.ACCTENTITYNO = TH.ACCTENTITYNO
					AND		DH.ACCTDEBTORNO = TH.ACCTDEBTORNO
					AND		DH.ASSOCLINENO = TH.HISTORYLINENO))"
							
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnItemEntityNo	int,
					  @nTransNo	int',
					  @pnItemEntityNo = @pnItemEntityNo,
					  @nTransNo = @nTransNo
	End
	
	
	-- Unlink instalment if exists
	If (@nErrorCode = 0)
	Begin
		If (@nTransType != 516 and @nTransType != 519)
		Begin
			if exists (select 1 from SITECONTROL where CONTROLID = 'Quotations' and COLBOOLEAN = 1)
			Begin	
				If (@nDebug = 1)
					select ' unlink instalment if exists'	

				Set @sSQLString = "	
				Update Q
				Set STATUS = 7402
				From Quotation Q
				Join INSTALMENT I on (Q.QUOTATIONNO = I.QUOTATIONNO and I.ENTITYNO = @pnItemEntityNo 
										and I.TRANSNO = @pnItemTransNo and I.QUOTATIONNO is not null )"
				
				exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnItemEntityNo	int,
					  @pnItemTransNo	int',
					  @pnItemEntityNo = @pnItemEntityNo,
					  @pnItemTransNo = @pnItemTransNo
			End
		End
		
	End
	
	-- Create WIP Prepayment
	If @nErrorCode = 0 and 
	exists (select * from SITECONTROL WHERE CONTROLID = 'Cash Accounting' AND COLBOOLEAN = 1) and 
	exists (select 	1 
		from	SITECONTROL 
		where   CONTROLID = 'FI WIP Payment Preference'	
		and	case when isnull(PATINDEX('%PD%', COLCHARACTER), 0) > 0 then 1 else 0 end = 1)
	Begin	
		-- Note: Reverse a credit full bill involves reverse the bills (multiple bills if multi debtors) and associated credit notes
		INSERT INTO WIPPAYMENT (ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE,
		LOCALTRANSVALUE, LOCALBALANCE, REFENTITYNO, REFTRANSNO)

		SELECT WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WP2.PAYMENTSEQNO+1, WP.WIPCODE,
		CASE WHEN WH.TRANSTYPE = 511 THEN WP.LOCALBALANCE * -1 ELSE WP.LOCALTRANSVALUE*-1 END LOCALTRANSVALUE, 
		CASE WHEN WH.TRANSTYPE = 511 THEN 0 ELSE WP3.LOCALBALANCE + WP.LOCALTRANSVALUE*-1 END LOCALBALANCE,
		@nItemEntityNo, @nTransNo
		from WIPPAYMENT WP
		-- Get the max wippayment.paymentseqno
		JOIN (	Select WP1.ENTITYNO, WP1.TRANSNO, WP1.WIPSEQNO, WP1.HISTORYLINENO, WP1.ACCTDEBTORNO, MAX(WP1.PAYMENTSEQNO) PAYMENTSEQNO
			from DEBTORHISTORY DH
			JOIN WORKHISTORY WH  ON WH.REFENTITYNO = DH.ITEMENTITYNO        
						AND WH.REFTRANSNO = DH.ITEMTRANSNO 
			JOIN WIPPAYMENT WP1 ON (WP1.ENTITYNO = WH.ENTITYNO
					AND WP1.TRANSNO = WH.TRANSNO
					AND WP1.WIPSEQNO = WH.WIPSEQNO
					AND WP1.HISTORYLINENO = WH.HISTORYLINENO
					AND WP1.ACCTDEBTORNO = DH.ACCTDEBTORNO ) 
			WHERE  DH.ITEMENTITYNO = @pnItemEntityNo
			AND DH.REFTRANSNO = @pnItemTransNo
			AND  WH.MOVEMENTCLASS = 2
			group by WP1.ENTITYNO, WP1.TRANSNO, WP1.WIPSEQNO, WP1.HISTORYLINENO, WP1.ACCTDEBTORNO
			) WP2 ON (WP2.ENTITYNO = WP.ENTITYNO
				AND WP2.TRANSNO = WP.TRANSNO
				AND WP2.WIPSEQNO = WP.WIPSEQNO
				AND WP2.ACCTDEBTORNO = WP.ACCTDEBTORNO
				AND WP2.HISTORYLINENO = WP.HISTORYLINENO) 
		-- Get the transaction type so we can test if it is a bill or a credit note
		JOIN WORKHISTORY WH ON WH.ENTITYNO = WP2.ENTITYNO
				AND WH.TRANSNO  = WP2.TRANSNO
				AND WH.WIPSEQNO = WP2.WIPSEQNO
				AND WH.HISTORYLINENO = WP2.HISTORYLINENO
		-- The current row with the latest balance to be updated					
		JOIN WIPPAYMENT WP3 on (WP3.ENTITYNO = WP2.ENTITYNO
					and WP3.TRANSNO = WP2.TRANSNO
					and WP3.WIPSEQNO = WP2.WIPSEQNO
					and WP3.HISTORYLINENO = WP2.HISTORYLINENO
					AND WP3.ACCTDEBTORNO = WP2.ACCTDEBTORNO
					AND WP3.PAYMENTSEQNO = WP2.PAYMENTSEQNO )
		WHERE WP.REFENTITYNO = @pnItemEntityNo
		AND WP.REFTRANSNO = @pnItemTransNo
		AND WP.PAYMENTSEQNO <> 1

		Select @nErrorCode = @@error
	End
	
	-- Process GL Interface
	If (@nErrorCode = 0 and @nGLJournalCreation = 1)
	Begin
		If (@nDebug = 1)
		select ' process GL Interface'
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
			
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select 'reconcile WIP Items'
			
		exec @nErrorCode = dbo.biw_ReconcileWIPItems
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture	= @psCulture,
		@pbCalledFromCentura = @pbCalledFromCentura,
		@pnItemEntityNo	= @pnItemEntityNo, 
		@pnItemTransNo	= @nTransNo
	End
	
	If (@nErrorCode = 0)
		commit transaction
	Else
		rollback transaction
End

return @nErrorCode
go

grant execute on dbo.[biw_ReverseBill]  to public
go
