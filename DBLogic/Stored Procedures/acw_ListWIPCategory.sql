-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListWIPCategory
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListWIPCategory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListWIPCategory.'
	Drop procedure [dbo].[acw_ListWIPCategory]
	Print '**** Creating Stored Procedure dbo.acw_ListWIPCategory...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListWIPCategory
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	acw_ListWIPCategory
-- VERSION:	1
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns list of WIP Categories

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10-Feb-2010	MS	RFC8607	1	Procedure created.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@nErrorCode		int
Declare	@sSQLString		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nErrorCode      = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select 	CATEGORYCODE  as 'WIPCategoryCode',
		"+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,null,@sLookupCulture,@pbCalledFromCentura)
			+ " as 'WIPCategoryDescription'
	from	WIPCATEGORY 
	order by 2"

	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount

End

RETURN @nErrorCode
GO

Grant execute on dbo.acw_ListWIPCategory to public
GO
