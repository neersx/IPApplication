-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_CreateAndPostJournals
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_CreateAndPostJournals]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_CreateAndPostJournals.'
	Drop procedure [dbo].[fi_CreateAndPostJournals]
End
Print '**** Creating Stored Procedure dbo.fi_CreateAndPostJournals...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.fi_CreateAndPostJournals
(
	@pnResult			int		= null output,	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		tinyint		= 0,
	@pbDebugFlag			tinyint		= 0,	
	@pnEntityNo			int		= null,
	@pnTransNo			int		= null,
	@pnDesignation			int		= null,
	@pnPeriodId			int		= null,
	@pbIncProcessedNoJournal	tinyint		= 0,
	@psTransTypeIds			nvarchar(255)	= null, -- comma seperated list of Transaction Types
	@pbCalculateJournalOnly		bit		= 0,	-- 1 = calculate and return journal details without saving to database
	@pbCashAcctAR			bit		= 0	-- 1 = Calculate AR journals for transactions created outside of AR module.  e.g. AR/AP offset. 
)
as
-- PROCEDURE:	fi_CreateAndPostJournals
-- VERSION:	33
-- COPYRIGHT:	Copyright CPA Global Software Solutions Australia Pty Ltd 
-- DESCRIPTION:	Called from Time and Billing and Accounting Modules to process
--		Accounting transactions into GLJournals (in FI).

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	----------------------------------------------- 
-- 06 Nov 2009	CR	RFC8407		1	Procedure created
-- 29 Dec 2009	CR	SQA18341	2	Change Key fields of Debtors to be consistent 
--									with the WIP Ledger
-- 10 Feb 2010	CR	SQA18351	3	Implement Sales Tax for Cash Accounting
-- 04 Jun 2010	AT	RFC9420	4	Fix variable declaration errors.
-- 20 Jul 2010  DL	SQA17799	5	Calculate and return journal details without saving to database
-- 08 Oct 2010	DL	SQA18901	6	Fix incorrect tax calculation when MOVEMENTCLASS = 2
-- 11 Nov 2010	AT	RFC9919	7	Fix table alias error.
-- 11 May 2011	KR	RFC10616	8	fixing an issue with sql statement merge
-- 28 Jul 2011	KR	RFC11034	9	Fix a sql syntax error in the where clause of the
--						sql -- Insert Description in Temporary Table.
-- 12 Aug 2011	KR	RFC11040	10	Fixed merge issues
-- 09 Aug 2011	AT	RFC10241	10	Unset the debug flag.
-- 15 Aug 2011	DL	SQA19897	11	Fix divide by zero error when posting $0 invoice.
-- 17 May 2012 DL	SQA20452	12	Recalculate tax for tax ledger using proportional calcuation instead of DEBTORHISTORY.LOCALTAXAMT as it is not recorded for partial payment.
-- 18 Jul 2012	CR	SQA20666	13	re-implement use of DEBTORHISTORY.ITEMPRETAXVALUE in (IL5) 
-- 						and DEBTORHISTORY.LOCALTAXAMT in (IL7) on conditional basis 
-- 3 Oct 2013	DL	SQA21342	14	Added TAXCODE, DEBTORTYPE and DESTINATIONCOUNTRY to Debtor and Tax ledger
-- 11 Dec 2013	DL	SQA21691	15	Not creating journal lines in Cash Accounting when using derive to determine Profit Centre
-- 24 Jun 2014	DL	RFC34800	16	SQA22138 - Incorrect GL Journal on AR/AP Offset in Cash accounting - fixed issues with discounted wip, multiple debtor invoices and rounding errors.
-- 7 May 2015	DL	R46377		17	Credit Full Bill creating an invalid GL Journal (bill has no partial credit applied)
-- 11 May 2015	DL	R46271		18	GL Journals are created based on the WIPPAYMENT rows for bill and its reversal with credit applied
-- 28 May 2015	DL	R46271		19	Handle credit full bill transactions
-- 02 Jun 2015	DL	R46271		20	Handle credit full bill / reversal of multi-debtor bill in Cash Accounting.
-- 15 Jun 2015	DL	R46271		21	Handle credit full bill and reversal for bills associated with multiple wip. 
-- 17 Jun 2015	DL	R46271		22	Performance enhancement. 
-- 26 Jun 2015	DL	R48445		23	Incorrect journal entries created for Client Refund transactions.
-- 30 Jul 2015	DL	R48744		24	Incorrect journal entries created for AR/AP offset transactions
-- 12 Aug 2015	DL	R50839		25	Fix bug Invalid Journal - Credit Full Bill 
-- 16 Oct 2015	DL	RFC54078	26	AP/AR Offset is crashing with a SQL Error when finalising.	
-- 11 May 2016	DL	RFC60728	27	Incorrect GL Journal when a bill that has credit WIP items is 'paid off'
-- 07 Jul 2016	MF	63861		28	A null LOCALCLIENTFLAG should default to 0.
-- 04 Oct 2016	DL	69137		29	Invoice could not be finalised with a large number of WIP items being billed and a credit being applied
-- 06 Feb 2017	DL	R70055		30	Extended fields for tax journal lines are not recorded in web Billing
-- 29 Jun 2017	DL	R71501		31	Zero-value Credit note creates unbalanced journals when associated debit WIP has tax
-- 24 Oct 2017	AK	R72645	        32	Make compatible with case sensitive server with case insensitive database.
-- 17 Oct 2018  MS      DR-43060        33      Added AcctEntityNo in WorkHistory

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

CREATE TABLE #TRANSACTIONID ( ENTITYNO integer NULL, 
				TRANSNO integer NULL )

CREATE TABLE #GLMAPPING (SEQNO integer identity PRIMARY KEY, 
				ACCOUNTTYPE integer NULL, 
				ENTITY integer NULL, 
				SOURCEOFFICEID integer NULL, 
				WIPINADVANCE decimal(1,0) NULL, 
				WIPCODE nvarchar(6) collate database_default NULL, 
				WIPTYPEID nvarchar(6) collate database_default NULL, 
				WIPCATEGORYCODE nvarchar(3) collate database_default NULL, 
				WIPEMPLOYEENO integer NULL, 
				STAFFCLASS integer NULL, 
				LOCALCLIENTFLAG decimal(1,0) NULL, 
    			        TAXCODE            NVARCHAR(3) COLLATE database_default NULL,
			        DEBTORTYPE         INTEGER NULL,
			        DESTINATIONCOUNTRY NVARCHAR(3) COLLATE database_default NULL,
				CURRENCY nvarchar(3) collate database_default NULL, 
				CASETYPE char(1) collate database_default NULL, 
				PROPERTYTYPE char(1) collate database_default NULL, 
				COUNTRY nvarchar(3) collate database_default NULL, 
				ACTION nvarchar(2) collate database_default NULL, 
				REASONCODE nvarchar(2) collate database_default NULL, 
				DEBTFROMWIP decimal(1,0) NULL, 
				INTERNALWORKFLAG decimal(1,0) NULL, 
				BANKENTITYNO integer NULL, 
				BANKNAMENO integer NULL, 
				BANKSEQUENCENO integer NULL, 
				DEBTORITEMTYPE integer NULL, 
				GLACCOUNTCODE nvarchar(100) collate database_default NULL, 
				LOCALAMOUNT decimal(11,2) NULL, 
				FOREIGNAMOUNT decimal(11,2) NULL, 
				BILLPERCENTAGE decimal(5,2) NULL, 
				TRANSNO integer NULL, 
				MOVEMENTCLASS smallint NULL, 
				AMOUNTTYPE integer NULL, 
				ACCTENTITYNO integer NULL, 
				ACCTPROFITCENTRE nvarchar(6) collate database_default NULL, 
				LEDGERACCOUNTID integer NULL, 
				CASEID integer NULL, 
				LEDGER integer NULL, 
				KEYFIELD1 integer NULL, 
				KEYFIELD2 integer NULL,	
				KEYFIELD3 integer NULL, 
				KEYFIELD4 integer NULL, 
				KEYFIELD5 integer NULL, 
				KEYFIELD6 integer NULL, 
				SMALLKEYFIELD1 integer NULL, 
				SMALLKEYFIELD2 integer NULL, 
				DESIGNATION integer NULL )

CREATE TABLE #GLDESCRIPTION ( ENTITYNO integer NULL, 
				TRANSNO integer NULL, 
				DESIGNATION integer NULL, 
				SEQNO integer NULL, 
				SEGMENTNO integer NULL, 
				SEPARATOR nvarchar(10) collate database_default NULL, 
				DESCRIPTION nvarchar(254) collate database_default NULL )

-- Generate movement no
-- Writing to a temporary table with the MovementNo defined as an Identity column was much faster than trying to update the TempGLMapping table
CREATE TABLE #GLMOVEMENTNO ( LEDGER integer NULL, 
				KEYFIELD1 integer NULL, 
				KEYFIELD2 integer NULL, 
				KEYFIELD3 integer NULL, 
				KEYFIELD4 integer NULL, 
				KEYFIELD5 integer NULL, 
				KEYFIELD6 integer NULL, 
				SMALLKEYFIELD1 integer NULL, 
				SMALLKEYFIELD2 integer NULL, 
				MOVEMENTNO integer identity )

-- Split WIP table used for WIP on Split Bills or calculating Billed WIP values for Cash Accounting
CREATE TABLE #SPLITWIP (SEQNO integer identity PRIMARY KEY, 
				ACCOUNTTYPE integer NULL, 
				BILLPERCENTAGE decimal(7,4) NULL,			-- SQA22138 change from decimal(5,2) to (7,4) to address rounding issue
				KEYFIELD1 integer NULL, 
				KEYFIELD2 integer NULL,	
				KEYFIELD3 integer NULL, 
				KEYFIELD4 integer NULL, 
				KEYFIELD5 integer NULL, 
				KEYFIELD6 integer NULL, 
				OPENITEMNO nvarchar(12) collate database_default NULL,
				LEDGER integer NULL, 
				LOCALAMOUNT decimal(11,2) NULL, 
				FOREIGNAMOUNT decimal(11,2) NULL, 
				SMALLKEYFIELD1 integer NULL, 
				SMALLKEYFIELD2 integer NULL, 
				MOVEMENTCLASS smallint NULL,
				DISCOUNTFLAG smallint NULL)				-- SQA22138 Handle discount



CREATE TABLE #TEMP_WIPPAYMENT(
	ENTITYNO int NOT NULL,
	TRANSNO int NOT NULL,
	WIPSEQNO smallint NOT NULL,
	HISTORYLINENO smallint NOT NULL,
	ACCTDEBTORNO int NOT NULL,
	PAYMENTSEQNO smallint NOT NULL,
	WIPCODE nvarchar(6) collate database_default NOT NULL,
	LOCALTRANSVALUE decimal(11, 2) NULL,
	FOREIGNTRANSVALUE decimal(11, 2) NULL,
	LOCALBALANCE decimal(11, 2) NULL,
	FOREIGNBALANCE decimal(11, 2) NULL,
	FOREIGNCURRENCY nvarchar(3) collate database_default NULL,
	REFENTITYNO int NULL,
	REFTRANSNO int NULL
)


declare	@nErrorCode		int
declare @nTransUsedBy		int
declare @nTransUsedByBilling	int
declare @nTransUsedByAR		int
declare @nTransUsedByCB		int
declare @bCashAccounting	bit
declare @bFIwithGL		bit
declare @bIsDebtorCaseRequired	bit
declare @sSQLString		nvarchar(MAX)
declare @sSelect		nvarchar(2000)
declare @sFrom			nvarchar(2000)
declare @sJoin			nvarchar(2000)
declare @sWhere			nvarchar(2000)
declare @nTransCount		int
declare @nJournalCount		int
declare @nSeqNo			int
declare @nTempSeqNo		int
declare @sGLAccountCode		nvarchar(100) 
declare @nContentId		int
declare @nTempContentId		int
declare @nNameData		int
declare @nSegNo			int
Declare @nPercentRemainder	decimal(5,2)
Declare @nTotalAmount		decimal(11,2)
Declare @nTotalAmountRemainder	decimal(11,2)
Declare @nTotalForeign		decimal(11,2)
Declare @nTotalForeignRemainder	decimal(11,2)
Declare @nSplitLocal		decimal(11,2)
Declare @nSplitForeign		decimal(11,2)
Declare @nPrevAccountType	int		
Declare @nPrevKeyField1		int
Declare @nPrevKeyField2		int
Declare @nPrevKeyField3		int
Declare @nPrevKeyField4		int
Declare @nPrevKeyField5		int
Declare @nPrevKeyField6		int
Declare @nPrevMovementClass	int
Declare @nPrevLedger		int
Declare @nPrevSmallKeyField1	int
Declare @nPrevSmallKeyField2	int
Declare @nCurrentAccountType	int
Declare @nCurrentKeyField1	int
Declare @nCurrentKeyField2	int
Declare @nCurrentKeyField3	int
Declare @nCurrentKeyField4	int
Declare @nCurrentKeyField5	int
Declare @nCurrentKeyField6	int
Declare @nCurrentMovementClass	int
Declare @nCurrentLedger		int
Declare @nCurrentSmallKeyField1	int
Declare @nCurrentSmallKeyField2	int
Declare @nBillPercentage	decimal(7,4)					-- SQA22138
Declare	@nLocalAmount		decimal(11,2) 
Declare @nForeignAmount		decimal(11,2)
Declare @nRowCount		int
Declare @nAdjLocalAmount	decimal(11,2)					-- SQA22138
Declare @nAdjForeignAmount	decimal(11,2)					-- SQA22138
Declare @bFIWipPaymentPref	bit


-- Initialise variables
Set @nErrorCode = 0
Set @nTransUsedByBilling = 2
Set @nTransUsedByAR = 4
Set @nTransUsedByCB = 16
Set @bCashAccounting = 0
Set @bFIWipPaymentPref = 0
Set @bFIwithGL = 0
Set @bIsDebtorCaseRequired = 0

Set @sSQLString = NULL
Set @sSelect = NULL
Set @sFrom = NULL
Set @sJoin = NULL
Set @sWhere = NULL

Set @nTransCount = 0
Set @nJournalCount = 0
set @nSeqNo = 0

If @pbDebugFlag = 1
Begin
	Print " -- Create necessary Temporary tables
CREATE TABLE #TRANSACTIONID ( ENTITYNO integer NULL, 
				TRANSNO integer NULL )

CREATE TABLE #GLMAPPING (SEQNO integer identity PRIMARY KEY, 
				ACCOUNTTYPE integer NULL, 
				ENTITY integer NULL, 
				SOURCEOFFICEID integer NULL, 
				WIPINADVANCE decimal(1,0) NULL, 
				WIPCODE nvarchar(6) collate database_default NULL, 
				WIPTYPEID nvarchar(6) collate database_default NULL, 
				WIPCATEGORYCODE nvarchar(3) collate database_default NULL, 
				WIPEMPLOYEENO integer NULL, 
				STAFFCLASS integer NULL, 
				LOCALCLIENTFLAG decimal(1,0) NULL, 
			        TAXCODE            NVARCHAR(3) COLLATE database_default NULL,
			        DEBTORTYPE         INTEGER NULL,
			        DESTINATIONCOUNTRY NVARCHAR(3) COLLATE database_default NULL,
				CURRENCY nvarchar(3) collate database_default NULL, 
				CASETYPE char(1) collate database_default NULL, 
				PROPERTYTYPE char(1) collate database_default NULL, 
				COUNTRY nvarchar(3) collate database_default NULL, 
				ACTION nvarchar(2) collate database_default NULL, 
				REASONCODE nvarchar(2) collate database_default NULL, 
				DEBTFROMWIP decimal(1,0) NULL, 
				INTERNALWORKFLAG decimal(1,0) NULL, 
				BANKENTITYNO integer NULL, 
				BANKNAMENO integer NULL, 
				BANKSEQUENCENO integer NULL, 
				DEBTORITEMTYPE integer NULL, 
				GLACCOUNTCODE nvarchar(100) collate database_default NULL, 
				LOCALAMOUNT decimal(11,2) NULL, 
				FOREIGNAMOUNT decimal(11,2) NULL, 
				BILLPERCENTAGE decimal(7,4) NULL, 
				TRANSNO integer NULL, 
				MOVEMENTCLASS smallint NULL, 
				AMOUNTTYPE integer NULL, 
				ACCTENTITYNO integer NULL, 
				ACCTPROFITCENTRE nvarchar(6) collate database_default NULL, 
				LEDGERACCOUNTID integer NULL, 
				CASEID integer NULL, 
				LEDGER integer NULL, 
				KEYFIELD1 integer NULL, 
				KEYFIELD2 integer NULL,	
				KEYFIELD3 integer NULL, 
				KEYFIELD4 integer NULL, 
				KEYFIELD5 integer NULL, 
				KEYFIELD6 integer NULL, 
				SMALLKEYFIELD1 integer NULL, 
				SMALLKEYFIELD2 integer NULL, 
				DESIGNATION integer NULL )

CREATE TABLE #GLDESCRIPTION ( ENTITYNO integer NULL, 
				TRANSNO integer NULL, 
				DESIGNATION integer NULL, 
				SEQNO integer NULL, 
				SEGMENTNO integer NULL, 
				SEPARATOR nvarchar(10) collate database_default NULL, 
				DESCRIPTION nvarchar(254) collate database_default NULL )

--Generate movement no
-- ! Writing to a temporary table with the MovementNo defined as an Identity column was much faster than trying to update the TempGLMapping table
CREATE TABLE #GLMOVEMENTNO ( LEDGER integer NULL, 
				KEYFIELD1 integer NULL, 
				KEYFIELD2 integer NULL, 
				KEYFIELD3 integer NULL, 
				KEYFIELD4 integer NULL, 
				KEYFIELD5 integer NULL, 
				KEYFIELD6 integer NULL, 
				SMALLKEYFIELD1 integer NULL, 
				SMALLKEYFIELD2 integer NULL, 
				MOVEMENTNO integer identity )

-- Split WIP table used for WIP on Split Bills or calculating Billed WIP values for Cash Accounting
CREATE TABLE #SPLITWIP (SEQNO integer identity PRIMARY KEY, 
				ACCOUNTTYPE integer NULL, 
				BILLPERCENTAGE decimal(7,4) NULL, 
				KEYFIELD1 integer NULL, 
				KEYFIELD2 integer NULL,	
				KEYFIELD3 integer NULL, 
				KEYFIELD4 integer NULL, 
				KEYFIELD5 integer NULL, 
				KEYFIELD6 integer NULL, 
				OPENITEMNO nvarchar(12) collate database_default NULL,
				LEDGER integer NULL, 
				LOCALAMOUNT decimal(11,2) NULL, 
				FOREIGNAMOUNT decimal(11,2) NULL, 
				SMALLKEYFIELD1 integer NULL, 
				SMALLKEYFIELD2 integer NULL, 
				MOVEMENTCLASS smallint NULL)
"

End

-- Determine if Cash Accounting is in use
If @nErrorCode = 0
Begin
	Set @sSQLString="		
	SELECT 	@bCashAccounting=COLBOOLEAN 
	FROM	SITECONTROL 
	WHERE   CONTROLID = 'Cash Accounting'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bCashAccounting	bit	OUTPUT',
			  @bCashAccounting	OUTPUT

	If @pbDebugFlag = 1
	Begin
		print @sSQLString
		Select @bCashAccounting as CASHACCOUNTING
	End
End


-- Determine if Cash Accounting is in use and payment by wip preference
If @nErrorCode = 0
Begin
	Set @sSQLString="		
	SELECT 	@bFIWipPaymentPref=case when isnull(PATINDEX('%PD%', COLCHARACTER), 0) > 0 then 1 else 0 end
	FROM	SITECONTROL 
	WHERE   CONTROLID = 'FI WIP Payment Preference'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bFIWipPaymentPref	bit	OUTPUT',
			  @bFIWipPaymentPref	OUTPUT

	If @pbDebugFlag = 1
	Begin
		print @sSQLString
		Select @bFIWipPaymentPref as 'CASHACCOUNTING WIP Payment Preferences'
	End
End


-- Determine if FI journals should be posted directly to GL
If @nErrorCode = 0
Begin
	Set @sSQLString="		
	SELECT 	@bFIwithGL=COLBOOLEAN 
	FROM	SITECONTROL 
	WHERE   CONTROLID = 'Financial Interface with GL'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bFIwithGL	bit	OUTPUT',
			  @bFIwithGL	OUTPUT

	If @pbDebugFlag = 1
	Begin
		print @sSQLString
		Select @bFIwithGL as FIWITHGL
	End
End


If (@nErrorCode=0)
Begin

	If exists (select * FROM GLFIELDRULECONTENT WHERE CONTENTID IN (10, 11, 29))
		Set @bIsDebtorCaseRequired = 1 
	Else 
		Set @bIsDebtorCaseRequired = 0
	
	If @pbDebugFlag = 1
		Select @bIsDebtorCaseRequired as DEBTORCASEREQUIRED	
End

-- Determine the Transaction Used By, if processing a batch the used by will be NULL
If (@nErrorCode = 0) AND 
(@pnEntityNo IS NOT NULL) AND (@pnTransNo IS NOT NULL) AND (@pnDesignation IS NOT NULL)
Begin
	Set @sSQLString="INSERT into #TRANSACTIONID (ENTITYNO, TRANSNO) 
	VALUES (@pnEntityNo, @pnTransNo)"	

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnEntityNo		int,
			@pnTransNo		int',
			@pnEntityNo,
			@pnTransNo 

	Set @nTransCount=@@Rowcount

	If @pbDebugFlag = 1
	Begin
		print ''
		print '-- Include specified transaction'
		print @sSQLString
	End	

	If @nTransCount=0
	Begin
		-- no additional processing required
		Set @nErrorCode = -1
	End

	If @nErrorCode=0
	Begin

		Set @sSQLString="SELECT @nTransUsedBy = ATT.USED_BY 
		FROM TRANSACTIONHEADER TH
		JOIN ACCT_TRANS_TYPE ATT	ON (ATT.TRANS_TYPE_ID = TH.TRANSTYPE)
		WHERE TH.ENTITYNO = @pnEntityNo 
		AND TH.TRANSNO = @pnTransNo"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@nTransUsedBy	int	OUTPUT,
			@pnEntityNo	int,
			@pnTransNo	int',
			@nTransUsedBy	OUTPUT,
			@pnEntityNo,
			@pnTransNo 

		If @pbDebugFlag = 1
		Begin
			print ''
			print '-- Determine what the Transaction''s Used by is'
			print @sSQLString
			Select @nTransUsedBy AS TRANSUSEDBY, @pnEntityNo AS ENTITYNO, @pnTransNo AS TRANSNO, @nTransCount AS TRANSCOUNT
		End
		

	End
End
Else
Begin
	Set @nTransUsedBy = NULL

	Set @sWhere = "WHERE ENTITYNO = " + CAST (@pnEntityNo as nvarchar)

	If  @pnPeriodId is NOT NULL
	Begin
		Set @sWhere = @sWhere + '
		AND TRANPOSTPERIOD = ' + CAST (@pnPeriodId as nvarchar)
	End 

	If @psTransTypeIds is NOT NULL
	Begin
		Set @sWhere = @sWhere + '
		AND TRANSTYPE IN (' + @psTransTypeIds + ')'
	End


	Set @sSQLString="INSERT INTO #TRANSACTIONID
	(ENTITYNO, TRANSNO)
	SELECT ENTITYNO, TRANSNO
	FROM TRANSACTIONHEADER 
	" + @sWhere + "
	AND TRANSTATUS <> 0 
	AND GLSTATUS = 0"
	

	
	exec @nErrorCode=sp_executesql @sSQLString
	Set @nTransCount=@@Rowcount		

	

	If @pbDebugFlag = 1
	Begin
		print ''
		Print '-- Include unprocessed transactions for the specified Entity, Period and transaction types'
		print @sSQLString
		Select @nTransUsedBy AS TRANSUSEDBY, @nTransCount AS TRANSCOUNT
	End

	If @nErrorCode=0 AND
	( @pnDesignation = 1 AND @pbIncProcessedNoJournal = 1)
	Begin
		Set @sSQLString="INSERT INTO #TRANSACTIONID
		(ENTITYNO, TRANSNO)
		SELECT ENTITYNO, TRANSNO
		FROM TRANSACTIONHEADER
		WHERE NOT EXISTS
			( SELECT * FROM GLJOURNAL GL
			  WHERE TRANSACTIONHEADER.ENTITYNO = GL.ENTITYNO
			  AND TRANSACTIONHEADER.TRANSNO = GL.TRANSNO
			  AND GL.DESIGNATION =  1 ) 
		" + @sWhere + "
		AND GLSTATUS = 1"

		exec @nErrorCode=sp_executesql @sSQLString

		Set @nTransCount=@nTransCount+@@Rowcount
		
		If @pbDebugFlag = 1
		Begin
			print ''
			print '-- Include Processed Journals'
			print @sSQLString
			Select @nTransUsedBy AS TRANSUSEDBY, @nTransCount AS TRANSCOUNT
		End

	End

	-- Check count of transactions, if 0 don't do anything.
	If @nTransCount = 0
	Begin
		Set @nErrorCode = -1
	End

End
	
/*
KeyField1 = H.ENTITYNO
KeyField2 = WH.TRANSNO OR BH OR CH.BANKNAMENO
KeyField3 = OI.ITEMENTITYNO OR BH OR CH.SEQUENCENO
KeyField4 = OI.ITEMTRANSNO OR CH.TRANSENTITYNO OR BH.HISTORYLINENO
KeyField5 = OI.ACCTENTITYNO OR CH.TRANSNO
KeyField6 = OI.ACCTDEBTORNO
SmallKeyField1 = WH.WIPSEQNO OR CH OR DH.HISTORYLINENO
SmallKeyField2 = WH.HISTORYLINENO
*/

-- Insert Account Mapping details by ledger relevant for the transaction(s) selected
If @pbDebugFlag = 1
Begin
	print ''
	Print '-- Insert Account Mapping details by ledger relevant for the transaction(s) selected'
End

