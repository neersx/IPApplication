-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseFeesAndChargesData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseFeesAndChargesData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseFeesAndChargesData.'
	Drop procedure [dbo].[csw_ListCaseFeesAndChargesData]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseFeesAndChargesData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseFeesAndChargesData
(
	@pnUserIdentityId		int,			-- the user logged on
	@psCulture			nvarchar(10)	= null,
	@pnCaseKey			int,
	@pbIsAllYears			bit		= 0,
	@psCurrencyCode			nvarchar(3)	= null,
	@pnChargeTypeNo			int		= null,
	@pbIncludeHeader		bit		= 1,	-- return the Calculation result set without the header
	@pbCalledFromCentura		bit 		= 0,
	@pnYearNo			int		= 0
)
as
-- PROCEDURE:	csw_ListCaseFeesAndChargesData
-- VERSION:	3
-- DESCRIPTION:	Returns the header information and fees and charges calculations
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Oct 2006	LP	RFC3218	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 27 Oct 2014	KR	R14149	3	Extended to include @pnYearNo

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint
Declare @bIsExternalUser	bit
Declare	@dtNextRenewalDate 		datetime
Declare	@dtExpiryDate 		datetime
Declare	@dtLapseDate 		datetime
Declare @sYourReference		nvarchar(80)
Declare @sBillingCurrencyCode	nvarchar(3)
Declare @nBillingDecimalPlaces	tinyint
Declare @nRowCount		int
Declare @nYearNo		tinyint
Declare @nChargeTypeNo		int
Declare @sRenewalFee		nvarchar(50)
Declare @sChargeTypeDesc 	nvarchar(50)

-- Initialise variables
Set @nErrorCode = 0
Set @sBillingCurrencyCode = NULL

Select @sRenewalFee = COLCHARACTER from SITECONTROL where CONTROLID = 'Renewal Fee'

-- Get Charge Type Description
If @nErrorCode = 0
Begin

	Set @sSQLString="
	Select @sChargeTypeDesc = CT.CHARGEDESC,
	@nChargeTypeNo	= CT.CHARGETYPENO
	from CHARGETYPE CT
	where CT.CHARGETYPENO = 
		(select MIN(Parameter) 
		 from dbo.fn_Tokenise(@sRenewalFee,',') FT)"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sChargeTypeDesc	nvarchar(50) OUTPUT,
					  @nChargeTypeNo	int	OUTPUT,
					  @sRenewalFee		nvarchar(50)',
					  @sChargeTypeDesc      =@sChargeTypeDesc	OUTPUT,
					  @nChargeTypeNo	=@nChargeTypeNo		OUTPUT,
					  @sRenewalFee          =@sRenewalFee

End

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Extract the @bIsExternalUser from UserIdentity
If @nErrorCode=0
Begin		
	Set @sSQLString="
	Select @bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End


-- Extract the @sYourReference for external users
If @nErrorCode = 0
and @bIsExternalUser = 1
Begin
	Set @sSQLString = "
		Select	@sYourReference		= FC.CLIENTREFERENCENO			
		from	dbo.fn_FilterUserCases(@pnUserIdentityId,1,@pnCaseKey) FC"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @pnCaseKey			int,
					  @sYourReference		nvarchar(80)			OUTPUT',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnCaseKey			= @pnCaseKey,
					  @sYourReference		= @sYourReference		OUTPUT					  
End

-- Get dates
-- It is safe to hardcode the EventNos for Expiry, and Renewal Date 
-- Split the SELECTS so as to ensure the optimiser chooses an Index SEEK
If @nErrorCode=0
Begin 
	Set @sSQLString="
	select	@dtExpiryDate	    = isnull(CE2.EVENTDATE, CE2.EVENTDUEDATE)
	from CASES C
	left join CASEEVENT CE2		on (CE2.CASEID =C.CASEID
					and CE2.CYCLE  = 1
					and CE2.EVENTNO=-12)
	Where C.CASEID = @pnCaseKey"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@dtExpiryDate		datetime OUTPUT,
					  @pnCaseKey		int',
					  @dtExpiryDate      =@dtExpiryDate		OUTPUT,
					  @pnCaseKey         =@pnCaseKey
