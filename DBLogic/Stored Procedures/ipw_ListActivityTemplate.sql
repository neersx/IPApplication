-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListActivityTemplate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListActivityTemplate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListActivityTemplate.'
	Drop procedure [dbo].[ipw_ListActivityTemplate]
	Print '**** Creating Stored Procedure dbo.ipw_ListActivityTemplate...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListActivityTemplate
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 960, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	[ipw_ListActivityTemplate]
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists the Exchange Rate Variation records on the basis of Filter Criteria

-- MODIFICATIONS :
-- Date		Who	Change	Version		Description
-- -----------	-------	------	----------	----------------------------------------------- 
-- 25 Sep 2014	DV	R26412		1	Procedure created
-- 23 Mar 2020	BS	DR-57435 	2	DB public role missing execute permission on some stored procedures and functions

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)

Declare @sLookupCulture			nvarchar(10)

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
Declare @sActivityTemplateCode 			nvarchar(10)	-- The unique code (primary key) of the ad hoc template. Case insensitive search.
Declare @nActivityTemplateCodeOperator		tinyint		
Declare @sPickListSearch			nvarchar(254)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.
Declare @bExists				bit
Declare @sTemplateMessage			nvarchar(254)	-- The template reminder message. Case insensitive search.
Declare @nTemplateMessageOperator		tinyint
Declare @bIsExternalUser			bit

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
Set	@CommaString			='CS'


Set 	@nErrorCode = 0

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit		  OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

-- Initialise variables
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+"From ACTIVITYTEMPLATE A"
set 	@sWhere 				= char(10)+"	WHERE A.ISEXTERNAL=" + convert(char(1), @bIsExternalUser)

if(@bIsExternalUser=1)
Begin
	Set @sFrom = @sFrom +CHAR(10)+"join USERIDENTITY U on (U.ACCOUNTID=A.ACCESSACCOUNTID and U.IDENTITYID=" + convert(nvarchar,@pnUserIdentityId) + ")"
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
	-- Default @pnQueryContextKey to 960.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 960)

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
		If @sColumn='ActivityTemplateCode'
		Begin
			Set @sTableColumn='A.ACTIVITYTEMPLATECODE'
		End
		
		Else If @sColumn = 'ActivityCategory'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join TABLECODES T on (T.TABLECODE=A.ACTIVITYCATEGORY)'
		End
		
		Else If @sColumn = 'Notes'
		Begin
			Set @sTableColumn='A.NOTES'
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

	-- 1) Retrieve filter criteria using element-centric mapping (implement 
	--    Case Insensitive searching)   
	Set @sSQLString = 	
	"Select @sActivityTemplateCode		= upper(ActivityTemplateCode),"+CHAR(10)+
	"	@nActivityTemplateCodeOperator	= ActivityTemplateCodeOperator,"+CHAR(10)+
	"	@sPickListSearch		= upper(PickListSearch),"+CHAR(10)+
	"	@sTemplateMessage		= upper(TemplateMessage),"+CHAR(10)+
	"	@nTemplateMessageOperator	= TemplateMessageOperator"+CHAR(10)+	
	"from	OPENXML (@idoc, '//ipw_ListActivityTemplate/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      ActivityTemplateCode		nvarchar(10)	'ActivityTemplateCode/text()',"+CHAR(10)+
	"	      ActivityTemplateCodeOperator	tinyint		'ActivityTemplateCode/@Operator/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(254)	'PickListSearch/text()',"+CHAR(10)+	
	"	      TemplateMessage		nvarchar(254)	'TemplateMessage/text()',"+CHAR(10)+
 	"	      TemplateMessageOperator	tinyint		'TemplateMessage/@Operator/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sActivityTemplateCode 		nvarchar(10)		output,
				  @nActivityTemplateCodeOperator	tinyint			output,
				  @sPickListSearch		nvarchar(254)		output,
				  @sTemplateMessage		nvarchar(254)		output,	
				  @nTemplateMessageOperator	tinyint			output',
				  @idoc				= @idoc,
				  @sActivityTemplateCode 		= @sActivityTemplateCode		output,
				  @nActivityTemplateCodeOperator	= @nActivityTemplateCodeOperator	output,
				  @sPickListSearch		= @sPickListSearch		output,
				  @sTemplateMessage		= @sTemplateMessage		output,
				  @nTemplateMessageOperator	= @nTemplateMessageOperator	output		
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
	
		If @sActivityTemplateCode is not NULL
		or @nActivityTemplateCodeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and UPPER(A.ACTIVITYTEMPLATECODE) " + dbo.fn_ConstructOperator(@nActivityTemplateCodeOperator,@String,@sActivityTemplateCode, null,0)
		End
		
		-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
		-- is produced.  The search only continues to the next criterion if no rows were located.
			
		If @sPickListSearch is not null
		Begin
			-- If the length of PickListSearch does not exceed the maximum length of the Code
			
			If LEN(@sPickListSearch) <= 20
			Begin
				Set @bExists = 0
				-- Check if Code Equals To PickListSearch
				Set @sSQLString = "Select @bExists=1"+char(10)+
						  "from ACTIVITYTEMPLATE A"+char(10)+
						  @sWhere+
						  "and (UPPER(A.ACTIVITYTEMPLATECODE)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
			
				exec @nErrorCode =  sp_executesql @sSQLString,
							N'@bExists		bit		OUTPUT,
							  @sPickListSearch	nvarchar(254)',
							  @bExists		= @bExists 	OUTPUT,
							  @sPickListSearch	= @sPickListSearch
			
				If @bExists=1
				Begin
					Set @sWhere=@sWhere+char(10)+"and (UPPER(A.ACTIVITYTEMPLATECODE)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
				End
				Else
				Begin
					Set @sWhere=@sWhere+char(10)+"and (UPPER(A.ACTIVITYTEMPLATECODE) like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
				End
			End			
		End	
	End
End

If @nErrorCode=0
Begin   
	-- Now execute the constructed SQL to return the result set
	exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant exec on dbo.ipw_ListActivityTemplate to Public
go