-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wpw_GetWIPItem
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[wpw_GetWIPItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure  dbo.wpw_GetWIPItem.'
	drop procedure dbo.wpw_GetWIPItem
End
print '**** Creating Stored Procedure dbo.wpw_GetWIPItem...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wpw_GetWIPItem
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura		bit		= 0,
	@pnEntityKey			int,
	@pnTransKey			int,
	@pnWIPSeqKey			int
)		
-- PROCEDURE :	wpw_GetWIPItem
-- VERSION :  10
-- DESCRIPTION:	Get a WIP Item
-- CALLED BY :	Inprotech Web

-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 19 Sep 2011	AT	RFC9012	1	Procedure created.
-- 14 Mar 2013	SW	RFC9011	2	Returned Entity Description and Responsible Name for WIP in the result set
-- 15 Mar 2013	SW	RFC9011	3	Added Local Currency details in the result set
-- 21 Mar 2013  SW	RFC9011 4	Added WIP Category key in the resultr set        
-- 22 Mar 2013  ASH	RFC9011 5	Returned Profit Centre for WIP in the result set        
-- 22 Mar 2013  SW	RFC9011	6	Added ResponsibleNameKey and ResponsibleNameCode in the result set  
-- 26 Mar 2013	DV	RFC9011	7	Returned WIP Profit Centre Source site control value in the result set.
    
-- 20 Oct 2015  MS      R53933  8       Changed size from decimal(8,4) to decimal(11,4) for rate cols
-- 02 Nov 2015	vql	R53910	9	Adjust formatted names logic (DR-15543).
-- 24 Oct 2017	AK	R72645	10	Make compatible with case sensitive server with case insensitive database.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString		nvarchar(max)
Declare @nErrorCode		int
Declare @sLookupCulture		nvarchar(10)
Declare @sAlertXML		nvarchar(1000)

Declare @nRequestedByStaffKey	int
Declare @sRequestedByStaffCode	nvarchar(20)
Declare @sRequestedByStaffName	nvarchar(326)
	
Declare @sWIPDescription	nvarchar(30)
Declare @sCurrencyCode		nvarchar(3)
Declare @nExchangeRate		decimal(11,4)
Declare @sWipTypeKey		nvarchar(6)
Declare @sWipCategoryKey	nvarchar(2)
Declare @bIsServiceCharge	bit
Declare @bUseSellRate		bit
Declare @bUseHistoricalRates	bit
Declare @dtExchTransDate	datetime
Declare @nCaseKey		int
Declare @nExchDetailsNameKey	int
Declare @bIsSupplier		bit
Declare @nBuyRate		decimal(11,2)
Declare @nSellRate		decimal(11,2)
Declare @nForeignDecimalPlaces	int
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces 	tinyint
Declare @sProfitCentreCode nvarchar(6)
Declare @sProfitCentre nvarchar(50)
Declare @nWipProfitCentreSource	int

Declare @bDebug			bit

Set @bDebug = 0

Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @dtExchTransDate = getdate()

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= 0
End

If not exists (select * from WORKINPROGRESS
	WHERE ENTITYNO = @pnEntityKey
	and	TRANSNO = @pnTransKey
	and	WIPSEQNO = @pnWIPSeqKey)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('AC29', 'WIP Item has been changed or removed. Please reload the WIP item and try again.',
    							null, null, null, null, null)
  			RAISERROR(@sAlertXML, 14, 1)
  			Set @nErrorCode = @@ERROR
End

-- Get Requested By Staff details
If @nErrorCode = 0
Begin
        set @sSQLString = 'SELECT @nRequestedByStaffKey = UIN.NAMENO,
	@sRequestedByStaffCode = UIN.NAMECODE,
        @sRequestedByStaffName =  dbo.fn_FormatNameUsingNameNo(UIN.NAMENO, null)
        FROM USERIDENTITY UI
        join NAME UIN ON UIN.NAMENO = UI.NAMENO
        where UI.IDENTITYID = @pnUserIdentityId'
        
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nRequestedByStaffKey	 int		output,
				  @sRequestedByStaffCode nvarchar(20)	output,
				  @sRequestedByStaffName nvarchar(326)	output,
				  @pnUserIdentityId	int',
				@nRequestedByStaffKey = @nRequestedByStaffKey output,
				@sRequestedByStaffCode = @sRequestedByStaffCode output,
				@sRequestedByStaffName = @sRequestedByStaffName output,
				@pnUserIdentityId = @pnUserIdentityId
End

