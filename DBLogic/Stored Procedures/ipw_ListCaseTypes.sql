-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListCaseTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListCaseTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListCaseTypes.'
	Drop procedure [dbo].[ipw_ListCaseTypes]
	Print '**** Creating Stored Procedure dbo.ipw_ListCaseTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListCaseTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsExternalUser       bit 		= null,
	@pbIncludeCRM		bit		= 0,
	@pnCaseAccessMode	int		= 1 /* 0=Return All, 1=Select, 4=insert, 8=update */
)
AS
-- PROCEDURE:	ipw_ListCaseTypes
-- VERSION:	13
-- SCOPE:	Inpro.Net

-- DESCRIPTION:	Returns a list of Case Types that the currently logged on user
--		identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Details
-- ----		---	-------	-------	-------------------------------------
-- 08 Oct 2003  TM		1	Procedure created
-- 19-Feb-2004	TM	RFC976	2	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 09 Sep 2004	JEK	RFC886	3	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 15 May 2005  JEK	RFC2508	4	Pass @sLookupCulture to fn_FilterUserXxx.
-- 01 Dec 2006  PG      RFC3646 5       Pass @pbIsExternalUser to fn_filterUserXxx.
-- 15 Jul 2008	AT	RFC5749	6	Filter out CRM Case Types.
-- 12 Dec 2008	AT	RFC7365	7	Added date to Case Type filter for license check. 
-- 29 Jan 2008	AT	RFC7173 8	Enable the return of CRM Case Types if requested.
-- 18 Aug 2009	ASH	RFC7901 9	Populate only Case Types which have  null value in ACTUALCASETYPE field.
-- 11 Nov 2009	LP	RFC6712	10	Filter CaseTypes based on AccessMode, if specified.
-- 11 Dec 2012	LP	R11555	11	Allow capability to disregard case row-level access and return all Case Types
-- 03 Jul 2014	LP	R33261	12	"Best-fit" logic is not required. Case Type is valid as long as the user
--					has at least one row-access profile that deems it available.
-- 09 Jun 2016	LP	R54764	13	External Users do not require row-level access security.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(max)
Declare @dtToday	datetime

Declare @sLookupCulture		nvarchar(10)
Declare @bHasRowAccessSecurity	bit
Declare @sOfficeFilter		nvarchar(1000)
Declare @bColboolean		bit


set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set 	@dtToday 	 = getdate()
Set	@bHasRowAccessSecurity = 0
Set	@bColboolean	= 0

If @nErrorCode = 0
Begin	
	If @pbIsExternalUser is null
	Begin		
		Set @sSQLString='
		Select @pbIsExternalUser=ISEXTERNALUSER
		from USERIDENTITY
		where IDENTITYID=@pnUserIdentityId'
		
		Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@pbIsExternalUser	bit	OUTPUT,
					  @pnUserIdentityId	int',
					  @pbIsExternalUser	=@pbIsExternalUser	OUTPUT,
					  @pnUserIdentityId	=@pnUserIdentityId
	End
End

-- Activate Row-Access Security 
-- if there are any Row-Access Profiles assigned to any Web user
If @nErrorCode = 0
and @pnCaseAccessMode > 0
and exists (Select 1	from IDENTITYROWACCESS U WITH (NOLOCK) 
			join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
			where R.RECORDTYPE = 'C')
Begin
	Set @bHasRowAccessSecurity = 1	
End

If @nErrorCode = 0
Begin
	
	Set @sSQLString = "
	Select 	FC.CASETYPE 	as 'CaseTypeKey', 
		FC.CASETYPEDESC 	as 'CaseTypeDescription'
	from dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,@sLookupCulture, @pbIsExternalUser,@pbCalledFromCentura, @dtToday) FC"
	If @bHasRowAccessSecurity = 1 and @pbIsExternalUser = 0
	Begin
		Set @sSQLString = @sSQLString + CHAR(10) +
		"join (
			Select DISTINCT R.CASETYPE as CASETYPE
			From  IDENTITYROWACCESS U, ROWACCESSDETAIL R  
			Where U.IDENTITYID = @pnUserIdentityId  
			And R.ACCESSNAME= U.ACCESSNAME  
			And R.RECORDTYPE = 'C'  
			And R.CASETYPE IS NOT NULL
			And R.SECURITYFLAG & @pnCaseAccessMode = @pnCaseAccessMode		  
			UNION  
			Select C.CASETYPE  
			From CASETYPE C  
			Where  exists  (
			select * from IDENTITYROWACCESS U, ROWACCESSDETAIL R  
			Where U.IDENTITYID = @pnUserIdentityId  
			And R.ACCESSNAME= U.ACCESSNAME  
			And R.RECORDTYPE = 'C'  
			And R.SECURITYFLAG & @pnCaseAccessMode = @pnCaseAccessMode
			And R.CASETYPE is NULL)
		) CX on (CX.CASETYPE = FC.CASETYPE)"
	End	
	if (@pbIncludeCRM=0)
	Begin
		Set @sSQLString = @sSQLString +char(10)+"where FC.CASETYPE not in (select CASETYPE from CASETYPE where CRMONLY = 1 or ACTUALCASETYPE is not null)"
	End
	Else
	Begin
		Set @sSQLString = @sSQLString +char(10)+"where FC.CASETYPE not in (select CASETYPE from CASETYPE where ACTUALCASETYPE is not null)"
	End
	
	Set @sSQLString = @sSQLString +char(10)+ "order by FC.CASETYPEDESC"
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10),
					  @pbIsExternalUser	bit,
					  @pbCalledFromCentura	bit,
					  @dtToday		datetime,
					  @pnCaseAccessMode	int',
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbIsExternalUser	= @pbIsExternalUser,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @dtToday		= @dtToday,
					  @pnCaseAccessMode	= @pnCaseAccessMode
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListCaseTypes to public
GO
