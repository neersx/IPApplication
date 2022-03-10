-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_PostDebtorHistory									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_PostDebtorHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_PostDebtorHistory.'
	Drop procedure [dbo].[acw_PostDebtorHistory]
End
Print '**** Creating Stored Procedure dbo.acw_PostDebtorHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_PostDebtorHistory
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo	int,
	@pnItemTransNo	int,
	@pnMovementType	int,
	@pdtPostDate	datetime,
	@pnPostPeriod	int,
	@pbPostCredits	bit,
	@psReasonCode	nvarchar(2) = null
)
as
-- PROCEDURE:	acw_PostDebtorHistory
-- VERSION:	11
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Post Debtor Hisotry records when finalising open items

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	-----------------------------------------------
-- 05 Feb 2010	AT	RFC3605		1	Procedure created.
-- 23 Jun 2010	AT	RFC8291		2	Updated for Credit Notes.
-- 15 Jul 2011	DL	SQA19791	3	Extend variable referencing CONTROLTOTAL.TOTAL to dec(13,2) instead of dec(11,2)
-- 20 Jan 2012	AT	RFC11812	4	Apply credits in Debtor History using current open item details.
-- 06 Feb 2012	AT	RFC11865	5	Fixed tax allocation for prepayments in Debtor History.
-- 16 Feb 2012	AT	RFC11865	6	Fixed allocation of prepayments when credit represents full bill.
-- 30 Apr 2012	AT	RFC12226	7	Sync Credit Item's DEBTORHISTORY.HISTORYLINENO with DEBTORHISTORYCASE.
-- 25 May 2012	AT	RFC12269	8	Fixed setting of status on Debtor History for credit notes.
-- 18 Jun 2012	AT	RFC12386	9	Fixed tax allocation for prepayments in Debtor History when multiple tax rates applicable.
-- 05 Nov 2014	AT	RFC41291	10	Cater for multi-case prepayments.
--						Reverse sign for prepayment Tax History.
-- 20 Oct 2015  MS      R53933          11      Changed size from decimal(8,4) to decimal(11,4) for TaxRate cols

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int

Declare @sSQLString nvarchar(MAX)
Declare @sInsert nvarchar(1000)
Declare @sColumnsSelect nvarchar(2000)
Declare @sFrom nvarchar(2000)
Declare @sWhere nvarchar(1000)
Declare @sAlertXML nvarchar(1000)
Declare @nControlTotal decimal(13,2)
Declare @nStatus smallint
Declare @nHistoryLineNo int -- the history line no of this history entry

Set @nErrorCode = 0

-- Preconditions
If @pnMovementType not in (1, 4, 5)
Begin
	-- Movement Type not supported
	Set @sAlertXML = dbo.fn_GetAlertXML('AC5', 'An unsupported movement type was passed into acw_LoadWorkHistory. Please report this coding error to a support consultant.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Set @sSQLString = 'select @nStatus = STATUS FROM OPENITEM WHERE ITEMENTITYNO = @pnItemEntityNo
					AND ITEMTRANSNO = @pnItemTransNo'
					
	exec @nErrorCode=sp_executesql @sSQLString, 
			N'@pnItemEntityNo	int,
			  @pnItemTransNo	int,
			  @nStatus		smallint output',
			  @pnItemEntityNo = @pnItemEntityNo,
			  @pnItemTransNo = @pnItemTransNo,
			  @nStatus = @nStatus output
End

-- PRE-POPULATE THE TAX SUMMARY FOR PREPAYMENT CREDITS
CREATE TABLE #TEMPTAXHISTORY
(	[ITEMENTITYNO] [int] NOT NULL,
	[ITEMTRANSNO] [int] NOT NULL,
	[ACCTENTITYNO] [int] NOT NULL,
	[ACCTDEBTORNO] [int] NOT NULL,
	[HISTORYLINENO] [smallint] NOT NULL,
	[TAXCODE] [nvarchar](3) NOT NULL,
	[TAXRATE] [decimal](11, 4) NULL,
	[TAXABLEAMOUNT] [decimal](11, 2) NULL,
	[TAXAMOUNT] [decimal](11, 2) NULL,
	[FOREIGNTAXABLE] decimal(11,2) null,
	FOREIGNTAX decimal(11,2) null,
	[COUNTRYCODE] [nvarchar](3) NULL,
	[REFENTITYNO] [int] NULL,
	[REFTRANSNO] [int] NULL,
	[STATE] [nvarchar](20) NULL,
	[HARMONISED] [bit] NULL,
	[TAXONTAX] [bit] NULL,
	[MODIFIED] [bit] NULL,
	[ADJUSTMENT] [decimal](11, 2) NULL
)

CREATE TABLE #TEMPBILLEDCREDIT (
	CRITEMENTITYNO INT NOT NULL,
	CRITEMTRANSNO INT NOT NULL,
	CRACCTENTITYNO INT NOT NULL,
	CRACCTDEBTORNO INT NOT NULL,
	DRITEMENTITYNO INT NOT NULL,
	DRITEMTRANSNO INT NOT NULL,
	FORCEDPAYOUT BIT not null default 0,
	LOCALSELECTED DECIMAL(13,2),
	FOREIGNSELECTED DECIMAL(13,2),
	CREXCHVARIANCE DECIMAL(13,2)
)

