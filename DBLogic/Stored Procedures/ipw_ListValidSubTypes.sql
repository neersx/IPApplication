---------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListValidSubTypes
---------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListValidSubTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListValidSubTypes.'
	drop procedure [dbo].[ipw_ListValidSubTypes]
	Print '**** Creating Stored Procedure dbo.ipw_ListValidSubTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListValidSubTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListValidSubTypes
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Valid SubTypes.

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
	Select 	S.SUBTYPE		as 'SubTypeKey',
		"+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'SubTypeDescription',
		S.COUNTRYCODE 		as 'CountryKey',
		CASE S.COUNTRYCODE WHEN 'ZZZ' THEN 1 ELSE 0 END
		 			as 'IsDefaultCountry',
		S.PROPERTYTYPE 		as 'PropertyTypeKey',
		S.CASETYPE		as 'CaseTypeKey',
		S.CASECATEGORY		as 'CaseCategoryKey'
	from	VALIDSUBTYPE S
	order by SubTypeDescription"
	
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End	

Return @nErrorCode
GO

grant exec on dbo.ipw_ListValidSubTypes to public
go