If @nErrorCode=0 AND
(( @nTransUsedBy = NULL ) OR 
( @nTransUsedBy & @nTransUsedByBilling != 0))
Begin
	-- IDC_GLMAPPING_IL1 - WIP Ledger - joined to Debtor History
	/*
	KEYFIELD1 = WORKHISTORY.ENTITYNO    
	KEYFIELD2 = WORKHISTORY.TRANSNO
	KEYFIELD3 = OPENITEM.ITEMENTITYNO
	KEYFIELD4 = OPENITEM.ITEMTRANSNO
	KEYFIELD5 = OPENITEM.ACCTENTITYNO
	KEYFIELD6 = OPENITEM.ACCTDEBTORNO
	SMALLKEYFIELD1 =  WORKHISTORY.WIPSEQNO
	SMALLKEYFIELD2 = WORKHISTORY..HISTORYLINENO
	*/
	Set @sSQLString="INSERT INTO #GLMAPPING
	(LEDGER, ACCOUNTTYPE, ENTITY,
	WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
	LOCALCLIENTFLAG,
	CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
	REASONCODE,DEBTFROMWIP,BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
	GLACCOUNTCODE, LOCALAMOUNT, FOREIGNAMOUNT, BILLPERCENTAGE, TRANSNO,
	MOVEMENTCLASS, AMOUNTTYPE,
	KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
	SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION)
	SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO,
	NULL,
	H.WIPCODE, W.WIPTYPEID, WT.CATEGORYCODE,
	H.EMPLOYEENO, IP.LOCALCLIENTFLAG,
	DH.CURRENCY, C.CASEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, OI.ACTION,
	H.REASONCODE,
	NULL, NULL, NULL, NULL,
	NULL,
	CASE 	WHEN GLA.AMOUNTTYPE = 6618
		THEN H.LOCALCOST
		ELSE  H.LOCALTRANSVALUE
		END
		* CASE WHEN H.MOVEMENTCLASS IN (1, 4, 9) 
	THEN 1 ELSE -1 END
		* GLA.AMOUNTSIGN,
	CASE 	WHEN GLA.AMOUNTTYPE = 6618
		THEN H.FOREIGNCOST
		ELSE  H.FOREIGNTRANVALUE
		END
		* CASE WHEN H.MOVEMENTCLASS IN (1, 4, 9) 
	THEN 1 ELSE -1 END
		* GLA.AMOUNTSIGN,
	OI.BILLPERCENTAGE, H.REFTRANSNO,
	H.MOVEMENTCLASS, GLA.AMOUNTTYPE,
	H.ENTITYNO, H.TRANSNO, OI.ITEMENTITYNO, OI.ITEMTRANSNO, OI.ACCTENTITYNO, OI.ACCTDEBTORNO,
	H.WIPSEQNO, H.HISTORYLINENO, @pnDesignation
	FROM GLACCOUNTTYPE AT
	JOIN GLACCOUNTING GLA	ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
	JOIN WORKHISTORY H	ON GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
	JOIN #TRANSACTIONID TID	ON H.REFENTITYNO = TID.ENTITYNO 
				AND H.REFTRANSNO = TID.TRANSNO
	JOIN WIPTEMPLATE W	ON H.WIPCODE = W.WIPCODE
	JOIN WIPTYPE WT		ON W.WIPTYPEID = WT.WIPTYPEID
	JOIN DEBTORHISTORY DH	ON H.REFENTITYNO = DH.REFENTITYNO 
				AND H.REFTRANSNO = DH.REFTRANSNO
	JOIN OPENITEM OI	ON DH.ITEMENTITYNO = OI.ITEMENTITYNO 
				AND DH.ITEMTRANSNO = OI.ITEMTRANSNO 
				AND DH.ACCTENTITYNO = OI.ACCTENTITYNO 
				AND DH.ACCTDEBTORNO = OI.ACCTDEBTORNO
	JOIN IPNAME IP		ON OI.ACCTDEBTORNO = IP.NAMENO
	LEFT JOIN CASES C	ON H.CASEID = C.CASEID
	WHERE (AT.LEDGER = 1)
	AND (GLA.AMOUNTTYPE <> 6600)
	AND (DH.MOVEMENTCLASS = 1)"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDesignation int',
				@pnDesignation

	If @pbDebugFlag = 1
	Begin
		print ''
		Print '-- IDC_GLMAPPING_IL1 - WIP Ledger - joined to Debtor History'
		print @sSQLString
	End
End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR ( @nTransUsedBy & @nTransUsedByBilling != 0 ) )
Begin	
	-- IDC_GLMAPPING_IL2 - WIP Ledger - Case and no Debtor History
	/*
	KEYFIELD1 = WORKHISTORY.ENTITYNO    
	KEYFIELD2 = WORKHISTORY.TRANSNO
	KEYFIELD3 = 0
	KEYFIELD4 = 0
	KEYFIELD5 = 0
	KEYFIELD6 = 0
	SMALLKEYFIELD1 =  WORKHISTORY.WIPSEQNO
	SMALLKEYFIELD2 = WORKHISTORY.HISTORYLINENO
	*/
	Set @sSQLString="INSERT INTO #GLMAPPING
	(LEDGER, ACCOUNTTYPE, ENTITY,
	WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
	LOCALCLIENTFLAG,
	CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
	REASONCODE,DEBTFROMWIP,BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
	GLACCOUNTCODE, LOCALAMOUNT, FOREIGNAMOUNT, BILLPERCENTAGE, TRANSNO,
	MOVEMENTCLASS, AMOUNTTYPE,
	KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
	SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION, ACCTENTITYNO)
	SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO, 
	NULL, 
	H.WIPCODE, W.WIPTYPEID, WT.CATEGORYCODE,
	H.EMPLOYEENO, NULL,
	NULL, C.CASEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, NULL, 
	H.REASONCODE, 
	NULL, NULL, NULL, NULL, 
	NULL, 
	CASE 	WHEN GLA.AMOUNTTYPE = 6618
		THEN H.LOCALCOST
		ELSE  H.LOCALTRANSVALUE
		END
		* CASE WHEN H.MOVEMENTCLASS IN (1, 4, 9) 
	THEN 1 ELSE -1 END
		* GLA.AMOUNTSIGN,
	CASE 	WHEN GLA.AMOUNTTYPE = 6618
		THEN H.FOREIGNCOST
		ELSE  H.FOREIGNTRANVALUE
		END
		* CASE WHEN H.MOVEMENTCLASS IN (1, 4, 9) 
	THEN 1 ELSE -1 END
		* GLA.AMOUNTSIGN,
	100, H.REFTRANSNO, 
	H.MOVEMENTCLASS, GLA.AMOUNTTYPE,
	H.ENTITYNO, H.TRANSNO, 0, 0, 0, 0,
	H.WIPSEQNO, H.HISTORYLINENO, @pnDesignation, H.ENTITYNO
	FROM #TRANSACTIONID TID
	JOIN WORKHISTORY H	ON H.REFENTITYNO = TID.ENTITYNO 
				AND H.REFTRANSNO = TID.TRANSNO
	JOIN GLACCOUNTING GLA	ON GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
	JOIN GLACCOUNTTYPE AT	ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
	JOIN WIPTEMPLATE W	ON W.WIPCODE = H.WIPCODE
	JOIN WIPTYPE WT		ON W.WIPTYPEID = WT.WIPTYPEID
	LEFT JOIN CASES C	ON H.CASEID = C.CASEID
	WHERE AT.LEDGER = 1
	AND GLA.AMOUNTTYPE <> 6600
	AND NOT EXISTS
		( SELECT * FROM DEBTORHISTORY DH
		  WHERE DH.REFENTITYNO = H.REFENTITYNO
		  AND DH.REFTRANSNO = H.REFTRANSNO
		  AND DH.MOVEMENTCLASS = 1 )"

	/*FROM 	#TRANSACTIONID TID, WORKHISTORY H, GLACCOUNTING GLA, GLACCOUNTTYPE AT,
	WIPTEMPLATE W, WIPTYPE WT, CASES C
	WHERE 	AT.LEDGER = 1
	AND	AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
	AND	GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
	AND	GLA.AMOUNTTYPE <> 6600
	AND	TID.ENTITYNO = H.REFENTITYNO
	AND	TID.TRANSNO = H.REFTRANSNO
	AND	W.WIPCODE = H.WIPCODE
	AND 	W.WIPTYPEID = WT.WIPTYPEID
	AND	H.CASEID = C.CASEID
	AND	NOT EXISTS
		( SELECT * FROM DEBTORHISTORY DH
		  WHERE DH.REFENTITYNO = H.REFENTITYNO
		  AND	DH.REFTRANSNO = H.REFTRANSNO
		  AND	DH.MOVEMENTCLASS = 1 */

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDesignation int',
				@pnDesignation


	If @pbDebugFlag = 1
	Begin
		print ''
		Print '-- IDC_GLMAPPING_IL2 - WIP Ledger - Case and no Debtor History'
		print @sSQLString
	End	
End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR ( @nTransUsedBy & @nTransUsedByBilling != 0) )
Begin	
	-- IDC_GLMAPPING_IL3 - WIP Ledger - No Case and no Debtor History i.e. unbilled, debtor only WIP
	/*
	KEYFIELD1 = WORKHISTORY.ENTITYNO    
	KEYFIELD2 = WORKHISTORY.TRANSNO
	KEYFIELD3 = 0
	KEYFIELD4 = 0
	KEYFIELD5 = 0
	KEYFIELD6 = 0
	SMALLKEYFIELD1 =  WORKHISTORY.WIPSEQNO
	SMALLKEYFIELD2 = WORKHISTORY.HISTORYLINENO
	*/
	Set @sSQLString="INSERT INTO #GLMAPPING
	(LEDGER, ACCOUNTTYPE, ENTITY,
	WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
	LOCALCLIENTFLAG, 
	CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
	REASONCODE,DEBTFROMWIP,BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
	GLACCOUNTCODE, LOCALAMOUNT, FOREIGNAMOUNT, BILLPERCENTAGE, TRANSNO,
	MOVEMENTCLASS, AMOUNTTYPE,
	KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
	SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION, ACCTENTITYNO)
	SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO, 
	NULL,
	H.WIPCODE, W.WIPTYPEID, WT.CATEGORYCODE,
	H.EMPLOYEENO, IP.LOCALCLIENTFLAG, 
	NULL, NULL, NULL, NULL, NULL, NULL, 
	H.REASONCODE, 
	NULL, NULL, NULL, NULL, 
	NULL, 
	CASE 	WHEN GLA.AMOUNTTYPE = 6618
		THEN H.LOCALCOST
		ELSE  H.LOCALTRANSVALUE
		END
		* CASE WHEN H.MOVEMENTCLASS IN (1, 4, 9) 
	THEN 1 ELSE -1 END
		* GLA.AMOUNTSIGN,
	CASE 	WHEN GLA.AMOUNTTYPE = 6618
		THEN H.FOREIGNCOST
		ELSE H.FOREIGNTRANVALUE
		END
		* CASE WHEN H.MOVEMENTCLASS IN (1, 4, 9) 
	THEN 1 ELSE -1 END
		* GLA.AMOUNTSIGN,
	100, H.REFTRANSNO, 
	H.MOVEMENTCLASS, GLA.AMOUNTTYPE,
	H.ENTITYNO, H.TRANSNO, 0, 0, H.ACCTENTITYNO, 0,
	H.WIPSEQNO, H.HISTORYLINENO, @pnDesignation, H.ENTITYNO
	FROM #TRANSACTIONID TID
	JOIN WORKHISTORY H	ON H.REFENTITYNO = TID.ENTITYNO
				AND H.REFTRANSNO = TID.TRANSNO
	JOIN GLACCOUNTING GLA	ON GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
	JOIN GLACCOUNTTYPE AT	ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
	JOIN WIPTEMPLATE W	ON W.WIPCODE = H.WIPCODE
	JOIN WIPTYPE WT		ON WT.WIPTYPEID = W.WIPTYPEID
	LEFT JOIN IPNAME IP	ON IP.NAMENO = H.ACCTCLIENTNO
	WHERE AT.LEDGER = 1
	AND GLA.AMOUNTTYPE <> 6600
	AND H.CASEID IS NULL
	AND NOT EXISTS
		( SELECT * FROM DEBTORHISTORY DH
		  WHERE DH.REFENTITYNO = H.REFENTITYNO
		  AND DH.REFTRANSNO = H.REFTRANSNO
		  AND DH.MOVEMENTCLASS = 1 )"

	/*FROM 	#TRANSACTIONID TID, WORKHISTORY H, GLACCOUNTING GLA, GLACCOUNTTYPE AT,
	WIPTEMPLATE W, WIPTYPE WT, 
	IPNAME IP
	WHERE 	AT.LEDGER = 1
	AND	AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
	AND	GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
	AND	GLA.AMOUNTTYPE <> 6600
	AND	TID.ENTITYNO = H.REFENTITYNO
	AND	TID.TRANSNO = H.REFTRANSNO
	AND	W.WIPCODE = H.WIPCODE
	AND 	W.WIPTYPEID = WT.WIPTYPEID
	AND	H.CASEID IS NULL
	AND	H.ACCTCLIENTNO = IP.NAMENO
	AND	NOT EXISTS
		( SELECT * FROM DEBTORHISTORY DH
		  WHERE DH.REFENTITYNO = H.REFENTITYNO
		  AND	DH.REFTRANSNO = H.REFTRANSNO
		  AND	DH.MOVEMENTCLASS = 1*/ 

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnDesignation int',
			@pnDesignation
	
	
	If @pbDebugFlag = 1
	Begin
		print ''
		Print '-- IDC_GLMAPPING_IL3 - WIP Ledger - No Case and no Debtor History i.e. unbilled, debtor only WIP'
		print @sSQLString
	End
End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR ( @nTransUsedBy & @nTransUsedByAR != 0) OR (@pbCashAcctAR  = 1) )
Begin	
	-- IDC_GLMAPPING_IL5 - Debtors ledger
	/*
	KEYFIELD1 = 0   
	KEYFIELD2 = 0
	KEYFIELD3 = DEBTORHISTORY.ITEMENTITYNO
	KEYFIELD4 = DEBTORHISTORY.ITEMTRANSNO
	KEYFIELD5 = DEBTORHISTORY.ACCTENTITYNO
	KEYFIELD6 = DEBTORHISTORY.ACCTDEBTORNO
	SMALLKEYFIELD1 = DEBTORHISTORY.HISTORYLINENO
	SMALLKEYFIELD2 = 0
	KeyField1 = H.ENTITYNO
	*/
	-- If payment is based on wip preferences then not all wips has payment.  Only extract data that has payment appplied.
	If @bFIWipPaymentPref = 1
	Begin
		Set @sSQLString="INSERT INTO #GLMAPPING
		(LEDGER, ACCOUNTTYPE, ENTITY,
		WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
		LOCALCLIENTFLAG,
		CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
		REASONCODE,DEBTFROMWIP,
		BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
		DEBTORITEMTYPE, GLACCOUNTCODE, 
		LOCALAMOUNT, 
		BILLPERCENTAGE, TRANSNO,
		MOVEMENTCLASS, AMOUNTTYPE,
		KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
		SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION, INTERNALWORKFLAG,
		DEBTORTYPE, DESTINATIONCOUNTRY)
		
		SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO,
		NULL, NULL, NULL, NULL,NULL,
		IP.LOCALCLIENTFLAG,
		H.CURRENCY, NULL, NULL, NULL, NULL, NULL,
		H.REASONCODE, convert(bit, TTYPE.USED_BY & 2),
		NULL, NULL, NULL,
		OI.ITEMTYPE, NULL,
		-- SQA19897 - Calculate before tax amount using proportion of OPENITEM.LOCALTAXAMT instead of DEBTORHISTORY.ITEMPRETAXVALUE (H.ITEMPRETAXVALUE is not recorded for partial payment)
		--	      Also ensure zero invoice can be posted 	
		CASE 	WHEN GLA.AMOUNTTYPE = 6612
			THEN  CASE WHEN  ISNULL(OI.LOCALVALUE, 0) =0 THEN 0 ELSE 
				CASE WHEN (H.ITEMPRETAXVALUE + H.LOCALTAXAMT) = H.LOCALVALUE THEN H.ITEMPRETAXVALUE
				ELSE (H.LOCALVALUE - (H.LOCALVALUE / OI.LOCALVALUE * OI.LOCALTAXAMT)) END
			END
			ELSE CASE WHEN GLA.AMOUNTTYPE = 6631
				 THEN H.LOCALTAXAMT
				 ELSE H.LOCALVALUE
				 END
			END
			* CASE WHEN H.MOVEMENTCLASS IN (1, 4) 
		THEN 1 ELSE -1 END
			* GLA.AMOUNTSIGN,
		NULL, H.REFTRANSNO,
		H.MOVEMENTCLASS, GLA.AMOUNTTYPE,
		0, 0, H.ITEMENTITYNO, H.ITEMTRANSNO, H.ACCTENTITYNO, H.ACCTDEBTORNO,
		H.HISTORYLINENO, 0, @pnDesignation, D.INTERNAL,
		IP.DEBTORTYPE, ADDR.COUNTRYCODE
		
		FROM #TRANSACTIONID TID
		JOIN DEBTORHISTORY H		ON H.REFENTITYNO = TID.ENTITYNO
						AND H.REFTRANSNO = TID.TRANSNO
		JOIN GLACCOUNTING GLA		ON GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
		JOIN GLACCOUNTTYPE AT		ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
		JOIN IPNAME IP			ON IP.NAMENO = H.ACCTDEBTORNO
		JOIN TRANSACTIONHEADER TH	ON TH.ENTITYNO = H.REFENTITYNO
						AND TH.TRANSNO = H.REFTRANSNO
		JOIN ACCT_TRANS_TYPE TTYPE	ON TTYPE.TRANS_TYPE_ID = TH.TRANSTYPE
		JOIN OPENITEM OI		ON OI.ITEMENTITYNO = H.ITEMENTITYNO
						AND OI.ITEMTRANSNO = H.ITEMTRANSNO
						AND OI.ACCTENTITYNO = H.ACCTENTITYNO
						AND OI.ACCTDEBTORNO = H.ACCTDEBTORNO
		JOIN DEBTOR_ITEM_TYPE D		ON D.ITEM_TYPE_ID = OI.ITEMTYPE
		LEFT JOIN NAME N		ON N.NAMENO = IP.NAMENO 
		LEFT JOIN ADDRESS ADDR		ON N.POSTALADDRESS = ADDR.ADDRESSCODE
		
		WHERE AT.LEDGER = 2
		AND ((AT.USEBILLEDWIPCRITERIA = 0) OR (AT.USEBILLEDWIPCRITERIA IS NULL) )
		AND GLA.AMOUNTTYPE <> 6600
		
		/*Only include credit notes that was created from a bill with payment applied*/
		AND NOT EXISTS  (SELECT 1 
				FROM DEBTORHISTORY DH2
				WHERE DH2.REFENTITYNO = H.REFENTITYNO 
				AND DH2.REFTRANSNO = H.REFTRANSNO 
				AND DH2.ITEMENTITYNO = H.ITEMENTITYNO
				AND DH2.ITEMTRANSNO  = H.ITEMTRANSNO
				AND DH2.ACCTDEBTORNO = H.ACCTDEBTORNO
				AND DH2.HISTORYLINENO = H.HISTORYLINENO
				AND DH2.TRANSTYPE in ( 511, 513)
				AND DH2.LOCALBALANCE = 0
				AND DH2.MOVEMENTCLASS = 4)
		
		"
	end
	else
	Begin
		-- SQA21342 Add DEBTORTYPE and DESTINATIONCOUNTRY
		Set @sSQLString="INSERT INTO #GLMAPPING
		(LEDGER, ACCOUNTTYPE, ENTITY,
		WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
		LOCALCLIENTFLAG,
		CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
		REASONCODE,DEBTFROMWIP,
		BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
		DEBTORITEMTYPE, GLACCOUNTCODE, 
		LOCALAMOUNT, 
		BILLPERCENTAGE, TRANSNO,
		MOVEMENTCLASS, AMOUNTTYPE,
		KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
		SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION, INTERNALWORKFLAG,
		DEBTORTYPE, DESTINATIONCOUNTRY)
		
		SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO,
		NULL, NULL, NULL, NULL,NULL,
		IP.LOCALCLIENTFLAG,
		H.CURRENCY, NULL, NULL, NULL, NULL, NULL,
		H.REASONCODE, convert(bit, TTYPE.USED_BY & 2),
		NULL, NULL, NULL,
		OI.ITEMTYPE, NULL,
		-- SQA19897 - Calculate before tax amount using proportion of OPENITEM.LOCALTAXAMT instead of DEBTORHISTORY.ITEMPRETAXVALUE (H.ITEMPRETAXVALUE is not recorded for partial payment)
		--	      Also ensure zero invoice can be posted 	
		CASE 	WHEN GLA.AMOUNTTYPE = 6612
			THEN  CASE WHEN  ISNULL(OI.LOCALVALUE, 0) =0 THEN 0 ELSE 
				CASE WHEN (H.ITEMPRETAXVALUE + H.LOCALTAXAMT) = H.LOCALVALUE THEN H.ITEMPRETAXVALUE
				ELSE (H.LOCALVALUE - (H.LOCALVALUE / OI.LOCALVALUE * OI.LOCALTAXAMT)) END
			END
			ELSE CASE WHEN GLA.AMOUNTTYPE = 6631
				 THEN H.LOCALTAXAMT
				 ELSE H.LOCALVALUE
				 END
			END
			* CASE WHEN H.MOVEMENTCLASS IN (1, 4) 
		THEN 1 ELSE -1 END
			* GLA.AMOUNTSIGN,
		NULL, H.REFTRANSNO,
		H.MOVEMENTCLASS, GLA.AMOUNTTYPE,
		0, 0, H.ITEMENTITYNO, H.ITEMTRANSNO, H.ACCTENTITYNO, H.ACCTDEBTORNO,
		H.HISTORYLINENO, 0, @pnDesignation, D.INTERNAL,
		IP.DEBTORTYPE, ADDR.COUNTRYCODE
		
		FROM #TRANSACTIONID TID
		JOIN DEBTORHISTORY H		ON H.REFENTITYNO = TID.ENTITYNO
						AND H.REFTRANSNO = TID.TRANSNO
		JOIN GLACCOUNTING GLA		ON GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
		JOIN GLACCOUNTTYPE AT		ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
		JOIN IPNAME IP			ON IP.NAMENO = H.ACCTDEBTORNO
		JOIN TRANSACTIONHEADER TH	ON TH.ENTITYNO = H.REFENTITYNO
						AND TH.TRANSNO = H.REFTRANSNO
		JOIN ACCT_TRANS_TYPE TTYPE	ON TTYPE.TRANS_TYPE_ID = TH.TRANSTYPE
		JOIN OPENITEM OI		ON OI.ITEMENTITYNO = H.ITEMENTITYNO
						AND OI.ITEMTRANSNO = H.ITEMTRANSNO
						AND OI.ACCTENTITYNO = H.ACCTENTITYNO
						AND OI.ACCTDEBTORNO = H.ACCTDEBTORNO
		JOIN DEBTOR_ITEM_TYPE D		ON D.ITEM_TYPE_ID = OI.ITEMTYPE
		LEFT JOIN NAME N		ON N.NAMENO = IP.NAMENO 
		LEFT JOIN ADDRESS ADDR		ON N.POSTALADDRESS = ADDR.ADDRESSCODE
		
		WHERE AT.LEDGER = 2
		AND ((AT.USEBILLEDWIPCRITERIA = 0) OR (AT.USEBILLEDWIPCRITERIA IS NULL) )
		AND GLA.AMOUNTTYPE <> 6600"
	end

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnDesignation int',
			@pnDesignation


	If @pbDebugFlag = 1
	Begin
		print ''
		Print '	-- IDC_GLMAPPING_IL5 - Debtors ledger'
		print @sSQLString
	End
End


If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR ( @nTransUsedBy & @nTransUsedByAR != 0) OR (@pbCashAcctAR  = 1) )
Begin	
	--IDC_GLMAPPING_IL6 - Debtors ledger - Exchange Gain/Loss
	/*
	KEYFIELD1 = 0 
	KEYFIELD2 = 0 
	KEYFIELD3 = DEBTORHISTORY.ITEMENTITYNO   
	KEYFIELD4 = DEBTORHISTORY.ITEMTRANSNO
	KEYFIELD5 = DEBTORHISTORY.ACCTENTITYNO
	KEYFIELD6 = DEBTORHISTORY.ACCTDEBTORNO
	SMALLKEYFIELD1 = DEBTORHISTORY.HISTORYLINENO
	SMALLKEYFIELD2 = 0
	*/
	/* ** NOTE GLACCOUNTING GLA does not join to DEBTORHISTORY H by MOVEMENTCLASS 
	in this case as the amounts are in a seperate column and can apply to multiple movements 
	so to make mapping easier accounting is saved against a specific Debt Variance MOVEMENTCLASS.*/

	-- SQA21342 Add DEBTORTYPE and DESTINATIONCOUNTRY
	Set @sSQLString="INSERT INTO #GLMAPPING
	(LEDGER, ACCOUNTTYPE, ENTITY,
	WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
	LOCALCLIENTFLAG,
	CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
	REASONCODE,DEBTFROMWIP,
	BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
	DEBTORITEMTYPE, GLACCOUNTCODE, LOCALAMOUNT, 
	BILLPERCENTAGE, TRANSNO,
	MOVEMENTCLASS, AMOUNTTYPE,
	KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
	SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION, INTERNALWORKFLAG,
	DEBTORTYPE, DESTINATIONCOUNTRY)
	
	SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO,
	NULL, NULL, NULL, NULL, NULL,
	IP.LOCALCLIENTFLAG,
	H.CURRENCY, NULL, NULL, NULL, NULL, NULL,
	H.REASONCODE, convert(bit, TTYPE.USED_BY & 2),
	NULL, NULL, NULL,
	OI.ITEMTYPE, NULL, H.EXCHVARIANCE * -1 * GLA.AMOUNTSIGN,
	NULL, H.REFTRANSNO,
	GLA.MOVEMENTCLASS, GLA.AMOUNTTYPE,
	0, 0, H.ITEMENTITYNO, H.ITEMTRANSNO, H.ACCTENTITYNO, H.ACCTDEBTORNO,
	H.HISTORYLINENO, 0, @pnDesignation, D.INTERNAL,
	IP.DEBTORTYPE, ADDR.COUNTRYCODE
	 
	FROM #TRANSACTIONID TID
	JOIN DEBTORHISTORY H		ON H.REFENTITYNO = TID.ENTITYNO
					AND H.REFTRANSNO = TID.TRANSNO
	JOIN IPNAME IP			ON IP.NAMENO = H.ACCTDEBTORNO
	JOIN TRANSACTIONHEADER TH	ON TH.ENTITYNO = H.REFENTITYNO
					AND TH.TRANSNO = H.REFTRANSNO
	JOIN ACCT_TRANS_TYPE TTYPE	ON TTYPE.TRANS_TYPE_ID = TH.TRANSTYPE
	JOIN OPENITEM OI		ON OI.ITEMENTITYNO = H.ITEMENTITYNO
					AND OI.ITEMTRANSNO = H.ITEMTRANSNO
					AND OI.ACCTENTITYNO = H.ACCTENTITYNO
					AND OI.ACCTDEBTORNO = H.ACCTDEBTORNO
	JOIN DEBTOR_ITEM_TYPE D		ON D.ITEM_TYPE_ID = OI.ITEMTYPE
	JOIN GLACCOUNTING GLA		ON GLA.MOVEMENTCLASS = 9
					AND GLA.AMOUNTTYPE <> 6600
	JOIN GLACCOUNTTYPE AT		ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
	LEFT JOIN NAME N		ON N.NAMENO = IP.NAMENO 
	LEFT JOIN ADDRESS ADDR		ON N.POSTALADDRESS = ADDR.ADDRESSCODE

	WHERE AT.LEDGER = 2
	AND ( (AT.USEBILLEDWIPCRITERIA = 0) OR (AT.USEBILLEDWIPCRITERIA IS NULL) )
	AND H.EXCHVARIANCE <> 0"
	/*
	FROM #TRANSACTIONID TID, DEBTORHISTORY H, GLACCOUNTING GLA, GLACCOUNTTYPE AT,
	IPNAME IP, TRANSACTIONHEADER TH, ACCT_TRANS_TYPE TTYPE, OPENITEM OI, DEBTOR_ITEM_TYPE D
	WHERE TID.ENTITYNO = H.REFENTITYNO
	AND TID.TRANSNO = H.REFTRANSNO
	AND H.ACCTDEBTORNO = IP.NAMENO
	AND H.REFENTITYNO = TH.ENTITYNO
	AND H.REFTRANSNO = TH.TRANSNO
	AND TH.TRANSTYPE = TTYPE.TRANS_TYPE_ID
	AND OI.ITEMENTITYNO = H.ITEMENTITYNO
	AND OI.ITEMTRANSNO = H.ITEMTRANSNO
	AND OI.ACCTENTITYNO = H.ACCTENTITYNO
	AND OI.ACCTDEBTORNO = H.ACCTDEBTORNO
	AND D.ITEM_TYPE_ID = OI.ITEMTYPE
	and AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
	and AT.LEDGER = 2
	AND H.EXCHVARIANCE <> 0
	AND ( (AT.USEBILLEDWIPCRITERIA = 0) OR (AT.USEBILLEDWIPCRITERIA IS NULL) )
	AND GLA.MOVEMENTCLASS = 9
	AND GLA.AMOUNTTYPE <> 6600"
	*/

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnDesignation int',
			@pnDesignation
	
	
	If @pbDebugFlag = 1
	Begin
		print ''
		Print '	--IDC_GLMAPPING_IL6 - Debtors ledger - Exchange Gain/Loss'
		print @sSQLString
	End