if @nErrorCode = 0 and @pnMovementType = 4
Begin
	INSERT INTO #TEMPBILLEDCREDIT (LOCALSELECTED, FOREIGNSELECTED, CREXCHVARIANCE,
					CRITEMENTITYNO,CRITEMTRANSNO,CRACCTENTITYNO,CRACCTDEBTORNO,
					DRITEMENTITYNO,DRITEMTRANSNO,FORCEDPAYOUT)
	SELECT SUM(LOCALSELECTED) AS LOCALSELECTED, SUM(ISNULL(FOREIGNSELECTED,0)) AS FOREIGNSELECTED, SUM(ISNULL(CREXCHVARIANCE,0)) AS CREXCHVARIANCE,
		CRITEMENTITYNO,CRITEMTRANSNO,CRACCTENTITYNO,CRACCTDEBTORNO,
		DRITEMENTITYNO,DRITEMTRANSNO,FORCEDPAYOUT
	FROM BILLEDCREDIT
	Where DRITEMENTITYNO = @pnItemEntityNo
	and DRITEMTRANSNO = @pnItemTransNo
	GROUP BY CRITEMENTITYNO,CRITEMTRANSNO,CRACCTENTITYNO,CRACCTDEBTORNO,DRITEMENTITYNO,DRITEMTRANSNO,FORCEDPAYOUT
End

