-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListPortal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListPortal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListPortal.'
	Drop procedure [dbo].[ua_ListPortal]
End
Print '**** Creating Stored Procedure dbo.ua_ListPortal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ua_ListPortal
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 120 , -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	ua_ListPortal
-- VERSION:	13
-- DESCRIPTION:	Returns the requested Portal Configuration information, for groups that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Jun 2004	TM	RFC1499	1	Procedure created
-- 17 Aug 2004	TM	RFC1500	2	Implement Selected Roles filter criteria.
-- 02 Sep 2004	JEK	RFC1377	3	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 22 Sep 2004	TM	RFC886	4	Implement translation.
-- 30 Sep 2004	JEK	RFC1695 5	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 15 May 2005	JEK	RFC2508	6	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	7	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 24 Oct 2005	TM	RFC3024	8	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 23 Mar 2006	IB	RFC3212	9	For external users show external portals only.
-- 13 Jul 2006	SW	RFC3828	10	Pass getdate() to fn_Permission..
-- 03 Dec 2007	vql	RFC5909	11	Change RoleKey and DocumentDefId from smallint to int.
-- 07 Jul 2011	DL	RFC10830 12	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 23 Aug 2016	MF	63098	13	Cater for very large RoleKey values by CASTing as nvarchar(11).

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	PortalKey
--	Name
--	Description 
--	IsExternal

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	P

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(max)

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

