-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_PostWorkHistory									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_PostWorkHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_PostWorkHistory.'
	Drop procedure [dbo].[acw_PostWorkHistory]
End
Print '**** Creating Stored Procedure dbo.acw_PostWorkHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.acw_PostWorkHistory
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo	int,
	@pnItemTransNo	int,
	@pnMovementType	int,
	@pnPostPeriod	int,
	@pnTransType	int = null
)
as
-- PROCEDURE:	acw_PostWorkHistory
-- VERSION:	21
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Post WORKHISTORY for a bill for a particular Movement Type.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	-----------------------------------------------
-- 05 Feb 2010	AT	RFC3605		1	Procedure created.
-- 27 Apr 2010	AT	RFC8292		2	Cater for bill in advance WIP.
-- 13 May 2010	AT	RFC9092		3	Modify where clause to process draft WIP.
-- 19 May 2010	AT	RFC9092		4	Modify adjust Where clause to ignore bill in advance WIP (Movementclass = 2)
-- 25 Jun 2010	AT	RFC8291		5	Adjust Where clause to process appropriate write down WIP
-- 06 Sep 2010	AT	RFC9740 	9	Fixed writing of Work History rows when adjusting WIP.
-- 11-Feb-2011	AT	RFC10202	10	Fixed write down dispose row writing to Work History.
-- 04 May 2011	AT	RFC10568	11	Fixed Cost Calculation for consumed WIP items.
-- 16 May 2011	AT	RFC10642	12	Fix Cost Calculation for write downs.
-- 15 Jul 2011	DL	SQA19791	13	Extend variable referencing CONTROLTOTAL.TOTAL to dec(13,2) instead of dec(11,2)
-- 07 Oct 2011	AT	RFC11392	14	Moved Post draft WIP from biw_FinaliseOpenItem to be handled here.
-- 17 Oct 2011	AT	RFC11392	15	Fix control total calculation for draft credit wip items.
-- 05 Jan 2012	AT	RFC9165		16	Re-derive Exch rate for billed items
-- 15 Feb 2012	LP	R100613		17	Update BILLLINENO in WORKHISTORY for creditor-only credit notes.
-- 11 Sep 2013	vql	DR-495		18	Reverse a bill that includes debtor-allocated WIP.
-- 29 Apr 2014	LP	R13938		19	Do not update control totals if WORKHISTORY was not updated.
-- 18 Jun 2014	AT	R35473		20	Revise LOCALCOST and FOREIGNCOST calculations.
-- 13 Apr 2015	vql	R35473		21	Fix bug to write marginflag

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Set @nErrorCode = 0

Declare @sSQLString nvarchar(max)
Declare @sInsert nvarchar(max)
Declare @sColumnsSelect nvarchar(max)
Declare @sFrom nvarchar(max)
Declare @sWhere nvarchar(max)
Declare @sAlertXML nvarchar(1000)
Declare @nWorkHistoryInserted int

Set @nWorkHistoryInserted = 0

