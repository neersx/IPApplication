-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ip_ListTable 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListTable ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListTable.'
	Drop procedure [dbo].[ip_ListTable ]
	Print '**** Creating Stored Procedure dbo.ip_ListTable ...'
	Print ''
End
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_ListTable 
(
	@pnRowCount			int		= null	output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnQueryContextKey		int		= 100,		-- The key for the context of the query; e.g. internal case search or case report. Supplied when the default output requests for the context are required.
	@ptXMLOutputRequests		ntext		= null, 	-- The columns and sorting required in the result Set.
	@ptXMLFilterCriteria		ntext		= null,		-- The filtering to be performed on the result Set.
	@pbCalledFromCentura		bit		= 0,
	@pbProduceTableName		bit		= 1		-- When true, a second result set is produced containing the name of the table. See Notes for details.
)
AS
-- PROCEDURE:	ip_ListTable 
-- VERSION:	18
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns the requested table information for a specific Table Type, for entries that match 
--		the filter criteria provided.
--		

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18-Dec-2003  TM	RFC611	1	Procedure created
-- 18-Dec-2003	TM	RFC611	2	Correct the PickListSearch datasize
-- 05-Jan-2003	TM	RFC611	3	Use TABLETYPE.DATABASETABLE = 'OFFICE' instead of hard coding a specific table type.  
--					Correct syntax error for the Code and Description Filter Criteria. 
-- 27-Feb-2004	TM	RFC1068 4	Select specific columns from the fn_GetQueryOutputRequests's table variable 
--					and implement the new DocItemKey column.
-- 13-May-2004	TM	RFC1246	5	Implement fn_GetCorrelationSuffix function to generate the correlation suffix 
--					based on the supplied qualifier.
-- 02 Sep 2004	JEK	RFC1377	6	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 21 Sep 2004	TM	RFC886	7	Implement translation.
-- 30 Sep 2004	JEK	RFC1695 8	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 15 May 2005	JEK	RFC2508	9	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	10	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 07 Jun 2005	TM	RFC2575	11	Add new @pbProduceTableName parameter.
-- 24 Oct 2005	TM	RFC3024	12	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 13 Oct 2008	SF	RFC6510	13	Add new joins and data items 
-- 20 Oct 2009  LP      100095	14	Extend to allow for multiple keys to be returned.
-- 25 Jan 2010	LP	100165	15	Extend to filter OFFICE by access mode.	
-- 01 Feb 2010	LP	100165	16	If OFFICE is null in Row Access Profile, then do not filter offices.
-- 07 Jul 2011	DL	10830	17	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 26 Oct 2017	MF	172198	18	Correction supplied by Adri from Novagraaf.
--					Set @nAccessMode to 1 if not supplied (Only applicable for tabletype 44, OFFICE) (<AccessMode> was not supplied).
--					Also changed datatype to nvarchar(max) for variables that contain (parts of) SQL statements

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	Key
--	Description
--	Code
--	TableType
--	TableTypeKey
--	TableCode

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	O
--	TC
--	TT


Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

Declare @sSelect		nvarchar(max)	-- the SQL list of columns to return
Declare	@sFrom			nvarchar(max)	-- the SQL to list tables and joins
Declare @sJoin			nvarchar(max)
Declare	@sWhere			nvarchar(max) 	-- the SQL to filter
Declare	@sOrder			nvarchar(max)	-- the SQL sort order

Declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
Declare	@sSQLString		nvarchar(max)
Declare @nColumnNo		tinyint
Declare @sColumn		nvarchar(100)
Declare @sPublishName		nvarchar(50)
Declare @sQualifier		nvarchar(50)
Declare @sTableColumn		nvarchar(1000)
Declare @nOrderPosition		tinyint
Declare @sOrderDirection	nvarchar(5)
Declare @sCorrelationSuffix	nvarchar(20)
Declare @sTable1		nvarchar(25)
Declare @sTable2		nvarchar(25)
Declare @sTable3		nvarchar(25)
Declare @sTable4		nvarchar(25)
Declare @sTable5		nvarchar(25)

