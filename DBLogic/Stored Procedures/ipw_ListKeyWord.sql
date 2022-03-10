-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListKeyWord
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListKeyWord]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListKeyWord.'
	Drop procedure [dbo].[ipw_ListKeyWord]
End
Print '**** Creating Stored Procedure dbo.ipw_ListKeyWord...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListKeyWord
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 260, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0	
)
as
-- PROCEDURE:	ipw_ListKeyWord
-- VERSION:	3
-- DESCRIPTION:	Returns the requested case keyword information, for keywords that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Oct 2005	TM	RFC3144	1	Procedure created
-- 18 Oct 2005	TM	RFC3144	2	Default ContextKey parameter to 260.
-- 07 Jul 2011	DL	RFC10830 3	Specify database collation default to temp table columns of type varchar, nvarchar and char


-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	KeyWordKey
--	KeyWord
--	IsStopWord

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	KW
--	CW

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
Declare @nCaseKey				int		-- The database key of the case to which the keyword belongs.
Declare @nCaseKeyOperator			tinyint
Declare @nKeyWordKey				int		-- The database key of the keyword.
Declare @nKeyWordKeyOperator			tinyint
Declare	@sPickListSearch			nvarchar(50)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.
Declare @bExists				bit
Declare	@sKeyWord				nvarchar(50)	-- The keyword of the case. Case insensitive search.
Declare @nKeyWordOperator			tinyint
Declare @bIsStopWord				bit		-- If set to 1, all keywords that will not be assigned automatically to a Case will be returned (i.e. where KeyWords.StopWord = 1). If set to 0, all keywords that will be automatically assigned to a Case will be returned (i.e. where KeyWords.StopWord equals to 0 or is NULL). If not provided, all the keywords will be returned, i.e. no filtering on the IsStopWord filter criteria will be performed. 

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
set 	@sSelect				="SET ANSI_NULLS OFF Select "
set 	@sFrom					= char(10)+"From KEYWORDS KW"
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
	-- Default @pnQueryContextKey to 260.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 260)

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
		If @sColumn='KeyWordKey'
		Begin
			Set @sTableColumn='KW.KEYWORDNO'
		End
		Else 
		If @sColumn='KeyWord'
		Begin
			Set @sTableColumn='KW.KEYWORD'
		End
		Else 
		If @sColumn = 'IsStopWord'
		Begin
			Set @sTableColumn='CASE WHEN KW.STOPWORD = 1 THEN CAST(1 as bit) ELSE CAST(0 as bit) END' 
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

	-- 1) Retrieve the AnySearch element using element-centric mapping (implement 
	--    Case Insensitive searching)   
	Set @sSQLString = 	
	"Select @nCaseKey			= CaseKey,"+CHAR(10)+
	"	@nCaseKeyOperator		= CaseKeyOperator,"+CHAR(10)+
	"	@sPickListSearch		= upper(PickListSearch),"+CHAR(10)+
	"	@nKeyWordKey			= KeyWordKey,"+CHAR(10)+
	"	@nKeyWordKeyOperator		= KeyWordKeyOperator,"+CHAR(10)+
	"	@sKeyWord			= upper(KeyWord),"+CHAR(10)+
	"	@nKeyWordOperator		= KeyWordOperator,"+CHAR(10)+	
	"	@bIsStopWord			= IsStopWord"+CHAR(10)+	
	"from	OPENXML (@idoc, '//ipw_ListKeyWord/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseKey			int		'CaseKey/text()',"+CHAR(10)+
	"	      CaseKeyOperator		tinyint		'CaseKey/@Operator/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(50)	'PickListSearch/text()',"+CHAR(10)+	
	"	      KeyWordKey		int		'KeyWordKey/text()',"+CHAR(10)+	
	"	      KeyWordKeyOperator	tinyint		'KeyWordKey/@Operator/text()',"+CHAR(10)+	
	"	      KeyWord			nvarchar(50)	'KeyWord/text()',"+CHAR(10)+	
	"	      KeyWordOperator		tinyint		'KeyWord/@Operator/text()',"+CHAR(10)+	
	"	      IsStopWord		bit		'IsStopWord/text()'"+CHAR(10)+
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nCaseKey 			int			output,
				  @nCaseKeyOperator		tinyint			output,
				  @sPickListSearch		nvarchar(50)		output,				  		
				  @nKeyWordKey			int			output,
				  @nKeyWordKeyOperator		tinyint			output,		
				  @sKeyWord			nvarchar(50)		output,		
				  @nKeyWordOperator		tinyint			output,
				  @bIsStopWord			bit			output',
				  @idoc				= @idoc,
				  @nCaseKey 			= @nCaseKey		output,
				  @nCaseKeyOperator		= @nCaseKeyOperator	output,
				  @sPickListSearch		= @sPickListSearch	output,				  		
				  @nKeyWordKey			= @nKeyWordKey		output,
				  @nKeyWordKeyOperator 		= @nKeyWordKeyOperator	output,
				  @sKeyWord			= @sKeyWord		output,
				  @nKeyWordOperator		= @nKeyWordOperator	output,
				  @bIsStopWord			= @bIsStopWord		output			
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
	
		If @nCaseKey is not NULL
		or @nCaseKeyOperator between 2 and 6
		Begin
			If charindex('join CASEWORDS CW ',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'join CASEWORDS CW	on (CW.KEYWORDNO = KW.KEYWORDNO)'
			End

			Set @sWhere = @sWhere+char(10)+"and CW.CASEID " + dbo.fn_ConstructOperator(@nCaseKeyOperator,@Numeric,@nCaseKey, null,0)
		End			

		If @nKeyWordKey is not NULL
		or @nKeyWordKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and KW.KEYWORDNO " + dbo.fn_ConstructOperator(@nKeyWordKeyOperator,@Numeric,@nKeyWordKey, null,0)
		End	

		If @sKeyWord is not NULL
		or @nKeyWordOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper(KW.KEYWORD) " + dbo.fn_ConstructOperator(@nKeyWordOperator,@String,@sKeyWord, null,0)
		End			

		If @bIsStopWord is not NULL
		Begin
			Set @sWhere = @sWhere+char(10)+"and KW.STOPWORD = "+CAST(@bIsStopWord as char(1)) 
		End	

		-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
		-- is produced.  The search only continues to the next criterion if no rows were located.
			
		If @sPickListSearch is not null
		Begin
			Set @bExists = 0
			-- Check if Code Equals To PickListSearch
			Set @sSQLString = "Select @bExists=1"+char(10)+
					  "from KEYWORDS KW"+char(10)+
					   CASE WHEN (@nCaseKey is not NULL or @nCaseKeyOperator between 2 and 6)
						THEN "join CASEWORDS CW	on (CW.KEYWORDNO = KW.KEYWORDNO)"
					   END+char(10)+
					   @sWhere+
					  "and (upper(KW.KEYWORD)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
		
			exec @nErrorCode =  sp_executesql @sSQLString,
						N'@bExists		bit		OUTPUT,
						  @sPickListSearch	nvarchar(50)',
						  @bExists		= @bExists 	OUTPUT,
						  @sPickListSearch	= @sPickListSearch
		
			If @bExists=1
			Begin
				Set @sWhere=@sWhere+char(10)+"and (upper(KW.KEYWORD)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
			End
			Else
			Begin
				Set @sWhere=@sWhere+char(10)+"and upper(KW.KEYWORD) like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
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

Grant execute on dbo.ipw_ListKeyWord to public
GO
