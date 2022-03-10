-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListDocument
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_ListDocument]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_ListDocument.'
	drop procedure dbo.ip_ListDocument
	print '**** Creating procedure dbo.ip_ListDocument...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ip_ListDocument
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey			int		= 40,	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext	= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext	= null,	-- The filtering to be performed on the result set.		
	@pbPrintSQL					bit		= null,	-- When set to 1, the executed SQL statement is printed out. 
	@pbCalledFromCentura		bit		= 0
AS

-- PROCEDURE :	ip_ListDocument
-- VERSION :	17
-- DESCRIPTION:	Returns the information requested about documents (letters, pdf forms etc.), 
--		that matches the filter criteria provided.

-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 26 SEP 2002	MF		0	Procedure created
-- 27 SEP 2002  JB		1	Changes to incorporate changes to spec (v0.2)
-- 15 OCT 2002	SF		2	Move DocumentKey Comparison to before PickListSearch Comparison.
-- 15 OCT 2002	SF		3	More adjustment on the Key Comparison.
-- 15 OCT 2002	MF		4	Return documents where Document Code or description Starts With @sPickListSearch.
-- 17 Jul 2003	TM		8	RFC76 - Case Insensitive searching
-- 13-May-2004	TM	RFC1246	9	Implement fn_GetCorrelationSuffix function to generate the correlation suffix 
--					based on the supplied qualifier.
-- 02 Sep 2004	JEK	RFC1377	10	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 17 Dec 2004	TM	RFC1674	11	Remove the UPPER function around the DocumentCode to improve performance.
-- 25 Oct 2006	AU	RFC3646	12	Implemented translations for DocumentDescription, DeliveryMethodDescription,
--					CountryName, InstructionTypeDescription, PropertyTypeDescription,
--					CorrespondenceTypeDescription, CoveringDocumentName, EnvelopeName.
-- 16 Mar 2007	SF	RFC4588	13	Implemented filtering on UsedBy
-- 26 Oct 2009	SF	RFC8449	14	Standardise generic stored procedure interface
-- 07 Jul 2011	DL	R10830	15	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 27 Feb 2012	SF	R11961	16	Add capability to filter using not operator on USEDBY
-- 24 Oct 2017	AK	R72645	17	Make compatible with case sensitive server with case insensitive database.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @nErrorCode		int

declare @sSqlString		nvarchar(max)
declare @sSelect		nvarchar(max)  -- the SQL list of columns to return
declare	@sFrom			nvarchar(max)	-- the SQL to list tables and joins
declare @sWhere			nvarchar(max) 	-- the SQL to filter
declare @sOrder			nvarchar(max)	-- the SQL sort order
declare	@sDelimiter		nchar(1)
declare @nCount			int
declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
declare @nOutRequestsRowCount	int
declare @nColumnNo		tinyint
declare @sColumn		nvarchar(100)
declare @sPublishName		nvarchar(50)
declare @sQualifier		nvarchar(50)
declare @sTableColumn		nvarchar(1000)
declare @nLastPosition		smallint
declare @nOrderPosition		tinyint
declare @sOrderDirection	nvarchar(5)
declare @sCorrelationSuffix	nvarchar(20)
declare @sTable1		nvarchar(25)
declare @sLookupCulture		nvarchar(10)
declare @nUsedByFlag		int
declare @nNotUsedByFlag		int

	-- Filter Parameters
declare	@nDocumentKey			int	-- the key of the Letter
declare	@nDocumentKeyOperator		tinyint
declare	@sPickListSearch		nvarchar(254)
declare	@sDocumentCode			nvarchar(10)
declare	@nDocumentCodeOperator		tinyint
declare	@sDocumentDescription		nvarchar(254)
declare	@nDocumentDescriptionOperator	tinyint
declare	@sCountryKey			nvarchar(3)
declare	@nCountryKeyOperator		tinyint
declare	@sPropertyTypeKey	 	nchar(1)
declare	@nPropertyTypeKeyOperator	tinyint
declare	@nDeliveryMethodKey		smallint
declare	@nDeliveryMethodKeyOperator	tinyint
declare	@nDocumentTypeKey		smallint
declare	@nDocumentTypeKeyOperator	tinyint
declare	@bUsedForCases			bit
declare	@bUsedForNames			bit
declare	@bUsedForTimeAndBilling		bit

declare	@bIsInproDocOnly		bit
declare	@bIsDGLibOnly			bit

