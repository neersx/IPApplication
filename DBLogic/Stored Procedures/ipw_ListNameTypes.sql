-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListNameTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListNameTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListNameTypes.'
	Drop procedure [dbo].[ipw_ListNameTypes]
	Print '**** Creating Stored Procedure dbo.ipw_ListNameTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListNameTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbIsUsedByStaff 	bit		= null,	
	@pbExcludeCRM		bit		= 0, -- default is 0 means returns all name types including CRM Name Types 
	@pbIsCRMOnly	 	bit		= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsExternalUser	bit		= null
)
AS
-- PROCEDURE:	ipw_ListNameTypes
-- VERSION:	12
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Name Types that the currently logged on user
--		identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATIONS :
--- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	---------------------------------------------- 
-- 08 Oct 2003  TM		1	Procedure created
-- 11 Feb 2004	TM		2	Sort on DESCRIPTION instead of NAMETYPE.
-- 17 Feb 2004	TM		3	Implement a new optional @pbIsUsedByStaff bit parameter. When @pbIsUsedByStaff = 1 
--					return NameTypes where PICKLISTFLAGS & 2 = 2.
-- 19-Feb-2004	TM	RFC976	4	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 09 Sep 2004	JEK	RFC886	5	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 15 May 2005  JEK	RFC2508	6	Pass @sLookupCulture to fn_FilterUserXxx.
-- 04 Dec 2006  PG  	RFC3646 7	Pass @pbIsExternalUser to fn_filterUserXxx.
-- 11 Dec 2008	AT	RFC7365	8	Filter out CRM name types for non-crm licensed users
-- 22 Jun 2009	PA	RFC7494	9	Implement a new optional @pbExcludeCRM bit parameter to return non-CRM Name Types(if @pbExcludeCRM = 1)
-- 06 Jul 2009	MS	RFC7085	10	Filter out Non-CRM name types for crm only licensed users
-- 01 Oct 2014	LP	R9422	11	Cater for Marketing Module license.
-- 17 May 2016	MF	13471	12	When returning Staff Name Types, exclude Name Types used as Ethical Wall to block access.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0


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

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	NAMETYPE 	as NameTypeKey,
		DESCRIPTION 	as NameTypeDescription
	from dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture, @pbIsExternalUser,@pbCalledFromCentura)"
	+ char(10) + "where 1=1" + char(10) +
	CASE WHEN @pbIsUsedByStaff = 1 THEN char(10) + "	and PICKLISTFLAGS & 2 = 2"
					   +CHAR(10) + "	and ETHICALWALL in (0,1)"
	END +
	CASE WHEN dbo.fn_IsLicensedForCRM(@pnUserIdentityId, getdate())= 0
		OR @pbExcludeCRM = 1 THEN char(10) + "	and PICKLISTFLAGS & 32 != 32" END 
	+ CASE WHEN @pbIsCRMOnly = 1 THEN char(10) + "  and PICKLISTFLAGS & 32 = 32" END
	+ char(10) + "	order by DESCRIPTION"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10),
					  @pbIsExternalUser	bit,
					  @pbCalledFromCentura	bit,
					  @pbExcludeCRM	bit',					  
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbIsExternalUser	= @pbIsExternalUser,
					  @pbExcludeCRM		= @pbExcludeCRM,
					  @pbCalledFromCentura	= @pbCalledFromCentura

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListNameTypes to public
GO
