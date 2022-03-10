-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListTextTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListTextTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListTextTypes.'
	Drop procedure [dbo].[ipw_ListTextTypes]
	Print '**** Creating Stored Procedure dbo.ipw_ListTextTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListTextTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsExternalUser	bit		= null,
	@pbIsCaseOnly		bit		= 1
)
AS
-- PROCEDURE:	ipw_ListTextTypes
-- VERSION:	7
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Text Types that the currently logged on user
--		identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 08 Oct 2003  TM		1	Procedure created
-- 19-Feb-2004	TM	RFC976	2	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 09 Sep 2004	JEK	RFC886	3	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 15 May 2005  JEK	RFC2508	4	Pass @sLookupCulture to fn_FilterUserXxx.
-- 04 Dec 2006  PG	RFC3646	5	Pass @pbIsExternalUser to fn_FilterUserXxx.
-- 04 Aug 2010  DV	RFC9526 6	Restrict the Text Types where USEDBYFLAG is 0 or null
-- 11 Apr 2013	DV	R13319	7	Use site control Allow All Text Types for Cases for restricting Cases

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

Declare @bAllowAllTextTypes bit

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
		SELECT @bAllowAllTextTypes = ISNULL(SC.COLBOOLEAN,0)
		FROM SITECONTROL SC 
		WHERE SC.CONTROLID = 'Allow All Text Types For Cases'"

		exec @nErrorCode =	sp_executesql @sSQLString,
					N'@bAllowAllTextTypes	bit 		output',
	  				@bAllowAllTextTypes	= @bAllowAllTextTypes 	output
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	TEXTTYPE 	as TextTypeKey, 
		TEXTDESCRIPTION as TextTypeDescription
	from dbo.fn_FilterUserTextTypes(@pnUserIdentityId,@sLookupCulture, @pbIsExternalUser,@pbCalledFromCentura)"
	+CASE WHEN(@pbIsCaseOnly=1 and @bAllowAllTextTypes = 0)
	THEN +char(10)+" where USEDBYFLAG is null or USEDBYFLAG = 0" END 
	+char(10)+ "order by TEXTDESCRIPTION"
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10),
					  @pbIsExternalUser	bit,
					  @pbCalledFromCentura	bit',
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbIsExternalUser	= @pbIsExternalUser,
					  @pbCalledFromCentura	= @pbCalledFromCentura

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListTextTypes to public
GO
