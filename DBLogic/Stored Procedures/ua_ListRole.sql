-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListRole
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListRole]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListRole.'
	Drop procedure [dbo].[ua_ListRole]
End
Print '**** Creating Stored Procedure dbo.ua_ListRole...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ua_ListRole
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 110, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	ua_ListRole
-- VERSION:	20
-- DESCRIPTION:	Returns the requested Role information, for groups that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 31 Mar 2004	TM	RFC917	1	Procedure created
-- 11 Jun 2004	TM	RFC1499	2	Default @pnQueryContextKey parameter to 110 instead of 90.
-- 18 Jun 2004	TM	RFC1499	3	New filter criteria IsProtected to be added. If IsProtected = 0 then 
--					only roles that are not special system roles will be returned. Remove 
--					the columns that are no longer in use - PortalKey, PortalName, 
--					PortalDescription. Remove the filter criteria that is no longer 
--					in use - PortalKey. Correct the TopicKey filtering logic.
-- 25 Jun 2004	JEK	RFC1499	4	Implement IsProtected column.
-- 11 Aug 2004	TM	RFC1500	5	Change the stored procedure to implement the new filter criteria required:
--					Web Part (Module) permission, Task permission, Subject (DataTopic) permission.
--					Remove existing TaskKey filtering. The existing topic columns are implemented
--					using the old RoleTopic table. Remove these columns as they would require 
--					a change in implementation as well as more work to indicate what permissions
--					were available.
-- 23 Aug 2004	TM	RFC15000 6	Prepare all embedded literals with fn_WrapQuotes.
-- 02 Sep 2004	JEK	RFC1377	 7	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 20 Sep 2004	JEK	RFC1826	 8	Change Role.Description from ntext to nvarchar(1000).
-- 22 Sep 2004	TM	RFC886	 9	Implement translation.
-- 23 Sep 2004	TM	RFC1500	 10	Correct the PermissionsGroup filter criteria logic to cater for multiple 
--					permissions elements.
-- 30 Sep 2004	JEK	RFC1695 11	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 13 Oct 2004	TM	RFC1898	12	Correct the Permissions filter criteria logic.
-- 15 May 2005	JEK	RFC2508	13	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	14	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 24 Oct 2005	TM	RFC3024	15	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 22 Mar 2006  IB	RFC3212 16	When called by an external user do not return roles marked for internal use only.
-- 13 Jul 2006	SW	RFC3828	17	Pass getdate() to fn_Permission..
-- 03 Dec 2007	vql	RFC5909	18	Change RoleKey and DocumentDefId from smallint to int.
-- 07 Jul 2011	DL	RFC10830 19	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 31 Oct 2018	DL	DR-45102	20	Replace control character (word hyphen) with normal sql editor hyphen

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	RoleKey
--	RoleName
--	Description
--	IsExternal
--	IsProtected

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	R

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
Declare @nRoleKey	 			int	-- The database key of the Role.  
Declare @nRoleKeyOperator	 		tinyint
Declare @sPickListSearch 			nvarchar(254)	-- The text entered by a user in a pick list field to locate appropriate entries.  
Declare @sRoleName				nvarchar(254)	-- The name of the role; e.g. Fee Earner, System Administrator.
Declare @nRoleNameOperator			tinyint
Declare	@sDescription 	 			nvarchar(1000)	-- A description of the purpose and function of the role.
Declare	@nDescriptionOperator 	 		tinyint
Declare	@bIsExternal				bit		-- True for roles that are for external (client) users of the system.
Declare @bIsProtected				bit		-- Indicates whether the role is a special system role.

