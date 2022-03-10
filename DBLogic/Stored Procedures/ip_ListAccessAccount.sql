-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListAccessAccount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListAccessAccount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListAccessAccount.'
	Drop procedure [dbo].[ip_ListAccessAccount]
End
Print '**** Creating Stored Procedure dbo.ip_ListAccessAccount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_ListAccessAccount
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura	bit		= 1
)
as
-- PROCEDURE:	ip_ListAccessAccount
-- VERSION:	13
-- DESCRIPTION:	Returns the requested columns for Access Accounts that match
--		supplied filter criteria.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 Dec 2003	JEK	RFC683	1	Procedure created
-- 16 Jan 2004	TM	RFC830	2	Add a new NameCode column.	
-- 25 Feb 2004	MF	SQA9662	3	Return DOCITEMKEY from XML
-- 02 Mar 2004	TM	RFC622	4	Extend to allow searching on and display of IsInternal column.  
-- 05 May 2004 	TM	RFC1363	5	Correct the Name Accessed filtering logic.
-- 02 Sep 2004	JEK	RFC1377	6	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 30 Sep 2004	JEK	RFC1695 7	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 06 Jun 2005	TM	RFC2630	8	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 24 Oct 2005	TM	RFC3024	9	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 07 Jul 2011	DL	R10830	10	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 15 Apr 2013	DV	R13270	11	Increase the length of nvarchar to 11 when casting or declaring integer
-- 01 Jul 2014	JD	R36539	12	External Admin user can see accounts for other clients.
-- 02 Nov 2015	vql	R53910	13	Adjust formatted names logic (DR-15543).

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	AccountKey
--	AccountName
--	NameKey
--	NameCode
--	DisplayName

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	AA
--	AN
--	N
--	XAN

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
declare @tblOutputRequests table 
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
declare @tbOrderBy table (
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null
			)

declare @nOutRequestsRowCount			int
declare @nColumnNo				tinyint
declare @sColumn				nvarchar(100)
declare @sPublishName				nvarchar(50)
declare @sQualifier				nvarchar(50)
declare @nOrderPosition				tinyint
declare @sOrderDirection			nvarchar(5)
declare @sTableColumn				nvarchar(1000)
declare @sComma					nchar(2)	-- initialised when a column has been added to the Select

-- Declare Filter Variables
Declare @nAccountKey				int
Declare @sPickListSearch 			nvarchar(50)
Declare	@sAccountName	 			nvarchar(50)		
Declare	@nAccountNameOperator			tinyint		
Declare	@sNameKeys				nvarchar(4000)	-- A comma separated list of NameNos
Declare	@nNameKeysOperator			tinyint
Declare @bIsInternal				bit		-- Returns either internal or external users based on the value requested.

