-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListQuestion
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_ListQuestion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipw_ListQuestion.'
	drop procedure dbo.ipw_ListQuestion
	print '**** Creating procedure dbo.ipw_ListQuestion...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_ListQuestion
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey			int		= 40,	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext	= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext	= null,	-- The filtering to be performed on the result set.		
	@pbPrintSQL					bit		= null,	-- When set to 1, the executed SQL statement is printed out. 
	@pbCalledFromCentura		bit		= 0
AS

-- PROCEDURE :	ipw_ListQuestion
-- VERSION :	4
-- DESCRIPTION:	Returns the Charge Type information requested, that matches the filter criteria provided.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15/11/2010	KR		 1	Procedure created
-- 12/07/2011	DL	RFC19795 2	Specify collate database_default for temp tables.
-- 09/05/2012	ASH	R10676   3	Search a question by entering the no or code.
-- 24/10/2017	AK	R72645 	 4	Make compatible with case sensitive server with case insensitive database.

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

-- VARIABLES

declare @nErrorCode		int
declare @sSqlString		nvarchar(4000)
declare @sSelect		nvarchar(4000)  -- the SQL list of columns to return
declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
declare @sWhere			nvarchar(4000) 	-- the SQL to filter
declare @sOrder			nvarchar(1000)	-- the SQL sort order
declare @pbExists		bit
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
declare @bIsExternalUser	bit

-- Filter Parameters
declare @sQuestionKey		nvarchar(20)	-- the key of the Charge Type Key
declare @nQuestionKeyOperator	tinyint
declare @sPickListSearch	nvarchar(254)
declare @sQuestion		nvarchar(200)
declare @nQuestionOperator	tinyint
	
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
	ColumnNumber		tinyint		not null)

-- CONSTANTS

declare @String			nchar(1),
	@Date			nchar(2),
	@Numeric		nchar(1),
	@Text			nchar(1)

-- Initialisation
set @String	='S'
set @Date	='DT'
set @Numeric	='N'
set @Text	='T'
Set @nCount					= 1

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

-- Case Insensitive searching

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


set @nErrorCode	=0
set @sDelimiter	='^'
set @sSelect	='SET ANSI_NULLS OFF' + char(10)+ 'Select DISTINCT '
set @sFrom	=char(10)+'From QUESTION'