declare	@bUsedForCasesOperator		tinyint
declare	@bUsedForNamesOperator		tinyint
declare	@bUsedForTimeAndBillingOperator	tinyint
declare	@bIsInproDocOnlyOperator	tinyint
declare	@bIsDGLibOnlyOperator		tinyint


-- declare some constants
declare @String			nchar(1),
	@Date			nchar(2),
	@Numeric		nchar(1),
	@Text			nchar(1)

Set	@String ='S'
Set	@Date   ='DT'
Set	@Numeric='N'
Set	@Text   ='T'

Set @nUsedByFlag = 0
Set @nNotUsedByFlag = 0

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
declare @tblOutputRequests table 
			 (	ROWNUMBER	int 		not null,
		   		ID		nvarchar(100)	collate database_default not null,
		   		SORTORDER	tinyint		null,
		   		SORTDIRECTION	nvarchar(1)	collate database_default null,
				PUBLISHNAME	nvarchar(100)	collate database_default null,
				QUALIFIER	nvarchar(100)	collate database_default null,				
				DOCITEMKEY	int		null
			  )


-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
declare @tbOrderBy table (
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null
			)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialisation
set @nErrorCode	=0
set @sDelimiter	='^'
set @sSelect='Select '
set @sFrom	='From LETTER XL'

Set @nCount					= 1

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin	
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End
-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
Else
Begin
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 40)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End