If @nErrorCode = 0
Begin
	Select @nWipProfitCentreSource = COLINTEGER
	from SITECONTROL
	where CONTROLID = 'WIP Profit Centre Source'	
	
	Set @sSQLString = "
		    select @sProfitCentreCode = E.PROFITCENTRECODE,
		    @sProfitCentre = " + dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'P',@sLookupCulture,@pbCalledFromCentura) + char(10) +
		    "FROM EMPLOYEE E
		    left join PROFITCENTRE P on (P.PROFITCENTRECODE = E.PROFITCENTRECODE)" +char(10)+
			CASE WHEN @nWipProfitCentreSource = 1 THEN 
			"left join USERIDENTITY U on (U.IDENTITYID = @pnUserIdentityId) where E.EMPLOYEENO = isnull(@nRequestedByStaffKey, U.NAMENO)" ELSE 
			"where E.EMPLOYEENO = @nRequestedByStaffKey" END

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@sProfitCentreCode	nvarchar(6) output,
		@sProfitCentre		nvarchar(50) output,
		@nRequestedByStaffKey	 int,
		@pnUserIdentityId	int',
		@sProfitCentreCode	=@sProfitCentreCode output,
		@sProfitCentre		=@sProfitCentre output,
		@nRequestedByStaffKey =@nRequestedByStaffKey,
		@pnUserIdentityId = @pnUserIdentityId
End

If @nErrorCode = 0
Begin
	Set @sSQLString = 'Select @sCurrencyCode = W.FOREIGNCURRENCY,
		@sWipCategoryKey = WTY.CATEGORYCODE,
		@sWipTypeKey = WTY.WIPTYPEID,
		@bIsServiceCharge = case when WTY.CATEGORYCODE = ''SC'' then 1 else 0 end,
		@nCaseKey	= W.CASEID,
		@nExchDetailsNameKey = W.ACCTCLIENTNO,
		@bIsSupplier = ISNULL(D.SUPPLIERFLAG,0),
		@sWIPDescription = WT.DESCRIPTION
		FROM WORKINPROGRESS W
		JOIN WIPTEMPLATE WT ON (WT.WIPCODE = W.WIPCODE)
		JOIN WIPTYPE WTY ON (WTY.WIPTYPEID = WT.WIPTYPEID)
		LEFT JOIN NAME D ON (D.NAMENO = W.ACCTCLIENTNO)
		WHERE W.ENTITYNO = @pnEntityKey
		AND W.TRANSNO = @pnTransKey
		AND W.WIPSEQNO = @pnWIPSeqKey'
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sCurrencyCode	nvarchar(3) OUTPUT,
					@sWipCategoryKey	nvarchar(2) OUTPUT,
					@sWipTypeKey		nvarchar(6) OUTPUT,
					@bIsServiceCharge	bit OUTPUT,
					@nCaseKey		int OUTPUT,
					@nExchDetailsNameKey	int OUTPUT,
					@bIsSupplier		bit OUTPUT,
					@sWIPDescription	nvarchar(30) OUTPUT,
					@pnEntityKey		int,
					@pnTransKey		int,
					@pnWIPSeqKey		int',
					@sCurrencyCode = @sCurrencyCode OUTPUT,
					@sWipCategoryKey = @sWipCategoryKey OUTPUT,
					@sWipTypeKey = @sWipTypeKey OUTPUT,
					@bIsServiceCharge = @bIsServiceCharge OUTPUT,
					@nCaseKey = @nCaseKey OUTPUT,
					@nExchDetailsNameKey = @nExchDetailsNameKey OUTPUT,
					@bIsSupplier = @bIsSupplier OUTPUT,
					@sWIPDescription = @sWIPDescription OUTPUT,
					@pnEntityKey	= @pnEntityKey,	
					@pnTransKey	= @pnTransKey,
					@pnWIPSeqKey	= @pnWIPSeqKey
End

