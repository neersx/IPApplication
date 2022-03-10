-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListValidBasis
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListValidBasis]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListValidBasis.'
	Drop procedure [dbo].[ipw_ListValidBasis]
	Print '**** Creating Stored Procedure dbo.ipw_ListValidBasis...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListValidBasis
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListValidBasis
-- VERSION:	6
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists ValidBasis.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 08 Oct 2003  TM	1	Procedure created
-- 15 Sep 2004	JEK	2	RFC886	Implement translation.
-- 15 May 2005	JEK	3	RFC2508	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 23 May 2005	TM	4	RFC2602	Add new columns CaseTypeKey and CaseCategoryKey to result set.
-- 03 Jun 2005	TM	5	RFC2602 Implement a left join to ValidBasisX to get the CaseTypeKey and
--				CaseCategoryKey columns.
-- 22 Dec 2014  SW      6       RFC41698 Removed left join with ValidBasisEx to only return records ValidBasis table.
--                              New stored procedure has been added named as ipw_ListValidBasisEx to list records from
--                              ValidBasisEx.       


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
	Select 	B.BASIS 	        as 'ApplicationBasisKey',
		"+dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,@pbCalledFromCentura)
				    + " as 'ApplicationBasisDescription',
		B.COUNTRYCODE 		as 'CountryKey',
		CASE B.COUNTRYCODE WHEN 'ZZZ' THEN 1 ELSE 0 END
		 			as 'IsDefaultCountry',
		B.PROPERTYTYPE 		as 'PropertyTypeKey'
	from	VALIDBASIS B	
	order by ApplicationBasisDescription"

	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListValidBasis to public
GO