End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR ( @nTransUsedBy & @nTransUsedByAR != 0 ) OR (@pbCashAcctAR  = 1) )
Begin	
	If (@bCashAccounting = 1) 
	Begin
		-- IDC_GLMAPPING_IL11 - Tax ledger for Cash Accounting
		-- SQA21342 Add TAXCODE, DEBTORTYPE and DESTINATIONCOUNTRY
		Set @sSQLString="INSERT INTO #GLMAPPING
		(LEDGER, ACCOUNTTYPE, ENTITY,
		WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
		LOCALCLIENTFLAG,
		CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
		REASONCODE,DEBTFROMWIP,BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
		GLACCOUNTCODE, LOCALAMOUNT, BILLPERCENTAGE, TRANSNO,
		MOVEMENTCLASS, AMOUNTTYPE,
		KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
		SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION,
		TAXCODE, DEBTORTYPE, DESTINATIONCOUNTRY)
		
		SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO, 
		NULL, NULL, NULL, NULL,NULL, 
		NULL, 
		NULL, NULL, NULL, NULL, NULL, NULL, 
		NULL, NULL, 
		NULL, NULL, NULL, 
		NULL, 
		-- SQA18901 Fix incorrect tax when MOVEMENTCLASS = 2,  use OI.LOCALTAXAMT instead of H.LOCALTAXAMT 
		--CASE WHEN ( GLA.AMOUNTTYPE = 6631 AND GLA.MOVEMENTCLASS <> 2 ) THEN ABS(OI.LOCALTAXAMT)
		--ELSE H.LOCALTAXAMT END * 1 * GLA.AMOUNTSIGN * ABS(H.LOCALVALUE / OI.LOCALVALUE), 
		CASE WHEN ( GLA.AMOUNTTYPE = 6631 AND GLA.MOVEMENTCLASS <> 2 ) THEN ABS(OI.LOCALTAXAMT)
		ELSE OI.LOCALTAXAMT END * 1 * GLA.AMOUNTSIGN * 
			-- RFC60728 Handle reversal
			CASE WHEN H.COMMANDID = 99  /*Reversal*/ THEN -1 ELSE 1 END	*  
			-- SQA19897 Ensure when OI.LOCALVALUE=0 does not cause divide by zero error
			-- RFC60728 Handle negative tax for credit wip by * sign(OI.LOCALTAXAMT)
			(CASE WHEN ISNULL(OI.LOCALVALUE, 0) = 0 THEN 0 ELSE ABS(H.LOCALVALUE / OI.LOCALVALUE) * sign(OI.LOCALTAXAMT) END),

		NULL, H.REFTRANSNO, H.MOVEMENTCLASS, GLA.AMOUNTTYPE,
		0, 0, H.ITEMENTITYNO, H.ITEMTRANSNO, H.ACCTENTITYNO, H.ACCTDEBTORNO, 
		H.HISTORYLINENO, 0, @pnDesignation,
		IP.TAXCODE, IP.DEBTORTYPE, ADDR.COUNTRYCODE
		
		FROM #TRANSACTIONID TID
		JOIN DEBTORHISTORY H	ON (TID.ENTITYNO = H.REFENTITYNO
					AND TID.TRANSNO = H.REFTRANSNO)
		JOIN OPENITEM OI	ON (OI.ITEMENTITYNO = H.ITEMENTITYNO
					AND OI.ITEMTRANSNO = H.ITEMTRANSNO
					AND OI.ACCTENTITYNO = H.ACCTENTITYNO
					AND OI.ACCTDEBTORNO = H.ACCTDEBTORNO)
		JOIN GLACCOUNTING GLA	ON (GLA.MOVEMENTCLASS = H.MOVEMENTCLASS)
		JOIN GLACCOUNTTYPE AT 	ON (AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE)
		JOIN IPNAME IP			ON IP.NAMENO = H.ACCTDEBTORNO
		LEFT JOIN NAME N		ON N.NAMENO = IP.NAMENO 
		LEFT JOIN ADDRESS ADDR		ON N.POSTALADDRESS = ADDR.ADDRESSCODE
		
		WHERE AT.LEDGER = 3
		AND GLA.AMOUNTTYPE <> 6600
		AND ( (H.LOCALTAXAMT <> 0) OR (OI.LOCALTAXAMT <> 0) )"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnDesignation int',
					@pnDesignation

		If @pbDebugFlag = 1
		Begin
			print ''
			Print '	-- IDC_GLMAPPING_IL11 - Tax ledger for Cash Accounting'
			print @sSQLString
		End

		
	End
	Else
	Begin
		-- IDC_GLMAPPING_IL7 - Tax ledger
		-- SQA21342 Add TAXCODE, DEBTORTYPE and DESTINATIONCOUNTRY
		-- RFC71501 Zero-value Credit note creates unbalanced journals when associated debit WIP has tax
		/*
		KEYFIELD1 = 0   
		KEYFIELD2 = 0
		KEYFIELD3 = DEBTORHISTORY.ITEMENTITYNO
		KEYFIELD4 = DEBTORHISTORY.ITEMTRANSNO
		KEYFIELD5 = DEBTORHISTORY.ACCTENTITYNO
		KEYFIELD6 = DEBTORHISTORY.ACCTDEBTORNO
		SMALLKEYFIELD1 = DEBTORHISTORY.HISTORYLINENO
		SMALLKEYFIELD2 = 0
		*/
		Set @sSQLString="INSERT INTO #GLMAPPING
		(LEDGER, ACCOUNTTYPE, ENTITY,
		WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
		LOCALCLIENTFLAG,
		CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
		REASONCODE,DEBTFROMWIP,BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
		GLACCOUNTCODE, LOCALAMOUNT, BILLPERCENTAGE, TRANSNO,
		MOVEMENTCLASS, AMOUNTTYPE,
		KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
		SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION,
		TAXCODE, DEBTORTYPE, DESTINATIONCOUNTRY)
		
		SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO, 
		NULL, NULL, NULL, NULL,NULL, 
		NULL, 
		NULL, NULL, NULL, NULL, NULL, NULL, 
		NULL, NULL, 
		NULL, NULL, NULL, 
		NULL, 
		-- SQA20452	- Recalculate tax for tax ledger using proportional calcuation instead of DEBTORHISTORY.LOCALTAXAMT as it is not recorded for partial payment.
		-- H.LOCALTAXAMT *
		CASE WHEN (H.ITEMPRETAXVALUE + H.LOCALTAXAMT) = H.LOCALVALUE THEN H.LOCALTAXAMT
			ELSE CASE WHEN  ISNULL(OI.LOCALVALUE, 0) =0 THEN 0 
				ELSE (H.LOCALVALUE / OI.LOCALVALUE * OI.LOCALTAXAMT) 
			END
		END *		
		CASE WHEN H.MOVEMENTCLASS IN (1, 4) 
		THEN 1 ELSE -1 END
		* GLA.AMOUNTSIGN, 
		NULL, H.REFTRANSNO, 
		H.MOVEMENTCLASS, GLA.AMOUNTTYPE,
		H.ITEMENTITYNO, H.ITEMTRANSNO, H.ACCTENTITYNO, 
		
		/* RFC70055 correct values for KEYFIELD4, KEYFIELD5, KEYFIELD6*/
		H.ITEMTRANSNO, H.ACCTENTITYNO, H.ACCTDEBTORNO,		

		H.HISTORYLINENO, 0, @pnDesignation,
		IP.TAXCODE, IP.DEBTORTYPE, ADDR.COUNTRYCODE
		
		FROM #TRANSACTIONID TID
		JOIN DEBTORHISTORY H	ON H.REFENTITYNO = TID.ENTITYNO
					AND H.REFTRANSNO = TID.TRANSNO
		JOIN GLACCOUNTING GLA	ON GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
		JOIN GLACCOUNTTYPE AT	ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
		-- SQA20452
		JOIN OPENITEM OI	ON (OI.ITEMENTITYNO = H.ITEMENTITYNO
					AND OI.ITEMTRANSNO = H.ITEMTRANSNO
					AND OI.ACCTENTITYNO = H.ACCTENTITYNO
					AND OI.ACCTDEBTORNO = H.ACCTDEBTORNO)
		JOIN IPNAME IP			ON IP.NAMENO = H.ACCTDEBTORNO
		LEFT JOIN NAME N		ON N.NAMENO = IP.NAMENO 
		LEFT JOIN ADDRESS ADDR		ON N.POSTALADDRESS = ADDR.ADDRESSCODE
		
		WHERE AT.LEDGER = 3
		AND GLA.AMOUNTTYPE <> 6600
		AND H.LOCALTAXAMT <> 0"

		/*FROM #TRANSACTIONID TID, DEBTORHISTORY H, GLACCOUNTING GLA, GLACCOUNTTYPE AT
		WHERE 	AT.LEDGER = 2
		AND	AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
		AND	GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
		AND	GLA.AMOUNTTYPE <> 6600
		AND	TID.ENTITYNO = H.REFENTITYNO
		AND	TID.TRANSNO = H.REFTRANSNO
		AND	H.LOCALTAXAMT <> 0*/
		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnDesignation int',
					@pnDesignation

		If @pbDebugFlag = 1
		Begin
			print ''
			Print '	-- IDC_GLMAPPING_IL7 - Tax ledger'
			print @sSQLString
		End
		
	End
End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR ( @nTransUsedBy & @nTransUsedByCB != 0 ) )
Begin
	-- IDC_GLMAPPING_IL8 - Cash Book
	/*
	KEYFIELD1 = CASHHISTORY.ENTITYNO   
	KEYFIELD2 = CASHHISTORY.BANKNAMENO
	KEYFIELD3 = CASHHISTORY.SEQUENCENO
	KEYFIELD4 = CASHHISTORY.TRANSENTITYNO
	KEYFIELD5 = CASHHISTORY.TRANSNO
	KEYFIELD6 = 0
	SMALLKEYFIELD1 = CASHHISTORY.HISTORYLINENO
	SMALLKEYFIELD2 = 0
	*/
	
	Set @sSQLString="INSERT INTO #GLMAPPING
	(LEDGER, ACCOUNTTYPE, ENTITY,
	WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
	LOCALCLIENTFLAG,
	CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
	REASONCODE,DEBTFROMWIP,BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
	GLACCOUNTCODE, LOCALAMOUNT, BILLPERCENTAGE, TRANSNO,
	MOVEMENTCLASS, AMOUNTTYPE,
	KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
	SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION)
	SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO, NULL, NULL, NULL, NULL,
	NULL, NULL, 
	NULL, NULL, NULL, NULL, NULL, NULL, 
	NULL, NULL, H.ENTITYNO, H.BANKNAMENO, H.SEQUENCENO,
	NULL, 
	H.LOCALAMOUNT *
	CASE WHEN H.MOVEMENTCLASS IN (1, 4, 9) 
	THEN 1 ELSE -1 END
	* GLA.AMOUNTSIGN, 
	NULL, H.REFTRANSNO, 
	H.MOVEMENTCLASS, GLA.AMOUNTTYPE,
	H.ENTITYNO, H.BANKNAMENO, H.SEQUENCENO, H.TRANSENTITYNO, H.TRANSNO, 0,
	H.HISTORYLINENO, 0, @pnDesignation
	FROM #TRANSACTIONID TID 
	JOIN CASHHISTORY H	ON H.REFENTITYNO = TID.ENTITYNO
				AND H.REFTRANSNO = TID.TRANSNO
	JOIN GLACCOUNTING GLA	ON GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
	JOIN GLACCOUNTTYPE AT	ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
	WHERE AT.LEDGER = 4
	AND GLA.AMOUNTTYPE <> 6600"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDesignation int',
				@pnDesignation
	
	If @pbDebugFlag = 1
	Begin
		print ''
		Print '	-- IDC_GLMAPPING_IL8 - Cash Book'
		print @sSQLString
	End

End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR ( @nTransUsedBy & @nTransUsedByCB != 0 ))
Begin
	-- IDC_GLMAPPING_IL9 - Bank Ledger
	/* 
	KEYFIELD1 = BANKHISTORY.ENTITYNO   
	KEYFIELD2 = BANKHISTORY.BANKNAMENO
	KEYFIELD3 = BANKHISTORY.SEQUENCENO
	KEYFIELD4 = BANKHISTORY.HISTORYLINENO
	KEYFIELD5 = 0
	KEYFIELD6 = 0
	SMALLKEYFIELD1 = 0
	SMALLKEYFIELD2 = 0
	*/
	Set @sSQLString="INSERT INTO #GLMAPPING
	(LEDGER, ACCOUNTTYPE, ENTITY,
	WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
	LOCALCLIENTFLAG,
	CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,ACTION,
	REASONCODE,DEBTFROMWIP,BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
	GLACCOUNTCODE, LOCALAMOUNT, BILLPERCENTAGE, TRANSNO,
	MOVEMENTCLASS, AMOUNTTYPE,
	KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
	SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION)
	SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO, NULL, NULL, NULL, NULL,
	NULL, NULL, 
	NULL, NULL, NULL, NULL, NULL, NULL, 
	NULL, NULL, H.ENTITYNO, H.BANKNAMENO, H.SEQUENCENO, 
	NULL, 
	CASE 	WHEN GLA.AMOUNTTYPE = 6649
		THEN H.LOCALCHARGES 
		ELSE CASE WHEN GLA.AMOUNTTYPE = 6652
			 THEN H.LOCALNET
			 ELSE H.LOCALAMOUNT
			 END
		END
		* CASE WHEN H.MOVEMENTCLASS IN (1, 4, 9) 
	THEN 1 ELSE -1 END
		* GLA.AMOUNTSIGN, 
	NULL, H.REFTRANSNO, 
	H.MOVEMENTCLASS, GLA.AMOUNTTYPE, 
	H.ENTITYNO, H.BANKNAMENO, H.SEQUENCENO, H.HISTORYLINENO, 0, 0,
	0, 0, @pnDesignation
	FROM #TRANSACTIONID TID
	JOIN BANKHISTORY H	ON H.REFENTITYNO = TID.ENTITYNO
				AND H.REFTRANSNO = TID.TRANSNO
	JOIN GLACCOUNTING GLA	ON GLA.MOVEMENTCLASS = H.MOVEMENTCLASS
	JOIN GLACCOUNTTYPE AT	ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
	WHERE AT.LEDGER = 5
	AND GLA.AMOUNTTYPE <> 6600"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDesignation int',
				@pnDesignation

	If @pbDebugFlag = 1
	Begin
		print ''
		Print '	-- IDC_GLMAPPING_IL9 - Bank Ledger'
		print @sSQLString
	End

End


If ( @nErrorCode=0 ) AND
( (@bCashAccounting = 1) AND 
(( @nTransUsedBy = NULL ) OR ( @nTransUsedBy & @nTransUsedByAR != 0 ) OR (@pbCashAcctAR  = 1)) )
Begin
	-- if site control Cash Accounting = 1 
	-- IDC_GLMAPPING_IL10 - Debtors ledger - billed WIP
	/*
	KEYFIELD1 = WORKHISTORY.ENTITYNO    
	KEYFIELD2 = WORKHISTORY.TRANSNO
	KEYFIELD3 = OPENITEM.ITEMENTITYNO
	KEYFIELD4 = OPENITEM.ITEMTRANSNO
	KEYFIELD5 = OPENITEM.ACCTENTITYNO
	KEYFIELD6 = OPENITEM.ACCTDEBTORNO
	SMALLKEYFIELD1 =  WORKHISTORY.WIPSEQNO
	SMALLKEYFIELD2 = WORKHISTORY.HISTORYLINENO
	*/

	-- If payment is based on wip preferences then extract the payment allocations from the wippayment table.
	If @bFIWipPaymentPref = 1
	Begin

			Set @sSQLString="
			WITH 
			DWP_HISTORY (ITEMENTITYNO, ITEMTRANSNO, ACCTDEBTORNO, REFENTITYNO, REFTRANSNO, MOVEMENTCLASS, LOCALVALUE, TRANSTYPE, 
						ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, WIPCODE, CASEID, 
						PAYMENTSEQNO, LOCALTRANSVALUE, LOCALBALANCE, FOREIGNTRANSVALUE, FOREIGNBALANCE, WP_REFENTITYNO, WP_REFTRANSNO ) 
			AS 
			( SELECT	DH.ITEMENTITYNO, DH.ITEMTRANSNO, DH.ACCTDEBTORNO, DH.REFENTITYNO, DH.REFTRANSNO, DH.MOVEMENTCLASS, DH.LOCALVALUE, DH.TRANSTYPE,
						WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.HISTORYLINENO, WH.WIPCODE, WH.CASEID, 
						WP.PAYMENTSEQNO, WP.LOCALTRANSVALUE, WP.LOCALBALANCE, WP.FOREIGNTRANSVALUE, WP.FOREIGNBALANCE, WP.REFENTITYNO, WP.REFTRANSNO
					FROM #TRANSACTIONID TID
					JOIN DEBTORHISTORY DH  
								ON DH.REFENTITYNO = TID.ENTITYNO
								AND DH.REFTRANSNO = TID.TRANSNO
					JOIN WORKHISTORY WH  
								ON WH.REFENTITYNO = DH.ITEMENTITYNO
								AND WH.REFTRANSNO = DH.ITEMTRANSNO
								AND WH.MOVEMENTCLASS = 2
					JOIN WIPPAYMENT WP 
									ON WP.ENTITYNO = WH.ENTITYNO
									AND WP.TRANSNO = WH.TRANSNO
									AND WP.WIPSEQNO = WH.WIPSEQNO
									AND WP.HISTORYLINENO = WH.HISTORYLINENO
									AND WP.ACCTDEBTORNO = DH.ACCTDEBTORNO
									AND WP.REFENTITYNO = DH.REFENTITYNO
									AND WP.REFTRANSNO = DH.REFTRANSNO
			)			

			INSERT INTO #GLMAPPING
			(LEDGER, ACCOUNTTYPE, ENTITY,
			WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
			LOCALCLIENTFLAG,CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,
			ACTION,REASONCODE,DEBTFROMWIP,BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
			DEBTORITEMTYPE, GLACCOUNTCODE, LOCALAMOUNT, FOREIGNAMOUNT, 
			BILLPERCENTAGE, TRANSNO, MOVEMENTCLASS, AMOUNTTYPE,
			KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
			SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION, INTERNALWORKFLAG,
			DEBTORTYPE, DESTINATIONCOUNTRY)
			
			SELECT DISTINCT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO,
			NULL, H.WIPCODE, W.WIPTYPEID, WT.CATEGORYCODE, H.EMPLOYEENO, 
			IP.LOCALCLIENTFLAG, DH.CURRENCY, C.CASEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, 
			OI.ACTION, H.REASONCODE, convert(bit, TTYPE.USED_BY & 2), NULL, NULL, NULL,
			OI.ITEMTYPE,NULL, 

			-- Credit full bill reversal write down the wip of the credit note.  So the amount for the credit note can't be extracted from the wippayment row of the transaction.		
			-- It's derived from the sum of the wip initital balance and the write down amount.
			CASE WHEN (DH.TRANSTYPE = 513 AND OI.ITEMTYPE = 511) THEN (WP2.LOCALBALANCE + WP.LOCALTRANSVALUE) ELSE WP.LOCALTRANSVALUE END
			* CASE WHEN DH.MOVEMENTCLASS IN (1, 4, 9) THEN 1 ELSE -1 END 
			* GLA.AMOUNTSIGN,
			
			CASE WHEN (DH.TRANSTYPE = 513 AND OI.ITEMTYPE = 511) THEN (WP2.FOREIGNBALANCE + WP.FOREIGNTRANSVALUE) ELSE WP.FOREIGNTRANSVALUE END
			* CASE WHEN DH.MOVEMENTCLASS IN (1, 4, 9) THEN 1 ELSE -1 END 
			* GLA.AMOUNTSIGN,
			
			OI.BILLPERCENTAGE, DH.REFTRANSNO, DH.MOVEMENTCLASS, GLA.AMOUNTTYPE,
			H.ENTITYNO, H.TRANSNO, OI.ITEMENTITYNO, OI.ITEMTRANSNO, OI.ACCTENTITYNO, OI.ACCTDEBTORNO,
			H.WIPSEQNO, H.HISTORYLINENO, @pnDesignation, D.INTERNAL,
			IP.DEBTORTYPE, ADDR.COUNTRYCODE
			
			FROM #TRANSACTIONID TID 
			JOIN DEBTORHISTORY DH		ON DH.REFENTITYNO = TID.ENTITYNO 
							AND DH.REFTRANSNO = TID.TRANSNO
			JOIN GLACCOUNTING GLA		ON GLA.MOVEMENTCLASS = DH.MOVEMENTCLASS
			JOIN GLACCOUNTTYPE AT		ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
			JOIN IPNAME IP			ON DH.ACCTDEBTORNO = IP.NAMENO
			JOIN TRANSACTIONHEADER TH	ON DH.REFENTITYNO = TH.ENTITYNO
							AND DH.REFTRANSNO = TH.TRANSNO
			JOIN ACCT_TRANS_TYPE TTYPE	ON TH.TRANSTYPE = TTYPE.TRANS_TYPE_ID
			JOIN OPENITEM OI		ON OI.ITEMENTITYNO = DH.ITEMENTITYNO
							AND OI.ITEMTRANSNO = DH.ITEMTRANSNO
							AND OI.ACCTENTITYNO = DH.ACCTENTITYNO
							AND OI.ACCTDEBTORNO = DH.ACCTDEBTORNO
			JOIN DEBTOR_ITEM_TYPE D		ON D.ITEM_TYPE_ID = OI.ITEMTYPE
			JOIN WORKHISTORY H		ON H.REFENTITYNO = DH.ITEMENTITYNO 
							AND H.REFTRANSNO = DH.ITEMTRANSNO 
			LEFT JOIN CASES C 		ON H.CASEID = C.CASEID
			JOIN WIPTEMPLATE W 		ON H.WIPCODE = W.WIPCODE
			JOIN WIPTYPE WT 		ON W.WIPTYPEID = WT.WIPTYPEID
			LEFT JOIN NAME N		ON N.NAMENO = IP.NAMENO 
			LEFT JOIN ADDRESS ADDR		ON N.POSTALADDRESS = ADDR.ADDRESSCODE

			/*Get the allocated payment at WIP level*/
			LEFT JOIN DWP_HISTORY WP 		ON  WP.ENTITYNO = H.ENTITYNO
              								AND WP.TRANSNO = H.TRANSNO
											AND WP.WIPSEQNO = H.WIPSEQNO
              								AND WP.HISTORYLINENO = H.HISTORYLINENO
             	 							AND WP.ACCTDEBTORNO = DH.ACCTDEBTORNO
              								AND WP.WP_REFENTITYNO = DH.REFENTITYNO
              								AND WP.WP_REFTRANSNO = DH.REFTRANSNO
              								AND WP.PAYMENTSEQNO <> 1 
       
			/* Get the wip initial balance */
			LEFT JOIN WIPPAYMENT WP2 		ON  WP2.ENTITYNO = WP.ENTITYNO
              								AND WP2.TRANSNO = WP.TRANSNO
											AND WP2.WIPSEQNO = WP.WIPSEQNO
              								AND WP2.HISTORYLINENO = WP.HISTORYLINENO
             	 							AND WP2.ACCTDEBTORNO = WP.ACCTDEBTORNO
              								AND WP2.PAYMENTSEQNO = 1 
								
			WHERE AT.LEDGER = 2  
			AND AT.USEBILLEDWIPCRITERIA = 1
			AND GLA.AMOUNTTYPE <> 6600 
			AND H.MOVEMENTCLASS = 2

			/*exclude Credit full bill where bill has no payment applied.*/
			AND NOT EXISTS (SELECT SUM(DH2.LOCALBALANCE) 
					FROM DEBTORHISTORY DH2
					WHERE DH2.REFENTITYNO = TID.ENTITYNO 
					AND DH2.REFTRANSNO = TID.TRANSNO 
					AND DH2.TRANSTYPE in ( 511, 513) -- Credit Full Bill and its Reversal	
					AND DH2.MOVEMENTCLASS = 4
					GROUP BY DH2.ITEMTRANSNO
					HAVING  SUM(DH2.LOCALBALANCE) = 0)
					
			"	

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnDesignation int',
							@pnDesignation
	End
	Else Begin
		Set @sSQLString="INSERT INTO #GLMAPPING
		(LEDGER, ACCOUNTTYPE, ENTITY,
		WIPINADVANCE,WIPCODE,WIPTYPEID,WIPCATEGORYCODE,WIPEMPLOYEENO,
		LOCALCLIENTFLAG,CURRENCY, CASEID, CASETYPE, PROPERTYTYPE,COUNTRY,
		ACTION,REASONCODE,DEBTFROMWIP,BANKENTITYNO ,BANKNAMENO, BANKSEQUENCENO,
		DEBTORITEMTYPE, GLACCOUNTCODE, LOCALAMOUNT, FOREIGNAMOUNT, 
		BILLPERCENTAGE, TRANSNO, MOVEMENTCLASS, AMOUNTTYPE,
		KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6,
		SMALLKEYFIELD1, SMALLKEYFIELD2, DESIGNATION, INTERNALWORKFLAG,
		DEBTORTYPE, DESTINATIONCOUNTRY)
		
		SELECT AT.LEDGER, GLA.ACCOUNTTYPE, H.REFENTITYNO,
		NULL, H.WIPCODE, W.WIPTYPEID, WT.CATEGORYCODE, H.EMPLOYEENO, 
		IP.LOCALCLIENTFLAG, DH.CURRENCY, C.CASEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, 
		OI.ACTION, H.REASONCODE, convert(bit, TTYPE.USED_BY & 2), NULL, NULL, NULL,
		OI.ITEMTYPE,NULL, 
		
		H.LOCALTRANSVALUE 
		* CASE WHEN DH.MOVEMENTCLASS IN (1, 4, 9) THEN 1 ELSE -1 END 
		* CASE WHEN DH.TRANSTYPE = 512 /*BILL REVERSAL*/  THEN -1  ELSE 1 END
		* GLA.AMOUNTSIGN,
		
		H.FOREIGNTRANVALUE 
		* CASE WHEN DH.MOVEMENTCLASS IN (1, 4, 9) THEN 1 ELSE -1 END 
		* CASE WHEN DH.TRANSTYPE = 512 /*BILL REVERSAL*/  THEN -1  ELSE 1 END
		* GLA.AMOUNTSIGN,
		
		OI.BILLPERCENTAGE, DH.REFTRANSNO, DH.MOVEMENTCLASS, GLA.AMOUNTTYPE,
		H.ENTITYNO, H.TRANSNO, OI.ITEMENTITYNO, OI.ITEMTRANSNO, OI.ACCTENTITYNO, OI.ACCTDEBTORNO,
		H.WIPSEQNO, H.HISTORYLINENO, @pnDesignation, D.INTERNAL,
		IP.DEBTORTYPE, ADDR.COUNTRYCODE
		
		FROM #TRANSACTIONID TID 
		JOIN DEBTORHISTORY DH		ON DH.REFENTITYNO = TID.ENTITYNO 
						AND DH.REFTRANSNO = TID.TRANSNO
		JOIN GLACCOUNTING GLA		ON GLA.MOVEMENTCLASS = DH.MOVEMENTCLASS
		JOIN GLACCOUNTTYPE AT		ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
		JOIN IPNAME IP			ON DH.ACCTDEBTORNO = IP.NAMENO
		JOIN TRANSACTIONHEADER TH	ON DH.REFENTITYNO = TH.ENTITYNO
						AND DH.REFTRANSNO = TH.TRANSNO
		JOIN ACCT_TRANS_TYPE TTYPE	ON TH.TRANSTYPE = TTYPE.TRANS_TYPE_ID
		JOIN OPENITEM OI		ON OI.ITEMENTITYNO = DH.ITEMENTITYNO
						AND OI.ITEMTRANSNO = DH.ITEMTRANSNO
						AND OI.ACCTENTITYNO = DH.ACCTENTITYNO
						AND OI.ACCTDEBTORNO = DH.ACCTDEBTORNO
		JOIN DEBTOR_ITEM_TYPE D		ON D.ITEM_TYPE_ID = OI.ITEMTYPE
		JOIN WORKHISTORY H		ON H.REFENTITYNO = DH.ITEMENTITYNO 
						AND H.REFTRANSNO = DH.ITEMTRANSNO 
		LEFT JOIN CASES C 		ON H.CASEID = C.CASEID
		JOIN WIPTEMPLATE W 		ON H.WIPCODE = W.WIPCODE
		JOIN WIPTYPE WT 		ON W.WIPTYPEID = WT.WIPTYPEID
		LEFT JOIN NAME N		ON N.NAMENO = IP.NAMENO 
		LEFT JOIN ADDRESS ADDR		ON N.POSTALADDRESS = ADDR.ADDRESSCODE

		WHERE AT.LEDGER = 2  
		AND AT.USEBILLEDWIPCRITERIA = 1
		AND GLA.AMOUNTTYPE <> 6600 
		AND H.MOVEMENTCLASS = 2

		/*exclude Credit full bill where bill has no payment applied*/
		AND NOT EXISTS (SELECT SUM(DH2.LOCALBALANCE) 
				FROM DEBTORHISTORY DH2
				WHERE DH2.REFENTITYNO = TID.ENTITYNO 
				AND DH2.REFTRANSNO = TID.TRANSNO 
				AND DH2.TRANSTYPE in ( 511, 513)		-- Credit Full Bill and its Reversal	
				AND DH2.MOVEMENTCLASS = 4
				GROUP BY DH2.ITEMTRANSNO
				HAVING  SUM(DH2.LOCALBALANCE) = 0)
				
		"	

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnDesignation int',
						@pnDesignation
	End
	
	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- if site control Cash Accounting = 1 
				-- IDC_GLMAPPING_IL10 - Debtors ledger - billed WIP'
		print @sSQLString
	End
	
