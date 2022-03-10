-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListCountry
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ip_ListCountry]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.ip_ListCountry.'
	drop procedure dbo.ip_ListCountry
	Print '**** Creating procedure dbo.ip_ListCountry...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ip_ListCountry
	@pnRowCount			int output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 30,	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbPrintSQL			bit		= null,	-- When set to 1, the executed SQL statement is printed out. 
	@pbCalledFromCentura		bit		= 0

AS


-- PROCEDURE :	ip_ListCountry
-- VERSION :	27
-- DESCRIPTION:	Returns the Country information requested, that matches the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15-OCT-2002  JB		1	Procedure created - parameters correct only
-- 17-OCT-2002  JB		2	Procedure compeleted
-- 17-OCT-2002  JB		3	Forgot to update the Version No :(
-- 22-OCT-2002	JB		4	Fixed bug with staged search
-- 22-OCT-2002	JB		5	Added @pbDebugMode
-- 22-OCT-2002	JB		6	Fixed bug with DATECEASED (thanks to Karen)
-- 17 Jul 2003	TM		9	RFC76 - Case Insensitive searching
-- 07 Nov 2003	MF	RFC586	10	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 27 Nov 2003	JEK	RFC387	11	Implement some default columns.
-- 18 Dec 2003	JEK	RFC766	12	Return IsCountryCurrent as type bit.
-- 18 Dec 2003	TM	RFC611	13	Add two new columns StateLiteral and PostcodeLiteral.
-- 13 May 2004	TM	RFC1246	14	Implement fn_GetCorrelationSuffix function to generate the correlation suffix 
--					based on the supplied qualifier.
-- 02 Sep 2004	JEK	RFC1377	15	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 15 Sep 2004	TM	RFC886	16	Implement translation.
-- 30 Sep 2004	TM	RFC1806	17	New PostalName column and additional PickListSearch filtering.
-- 17 Dec 2004	TM	RFC1674	18	Remove the UPPER function around the CountryCode to improve performance.
-- 22 Feb 2005	TM	RFC2340	19	Correct the pick list search logic.
-- 15 May 2005	JEK	RFC2508	20	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 19 Oct 2005	TM	RFC3024	21	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 08 Sep 2006	SW	RFC4046	22	Filter by @pbIsCurrent, @pbIsAddress, @pbIsGroup, @pbIsTemplate, @pbIsIPOnly
--					regardless @psPickListSearch is null or not.
-- 23 Feb 2009	AT	RFC7369	23	Add ISD column.
-- 23 Oct 2009	SF	RFC8449	24	Standardise generic stored procedure interface
-- 23 Nov 2009	SF	RFC8449 25	Sorting was not implemented correctly
-- 07 Jul 2011	DL	RFC10830 26	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 21 Jun 2013	MS	DR108	27	Added CountryGroup and Attributes in where coundition

-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- VARIABLES
Declare @nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sSelect		nvarchar(4000)  -- the SQL list of columns to return
Declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
Declare @sWhere			nvarchar(4000) 	-- the SQL to filter
Declare @sOrder			nvarchar(1000)	-- the SQL sort order
Declare	@sDelimiter		nchar(1)
Declare @nCount			int
Declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
Declare @nOutRequestsRowCount	int
Declare @nColumnNo		tinyint
Declare @sColumn		nvarchar(100)
Declare @sPublishName		nvarchar(50)
Declare @sQualifier		nvarchar(50)
Declare @sTableColumn		nvarchar(1000)
Declare @nLastPosition		smallint
Declare @nOrderPosition		tinyint
Declare @sOrderDirection	nvarchar(5)
Declare @sCorrelationSuffix	nvarchar(20)
Declare @bExists		bit

-- Filter Parameters
Declare	@sCountryKey			nvarchar(20)
Declare	@nCountryKeyOperator		tinyint
Declare	@sPickListSearch		nvarchar(254)		-- The text entered by a user in a pick list field to locate appropriate entries.
Declare	@bIsCurrent			bit					-- Returns countries where the date commenced (if any) is prior to today, and the date ceased (if any) is after today.
Declare	@bIsAddress			bit					-- Returns countries that may be used in an address (where RecordType = 0).
Declare	@bIsGroup			bit					-- Returns country groups (where RecordType = 1).
Declare	@bIsTemplate			bit					-- Returns countries acting as templates (where RecordType = 2).
Declare	@bIsIPOnly			bit					-- Returns countries that are for use for intellectual property purposes only (where RecordType = 3).
Declare	@sCountryName			nvarchar (60)
Declare	@nCountryNameOperator		tinyint
Declare	@sCountryAdjective		nvarchar (60)
Declare	@nCountryAdjectiveOperator	tinyint
Declare	@sAlternateCode			nvarchar (60)
Declare	@nAlternateCodeOperator		tinyint
Declare	@sCountryGroupKeys		nvarchar (4000)		-- Searches for countries that are members of the supplied group country.
Declare	@nCountryGroupKeysOperator	tinyint
Declare	@dtCommencedFromDate		datetime 
Declare	@dtCommencedToDate		datetime 
Declare	@nCommencedDateOperator		tinyint
Declare	@dtCeasedFromDate		datetime
Declare	@dtCeasedToDate			datetime
Declare	@nCeasedDateOperator		tinyint
Declare @sAttributeKeys			nvarchar(4000)  -- Comma seperated list of Attribute Keys
Declare @sAttributeTypeKey		nvarchar(11)
Declare @nAttributeOperator		tinyint
Declare @bBooleanOr			bit		-- When set to 1, cases are returned that match any of the attributes in the group.
							-- When set to 0 (or not supplied), cases are returned that match all of the attributes in the group.
Declare @bHasCountryAdjective		bit
Declare @bHasPostalName			bit
Declare @sRowPattern			nvarchar(100)	-- Is used to dynamically build the XPath to use with OPENXML depending on the FilterCriteriaGroup node number.
Declare @nAttributeRowCount		int		-- Number of rows in the @tblAttributeGroup table
Declare @sCorrelationName		nvarchar(20) 
Declare @sStringOr			nvarchar(5)

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
declare @tblOutputRequests table 
			 (	ROWNUMBER		int 		not null,
		   		ID			nvarchar(100)	collate database_default not null,
		   		SORTORDER		tinyint		null,
		   		SORTDIRECTION		nvarchar(1)	collate database_default null,
				PUBLISHNAME		nvarchar(100)	collate database_default null,
				QUALIFIER		nvarchar(100)	collate database_default null,				
				DOCITEMKEY		int		null
			  )

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
Declare @tbOrderBy table (
				Position		tinyint		not null,
				Direction		nvarchar(5)	collate database_default not null,
				ColumnName		nvarchar(1000)	collate database_default not null,
				PublishName		nvarchar(50)	collate database_default null,
				ColumnNumber		tinyint		not null
			)

Declare @tblAttributeGroup table 
			(	AttributeIdentity	int IDENTITY,
				BooleanOr		bit,
				AttributeKeys		nvarchar(4000)	collate database_default ,
		      		AttributeOperator	tinyint,		
		      		AttributeTypeKey	nvarchar(11)	collate database_default 
			)		

-- CONSTANTS
Declare @String			nchar(1),
	@Date			nchar(2),
	@Numeric		nchar(1),
	@Text			nchar(1),
	@CommaString		nchar(2)

Declare @idoc 			int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.	
Declare @sLookupCulture		nvarchar(10)

-- Initialisation
Set @String	='S'
Set @CommaString ='CS'
Set @Date	='DT'
Set @Numeric	='N'
Set @Text	='T'
Set @nCount	= 1

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nErrorCode	=0
Set @sDelimiter	='^'
set @sSelect	='SET ANSI_NULLS OFF' + char(10)+ 'Select distinct '
Set @sFrom	= char(10) + 'From COUNTRY CTRY'
Set @bExists	=0

Set @bHasCountryAdjective = 0
Set @bHasPostalName = 0

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
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 30)

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

	Set @sSQLString = 	
	"Select @sPickListSearch			= upper(PickListSearch),"+CHAR(10)+
	"	@sCountryKey					= upper(CountryKey),"+CHAR(10)+	
	"	@nCountryKeyOperator			= CountryKeyOperator,"+CHAR(10)+	
	"	@bIsCurrent						= IsCurrent,"+CHAR(10)+
	"	@bIsAddress						= IsAddress,"+CHAR(10)+
	"	@bIsGroup						= IsGroup,"+CHAR(10)+
	"	@bIsTemplate					= IsTemplate,"+CHAR(10)+
	"	@bIsIPOnly						= IsIPOnly,"+CHAR(10)+	
	"	@sCountryName					= upper(CountryName),"+CHAR(10)+	
	"	@nCountryNameOperator			= CountryNameOperator,"+CHAR(10)+
	"	@sCountryAdjective				= upper(CountryAdjective),"+CHAR(10)+
	"	@nCountryAdjectiveOperator		= CountryAdjectiveOperator,"+CHAR(10)+
	"	@sAlternateCode					= upper(AlternateCode),"+CHAR(10)+
	"	@nAlternateCodeOperator			= AlternateCodeOperator,"+CHAR(10)+
	"	@nDateCommencedOperator			= DateCommencedOperator,"+CHAR(10)+
	"	@dtDateCommencedFrom			= DateCommencedFrom,"+CHAR(10)+
	"	@dtDateCommencedTo				= DateCommencedTo,"+CHAR(10)+
	"	@nDateCeasedOperator			= DateCeasedOperator,"+CHAR(10)+
	"	@dtDateCeasedFrom				= DateCeasedFrom,"+CHAR(10)+
	"	@dtDateCeasedTo					= DateCeasedTo,"+CHAR(10)+
	"	@sCountryGroupKeys			= CountryGroupKeys,"+CHAR(10)+
	"	@nCountryGroupKeysOperator		= CountryGroupKeysOperator"+CHAR(10)+	
	"from	OPENXML (@idoc, '/ip_ListCountry/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      PickListSearch			nvarchar(254)	'PickListSearch/text()',"+CHAR(10)+	
	"	      CountryKey				nvarchar(20)	'CountryKey/text()',"+CHAR(10)+	
	"	      CountryKeyOperator		tinyint			'CountryKey/@Operator/text()',"+CHAR(10)+	
	"	      IsCurrent					bit				'IsCurrent/text()',"+CHAR(10)+		
	"	      IsAddress					bit				'IsAddress/text()',"+CHAR(10)+		
	"	      IsGroup					bit				'IsGroup/text()',"+CHAR(10)+		
	"	      IsTemplate				bit				'IsTemplate/text()',"+CHAR(10)+		
	"	      IsIPOnly					bit				'IsIPOnly/text()',"+CHAR(10)+		
	"	      CountryName				nvarchar(60)	'CountryName/text()',"+CHAR(10)+	
	"	      CountryNameOperator		tinyint			'CountryName/@Operator/text()',"+CHAR(10)+		
	"	      CountryAdjective			nvarchar(60)	'CountryAdjective/text()',"+CHAR(10)+	
	"	      CountryAdjectiveOperator	tinyint			'CountryAdjective/@Operator/text()',"+CHAR(10)+		
	"	      AlternateCode				nvarchar(60)	'AlternateCode/text()',"+CHAR(10)+	
	"	      AlternateCodeOperator		tinyint			'AlternateCode/@Operator/text()',"+CHAR(10)+		
	"	      DateCommencedOperator		tinyint			'DateCommenced/@Operator/text()',"+CHAR(10)+
	"	      DateCommencedFrom			datetime		'DateCommenced/From/text()',"+CHAR(10)+	
	"	      DateCommencedTo			datetime		'DateCommenced/To/text()',"+CHAR(10)+	
	"	      DateCeasedOperator		tinyint			'DateCeased/@Operator/text()',"+CHAR(10)+
	"	      DateCeasedFrom			datetime		'DateCeased/From/text()',"+CHAR(10)+	
	"	      DateCeasedTo				datetime	'DateCeased/To/text()',"+CHAR(10)+
	"	      CountryGroupKeys			nvarchar(400)		'CountryGroupKeys/text()',"+CHAR(10)+
	"	      CountryGroupKeysOperator		tinyint			'CountryGroupKeys/@Operator/text()'"+CHAR(10)+	
	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc					int,
				  @sPickListSearch			nvarchar(254)			output,
				  @sCountryKey				nvarchar(20)			output,
				  @nCountryKeyOperator			tinyint				output,
				  @bIsCurrent				bit				output,
				  @bIsAddress				bit				output,
				  @bIsGroup				bit				output,
				  @bIsTemplate				bit				output,
				  @bIsIPOnly				bit				output,
				  @sCountryName				nvarchar(60)			output,
				  @nCountryNameOperator			tinyint				output,
				  @sCountryAdjective			nvarchar(60)			output,
				  @nCountryAdjectiveOperator		tinyint				output,
				  @sAlternateCode			nvarchar(60)			output,
				  @nAlternateCodeOperator		tinyint				output,
				  @nDateCeasedOperator			tinyint				output,
				  @dtDateCeasedFrom			datetime			output,
				  @dtDateCeasedTo			datetime			output,
				  @nDateCommencedOperator		tinyint				output,
				  @dtDateCommencedFrom			datetime			output,
				  @dtDateCommencedTo			datetime			output,
				  @sCountryGroupKeys			nvarchar(4000)			output,
				  @nCountryGroupKeysOperator		tinyint				output',
				  @idoc					= @idoc,
				  @sPickListSearch			= @sPickListSearch		output,				  		
				  @sCountryKey				= @sCountryKey			output,
				  @nCountryKeyOperator			= @nCountryKeyOperator		output,
				  @bIsCurrent				= @bIsCurrent			output,
				  @bIsAddress				= @bIsAddress			output,
				  @bIsGroup				= @bIsGroup			output,
				  @bIsTemplate				= @bIsTemplate			output,
				  @bIsIPOnly				= @bIsIPOnly			output,
				  @sCountryName				= @sCountryName			output,
				  @nCountryNameOperator			= @nCountryNameOperator		output,
				  @sCountryAdjective			= @sCountryAdjective		output,
				  @nCountryAdjectiveOperator		= @nCountryAdjectiveOperator	output,
				  @sAlternateCode			= @sAlternateCode		output,
				  @nAlternateCodeOperator		= @nAlternateCodeOperator	output,
				  @nDateCeasedOperator			= @nCeasedDateOperator		output,
				  @dtDateCeasedFrom			= @dtCeasedFromDate		output,
				  @dtDateCeasedTo			= @dtCeasedToDate		output,
				  @nDateCommencedOperator		= @nCommencedDateOperator	output,
				  @dtDateCommencedFrom			= @dtCommencedFromDate		output,
				  @dtDateCommencedTo			= @dtCommencedToDate		output,
				  @sCountryGroupKeys			= @sCountryGroupKeys		output,
				  @nCountryGroupKeysOperator		= @nCountryGroupKeysOperator	output

	Set @sRowPattern = "//ip_ListCountry/FilterCriteria/AttributeGroup/Attribute"
		
		Insert into @tblAttributeGroup
		Select	*
		from	OPENXML (@idoc, @sRowPattern, 2)
		WITH (
		      BooleanOr			bit		'../@BooleanOr/text()',	
		      AttributeKeys		nvarchar(4000)	'AttributeKey/text()',
		      AttributeOperator		tinyint		'@Operator/text()',
		      AttributeTypeKey		nvarchar(11)	'TypeKey/text()'
		     )
	
		Set @nAttributeRowCount = @@RowCount		
				  
				  
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
		If @sColumn='CountryKey'
		Begin
			Set @sTableColumn='CTRY.COUNTRYCODE'
		End

		Else If @sColumn='CountryName'
		Begin				
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CTRY',@sLookupCulture,@pbCalledFromCentura) 
		End

		Else If @sColumn='CountryAdjective'
		Begin
			Set @bHasCountryAdjective = 1
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CTRY',@sLookupCulture,@pbCalledFromCentura) 
		End

		Else If @sColumn='CountryAbbreviation'
		Begin
			Set @sTableColumn='CTRY.COUNTRYABBREV'
		End

		Else If @sColumn='CountryAlternateCode'
		Begin
			Set @sTableColumn='CTRY.ALTERNATECODE'
		End

		Else If @sColumn='DateCommenced'
		Begin
			Set @sTableColumn='CTRY.DATECOMMENCED'
		End

		Else If @sColumn='DateCeased'
		Begin
			Set @sTableColumn='CTRY.DATECEASED'
		End

		Else If @sColumn='IsCountryCurrent'
		-- True when the date commenced (if any) is prior to today, and the date ceased (if any) is after today.
		Begin
			Set @sTableColumn='cast(CASE WHEN (CTRY.DATECOMMENCED is null or GETDATE() > CTRY.DATECOMMENCED) and (CTRY.DATECEASED is null OR GETDATE() < CTRY.DATECEASED) then 1 else 0 end as bit)'
		End
		
		Else If @sColumn='StateLiteral'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','STATELITERAL',null,'CTRY',@sLookupCulture,@pbCalledFromCentura) 
		End
	
		Else If @sColumn='PostcodeLiteral'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','POSTCODELITERAL',null,'CTRY',@sLookupCulture,@pbCalledFromCentura) 
		End

		Else If @sColumn='PostalName'
		Begin
			Set @bHasPostalName = 1
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','POSTALNAME',null,'CTRY',@sLookupCulture,@pbCalledFromCentura) 
		End
		
		Else If @sColumn='ISD'
		Begin
			Set @sTableColumn='CTRY.ISD'
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
			+CASE WHEN Direction = 'A' or Direction = ' ASC' THEN ' ASC ' ELSE ' DESC ' END
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