If (@pnMovementType = 4
and exists (select * from SITECONTROL WHERE CONTROLID = 'Tax Prepayments' and COLBOOLEAN = 1)
and exists (select * from SITECONTROL WHERE CONTROLID = 'TAXREQUIRED' AND COLBOOLEAN = 1)
and exists (select * from BILLEDCREDIT BC 
		JOIN OPENITEM OI on (BC.CRITEMENTITYNO = OI.ITEMENTITYNO
					AND BC.CRITEMTRANSNO = OI.ITEMTRANSNO
					AND OI.ITEMTYPE = 523)
		WHERE BC.DRITEMENTITYNO = @pnItemEntityNo
		AND BC.DRITEMTRANSNO = @pnItemTransNo)
)
Begin
	-- BUILD A TEMP TABLE OF CONSUMED TAX AMOUNTS FOR PREPAYMENTS IN THE CURRENCY OF THE ORIGINAL CREDIT ITEM
	INSERT INTO #TEMPTAXHISTORY ([ITEMENTITYNO],
		[ITEMTRANSNO],
		[ACCTENTITYNO],
		[ACCTDEBTORNO],
		[HISTORYLINENO],
		[TAXCODE],
		[TAXRATE],
		[TAXABLEAMOUNT],
		[TAXAMOUNT],
		[FOREIGNTAXABLE],
		[FOREIGNTAX],
		[COUNTRYCODE])
	Select TAXBALANCE.ITEMENTITYNO, TAXBALANCE.ITEMTRANSNO, TAXBALANCE.ACCTENTITYNO, TAXBALANCE.ACCTDEBTORNO,
	MAXDHIST.MAXHISTORYLINENO + 1, -- history line no will match DEBTORHISTORY.HISTORYLINENO
	TAXBALANCE.TAXCODE, TAXBALANCE.TAXRATE,

	-- proportion taxable amount
	ROUND(BCT.LOCALSELECTED * (TAXBALANCE.TOTALTAXABLE / (TAXBALANCE.TOTALTAXABLE + TAXBALANCE.TOTALTAX)), 2),
	--  tax amount based on proportionate taxable
	ROUND(BCT.LOCALSELECTED * (TAXBALANCE.TOTALTAX / (TAXBALANCE.TOTALTAX + TAXBALANCE.TOTALTAXABLE)),2),
	
	NULL, NULL, NULL
	From
	#TEMPBILLEDCREDIT BCT
	Join (Select max(HISTORYLINENO) MAXHISTORYLINENO,
			ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
			From DEBTORHISTORY
			GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) as MAXDHIST
			on (	MAXDHIST.ITEMENTITYNO = BCT.CRITEMENTITYNO
					and MAXDHIST.ITEMTRANSNO = BCT.CRITEMTRANSNO
					and MAXDHIST.ACCTENTITYNO = BCT.CRACCTENTITYNO
					and MAXDHIST.ACCTDEBTORNO = BCT.CRACCTDEBTORNO)
	Join (Select sum(TAXABLEAMOUNT) as TOTALTAXABLE, sum(TAXAMOUNT) as TOTALTAX,
			ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, TAXCODE, TAXRATE
			From TAXHISTORY
			Group by ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, TAXCODE, TAXRATE) as TAXBALANCE
			on (	TAXBALANCE.ITEMENTITYNO = BCT.CRITEMENTITYNO
					and TAXBALANCE.ITEMTRANSNO = BCT.CRITEMTRANSNO
					and TAXBALANCE.ACCTENTITYNO = BCT.CRACCTENTITYNO
					and TAXBALANCE.ACCTDEBTORNO = BCT.CRACCTDEBTORNO)


	-- CALCULATE Foreign tax amounts in the currency of the ORIGINAL CREDIT
	Update T
	Set FOREIGNTAX = 
			Case WHEN DHSUM.LOCALTAXBALANCE = 0 or DHSUM.LOCALTAXBALANCE IS NULL 
				THEN round(T.TAXAMOUNT * OI.EXCHRATE, 2) -- Derive Foreign using currency/exch
				ELSE T.TAXAMOUNT * (DHSUM.FOREIGNTAXBALANCE / DHSUM.LOCALTAXBALANCE) -- Derive Foreign
			End,
	FOREIGNTAXABLE = Case WHEN DHSUM.LOCALTAXBALANCE = 0 or DHSUM.LOCALTAXBALANCE IS NULL 
				THEN round(T.TAXABLEAMOUNT * OI.EXCHRATE, 2) -- Derive Foreign using currency/exch
				ELSE T.TAXABLEAMOUNT * (DHSUM.FOREIGNTAXBALANCE / DHSUM.LOCALTAXBALANCE) -- Derive Foreign
			End
	From
	#TEMPTAXHISTORY T
	Join OPENITEM OI on (OI.ITEMENTITYNO = T.ITEMENTITYNO
						and OI.ITEMTRANSNO = T.ITEMTRANSNO
						and OI.ACCTENTITYNO = T.ACCTENTITYNO
						and OI.ACCTDEBTORNO = T.ACCTDEBTORNO)
	Join (SELECT SUM(LOCALTAXAMT) AS LOCALTAXBALANCE, SUM(FOREIGNTAXAMT) AS FOREIGNTAXBALANCE,
			ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO 
			FROM DEBTORHISTORY
			GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) as DHSUM
		on (DHSUM.ITEMENTITYNO = OI.ITEMENTITYNO
					and DHSUM.ITEMTRANSNO = OI.ITEMTRANSNO
					and DHSUM.ACCTENTITYNO = OI.ACCTENTITYNO
					and DHSUM.ACCTDEBTORNO = OI.ACCTDEBTORNO)
	-- Where clause not required as #TEMPTAXHISTORY already filtered
End

