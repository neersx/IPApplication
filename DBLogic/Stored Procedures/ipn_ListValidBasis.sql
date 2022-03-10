SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListValidBasis]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListValidBasis.'
	Drop procedure [dbo].[ipn_ListValidBasis]
End
Print '**** Creating Stored Procedure dbo.ipn_ListValidBasis...'
Print ''
GO

CREATE PROCEDURE dbo.ipn_ListValidBasis
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLFilterCriteria	ntext		= null
)
-- PROCEDURE:	ipn_ListValidBasis
-- VERSION:	6
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Implement Case Fields necessary for rules processing
--		See RFC05 for full details.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 11-FEB-2003  SF	1	Procedure created
-- 25-MAY-2005	TM	2	RFC2241 Add new @ptXMLFilterCriteria parameter (see details below) and perform 
--				the new filtering. Remove the IsDefaultCountry column.
-- 25-MAY-2005	TM	3	If there are any rows with the correct CaseType/Category on them, these are the only 
--				rows that are valid.
-- 26-MAY-2005	TM	4	RFC2241	Cater for @ptXMLFilterCriteria = null.
-- 03-JUN-2005	TM	5	RFC2241	Remove the CountryKey and PropertyTypeKey columns. Use new VALIDBASISEX
--				to filter on CaseType and CaseCategory.
-- 07-JUL-2005	TM	6	RFC2329	Increase the size of all case category parameters and local variables 
--				to 2 characters.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)
Declare @nRowCount		int

Declare @idoc 			int	-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

-- Filter criteria:
Declare @sCountryKey		nvarchar(3)	
Declare @sPropertyTypeKey	nchar(1)	
Declare @sCaseTypeKey		nchar(1)
Declare @sCaseCategoryKey	nvarchar(2)

Declare @tblValidBasis		table( 	BASIS 			nvarchar(2) 	collate database_default not null,
					BASISDESCRIPTION 	nvarchar(50)	collate database_default null)

Set @nErrorCode = 0
Set @nRowCount = 0

If (datalength(@ptXMLFilterCriteria) > 0
and datalength(@ptXMLFilterCriteria) is not null)
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	-- Extract the filter criteria:
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 	
		"Select @sCountryKey		= CountryKey,"+CHAR(10)+
		"	@sPropertyTypeKey	= PropertyTypeKey,"+CHAR(10)+
		"	@sCaseTypeKey		= CaseTypeKey,"+CHAR(10)+
		"	@sCaseCategoryKey	= CaseCategoryKey"+CHAR(10)+
		"from	OPENXML (@idoc, '/query/criteria',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      CountryKey		nvarchar(3)	'CountryKey/text()',"+CHAR(10)+
		"	      PropertyTypeKey		nchar(1)	'PropertyTypeKey/text()',"+CHAR(10)+
		"	      CaseTypeKey		nchar(1)	'CaseTypeKey/text()',"+CHAR(10)+
		"	      CaseCategoryKey		nvarchar(2)	'CaseCategoryKey/text()'"+CHAR(10)+
	     	"     	     )"
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc			int,
					  @sCountryKey		nvarchar(3)		output,
					  @sPropertyTypeKey 	nchar(1)		output,
					  @sCaseTypeKey		nchar(1)		output,
					  @sCaseCategoryKey	nvarchar(2)		output',
					  @idoc			= @idoc,
					  @sCountryKey		= @sCountryKey		output,
					  @sPropertyTypeKey 	= @sPropertyTypeKey 	output,
					  @sCaseTypeKey		= @sCaseTypeKey		output,
					  @sCaseCategoryKey	= @sCaseCategoryKey 	output
	
		-- deallocate the xml document handle when finished.
		exec sp_xml_removedocument @idoc	
	End
End

-- 1) Show rows that have the same CaseType, Country, Property Type and Case Category:
If @nErrorCode = 0
Begin
	insert into @tblValidBasis (BASIS, BASISDESCRIPTION)
	Select 	VX.BASIS 		as 'ApplicationBasisKey',
		B.BASISDESCRIPTION 	as 'ApplicationBasisDescription'
	from	VALIDBASISEX VX
	left join VALIDBASIS B		on (B.COUNTRYCODE = VX.COUNTRYCODE
					and B.PROPERTYTYPE = VX.PROPERTYTYPE
					and B.BASIS = VX.BASIS)
	where 	VX.PROPERTYTYPE = @sPropertyTypeKey   
	and 	VX.COUNTRYCODE = @sCountryKey 
	and 	VX.CASETYPE = @sCaseTypeKey
	and 	VX.CASECATEGORY = @sCaseCategoryKey
	order by B.BASISDESCRIPTION

	Select	@nErrorCode = @@Error,
		@nRowCount = @@RowCount
End

-- 2) If none, show rows that have the Case Type, Default Country (ZZZ), Property Type and Case Category
If @nErrorCode = 0
and @nRowCount = 0
Begin
	insert into @tblValidBasis (BASIS, BASISDESCRIPTION)
	Select 	VX.BASIS 		as 'ApplicationBasisKey',
		B.BASISDESCRIPTION 	as 'ApplicationBasisDescription'
	from	VALIDBASISEX VX
	left join VALIDBASIS B		on (B.COUNTRYCODE = VX.COUNTRYCODE
					and B.PROPERTYTYPE = VX.PROPERTYTYPE
					and B.BASIS = VX.BASIS)
	where 	VX.PROPERTYTYPE = @sPropertyTypeKey   
	and 	VX.COUNTRYCODE = 'ZZZ' 
	and 	VX.CASETYPE = @sCaseTypeKey
	and 	VX.CASECATEGORY = @sCaseCategoryKey
	order by B.BASISDESCRIPTION

	Select	@nErrorCode = @@Error,
		@nRowCount = @@RowCount
End

-- 3) If none, show rows that have the Country and Property Type
If @nErrorCode = 0
and @nRowCount = 0
Begin
	insert into @tblValidBasis (BASIS, BASISDESCRIPTION)
	Select 	BASIS 			as 'ApplicationBasisKey',
		BASISDESCRIPTION 	as 'ApplicationBasisDescription'
	from	VALIDBASIS
	where 	PROPERTYTYPE = @sPropertyTypeKey   
	and 	COUNTRYCODE = @sCountryKey
	order by BASISDESCRIPTION	

	Select	@nErrorCode = @@Error,
		@nRowCount = @@RowCount
End

-- 4) If none, show rows that have the Default Country and Property Type.
If @nErrorCode = 0
and @nRowCount = 0
Begin
	insert into @tblValidBasis (BASIS, BASISDESCRIPTION)
	Select 	BASIS 			as 'ApplicationBasisKey',
		BASISDESCRIPTION 	as 'ApplicationBasisDescription'
	from	VALIDBASIS
	where 	PROPERTYTYPE = @sPropertyTypeKey   
	and 	COUNTRYCODE = 'ZZZ'
	order by BASISDESCRIPTION

	Select	@nErrorCode = @@Error,
		@nRowCount = @@RowCount
End

If @nErrorCode = 0
Begin
	Select 	BASIS 			as 'ApplicationBasisKey',
		BASISDESCRIPTION 	as 'ApplicationBasisDescription'
	from	@tblValidBasis
	order by BASISDESCRIPTION
End

Return @nErrorCode
GO

Grant execute on dbo.ipn_ListValidBasis to public
GO

