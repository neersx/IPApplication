-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListFileLocations 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListFileLocations ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListFileLocations.'
	Drop procedure [dbo].[ipw_ListFileLocations ]
	Print '**** Creating Stored Procedure dbo.ipw_ListFileLocations ...'
	Print ''
End
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListFileLocations 
(
	@pnRowCount			int		= null	output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnQueryContextKey		int		= 940,		-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, 	-- The columns and sorting required in the result Set.
	@ptXMLFilterCriteria		ntext		= null,		-- The filtering to be performed on the result Set.
	@pbCalledFromCentura		bit		= 0
)
AS
-- PROCEDURE:	ipw_ListFileLocations 
-- VERSION:	1
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns the requested table information for a file locations		

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18-Jul-2012  MS	R100715	1	Procedure created

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	Key
--	Description
--	Office
--	BarCode

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	O
--	FO
--      TC

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

Declare @sSelect		nvarchar(4000)	-- the SQL list of columns to return
Declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
Declare @sJoin			nvarchar(1000)
Declare	@sWhere			nvarchar(4000) 	-- the SQL to filter
Declare	@sOrder			nvarchar(1000)	-- the SQL sort order

Declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
Declare	@sSQLString		nvarchar(4000)
Declare @nColumnNo		tinyint
Declare @sColumn		nvarchar(100)
Declare @sPublishName		nvarchar(50)
Declare @sQualifier		nvarchar(50)
Declare @sTableColumn		nvarchar(1000)
Declare @nOrderPosition		tinyint
Declare @sOrderDirection	nvarchar(5)

-- Filter criteria variables declaration
Declare @sKey			nvarchar(10)
Declare @sPickListSearch	nvarchar(80)
Declare @bExists		bit		-- If @bExists = 1 then rows are located for a @sPickListSearch criterion
Declare @sDescription		nvarchar(80)
Declare @nDescriptionOperator	tinyint
Declare @sOffice		nvarchar(80)
Declare @nOfficeOperator	tinyint
Declare @sBarCode		nvarchar(50)
Declare @nBarCodeOperator	tinyint

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int 
Declare @nOutRequestsRowCount	int
Declare @nCount			int

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
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null
			)

-- Declare some constants
Declare @String			nchar(1)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialisation
Set @nErrorCode			= 0
Set @pnRowCount			= 0
Set @nOutRequestsRowCount	= 0
Set @nCount			= 1
Set @sSelect			= 'Select '
Set @sFrom			= 'from TABLECODES TC'
Set @String 			= 'S'
Set @sJoin			= ''

If @nErrorCode = 0
Begin 
	-- Filter criteria is always provided with at least TableTypeKey so retrieve it using element-centric mapping: 
		
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML			
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	Set @sSQLString = 	
	"Select @sKey			= FKey,"+CHAR(10)+
	"	@sPickListSearch	= upper(PickListSearch),"+CHAR(10)+
	"	@sDescription		= upper(Description),"+CHAR(10)+
	"	@nDescriptionOperator	= DescriptionOperator,"+CHAR(10)+	
	"	@sOffice		= upper(Office),"+CHAR(10)+	
	"	@nOfficeOperator	= OfficeOperator,"+CHAR(10)+	
	"	@sBarCode		= upper(BarCode),"+CHAR(10)+
	"	@nOfficeOperator	= BarCodeOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '/ipw_ListFileLocations/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      FKey			nvarchar(10)	'Key/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(80)	'PickListSearch/text()',"+CHAR(10)+	
	"	      Description		nvarchar(80)	'Description/text()',"+CHAR(10)+
	"	      DescriptionOperator	tinyint		'Description/@Operator/text()',"+CHAR(10)+
	"	      Office			nvarchar(80)	'Office/text()',"+CHAR(10)+	
	"	      OfficeOperator		tinyint		'Office/@Operator/text()',"+CHAR(10)+
	"	      BarCode			nvarchar(80)	'BarCode/text()',"+CHAR(10)+	
	"	      BarCodeOperator		tinyint		'BarCode/@Operator/text()'"+CHAR(10)+	
	"	     )"		
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc			int,
					  @sKey			nvarchar(10)		output,
					  @sPickListSearch	nvarchar(80)		output,
				          @sDescription		nvarchar(80)		output,
					  @nDescriptionOperator tinyint			output,
					  @sOffice		nvarchar(80)		output,
					  @nOfficeOperator	tinyint			output,
					  @sBarCode		nvarchar(50)		output,
					  @nBarCodeOperator	tinyint			output',
					  @idoc			= @idoc,
					  @sKey			= @sKey			output,
					  @sPickListSearch	= @sPickListSearch	output,
					  @sDescription		= @sDescription		output,
					  @nDescriptionOperator	= @nDescriptionOperator output,
					  @sOffice		= @sOffice		output,
					  @nOfficeOperator	= @nOfficeOperator      output,				  	  
					  @sBarCode	        = @sBarCode	        output,
					  @nBarCodeOperator     = @nBarCodeOperator	output	

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End
		
