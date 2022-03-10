-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListUserIdentity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_ListUserIdentity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.ipw_ListUserIdentity.'
	drop procedure dbo.ipw_ListUserIdentity
	print '**** Creating procedure dbo.ipw_ListUserIdentity...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_ListUserIdentity
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 50, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0
)	
AS

-- PROCEDURE :	ipw_ListUserIdentity
-- VERSION :	16
-- DESCRIPTION:	Returns the User Identity information requested, that matches the filter criteria provided.


-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22-MAR-2004  TM	RFC738	1	Procedure created 
-- 05-May-2004	TM	RFC1363	2	Correct the Email filtering logic.
-- 18-Jun-2004	TM	RFC1499	3	Add PortalKey, PortalName, PortalDescription as new selectable columns 
--					and PortalKey as new filter criteria. 
-- 02 Sep 2004	JEK	RFC1377	4	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 15 Sep 2004	JEK	RFC886	5	Implement translation.
-- 30 Sep 2004	JEK	RFC1695 6	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 15 May 2005	JEK	RFC2508	7	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	8	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 14 Sep 2005	TM	RFC2953	9	Add pick list search criteria.
-- 24 Oct 2005	TM	RFC3024	10	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 06 Mar 2006	IB	RFC3486	11	Fixed WHERE clause for users with multiple roles.
-- 06 Mar 2006	IB	RFC3486	12	Fixed setting operator value for Does Not Exist option.
-- 23 Mar 2006	IB	RFC3212	13	For external users restrict result set to rows that they can access.
-- 22 Nov 2007	SW	RFC5967	14	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 03 Dec 2007	vql	RFC5909	14	Change RoleKey and DocumentDefId from smallint to int.
-- 07 Jul 2011	DL	R10830	15	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 02 Nov 2015	vql	R53910	16	Adjust formatted names logic (DR-15543).

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	IdentityKey
--	LoginID
--	IdentityNameKey
--	DisplayName
--	NameCode
--	DisplayEmail
--	IsInternalUser
--	IsExternalUser
--	IsAdministrator
--	AccessAccountKey
--	AccessAccountName
--	RoleName
--	IsIncompleteWorkBench
--	IsIncompleteInprostart
--	PortalKey (RFC1499)
--  	PortalName (RFC1499)
--	PortalDescription (RFC1499)

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	ACN
--	E
--	IDR
--	N
--	NT
--	P
--	T
--	UID
--	UID2

-- SETTINGS
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
Declare	@nIdentityKey				int		-- The IdentityID (primary key) of the UserIdentity.	
Declare	@nIdentityKeyOperator			tinyint		
Declare	@sLoginID				nvarchar(50)	-- The identifier used to log in. Case insensitive search.	
Declare	@nLoginIDOperator			tinyint		
Declare	@nNameKey				nvarchar (60)	-- The internal key for the name.	
Declare	@nNameKeyOperator			tinyint		
Declare	@bIsExternalUser			bit		-- True returns users that are external; e.g. clients.		 
Declare	@bIsAdministrator			bit		-- True returns users with special security privileges.	 
Declare	@sEmailAddress				nvarchar(100)	-- The main email address of the user. Case insensitive search.	
Declare	@nEmailAddressOperator			tinyint		
Declare	@nAccessAccountKey			int		-- The key of the account that the user operates under.		
Declare	@nAccessAccountOperator			tinyint		
Declare	@nRoleKey				int	-- The key of the role the user has in the system.  
Declare	@nRoleOperator				tinyint 	
Declare	@bIsIncompleteWorkBench			bit		-- True returns users that are not fully configured for use with the WorkBench products.
Declare	@bIsIncompleteInprostart		bit		-- True returns users that are not fully configured for use with CPA Inprostart.
Declare @nPortalKey				int		-- The database key of the default Portal Configuration of the user.
Declare	@nPortalOperator			tinyint
Declare @sPickListSearch 			nvarchar(50)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.  
Declare @bExists				bit