-- Get currency information (copied from wp_GetWipCost)
If @nErrorCode = 0
and (@sCurrencyCode is not null)
Begin
	-- Always use sell rate for services
	If (@bIsServiceCharge = 1)
	Begin
		Set @bUseSellRate = 1
	End
	-- Expenses may use either sell or buy rates
	-- Only expenses use historical rates at the moment
	Else
	Begin
		Set @sSQLString = "
		select  @bUseSellRate = isnull(COLBOOLEAN,0)
		from	SITECONTROL
		WHERE 	CONTROLID = 'Sell Rate Only for New WIP'"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@bUseSellRate		bit			OUTPUT',
						  @bUseSellRate		= @bUseSellRate		OUTPUT

	End
	
	--Get parameters required by ac_GetExchangeDetails for the given WIPCategory
	exec @nErrorCode = dbo.ac_GetExchangeParameters
		@pbUseHistoricalRates	= @bUseHistoricalRates output,
		@pdtTransactionDate	= @dtExchTransDate output,
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@psWIPCategory		= @sWipCategoryKey,
		@pnAccountingSystemID	= 2
	
	If @bDebug = 1
	Begin
		Print 'ac_GetExchangeParameters'
		Select @bUseHistoricalRates as USEHISTEXCH, @dtExchTransDate AS EXCHTRANSDATE 
	End

	If (@nErrorCode = 0)

	Begin
		
		exec @nErrorCode = dbo.ac_GetExchangeDetails
			@pnBuyRate		= @nBuyRate output,
			@pnSellRate		= @nSellRate output,
			@pnDecimalPlaces	= @nForeignDecimalPlaces output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@psCurrencyCode		= @sCurrencyCode,
			@pdtTransactionDate	= @dtExchTransDate,
			@pbUseHistoricalRates	= @bUseHistoricalRates,
			@pnCaseID		= @nCaseKey,
			@pnNameNo		= @nExchDetailsNameKey,
			@pbIsSupplier		= @bIsSupplier,
			@psWIPTypeId		= @sWipTypeKey


		If @bDebug = 1
		Begin
			Print 'ac_GetExchangeDetails'
			Select @nBuyRate	AS BUYRATE,
			@nSellRate		AS SELLRATE,
			@nForeignDecimalPlaces	AS FOREIGNDECIMALPLACES,
			@sCurrencyCode		AS CURRENCYCODE,
			@dtExchTransDate	AS TRANSDATE,
			@bUseHistoricalRates	AS USEHISTRATES,
			@nCaseKey		AS CASEID,
			@nExchDetailsNameKey	AS CASENAME,
			@bIsSupplier		AS ISSUPPLIER,
			@sWipTypeKey		as WIPTYPEID
		End
	End	


	If @nErrorCode = 0
	Begin
		If @bUseSellRate = 1
		Begin
			If isnull(@nSellRate,0) = 0
			Begin
		  		Set @sAlertXML = dbo.fn_GetAlertXML('AC5', 'Sell Rate is not available for currency {0}.',
		    						@sCurrencyCode, null, null, null, null)
		  		RAISERROR(@sAlertXML, 14, 1)
		  		Set @nErrorCode = @@ERROR
			End
			Else
			Begin
				Set @nExchangeRate = @nSellRate
			End
		End
		Else
		Begin
			If isnull(@nBuyRate,0) = 0
			Begin
		  		Set @sAlertXML = dbo.fn_GetAlertXML('AC4', 'Buy Rate is not available for currency {0}.',
		    						@sCurrencyCode, null, null, null, null)
		  		RAISERROR(@sAlertXML, 14, 1)
		  		Set @nErrorCode = @@ERROR
			End
			Else
			Begin
				Set @nExchangeRate = @nBuyRate
			End
		End
	End
End

	  
	  