End


If @pbDebugFlag = 1
Begin
	Print ''
	Print '	-- now update the inserted rows with the correct data'
End


-- now update the inserted rows with the correct data
If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR 
( @nTransUsedBy & @nTransUsedByBilling != 0 ) OR 
( ((@nTransUsedBy & @nTransUsedByAR != 0 ) OR (@pbCashAcctAR  = 1)) AND (@bCashAccounting = 1)) )
Begin	
	-- IDC_GLMAPPING_UL1 - Update the WIP In Advance field for the WIP ledger
	Set @sSQLString="UPDATE #GLMAPPING
	SET WIPINADVANCE = CASE WHEN WHORIG.MOVEMENTCLASS = 2 THEN 1 ELSE 0 END
	FROM WORKHISTORY WHORIG
	WHERE WHORIG.ENTITYNO = #GLMAPPING.KEYFIELD1
	AND WHORIG.TRANSNO = #GLMAPPING.KEYFIELD2
	AND WHORIG.WIPSEQNO = #GLMAPPING.SMALLKEYFIELD1
	AND WHORIG.ITEMIMPACT =  1
	AND #GLMAPPING.LEDGER = 1"

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- IDC_GLMAPPING_UL1 - Update the WIP In Advance field for the WIP ledger'
		print @sSQLString
	End
End


If ( @nErrorCode=0 ) AND
(( @nTransUsedBy = NULL ) OR 
( @nTransUsedBy & @nTransUsedByBilling != 0 ) OR 
(((@nTransUsedBy & @nTransUsedByAR != 0) OR (@pbCashAcctAR  = 1)) AND (@bCashAccounting = 1)) )
Begin
	-- IDC_GLMAPPING_UL2 - Update the Local Client Flag field for the WIP ledger Case records where it isn't present yet
	Set @sSQLString="UPDATE #GLMAPPING
	SET #GLMAPPING.LOCALCLIENTFLAG = IP.LOCALCLIENTFLAG
	FROM WORKHISTORY H	
	JOIN CASENAME CN	ON H.CASEID = CN.CASEID	
	JOIN IPNAME IP		ON IP.NAMENO = CN.NAMENO
	WHERE H.ENTITYNO = #GLMAPPING.KEYFIELD1
	AND H.TRANSNO = #GLMAPPING.KEYFIELD2
	AND H.WIPSEQNO = #GLMAPPING.SMALLKEYFIELD1
	AND H.HISTORYLINENO = #GLMAPPING.SMALLKEYFIELD2
	AND CN.NAMETYPE = 'D'
	AND CN.EXPIRYDATE IS NULL
	AND CN.SEQUENCE =
		( SELECT MIN(CN2.SEQUENCE)
		  FROM CASENAME CN2
		  WHERE CN2.CASEID = CN.CASEID
		  AND CN2.NAMETYPE = CN.NAMETYPE
		  AND CN2.EXPIRYDATE IS NULL )
	AND #GLMAPPING.LOCALCLIENTFLAG IS NULL 
	AND #GLMAPPING.LEDGER = 1"

	/*FROM IPNAME IP, CASENAME CN, WORKHISTORY H
	WHERE H.CASEID = CN.CASEID
	AND	IP.NAMENO = CN.NAMENO
	AND	CN.NAMETYPE = 'D'
	AND	CN.EXPIRYDATE IS NULL
	AND	CN.SEQUENCE =
		( SELECT MIN(CN2.SEQUENCE)
		  FROM CASENAME CN2
		  WHERE CN2.CASEID = CN.CASEID
		  AND	CN2.NAMETYPE = CN.NAMETYPE
		  AND	CN2.EXPIRYDATE IS NULL )
	AND 	H.ENTITYNO = #GLMAPPING.KEYFIELD1
	AND 	H.TRANSNO = #GLMAPPING.KEYFIELD2
	AND 	H.WIPSEQNO = #GLMAPPING.SMALLKEYFIELD1
	AND 	H.HISTORYLINENO = #GLMAPPING.SMALLKEYFIELD2
	AND 	#GLMAPPING.LOCALCLIENTFLAG IS NULL 
	AND 	#GLMAPPING.LEDGER = 1
	*/

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- IDC_GLMAPPING_UL2 - Update the Local Client Flag field for the WIP ledger Case records where it isn''t present yet'
		print @sSQLString
	End
End


If ( @nErrorCode=0 ) AND
( @bIsDebtorCaseRequired = 1 ) AND
(( @nTransUsedBy = NULL ) OR ( @nTransUsedBy & @nTransUsedByAR != 0 ) OR (@pbCashAcctAR  = 1) ) 
Begin
	-- IDC_GLMAPPING_UL3 - Update the CaseId for any Debtor/Tax records from any associated Work History rows
	Set @sSQLString="UPDATE #GLMAPPING
		SET #GLMAPPING.CASEID = 
			( SELECT min( H.CASEID )
			  FROM WORKHISTORY H
			  WHERE H.REFENTITYNO = #GLMAPPING.ENTITY
			  AND 	H.REFTRANSNO = #GLMAPPING.TRANSNO 
			  AND 	H.MOVEMENTCLASS = 2 )
		WHERE	#GLMAPPING.LEDGER IN ( 2, 3 )"

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- IDC_GLMAPPING_UL3 - Update the CaseId for any Debtor/Tax records from any associated Work History rows'
		print @sSQLString
	End

End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR
( @nTransUsedBy & @nTransUsedByAR != 0 ) OR (@pbCashAcctAR  = 1) )
Begin
	-- IDC_GLMAPPING_UL4 - Update the Bank details for any Debtor records from any associated Work History rows
	Set @sSQLString="UPDATE GL
	SET BANKENTITYNO = CH.ENTITYNO,
	BANKNAMENO = CH.BANKNAMENO, 
	BANKSEQUENCENO = CH.SEQUENCENO
	FROM  #GLMAPPING GL
	JOIN DEBTORHISTORY DH			ON (DH.REFENTITYNO = GL.ENTITY
						AND DH.REFTRANSNO = GL.TRANSNO)
	JOIN (SELECT DISTINCT ENTITYNO, BANKNAMENO, SEQUENCENO, REFENTITYNO, REFTRANSNO
		FROM CASHHISTORY
		WHERE MOVEMENTCLASS = 2) CH	ON CH.REFENTITYNO = DH.REFENTITYNO
						AND CH.REFTRANSNO = DH.REFTRANSNO
	WHERE GL.LEDGER = 2"

	/*
	FROM  DEBTORHISTORY DH, CASHHISTORY CH
	WHERE	#GLMAPPING.LEDGER = 2
	AND CH.MOVEMENTCLASS = 2
	AND DH.REFENTITYNO = #GLMAPPING.ENTITY
	AND DH.REFTRANSNO = #GLMAPPING.TRANSNO 
	AND DH.REFENTITYNO = CH.REFENTITYNO
	AND DH.REFTRANSNO = CH.REFTRANSNO
	*/

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- IDC_GLMAPPING_UL4 - Update the Bank details for any Debtor records from any associated Work History rows'
		print @sSQLString
	End
	
End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR 
 ( @nTransUsedBy & @nTransUsedByBilling != 0 ) OR 
 ( ((@nTransUsedBy & @nTransUsedByAR != 0) OR (@pbCashAcctAR  = 1)) AND (@bCashAccounting = 1)) )
Begin
	-- IDC_GLMAPPING_UL5 - Update the WIP ledger records with the staff classification
	Set @sSQLString="UPDATE #GLMAPPING
	SET #GLMAPPING.STAFFCLASS = EMP.STAFFCLASS
	FROM  EMPLOYEE EMP
	WHERE	EMP.EMPLOYEENO = #GLMAPPING.WIPEMPLOYEENO
	AND 	#GLMAPPING.LEDGER = 1"

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- IDC_GLMAPPING_UL5 - Update the WIP ledger records with the staff classification'
		print @sSQLString
	End
End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR 
( @nTransUsedBy & @nTransUsedByBilling != 0 ) OR 
( ((@nTransUsedBy & @nTransUsedByAR != 0) OR (@pbCashAcctAR  = 1)) AND (@bCashAccounting = 1)) )
Begin
	-- IDC_GLMAPPING_UL6 - Update the WIP ledger records with the staff classification
	Set @sSQLString="UPDATE #GLMAPPING
	SET #GLMAPPING.SOURCEOFFICEID = 	
		CASE
		WHEN A.STAFFOFFICE IS NOT NULL THEN A.STAFFOFFICE
		ELSE 
			CASE 
			WHEN A.CASEOFFICE IS NOT NULL THEN A.CASEOFFICE
			ELSE A.STAFFOFFICE2
			END
		END
	FROM (
	SELECT DISTINCT M.ENTITY, M.TRANSNO, M.SEQNO, M.DESIGNATION, O.OFFICEID AS STAFFOFFICE, 
	O1.OFFICEID AS CASEOFFICE, O2.OFFICEID AS STAFFOFFICE2
	FROM  #GLMAPPING M 
	LEFT JOIN WORKHISTORY WH 	ON WH.ENTITYNO = M.KEYFIELD1
					AND WH.TRANSNO = M.KEYFIELD2
					AND WH.WIPSEQNO = M.SMALLKEYFIELD1
					AND WH.HISTORYLINENO = M.SMALLKEYFIELD2
	LEFT JOIN TRANSACTIONHEADER TH	ON TH.TRANSNO = M.TRANSNO
					AND TH.ENTITYNO = M.ENTITY
	LEFT JOIN TABLEATTRIBUTES TA	ON TA.GENERICKEY = CAST(WH.EMPLOYEENO AS VARCHAR(15))
					AND TA.PARENTTABLE = 'NAME'
					AND TA.TABLETYPE = 44
	LEFT JOIN OFFICE O		ON TA.TABLECODE = O.OFFICEID
	LEFT JOIN CASES C		ON C.CASEID = WH.CASEID
	LEFT JOIN OFFICE O1		ON O1.OFFICEID = C.OFFICEID
	LEFT JOIN TABLEATTRIBUTES TA1	ON TA1.GENERICKEY = CAST(TH.EMPLOYEENO AS VARCHAR(15))
					AND TA1.PARENTTABLE = 'NAME'
					AND TA1.TABLETYPE = 44
	LEFT JOIN OFFICE O2		ON O2.OFFICEID = TA1.TABLECODE
	WHERE 	M.LEDGER = 1
	) A 
	WHERE #GLMAPPING.ENTITY = A.ENTITY
	AND #GLMAPPING.TRANSNO = A.TRANSNO
	AND #GLMAPPING.SEQNO = A.SEQNO
	AND #GLMAPPING.DESIGNATION = A.DESIGNATION"

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- IDC_GLMAPPING_UL6 - Update the WIP ledger records with the staff classification'
		print @sSQLString
	End
	
End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR 
( @nTransUsedBy & @nTransUsedByBilling != 0 ) OR 
( @nTransUsedBy & @nTransUsedByAR != 0 ) OR (@pbCashAcctAR  = 1) )
Begin
	-- IDC_GLMAPPING_UL7 - Update the Debtors and Tax ledger records with the source office Id
	Set @sSQLString="UPDATE #GLMAPPING
	SET #GLMAPPING.SOURCEOFFICEID = STAFFOFFICE2
	FROM (
	SELECT DISTINCT M.ENTITY, M.TRANSNO, M.SEQNO, M.DESIGNATION, O2.OFFICEID AS STAFFOFFICE2
	FROM  #GLMAPPING M 
	LEFT JOIN TRANSACTIONHEADER TH	ON TH.TRANSNO = M.TRANSNO
					AND TH.ENTITYNO = M.ENTITY
	LEFT JOIN TABLEATTRIBUTES TA1	ON TA1.GENERICKEY = CAST(TH.EMPLOYEENO AS VARCHAR(15))
					AND TA1.PARENTTABLE = 'NAME'
					AND TA1.TABLETYPE = 44
	LEFT JOIN OFFICE O2		ON O2.OFFICEID = TA1.TABLECODE
	WHERE M.LEDGER IN (2, 3)
	) A
	WHERE #GLMAPPING.ENTITY = A.ENTITY
	AND #GLMAPPING.TRANSNO = A.TRANSNO
	AND #GLMAPPING.SEQNO = A.SEQNO
	AND #GLMAPPING.DESIGNATION = A.DESIGNATION"

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- IDC_GLMAPPING_UL7 - Update the Debtors and Tax ledger records with the source office Id'
		print @sSQLString
	End
End

If ( @nErrorCode=0 ) AND
( ( @nTransUsedBy = NULL ) OR 
( @nTransUsedBy & @nTransUsedByAR != 0 ) OR (@pbCashAcctAR  = 1) )
Begin	
	-- IDC_GLMAPPING_UL8 - Update the Cash ledger records for GL Adjustments with the GLACCOUNTCODE from CASHHISTORY
	Set @sSQLString="UPDATE #GLMAPPING
	SET #GLMAPPING.GLACCOUNTCODE = CH.GLACCOUNTCODE
	FROM CASHHISTORY CH
	WHERE #GLMAPPING.LEDGER = 4
	AND CH.MOVEMENTCLASS IN (4, 5)
	AND CH.REFENTITYNO = #GLMAPPING.ENTITY
	AND CH.REFTRANSNO = #GLMAPPING.TRANSNO
	AND CH.HISTORYLINENO = #GLMAPPING.SMALLKEYFIELD1
	AND #GLMAPPING.ACCOUNTTYPE = 0"

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- IDC_GLMAPPING_UL8 - Update the Cash ledger records for GL Adjustments with the GLACCOUNTCODE from CASHHISTORY'
		print @sSQLString
	End
End

If @nErrorCode=0
Begin
	-- Update rows where AccountCode is NULL with the best possible AccountCode 
	-- based on a best fit criteria search.
	-- Some Cash ledger rows already have the account code on them. Make sure we exclude these.
	-- SQA21342 - Add 3 more fields (TAXCODE, DEBTORTYPE, DESTINATIONCOUNTRY) so the substring start position is increased from 22 to 25
	Set @sSQLString="UPDATE T
	set GLACCOUNTCODE=
	      (SELECT 
		substring(
		max( CASE WHEN(GLA.ENTITY           is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.SOURCEOFFICEID   is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.WIPINADVANCE     is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.WIPCODE          is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.WIPTYPEID        is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.WIPCATEGORYCODE  is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.WIPEMPLOYEENO    is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.STAFFCLASS       is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.BANKENTITYNO     is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.BANKNAMENO       is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.BANKSEQUENCENO   is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.DEBTORITEMTYPE   is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.DEBTFROMWIP      is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.INTERNALWORKFLAG is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.LOCALCLIENTFLAG  is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.TAXCODE	    is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.DEBTORTYPE       is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.DESTINATIONCOUNTRY  is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.CURRENCY         is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.CASETYPE         is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.PROPERTYTYPE     is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.COUNTRY          is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.ACTION           is null) THEN '0' ELSE '1' END +
		     CASE WHEN(GLA.REASONCODE       is null) THEN '0' ELSE '1' END +
		     GLACCOUNTCODE),25,100)
		FROM GLACCOUNTMAPPING GLA
		WHERE GLA.ACCOUNTTYPE = T.ACCOUNTTYPE                                       AND
		(GLA.ENTITY           = isnull(T.ACCTENTITYNO, T.ENTITY) OR GLA.ENTITY IS NULL) AND  
		(GLA.SOURCEOFFICEID   = T.SOURCEOFFICEID   OR GLA.SOURCEOFFICEID       IS NULL) AND 
		(GLA.WIPINADVANCE     = T.WIPINADVANCE     OR GLA.WIPINADVANCE     IS NULL) AND 
		(GLA.WIPCODE          = T.WIPCODE          OR GLA.WIPCODE          IS NULL) AND 
		(GLA.WIPTYPEID        = T.WIPTYPEID        OR GLA.WIPTYPEID        IS NULL) AND 
		(GLA.WIPCATEGORYCODE  = T.WIPCATEGORYCODE  OR GLA.WIPCATEGORYCODE  IS NULL) AND 
		(GLA.WIPEMPLOYEENO    = T.WIPEMPLOYEENO    OR GLA.WIPEMPLOYEENO    IS NULL) AND 
		(GLA.STAFFCLASS       = T.STAFFCLASS       OR GLA.STAFFCLASS       IS NULL) AND 
		(GLA.LOCALCLIENTFLAG  = isnull(T.LOCALCLIENTFLAG,0)
							   OR GLA.LOCALCLIENTFLAG  IS NULL) AND 
		(GLA.TAXCODE	      = T.TAXCODE	   OR GLA.TAXCODE	   IS NULL) AND 
		(GLA.DEBTORTYPE	      = T.DEBTORTYPE	   OR GLA.DEBTORTYPE	   IS NULL) AND 
		(GLA.DESTINATIONCOUNTRY	= T.DESTINATIONCOUNTRY	   OR GLA.DESTINATIONCOUNTRY	   IS NULL) AND 
		(GLA.CURRENCY         = T.CURRENCY         OR GLA.CURRENCY         IS NULL) AND 
		(GLA.CASETYPE         = T.CASETYPE         OR GLA.CASETYPE         IS NULL) AND 
		(GLA.PROPERTYTYPE     = T.PROPERTYTYPE     OR GLA.PROPERTYTYPE     IS NULL) AND 
		(GLA.COUNTRY          = T.COUNTRY          OR GLA.COUNTRY          IS NULL) AND 
		(GLA.ACTION           = T.ACTION           OR GLA.ACTION           IS NULL) AND 
		(GLA.REASONCODE       = T.REASONCODE       OR GLA.REASONCODE       IS NULL) AND 
		(GLA.DEBTFROMWIP      = T.DEBTFROMWIP      OR GLA.DEBTFROMWIP      IS NULL) AND 
		(GLA.INTERNALWORKFLAG = T.INTERNALWORKFLAG OR GLA.INTERNALWORKFLAG IS NULL) AND 
		(GLA.BANKENTITYNO     = T.BANKENTITYNO     OR GLA.BANKENTITYNO     IS NULL) AND 
		(GLA.BANKNAMENO       = T.BANKNAMENO       OR GLA.BANKNAMENO       IS NULL) AND 
		(GLA.BANKSEQUENCENO   = T.BANKSEQUENCENO   OR GLA.BANKSEQUENCENO   IS NULL) AND 
		(GLA.DEBTORITEMTYPE   = T.DEBTORITEMTYPE   OR GLA.DEBTORITEMTYPE   IS NULL) 
	      )	
	From #GLMAPPING T"

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- Update rows where AccountCode is NULL with the best possible AccountCode 
			-- based on a best fit criteria search.
			-- Some Cash ledger rows already have the account code on them. Make sure we exclude these.'
		print @sSQLString
	End
End

If @nErrorCode=0
Begin
	-- delete non accounting entries.
	Set @sSQLString=" DELETE 
	from #GLMAPPING 
	WHERE GLACCOUNTCODE IS NULL OR 
	GLACCOUNTCODE = '' OR
	LOCALAMOUNT IS NULL OR 
	LOCALAMOUNT = 0"
	
	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- delete non accounting entries.'
		print @sSQLString
	End
End


If @nErrorCode = 0
Begin
	-- Check count of transactions, if 0 don't do anything.
	Set @sSQLString="SELECT @nTransCount=COUNT(*) FROM #GLMAPPING" 

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nTransCount	int		OUTPUT',
				@nTransCount	= @nTransCount	OUTPUT
			

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- Entries to be processed'
		print @sSQLString
		Print ''
		SELECT @nTransCount
		Print ''
		SELECT * FROM #GLMAPPING
	End

	If @nTransCount=0
	Begin
		-- no additional processing required
		Set @nErrorCode = -1
	End
End

If @nErrorCode=0
Begin
	-- update assembled Account Codes
	-- update account WIP Code
	-- Use patindex to locate the start of the [WIPCode]  literal.  Use stuff to replace it with the WIP Code column.
	Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
	stuff(GLACCOUNTCODE, patindex('%[[]WIPCode]%', GLACCOUNTCODE), 9, WIPCODE)
	WHERE 	GLACCOUNTCODE LIKE '%[[]WIPCode]%' "
	
	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- update assembled Account Codes
			-- update account WIP Code
			-- Use patindex to locate the start of the [WIPCode]  literal.  Use stuff to replace it with the WIP Code column.'
		print @sSQLString
	End
End


If @nErrorCode=0
Begin
	-- update staff code
	Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
	stuff(GLACCOUNTCODE, patindex('%[[]StaffCode]%', GLACCOUNTCODE), 11, STF.NAMECODE)
	FROM NAME STF
	RIGHT OUTER JOIN #GLMAPPING ON (STF.NAMENO = #GLMAPPING.WIPEMPLOYEENO)
	WHERE	GLACCOUNTCODE LIKE '%[[]StaffCode]%' "
	
	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- update staff code'
		print @sSQLString
	End
End