Declare @nCount					int	 	-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sOrder					nvarchar(4000)

Declare @idoc 					int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
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

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set 	@nErrorCode				=0
Set     @nCount					= 1
Set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
Set 	@sFrom					='From USERIDENTITY UID'
-- Initialise the WHERE clause with a test that will always be true and will have no performance
-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
Set 	@sWhere 				= char(10)+"WHERE 1=1"

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****                                       ****/
/***********************************************/

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
	-- Default @pnQueryContextKey to 70.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 70)

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
	
-- Restrict access to external users when called by an external user
If @bIsExternalUser = 1
Begin
	Set @sFrom  = @sFrom +char(10)+"join USERIDENTITY UID2 on (UID2.IDENTITYID = " + cast(@pnUserIdentityId as varchar(12))
			     +char(10)+"			   and UID2.ACCOUNTID = UID.ACCOUNTID)"

	Set @sWhere = @sWhere+char(10)+"and UID.ISEXTERNALUSER = 1"   
End	

-- Reset @bIsExternalUser to null so that it could be re-used in construction of WHERE clause.
Set @bIsExternalUser = null

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
		If @sColumn='IdentityKey'
		Begin
			Set @sTableColumn='UID.IDENTITYID'
		End

		Else If @sColumn='LoginID'
		Begin
			Set @sTableColumn='UID.LOGINID'
		End

		Else If @sColumn='IdentityNameKey'
		Begin
			Set @sTableColumn='UID.NAMENO'
		End

		Else If @sColumn in ('DisplayName',
				     'NameCode',
				     'DisplayEmail')		
		Begin
			If charindex('left join NAME N',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAME N on N.NAMENO = UID.NAMENO '
			End
			
			If @sColumn='DisplayName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)'
			End

			If @sColumn='NameCode'
			Begin
				Set @sTableColumn='N.NAMECODE'
			End

			If @sColumn='DisplayEmail'
			Begin
				Set @sTableColumn='dbo.fn_FormatTelecom(E.TELECOMTYPE, E.ISD, E.AREACODE, E.TELECOMNUMBER, E.EXTENSION) '				
			
				Set @sFrom = @sFrom + char(10) + 'left join TELECOMMUNICATION E on (E.TELECODE = N.MAINEMAIL) '
			End
		End		

		Else If @sColumn='IsInternalUser'
		Begin
			Set @sTableColumn='CASE when UID.ISEXTERNALUSER = 1 then 0 else 1 end'
		End

		Else If @sColumn='IsExternalUser'
		Begin
			Set @sTableColumn='UID.ISEXTERNALUSER'
		End

		Else If @sColumn='IsAdministrator'		
		Begin
			Set @sTableColumn='UID.ISADMINISTRATOR'
		End

		Else If @sColumn='AccessAccountKey'
		Begin
			Set @sTableColumn='UID.ACCOUNTID'
		End

		Else If @sColumn='AccessAccountName'
		Begin
			Set @sTableColumn='ACN.ACCOUNTNAME'
			
			Set @sFrom = @sFrom + char(10) + 'left join ACCESSACCOUNT ACN	on (ACN.ACCOUNTID = UID.ACCOUNTID)'
		End

		Else If @sColumn='RoleName'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('ROLE','ROLENAME',null,'RL',@sLookupCulture,@pbCalledFromCentura)
			
			Set @sFrom=@sFrom + char(10) + "left join IDENTITYROLES IDR	on (IDR.IDENTITYID = UID.IDENTITYID)"
				     	  + char(10) + "left join ROLE RL		on (RL.ROLEID	   = IDR.ROLEID)"
		End
		
		Else If @sColumn='IsIncompleteWorkBench'
		Begin
			Set @sTableColumn='CASE WHEN UID.ISVALIDWORKBENCH=1 THEN cast(0 as bit) ELSE cast(1 as bit) END'			
		End		

		Else If @sColumn='IsIncompleteInprostart'
		Begin
			Set @sTableColumn='CASE WHEN UID.ISVALIDINPROSTART=1 THEN cast(0 as bit) ELSE cast(1 as bit) END'			
		End		
		
		Else If @sColumn='PortalKey'
		Begin
			Set @sTableColumn='UID.DEFAULTPORTALID'			
		End		

		Else If @sColumn in ('PortalName',
				     'PortalDescription')
		Begin
			If charindex('Left Join PORTAL P',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+'Left Join PORTAL P		on (P.PORTALID=UID.DEFAULTPORTALID)'
			End	

			If @sColumn=('PortalName')	
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PORTAL','NAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
			End
			Else Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PORTAL','DESCRIPTION',null,'P',@sLookupCulture,@pbCalledFromCentura)
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

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the Filter elements using element-centric mapping (implement 
	--    Case Insensitive searching)   

	Set @sSQLString = 	
	"Select @nIdentityKey			= IdentityKey,"+CHAR(10)+
	"	@nIdentityKeyOperator		= IdentityKeyOperator,"+CHAR(10)+
	"	@sLoginID			= upper(LoginID),"+CHAR(10)+
	"	@nLoginIDOperator		= LoginIDOperator,"+CHAR(10)+
	"	@nNameKey			= NameKey,"+CHAR(10)+				
	"	@nNameKeyOperator		= NameKeyOperator,"+CHAR(10)+
	"	@bIsExternalUser		= IsExternalUser,"+CHAR(10)+
	"	@bIsAdministrator		= IsAdministrator,"+CHAR(10)+
	"	@sEmailAddress			= upper(EmailAddress),"+CHAR(10)+
	"	@nEmailAddressOperator		= EmailAddressOperator,"+CHAR(10)+
	"	@nAccessAccountKey		= AccessAccountKey,"+CHAR(10)+
	"	@nAccessAccountOperator		= AccessAccountOperator,"+CHAR(10)+
	"	@nRoleKey			= RoleKey,"+CHAR(10)+
	"	@nRoleOperator			= RoleOperator,"+CHAR(10)+
	"	@bIsIncompleteWorkBench		= IsIncompleteWorkBench,"+CHAR(10)+
	"	@bIsIncompleteInprostart	= IsIncompleteInprostart,"+CHAR(10)+
	"	@nPortalKey			= PortalKey,"+CHAR(10)+	
	"	@nPortalOperator		= PortalOperator,"+CHAR(10)+		
	"	@sPickListSearch		= upper(PickListSearch)"+CHAR(10)+
	"from	OPENXML (@idoc, '/ipw_ListUserIdentity/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      IdentityKey		int		'IdentityKey/text()',"+CHAR(10)+
	"	      IdentityKeyOperator	tinyint		'IdentityKey/@Operator/text()',"+CHAR(10)+
	"	      LoginID			nvarchar(50)	'LoginID/text()',"+CHAR(10)+	
	"	      LoginIDOperator		tinyint		'LoginID/@Operator/text()',"+CHAR(10)+
 	"	      NameKey			int		'NameKey/text()',"+CHAR(10)+	
	"	      NameKeyOperator		tinyint		'NameKey/@Operator/text()',"+CHAR(10)+	
	"	      IsExternalUser		bit		'IsExternalUser/text()',"+CHAR(10)+	
	"	      IsAdministrator		bit		'IsAdministrator/text()',"+CHAR(10)+	
	"	      EmailAddress		nvarchar(100)	'EmailAddress/text()',"+CHAR(10)+	
	"	      EmailAddressOperator	tinyint		'EmailAddress/@Operator/text()',"+CHAR(10)+	
	"	      AccessAccountKey		int		'AccessAccountKey/text()',"+CHAR(10)+	
	"	      AccessAccountOperator	tinyint		'AccessAccountKey/@Operator/text()',"+CHAR(10)+	
	"	      RoleKey			int		'RoleKey/text()',"+CHAR(10)+	
	"	      RoleOperator		tinyint		'RoleKey/@Operator/text()',"+CHAR(10)+	
	"	      IsIncompleteWorkBench	bit		'IsIncompleteWorkBench/text()',"+CHAR(10)+	
	"	      IsIncompleteInprostart	bit		'IsIncompleteInprostart/text()',"+CHAR(10)+	
	"	      PortalKey			int		'PortalKey/text()',"+CHAR(10)+	
	"	      PortalOperator		tinyint		'PortalKey/@Operator/text()',"+CHAR(10)+			
	"	      PickListSearch		nvarchar(50)	'PickListSearch/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nIdentityKey 		int			output,
				  @nIdentityKeyOperator		tinyint			output,
				  @sLoginID			nvarchar(50)		output,
				  @nLoginIDOperator		tinyint			output,	
				  @nNameKey			int			output,				
				  @nNameKeyOperator		tinyint			output,
				  @bIsExternalUser		bit			output,		
				  @bIsAdministrator		bit			output,		
				  @sEmailAddress		nvarchar(100)		output,		
				  @nEmailAddressOperator	tinyint			output,		
				  @nAccessAccountKey		int			output,
				  @nAccessAccountOperator	tinyint			output,
				  @nRoleKey			int			output,
				  @nRoleOperator		tinyint			output,
				  @bIsIncompleteWorkBench	bit			output,
				  @bIsIncompleteInprostart	bit			output,
				  @nPortalKey			int			output,
				  @nPortalOperator		tinyint			output,	
				  @sPickListSearch		nvarchar(50)		output',
				  @idoc				= @idoc,
				  @nIdentityKey 		= @nIdentityKey		output,
				  @nIdentityKeyOperator		= @nIdentityKeyOperator	output,
				  @sLoginID			= @sLoginID		output,
				  @nLoginIDOperator		= @nLoginIDOperator	output,
				  @nNameKey			= @nNameKey		output,				
				  @nNameKeyOperator		= @nNameKeyOperator	output,
				  @bIsExternalUser 		= @bIsExternalUser	output,
				  @bIsAdministrator		= @bIsAdministrator	output,
				  @sEmailAddress		= @sEmailAddress	output,
				  @nEmailAddressOperator	= @nEmailAddressOperator output,
				  @nAccessAccountKey		= @nAccessAccountKey	output,
				  @nAccessAccountOperator	= @nAccessAccountOperator output,
				  @nRoleKey			= @nRoleKey		output,
				  @nRoleOperator		= @nRoleOperator 	output,
				  @bIsIncompleteWorkBench	= @bIsIncompleteWorkBench output,
				  @bIsIncompleteInprostart	= @bIsIncompleteInprostart output,
				  @nPortalKey			= @nPortalKey		output,
				  @nPortalOperator		= @nPortalOperator	output,
				  @sPickListSearch		= @sPickListSearch	output		
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc			
	
	Set @nErrorCode=@@Error

	If @nIdentityKey is not NULL
	or @nIdentityKeyOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.IDENTITYID"+dbo.fn_ConstructOperator(@nIdentityKeyOperator,@Numeric,@nIdentityKey, null,0)
	End

	If @sLoginID is not NULL
	or @nLoginIDOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and upper(UID.LOGINID)"+dbo.fn_ConstructOperator(@nLoginIDOperator,@String,@sLoginID, null,0)
	End

	If @nNameKey is not NULL
	or @nNameKeyOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.NAMENO"+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
	End

	If @bIsExternalUser is not NULL
		Set @sWhere = @sWhere+char(10)+"and UID.ISEXTERNALUSER = " + CAST(@bIsExternalUser as nchar(1))

	If @bIsAdministrator is not NULL
		Set @sWhere = @sWhere+char(10)+"and UID.ISADMINISTRATOR = " + + CAST(@bIsAdministrator as nchar(1))

	If @sEmailAddress is not NULL
	or @nEmailAddressOperator between 2 and 6
	Begin
		-- If Operator is set to NOT EQUAL or IS NULL then use NOT EXISTS
		If @nEmailAddressOperator = 6
		Begin
			set @sWhere =@sWhere+char(10)+"and not exists"
		End
		Else 
		Begin
			Set @sWhere =@sWhere+char(10)+"and exists"
		End
				
		Set @sWhere = @sWhere+char(10)+"(Select 1 from NAMETELECOM NT" 
				     +char(10)+" join TELECOMMUNICATION T on (T.TELECODE = NT.TELECODE"					
				     +char(10)+" 			  and T.TELECOMTYPE = 1903)"
				     +char(10)+" where NT.NAMENO = UID.NAMENO"	

		If @sEmailAddress is not null
		and @nEmailAddressOperator not in (5,6)
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper(T.TELECOMNUMBER)"+dbo.fn_ConstructOperator(@nEmailAddressOperator,@String,@sEmailAddress, null,0)
		End			
		
		Set @sWhere=@sWhere+")"				
	End

	If @nAccessAccountKey is not NULL
	or @nAccessAccountOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.ACCOUNTID"+dbo.fn_ConstructOperator(@nAccessAccountOperator,@Numeric,@nAccessAccountKey, null,0)
	End

	If @nRoleKey is not NULL
	or @nRoleOperator between 2 and 6
	Begin
		If @nRoleOperator in (1, 6)
		Begin
			set @sWhere =@sWhere+char(10)+"and not exists"

			If @nRoleOperator in (1)
			Begin
				set @nRoleOperator = 0
			End

			If  @nRoleOperator in (6)
			Begin
				set @nRoleOperator = 5
			End
		End
		Else 
		Begin
			Set @sWhere =@sWhere+char(10)+"and exists"
		End

		Set @sWhere = @sWhere+char(10)+"(select 1"
				     +char(10)+" from IDENTITYROLES XIDR"
				     +char(10)+" where XIDR.IDENTITYID = UID.IDENTITYID"
				     +char(10)+" and XIDR.ROLEID"+dbo.fn_ConstructOperator(@nRoleOperator,@Numeric,@nRoleKey, null,0)+")"
	End
	
	If @bIsIncompleteWorkBench is not NULL	
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.ISVALIDWORKBENCH <> "+CAST(@bIsIncompleteWorkBench as nchar(1))

	End

	If @bIsIncompleteInprostart is not NULL	
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.ISVALIDINPROSTART <> "+CAST(@bIsIncompleteInprostart as nchar(1))
	End

	If @nPortalKey is not NULL
	or @nPortalOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.DEFAULTPORTALID"+dbo.fn_ConstructOperator(@nPortalOperator,@Numeric,@nPortalKey, null,0)
	End

	-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
	-- is produced.  The search only continues to the next criterion if no rows were located.
		
	If @sPickListSearch is not null
	Begin		
		Set @bExists = 0
		-- Check if LoginID Equal To @psPickListSearch
		Set @sSQLString = "Select @bExists=1"+char(10)+
				  "from USERIDENTITY UID"+char(10)+
				  @sWhere+
				  "and (UPPER(UID.LOGINID)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
	
		exec @nErrorCode =  sp_executesql @sSQLString,
					N'@bExists		bit		OUTPUT,
					  @sPickListSearch	nvarchar(50)',
					  @bExists		= @bExists 	OUTPUT,
					  @sPickListSearch	= @sPickListSearch
	
		If @bExists=1
		Begin
			Set @sWhere=@sWhere+char(10)+"and UPPER(UID.LOGINID)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)
		End
		Else Begin
			Set @sWhere=@sWhere+char(10)+"and UPPER(UID.LOGINID) like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
						     
		End		
	End
End

if @nErrorCode=0
begin  
	-- Now execute the constructed SQL to return the result set
	Exec (@sSelect + @sFrom + @sWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

end

RETURN @nErrorCode
GO

Grant execute on dbo.ipw_ListUserIdentity  to public
GO
