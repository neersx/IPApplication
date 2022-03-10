-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListFunctionTerminology
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListFunctionTerminology]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListFuipw_ListFunctionTerminologynctionSecurityRule.'
	Drop procedure [dbo].[ipw_ListFunctionTerminology]
End
Print '**** Creating Stored Procedure dbo.ipw_ListFunctionTerminology...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ipw_ListFunctionTerminology]
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 730, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.
	@pbCalledFromCentura		bit 		= 0,
	@pbIsDebugMode			bit	 	= 0
)
as
-- PROCEDURE:	ipw_ListFunctionTerminology
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Mar 2010	PA	8378	1	Procedure created
-- 07 Jul 2011	DL	RFC10830 2	Specify database collation default to temp table columns of type varchar, nvarchar and char


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)

Declare @sLookupCulture				nvarchar(10)

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
Declare @nFunctionType 				int	-- The primary key of the document request.
Declare @nFunctionTypeOperator			tinyint
Declare @sFunctionTypeDescription			nvarchar(254)
Declare @nFunctionTypeDescriptionOperator		tinyint
Declare @sPickListSearch				nvarchar(254)

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sOrder					nvarchar(4000)
Declare @Numeric				nchar(1)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String					nchar(1)
Set	@Numeric				='N'
Set	@String 				='S'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'SELECT '
set 	@sFrom					= char(10)+" From BUSINESSFUNCTION B"
set 	@sWhere 				= char(10)+" WHERE 1=1"
set		@sOrder					= char(10)+" B.DESCRIPTION"

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
	-- Default @pnQueryContextKey to 730.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 730)

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
		If @sColumn='FunctionType'
		Begin
			Set @sTableColumn='B.FUNCTIONTYPE'
		End
		If @sColumn='FunctionTypeDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('BUSINESSFUNCTION','DESCRIPTION',null,'B',@sLookupCulture,@pbCalledFromCentura) 
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

	-- 	Retrieve the filter criteria using element-centric mapping (implement 
	--    	Case Insensitive searching)   

	Set @sSQLString = 	
	"Select @nFunctionType			= FunctionType,"+CHAR(10)+
	"	@nFunctionTypeOperator		= FunctionTypeOperator,"+CHAR(10)+
	"	@sFunctionTypeDescription		= upper(FunctionTypeDescription),"+CHAR(10)+
	"	@nFunctionTypeDescriptionOperator	= upper(FunctionTypeDescriptionOperator),"+CHAR(10)+
	"	@sPickListSearch		= upper(PickListSearch)"+CHAR(10)+	
	"from	OPENXML (@idoc, '/ipw_ListFunctionTerminology/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      FunctionType		int		'FunctionType/text()',"+CHAR(10)+
	"	      FunctionTypeOperator	tinyint		'FunctionType/@Operator/text()',"+CHAR(10)+
	"	      FunctionTypeDescription		nvarchar(50)	'FunctionTypeDescription/text()',"+CHAR(10)+	
	"	      FunctionTypeDescriptionOperator	tinyint		'FunctionTypeDescription/@Operator/text()',"+CHAR(10)+
 	"	      PickListSearch		nvarchar(50)	'PickListSearch/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nFunctionType		int			output,
				  @nFunctionTypeOperator	tinyint			output,
				  @sFunctionTypeDescription		nvarchar(50)		output,
				  @nFunctionTypeDescriptionOperator	tinyint			output,	
				  @sPickListSearch		nvarchar(50)		output',
				  @idoc				= @idoc,
				  @nFunctionType		= @nFunctionType		output,
				  @nFunctionTypeOperator	= @nFunctionTypeOperator	output,
				  @sFunctionTypeDescription		= @sFunctionTypeDescription		output,
				  @nFunctionTypeDescriptionOperator	= @nFunctionTypeDescriptionOperator	output,
				  @sPickListSearch		= @sPickListSearch	output			
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin	
		If @nFunctionType is not NULL
		or @nFunctionTypeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and B.FUNCTIONTYPE " + dbo.fn_ConstructOperator(@nFunctionTypeOperator,@Numeric,@nFunctionType, null, 0)
		End

		If @sFunctionTypeDescription is not NULL
		or @nFunctionTypeDescriptionOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('BUSINESSFUNCTION','DESCRIPTION',null,'B',@sLookupCulture,@pbCalledFromCentura)+")"+dbo.fn_ConstructOperator(@nFunctionTypeDescriptionOperator,@String,@sFunctionTypeDescription, null,0)
		End
		
		If @sPickListSearch is not null
		Begin
			Set @sWhere=@sWhere+char(10)+"and upper(B.DESCRIPTION) Like '"+@sPickListSearch+"%'"
		End	
	End
End

If @nErrorCode=0
Begin
	If @pbIsDebugMode = 1
	Begin
		print @sSelect + @sFrom + @sWhere + @sOrder
	End
	Else
	Begin  
		-- Now execute the constructed SQL to return the result set
		Exec (@sSelect + @sFrom + @sWhere + @sOrder)
		Select 	@nErrorCode =@@ERROR,
			@pnRowCount=@@ROWCOUNT
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListFunctionTerminology to public
GO