--If Financial Interface with GL site control = 1
If (@bFIwithGL = 1 OR (@pbCalculateJournalOnly  = 1)) AND @nErrorCode=0
Begin

	-- Update Ledger Account details with profit centre and entity
	Set @sSQLString="UPDATE #GLMAPPING SET ACCTENTITYNO = GLA.ENTITYNO,
	ACCTPROFITCENTRE = GLA.PROFITCENTRECODE,
	LEDGERACCOUNTID = GLA.LEDGERACCOUNTID
	FROM #GLMAPPING GM
	JOIN GENERALLEDGERACCTS GLA ON (GLA.GLACCOUNTCODE = GM.GLACCOUNTCODE)
	WHERE GM.GLACCOUNTCODE IS NOT NULL "

	exec @nErrorCode=sp_executesql @sSQLString

	If @pbDebugFlag = 1
	Begin
		Print ''
		Print '	-- Update Ledger Account details with profit centre and entity'
		print @sSQLString
	End

	If @nErrorCode=0
	Begin
		-- Update Rows where the AcctEntity is to be derived
		Set @sSQLString="UPDATE #GLMAPPING SET ACCTENTITYNO = E.NAMENO
		FROM #GLMAPPING GL 
		JOIN GENERALLEDGERACCTS GLA	ON (GLA.GLACCOUNTCODE = GL.GLACCOUNTCODE)
		JOIN NAME E			ON (E.NAMENO = GL.ENTITY)
		WHERE GLA.DERIVETRANENTITY = 1"
	
		exec @nErrorCode=sp_executesql @sSQLString  

		If @pbDebugFlag = 1
		Begin
			Print ''
			Print '	-- Update Rows where the AcctEntity is to be derived'
			print @sSQLString
		End
	End
	
	-- Note the following logic relies on the various profit centres being set for 
	-- Employees and/or Cases BEFORE bills etc are processed
	If @nErrorCode=0
	Begin
		-- Update Rows where AcctProfitCentre is to be derived - for WIP transactions
		-- Update Rows where the account code is assembled from the derived Employee Profit Centre - for WIP Transactions
		-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
		-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
		-- IDC_GLMAPPING_UDWPC
		Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
		CASE WHEN GL.GLACCOUNTCODE LIKE '%[[]Raised By Staff PC]%' THEN stuff(GL.GLACCOUNTCODE, patindex('%[[]Raised By Staff PC]%', GL.GLACCOUNTCODE), 20, P.PROFITCENTRECODE) ELSE GL.GLACCOUNTCODE END,
		ACCTPROFITCENTRE = P.PROFITCENTRECODE
		FROM #GLMAPPING GL
		JOIN GENERALLEDGERACCTS GLA	ON (GLA.GLACCOUNTCODE = GL.GLACCOUNTCODE)
		JOIN WORKHISTORY H		ON (GL.KEYFIELD1 = H.ENTITYNO
						AND GL.KEYFIELD2 = H.TRANSNO
						AND GL.SMALLKEYFIELD1 = H.WIPSEQNO
						AND GL.SMALLKEYFIELD2 = H.HISTORYLINENO)
		LEFT JOIN PROFITCENTRE P	ON (P.ENTITYNO = GL.ACCTENTITYNO
						AND P.PROFITCENTRECODE = H.EMPPROFITCENTRE)
		WHERE GL.LEDGER = 1 
		AND H.EMPPROFITCENTRE IS NOT NULL 
		AND GLA.DERIVEPCRAISEDSTAFF = 1"
	
		exec @nErrorCode=sp_executesql @sSQLString    

		If @pbDebugFlag = 1
		Begin
			Print ''
			Print '	-- Update Rows where AcctProfitCentre is to be derived - for WIP transactions
			-- Update Rows where the account code is assembled from the derived Employee Profit Centre - for WIP Transactions
			-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
			-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
			-- IDC_GLMAPPING_UDWPC'
			print @sSQLString
		End
	End


	-- SQA21691 DERIVEPCRAISEDSTAFF= 1 ==> calculate derive profit centre for cash accounting at WIP or Debtor level
	If (@bCashAccounting = 1) AND (@nErrorCode=0)
	Begin
		-- option 'Billed Wip Criteria applicable' is off, derive the profit centre at debtor(OPENITEM) level 
		-- IDC_GLMAPPING_UDOIPC2
		If (@nErrorCode=0)
		Begin
			Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
			CASE WHEN GL.GLACCOUNTCODE LIKE '%[[]Raised By Staff PC]%' THEN stuff(GL.GLACCOUNTCODE, patindex('%[[]Raised By Staff PC]%', GL.GLACCOUNTCODE), 20, P.PROFITCENTRECODE) ELSE GL.GLACCOUNTCODE END,
			ACCTPROFITCENTRE = P.PROFITCENTRECODE
			FROM #GLMAPPING GL
			JOIN GENERALLEDGERACCTS GLA	ON (GLA.GLACCOUNTCODE = GL.GLACCOUNTCODE)
			JOIN OPENITEM OI		ON (GL.KEYFIELD3 = OI.ITEMENTITYNO
							AND GL.KEYFIELD4 = OI.ITEMTRANSNO
							AND GL.KEYFIELD5 = OI.ACCTENTITYNO
							AND GL.KEYFIELD6 = OI.ACCTDEBTORNO)
			LEFT JOIN PROFITCENTRE P	ON (P.ENTITYNO = GL.ACCTENTITYNO
							AND P.PROFITCENTRECODE = OI.EMPPROFITCENTRE)
			WHERE (GL.LEDGER = 2 OR GL.LEDGER = 3)  
			AND (GL.WIPCODE is null and GL.WIPTYPEID is null and GL.WIPCATEGORYCODE is null and GL.WIPEMPLOYEENO is null)   
			AND OI.EMPPROFITCENTRE IS NOT NULL
			AND GLA.DERIVEPCRAISEDSTAFF = 1"
		
			exec @nErrorCode=sp_executesql @sSQLString    
		End

		-- option 'Billed Wip Criteria applicable' is on so derive the profit centre at WIP level
		-- IDC_GLMAPPING_UDOIPC3
		If (@nErrorCode=0)
		Begin
			Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
			CASE WHEN GL.GLACCOUNTCODE LIKE '%[[]Raised By Staff PC]%' THEN stuff(GL.GLACCOUNTCODE, patindex('%[[]Raised By Staff PC]%', GL.GLACCOUNTCODE), 20, P.PROFITCENTRECODE) ELSE GL.GLACCOUNTCODE END,
			ACCTPROFITCENTRE = P.PROFITCENTRECODE
			FROM #GLMAPPING GL
			JOIN GENERALLEDGERACCTS GLA	ON (GLA.GLACCOUNTCODE = GL.GLACCOUNTCODE)
			JOIN WORKHISTORY H		ON (GL.KEYFIELD1 = H.ENTITYNO
							AND GL.KEYFIELD2 = H.TRANSNO
							AND GL.SMALLKEYFIELD1 = H.WIPSEQNO
							AND GL.SMALLKEYFIELD2 = H.HISTORYLINENO)
			LEFT JOIN PROFITCENTRE P	ON (P.ENTITYNO = GL.ACCTENTITYNO
							AND P.PROFITCENTRECODE = H.EMPPROFITCENTRE)
			WHERE GL.LEDGER = 2
			AND (GL.WIPCODE is not null or GL.WIPTYPEID is not null or GL.WIPCATEGORYCODE is not null or GL.WIPEMPLOYEENO is not null)   
			AND H.EMPPROFITCENTRE IS NOT NULL 
			AND GLA.DERIVEPCRAISEDSTAFF = 1"
			
			exec @nErrorCode=sp_executesql @sSQLString    
		End

	End
	Else If @nErrorCode=0
	Begin
		-- Update Rows where the AcctProfitCentre is to be derived - for OpenItem transactions
		-- Update Rows where the account code is assembled from the derived Employee Profit Centre - for OpenItem Transactions
		-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
		-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
		-- IDC_GLMAPPING_UDOIPC
		Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
		CASE WHEN GL.GLACCOUNTCODE LIKE '%[[]Raised By Staff PC]%' THEN stuff(GL.GLACCOUNTCODE, patindex('%[[]Raised By Staff PC]%', GL.GLACCOUNTCODE), 20, P.PROFITCENTRECODE) ELSE GL.GLACCOUNTCODE END,
		ACCTPROFITCENTRE = P.PROFITCENTRECODE
		FROM #GLMAPPING GL
		JOIN GENERALLEDGERACCTS GLA	ON (GLA.GLACCOUNTCODE = GL.GLACCOUNTCODE)
		JOIN OPENITEM OI		ON (GL.KEYFIELD3 = OI.ITEMENTITYNO
						AND GL.KEYFIELD4 = OI.ITEMTRANSNO
						AND GL.KEYFIELD5 = OI.ACCTENTITYNO
						AND GL.KEYFIELD6 = OI.ACCTDEBTORNO)
		LEFT JOIN PROFITCENTRE P	ON (P.ENTITYNO = GL.ACCTENTITYNO
						AND P.PROFITCENTRECODE = OI.EMPPROFITCENTRE)
		WHERE (GL.LEDGER = 2 OR GL.LEDGER = 3) 
		AND OI.EMPPROFITCENTRE IS NOT NULL
		AND GLA.DERIVEPCRAISEDSTAFF = 1"
	
		exec @nErrorCode=sp_executesql @sSQLString    

		If @pbDebugFlag = 1
		Begin
			Print ''
			Print '	-- Update Rows where the AcctProfitCentre is to be derived - for OpenItem transactions
			-- Update Rows where the account code is assembled from the derived Employee Profit Centre - for OpenItem Transactions
			-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
			-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
			-- IDC_GLMAPPING_UDOIPC'
			print @sSQLString
		End
	End


	
	If @nErrorCode=0
	Begin
		-- Update Rows where AcctProfitCentre is to be derived - for WIP transactions
		-- Update Rows where the account code is assembled from the derived Case Profit Centre - for WIP Transactions
		-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
		-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
		-- IDC_GLMAPPING_UDWCPC
		Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
		CASE WHEN GL.GLACCOUNTCODE LIKE '%[[]Case/Raised By Staff PC]%' THEN stuff(GL.GLACCOUNTCODE, patindex('%[[]Case/Raised By Staff PC]%', GL.GLACCOUNTCODE), 25, ISNULL( CPC.PROFITCENTRECODE, EPC.PROFITCENTRECODE )) ELSE GL.GLACCOUNTCODE END,
		ACCTPROFITCENTRE = ISNULL( CPC.PROFITCENTRECODE, EPC.PROFITCENTRECODE )
		FROM #GLMAPPING GL
		JOIN GENERALLEDGERACCTS GLA	ON (GLA.GLACCOUNTCODE = GL.GLACCOUNTCODE)
		JOIN WORKHISTORY H		ON (GL.KEYFIELD1 = H.ENTITYNO
						AND GL.KEYFIELD2 = H.TRANSNO
						AND GL.SMALLKEYFIELD1 = H.WIPSEQNO
						AND GL.SMALLKEYFIELD2 = H.HISTORYLINENO)
		LEFT JOIN PROFITCENTRE CPC	ON (CPC.ENTITYNO = GL.ACCTENTITYNO
						AND CPC.PROFITCENTRECODE = H.CASEPROFITCENTRE)
		LEFT JOIN PROFITCENTRE EPC	ON (EPC.ENTITYNO = GL.ACCTENTITYNO
						AND EPC.PROFITCENTRECODE = H.EMPPROFITCENTRE)
		WHERE GL.LEDGER = 1 
		AND ( (H.CASEPROFITCENTRE IS NOT NULL) OR (H.EMPPROFITCENTRE IS NOT NULL ) )
		AND GLA.DERIVEPCCASESTAFF = 1"
	
		exec @nErrorCode=sp_executesql @sSQLString  

		If @pbDebugFlag = 1
		Begin
			Print ''
			Print '	-- Update Rows where AcctProfitCentre is to be derived - for WIP transactions
			-- Update Rows where the account code is assembled from the derived Case Profit Centre - for WIP Transactions
			-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
			-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
			-- IDC_GLMAPPING_UDWCPC'
			print @sSQLString
		End  	
	End


	-- SQA21691 calculate derive profit centre for cash accounting at WIP or Debtor level
	If (@bCashAccounting = 1) AND (@nErrorCode=0)
	Begin
		-- option 'Billed Wip Criteria applicable' is off, derive the profit centre at debtor(OPENITEM) level 
		If @nErrorCode=0
		Begin
			-- Update Rows where the AcctProfitCentre is to be derived - for OpenItem transactions
			-- Update Rows where the account code is assembled from the derived Case Profit Centre - for OpenItem Transactions
			-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
			-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
			-- IDC_GLMAPPING_UDOICPC2
			Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
			CASE WHEN GL.GLACCOUNTCODE LIKE '%[[]Case/Raised By Staff PC]%' THEN stuff(GL.GLACCOUNTCODE, patindex('%[[]Case/Raised By Staff PC]%', GL.GLACCOUNTCODE), 25, ISNULL( CPC.PROFITCENTRECODE, EPC.PROFITCENTRECODE )) ELSE GL.GLACCOUNTCODE END,
			ACCTPROFITCENTRE = ISNULL( CPC.PROFITCENTRECODE, EPC.PROFITCENTRECODE )
			FROM #GLMAPPING GL
			JOIN GENERALLEDGERACCTS GLA	ON (GLA.GLACCOUNTCODE = GL.GLACCOUNTCODE)
			JOIN OPENITEM OI		ON (GL.KEYFIELD3 = OI.ITEMENTITYNO
							AND GL.KEYFIELD4 = OI.ITEMTRANSNO
							AND GL.KEYFIELD5 = OI.ACCTENTITYNO
							AND GL.KEYFIELD6 = OI.ACCTDEBTORNO)
			LEFT JOIN PROFITCENTRE CPC	ON (CPC.ENTITYNO = GL.ACCTENTITYNO
							AND CPC.PROFITCENTRECODE = OI.CASEPROFITCENTRE)
			LEFT JOIN PROFITCENTRE EPC	ON (EPC.ENTITYNO = GL.ACCTENTITYNO
							AND EPC.PROFITCENTRECODE = OI.EMPPROFITCENTRE)
			WHERE	( GL.LEDGER = 2 OR GL.LEDGER = 3) 
			AND ( (OI.CASEPROFITCENTRE IS NOT NULL) OR (OI.EMPPROFITCENTRE IS NOT NULL ) )
			AND (GL.WIPCODE is null and GL.WIPTYPEID is null and GL.WIPCATEGORYCODE is null and GL.WIPEMPLOYEENO is null)   
			AND GLA.DERIVEPCCASESTAFF = 1"
		
			exec @nErrorCode=sp_executesql @sSQLString   

			If @pbDebugFlag = 1
			Begin
				Print ''
				Print '	-- Update Rows where the AcctProfitCentre is to be derived - for OpenItem transactions
				-- Update Rows where the account code is assembled from the derived Case Profit Centre - for OpenItem Transactions
				-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
				-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
				-- IDC_GLMAPPING_UDOICPC2'
				print @sSQLString
			End  
		End
		If @nErrorCode=0
		Begin
			-- Update Rows where AcctProfitCentre is to be derived - for Debtors transactions
			-- Update Rows where the account code is assembled from the derived Case Profit Centre - for Debtors Transactions
			-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
			-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
			-- IDC_GLMAPPING_UDOICPC3
			Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
			CASE WHEN GL.GLACCOUNTCODE LIKE '%[[]Case/Raised By Staff PC]%' THEN stuff(GL.GLACCOUNTCODE, patindex('%[[]Case/Raised By Staff PC]%', GL.GLACCOUNTCODE), 25, ISNULL( CPC.PROFITCENTRECODE, EPC.PROFITCENTRECODE )) ELSE GL.GLACCOUNTCODE END,
			ACCTPROFITCENTRE = ISNULL( CPC.PROFITCENTRECODE, EPC.PROFITCENTRECODE )
			FROM #GLMAPPING GL
			JOIN GENERALLEDGERACCTS GLA	ON (GLA.GLACCOUNTCODE = GL.GLACCOUNTCODE)
			JOIN WORKHISTORY H		ON (GL.KEYFIELD1 = H.ENTITYNO
							AND GL.KEYFIELD2 = H.TRANSNO
							AND GL.SMALLKEYFIELD1 = H.WIPSEQNO
							AND GL.SMALLKEYFIELD2 = H.HISTORYLINENO)
			LEFT JOIN PROFITCENTRE CPC	ON (CPC.ENTITYNO = GL.ACCTENTITYNO
							AND CPC.PROFITCENTRECODE = H.CASEPROFITCENTRE)
			LEFT JOIN PROFITCENTRE EPC	ON (EPC.ENTITYNO = GL.ACCTENTITYNO
							AND EPC.PROFITCENTRECODE = H.EMPPROFITCENTRE)
			WHERE GL.LEDGER = 2 
			AND ( (H.CASEPROFITCENTRE IS NOT NULL) OR (H.EMPPROFITCENTRE IS NOT NULL ) )
			AND (GL.WIPCODE is not null or GL.WIPTYPEID is not null or GL.WIPCATEGORYCODE is not null or GL.WIPEMPLOYEENO is not null)   
			AND GLA.DERIVEPCCASESTAFF = 1"
		
			exec @nErrorCode=sp_executesql @sSQLString  

			If @pbDebugFlag = 1
			Begin
				Print ''
				Print '	-- Update Rows where AcctProfitCentre is to be derived - for debtors transactions
				-- Update Rows where the account code is assembled from the derived Case Profit Centre - for debtors Transactions
				-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
				-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
				-- IDC_GLMAPPING_UDOICPC3'
				print @sSQLString
			End  	
		End
	End
	Else If @nErrorCode=0
	Begin
		-- Update Rows where the AcctProfitCentre is to be derived - for OpenItem transactions
		-- Update Rows where the account code is assembled from the derived Case Profit Centre - for OpenItem Transactions
		-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
		-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
		-- IDC_GLMAPPING_UDOICPC
		Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
		CASE WHEN GL.GLACCOUNTCODE LIKE '%[[]Case/Raised By Staff PC]%' THEN stuff(GL.GLACCOUNTCODE, patindex('%[[]Case/Raised By Staff PC]%', GL.GLACCOUNTCODE), 25, ISNULL( CPC.PROFITCENTRECODE, EPC.PROFITCENTRECODE )) ELSE GL.GLACCOUNTCODE END,
		ACCTPROFITCENTRE = ISNULL( CPC.PROFITCENTRECODE, EPC.PROFITCENTRECODE )
		FROM #GLMAPPING GL
		JOIN GENERALLEDGERACCTS GLA	ON (GLA.GLACCOUNTCODE = GL.GLACCOUNTCODE)
		JOIN OPENITEM OI		ON (GL.KEYFIELD3 = OI.ITEMENTITYNO
						AND GL.KEYFIELD4 = OI.ITEMTRANSNO
						AND GL.KEYFIELD5 = OI.ACCTENTITYNO
						AND GL.KEYFIELD6 = OI.ACCTDEBTORNO)
		LEFT JOIN PROFITCENTRE CPC	ON (CPC.ENTITYNO = GL.ACCTENTITYNO
						AND CPC.PROFITCENTRECODE = OI.CASEPROFITCENTRE)
		LEFT JOIN PROFITCENTRE EPC	ON (EPC.ENTITYNO = GL.ACCTENTITYNO
						AND EPC.PROFITCENTRECODE = OI.EMPPROFITCENTRE)
		WHERE	( GL.LEDGER = 2 OR GL.LEDGER = 3) 
		AND ( (OI.CASEPROFITCENTRE IS NOT NULL) OR (OI.EMPPROFITCENTRE IS NOT NULL ) )
		AND GLA.DERIVEPCCASESTAFF = 1"
	
		exec @nErrorCode=sp_executesql @sSQLString   

		If @pbDebugFlag = 1
		Begin
			Print ''
			Print '	-- Update Rows where the AcctProfitCentre is to be derived - for OpenItem transactions
			-- Update Rows where the account code is assembled from the derived Case Profit Centre - for OpenItem Transactions
			-- Do this after all posible scenarios for AcctEntityNo have been executed as this uses the AcctEntityNo (where available) 
			-- to ensure the Profit Centre derived is valid i.e. for the selected Entity.
			-- IDC_GLMAPPING_UDOICPC'
			print @sSQLString
		End  
	End


	If @nErrorCode=0
	Begin
		-- Update Rows where the Account code is assembled from the derived Entity 
		-- Do this last as the Profit Centre relies on joining by GLACCOUNTCODE	
		Set @sSQLString="UPDATE #GLMAPPING SET GLACCOUNTCODE =
		stuff(GLACCOUNTCODE, patindex('%[[]Entity]%', GLACCOUNTCODE), 8, E.NAMECODE)
		FROM #GLMAPPING GL
		JOIN NAME E ON (E.NAMENO = GL.ENTITY)
		WHERE GLACCOUNTCODE LIKE '%[[]Entity]%' "
	
		exec @nErrorCode=sp_executesql @sSQLString  

		If @pbDebugFlag = 1
		Begin
			Print ''
			Print '	-- Update Rows where the Account code is assembled from the derived Entity 
			-- Do this last as the Profit Centre relies on joining by GLACCOUNTCODE	'
			print @sSQLString
		End
	End
End