-- Filter criteria variables declaration
Declare @sTableTypeKey		nvarchar(5)
Declare @sKey			nvarchar(10)
Declare @sKeys                  nvarchar(1000) 
Declare @sPickListSearch	nvarchar(80)
Declare @bExists		bit		-- If @bExists = 1 then rows are located for a @sPickListSearch criterion
Declare @sDescription		nvarchar(80)
Declare @nDescriptionOperator	tinyint
Declare @sCode			nvarchar(80)
Declare @nCodeOperator		tinyint
Declare @bUseOffice		bit		-- If set to 1 then Office attribute needs to be listed.
Declare @nAccessMode		tinyint		-- 1=select/search, 4=insert, 8=update
Declare @bHasRowAccessSecurity	bit

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
Set @sFrom			= 'from '
Set @String 			= 'S'
Set @sJoin			= ''
Set @bHasRowAccessSecurity	= 0

-- Check if the user has row access security profile
If @nErrorCode = 0
Begin
	Set @sSQLString="Select @bHasRowAccessSecurity = 1
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'C'
	and R.OFFICE IS NOT NULL
	and U.IDENTITYID = @pnUserIdentityId"
	
	Exec  @nErrorCode=sp_executesql @sSQLString,
		N'@bHasRowAccessSecurity	bit	OUTPUT,
		  @pnUserIdentityId	int',
		  @bHasRowAccessSecurity	=@bHasRowAccessSecurity	OUTPUT,
		  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode = 0
Begin 
	-- Filter criteria is always provided with at least TableTypeKey so retrieve it using element-centric mapping: 
		
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML			
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	Set @sSQLString = 	
	"Select @sTableTypeKey 		= TableTypeKey,"+CHAR(10)+
	"	@sKey			= FKey,"+CHAR(10)+
	"	@sKeys			= FKeys,"+CHAR(10)+ -- comma-separated list of TableCodes
	"	@sPickListSearch	= upper(PickListSearch),"+CHAR(10)+
	"	@sDescription		= upper(Description),"+CHAR(10)+
	"	@nDescriptionOperator	= DescriptionOperator,"+CHAR(10)+	
	"	@sCode			= upper(Code),"+CHAR(10)+	
	"	@nCodeOperator		= CodeOperator,"+CHAR(10)+	
	"	@nAccessMode		= AccessMode"+CHAR(10)+
	"from	OPENXML (@idoc, '/ip_ListTable/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      TableTypeKey		nvarchar(5)	'TableTypeKey/text()',"+CHAR(10)+
	"	      FKey			nvarchar(10)	'Key/text()',"+CHAR(10)+
	"	      FKeys			nvarchar(1000)	'Keys/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(80)	'PickListSearch/text()',"+CHAR(10)+	
	"	      Description		nvarchar(80)	'Description/text()',"+CHAR(10)+
	"	      DescriptionOperator	tinyint		'Description/@Operator/text()',"+CHAR(10)+
	"	      Code			nvarchar(80)	'Code/text()',"+CHAR(10)+	
	"	      CodeOperator		tinyint		'Code/@Operator/text()',"+CHAR(10)+
	"	      AccessMode		tinyint		'AccessMode/text()'"+CHAR(10)+	
	"	     )"		
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc			int,
					  @sTableTypeKey	nvarchar(5)		output,
					  @sKey			nvarchar(10)		output,
					  @sKeys		nvarchar(1000)		output,
					  @sPickListSearch	nvarchar(80)		output,
				          @sDescription		nvarchar(80)		output,
					  @nDescriptionOperator tinyint			output,
					  @sCode		nvarchar(80)		output,
					  @nCodeOperator	tinyint			output,
					  @nAccessMode		tinyint			output',
					  @idoc			= @idoc,
					  @sTableTypeKey	= @sTableTypeKey 	output,
					  @sKey			= @sKey			output,
					  @sKeys		= @sKeys		output,
					  @sPickListSearch	= @sPickListSearch	output,
					  @sDescription		= @sDescription		output,
					  @nDescriptionOperator	= @nDescriptionOperator output,
				  	  @sCode		= @sCode		output,
					  @nCodeOperator	= @nCodeOperator	output,
					  @nAccessMode		= @nAccessMode		output	

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End