-- Permissions Group Filter Criteria
Declare @nPermissionsOperator			tinyint
Declare @sObjectTable				nvarchar(30)	-- Returns roles that have permissions defined for this type of object; e.g. MODULE, DATATOPIC, TASK.
Declare	@nObjectIntegerKey 			int		-- Returns roles that have permissions for a particular object.  
Declare	@sObjectStringKey			nvarchar(30)	-- Returns roles that have permissions for a particular object.  
Declare @bPermissionIsDenied 			bit		-- Indicates whether the permission has been denied.  The default is to search for granted permissions.
Declare @nPermission				tinyint		-- Set to 1 (Granted) or 2 (Denied) depending on the value of the @bPermissionIsDenied filter criteria. 
Declare @nPermissionsGroupIndex			tinyint		-- The Permissions filter criteria element.
Declare @nPermissionsGroupCount			tinyint		-- The number of the Permission filter criteria elements within the supplied FilterCriteria XML.
Declare @sCorrelationName			nvarchar(20)
-- Only entries set to 1 are tested. Roles are returned where 
-- all the marked object permissions are present.  
-- Note: permissions set to 0 or absent are not tested.
Declare @bCanSelect				bit
Declare @bIsMandatory				bit
Declare @bCanInsert				bit
Declare @bCanUpdate				bit
Declare @bCanDelete				bit
Declare @bCanExecute				bit

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
Declare	@bIsExternalUser	bit
Declare @dtToday		datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				="Select "
set 	@sFrom					= char(10)+"From ROLE R"
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
	-- Default @pnQueryContextKey to 110.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 110)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End

-- Select @bIsExternalUser from UserIdentity.
If @nErrorCode=0
Begin		
	Set @sSQLString='
	Select @bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End	
	
