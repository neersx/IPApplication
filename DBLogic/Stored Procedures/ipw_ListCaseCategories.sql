---------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListCaseCategories
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListCaseCategories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListCaseCategories.'
	drop procedure [dbo].[ipw_ListCaseCategories]
	Print '**** Creating Stored Procedure dbo.ipw_ListCaseCategories...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListCaseCategories
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListProperties
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Case Categories.

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
	Select 	distinct
		C.CASECATEGORY		as 'CaseCategoryKey',
		"+dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'CaseCategoryDescription'
	from 	CASECATEGORY C
	order by 2"

	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant exec on dbo.ipw_ListCaseCategories to public
GO
