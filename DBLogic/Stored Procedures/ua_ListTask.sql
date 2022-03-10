-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListTask
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListTask]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListTask.'
	Drop procedure [dbo].[ua_ListTask]
End
Print '**** Creating Stored Procedure dbo.ua_ListTask...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ua_ListTask
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 140 , -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	ua_ListTask
-- VERSION:	16
-- DESCRIPTION:	Returns the requested tasks information, for tasks that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Jul 2004	TM	RFC1500	1	Procedure created
-- 06 Jul 2004  TM	RFC1500	2	Default @pnQueryContextKey to 140 instead of 150.
-- 17 Aug 2004	TM	RFC1500	3	Add new IsInsertApplicable, IsUpdateApplicable, IsDeleteApplicable,
--					and IsExecuteApplicable columns.
-- 23 Aug 2004	TM	RFC1500	4	Use the values of the Permissions columns to return Is Applicable:
--					e.g IsInsertApplicable - cast(PR.InsertPermission as bit). 
-- 02 Sep 2004	JEK	RFC1377	5	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 22 Sep 2004	JEK	RFC1500	6	Change ItemID Name to TaskName to match rules.
-- 22 Sep 2004	TM	RFC886	7	Implement translation.
-- 30 Sep 2004	JEK	RFC1695 8	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 29 Sep 2004	TM	RFC1903	9	Modify translation of the Task.Description as required for a Short Column.
-- 16 Nov 2004	TM	RFC869	10	Implement a full join to fn_ValidObjects to suppress tasks that are not
--					licensed to the firm.
-- 15 May 2005	JEK	RFC2508	11	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	12	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 24 Oct 2005	TM	RFC3024	13	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 12 Jul 2006	SW	RFC3828	14	Pass getdate() to fn_Permission..
-- 15 Sep 2006	LP	RFC4414	15	Remove @dtToday argument when calling dbo.fn_PermissionRule
-- 07 Jul 2011	DL	RFC10830 16	Specify database collation default to temp table columns of type varchar, nvarchar and char


-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	IsInsertApplicable 
--	IsUpdateApplicable
--	IsDeleteApplicable
--	IsExecuteApplicable
--	TaskKey
--	TaskName
--	Description 

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	T

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)

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
Declare @sPickListSearch 			nvarchar(254)	-- The text entered by a user in a pick list field to locate appropriate entries.  
Declare	@nTaskKey				smallint	-- The database key of the task.
Declare	@nTaskKeyOperator			tinyint
Declare @sName					nvarchar(254)	-- The name of the task. Case insensitive search.
Declare	@nNameOperator				tinyint

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

Declare @sLookupCulture		nvarchar(10)
Declare @dtToday		datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				="Select "
set 	@sFrom					= char(10)+"From TASK T"
						 -- Suppress tasks that are not licensed to the firm
						 +char(10)+"join dbo.fn_ValidObjects(null, 'TASK', '" + cast(@dtToday as nvarchar(20)) + "') VO"
					 	 +char(10)+"	  		on (VO.ObjectIntegerKey = T.TASKID)"

set 	@sWhere 				= char(10)+"WHERE 1=1"

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
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 140)

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
		If @sColumn='TaskKey'
		Begin
			Set @sTableColumn='T.TASKID'
		End
		Else 
		If @sColumn='TaskName'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TASK','TASKNAME',null,'T',@sLookupCulture,@pbCalledFromCentura)
		End
		Else 
		If @sColumn = 'Description'
		Begin
			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By				
				
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TASK','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
		End
		Else If @sColumn in (	'IsInsertApplicable',
					'IsUpdateApplicable',
					'IsDeleteApplicable',
					'IsExecuteApplicable') 
		Begin
			If charindex('left join dbo.fn_PermissionRule',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+'left join dbo.fn_PermissionRule(''TASK'', NULL, NULL) PR'
						 +char(10)+'			on (PR.ObjectIntegerKey = T.TASKID)'
			End	

			If @sColumn='IsInsertApplicable'	
			Begin
				Set @sTableColumn='CAST(PR.InsertPermission as bit)'		
			End
			Else If @sColumn='IsUpdateApplicable' 
			Begin
				Set @sTableColumn='CAST(PR.UpdatePermission as bit)'		
			End	
			Else If @sColumn='IsDeleteApplicable' 
			Begin
				Set @sTableColumn='CAST(PR.DeletePermission as bit)'		
			End		
			Else Begin
				Set @sTableColumn='CAST(PR.ExecutePermission as bit)'		
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

	-- 1) Retrieve the Filter Criteria using element-centric mapping (implement 
	--    Case Insensitive searching where required)   

	Set @sSQLString = 	
	"Select @sPickListSearch		= upper(PickListSearch),"+CHAR(10)+
	"	@nTaskKey			= TaskKey,"+CHAR(10)+	
	"	@nTaskKeyOperator		= TaskKeyOperator,"+CHAR(10)+	
	"	@sName				= upper(Name),"+CHAR(10)+
	"	@nNameOperator			= NameOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '/ua_ListTask/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      PickListSearch		nvarchar(254)	'PickListSearch/text()',"+CHAR(10)+	
	"	      TaskKey			smallint	'TaskKey/text()',"+CHAR(10)+	
	"	      TaskKeyOperator		tinyint		'TaskKey/@Operator/text()',"+CHAR(10)+	
	"	      Name			nvarchar(254)	'Name/text()',"+CHAR(10)+	
	"	      NameOperator		tinyint		'Name/@Operator/text()'"+CHAR(10)+		
	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sPickListSearch		nvarchar(254)			output,
				  @nTaskKey			smallint			output,
				  @nTaskKeyOperator		tinyint				output,
				  @sName			nvarchar(254)			output,		
				  @nNameOperator		tinyint				output',
				  @idoc				= @idoc,
				  @sPickListSearch		= @sPickListSearch		output,				  		
				  @nTaskKey			= @nTaskKey			output,
				  @nTaskKeyOperator		= @nTaskKeyOperator		output,
				  @sName			= @sName			output,
				  @nNameOperator 		= @nNameOperator		output

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
		-- The PickListSearch filtering implemented as the following: Portal Name Starts With PickListSearch:			
		If @sPickListSearch is not null
		Begin
			Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('TASK','TASKNAME',null,'T',@sLookupCulture,@pbCalledFromCentura)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)				
		End				

		If @nTaskKey is not NULL
		or @nTaskKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and T.TASKID " + dbo.fn_ConstructOperator(@nTaskKeyOperator,@Numeric,@nTaskKey, null,0)  
		End	
	
		If @sName is not NULL
		or @nNameOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('TASK','TASKNAME',null,'T',@sLookupCulture,@pbCalledFromCentura)+") " + dbo.fn_ConstructOperator(@nNameOperator,@String,@sName, null,0)
		End			
	End
End

If @nErrorCode=0
Begin	
	-- Now execute the constructed SQL to return the result set
	Exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.ua_ListTask to public
GO