-- Preconditions
If @pnMovementType not in (1, 2, 3, 9)
Begin
	-- Movement Type not supported
	Set @sAlertXML = dbo.fn_GetAlertXML('AC5', 'An unsupported movement type was passed into acw_LoadWorkHistory. Please report this coding error to a support consultant.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End


If not exists (Select * 
		From WORKHISTORY WH
		Join BILLEDITEM BI ON (BI.WIPENTITYNO = WH.ENTITYNO
							and BI.WIPTRANSNO = WH.TRANSNO
							and BI.WIPSEQNO = WH.WIPSEQNO)
		Where BI.ITEMENTITYNO = @pnItemEntityNo
		and BI.ITEMTRANSNO = @pnItemTransNo)
Begin
	-- Transction not found
	Set @sAlertXML = dbo.fn_GetAlertXML('AC6', 'The Work History has changed or could not be found. Please reload the data and try again.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End


If (@nErrorCode = 0)
Begin
	Set @sInsert = "
		Insert into WORKHISTORY (ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, 
		TRANSDATE, TRANSTYPE,
		REASONCODE,
		ACCTCLIENTNO, ACCTENTITYNO,
		POSTDATE, POSTPERIOD, STATUS,
		ASSOCLINENO, BILLLINENO,
		RATENO, WIPCODE, CASEID,
		EMPLOYEENO,ASSOCIATENO, INVOICENUMBER,
		VERIFICATIONNUMBER, 
		REFENTITYNO, REFTRANSNO, 
		EMPPROFITCENTRE, EMPFAMILYNO, EMPOFFICECODE, 
		CASEPROFITCENTRE, NARRATIVENO, SHORTNARRATIVE, LONGNARRATIVE,
		FEECRITERIANO, FEEUNIQUEID, VARIABLEFEEAMT, VARIABLEFEECURR, VARIABLEFEETYPE,
		QUOTATIONNO, 
		DISCOUNTFLAG, PRODUCTCODE, GENERATEDINADVANCE,
		FOREIGNCURRENCY, SPLITPERCENTAGE, MARGINFLAG, EXCHRATE,
		LOCALTRANSVALUE, FOREIGNTRANVALUE, COSTCALCULATION1, COSTCALCULATION2,
		MOVEMENTCLASS, COMMANDID, ITEMIMPACT, 
		LOCALCOST, FOREIGNCOST)"

		-- TODO: populate these columns on Generate.
		-- These values are not updated in the post.
		--CHARGEOUTRATE,
		--
		--ENTEREDQUANTITY,
		--GENERATEDINADVANCE, GLMOVEMENTNO, 
		--REASONCODE,
		--REFACCTDEBTORNO, REFACCTENTITYNO, 
		--REFSEQNO, 
		--TRANSFERDETAIL, 
		--TOTALTIME, TOTALUNITS,
		--UNITSPERHOUR, 


	Select @sColumnsSelect = "SELECT WIP.ENTITYNO, WIP.TRANSNO,
			WH.WIPSEQNO,
			MAXHLN.MAXHISTORYLINENO + 1,
			TH.TRANSDATE,
			TH.TRANSTYPE,"

			IF @pnMovementType IN (3,9)
			Begin
				Set @sColumnsSelect = @sColumnsSelect + char(10) + "BI.REASONCODE,"
			End
			Else
			Begin
				Set @sColumnsSelect = @sColumnsSelect + char(10) + "null,"
			End

			Set @sColumnsSelect = @sColumnsSelect + char(10) + "CASE WHEN WIP.ACCTCLIENTNO IS NOT NULL THEN WIP.ACCTCLIENTNO ELSE NULL END,
			CASE WHEN WIP.ACCTCLIENTNO IS NOT NULL THEN TH.ENTITYNO ELSE NULL END,
			O.POSTDATE, O.POSTPERIOD, 1,
			NULL, ISNULL(BI.ITEMLINENO, 1),
			WIP.RATENO,	-- rateno
			WIP.WIPCODE, -- WIPCODE
			WIP.CASEID, -- CASEID
			WIP.EMPLOYEENO,	WIP.ASSOCIATENO, WIP.INVOICENUMBER,
			WIP.VERIFICATIONNUMBER,

			TH.ENTITYNO,
			TH.TRANSNO,

			WIP.EMPPROFITCENTRE,
			WIP.EMPFAMILYNO,
			WIP.EMPOFFICECODE,

			WIP.CASEPROFITCENTRE, WIP.NARRATIVENO, WIP.SHORTNARRATIVE, WIP.LONGNARRATIVE,
			WIP.FEECRITERIANO, WIP.FEEUNIQUEID, WIP.VARIABLEFEEAMT, WIP.VARIABLEFEECURR, WIP.VARIABLEFEETYPE,
			Case when (WH.QUOTATIONNO != WIP.QUOTATIONNO) THEN NULL ELSE WIP.QUOTATIONNO END, --QUOTATIONNO
			WIP.DISCOUNTFLAG, WIP.PRODUCTCODE, WIP.GENERATEDINADVANCE,
			WIP.FOREIGNCURRENCY, WIP.SPLITPERCENTAGE, WIP.MARGINFLAG, "

	If (@pnMovementType = 1)
	Begin
		-- GENERATE
		set @sColumnsSelect = @sColumnsSelect + char(10) + 
			"WIP.EXCHRATE, WIP.LOCALVALUE, WIP.FOREIGNVALUE, WIP.COSTCALCULATION1, WIP.COSTCALCULATION2,"
	End
	Else If (@pnMovementType = 2)
	Begin
		-- Consume
		set @sColumnsSelect = @sColumnsSelect + char(10) + 
			"abs(BI.FOREIGNBILLEDVALUE / BI.BILLEDVALUE), 
			BI.BILLEDVALUE * -1, BI.FOREIGNBILLEDVALUE * -1, null, null,"
	End
	Else
	Begin
		-- WIP Variation
		set @sColumnsSelect = @sColumnsSelect + char(10) + 
			"Case when ISNULL(BI.FOREIGNADJUSTEDVALUE,0) = 0 THEN NULL ELSE abs(BI.FOREIGNADJUSTEDVALUE / BI.ADJUSTEDVALUE) END,
			BI.ADJUSTEDVALUE, -- LOCALTRANSVALUE
			BI.FOREIGNADJUSTEDVALUE, --FOREIGNTRANVALUE
			NULL, NULL,"
	End

	If @pnMovementType = 1
	Begin
		-- GENERATE
		Set @sColumnsSelect = @sColumnsSelect + 
		char(10)+"1, -- MOVEMENTCLASS
			1, --COMMANDID
			1, -- ITEMIMPACT"
	End
	Else If @pnMovementType = 2
	Begin
		-- CONSUME
		Set @sColumnsSelect = @sColumnsSelect + 
		char(10)+"2, -- MOVEMENTCLASS
		3, --COMMANDID
		NULL, -- ITEMIMPACT"
	End
	Else If @pnMovementType = 3
	Begin
		-- DISPOSE
			Set @sColumnsSelect = @sColumnsSelect + 
		char(10)+"3, -- MOVEMENTCLASS
		4, -- COMMANDID
		NULL, -- ITEMIMPACT"
	End
	Else If @pnMovementType = 9
	Begin
		-- EQUALISE
		Set @sColumnsSelect = @sColumnsSelect + 
		char(10)+"9, -- MOVEMENTCLASS
		7, -- COMMANDID
		NULL, -- ITEMIMPACT"
	End

	-- CONSUME
	If (@pnMovementType = 2)
	Begin
		-- 10568 - Write-ups apply the entire cost.
		-- otherwise proportion the cost value from the BILLEDVALUE
		Set @sColumnsSelect = @sColumnsSelect + char(10) + "
			Case WHEN ISNULL(WH.LOCALCOST,0) != 0
			THEN CASE WHEN ABS(BI.BILLEDVALUE) >= ABS(WIP.BALANCE)
					THEN WHCOST.LCOSTBAL * -1
				ELSE BI.BILLEDVALUE * -1 * WH.LOCALCOST / WH.LOCALTRANSVALUE
				END
			ELSE NULL
			END, -- LOCAL COST

			Case WHEN ISNULL(WH.FOREIGNCOST,0) != 0 AND ISNULL(WH.FOREIGNTRANVALUE,0) != 0
			THEN	Case WHEN ABS(BI.BILLEDVALUE) >= ABS(WIP.BALANCE)
					THEN WHCOST.FCOSTBAL * -1
				ELSE BI.FOREIGNBILLEDVALUE * -1 * WH.FOREIGNCOST / WH.FOREIGNTRANVALUE
				END
			ELSE NULL
			END -- FOREIGN COST"
	End
	Else If (@pnMovementType = 3)
	Begin
		-- EQUALISE / DISPOSE (Adjust up/down)
		-- C/S doesn't write cost values for write up row.
		Set @sColumnsSelect = @sColumnsSelect + char(10) + "
			Case When ISNULL(WH.LOCALCOST,0) != 0
				and ISNULL(BI.ADJUSTEDVALUE,0) != 0
				and WIP.BALANCE > 0 -- Dispose
					Then BI.ADJUSTEDVALUE * WH.LOCALCOST / WH.LOCALTRANSVALUE
			ELSE NULL
			END, -- LOCAL COST

			Case When ISNULL(WH.FOREIGNCOST,0) != 0
				and ISNULL(BI.FOREIGNADJUSTEDVALUE,0) != 0
				and ISNULL(WH.FOREIGNTRANVALUE,0) != 0
				and WIP.BALANCE > 0 -- Dispose
					Then BI.FOREIGNADJUSTEDVALUE * WH.FOREIGNCOST / WH.FOREIGNTRANVALUE
			ELSE NULL
			END -- FOREIGN COST"
	End
	Else
	Begin
		Set @sColumnsSelect = @sColumnsSelect + char(10) + "null, null"
	End

	Set @sFrom = "FROM BILLEDITEM BI
			Join WORKHISTORY WH ON (WH.ENTITYNO = BI.WIPENTITYNO
								and WH.TRANSNO = BI.WIPTRANSNO
								and WH.WIPSEQNO = BI.WIPSEQNO
								and WH.ITEMIMPACT = 1)
			Join WORKINPROGRESS WIP ON WIP.ENTITYNO = WH.ENTITYNO
								and WIP.TRANSNO = WH.TRANSNO
								and WIP.WIPSEQNO = WH.WIPSEQNO
								
			JOIN (select ENTITYNO, TRANSNO, WIPSEQNO, 
				sum(isnull(LOCALCOST,0)) AS LCOSTBAL,
				sum(isnull(FOREIGNCOST,0)) AS FCOSTBAL
				FROM WORKHISTORY
				GROUP BY ENTITYNO, TRANSNO, WIPSEQNO) as WHCOST ON WHCOST.TRANSNO = WH.TRANSNO
						AND WHCOST.ENTITYNO = WH.ENTITYNO
						AND WHCOST.WIPSEQNO = WH.WIPSEQNO
			Join TRANSACTIONHEADER TH ON TH.ENTITYNO = BI.ENTITYNO
									AND TH.TRANSNO = BI.TRANSNO
			Join (SELECT ENTITYNO, TRANSNO, WIPSEQNO, MAX(HISTORYLINENO) as MAXHISTORYLINENO 
					FROM WORKHISTORY
					GROUP BY ENTITYNO, TRANSNO, WIPSEQNO) 
				as MAXHLN on MAXHLN.ENTITYNO = WH.ENTITYNO 
							and MAXHLN.TRANSNO = WH.TRANSNO
							and MAXHLN.WIPSEQNO = WH.WIPSEQNO
			Join (SELECT TOP 1 ITEMENTITYNO, ITEMTRANSNO, POSTDATE, POSTPERIOD FROM OPENITEM 
					Where ITEMENTITYNO = @pnItemEntityNo
					and ITEMTRANSNO = @pnItemTransNo)
				as O on (O.ITEMENTITYNO = BI.ITEMENTITYNO
						and O.ITEMTRANSNO = BI.ITEMTRANSNO)"

	Set @sWhere = "WHERE BI.ITEMENTITYNO = @pnItemEntityNo
			AND BI.ITEMTRANSNO = @pnItemTransNo"
			
	If (@pnMovementType = 2)
	Begin
		Set @sWhere = @sWhere + CHAR(10) + "AND NOT (WH.STATUS = 0 AND WH.MOVEMENTCLASS = 2)" + CHAR(10) +
						"AND ISNULL(BI.BILLEDVALUE,0) != 0"
	End
			

	if (@pnMovementType in (3,9))
	Begin
	Set @sWhere = @sWhere + char(10) + "AND ISNULL(BI.ADJUSTEDVALUE,0) != 0
				AND BI.REASONCODE IS NOT NULL"
				
		if (@pnMovementType = 3)
		Begin
			Set @sWhere = @sWhere + char(10) + "AND BI.ADJUSTEDVALUE < 0"
		End
		Else
		Begin
			Set @sWhere = @sWhere + char(10) + "AND BI.ADJUSTEDVALUE > 0"
		End
	End

	Set @sSQLString = @sInsert +char(10)+ @sColumnsSelect +char(10)+ @sFrom +char(10)+ @sWhere
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnItemEntityNo	int,
					  @pnItemTransNo	int,
					  @pnMovementType	int',
					  @pnItemEntityNo = @pnItemEntityNo,
					  @pnItemTransNo = @pnItemTransNo,
					  @pnMovementType = @pnMovementType
	
	Set @nWorkHistoryInserted = @@ROWCOUNT
End

Declare @nControlTotal decimal(13,2)

-- Update the WIP Ledger Control Totals
If (@nErrorCode = 0 and @nWorkHistoryInserted > 0)
Begin
	if @pnTransType is null
	Begin
		Set @sSQLString = "Select @pnTransType = TRANSTYPE
			FROM TRANSACTIONHEADER
			WHERE ENTITYNO = @pnItemEntityNo
			AND TRANSNO = @pnItemTransNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnItemEntityNo	int,
					  @pnItemTransNo	int,
					  @pnTransType	int OUTPUT',
					  @pnItemEntityNo = @pnItemEntityNo,
					  @pnItemTransNo = @pnItemTransNo,
					  @pnTransType = @pnTransType OUTPUT
	End

	Set @sSQLString = "select @nControlTotal = sum(LOCALTRANSVALUE)
				FROM WORKHISTORY
				WHERE REFENTITYNO = @pnItemEntityNo
				AND REFTRANSNO = @pnItemTransNo
				AND MOVEMENTCLASS = @pnMovementType"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnItemEntityNo	int,
			  @pnItemTransNo	int,
			  @pnMovementType	int,
			  @nControlTotal	decimal(12,2) OUTPUT',
			  @pnItemEntityNo = @pnItemEntityNo,
			  @pnItemTransNo = @pnItemTransNo,
			  @pnMovementType = @pnMovementType,
			  @nControlTotal = @nControlTotal OUTPUT

	If @nErrorCode = 0
	Begin
		-- Call this procedure to insert/update as appropriate
		exec @nErrorCode = dbo.acw_UpdateControlTotal
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnLedger = 1,
			@pnCategory	= @pnMovementType,
			@pnType	= @pnTransType,
			@pnPeriodId	= @pnPostPeriod,
			@pnEntityNo	= @pnItemEntityNo,
			@pnAmountToAdd = @nControlTotal
	End
End

-- If Consuming WIP on a bill, post any draft work history rows too.
If (@nErrorCode = 0
	and @pnMovementType = 2 -- Consume
	and exists (select * from WORKINPROGRESS WHERE ENTITYNO = @pnItemEntityNo and TRANSNO = @pnItemTransNo)
	)
Begin
	if @nErrorCode = 0
	Begin
		-- set the BILLLINENO against the WORKHISTORY row for non-CASE Credit Notes
		Set @sSQLString = "
			UPDATE W
			set BILLLINENO = ISNULL(BI.ITEMLINENO, 1)
			FROM WORKHISTORY W
			JOIN BILLEDITEM BI ON (BI.WIPENTITYNO = W.ENTITYNO
					and BI.WIPTRANSNO = W.TRANSNO
					and BI.WIPSEQNO = W.WIPSEQNO)
			WHERE W.ENTITYNO = @pnItemEntityNo
			and W.TRANSNO = @pnItemTransNo
			and W.STATUS = 0
			and W.MOVEMENTCLASS = 2
			and W.COMMANDID = 99
			and W.ITEMIMPACT = 1"

		exec @nErrorCode=sp_executesql @sSQLString, 
					N'@pnItemEntityNo	int,
					  @pnItemTransNo	int',
					  @pnItemEntityNo = @pnItemEntityNo,
					  @pnItemTransNo = @pnItemTransNo
	End
	
	if @nErrorCode = 0
	Begin
		Set @sSQLString = "
			UPDATE W
			set POSTDATE = OI.POSTDATE,
			POSTPERIOD = OI.POSTPERIOD,
			TRANSDATE = OI.ITEMDATE,
			STATUS = 1
			FROM WORKHISTORY W
			JOIN OPENITEM OI ON (OI.ITEMENTITYNO = W.ENTITYNO
						AND OI.ITEMTRANSNO = W.TRANSNO)
			WHERE W.ENTITYNO = @pnItemEntityNo
			and W.TRANSNO = @pnItemTransNo"

		exec @nErrorCode=sp_executesql @sSQLString, 
					N'@pnItemEntityNo	int,
					  @pnItemTransNo	int',
					  @pnItemEntityNo = @pnItemEntityNo,
					  @pnItemTransNo = @pnItemTransNo
	End
	
	-- calculate control total for original generated draft wip rows
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "select @nControlTotal = sum(WH.LOCALTRANSVALUE)
					FROM WORKHISTORY WH
					JOIN BILLEDITEM BI ON (BI.WIPENTITYNO = WH.ENTITYNO
							and BI.WIPTRANSNO = WH.TRANSNO
							and BI.WIPSEQNO = WH.WIPSEQNO)
					WHERE WH.ENTITYNO = @pnItemEntityNo
					AND WH.TRANSNO = @pnItemTransNo
					AND WH.ITEMIMPACT = 1
					-- Don't include draft credit WIP items because they're not actually consumed here,
					-- they're generated with a MOVEMENTCLASS of 2 because they're un-consumed by the CN and generated into WIP at the same time.
					-- Automatic draft credit write downs adjust the control total separately.
					AND NOT (WH.COMMANDID = 99)"
					
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @pnMovementType	int,
				  @nControlTotal	decimal(12,2) OUTPUT',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @pnMovementType = @pnMovementType,
				  @nControlTotal = @nControlTotal OUTPUT
	End

	If @nErrorCode = 0 AND @nControlTotal != 0
	Begin
		-- Call this procedure to insert/update as appropriate
		exec @nErrorCode = dbo.acw_UpdateControlTotal
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnLedger	= 1,
			@pnCategory	= 1,
			@pnType	= @pnTransType,
			@pnPeriodId	= @pnPostPeriod,
			@pnEntityNo	= @pnItemEntityNo,
			@pnAmountToAdd = @nControlTotal
	End
End

Return @nErrorCode
GO

Grant execute on dbo.acw_PostWorkHistory to public
GO