-- Restrict access to external roles when called by an external user
If @bIsExternalUser = 1
Begin
	Set @sWhere = @sWhere+char(10)+"and (R.ISEXTERNAL = 1 or R.ISEXTERNAL is null)" 				   
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
		If @sColumn='RoleKey'
		Begin
			Set @sTableColumn='R.ROLEID'
		End
		Else 
		If @sColumn='RoleName'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('ROLE','ROLENAME',null,'R',@sLookupCulture,@pbCalledFromCentura) 
		End
		Else 
		If @sColumn = 'Description'
		Begin
			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By				

			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('ROLE','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura) 
		End
		If @sColumn = 'IsExternal'
		Begin
			Set @sTableColumn='R.ISEXTERNAL'
		End
		
		If @sColumn = 'IsProtected'
		Begin
			Set @sTableColumn='R.ISPROTECTED'
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
	"Select @nRoleKey			= RoleKey,"+CHAR(10)+
	"	@nRoleKeyOperator		= RoleKeyOperator,"+CHAR(10)+
	"	@sPickListSearch		= upper(PickListSearch),"+CHAR(10)+
	"	@sRoleName			= upper(RoleName),"+CHAR(10)+
	"	@nRoleNameOperator		= RoleNameOperator,"+CHAR(10)+
	"	@sDescription			= Description,"+CHAR(10)+	
	"	@nDescriptionOperator		= DescriptionOperator,"+CHAR(10)+	
	"	@bIsExternal			= IsExternal,"+CHAR(10)+	
	"	@bIsProtected			= IsProtected"+CHAR(10)+	
	"from	OPENXML (@idoc, '/ua_ListRole/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      RoleKey			int	'RoleKey/text()',"+CHAR(10)+
	"	      RoleKeyOperator		tinyint		'RoleKey/@Operator/text()',"+CHAR(10)+	
	"	      PickListSearch		nvarchar(254)	'PickListSearch/text()',"+CHAR(10)+	
	"	      RoleName			nvarchar(254)	'RoleName/text()',"+CHAR(10)+	
	"	      RoleNameOperator		tinyint		'RoleName/@Operator/text()',"+CHAR(10)+	
	"	      Description		nvarchar(1000)	'Description/text()',"+CHAR(10)+	
	"	      DescriptionOperator	tinyint		'Description/@Operator/text()',"+CHAR(10)+		
	"	      IsExternal		bit		'IsExternal/text()',"+CHAR(10)+	
	"	      PortalKey			int		'PortalKey/text()',"+CHAR(10)+	
	"	      PortalKeyOperator		tinyint		'PortalKey/@Operator/text()',"+CHAR(10)+	
	"	      IsProtected		bit		'IsProtected/text()'"+CHAR(10)+		
	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nRoleKey 			int			output,
				  @nRoleKeyOperator		tinyint				output,				  		
				  @sPickListSearch		nvarchar(254)			output,
				  @sRoleName			nvarchar(254)			output,		
				  @nRoleNameOperator		tinyint				output,		
				  @sDescription			nvarchar(1000)			output,
				  @nDescriptionOperator		tinyint				output,
				  @bIsExternal			bit				output,
				  @bIsProtected			bit				output,
				  @nPermissionsOperator		tinyint				output,
				  @sObjectTable			nvarchar(30)			output,
				  @nObjectIntegerKey		int				output,
				  @sObjectStringKey		nvarchar(30)			output,
				  @bPermissionIsDenied		bit				output,
				  @bCanSelect			bit				output,
				  @bIsMandatory			bit				output,
				  @bCanInsert			bit				output,
				  @bCanUpdate			bit				output,
				  @bCanDelete			bit				output,
				  @bCanExecute			bit				output',
				  @idoc				= @idoc,
				  @nRoleKey 			= @nRoleKey			output,
				  @nRoleKeyOperator		= @nRoleKeyOperator		output,
				  @sPickListSearch		= @sPickListSearch		output,				  		
				  @sRoleName			= @sRoleName			output,
				  @nRoleNameOperator 		= @nRoleNameOperator		output,
				  @sDescription			= @sDescription 		output,
				  @nDescriptionOperator		= @nDescriptionOperator		output,
				  @bIsExternal			= @bIsExternal			output,
				  @bIsProtected			= @bIsProtected			output,
				  @nPermissionsOperator		= @nPermissionsOperator		output,
				  @sObjectTable			= @sObjectTable			output,
				  @nObjectIntegerKey		= @nObjectIntegerKey		output,
				  @sObjectStringKey		= @sObjectStringKey		output,
				  @bPermissionIsDenied		= @bPermissionIsDenied		output,
				  @bCanSelect			= @bCanSelect			output,
				  @bIsMandatory			= @bIsMandatory			output,
				  @bCanInsert			= @bCanInsert			output,
				  @bCanUpdate			= @bCanUpdate			output,
				  @bCanDelete			= @bCanDelete			output,
				  @bCanExecute			= @bCanExecute			output  				  				  	
	
	-- Find out how many permission elements are in the supplied filter criteria XML:
	Set @sSQLString = " 	
	Select	@nPermissionsGroupCount = count(*)
			from	OPENXML (@idoc, '/ua_ListRole/FilterCriteria/PermissionsGroup/Permissions',2)
			WITH (
			      id int '@mp:id'		   
			     )"		

	exec @nErrorCode = sp_executesql @sSQLString,
						N'@idoc				int,
						  @nPermissionsGroupCount	tinyint			 output',
						  @idoc				= @idoc,
						  @nPermissionsGroupCount	=@nPermissionsGroupCount output
	
	-- Set @nPermissionsGroupIndex to 1 so it points to the first Permission Element	
	Set @nPermissionsGroupIndex = 1
		
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
	
		If @nRoleKey is not NULL
		or @nRoleKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and R.ROLEID " + dbo.fn_ConstructOperator(@nRoleKeyOperator,@Numeric,@nRoleKey, null,0)  
		End		

		If @sRoleName is not NULL
		or @nRoleNameOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('ROLE','ROLENAME',null,'R',@sLookupCulture,@pbCalledFromCentura)+") " + dbo.fn_ConstructOperator(@nRoleNameOperator,@String,@sRoleName, null,0)
		End	

		If @sDescription is not NULL
		or @nDescriptionOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and "+dbo.fn_SqlTranslatedColumn('ROLE','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura)+" " + dbo.fn_ConstructOperator(@nDescriptionOperator,@String,@sDescription, null,0)
		End			
	
		If @bIsExternal is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and R.ISEXTERNAL = " + CAST(@bIsExternal as nchar(1)) 	  				   
		End	

		-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
		-- is produced.  The search only continues to the next criterion if no rows were located.
			
		If @sPickListSearch is not null
		Begin
			Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('ROLE','ROLENAME',null,'R',@sLookupCulture,@pbCalledFromCentura)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)				
		End

		If @bIsProtected is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and R.ISPROTECTED = " + CAST(@bIsProtected as nchar(1)) 	  				   
		End	

		While @nPermissionsGroupIndex<=@nPermissionsGroupCount
		Begin				
			Set @sCorrelationName = 'PD_' + cast(@nPermissionsGroupIndex as nvarchar(20))

			Set @sSQLString = 				
			"Select @nPermissionsOperator		= PermissionsOperator,"+CHAR(10)+	
			"	@sObjectTable			= ObjectTable,"+CHAR(10)+	
			"	@nObjectIntegerKey		= ObjectIntegerKey,"+CHAR(10)+	
			"	@sObjectStringKey		= ObjectStringKey,"+CHAR(10)+	
			"	@bPermissionIsDenied		= PermissionIsDenied,"+CHAR(10)+	
			"	@bCanSelect			= CanSelect,"+CHAR(10)+	
			"	@bIsMandatory			= IsMandatory,"+CHAR(10)+	
			"	@bCanInsert			= CanInsert,"+CHAR(10)+	
			"	@bCanUpdate			= CanUpdate,"+CHAR(10)+	
			"	@bCanDelete			= CanDelete,"+CHAR(10)+	
			"	@bCanExecute			= CanExecute"+CHAR(10)+	
			"from	OPENXML (@idoc, '/ua_ListRole/FilterCriteria/PermissionsGroup/Permissions["+convert(nvarchar(3), @nPermissionsGroupIndex)+"]',2)"+CHAR(10)+
			"	WITH ("+CHAR(10)+
			"	      PermissionsOperator	tinyint		'@Operator/text()',"+CHAR(10)+	
			"	      ObjectTable		nvarchar(30)	'ObjectTable/text()',"+CHAR(10)+	
			"	      ObjectIntegerKey		int		'ObjectIntegerKey/text()',"+CHAR(10)+	
			"	      ObjectStringKey		nvarchar(30)	'ObjectStringKey/text()',"+CHAR(10)+	
			"	      PermissionIsDenied	bit		'Permission/@IsDenied',"+CHAR(10)+	
			"	      CanSelect			bit		'Permission/CanSelect',"+CHAR(10)+	
			"	      IsMandatory		bit		'Permission/IsMandatory',"+CHAR(10)+	
			"	      CanInsert			bit		'Permission/CanInsert',"+CHAR(10)+	
			"	      CanUpdate			bit		'Permission/CanUpdate',"+CHAR(10)+	
			"	      CanDelete			bit		'Permission/CanDelete',"+CHAR(10)+	
			"	      CanExecute		bit		'Permission/CanExecute'"+CHAR(10)+	
		     	"     	     )"

			exec @nErrorCode = sp_executesql @sSQLString,
						N'@idoc				int,
						  @nPermissionsOperator		tinyint				output,
						  @sObjectTable			nvarchar(30)			output,
						  @nObjectIntegerKey		int				output,
						  @sObjectStringKey		nvarchar(30)			output,
						  @bPermissionIsDenied		bit				output,
						  @bCanSelect			bit				output,
						  @bIsMandatory			bit				output,
						  @bCanInsert			bit				output,
						  @bCanUpdate			bit				output,
						  @bCanDelete			bit				output,
						  @bCanExecute			bit				output',
						  @idoc				= @idoc,
						  @nPermissionsOperator		= @nPermissionsOperator		output,
						  @sObjectTable			= @sObjectTable			output,
						  @nObjectIntegerKey		= @nObjectIntegerKey		output,
						  @sObjectStringKey		= @sObjectStringKey		output,
						  @bPermissionIsDenied		= @bPermissionIsDenied		output,
						  @bCanSelect			= @bCanSelect			output,
						  @bIsMandatory			= @bIsMandatory			output,
						  @bCanInsert			= @bCanInsert			output,
						  @bCanUpdate			= @bCanUpdate			output,
						  @bCanDelete			= @bCanDelete			output,
						  @bCanExecute			= @bCanExecute			output  				  				  	
		
			If @sObjectTable is not null
			or @nObjectIntegerKey is not null
			or @sObjectStringKey is not null 
			or @nPermissionsOperator between 2 and 6
			Begin
				-- If Operator is set to IS NULL then use NOT EXISTS
				If @nPermissionsOperator in (1, 6)
				Begin
					set @sWhere =@sWhere+char(10)+"and not exists"
				End
				Else 
				Begin
					Set @sWhere =@sWhere+char(10)+"and exists"
				End
	
				Set @sWhere = @sWhere+char(10)+"(Select 1 "  
						     +char(10)+" from dbo.fn_PermissionData("
						     +char(10)+"	"+dbo.fn_WrapQuotes('ROLE',0,0) +","
						     +char(10)+"        "+CASE WHEN @nRoleKey 		IS NOT NULL THEN CAST(@nRoleKey as varchar(5)) 		ELSE 'Null' END+"," 
						     +char(10)+"	"+CASE WHEN @sObjectTable 	IS NOT NULL THEN dbo.fn_WrapQuotes(@sObjectTable,0,0) 	ELSE 'Null' END+","
						     +char(10)+"	"+CASE WHEN @nObjectIntegerKey  IS NOT NULL THEN CAST(@nObjectIntegerKey as varchar(10))ELSE 'Null' END+","
						     +char(10)+"	"+CASE WHEN @sObjectStringKey   IS NOT NULL THEN dbo.fn_WrapQuotes(@sObjectStringKey,0,0) ELSE 'Null' END+","
						     +char(10)+"	'"+cast(@dtToday as nvarchar(20))+"') "+@sCorrelationName						     
						     +char(10)+" where  "+@sCorrelationName+".LevelKey = R.ROLEID"	
	
				-- IsDenied=1 returns denied perissions otherwise returns 
				-- granted permissions:
				Set @nPermission = CASE WHEN @bPermissionIsDenied = 1 
							THEN 2  
							ELSE 1
						   END
	 
				-- Only entries set to 1 are tested. Roles are returned where all the marked object
				-- permissions are present.  Note: permissions set to 0 or absent are not tested.
				If @bCanSelect = 1	
				Begin
					Set @sWhere = @sWhere+char(10)+" and "+@sCorrelationName+".SelectPermission = "+cast(@nPermission as char(1))
				End
	
				If @bIsMandatory = 1	
				Begin
					Set @sWhere = @sWhere+char(10)+" and "+@sCorrelationName+".MandatoryPermission = "+cast(@nPermission as char(1))
				End
	
				If @bCanInsert = 1	
				Begin
					Set @sWhere = @sWhere+char(10)+" and "+@sCorrelationName+".InsertPermission = "+cast(@nPermission as char(1))
				End
	
				If @bCanUpdate = 1	
				Begin
					Set @sWhere = @sWhere+char(10)+" and "+@sCorrelationName+".UpdatePermission = "+cast(@nPermission as char(1))
				End
	
				If @bCanDelete = 1	
				Begin
					Set @sWhere = @sWhere+char(10)+" and "+@sCorrelationName+".DeletePermission = "+cast(@nPermission as char(1))
				End
	
				If @bCanExecute = 1	
				Begin
					Set @sWhere = @sWhere+char(10)+" and "+@sCorrelationName+".ExecutePermission = "+cast(@nPermission as char(1))
				End
	
				Set @sWhere = @sWhere+")"		
			End	

			Set @nPermissionsGroupIndex = @nPermissionsGroupIndex + 1
		End	-- end of while loop
	End

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
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

Grant execute on dbo.ua_ListRole to public
GO