If (@nErrorCode = 0)
Begin
	-- Load Debtor history (Movement = Generate)
	Set @sInsert = "		
		Insert into DEBTORHISTORY
		(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO,
		HISTORYLINENO,
		TRANSDATE, TRANSTYPE,
		OPENITEMNO, CURRENCY, EXCHRATE, REFERENCETEXT,
		REFENTITYNO, REFTRANSNO,

		COMMANDID, MOVEMENTCLASS, ITEMIMPACT,

		REASONCODE,
		ITEMPRETAXVALUE, LOCALTAXAMT, LOCALVALUE,
		FOREIGNTAXAMT, FOREIGNTRANVALUE, EXCHVARIANCE, TOTALEXCHVARIANCE,
		LOCALBALANCE, FOREIGNBALANCE,FORCEDPAYOUT,

		STATUS,POSTDATE, POSTPERIOD)"

	Set @sColumnsSelect = "SELECT O.ITEMENTITYNO, O.ITEMTRANSNO, O.ACCTENTITYNO, O.ACCTDEBTORNO,
	ISNULL(MAXHIST.MAXHISTORYLINENO, 0) + 1,
	TH.TRANSDATE, TH.TRANSTYPE,
	O.OPENITEMNO, O.CURRENCY, O.EXCHRATE, O.REFERENCETEXT,
	@pnItemEntityNo, @pnItemTransNo,"

	if (@pnMovementType = 1) -- Generate
	Begin
	Set @sColumnsSelect = @sColumnsSelect+char(10)+"
		1, 1, 1,
		CASE WHEN TH.TRANSTYPE IN (516,519) THEN @psReasonCode ELSE NULL END, -- REASONCODE CREDITS
		O.ITEMPRETAXVALUE, O.LOCALTAXAMT, O.LOCALVALUE,
		O.FOREIGNTAXAMT, O.FOREIGNVALUE, 0, 0,
		O.LOCALVALUE, CASE WHEN O.CURRENCY IS NOT NULL THEN O.FOREIGNVALUE ELSE NULL END,0,"
	End
	Else if (@pnMovementType = 5 and @pbPostCredits = 0) -- Adjust down
	Begin
		Set @sColumnsSelect = @sColumnsSelect+char(10)+"6, 5, null,
		CASE WHEN (O.EXCHVARIANCE * -1) > 0 THEN SCELR.COLCHARACTER ELSE NULL END, -- REASONCODE VARIANCE
		0, 0, O.LOCALORIGTAKENUP * -1, -- ITEMPRETAXVALUE, LOCALTAX, LOCALVALUE
		0, CASE WHEN O.CURRENCY IS NOT NULL THEN O.FOREIGNORIGTAKENUP * -1 ELSE NULL END, -- FOREIGNTAXAMT, FOREIGNTRANVALUE
		O.EXCHVARIANCE * -1, O.EXCHVARIANCE, -- EXCHVARIANCE, TOTALEXCHVARIANCE,
		O.LOCALBALANCE, CASE WHEN O.CURRENCY IS NOT NULL THEN O.FOREIGNBALANCE END,ISNULL(BC.FORCEDPAYOUT, 0),"
	End
	Else if (@pnMovementType = 4 and @pbPostCredits = 1) -- Adjust up credit note
	Begin
		Set @sColumnsSelect = @sColumnsSelect+char(10)+"5, 4, NULL,
		null, -- REASONCODE VARIANCE
		BC.LOCALSELECTED - isnull(TTH.TAXAMOUNT,0), --ITEMPRETAX
		isnull(TTH.TAXAMOUNT,0), -- TAX
		BC.LOCALSELECTED, -- LOCALVALUE
		CASE WHEN O.CURRENCY IS NOT NULL THEN TTH.FOREIGNTAX ELSE NULL END, -- FOREIGNTAXAMT
		CASE WHEN O.CURRENCY IS NOT NULL THEN BC.FOREIGNSELECTED ELSE NULL END, -- FOREIGNTRANVALUE
		ISNULL(BC.CREXCHVARIANCE, 0), ISNULL(BC.CREXCHVARIANCE, 0) * -1, -- EXCHVARIANCE, TOTALEXCHVARIANCE
		O.LOCALBALANCE + BC.LOCALSELECTED, -- LOCALBALANCE
		CASE WHEN O.CURRENCY IS NOT NULL THEN O.FOREIGNBALANCE + BC.FOREIGNSELECTED END,0,"
	End
	Else 
	Begin
		Set @sColumnsSelect = @sColumnsSelect+char(10)+"1, 1, 1,
		CASE WHEN TH.TRANSTYPE IN (516,519) THEN @psReasonCode ELSE NULL END, -- REASONCODE CREDITS
		null, null, null
		null, null, null, null
		null, null,0,"
	End

	Set @sColumnsSelect = @sColumnsSelect+char(10)+"@nStatus, @pdtPostDate, @pnPostPeriod"

	If (@pbPostCredits = 0)
	Begin
		Set @sFrom = "From OPENITEM O
			Join TRANSACTIONHEADER TH on (TH.ENTITYNO = O.ITEMENTITYNO
							and TH.TRANSNO = O.ITEMTRANSNO)
			Left Join (SELECT TOP 1 DRITEMENTITYNO, DRITEMTRANSNO, DRACCTENTITYNO, DRACCTDEBTORNO, FORCEDPAYOUT
				FROM BILLEDCREDIT
				WHERE DRITEMENTITYNO = @pnItemEntityNo
				and DRITEMTRANSNO = @pnItemTransNo) AS BC
							on (O.ITEMENTITYNO = BC.DRITEMENTITYNO
							and O.ITEMTRANSNO = BC.DRITEMTRANSNO
							and O.ACCTENTITYNO = BC.DRACCTENTITYNO
							and O.ACCTDEBTORNO = BC.DRACCTDEBTORNO)
			Left join SITECONTROL SCELR on SCELR.CONTROLID = 'Exchange Loss Reason'"
	End
	Else If (@pnMovementType = 4 and @pbPostCredits = 1)
	Begin	
		-- We're adding a DH row for the taken up credit item(s)
		Set @sFrom = "From #TEMPBILLEDCREDIT BC 
			Join OPENITEM O on (O.ITEMENTITYNO = BC.CRITEMENTITYNO
										and O.ITEMTRANSNO = BC.CRITEMTRANSNO
										and O.ACCTENTITYNO = BC.CRACCTENTITYNO
										and O.ACCTDEBTORNO = BC.CRACCTDEBTORNO)
			Join TRANSACTIONHEADER TH on (TH.ENTITYNO = BC.DRITEMENTITYNO
							and TH.TRANSNO = BC.DRITEMTRANSNO)
			Join TRANSACTIONHEADER THPP on (THPP.ENTITYNO = O.ITEMENTITYNO
							and THPP.TRANSNO = O.ITEMTRANSNO)
			Left Join (select sum(TAXAMOUNT) as TAXAMOUNT, sum(FOREIGNTAX) as FOREIGNTAX,
				ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
				from #TEMPTAXHISTORY
				GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) as TTH on (TTH.ITEMENTITYNO = O.ITEMENTITYNO
													and TTH.ITEMTRANSNO = O.ITEMTRANSNO
													and TTH.ACCTENTITYNO = O.ACCTENTITYNO
													and TTH.ACCTDEBTORNO = O.ACCTDEBTORNO)"
	End

	Set @sFrom = @sFrom + char(10) + "Left Join (SELECT MAX(HISTORYLINENO) MAXHISTORYLINENO, ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
				From DEBTORHISTORY
				GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) AS MAXHIST
					on (MAXHIST.ITEMENTITYNO = O.ITEMENTITYNO
						and MAXHIST.ITEMTRANSNO = O.ITEMTRANSNO
						and MAXHIST.ACCTENTITYNO = O.ACCTENTITYNO
						and MAXHIST.ACCTDEBTORNO = O.ACCTDEBTORNO)"

	
	if (@pnMovementType != 4)
	Begin
		-- Get the Debit info
		Set @sWhere = "Where O.ITEMENTITYNO = @pnItemEntityNo
			and O.ITEMTRANSNO = @pnItemTransNo"
	End

	Set @sSQLString = @sInsert +char(10)+ @sColumnsSelect +char(10)+ @sFrom +char(10)+ @sWhere

	exec @nErrorCode=sp_executesql @sSQLString, 
			N'@pnItemEntityNo	int,
			  @pnItemTransNo	int,
			  @psReasonCode		nvarchar(2),
			  @pdtPostDate		datetime,
			  @pnPostPeriod		int,
			  @nStatus		smallint',
			  @pnItemEntityNo = @pnItemEntityNo,
			  @pnItemTransNo = @pnItemTransNo,
			  @psReasonCode = @psReasonCode,
			  @pdtPostDate = @pdtPostDate,
			  @pnPostPeriod = @pnPostPeriod,
			  @nStatus = @nStatus
