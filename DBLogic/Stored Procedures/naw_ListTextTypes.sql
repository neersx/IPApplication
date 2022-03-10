-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListTextTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListTextTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListTextTypes.'
	Drop procedure [dbo].[naw_ListTextTypes]
	Print '**** Creating Stored Procedure dbo.naw_ListTextTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListTextTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	naw_ListTextTypes
-- VERSION:	4
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Text Types that the currently logged on user
--		identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Dec-2003	TM	RFC611	1	Procedure created
-- 19-Feb-2004	TM	RFC976	2	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 09 Sep 2004	JEK	RFC886	3	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 15 May 2005  JEK	RFC2508	4	Pass @sLookupCulture to fn_FilterUserXxx.


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
	Set @sSQLString = "
	Select 	TEXTTYPE 	as 'TextTypeKey', 
		TEXTDESCRIPTION as 'TextTypeDescription'
	-- Let the function dbo.fn_FilterUserTextTypes determine if the user is internal
	-- or external by passing null as the @pbIsExternalUser  
	from dbo.fn_FilterUserTextTypes(@pnUserIdentityId,@sLookupCulture, null,@pbCalledFromCentura)
	where USEDBYFLAG > 0
	order by TEXTDESCRIPTION"
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit',
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListTextTypes to public
GO