End
-- Set to Next Renewal Date
If @nErrorCode=0
Begin 
	Set @sSQLString="
	select	@dtNextRenewalDate = CE3.EVENTDATE
	from CASES C
	left join CASEEVENT CE3 	on (CE3.CASEID =C.CASEID
					and CE3.CYCLE  = 1
					and CE3.EVENTNO=-11)
	Where C.CASEID = @pnCaseKey"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@dtNextRenewalDate  		datetime	OUTPUT,
					  @pnCaseKey			int',
					  @dtNextRenewalDate		=@dtNextRenewalDate OUTPUT,
					  @pnCaseKey         		=@pnCaseKey
End

If @nErrorCode=0
Begin 
	Set @sSQLString="
	select	@dtLapseDate = CE3.EVENTDATE
	from CASES C
	left join CASEEVENT CE3 	on (CE3.CASEID =C.CASEID
					and CE3.CYCLE  = 1
					and CE3.EVENTNO=-108)
	Where C.CASEID = @pnCaseKey"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@dtLapseDate  		datetime	OUTPUT,
					  @pnCaseKey			int',
					  @dtLapseDate			=@dtLapseDate 	OUTPUT,
					  @pnCaseKey			=@pnCaseKey
End

-- Set the Billing Currency Code
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select @sBillingCurrencyCode = CASE WHEN (NT.COLUMNFLAGS&69=69 AND @bIsExternalUser=0) THEN IP.CURRENCY END " +char(10)+
	"from CASENAME CN"+char(10)+
	"left join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@psCulture,@bIsExternalUser,@pbCalledFromCentura) NT"+char(10)+
	"on (NT.NAMETYPE='D')"+char(10)+
	"left join IPNAME IP on (IP.NAMENO=CN.NAMENO)"+char(10)+
	"where CN.CASEID = @pnCaseKey
	and CN.NAMETYPE = 'D'"	

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
				@sBillingCurrencyCode	nvarchar(3) OUTPUT,
				@bIsExternalUser	bit,
				@pnUserIdentityId	int,
				@psCulture		nvarchar(10),
				@pbCalledFromCentura	bit,
				@pnCaseKey		int',
				@sBillingCurrencyCode	= @sBillingCurrencyCode OUTPUT,
				@bIsExternalUser	= @bIsExternalUser,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@pnCaseKey		= @pnCaseKey

End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select  @nBillingDecimalPlaces = case when W.COLBOOLEAN = 1 then 0 else isnull(CY.DECIMALPLACES,2) end
	from	CURRENCY CY
	left join SITECONTROL W on (W.CONTROLID = 'Currency Whole Units')
	where CY.CURRENCY = @sBillingCurrencyCode"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
				@nBillingDecimalPlaces	tinyint		OUTPUT,
				@sBillingCurrencyCode	nvarchar(3)',
				@nBillingDecimalPlaces	= @nBillingDecimalPlaces	OUTPUT,
				@sBillingCurrencyCode	= @sBillingCurrencyCode
End


-- Get Header result set