/*************************************************************************************************
-- Step through rows for billed WIP and calculate the billed value - only relevant for Cash Accounting
-- __cfUpdateBilledWIP
--browse for billed WIP
-- cfDBBrowseBilledWIP
-- must sort by accounttype when the same transaction has multiple account types
-- Refer to sign of WORKHISTORY consume record to determine sign of percentage - required to cater for Discounts
*************************************************************************************************/
If (@bCashAccounting = 1) AND (@nErrorCode=0) AND @bFIWipPaymentPref = 0
Begin
	-- Ensure temporary table is empty before beginning
	TRUNCATE TABLE #SPLITWIP

	-- sqa22138 deduct discount wip
	Set @sSQLString = "INSERT INTO #SPLITWIP (ACCOUNTTYPE, BILLPERCENTAGE, KEYFIELD1, KEYFIELD2, KEYFIELD3, 
				KEYFIELD4, KEYFIELD5, OPENITEMNO, KEYFIELD6, LEDGER, 
				LOCALAMOUNT, FOREIGNAMOUNT, SMALLKEYFIELD1, SMALLKEYFIELD2, MOVEMENTCLASS, DISCOUNTFLAG)
				
		SELECT DISTINCT #GLMAPPING.ACCOUNTTYPE, 

			abs(( (abs(#GLMAPPING.LOCALAMOUNT) - abs(isnull(WHD.LOCALTRANSVALUE, 0))) * CASE WHEN H.LOCALTRANSVALUE > 0 THEN -1 ELSE 1 END  ) / 
			abs(CASE WHEN GLA.AMOUNTTYPE = 6612 THEN OI.ITEMPRETAXVALUE ELSE  OI.LOCALVALUE END) ) * 100 AS PERCENTAGE, 

			KEYFIELD1, KEYFIELD2, KEYFIELD3,  
			KEYFIELD4,  KEYFIELD5, OI.OPENITEMNO, KEYFIELD6, 
			#GLMAPPING.LEDGER, 
			
			ABS( CASE 	WHEN GLA.AMOUNTTYPE = 6612
			THEN (ABS(DH.LOCALVALUE) - 
			-- SQA19897 Ensure when OI.LOCALVALUE=0 does not cause divide by zero erro
			CASE WHEN ISNULL(OI.LOCALVALUE, 0) = 0 THEN 0 ELSE ABS((DH.LOCALVALUE / OI.LOCALVALUE) * OI.LOCALTAXAMT) END)
			ELSE CASE WHEN GLA.AMOUNTTYPE = 6631
				 THEN DH.LOCALTAXAMT
				 ELSE DH.LOCALVALUE
				 END
			END ) AS LOCALVALUE, 

		ABS( CASE 	WHEN GLA.AMOUNTTYPE = 6612
			-- SQA19897 Ensure when OI.LOCALVALUE=0 does not cause divide by zero erro
--			THEN (ABS(DH.FOREIGNTRANVALUE) - ABS((DH.LOCALVALUE / OI.LOCALVALUE) * OI.FOREIGNTAXAMT))
			THEN (ABS(DH.FOREIGNTRANVALUE) -
				(CASE WHEN ISNULL(OI.LOCALVALUE, 0) = 0 THEN 0 ELSE ABS((DH.LOCALVALUE / OI.LOCALVALUE) * OI.FOREIGNTAXAMT) END))
			ELSE CASE WHEN GLA.AMOUNTTYPE = 6631
				 THEN DH.FOREIGNTAXAMT
				 ELSE DH.FOREIGNTRANVALUE
				 END
			END ) AS FOREIGNVALUE,
		
			SMALLKEYFIELD1, SMALLKEYFIELD2, #GLMAPPING.MOVEMENTCLASS, H.DISCOUNTFLAG
			FROM #GLMAPPING
			JOIN GLACCOUNTING GLA	ON GLA.MOVEMENTCLASS = #GLMAPPING.MOVEMENTCLASS
						AND GLA.ACCOUNTTYPE = #GLMAPPING.ACCOUNTTYPE 
			JOIN GLACCOUNTTYPE AT	ON AT.ACCOUNTTYPE = GLA.ACCOUNTTYPE
			JOIN DEBTORHISTORY DH	ON DH.REFENTITYNO = #GLMAPPING.ENTITY
						AND DH.REFTRANSNO = #GLMAPPING.TRANSNO
						AND DH.ACCTDEBTORNO = #GLMAPPING.KEYFIELD6
						AND DH.MOVEMENTCLASS = #GLMAPPING.MOVEMENTCLASS
			JOIN OPENITEM OI	ON OI.ITEMENTITYNO = DH.ITEMENTITYNO
						AND OI.ITEMTRANSNO = DH.ITEMTRANSNO
						AND OI.ACCTENTITYNO = DH.ACCTENTITYNO
						AND OI.ACCTDEBTORNO = DH.ACCTDEBTORNO
			JOIN WORKHISTORY H	ON H.REFENTITYNO = DH.ITEMENTITYNO 
						AND H.REFTRANSNO = DH.ITEMTRANSNO
						AND H.ENTITYNO = #GLMAPPING.KEYFIELD1
						AND H.TRANSNO = #GLMAPPING.KEYFIELD2
						AND H.WIPSEQNO = #GLMAPPING.SMALLKEYFIELD1
						AND H.HISTORYLINENO = #GLMAPPING.SMALLKEYFIELD2	
			-- SQA22138 handle discount
			LEFT JOIN WORKHISTORY WHD 	ON (WHD.TRANSNO = H.TRANSNO
					AND WHD.ENTITYNO = H.ENTITYNO
					AND WHD.HISTORYLINENO = H.HISTORYLINENO
					AND WHD.WIPSEQNO = H.WIPSEQNO + 1
					AND WHD.DISCOUNTFLAG = 1)
							
			WHERE #GLMAPPING.LEDGER = 2
			AND AT.USEBILLEDWIPCRITERIA = 1
			AND H.MOVEMENTCLASS = 2
			ORDER BY #GLMAPPING.ACCOUNTTYPE, KEYFIELD3, KEYFIELD4, KEYFIELD5, OI.OPENITEMNO, KEYFIELD6, 
			#GLMAPPING.MOVEMENTCLASS, KEYFIELD1, KEYFIELD2, SMALLKEYFIELD1, SMALLKEYFIELD2"

			exec @nErrorCode=sp_executesql @sSQLString

			If @pbDebugFlag = 1
			Begin
				Print ''
				Print '	/*************************************************************************************************
			-- Step through rows for billed WIP and calculate the billed value - only relevant for Cash Accounting
			-- __cfUpdateBilledWIP
			--browse for billed WIP
			-- cfDBBrowseBilledWIP
			-- must sort by accounttype when the same transaction has multiple account types
			-- Refer to sign of WORKHISTORY consume record to determine sign of percentage - required to cater for Discounts
			*************************************************************************************************/'
				print @sSQLString

				SELECT * FROM #SPLITWIP
			End


	-- sqa22138 remove discounted wip
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "DELETE G
		from #GLMAPPING G
		JOIN #SPLITWIP S ON S.LEDGER = G.LEDGER
			and S.ACCOUNTTYPE = G.ACCOUNTTYPE
			and S.KEYFIELD1 = G.KEYFIELD1
			and S.KEYFIELD2 = G.KEYFIELD2
			and S.KEYFIELD3 = G.KEYFIELD3
			and S.KEYFIELD4 = G.KEYFIELD4
			and S.KEYFIELD5 = G.KEYFIELD5
			and S.KEYFIELD6 = G.KEYFIELD6
			and S.SMALLKEYFIELD1 = G.SMALLKEYFIELD1
			and S.SMALLKEYFIELD2 = G.SMALLKEYFIELD2
		WHERE S.DISCOUNTFLAG = 1"

		exec @nErrorCode=sp_executesql @sSQLString
	End

	
	
	If @nErrorCode = 0
	Begin
		-- 17799 MOVED THIS BLOCK TO AFTER FETCHING THE FIRST ROW	
		-- First row
		--Set @nPercentRemainder = 100
		--Set @nTotalAmount = @nLocalAmount
		--Set @nTotalAmountRemainder = @nTotalAmount
		--Set @nTotalForeign = @nForeignAmount
		--Set @nTotalForeignRemainder = @nTotalForeign
		

		Set @sSQLString=" Select @nSeqNo=min(SEQNO)
		from #SPLITWIP
		WHERE DISCOUNTFLAG <> 1"				-- SQA22138 Ignore discount
		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nSeqNo	int		OUTPUT',
					@nSeqNo		= @nSeqNo	OUTPUT

		If @nErrorCode = 0
		Begin
			-- sqa17799 select SMALLKEYFIELD1, SMALLKEYFIELD2 = WORKHISTORY.WIPSEQNO and HISTORYLINENO
			-- sqa22138 select KEYFIELD2 = WORKHISTORY.TRANSNO
			Set @sSQLString="SELECT @nCurrentAccountType=ACCOUNTTYPE, @nBillPercentage=BILLPERCENTAGE, 
			@nCurrentKeyField2=KEYFIELD2, @nCurrentKeyField3=KEYFIELD3, @nCurrentKeyField4=KEYFIELD4, @nCurrentKeyField5=KEYFIELD5, 
			@nCurrentKeyField6=KEYFIELD6, @nCurrentLedger=LEDGER, @nLocalAmount=LOCALAMOUNT, @nForeignAmount=FOREIGNAMOUNT, 
			@nCurrentMovementClass=MOVEMENTCLASS, @nCurrentSmallKeyField1=SMALLKEYFIELD1, @nCurrentSmallKeyField2=SMALLKEYFIELD2
			
			from #SPLITWIP
			WHERE SEQNO = @nSeqNo"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nCurrentAccountType	int OUTPUT, 
							@nBillPercentage	decimal(7,4) OUTPUT, 
							@nCurrentKeyField2	int OUTPUT, 
							@nCurrentKeyField3	int OUTPUT, 
							@nCurrentKeyField4	int OUTPUT, 
							@nCurrentKeyField5	int OUTPUT, 
							@nCurrentKeyField6	int OUTPUT, 
							@nCurrentLedger		int OUTPUT, 
							@nLocalAmount		decimal(11,2)		OUTPUT, 
							@nForeignAmount		decimal(11,2)		OUTPUT, 
							@nCurrentMovementClass	int OUTPUT,
							@nCurrentSmallKeyField1 int OUTPUT, 
							@nCurrentSmallKeyField2 int OUTPUT, 
							@nSeqNo			int',
							@nCurrentAccountType = @nCurrentAccountType	OUTPUT, 
							@nBillPercentage = @nBillPercentage		OUTPUT, 
							@nCurrentKeyField2 = @nCurrentKeyField2		OUTPUT, 
							@nCurrentKeyField3 = @nCurrentKeyField3		OUTPUT, 
							@nCurrentKeyField4 = @nCurrentKeyField4		OUTPUT, 
							@nCurrentKeyField5 = @nCurrentKeyField5		OUTPUT, 
							@nCurrentKeyField6 = @nCurrentKeyField6		OUTPUT, 
							@nCurrentLedger = @nCurrentLedger		OUTPUT, 
							@nLocalAmount = @nLocalAmount			OUTPUT, 
							@nForeignAmount = @nForeignAmount		OUTPUT, 
							@nCurrentMovementClass = @nCurrentMovementClass OUTPUT,
							@nCurrentSmallKeyField1 = @nCurrentSmallKeyField1 OUTPUT, 
							@nCurrentSmallKeyField2 = @nCurrentSmallKeyField2 OUTPUT, 
							@nSeqNo	= @nSeqNo

			If @pbDebugFlag = 1
			Begin
				Print ''
				print '-- First Row'
				print @sSQLString
				Select @nCurrentAccountType as CurrentAccountType, 
							@nBillPercentage as BillPercentage, 
							@nCurrentKeyField2 as CurrentKeyField2, 
							@nCurrentKeyField3 as CurrentKeyField3, 
							@nCurrentKeyField4  as CurrentKeyField4, 
							@nCurrentKeyField5 as CurrentKeyField5, 
							@nCurrentKeyField6 as CurrentKeyField6, 
							@nCurrentLedger as CurrentLedger, 
							@nLocalAmount as LocalAmount, 
							@nForeignAmount as ForeignAmount, 
							@nCurrentMovementClass as CurrentMovementClass,
							@nCurrentSmallKeyField1 as CurrentSmallKeyField1,
							@nCurrentSmallKeyField2 as CurrentSmallKeyField2,
							@nSeqNo	as SeqNo
			End

			If @nErrorCode = 0
			Begin
				-- SQA17799 intialise here after the first fetch				
				-- First row
				Set @nPercentRemainder = 100.00
				Set @nTotalAmount = @nLocalAmount
				Set @nTotalAmountRemainder = @nTotalAmount
				Set @nTotalForeign = @nForeignAmount
				Set @nTotalForeignRemainder = @nTotalForeign
			
				-- SQA17799 do this initialise after processing the first row			
				-- copy details of current row
				Set @nPrevAccountType = @nCurrentAccountType
				Set @nPrevKeyField2 = @nCurrentKeyField2
				Set @nPrevKeyField3 = @nCurrentKeyField3
				Set @nPrevKeyField4 = @nCurrentKeyField4
				Set @nPrevKeyField5 = @nCurrentKeyField5
				Set @nPrevKeyField6 = @nCurrentKeyField6
				Set @nPrevLedger = @nCurrentLedger
				Set @nPrevMovementClass = @nCurrentMovementClass
				Set @nPrevSmallKeyField1 = @nCurrentSmallKeyField1					-- SQA17799
				Set @nPrevSmallKeyField2 = @nCurrentSmallKeyField2					-- SQA17799
			End
		End

	End

	While @nSeqNo is not null
	and   @nErrorCode = 0
	Begin
		/***/
		-- For each row
		-- check to see if moved onto the next invoice
		If	( @nCurrentKeyField3 <> @nPrevKeyField3 ) OR
			( @nCurrentKeyField4 <> @nPrevKeyField4 ) OR
			( @nCurrentKeyField5 <> @nPrevKeyField5 ) OR
			( @nCurrentKeyField6 <> @nPrevKeyField6 ) OR
			( @nCurrentLedger <> @nPrevLedger ) OR
			--( @nCurrentSmallKeyField1 <> @nPrevSmallKeyField1 ) OR			-- SQA17799
			--( @nCurrentSmallKeyField2 <> @nPrevSmallKeyField2 ) OR			-- SQA17799
			( @nCurrentMovementClass <> @nPrevMovementClass )OR
			( @nCurrentAccountType <> @nPrevAccountType )
		Begin
			-- current row is a new WIP item. If there is still a remainder from the last WIP item
			-- update the previous row with this remainder
			If ( ( @nTotalAmountRemainder IS NOT NULL ) AND ( @nTotalAmountRemainder <> 0 ) ) OR
			( ( @nTotalForeignRemainder IS NOT NULL ) AND ( @nTotalForeignRemainder <> 0 ) )
			Begin
				Set @nAdjLocalAmount = @nSplitLocal + @nTotalAmountRemainder
				Set @nAdjForeignAmount = @nSplitForeign + @nTotalForeignRemainder

				-- The entries for the movement may be either positive or negative, and we want to retain the sign
				Set @sSQLString = "UPDATE #GLMAPPING
				SET LOCALAMOUNT = CASE WHEN LOCALAMOUNT < 0 THEN @nAdjLocalAmount * -1 ELSE @nAdjLocalAmount END,
				FOREIGNAMOUNT = CASE WHEN FOREIGNAMOUNT < 0 THEN @nAdjForeignAmount * -1 ELSE @nAdjForeignAmount END"

				-- __ Replace the where clause
				-- for the previous row
				-- Set sWhere = uSQLUtility.cfAppendAnd( @sWhere,  __cfGetLedgerKeyWhere() )
				Set @sSQLString = @sSQLString + "
					WHERE LEDGER = @nPrevLedger
					AND ACCOUNTTYPE = @nPrevAccountType
					AND KEYFIELD3 = @nPrevKeyField3 
					AND KEYFIELD4 = @nPrevKeyField4
					AND KEYFIELD5 = @nPrevKeyField5
					AND KEYFIELD6 = @nPrevKeyField6
					AND MOVEMENTCLASS = @nPrevMovementClass
					AND SMALLKEYFIELD1 = @nPrevSmallKeyField1			
					AND SMALLKEYFIELD2 = @nPrevSmallKeyField2"

				exec @nErrorCode=sp_executesql @sSQLString,
						N'@nAdjLocalAmount decimal(11,2),
						@nAdjForeignAmount decimal(11,2),
						@nPrevLedger int,
						@nPrevAccountType int,
						@nPrevKeyField3 int,  
						@nPrevKeyField4 int,
						@nPrevKeyField5 int,
						@nPrevKeyField6 int,
						@nPrevMovementClass int,
						@nPrevSmallKeyField1 int,
						@nPrevSmallKeyField2 int',
						@nAdjLocalAmount = @nAdjLocalAmount,
						@nAdjForeignAmount = @nAdjForeignAmount,
						@nPrevLedger = @nPrevLedger,
						@nPrevAccountType = @nPrevAccountType,
						@nPrevKeyField3 = @nPrevKeyField3,  
						@nPrevKeyField4 = @nPrevKeyField4,
						@nPrevKeyField5 = @nPrevKeyField5,
						@nPrevKeyField6 = @nPrevKeyField6,
						@nPrevMovementClass = @nPrevMovementClass,
						@nPrevSmallKeyField1 = @nPrevSmallKeyField1,
						@nPrevSmallKeyField2 = @nPrevSmallKeyField2						

				If @pbDebugFlag = 1
				Begin
					Print ''
					print ' -- current row is a new WIP item. If there is still a remainder from the last WIP item
				-- update the previous row with this remainder'
					print @sSQLString
					Select @nLocalAmount as LocalAmount,
						@nForeignAmount as ForeignAmount,
						@nPrevLedger as PrevLedger,
						@nPrevAccountType as PrevAccountType,
						@nPrevKeyField3 as PrevKeyField3,  
						@nPrevKeyField4 as PrevKeyField4,
						@nPrevKeyField5 as PrevKeyField5,
						@nPrevKeyField6 as PrevKeyField6,
						@nPrevMovementClass as PrevMovementClass,
						@nPrevSmallKeyField1 as PrevSmallKeyField1,
						@nPrevSmallKeyField2 as PrevSmallKeyField2						
				End
			End


			If @nErrorCode = 0
			Begin
				-- change of transaction (invoice) or Account Type
				Set @nTotalAmount = @nLocalAmount
				Set @nTotalForeign = @nForeignAmount
				Set @nPercentRemainder = 100.00			
				Set @nTotalAmountRemainder = @nTotalAmount
				Set @nTotalForeignRemainder = @nTotalForeign
			End
		End

		If @nErrorCode = 0
		Begin 
			Set @nSplitLocal = NULL
			Set @nSplitForeign = NULL

			-- __cfGetSplitAmounts
			If ( @nBillPercentage = @nPercentRemainder ) 
			Begin
				-- This is the last split - avoid rounding errors
				Set @nSplitLocal = @nTotalAmountRemainder
				Set @nTotalAmountRemainder = 0
				Set @nSplitForeign = @nTotalForeignRemainder
				Set @nTotalForeignRemainder = 0
				Set @nPercentRemainder = 0
			End
			Else
			Begin
				Set @nPercentRemainder = @nPercentRemainder - @nBillPercentage
				-- perform necessary rounding
				Set @nSplitLocal = round(( @nTotalAmount * @nBillPercentage / 100 ), 2)
				Set @nTotalAmountRemainder = @nTotalAmountRemainder - @nSplitLocal
				
				-- Get the rounded foreign amount too.
				If ( @nTotalForeign IS NOT NULL AND @nTotalForeign <> 0 )
				Begin
					Set @nSplitForeign = round(( @nTotalForeign * @nBillPercentage / 100 ), 2)
					Set @nTotalForeignRemainder = @nTotalForeignRemainder - @nSplitForeign
				End
			End

			-- for every WIP row found do an update with the calcuated split values as follows
			-- The entries for the movement may be either positive or negative, and we want to retain the sign
			Set @sSQLString = "UPDATE #GLMAPPING
			SET LOCALAMOUNT = CASE WHEN LOCALAMOUNT < 0 THEN @nSplitLocal * -1 ELSE @nSplitLocal END,
			FOREIGNAMOUNT = CASE WHEN FOREIGNAMOUNT < 0 THEN @nSplitForeign * -1 ELSE @nSplitForeign END"
			-- __ Replace the where clause
			-- Current Row
			-- Set sWhere = uSQLUtility.cfAppendAnd( @sWhere,  __cfGetLedgerKeyWhere() )
			-- SQA22138 add filter by KEYFIELD2 (WORKHISTORY.TRANSNO) to handle wip that was not created by the bill 
			Set @sSQLString = @sSQLString + "
			WHERE LEDGER = @nCurrentLedger
			AND ACCOUNTTYPE = @nCurrentAccountType
			AND KEYFIELD2 = @nCurrentKeyField2 
			AND KEYFIELD3 = @nCurrentKeyField3 
			AND KEYFIELD4 = @nCurrentKeyField4
			AND KEYFIELD5 = @nCurrentKeyField5
			AND KEYFIELD6 = @nCurrentKeyField6
			AND MOVEMENTCLASS = @nCurrentMovementClass
			AND SMALLKEYFIELD1 = @nCurrentSmallKeyField1
			AND SMALLKEYFIELD2 = @nCurrentSmallKeyField2"
			
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nSplitLocal decimal(11,2),
					@nSplitForeign decimal(11,2),
					@nCurrentLedger int,
					@nCurrentAccountType int,
					@nCurrentKeyField2 int,  
					@nCurrentKeyField3 int,  
					@nCurrentKeyField4 int,
					@nCurrentKeyField5 int,
					@nCurrentKeyField6 int,
					@nCurrentMovementClass int,
					@nCurrentSmallKeyField1 int,
					@nCurrentSmallKeyField2 int',
					@nSplitLocal = @nSplitLocal,
					@nSplitForeign = @nSplitForeign,
					@nCurrentLedger = @nCurrentLedger,
					@nCurrentAccountType = @nCurrentAccountType,
					@nCurrentKeyField2 = @nCurrentKeyField2,  
					@nCurrentKeyField3 = @nCurrentKeyField3,  
					@nCurrentKeyField4 = @nCurrentKeyField4,
					@nCurrentKeyField5 = @nCurrentKeyField5,
					@nCurrentKeyField6 = @nCurrentKeyField6,
					@nCurrentMovementClass = @nCurrentMovementClass,
					@nCurrentSmallKeyField1 = @nCurrentSmallKeyField1, 
					@nCurrentSmallKeyField2 = @nCurrentSmallKeyField2 
					

			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- current row 
			-- for every WIP row found do an update with the calcuated split values'
				print @sSQLString
				Select @nSplitLocal as SplitLocal,
					@nSplitForeign as SplitForeign,
					@nCurrentLedger as CurrentLedger,
					@nCurrentAccountType as CurrentAccountType,
					@nCurrentKeyField2 as CurrentKeyField2, 
					@nCurrentKeyField3 as CurrentKeyField3,  
					@nCurrentKeyField4 as CurrentKeyField4,
					@nCurrentKeyField5 as CurrentKeyField5,
					@nCurrentKeyField6 as CurrentKeyField6,
					@nCurrentSmallKeyField1 as CurrentSmallKeyField1,
					@nCurrentSmallKeyField2 as CurrentSmallKeyField2,
					@nCurrentMovementClass as CurrentMovementClass
			End

		
			-- copy details of current row before fetching the next row
			Set @nPrevAccountType = @nCurrentAccountType
			Set @nPrevKeyField2 = @nCurrentKeyField2
			Set @nPrevKeyField3 = @nCurrentKeyField3
			Set @nPrevKeyField4 = @nCurrentKeyField4
			Set @nPrevKeyField5 = @nCurrentKeyField5
			Set @nPrevKeyField6 = @nCurrentKeyField6
			Set @nPrevLedger = @nCurrentLedger
			Set @nPrevMovementClass = @nCurrentMovementClass
			Set @nPrevSmallKeyField1 = @nCurrentSmallKeyField1					
			Set @nPrevSmallKeyField2 = @nCurrentSmallKeyField2					


			Set @nTempSeqNo = @nSeqNo
			Set @nSeqNo = NULL

			-- Now get the next row
			If @nErrorCode = 0
			Begin
				Set @sSQLString=" Select @nSeqNoOUT = min(SEQNO)
				from #SPLITWIP
				where SEQNO > @nSeqNoIN
				and DISCOUNTFLAG <> 1"				-- SQA22138 Ignore discount
			
				exec @nErrorCode=sp_executesql @sSQLString,
						N'@nSeqNoOUT	int	OUTPUT,
						  @nSeqNoIN	int',
						  @nSeqNoOUT	= @nSeqNo	OUTPUT,
						  @nSeqNoIN	= @nTempSeqNo  -- @nSeqNo    sqa17799 - use @nTempSeqNo to get the next row
			End


			If @nErrorCode = 0  
			Begin
				Set @sSQLString="SELECT @nCurrentAccountType=ACCOUNTTYPE, @nBillPercentage=BILLPERCENTAGE, 
				@nCurrentKeyField2=KEYFIELD2, @nCurrentKeyField3=KEYFIELD3, @nCurrentKeyField4=KEYFIELD4, @nCurrentKeyField5=KEYFIELD5, 
				@nCurrentKeyField6=KEYFIELD6, @nCurrentLedger=LEDGER, @nLocalAmount=LOCALAMOUNT, @nForeignAmount=FOREIGNAMOUNT, 
				@nCurrentMovementClass=MOVEMENTCLASS, @nCurrentSmallKeyField1=SMALLKEYFIELD1, @nCurrentSmallKeyField2=SMALLKEYFIELD2
				from #SPLITWIP
				WHERE SEQNO = @nSeqNo"
			
				exec @nErrorCode=sp_executesql @sSQLString,
						N'@nCurrentAccountType int OUTPUT, 
						@nBillPercentage decimal(7,4) OUTPUT, 
						@nCurrentKeyField2 int OUTPUT, 
						@nCurrentKeyField3 int OUTPUT, 
						@nCurrentKeyField4 int OUTPUT, 
						@nCurrentKeyField5 int OUTPUT, 
						@nCurrentKeyField6 int OUTPUT, 
						@nCurrentLedger int OUTPUT, 
						@nLocalAmount decimal(11,2) OUTPUT, 
						@nForeignAmount decimal(11,2) OUTPUT, 
						@nCurrentMovementClass int OUTPUT,
						@nCurrentSmallKeyField1 int OUTPUT, 
						@nCurrentSmallKeyField2 int OUTPUT, 
						@nSeqNo	int',
						@nCurrentAccountType = @nCurrentAccountType OUTPUT, 
						@nBillPercentage = @nBillPercentage OUTPUT, 
						@nCurrentKeyField2 = @nCurrentKeyField2 OUTPUT, 
						@nCurrentKeyField3 = @nCurrentKeyField3 OUTPUT, 
						@nCurrentKeyField4 = @nCurrentKeyField4 OUTPUT, 
						@nCurrentKeyField5 = @nCurrentKeyField5 OUTPUT, 
						@nCurrentKeyField6 = @nCurrentKeyField6 OUTPUT, 
						@nCurrentLedger = @nCurrentLedger OUTPUT, 
						@nLocalAmount = @nLocalAmount OUTPUT, 
						@nForeignAmount = @nForeignAmount OUTPUT, 
						@nCurrentMovementClass = @nCurrentMovementClass OUTPUT,
						@nCurrentSmallKeyField1 = @nCurrentSmallKeyField1 OUTPUT, 
						@nCurrentSmallKeyField2 = @nCurrentSmallKeyField2 OUTPUT, 
						@nSeqNo	= @nSeqNo

				If @pbDebugFlag = 1
				Begin
					Print ''
					print '-- Get the Next Row'
					print @sSQLString
					Select @nCurrentAccountType as CurrentAccountType, 
								@nBillPercentage as BillPercentage, 
								@nCurrentKeyField2 as CurrentKeyField2, 
								@nCurrentKeyField3 as CurrentKeyField3, 
								@nCurrentKeyField4  as CurrentKeyField4, 
								@nCurrentKeyField5 as CurrentKeyField5, 
								@nCurrentKeyField6 as CurrentKeyField6, 
								@nCurrentLedger as CurrentLedger, 
								@nLocalAmount as LocalAmount, 
								@nForeignAmount as ForeignAmount, 
								@nCurrentMovementClass as CurrentMovementClass,
								@nCurrentSmallKeyField1 as CurrentSmallKeyField1,
								@nCurrentSmallKeyField2 as CurrentSmallKeyField2,
								@nSeqNo	as SeqNo
				End
			End
		End
	End
	
	If @nErrorCode = 0
	Begin 
		-- If there is still a remainder from the last WIP item
		-- update the previous row with this remainder
		If ( ( @nTotalAmountRemainder IS NOT NULL ) AND ( @nTotalAmountRemainder <> 0 ) ) OR
			( ( @nTotalForeignRemainder IS NOT NULL ) AND ( @nTotalForeignRemainder <> 0 ) )
		Begin
			Set @nLocalAmount = @nSplitLocal + @nTotalAmountRemainder
			Set @nForeignAmount = @nSplitForeign + @nTotalForeignRemainder
			-- The entries for the movement may be either positive or negative, and we want to retain the sign
			Set @sSQLString = "UPDATE #GLMAPPING
			SET LOCALAMOUNT = CASE WHEN LOCALAMOUNT < 0 THEN @nLocalAmount * -1 ELSE @nLocalAmount END,
			FOREIGNAMOUNT = CASE WHEN FOREIGNAMOUNT < 0 THEN @nForeignAmount * -1 ELSE @nForeignAmount END"

			-- __ Replace the where clause
			-- for the previous row
			-- Set sWhere = uSQLUtility.cfAppendAnd( @sWhere,  __cfGetLedgerKeyWhere() )
			-- sqa22138 add SMALLKEYFIELD1 & SMALLKEYFIELD2
			Set @sSQLString = @sSQLString + "
			WHERE LEDGER = @nPrevLedger
			AND ACCOUNTTYPE = @nPrevAccountType
			AND KEYFIELD2 = @nPrevKeyField2 
			AND KEYFIELD3 = @nPrevKeyField3 
			AND KEYFIELD4 = @nPrevKeyField4
			AND KEYFIELD5 = @nPrevKeyField5
			AND KEYFIELD6 = @nPrevKeyField6
			AND MOVEMENTCLASS = @nPrevMovementClass
			AND SMALLKEYFIELD1 = @nPrevSmallKeyField1		
			AND SMALLKEYFIELD2 = @nPrevSmallKeyField2"		
			
			
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nLocalAmount decimal(11,2),
					@nForeignAmount decimal(11,2),
					@nPrevLedger int,
					@nPrevAccountType int,
					@nPrevKeyField2 int,  
					@nPrevKeyField3 int,  
					@nPrevKeyField4 int,
					@nPrevKeyField5 int,
					@nPrevKeyField6 int,
					@nPrevMovementClass int,		
					@nPrevSmallKeyField1 int,		
					@nPrevSmallKeyField2 int',							
					@nLocalAmount = @nLocalAmount,
					@nForeignAmount = @nForeignAmount,
					@nPrevLedger = @nPrevLedger,
					@nPrevAccountType = @nPrevAccountType,
					@nPrevKeyField2 = @nPrevKeyField2,  
					@nPrevKeyField3 = @nPrevKeyField3,  
					@nPrevKeyField4 = @nPrevKeyField4,
					@nPrevKeyField5 = @nPrevKeyField5,
					@nPrevKeyField6 = @nPrevKeyField6,
					@nPrevMovementClass = @nPrevMovementClass,
					@nPrevSmallKeyField1 = @nPrevSmallKeyField1,	
					@nPrevSmallKeyField2 = @nPrevSmallKeyField2	
					

			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- If there is still a remainder from the last WIP item
				-- update the previous row with this remainder'
				print @sSQLString
				Select @nLocalAmount as LocalAmount,
					@nForeignAmount as ForeignAmount,
					@nPrevLedger as PrevLedger,
					@nPrevAccountType as PrevAccountType,
					@nPrevKeyField2 as PrevKeyField2,  
					@nPrevKeyField3 as PrevKeyField3,  
					@nPrevKeyField4 as PrevKeyField4,
					@nPrevKeyField5 as PrevKeyField5,
					@nPrevKeyField6 as PrevKeyField6,
					@nPrevMovementClass as PrevMovementClass
			End
		End
	End
End



/*************************************************************************************************
-- Step through rows for WIP and calculate the split billed WIP value
-- __cfUpdateSplitWIP
-- There are currently multiple WIP rows in the table, one for each Bill Percentage
-- However, the LocalAmount is the amount of the WIP entry and needs to be split up
-- according to the Bill Percentage
-- cfDBBrowseSplitWIP - browse for split WIP
*************************************************************************************************/
If (@nErrorCode=0) 
Begin
	-- clear account key variables
	Set @nPrevAccountType = @nCurrentAccountType
	Set @nPrevKeyField1 = @nCurrentKeyField1
	Set @nPrevKeyField2= @nCurrentKeyField2
	Set @nPrevLedger = @nCurrentLedger
	Set @nPrevSmallKeyField1 = @nCurrentSmallKeyField1
	Set @nPrevSmallKeyField2 = @nCurrentSmallKeyField2
		
	-- Ensure temporary table is empty before beginning
	TRUNCATE TABLE #SPLITWIP

	Set @sSQLString = "INSERT INTO #SPLITWIP (ACCOUNTTYPE, BILLPERCENTAGE, KEYFIELD1, KEYFIELD2, KEYFIELD3, 
	KEYFIELD4, KEYFIELD5, OPENITEMNO, KEYFIELD6, LEDGER, 
	LOCALAMOUNT, FOREIGNAMOUNT, SMALLKEYFIELD1, SMALLKEYFIELD2)
	
	SELECT DISTINCT ACCOUNTTYPE, #GLMAPPING.BILLPERCENTAGE, 
	KEYFIELD1, KEYFIELD2, KEYFIELD3,  
	KEYFIELD4,  KEYFIELD5, OI.OPENITEMNO, KEYFIELD6, 
	LEDGER, abs(LOCALAMOUNT), abs(FOREIGNAMOUNT), 
	SMALLKEYFIELD1, SMALLKEYFIELD2 
	FROM #GLMAPPING
	LEFT JOIN OPENITEM OI	ON (OI.ITEMENTITYNO = #GLMAPPING.KEYFIELD1
				AND OI.ITEMTRANSNO = #GLMAPPING.KEYFIELD2
				AND OI.ACCTDEBTORNO = #GLMAPPING.KEYFIELD6) 
	WHERE #GLMAPPING.BILLPERCENTAGE <> 100" 

	If (@bCashAccounting = 1 AND @bFIWipPaymentPref = 0)
	Begin
		Set @sSQLString = @sSQLString + "
		AND ( LEDGER = 1 OR LEDGER = 2) " 
	End
	Else
	Begin
		Set @sSQLString = @sSQLString +  "
		AND ( LEDGER = 1 )"
	End
	-- SQA7541 must sort by accounttype when the same transaction has multiple account types
	Set @sSQLString = @sSQLString + "
	ORDER BY ACCOUNTTYPE, KEYFIELD1, KEYFIELD2, SMALLKEYFIELD1, SMALLKEYFIELD2,
	KEYFIELD3, KEYFIELD4, KEYFIELD5, OI.OPENITEMNO, KEYFIELD6"

	exec @nErrorCode=sp_executesql @sSQLString  	


	If @pbDebugFlag = 1
	Begin
		Print ''
		print ' /*************************************************************************************************
	-- Step through rows for WIP and calculate the split billed WIP value
	-- __cfUpdateSplitWIP
	-- There are currently multiple WIP rows in the table, one for each Bill Percentage
	-- However, the LocalAmount is the amount of the WIP entry and needs to be split up
	-- according to the Bill Percentage
	-- cfDBBrowseSplitWIP - browse for split WIP
	*************************************************************************************************/'
		print @sSQLString
		SELECT * FROM #SPLITWIP
	End
	

	If @nErrorCode = 0
	Begin
		Set @sSQLString=" Select @nSeqNo=min(SEQNO)
		from #SPLITWIP"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nSeqNo	int		OUTPUT',
						@nSeqNo		= @nSeqNo	OUTPUT

		If @nErrorCode = 0
		Begin
			Set @sSQLString="SELECT @nCurrentAccountType=ACCOUNTTYPE, @nBillPercentage=BILLPERCENTAGE, 
			@nCurrentKeyField1=KEYFIELD1, @nCurrentKeyField2=KEYFIELD2, @nCurrentKeyField6=KEYFIELD6, @nCurrentLedger=LEDGER, 
			@nCurrentSmallKeyField1=SMALLKEYFIELD1, @nCurrentSmallKeyField2=SMALLKEYFIELD2, 
			@nLocalAmount=LOCALAMOUNT, @nForeignAmount=FOREIGNAMOUNT
			from #SPLITWIP
			WHERE SEQNO = @nSeqNo"
		
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCurrentAccountType int OUTPUT, 
					@nBillPercentage decimal(5,2) OUTPUT, 
					@nCurrentKeyField1 int OUTPUT, 
					@nCurrentKeyField2 int OUTPUT, 
					@nCurrentKeyField6 int OUTPUT,
					@nCurrentLedger int OUTPUT, 
					@nCurrentSmallKeyField1 int OUTPUT, 
					@nCurrentSmallKeyField2 int OUTPUT, 
					@nLocalAmount decimal(11,2) OUTPUT, 
					@nForeignAmount decimal(11,2) OUTPUT, 
					@nSeqNo	int',
					@nCurrentAccountType = @nCurrentAccountType OUTPUT, 
					@nBillPercentage = @nBillPercentage OUTPUT, 
					@nCurrentKeyField1 = @nCurrentKeyField1 OUTPUT, 
					@nCurrentKeyField2 = @nCurrentKeyField2 OUTPUT, 
					@nCurrentKeyField6 = @nCurrentKeyField6 OUTPUT,
					@nCurrentLedger = @nCurrentLedger OUTPUT, 
					@nCurrentSmallKeyField1 = @nCurrentSmallKeyField1 OUTPUT, 
					@nCurrentSmallKeyField2 = @nCurrentSmallKeyField2 OUTPUT, 
					@nLocalAmount = @nLocalAmount OUTPUT, 
					@nForeignAmount = @nForeignAmount OUTPUT, 
					@nSeqNo	= @nSeqNo

			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- First Row'
				print @sSQLString
				SELECT @nCurrentAccountType as CurrentAccountType, 
					@nBillPercentage as BillPercentage, 
					@nCurrentKeyField1 as CurrentKeyField1, 
					@nCurrentKeyField2 as CurrentKeyField2, 
					@nCurrentKeyField6 as CurrentKeyField6,
					@nCurrentLedger as CurrentLedger, 
					@nCurrentSmallKeyField1 as CurrentSmallKeyField1, 
					@nCurrentSmallKeyField2 as CurrentSmallKeyField2, 
					@nLocalAmount as LocalAmount, 
					@nForeignAmount as ForeignAmount, 
					@nSeqNo	as SeqNo
			End
			
			-- First row
			Set @nPercentRemainder = 100
			Set @nTotalAmount = @nLocalAmount
			Set @nTotalAmountRemainder = @nTotalAmount
			Set @nTotalForeign = @nForeignAmount
			Set @nTotalForeignRemainder = @nTotalForeign

			If @nErrorCode = 0
			Begin
				-- copy details of current row
				Set @nPrevAccountType = @nCurrentAccountType
				Set @nPrevKeyField1 = @nCurrentKeyField1
				Set @nPrevKeyField2= @nCurrentKeyField2
				Set @nPrevKeyField6 = @nCurrentKeyField6
				Set @nPrevLedger = @nCurrentLedger
				Set @nPrevSmallKeyField1 = @nCurrentSmallKeyField1
				Set @nPrevSmallKeyField2 = @nCurrentSmallKeyField2

			End
		End
	End

	While @nSeqNo is not null
	and   @nErrorCode = 0
	Begin
		-- For each row
		-- check to see if moved onto the next WIP Item
		If  ( @nCurrentKeyField1 <> @nPrevKeyField1 ) OR
			( @nCurrentKeyField2 <> @nPrevKeyField2 ) OR
			( @nCurrentSmallKeyField1 <> @nPrevSmallKeyField1 ) OR
			( @nCurrentSmallKeyField2 <> @nPrevSmallKeyField2 ) OR
			( @nCurrentLedger <> @nPrevLedger ) OR
			( @nCurrentAccountType <> @nPrevAccountType )
		Begin
			-- current row is a new WIP item. If there is still a remainder from the last WIP item
			-- update the previous row with this remainder
			If ( ( @nTotalAmountRemainder IS NOT NULL ) AND ( @nTotalAmountRemainder <> 0 ) ) OR
			( ( @nTotalForeignRemainder IS NOT NULL ) AND ( @nTotalForeignRemainder <> 0 ) )
			Begin
				Set @nLocalAmount = @nSplitLocal + @nTotalAmountRemainder
				Set @nForeignAmount = @nSplitForeign + @nTotalForeignRemainder
				-- The entries for the movement may be either positive or negative, and we want to retain the sign
				Set @sSQLString = "UPDATE #GLMAPPING
				SET LOCALAMOUNT = CASE WHEN LOCALAMOUNT < 0 THEN @nLocalAmount * -1 ELSE @nLocalAmount END,
				FOREIGNAMOUNT = CASE WHEN FOREIGNAMOUNT < 0 THEN @nForeignAmount * -1 ELSE @nForeignAmount END"

				-- __ Replace the where clause
				-- for the previous row
				-- Set sWhere = uSQLUtility.cfAppendAnd( @sWhere,  __cfGetLedgerKeyWhere() )
				Set @sSQLString = @sSQLString + "
					WHERE LEDGER = @nPrevLedger
					AND ACCOUNTTYPE = @nPrevAccountType
					AND KEYFIELD1 = @nPrevKeyField1
					AND KEYFIELD2 = @nPrevKeyField2
					AND KEYFIELD6 = @nPrevKeyField6
					AND SMALLKEYFIELD1 = @nPrevSmallKeyField1
					AND SMALLKEYFIELD2 = @nPrevSmallKeyField2"

				exec @nErrorCode=sp_executesql @sSQLString,
						N'@nLocalAmount decimal(11,2),
						@nForeignAmount decimal(11,2),
						@nPrevLedger int,
						@nPrevAccountType int,
						@nPrevKeyField1 int,  
						@nPrevKeyField2 int,
						@nPrevKeyField6 int,
						@nPrevSmallKeyField1 int,
						@nPrevSmallKeyField2 int',
						@nLocalAmount = @nLocalAmount,
						@nForeignAmount = @nForeignAmount,
						@nPrevLedger = @nPrevLedger,
						@nPrevAccountType = @nPrevAccountType,
						@nPrevKeyField1 = @nPrevKeyField1,  
						@nPrevKeyField2 = @nPrevKeyField2,
						@nPrevKeyField6 = @nPrevKeyField6,
						@nPrevSmallKeyField1 = @nPrevSmallKeyField1,
						@nPrevSmallKeyField2 = @nPrevSmallKeyField2

				If @pbDebugFlag = 1
				Begin
					Print ''
					print ' -- current row is a new WIP item. If there is still a remainder from the last WIP item
				-- update the previous row with this remainder'
					print @sSQLString
					SELECT @nLocalAmount as LocalAmount,
						@nForeignAmount as ForeignAmount,
						@nPrevLedger as PrevLedger,
						@nPrevAccountType as PrevAccountType,
						@nPrevKeyField1 as PrevKeyField1,  
						@nPrevKeyField2 as PrevKeyField2,
						@nPrevKeyField6 as PrevKeyField6,
						@nPrevSmallKeyField1 as PrevSmallKeyField1,
						@nPrevSmallKeyField2 as PrevSmallKeyField2
				End
			End

			-- change of transaction or Account Type
			Set @nPercentRemainder = 100
			Set @nTotalAmount = @nLocalAmount
			Set @nTotalAmountRemainder = @nTotalAmount
			Set @nTotalForeign = @nForeignAmount
			Set @nTotalForeignRemainder = @nTotalForeign

			Set @nPrevAccountType = @nCurrentAccountType
			Set @nPrevKeyField1 = @nCurrentKeyField1
			Set @nPrevKeyField2 = @nCurrentKeyField2
			Set @nPrevKeyField6 = @nCurrentKeyField6
			Set @nPrevLedger = @nCurrentLedger
			Set @nPrevSmallKeyField1 = @nCurrentSmallKeyField1
			Set @nPrevSmallKeyField2 = @nCurrentSmallKeyField2
		End

		Set @nSplitLocal = NULL
		Set @nSplitForeign = NULL

		-- __cfGetSplitAmounts
		If ( @nBillPercentage = @nPercentRemainder )
		Begin
			-- This is the last split - avoid rounding errors
			Set @nSplitLocal = @nTotalAmountRemainder
			Set @nTotalAmountRemainder = 0
			Set @nSplitForeign = @nTotalForeignRemainder
			Set @nTotalForeignRemainder = 0
			Set @nPercentRemainder = 0
		End
		Else
		Begin			
			Set @nPercentRemainder = @nPercentRemainder - @nBillPercentage
			-- Dual Currency performs rounding
			Set @nSplitLocal = round(( @nTotalAmount * @nBillPercentage / 100 ), 2)
			Set @nTotalAmountRemainder = @nTotalAmountRemainder - @nSplitLocal

			-- Get the rounded foreign amount too.
			If ( @nTotalForeign IS NOT NULL AND @nTotalForeign <> 0 )
			Begin
				Set @nSplitForeign = round(( @nTotalForeign * @nBillPercentage / 100 ), 2)
				Set @nTotalForeignRemainder = @nTotalForeignRemainder - @nSplitForeign
			End
		End

		-- for every WIP row found do an update with the calculated split amounts as follows
		-- The entries for the movement may be either positive or negative, and we want to retain the sign
		Set @sSQLString = "UPDATE #GLMAPPING
		SET LOCALAMOUNT = CASE WHEN LOCALAMOUNT < 0 THEN @nSplitLocal * -1 ELSE @nSplitLocal END,
		FOREIGNAMOUNT = CASE WHEN FOREIGNAMOUNT < 0 THEN @nSplitForeign * -1 ELSE @nSplitForeign END"
		-- __ Replace the where clause
		-- Current Row
		-- Set sWhere = uSQLUtility.cfAppendAnd( @sWhere,  __cfGetLedgerKeyWhere() )
		Set @sSQLString = @sSQLString + "
		WHERE LEDGER = @nCurrentLedger
		AND ACCOUNTTYPE = @nCurrentAccountType
		AND KEYFIELD1 = @nCurrentKeyField1 
		AND KEYFIELD2 = @nCurrentKeyField2
		AND KEYFIELD6 = @nCurrentKeyField6
		AND SMALLKEYFIELD1 = @nCurrentSmallKeyField1
		AND SMALLKEYFIELD2 = @nCurrentSmallKeyField2"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nSplitLocal decimal(11,2),
				@nSplitForeign decimal(11,2),
				@nCurrentLedger int,
				@nCurrentAccountType int,
				@nCurrentKeyField1 int,  
				@nCurrentKeyField2 int,
				@nCurrentKeyField6 int,
				@nCurrentSmallKeyField1 int,
				@nCurrentSmallKeyField2 int',
				@nSplitLocal = @nSplitLocal,
				@nSplitForeign = @nSplitForeign,
				@nCurrentLedger = @nCurrentLedger,
				@nCurrentAccountType = @nCurrentAccountType,
				@nCurrentKeyField1 = @nCurrentKeyField1,  
				@nCurrentKeyField2 = @nCurrentKeyField2,
				@nCurrentKeyField6 = @nCurrentKeyField6,
				@nCurrentSmallKeyField1 = @nCurrentSmallKeyField1,
				@nCurrentSmallKeyField2 = @nCurrentSmallKeyField2

		If @pbDebugFlag = 1
		Begin
			Print ''
			print ' -- for every WIP row found do an update with the calculated split amounts '
			print @sSQLString
			SELECT @nSplitLocal as SplitLocal,
				@nSplitForeign as SplitForeign,
				@nCurrentLedger as CurrentLedger,
				@nCurrentAccountType as CurrentAccountType,
				@nCurrentKeyField1 as CurrentKeyField1,  
				@nCurrentKeyField2 as CurrentKeyField2,
				@nCurrentKeyField6 as CurrentKeyField6,
				@nCurrentSmallKeyField1 as CurrentSmallKeyField1,
				@nCurrentSmallKeyField2 as CurrentSmallKeyField2
		End	

		-- Now get the next row
		If @nErrorCode = 0
		Begin
			Set @sSQLString=" Select @nSeqNoOUT = min(SEQNO)
			from #SPLITWIP
			where SEQNO > @nSeqNo"
		
			exec @nErrorCode=sp_executesql @sSQLString,
				N'@nSeqNoOUT	int	OUTPUT,
				@nSeqNo		int',
				@nSeqNoOUT	= @nSeqNo OUTPUT,
				@nSeqNo		= @nSeqNo
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString="SELECT @nCurrentAccountType=ACCOUNTTYPE, @nBillPercentage=BILLPERCENTAGE, 
			@nCurrentKeyField1=KEYFIELD1, @nCurrentKeyField2=KEYFIELD2, @nCurrentKeyField6=KEYFIELD6, @nCurrentLedger=LEDGER, 
			@nCurrentSmallKeyField1=SMALLKEYFIELD1, @nCurrentSmallKeyField2=SMALLKEYFIELD2, 
			@nLocalAmount=LOCALAMOUNT, @nForeignAmount=FOREIGNAMOUNT
			from #SPLITWIP
			WHERE SEQNO = @nSeqNo"
		
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCurrentAccountType int OUTPUT, 
					@nBillPercentage decimal(5,2) OUTPUT, 
					@nCurrentKeyField1 int OUTPUT, 
					@nCurrentKeyField2 int OUTPUT, 
					@nCurrentKeyField6 int OUTPUT,
					@nCurrentLedger int OUTPUT,
					@nCurrentSmallKeyField1 int OUTPUT, 
					@nCurrentSmallKeyField2 int OUTPUT, 
					@nLocalAmount decimal(11,2) OUTPUT, 
					@nForeignAmount decimal(11,2) OUTPUT, 
					@nSeqNo	int',
					@nCurrentAccountType = @nCurrentAccountType OUTPUT, 
					@nBillPercentage = @nBillPercentage OUTPUT, 
					@nCurrentKeyField1 = @nCurrentKeyField1 OUTPUT, 
					@nCurrentKeyField2 = @nCurrentKeyField2 OUTPUT, 
					@nCurrentKeyField6 = @nCurrentKeyField6 OUTPUT,
					@nCurrentLedger = @nCurrentLedger OUTPUT, 
					@nCurrentSmallKeyField1 = @nCurrentSmallKeyField1 OUTPUT, 
					@nCurrentSmallKeyField2 = @nCurrentSmallKeyField2 OUTPUT, 
					@nLocalAmount = @nLocalAmount OUTPUT, 
					@nForeignAmount = @nForeignAmount OUTPUT, 
					@nSeqNo	= @nSeqNo

			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- Now get the next row'
				print @sSQLString
				SELECT @nCurrentAccountType as CurrentAccountType,
					@nBillPercentage as BillPercentage,
					@nCurrentKeyField1 as CurrentKeyField1,
					@nCurrentKeyField2 as CurrentKeyField2,
					@nCurrentKeyField6 as CurrentKeyField6,
					@nCurrentLedger as CurrentLedger,
					@nCurrentSmallKeyField1 as CurrentSmallKeyField1,
					@nCurrentSmallKeyField2 as CurrentSmallKeyField2,
					@nLocalAmount as LocalAmount,
					@nForeignAmount as ForeignAmount,
					@nSeqNo	as SeqNo
			End
		End
	End
End

If @nErrorCode = 0
Begin 
	-- If there is still a remainder from the last WIP item
	-- update the previous row with this remainder
	If ( ( @nTotalAmountRemainder IS NOT NULL ) AND ( @nTotalAmountRemainder <> 0 ) ) OR
		( ( @nTotalForeignRemainder IS NOT NULL ) AND ( @nTotalForeignRemainder <> 0 ) )
	Begin
		Set @nLocalAmount = @nSplitLocal + @nTotalAmountRemainder
		Set @nForeignAmount = @nSplitForeign + @nTotalForeignRemainder
		-- The entries for the movement may be either positive or negative, and we want to retain the sign
		Set @sSQLString = "UPDATE #GLMAPPING
		SET LOCALAMOUNT = CASE WHEN LOCALAMOUNT < 0 THEN @nLocalAmount * -1 ELSE @nLocalAmount END,
		FOREIGNAMOUNT = CASE WHEN FOREIGNAMOUNT < 0 THEN @nForeignAmount * -1 ELSE @nForeignAmount END"

		-- __ Replace the where clause
		-- for the previous row
		-- Set sWhere = uSQLUtility.cfAppendAnd( @sWhere,  __cfGetLedgerKeyWhere() )
		Set @sSQLString = @sSQLString + "
			WHERE LEDGER = @nPrevLedger
			AND ACCOUNTTYPE = @nPrevAccountType
			AND KEYFIELD1 = @nPrevKeyField1
			AND KEYFIELD2 = @nPrevKeyField2
			AND KEYFIELD6 = @nPrevKeyField6
			AND SMALLKEYFIELD1 = @nPrevSmallKeyField1
			AND SMALLKEYFIELD2 = @nPrevSmallKeyField2"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nLocalAmount decimal(11,2),
				@nForeignAmount decimal(11,2),
				@nPrevLedger int,
				@nPrevAccountType int,
				@nPrevKeyField1 int,  
				@nPrevKeyField2 int,
				@nPrevKeyField6 int,
				@nPrevSmallKeyField1 int,
				@nPrevSmallKeyField2 int',
				@nLocalAmount = @nLocalAmount,
				@nForeignAmount = @nForeignAmount,
				@nPrevLedger = @nPrevLedger,
				@nPrevAccountType = @nPrevAccountType,
				@nPrevKeyField1 = @nPrevKeyField1,  
				@nPrevKeyField2 = @nPrevKeyField2,
				@nPrevKeyField6 = @nPrevKeyField6,
				@nPrevSmallKeyField1 = @nPrevSmallKeyField1,
				@nPrevSmallKeyField2 = @nPrevSmallKeyField2

		If @pbDebugFlag = 1
		Begin
			Print ''
			print ' -- If there is still a remainder from the last WIP item
		-- update the previous row with this remainder'
			print @sSQLString
			SELECT @nLocalAmount as LocalAmount,
				@nForeignAmount as ForeignAmount,
				@nPrevLedger as PrevLedger,
				@nPrevAccountType as PrevAccountType,
				@nPrevKeyField1 as PrevKeyField1,  
				@nPrevKeyField2 as PrevKeyField2,
				@nPrevKeyField6 as PrevKeyField6,
				@nPrevSmallKeyField1 as PrevSmallKeyField1,
				@nPrevSmallKeyField2 as PrevSmallKeyField2
		End
	End
End

If @pbDebugFlag = 1
Begin
	Print ''
	Print '-- Entries to be written'
	SELECT * FROM #GLMAPPING
End


-- Write Journal Data......
-- __cfWriteJournalData

/***********************************************************************************
-- Step through rows that require a Description field
***********************************************************************************/
Set @nContentId = NULL -- need to initialise it because it will never be null if previously set

If (@nErrorCode=0)
Begin
	-- Browse Description Fields required
	-- cfDBBrowseDescRulesRequired - IDC_GLCONTENTX_BDR
	Set @sSQLString="SELECT TOP 1 @nContentId=CONT.CONTENTID, 
	@nNameData=CONT.NAMEDATA 
	FROM GLFIELDRULECONTENT CONT
	join #GLMAPPING GL	ON CONT.ACCOUNTTYPE = GL.ACCOUNTTYPE
	WHERE CONT.FIELDNO = -1 
	GROUP BY CONT.CONTENTID, CONT.NAMEDATA 
	ORDER BY CONT.CONTENTID, CONT.NAMEDATA"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nContentId	int OUTPUT,
			@nNameData int OUTPUT',
			@nContentId	= @nContentId OUTPUT,
			@nNameData = @nNameData OUTPUT  

	If @pbDebugFlag = 1
	Begin
		Print ''
		print ' -- Step through rows that require a Description field'
		print @sSQLString
		SELECT @nContentId as ContentId,
			@nNameData as NameData
	End	

	While @nContentId IS NOT NULL AND @nErrorCode = 0
	Begin
		-- for each row		
		Set @sSQLString = NULL
		Set @sSelect = NULL
		Set @sFrom = NULL
		Set @sJoin = NULL
		Set @sWhere = NULL

		-- Create Insert SQL
		-- contentid value as returned from previous browse
		-- namedata value as returned from previous browse only include if namedata is not null
		Set @sSQLString=" INSERT INTO #GLDESCRIPTION
		(ENTITYNO, TRANSNO, DESIGNATION, SEQNO, SEGMENTNO, SEPARATOR, DESCRIPTION )"


		Set @sSelect = "SELECT GL.ENTITY, GL.TRANSNO, GL.DESIGNATION, GL.SEQNO,
			CONT.SEGMENTNO, FR.SEPARATOR"
		Set @sFrom = "FROM #GLMAPPING GL
			JOIN GLFIELDRULECONTENT CONT ON (CONT.ACCOUNTTYPE = GL.ACCOUNTTYPE)
			JOIN GLFIELDRULE FR ON (FR.FIELDNO = CONT.FIELDNO AND FR.ACCOUNTTYPE = CONT.ACCOUNTTYPE)"

		Set @sWhere = "WHERE CONT.FIELDNO = -1
				AND	CONT.CONTENTID = " + CAST(@nContentId as nvarchar(10))

		If ( @nNameData IS NOT NULL )
			Set @sWhere = @sWhere +  "
			AND CONT.NAMEDATA = " + CAST(@nNameData as nvarchar(10)) 

		If @pbDebugFlag = 1
		Begin
			SELECT @sSelect AS SELECTSTMT
			,@sFrom AS FROMSTMT
			,@sWhere AS WHERESTMT
			,@sJoin AS JOINSTMT
		End
		-- refer user fields __cfAppendContent logic below
		exec @nErrorCode = fi_AppendUserFieldContent
				   @sSelect OUTPUT
				  ,@sFrom OUTPUT
				  ,@sWhere OUTPUT
				  ,@sJoin OUTPUT
				  ,@pnUserIdentityId
				  ,@nContentId
				  ,@nNameData
				  ,@psCulture
				  ,0
				  ,@pbDebugFlag


		If @nErrorCode = 0
		Begin
			--Set @sSqlString = @sSqlString +char(10)+ 
			--		@sSelect +char(10)+ 
			--		@sFrom +char(10)+ 
			--		"WHERE " + @sJoin
			Set @sSQLString = @sSQLString +char(10)+ 
					@sSelect +char(10)+ 
			@sFrom +char(10)

			If @sWhere is NOT NULL
				Set @sSQLString = @sSQLString + +char(10)+ @sWhere

			exec @nErrorCode=sp_executesql @sSQLString


			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- Insert Description in Temporary Table'
				SELECT @sSelect AS SELECTSTMT
				  ,@sFrom AS FROMSTMT
				  ,@sWhere AS WHERESTMT
				  ,@sJoin AS JOINSTMT
				print @sSQLString
			End  
		End

		If @nErrorCode = 0
		begin
			set @nTempContentId = @nContentId
			set @nContentId = null  -- need to initialise it because it will never be null if previously set
			set @nNameData = null

			-- Get Next Row
			Set @sSQLString="SELECT TOP 1 @nContentId=CONT.CONTENTID, 
			@nNameData=CONT.NAMEDATA 
			FROM GLFIELDRULECONTENT CONT
			join #GLMAPPING GL	ON CONT.ACCOUNTTYPE = GL.ACCOUNTTYPE
			WHERE CONT.FIELDNO = -1 
			AND CONT.CONTENTID > @nTempContentId
			GROUP BY CONT.CONTENTID, CONT.NAMEDATA 
			ORDER BY CONT.CONTENTID, CONT.NAMEDATA"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nContentId	int OUTPUT,
					@nNameData	int OUTPUT,
					@nTempContentId int',
					@nContentId	= @nContentId OUTPUT,
					@nNameData	= @nNameData OUTPUT ,
					@nTempContentId	= @nTempContentId 

			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- Get Next Row'
				print @sSQLString
				SELECT @nContentId as ContentId,
					@nNameData as NameData,
					@nTempContentId	as TempContentId 
			End	
		End
	End
End



If @nErrorCode = 0
Begin
	Set @sSQLString=" INSERT INTO #GLMOVEMENTNO
	( KEYFIELD1, KEYFIELD2, KEYFIELD3, KEYFIELD4, KEYFIELD5, KEYFIELD6, 
	SMALLKEYFIELD1, SMALLKEYFIELD2, LEDGER)
	SELECT DISTINCT KEYFIELD1, KEYFIELD2, 
	CASE WHEN LEDGER = 1 THEN 0 ELSE KEYFIELD3 END, 
	CASE WHEN LEDGER = 1 THEN 0 ELSE KEYFIELD4 END,
	CASE WHEN LEDGER = 1 THEN 0 ELSE KEYFIELD5 END,
	CASE WHEN LEDGER = 1 THEN 0 ELSE KEYFIELD6 END,
	SMALLKEYFIELD1, SMALLKEYFIELD2,
	CASE WHEN LEDGER = 3 THEN 2 ELSE LEDGER END
	FROM #GLMAPPING"
		
	exec @nErrorCode=sp_executesql @sSQLString  

	If @pbDebugFlag = 1
	Begin
		Print ''
		print ' -- Insert Movement Nos in Temporary Table'
		print @sSQLString
	End 
End


-- SQA17799 
-- Return the derived GL ledger details without saving to database
If ( (@nErrorCode=0) and (@pbCalculateJournalOnly = 1) and (@pbCashAcctAR = 1) )
Begin
	If exists( SELECT * FROM #GLDESCRIPTION )
	Begin
		SELECT GL.MOVEMENTCLASS, GL.LEDGERACCOUNTID, GL.ACCTPROFITCENTRE, GL.LOCALAMOUNT, 
		GL.FOREIGNAMOUNT, GL.CURRENCY, 
		case when	(CURRENCY IS NOT NULL and 
					isnull(FOREIGNAMOUNT, 0) <> 0 and
					isnull(LOCALAMOUNT, 0) <> 0 ) 
			then	FOREIGNAMOUNT/LOCALAMOUNT
			else	null end as EXCHRATE,
		convert( nvarchar(254),
		DESC1.DESCRIPTION +
		CASE 	WHEN 	DESC1.DESCRIPTION IS NOT NULL AND
     				DESC2.DESCRIPTION IS NOT NULL
			THEN 	STUFF( DESC1.SEPARATOR, PATINDEX( '%^', DESC1.SEPARATOR),1, NULL) +
				DESC2.DESCRIPTION
			ELSE DESC2.DESCRIPTION
			END) as NOTE
		FROM #GLMAPPING GL
		JOIN #GLMOVEMENTNO GLM		ON (GLM.KEYFIELD1 = GL.KEYFIELD1
						AND GLM.KEYFIELD2 = GL.KEYFIELD2
						AND GLM.SMALLKEYFIELD1 = GL.SMALLKEYFIELD1
						AND GLM.SMALLKEYFIELD2 = GL.SMALLKEYFIELD2)
		LEFT JOIN #GLDESCRIPTION DESC1	ON (DESC1.SEQNO = GL.SEQNO 
						AND DESC1.SEGMENTNO = 1)
		LEFT JOIN #GLDESCRIPTION DESC2	ON (DESC2.SEQNO = GL.SEQNO 
						AND DESC2.SEGMENTNO = 2)
		WHERE GL.LEDGER IN (2, 3)  -- Debtor and Tax ledger only
		AND GLM.LEDGER = CASE WHEN GL.LEDGER = 3 THEN 2 ELSE GL.LEDGER END
		AND GLM.KEYFIELD3 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD3 END
		AND GLM.KEYFIELD4 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD4 END
		AND GLM.KEYFIELD5 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD5 END
		AND GLM.KEYFIELD6 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD6 END

	End
	Else
	Begin
		SELECT GL.MOVEMENTCLASS, GL.LEDGERACCOUNTID, GL.ACCTPROFITCENTRE, GL.LOCALAMOUNT, 
		GL.FOREIGNAMOUNT, GL.CURRENCY, 
		case when	(CURRENCY IS NOT NULL and 
					isnull(FOREIGNAMOUNT, 0) <> 0 and
					isnull(LOCALAMOUNT, 0) <> 0 ) 
			then	FOREIGNAMOUNT/LOCALAMOUNT
			else	null end as EXCHRATE,
		NULL as NOTE		
		FROM #GLMAPPING GL
		JOIN #GLMOVEMENTNO GLM	ON (GLM.KEYFIELD1 = GL.KEYFIELD1
					AND GLM.KEYFIELD2 = GL.KEYFIELD2
					AND GLM.SMALLKEYFIELD1 = GL.SMALLKEYFIELD1
					AND GLM.SMALLKEYFIELD2 = GL.SMALLKEYFIELD2)	
		WHERE GL.LEDGER IN (2, 3)  -- Debtor and Tax ledger only
		AND GLM.LEDGER = CASE WHEN GL.LEDGER = 3 THEN 2 ELSE GL.LEDGER END
		AND GLM.KEYFIELD3 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD3 END
		AND	GLM.KEYFIELD4 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD4 END
		AND	GLM.KEYFIELD5 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD5 END
		AND	GLM.KEYFIELD6 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD6 END
	End

	Set @nErrorCode = @@ERROR 
	Return @nErrorCode