Declare @nCount					int		-- Current table row being processed
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sOrder					nvarchar(4000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				="Select "
set 	@sFrom					= char(10)+"From ACCESSACCOUNT AA"
set 	@sWhere 				= char(10)+"	WHERE 1=1"

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
	set @pnQueryContextKey = isnull(@pnQueryContextKey, 60)
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
			Set @sTableColumn='AA.ACCOUNTID'
		End
		Else If @sColumn='AccountName'
		Begin
			Set @sTableColumn='AA.ACCOUNTNAME'
		End
		Else If @sColumn='IsInternal'
		Begin
			Set @sTableColumn='AA.ISINTERNAL'
		End
		Else If @sColumn = 'NameKey'
		     or @sColumn = 'DisplayName'
		     or @sColumn = 'NameCode'
		Begin
			If charindex('left join ACCESSACCOUNTNAMES AN',@sFrom)=0
			Begin
				Set @sFrom = @sFrom+char(10)+"	left join ACCESSACCOUNTNAMES AN on (AN.ACCOUNTID=AA.ACCOUNTID"
				Set @sFrom = @sFrom+char(10)+"	                                and AN.NAMENO ="
				Set @sFrom = @sFrom+char(10)+"	                                    (Select min(AN1.NAMENO)"
				Set @sFrom = @sFrom+char(10)+"	                                     from ACCESSACCOUNTNAMES AN1"
				Set @sFrom = @sFrom+char(10)+"	                                     where AN1.ACCOUNTID = AN.ACCOUNTID))"				
			End

			If @sColumn = 'NameKey'
			Begin
				Set @sTableColumn='AN.NAMENO'
			End
			Else If @sColumn = 'NameCode'
			Begin	
				If charindex('left join NAME N',@sFrom)=0
				Begin				
					Set @sFrom = @sFrom+char(10)+"	left join NAME N on (N.NAMENO = AN.NAMENO)"
				End

				Set @sTableColumn='N.NAMECODE'
			End
			Else If @sColumn = 'DisplayName'
			Begin
				If charindex('left join NAME N',@sFrom)=0
				Begin				
					Set @sFrom = @sFrom+char(10)+"	left join NAME N on (N.NAMENO = AN.NAMENO)"
				End
				
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)'
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

	-- 1) Retrieve the AnySearch element using element-centric mapping (implement 
	--    Case Insensitive searching)   
	Set @sSQLString = 	
	"Select @nAccountKey			= AccountKey,"+CHAR(10)+
	"	@sPickListSearch		= upper(PickListSearch),"+CHAR(10)+
	"	@sAccountName			= upper(AccountName),"+CHAR(10)+
	"	@nAccountNameOperator		= AccountNameOperator,"+CHAR(10)+
	"	@sNameKeys			= NameKeys,"+CHAR(10)+				
	"	@nNameKeysOperator		= NameKeysOperator,"+CHAR(10)+
	"	@bIsInternal			= IsInternal"+CHAR(10)+
	"from	OPENXML (@idoc, '/ip_ListAccessAccount/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      AccountKey		int		'AccountKey/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(50)	'PickListSearch/text()',"+CHAR(10)+
	"	      AccountName		nvarchar(50)	'AccountName/text()',"+CHAR(10)+	
	"	      AccountNameOperator	tinyint		'AccountName/@Operator/text()',"+CHAR(10)+
 	"	      NameKeys			nvarchar(4000)	'NameKeys',"+CHAR(10)+	
	"	      NameKeysOperator		tinyint		'NameKeys/@Operator/text()',"+CHAR(10)+	
	"	      IsInternal		bit		'IsInternal/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nAccountKey 			int			output,
				  @sPickListSearch		nvarchar(50)		output,
				  @sAccountName			nvarchar(50)		output,
				  @nAccountNameOperator		tinyint			output,	
				  @sNameKeys			nvarchar(4000)		output,				
				  @nNameKeysOperator		tinyint			output,
				  @bIsInternal			bit			output',
				  @idoc				= @idoc,
				  @nAccountKey 			= @nAccountKey		output,
				  @sPickListSearch		= @sPickListSearch	output,
				  @sAccountName			= @sAccountName		output,
				  @nAccountNameOperator		= @nAccountNameOperator	output,
				  @sNameKeys			= @sNameKeys		output,				
				  @nNameKeysOperator		= @nNameKeysOperator	output,
				  @bIsInternal			= @bIsInternal 		output

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
	
		If @sPickListSearch is not NULL
		Begin
	
			Set @sWhere = @sWhere+char(10)+"	and	upper(AA.ACCOUNTNAME)"+dbo.fn_ConstructOperator(2,@String,@sPickListSearch, null,0)
	
		End
	
		If @nAccountKey is not null
		Begin
			Set @sWhere=@sWhere+char(10)+"	and	AA.ACCOUNTID="+cast(@nAccountKey as nvarchar(11))
		End
		
		If @bIsInternal is not null
		Begin
			Set @sWhere=@sWhere+char(10)+"	and	AA.ISINTERNAL="+cast(@bIsInternal as nvarchar(1))
		End
	
		If @sAccountName is not NULL
		or @nAccountNameOperator between 2 and 6
		Begin
	
			Set @sWhere = @sWhere+char(10)+"	and	upper(AA.ACCOUNTNAME)"+dbo.fn_ConstructOperator(@nAccountNameOperator,@String,@sAccountName, null,0)
	
		End
		
		If (@sNameKeys is not null
		or @nNameKeysOperator between 2 and 6)		
		Begin
			-- If Operator is set to NOT EQUAL or IS NULL then use NOT EXISTS
			If @nNameKeysOperator in (1,6)
			Begin
				set @sWhere =@sWhere+char(10)+"and not exists"
			End
			Else 
			Begin
				Set @sWhere =@sWhere+char(10)+"and exists"
			End
					
			Set @sWhere = @sWhere+char(10)+"(Select 1 from ACCESSACCOUNTNAMES XAN" 
					     +char(10)+" where XAN.ACCOUNTID = AA.ACCOUNTID"	
	
			If @sNameKeys is not null
			and @nNameKeysOperator not in (5,6)
			Begin
				Set @sWhere =@sWhere+char(10)+" and   XAN.NAMENO = "+@sNameKeys
			End			
			
			Set @sWhere=@sWhere+")"			
		End
	
	End
End

if @nErrorCode=0
begin	
	--If it is an external user then only return the access accounts for that client
	select @bIsInternal = ~ISEXTERNALUSER from USERIDENTITY where IDENTITYID = @pnUserIdentityId
	if @bIsInternal=0
	begin
	 select @nAccountKey=ACCOUNTID from USERIDENTITY where IDENTITYID = @pnUserIdentityId 
	 Set @sWhere=@sWhere+char(10)+" and AA.ACCOUNTID="+cast(@nAccountKey as nvarchar(11))
	end
end

if @nErrorCode=0
begin	
	-- Now execute the constructed SQL to return the result set
	Exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

end

Return @nErrorCode
GO

Grant execute on dbo.ip_ListAccessAccount to public
GO