If @nErrorCode = 0
and @pbIncludeHeader = 1
Begin
	Set @sSQLString=
	"Select"+char(10)+
	"C.CASEID as CaseKey,"+char(10)+
	"C.IRN as CaseReference,"+char(10)+
	"@sYourReference as ClientReference,"+char(10)+
	"C.CURRENTOFFICIALNO as CurrentOfficialNo,"+char(10)+
	"CO.COUNTRY as CountryName,"+char(10)+
	"CT.CASETYPEDESC as CaseTypeDescription,"+char(10)+
	"PT.PROPERTYNAME as PropertyTypeDescription,"+char(10)+
	"@pbIsAllYears as IsAllYears,"+char(10)+
	"ISNULL(@psCurrencyCode,@sBillingCurrencyCode) as RequestedCurrencyCode,"+char(10)+
	"@sLocalCurrencyCode as LocalCurrencyCode,"+char(10)+
	"@nLocalDecimalPlaces as LocalDecimalPlaces,"+char(10)+
	"@sBillingCurrencyCode as BillingCurrencyCode,"+char(10)+
	"@nBillingDecimalPlaces as BillingDecimalPlaces,"+char(10)+
	"ISNULL(@pnChargeTypeNo,@nChargeTypeNo)as ChargeTypeKey,"+char(10)+
	"@sChargeTypeDesc as ChargeTypeDescription,"+char(10)+
	"@dtNextRenewalDate as RenewalDate,"+char(10)+
	"@dtExpiryDate as ExpiryDate,"+char(10)+
	"@dtLapseDate as LapseDate" +char(10)+ 
	"from CASES C"+char(10)+
	"left join CASENAME CN on (C.CASEID = CN.CASEID)"+char(10)+
	"left join COUNTRY CO on (CO.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
	"left join CASETYPE CT on (CT.CASETYPE=C.CASETYPE)"+char(10)+
	"left join PROPERTYTYPE PT on (PT.PROPERTYTYPE=C.PROPERTYTYPE)"+char(10)+
	"where C.CASEID = @pnCaseKey
	and CN.NAMETYPE = 'D'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnUserIdentityId	int,
				@psCulture		nvarchar(10),
				@pbCalledFromCentura	bit,
				@pnCaseKey		int,
				@bIsExternalUser	bit,
				@pbIsAllYears		bit,
				@sYourReference		nvarchar(80),
				@psCurrencyCode		nvarchar(3),
				@sLocalCurrencyCode	nvarchar(3),
				@nLocalDecimalPlaces	tinyint,
				@nBillingDecimalPlaces	tinyint,
				@sBillingCurrencyCode	nvarchar(3),
				@pnChargeTypeNo		int,
				@nChargeTypeNo		int,
				@sChargeTypeDesc	nvarchar(50),
				@dtNextRenewalDate	datetime,
				@dtExpiryDate		datetime,
				@dtLapseDate		datetime',
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@pnCaseKey		= @pnCaseKey,
				@bIsExternalUser	= @bIsExternalUser,
				@pbIsAllYears		= @pbIsAllYears,
				@sYourReference		= @sYourReference,
				@psCurrencyCode		= @psCurrencyCode,
				@sLocalCurrencyCode	= @sLocalCurrencyCode,
				@nLocalDecimalPlaces	= @nLocalDecimalPlaces,
				@nBillingDecimalPlaces	= @nBillingDecimalPlaces,
				@sBillingCurrencyCode	= @sBillingCurrencyCode,
				@pnChargeTypeNo		= @pnChargeTypeNo,
				@nChargeTypeNo		= @nChargeTypeNo,
				@sChargeTypeDesc	= @sChargeTypeDesc,
				@dtNextRenewalDate	= @dtNextRenewalDate,
				@dtExpiryDate		= @dtExpiryDate,
				@dtLapseDate		= @dtLapseDate
	

End



-- Get Renewal Fees Calculations result sets

If @nErrorCode = 0
and @psCurrencyCode is not null
and @pnChargeTypeNo is not null
and @pbIsAllYears = 0
Begin
	If @pnYearNo != 0
	Begin
		Set @nYearNo = @pnYearNo	
	End
	Else Begin
		exec @nErrorCode = dbo.pt_GetAgeOfCase 
			@pnCaseId           =@pnCaseKey, 
			@pnCycle            =null, 
			@pdtRenewalStartDate=null,
			@pdtNextRenewalDate =null,
			@pnAgeOfCase        =@nYearNo output,
			@pdtCPARenewalDate  =null
	End

	If @nErrorCode = 0
	Begin
		
		exec @nErrorCode = dbo.cs_ListCaseCharges
				@pnRowCount		= @nRowCount 		OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,			
				@pnCaseId		= @pnCaseKey,
				@pnYearNo		= @nYearNo,
				@pnChargeTypeNo		= @pnChargeTypeNo,
				@pbCalledFromCentura	= 0,
				@psCurrency		= @psCurrencyCode

	End

End

If @nErrorCode = 0
and @psCurrencyCode is not null
and @pnChargeTypeNo is not null
and @pbIsAllYears = 1
Begin
	
	exec @nErrorCode = dbo.cs_ListCaseCharges
			@pnRowCount		= @nRowCount 		OUTPUT,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,			
			@pnCaseId		= @pnCaseKey,
			@pnYearNo		= null,
			@pnChargeTypeNo		= @pnChargeTypeNo,
			@pbCalledFromCentura	= 0,
			@psCurrency		= @psCurrencyCode

End


Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseFeesAndChargesData to public
GO
