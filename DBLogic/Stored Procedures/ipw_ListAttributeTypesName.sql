-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListAttributeTypesName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListAttributeTypesName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListAttributeTypesName.'
	Drop procedure [dbo].[ipw_ListAttributeTypesName]
End
Print '**** Creating Stored Procedure dbo.ipw_ListAttributeTypesName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE PROCEDURE [dbo].[ipw_ListAttributeTypesName]
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 620, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.
	@pbCalledFromCentura		bit 		= 0,
	@pbIsDebugMode			bit	 	= 0
)
as
-- PROCEDURE:	ipw_ListAttributeTypesName
-- VERSION:	3
-- DESCRIPTION:	Returns the requested information for Attribute Types that match the filter criteria provided for Name.
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24 Sep 2009	DV	RFC8016	1	Procedure created 
-- 04 Feb 2010	DL	18430	2	Grant stored procedure to public
-- 07 Jul 2011	DL	RFC10830 3	Specify database collation default to temp table columns of type varchar, nvarchar and char


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
Declare @nAttributeKey			nvarchar(3)	-- The primary key of the currency. This is user modifiable, so also acts as the currency code.The data is held on the database in upper case. Always convert search string to upper case.
Declare @nAttributeKeyOperator			tinyint		
Declare @sAttributeName			nvarchar(40)	-- The description of the currency. Case insensitive search.
Declare @nAttributeNameOperator		tinyint
Declare @sPickListSearch			nvarchar(50)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.
Declare @bExists				bit

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sOrder					nvarchar(4000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String					nchar(1)

Set	@String 				='S'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+"From SELECTIONTYPES ST"
set 	@sWhere 				= char(10)+"	WHERE ST.PARENTTABLE in ('INDIVIDUAL','EMPLOYEE','ORGANISATION','NAME/LEAD')"
set		@sOrder					= char(10)+" TT.TABLENAME"

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
	-- Default @pnQueryContextKey to 620.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 620)

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
		If @sColumn='AttributeKey'
		Begin
			Set @sTableColumn='(Cast(ST.PARENTTABLE as nvarchar(100))+ ''^''+ Cast(ST.TABLETYPE as nvarchar(10)))'
		End
		Else 
		If @sColumn='AttributeName'
		Begin
			If charindex('join TABLETYPE TT',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'join TABLETYPE TT on (TT.TABLETYPE = ST.TABLETYPE)'
			End			
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TT',@sLookupCulture,@pbCalledFromCentura)
		End	
		Else 
		If @sColumn = 'NameType'
		Begin
			Set @sTableColumn='ST.PARENTTABLE'
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
	"Select @nAttributeKey			= upper(AttributeKey),"+CHAR(10)+
	"	@nAttributeKeyOperator		= AttributeKeyOperator,"+CHAR(10)+
	"	@sAttributeName		= upper(AttributeName),"+CHAR(10)+
	"	@nAttributeNameOperator	= upper(AttributeNameOperator),"+CHAR(10)+
	"	@sPickListSearch		= upper(PickListSearch)"+CHAR(10)+	
	"from	OPENXML (@idoc, '/ipw_ListAttributeTypesName/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      AttributeKey		int		'AttributeKey/text()',"+CHAR(10)+
	"	      AttributeKeyOperator	tinyint		'AttributeKey/@Operator/text()',"+CHAR(10)+
	"	      AttributeName		nvarchar(50)	'AttributeName/text()',"+CHAR(10)+	
	"	      AttributeNameOperator	tinyint		'AttributeName/@Operator/text()',"+CHAR(10)+
 	"	      PickListSearch		nvarchar(50)	'PickListSearch/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nAttributeKey		int			output,
				  @nAttributeKeyOperator	tinyint			output,
				  @sAttributeName		nvarchar(50)		output,
				  @nAttributeNameOperator	tinyint			output,	
				  @sPickListSearch		nvarchar(50)		output',
				  @idoc				= @idoc,
				  @nAttributeKey		= @nAttributeKey		output,
				  @nAttributeKeyOperator	= @nAttributeKeyOperator	output,
				  @sAttributeName		= @sAttributeName		output,
				  @nAttributeNameOperator	= @nAttributeNameOperator	output,
				  @sPickListSearch		= @sPickListSearch	output			
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin	
		If @sAttributeName is not NULL 		
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TT',@sLookupCulture,@pbCalledFromCentura)+") " + dbo.fn_ConstructOperator(@nAttributeNameOperator,@String,@sAttributeName, null,0)
		End	
		
		If @sPickListSearch is not null
		Begin
			Set @sWhere=@sWhere+char(10)+"and upper(TT.[TABLENAME]) Like '"+@sPickListSearch+"%'"
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

grant execute on dbo.ipw_ListAttributeTypesName to public
GO