If @nErrorCode = 0
Begin
	set @sSQLString = 'SELECT WIP.ENTITYNO            AS EntityKey,
	       EN.NAME		       AS Entity,
               WIP.TRANSNO             AS TransKey,
               WIP.WIPSEQNO            AS WIPSeqKey,
               WIP.TRANSDATE           AS TransDate,
               WIP.WIPCODE             AS WIPCode,
               @sWIPDescription		AS WIPDescription,
		@nRequestedByStaffKey	AS RequestedByStaffKey,
		@sRequestedByStaffCode	AS RequestedByStaffCode,
		@sRequestedByStaffName	AS RequestedByStaffName,
		@sWipCategoryKey        AS WIPCategoryKey,
		NI.NAMENO               AS ResponsibleNameKey,
		NI.NAMECODE             AS ResponsibleNameCode,
	       dbo.fn_FormatNameUsingNameNo(NI.NAMENO, null) as ResponsibleName, 	
               WIP.CASEID              AS CaseKey,
               C.IRN			AS IRN,
               WIP.ACCTCLIENTNO        AS AcctClientKey,
               dbo.fn_FormatNameUsingNameNo(CLIENT.NAMENO, null) as AcctClientName,
               CLIENT.NAMECODE as AcctClientCode,
               WIP.EMPLOYEENO          AS StaffKey,
               dbo.fn_FormatNameUsingNameNo(STAFF.NAMENO, null) as StaffName,
               STAFF.NAMECODE as StaffCode,
               @sLocalCurrencyCode      AS LocalCurrency,
               @nLocalDecimalPlaces     AS LocalDecimalPlaces, 
               WIP.FOREIGNCURRENCY     AS ForeignCurrency,
               
               CUR.DECIMALPLACES	AS ForeignDecimalPlaces,
               
               WIP.FOREIGNVALUE        AS ForeignValue,
               WIP.FOREIGNBALANCE      AS ForeignBalance,
               -- Return Todays Exch Rate
               @nExchangeRate            AS ExchRate,
               
               WIP.LOCALVALUE          AS LocalValue,
               WIP.BALANCE             AS Balance,
               WIP.NARRATIVENO		AS NarrativeKey,
               N.NARRATIVECODE		as NarrativeCode, ' + char(10) +
               dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETITLE',NULL,'N',@sLookupCulture,@pbCalledFromCentura) + ' as NarrativeTitle,' + char(10) +
	       dbo.fn_SqlTranslatedColumn('WORKINPROGRESS','SHORTNARRATIVE','LONGNARRATIVE','WIP',@sLookupCulture,@pbCalledFromCentura) + ' as DebitNoteText,
               WIP.PRODUCTCODE         AS ProductCodeKey,
               PC.DESCRIPTION		AS ProductCodeDescription,
			   @sProfitCentreCode as ProfitCentreCode,
		       @sProfitCentre as ProfitCentre,
		       @nWipProfitCentreSource as WipProfitCentreSource,
               WIP.LOGDATETIMESTAMP    AS LogDateTimeStamp
        FROM   WORKINPROGRESS WIP
        left join NAME STAFF ON (STAFF.NAMENO = WIP.EMPLOYEENO)
        left join NAME EN on (EN.NAMENO = WIP.ENTITYNO)
        left join NAME CLIENT on (CLIENT.NAMENO = WIP.ACCTCLIENTNO)
        left join CASES C ON (C.CASEID = WIP.CASEID)
        left join CASENAME CN on (CN.CASEID = C.CASEID
				   and CN.NAMETYPE = ''I''
				   and (CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate()))	
        left join NAME NI on (NI.NAMENO = ISNULL(CN.NAMENO, WIP.ACCTCLIENTNO))
        left join NARRATIVE N on (N.NARRATIVENO = WIP.NARRATIVENO)
        left join TABLECODES PC on (PC.TABLECODE = WIP.PRODUCTCODE)
        left join CURRENCY CUR ON (CUR.CURRENCY = WIP.FOREIGNCURRENCY)
        
        
        where  WIP.STATUS = 1
	AND WIP.ENTITYNO = @pnEntityKey
	AND WIP.TRANSNO = @pnTransKey
	AND WIP.WIPSEQNO = @pnWIPSeqKey'
        
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nExchangeRate	decimal(11,4),
					@pnEntityKey		int,
					@pnTransKey		int,
					@pnWIPSeqKey		int,
					@sWIPDescription	nvarchar(30),
					@nRequestedByStaffKey	 int,
					@sRequestedByStaffCode nvarchar(20),
					@sRequestedByStaffName nvarchar(326),
					@sLocalCurrencyCode     nvarchar(3),
					@nLocalDecimalPlaces    tinyint,
					@sWipCategoryKey        nvarchar(2),
					@sProfitCentreCode	nvarchar(6),
					@sProfitCentre		nvarchar(50),
					@nWipProfitCentreSource		int',
					@nExchangeRate = @nExchangeRate,
					@pnEntityKey	= @pnEntityKey,	
					@pnTransKey	= @pnTransKey,
					@pnWIPSeqKey	= @pnWIPSeqKey,
					@sWIPDescription = @sWIPDescription,
					@nRequestedByStaffKey = @nRequestedByStaffKey,
					@sRequestedByStaffCode = @sRequestedByStaffCode,
					@sRequestedByStaffName = @sRequestedByStaffName,
					@sLocalCurrencyCode     = @sLocalCurrencyCode,
					@nLocalDecimalPlaces    = @nLocalDecimalPlaces,
					@sWipCategoryKey        = @sWipCategoryKey,
					@sProfitCentreCode =@sProfitCentreCode,
					@sProfitCentre    = @sProfitCentre,
					@nWipProfitCentreSource = @nWipProfitCentreSource
        
End
--sp_help WORKINPROGRESS
RETURN @nErrorCode
GO

Grant execute on dbo.wpw_GetWIPItem  to public
GO