-- Find out if the Office or the TableCodes table is required to list the attributes: 
If @nErrorCode = 0
Begin 

	Set @sSQLString = "
	Select @bUseOffice = CASE WHEN UPPER(DATABASETABLE) = 'OFFICE' THEN 1 ELSE 0 END
	from TABLETYPE
	where TABLETYPE = @sTableTypeKey"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bUseOffice		bit			output,
					  @sTableTypeKey	nvarchar(5)',
					  @bUseOffice		= @bUseOffice		output,
					  @sTableTypeKey	= @sTableTypeKey 	
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


	-- If a Qualifier exists then generate a value from it that can be used
	-- to create a unique Correlation name for the table

	If  @nErrorCode=0
	and @sQualifier is not null
	Begin
		Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
	End
	Else Begin
		Set @sCorrelationSuffix=NULL 
	End
	
	-- Now test the value of the Column to determine what table and column is required
	-- in the Select.  Note that if the PublishName is null then the column will not be
	-- returned in the result Set however it is probably required for sorting.

	If @nErrorCode=0
	Begin
		If @sColumn in('Key','TableCode')
		Begin
			If @bUseOffice = 1
			Begin
				Set @sTableColumn='O.OFFICEID' 			
			End
			Else
			Begin 
				Set @sTableColumn='TC.TABLECODE'
			End 
		End

		Else If @sColumn='Description'
		Begin
			If @bUseOffice = 1
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,@pbCalledFromCentura) 
			End
			Else 
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura) 
			End 
			
		End

		Else If @sColumn='Code'
		Begin
			If @bUseOffice = 1
			Begin
				Set @sTableColumn='O.USERCODE'
			End
			Else 
			Begin
				Set @sTableColumn='TC.USERCODE'
			End 			
		End

		
		Else If @sColumn in ('TableTypeKey','TableType')
		Begin
			If charindex('left join TABLETYPE TT',@sJoin)=0
			Begin
				Set @sJoin = @sJoin + char(10) + 'left join TABLETYPE TT on (TT.TABLETYPE = @sTableTypeKey)'
			End
		
			Set @sTableColumn = case 
						when @sColumn = 'TableTypeKey' then @sTableTypeKey
						when @sColumn = 'TableType' then dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TT',@sLookupCulture,@pbCalledFromCentura)
					end
		End

		if @bUseOffice=1
		Begin
			If charindex('from OFFICE O',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + 'OFFICE O ' 
			End
		End
		Else
		Begin
			If charindex('from TABLECODES TC',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + 'TABLECODES TC' 
			End
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
	Set @sWhere = char(10)+"WHERE 1=1"
	
	If @bUseOffice = 1
	Begin
		If @sKey is not NULL
		Begin
			Set @sWhere = @sWhere+char(10)+"and O.OFFICEID = " + @sKey
		End		

		If @sDescription is not NULL
		or @nDescriptionOperator between 2 and 6
		Begin						
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,@pbCalledFromCentura)+") " + dbo.fn_ConstructOperator(@nDescriptionOperator,@String,@sDescription, null,0)
		End	

		If @sCode is not NULL
		or @nCodeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper(O.USERCODE) " + dbo.fn_ConstructOperator(@nCodeOperator,@String,@sCode, null,0)
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
						  "from OFFICE O"+char(10)+
						  @sWhere+
						  "and (upper(O.USERCODE)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
			
				exec @nErrorCode =  sp_executesql @sSQLString,
							N'@bExists		bit		OUTPUT,
							  @sPickListSearch	nvarchar(80)',
							  @bExists		= @bExists 	OUTPUT,
							  @sPickListSearch	= @sPickListSearch
			
				If @bExists=1
				Begin
					Set @sWhere=@sWhere+char(10)+"and (upper(O.USERCODE)=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
				End
				Else
				Begin
					Set @sWhere=@sWhere+char(10)+"and (upper(O.USERCODE) like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+ 
								     " or upper("+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,@pbCalledFromCentura)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
				End
			End
			Else 
			Begin
				Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,@pbCalledFromCentura)+") like "+ dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
			End
		End		
	End	
	Else	-- else use TABLECODES table: 
	Begin
		If @sTableTypeKey is not NULL
		Begin
			Set @sWhere = @sWhere+char(10)+"and TC.TABLETYPE = " + @sTableTypeKey
		End	
		
		If @sKey is not NULL
		Begin
			Set @sWhere = @sWhere+char(10)+"and TC.TABLECODE = " + @sKey
		End	
		
		If @sKeys is not NULL
		Begin
		        Set @sWhere = @sWhere+char(10)+"and TC.TABLECODE in (" + @sKeys + ")"
		End	
	
		If @sDescription is not NULL
		or @nDescriptionOperator between 2 and 6
		Begin					
			Set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+") " + dbo.fn_ConstructOperator(@nDescriptionOperator,@String,@sDescription, null,0)
		End	
	
		If @sCode is not NULL
		or @nCodeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper(TC.USERCODE) " + dbo.fn_ConstructOperator(@nCodeOperator,@String,@sCode, null,0)
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
								     " or upper("+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+") like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
				End
			End
			Else 
			Begin
				Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+") like "+ dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
			End
		End		
	End	

	-- special case for Office
	If @bHasRowAccessSecurity = 1
	and @sTableTypeKey = "44"
	Begin
		Set @nAccessMode = ISNULL(@nAccessMode, 1)
		Set @sWhere = @sWhere + " and convert(int,Substring("
		+char(10)+"		(Select MAX (   CASE when XRAD.OFFICE       is null then '0' else '1' end +"
		+char(10)+"				CASE when XRAD.CASETYPE     is null then '0' else '1' end +"
		+char(10)+"				CASE when XRAD.PROPERTYTYPE is null then '0' else '1' end +"								
		+char(10)+"				CASE when XRAD.SECURITYFLAG < 10    then '0' else ''  end +"
		+char(10)+"				convert(nvarchar(2),XRAD.SECURITYFLAG)"
		+char(10)+"			)"
		+char(10)+"		from IDENTITYROWACCESS XIA"
		+char(10)+"		join ROWACCESSDETAIL XRAD	on  (XRAD.ACCESSNAME   = XIA.ACCESSNAME 
									and  XRAD.RECORDTYPE = 'C'"+char(10)+ 
		CASE WHEN @bUseOffice = 1 THEN " and  (XRAD.OFFICE = O.OFFICEID))"
			ELSE " and  (XRAD.OFFICE = TC.TABLECODE))" END
		+char(10)+"		join USERIDENTITY XUI on (XUI.IDENTITYID = XIA.IDENTITYID)"
		+char(10)+"		where XIA.IDENTITYID=" + convert(varchar,@pnUserIdentityId)
		+char(10)+"		),4,2)) & "+convert(nvarchar(3),@nAccessMode)+"="+ convert(nvarchar(3),@nAccessMode)
	End	
End
	
If @nErrorCode=0
Begin	
	-- Now execute the constructed SQL to return the result set
	select	@sSQLString = N'SET ANSI_NULLS OFF '
	select	@sSQLString = @sSQLString  + @sSelect + @sFrom + @sWhere + @sOrder
	exec	(@sSQLString)
	
	select 	@nErrorCode =@@Error,
		@pnRowCount=@@Rowcount
	
End

-- Produce Table Name result set if required
If @nErrorCode=0
and @pbProduceTableName=1
Begin	
	Set @sSQLString = "
	Select "+dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'T',@sLookupCulture,@pbCalledFromCentura)+ 
		      " as 'TableName'
	from TABLETYPE T
	where T.TABLETYPE = cast(@sTableTypeKey as smallint)" 

	exec @nErrorCode =  sp_executesql @sSQLString,
				N'@sTableTypeKey	nvarchar(5)',
				  @sTableTypeKey	= @sTableTypeKey
End

Return @nErrorCode
GO

Grant execute on dbo.ip_ListTable  to public
GO


