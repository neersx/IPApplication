-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListValidCategories
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListValidCategories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure dbo.ipw_ListValidCategories.'
	drop procedure [dbo].[ipw_ListValidCategories]
	print '**** Creating Stored Procedure dbo.ipw_ListValidCategories...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListValidCategories
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListValidCategories
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Valid Categories.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 08 Oct 2003  TM	1	Procedure created
-- 15 Sep 2004	JEK	2	RFC886	Implement translation.
-- 15 May 2005	JEK	3	RFC2508	Extract @sLookupCulture and pass to translation instead of @psCulture


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
	select 	C.CASECATEGORY 		as 'CaseCategoryKey',
		"+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'CaseCategoryDescription',
		C.COUNTRYCODE 		as 'CountryKey',
		CASE C.COUNTRYCODE WHEN 'ZZZ' THEN 1 ELSE 0 END 
					as 'IsDefaultCountry',
		C.PROPERTYTYPE 		as 'PropertyTypeKey',
		C.CASETYPE 		as 'CaseTypeKey'
	from	VALIDCATEGORY C
	order by CaseCategoryDescription"

	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListValidCategories to public
GO