-- Check if external user
If @nErrorCode=0
Begin		
	Set @sSqlString='
	Select @bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSqlString,
				N'@bIsExternalUser	bit			OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

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
	"Select @sPickListSearch			= upper(PickListSearch),"+CHAR(10)+
	"	@sQuestionKey				= QuestionKey,"+CHAR(10)+	
	"	@nQuestionKeyOperator			= QuestionKeyOperator,"+CHAR(10)+	
	"	@sQuestion				= upper(Question),"+CHAR(10)+	
	"	@nQuestionOperator			= QuestionOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '/ipw_ListQuestion/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      PickListSearch			nvarchar(254)	'PickListSearch/text()',"+CHAR(10)+	
	"	      QuestionKey			nvarchar(20)	'QuestionKey/text()',"+CHAR(10)+	
	"	      QuestionKeyOperator		tinyint		'QuestionKey/@Operator/text()',"+CHAR(10)+	
	"	      Question				nvarchar(200)	'Question/text()',"+CHAR(10)+	
	"	      QuestionOperator			tinyint		'Question/@Operator/text()'"+CHAR(10)+		
	"     	     )"

	exec @nErrorCode = sp_executesql @sSqlString,
				N'@idoc					int,
				  @sPickListSearch			nvarchar(254)			output,
				  @sQuestionKey				nvarchar(20)			output,
				  @nQuestionKeyOperator			tinyint					output,
				  @sQuestion				nvarchar(200)			output,
				  @nQuestionOperator			tinyint					output',
				  @idoc					= @idoc,
				  @sPickListSearch			= @sPickListSearch		output,				  		
				  @sQuestionKey				= @sQuestionKey			output,
				  @nQuestionKeyOperator			= @nQuestionKeyOperator		output,
				  @sQuestion				= @sQuestion			output,
				  @nQuestionOperator			= @nQuestionOperator		output
				  
				  
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
		If @sColumn='QuestionKey'
		Begin
			Set @sTableColumn='QUESTIONNO'
		End
		
		Else If @sColumn='PickListCode'
		Begin
			Set @sTableColumn='QUESTIONCODE'
		End

		Else If @sColumn='Question'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('QUESTION','QUESTION',null,null,@sLookupCulture,@pbCalledFromCentura) 
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
			+CASE WHEN Direction in ('A',' ASC') THEN ' ASC ' ELSE ' DESC ' END
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

	If @sQuestionKey is not NULL
	and @nQuestionOperator = 0 
	Begin
		Set @sWhere = @sWhere+char(10)+"and QUESTIONNO"+dbo.fn_ConstructOperator(@nQuestionKeyOperator,@String,@sQuestionKey, null,0)
	End
	Else if @sQuestionKey is not NULL
	or @nQuestionOperator between 2 and 6
	begin
		set @sWhere = @sWhere+char(10)+"and QUESTIONNO"+dbo.fn_ConstructOperator(@nQuestionKeyOperator,@String,@sQuestionKey, null,0)
	end

	if @sQuestion is not NULL
	or @nQuestionOperator between 2 and 6
	begin						 
		set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('QUESTION','QUESTION',null,null,@sLookupCulture,@pbCalledFromCentura)+")"+dbo.fn_ConstructOperator(@nQuestionOperator,@String,@sQuestion, null,0)
	end	

	-- If the PicklistSearch is to be used then combine it with any previous WHERE clause
	-- and use a staged approach to determine what is to be searched on
	
	If @sPickListSearch is not null
	Begin
			-- Check for exact match on IRN
	
		If LEN(@sPickListSearch)<=20
		Begin
			set @pbExists=0
			-- RFC46 1st stage should check for exactly equal to Family only
			set @sSqlString="Select @pbExists=1"+char(10)+
					"from QUESTION "+char(10)+
					@sWhere+
					"and (QUESTION ="+dbo.fn_WrapQuotes(@sPickListSearch, 0, 0)+")"
	
			exec sp_executesql @sSqlString,
					N'@pbExists		bit	OUTPUT,
					  @sPickListSearch	nvarchar(254)',
					  @pbExists		=@pbExists OUTPUT,
					  @sPickListSearch	=@sPickListSearch
	
			If @pbExists=1
				-- RFC46 1st stage should check for exactly equal to Family only
				Set @sWhere=@sWhere+char(10)+"and (QUESTION ="+dbo.fn_WrapQuotes(@sPickListSearch, 0, 0)+")"
			Else
				Set @sWhere=@sWhere+char(10)+"and (QUESTION Like "+dbo.fn_WrapQuotes(@sPickListSearch + '%', 0, 0)+" OR upper("+dbo.fn_SqlTranslatedColumn('QUESTION','QUESTION',null,null,@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch + '%', 0, 0)+" OR upper("+dbo.fn_SqlTranslatedColumn('QUESTION','QUESTIONCODE',null,null,@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch + '%', 0, 0)+" OR QUESTIONNO like "+dbo.fn_WrapQuotes(@sPickListSearch + '%', 0, 0)+")"
		End
		Else Begin
			set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('QUESTION','QUESTION',null,null,@sLookupCulture,@pbCalledFromCentura)+") Like "+dbo.fn_WrapQuotes(@sPickListSearch + '%', 0, 0)
		End
	End
End

if @nErrorCode=0
begin

	If @pbPrintSQL = 1
	Begin
	
		Print (@sSelect + @sFrom + @sWhere + @sOrder)
	End
	
	-- Now execute the constructed SQL to return the result set

	exec (@sSelect + @sFrom + @sWhere + @sOrder)
	select 	@nErrorCode =@@Error,
		@pnRowCount=@@Rowcount

end

RETURN @nErrorCode
go

grant execute on dbo.ipw_ListQuestion  to public
go
