-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListProperties
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListProperties.'
	Drop procedure [dbo].[ipw_ListProperties]
	Print '**** Creating Stored Procedure dbo.ipw_ListProperties...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListProperties
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIncludeCRM		bit		= 0,
	@pnCaseAccessMode	int		= 1 /* 0=Return All, 1=Select, 4=insert, 8=update */
)
AS
-- PROCEDURE:	ipw_ListProperties
-- VERSION:	11
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Property Types.

-- MODIFICATIONS :
-- Date		Who	Change  Version	Description
-- ------------	-------	------- -------	----------------------------------------------- 
-- 08 Oct 2003  TM	        1	Procedure created
-- 09 Sep 2004	JEK	RFC1695 2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 15 Oct 2008  LP      RFC7128 4       Filter out CRM Property Types.
-- 29 Jan 2008	AT	RFC7173 5	Enable the return of CRM Property Types if requested.
-- 07 Apr 2009	NG	RFC6921	6	Filter Property Types depending upon user license.
-- 13 Nov 2009	LP	RFC6712	7	Implement row access based on @pnCaseAccessMode
-- 04 Dec 2012	LP	R11555	8	Fix row-level access security check as it fails when security permission exceeds 10
-- 11 Dec 2012	LP	R11555	9	Allow capability to disregard case row-level access and return all property types
-- 02 Oct 2014	LP	R9422	10	Cater for Marketing Module license.
-- 20 Nov 2014	LP	R41712	11	Corrected license number for Marketing Module (Pricing Model 2)


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

Declare @bNonCRMLicense	bit	
Declare @bCRMLicense		bit
Declare @dtToday	datetime
Declare @bHasRowAccessSecurity	bit
Declare @sOfficeFilter		nvarchar(1000)
Declare @bColboolean		bit
Declare @CRMWorkBenchLicense	int
Declare @MarketingModuleLicense int

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set 	@dtToday 	 = getdate()
Set	@bNonCRMLicense	= 0	
Set	@bCRMLicense	= 0
Set	@bHasRowAccessSecurity = 0
Set	@bColboolean	= 0
Set	@CRMWorkBenchLicense = 25
Set	@MarketingModuleLicense = 32

If @nErrorCode = 0
and @pnCaseAccessMode > 0
Begin
	Set @sSQLString="Select @bHasRowAccessSecurity = 1
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @pnUserIdentityId"
	
	Exec  @nErrorCode=sp_executesql @sSQLString,
		N'@bHasRowAccessSecurity	bit	OUTPUT,
		  @pnUserIdentityId	int',
		  @bHasRowAccessSecurity	=@bHasRowAccessSecurity	OUTPUT,
		  @pnUserIdentityId	=@pnUserIdentityId
End


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	P.PROPERTYTYPE as PropertyTypeKey,
		"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as PropertyTypeDescription
	from 	PROPERTYTYPE P where 1=1 "
	
	If @nErrorCode = 0 and (@pbCalledFromCentura = 0 or @pbCalledFromCentura is null)
	Begin
		If exists (select 1 from dbo.fn_LicensedModules(@pnUserIdentityId,@dtToday) LM
							join LICENSEMODULE M ON M.MODULEID = LM.MODULEID
							where M.MODULEFLAG = 4
							and M.MODULEID not in (@CRMWorkBenchLicense,@MarketingModuleLicense))
		Begin
			Set @bNonCRMLicense = 1
		End

		If dbo.fn_IsLicensedForCRM(@pnUserIdentityId, @dtToday)=1
		Begin
			Set @bCRMLicense = 1
		End

		If @bCRMLicense = 1 and @bNonCRMLicense = 0
		Begin
			Set @sSQLString = @sSQLString +char(10)+ " and P.CRMONLY = 1"
		End
		Else if @bCRMLicense = 0 and @bNonCRMLicense = 1
		Begin
			Set @sSQLString = @sSQLString +char(10)+ " and (P.CRMONLY = 0 or P.CRMONLY is null)"
		End
	End

	if (@pbIncludeCRM=0)
	Begin
		Set @sSQLString = @sSQLString +char(10)+" and   P.PROPERTYTYPE not in (select PROPERTYTYPE from PROPERTYTYPE where CRMONLY = 1)"
	End
	
	If @bHasRowAccessSecurity = 1
	Begin
		Set @sSQLString = @sSQLString + " and convert(int,Substring("
		+char(10)+"		(Select MAX (   CASE when XRAD.OFFICE       is null then '0' else '1' end +"
		+char(10)+"				CASE when XRAD.CASETYPE     is null then '0' else '1' end +"
		+char(10)+"				CASE when XRAD.PROPERTYTYPE is null then '0' else '1' end +"								
		+char(10)+"				CASE when XRAD.SECURITYFLAG < 10    then '0' else ''  end +"
		+char(10)+"				convert(nvarchar(2),XRAD.SECURITYFLAG)"
		+char(10)+"			)"
		+char(10)+"		from IDENTITYROWACCESS XIA"
		+char(10)+"		join ROWACCESSDETAIL XRAD	on  (XRAD.ACCESSNAME   = XIA.ACCESSNAME 
									and  XRAD.RECORDTYPE = 'C' 
									and  (XRAD.PROPERTYTYPE = P.PROPERTYTYPE or XRAD.PROPERTYTYPE IS NULL))"
		+char(10)+"		join USERIDENTITY XUI on (XUI.IDENTITYID = XIA.IDENTITYID)"
		+char(10)+"		where XIA.IDENTITYID=" + convert(varchar,@pnUserIdentityId)
		+char(10)+"		),4,2)) & @pnCaseAccessMode = @pnCaseAccessMode"
	End
	
	Set @sSQLString = @sSQLString +char(10)+"order by PropertyTypeDescription"
	
	Exec  @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseAccessMode	int',
		  @pnCaseAccessMode	=@pnCaseAccessMode
	
End




Return @nErrorCode
GO

Grant execute on dbo.ipw_ListProperties to public
GO
