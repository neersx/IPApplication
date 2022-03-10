-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListLedgerAccount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListLedgerAccount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListLedgerAccount.'
	Drop procedure [dbo].[acw_ListLedgerAccount]
End
Print '**** Creating Stored Procedure dbo.acw_ListLedgerAccount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListLedgerAccount
(
	@pnRowCount			int 		= null	        output,
	@pnUserIdentityId		int,			        -- Mandatory
	@psCulture			nvarchar(10)	= null,         -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 210, 	        -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null,         -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	        -- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	acw_ListLedgerAccount
-- VERSION:	2
-- DESCRIPTION:	Returns the requested Ledger Account information, for accounts that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Jun 2011	MS	RFC7998	1	Procedure created
-- 21 Sep 2012 DL	R12763	2	Fix collation error by adding 'collate database_default' to character based columns in temp table definition.


-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	AccountKey
--	AccountCode
--	AccountDescription
--	AccountTypeKey
--      AccountType
--      ParentAccountKey
--      ParentAccountCode
--      ParentAccountDescription
--      DisburseToWIP
--      BudgetMovement

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	LA1
--	LA2
--	TC

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sSQLString			nvarchar(4000)
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
Declare @nAccountKey 				int     	-- The primary key of the Ledger account. This is user modifiable, so also acts as the Ledger account code.The data is held on the database in upper case. Always convert search string to upper case.
Declare @nAccountKeyOperator			tinyint	
Declare @sAccountCode                           nvarchar(100)
Declare @nAccountCodeOperator			tinyint		
Declare @sDescription				nvarchar(100)	-- The description of the Ledger account. Case insensitive search.
Declare @nDescriptionOperator			tinyint
Declare @sPickListSearch			nvarchar(110)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.
Declare @bExists				bit

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
set 	@sFrom					= char(10)+"From LEDGERACCOUNT LA1"
set 	@sWhere 				= char(10)+"	WHERE 1=1"

set @sWhere = @sWhere + char(10)+"AND LA1.ACCOUNTID NOT IN (SELECT DISTINCT LA3.PARENTACCOUNTID  FROM LEDGERACCOUNT LA3 WHERE LA3.PARENTACCOUNTID IS NOT NULL)"
set @sWhere = @sWhere + char(10)+"AND LA1.ISACTIVE = 1"

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
	-- Default @pnQueryContextKey to 210.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 210)

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
		If @sColumn='AccountKey'
		Begin
			Set @sTableColumn='LA1.ACCOUNTID'
		End
		Else 
		If @sColumn='AccountCode'
		Begin
			Set @sTableColumn='LA1.ACCOUNTCODE'
		End
		Else 
		If @sColumn = 'AccountDescription'
		Begin
			Set @sTableColumn='LA1.DESCRIPTION'
		End
		Else 
		If @sColumn in ('AccountTypeKey','AccountType')
		Begin
                        If @sColumn = 'AccountTypeKey'
                        Begin
			        Set @sTableColumn='TC.TABLECODE'
                        End
                        Else
                        Begin
                                Set @sTableColumn='TC.DESCRIPTION'
                        End
			
			If charindex('left join TABLECODES TC',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join TABLECODES TC	on (TC.TABLETYPE = 81 and LA1.ACCOUNTTYPE = TC.TABLECODE)' 							   
			End
		End
                Else
                If @sColumn in ('ParentAccountKey', 'ParentAccountCode', 'ParentAccountDescription')
		Begin
                        If @sColumn = 'ParentAccountKey'
                        Begin
			        Set @sTableColumn='LA2.ACCOUNTID'
                        End
                        Else If @sColumn = 'ParentAccountCode'
                        Begin
                                Set @sTableColumn='LA2.ACCOUNTCODE'
                        End 
                        Else
                        Begin
                                Set @sTableColumn='LA2.DESCRIPTION'
                        End    
			
			If charindex('left outer join LEDGERACCOUNT LA2',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left outer join LEDGERACCOUNT LA2	on (LA1.PARENTACCOUNTID = LA2.ACCOUNTID)' 							   
			End
		End
                Else 
		If @sColumn='DisburseToWIP'
		Begin
			Set @sTableColumn='LA1.DISBURSETOWIP'
		End
                Else 
		If @sColumn='BudgetMovement'
		Begin
			Set @sTableColumn='Case LA1.BUDGETMOVEMENT when 1 then ''Movement'' when 0 then ''Balance'' End'
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
	--    Case Insensitive searching)   

	Set @sSQLString = 	
	"Select @sAccountCode			= upper(AccountCode),"+CHAR(10)+
	"	@nAccountCodeOperator		= AccountCodeOperator,"+CHAR(10)+
	"	@sDescription			= upper(Description),"+CHAR(10)+
	"	@nDescriptionOperator		= upper(DescriptionOperator),"+CHAR(10)+
	"	@sPickListSearch		= upper(PickListSearch)"+CHAR(10)+	
	"from	OPENXML (@idoc, '/acw_ListLedgerAccount/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      AccountCode		nvarchar(100)	'AccountCode/text()',"+CHAR(10)+
	"	      AccountCodeOperator	tinyint		'AccountCode/@Operator/text()',"+CHAR(10)+
	"	      Description		nvarchar(100)	'Description/text()',"+CHAR(10)+	
	"	      DescriptionOperator	tinyint		'Description/@Operator/text()',"+CHAR(10)+
 	"	      PickListSearch		nvarchar(110)	'PickListSearch/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sAccountCode 		nvarchar(100)		output,
				  @nAccountCodeOperator		tinyint			output,
				  @sDescription			nvarchar(100)		output,
				  @nDescriptionOperator		tinyint			output,	
				  @sPickListSearch		nvarchar(110)		output',
				  @idoc				= @idoc,
				  @sAccountCode 		= @sAccountCode		output,
				  @nAccountCodeOperator		= @nAccountCodeOperator	output,
				  @sDescription			= @sDescription		output,
				  @nDescriptionOperator		= @nDescriptionOperator	output,
				  @sPickListSearch		= @sPickListSearch	output			
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin	
		If @sAccountCode is not NULL
		or @nAccountCodeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and LA1.ACCOUNTCODE " + dbo.fn_ConstructOperator(@nAccountCodeOperator,@String,@sAccountCode, null,0)
		End		

		If @sDescription is not NULL
		or @nDescriptionOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('LEDGERACCOUNT','DESCRIPTION',null,'LA1',@sLookupCulture,@pbCalledFromCentura)+") " + dbo.fn_ConstructOperator(@nDescriptionOperator,@String,@sDescription, null,0)
		End	

		-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
		-- is produced.  The search only continues to the next criterion if no rows were located.
			
		If @sPickListSearch is not null
		Begin
			-- If the length of PickListSearch does not exceed the maximum length of the Code
			
			If LEN(@sPickListSearch) <= 100
			Begin
				Set @bExists = 0
				-- Check if Code Equals To PickListSearch
				Set @sSQLString = "Select @bExists=1"+char(10)+
						  "from LEDGERACCOUNT LA1"+char(10)+
						  @sWhere+
						  "and (LA1.ACCOUNTCODE=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
			
				exec @nErrorCode =  sp_executesql @sSQLString,
							N'@bExists		bit		OUTPUT,
							  @sPickListSearch	nvarchar(110)',
							  @bExists		= @bExists 	OUTPUT,
							  @sPickListSearch	= @sPickListSearch
			
				If @bExists=1
				Begin
					Set @sWhere=@sWhere+char(10)+"and (LA1.ACCOUNTCODE=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
				End
				Else
				Begin
					Set @sWhere=@sWhere+char(10)+"and (LA1.ACCOUNTCODE like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+ 
								     " or upper(LA1.DESCRIPTION) like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
				End
			End
			Else 
			Begin
				Set @sWhere=@sWhere+char(10)+"and upper(LA1.DESCRIPTION) like "+ dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
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

Grant execute on dbo.acw_ListLedgerAccount to public
GO
