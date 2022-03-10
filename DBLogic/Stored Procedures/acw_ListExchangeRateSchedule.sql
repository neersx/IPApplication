-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListExchangeRateSchedule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListExchangeRateSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListExchangeRateSchedule.'
	Drop procedure [dbo].[acw_ListExchangeRateSchedule]
	Print '**** Creating Stored Procedure dbo.acw_ListExchangeRateSchedule...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListExchangeRateSchedule
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 820, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.
	@pbCalledFromCentura		bit 		= 0,					
	@pbIsDebugMode			bit	 	= 0
)
as
-- PROCEDURE:	acw_ListExchangeRateSchedule
-- VERSION:	2
-- DESCRIPTION:	Returns the requested information for Exchange Rate schedule that match the filter criteria provided.
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- ------------	-------	------		-------	----------------------------------------------- 
-- 23 Jun 2010	DV	RFC7350		1	Procedure created 
-- 11 Jul 2011	DL	RFC19795	2	Specify Collation Database Default for temp table.



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
Declare @sPickListSearch		nvarchar(50)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.
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
set 	@sFrom					= char(10)+"From EXCHRATESCHEDULE E"
set 	@sWhere 				= char(10)+"	WHERE 1=1"
set		@sOrder					= char(10)+" E.EXCHSCHEDULECODE"

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
	-- Default @pnQueryContextKey to 820.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 820)

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
		If @sColumn='ExchangeRateKey'
		Begin
			Set @sTableColumn='E.EXCHSCHEDULEID'
		End
		If @sColumn='ExchangeKey'
		Begin
			Set @sTableColumn='E.EXCHSCHEDULEID'
		End
		If @sColumn='ExchangeRateCode'
		Begin
			Set @sTableColumn='E.EXCHSCHEDULECODE'
		End
		Else 
		If @sColumn = 'ExchangeRateDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) 
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
	"Select @sPickListSearch		= upper(PickListSearch)"+CHAR(10)+	
	"from	OPENXML (@idoc, '/acw_ListExchangeRateSchedule/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+	
 	"	      PickListSearch		nvarchar(50)	'PickListSearch/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sPickListSearch		nvarchar(50)		output',
				  @idoc				= @idoc,
				  @sPickListSearch		= @sPickListSearch	output			
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
	
	If @nErrorCode = 0
	Begin
		If @sPickListSearch is not null
		Begin
			Set @bExists = 0
				-- Check if Code Equals To PickListSearch
				Set @sSQLString = "Select @bExists=1"+char(10)+
						  "from EXCHRATESCHEDULE E"+char(10)+
						  @sWhere+
						  "and (E.EXCHSCHEDULECODE=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
			
				exec @nErrorCode =  sp_executesql @sSQLString,
							N'@bExists		bit		OUTPUT,
							  @sPickListSearch	nvarchar(50)',
							  @bExists		= @bExists 	OUTPUT,
							  @sPickListSearch	= @sPickListSearch
			
				If @bExists=1
				Begin
					Set @sWhere=@sWhere+char(10)+"and (E.EXCHSCHEDULECODE=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
				End
				Else
				Begin
					Set @sWhere=@sWhere+char(10)+"and (E.EXCHSCHEDULECODE like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+ 
								     " or upper("+dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
				End
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
go

Grant exec on dbo.acw_ListExchangeRateSchedule to Public
go