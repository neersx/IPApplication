-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFeesCalculationHeader
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFeesCalculationHeader]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFeesCalculationHeader.'
	Drop procedure [dbo].[csw_ListFeesCalculationHeader]
End
Print '**** Creating Stored Procedure dbo.csw_ListFeesCalculationHeader...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListFeesCalculationHeader
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_ListFeesCalculationHeader
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the header result set for case fees calculation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Dec 2006	JEK	RFC3218	1	Procedure created
-- 14 Dec 2006	JEK	RFC3218 2	Add renewal status.
-- 15 Dec 2006	JEK	RFC3218	3	Add Fees and Charges Elements subject security.
-- 10 Aug 2007	LP	RFC5636	4	Return Age Of Case as 0 instead of NULL.
-- 11 Dec 2008	MF	17136	5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 May 2010	MF	RFC9071	6	Use the highest open cycle to get the NRD and get the Lapse Date 
--					whose Cycle matches the cycle of the NRD.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @bIsExternalUser	bit
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint
Declare	@dtNextRenewalDate 	datetime
Declare	@dtCPARenewalDate	datetime
Declare	@dtRenewalStartDate 	datetime
Declare	@dtExpiryDate 		datetime
Declare	@dtLapseDate 		datetime
Declare	@nYear 			smallint
Declare	@nCycle 		smallint
Declare @dtToday		datetime

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @dtToday=getdate()

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

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Get dates
-- It is safe to hardcode the EventNos for Expiry, and Renewal Start 
If @nErrorCode=0
Begin 
	Set @sSQLString="
	select	@dtRenewalStartDate = CE1.EVENTDATE,
		@dtExpiryDate	    = isnull(CE2.EVENTDATE, CE2.EVENTDUEDATE)
	from CASES C
	left join CASEEVENT CE1		on (CE1.CASEID =C.CASEID
					and CE1.CYCLE  = 1
					and CE1.EVENTNO=-9)
	left join CASEEVENT CE2		on (CE2.CASEID =C.CASEID
					and CE2.CYCLE  = 1
					and CE2.EVENTNO=-12)
	Where C.CASEID = @pnCaseKey"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@dtRenewalStartDate	datetime OUTPUT,
					  @dtExpiryDate		datetime OUTPUT,
					  @pnCaseKey		int',
					  @dtRenewalStartDate=@dtRenewalStartDate 		OUTPUT,
					  @dtExpiryDate      =@dtExpiryDate		OUTPUT,
					  @pnCaseKey         =@pnCaseKey
End


-- Get Next Renewal Date by calling a standard stored procedure.  This will return both 
-- the InProma Next Renewal Date as well as the CPA Renewal Date.
If @nErrorCode=0
Begin 
	Exec @nErrorCode= dbo.cs_GetNextRenewalDate
				@pnCaseKey		=@pnCaseKey,
				@pbCallFromCentura	=0,
				@pdtNextRenewalDate 	=@dtNextRenewalDate	output,
				@pdtCPARenewalDate	=@dtCPARenewalDate	output,
				@pnCycle		=@nCycle		output,
				@pbUseHighestCycle	=1
End

-- Lapse date - event needs to come from site control
-- Split the SELECTS so as to ensure the optimiser chooses an Index SEEK
If  @nErrorCode=0
and @dtNextRenewalDate is not null
Begin 
	Set @sSQLString="
	select @dtLapseDate = isnull(CE3.EVENTDATE,CE3.EVENTDUEDATE)
	from SITECONTROL S
	join CASEEVENT CE1	on (CE1.EVENTNO=-11)
	join CASEEVENT CE3 	on (CE3.CASEID =CE1.CASEID
				and CE3.CYCLE  =CE1.CYCLE
				and CE3.EVENTNO=S.COLINTEGER)
	Where CE1.CASEID = @pnCaseKey
	and isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE)=@dtNextRenewalDate
	and S.CONTROLID='Lapse Event'"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@dtLapseDate  		datetime	OUTPUT,
					  @pnCaseKey			int,
					  @dtNextRenewalDate		datetime',
					  @dtLapseDate			=@dtLapseDate 	OUTPUT,
					  @pnCaseKey			=@pnCaseKey,
					  @dtNextRenewalDate		=@dtNextRenewalDate
End

-- Get the Renewal Year - Age Of Case
-- only do this if there is an Expiry Date as this information is meaningless for
-- Cases that have indefinite lives.
If  @nErrorCode=0
and @dtExpiryDate is not null
Begin
	Exec @nErrorCode = 
		dbo.pt_GetAgeOfCase 
			@pnCaseId           =@pnCaseKey, 
			@pnCycle            =@nCycle, 
			@pdtRenewalStartDate=@dtRenewalStartDate,
			@pdtNextRenewalDate =@dtNextRenewalDate,
			@pnAgeOfCase        =@nYear output,
			@pdtCPARenewalDate  =@dtCPARenewalDate