End


-- Update the Debtors Ledger Control Totals
If (@nErrorCode = 0 and @pnMovementType = 1 AND @pnPostPeriod is not null)
Begin
	Select @nControlTotal = SUM(LOCALVALUE)
			From OPENITEM
			Where ITEMENTITYNO = @pnItemEntityNo
			and ITEMTRANSNO = @pnItemTransNo

	-- Call this procedure to insert/update as appropriate
	exec @nErrorCode = dbo.acw_UpdateControlTotal
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pbCalledFromCentura = @pbCalledFromCentura,
		@pnLedger = 2,
		@pnCategory	= @pnMovementType,
		@pnType	= 510,
		@pnPeriodId	= @pnPostPeriod,
		@pnEntityNo	= @pnItemEntityNo,
		@pnAmountToAdd = @nControlTotal
End
Else If (@nErrorCode = 0 and @pnMovementType = 5)
Begin
	set @nControlTotal = 0
	
	Select @nControlTotal = SUM(LOCALORIGTAKENUP) * -1
		From OPENITEM
		Where ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo

	if (@nControlTotal != 0)
	Begin
		-- Call this procedure to insert/update as appropriate
		exec @nErrorCode = dbo.acw_UpdateControlTotal
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnLedger = 2,
			@pnCategory	= @pnMovementType,
			@pnType	= 510,
			@pnPeriodId	= @pnPostPeriod,
			@pnEntityNo	= @pnItemEntityNo,
			@pnAmountToAdd = @nControlTotal
	End