-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
If (datalength(@ptXMLOutputRequests) = 0
or datalength(@ptXMLOutputRequests) is null)
and @nErrorCode = 0
Begin
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 2)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY  
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End
Else If @nErrorCode = 0
--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
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
	
        If @nErrorCode=0
	Begin
		If @sColumn = 'Key'
		Begin
			Set @sTableColumn='TC.TABLECODE'
		End

		Else If @sColumn='Description'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura) 			
		End

		Else If @sColumn='BarCode'
		Begin
			Set @sTableColumn='TC.USERCODE'
		End

		
		Else If @sColumn = 'OfficeDescription'
		Begin
			If charindex('left join FILELOCATIONOFFICE FO',@sJoin)=0
			Begin
				Set @sJoin = @sJoin + char(10) + 'left join FILELOCATIONOFFICE FO on (FO.FILELOCATIONID = TC.TABLECODE)'
				Set @sJoin = @sJoin + char(10) + 'left join OFFICE O on (O.OFFICEID = FO.OFFICEID)'
			End
		
			Set @sTableColumn = dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,@pbCalledFromCentura) 			
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
		values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)

		Set @nErrorCode = @@ERROR
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
	Set @nErrorCode=@@Error
End

-- Now construct the Order By clause

If @nErrorCode=0
Begin		
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
	
If @nErrorCode = 0
Begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	Set @sWhere = char(10)+"WHERE TC.TABLETYPE = 10"	
	
		
	If @sKey is not NULL
	Begin
	        Set @sWhere = @sWhere+char(10)+"and TC.TABLECODE = " + @sKey
	End	
		
	If @sDescription is not NULL
	or @nDescriptionOperator between 2 and 6
	Begin					
		Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+") " 
		+ dbo.fn_ConstructOperator(@nDescriptionOperator,@String,@sDescription, null,0)
	End	
	
	If @sBarCode is not NULL
	or @nBarCodeOperator between 2 and 6
	Begin
			Set @sWhere = @sWhere+char(10)+"and upper(TC.USERCODE) " + dbo.fn_ConstructOperator(@nBarCodeOperator,@String,@sBarCode, null,0)
	End
	
	If @sOffice is not NULL
	or @nOfficeOperator between 2 and 6
	Begin
			Set @sWhere = @sWhere+char(10)+"and upper(O.DESCRIPTION) " + dbo.fn_ConstructOperator(@nOfficeOperator,@String,@sOffice, null,0)
	End			
	
	-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
	-- is produced.  The search only continues to the next criterion if no rows were located.
				
	If @sPickListSearch is not null
	Begin
	
	        -- If the length of PickListSearch does not exceed the maximum length of the Code				
	        If LEN(@sPickListSearch) <= 10
	        Begin
        	
	                Set @bExists = 0
		        -- Check if Code Equals To PickListSearch
		        Set @sSQLString = "Select @bExists=1"+char(10)+
				        "from TABLECODES TC"+char(10)+
				        @sWhere+
				        "and (upper(TC.USERCODE)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
        				
		        exec @nErrorCode =  sp_executesql @sSQLString,
		                N'@bExists		bit		OUTPUT,
			          @sPickListSearch	nvarchar(80)',
			          @bExists		= @bExists 	OUTPUT,
			          @sPickListSearch	= @sPickListSearch
        				
		        If @bExists=1
		        Begin
			        Set @sWhere=@sWhere+char(10)+"and (upper(TC.USERCODE)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
	                End
		        Else
		        Begin
			        Set @sWhere=@sWhere+char(10)+"and (upper(TC.USERCODE) like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+ 
	                                " or upper("+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+") like " 
	                                + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
		        End
	        End
	        Else 
	        Begin
	                Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+") like "
	                        + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
	        End
				
	End
End
	
If @nErrorCode=0
Begin
	-- Now execute the constructed SQL to return the result set
	exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sJoin + @sWhere + @sOrder)
	
	select 	@nErrorCode =@@Error,
		@pnRowCount=@@Rowcount
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListFileLocations  to public
GO