End






If @nErrorCode = 0
Begin
	begin transaction
	set nocount on
		
	If @nErrorCode=0
	Begin
		-- write journal as valid - from temp to real table
		Set @sSQLString=" INSERT INTO GLJOURNAL
		(TRANSNO, ENTITYNO, DESIGNATION,
		CREATIONDATE, DATELASTUPDATED, EXPORTDATE,
		JOURNALDATE, JOURNALPERIOD, LABELID,
		POSTPERIOD, REJECTREASON, STATUS,
		USERID)
		SELECT TH.TRANSNO, TH.ENTITYNO, GL.DESIGNATION,
		GETDATE(), NULL, NULL, 
		TH.TRANSDATE, TH.TRANPOSTPERIOD, 84,
		TH.TRANPOSTPERIOD, NULL,6711,
		SYSTEM_USER
		FROM TRANSACTIONHEADER TH
		JOIN #GLMAPPING GL	ON GL.ENTITY = TH.ENTITYNO
					AND GL.TRANSNO = TH.TRANSNO
		GROUP BY TH.TRANSNO, TH.ENTITYNO, TH.TRANSDATE, TH.TRANPOSTPERIOD, GL.DESIGNATION"
			
		exec @nErrorCode=sp_executesql @sSQLString  

		If @pbDebugFlag = 1
		Begin
			Print ''
			Print 'begin transaction
			set nocount on'
			Print ''
			print ' -- Insert GLJOURNAL rows for Journals to be created'
			print @sSQLString
		End 
	End

	If (@nErrorCode=0)
	Begin
		-- write journal lines
		-- #GLMOVEMENTNO contains a unique movement no for each ledger movement
		-- -- Note: the WIP Ledger entries contain a combination of WH Key and OI Key
		-- -- Make sure we only select the WH key
		-- -- Tax (Ledger 3) records come from Debtor History (Ledger 2)
		Set @sSQLString=" INSERT INTO GLJOURNALLINE
		(TRANSNO, SEQNO, ENTITYNO,
		DESIGNATION, ACCOUNTTYPE, DESCRIPTION,
		GLACCOUNTCODE, LOCALAMOUNT, MOVEMENTCLASS,
		MOVEMENTNO, ACCTENTITYNO, ACCTPROFITCENTRE, LEDGERACCOUNTID)"

		If exists( SELECT * FROM #GLDESCRIPTION )
        	Begin
			Set @sSQLString = @sSQLString+"
			SELECT GL.TRANSNO, GL.SEQNO, GL.ENTITY,
			GL.DESIGNATION, GL.ACCOUNTTYPE, convert( nvarchar(254),
			DESC1.DESCRIPTION +
			CASE 	WHEN 	DESC1.DESCRIPTION IS NOT NULL AND
	     				DESC2.DESCRIPTION IS NOT NULL
				THEN 	STUFF( DESC1.SEPARATOR, PATINDEX( '%^', DESC1.SEPARATOR),1, NULL) +
					DESC2.DESCRIPTION
				ELSE DESC2.DESCRIPTION
				END),
			GL.GLACCOUNTCODE, GL.LOCALAMOUNT, GL.MOVEMENTCLASS,
			GLM.MOVEMENTNO, GL.ACCTENTITYNO, GL.ACCTPROFITCENTRE, GL.LEDGERACCOUNTID
			FROM #GLMAPPING GL
			JOIN #GLMOVEMENTNO GLM		ON (GLM.KEYFIELD1 = GL.KEYFIELD1
							AND GLM.KEYFIELD2 = GL.KEYFIELD2
							AND GLM.SMALLKEYFIELD1 = GL.SMALLKEYFIELD1
							AND GLM.SMALLKEYFIELD2 = GL.SMALLKEYFIELD2)
			LEFT JOIN #GLDESCRIPTION DESC1	ON (DESC1.SEQNO = GL.SEQNO 
							AND DESC1.SEGMENTNO = 1)
			LEFT JOIN #GLDESCRIPTION DESC2	ON (DESC2.SEQNO = GL.SEQNO 
							AND DESC2.SEGMENTNO = 2)
			WHERE GLM.LEDGER = CASE WHEN GL.LEDGER = 3 THEN 2 ELSE GL.LEDGER END
			AND GLM.KEYFIELD3 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD3 END
			AND GLM.KEYFIELD4 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD4 END
			AND GLM.KEYFIELD5 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD5 END
			AND GLM.KEYFIELD6 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD6 END"
		End
		Else
		Begin
			Set @sSQLString = @sSQLString+"
			SELECT GL.TRANSNO, GL.SEQNO, GL.ENTITY, 
			GL.DESIGNATION, GL.ACCOUNTTYPE, NULL,
			GL.GLACCOUNTCODE, GL.LOCALAMOUNT, GL.MOVEMENTCLASS, 
			GLM.MOVEMENTNO, GL.ACCTENTITYNO, GL.ACCTPROFITCENTRE, GL.LEDGERACCOUNTID
			FROM #GLMAPPING GL
			JOIN #GLMOVEMENTNO GLM	ON (GLM.KEYFIELD1 = GL.KEYFIELD1
						AND GLM.KEYFIELD2 = GL.KEYFIELD2
						AND GLM.SMALLKEYFIELD1 = GL.SMALLKEYFIELD1
						AND GLM.SMALLKEYFIELD2 = GL.SMALLKEYFIELD2)	
			WHERE 	GLM.LEDGER = CASE WHEN GL.LEDGER = 3 THEN 2 ELSE GL.LEDGER END
			AND 	GLM.KEYFIELD3 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD3 END
			AND	GLM.KEYFIELD4 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD4 END
			AND	GLM.KEYFIELD5 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD5 END
			AND	GLM.KEYFIELD6 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD6 END"

			/*
			SELECT GL.TRANSNO, GL.SEQNO, GL.ENTITY, 
			GL.DESIGNATION, GL.ACCOUNTTYPE, NULL,
			GL.GLACCOUNTCODE, GL.LOCALAMOUNT, GL.MOVEMENTCLASS, 
			GLM.MOVEMENTNO, GL.ACCTENTITYNO, GL.ACCTPROFITCENTRE, GL.LEDGERACCOUNTID
			FROM #GLMAPPING GL,  #GLMOVEMENTNO GLM
			WHERE 	GLM.LEDGER = CASE WHEN GL.LEDGER = 3 THEN 2 ELSE GL.LEDGER END
			AND	GLM.KEYFIELD1 = GL.KEYFIELD1
			AND	GLM.KEYFIELD2 = GL.KEYFIELD2
			AND 	GLM.KEYFIELD3 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD3 END
			AND	GLM.KEYFIELD4 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD4 END
			AND	GLM.KEYFIELD5 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD5 END
			AND	GLM.KEYFIELD6 = CASE WHEN GL.LEDGER = 1 THEN 0 ELSE GL.KEYFIELD6 END
			AND	GLM.SMALLKEYFIELD1 = GL.SMALLKEYFIELD1
			AND	GLM.SMALLKEYFIELD2 = GL.SMALLKEYFIELD2
			*/
		End
			
		exec @nErrorCode=sp_executesql @sSQLString  

		If @pbDebugFlag = 1
		Begin
			Print ''
			print ' -- Insert GLJOURNALLINE rows for Journal Liness to be created'
			print @sSQLString
		End
	End

	If (@nErrorCode=0)
	Begin
		-- update invalid journals 
		-- for every row found.....
		-- register user error - Call guAlert.cfRegister( MODULE_GLINTERFACE, 14, SEVERITY_USER_ERROR, csClassContext, sFunctionContext)
		Set @sSQLString=" UPDATE GLJOURNAL SET REJECTREASON = 
		'Journal debit value '+ CAST(TOTALS.TOTALDEBIT as NVARCHAR(30)) + 
		' differs from credit value ' + CAST( TOTALS.TOTALCREDIT as NVARCHAR(30)) + 
		' by ' + CAST((TOTALS.TOTALDEBIT - TOTALS.TOTALCREDIT) as NVARCHAR(30)) + '.',
		STATUS = 6701 
		FROM GLJOURNAL GL
		JOIN 	(
			SELECT ENTITY, TRANSNO, DESIGNATION, SUM(CASE WHEN LOCALAMOUNT < 0 THEN 0 ELSE LOCALAMOUNT END) AS TOTALDEBIT, 
			SUM(CASE WHEN LOCALAMOUNT < 0 THEN LOCALAMOUNT * -1 ELSE 0 END) AS TOTALCREDIT
			FROM #GLMAPPING  
			GROUP BY ENTITY, TRANSNO, DESIGNATION 
			HAVING SUM(LOCALAMOUNT) <> 0
			) AS TOTALS	ON (GL.ENTITYNO = TOTALS.ENTITY
					AND GL.TRANSNO = TOTALS.TRANSNO
					AND GL.DESIGNATION = TOTALS.DESIGNATION)"
		
		exec @nErrorCode=sp_executesql @sSQLString  

		If @pbDebugFlag = 1
		Begin
			Print ''
			print ' -- update invalid journals that do not balance'
			print @sSQLString
		End
	End

	If (@nErrorCode=0)
	Begin
		-- Validate GL Account
		-- if the account code is null record an error message - Call guAlert.cfRegister( MODULE_GLINTERFACE, 1, SEVERITY_USER_ERROR, csClassContext, sFunctionContext)
		Set @sSQLString=" UPDATE GLJOURNAL SET REJECTREASON = 'No Account Code was specified.', STATUS = 6701  
		FROM GLJOURNAL GL
		JOIN #GLMAPPING GLM	ON (GLM.ENTITY = GL.ENTITYNO
					AND GLM.TRANSNO = GL.TRANSNO
					AND GLM.DESIGNATION = GL.DESIGNATION)
		WHERE GLM.GLACCOUNTCODE IS NULL"
			
		exec @nErrorCode=sp_executesql @sSQLString  

		If @pbDebugFlag = 1
		Begin
			Print ''
			print ' -- update invalid journals where account code is null'
			print @sSQLString
		End
	End
	If (@nErrorCode=0)
	Begin
		If (@bFIwithGL = 1 )
		Begin
			-- else if @bFIwithGL = 1 and ledger id or account, entity or profile centre is null record an alert error message 
			-- guAlert.cfRegister( MODULE_GLINTERFACE, 107, SEVERITY_USER_ERROR, csClassContext, sFunctionContext)
			/* e.g. of raise error syntax
			Set @sAlertXML = dbo.fn_GetAlertXML('AC18', 'The Bank Amounts of the Cash Items added do not reconcile to the Bank History row/s added.',
			null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @nErrorCode = @@ERROR
			*/

			Set @sSQLString=" UPDATE GLJOURNAL SET REJECTREASON = 'There are no General Ledger account details specified.', STATUS = 6701  
			FROM GLJOURNAL GL
			JOIN #GLMAPPING GLM	ON (GLM.ENTITY = GL.ENTITYNO
						AND GLM.TRANSNO = GL.TRANSNO
						AND GLM.DESIGNATION = GL.DESIGNATION)
			WHERE GLM.ACCTENTITYNO IS NULL
			OR GLM.ACCTPROFITCENTRE IS NULL
			OR GLM.LEDGERACCOUNTID IS NULL"
			
			exec @nErrorCode=sp_executesql @sSQLString  
			
			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- update invalid journals where account, entity or profile centre is null'
				print @sSQLString
			End
		End
		Else
		Begin
			-- Call guAlert.cfRegister( MODULE_GLINTERFACE, 2, SEVERITY_USER_ERROR, csClassContext, sFunctionContext)
			Set @sSQLString=" UPDATE GLJOURNAL SET REJECTREASON = 'Account Code ' + GLM.GLACCOUNTCODE + ' is not defined as a valid code', STATUS = 6701 
			FROM GLJOURNAL GL
			JOIN #GLMAPPING GLM	ON (GLM.ENTITY = GL.ENTITYNO
						AND GLM.TRANSNO = GL.TRANSNO
						AND GLM.DESIGNATION = GL.DESIGNATION) 
			WHERE NOT EXISTS
				( SELECT *
				  FROM GENERALLEDGERACCTS GLA
				  WHERE GLM.GLACCOUNTCODE = GLA.GLACCOUNTCODE )"
			
			exec @nErrorCode=sp_executesql @sSQLString  

			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- update invalid journals where glaccount does not exist in GENERALLEDGERACCTS'
				print @sSQLString
			End
		End
	End