/***********************************************/
/****                                       ****/
/****    EXTRACT FILTER CRITERIA FROM XML   ****/
/****                                       ****/
/***********************************************/

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the Filter Criteria using element-centric mapping (implement 
	--    Case Insensitive searching where required)   

	Set @sSqlString = 	
	"Select @sPickListSearch					= upper(PickListSearch),"+CHAR(10)+
	"	@nDocumentKey						= DocumentKey,"+CHAR(10)+	
	"	@nDocumentKeyOperator					= DocumentKeyOperator,"+CHAR(10)+	
	"	@sDocumentCode						= upper(DocumentCode),"+CHAR(10)+	
	"	@nDocumentCodeOperator					= DocumentCodeOperator,"+CHAR(10)+
	"	@sDocumentDescription					= upper(DocumentDescription),"+CHAR(10)+	
	"	@nDocumentDescriptionOperator				= DocumentDescriptionOperator,"+CHAR(10)+
	"	@nDocumentTypeKey					= DocumentTypeKey,"+CHAR(10)+	
	"	@nDocumentTypeKeyOperator				= DocumentTypeKeyOperator,"+CHAR(10)+
	"	@sCountryKey						= CountryKey,"+CHAR(10)+	
	"	@nCountryKeyOperator					= CountryKeyOperator,"+CHAR(10)+
	"	@sPropertyTypeKey					= PropertyTypeKey,"+CHAR(10)+	
	"	@nPropertyTypeKeyOperator				= PropertyTypeKeyOperator,"+CHAR(10)+
	"	@nDeliveryMethodKey					= DeliveryMethodKey,"+CHAR(10)+	
	"	@nDeliveryMethodKeyOperator				= DeliveryMethodKeyOperator,"+CHAR(10)+
	"	@bUsedForCases						= IsUsedForCases,"+CHAR(10)+
	"	@bUsedForNames						= IsUsedForNames,"+CHAR(10)+
	"	@bUsedForTimeAndBilling					= IsUsedForTimeAndBilling,"+CHAR(10)+
	"	@bIsInproDocOnly					= IsInproDocOnly,"+CHAR(10)+
	"	@bIsDGLibOnly						= IsDGLibOnly,"+CHAR(10)+
	"	@bUsedForCasesOperator					= IsUsedForCasesOperator,"+CHAR(10)+
	"	@bUsedForNamesOperator					= IsUsedForNamesOperator,"+CHAR(10)+
	"	@bUsedForTimeAndBillingOperator				= IsUsedForTimeAndBillingOperator,"+CHAR(10)+
	"	@bIsInproDocOnlyOperator				= IsInproDocOnlyOperator,"+CHAR(10)+
	"	@bIsDGLibOnlyOperator					= IsDGLibOnlyOperator"+CHAR(10)+

	"from	OPENXML (@idoc, '/ip_ListDocument/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      PickListSearch					nvarchar(254)		'PickListSearch/text()',"+CHAR(10)+	
	"	      DocumentKey					int			'DocumentKey/text()',"+CHAR(10)+	
	"	      DocumentKeyOperator				tinyint			'DocumentKey/@Operator/text()',"+CHAR(10)+	
	"	      DocumentCode					nvarchar(10)		'DocumentCode/text()',"+CHAR(10)+	
	"	      DocumentCodeOperator				tinyint			'DocumentCode/@Operator/text()',"+CHAR(10)+		
	"	      DocumentDescription				nvarchar(254)		'DocumentDescription/text()',"+CHAR(10)+	
	"	      DocumentDescriptionOperator			tinyint			'DocumentDescription/@Operator/text()',"+CHAR(10)+		
	"	      DocumentTypeKey					int			'DocumentTypeKey/text()',"+CHAR(10)+	
	"	      DocumentTypeKeyOperator				tinyint			'DocumentTypeKey/@Operator/text()',"+CHAR(10)+		
	"	      CountryKey					nvarchar(10)		'CountryKey/text()',"+CHAR(10)+	
	"	      CountryKeyOperator				tinyint			'CountryKey/@Operator/text()',"+CHAR(10)+		
	"	      PropertyTypeKey					nchar(1)		'PropertyTypeKey/text()',"+CHAR(10)+	
	"	      PropertyTypeKeyOperator				tinyint			'PropertyTypeKey/@Operator/text()',"+CHAR(10)+		
	"	      DeliveryMethodKey					smallint		'DeliveryMethodKey/text()',"+CHAR(10)+	
	"	      DeliveryMethodKeyOperator				tinyint			'DeliveryMethodKey/@Operator/text()',"+CHAR(10)+	
	"	      IsUsedForCases					bit			'IsUsedForCases',"+CHAR(10)+
	"	      IsUsedForNames					bit			'IsUsedForNames',"+CHAR(10)+	
	"	      IsUsedForTimeAndBilling				bit			'IsUsedForTimeAndBilling',"+CHAR(10)+	
	"	      IsInproDocOnly					bit			'IsInproDocOnly',"+CHAR(10)+
	"	      IsDGLibOnly					bit			'IsDGLibOnly',"+CHAR(10)+
	"	      IsUsedForCasesOperator				tinyint			'IsUsedForCases/@Operator/text()',"+CHAR(10)+	
	"	      IsUsedForNamesOperator				tinyint			'IsUsedForNames/@Operator/text()',"+CHAR(10)+	
	"	      IsUsedForTimeAndBillingOperator			tinyint			'IsUsedForTimeAndBilling/@Operator/text()',"+CHAR(10)+	
	"	      IsInproDocOnlyOperator				tinyint			'IsInproDocOnly/@Operator/text()',"+CHAR(10)+	
	"	      IsDGLibOnlyOperator				tinyint			'IsDGLibOnly/@Operator/text()'"+CHAR(10)+	
	"     	     )"

	exec @nErrorCode = sp_executesql @sSqlString,
				N'@idoc						int,
				  @sPickListSearch				nvarchar(254)		output,
				  @nDocumentKey					int			output,
				  @nDocumentKeyOperator				tinyint			output,
				  @sDocumentCode				nvarchar(10)		output,
				  @nDocumentCodeOperator			tinyint			output,
				  @sDocumentDescription				nvarchar(254)		output,
				  @nDocumentDescriptionOperator			tinyint			output,
				  @nDocumentTypeKey				int			output,
				  @nDocumentTypeKeyOperator			tinyint			output,
				  @sCountryKey					nvarchar(3)		output,
				  @nCountryKeyOperator				tinyint			output,
				  @sPropertyTypeKey				nchar(1)		output,
				  @nPropertyTypeKeyOperator			tinyint			output,
				  @nDeliveryMethodKey				smallint		output,
				  @nDeliveryMethodKeyOperator			tinyint			output,
				  @bUsedForCases				bit			output,
				  @bUsedForNames				bit			output,
				  @bUsedForTimeAndBilling			bit			output,
				  @bIsInproDocOnly				bit			output,
				  @bIsDGLibOnly					bit			output,
				  @bUsedForCasesOperator			tinyint			output,
				  @bUsedForNamesOperator			tinyint			output,
				  @bUsedForTimeAndBillingOperator		tinyint			output,
				  @bIsInproDocOnlyOperator			tinyint			output,
				  @bIsDGLibOnlyOperator				tinyint			output
				  ',
				  @idoc						= @idoc,
				  @sPickListSearch				= @sPickListSearch			output,				  		
				  @nDocumentKey					= @nDocumentKey				output,
				  @nDocumentKeyOperator				= @nDocumentKeyOperator			output,
				  @sDocumentCode				= @sDocumentCode			output,
				  @nDocumentCodeOperator			= @nDocumentCodeOperator		output,
				  @sDocumentDescription				= @sDocumentDescription			output,
				  @nDocumentDescriptionOperator			= @nDocumentDescriptionOperator		output,
				  @nDocumentTypeKey				= @nDocumentTypeKey			output,
				  @nDocumentTypeKeyOperator			= @nDocumentTypeKeyOperator		output,
				  @sCountryKey					= @sCountryKey				output,
				  @nCountryKeyOperator				= @nCountryKeyOperator			output,
				  @sPropertyTypeKey				= @sPropertyTypeKey			output,
				  @nPropertyTypeKeyOperator			= @nPropertyTypeKeyOperator		output,
				  @nDeliveryMethodKey				= @nDeliveryMethodKey			output,
				  @nDeliveryMethodKeyOperator			= @nDeliveryMethodKeyOperator		output,
				  @bUsedForCases				= @bUsedForCases			output,
				  @bUsedForNames				= @bUsedForNames			output,
				  @bUsedForTimeAndBilling			= @bUsedForTimeAndBilling		output,
				  @bIsInproDocOnly				= @bIsInproDocOnly			output,
				  @bIsDGLibOnly					= @bIsDGLibOnly				output,
				  @bUsedForCasesOperator			= @bUsedForCasesOperator		output,
				  @bUsedForNamesOperator			= @bUsedForNamesOperator		output,
				  @bUsedForTimeAndBillingOperator		= @bUsedForTimeAndBillingOperator	output,
				  @bIsInproDocOnlyOperator			= @bIsInproDocOnlyOperator		output,
				  @bIsDGLibOnlyOperator				= @bIsDGLibOnlyOperator			output
				  
				  
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****                                       ****/
/***********************************************/

