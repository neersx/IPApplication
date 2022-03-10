-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetAdditionalDraftWIPDetails] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetAdditionalDraftWIPDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetAdditionalDraftWIPDetails].'
	drop procedure dbo.[biw_GetAdditionalDraftWIPDetails]
end
print '**** Creating procedure dbo.[biw_GetAdditionalDraftWIPDetails]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go      

create procedure dbo.[biw_GetAdditionalDraftWIPDetails]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnStaffKey		int		= null,
				@psBillCurrency		nvarchar(3) = null,
				@pdtItemDate		datetime = null,
				@psWIPType		nvarchar(6),
				@psWIPCategory		nvarchar(3) = null,
				@pnMainCaseKey		int = null,
				@pnDebtorKey		int = null,
				@psWIPCode		nvarchar(6) = null
as
-- PROCEDURE :	biw_GetAdditionalDraftWIPDetails
-- VERSION :	4
-- DESCRIPTION:	A procedure to return the additional data required by billing wizard for draft wip.
--
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Global Software Solutions Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 21 Dec 2011	AT	RFC11728	1	Procedure created.
-- 13 Feb 2012	AT	RFC11910	2	Return WIP's buy/sell rate.
-- 17 Jan 2013	LP	RFC11614	3	Return WIPTypeDescription and WIPCategoryDescription.
--						Infer WIPTypeDescription and WIPCategoryDescription from WIPCode where specified.
--						Return default ProfitCentreCode and ProfitCentre.
-- 20 Oct 2015  MS      R53933          4       Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

set nocount on

Declare	@nErrorCode	int
Declare @sSQLString nvarchar(max)

-- Data to return
declare @sSignOffName nvarchar(50)
declare @nBuyRate decimal(11,4)
declare @nSellRate decimal(11,4)
declare @sWipTypeDescription nvarchar(50)
declare @sWipCategoryDescription nvarchar(50)
declare @sProfitCentreCode nvarchar(6)
declare @sProfitCentre nvarchar(50)
Declare @nWipProfitCentreSource	int

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select @nWipProfitCentreSource = COLINTEGER
	from SITECONTROL
	where CONTROLID = 'WIP Profit Centre Source'	
	
	Set @sSQLString = "
		    select @sSignOffName = E.SIGNOFFNAME,
		    @sProfitCentreCode = E.PROFITCENTRECODE,
		    @sProfitCentre = " + dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'P',@sLookupCulture,@pbCalledFromCentura) + char(10) +
		    "FROM EMPLOYEE E
		    left join PROFITCENTRE P on (P.PROFITCENTRECODE = E.PROFITCENTRECODE)" +char(10)+
			CASE WHEN @nWipProfitCentreSource = 1 THEN 
			"left join USERIDENTITY U on (U.IDENTITYID = @pnUserIdentityId) where E.EMPLOYEENO = isnull(@pnStaffKey, U.NAMENO)" ELSE 
			"where E.EMPLOYEENO = @pnStaffKey" END

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@sSignOffName	        nvarchar(50) output,
		@sProfitCentreCode	nvarchar(6) output,
		@sProfitCentre		nvarchar(50) output,
		@pnStaffKey		int,
		@pnUserIdentityId	int',
		@sSignOffName           =@sSignOffName output,
		@sProfitCentreCode	=@sProfitCentreCode output,
		@sProfitCentre		=@sProfitCentre output,
		@pnStaffKey		=@pnStaffKey,
		@pnUserIdentityId = @pnUserIdentityId
End

If @nErrorCode = 0
	and @psBillCurrency IS NOT null
	AND @psBillCurrency != ''
Begin	
	Set @nBuyRate = null
	Set @nSellRate = null
	
	exec @nErrorCode = dbo.ac_DoExchangeDetails
		@pnBankRate		= null,
		@pnBuyRate		= @nBuyRate output,
		@pnSellRate		= @nSellRate output,
		@pnDecimalPlaces	= null,
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@psCurrencyCode		= @psBillCurrency,
		@pdtTransactionDate	= @pdtItemDate,
		@pbUseHistoricalRates	= null,
		@psWIPCategory		= @psWIPCategory,
		@pnCaseID		= @pnMainCaseKey,
		@pnNameNo		= @pnDebtorKey,
		@pbIsSupplier		= 0,
		@pnRoundBilledValues	= null,
		@pnAccountingSystemID	= 2,
		@psWIPTypeId		= @psWIPType
End

If @nErrorCode = 0
Begin
	if @psWIPCode is not null
	begin
		Set @sSQLString = "
		SELECT " + char(10) +
		"@sWipTypeDescription = " + dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura) + "," + char(10) +
		"@sWipCategoryDescription = " + dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura) + char(10) +
		"from WIPTEMPLATE W
		left join WIPTYPE WT on (WT.WIPTYPEID = W.WIPTYPEID)
		left join WIPCATEGORY WC on (WC.CATEGORYCODE = WT.CATEGORYCODE)
		where W.WIPCODE = @psWIPCode"
		
		exec @nErrorCode = sp_executesql @sSQLString,
			N'@psWIPCode		nvarchar(6),
			  @sWipTypeDescription	nvarchar(50) output,
			  @sWipCategoryDescription nvarchar(50) output',
			  @psWIPCode		= @psWIPCode,
			  @sWipTypeDescription	= @sWipTypeDescription output,
			  @sWipCategoryDescription = @sWipCategoryDescription output
	end
	else begin
		Set @sSQLString = "
		SELECT " + char(10) +
		"@sWipTypeDescription = " + dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura) + "," + char(10) +
		"@sWipCategoryDescription = " + dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura) + char(10) +
		"from WIPTYPE WT, WIPCATEGORY WC" + char(10) +
		"where WT.WIPTYPEID = @psWIPType" + char(10) +
		"and WC.CATEGORYCODE = @psWIPCategory"
		
		exec @nErrorCode = sp_executesql @sSQLString,
			N'@psWIPType		nvarchar(6),
			  @psWIPCategory	nvarchar(3),
			  @sWipTypeDescription	nvarchar(50) output,
			  @sWipCategoryDescription nvarchar(50) output',
			  @psWIPType		= @psWIPType,
			  @psWIPCategory	= @psWIPCategory,
			  @sWipTypeDescription	= @sWipTypeDescription output,
			  @sWipCategoryDescription = @sWipCategoryDescription output
	end
End

If @nErrorCode = 0
Begin
	-- Return the data
	select @sSignOffName as 'EmployeeSignOffName',
		@nBuyRate as 'BillBuyRate',
		@nSellRate as 'BillSellRate',
		@sProfitCentreCode as 'ProfitCentreCode',
		@sProfitCentre as 'ProfitCentre',
		@sWipTypeDescription as 'WIPTypeDescription',
		@sWipCategoryDescription as 'WIPCategoryDescription'
End

return @nErrorCode
go

grant execute on dbo.[biw_GetAdditionalDraftWIPDetails]  to public
go
