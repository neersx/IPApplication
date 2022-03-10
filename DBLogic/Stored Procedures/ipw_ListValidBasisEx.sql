-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListValidBasisEx
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListValidBasisEx]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListValidBasisEx.'
	Drop procedure [dbo].[ipw_ListValidBasisEx]
	Print '**** Creating Stored Procedure dbo.ipw_ListValidBasisEx...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListValidBasisEx
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListValidBasisEx
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists ValidBasisEx.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 22 Dec 2014	SW	1	RFC41698 Implement a left join to ValidBasisEx to get the CaseTypeKey and
--				CaseCategoryKey columns.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	B.BASIS 			as 'ApplicationBasisKey',
		"+dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ApplicationBasisDescription',
		B.COUNTRYCODE 		as 'CountryKey',
		CASE B.COUNTRYCODE WHEN 'ZZZ' THEN 1 ELSE 0 END
		 			as 'IsDefaultCountry',
		B.PROPERTYTYPE 		as 'PropertyTypeKey',
		VX.CASETYPE		as 'CaseTypeKey',
		VX.CASECATEGORY		as 'CaseCategoryKey'
	from	VALIDBASIS B
	left join VALIDBASISEX VX	on (VX.COUNTRYCODE = B.COUNTRYCODE
					and VX.PROPERTYTYPE = B.PROPERTYTYPE
					and VX.BASIS = B.BASIS)
	order by ApplicationBasisDescription"

	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListValidBasisEx to public
GO

