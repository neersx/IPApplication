-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseList
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseList.'
	Drop procedure [dbo].[csw_ListCaseList]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseList...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListCaseList
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 180, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	csw_ListCaseList
-- VERSION:	5
-- DESCRIPTION:	Returns the requested information for Case Lists that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Nov 2004	TM	RFC931	1	Procedure created
-- 15 May 2005	JEK	RFC2508	2	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	3	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 24 Oct 2005	TM	RFC3024 4	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 07 Jul 2011	DL	RFC10830 5	Specify database collation default to temp table columns of type varchar, nvarchar and char


-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	CaseListKey
--	ListName
--	ListDescription

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	CL

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests table 
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
Declare @tbOrderBy table (
				Position	tinyint		not null,
				Direction	nvarchar(5)	collate database_default not null,
				ColumnName	nvarchar(1000)	collate database_default not null,
				PublishName	nvarchar(50)	collate database_default null,
				ColumnNumber	tinyint		not null
			)

Declare @nOutRequestsRowCount			int
Declare @nColumnNo				tinyint
Declare @sColumn				nvarchar(100)
Declare @sPublishName				nvarchar(50)
Declare @sQualifier				nvarchar(50)
Declare @nOrderPosition				tinyint
Declare @sOrderDirection			nvarchar(5)
Declare @sTableColumn				nvarchar(1000)
Declare @sComma					nchar(2)	-- initialised when a column has been added to the Select.

-- Declare Filter Variables
Declare @nCaseListKey 				int		-- Unique identifier for the Case List.
Declare @nCaseListKeyOperator			tinyint
Declare @sPickListSearch			nvarchar(254)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.
Declare @bExists				bit
Declare @sListName				nvarchar(50)	-- Name of the Case List. Case insensitive search.
Declare @nListNameOperator			tinyint
Declare @sListDescription			nvarchar(254)	-- Case List Description. Case insensitive search.
Declare @nListDescriptionOperator		tinyint

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sOrder					nvarchar(4000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+"From CASELIST CL"
set 	@sWhere 				= char(10)+"	WHERE 1=1"

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
	-- Default @pnQueryContextKey to 180.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 180)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End

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

	If @nErrorCode=0
	Begin
		If @sColumn='CaseListKey'
		Begin
			Set @sTableColumn='CL.CASELISTNO'
		End
		Else 
		If @sColumn='ListName'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASELIST','CASELISTNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura) 
		End
		Else 
		If @sColumn = 'ListDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASELIST','DESCRIPTION',null,'CL',@sLookupCulture,@pbCalledFromCentura) 
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
			values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)

			Set @nErrorCode = @@ERROR
		End
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
End

-- Now construct the Order By clause

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

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the filter criteria using element-centric mapping (implement 
	--    Case Insensitive searching wher required)   
	Set @sSQLString = 	
	"Select @nCaseListKey			= CaseListKey,"+CHAR(10)+
	"	@nCaseListKeyOperator		= CaseListKeyOperator,"+CHAR(10)+
	"	@sPickListSearch		= upper(PickListSearch),"+CHAR(10)+
	"	@sListName			= upper(ListName),"+CHAR(10)+
	"	@nListNameOperator		= ListNameOperator,"+CHAR(10)+				
	"	@sListDescription		= upper(ListDescription),"+CHAR(10)+
	"	@nListDescriptionOperator	= ListDescriptionOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '/csw_ListCaseList/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseListKey		int		'CaseListKey/text()',"+CHAR(10)+
	"	      CaseListKeyOperator	tinyint		'CaseListKey/@Operator/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(254)	'PickListSearch/text()',"+CHAR(10)+	
	"	      ListName			nvarchar(50)	'ListName/text()',"+CHAR(10)+
 	"	      ListNameOperator		tinyint		'ListName/@Operator/text()',"+CHAR(10)+	
	"	      ListDescription		nvarchar(254)	'ListDescription/text()',"+CHAR(10)+	
	"	      ListDescriptionOperator	tinyint		'ListDescription/@Operator/text()'"+CHAR(10)+
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nCaseListKey 		int			output,
				  @nCaseListKeyOperator		tinyint			output,
				  @sPickListSearch		nvarchar(254)		output,
				  @sListName			nvarchar(50)		output,	
				  @nListNameOperator		tinyint			output,				
				  @sListDescription		nvarchar(254)		output,
				  @nListDescriptionOperator	tinyint			output',
				  @idoc				= @idoc,
				  @nCaseListKey 		= @nCaseListKey		output,
				  @nCaseListKeyOperator		= @nCaseListKeyOperator	output,
				  @sPickListSearch		= @sPickListSearch	output,
				  @sListName			= @sListName		output,
				  @nListNameOperator		= @nListNameOperator	output,				
				  @sListDescription		= @sListDescription	output,
				  @nListDescriptionOperator 	= @nListDescriptionOperator output		
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
	
		If @nCaseListKey is not NULL
		or @nCaseListKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and CL.CASELISTNO " + dbo.fn_ConstructOperator(@nCaseListKeyOperator,@Numeric,@nCaseListKey, null,0)
		End		

		If @sListName is not NULL
		or @nListNameOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('CASELIST','CASELISTNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura)+") " + dbo.fn_ConstructOperator(@nListNameOperator,@String,@sListName, null,0)
		End	

		If @sListDescription is not NULL
		or @nListDescriptionOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('CASELIST','DESCRIPTION',null,'CL',@sLookupCulture,@pbCalledFromCentura)+") " + dbo.fn_ConstructOperator(@nListDescriptionOperator,@String,@sListDescription, null,0)
		End			

		-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
		-- is produced.  The search only continues to the next criterion if no rows were located.
			
		If @sPickListSearch is not null
		Begin
			-- If the length of PickListSearch does not exceed the maximum length of the ListName
			
			If LEN(@sPickListSearch) <= 50
			Begin
				Set @bExists = 0
				-- Check if ListName Equals To PickListSearch
				Set @sSQLString = "Select @bExists=1"+char(10)+
						  "from CASELIST CL"+char(10)+
						  @sWhere+
						  "and (upper("+dbo.fn_SqlTranslatedColumn('CASELIST','CASELISTNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura)+")=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
			
				exec @nErrorCode =  sp_executesql @sSQLString,
							N'@bExists		bit		OUTPUT,
							  @sPickListSearch	nvarchar(254)',
							  @bExists		= @bExists 	OUTPUT,
							  @sPickListSearch	= @sPickListSearch
			
				If @bExists=1
				Begin
					Set @sWhere=@sWhere+char(10)+"and (upper("+dbo.fn_SqlTranslatedColumn('CASELIST','CASELISTNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura)+")=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
				End
				Else
				Begin
					Set @sWhere=@sWhere+char(10)+"and (upper("+dbo.fn_SqlTranslatedColumn('CASELIST','CASELISTNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+ 
								     " or upper("+dbo.fn_SqlTranslatedColumn('CASELIST','DESCRIPTION',null,'CL',@sLookupCulture,@pbCalledFromCentura)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
				End
			End
			Else 
			Begin
				Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('CASELIST','DESCRIPTION',null,'CL',@sLookupCulture,@pbCalledFromCentura)+") like "+ dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
			End
		End
	
	End
End

If @nErrorCode=0
Begin 	
	-- Now execute the constructed SQL to return the result set
	Exec (@sSelect + @sFrom + @sWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseList to public
GO