If @nErrorCode=0
Begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	Set @sWhere = char(10)+"WHERE 1=1"

	-- Perform filtering
	If @bIsCurrent is not NULL
		Set @sWhere = @sWhere+char(10)+"and (CTRY.DATECOMMENCED is null or GETDATE() > CTRY.DATECOMMENCED) and (CTRY.DATECEASED is null OR GETDATE() < CTRY.DATECEASED)"

	If @bIsAddress is not NULL
		Set @sWhere = @sWhere+char(10)+"and RECORDTYPE = '0'"

	If @bIsGroup is not NULL
		Set @sWhere = @sWhere+char(10)+"and RECORDTYPE = '1'"

	If @bIsTemplate is not NULL
		Set @sWhere = @sWhere+char(10)+"and RECORDTYPE = '2'"

	If @bIsIPOnly is not NULL
		Set @sWhere = @sWhere+char(10)+"and RECORDTYPE = '3'"

	-- Country key has been specified (normally by picklist)
	If @sCountryKey is not NULL and @nCountryKeyOperator = 0 
	Begin
		set @sWhere = @sWhere+char(10)+"and CTRY.COUNTRYCODE"+dbo.fn_ConstructOperator(@nCountryKeyOperator,@String,@sCountryKey, null,0)
	End
	
	-- Picklist search
	Else If @sPickListSearch is not null
	Begin
		-- If the length of @psPickListSearch does not exceed 
		-- the maximum length of the Country Code:
		If LEN(@sPickListSearch) <= 3
		Begin
			-- Is the Country Code Equal To @psPickListSearch?
			Set @sSQLString="Select @bExists=1"+char(10)+
					"from COUNTRY CTRY"+char(10)+
					@sWhere +char(10)+
					"and COUNTRYCODE = "+dbo.fn_WrapQuotes(@sPickListSearch,0,0)					
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@bExists		bit		OUTPUT,
						  @sPickListSearch	nvarchar(254)',
						  @bExists		=@bExists 	OUTPUT,
						  @sPickListSearch	=@sPickListSearch

			If @bExists=1
			and @nErrorCode=0
			Begin
				Set @sWhere=@sWhere+char(10)+"and CTRY.COUNTRYCODE = "+dbo.fn_WrapQuotes(@sPickListSearch,0,0)
			End				
			-- If the Country Code Does Not Equal To @sPickListSearch:
			Else
			If @nErrorCode=0
			Begin 
				Set @sWhere=@sWhere+char(10)+  "and (CTRY.COUNTRYCODE Like "+dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+char(10)+
							       "or upper("+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CTRY',@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+char(10)+					
								CASE   	WHEN @bHasCountryAdjective = 1
									THEN " or upper("+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CTRY',@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)
								END+char(10)+
								CASE	WHEN @bHasPostalName = 1
									THEN " or upper("+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTALNAME',null,'CTRY',@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)
								END+char(10)+")"
			End
		End
		Else
		If LEN(@sPickListSearch) > 3
		Begin
			Set @sWhere=@sWhere+char(10)+  "and (upper("+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CTRY',@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+char(10)+					
							CASE   	WHEN @bHasCountryAdjective = 1
								THEN " or upper("+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CTRY',@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)
							END+char(10)+
							CASE	WHEN @bHasPostalName = 1
								THEN " or upper("+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTALNAME',null,'CTRY',@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)
							END+char(10)+")"
		End

	End
	
	-- Other search
	Else Begin
		-- It will only get in here if @pnCountryKeyOperator <> 0
		If @sCountryKey is not NULL
		or @nCountryKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and CTRY.COUNTRYCODE"+dbo.fn_ConstructOperator(@nCountryKeyOperator,@String,@sCountryKey, null,0)
		End
	
		If @sCountryName is not NULL
		or @nCountryNameOperator between 2 and 6
		Begin		
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CTRY',@sLookupCulture,@pbCalledFromCentura)+")"+dbo.fn_ConstructOperator(@nCountryNameOperator,@String,@sCountryName, null,0)
		End

		If @sCountryAdjective is not NULL
		or @nCountryAdjectiveOperator between 2 and 6
		Begin	
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CTRY',@sLookupCulture,@pbCalledFromCentura)+")"+dbo.fn_ConstructOperator(@nCountryAdjectiveOperator,@String,@sCountryAdjective, null,0)
		End

		If @sAlternateCode is not NULL
		or @nAlternateCodeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper(CTRY.ALTERNATECODE)"+dbo.fn_ConstructOperator(@nAlternateCodeOperator,@String,upper(@sAlternateCode), null,0)
		End

		If @sCountryGroupKeys is not NULL
		or @nCountryGroupKeysOperator between 2 and 6
		Begin
			set @sFrom = @sFrom+char(10)+"left join COUNTRYGROUP XCG on (XCG.MEMBERCOUNTRY=CTRY.COUNTRYCODE)"
			Set @sWhere = @sWhere+char(10)+"and upper(XCG.TREATYCODE)"+dbo.fn_ConstructOperator(@nCountryGroupKeysOperator,@CommaString,upper(@sCountryGroupKeys), null,0)
		End

		If @dtCommencedFromDate is not NULL
		or @dtCommencedToDate   is not NULL
		or @nCommencedDateOperator between 2 and 6
		Begin
			set @sWhere=@sWhere+char(10)+"	and CTRY.DATECOMMENCED "+dbo.fn_ConstructOperator(@nCommencedDateOperator,@Date,@dtCommencedFromDate, @dtCommencedToDate,0)
		End

		If @dtCeasedFromDate is not NULL
		or @dtCeasedToDate   is not NULL
		or @nCeasedDateOperator between 2 and 6
		Begin
			set @sWhere=@sWhere+char(10)+"	and CTRY.DATECEASED "+dbo.fn_ConstructOperator(@nCeasedDateOperator,@Date,@dtCeasedFromDate, @dtCeasedToDate,0)
		End

		-- Set @nCount to 1 so it points to the first record of the table		
		Set @nCount = 1	
		
		-- @nAttributeRowCount is the number of rows in the @tblAttributeGroup table, which is used to loop the Attributes while constructing the 'From' and the 'Where' clause  		
		While @nCount <= @nAttributeRowCount
		Begin
			Set @sCorrelationName = 'XTA_' + cast(@nCount as nvarchar(20))
				
			Select  @bBooleanOr		= BooleanOr,
				@sAttributeKeys		= AttributeKeys,
				@sAttributeTypeKey	= AttributeTypeKey,
			     	@nAttributeOperator	= AttributeOperator
			from	@tblAttributeGroup
			where   AttributeIdentity = @nCount 
					
			If (@sAttributeKeys is not null	or @nAttributeOperator between 2 and 6)		
			Begin
				If @nAttributeRowCount > 1 and @nCount >1 
				Begin 
					set @sStringOr = CASE WHEN @bBooleanOr = 1 THEN " or "
					      	      	      WHEN @bBooleanOr = 0 or @bBooleanOr is null THEN " and "
					 	 	 END
				End
				Else If @nCount = 1
				Begin
					set @sWhere =@sWhere+char(10)+"	and ("
				End
				Set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES " + @sCorrelationName + " WITH (NOLOCK)"
						   +char(10)+"		on (" + @sCorrelationName + ".PARENTTABLE='COUNTRY'"
					   	   +char(10)+"	            and " + @sCorrelationName + ".TABLETYPE="+@sAttributeTypeKey

				If  @nAttributeOperator=1 and @sAttributeKeys is not null
				Begin
					Set @sFrom = @sFrom+char(10)+"	    and " + @sCorrelationName + ".TABLECODE" + dbo.fn_ConstructOperator(@nAttributeOperator,@CommaString,@sAttributeKeys, null,@pbCalledFromCentura)
	   			End
				Set @sFrom = @sFrom+char(10)+"	            and " + @sCorrelationName + ".GENERICKEY=convert(varchar,CTRY.COUNTRYCODE))"

				If @nAttributeOperator=1
				Begin
					Set @sWhere =@sWhere+@sStringOr+space(1)+ @sCorrelationName + ".TABLECODE is null"
				End
				Else
				Begin
					Set @sWhere =@sWhere+@sStringOr+space(1)+ 
						 + @sCorrelationName + ".TABLECODE"+dbo.fn_ConstructOperator(@nAttributeOperator,@Numeric,@sAttributeKeys, null,@pbCalledFromCentura)
				End
				If @nCount = @nAttributeRowCount
				Begin
					Set @sWhere = @sWhere + ")"
				End
			End	
			Set @nCount = @nCount + 1	
		End
	End
End

if @nErrorCode=0
begin 
	-- Now execute the constructed SQL to return the result set
	If @pbPrintSQL = 1
	Begin
		Print (@sSelect + @sFrom + @sWhere + @sOrder)
	End

	Exec (@sSelect + @sFrom + @sWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

end

RETURN @nErrorCode
GO

Grant execute on dbo.ip_ListCountry  to public
GO
