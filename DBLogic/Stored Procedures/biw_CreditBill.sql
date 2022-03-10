-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_CreditBill] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_CreditBill]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_CreditBill].'
	drop procedure dbo.[biw_CreditBill]
end
print '**** Creating procedure dbo.[biw_CreditBill]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go
SET CONCAT_NULL_YIELDS_NULL OFF
go 

create procedure dbo.[biw_CreditBill]
				@pnUserIdentityId		int,				-- Mandatory
				@psCulture				nvarchar(10) 		= null,
				@pbCalledFromCentura	bit					= 0,
				@pnItemEntityNo			int,				-- Mandatory
				@pnItemTransNo			int,				-- Mandatory
				@pnEmployeeNo			int,				-- Mandatory
				@pdtTransDate			datetime,			-- Mandatory
				@pdtPostDate			datetime,			-- Mandatory - The transaction date entered
				@psCreditReasonCode		nvarchar(12),			-- Mandatory
				@psRegarding			nvarchar(254),			-- Mandatory
				@psStatementRef			nvarchar(254),			-- Mandatory
				@pnLanguageCode			int				= null,
				@psWriteDownReasonCode		nvarchar(12)			= null,
				@psCreditItemNoList		xml				= null

as
-- PROCEDURE :	biw_CreditBill
-- VERSION :	39
-- DESCRIPTION:	A procedure that credits the selected bill.
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATIONS
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 01/04/2010	KR	RFC8299		1	Procedure created
-- 04/08/2010	KR	RFC9280		2	fix issues
-- 20/08/2010	KR	RFC9608		3	fix issues
-- 28/08/2010	KR	RFC9608		4	fixed the problem where credit bill created cannot be reversed
-- 01/09/2010	KR	RFC9280		5	credit bill issues with takenup, write up and write down have been fixed
-- 16/05/2011	AT	RFC10630	6	Fixed issue with bill line local tax having incorrect sign.
-- 24/05/2011	AT	RFC10696	7	Swap discount/wip item movement class/command id.
-- 25/05/2011	AT	RFC10703	8	Set closed post date on original debit item. Set all post dates to today's date and time.
-- 28/06/2011	KR	RFC10905	9	Update ACCOUNT.BALANCE correctly for split bills
-- 15/07/2011	DL	SQA19791	10	Extend variable referencing CONTROLTOTAL.TOTAL to dec(13,2) instead of dec(11,2)
-- 25/07/2011	JC	RFC9599		11	Return the new OPENITEMNO
-- 28 Jul 2011	KR	RFC11034	12	tax history foreign key error fix
-- 20 Aug 2011  DV      RFC11069        13	Insert IDENTITYID value in ACTIVITYREQUEST table
-- 25/08/2011	KR	RFC11054	14	Fix tax history so that it gets written against the credit notes. 
-- 11/10/2011	KR	RFC100624	15	Fixed tax history merge issue.
-- 19/10/2011	KR	RFC100624	16	Write OPENITEMTAX even if the TAXAMOUNT is 0
-- 26/10/2011	AT	RFC10168	17	Add call to process inter-entity billing.
-- 12/12/2011	AT	RFC11681	18	Fix tax history so it picks up appropriate key from debtor history.
--						Removed erroneous update of LOCALBALANCE on original OpenItem when prepayment applied.
-- 16/12/2011	AT	RFC11657	19	Pass correct TransNo to biw_ProcessInterEntityTransfer.
-- 20/02/2012	AT	RFC11570	20	Fixed Open Item number generated for Employee's office.
--					21	Clean up ControlTotal updates.
-- 24/02/2012	AT	RFC11976	22	Fix tax history picking up old reversed Open Item.
-- 30/03/2012	KR	RFC12081	23	Currency, ExchRate & ForcePayOut were inserted into the DEBTORHISTORY of the credit open item
-- 08/06/2012	AT	RFC12386	24	Implement SQA19245 affecting adjusted WIP, fixing error when write down wip option is selected.
--									Fixed WORKHISTORY.HISTORYLINENO sequencing problem
--									Simplify set write down attribute logic into 1 statement.
-- 27/07/2012	KR	RFC12525	25	modified @nItemNoTo type from int to decimal to match the db
-- 20/03/2013	AT	RFC13225	26	Added pre-processing to check if item already credited.
-- 25/10/2013	AT	RFC27810	27	Fixed letter generation request.
-- 18/05/2015	LP	RFC46602	28	Fully-crediting a bill with credit applied should update WIPPAYMENT table
-- 21/05/2015	LP	RFC46602	29	Use TransNo from new TRANSACTIONHEADER row as the REFTRANSNO for WIPPAYMENT rows
-- 27/05/2015	DL	RFC46602	30	Create WIPPAYMENT rows for the credit note that created by the Credit full bill
-- 20 Oct 2015  MS      R53933          31      Changed size from decimal(8,4) to decimal(11,4) for ExchRate cols
-- 09/11/2015   MS      R43311          32      Fix Writedown issue with bill in advance wip
-- 08/08/2016	DL	R63741 		33	Zero amount WIPPAYMENT rows unnecessarily created for partial payments allocated to Invoices 
-- 29/12/2016   AK      R57163          34      Fix Missing TaxCode issue
-- 25/07/2017	DV	RFC71750	35	Added check for ItemEntityNo and ItemTransNo when updating openitem.
-- 24/10/2017	AK	R72645	        36	Make compatible with case sensitive server with case insensitive database.
-- 07 Feb 2018  MS      R73082          37      Added logic to use next available OPENITEMNO rather than throwing error
-- 31 May 2019  MS      DR-45655        38      Added columns ForeignTaxableAmount, ForeignTaxAmount and Currency for OPENITEMTAX
-- 27 Aug 2019  AK	DR-45752	39 pull out the logic to check biw_ReconcileDebtorItems

Set nocount on

--create temp tables
If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPCREDITOPENITEM')
Begin
	delete from #TEMPCREDITOPENITEM
End
Else
Begin
	CREATE TABLE #TEMPCREDITOPENITEM
	(
	[SEQNO] [INT] IDENTITY,
	[ITEMENTITYNO] [int] NOT NULL,
	[ITEMTRANSNO] [int] NOT NULL,
	[ACCTENTITYNO] [int] NOT NULL,
	[ACCTDEBTORNO] [int] NOT NULL,
	[ACTION] [nvarchar](2) collate database_default NULL,
	[OPENITEMNO] [nvarchar](12) collate database_default  NOT NULL,
	[OLDOPENITEMNO] [nvarchar](12) collate database_default  NOT NULL,
	[ITEMNO]	[int] NULL,
	[ITEMDATE] [datetime] NULL,
	[POSTDATE] [datetime] NULL,
	[POSTPERIOD] [int] NULL,
	[CLOSEPOSTDATE] [datetime] NULL,
	[CLOSEPOSTPERIOD] [int] NULL,
	[STATUS] [smallint] NULL,
	[ITEMTYPE] [int] NULL,
	[BILLPERCENTAGE] [decimal](5, 2) NULL,
	[EMPLOYEENO] [int] NULL,
	[EMPPROFITCENTRE] [nvarchar](6) collate database_default NULL,
	[CURRENCY] [nvarchar](3) collate database_default NULL,
	[EXCHRATE] [decimal](11, 4) NULL,
	[ITEMPRETAXVALUE] [decimal](11, 2) NULL,
	[LOCALTAXAMT] [decimal](11, 2) NULL,
	[LOCALVALUE] [decimal](11, 2) NULL,
	[FOREIGNTAXAMT] [decimal](11, 2) NULL,
	[FOREIGNVALUE] [decimal](11, 2) NULL,
	[LOCALBALANCE] [decimal](11, 2) NULL,
	[FOREIGNBALANCE] [decimal](11, 2) NULL,
	[EXCHVARIANCE] [decimal](11, 2) NULL,
	[STATEMENTREF] [nvarchar](254) collate database_default NULL,
	[REFERENCETEXT] [nvarchar](254) collate database_default NULL,
	[NAMESNAPNO] [int] NULL,
	[BILLFORMATID] [smallint] NULL,
	[BILLPRINTEDFLAG] [decimal](1, 0) NULL,
	[REGARDING] [nvarchar](254) collate database_default NULL,
	[SCOPE] [nvarchar](254) collate database_default NULL,
	[LANGUAGE] [int] NULL,
	[ASSOCOPENITEMNO] [nvarchar](12) collate database_default NULL,
	[LONGREGARDING] [ntext] NULL,
	[LONGREFTEXT] [ntext] NULL,
	[IMAGEID] [int] NULL,
	[FOREIGNEQUIVCURRCY] [nvarchar](3) collate database_default NULL,
	[FOREIGNEQUIVEXRATE] [decimal](11, 4) NULL,
	[ITEMDUEDATE] [datetime] NULL,
	[PENALTYINTEREST] [decimal](5, 2) NULL,
	[LOCALORIGTAKENUP] [decimal](11, 2) NULL,
	[FOREIGNORIGTAKENUP] [decimal](11, 2) NULL,
	[REFERENCETEXT_TID] [int] NULL,
	[REGARDING_TID] [int] NULL,
	[SCOPE_TID] [int] NULL,
	[INCLUDEONLYWIP] [nvarchar](1) collate database_default NULL,
	[PAYFORWIP] [nvarchar](1) collate database_default NULL,
	[PAYPROPERTYTYPE] [nchar](1) collate database_default NULL,
	[RENEWALDEBTORFLAG] [decimal](1, 0) NULL,
	[LOGUSERID] [nvarchar](50) collate database_default NULL,
	[LOGIDENTITYID] [int] NULL,
	[LOGTRANSACTIONNO] [int] NULL,
	[LOGDATETIMESTAMP] [datetime] NULL,
	[LOGAPPLICATION] [nvarchar](128) collate database_default NULL,
	[LOGOFFICEID] [int] NULL,
	[CASEPROFITCENTRE] [nvarchar](6) collate database_default NULL,
	[LOCKIDENTITYID] [int] NULL,
	[MAINCASEID] [int] NULL
	)
End

If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPOPENITEM')
Begin
	delete from #TEMPOPENITEM
End
Else
Begin
	CREATE TABLE #TEMPOPENITEM
	(
	[SEQNO] [INT] IDENTITY,
	[ITEMENTITYNO] [int] NOT NULL,
	[ITEMTRANSNO] [int] NOT NULL,
	[ACCTENTITYNO] [int] NOT NULL,
	[ACCTDEBTORNO] [int] NOT NULL,
	[ACTION] [nvarchar](2) collate database_default NULL,
	[OPENITEMNO] [nvarchar](12) collate database_default  NOT NULL,
	[OLDOPENITEMNO] [nvarchar](12) collate database_default  NOT NULL,
	[ITEMDATE] [datetime] NULL,
	[POSTDATE] [datetime] NULL,
	[POSTPERIOD] [int] NULL,
	[CLOSEPOSTDATE] [datetime] NULL,
	[CLOSEPOSTPERIOD] [int] NULL,
	[STATUS] [smallint] NULL,
	[ITEMTYPE] [int] NULL,
	[BILLPERCENTAGE] [decimal](5, 2) NULL,
	[EMPLOYEENO] [int] NULL,
	[EMPPROFITCENTRE] [nvarchar](6) collate database_default NULL,
	[CURRENCY] [nvarchar](3) collate database_default NULL,
	[EXCHRATE] [decimal](11, 4) NULL,
	[ITEMPRETAXVALUE] [decimal](11, 2) NULL,
	[LOCALTAXAMT] [decimal](11, 2) NULL,
	[LOCALVALUE] [decimal](11, 2) NULL,
	[FOREIGNTAXAMT] [decimal](11, 2) NULL,
	[FOREIGNVALUE] [decimal](11, 2) NULL,
	[LOCALBALANCE] [decimal](11, 2) NULL,
	[FOREIGNBALANCE] [decimal](11, 2) NULL,
	[EXCHVARIANCE] [decimal](11, 2) NULL,
	[STATEMENTREF] [nvarchar](254) collate database_default NULL,
	[REFERENCETEXT] [nvarchar](254) collate database_default NULL,
	[NAMESNAPNO] [int] NULL,
	[BILLFORMATID] [smallint] NULL,
	[BILLPRINTEDFLAG] [decimal](1, 0) NULL,
	[REGARDING] [nvarchar](254) collate database_default NULL,
	[SCOPE] [nvarchar](254) collate database_default NULL,
	[LANGUAGE] [int] NULL,
	[ASSOCOPENITEMNO] [nvarchar](12) collate database_default NULL,
	[LONGREGARDING] [ntext] NULL,
	[LONGREFTEXT] [ntext] NULL,
	[IMAGEID] [int] NULL,
	[FOREIGNEQUIVCURRCY] [nvarchar](3) collate database_default NULL,
	[FOREIGNEQUIVEXRATE] [decimal](11, 4) NULL,
	[ITEMDUEDATE] [datetime] NULL,
	[PENALTYINTEREST] [decimal](5, 2) NULL,
	[LOCALORIGTAKENUP] [decimal](11, 2) NULL,
	[FOREIGNORIGTAKENUP] [decimal](11, 2) NULL,
	[REFERENCETEXT_TID] [int] NULL,
	[REGARDING_TID] [int] NULL,
	[SCOPE_TID] [int] NULL,
	[INCLUDEONLYWIP] [nvarchar](1) collate database_default NULL,
	[PAYFORWIP] [nvarchar](1) collate database_default NULL,
	[PAYPROPERTYTYPE] [nchar](1) collate database_default NULL,
	[RENEWALDEBTORFLAG] [decimal](1, 0) NULL,
	[LOGUSERID] [nvarchar](50) collate database_default NULL,
	[LOGIDENTITYID] [int] NULL,
	[LOGTRANSACTIONNO] [int] NULL,
	[LOGDATETIMESTAMP] [datetime] NULL,
	[LOGAPPLICATION] [nvarchar](128) collate database_default NULL,
	[LOGOFFICEID] [int] NULL,
	[CASEPROFITCENTRE] [nvarchar](6) collate database_default NULL,
	[LOCKIDENTITYID] [int] NULL,
	[MAINCASEID] [int] NULL
	)
End

If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPWORKHISTORY')
Begin
	delete from #TEMPWORKHISTORY
End
Else
Begin
	CREATE TABLE #TEMPWORKHISTORY
	(
	[SEQNO] [INT] IDENTITY,
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
	[MARGINNO] [int] NULL
	)
End

If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPDEBTORHISTORY')
Begin
	delete from #TEMPDEBTORHISTORY
End
Else
Begin	
	Create table #TEMPDEBTORHISTORY
	([SEQNO] [INT] IDENTITY,
	[ITEMENTITYNO] [int] NOT NULL,
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

If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPCASEID')
Begin
	delete from #TEMPCASEID
End
Else
Begin
	Create table #TEMPCASEID ( [CASEID] [int], [ISMAINCASE] [bit])
End	

If exists(select * from tempdb.dbo.sysobjects where name = '#TEMPBALANCE')
Begin
	delete from #TEMPBALANCE
End
Else
Begin
	Create table #TEMPBALANCE ( [BALANCE] [decimal](11, 2) NULL,
					[ENTITYNO] int,
					[NAMENO] int )
End


Declare	@bWriteDownWIP bit
Declare	@nErrorCode int
Declare	@sSQLString nvarchar(MAX)
Declare	@nPostPeriod int
--Declare @nRecordCount int
Declare @sDraftPrefix nvarchar(4)
Declare @nOfficeId int
Declare @nFirstItemNoOffice int
Declare @sItemNoPrefix nvarchar(4)
Declare @nItemNoTo decimal(10,0)
Declare @sOfficeDescription nvarchar(80)
Declare @nGLJournalCreation int
Declare @nGLStatus int
Declare @sCreditNoteNos nvarchar(2000)
Declare @bEnterOpenItemNo bit
Declare @bARForPrepayments bit
Declare @bQuotations bit
Declare @nCreditBillLetterGen int
Declare @nTransNo int

Declare @nSource int
Declare @nDebug int
Declare @nReverseTransType int
Declare @nMovementClass int
Declare @nTransType int
Declare @nControlTotal decimal(13,2)
Declare @nLocalTransValue decimal(12,2)
Declare @nExchVariance decimal(12,2)
Declare @nLocalTaxAmt decimal(12,2)
Declare @nInstalmentNo int
Declare @nExchRate decimal(12,2)
Declare @nLocalAmt decimal(12,2)
Declare @nQuotationNo int
Declare @nResult int

Declare @nCreditNoteEvent int
Declare @nForeignAmt decimal(12,2)
Declare @nDHCount int
Declare @SumTotalValue decimal(12,2)
Declare @nLocalValue decimal(12,2)
Declare @dtCurrentDate datetime
Declare @sAlertXML nvarchar(400)

Set @nErrorCode = 0
Set @nDebug = 0
Set @dtCurrentDate = getdate()

If (@nErrorCode = 0)
Begin
	If exists (Select * from OPENITEM 
				Where ITEMENTITYNO = @pnItemEntityNo 
				and ITEMTRANSNO = @pnItemTransNo
				and ASSOCOPENITEMNO is not null)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC110', 'Debit Note has already been credited. Credit Note has been issued against this Debit Note. A second Credit Note cannot be issued.',null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