End
Else If (@nErrorCode = 0 and @pnMovementType = 4)
Begin

	set @nControlTotal = 0

	Select @nControlTotal = SUM(LOCALSELECTED)
		From BILLEDCREDIT
		Where DRITEMENTITYNO = @pnItemEntityNo
		and DRITEMTRANSNO = @pnItemTransNo


	if (@nControlTotal != 0)
	Begin
		-- Call this procedure to insert/update as appropriate
		exec @nErrorCode = dbo.acw_UpdateControlTotal
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnLedger = 2,
			@pnCategory	= @pnMovementType,
			@pnType	= 510,
			@pnPeriodId	= @pnPostPeriod,
			@pnEntityNo	= @pnItemEntityNo,
			@pnAmountToAdd = @nControlTotal
	End

	-- Write any corresponding tax history
	If (@nErrorCode = 0) 
		and exists (select * from #TEMPTAXHISTORY)
	Begin
		insert into TAXHISTORY(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO,
		HISTORYLINENO, TAXCODE, TAXRATE, 
		TAXABLEAMOUNT, TAXAMOUNT, 
		COUNTRYCODE, REFENTITYNO, REFTRANSNO)
		SELECT ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO,
		HISTORYLINENO, TAXCODE, TAXRATE, TAXABLEAMOUNT * -1, TAXAMOUNT * -1,
		COUNTRYCODE, @pnItemEntityNo, @pnItemTransNo
		FROM #TEMPTAXHISTORY
	End

	-- update credit open item(s) balances
	If (@nErrorCode = 0)
	Begin
		Update OI
		SET STATUS = 1,
			LOCALBALANCE = OI.LOCALBALANCE + BC.LOCALSELECTED,
			EXCHVARIANCE = CASE WHEN BC.CREXCHVARIANCE IS NOT NULL THEN BC.CREXCHVARIANCE * -1 ELSE OI.EXCHVARIANCE END,
			FOREIGNBALANCE = OI.FOREIGNBALANCE + BC.FOREIGNSELECTED,
			CLOSEPOSTPERIOD = CASE WHEN (OI.LOCALBALANCE + BC.LOCALSELECTED) = 0 THEN @pnPostPeriod ELSE CLOSEPOSTPERIOD END,
			CLOSEPOSTDATE = CASE WHEN (OI.LOCALBALANCE + BC.LOCALSELECTED) = 0 THEN @pdtPostDate ELSE CLOSEPOSTDATE END
		From OPENITEM OI
		Join #TEMPBILLEDCREDIT BC on (BC.CRITEMENTITYNO = OI.ITEMENTITYNO
							and BC.CRITEMTRANSNO = OI.ITEMTRANSNO
							and BC.CRACCTENTITYNO = OI.ACCTENTITYNO
							and BC.CRACCTDEBTORNO = OI.ACCTDEBTORNO)
	End

	-- If the credit is at the case level, write DebtorHistoryCase records
	If exists (select * from BILLEDCREDIT 
				Where CRCASEID is not null 
				and DRITEMENTITYNO = @pnItemEntityNo
				and DRITEMTRANSNO = @pnItemTransNo)
	Begin
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "insert into DEBTORHISTORYCASE (ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO,
				HISTORYLINENO, CASEID, LOCALVALUE, FOREIGNTRANVALUE)
			select BC.CRITEMENTITYNO, BC.CRITEMTRANSNO, BC.CRACCTENTITYNO, BC.CRACCTDEBTORNO,
				MAXDH.MAXHISTORYLINENO, BC.CRCASEID, BC.LOCALSELECTED, BC.FOREIGNSELECTED
			From BILLEDCREDIT BC
			Join (SELECT ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, MAX(HISTORYLINENO) MAXHISTORYLINENO FROM DEBTORHISTORY
				WHERE MOVEMENTCLASS = 4
				GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) AS MAXDH
						on (MAXDH.ITEMENTITYNO = BC.CRITEMENTITYNO
							and MAXDH.ITEMTRANSNO = BC.CRITEMTRANSNO
							and MAXDH.ACCTENTITYNO = BC.CRACCTENTITYNO
							and MAXDH.ACCTDEBTORNO = BC.CRACCTDEBTORNO)
			WHERE BC.DRITEMENTITYNO = @pnItemEntityNo
			and BC.DRITEMTRANSNO = @pnItemTransNo
			and BC.CRCASEID is not null"

			exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
		End

		-- Update openitemcase
		If (@nErrorCode = 0)
		Begin
			Set @sSQLString = "Update OIC
			Set LOCALBALANCE = OIC.LOCALBALANCE + BC.LOCALSELECTED, 
				FOREIGNBALANCE = OIC.FOREIGNBALANCE + BC.FOREIGNSELECTED,
				STATUS = 1
			From BILLEDCREDIT BC
			Join OPENITEMCASE OIC on OIC.ITEMENTITYNO = BC.CRITEMENTITYNO
						and OIC.ITEMTRANSNO = BC.CRITEMTRANSNO
						and OIC.ACCTENTITYNO = BC.CRACCTENTITYNO
						and OIC.ACCTDEBTORNO = BC.CRACCTDEBTORNO
						and OIC.CASEID = BC.CRCASEID
			and BC.DRITEMENTITYNO = @pnItemEntityNo
			and BC.DRITEMTRANSNO = @pnItemTransNo
			and BC.CRCASEID is not null"

		exec @nErrorCode=sp_executesql @sSQLString, 
			N'@pnItemEntityNo	int,
			  @pnItemTransNo	int',
			  @pnItemEntityNo = @pnItemEntityNo,
			  @pnItemTransNo = @pnItemTransNo
		End
	End

End

if exists (select * from tempdb.dbo.sysobjects where name like '#TEMPTAXHISTORY%')
Begin
	DROP TABLE #TEMPTAXHISTORY
End

if exists (select * from tempdb.dbo.sysobjects where name like '#TEMPBILLEDCREDIT%')
Begin
	DROP TABLE #TEMPBILLEDCREDIT
End


Return @nErrorCode
GO

Grant execute on dbo.acw_PostDebtorHistory to public
GO