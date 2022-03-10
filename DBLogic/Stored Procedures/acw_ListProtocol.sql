-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListProtocol
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListProtocol]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListProtocol.'
	Drop procedure [dbo].[acw_ListProtocol]
End
Print '**** Creating Stored Procedure dbo.acw_ListProtocol...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListProtocol
(
	@pnRowCount			int		= null output,	
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 235, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null	-- The filtering to be performed on the result set.			
)
as
-- PROCEDURE:	acw_ListProtocol
-- VERSION:	5
-- DESCRIPTION:	Returns the requested Protocol references that matches the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 31 Mar 2011	AT	RFC10072	1	Procedure created.
-- 21 Apr 2011	AT	RFC10492	2	Added null checks to discount and margin flags.
-- 13 Jul 2011	DL	SQA19795	3	Specify collate database default for temp table.
-- 05 Jul 2013	vql	R13629		4	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910		5	Adjust formatted names logic (DR-15543).

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	ProtocolKey
--	ProtocolDate
--	AssociateName
--	ItemTransNo

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	CI
--	W
--	DW
--	N

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int

Declare @sSQLString		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

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
Declare @sProtocolKey				nvarchar(20)
Declare @sPickListSearch			nvarchar(50)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.
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
set 	@sSelect				="Select "

set 	@sFrom = char(10)+"from CREDITORITEM CI
	  Join NAME N on (N.NAMENO = CI.ACCTCREDITORNO)
	Left Join
	-- The total allocated when raising the credit:
	(Select sum(Case when FOREIGNCURRENCY is null then LOCALCOST else FOREIGNCOST end) as SUMITEM, 
		REFTRANSNO, REFENTITYNO
		From WORKHISTORY
		Where MOVEMENTCLASS = 1
		and (DISCOUNTFLAG != 1 OR DISCOUNTFLAG IS NULL)
		and (MARGINFLAG != 1 OR MARGINFLAG IS NULL)
		Group by REFTRANSNO, REFENTITYNO
		) as W on (W.REFTRANSNO = CI.ITEMTRANSNO
				AND W.REFENTITYNO = CI.ITEMENTITYNO)
	Left Join 
	-- the total WIP dissected against the protocol no/date after purchase
	(Select sum(CASE WHEN FOREIGNCURRENCY IS NULL THEN LOCALCOST ELSE FOREIGNCOST END) as SUMITEM, 
		PROTOCOLNO, PROTOCOLDATE
		From WORKHISTORY
		Where MOVEMENTCLASS = 1
		and (DISCOUNTFLAG != 1 OR DISCOUNTFLAG IS NULL)
		and (MARGINFLAG != 1 OR MARGINFLAG IS NULL)
		and PROTOCOLNO is not null
		group by PROTOCOLNO, PROTOCOLDATE
		) as DW on (DW.PROTOCOLNO = CI.PROTOCOLNO
				and DW.PROTOCOLDATE = CI.PROTOCOLDATE)"
									
set 	@sWhere 				= char(10)+"	-- where the CREDITORITEM total has not been fully allocated
						Where Case when CI.CURRENCY is not null 
							then CI.FOREIGNVALUE 
							else CI.LOCALPRETAXVALUE end > isnull(W.SUMITEM,0) + isnull(DW.SUMITEM,0)
						and CI.PROTOCOLNO IS NOT NULL
						and CI.STATUS != 9"
set 	@sLookupCulture 			= dbo.fn_GetLookupCulture(@psCulture, null, 0)

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the filter criteria using element-centric mapping (implement 
	--    Case Insensitive searching were required)   

	Set @sSQLString = 	
	"Select @sProtocolKey		= ProtocolKey,"+CHAR(10)+
	"	@sPickListSearch	= upper(PickListSearch)"+CHAR(10)+
	"from	OPENXML (@idoc, '//acw_ListProtocol',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      ProtocolKey		nvarchar(20)	'FilterCriteria/ProtocolKey/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(50)	'FilterCriteria/PickListSearch/text()'"+CHAR(10)+
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sProtocolKey 		nvarchar(20)		output,
				  @sPickListSearch		nvarchar(50)		output',
				  @idoc				= @idoc,
				  @sProtocolKey 		= @sProtocolKey		output,
				  @sPickListSearch		= @sPickListSearch	output		
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
	

	If @nErrorCode = 0
	Begin
	
		If @sProtocolKey is not NULL
		Begin
			Set @sWhere = @sWhere+char(10)+"and CI.PROTOCOLNO = '" + @sProtocolKey + "'"
		End

		-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
		-- is produced. The search only continues to the next criterion if no rows were located.
			
		If @sPickListSearch is not null
		Begin
			-- If the length of PickListSearch does not exceed the maximum length of the Code
			
			If LEN(@sPickListSearch) <= 20
			Begin
				Set @bExists = 0
				-- Check if Code Equals To PickListSearch
				Set @sSQLString = "Select @bExists=1"+char(10)+
						@sFrom +char(10)+
						@sWhere +char(10)+
						  "and (CI.PROTOCOLNO=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
			
				exec @nErrorCode =  sp_executesql @sSQLString,
							N'@bExists		bit		OUTPUT,
							  @sPickListSearch	nvarchar(50)',
							  @bExists		= @bExists 	OUTPUT,
							  @sPickListSearch	= @sPickListSearch
			
				If @bExists=1
				Begin
					Set @sWhere=@sWhere+char(10)+"and (CI.PROTOCOLNO=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
				End
				Else
				Begin
					Set @sWhere=@sWhere+char(10)+"and (CI.PROTOCOLNO like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+ 
								     " or upper(CI.PROTOCOLNO) like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
				End
			End
			Else 
			Begin
				Set @sWhere=@sWhere+char(10)+"and upper(CI.PROTOCOLNO) like "+ dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
			End
		End	
	End
End

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,0,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End
-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
Else
Begin
	-- Default @pnQueryContextKey to 220.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 235)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,0,null)

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
	
		--print @sColumn
	
		If @sColumn='NULL'		
		Begin
			Set @sTableColumn='NULL'
		End
		Else
		If @sColumn='ProtocolKey'
		Begin
			Set @sTableColumn='CI.PROTOCOLNO'
		End
		Else 
		If @sColumn='ProtocolDate'
		Begin
			Set @sTableColumn='cast(dbo.fn_DateOnly(CI.PROTOCOLDATE) as nvarchar)'
		End
		Else 
		If @sColumn = 'AssociateName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)'
		End
		Else 
		If @sColumn = 'ItemTransNo'
		Begin
			Set @sTableColumn = "CI.ITEMTRANSNO"
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
--print @sSelect + @sFrom + @sWhere + @sOrder
If @nErrorCode=0
Begin 	
	-- Now execute the constructed SQL to return the result set
	Exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sWhere + @sOrder)

	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.acw_ListProtocol to public
GO