-- Loop through each column in order to construct the components of the SELECT
While @nCount < @nOutRequestsRowCount + 1
and   @nErrorCode=0
Begin
	-- Get the ColumnID, Name of the column to be published (@sPublishName), the position of the Column 
	-- in the Order By clause (@nOrderPosition), the direction of the sort (@sOrderDirection),
	-- Qualifier to be used to get the column (@sQualifier)   
	Select	@nColumnNo 		= ROWNUMBER,
		@sColumn   		= ID,
		@sPublishName 		= PUBLISHNAME,
		@nOrderPosition		= SORTORDER,
		@sOrderDirection	= CASE WHEN SORTORDER > 0 THEN SORTDIRECTION
					       ELSE NULL
					  END,
		@sQualifier		= QUALIFIER
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	Set @nErrorCode = @@ERROR

	-- Now test the value of the Column to determine what table and column is required
	-- in the Select.  Note that if the PublishName is null then the column will not be
	-- returned in the result set however it is probably required for sorting.

	If @nErrorCode=0
	Begin
		If @sColumn='DocumentKey'
		Begin
			Set @sTableColumn='XL.LETTERNO'
		End

		Else If @sColumn='DocumentCode'
		Begin
			Set @sTableColumn='XL.DOCUMENTCODE'
		End

		Else If @sColumn='DocumentDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'XL',@sLookupCulture,@pbCalledFromCentura)--'XL.LETTERNAME'
		End

		Else If @sColumn='TemplateName'
		Begin
			Set @sTableColumn='XL.MACRO'
		End

		Else If @sColumn='IsPlacedOnHold'
		Begin
			Set @sTableColumn='cast(XL.HOLDFLAG as bit)'
		End

		Else If @sColumn='DeliveryMethodDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('DELIVERYMETHOD','DESCRIPTION',null,'DM',@sLookupCulture,@pbCalledFromCentura)--'DM.DESCRIPTION'

			If charindex('Left Join DELIVERMETHOD DM',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Left Join DELIVERYMETHOD DM on (DM.DELIVERYID=XL.DELIVERYID)"
			End
		End

		Else If @sColumn='CountryName'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)--'C.COUNTRY'

			If charindex('Left Join COUNTRY C',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Left Join COUNTRY C on (C.COUNTRYCODE=XL.COUNTRYCODE)"
			End
		End

		Else If @sColumn='InstructionTypeDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)--'I.INSTRTYPEDESC'

			If charindex('Left Join INSTRUCTIONTYPE I',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Left Join INSTRUCTIONTYPE I on (I.INSTRUCTIONTYPE=XL.INSTRUCTIONTYPE)"
			End
		End

		Else If @sColumn='PropertyTypeDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)--'P.PROPERTYNAME'

			If charindex('Left Join PROPERTYTYPE P',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Left Join PROPERTYTYPE P on (P.PROPERTYTYPE=XL.PROPERTYTYPE)"
			End
		End

		Else If @sColumn='IsWPDocument'
		Begin
			Set @sTableColumn="CASE WHEN (XL.DOCUMENTTYPE=1) THEN 1 ELSE 0 END"
		End

		Else If @sColumn='IsPDFForm'
		Begin
			Set @sTableColumn="CASE WHEN (XL.DOCUMENTTYPE=2) THEN 1 ELSE 0 END"
		End

		Else If @sColumn='CorrespondenceTypeDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CORRESPONDTO','DESCRIPTION',null,'CT',@sLookupCulture,@pbCalledFromCentura)--'CT.DESCRIPTION'

			If charindex('Left Join CORRESPONDTO CT',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Left Join CORRESPONDTO CT on (CT.CORRESPONDTYPE=XL.CORRESPONDTYPE)"
			End
		End

		Else If @sColumn='CoveringDocumentName'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura)--'CL.LETTERNAME'

			If charindex('Left Join LETTER CL',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Left Join LETTER CL on (CL.LETTERNO=XL.COVERINGLETTER)"
			End
		End

		Else If @sColumn='EnvelopeName'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'EL',@sLookupCulture,@pbCalledFromCentura)--'EL.LETTERNAME'

			If charindex('Left Join LETTER EL',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Left Join LETTER EL on (EL.LETTERNO=XL.ENVELOPE)"
			End
		End

		Else If @sColumn='AllowsMultipleCases'
		Begin
			Set @sTableColumn='cast(XL.MULTICASEFLAG as bit)'
		End

		Else If @sColumn='AllowsCopies'
		Begin
			Set @sTableColumn='cast(XL.COPIESALLOWEDFLAG as bit)'
		End

		Else If @sColumn='NoOfExtraCopies'
		Begin
			Set @sTableColumn='XL.EXTRACOPIES'
		End
	End

	-- If the column is being published then concatenate it to the Select list

	If datalength(@sPublishName)>0
	Begin
		Set @sSelect=@sSelect+@sComma+@sTableColumn+' as ['+@sPublishName+']'
		Set @sComma=', '
	End
	Else Begin
		Set @sPublishName=NULL
	End

	-- If the column is to be sorted on then save the name of the table column along
	-- with the sort details so that later the Order By can be constructed in the correct sequence

	If @nOrderPosition>0
	Begin
		Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
		values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, 
		       Case When(@sOrderDirection='D') Then ' DESC' ELSE ' ASC' End)
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1

End


/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE ORDER BY       ****/
/****                                       ****/
/***********************************************/

If @nErrorCode=0
Begin		
	-- Assemble the "Order By" clause.

	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @sOrder= ISNULL(NULLIF(@sOrder+',', ','),'')			
			 +CASE WHEN(PublishName is null) 
			       THEN ColumnName
			       ELSE '['+PublishName+']'
			  END
			+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
			from @tbOrderBy
			order by Position			

	If @sOrder is not null
	Begin
		Set @sOrder = ' Order by ' + @sOrder
	End

	Set @nErrorCode=@@Error
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSE   ****/
/****                                       ****/
/***********************************************/
if @nErrorCode=0
begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	set @sWhere = char(10)+"WHERE 1=1"

	-- SF: Move DocumentKey up so that Document is compared before PicklistSearch.
	If @nDocumentKey is not NULL
	and @nDocumentKeyOperator = 0
	Begin
		Set @sWhere = @sWhere+char(10)+"and XL.LETTERNO"+dbo.fn_ConstructOperator(@nDocumentKeyOperator,@Numeric,@nDocumentKey, null,0)
	End
	Else If @sPickListSearch is not null
	Begin
		If LEN(@sPickListSearch)<=10
		and (exists (Select * from LETTER where DOCUMENTCODE=@sPickListSearch)
		  or exists (Select * from LETTER where DOCUMENTCODE like @sPickListSearch+'%'))
		Begin
			If exists (Select * from LETTER where DOCUMENTCODE=@sPickListSearch)
				set @sWhere=@sWhere+char(10)+"and (XL.DOCUMENTCODE='"+@sPickListSearch+"' OR upper(XL.LETTERNAME) Like '"+@sPickListSearch+"%')"
			Else
				set @sWhere=@sWhere+char(10)+"and (XL.DOCUMENTCODE Like'"+@sPickListSearch+"%' OR upper(XL.LETTERNAME) Like '"+@sPickListSearch+"%')"
		End
		Else Begin
			set @sWhere=@sWhere+char(10)+"and upper(XL.LETTERNAME) Like '"+@sPickListSearch+"%'"
		End
	End	
	Else Begin
		if @nDocumentKey is not NULL
		or @nDocumentKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and XL.LETTERNO"+dbo.fn_ConstructOperator(@nDocumentKeyOperator,@Numeric,@nDocumentKey, null,0)
		end
	
		if @sDocumentCode is not NULL
		or @nDocumentCodeOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and XL.DOCUMENTCODE"+dbo.fn_ConstructOperator(@nDocumentCodeOperator,@String,@sDocumentCode, null,0)
		end
	
		if @sDocumentDescription is not NULL
		or @nDocumentDescriptionOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and upper(XL.LETTERNAME)"+dbo.fn_ConstructOperator(@nDocumentDescriptionOperator,@String,@sDocumentDescription, null,0)
		end	
	
		if @sCountryKey is not NULL
		or @nCountryKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and XL.COUNTRYCODE"+dbo.fn_ConstructOperator(@nCountryKeyOperator,@String,@sCountryKey, null,0)
		end	
	
		if @sPropertyTypeKey is not NULL
		or @nPropertyTypeKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and XL.PROPERTYTYPE"+dbo.fn_ConstructOperator(@nPropertyTypeKeyOperator,@String,@sPropertyTypeKey, null,0)
		end
	
		if @nDeliveryMethodKey is not NULL
		or @nDeliveryMethodKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and XL.DELIVERYID"+dbo.fn_ConstructOperator(@nDeliveryMethodKeyOperator,@Numeric,@nDeliveryMethodKey, null,0)
		end
	
		if @nDocumentTypeKey is not NULL
		or @nDocumentTypeKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and XL.DOCUMENTTYPE"+dbo.fn_ConstructOperator(@nDocumentTypeKeyOperator,@Numeric,@nDocumentTypeKey, null,0)
		end	

		if @bUsedForTimeAndBilling=1
		begin
			if @bUsedForTimeAndBillingOperator = 1
			begin
				set @nNotUsedByFlag = @nNotUsedByFlag | 1
			end
			else
			begin
				set @nUsedByFlag = @nUsedByFlag | 1
			end
		end

		if @bUsedForCases=1
		begin
			if @bUsedForCasesOperator = 1
			begin
				set @nNotUsedByFlag = @nNotUsedByFlag | 32
			end
			else
			begin
				set @nUsedByFlag = @nUsedByFlag | 32
			end
		end

		if @bUsedForNames=1
		begin
			if @bUsedForNamesOperator = 1
			begin
				set @nNotUsedByFlag = @nNotUsedByFlag | 256
			end
			else
			begin
				set @nUsedByFlag = @nUsedByFlag | 256
			end
		end

		if @bIsInproDocOnly=1
		begin
			if @bIsInproDocOnlyOperator = 1
			begin
				set @nNotUsedByFlag = @nNotUsedByFlag | 1024
			end
			else
			begin
				set @nUsedByFlag = @nUsedByFlag | 1024
			end
		end
		
		if @bIsDGLibOnly=1
		begin
			if @bIsDGLibOnlyOperator = 1
			begin
				set @nNotUsedByFlag = @nNotUsedByFlag | 2048
			end
			else
			begin
				set @nUsedByFlag = @nUsedByFlag | 2048
			end
		end
		
		if @nUsedByFlag>0
		begin
			set @sWhere = @sWhere+char(10)+"and XL.USEDBY&"+cast(@nUsedByFlag as varchar(5))+">0" 	
		end
		
		if @nNotUsedByFlag>0
		begin
			set @sWhere = @sWhere+char(10)+"and XL.USEDBY&"+cast(@nNotUsedByFlag as varchar(5))+"=0" 	
		end	
	End
End

if @nErrorCode=0
begin

	If @pbPrintSQL = 1
	Begin
	
		print (@sSelect + @sFrom + @sWhere + CHAR(10)+ @sOrder)
		
	End
	
	-- Now execute the constructed SQL to return the result set
	exec (@sSelect + @sFrom + @sWhere + @sOrder)
	select 	@nErrorCode =@@Error,
		@pnRowCount=@@Rowcount
 
end

RETURN @nErrorCode
go

grant execute on dbo.ip_ListDocument  to public
go
