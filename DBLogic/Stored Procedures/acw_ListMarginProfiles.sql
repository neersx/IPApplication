-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListMarginProfiles
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListMarginProfiles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListMarginProfiles.'
	Drop procedure [dbo].[acw_ListMarginProfiles]
	Print '**** Creating Stored Procedure dbo.acw_ListMarginProfiles...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListMarginProfiles
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psWIPCategoryCode	nvarchar(3)	= null
)
AS
-- PROCEDURE:	acw_ListMarginProfiles
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of available margin profiles.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 17 Mar 2010	MS	RFC3298	1	Procedure created.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(1000)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "select
			M.MARGINPROFILENO	as 'MarginProfileKey',
			"+dbo.fn_SqlTranslatedColumn('MARGINPROFILE','PROFILENAME',null,'M',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'MarginProfileDescription', 
			W.CATEGORYCODE		as 'WIPCategoryCode',
			"+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'WIPCategory' 
			from MARGINPROFILE M
			join WIPCATEGORY W on (W.CATEGORYCODE = M.CATEGORYCODE)"
			
	If @psWIPCategoryCode is not null
	Begin
		Set @sSQLString = @sSQLString  + CHAR(10) + "Where M.CATEGORYCODE = @psWIPCategoryCode"
	End
			
	Set @sSQLString = @sSQLString + CHAR(10) + "Order by 2"

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@psWIPCategoryCode	nvarchar(3)',
		@psWIPCategoryCode	= @psWIPCategoryCode		
	
	Set @pnRowCount = @@Rowcount

End
Return @nErrorCode
GO

Grant execute on dbo.acw_ListMarginProfiles to public
GO