/*************************************************************************************************
/** User defined fields **/
-- Step through rows that require a user fields defined
-- Populate user defined fields according to rules defined, for all rows in the Temp GL Mapping table
-- Browse field rules required
*************************************************************************************************/

	Set @nContentId = NULL -- need to initialise it because it will never be null if previously set

	If (@nErrorCode=0)
	Begin
		Set @sSQLString="SELECT TOP 1 @nContentId=CONT.CONTENTID, 
		@nSegNo=CONT.SEGMENTNO, 
		@nNameData=CONT.NAMEDATA 
		FROM GLFIELDRULECONTENT CONT, #GLMAPPING GL 
		WHERE CONT.ACCOUNTTYPE = GL.ACCOUNTTYPE
		AND CONT.FIELDNO <> -1 
		GROUP BY CONT.SEGMENTNO, CONT.CONTENTID, CONT.NAMEDATA 
		ORDER BY CONT.SEGMENTNO, CONT.CONTENTID, CONT.NAMEDATA"
			
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nContentId	int OUTPUT,
				@nSegNo		int OUTPUT,
				@nNameData	int OUTPUT',
				@nContentId	= @nContentId OUTPUT,
				@nSegNo		= @nSegNo OUTPUT,
				@nNameData	= @nNameData OUTPUT  

		If @pbDebugFlag = 1
		Begin
			Print ''
			print ' /*************************************************************************************************
		/** User defined fields **/
		-- Step through rows that require a user fields defined
		-- Populate user defined fields according to rules defined, for all rows in the Temp GL Mapping table
		-- Browse field rules required
		*************************************************************************************************/'
			print @sSQLString
			Select @nContentId as ContentId,
				@nSegNo	as SegNo,
				@nNameData as NameData
		End
	End

	While @nContentId is not null AND
	@nErrorCode = 0
	Begin
	

		-- for each row
		Set @sSQLString = NULL
		Set @sSelect = NULL
		Set @sFrom = NULL
		Set @sJoin = NULL
		Set @sWhere = NULL

		Set @sSQLString = "INSERT INTO GLJOURNALLINEEXT
			(ENTITYNO, TRANSNO, DESIGNATION, SEQNO, FIELDNO, CONTENTS )"


		Set @sSelect = "SELECT GL.ENTITY, GL.TRANSNO, GL.DESIGNATION, GL.SEQNO,
			CONT.FIELDNO"

		Set @sFrom = "FROM #GLMAPPING GL
		JOIN GLFIELDRULECONTENT CONT ON (CONT.ACCOUNTTYPE = GL.ACCOUNTTYPE)"

		Set @sJoin = "CONT.FIELDNO <> -1
				AND	CONT.CONTENTID = " + CAST(@nContentId as NVARCHAR(10)) + "
				AND	CONT.SEGMENTNO = " + CAST(@nSegNo as NVARCHAR(10))

		If ( @nNameData IS NOT NULL )
			Set @sJoin = @sJoin + "
			AND CONT.NAMEDATA = " + CAST(@nNameData as NVARCHAR(10)) 

		Set @sWhere = "NOT EXISTS
					( SELECT * FROM GLJOURNALLINEEXT EXT
					  WHERE EXT.ENTITYNO = GL.ENTITY
					  AND   EXT.TRANSNO = GL.TRANSNO
					  AND   EXT.DESIGNATION = GL.DESIGNATION
					  AND   EXT.SEQNO = GL.SEQNO
					  AND   EXT.FIELDNO = CONT.FIELDNO )"

		If @pbDebugFlag = 1
		Begin
			SELECT @sSelect AS SELECTSTMT
				  ,@sFrom AS FROMSTMT
				  ,@sWhere AS WHERESTMT
				  ,@sJoin AS JOINSTMT
		End

		exec @nErrorCode = fi_AppendUserFieldContent
				   @sSelect OUTPUT
				  ,@sFrom OUTPUT
				  ,@sWhere OUTPUT
				  ,@sJoin OUTPUT
				  ,@pnUserIdentityId
				  ,@nContentId
				  ,@nNameData
				  ,@psCulture
				  ,0
				  ,@pbDebugFlag

		Set @sSQLString = @sSQLString +char(10)+ @sSelect +char(10)+ @sFrom +char(10)+ "WHERE " + @sJoin 

		If @sWhere is NOT NULL
			Set @sSQLString = @sSQLString + " AND " +char(10)+ @sWhere

		exec @nErrorCode=sp_executesql @sSQLString  
		


		If @pbDebugFlag = 1
		Begin
			Print ''
			print ' -- for each row Insert User defined fields into GLJOURNALLINEEXT'
			SELECT @sSelect AS SELECTSTMT
				  ,@sFrom AS FROMSTMT
				  ,@sWhere AS WHERESTMT
				  ,@sJoin AS JOINSTMT
			print @sSQLString
			
		End
		
		Set @nTempContentId = @nContentId
		Set @nContentId = NULL -- need to initialise it because it will never be null if previously set

		-- Get Next Row
		Set @sSQLString="SELECT TOP 1 @nContentId=CONT.CONTENTID, 
		@nSegNo=CONT.SEGMENTNO, 
		@nNameData=CONT.NAMEDATA 
		FROM GLFIELDRULECONTENT CONT, #GLMAPPING GL 
		WHERE CONT.ACCOUNTTYPE = GL.ACCOUNTTYPE
		AND CONT.FIELDNO <> -1 
		AND CONT.CONTENTID > @nTempContentId
		GROUP BY CONT.SEGMENTNO, CONT.CONTENTID, CONT.NAMEDATA 
		ORDER BY CONT.SEGMENTNO, CONT.CONTENTID, CONT.NAMEDATA"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nContentId	int OUTPUT,
				@nSegNo		int OUTPUT,
				@nNameData	int OUTPUT,
				@nTempContentId	int',
				@nContentId	= @nContentId OUTPUT,
				@nSegNo		= @nSegNo OUTPUT,
				@nNameData	= @nNameData OUTPUT,
				@nTempContentId	= @nTempContentId  

		If @pbDebugFlag = 1
		Begin
			Print ''
			print ' -- Get Next Row'
			print @sSQLString
			SELECT @nContentId as ContentId,
				@nSegNo	as SegNo,
				@nNameData as NameData,
				@nTempContentId	as TempContentId  
		End
	End
/*************************************************************************************************/

	-- write audit trail
	If ( @nErrorCode=0 ) AND ( @pnDesignation = 1 )
	Begin
		Set @sSQLString=" UPDATE TRANSACTIONHEADER
		SET GLSTATUS = 1
		FROM #TRANSACTIONID
		WHERE #TRANSACTIONID.ENTITYNO = TRANSACTIONHEADER.ENTITYNO
		AND #TRANSACTIONID.TRANSNO = TRANSACTIONHEADER.TRANSNO"
		
		exec @nErrorCode=sp_executesql @sSQLString
		
		If @pbDebugFlag = 1
		Begin
			Print ''
			print ' -- write audit trail
				-- Update TRANSACTIONHEADER'
			print @sSQLString
		End

		If ( @nErrorCode=0 ) AND
		( ( @nTransUsedBy = NULL ) OR 
		( @nTransUsedBy & @nTransUsedByBilling != 0 ) )
		Begin
			Set @sSQLString=" UPDATE WORKHISTORY
			SET GLMOVEMENTNO = #GLMOVEMENTNO.MOVEMENTNO
			FROM #GLMOVEMENTNO
			WHERE #GLMOVEMENTNO.KEYFIELD1 = WORKHISTORY.ENTITYNO
			AND #GLMOVEMENTNO.KEYFIELD2 = WORKHISTORY.TRANSNO
			AND #GLMOVEMENTNO.SMALLKEYFIELD1 = WORKHISTORY.WIPSEQNO
			AND #GLMOVEMENTNO.SMALLKEYFIELD2 = WORKHISTORY.HISTORYLINENO
			AND #GLMOVEMENTNO.LEDGER = 1"
		
			exec @nErrorCode=sp_executesql @sSQLString

			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- Update WORKHISTORY'
				print @sSQLString
			End
		End
		
		If ( @nErrorCode=0 ) AND
		( ( @nTransUsedBy = NULL ) OR 
		( @nTransUsedBy & @nTransUsedByAR != 0 ) )
		Begin
			Set @sSQLString=" UPDATE DEBTORHISTORY
			SET GLMOVEMENTNO = #GLMOVEMENTNO.MOVEMENTNO
			FROM #GLMOVEMENTNO
			WHERE #GLMOVEMENTNO.KEYFIELD3 = DEBTORHISTORY.ITEMENTITYNO
			AND #GLMOVEMENTNO.KEYFIELD4 = DEBTORHISTORY.ITEMTRANSNO
			AND #GLMOVEMENTNO.KEYFIELD5 = DEBTORHISTORY.ACCTENTITYNO
			AND #GLMOVEMENTNO.KEYFIELD6 = DEBTORHISTORY.ACCTDEBTORNO
			AND #GLMOVEMENTNO.SMALLKEYFIELD1 = DEBTORHISTORY.HISTORYLINENO
			AND #GLMOVEMENTNO.LEDGER = 2"
		
			exec @nErrorCode=sp_executesql @sSQLString

			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- Update DEBTORHISTORY'
				print @sSQLString
			End
		End

		If ( @nErrorCode=0 ) AND
		( ( @nTransUsedBy = NULL ) OR 
		( @nTransUsedBy & @nTransUsedByCB != 0 ) )
		Begin
			Set @sSQLString=" UPDATE CASHHISTORY
			SET GLMOVEMENTNO = #GLMOVEMENTNO.MOVEMENTNO
			FROM #GLMOVEMENTNO
			WHERE #GLMOVEMENTNO.KEYFIELD1 = CASHHISTORY.ENTITYNO
			AND #GLMOVEMENTNO.KEYFIELD2 = CASHHISTORY.BANKNAMENO
			AND #GLMOVEMENTNO.KEYFIELD3 = CASHHISTORY.SEQUENCENO
			AND #GLMOVEMENTNO.KEYFIELD4 = CASHHISTORY.TRANSENTITYNO
			AND #GLMOVEMENTNO.KEYFIELD5 = CASHHISTORY.TRANSNO
			AND #GLMOVEMENTNO.SMALLKEYFIELD1 = CASHHISTORY.HISTORYLINENO
			AND #GLMOVEMENTNO.LEDGER = 4"
		
			exec @nErrorCode=sp_executesql @sSQLString

			If @pbDebugFlag = 1
			Begin
				Print ''
				print ' -- Update CASHHISTORY'
				print @sSQLString
			End

			If ( @nErrorCode=0 )
			Begin
				Set @sSQLString=" UPDATE BANKHISTORY
				SET GLMOVEMENTNO = #GLMOVEMENTNO.MOVEMENTNO
				FROM #GLMOVEMENTNO
				WHERE #GLMOVEMENTNO.KEYFIELD1 = BANKHISTORY.ENTITYNO
				AND #GLMOVEMENTNO.KEYFIELD2 = BANKHISTORY.BANKNAMENO
				AND #GLMOVEMENTNO.KEYFIELD3 = BANKHISTORY.SEQUENCENO
				AND #GLMOVEMENTNO.KEYFIELD4 = BANKHISTORY.HISTORYLINENO
				AND #GLMOVEMENTNO.LEDGER = 5"
		
				exec @nErrorCode=sp_executesql @sSQLString

				If @pbDebugFlag = 1
				Begin
					Print ''
					print ' -- Update BANKHISTORY'
					print @sSQLString
				End
			End
		End
	End

	If (@nErrorCode = 0)
	Begin
		commit transaction
		If @pbDebugFlag = 1
			print 'commit transaction'
	End
	else
	Begin
		rollback transaction
		If @pbDebugFlag = 1
			print 'rollback transaction'
	End
End
-- end begin If @nErrorCode=0 block	

If ( @nErrorCode=0 ) AND ( @bFIwithGL = 1 ) AND ( @pnDesignation = 1 )
Begin
	EXECUTE @nErrorCode = [dbo].[fi_PostToGL] 
		   @nRowCount OUTPUT
		  ,@pbDebugFlag
		  ,@pnUserIdentityId
		  ,@psCulture
		  ,@pnEntityNo
		  ,@pnTransNo
		  ,@pnDesignation
End


If @nErrorCode = -1
Begin
	-- No processing required
	Set @nErrorCode = 0
End

Return @nErrorCode
GO

Grant execute on dbo.fi_CreateAndPostJournals to public
GO