If (@nErrorCode = 0)
Begin
	If (@psWriteDownReasonCode is not null and @psWriteDownReasonCode != '' )
		Set @bWriteDownWIP = 1
		
	if (@nDebug = 1)
		select '-- get site control values'
	
	Set @sSQLString = "
	Select @sDraftPrefix = isnull(COLCHARACTER,'D')
	From SITECONTROL
	Where CONTROLID = 'DRAFTPREFIX'"

	exec	@nErrorCode = sp_executesql @sSQLString,
	N'@sDraftPrefix	nvarchar(4) 			OUTPUT',
	@sDraftPrefix = @sDraftPrefix	OUTPUT
	
	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "
		Select @nGLJournalCreation = isnull(COLINTEGER,0)
		From SITECONTROL
		Where CONTROLID = 'GL Journal Creation'"

		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@nGLJournalCreation	int 			OUTPUT',
		@nGLJournalCreation = @nGLJournalCreation	OUTPUT
	End
	
	
	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "
		Select @bEnterOpenItemNo = isnull(COLBOOLEAN,0)
		From SITECONTROL
		Where CONTROLID = 'Enter Open Item No.'"

		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@bEnterOpenItemNo	bit 			OUTPUT',
		@bEnterOpenItemNo = @bEnterOpenItemNo	OUTPUT
	End
	
	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "
		Select @bQuotations = isnull(COLBOOLEAN,0)
		From SITECONTROL
		Where CONTROLID = 'Quotations'"

		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@bQuotations	bit 			OUTPUT',
		@bQuotations = @bQuotations	OUTPUT
	End
	
	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "
		Select @bARForPrepayments = isnull(COLBOOLEAN,0)
		From SITECONTROL
		Where CONTROLID = 'AR for Prepayments'"

		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@bARForPrepayments	bit 			OUTPUT',
		@bARForPrepayments = @bARForPrepayments	OUTPUT
	End
	
	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "
		Select @nCreditBillLetterGen = isnull(COLINTEGER,0)
		From SITECONTROL
		Where CONTROLID = 'Credit Bill Letter Generation'"

		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@nCreditBillLetterGen	int 			OUTPUT',
		@nCreditBillLetterGen = @nCreditBillLetterGen	OUTPUT
	End
	
	if (@nDebug = 1)
		SELECT @sDraftPrefix AS DRAFTPREFIX, @nGLJournalCreation AS GLJOURNALCREATION, @bEnterOpenItemNo AS ENTEROPENITEMNO, @bQuotations AS QUOTATIONS, @bARForPrepayments AS ARFORPREPAYMENTS, @nCreditBillLetterGen AS CREDITBILLLETTERGEN

	if (@nDebug = 1)
		select '-- set GLStatus'

	If (@nGLJournalCreation is null)
		Set @nGLStatus = null
	Else
		Set @nGLStatus = 0
		
	if (@nDebug = 1)
		select @nGLStatus as GLSTATUS

	if (@nDebug = 1)
		select '-- Get Post Period.'
	
	-- Post Period is period of the item date
	Set @sSQLString = "Select @nPostPeriod = dbo.fn_GetPostPeriod(@pdtPostDate, 2) "
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@nPostPeriod int OUTPUT,
			@pdtPostDate datetime',
			@nPostPeriod	= @nPostPeriod	output,
			@pdtPostDate = @pdtPostDate

	if (@nDebug = 1)
		select @nPostPeriod AS POSTPERIOD

	-- load OpenItem temp table to be used later in adjust open item bal if required.
	/* CR 4.1 - in reality it makes more sense (improves logical readibility if we first inserted 
	into #TEMPOPENITEM i.e. the bill and then copied from there into #TEMPCREDITOPENITEM to create the credit note.
	I know you have done this in the order you have because of the Centura logic but in reality this is what we 
	are effectively doing. */
	
	
	If (@nErrorCode = 0)
	Begin

		Set @sSQLString = "Insert Into #TEMPCREDITOPENITEM(
		[ITEMENTITYNO],	[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[ACTION],
		[OPENITEMNO],[OLDOPENITEMNO],[ITEMDATE],[POSTDATE],[POSTPERIOD],[CLOSEPOSTDATE],
		[CLOSEPOSTPERIOD],[STATUS],[ITEMTYPE],[BILLPERCENTAGE],	[EMPLOYEENO],
		[EMPPROFITCENTRE],[CURRENCY],[EXCHRATE],[ITEMPRETAXVALUE],[LOCALTAXAMT],
		[LOCALVALUE],[FOREIGNTAXAMT],[FOREIGNVALUE],[LOCALBALANCE],[FOREIGNBALANCE],
		[EXCHVARIANCE],[STATEMENTREF],[REFERENCETEXT],[NAMESNAPNO],[BILLFORMATID],
		[BILLPRINTEDFLAG],[REGARDING],[SCOPE],[LANGUAGE],[ASSOCOPENITEMNO],
		[LONGREGARDING],[LONGREFTEXT],[IMAGEID],[FOREIGNEQUIVCURRCY],[FOREIGNEQUIVEXRATE],
		[ITEMDUEDATE],[PENALTYINTEREST],[LOCALORIGTAKENUP],[FOREIGNORIGTAKENUP],
		[REFERENCETEXT_TID],[REGARDING_TID],[SCOPE_TID],[INCLUDEONLYWIP],
		[PAYFORWIP],[PAYPROPERTYTYPE],[RENEWALDEBTORFLAG],[CASEPROFITCENTRE],
		[LOCKIDENTITYID],[MAINCASEID])
		Select 
		[ITEMENTITYNO],	[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[ACTION],
		[OPENITEMNO],[OPENITEMNO], [ITEMDATE],[POSTDATE],[POSTPERIOD],[CLOSEPOSTDATE],
		[CLOSEPOSTPERIOD],[STATUS], case when (ITEMTYPE = 513) then 514 else 511 end,[BILLPERCENTAGE],	[EMPLOYEENO],
		[EMPPROFITCENTRE],[CURRENCY],[EXCHRATE],[ITEMPRETAXVALUE],[LOCALTAXAMT],
		[LOCALVALUE],[FOREIGNTAXAMT],[FOREIGNVALUE],[LOCALBALANCE],[FOREIGNBALANCE],
		[EXCHVARIANCE],[STATEMENTREF],[REFERENCETEXT],[NAMESNAPNO],[BILLFORMATID],
		[BILLPRINTEDFLAG],[REGARDING],[SCOPE],[LANGUAGE],[ASSOCOPENITEMNO],
		[LONGREGARDING],[LONGREFTEXT],[IMAGEID],[FOREIGNEQUIVCURRCY],[FOREIGNEQUIVEXRATE],
		[ITEMDUEDATE],[PENALTYINTEREST],[LOCALORIGTAKENUP],[FOREIGNORIGTAKENUP],
		[REFERENCETEXT_TID],[REGARDING_TID],[SCOPE_TID],[INCLUDEONLYWIP],
		[PAYFORWIP],[PAYPROPERTYTYPE],[RENEWALDEBTORFLAG],[CASEPROFITCENTRE],
		[LOCKIDENTITYID],[MAINCASEID]
		From OPENITEM Where
		ITEMENTITYNO = @pnItemEntityNo and
		ITEMTRANSNO = @pnItemTransNo
		"
		
		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @pnItemTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo
			
		If (@nErrorCode = 0)
		Begin

			Set @sSQLString = "Insert into #TEMPOPENITEM([ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[ACTION],
			[OPENITEMNO],[OLDOPENITEMNO],[ITEMDATE],[POSTDATE],[POSTPERIOD],[CLOSEPOSTDATE],
			[CLOSEPOSTPERIOD],[STATUS],[ITEMTYPE],[BILLPERCENTAGE],	[EMPLOYEENO],
			[EMPPROFITCENTRE],[CURRENCY],[EXCHRATE],[ITEMPRETAXVALUE],[LOCALTAXAMT],
			[LOCALVALUE],[FOREIGNTAXAMT],[FOREIGNVALUE],[LOCALBALANCE],[FOREIGNBALANCE],
			[EXCHVARIANCE],[STATEMENTREF],[REFERENCETEXT],[NAMESNAPNO],[BILLFORMATID],
			[BILLPRINTEDFLAG],[REGARDING],[SCOPE],[LANGUAGE],[ASSOCOPENITEMNO],
			[LONGREGARDING],[LONGREFTEXT],[IMAGEID],[FOREIGNEQUIVCURRCY],[FOREIGNEQUIVEXRATE],
			[ITEMDUEDATE],[PENALTYINTEREST],[LOCALORIGTAKENUP],[FOREIGNORIGTAKENUP],
			[REFERENCETEXT_TID],[REGARDING_TID],[SCOPE_TID],[INCLUDEONLYWIP],
			[PAYFORWIP],[PAYPROPERTYTYPE],[RENEWALDEBTORFLAG],[CASEPROFITCENTRE],
			[LOCKIDENTITYID],[MAINCASEID]) 
			Select [ITEMENTITYNO],	[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[ACTION],
			[OPENITEMNO],[OLDOPENITEMNO],[ITEMDATE],[POSTDATE],[POSTPERIOD],[CLOSEPOSTDATE],
			[CLOSEPOSTPERIOD],[STATUS],[ITEMTYPE],[BILLPERCENTAGE],	[EMPLOYEENO],
			[EMPPROFITCENTRE],[CURRENCY],[EXCHRATE],[ITEMPRETAXVALUE],[LOCALTAXAMT],
			[LOCALVALUE],[FOREIGNTAXAMT],[FOREIGNVALUE],[LOCALBALANCE],[FOREIGNBALANCE],
			[EXCHVARIANCE],[STATEMENTREF],[REFERENCETEXT],[NAMESNAPNO],[BILLFORMATID],
			[BILLPRINTEDFLAG],[REGARDING],[SCOPE],[LANGUAGE],[ASSOCOPENITEMNO],
			[LONGREGARDING],[LONGREFTEXT],[IMAGEID],[FOREIGNEQUIVCURRCY],[FOREIGNEQUIVEXRATE],
			[ITEMDUEDATE],[PENALTYINTEREST],[LOCALORIGTAKENUP],[FOREIGNORIGTAKENUP],
			[REFERENCETEXT_TID],[REGARDING_TID],[SCOPE_TID],[INCLUDEONLYWIP],
			[PAYFORWIP],[PAYPROPERTYTYPE],[RENEWALDEBTORFLAG],[CASEPROFITCENTRE],
			[LOCKIDENTITYID],[MAINCASEID] from #TEMPCREDITOPENITEM"


			exec	@nErrorCode = sp_executesql @sSQLString
		End 

	End
	

	-- Assign OpenItemNos
	-- auto allocate Open Item no if site control Enter Open Item No is FALSE
	-- FCDBOpenItemTransaction.xfAllocateCreditNoteNumbers()
	If (@nErrorCode = 0 )
	Begin
		If (@bEnterOpenItemNo = 0)
		Begin
                        if (@nDebug = 1)
				Select 'auto generate openitem no'

                        Declare @sItemTypeSuffix nvarchar(2)
                        Declare @sOpenItemNo nvarchar(12)
                        Declare @nItemNo int

                        Set @sSQLString = "Select @sItemTypeSuffix = DIT.ABBREVIATION
			        from #TEMPCREDITOPENITEM T
			        Join DEBTOR_ITEM_TYPE DIT on (T.ITEMTYPE = DIT.ITEM_TYPE_ID)"
                        exec	@nErrorCode = sp_executesql @sSQLString,
			                N'@sItemTypeSuffix nvarchar(2) OUTPUT',
                                        @sItemTypeSuffix = @sItemTypeSuffix OUTPUT
			
                        If @nErrorCode = 0
                        Begin
			        Set @sSQLString = "Select @nOfficeId = O.OFFICEID, 
                                                @nFirstItemNoOffice = Case when (ISNULL(O.LASTITEMNO,0) + 1) < ISNULL(O.ITEMNOFROM,0) THEN O.ITEMNOFROM ELSE ISNULL(O.LASTITEMNO,0) + 1 END, 
					        @sItemNoPrefix = O.ITEMNOPREFIX, @nItemNoTo = O.ITEMNOTO,
                                                @sOfficeDescription = O.DESCRIPTION
                                                From OFFICE O
					        Join	[TABLEATTRIBUTES] TA on (TA.[TABLECODE] = O.OFFICEID
					        and	TA.[TABLETYPE] = 44 
					        and	TA.[PARENTTABLE] = 'NAME'
					        and	TA.[GENERICKEY] = @pnEmployeeNo)"       

			        exec	@nErrorCode = sp_executesql @sSQLString,
			                        N'@nOfficeId int OUTPUT,
			                          @nFirstItemNoOffice int OUTPUT,
			                          @sItemNoPrefix nvarchar(4) OUTPUT,
			                          @nItemNoTo decimal(10,0) OUTPUT,
                                                  @sOfficeDescription nvarchar(80) OUTPUT,
			                          @pnEmployeeNo int',
			                        @nOfficeId = @nOfficeId OUTPUT,
			                        @nFirstItemNoOffice = @nFirstItemNoOffice OUTPUT,
			                        @sItemNoPrefix = @sItemNoPrefix OUTPUT,
			                        @nItemNoTo = @nItemNoTo OUTPUT,
                                                @sOfficeDescription = @sOfficeDescription OUTPUT,
			                        @pnEmployeeNo = @pnEmployeeNo
                        End
			
			if (@nDebug = 1)
				select @nOfficeId as OFFICEID, @nFirstItemNoOffice AS LASTITEMNO, @sItemNoPrefix AS ITEMNOPREFIX, @nItemNoTo AS ITEMNOTO

			If (@nErrorCode = 0)
			Begin
				-- FCDBSpecialNameX.cfGenerateARNo()
				if (@sItemNoPrefix is not null 
					and @nItemNoTo is not null
					AND NOT EXISTS(SELECT * FROM #TEMPCREDITOPENITEM WHERE ITEMTYPE = 514))
				Begin
					If (@nDebug = 1)
						Select 'get open iten no from the office'

                                        If @nErrorCode = 0
                                        Begin      
                                                Select @sOpenItemNo = @sItemNoPrefix + cast(@nFirstItemNoOffice as nvarchar(12)) + @sItemTypeSuffix
                                                                       
                                                While exists (Select 1 from OPENITEM where OPENITEMNO = @sOpenItemNo AND ITEMENTITYNO = @pnItemEntityNo)
                                                Begin
                                                        Set @nFirstItemNoOffice = @nFirstItemNoOffice + 1
	                                                Select @sOpenItemNo = @sItemNoPrefix + cast(@nFirstItemNoOffice as nvarchar(12)) + @sItemTypeSuffix
                                                End
                                        End

					If (@nFirstItemNoOffice > @nItemNoTo) -- Item no to be used should be less than Office No To
					Begin
						Set @sAlertXML = dbo.fn_GetAlertXML('ACxxx', 'The credit note number upper limit of ' + cast(@nItemNoTo as nvarchar(14)) + ' for the office ' 
                                                        + @sOfficeDescription + ' has been exceeded. You must revise the upper limit before continuing.',
					                null, null, null, null, null)

			                        RAISERROR(@sAlertXML, 14, 1)
			                        Set @nErrorCode = @@ERROR

					End
					Else
					Begin
						Set @sSQLString = "Update T
						Set OPENITEMNO = @sItemNoPrefix + CAST((@nFirstItemNoOffice + T.SEQNO - 1) AS NVARCHAR(12)),
						    ITEMNO = @nFirstItemNoOffice + (T.SEQNO - 1)
                                                FROM #TEMPCREDITOPENITEM T"
					
						exec	@nErrorCode = sp_executesql @sSQLString,
								N'@sItemNoPrefix nvarchar(4),
								@nFirstItemNoOffice int',
								@sItemNoPrefix = @sItemNoPrefix,
								@nFirstItemNoOffice = @nFirstItemNoOffice
						
						If (@nErrorCode = 0)
						Begin
							Set @sSQLString = "Update OFFICE Set LASTITEMNO = (Select max(ITEMNO) from #TEMPCREDITOPENITEM)
							Where OFFICEID = @nOfficeId"
							
							exec	@nErrorCode = sp_executesql @sSQLString,
							N'@nOfficeId int',
							@nOfficeId = @nOfficeId
						End
					End
				End
				Else
				Begin  
                                        Declare @sNeedDraftPrefix nvarchar(4)

                                        If @nErrorCode = 0
                                        Begin
                                                Set @sSQLString = "
			                                        Select @nItemNo = ISNULL(SN.LASTOPENITEMNO,0) + 1,
                                                                @sNeedDraftPrefix = case when T.STATUS = 0 then @sDraftPrefix else '' end
			                                        FROM SPECIALNAME SN
                                                                join #TEMPCREDITOPENITEM T on (SN.NAMENO = T.ITEMENTITYNO)"

	                                         exec @nErrorCode=sp_executesql @sSQLString, 
				                                        N'@nItemNo      int             OUTPUT,
                                                                          @sNeedDraftPrefix nvarchar(4) OUTPUT,
                                                                          @sDraftPrefix nvarchar(4)',
                                                                          @nItemNo      = @nItemNo      OUTPUT,
				                                          @sNeedDraftPrefix = @sNeedDraftPrefix OUTPUT,
                                                                          @sDraftPrefix = @sDraftPrefix
                                        End	

                                        If @nErrorCode = 0
                                        Begin 
                                                Set @sOpenItemNo = @sNeedDraftPrefix + cast(@nItemNo as nvarchar(10)) + @sItemTypeSuffix
                                                While exists (Select 1 from OPENITEM where OPENITEMNO = @sOpenItemNo AND ITEMENTITYNO = @pnItemEntityNo)
                                                Begin
                                                        Set @nItemNo = @nItemNo + 1
	                                                Set @sOpenItemNo = @sNeedDraftPrefix + cast(@nItemNo as nvarchar(10)) + @sItemTypeSuffix
                                                End
                                        End

                                        If (@nDebug = 1)
					Begin
						Select 'getting next available open item no'
						select  @sOpenItemNo 
					End

                                        Set @sSQLString = "Update T
					        Set OPENITEMNO = @sNeedDraftPrefix + @nItemNo + (T.SEQNO - 1)
                                                FROM #TEMPCREDITOPENITEM T"

					exec	@nErrorCode = sp_executesql @sSQLString,
					                N'@nItemNo int,
                                                        @sNeedDraftPrefix nvarchar(4)',
					                @nItemNo = @nItemNo,
                                                        @sNeedDraftPrefix = @sNeedDraftPrefix
					
					If (@nErrorCode = 0)
					Begin
						If (@nDebug = 1)
						Begin
							Select 'update last open item no on special names'
						End

						Set @sSQLString = "UPDATE SPECIALNAME Set LASTOPENITEMNO = (Select max(OPENITEMNO) From #TEMPCREDITOPENITEM )
						Where NAMENO = @pnItemEntityNo"
						
						exec	@nErrorCode = sp_executesql @sSQLString,
							N'@pnItemEntityNo int',
							@pnItemEntityNo = @pnItemEntityNo
					End
					
					If (@nDebug = 1)
					Begin
						Select 'Current details in #TEMPCREDITOPENITEM'
						Select * from #TEMPCREDITOPENITEM

						Select 'Current details in #TEMPOPENITEM'
						Select * from #TEMPOPENITEM
					End
					
				End
			End
		End
		Else
		Begin
			Set @sSQLString = ""
		End	
		
	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select '-- get the list of generated open item numbers'

		Set @sSQLString = "SELECT @sCreditNoteNos = ISNULL( @sCreditNoteNos + ', ', '' ) + OPENITEMNO
				FROM #TEMPCREDITOPENITEM"

		exec	@nErrorCode = sp_executesql @sSQLString,
					N'@sCreditNoteNos nvarchar(2000) OUTPUT',
					@sCreditNoteNos = @sCreditNoteNos OUTPUT
		If (@nDebug = 1)
			select @sCreditNoteNos as CREDITNOTENOS
	End
	
	if (@nErrorCode = 0)
	Begin
	    if (@nDebug =1)
		Select '-- insert transaction header'

	    exec @nErrorCode = dbo.ip_GetLastInternalCode 
		@pnUserIdentityId	= @pnUserIdentityId,
		@psTable	= 'TRANSACTIONHEADER',
		@pnLastInternalCode = @nTransNo output
	End
	
	if (@nErrorCode = 0)
	Begin
		Begin Transaction
	
		Set @sSQLString = "Insert into TRANSACTIONHEADER(ENTITYNO, TRANSNO, TRANSDATE, TRANSTYPE, EMPLOYEENO, USERID, ENTRYDATE,
						SOURCE, TRANSTATUS, TRANPOSTPERIOD, TRANPOSTDATE, GLSTATUS)
		Values(@pnItemEntityNo, @nTransNo, @pdtPostDate, 511, @pnEmployeeNo, SYSTEM_USER , @dtCurrentDate,
					2, 1, @nPostPeriod, @dtCurrentDate, @nGLStatus)"
		
		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@pnItemEntityNo int,
		  @nTransNo int,
		  @pdtPostDate datetime,
		  @pnEmployeeNo int,
		  @nSource int,
		  @nPostPeriod int,
		  @nGLStatus int,
		  @dtCurrentDate datetime',
		@pnItemEntityNo = @pnItemEntityNo,
		@nTransNo = @nTransNo,
		@pdtPostDate = @pdtPostDate,
		@pnEmployeeNo = @pnEmployeeNo,
		@nSource = @nSource,
		@nPostPeriod = @nPostPeriod,
		@nGLStatus = @nGLStatus,
		@dtCurrentDate = @dtCurrentDate

		If (@nDebug = 1)
			Select * from TRANSACTIONHEADER
			where ENTITYNO = @pnItemEntityNo AND TRANSNO = @nTransNo
		
	End
	
	if (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			SELECT ' -- insert into Bill Line'

		Set @sSQLString = "INSERT INTO BILLLINE (
		ITEMENTITYNO,ITEMTRANSNO,
		ITEMLINENO, WIPCODE, WIPTYPEID, CATEGORYCODE, IRN, VALUE, FOREIGNVALUE,
		DISPLAYSEQUENCE, PRINTDATE, PRINTNAME,PRINTCHARGEOUTRATE, PRINTTOTALUNITS, PRINTTIME,
		UNITSPERHOUR, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, PRINTCHARGECURRNCY, LOCALTAX, TAXCODE)
		SELECT @pnItemEntityNo, @nTransNo, ITEMLINENO, WIPCODE, WIPTYPEID, CATEGORYCODE, IRN, 
		(-1*VALUE), (-1*FOREIGNVALUE), DISPLAYSEQUENCE, PRINTDATE, PRINTNAME,PRINTCHARGEOUTRATE, 
		PRINTTOTALUNITS, PRINTTIME, UNITSPERHOUR, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE, 
		PRINTCHARGECURRNCY, (-1*LOCALTAX), TAXCODE
		FROM BILLLINE
		WHERE ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO = @pnItemTransNo"
		
		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@pnItemEntityNo int,
		  @nTransNo int,
		  @pnItemTransNo int',
		@pnItemEntityNo = @pnItemEntityNo,
		@nTransNo = @nTransNo,
		@pnItemTransNo = @pnItemTransNo

		If (@nDebug = 1)
			SELECT * 
			FROM BILLLINE
			WHERE ITEMENTITYNO = @pnItemEntityNo
			AND ITEMTRANSNO = @nTransNo
	End
	
	If (@nErrorCode = 0)
	Begin
		
		If (@nDebug = 1)
		begin
			select ' -- reinstate Work History bills and write ups (4)'
			Select 
		[ENTITYNO] ,[TRANSNO] ,[WIPSEQNO] ,
		[HISTORYLINENO], [HISTORYLINENO] ,@pdtPostDate , @dtCurrentDate, 
		511 ,[RATENO] ,[WIPCODE] ,[CASEID] ,
		[ACCTENTITYNO] ,[ACCTCLIENTNO] ,[EMPLOYEENO] ,
		case when [ITEMIMPACT] = 1 then null else [TOTALTIME] end ,
		case when [ITEMIMPACT] = 1 then null else [TOTALUNITS]end ,
		case when [ITEMIMPACT] = 1 then null else [UNITSPERHOUR] end ,
		case when [ITEMIMPACT] = 1 then null else [CHARGEOUTRATE] end ,
		[ASSOCIATENO] ,[INVOICENUMBER] ,[FOREIGNCURRENCY] ,
		case when [FOREIGNCURRENCY] is not null then [FOREIGNTRANVALUE]*-1 else [FOREIGNTRANVALUE] end  ,
		[EXCHRATE] ,[LOCALTRANSVALUE] * -1 ,@pnItemEntityNo ,@nTransNo ,
		[REFSEQNO] ,[REFACCTENTITYNO] ,[REFACCTDEBTORNO] ,
		[REASONCODE] ,[BILLLINENO] ,[EMPPROFITCENTRE],
		[CASEPROFITCENTRE] ,[NARRATIVENO] ,[SHORTNARRATIVE] ,
		[LONGNARRATIVE] ,[HISTORYLINENO] ,[TRANSFERDETAIL] ,
		1 ,[MOVEMENTCLASS] ,99 ,case when [ITEMIMPACT] = 1 then 9 else [ITEMIMPACT] end ,
		@nPostPeriod ,[VARIABLEFEEAMT] ,[VARIABLEFEETYPE] ,
		[VARIABLEFEECURR] ,[FEECRITERIANO] ,[FEEUNIQUEID] ,
		null ,[QUOTATIONNO] ,[EMPFAMILYNO] ,
		[EMPOFFICECODE] ,[VERIFICATIONNUMBER] ,
		case when [LOCALCOST] is not null then [LOCALCOST]*-1 else [LOCALCOST] end,
		case when [FOREIGNCOST] is not null then [FOREIGNCOST]*-1 else [FOREIGNCOST] end ,
		[ENTEREDQUANTITY] ,[DISCOUNTFLAG] ,
		[NARRATIVE_TID] ,[COSTCALCULATION1] ,[COSTCALCULATION2] ,
		[PRODUCTCODE] ,[GENERATEDINADVANCE],[MATCHENTITYNO] ,
		[MATCHTRANSNO] ,[MATCHWIPSEQNO] ,[MATCHEDTOOPENITEM] ,
		[MATCHEDFULLY] ,[MARGINNO] 
		From WORKHISTORY WH1
		Where 				
		REFENTITYNO = @pnItemEntityNo
		AND REFTRANSNO = @pnItemTransNo
		AND MOVEMENTCLASS = 2
		ORDER BY ENTITYNO, TRANSNO, WIPSEQNO, MOVEMENTCLASS DESC
		
		end
	
		Set @sSQLString = "Insert into #TEMPWORKHISTORY ([ENTITYNO],[TRANSNO],[WIPSEQNO],
		[HISTORYLINENO], [OLDHISTORYLINENO], [TRANSDATE],[POSTDATE],
		[TRANSTYPE],[RATENO],[WIPCODE],[CASEID],
		[ACCTENTITYNO],[ACCTCLIENTNO],[EMPLOYEENO],
		[TOTALTIME],
		[TOTALUNITS],
		[UNITSPERHOUR],
		[CHARGEOUTRATE],
		[ASSOCIATENO],[INVOICENUMBER],[FOREIGNCURRENCY],
		[FOREIGNTRANVALUE],
		[EXCHRATE],[LOCALTRANSVALUE],[REFENTITYNO],[REFTRANSNO],
		[REFSEQNO],[REFACCTENTITYNO],[REFACCTDEBTORNO],
		[REASONCODE],[BILLLINENO],[EMPPROFITCENTRE],
		[CASEPROFITCENTRE],[NARRATIVENO],[SHORTNARRATIVE],
		[LONGNARRATIVE],[ASSOCLINENO],[TRANSFERDETAIL],
		[STATUS],[MOVEMENTCLASS],[COMMANDID],[ITEMIMPACT],
		[POSTPERIOD],[VARIABLEFEEAMT],[VARIABLEFEETYPE],
		[VARIABLEFEECURR],[FEECRITERIANO],[FEEUNIQUEID],
		[GLMOVEMENTNO],[QUOTATIONNO],[EMPFAMILYNO],
		[EMPOFFICECODE],[VERIFICATIONNUMBER],
		[LOCALCOST],
		[FOREIGNCOST],
		[ENTEREDQUANTITY],[DISCOUNTFLAG],
		[NARRATIVE_TID],[COSTCALCULATION1],[COSTCALCULATION2],
		[PRODUCTCODE],[GENERATEDINADVANCE],[MATCHENTITYNO],
		[MATCHTRANSNO],[MATCHWIPSEQNO],[MATCHEDTOOPENITEM],
		[MATCHEDFULLY],[MARGINNO])
		Select 
		[ENTITYNO] ,[TRANSNO] ,[WIPSEQNO] ,
		[HISTORYLINENO], [HISTORYLINENO] ,@pdtPostDate , @dtCurrentDate, 
		511 ,[RATENO] ,[WIPCODE] ,[CASEID] ,
		[ACCTENTITYNO] ,[ACCTCLIENTNO] ,[EMPLOYEENO] ,
		case when [ITEMIMPACT] = 1 then null else [TOTALTIME] end ,
		case when [ITEMIMPACT] = 1 then null else [TOTALUNITS]end ,
		case when [ITEMIMPACT] = 1 then null else [UNITSPERHOUR] end ,
		case when [ITEMIMPACT] = 1 then null else [CHARGEOUTRATE] end ,
		[ASSOCIATENO] ,[INVOICENUMBER] ,[FOREIGNCURRENCY] ,
		case when [FOREIGNCURRENCY] is not null then [FOREIGNTRANVALUE]*-1 else [FOREIGNTRANVALUE] end  ,
		[EXCHRATE] ,[LOCALTRANSVALUE]*-1 ,@pnItemEntityNo ,@nTransNo ,
		[REFSEQNO] ,[REFACCTENTITYNO] ,[REFACCTDEBTORNO] ,
		[REASONCODE] ,[BILLLINENO] ,[EMPPROFITCENTRE],
		[CASEPROFITCENTRE] ,[NARRATIVENO] ,[SHORTNARRATIVE] ,
		[LONGNARRATIVE] ,[HISTORYLINENO] ,[TRANSFERDETAIL] ,
		1 ,[MOVEMENTCLASS] ,99 ,case when [ITEMIMPACT] = 1 then 9 else [ITEMIMPACT] end ,
		@nPostPeriod ,[VARIABLEFEEAMT] ,[VARIABLEFEETYPE] ,
		[VARIABLEFEECURR] ,[FEECRITERIANO] ,[FEEUNIQUEID] ,
		null ,[QUOTATIONNO] ,[EMPFAMILYNO] ,
		[EMPOFFICECODE] ,[VERIFICATIONNUMBER] ,
		case when [LOCALCOST] is not null then [LOCALCOST]*-1 else [LOCALCOST] end,
		case when [FOREIGNCOST] is not null then [FOREIGNCOST]*-1 else [FOREIGNCOST] end ,
		[ENTEREDQUANTITY] ,[DISCOUNTFLAG] ,
		[NARRATIVE_TID] ,[COSTCALCULATION1] ,[COSTCALCULATION2] ,
		[PRODUCTCODE] ,[GENERATEDINADVANCE],[MATCHENTITYNO] ,
		[MATCHTRANSNO] ,[MATCHWIPSEQNO] ,[MATCHEDTOOPENITEM] ,
		[MATCHEDFULLY] ,[MARGINNO] 
		From WORKHISTORY WH1
		Where REFENTITYNO = @pnItemEntityNo
		AND REFTRANSNO = @pnItemTransNo
		AND MOVEMENTCLASS = 2
		ORDER BY ENTITYNO, TRANSNO, WIPSEQNO, MOVEMENTCLASS DESC"
		  

		exec	@nErrorCode = sp_executesql @sSQLString,
					N'@pnItemEntityNo int,
					@pnItemTransNo int,
					@pdtPostDate datetime,
					@nReverseTransType int,
					@nPostPeriod int,
					@nTransNo int,
					@dtCurrentDate datetime',
					@pnItemEntityNo = @pnItemEntityNo,
					@pnItemTransNo = @pnItemTransNo,
					@pdtPostDate = @pdtPostDate,
					@nReverseTransType = @nReverseTransType,
					@nPostPeriod = @nPostPeriod,
					@nTransNo = @nTransNo,
					@dtCurrentDate = @dtCurrentDate
		  
		If (@nDebug = 1)
			select * from #TEMPWORKHISTORY
	End
	
	select @nErrorCode
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select '-- update narrative for movement class 2 with narrative'

		Set @sSQLString = "Update #TEMPWORKHISTORY Set SHORTNARRATIVE = @sCreditNoteNos
					Where MOVEMENTCLASS = 2"
		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@sCreditNoteNos nvarchar(2000)',
			@sCreditNoteNos = @sCreditNoteNos		
	End
		  
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update temp work history history line no'
		
		Set @sSQLString = "Update T
		Set T.HISTORYLINENO = MHLN.MAXHISTLINENO + TWH.HISTORYLINESEQ
		From #TEMPWORKHISTORY T
		JOIN (SELECT MAX(HISTORYLINENO) AS MAXHISTLINENO, ENTITYNO, TRANSNO, WIPSEQNO 
			FROM WORKHISTORY
			GROUP BY ENTITYNO, TRANSNO, WIPSEQNO) AS MHLN ON (MHLN.ENTITYNO = T.ENTITYNO
									AND MHLN.TRANSNO = T.TRANSNO
									AND MHLN.WIPSEQNO = T.WIPSEQNO)
		JOIN (SELECT ENTITYNO, TRANSNO, WIPSEQNO,
			ROW_NUMBER() OVER (PARTITION BY ENTITYNO, TRANSNO, WIPSEQNO ORDER BY HISTORYLINENO) AS HISTORYLINESEQ
			FROM #TEMPWORKHISTORY) AS TWH ON (TWH.ENTITYNO = T.ENTITYNO
							AND TWH.TRANSNO = T.TRANSNO
							AND TWH.WIPSEQNO = T.WIPSEQNO)"
		
		exec	@nErrorCode = sp_executesql @sSQLString

		If (@nDebug = 1)
		Begin
			select 'temp work history rows'
			select * from #TEMPWORKHISTORY
		End
	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update work history assoc line no'

		Set @sSQLString = "			
		Update WH
		Set ASSOCLINENO = T.HISTORYLINENO, STATUS = 9									
		From WORKHISTORY WH
		Join #TEMPWORKHISTORY T	on (T.ENTITYNO = WH.ENTITYNO 
					and T.TRANSNO = WH.TRANSNO 
					and T.WIPSEQNO = WH.WIPSEQNO 
					and T.OLDHISTORYLINENO = WH.HISTORYLINENO)"
		exec	@nErrorCode = sp_executesql @sSQLString

	End
	
									
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
		begin
			select ' insert into work history form temp table'
			select * from #TEMPWORKHISTORY
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
		[MATCHEDFULLY],[MARGINNO])
		Select 
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
		[MATCHEDFULLY],[MARGINNO]				
		From #TEMPWORKHISTORY"
		
		exec	@nErrorCode = sp_executesql @sSQLString
	End

	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' -- update WIP Ledger control totals 1'

		Declare cWorkHistory cursor for
		Select MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, LOCALTRANSVALUE
		From #TEMPWORKHISTORY
		
		Open cWorkHistory
		Fetch Next From cWorkHistory Into @nMovementClass, @nTransType, @nPostPeriod, @nLocalTransValue
		
		While @@FETCH_STATUS = 0
		Begin
			If (@nErrorCode = 0)
			Begin
				-- Call this procedure to insert/update as appropriate
				exec @nErrorCode = dbo.acw_UpdateControlTotal
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@pbCalledFromCentura	= @pbCalledFromCentura,
					@pnLedger		= 1,
					@pnCategory		= @nMovementClass,
					@pnType			= @nTransType,
					@pnPeriodId		= @nPostPeriod,
					@pnEntityNo		= @pnItemEntityNo,
					@pnAmountToAdd		= @nLocalTransValue


				If (@nDebug = 1)
					select ' update WIP Ledger control total 1 step 2'
			End
			
			Fetch Next From cWorkHistory Into @nMovementClass, @nTransType, @nPostPeriod, @nLocalTransValue
		End
		Close cWorkHistory
		Deallocate cWorkHistory
		
		If (@nDebug = 1)
			select ' update WIP Ledger control total 1 completed'
	End

	If (@nErrorCode = 0 )
	Begin
		Delete from #TEMPWORKHISTORY
		
		If (@nDebug = 1)
			select '-- reinstate Work History DISCOUNT write downs (5)'

		Set @sSQLString = "Insert into #TEMPWORKHISTORY 
		([ENTITYNO],[TRANSNO],[WIPSEQNO],
		[HISTORYLINENO], [OLDHISTORYLINENO], [TRANSDATE],[POSTDATE],
		[TRANSTYPE],[RATENO],[WIPCODE],[CASEID],
		[ACCTENTITYNO],[ACCTCLIENTNO],[EMPLOYEENO],
		[TOTALTIME],
		[TOTALUNITS],
		[UNITSPERHOUR],
		[CHARGEOUTRATE],
		[ASSOCIATENO],[INVOICENUMBER],[FOREIGNCURRENCY],
		[FOREIGNTRANVALUE],[EXCHRATE],
		[LOCALTRANSVALUE],[REFENTITYNO],[REFTRANSNO],
		[REFSEQNO],[REFACCTENTITYNO],[REFACCTDEBTORNO],
		[REASONCODE],[BILLLINENO],[EMPPROFITCENTRE],
		[CASEPROFITCENTRE],[NARRATIVENO],[SHORTNARRATIVE],
		[LONGNARRATIVE],[ASSOCLINENO],[TRANSFERDETAIL],
		[STATUS],[MOVEMENTCLASS],[COMMANDID],
		[ITEMIMPACT],
		[POSTPERIOD],[VARIABLEFEEAMT],[VARIABLEFEETYPE],
		[VARIABLEFEECURR],[FEECRITERIANO],[FEEUNIQUEID],
		[GLMOVEMENTNO],[QUOTATIONNO],[EMPFAMILYNO],
		[EMPOFFICECODE],[VERIFICATIONNUMBER],
		[LOCALCOST],
		[FOREIGNCOST],
		[ENTEREDQUANTITY],[DISCOUNTFLAG],
		[NARRATIVE_TID],[COSTCALCULATION1],[COSTCALCULATION2],
		[PRODUCTCODE],[GENERATEDINADVANCE],[MATCHENTITYNO],
		[MATCHTRANSNO],[MATCHWIPSEQNO],[MATCHEDTOOPENITEM],
		[MATCHEDFULLY],[MARGINNO])
		Select 
		[ENTITYNO] ,[TRANSNO] ,[WIPSEQNO] ,
		[HISTORYLINENO], [HISTORYLINENO] ,@pdtPostDate ,@dtCurrentDate ,
		511 ,[RATENO] ,[WIPCODE] ,[CASEID] ,
		[ACCTENTITYNO] ,[ACCTCLIENTNO] ,[EMPLOYEENO] ,
		case when [ITEMIMPACT]= 1 then null else [TOTALTIME] end ,
		case when [ITEMIMPACT] = 1 then null else [TOTALUNITS]end ,
		case when [ITEMIMPACT] = 1 then null else [UNITSPERHOUR] end ,
		case when [ITEMIMPACT] = 1 then null else [CHARGEOUTRATE] end,
		[ASSOCIATENO] ,[INVOICENUMBER] ,[FOREIGNCURRENCY] ,
		case when [FOREIGNCURRENCY] is not null then [FOREIGNTRANVALUE]*-1 else null end, [EXCHRATE],
		[LOCALTRANSVALUE]*-1 ,@pnItemEntityNo , @nTransNo ,
		[REFSEQNO] ,[REFACCTENTITYNO] ,[REFACCTDEBTORNO] ,
		WH.[REASONCODE] ,[BILLLINENO] ,[EMPPROFITCENTRE],
		[CASEPROFITCENTRE] ,[NARRATIVENO] ,[SHORTNARRATIVE] ,
		[LONGNARRATIVE] ,[HISTORYLINENO] ,[TRANSFERDETAIL] ,
		1 ,[MOVEMENTCLASS] ,99 ,
		case when [ITEMIMPACT] = 1 then 9 else [ITEMIMPACT] end ,
		@nPostPeriod ,[VARIABLEFEEAMT] ,[VARIABLEFEETYPE] ,
		[VARIABLEFEECURR] ,[FEECRITERIANO] ,[FEEUNIQUEID] ,
		null ,[QUOTATIONNO] ,[EMPFAMILYNO] ,
		[EMPOFFICECODE] ,[VERIFICATIONNUMBER] ,
		case when [LOCALCOST] is not null then [LOCALCOST]*-1 else null end,
		case when [FOREIGNCOST] is not null then [FOREIGNCOST]*-1 else null end,
		[ENTEREDQUANTITY] ,[DISCOUNTFLAG] ,
		[NARRATIVE_TID] ,[COSTCALCULATION1] ,[COSTCALCULATION2] ,
		[PRODUCTCODE] ,[GENERATEDINADVANCE],[MATCHENTITYNO] ,
		[MATCHTRANSNO] ,[MATCHWIPSEQNO] ,[MATCHEDTOOPENITEM] ,
		[MATCHEDFULLY] ,[MARGINNO] 
		From WORKHISTORY WH
		Join REASON R	ON (R.REASONCODE = WH.REASONCODE 
				and R.SHOWONDEBITNOTE = 1)
		Where
		REFENTITYNO = @pnItemEntityNo
		AND REFTRANSNO =  @pnItemTransNo
		AND MOVEMENTCLASS = 3
		ORDER BY ENTITYNO, TRANSNO, WIPSEQNO, MOVEMENTCLASS DESC"		
		
	  	exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @pnItemTransNo int,
			  @pdtPostDate datetime,
			  @nPostPeriod int,
			  @nTransNo int,
			  @dtCurrentDate datetime',
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo,
			@pdtPostDate = @pdtPostDate,
			@nPostPeriod = @nPostPeriod,
			@nTransNo = @nTransNo,
			@dtCurrentDate = @dtCurrentDate
	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
		Begin
			select ' update temp work history history line no'
			select (SELECT MAX(WH.HISTORYLINENO)+T.SEQNO 
					from WORKHISTORY WH 
					where T.ENTITYNO = WH.ENTITYNO
					and T.TRANSNO = WH.TRANSNO 
					and T.WIPSEQNO = WH.WIPSEQNO)
			From #TEMPWORKHISTORY T
		End

		Set @sSQLString = "Update T
			Set T.HISTORYLINENO = MHLN.MAXHISTLINENO + TWH.HISTORYLINESEQ
		From #TEMPWORKHISTORY T
			JOIN (SELECT MAX(HISTORYLINENO) AS MAXHISTLINENO, ENTITYNO, TRANSNO, WIPSEQNO 
				FROM WORKHISTORY
				GROUP BY ENTITYNO, TRANSNO, WIPSEQNO) AS MHLN ON (MHLN.ENTITYNO = T.ENTITYNO
										AND MHLN.TRANSNO = T.TRANSNO
										AND MHLN.WIPSEQNO = T.WIPSEQNO)
			JOIN (SELECT ENTITYNO, TRANSNO, WIPSEQNO,
				ROW_NUMBER() OVER (PARTITION BY ENTITYNO, TRANSNO, WIPSEQNO ORDER BY HISTORYLINENO) AS HISTORYLINESEQ
				FROM #TEMPWORKHISTORY) AS TWH ON (TWH.ENTITYNO = T.ENTITYNO
								AND TWH.TRANSNO = T.TRANSNO
								AND TWH.WIPSEQNO = T.WIPSEQNO)"
		
		exec	@nErrorCode = sp_executesql @sSQLString

		
		If (@nDebug = 1)
		BEGIN
			SELECT ' ************************* discount work history'
			SELECT * FROM #TEMPWORKHISTORY
		END
	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update work history assoc line no'

		Set @sSQLString = "			
		Update WH
		Set ASSOCLINENO = T.HISTORYLINENO, STATUS = 9									
		From WORKHISTORY WH
		Join #TEMPWORKHISTORY T	on  (T.ENTITYNO = WH.ENTITYNO 
					and T.TRANSNO = WH.TRANSNO 
					and T.WIPSEQNO = WH.WIPSEQNO 
					and T.OLDHISTORYLINENO = WH.HISTORYLINENO)"
		exec	@nErrorCode = sp_executesql @sSQLString
	End
	
									
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
		begin
			select ' insert into work history form temp table'
			select * from #TEMPWORKHISTORY
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
		[MATCHEDFULLY],[MARGINNO])
		Select 
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
		[MATCHEDFULLY],[MARGINNO]				
		From #TEMPWORKHISTORY"
		
		exec	@nErrorCode = sp_executesql @sSQLString
	End

	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' -- Update the WIP Ledger Control Totals 2'

		Declare cWorkHistory cursor for
		Select MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, LOCALTRANSVALUE
		From #TEMPWORKHISTORY
		
		Open cWorkHistory
		Fetch Next From cWorkHistory Into @nMovementClass, @nTransType, @nPostPeriod, @nLocalTransValue
		
		While @@FETCH_STATUS = 0
		Begin
			If (@nErrorCode = 0)
			Begin
				
				-- Call this procedure to insert/update as appropriate
				exec @nErrorCode = dbo.acw_UpdateControlTotal
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@pbCalledFromCentura = @pbCalledFromCentura,
					@pnLedger = 1,
					@pnCategory	= @nMovementClass,
					@pnType	= @nTransType,
					@pnPeriodId	= @nPostPeriod,
					@pnEntityNo	= @pnItemEntityNo,
					@pnAmountToAdd = @nLocalTransValue

				If (@nDebug = 1)
					select ' update WIP Ledger control total 2 step 2 '
			End

			Fetch Next From cWorkHistory Into @nMovementClass, @nTransType, @nPostPeriod, @nLocalTransValue
		End
		Close cWorkHistory
		Deallocate cWorkHistory
		
		If (@nDebug = 1)
			select ' update WIP Ledger control total 2 completed'
	End
	
	-- do the following when the write down reason is not null
	If (@nErrorCode = 0 and @bWriteDownWIP = 1)
	Begin
		Delete from #TEMPWORKHISTORY

		If (@nDebug = 1)
			select ' insert into temp workhistory to write down all WIP'
		
		Set @sSQLString = "	
		Insert Into #TEMPWORKHISTORY
		([ENTITYNO],[TRANSNO],[WIPSEQNO],
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
		[MATCHEDFULLY],[MARGINNO])
		Select 
		W.[ENTITYNO],W.[TRANSNO],W.[WIPSEQNO],
		[HISTORYLINENO], [HISTORYLINENO],[TRANSDATE],[POSTDATE],
		[TRANSTYPE],[RATENO],[WIPCODE],[CASEID],
		[ACCTENTITYNO],[ACCTCLIENTNO],[EMPLOYEENO],
		[TOTALTIME],[TOTALUNITS],[UNITSPERHOUR],
		[CHARGEOUTRATE],[ASSOCIATENO],[INVOICENUMBER],
		[FOREIGNCURRENCY],
		CASE WHEN FOREIGNCURRENCY IS NULL 
			THEN NULL 
			ELSE W.FOREIGNTRANVALUE + ISNULL(WIPWRITEDOWNS.FOREIGNWRITEDOWNTOTAL,0) + ISNULL(WIPWRITEUPS.FOREIGNWRITEUPTOTAL,0) END,
		[EXCHRATE],
		W.LOCALTRANSVALUE + ISNULL(WIPWRITEDOWNS.LOCALWRITEDOWNTOTAL,0) + ISNULL(WIPWRITEUPS.LOCALWRITEUPTOTAL,0),
		W.[REFENTITYNO],W.[REFTRANSNO],
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
		[MATCHEDFULLY],[MARGINNO]				
		From WORKHISTORY W
		LEFT JOIN (SELECT SUM(LOCALTRANSVALUE) AS LOCALWRITEDOWNTOTAL, 
				CASE WHEN FOREIGNCURRENCY IS NULL THEN NULL ELSE SUM(FOREIGNTRANVALUE) END AS FOREIGNWRITEDOWNTOTAL, 
				ENTITYNO, TRANSNO, WIPSEQNO, REFENTITYNO, REFTRANSNO
			FROM WORKHISTORY
			WHERE MOVEMENTCLASS = 3
			AND ITEMIMPACT IS NULL
			GROUP BY ENTITYNO, TRANSNO, WIPSEQNO, REFENTITYNO, REFTRANSNO, FOREIGNCURRENCY) 
							AS WIPWRITEDOWNS ON (WIPWRITEDOWNS.ENTITYNO = W.ENTITYNO
									AND WIPWRITEDOWNS.TRANSNO = W.TRANSNO
									AND WIPWRITEDOWNS.WIPSEQNO = W.WIPSEQNO
									AND WIPWRITEDOWNS.REFENTITYNO = W.REFENTITYNO
									AND WIPWRITEDOWNS.REFTRANSNO = W.REFTRANSNO)
		LEFT JOIN (SELECT SUM(LOCALTRANSVALUE) AS LOCALWRITEUPTOTAL, 
				CASE WHEN FOREIGNCURRENCY IS NULL THEN NULL ELSE SUM(FOREIGNTRANVALUE) END AS FOREIGNWRITEUPTOTAL, 
				ENTITYNO, TRANSNO, WIPSEQNO, REFENTITYNO, REFTRANSNO 
			FROM WORKHISTORY
			WHERE MOVEMENTCLASS = 9
			AND ITEMIMPACT IS NULL
			GROUP BY ENTITYNO, TRANSNO, WIPSEQNO, REFENTITYNO, REFTRANSNO, FOREIGNCURRENCY) 
							AS WIPWRITEUPS ON (WIPWRITEUPS.ENTITYNO = W.ENTITYNO
									AND WIPWRITEUPS.TRANSNO = W.TRANSNO
									AND WIPWRITEUPS.WIPSEQNO = W.WIPSEQNO
									AND WIPWRITEUPS.REFENTITYNO = W.REFENTITYNO
									AND WIPWRITEUPS.REFTRANSNO = W.REFTRANSNO)
		Where W.REFENTITYNO = @pnItemEntityNo
		AND W.REFTRANSNO =  @nTransNo
		AND W.ITEMIMPACT is null
		AND (W.MOVEMENTCLASS = 2 -- Process normal billed items (with or without adjustments)
			OR  
		    (MOVEMENTCLASS = 3 -- Process stand alone write downs (full write downs)
			AND not EXISTS
			(SELECT * FROM WORKHISTORY WHBILL
			  WHERE WHBILL.REFENTITYNO = @pnItemEntityNo
			  AND WHBILL.REFTRANSNO = @nTransNo
			  AND WHBILL.ENTITYNO = W.ENTITYNO
			  AND WHBILL.TRANSNO = W.TRANSNO
			  AND WHBILL.WIPSEQNO = W.WIPSEQNO
			  AND WHBILL.MOVEMENTCLASS = 2)
		    ))		
		ORDER BY W.ENTITYNO, W.TRANSNO, W.WIPSEQNO"
		
		exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @nTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@nTransNo = @nTransNo
	
		If (@nErrorCode = 0 )
		Begin
			If (@nDebug = 1)
				select ' set write down attributes for automatically written down wip'
	
			Set @sSQLString = "Update T
			Set LOCALTRANSVALUE = LOCALTRANSVALUE * -1,
			    FOREIGNTRANVALUE = case when FOREIGNCURRENCY is not null then FOREIGNTRANVALUE * -1 else FOREIGNTRANVALUE end,
			    TRANSDATE = @pdtPostDate, POSTDATE = @dtCurrentDate, POSTPERIOD = @nPostPeriod, TRANSTYPE = 511,
			    MOVEMENTCLASS = case when LOCALTRANSVALUE > 0 then 3 else 9 end,
			    COMMANDID = case when LOCALTRANSVALUE > 0 then 4 else 7 end,
			    ITEMIMPACT = null,
			    REASONCODE = @psCreditReasonCode,
			    BILLLINENO = null,
			    ASSOCLINENO = null,
			    SHORTNARRATIVE = @sCreditNoteNos,
			    LONGNARRATIVE = null,
			    GLMOVEMENTNO = null,
			    STATUS = 1,
			    LOCALCOST = CASE WHEN ISNULL(CB.LOCALCOSTBALANCE,0) != 0 THEN CB.LOCALCOSTBALANCE * -1 ELSE NULL END,
			    FOREIGNCOST = CASE WHEN T.FOREIGNCURRENCY IS NOT NULL AND ISNULL(CB.FOREIGNCOSTBALANCE,0) != 0 THEN CB.FOREIGNCOSTBALANCE * -1 ELSE NULL END
			From #TEMPWORKHISTORY T
			left join (SELECT SUM(ISNULL(LOCALCOST,0)) AS LOCALCOSTBALANCE, 
				CASE WHEN FOREIGNCURRENCY IS NULL THEN NULL ELSE SUM(ISNULL(FOREIGNCOST,0)) END AS FOREIGNCOSTBALANCE,
				ENTITYNO, TRANSNO, WIPSEQNO
				FROM WORKHISTORY
				group by ENTITYNO, TRANSNO, WIPSEQNO, FOREIGNCURRENCY) AS CB ON CB.ENTITYNO = T.ENTITYNO
												AND CB.TRANSNO = T.TRANSNO
												AND CB.WIPSEQNO = T.WIPSEQNO
			"
							  
  			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@psCreditReasonCode nvarchar(12) ,
			  @sCreditNoteNos nvarchar(2000),
			  @pdtPostDate datetime,
			  @nPostPeriod int,
			  @dtCurrentDate datetime',
			@psCreditReasonCode = @psCreditReasonCode,
			@sCreditNoteNos = @sCreditNoteNos,
			@pdtPostDate = @pdtPostDate,
			@nPostPeriod = @nPostPeriod,
			@dtCurrentDate = @dtCurrentDate
		End
		
		If (@nErrorCode = 0 )
		Begin
			If (@nDebug = 1)
				select '-- post work history'
			
			If (@nErrorCode = 0)
			Begin
				If (@nDebug = 1)
					select ' update temp work history history line no'
					
				Set @sSQLString = "Update T
					Set T.HISTORYLINENO = MHLN.MAXHISTLINENO + TWH.HISTORYLINESEQ
					From #TEMPWORKHISTORY T
					JOIN (SELECT MAX(HISTORYLINENO) AS MAXHISTLINENO, ENTITYNO, TRANSNO, WIPSEQNO 
						FROM WORKHISTORY
						GROUP BY ENTITYNO, TRANSNO, WIPSEQNO) AS MHLN ON (MHLN.ENTITYNO = T.ENTITYNO
												AND MHLN.TRANSNO = T.TRANSNO
												AND MHLN.WIPSEQNO = T.WIPSEQNO)
					JOIN (SELECT ENTITYNO, TRANSNO, WIPSEQNO,
						ROW_NUMBER() OVER (PARTITION BY ENTITYNO, TRANSNO, WIPSEQNO ORDER BY HISTORYLINENO) AS HISTORYLINESEQ
						FROM #TEMPWORKHISTORY) AS TWH ON (TWH.ENTITYNO = T.ENTITYNO
										AND TWH.TRANSNO = T.TRANSNO
										AND TWH.WIPSEQNO = T.WIPSEQNO)"
				
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
				Join #TEMPWORKHISTORY T	on (T.ENTITYNO = WH.ENTITYNO 
							and T.TRANSNO = WH.TRANSNO 
							and T.WIPSEQNO = WH.WIPSEQNO 
							and T.OLDHISTORYLINENO = WH.HISTORYLINENO)"
				exec	@nErrorCode = sp_executesql @sSQLString
			End
			
											
			If (@nErrorCode = 0)
			Begin
				If (@nDebug = 1)
				begin
					select ' insert into work history form temp table'
					select * from #TEMPWORKHISTORY
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
				[MATCHEDFULLY],[MARGINNO])
				Select 
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
				[MATCHEDFULLY],[MARGINNO]				
				From #TEMPWORKHISTORY"
				
				exec	@nErrorCode = sp_executesql @sSQLString
			End

			If (@nErrorCode = 0)
			Begin
				If (@nDebug = 1)
					select ' -- Update the WIP Ledger Control Totals 3'

				Declare cWorkHistory cursor for
				Select MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, LOCALTRANSVALUE
				From #TEMPWORKHISTORY
				
				Open cWorkHistory
				Fetch Next From cWorkHistory Into @nMovementClass, @nTransType, @nPostPeriod, @nLocalTransValue
				
				While @@FETCH_STATUS = 0
				Begin
					If (@nErrorCode = 0)
					Begin
						-- Call this procedure to insert/update as appropriate
						exec @nErrorCode = dbo.acw_UpdateControlTotal
							@pnUserIdentityId = @pnUserIdentityId,
							@psCulture = @psCulture,
							@pbCalledFromCentura = @pbCalledFromCentura,
							@pnLedger = 1,
							@pnCategory	= @nMovementClass,
							@pnType	= @nTransType,
							@pnPeriodId	= @nPostPeriod,
							@pnEntityNo	= @pnItemEntityNo,
							@pnAmountToAdd = @nLocalTransValue
						
						If (@nDebug = 1)
							select ' update WIP Ledger control total 3 step 2 '
					End
					
					Fetch Next From cWorkHistory Into @nMovementClass, @nTransType, @nPostPeriod, @nLocalTransValue 
					
				End
				Close cWorkHistory
				Deallocate cWorkHistory
				
				If (@nDebug = 1)
					select ' update WIP Ledger control total 3 completed'
			End
					
		End			
	End
	
	If (@nErrorCode = 0)
	Begin
		
		If (@nDebug = 1)
			Select ' -- reinstate WIP (6) '

		If (@bWriteDownWIP = 1)
		Begin

			If (@nDebug = 1)
			Begin
				Select ' -- reinstate WIP allowing for WIP Write Down '
				Select ' -- reinstate deleted credit WIP '
			End

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
			PRODUCTCODE, MARGINNO)
			select  WHCREDIT.ENTITYNO, WHCREDIT.TRANSNO, WHCREDIT.WIPSEQNO, 
			WHCREDIT.TRANSDATE, WHCREDIT.POSTDATE, 
			WHCREDIT.RATENO, WHCREDIT.WIPCODE, WHCREDIT.CASEID, WHCREDIT.ACCTENTITYNO, WHCREDIT.ACCTCLIENTNO, 
			WHCREDIT.EMPLOYEENO, WHCREDIT.TOTALTIME, WHCREDIT.TOTALUNITS, WHCREDIT.UNITSPERHOUR, 
			WHCREDIT.CHARGEOUTRATE, WHCREDIT.ASSOCIATENO, WHCREDIT.FOREIGNCURRENCY, 
			WHCREDIT.FOREIGNTRANVALUE, WHCREDIT.EXCHRATE, WHCREDIT.LOCALTRANSVALUE, 
			 WHCREDIT.EMPPROFITCENTRE, WHCREDIT.EMPFAMILYNO,WHCREDIT.EMPOFFICECODE,
			WHCREDIT.CASEPROFITCENTRE, WHCREDIT.NARRATIVENO, 
			WHCREDIT.SHORTNARRATIVE, WHCREDIT.LONGNARRATIVE, WHCREDIT.QUOTATIONNO, 
			WHCREDIT.FEECRITERIANO, WHCREDIT.FEEUNIQUEID, WHCREDIT.VARIABLEFEEAMT, WHCREDIT.VARIABLEFEETYPE, WHCREDIT.VARIABLEFEECURR,
			0, 0, 1, WHCREDIT.LOCALCOST, WHCREDIT.FOREIGNCOST, WHCREDIT.VERIFICATIONNUMBER, WHCREDIT.INVOICENUMBER, WHCREDIT.ENTEREDQUANTITY,
			WHCREDIT.DISCOUNTFLAG, WHCREDIT.COSTCALCULATION1, WHCREDIT.COSTCALCULATION2, WHCREDIT.GENERATEDINADVANCE, 
			WHCREDIT.PRODUCTCODE,  WHCREDIT.MARGINNO 
			from WORKHISTORY WHCREDIT
			where WHCREDIT.ITEMIMPACT = 1
			and WHCREDIT.REFENTITYNO = @pnItemEntityNo
			and WHCREDIT.REFTRANSNO= @pnItemTransNo
			and WHCREDIT.MOVEMENTCLASS = 2
			and NOT EXISTS (Select * from WORKINPROGRESS WIP
						  where WIP.ENTITYNO=WHCREDIT.ENTITYNO
						  and WIP.TRANSNO=WHCREDIT.TRANSNO
						  and WIP.WIPSEQNO=WHCREDIT.WIPSEQNO)"

			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @pnItemTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo


			
			if (@nErrorCode = 0)
			Begin
				If (@nDebug = 1)
				Begin
					select 'Update reinstated Credit WIP'
					select * from WORKINPROGRESS where ENTITYNO = @pnItemEntityNo and
					TRANSNO= @pnItemTransNo
				end
				
				Set @sSQLString = "Update WIP
				Set WIP.BALANCE = WIP.BALANCE + WH.LOCALTRANSVALUE,
				WIP.FOREIGNBALANCE = WIP.FOREIGNBALANCE + WH.FOREIGNTRANVALUE
				From WORKINPROGRESS WIP
				Join WORKHISTORY WH	on (WH.ENTITYNO = WIP.ENTITYNO 
							and WH.TRANSNO = WIP.TRANSNO 
							and WH.WIPSEQNO = WIP.WIPSEQNO)
				Where WH.REFENTITYNO = @pnItemEntityNo
				AND WH.REFTRANSNO = @nTransNo
				AND WH.MOVEMENTCLASS = 2
				AND WH.ITEMIMPACT = 9"
				
				exec	@nErrorCode = sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				  @nTransNo int',
				@pnItemEntityNo = @pnItemEntityNo,
				@nTransNo = @nTransNo
			End
				
			if (@nErrorCode = 0)
			Begin
				If (@nDebug = 1)
					select 'delete 0 Balance reinstated Credit WIP'

				Set @sSQLString = "Delete  WIP
				From WORKINPROGRESS WIP
				Join WORKHISTORY WH	on (WH.ENTITYNO = WIP.ENTITYNO 
							and WH.TRANSNO = WIP.TRANSNO 
							and WH.WIPSEQNO = WIP.WIPSEQNO)
				Where WH.REFENTITYNO = @pnItemEntityNo
				AND WH.REFTRANSNO = @nTransNo
				AND WH.MOVEMENTCLASS = 2
				AND WH.ITEMIMPACT = 9
				AND WIP.BALANCE = 0"
				
				exec	@nErrorCode = sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				 @nTransNo int',
				@pnItemEntityNo = @pnItemEntityNo,
				@nTransNo = @nTransNo
			End			
			
		End
		Else
		Begin
			if (@nDebug = 1)
			begin
				Select '-- reinstate deleted WIP for Consume (2), Disposal (3) and Equalise (9) movements '
				select   WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.TRANSDATE, WH.POSTDATE, 
			WH.RATENO, WH.WIPCODE, WH.CASEID, WH.ACCTENTITYNO, WH.ACCTCLIENTNO, 
			WH.EMPLOYEENO, WH.TOTALTIME, WH.TOTALUNITS, WH.UNITSPERHOUR, 
			WH.CHARGEOUTRATE, WH.ASSOCIATENO, WH.FOREIGNCURRENCY, 
			WH.FOREIGNTRANVALUE, WH.EXCHRATE, WH.LOCALTRANSVALUE,  WH.EMPPROFITCENTRE, WH.EMPFAMILYNO, WH.EMPOFFICECODE, 
			WH.CASEPROFITCENTRE, WH.NARRATIVENO, WH.SHORTNARRATIVE, WH.LONGNARRATIVE, WH.QUOTATIONNO, 
			WH.FEECRITERIANO, WH.FEEUNIQUEID, WH.VARIABLEFEEAMT, WH.VARIABLEFEETYPE, WH.VARIABLEFEECURR,
			0, 0, 1, WH.LOCALCOST, WH.FOREIGNCOST, WH.VERIFICATIONNUMBER, WH.INVOICENUMBER, WH.ENTEREDQUANTITY, 
			WH.DISCOUNTFLAG, WH.COSTCALCULATION1, WH.COSTCALCULATION2, WH.GENERATEDINADVANCE, 
			WH.PRODUCTCODE,  WH.MARGINNO 
			from WORKHISTORY WH
			Join WORKHISTORY WH1 on (WH.ENTITYNO = WH1.ENTITYNO and WH.TRANSNO = WH1.TRANSNO and WH.WIPSEQNO=WH1.WIPSEQNO)
			where WH.ITEMIMPACT = 1
			and WH1.REFENTITYNO= @pnItemEntityNo
			and WH1.REFTRANSNO= @pnItemTransNo
			and WH1.MOVEMENTCLASS = 2
			and NOT EXISTS (Select * from WORKINPROGRESS WIP
						  where WIP.ENTITYNO=WH.ENTITYNO
						  and WIP.TRANSNO=WH.TRANSNO
						  and WIP.WIPSEQNO=WH.WIPSEQNO)
			end

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
			PRODUCTCODE, MARGINNO) 
			select  WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.TRANSDATE, WH.POSTDATE, 
			WH.RATENO, WH.WIPCODE, WH.CASEID, WH.ACCTENTITYNO, WH.ACCTCLIENTNO, 
			WH.EMPLOYEENO, WH.TOTALTIME, WH.TOTALUNITS, WH.UNITSPERHOUR, 
			WH.CHARGEOUTRATE, WH.ASSOCIATENO, WH.FOREIGNCURRENCY, 
			WH.FOREIGNTRANVALUE, WH.EXCHRATE, WH.LOCALTRANSVALUE,  WH.EMPPROFITCENTRE, WH.EMPFAMILYNO, WH.EMPOFFICECODE, 
			WH.CASEPROFITCENTRE, WH.NARRATIVENO, WH.SHORTNARRATIVE, WH.LONGNARRATIVE, WH.QUOTATIONNO, 
			WH.FEECRITERIANO, WH.FEEUNIQUEID, WH.VARIABLEFEEAMT, WH.VARIABLEFEETYPE, WH.VARIABLEFEECURR,
			0, 0, 1, WH.LOCALCOST, WH.FOREIGNCOST, WH.VERIFICATIONNUMBER, WH.INVOICENUMBER, WH.ENTEREDQUANTITY, 
			WH.DISCOUNTFLAG, WH.COSTCALCULATION1, WH.COSTCALCULATION2, WH.GENERATEDINADVANCE, 
			WH.PRODUCTCODE,  WH.MARGINNO 
			from WORKHISTORY WH
			Join WORKHISTORY WH1 on (WH.ENTITYNO = WH1.ENTITYNO and WH.TRANSNO = WH1.TRANSNO and WH.WIPSEQNO=WH1.WIPSEQNO)
			where WH.ITEMIMPACT = 1
			and WH1.REFENTITYNO= @pnItemEntityNo
			and WH1.REFTRANSNO= @nTransNo
			and WH1.MOVEMENTCLASS = 2
			and NOT EXISTS (Select * from WORKINPROGRESS WIP
						  where WIP.ENTITYNO=WH.ENTITYNO
						  and WIP.TRANSNO=WH.TRANSNO
						  and WIP.WIPSEQNO=WH.WIPSEQNO)"
						  
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @nTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@nTransNo = @nTransNo
			
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
			PRODUCTCODE, MARGINNO) 
			select  WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.TRANSDATE, WH.POSTDATE, 
			WH.RATENO, WH.WIPCODE, WH.CASEID, WH.ACCTENTITYNO, WH.ACCTCLIENTNO, 
			WH.EMPLOYEENO, WH.TOTALTIME, WH.TOTALUNITS, WH.UNITSPERHOUR, 
			WH.CHARGEOUTRATE, WH.ASSOCIATENO, WH.FOREIGNCURRENCY, 
			WH.FOREIGNTRANVALUE, WH.EXCHRATE, WH.LOCALTRANSVALUE,  WH.EMPPROFITCENTRE, WH.EMPFAMILYNO, WH.EMPOFFICECODE, 
			WH.CASEPROFITCENTRE, WH.NARRATIVENO, WH.SHORTNARRATIVE, WH.LONGNARRATIVE, WH.QUOTATIONNO, 
			WH.FEECRITERIANO, WH.FEEUNIQUEID, WH.VARIABLEFEEAMT, WH.VARIABLEFEETYPE, WH.VARIABLEFEECURR,
			0, 0, 1, WH.LOCALCOST, WH.FOREIGNCOST, WH.VERIFICATIONNUMBER, WH.INVOICENUMBER, WH.ENTEREDQUANTITY, 
			WH.DISCOUNTFLAG, WH.COSTCALCULATION1, WH.COSTCALCULATION2, WH.GENERATEDINADVANCE, 
			WH.PRODUCTCODE,  WH.MARGINNO 
			from WORKHISTORY WH
			Join WORKHISTORY WH1 on (WH.ENTITYNO = WH1.ENTITYNO and WH.TRANSNO = WH1.TRANSNO and WH.WIPSEQNO=WH1.WIPSEQNO)
			where WH.ITEMIMPACT = 1
			and WH1.REFENTITYNO= @pnItemEntityNo
			and WH1.REFTRANSNO= @nTransNo
			and WH1.MOVEMENTCLASS = 3
			and NOT EXISTS (Select * from WORKINPROGRESS WIP
						  where WIP.ENTITYNO=WH.ENTITYNO
						  and WIP.TRANSNO=WH.TRANSNO
						  and WIP.WIPSEQNO=WH.WIPSEQNO)"
						  
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @nTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@nTransNo = @nTransNo
			
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
			PRODUCTCODE, MARGINNO) 
			select  WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.TRANSDATE, WH.POSTDATE, 
			WH.RATENO, WH.WIPCODE, WH.CASEID, WH.ACCTENTITYNO, WH.ACCTCLIENTNO, 
			WH.EMPLOYEENO, WH.TOTALTIME, WH.TOTALUNITS, WH.UNITSPERHOUR, 
			WH.CHARGEOUTRATE, WH.ASSOCIATENO, WH.FOREIGNCURRENCY, 
			WH.FOREIGNTRANVALUE, WH.EXCHRATE, WH.LOCALTRANSVALUE,  WH.EMPPROFITCENTRE, WH.EMPFAMILYNO, WH.EMPOFFICECODE, 
			WH.CASEPROFITCENTRE, WH.NARRATIVENO, WH.SHORTNARRATIVE, WH.LONGNARRATIVE, WH.QUOTATIONNO, 
			WH.FEECRITERIANO, WH.FEEUNIQUEID, WH.VARIABLEFEEAMT, WH.VARIABLEFEETYPE, WH.VARIABLEFEECURR,
			0, 0, 1, WH.LOCALCOST, WH.FOREIGNCOST, WH.VERIFICATIONNUMBER, WH.INVOICENUMBER, WH.ENTEREDQUANTITY, 
			WH.DISCOUNTFLAG, WH.COSTCALCULATION1, WH.COSTCALCULATION2, WH.GENERATEDINADVANCE, 
			WH.PRODUCTCODE,  WH.MARGINNO 
			from WORKHISTORY WH
			Join WORKHISTORY WH1 on (WH.ENTITYNO = WH1.ENTITYNO and WH.TRANSNO = WH1.TRANSNO and WH.WIPSEQNO=WH1.WIPSEQNO)
			where WH.ITEMIMPACT = 1
			and WH1.REFENTITYNO= @pnItemEntityNo
			and WH1.REFTRANSNO= @nTransNo
			and WH1.MOVEMENTCLASS = 9
			and NOT EXISTS (Select * from WORKINPROGRESS WIP
						  where WIP.ENTITYNO=WH.ENTITYNO
						  and WIP.TRANSNO=WH.TRANSNO
						  and WIP.WIPSEQNO=WH.WIPSEQNO)"
						  
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @nTransNo int',
			@pnItemEntityNo = @pnItemEntityNo,
			@nTransNo = @nTransNo
			

			if (@nErrorCode = 0)
			Begin
				if(@nDebug = 1)
				begin
					Select 'reinstate partially adjusted WIP'
					select * from WORKHISTORY where REFENTITYNO= @pnItemEntityNo
							and REFTRANSNO= @pnItemTransNo
				end
	
				 Set @sSQLString = "Update WIP
				 Set BALANCE = WIP.BALANCE + WIPWH.TOTAL,
				 WIP.FOREIGNBALANCE = WIP.FOREIGNBALANCE + WIPWH.FOREIGNTOTAL
				 From WORKINPROGRESS WIP
				 Join (Select WIP1.ENTITYNO as ENTITYNO, WIP1.TRANSNO as TRANSNO, WIP1.WIPSEQNO as WIPSEQNO, SUM(isnull(WH.LOCALTRANSVALUE,0)) as TOTAL, SUM(isnull(WH.FOREIGNTRANVALUE,0)) as FOREIGNTOTAL
					From WORKINPROGRESS WIP1
					Join WORKHISTORY WH on (WIP1.ENTITYNO=WH.ENTITYNO and WIP1.TRANSNO=WH.TRANSNO
							and WIP1.WIPSEQNO=WH.WIPSEQNO and WH.MOVEMENTCLASS in (1,2, 3, 9)
							and WH.REFENTITYNO= @pnItemEntityNo
							and WH.REFTRANSNO= @nTransNo)
							group by WIP1.ENTITYNO, WIP1.TRANSNO, WIP1.WIPSEQNO) WIPWH on
					(WIPWH.ENTITYNO = WIP.ENTITYNO and WIPWH.TRANSNO = WIP.TRANSNO and WIPWH.WIPSEQNO = WIP.WIPSEQNO)"
					
				exec	@nErrorCode = sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				  @nTransNo int',
				@pnItemEntityNo = @pnItemEntityNo,
				@nTransNo = @nTransNo
			End
					
			if (@nErrorCode = 0)
			Begin	
				if(@nDebug = 1)
				begin
					Select 'delete 0 Balance WIP items'
					select * From WORKINPROGRESS WIP
					Where
					WIP.BALANCE = 0
					AND EXISTS
					(	SELECT * FROM WORKHISTORY WH
					WHERE 	WH.ENTITYNO = WIP.ENTITYNO
					AND	WH.TRANSNO = WIP.TRANSNO
					AND	WH.WIPSEQNO = WIP.WIPSEQNO
					AND	WH.REFENTITYNO = @pnItemEntityNo   
					AND	WH.REFTRANSNO = @pnItemTransNo)
				end
					
				Set @sSQLString = "Delete WIP
				From WORKINPROGRESS WIP
				Where
				WIP.BALANCE = 0
				AND EXISTS
				(	SELECT * FROM WORKHISTORY WH
				WHERE 	WH.ENTITYNO = WIP.ENTITYNO
				AND	WH.TRANSNO = WIP.TRANSNO
				AND	WH.WIPSEQNO = WIP.WIPSEQNO
				AND	WH.REFENTITYNO = @pnItemEntityNo   
				AND	WH.REFTRANSNO = @pnItemTransNo)"
				
				exec	@nErrorCode = sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				  @pnItemTransNo int',
				@pnItemEntityNo = @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo

			End
		End

	End
	
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
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			SELECT '-- retrieve Case list from Bill for use in Name Snap processing'

		Set @sSQLString = "Insert into #TEMPCASEID (CASEID, ISMAINCASE)
				   Select distinct(CASEID), 0 
				   from WORKHISTORY
				   where REFENTITYNO = @pnItemEntityNo
				   and REFTRANSNO = @pnItemTransNo"
				   
		exec	@nErrorCode = sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				  @pnItemTransNo int',
				@pnItemEntityNo = @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo
				
		if @nErrorCode = 0
		Begin
			Set @sSQLString = "update TC
					set  TC.ISMAINCASE = 1
					FROM #TEMPCASEID TC
					JOIN OPENITEM O ON (TC.CASEID = O.MAINCASEID)
					   where O.ITEMENTITYNO = @pnItemEntityNo
					   and O.ITEMTRANSNO = @pnItemTransNo"

			exec	@nErrorCode = sp_executesql @sSQLString,
					N'@pnItemEntityNo int,
					  @pnItemTransNo int',
					@pnItemEntityNo = @pnItemEntityNo,
					@pnItemTransNo = @pnItemTransNo
		End
	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			Select '-- Credit the open items and adjust the open item bal.(7)'
		-- @pdtPostDate is used because the new item date is passed as @pdtPostDate.  Post Date is always todays date.
		Set @sSQLString = "Update #TEMPCREDITOPENITEM
		Set ITEMENTITYNO = @pnItemEntityNo,
		ITEMTRANSNO = @nTransNo,
		ITEMDATE = @pdtPostDate,
		POSTDATE = @dtCurrentDate,
		ITEMDUEDATE = null,
		PENALTYINTEREST = null,
		LOCALORIGTAKENUP = Case When @bARForPrepayments = 0 then (-1 * LOCALBALANCE) else 0 end,
		LOCALBALANCE =  Case When @bARForPrepayments = 0 then  (LOCALBALANCE - LOCALVALUE) else (-1 * LOCALVALUE) end,
		FOREIGNORIGTAKENUP = Case When @bARForPrepayments = 0 then 
					case when CURRENCY is not null then (-1 * FOREIGNBALANCE) else FOREIGNORIGTAKENUP end 
				else case when CURRENCY is not null then 0 else FOREIGNORIGTAKENUP end end,
		FOREIGNBALANCE = Case When @bARForPrepayments = 0 then 
					case when CURRENCY is not null then (FOREIGNBALANCE - FOREIGNVALUE) else FOREIGNBALANCE end 
				else case when CURRENCY is not null then (-1 * FOREIGNVALUE) else FOREIGNBALANCE end end,
		POSTPERIOD = @nPostPeriod,
		STATUS = 1,
		ITEMPRETAXVALUE = -1 * ITEMPRETAXVALUE,
		LOCALTAXAMT = -1 * LOCALTAXAMT,
		LOCALVALUE = -1 * LOCALVALUE,
		EXCHVARIANCE = 0,
		FOREIGNTAXAMT = case when CURRENCY is not null then (-1 * FOREIGNTAXAMT) else FOREIGNTAXAMT end,
		FOREIGNVALUE = case when CURRENCY is not null then (-1 * FOREIGNVALUE) else FOREIGNVALUE end,
		STATEMENTREF = @psStatementRef,
		REGARDING = @psRegarding,
		BILLPRINTEDFLAG = 0,
		ASSOCOPENITEMNO = OLDOPENITEMNO"

		exec	@nErrorCode = sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				  @nTransNo int,
				  @pdtPostDate datetime,
				  @bARForPrepayments bit,
				  @nPostPeriod int,
				  @psStatementRef nvarchar(254),
				  @psRegarding nvarchar(254),
				  @dtCurrentDate datetime',
				@pnItemEntityNo = @pnItemEntityNo,
				@nTransNo = @nTransNo,
				@pdtPostDate = @pdtPostDate,
				@bARForPrepayments = @bARForPrepayments,
				@nPostPeriod = @nPostPeriod,
				@psStatementRef = @psStatementRef,
				@psRegarding = @psRegarding,
				@dtCurrentDate = @dtCurrentDate
		
		If (@nErrorCode = 0)
		Begin
			Set @sSQLString = "Update T
			Set CLOSEPOSTDATE = Case When LOCALBALANCE = 0 Then @dtCurrentDate else '31-Dec-9999' end,
			CLOSEPOSTPERIOD = Case When LOCALBALANCE = 0 Then @nPostPeriod else 999999 end,
			OPENITEMNO = OPENITEMNO + DIT.ABBREVIATION
			from #TEMPCREDITOPENITEM T
			Join DEBTOR_ITEM_TYPE DIT on (T.ITEMTYPE = DIT.ITEM_TYPE_ID)"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@dtCurrentDate datetime,
			@nPostPeriod int',
			@dtCurrentDate = @dtCurrentDate,
			@nPostPeriod = @nPostPeriod
		End
		If (@nErrorCode = 0)
		Begin	
			If (@nDebug = 1)
			Begin
				Select 'insert into OPENITEM - CREDIT NOTE'
				Select * from #TEMPCREDITOPENITEM
			End

			Set @sSQLString = "Insert into OPENITEM 
			([ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[ACTION],
			[OPENITEMNO],[ITEMDATE],[POSTDATE],[POSTPERIOD],[CLOSEPOSTDATE],
			[CLOSEPOSTPERIOD],[STATUS],[ITEMTYPE],[BILLPERCENTAGE],	[EMPLOYEENO],
			[EMPPROFITCENTRE],[CURRENCY],[EXCHRATE],[ITEMPRETAXVALUE],[LOCALTAXAMT],
			[LOCALVALUE],[FOREIGNTAXAMT],[FOREIGNVALUE],[LOCALBALANCE],[FOREIGNBALANCE],
			[EXCHVARIANCE],[STATEMENTREF],[REFERENCETEXT],[NAMESNAPNO],[BILLFORMATID],
			[BILLPRINTEDFLAG],[REGARDING],[SCOPE],[LANGUAGE],[ASSOCOPENITEMNO],
			[LONGREGARDING],[LONGREFTEXT],[IMAGEID],[FOREIGNEQUIVCURRCY],[FOREIGNEQUIVEXRATE],
			[ITEMDUEDATE],[PENALTYINTEREST],[LOCALORIGTAKENUP],[FOREIGNORIGTAKENUP],
			[REFERENCETEXT_TID],[REGARDING_TID],[SCOPE_TID],[INCLUDEONLYWIP],
			[PAYFORWIP],[PAYPROPERTYTYPE],[RENEWALDEBTORFLAG],[CASEPROFITCENTRE],
			[LOCKIDENTITYID],[MAINCASEID])
			Select [ITEMENTITYNO],	[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[ACTION],
			[OPENITEMNO],[ITEMDATE],[POSTDATE],[POSTPERIOD],[CLOSEPOSTDATE],
			[CLOSEPOSTPERIOD],[STATUS],[ITEMTYPE],[BILLPERCENTAGE],	[EMPLOYEENO],
			[EMPPROFITCENTRE],[CURRENCY],[EXCHRATE],[ITEMPRETAXVALUE],[LOCALTAXAMT],
			[LOCALVALUE],[FOREIGNTAXAMT],[FOREIGNVALUE],[LOCALBALANCE],[FOREIGNBALANCE],
			[EXCHVARIANCE],[STATEMENTREF],[REFERENCETEXT],[NAMESNAPNO],[BILLFORMATID],
			[BILLPRINTEDFLAG],[REGARDING],[SCOPE],[LANGUAGE],[ASSOCOPENITEMNO],
			[LONGREGARDING],[LONGREFTEXT],[IMAGEID],[FOREIGNEQUIVCURRCY],[FOREIGNEQUIVEXRATE],
			[ITEMDUEDATE],[PENALTYINTEREST],[LOCALORIGTAKENUP],[FOREIGNORIGTAKENUP],
			[REFERENCETEXT_TID],[REGARDING_TID],[SCOPE_TID],[INCLUDEONLYWIP],
			[PAYFORWIP],[PAYPROPERTYTYPE],[RENEWALDEBTORFLAG],[CASEPROFITCENTRE],
			[LOCKIDENTITYID],[MAINCASEID] from #TEMPCREDITOPENITEM"
			
			exec	@nErrorCode = sp_executesql @sSQLString
		End

	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
		Begin
			Select 'insert into OPENITEMTAX'
			Select @pnItemEntityNo, @nTransNo, OIT.ACCTENTITYNO, OIT.ACCTDEBTORNO, OIT.TAXCODE, OIT.TAXRATE, 
			-1*OIT.TAXABLEAMOUNT, -1*OIT.TAXAMOUNT, OIT.COUNTRYCODE, OIT.STATE, OIT.HARMONISED, 
			OIT.TAXONTAX, OIT.MODIFIED, OIT.ADJUSTMENT, OIT.FOREIGNTAXABLEAMOUNT, OIT.FOREIGNTAXAMOUNT, OIT.CURRENCY
			From OPENITEMTAX OIT
			Join #TEMPOPENITEM T on (T.ITEMENTITYNO = OIT.ITEMENTITYNO and T.ITEMTRANSNO = OIT.ITEMTRANSNO 
					and T.ACCTENTITYNO = OIT.ACCTENTITYNO and T.ACCTDEBTORNO = OIT.ACCTDEBTORNO)
			--Where OIT.TAXAMOUNT is not null AND OIT.TAXAMOUNT != 0
		End
				
		Set @sSQLString = "Insert into OPENITEMTAX (ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, TAXCODE, TAXRATE,
					TAXABLEAMOUNT, TAXAMOUNT, COUNTRYCODE, STATE, HARMONISED, TAXONTAX, MODIFIED, ADJUSTMENT, FOREIGNTAXABLEAMOUNT, FOREIGNTAXAMOUNT, CURRENCY)
		Select @pnItemEntityNo, @nTransNo, OIT.ACCTENTITYNO, OIT.ACCTDEBTORNO, OIT.TAXCODE, OIT.TAXRATE, 
			-1*OIT.TAXABLEAMOUNT, -1*OIT.TAXAMOUNT, OIT.COUNTRYCODE, OIT.STATE, OIT.HARMONISED, 
			OIT.TAXONTAX, OIT.MODIFIED, OIT.ADJUSTMENT, -1*OIT.FOREIGNTAXABLEAMOUNT, -1*OIT.FOREIGNTAXAMOUNT, OIT.CURRENCY
		From OPENITEMTAX OIT
		Join #TEMPOPENITEM T on (T.ITEMENTITYNO = OIT.ITEMENTITYNO and T.ITEMTRANSNO = OIT.ITEMTRANSNO 
				and T.ACCTENTITYNO = OIT.ACCTENTITYNO and T.ACCTDEBTORNO = OIT.ACCTDEBTORNO)"
		--Where OIT.TAXAMOUNT is not null AND OIT.TAXAMOUNT != 0 "
		
		exec	@nErrorCode = sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				  @nTransNo int',
				@pnItemEntityNo = @pnItemEntityNo,
				@nTransNo = @nTransNo
		
	End
			
	If (@nErrorCode = 0)
	Begin	
		If (@nDebug = 1)
			Select 'insert debtor history row(s) for the credit note into temp debtor history. Copy of bill''s create debtorhistory row(s)'

		Set @sSQLString = "Insert into #TEMPDEBTORHISTORY(
		[ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO], [OLDHISTORYLINENO],
		[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
		[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
		[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
		[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
		[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO])
		select 
		DH.[ITEMENTITYNO],DH.[ITEMTRANSNO],DH.[ACCTENTITYNO],DH.[ACCTDEBTORNO],DH.[HISTORYLINENO], DH.[HISTORYLINENO],
		DH.[OPENITEMNO],DH.[TRANSDATE],DH.[POSTDATE],DH.[POSTPERIOD],DH.[TRANSTYPE],DH.[MOVEMENTCLASS],
		DH.[COMMANDID],DH.[ITEMPRETAXVALUE],DH.[LOCALTAXAMT],DH.[LOCALVALUE],DH.[EXCHVARIANCE],DH.[FOREIGNTAXAMT],
		DH.[FOREIGNTRANVALUE],DH.[REFERENCETEXT],DH.[REASONCODE],DH.[REFENTITYNO],DH.[REFTRANSNO],DH.[REFSEQNO],
		DH.[REFACCTENTITYNO],DH.[REFACCTDEBTORNO],DH.[LOCALBALANCE],DH.[FOREIGNBALANCE],DH.[TOTALEXCHVARIANCE],
		DH.[FORCEDPAYOUT],DH.[CURRENCY],DH.[EXCHRATE],DH.[STATUS],DH.[ASSOCLINENO],DH.[ITEMIMPACT],DH.[LONGREFTEXT],DH.[GLMOVEMENTNO]
		from DEBTORHISTORY DH
		Join #TEMPOPENITEM T on (DH.ITEMENTITYNO = T.ITEMENTITYNO and DH.ITEMTRANSNO = T.ITEMTRANSNO
					    and DH.ACCTENTITYNO = T.ACCTENTITYNO and DH.ACCTDEBTORNO = T.ACCTDEBTORNO
					    and DH.ITEMIMPACT = 1)"

		exec	@nErrorCode = sp_executesql @sSQLString

		/* CR 4.1 - This is the statement not the following, where I was suggesting #TEMPCREDITOPENITEM should be #TEMPOPENITEM for readibility
		,
		N'@pnItemTransNo int',
		@pnItemTransNo = @pnItemTransNo
		 */
	End
	
	If (@nErrorCode = 0)
	Begin
		if (@nDebug = 1)
		begin
			Select 'Update Debtor History for Credit Note'	
			Select * from #TEMPDEBTORHISTORY
		end

		/* set transno to the tranno of the credit note */
		/* KR1 - it appears that the openitemno for this line should be credit notes openitemno 
		GMOVEMENTNO should be 3 REFTRANSNO should be @nTransNo*/
		/* CR 4.1 - this one should have been left to be #TEMPCREDITOPENITEM - no need to link to #TEMPOPENITEM. 
		GLMOVEMENTNO should only be set by the Financial Interface. This should be set to NULL - 
		sorry should have picked up on that earlier
		This statement could be combined with the above statement to make more efficient...
		values could also be set directly from #TEMPCREDITOPENITEM*/ 
		Set @sSQLString = "Update DH
		Set OPENITEMNO = T.OPENITEMNO,
		ITEMTRANSNO = T.ITEMTRANSNO, 
		TRANSDATE = @pdtPostDate, 
		REFENTITYNO = T.ITEMENTITYNO, 
		REFTRANSNO = T.ITEMTRANSNO, 
		POSTDATE = @dtCurrentDate, 
		POSTPERIOD = @nPostPeriod,
		TRANSTYPE = 511, 
		ITEMPRETAXVALUE = -1*DH.ITEMPRETAXVALUE, 
		LOCALTAXAMT = -1*DH.LOCALTAXAMT, 
		LOCALVALUE = -1*DH.LOCALVALUE, 
		FOREIGNTAXAMT = Case when T.CURRENCY is not null then -1*DH.FOREIGNTAXAMT else DH.FOREIGNTAXAMT end,
		FOREIGNTRANVALUE = Case when T.CURRENCY is not null then -1*DH.FOREIGNTRANVALUE else DH.FOREIGNTRANVALUE end,
		FOREIGNBALANCE = Case when T.CURRENCY is not null then -1*DH.FOREIGNBALANCE else DH.FOREIGNBALANCE end,
		REASONCODE = @psCreditReasonCode, 
		LOCALBALANCE = -1*DH.LOCALBALANCE,
		STATUS = DH.STATUS,
		GLMOVEMENTNO = NULL
		From #TEMPDEBTORHISTORY DH
		JOIN #TEMPCREDITOPENITEM T on (DH.ITEMENTITYNO = T.ITEMENTITYNO and DH.ITEMTRANSNO = @pnItemTransNo
						    and DH.ACCTENTITYNO = T.ACCTENTITYNO and DH.ACCTDEBTORNO = T.ACCTDEBTORNO)"

		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@psCreditReasonCode nvarchar(12),
		@pnItemTransNo int,
		@nTransNo int,
		@pdtPostDate datetime,
		@nPostPeriod int,
		@dtCurrentDate datetime',
		@psCreditReasonCode = @psCreditReasonCode,
		@pnItemTransNo = @pnItemTransNo,
		@nTransNo = @nTransNo,
		@pdtPostDate = @pdtPostDate,
		@nPostPeriod = @nPostPeriod,
		@dtCurrentDate = @dtCurrentDate
		

	End
	
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
		Begin
			select 'insert history for the credit note into debtor history from temp table'
			Select * from #TEMPDEBTORHISTORY
		End

		Set @sSQLString = "						
		Insert into DEBTORHISTORY
		([ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO],
		[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
		[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
		[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
		[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
		[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO])
		Select 
		[ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],1,
		[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
		[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
		[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
		[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
		[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO]
		from #TEMPDEBTORHISTORY"
		
		exec @nErrorCode=sp_executesql @sSQLString
	End

	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select ' update the debtor ledger control totals'
			
			
		Declare cDebtorHistory cursor for
		Select MOVEMENTCLASS, TRANSTYPE, POSTPERIOD, EXCHVARIANCE, LOCALTAXAMT, LOCALVALUE
		From #TEMPDEBTORHISTORY
		
		Open cDebtorHistory
		Fetch Next From cDebtorHistory Into @nMovementClass, @nTransType, @nPostPeriod, @nExchVariance, @nLocalTaxAmt, @nLocalValue
		
		While @@FETCH_STATUS = 0
		Begin
			If (@nErrorCode = 0)
			Begin
				-- Call this procedure to insert/update as appropriate
				exec @nErrorCode = dbo.acw_UpdateControlTotal
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnLedger = 2,
				@pnCategory	= @nMovementClass,
				@pnType	= @nTransType,
				@pnPeriodId	= @nPostPeriod,
				@pnEntityNo	= @pnItemEntityNo,
				@pnAmountToAdd = @nLocalValue
			End
			
			
			If (@nErrorCode = 0)
			Begin
				If (@nExchVariance != 0 and @nExchVariance is not null )
					If (@nDebug = 1)
						select ' update the debtor ledger control totals for Exch Variance'

					-- Call this procedure to insert/update as appropriate
					exec @nErrorCode = dbo.acw_UpdateControlTotal
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@pbCalledFromCentura = @pbCalledFromCentura,
						@pnLedger = 2,
						@pnCategory	= 9,
						@pnType	= @nTransType,
						@pnPeriodId	= @nPostPeriod,
						@pnEntityNo	= @pnItemEntityNo,
						@pnAmountToAdd = @nExchVariance	
			End
			
			If (@nErrorCode = 0)
			Begin
				If (@nLocalTaxAmt != 0 and @nLocalTaxAmt is not null ) 
				Begin
					If (@nDebug = 1)
						select ' update the tax ledger control totals'
					
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
						@pnType	= @nTransType,
						@pnPeriodId	= @nPostPeriod,
						@pnEntityNo	= @pnItemEntityNo,
						@pnAmountToAdd = @nLocalTaxAmt	
				End
			End		
			
			Fetch Next From cDebtorHistory Into @nMovementClass, @nTransType, @nPostPeriod, @nExchVariance, @nLocalTaxAmt, @nLocalValue
		End
		Close cDebtorHistory
		Deallocate cDebtorHistory
	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
		Begin
			select '-- update account - adjust the account balance by the sum of localvalue from tempdebtorhistory'
			select A.BALANCE + sum(isnull(T.LOCALVALUE,0)), A.ENTITYNO , A.NAMENO 
				From ACCOUNT A
				Join #TEMPDEBTORHISTORY T on (A.ENTITYNO =  T.ACCTENTITYNO 
								and A.NAMENO = T.ACCTDEBTORNO)
				group by A.BALANCE, A.ENTITYNO , A.NAMENO 

			select * from #TEMPDEBTORHISTORY

			SELECT * 
			From ACCOUNT A
			Join #TEMPDEBTORHISTORY T on (A.ENTITYNO =  T.ACCTENTITYNO 
							and A.NAMENO = T.ACCTDEBTORNO)
		End
		
		insert into #TEMPBALANCE
		select A.BALANCE + sum(isnull(T.LOCALVALUE,0)), A.ENTITYNO , A.NAMENO 
				From ACCOUNT A
				Join #TEMPDEBTORHISTORY T on (A.ENTITYNO =  T.ACCTENTITYNO 
								and A.NAMENO = T.ACCTDEBTORNO)
				group by A.BALANCE, A.ENTITYNO , A.NAMENO 
			
		Set @sSQLString = "Update A
				Set A.BALANCE = isnull(T.BALANCE,0)
				From ACCOUNT A
				Join #TEMPBALANCE T on (A.ENTITYNO =  T.ENTITYNO 
								and A.NAMENO = T.NAMENO)"


		exec @nErrorCode=sp_executesql @sSQLString

	End
	
	If (@nErrorCode = 0)
	Begin
		--Tax history rows get written against the credit note and this behaviour is different from c/s.
		--C/S writes all the history rows against the original open item.
		If (@nDebug = 1)
		Begin
			Select '-- Now put in the tax history if there is any'
			Select O1.ITEMTRANSNO, DH.ITEMENTITYNO, DH.ITEMTRANSNO, DH.ACCTENTITYNO, DH.ACCTDEBTORNO,
			@pnItemEntityNo, @nTransNo, TH.ACCTENTITYNO, TH.ACCTDEBTORNO, DH.MAXHISTORYLINENO, TH.TAXCODE,
				TH.TAXRATE, -1*TH.TAXABLEAMOUNT, -1*TH.TAXAMOUNT, TH.COUNTRYCODE, O1.ITEMENTITYNO, O1.ITEMTRANSNO, 
				TH.STATE, TH.HARMONISED, TH.TAXONTAX,TH.MODIFIED, TH.ADJUSTMENT 
				from TAXHISTORY TH
				Join #TEMPOPENITEM T		on (T.ITEMTRANSNO = TH.ITEMTRANSNO 
								and T.ITEMENTITYNO = TH.ITEMENTITYNO
								and T.ACCTENTITYNO = TH.ACCTENTITYNO 
								and T.ACCTDEBTORNO = TH.ACCTDEBTORNO)
				Join (Select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, MAX(HISTORYLINENO) MAXHISTORYLINENO
						From DEBTORHISTORY
						Where ITEMENTITYNO = @pnItemEntityNo
						and ITEMTRANSNO = @nTransNo
						and ITEMIMPACT = 1
						GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) AS DH 
					on (DH.ITEMENTITYNO = @pnItemEntityNo
					and DH.ITEMTRANSNO = @nTransNo
					and DH.ACCTENTITYNO = T.ACCTENTITYNO
					and DH.ACCTDEBTORNO = T.ACCTDEBTORNO)
				Join OPENITEM O1 on (T.OPENITEMNO = O1.ASSOCOPENITEMNO
							AND O1.ITEMENTITYNO = @pnItemEntityNo
							AND O1.ITEMTRANSNO = @nTransNo)
				WHERE DH.MAXHISTORYLINENO = TH.HISTORYLINENO
		End
			
		Set @sSQLString = "Insert into TAXHISTORY (ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO, TAXCODE,
		TAXRATE, TAXABLEAMOUNT, TAXAMOUNT, COUNTRYCODE, REFENTITYNO, REFTRANSNO, STATE, HARMONISED, TAXONTAX,
		MODIFIED, ADJUSTMENT)
		Select 
		@pnItemEntityNo, @nTransNo, TH.ACCTENTITYNO, TH.ACCTDEBTORNO, DH.MAXHISTORYLINENO, TH.TAXCODE,
		TH.TAXRATE, -1*TH.TAXABLEAMOUNT, -1*TH.TAXAMOUNT, TH.COUNTRYCODE, O1.ITEMENTITYNO, O1.ITEMTRANSNO, 
		TH.STATE, TH.HARMONISED, TH.TAXONTAX,TH.MODIFIED, TH.ADJUSTMENT 
		from TAXHISTORY TH
		Join #TEMPOPENITEM T		on (T.ITEMTRANSNO = TH.ITEMTRANSNO 
						and T.ITEMENTITYNO = TH.ITEMENTITYNO
						and T.ACCTENTITYNO = TH.ACCTENTITYNO 
						and T.ACCTDEBTORNO = TH.ACCTDEBTORNO)
		Join (Select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, MAX(HISTORYLINENO) MAXHISTORYLINENO
				From DEBTORHISTORY
				Where ITEMENTITYNO = @pnItemEntityNo
				and ITEMTRANSNO = @nTransNo
				and ITEMIMPACT = 1
				GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) AS DH 
			on (DH.ITEMENTITYNO = @pnItemEntityNo
			and DH.ITEMTRANSNO = @nTransNo
			and DH.ACCTENTITYNO = T.ACCTENTITYNO
			and DH.ACCTDEBTORNO = T.ACCTDEBTORNO)
		Join OPENITEM O1 on (T.OPENITEMNO = O1.ASSOCOPENITEMNO
					AND O1.ITEMENTITYNO = @pnItemEntityNo
					AND O1.ITEMTRANSNO = @nTransNo)
		WHERE DH.MAXHISTORYLINENO = TH.HISTORYLINENO"
		
		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@pnItemEntityNo int,
		  @nTransNo int',
		@pnItemEntityNo = @pnItemEntityNo,
		@nTransNo = @nTransNo
	End
	
	If (@bARForPrepayments = 0)
	Begin
		If (@nDebug = 1)
			select '@bARForPrepayments = 0'
	
		If (@nErrorCode = 0 )
		Begin
			delete from #TEMPDEBTORHISTORY

			if (@nDebug = 1)
				Select 'insert into temp debtor history - Create an adjustment if the Debit Note OpenItem local balance is not zero.'
			
			/*KR1 - according to the c/s lines inserted, OPENITEMNO should come from #TEMPCREDITOPENITEM 
			GMOVEMENTNO should be 2*/
			/* CR 4.1 - This should be the DebtorHistory for the BILL not the credit note. 
			The only reference to the Credit Note here should be for the dates, transtype, refentityno and reftransno etc
			so as the logic suggests OPENITEMNO should be that for the bill and as mentioned above GLMOVEMENTNO should be NULL
			I found it a little confusing that OLDHISTORYLINENO was being set to the same thing as HISTORYLINENO 
			but I guess it doesn't really matter here because it is not subsequently referred to.*/

			Set @sSQLString = "Insert into #TEMPDEBTORHISTORY
			(ITEMENTITYNO, ITEMTRANSNO, HISTORYLINENO, OLDHISTORYLINENO, ACCTENTITYNO, ACCTDEBTORNO, 
			OPENITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, COMMANDID, ITEMIMPACT, GLMOVEMENTNO,
			LOCALVALUE, LOCALBALANCE, EXCHVARIANCE, 
			FOREIGNTRANVALUE, 
			FOREIGNBALANCE, 
			REFENTITYNO, REFTRANSNO, TOTALEXCHVARIANCE,
			CURRENCY, EXCHRATE, FORCEDPAYOUT, STATUS, LOCALTAXAMT, ITEMPRETAXVALUE)
			Select distinct T1.ITEMENTITYNO, T1.ITEMTRANSNO, DH.HISTORYLINENO, DH.HISTORYLINENO, T1.ACCTENTITYNO, T1.ACCTDEBTORNO, 
			T1.OPENITEMNO, @pdtPostDate, @dtCurrentDate, @nPostPeriod, 511, 5, 6, null, null,
			(-1 * T1.LOCALBALANCE), 0, 0, 
			Case when T1.CURRENCY is not null then (-1 * T1.FOREIGNBALANCE) else null end,
			Case when T1.CURRENCY is not null then 0 else null end, 
			T.ITEMENTITYNO, T.ITEMTRANSNO, T1.EXCHVARIANCE,
			T.CURRENCY, T.EXCHRATE, 0, 1, (-1*T1.LOCALTAXAMT), (-1*T1.ITEMPRETAXVALUE) 
			From #TEMPCREDITOPENITEM T
			Join #TEMPOPENITEM T1	on (T.OLDOPENITEMNO = T1.OPENITEMNO)
			Join (Select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, 
				max(HISTORYLINENO)+1 as HISTORYLINENO
				from DEBTORHISTORY 
				group by ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) DH
						on (DH.ITEMENTITYNO = T1.ITEMENTITYNO 
						and DH.ITEMTRANSNO = T1.ITEMTRANSNO
						and DH.ACCTENTITYNO = T1.ACCTENTITYNO 
						and DH.ACCTDEBTORNO = T1.ACCTDEBTORNO)
			Where T.LOCALORIGTAKENUP != 0"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pdtPostDate datetime,
			@nPostPeriod int,
			@dtCurrentDate datetime',
			@pdtPostDate = @pdtPostDate,
			@nPostPeriod = @nPostPeriod,
			@dtCurrentDate = @dtCurrentDate

		End
		
		If (@nErrorCode = 0)
		Begin
			If (@nDebug = 1)
			Begin
				select 'insert debit note entry into debtor history from temp table'
				Select * from #TEMPDEBTORHISTORY
			End
			
			Select @nDHCount = count(*) from #TEMPDEBTORHISTORY
			
			Set @sSQLString = "						
			Insert into DEBTORHISTORY
			([ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO],
			[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
			[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
			[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
			[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
			[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO])
			Select 
			[ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO],
			[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
			[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
			[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
			[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
			[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO]
			from #TEMPDEBTORHISTORY"
			
			exec @nErrorCode=sp_executesql @sSQLString
		End
		
		if (@nErrorCode = 0)
		Begin
			delete from #TEMPDEBTORHISTORY
			if (@nDebug = 1)
				Select 'insert to temp debtor history - Need the converse trans for credit'
					
			Set @sSQLString = "Insert into #TEMPDEBTORHISTORY
			(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, HISTORYLINENO, 
			OLDHISTORYLINENO, OPENITEMNO, TRANSDATE, POSTDATE, POSTPERIOD, TRANSTYPE, MOVEMENTCLASS, COMMANDID, 
			ITEMIMPACT, LOCALVALUE, LOCALBALANCE, EXCHVARIANCE, LOCALTAXAMT, ITEMPRETAXVALUE, 
			FOREIGNTRANVALUE, FOREIGNBALANCE, TOTALEXCHVARIANCE, REFENTITYNO, REFTRANSNO, GLMOVEMENTNO, STATUS, 
			CURRENCY, EXCHRATE, FORCEDPAYOUT )
			Select distinct T.ITEMENTITYNO, T.ITEMTRANSNO, T.ACCTENTITYNO, T.ACCTDEBTORNO, DH.HISTORYLINENO,  
			0, T.OPENITEMNO, @pdtPostDate, @dtCurrentDate, @nPostPeriod, 511, 4, 5,
			null, T1.LOCALBALANCE, T.LOCALBALANCE, 0, 
			T1.LOCALTAXAMT, T1.ITEMPRETAXVALUE, 		
			Case when T1.CURRENCY is not null then  T1.FOREIGNBALANCE else null end,
			Case when T1.CURRENCY is not null then T.FOREIGNBALANCE else null end, 0, 
			T.ITEMENTITYNO, T.ITEMTRANSNO, NULL, 1, T.CURRENCY, T.EXCHRATE, 0
			From #TEMPCREDITOPENITEM T
			Join #TEMPOPENITEM T1	on (T.OLDOPENITEMNO = T1.OPENITEMNO)
			Join (Select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, 
				max(HISTORYLINENO)+1 as HISTORYLINENO 
				from DEBTORHISTORY 
				group by ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) DH
						on (DH.ITEMENTITYNO = T.ITEMENTITYNO 
						and DH.ITEMTRANSNO = T.ITEMTRANSNO
						and DH.ACCTENTITYNO = T.ACCTENTITYNO 
						and DH.ACCTDEBTORNO = T.ACCTDEBTORNO)
				Where T.LOCALORIGTAKENUP != 0 "
			
			exec @nErrorCode=sp_executesql @sSQLString,
			N'@pdtPostDate datetime,
			@nPostPeriod int,
			@dtCurrentDate datetime',
			@pdtPostDate = @pdtPostDate,
			@nPostPeriod = @nPostPeriod,
			@dtCurrentDate = @dtCurrentDate
		End
		
		If (@nErrorCode = 0)
		Begin
			If (@nDebug = 1)
			Begin
				select 'insert credit note entry into debtor history from temp table'
				Select * from #TEMPDEBTORHISTORY
			End

			Set @sSQLString = "						
			Insert into DEBTORHISTORY
			([ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO],
			[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
			[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
			[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
			[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
			[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO])
			Select
			[ITEMENTITYNO],[ITEMTRANSNO],[ACCTENTITYNO],[ACCTDEBTORNO],[HISTORYLINENO],
			[OPENITEMNO],[TRANSDATE],[POSTDATE],[POSTPERIOD],[TRANSTYPE],[MOVEMENTCLASS],
			[COMMANDID],[ITEMPRETAXVALUE],[LOCALTAXAMT],[LOCALVALUE],[EXCHVARIANCE],[FOREIGNTAXAMT],
			[FOREIGNTRANVALUE],[REFERENCETEXT],[REASONCODE],[REFENTITYNO],[REFTRANSNO],[REFSEQNO],
			[REFACCTENTITYNO],[REFACCTDEBTORNO],[LOCALBALANCE],[FOREIGNBALANCE],[TOTALEXCHVARIANCE],
			[FORCEDPAYOUT],[CURRENCY],[EXCHRATE],[STATUS],[ASSOCLINENO],[ITEMIMPACT],[LONGREFTEXT],[GLMOVEMENTNO]
			from #TEMPDEBTORHISTORY"
			
			exec @nErrorCode=sp_executesql @sSQLString
		End
		
		If (@nErrorCode = 0)
		Begin
			if (@nDebug =1)
				Select 'update open item closepostdate and closepostperiod'

			Set @sSQLString = "Update OI Set CLOSEPOSTDATE = @dtCurrentDate, CLOSEPOSTPERIOD = @nPostPeriod,
			LOCALBALANCE = 0, FOREIGNBALANCE = 0
			From OPENITEM OI
			Join #TEMPCREDITOPENITEM T on (OI.OPENITEMNO = T.OLDOPENITEMNO and T.LOCALORIGTAKENUP != 0 and OI.ITEMENTITYNO = @pnItemEntityNo and OI.ITEMTRANSNO = @pnItemTransNo)"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@nPostPeriod int,
			  @dtCurrentDate	datetime,
			  @pnItemEntityNo	int,
			  @pnItemTransNo	int',
			@nPostPeriod = @nPostPeriod,
			@dtCurrentDate = @dtCurrentDate,
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo

		End
	End
	
	If (@nErrorCode = 0 )
	Begin
		Set @sSQLString = "Update OI 
		Set ASSOCOPENITEMNO = T.OPENITEMNO
		From OPENITEM OI
		Join #TEMPCREDITOPENITEM T on (OI.OPENITEMNO = T.OLDOPENITEMNO and OI.ITEMENTITYNO = @pnItemEntityNo and OI.ITEMTRANSNO = @pnItemTransNo)"
		
		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@pnItemEntityNo	int,
		  @pnItemTransNo	int',		
		@pnItemEntityNo = @pnItemEntityNo,
		@pnItemTransNo = @pnItemTransNo

	End


	If (@nErrorCode = 0 and @bQuotations = 1 )
	Begin
		If exists (Select * From INSTALMENT I 
			Join QUOTATION Q on (Q.QUOTATIONNO = I.QUOTATIONNO)
			where I.ENTITYNO = @pnItemEntityNo and I.TRANSNO = @pnItemTransNo 
			and I.QUOTATIONNO is not null and I.INSTALMENTNO is not null)
		Begin

			If (@nDebug = 1)
			Begin
				Select '-- unlink instalment if exists'	
				Select * From INSTALMENT I 
				Join QUOTATION Q	on (Q.QUOTATIONNO = I.QUOTATIONNO)
				where I.ENTITYNO = @pnItemEntityNo 
				and I.TRANSNO = @pnItemTransNo 
				and I.QUOTATIONNO is not null 
				and I.INSTALMENTNO is not null
			End

			Set @sSQLString = "Select @nInstalmentNo = I.INSTALLMENTNO, @nQuotationNo = Q.QUOTATIONNO, 
			@nExchRate = Q.EXCHANGERATE,
			@nForeignAmt = I.FOREIGNAMT
			From INSTALMENT I
			Join QUOTATION Q	on (Q.QUOTATIONNO = I.QUOTATIONNO)
			where I.ENTITYNO = @pnItemEntityNo 
			and I.TRANSNO = @pnItemTransNo 
			and I.QUOTATIONNO is not null 
			and I.INSTALMENTNO is not null"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
			N'@pnItemEntityNo int,
			  @pnItemTransNo int,
			  @nInstalmentNo int output,
			  @nQuotationNo int output',
			@pnItemEntityNo = @pnItemEntityNo,
			@pnItemTransNo = @pnItemTransNo,
			@nInstalmentNo = @nInstalmentNo output,
			@nQuotationNo = @nQuotationNo output
			
			If (@nErrorCode = 0)
			Begin
				if (@nExchRate is null)
					Set @nLocalAmt = @nForeignAmt
				Else
					Set @nLocalAmt = @nForeignAmt/@nExchRate
					
				Set @sSQLString = "Update INSTALMENT Set LOCALAMT = @nLocalAmt,
									 ENTITYNO = null,
									 TRANSNO = null
				where ENTITYNO = @pnItemEntityNo and TRANSNO = @pnItemTransNo"

				exec	@nErrorCode = sp_executesql @sSQLString,
				N'@pnItemEntityNo int,
				  @pnItemTransNo int,
				  @nLocalAmt decimal(12,2)',
				@pnItemEntityNo = @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo,
				@nLocalAmt = @nLocalAmt
				
				Set @sSQLString = "Update QUOTATION Set STATUS = 7402 Where QUOTATIONNO = @nQuotationNo"
				
				exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nQuotationNo int',
				@nQuotationNo = @nQuotationNo
			End
		End	
	End	
	
	-- Create Initial WIP Prepayment
	If @nErrorCode = 0 and 
	exists (select * from SITECONTROL WHERE CONTROLID = 'Cash Accounting' AND COLBOOLEAN = 1) and 
	exists (select 	1 
		from	SITECONTROL 
		where   CONTROLID = 'FI WIP Payment Preference'	
		and	case when isnull(PATINDEX('%PD%', COLCHARACTER), 0) > 0 then 1 else 0 end = 1)	
	Begin
			-- Write down the bill
			Insert into WIPPAYMENT (ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, LOCALTRANSVALUE, LOCALBALANCE,REFENTITYNO, REFTRANSNO)
			SELECT WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WP.PAYMENTSEQNO+1, WP.WIPCODE,
			WP2.LOCALBALANCE*-1, 0 LOCALBALANCE, @pnItemEntityNo, @nTransNo
			from 
			-- get the max PAYMENTSEQNO
			(     Select W.ENTITYNO, W.TRANSNO, W.WIPSEQNO, W.HISTORYLINENO, W.ACCTDEBTORNO, W.WIPCODE, MAX(W.PAYMENTSEQNO) PAYMENTSEQNO
			      from DEBTORHISTORY DH1 
			      join WORKHISTORY WH  ON WH.REFENTITYNO = DH1.ITEMENTITYNO        
							AND WH.REFTRANSNO = DH1.ITEMTRANSNO 
			      join WIPPAYMENT W on    (W.ENTITYNO = WH.ENTITYNO
						AND W.TRANSNO = WH.TRANSNO
						AND W.WIPSEQNO = WH.WIPSEQNO
						AND W.HISTORYLINENO = WH.HISTORYLINENO
						AND W.ACCTDEBTORNO = DH1.ACCTDEBTORNO)    

			      where DH1.ITEMENTITYNO = @pnItemEntityNo
			      and DH1.ITEMTRANSNO = @pnItemTransNo
			      and WH.MOVEMENTCLASS = 2
			      group by W.ENTITYNO, W.TRANSNO, W.WIPSEQNO, W.HISTORYLINENO, W.ACCTDEBTORNO, W.WIPCODE
			      ) WP
			-- current row to get the current balance
			JOIN WIPPAYMENT WP2 on (WP2.ENTITYNO = WP.ENTITYNO
					  and WP2.TRANSNO = WP.TRANSNO
					  and WP2.WIPSEQNO = WP.WIPSEQNO
					  and WP2.HISTORYLINENO = WP.HISTORYLINENO
					  AND WP2.ACCTDEBTORNO  = WP.ACCTDEBTORNO
					  AND WP2.PAYMENTSEQNO =  WP.PAYMENTSEQNO )
			WHERE WP2.LOCALBALANCE <> 0					  

			select 	@nErrorCode = @@ERROR				  
			

			If @nErrorCode = 0
			Begin
				-- Record the intital wip balance of the new credit note				
				Insert into WIPPAYMENT (ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, LOCALTRANSVALUE, LOCALBALANCE,REFENTITYNO, REFTRANSNO)
				Select WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.HISTORYLINENO, DH.ACCTDEBTORNO, 1 'PAYMENTSEQNO', WH.WIPCODE, 
				0 LOCALTRANSVALUE, round(WH.LOCALTRANSVALUE * (ISNULL(OI.BILLPERCENTAGE, 100) /100), 2) * -1 'LOCALBALANCE', @pnItemEntityNo, @nTransNo
				from DEBTORHISTORY DH 
				join OPENITEM OI   ON OI.ITEMENTITYNO = DH.ITEMENTITYNO       
						AND OI.ITEMTRANSNO = DH.ITEMTRANSNO       
						AND OI.ACCTENTITYNO = DH.ACCTENTITYNO       
						AND OI.ACCTDEBTORNO = DH.ACCTDEBTORNO  				
				join WORKHISTORY WH  ON WH.REFENTITYNO = DH.ITEMENTITYNO        
							AND WH.REFTRANSNO = DH.ITEMTRANSNO  
				where DH.ITEMENTITYNO = @pnItemEntityNo
				and DH.ITEMTRANSNO = @nTransNo
				and OI.LOCALBALANCE <> 0	
				and DH.MOVEMENTCLASS = 1	-- the debt created
				and WH.MOVEMENTCLASS = 2	-- billed wip only
				
				select 	@nErrorCode = @@ERROR				  
			End


			If @nErrorCode = 0
			Begin
				-- Record the credit note balance with the amount that used for paying the bill				
				Insert into WIPPAYMENT (ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, ACCTDEBTORNO, PAYMENTSEQNO, WIPCODE, LOCALTRANSVALUE, LOCALBALANCE,REFENTITYNO, REFTRANSNO)
				Select WP.ENTITYNO, WP.TRANSNO, WP.WIPSEQNO, WP.HISTORYLINENO, WP.ACCTDEBTORNO, WP.PAYMENTSEQNO+1, WP.WIPCODE, 
				WP2.LOCALBALANCE LOCALTRANSVALUE, WP2.LOCALTRANSVALUE 'LOCALBALANCE', @pnItemEntityNo, @nTransNo
				from WIPPAYMENT WP
				JOIN WIPPAYMENT WP2 on (WP2.ENTITYNO = WP.ENTITYNO
					  and WP2.TRANSNO = WP.TRANSNO
					  and WP2.WIPSEQNO = WP.WIPSEQNO
					  AND WP2.ACCTDEBTORNO  = WP.ACCTDEBTORNO)
				where WP.ENTITYNO =  @pnItemEntityNo
				and WP.REFTRANSNO =  @nTransNo
				and WP.PAYMENTSEQNO = 1
				and WP2.REFTRANSNO =  @pnItemTransNo
				and WP2.PAYMENTSEQNO <> 1
				and WP2.LOCALBALANCE <> 0
				
				select 	@nErrorCode = @@ERROR				  
			End
	End
	
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
	

	If (@nDebug = 1)
	Begin
		select 'Resulting data for this transaction'
		SELECT 'TRANSACTIONHEADER'
		SELECT *
		FROM TRANSACTIONHEADER
		WHERE ENTITYNO = @pnItemEntityNo 
		AND TRANSNO = @nTransNo

		SELECT 'BILLLINE'
		SELECT *
		FROM BILLLINE
		WHERE ITEMENTITYNO = @pnItemEntityNo 
		AND ITEMTRANSNO = @nTransNo

                select 'WORKINPROGRESS'
		SELECT *
		FROM WORKINPROGRESS WIP
		Join WORKHISTORY WH	on (WH.ENTITYNO = WIP.ENTITYNO
					and WH.TRANSNO = WIP.TRANSNO
					and WH.WIPSEQNO = WIP.WIPSEQNO)
		Where WH.ENTITYNO = @pnItemEntityNo
		and WH.TRANSNO in (select TRANSNO 
					from WORKHISTORY 
					where REFENTITYNO = @pnItemEntityNo 
					AND REFTRANSNO = @nTransNo)
		and WH.STATUS != 0

		select 'WORKHISTORY'
		select * 
		from WORKHISTORY
		WHERE REFENTITYNO = @pnItemEntityNo 
		AND REFTRANSNO = @nTransNo

		SELECT 'OPENITEM - CREDIT NOTE'
		SELECT * 
		FROM OPENITEM
		WHERE ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO = @nTransNo
		
		SELECT 'OPENITEM - BILL'
		SELECT * 
		FROM OPENITEM
		WHERE ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO = @pnItemTransNo

		SELECT 'DEBTORHISTORY'
		SELECT *
		FROM DEBTORHISTORY
		WHERE REFENTITYNO = @pnItemEntityNo 
		AND REFTRANSNO = @nTransNo

		SELECT 'OPENITEMTAX'
		SELECT * 
		FROM OPENITEMTAX
		WHERE ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO = @nTransNo

		SELECT 'TAXHISTORY'
		SELECT * 
		FROM TAXHISTORY
		WHERE ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO = @nTransNo

	End
		
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select '-- reconcile the WIP items'

		exec @nErrorCode = dbo.biw_ReconcileWIPItems
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture	= @psCulture,
		@pbCalledFromCentura = @pbCalledFromCentura,
		@pnItemEntityNo	= @pnItemEntityNo, 
		@pnItemTransNo	= @nTransNo
	End


	-- Create Activity request (documents)
	-- AT: I copied and adjusted this doc gen code from biw_FinaliseOpenItem
	Declare @nBillFormatId int
	Declare @nLanguage int
	Declare @nEntityNo int
	Declare @nDebtorNo int

	Declare @nMainCaseId int
	Declare @sCaseType nvarchar(1)
	Declare @sAction nvarchar(2)
	Declare @sPropertyType nvarchar(1)
	Declare @nSingleCase int
	Declare @nEmployeeNo int
	Declare @nBillLetterNo int
	Declare @nCoveringLetterNo int
	Declare @sDebitOpenItemNo nvarchar(12)
	Declare @sCreditOpenItemNo nvarchar(12)
	Declare @sDebtorNameType nvarchar(3)
	Declare @dBillPercentage decimal(5,2)
	Declare @bIsSplitBill bit
	
	Declare @nNoOfCaseRows int

	If (@nDebug = 1)
	Begin
		Print 'Generate Activity Request.'
	End

	if (@nErrorCode = 0)
	Begin
		Set @sSQLString = "
			SELECT @nMainCaseId = 
				(SELECT TOP 1 CASEID
				FROM #TEMPCASEID
				ORDER BY ISMAINCASE DESC),
			@nNoOfCaseRows = 
				(select count(*) FROM #TEMPCASEID)"
			
		exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nMainCaseId int OUTPUT,
				@nNoOfCaseRows int OUTPUT',
				@nMainCaseId = @nMainCaseId OUTPUT,
				@nNoOfCaseRows = @nNoOfCaseRows OUTPUT
				
		If (@nNoOfCaseRows = 0)
			Set @nSingleCase = 2
		Else If (@nNoOfCaseRows = 1)
			Set @nSingleCase = 1
		Else
			Set @nSingleCase = 0
	End
	
	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "Select @bIsSplitBill = CASE WHEN TOICOUNT.LINES > 1 THEN 1 ELSE 0 END
			FROM (Select count(*) as LINES from #TEMPOPENITEM) AS TOICOUNT"
	
		exec	@nErrorCode = sp_executesql @sSQLString,
							N'@bIsSplitBill bit output',
							@bIsSplitBill = @bIsSplitBill output
	End
					
	If (@nErrorCode = 0 and @nMainCaseId is not null)
	Begin
		If (@nDebug = 1)
		Begin
			Print 'Get Case details to insert into ACTIVITYREQUEST'
		End

		Set @sSQLString = "SELECT	@sCaseType = C.CASETYPE,
			@sPropertyType = C.PROPERTYTYPE
			FROM CASES C
			WHERE C.CASEID = @nMainCaseId"

		exec @nErrorCode=sp_executesql @sSQLString, 
					N'@sCaseType		nvarchar(1) OUTPUT,
					  @sPropertyType	nvarchar(1) OUTPUT,
					  @nMainCaseId		int',
					  @sCaseType = @sCaseType OUTPUT,
					  @sPropertyType = @sPropertyType OUTPUT,
					  @nMainCaseId = @nMainCaseId
	End

	if (@nErrorCode = 0)
	Begin
		-- Get the properties required to retrieve the letter for each openitem
		DECLARE CreditOpenItem_Cursor CURSOR FOR 
			SELECT O.BILLFORMATID, O.LANGUAGE, O.ACCTENTITYNO, O.ACCTDEBTORNO, O.ACTION, O.EMPLOYEENO,
			B.DEBITNOTE, B.COVERINGLETTER, O.OPENITEMNO, TC.OPENITEMNO,
			case when TC.RENEWALDEBTORFLAG = 1 then 'Z' else 'D' end, TC.BILLPERCENTAGE
			FROM #TEMPOPENITEM O
			JOIN #TEMPCREDITOPENITEM TC ON TC.ASSOCOPENITEMNO = O.OPENITEMNO
			Left Join BILLFORMAT B ON B.BILLFORMATID = O.BILLFORMATID

		OPEN CreditOpenItem_Cursor

		FETCH NEXT FROM CreditOpenItem_Cursor 
		INTO @nBillFormatId, @nLanguage, @nEntityNo, @nDebtorNo, @sAction, @nEmployeeNo,
		@nBillLetterNo, @nCoveringLetterNo, @sDebitOpenItemNo, @sCreditOpenItemNo,
		@sDebtorNameType, @dBillPercentage

		WHILE (@nErrorCode = 0 and @@FETCH_STATUS = 0)
		Begin
			-- if credit full bill and related debit note has no bill format (cfIsDocGenBillReq)
			If @nErrorCode = 0 
				and exists (SELECT * FROM #TEMPOPENITEM WHERE BILLFORMATID IS NULL)
			Begin
				Set @nBillLetterNo = null
				Set @nCoveringLetterNo = null

				If (@nCreditBillLetterGen = 1) -- (cfIsActivityRequestLetterReq)
				Begin
					-- Get the letter from ActivityHistory (cfRetrieveChGenLetters)
					select
					@nBillLetterNo = A.LETTERNO, 
					@nCoveringLetterNo = A.COVERINGLETTERNO
					From ACTIVITYHISTORY A
					where A.DEBITNOTENO = @sDebitOpenItemNo
					and A.ACTIVITYCODE IN (3202, 3204)
					and A.LETTERNO IS NOT NULL
					
					Set @nErrorCode = @@ERROR

				End
				Else If (@nCreditBillLetterGen = 2)
				Begin					
					-- Retrieve best fit Bill Format
					exec @nErrorCode = dbo.biw_FetchBestBillFormat
							@pnUserIdentityId = @pnUserIdentityId,		-- Mandatory
							@psCulture = @psCulture,
							@pbCalledFromCentura = @pbCalledFromCentura,
							@pnBillFormatId = @nBillFormatId OUTPUT,
							@pnLanguage	= @nLanguage, -- Set the remainder if best fit is to be used.
							@pnEntityNo = @nEntityNo,
							@pnNameNo = @nDebtorNo,
							@psCaseType = @sCaseType,
							@psAction = @sAction,
							@psPropertyType	= @sPropertyType,
							@pnRenewalWIP =	null, -- always null in this case
							@pnSingleCase = @nSingleCase,
							@pnEmployeeNo = @nEmployeeNo,
							@pnOfficeId	= @nOfficeId,
							@pbReturnBillFormatDetails = 0

					If (@nBillFormatId is not null)
					Begin
						Select 
						@nBillLetterNo = B.DEBITNOTE,
						@nCoveringLetterNo = B.COVERINGLETTER
						from BILLFORMAT B
						WHERE BILLFORMATID = @nBillFormatId
					End
				End
			End
			Else
			Begin
				If (@nBillLetterNo is not null)
				Begin
					If not exists (Select * from WORKHISTORY 
									Where REFENTITYNO = @pnItemEntityNo and REFTRANSNO = @pnItemTransNo
									and CASEID is not null)
					Begin
						-- DEBTOR ONLY BILL can only generate a letter with NameNo as entry point.
						If not exists (Select * from LETTER
										Where ENTRYPOINTTYPE = 4041 or ENTRYPOINTTYPE is null
										And LETTERNO = @nBillLetterNo)
						Begin
							Set @nBillLetterNo = null
						End
					End
				End
			End

			If (@nErrorCode = 0 and @nBillLetterNo is not null)
			Begin
			
				If (@nDebug = 1)
				Begin
					Print 'Insert into ACTIVITYREQUEST'
				End
			
				-- Insert Activity Request
				Insert into ACTIVITYREQUEST
				(
				CASEID, WHENREQUESTED, SQLUSER,
				ENTITYNO, DEBTORNAMETYPE, LETTERDATE,
				PROGRAMID,
				LETTERNO, COVERINGLETTERNO, HOLDFLAG, INSTRUCTOR,
				SPLITBILLFLAG,
				BILLPERCENTAGE,
				DEBITNOTENO,
				ACTIVITYTYPE,
				ACTIVITYCODE,
				PROCESSED,
				DEBTOR,
				IDENTITYID
				)
				select
				@nMainCaseId, GETDATE(), system_user,
				@nEntityNo, @sDebtorNameType, GETDATE(),
				'BILLING',
				@nBillLetterNo, @nCoveringLetterNo, L.HOLDFLAG,
				@nDebtorNo, -- instructor
				@bIsSplitBill,
				@dBillPercentage,
				CASE WHEN @sCreditOpenItemNo = "" then NULL ELSE @sCreditOpenItemNo END,
				32, -- activitytype (System Activity)
				3204, -- activity (letter)
				0, -- PROCESSED
				@nDebtorNo, -- debtor
				@pnUserIdentityId
				From LETTER L 
				Where L.LETTERNO = @nBillLetterNo
			End

			FETCH NEXT FROM CreditOpenItem_Cursor 
			INTO @nBillFormatId, @nLanguage, @nEntityNo, @nDebtorNo, @sAction, @nEmployeeNo,
				 @nBillLetterNo, @nCoveringLetterNo, @sDebitOpenItemNo, @sCreditOpenItemNo,
				 @sDebtorNameType, @dBillPercentage
		End

		CLOSE CreditOpenItem_Cursor
		DEALLOCATE CreditOpenItem_Cursor

	End
	
	If (@nErrorCode = 0)
	Begin
		If (@nDebug = 1)
			select '-- raise events'

		Set @sSQLString = "Select @nCreditNoteEvent = EVENTNO from DEBTOR_ITEM_TYPE where ITEM_TYPE_ID = 511"
		
		exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nCreditNoteEvent int OUTPUT',
				@nCreditNoteEvent = @nCreditNoteEvent OUTPUT
		
		If (@nCreditNoteEvent is not null and @nNoOfCaseRows > 0)
		Begin
			Set @sSQLString = "Insert INTO CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCUREDFLAG)
			Select T.CASEID, @nCreditNoteEvent, max(isnull(CE.CYCLE,0))+1, @pdtPostDate, 1
			From #TEMPCASEID T
			Join CASEEVENT CE on (CE.CASEID = T.CASEID and CE.EVENTNO = @nCreditNoteEvent)"
			
			exec	@nErrorCode = sp_executesql @sSQLString,
				N'@nCreditNoteEvent int,
				@pdtPostDate datetime,
				@nCreditNoteEvent int',
				@nCreditNoteEvent = @nCreditNoteEvent,
				@pdtPostDate = @pdtPostDate,
				@nCreditNoteEvent = @nCreditNoteEvent
	
		End
		
	End
	
	If (@nErrorCode = 0)
	Begin
		commit transaction
		
		Set @sSQLString = "SELECT ITEMENTITYNO as 'ItemEntityNo',
					  ITEMTRANSNO as 'ItemTransNo',
					  OPENITEMNO as 'OpenItemNo' FROM #TEMPCREDITOPENITEM"
		exec @nErrorCode = sp_executesql @sSQLString
	End
	Else
		rollback transaction
End

return @nErrorCode
go

grant execute on dbo.[biw_CreditBill]  to public
go