Declare @sSelectedRoles 			nvarchar(254)	-- The @sSelectedRoles variable holds the comma separated list of the database key of the selected roles.	

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
Declare @sPickListSearch 			nvarchar(50)	-- The text entered by a user in a pick list field to locate appropriate entries.  
Declare	@nPortalKey				int		-- The database key of the default portal configuration (menus, tabs, web parts).  
Declare	@nPortalKeyOperator			tinyint
Declare @sName					nvarchar(50)	-- The name of the Portal Configuration.
Declare	@nNameOperator				tinyint
Declare	@sDescription 	 			nvarchar(4000)	-- A description of the purpose and function of the role.
Declare	@nDescriptionOperator 	 		tinyint
Declare	@bIsExternal				bit		-- True for roles that are for external (client) users of the system.

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
set 	@sFrom					= char(10)+"From PORTAL P"
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
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 120)

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
	Set @sWhere = @sWhere+char(10)+"and P.ISEXTERNAL = 1" 				   
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
		If @sColumn='PortalKey'
		Begin
			Set @sTableColumn='P.PORTALID'
		End
		Else 
		If @sColumn='Name'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PORTAL','NAME',null,'P',@sLookupCulture,@pbCalledFromCentura) 
		End
		Else 
		If @sColumn = 'Description'
		Begin
			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By				

			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PORTAL','DESCRIPTION',null,'P',@sLookupCulture,@pbCalledFromCentura) 
		End
		If @sColumn = 'IsExternal'
		Begin
			Set @sTableColumn='P.ISEXTERNAL'
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
	"	@nPortalKey			= PortalKey,"+CHAR(10)+	
	"	@nPortalKeyOperator		= PortalKeyOperator,"+CHAR(10)+	
	"	@sName				= upper(Name),"+CHAR(10)+
	"	@nNameOperator			= NameOperator,"+CHAR(10)+
	"	@sDescription			= Description,"+CHAR(10)+	
	"	@nDescriptionOperator		= DescriptionOperator,"+CHAR(10)+	
	"	@bIsExternal			= IsExternal"+CHAR(10)+		
	"from	OPENXML (@idoc, '/ua_ListPortal/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      PickListSearch		nvarchar(50)	'PickListSearch/text()',"+CHAR(10)+	
	"	      PortalKey			int		'PortalKey/text()',"+CHAR(10)+	
	"	      PortalKeyOperator		tinyint		'PortalKey/@Operator/text()',"+CHAR(10)+	
	"	      Name			nvarchar(50)	'Name/text()',"+CHAR(10)+	
	"	      NameOperator		tinyint		'Name/@Operator/text()',"+CHAR(10)+	
	"	      Description		nvarchar(254)	'Description/text()',"+CHAR(10)+	
	"	      DescriptionOperator	tinyint		'Description/@Operator/text()',"+CHAR(10)+		
	"	      IsExternal		bit		'IsExternal/text()'"+CHAR(10)+		
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sPickListSearch		nvarchar(50)			output,
				  @nPortalKey			int				output,
				  @nPortalKeyOperator		tinyint				output,
				  @sName			nvarchar(50)			output,		
				  @nNameOperator		tinyint				output,		
				  @sDescription			nvarchar(254)			output,
				  @nDescriptionOperator		tinyint				output,
				  @bIsExternal			bit				output',
				  @idoc				= @idoc,
				  @sPickListSearch		= @sPickListSearch		output,				  		
				  @nPortalKey			= @nPortalKey			output,
				  @nPortalKeyOperator		= @nPortalKeyOperator		output,
				  @sName			= @sName			output,
				  @nNameOperator 		= @nNameOperator		output,
				  @sDescription			= @sDescription 		output,
				  @nDescriptionOperator		= @nDescriptionOperator		output,
				  @bIsExternal			= @bIsExternal			output

	-- Extract the Selected Roles as a comma separated list into the @sSelectedRoles variable:	
	Select @sSelectedRoles = @sSelectedRoles + nullif(',', ',' + @sSelectedRoles) + cast(RoleKey as varchar(11)) 
	from	OPENXML (@idoc, '/ua_ListPortal/FilterCriteria/SelectedRoles/RoleKey', 2)	
	WITH (
	      RoleKey			int	'text()'
	      )
	where RoleKey is not null	
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
		-- The PickListSearch filtering implemented as the following: Portal Name Starts With PickListSearch:			
		If @sPickListSearch is not null
		Begin
			Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('PORTAL','NAME',null,'P',@sLookupCulture,@pbCalledFromCentura)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)				
		End				

		If @nPortalKey is not NULL
		or @nPortalKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and P.PORTALID " + dbo.fn_ConstructOperator(@nPortalKeyOperator,@Numeric,@nPortalKey, null,0)  
		End	
	
		If @sName is not NULL
		or @nNameOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('PORTAL','NAME',null,'P',@sLookupCulture,@pbCalledFromCentura)+") " + dbo.fn_ConstructOperator(@nNameOperator,@String,@sName, null,0)
		End	

		If @sDescription is not NULL
		or @nDescriptionOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and "+dbo.fn_SqlTranslatedColumn('PORTAL','DESCRIPTION',null,'P',@sLookupCulture,@pbCalledFromCentura)+" " + dbo.fn_ConstructOperator(@nDescriptionOperator,@String,@sDescription, null,0)
		End			
	
		If @bIsExternal is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and P.ISEXTERNAL = " + CAST(@bIsExternal as nchar(1)) 	  				   
		End						

		-- When Selected Roles have been provided, only those portal configurations that 
		-- contain all web parts that are mandatory across the selected roles:
		If @sSelectedRoles is not null
		Begin
			Set @sWhere = @sWhere	+char(10)+"and (select count(distinct FP.ObjectIntegerKey)"
						+char(10)+"	from PORTALTAB PT" 	
						+char(10)+"	join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)" 
						+char(10)+"	join dbo.fn_PermissionsForLevel('ROLE', '"+@sSelectedRoles+"', 'MODULE', NULL, NULL, '" + cast(@dtToday as nvarchar(20)) + "') FP"
						+char(10)+"				on (FP.ObjectIntegerKey = MC.MODULEID"
						+char(10)+"				and FP.IsMandatory = 1)"	
						+char(10)+"	where P.PORTALID = PT.PORTALID"
						+char(10)+"	) = (	Select count(*) "
						+char(10)+"		from dbo.fn_PermissionsForLevel('ROLE', '"+@sSelectedRoles+"', 'MODULE', NULL, NULL, '" + cast(@dtToday as nvarchar(20)) + "')" 
						+char(10)+"		where IsMandatory = 1)"
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

Grant execute on dbo.ua_ListPortal to public
GO
