-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListValidProperties
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListValidProperties]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListValidProperties.'
	Drop procedure [dbo].[ipw_ListValidProperties]
	Print '**** Creating Stored Procedure dbo.ipw_ListValidProperties...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListValidProperties
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseAccessMode	int		= 1 /* 0=Return All, 1=Select, 4=insert, 8=update */
)
AS
-- PROCEDURE:	ipw_ListValidProperties
-- VERSION:	9
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Valid Property Types.

-- MODIFICATIONS :
-- Date		Who	Version	Number	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 08 Oct 2003  TM	1		Procedure created
-- 15 Sep 2004	JEK	2	RFC886	Implement translation.
-- 15 May 2005	JEK	3	RFC2508	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 08 May 2009	AT	4	Exclude CRM Property types.
-- 13 Nov 2009	LP	5	RFC6712	Implement row access security based on @pnCaseAccessMode
-- 04 Dec 2012	LP	6	R11555	Fix row-level access security check as it fails when security permission exceeds 10
-- 11 Dec 2012	LP	7	R11555	Allow capability to disregard case row-level access and return all property types
-- 30 Jun 2014	LP	8	R33261	If there is at least one Row Access Profile granting Insert rights that does not have a Property Type
--					then all Property Types should be returned when for Insert access mode, i.e. @pnCaseAccessMode = 4
--					The same should apply for Update rights and Update access mode, i.e. @pnCaseAccessMode = 8.
-- 23 Aug 2016	MF	9	65017	Row-level access is only to be applied to internal users.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(max)

Declare @sLookupCulture		nvarchar(10)
Declare @bHasRowAccessSecurity	bit
Declare @sOfficeFilter		nvarchar(1000)
Declare @bColboolean		bit

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set	@bHasRowAccessSecurity = 0
Set	@bColboolean	= 0

-- Activate Row-Access Security 
-- if there are any Row-Access Profiles assigned to any Web user and
-- the current user is internal.
If @nErrorCode = 0
and @pnCaseAccessMode > 0
and exists (Select 1	from IDENTITYROWACCESS U WITH (NOLOCK) 
			join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
			join USERIDENTITY I    WITH (NOLOCK) on (I.IDENTITYID=@pnUserIdentityId
							     and isnull(I.ISEXTERNALUSER,0)=0)
			where R.RECORDTYPE = 'C')
Begin
	Set @bHasRowAccessSecurity = 1	
End


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	P.PROPERTYTYPE 	 as 'PropertyTypeKey',
		"+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'PropertyTypeDescription',
		P.COUNTRYCODE  	 as  'CountryKey',
		CASE P.COUNTRYCODE WHEN 'ZZZ' THEN 1 ELSE 0 END
				 as IsDefaultCountry
	from VALIDPROPERTY P
	join PROPERTYTYPE PT on (PT.PROPERTYTYPE = P.PROPERTYTYPE)"
	If @bHasRowAccessSecurity = 1
	Begin
		Set @sSQLString = @sSQLString + 
		"join (
			Select DISTINCT R.PROPERTYTYPE as PROPERTYTYPE
			From  IDENTITYROWACCESS U, ROWACCESSDETAIL R  
			Where U.IDENTITYID = @pnUserIdentityId  
			And R.ACCESSNAME= U.ACCESSNAME  
			And R.RECORDTYPE = 'C'  
			And R.PROPERTYTYPE IS NOT NULL
			And R.SECURITYFLAG & @pnCaseAccessMode = @pnCaseAccessMode		  
			UNION  
			Select PT.PROPERTYTYPE  
			From PROPERTYTYPE PT  
			Where  exists  (
			select * from IDENTITYROWACCESS U, ROWACCESSDETAIL R  
			Where U.IDENTITYID = @pnUserIdentityId  
			And R.ACCESSNAME= U.ACCESSNAME  
			And R.RECORDTYPE = 'C'  
			And R.SECURITYFLAG & @pnCaseAccessMode = @pnCaseAccessMode
			And R.PROPERTYTYPE is NULL)
		) PTX on (PTX.PROPERTYTYPE = P.PROPERTYTYPE)
		where (PT.CRMONLY = 0 or PT.CRMONLY is null)"
	End	
	Set @sSQLString = @sSQLString +char(10)+"order by PropertyTypeDescription"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCaseAccessMode	int,
			@pnUserIdentityId	int',
			@pnCaseAccessMode	= @pnCaseAccessMode,
			@pnUserIdentityId	= @pnUserIdentityId
	
	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListValidProperties to public
GO