end

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select	C.CASEID		as CaseKey,"+char(10)+
	"	C.IRN			as CaseReference,"+
	case when @bIsExternalUser=1 then
	"	UC.CLIENTREFERENCENO 	as ClientReference,"
	else
	"	null		 	as ClientReference,"
	end+"
		C.CURRENTOFFICIALNO 	as CurrentOfficialNo,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura)+" as CaseTypeDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+" as CountryName,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+" as PropertyTypeDescription,"+char(10)+
	"CY.CURRENCY			as BillingCurrencyCode,"+char(10)+
	-- Access to local currency equivalents is controlled by subject security
	"case when S.IsAvailable = 1 then @sLocalCurrencyCode else null end"+char(10)+
	"				as LocalCurrencyCode,"+char(10)+
	"case when S.IsAvailable = 1 then @nLocalDecimalPlaces else null end"+char(10)+
	"				as LocalDecimalPlaces,"+char(10)+
	"isnull(@dtCPARenewalDate, @dtNextRenewalDate)"+char(10)+
	"		 		as NextRenewalDate,"+char(10)+
	"@dtExpiryDate 			as ExpiryDate,"+char(10)+
	"@dtLapseDate 			as LapseDate,"+char(10)+
	"isnull(@nYear, 0)		as AgeOfCase,"+char(10)+
	case when @bIsExternalUser=1
		then dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura) 
		else dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura) 
		end+"			as RenewalStatus"+char(10)+
	"from CASES C"+char(10)+
	case when @bIsExternalUser=1 then
		"join dbo.fn_FilterUserCases(@pnUserIdentityId,1,@pnCaseKey) UC	on (UC.CASEID=C.CASEID)"
	end+char(10)+
	"join CASETYPE CS 	on (CS.CASETYPE=C.CASETYPE)"+char(10)+
	"join COUNTRY CT 	on (CT.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
	"join VALIDPROPERTY VP 	on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)"+char(10)+
				"from VALIDPROPERTY VP1"+char(10)+
				"where VP1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"Left Join PROPERTY P		on (P.CASEID=C.CASEID)"+char(10)+
	"Left Join STATUS RS		on (RS.STATUSCODE=P.RENEWALSTATUS)"+char(10)+
	"Left Join CASENAME CN		on (CN.CASEID=C.CASEID"+char(10)+
	"                         	and CN.NAMETYPE='D'"+char(10)+
	"                         	and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate() )"+char(10)+
	"                         	and CN.SEQUENCE=(select min(SEQUENCE) from CASENAME CN2"+char(10)+
	"                    		                                  where CN2.CASEID=CN.CASEID"+char(10)+
	"                     		                                  and CN2.NAMETYPE=CN.NAMETYPE"+char(10)+
	"                      		                                  and(CN2.EXPIRYDATE is null or CN2.EXPIRYDATE>getdate())))"+char(10)+
	"left join IPNAME IP		on (IP.NAMENO=CN.NAMENO)"+char(10)+
	-- If the debtor exists but doesn't have a currency, assume local currency.
	-- However, if the debtor doesn't exist, we don't have a bill currency at all.
	"left join CURRENCY CY		on (CY.CURRENCY=case when IP.NAMENO is not null then isnull(IP.CURRENCY,@sLocalCurrencyCode) else null end)"+char(10)+
	-- Local currency equivalents are only available with Fees and Charges Elements subject security
	"left join dbo.fn_GetTopicSecurity(@pnUserIdentityId,6,@pbCalledFromCentura,@dtToday) S on (S.IsAvailable=1)"+char(10)+
	"WHERE C.CASEID=@pnCaseKey"

	Exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnUserIdentityId	int,
			  @pnCaseKey		int,
			  @sLocalCurrencyCode	nvarchar(3),
			  @nLocalDecimalPlaces	tinyint,
			  @dtNextRenewalDate	datetime,
			  @dtCPARenewalDate	datetime,
			  @dtExpiryDate		datetime,
			  @dtLapseDate		datetime,
			  @nYear		tinyint,
			  @pbCalledFromCentura	bit,
			  @dtToday		datetime',
			  @pnUserIdentityId	= @pnUserIdentityId,
			  @pnCaseKey		= @pnCaseKey,
			  @sLocalCurrencyCode	= @sLocalCurrencyCode,
			  @nLocalDecimalPlaces	= @nLocalDecimalPlaces,
			  @dtNextRenewalDate	= @dtNextRenewalDate,
			  @dtCPARenewalDate	= @dtCPARenewalDate,
			  @dtExpiryDate		= @dtExpiryDate,
			  @dtLapseDate		= @dtLapseDate,
			  @nYear		= @nYear,
			  @pbCalledFromCentura	= @pbCalledFromCentura,
			  @dtToday		= @dtToday
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListFeesCalculationHeader to public
GO
