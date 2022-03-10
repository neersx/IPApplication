-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListApplicationBasis
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListApplicationBasis]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListApplicationBasis.'
	Drop procedure [dbo].[ipw_ListApplicationBasis]
	Print '**** Creating Stored Procedure dbo.ipw_ListApplicationBasis...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListApplicationBasis
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListApplicationBasis
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists ApplicationBasis.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 08 Oct 2003  TM	1	Procedure created
-- 15 Sep 2004	JEK	2	RFC886	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture


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
	Select 	B.BASIS 			as 'ApplicationBasisKey',
		"+dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ApplicationBasisDescription'
	from	APPLICATIONBASIS B
	order by 2"
	
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListApplicationBasis to public
GO
