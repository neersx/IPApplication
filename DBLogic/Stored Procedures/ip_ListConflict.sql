-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListConflict
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_ListConflict]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_ListConflict.'
	drop procedure dbo.ip_ListConflict
end
print '**** Creating procedure dbo.ip_ListConflict...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ip_ListConflict
(
	@pnRowCount			int 		output,	-- Number of rows in the first result set
	@pnCaseRowCount			int		output,	-- Number of rows in the Case result set
	@psSearchTerms			nvarchar(max)	output,	-- Terms that were searched (in a readable format)
	@psNameFields			nvarchar(max)	output,	-- Name fields searched (in a readable format)
	@psCaseFields			nvarchar(max)	output,	-- Case fields searched (in a readable format)
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLNameOutputRequests	nvarchar(max)	= null, -- The columns and sorting required in the Name result set.
	@ptXMLCaseOutputRequests	nvarchar(max)	= null, -- The columns and sorting required in the Case result set.
	@ptXMLFilterFields		nvarchar(max)	= null,	-- The fields on which filtering is to be conducted.
	@ptXMLFilterCriteria		nvarchar(max)	= null,	-- The filtering to be performed on the result set.
	@pbSingleResultSet		bit		= 0,	-- Indicates that case and name information is returned together
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@pnCallingLevel			smallint	= null,	-- Optional number that acknowledges multiple calls of 
								-- the stored procedure from the one connection and
								-- ensures there is no temporary table conflict
	@pbPrintSQL			bit		= null	-- When set to 1, the executed SQL statement is printed out. 
)		
as
-- PROCEDURE :	ip_ListConflict
-- VERSION :	7
-- DESCRIPTION:	Searches both names and cases for data that matches a set of parameters
--		used for conflict of interest searching.

-- MODIFICTIONS :
-- Date		Who	Version	Mod	Details
-- ----		---	-------	---	-------------------------------------
-- 27 May 2005	MF	1		Procedure created
-- 30 Jun 2005	MF	2	10718	Centura requires the output parameters to be selected.
-- 04 Jul 2005	MF	3	10718	Include the Centura parameters into the same SELECT as the 
--					components of the SQL.
-- 06 Jul 2005	MF	4	10718	In a single result set the Case sort columns are to come before
--					the Name sort columns. This will then ensure that Name rows will appear
--					first because Case columns are null.
-- 24 Oct 2005	TM	5 	R3024	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 07 Jan 2016	MF	6	R55525	Long list of terms is causing dynamic SQL to crash. Change variables to NVARCHAR(max).
-- 14 Jul 2016	MF	7	62317	Performance improvement using a CTE to get the minimum SEQUENCE by Caseid and NameType. 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Create a temporary table that will be used when called from
-- Centura to combine the 4000 character sections of the SELECT into NTEXT columns
Create table #CenturaSelect(	SelectList	ntext	collate database_default,
				FromClause	ntext	collate database_default,
				WhereClause	ntext	collate database_default null,
				WhereFilter	ntext	collate database_default null,
				GroupBy		ntext	collate database_default null,
				UnionSelect	ntext	collate database_default null,
				UnionFrom	ntext	collate database_default null,
				UnionWhere	ntext	collate database_default null,
				UnionFilter	ntext	collate database_default null,
				UnionGroupBy	ntext	collate database_default null,
				OrderBy		ntext	collate database_default null,
				TableType	nvarchar(4) collate database_default null)

-- Create a temporary table to be used in the construction of the SELECT.
Create table #TempConstructSQL (Position	smallint	identity(1,1),
				ComponentType	char(1) 	collate database_default,
				SavedString	nvarchar(max)	collate database_default,
				SortedPosition	smallint	null
				)

-- Table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests table 
		 	       (ROWNUMBER	int 		not null,
	    			ID		nvarchar(100)	collate database_default not null,
	    			SORTORDER	tinyint		null,
	    			SORTDIRECTION	nvarchar(1)	collate database_default null,
				PUBLISHNAME	nvarchar(100)	collate database_default null,
				QUALIFIER	nvarchar(100)	collate database_default null,				
				DOCITEMKEY	int		null,
				PROCEDURENAME	nvarchar(50)	collate database_default null,
				DATAFORMATID  	int 		null,
				NAMECOLUMN	bit		null
			 	)

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
Declare @tbOrderBy 	table (	Position	tinyint		not null,
				Direction	nvarchar(5)	collate database_default not null,
				ColumnName	nvarchar(1000)	collate database_default not null,
				PublishName	nvarchar(50)	collate database_default null,
				ColumnNumber	tinyint		not null
				)


Declare @bShowMatchingName	bit
Declare @bShowMatchingCase	bit
Declare	@bShowCasesForName	bit

Declare @ErrorCode		int
Declare @sAlertXML	 	nvarchar(400)

Declare @Pointer		binary(16)

Declare @nCount			tinyint
Declare @nSelectCount		tinyint
Declare	@nFromCount		tinyint
Declare @nTableCount		tinyint
Declare @nSequenceNo		tinyint
Declare @nSortPosition		tinyint
Declare	@nOutRequestsRowCount	tinyint

Declare @sCurrentTable 		nvarchar(60)

Declare @nColumnNo		tinyint
Declare @sColumn		nvarchar(100)
Declare @sNameKeyLabel		nvarchar(20)
Declare @sCaseKeyLabel		nvarchar(20)
Declare @sPublishName		nvarchar(50)
Declare @sPublishNameForXML	nvarchar(50)	-- Publish name with such characters as '.' and ' ' removed.
Declare @sQualifier		nvarchar(50)
Declare @sProcedureName		nvarchar(50)
Declare @sCorrelationSuffix	nvarchar(50)
Declare @nOrderPosition		tinyint
Declare @sOrderDirection	nvarchar(5)
Declare @nDataFormatID		int

Declare @bNameColumn		bit
Declare	@bExternalUser		bit

Declare @sNameXMLOutputRequests	nvarchar(max)	-- The XML Output Requests prepared for the Name search procedure.
Declare @sCaseXMLOutputRequests	nvarchar(max)	-- The XML Output Requests prepared for the Case search procedure.

Declare @sTableColumn		nvarchar(max)
Declare @sSql			nvarchar(max)
Declare @sSQLString		nvarchar(max)
Declare	@sSavedString		nvarchar(max)

Declare	@sSelectList		nvarchar(max)

Declare @sDerivedStart1		nvarchar(100)
Declare @sDerivedStart2		nvarchar(100)
Declare @sDerivedEnd1		nvarchar(100)
Declare @sDerivedEnd2		nvarchar(100)

Declare	@sNameSelectList1	nvarchar(max)	-- the SQL list of columns to return
Declare	@sNameSelectList2	nvarchar(max)
Declare	@sNameSelectList3	nvarchar(max)
Declare	@sNameSelectList4	nvarchar(max)
Declare	@sNameSelectList5	nvarchar(max)	-- the SQL list of columns to return
Declare	@sNameSelectList6	nvarchar(max)
Declare	@sNameSelectList7	nvarchar(max)
Declare	@sNameSelectList8	nvarchar(max)
Declare	@sNameFrom1		nvarchar(max)	-- the SQL to list tables and joins
Declare	@sNameFrom2		nvarchar(max)
Declare	@sNameFrom3		nvarchar(max)
Declare	@sNameFrom4		nvarchar(max)
Declare	@sNameFrom5		nvarchar(max)	-- the SQL to list tables and joins
Declare	@sNameFrom6		nvarchar(max)
Declare	@sNameFrom7		nvarchar(max)
Declare	@sNameFrom8		nvarchar(max)
Declare	@sNameFrom9		nvarchar(max)	-- the SQL to list tables and joins
Declare	@sNameFrom10		nvarchar(max)
Declare	@sNameFrom11		nvarchar(max)
Declare	@sNameFrom12		nvarchar(max)
Declare @sNameWhere		nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseSelect)
Declare @sNameWhereFilter	nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the ip_FilterConflict)

Declare	@sCaseSelectList1	nvarchar(max)	-- the SQL list of columns to return
Declare	@sCaseSelectList2	nvarchar(max)
Declare	@sCaseSelectList3	nvarchar(max)
Declare	@sCaseSelectList4	nvarchar(max)
Declare	@sCaseSelectList5	nvarchar(max)	-- the SQL list of columns to return
Declare	@sCaseSelectList6	nvarchar(max)
Declare	@sCaseSelectList7	nvarchar(max)
Declare	@sCaseSelectList8	nvarchar(max)
Declare	@sCaseFrom1		nvarchar(max)	-- the SQL to list tables and joins
Declare	@sCaseFrom2		nvarchar(max)
Declare	@sCaseFrom3		nvarchar(max)
Declare	@sCaseFrom4		nvarchar(max)
Declare	@sCaseFrom5		nvarchar(max)	-- the SQL to list tables and joins
Declare	@sCaseFrom6		nvarchar(max)
Declare	@sCaseFrom7		nvarchar(max)
Declare	@sCaseFrom8		nvarchar(max)
Declare	@sCaseFrom9		nvarchar(max)	-- the SQL to list tables and joins
Declare	@sCaseFrom10		nvarchar(max)
Declare	@sCaseFrom11		nvarchar(max)
Declare	@sCaseFrom12		nvarchar(max)
Declare @sCaseWhere		nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseSelect)
Declare @sCaseWhereFilter	nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the ip_FilterConflict)

Declare @sOrder			nvarchar(max)	-- the SQL sort order
Declare @sNameOrder		nvarchar(max)	-- the SQL sort order
Declare @sCaseOrder		nvarchar(max)	-- the SQL sort order
Declare @sCTE			nvarchar(max)

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int 	

Set @ErrorCode=0

-- Determine if the user is internal or external
If @ErrorCode=0
Begin		
	Set @sSQLString='
	Select	@bExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @ErrorCode=sp_executesql @sSQLString,
				N'@bExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser=@bExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId
End

-- Construct the name of the temporary table used to hold CaseId(s) and NameNo(s).

Set @sCurrentTable = '##SEARCH_' + Cast(@@SPID as varchar(10))+'_' + Cast(@pnQueryContextKey as varchar(15))
				 + CASE WHEN(@pnCallingLevel is not null) THEN '_'+Cast(@pnCallingLevel as varchar(6)) END

-- Now drop the temporary table holding the results.  
-- This is because the temporary table must persist after the completion of the stored procedure when it
-- has been called from Centura to allow for scrolling of table windows within Centura.
If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
and @ErrorCode=0
Begin
	Set @sSql = "drop table "+@sCurrentTable

	exec @ErrorCode=sp_executesql @sSql
End

-- Create the table that will store Names and Cases to be reported on
-- as potential conflicts.
If @ErrorCode=0
Begin
	Set @sSql = '
	Create Table ' + @sCurrentTable + ' (
		RecordType		int		not null,
		NameKey			int		null,
		CaseKey			int		null,
		IsAssociatedName	bit		null,
		IsAssociatedNameDesc	nvarchar(30)	collate database_default null
		)'
		
	exec @ErrorCode=sp_executesql @sSql
End


-- Call the ip_FilterConflict that is responsible for the filter criteria 
-- and the production of an appropriate result set. 
-- The @psTempTableName output parameter is the name of the the global temporary
-- table that will hold the filtered list of Cases and Names that will subsequently
-- be reported on.

If @ErrorCode = 0
Begin
	exec @ErrorCode = dbo.ip_FilterConflict	@psReturnClause 	= @sCaseWhereFilter	OUTPUT,
						@psFormattedTerms	= @psSearchTerms	OUTPUT,
						@psFormattedNameFields	= @psNameFields		OUTPUT,
						@psFormattedCaseFields	= @psCaseFields		OUTPUT,	
						@pbShowMatchingName	= @bShowMatchingName	OUTPUT,
						@pbShowMatchingCase	= @bShowMatchingCase	OUTPUT,
						@pbShowCasesForName	= @bShowCasesForName	OUTPUT,
						@psTempTableName 	= @sCurrentTable,	
						@pnUserIdentityId	= @pnUserIdentityId,	
						@psCulture		= @psCulture,	
						@pbIsExternalUser	= @bExternalUser,
						@ptXMLFilterFields	= @ptXMLFilterFields,
						@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
					    	@pbCalledFromCentura	= @pbCalledFromCentura,
						@pbPrintSQL		= @pbPrintSQL
End

-- Load the columns required in the output into a table variable as some
-- preprocessing may be required on these if a single result set combining 
-- both Case and Name results is required. There is also the possibility of
-- an addional Name column that will be sourced from the temporary table generated
-- within this stored procedure.
If @ErrorCode=0
Begin
	Set @nOutRequestsRowCount=0

	--  If the @ptXMLNameOutputRequests have been supplied, the table variable is populated from the XML.
	If @bShowMatchingName=1
	Begin
		Set @sNameXMLOutputRequests = '<?xml version="1.0"?>'+char(10)+'	<OutputRequests>'

		If datalength(@ptXMLNameOutputRequests) > 0
		Begin
			-- Create an XML document in memory and then retrieve the information 
			-- from the rowset using OPENXML		
			exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLNameOutputRequests
			
			Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, NAMECOLUMN)
			Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, 1
			from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLNameOutputRequests, @idoc,@pbCalledFromCentura,null)
	
			-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
			-- while constructing the "Select" list   
			Set @nOutRequestsRowCount = @@ROWCOUNT
			
			-- deallocate the xml document handle when finished.
			exec sp_xml_removedocument @idoc
		End
		-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
		Else Begin   
			-- Default @pnQueryContextKey to 160.
			Set @pnQueryContextKey = isnull(@pnQueryContextKey, 250)
		
			Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, NAMECOLUMN)
			Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, 1
			from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,'Name')	

			-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
			-- while constructing the "Select" list   
			Set @nOutRequestsRowCount = @@ROWCOUNT
		End
	
		-- The NameKey will be required by the outer SQL because Name data is 
		-- always returned in derived table because there may be additional
		-- columns from the generated temporary table
		If not exists ( Select 1 
				from @tblOutputRequests
				where ID = 'NameKey'
				and PROCEDURENAME<>'ip_ListConflict')
		Begin
			insert into @tblOutputRequests (ROWNUMBER, ID,NAMECOLUMN, PROCEDURENAME)
			select isnull(max(ROWNUMBER),0)+1, 'NameKey',1,'naw_ListName'
			from @tblOutputRequests

			Set @nOutRequestsRowCount=@nOutRequestsRowCount+1
		End
	End

	--  If the @ptXMLCaseOutputRequests have been supplied, the table variable is populated from the XML.
	If @bShowMatchingCase=1
	or @bShowCasesForName=1
	Begin
		Set @sCaseXMLOutputRequests = '<?xml version="1.0"?>'+char(10)+'	<OutputRequests>'

		If datalength(@ptXMLCaseOutputRequests) > 0
		Begin	
			-- Create an XML document in memory and then retrieve the information 
			-- from the rowset using OPENXML		
			exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLCaseOutputRequests
			
			Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, NAMECOLUMN)
			Select ROWNUMBER+@nOutRequestsRowCount, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, 0
			from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLCaseOutputRequests, @idoc,@pbCalledFromCentura,null)
		
			-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
			-- while constructing the "Select" list   
			Set @nOutRequestsRowCount = @nOutRequestsRowCount + @@ROWCOUNT
			
			-- deallocate the xml document handle when finished.
			exec sp_xml_removedocument @idoc
		End
		-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
		Else
		Begin   
			-- Default @pnQueryContextKey to 160.
			Set @pnQueryContextKey = isnull(@pnQueryContextKey, 250)
		
			Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID)
			Select ROWNUMBER+@nOutRequestsRowCount, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID
			from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,'Case')	

			-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
			-- while constructing the "Select" list   
			Set @nOutRequestsRowCount = @nOutRequestsRowCount + @@ROWCOUNT
		End
	
		-- The CaseKey will be required by the outer SQL. Add it if not already present and
		-- a single result set is required.
		If @pbSingleResultSet=1
		and not exists ( Select 1 
				from @tblOutputRequests
				where ID = 'CaseKey'
				and PROCEDURENAME<>'ip_ListConflict')
		Begin
			insert into @tblOutputRequests (ROWNUMBER, ID,NAMECOLUMN,PROCEDURENAME)
			select isnull(max(ROWNUMBER),0)+1, 'CaseKey',0,'csw_ListCase'
			from @tblOutputRequests
 
			Set @nOutRequestsRowCount = @nOutRequestsRowCount + 1
		End
	End
End

-- Some special processing will be required to ensure the columns in the derived tables
-- are valid.

------------------------------------------------
-----                                      -----
-----    CONSTRUCTION OF THE SELECT list   -----
-----                                      -----
------------------------------------------------

Set @nCount = 1

-- Loop through each column in order to construct the components of the SELECT
-- Where a requested column is has a procedure name of ip_ListConflict then
-- strip that column out of the XML list of output as these columns will be
-- added to the SELECT list within this stored procedure.
While @nCount <= @nOutRequestsRowCount
and   @ErrorCode=0
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
		@sQualifier		= QUALIFIER,
		@sProcedureName		= PROCEDURENAME,
		@nDataFormatID		= DATAFORMATID,
		@bNameColumn		= NAMECOLUMN
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	Set @ErrorCode=@@Error

	-- If a Qualifier exists then generate a value from it that can be used
	-- to create a unique Correlation name for the table

	If @sQualifier is null
	Begin
		Set @sCorrelationSuffix=NULL
	End
	Else Begin			
		Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
	End

	If @sProcedureName = 'ip_ListConflict'
	Begin
		If @sColumn='NameKey'
		Begin
			Set @sTableColumn='Conflict.NameKey'
		End
		Else If @sColumn='RecordType'
		Begin
			Set @sTableColumn='Conflict.RecordType'
		End
		Else If @sColumn='IsAssociatedNameDescription'
		Begin
			Set @sTableColumn='Conflict.IsAssociatedNameDesc'
		End

		If datalength(@sPublishName)>0
		Begin
			Set @sSelectList=@sSelectList+nullif(',', ',' + @sSelectList)+@sTableColumn+' as ['+@sPublishName+']'					
		End
		Else Begin
			Set @sPublishName=NULL
		End
	End
	Else Begin
		-- If a derived table is going to be created then we need to convert any Text column to NVARCHAR
		-- Also Remove spaces, quotes, dots, and any special characters from the Derived Table 
		-- column names to avoid SQL error
		If @pbSingleResultSet=1
		or @bNameColumn=1
		Begin
			Set @sTableColumn=CASE WHEN(@nDataFormatID = 9107)
					       -- cast text type columns as nvarchar(max) to avoid SQL error:
					       THEN 'CAST(C.' + dbo.fn_ConvertToAlphanumeric(@sPublishName)+' as nvarchar(max))'	
					       ELSE CASE WHEN(@bNameColumn=1) THEN 'N.' ELSE 'C.' END + dbo.fn_ConvertToAlphanumeric(@sPublishName)
					  END
		
			If @sColumn='NameKey'
			Begin
				If @sPublishName is not null
					Set @sNameKeyLabel=@sTableColumn
				else
					Set @sNameKeyLabel='N.NameKey'
			End
		
			If @sColumn='CaseKey'
			Begin
				If @sPublishName is not null
					Set @sCaseKeyLabel=@sTableColumn
				else
					Set @sCaseKeyLabel='C.CaseKey'
			End

			-- If the column is being published then concatenate it to the Select list
		
			If datalength(@sPublishName)>0
			Begin
				Set @sSelectList=@sSelectList+nullif(',', ',' + @sSelectList)+@sTableColumn+' as ['+@sPublishName+']'
			End
			Else Begin
				Set @sPublishName=NULL
			End
		
			-- Any case column only required for Sorting, only needs to be produced by the inner SQL 
			-- for sorting by the outer SQL.
			If @sPublishName is null
			Begin  
				Set @sPublishName=@sColumn + @sCorrelationSuffix 
			End	
			
			-- Remove spaces, quotes, dots, and any special characters from the Derived Table 
			-- publish names to avoid SQL error		
			Set @sPublishName=dbo.fn_ConvertToAlphanumeric(@sPublishName)
	
			-- If the column is to be sorted on then save the name of the table column along
			-- with the sort details so that later the Order By can be constructed in the correct sequence
			If @nOrderPosition>0
			Begin
				-- The Case columns are to come before the Name columns in the sequence so that
				-- Null sort higher than data resulting in the Names being reported first
				Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
				values(	CASE WHEN(@bNameColumn=1) THEN 100+@nOrderPosition ELSE @nOrderPosition END, 
					@sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)
		
				Set @ErrorCode = @@ERROR
			End
		End
	
		If @bNameColumn=1
		Begin
			Set @sNameXMLOutputRequests = @sNameXMLOutputRequests + char(10) + 
			'	<Column ID="' + @sColumn + '" ProcedureName="' + @sProcedureName + '" Qualifier="' + @sQualifier + '" PublishName="' + @sPublishName + '" />'
		End
		Else Begin
			Set @sCaseXMLOutputRequests = @sCaseXMLOutputRequests + char(10) + 
			'	<Column ID="' + @sColumn + '" ProcedureName="' + @sProcedureName + '" Qualifier="' + @sQualifier + '" PublishName="' + @sPublishName + '" />'
		End
	End

	-- Increment the counter
	Set @nCount=@nCount+1
End -- While loop

----------------------------------------------------------
-----                                                -----
-----    CONSTRUCTION OF THE COMBINED ORDER BY       -----
-----                                                -----
----------------------------------------------------------
If @ErrorCode=0
Begin		
	-- Assemble the "Order By" clause use in either the Single Select or in the Name result set.

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

	Set @ErrorCode=@@Error		

	If @sOrder is not null
	Begin
		Set @sOrder = ' Order by ' + @sOrder
	End
End

-- Close the <OutputRequest> tag to be able to pass constructed output requests to the List Case procedures.
If @ErrorCode = 0
and @sCaseXMLOutputRequests is not null
Begin   
	Set @sCaseXMLOutputRequests = @sCaseXMLOutputRequests + char(10) + '	</OutputRequests>'

	-- Implement validation to ensure that the @sCaseXMLOutputRequests has not overflowed.
	If right(@sCaseXMLOutputRequests, 17) <> '</OutputRequests>'
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP46', 'There are more Case columns selected than the system is able to process. Please reduce the number of columns selected and retry.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @ErrorCode = @@ERROR
	End
End

-- Close the <OutputRequest> tag to be able to pass constructed output requests to the List Name procedures.
If @ErrorCode = 0
and @sNameXMLOutputRequests is not null
Begin   
	Set @sNameXMLOutputRequests = @sNameXMLOutputRequests + char(10) + '	</OutputRequests>'

	-- Implement validation to ensure that the @sNameXMLOutputRequests has not overflowed.
	If right(@sNameXMLOutputRequests, 17) <> '</OutputRequests>'
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP52', 'There are more Name columns selected than the system is able to process. Please reduce the number of columns selected and retry.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @ErrorCode = @@ERROR
	End
End


-- If a single result set is to be returned that combines both the Name and Case details then the format
-- of the SELECT will be as follows :
--	Select name columns, case columns
--	from @sCurrentTable Conflict
--	left join (Name derived table) N on (N.NameKey=Conflict.NameKey)
--	left join (Case derived table) C on (C.CaseKey=Conflict.CaseKey)
--	Order by T.RecordType, name sort columns, case sort columns

If @pbSingleResultSet=1
and @ErrorCode=0
Begin
	-- Construct the first part of the combined SELECT statement using 
	-- the newly derived SelectList
	If @pbCalledFromCentura=1
	and @ErrorCode=0
	Begin
		-- Single SELECT and called from CENTURA

		Set @sSQLString="
		Insert into #CenturaSelect(SelectList, FromClause, OrderBy)
		values(	'Select '+@sSelectList,
			char(10)+'From '+@sCurrentTable+' Conflict', 
			char(10)+@sOrder)"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSelectList		nvarchar(max),
						  @sCurrentTable	nvarchar(60),
						  @sOrder		nvarchar(1000)',
						  @sSelectList=@sSelectList,
						  @sCurrentTable=@sCurrentTable,
						  @sOrder=@sOrder
	End
	Else Begin
		Set @sSelectList='Select '+@sSelectList+char(10)+'From '+@sCurrentTable+' Conflict'
	End
	
	-- NAMES
	-- Construct the "Select", "From" and the "Order by" clauses for Names

	If datalength(@sNameXMLOutputRequests) > 0
	and @ErrorCode=0 
	Begin
		exec @ErrorCode=dbo.naw_ConstructNameSelect	@pnTableCount		= @nTableCount	OUTPUT,
								@pnUserIdentityId 	= @pnUserIdentityId,
								@psCulture		= @psCulture,
								@pnQueryContextKey	= @pnQueryContextKey,
								@ptXMLOutputRequests	= @sNameXMLOutputRequests,
								@pbCalledFromCentura	= @pbCalledFromCentura

		Set @nSequenceNo=0

		-- Force the order of the component to be Select, From and Where
		-- by updating the SortedPosition column
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL
			set	@nSequenceNo=@nSequenceNo+1,
				SortedPosition=@nSequenceNo
			Where ComponentType='S'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		tinyint	OUTPUT',
						  @nSequenceNo=@nSequenceNo	OUTPUT
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL
			set	@nSequenceNo=@nSequenceNo+1,
				SortedPosition=@nSequenceNo
			Where ComponentType='F'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		tinyint	OUTPUT',
						  @nSequenceNo=@nSequenceNo	OUTPUT
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL
			set	@nSequenceNo=@nSequenceNo+1,
				SortedPosition=@nSequenceNo
			Where ComponentType='W'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		tinyint	OUTPUT',
						  @nSequenceNo=@nSequenceNo	OUTPUT
		End

		-- Now the SQL will be constructed depending on whether the procedure
		-- has been called from Centura.
		If @pbCalledFromCentura=1
		and @ErrorCode=0
		Begin
			-- Format the SQL into Text columns so a single column for 
			-- each component can be returned.
			
			If @nSequenceNo>1
			and @ErrorCode=0
			Begin
				-- Get the TEXT pointer for the FromClause
				Set @sSQLString="
				Select @Pointer=TEXTPTR(FromClause)
				From #CenturaSelect"
				
				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@Pointer	binary(16)	OUTPUT',
								  @Pointer	=@Pointer	OUTPUT
		
				-- Create a LEFT JOIN for the derived table
				If @ErrorCode=0
				Begin
					Set @sSavedString=char(10)+"Left Join"+char(10)+"("
					UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sSavedString
	
					Set @ErrorCode=@@Error
				End
		
				Set @nSortPosition=1
				-- Loop through each component row of the SQL
				While @nSortPosition<=@nSequenceNo
				and   @ErrorCode=0
				Begin		
					-- Get the next SELECT row
					Set @sSQLString="
					Select @sSavedString=SavedString
					from #TempConstructSQL
					where SortedPosition=@nSortPosition"
		
					exec @ErrorCode=sp_executesql @sSQLString,
									N'@sSavedString		nvarchar(max)	OUTPUT,
									  @nSortPosition	tinyint',
									  @sSavedString=@sSavedString		OUTPUT,
									  @nSortPosition   =@nSortPosition
		
					-- Now append the SELECT row to the SelectList
					If @ErrorCode=0
					Begin
						UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sSavedString
		
						Set @ErrorCode=@@Error
					End

					Set @nSortPosition=@nSortPosition+1

				End -- of loop
		
				-- Complete the LEFT JOIN for the derived table
				If @ErrorCode=0
				Begin
					Set @sSavedString=") N"+char(10)+"	on ("+@sNameKeyLabel+"=Conflict.NameKey)"
					UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sSavedString
	
					Set @ErrorCode=@@Error
				End
			End
		End

		Else Begin
			-- Format the SQL into a fixed set of variables that will be
			-- able to be executed

			Set @sSQLString="
			Select 	@sNameSelectList1=S.SavedString, 
				@sNameFrom       =F.SavedString, 
				@sNameWhere      =W.SavedString
			from #TempConstructSQL W	
			left join #TempConstructSQL F	on (F.ComponentType='F'
							and F.Position=(select min(F1.Position)
									from #TempConstructSQL F1
									where F1.ComponentType=F.ComponentType))
			left join #TempConstructSQL S	on (S.ComponentType='S'
							and S.Position=(select min(S1.Position)
									from #TempConstructSQL S1
									where S1.ComponentType=S.ComponentType))	
			Where W.ComponentType='W'"	-- there will only be 1 Where row
		
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@sNameSelectList1	nvarchar(max)	OUTPUT,
							  @sNameFrom		nvarchar(max)	OUTPUT,
							  @sNameWhere		nvarchar(max)	OUTPUT',
							  @sNameSelectList1=@sNameSelectList1	OUTPUT,
							  @sNameFrom       =@sNameFrom1		OUTPUT,
							  @sNameWhere      =@sNameWhere		OUTPUT
		
			-- Now get the additial SELECT clause components.  
			-- A fixed number have been provided for at this point however this can 
			-- easily be increased
			
			If  @sNameSelectList1 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=1"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList2	OUTPUT
		
			End
			
			If  @sNameSelectList2 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=2"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList3	OUTPUT
			End
			
			If  @sNameSelectList3 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=3"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList4	OUTPUT
			End
		
			If  @sNameSelectList4 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=4"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList5		OUTPUT
		
			End
			
			If  @sNameSelectList5 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=5"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList6	OUTPUT
			End
			
			If  @sNameSelectList6 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=6"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList7		OUTPUT
			End
		
			If  @sNameSelectList7 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=7"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList8	OUTPUT
			End
		
			-- Now get the additial FROM clause components.  
			-- A fixed number have been provided for at this point however this can 
			-- easily be increased
			
			If  @sNameFrom1 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=1"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom2	OUTPUT
			End
			
			If  @sNameFrom2 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=2"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom3	OUTPUT
			End
			
			If  @sNameFrom3 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=3"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom4	OUTPUT
			End
		
			If  @sNameFrom4 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=4"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom5	OUTPUT
			End
			
			If  @sNameFrom5 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=5"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom6	OUTPUT
			End
			
			If  @sNameFrom6 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=6"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom7	OUTPUT
			End
		
			If  @sNameFrom7 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=7"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom8	OUTPUT
			End
			
			If  @sNameFrom8 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=8"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom9	OUTPUT
			End
		
			If  @sNameFrom9 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=9"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom10	OUTPUT
			End
			
			If  @sNameFrom10 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=10"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom11	OUTPUT
			End
		
			If  @sNameFrom11 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=11"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom12	OUTPUT
			End	
		End

		-- Clear out the contents of the temporary table #TempConstructSQL
		-- so that it can now be loaded with the Case related data

		If @ErrorCode=0
		Begin
			Set @sSQLString="truncate table #TempConstructSQL"

			exec @ErrorCode=sp_executesql @sSQLString
		End
	End -- End of Name column processing



	-- CASES
	-- Construct the "Select", "From" and the "Order by" clauses for Cases

	if datalength(@sCaseXMLOutputRequests) > 0
	and @ErrorCode=0 
	Begin
		exec @ErrorCode=dbo.csw_ConstructCaseSelect	@pnTableCount		= @nTableCount	OUTPUT,
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,
								@pbExternalUser		= @bExternalUser, 			
								@psTempTableName	= @sCurrentTable,	
								@pnQueryContextKey	= @pnQueryContextKey,
								@ptXMLOutputRequests	= @sCaseXMLOutputRequests,
								@pbCalledFromCentura	= @pbCalledFromCentura

		Set @nSequenceNo=0

		-- Force the order of the component to be Select, From and Where
		-- by updating the SortedPosition column
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL
			set	@nSequenceNo=@nSequenceNo+1,
				SortedPosition=@nSequenceNo
			Where ComponentType='S'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		tinyint	OUTPUT',
						  @nSequenceNo=@nSequenceNo	OUTPUT
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL
			set	@nSequenceNo=@nSequenceNo+1,
				SortedPosition=@nSequenceNo
			Where ComponentType='F'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		tinyint	OUTPUT',
						  @nSequenceNo=@nSequenceNo	OUTPUT
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL
			set	@nSequenceNo=@nSequenceNo+1,
				SortedPosition=@nSequenceNo
			Where ComponentType='W'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		tinyint	OUTPUT',
						  @nSequenceNo=@nSequenceNo	OUTPUT
		End

		-- Now the SQL will be constructed depending on whether the procedure
		-- has been called from Centura.
		If @pbCalledFromCentura=1
		Begin
			-- Format the SQL into Text columns so a single column for 
			-- each component can be returned.
			
			If @nSequenceNo>1
			and @ErrorCode=0
			Begin
				-- Get the TEXT pointer for the FromClause
				Set @sSQLString="
				Select @Pointer=TEXTPTR(FromClause)
				From #CenturaSelect"
				
				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@Pointer	binary(16)	OUTPUT',
								  @Pointer	=@Pointer	OUTPUT
		
				-- Create a LEFT JOIN for the derived table
				If @ErrorCode=0
				Begin
					Set @sSavedString=char(10)+"Left Join"+char(10)+"("
					UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sSavedString
	
					Set @ErrorCode=@@Error
				End
		
				Set @nSortPosition=1
				-- Loop through each component row of the SQL
				While @nSortPosition<=@nSequenceNo
				and   @ErrorCode=0
				Begin		
					-- Get the next SELECT row
					Set @sSQLString="
					Select @sSavedString=SavedString
					from #TempConstructSQL
					where SortedPosition=@nSortPosition"
		
					exec @ErrorCode=sp_executesql @sSQLString,
									N'@sSavedString	nvarchar(max)	OUTPUT,
									  @nSortPosition	tinyint',
									  @sSavedString=@sSavedString	OUTPUT,
									  @nSortPosition   =@nSortPosition
		
					-- Now append the SELECT row to the SelectList
					If @ErrorCode=0
					Begin
						UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sSavedString
		
						Set @ErrorCode=@@Error
					End

					Set @nSortPosition=@nSortPosition+1

				End -- of loop
		
				-- Complete the LEFT JOIN for the derived table
				If @ErrorCode=0
				Begin
					Set @sSavedString=") C"+char(10)+"	on ("+@sCaseKeyLabel+"=Conflict.CaseKey)"
					UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sSavedString
	
					Set @ErrorCode=@@Error
				End
			End
		End

		Else Begin
			-- Format the SQL into a fixed set of variables that will be
			-- able to be executed

			Set @sSQLString="
			Select 	@sCaseSelectList1=S.SavedString, 
				@sCaseFrom       =F.SavedString, 
				@sCaseWhere      =W.SavedString
			from #TempConstructSQL W	
			left join #TempConstructSQL F	on (F.ComponentType='F'
							and F.Position=(select min(F1.Position)
									from #TempConstructSQL F1
									where F1.ComponentType=F.ComponentType))
			left join #TempConstructSQL S	on (S.ComponentType='S'
							and S.Position=(select min(S1.Position)
									from #TempConstructSQL S1
									where S1.ComponentType=S.ComponentType))	
			Where W.ComponentType='W'"	-- there will only be 1 Where row
		
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@sCaseSelectList1	nvarchar(max)	OUTPUT,
							  @sCaseFrom		nvarchar(max)	OUTPUT,
							  @sCaseWhere		nvarchar(max)	OUTPUT',
							  @sCaseSelectList1=@sCaseSelectList1	OUTPUT,
							  @sCaseFrom       =@sCaseFrom1		OUTPUT,
							  @sCaseWhere      =@sCaseWhere		OUTPUT
		
			-- Now get the additial SELECT clause components.  
			-- A fixed number have been provided for at this point however this can 
			-- easily be increased
			
			If  @sCaseSelectList1 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=1"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList2	OUTPUT
		
			End
			
			If  @sCaseSelectList2 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=2"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList3	OUTPUT
			End
			
			If  @sCaseSelectList3 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=3"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList4	OUTPUT
			End
		
			If  @sCaseSelectList4 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=4"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList5		OUTPUT
		
			End
			
			If  @sCaseSelectList5 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=5"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList6	OUTPUT
			End
			
			If  @sCaseSelectList6 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=6"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList7		OUTPUT
			End
		
			If  @sCaseSelectList7 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=7"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList8	OUTPUT
			End
		
			-- Now get the additial FROM clause components.  
			-- A fixed number have been provided for at this point however this can 
			-- easily be increased
			
			If  @sCaseFrom1 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=1"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom2	OUTPUT
			End
			
			If  @sCaseFrom2 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=2"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom3	OUTPUT
			End
			
			If  @sCaseFrom3 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=3"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom4	OUTPUT
			End
		
			If  @sCaseFrom4 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=4"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom5	OUTPUT
			End
			
			If  @sCaseFrom5 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=5"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom6	OUTPUT
			End
			
			If  @sCaseFrom6 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=6"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom7	OUTPUT
			End
		
			If  @sCaseFrom7 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=7"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom8	OUTPUT
			End
			
			If  @sCaseFrom8 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=8"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom9	OUTPUT
			End
		
			If  @sCaseFrom9 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=9"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom10	OUTPUT
			End
			
			If  @sCaseFrom10 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=10"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom11	OUTPUT
			End
		
			If  @sCaseFrom11 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=11"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom12	OUTPUT
			End	
		End
	End -- End of Case column processing
End -- End of the Single SELECT  

------------------------------------------------------
--
-- Separate result set for Names and Cases is required
--
------------------------------------------------------

-- If a separate result set is to be returned for each of the Name and Case selects
-- the no special processing is required and the formatted SELECT will be:

--	Select name & conflict columns
--	from @sCurrentTable Conflict
--	join (Name derived table) N on (N.NameKey=Conflict.NameKey)
--	Order by name sort columns
--
--	The Name derived table is required because there are columns to be displayed
--	from the outer table
--
--	Select case columns
--	from Case tables N
--	where Case filter
--	and exists
--	(select * from temporary table t
--	 where t.CaseKey=N.CaseKey)
--	Order by case sort columns
Else Begin
	
	-- NAMES
	-- Construct the "Select", "From" and the "Order by" clauses for Names

	if @bShowMatchingName=1
	and @ErrorCode=0 
	Begin
		-- Construct the first part of the combined SELECT statement using 
		-- the newly derived SelectList
		If @pbCalledFromCentura=1
		Begin
			-- Single SELECT and called from CENTURA
	
			Set @sSQLString="
			Insert into #CenturaSelect(SelectList, FromClause, WhereClause, OrderBy, TableType)
			values(	'Select '+@sSelectList,
				char(10)+'From '+@sCurrentTable+' Conflict', 
				char(10)+'Where Conflict.CaseKey is null',
				char(10)+@sOrder,
				'Name')"

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@sSelectList		nvarchar(max),
							  @sCurrentTable	nvarchar(60),
							  @sOrder		nvarchar(1000)',
							  @sSelectList=@sSelectList,
							  @sCurrentTable=@sCurrentTable,
							  @sOrder=@sOrder
		End
		Else Begin
			Set @sSelectList='Select '+@sSelectList+char(10)+'From '+@sCurrentTable+' Conflict'
		End

		exec @ErrorCode=dbo.naw_ConstructNameSelect	@pnTableCount		= @nTableCount	OUTPUT,
								@pnUserIdentityId 	= @pnUserIdentityId,
								@psCulture		= @psCulture,
								@pnQueryContextKey	= @pnQueryContextKey,
								@ptXMLOutputRequests	= @sNameXMLOutputRequests,
								@pbCalledFromCentura	= @pbCalledFromCentura

		Set @nSequenceNo=0

		-- Force the order of the component to be Select, From and Where
		-- by updating the SortedPosition column
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL
			set	@nSequenceNo=@nSequenceNo+1,
				SortedPosition=@nSequenceNo
			Where ComponentType='S'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		tinyint	OUTPUT',
						  @nSequenceNo=@nSequenceNo	OUTPUT
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL
			set	@nSequenceNo=@nSequenceNo+1,
				SortedPosition=@nSequenceNo
			Where ComponentType='F'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		tinyint	OUTPUT',
						  @nSequenceNo=@nSequenceNo	OUTPUT
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL
			set	@nSequenceNo=@nSequenceNo+1,
				SortedPosition=@nSequenceNo
			Where ComponentType='W'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nSequenceNo		tinyint	OUTPUT',
						  @nSequenceNo=@nSequenceNo	OUTPUT
		End

		-- Now the SQL will be constructed depending on whether the procedure
		-- has been called from Centura.
		If @pbCalledFromCentura=1
		and @ErrorCode=0
		Begin
			-- Format the SQL into Text columns so a single column for 
			-- each component can be returned.
			
			If @nSequenceNo>1
			Begin
				-- Get the TEXT pointer for the FromClause
				Set @sSQLString="
				Select @Pointer=TEXTPTR(FromClause)
				From #CenturaSelect"
				
				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@Pointer	binary(16)	OUTPUT',
								  @Pointer	=@Pointer	OUTPUT
		
				-- Create a JOIN for the derived table
				If @ErrorCode=0
				Begin
					Set @sSavedString=char(10)+"Join"+char(10)+"("
					UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sSavedString
	
					Set @ErrorCode=@@Error
				End
		
				Set @nSortPosition=1
				-- Loop through each component row of the SQL
				While @nSortPosition<=@nSequenceNo
				and   @ErrorCode=0
				Begin		
					-- Get the next SELECT row
					Set @sSQLString="
					Select @sSavedString=SavedString
					from #TempConstructSQL
					where SortedPosition=@nSortPosition"
		
					exec @ErrorCode=sp_executesql @sSQLString,
									N'@sSavedString		nvarchar(max)	OUTPUT,
									  @nSortPosition	tinyint',
									  @sSavedString=@sSavedString		OUTPUT,
									  @nSortPosition   =@nSortPosition
		
					-- Now append the SELECT row to the SelectList
					If @ErrorCode=0
					Begin
						UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sSavedString
		
						Set @ErrorCode=@@Error
					End

					Set @nSortPosition=@nSortPosition+1

				End -- of loop
		
				-- Complete the JOIN for the derived table
				If @ErrorCode=0
				Begin
					Set @sSavedString=") N"+char(10)+"	on ("+@sNameKeyLabel+"=Conflict.NameKey)"
					UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sSavedString
	
					Set @ErrorCode=@@Error
				End
			End
		End

		Else Begin
			-- Format the SQL into a fixed set of variables that will be
			-- able to be executed

			Set @sSQLString="
			Select 	@sNameSelectList1=S.SavedString, 
				@sNameFrom       =F.SavedString, 
				@sNameWhere      =W.SavedString
			from #TempConstructSQL W	
			left join #TempConstructSQL F	on (F.ComponentType='F'
							and F.Position=(select min(F1.Position)
									from #TempConstructSQL F1
									where F1.ComponentType=F.ComponentType))
			left join #TempConstructSQL S	on (S.ComponentType='S'
							and S.Position=(select min(S1.Position)
									from #TempConstructSQL S1
									where S1.ComponentType=S.ComponentType))	
			Where W.ComponentType='W'"	-- there will only be 1 Where row
		
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@sNameSelectList1	nvarchar(max)	OUTPUT,
							  @sNameFrom		nvarchar(max)	OUTPUT,
							  @sNameWhere		nvarchar(max)	OUTPUT',
							  @sNameSelectList1=@sNameSelectList1	OUTPUT,
							  @sNameFrom       =@sNameFrom1		OUTPUT,
							  @sNameWhere      =@sNameWhere		OUTPUT
		
			-- Now get the additial SELECT clause components.  
			-- A fixed number have been provided for at this point however this can 
			-- easily be increased
			
			If  @sNameSelectList1 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=1"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList2	OUTPUT
		
			End
			
			If  @sNameSelectList2 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=2"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList3	OUTPUT
			End
			
			If  @sNameSelectList3 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=3"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList4	OUTPUT
			End
		
			If  @sNameSelectList4 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=4"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList5		OUTPUT
		
			End
			
			If  @sNameSelectList5 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=5"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList6	OUTPUT
			End
			
			If  @sNameSelectList6 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=6"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList7		OUTPUT
			End
		
			If  @sNameSelectList7 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=7"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameSelectList	nvarchar(max)	OUTPUT',
								  @sNameSelectList=@sNameSelectList8	OUTPUT
			End
		
			-- Now get the additial FROM clause components.  
			-- A fixed number have been provided for at this point however this can 
			-- easily be increased
			
			If  @sNameFrom1 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=1"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom2	OUTPUT
			End
			
			If  @sNameFrom2 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=2"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom3	OUTPUT
			End
			
			If  @sNameFrom3 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=3"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom4	OUTPUT
			End
		
			If  @sNameFrom4 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=4"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom5	OUTPUT
			End
			
			If  @sNameFrom5 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=5"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom6	OUTPUT
			End
			
			If  @sNameFrom6 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=6"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom7	OUTPUT
			End
		
			If  @sNameFrom7 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=7"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom8	OUTPUT
			End
			
			If  @sNameFrom8 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=8"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom9	OUTPUT
			End
		
			If  @sNameFrom9 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=9"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom10	OUTPUT
			End
			
			If  @sNameFrom10 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=10"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom11	OUTPUT
			End
		
			If  @sNameFrom11 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sNameFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=11"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sNameFrom	nvarchar(max)	OUTPUT',
								  @sNameFrom=@sNameFrom12	OUTPUT
			End	
		End

		-- Clear out the contents of the temporary table #TempConstructSQL
		-- so that it can now be loaded with the Case related data

		If @ErrorCode=0
		Begin
			Set @sSQLString="truncate table #TempConstructSQL"

			exec @ErrorCode=sp_executesql @sSQLString
		End
	End -- End of Name column processing

	-- CASES
	-- Construct the "Select", "From" and the "Order by" clauses for Cases

	If (@bShowMatchingCase=1
	or  @bShowCasesForName=1)
	and @ErrorCode=0 
	Begin
		exec @ErrorCode=dbo.csw_ConstructCaseSelect	@pnTableCount		= @nTableCount	OUTPUT,
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,
								@pbExternalUser		= @bExternalUser, 			
								@psTempTableName	= @sCurrentTable,	
								@pnQueryContextKey	= @pnQueryContextKey,
								@ptXMLOutputRequests	= @sCaseXMLOutputRequests,
								@pbCalledFromCentura	= @pbCalledFromCentura

		Set @sCaseWhereFilter=	char(10)+"and exists"+char(10)+
					"(select * from "+@sCurrentTable+" T"+char(10)+
					" where T.CaseKey=C.CASEID)"

		-- Now the SQL will be constructed depending on whether the procedure
		-- has been called from Centura.
		If @pbCalledFromCentura=1
		and @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into #CenturaSelect(SelectList, FromClause, WhereClause, WhereFilter,  
						   OrderBy, TableType)
			Select S.SavedString, F.SavedString, W.SavedString, @sCaseWhereFilter, O.SavedString, 'Case'
			from #TempConstructSQL W	
			left join #TempConstructSQL F	on (F.ComponentType='F'
							and F.Position=(select min(F1.Position)
									from #TempConstructSQL F1
									where F1.ComponentType=F.ComponentType))
			left join #TempConstructSQL S	on (S.ComponentType='S'
							and S.Position=(select min(S1.Position)
									from #TempConstructSQL S1
									where S1.ComponentType=S.ComponentType))	
			left join #TempConstructSQL O	on (O.ComponentType='O')
			Where W.ComponentType='W'"				-- there will only be 1 Where row
		
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@sCaseWhereFilter		nvarchar(max)',
							  @sCaseWhereFilter=@sCaseWhereFilter
		
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @nSelectCount=count(*)
				from #TempConstructSQL
				where ComponentType='S'"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@nSelectCount	tinyint		OUTPUT',
								  @nSelectCount	=@nSelectCount	OUTPUT
			End

			-- Format the SQL into Text columns so a single column for 
			-- each component can be returned.
	
			If @nSelectCount>1
			and @ErrorCode=0
			Begin
				-- Get the TEXT point for SelectList
				Set @sSQLString="
				Select @Pointer=TEXTPTR(SelectList)
				From #CenturaSelect"
				
				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@Pointer	binary(16)	OUTPUT',
								  @Pointer	=@Pointer	OUTPUT
		
				-- Loop through each SELECT row
				While @nSelectCount>1
				and   @ErrorCode=0
				Begin
					Set @nSelectCount=@nSelectCount-1
		
					-- Get the next SELECT row
					Set @sSQLString="
					Select @sCaseSelectList1=S.SavedString
					from #TempConstructSQL S
					where S.ComponentType='S'
					and (	select count(*)
						from #TempConstructSQL S1
						where S1.ComponentType=S.ComponentType
						and S1.Position>S.Position)=@nSelectCount-1"
		
					exec @ErrorCode=sp_executesql @sSQLString,
									N'@sCaseSelectList1	nvarchar(max)	OUTPUT,
									  @nSelectCount	tinyint',
									  @sCaseSelectList1=@sCaseSelectList1	OUTPUT,
									  @nSelectCount    =@nSelectCount
		
					-- Now append the SELECT row to the SelectList
					If @ErrorCode=0
					Begin
						UpdateText #CenturaSelect.SelectList @Pointer NULL NULL @sCaseSelectList1
		
						Set @ErrorCode=@@Error
					End
		
				End -- of loop
			End

			-- Now concatenate the components of the FROM clause
		
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @nFromCount=count(*)
				from #TempConstructSQL
				where ComponentType='F'"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@nFromCount		tinyint	OUTPUT',
								  @nFromCount=@nFromCount	OUTPUT
			End
			
			If @nFromCount>1
			and @ErrorCode=0
			Begin
				-- Get the TEXT point for FromClause
				Set @sSQLString="
				Select @Pointer=TEXTPTR(FromClause)
				From #CenturaSelect"
				
				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@Pointer	binary(16)	OUTPUT',
								  @Pointer=@Pointer		OUTPUT
		
				-- Loop through each FROM row
				While @nFromCount>1
				and   @ErrorCode=0
				Begin
					Set @nFromCount=@nFromCount-1
		
					-- Get the next FROM row
					Set @sSQLString="
					Select @sCaseFrom=F.SavedString
					from #TempConstructSQL F
					where F.ComponentType='F'
					and (	select count(*)
						from #TempConstructSQL F1
						where F1.ComponentType=F.ComponentType
						and F1.Position>F.Position)=@nFromCount-1"
		
					exec @ErrorCode=sp_executesql @sSQLString,
									N'@sCaseFrom	nvarchar(max)	OUTPUT,
									  @nFromCount	tinyint',
									  @sCaseFrom=@sCaseFrom1	OUTPUT,
									  @nFromCount=@nFromCount
		
					-- Now append the From row to the FromClause
					If @ErrorCode=0
					Begin
						UpdateText #CenturaSelect.FromClause @Pointer NULL NULL @sCaseFrom1
		
						Set @ErrorCode=@@Error
					End
		
				End -- of loop
			End

		End

		Else Begin
			-- Format the SQL into a fixed set of variables that will be
			-- able to be executed

			Set @sSQLString="
			Select 	@sCaseSelectList1=S.SavedString, 
				@sCaseFrom       =F.SavedString, 
				@sCaseWhere      =W.SavedString,
				@sCaseOrder	 =O.SavedString
			from #TempConstructSQL W	
			left join #TempConstructSQL F	on (F.ComponentType='F'
							and F.Position=(select min(F1.Position)
									from #TempConstructSQL F1
									where F1.ComponentType=F.ComponentType))
			left join #TempConstructSQL S	on (S.ComponentType='S'
							and S.Position=(select min(S1.Position)
									from #TempConstructSQL S1
									where S1.ComponentType=S.ComponentType))
			left join #TempConstructSQL O	on (O.ComponentType='O')
			Where W.ComponentType='W'"	-- there will only be 1 Where row
		
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@sCaseSelectList1	nvarchar(max)	OUTPUT,
							  @sCaseFrom		nvarchar(max)	OUTPUT,
							  @sCaseWhere		nvarchar(max)	OUTPUT,
							  @sCaseOrder		nvarchar(1000)	OUTPUT',
							  @sCaseSelectList1=@sCaseSelectList1	OUTPUT,
							  @sCaseFrom       =@sCaseFrom1		OUTPUT,
							  @sCaseWhere      =@sCaseWhere		OUTPUT,
							  @sCaseOrder	   =@sCaseOrder		OUTPUT
		
			-- Now get the additial SELECT clause components.  
			-- A fixed number have been provided for at this point however this can 
			-- easily be increased
			
			If  @sCaseSelectList1 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=1"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList2	OUTPUT
		
			End
			
			If  @sCaseSelectList2 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=2"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList3	OUTPUT
			End
			
			If  @sCaseSelectList3 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=3"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList4	OUTPUT
			End
		
			If  @sCaseSelectList4 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=4"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList5		OUTPUT
		
			End
			
			If  @sCaseSelectList5 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=5"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList6	OUTPUT
			End
			
			If  @sCaseSelectList6 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=6"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList7		OUTPUT
			End
		
			If  @sCaseSelectList7 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseSelectList=S.SavedString
				from #TempConstructSQL S
				where S.ComponentType='S'
				and (	select count(*)
					from #TempConstructSQL S1
					where S1.ComponentType=S.ComponentType
					and S1.Position<S.Position)=7"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseSelectList	nvarchar(max)	OUTPUT',
								  @sCaseSelectList=@sCaseSelectList8	OUTPUT
			End
		
			-- Now get the additial FROM clause components.  
			-- A fixed number have been provided for at this point however this can 
			-- easily be increased
			
			If  @sCaseFrom1 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=1"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom2	OUTPUT
			End
			
			If  @sCaseFrom2 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=2"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom3	OUTPUT
			End
			
			If  @sCaseFrom3 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=3"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom4	OUTPUT
			End
		
			If  @sCaseFrom4 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=4"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom5	OUTPUT
			End
			
			If  @sCaseFrom5 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=5"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom6	OUTPUT
			End
			
			If  @sCaseFrom6 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=6"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom7	OUTPUT
			End
		
			If  @sCaseFrom7 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=7"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom8	OUTPUT
			End
			
			If  @sCaseFrom8 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=8"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom9	OUTPUT
			End
		
			If  @sCaseFrom9 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=9"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom10	OUTPUT
			End
			
			If  @sCaseFrom10 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=10"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom11	OUTPUT
			End
		
			If  @sCaseFrom11 is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sCaseFrom=F.SavedString
				from #TempConstructSQL F
				where F.ComponentType='F'
				and (	select count(*)
					from #TempConstructSQL F1
					where F1.ComponentType=F.ComponentType
					and F1.Position<F.Position)=11"
		
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@sCaseFrom	nvarchar(max)	OUTPUT',
								  @sCaseFrom=@sCaseFrom12	OUTPUT
			End	

		End
	End -- End of Case column processing
End

If @ErrorCode=0
Begin
	-- If called from Centura then return the SQL for execution from the Centura program.
	If @pbCalledFromCentura=1
	Begin
		If @pbSingleResultSet=1
		Begin
			Set @sSQLString="
			Select 	SelectList, FromClause, WhereClause, WhereFilter, GroupBy, OrderBy,
				@psSearchTerms,
				@psNameFields,
				@psCaseFields
			from #CenturaSelect"
		End
		Else Begin
			Set @sSQLString="
			Select 	SelectList, FromClause, WhereClause, WhereFilter, GroupBy, OrderBy,
				@psSearchTerms,
				@psNameFields,
				@psCaseFields
			from #CenturaSelect
			Where TableType='Name'

			Select 	SelectList, FromClause, WhereClause, WhereFilter, GroupBy, OrderBy,
				@psSearchTerms,
				@psNameFields,
				@psCaseFields
			from #CenturaSelect
			Where TableType='Case'"
		End

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@psSearchTerms	nvarchar(max),
						  @psNameFields		nvarchar(max),
						  @psCaseFields		nvarchar(max)',
						  @psSearchTerms=@psSearchTerms,
						  @psNameFields=@psNameFields,
						  @psCaseFields=@psCaseFields
	End

	-- Not called by Centura so execute the constructed SQL
	Else Begin
		-------------------------------------------------
		-- RFC62317
		-- Add a common table expression (CTE) to get the 
		-- minimum sequence for a CASEID and NAMETYPE
		------------------------------------------------- 	
		Set @sCTE='with CTE_CaseNameSequence (CASEID, NAMETYPE, SEQUENCE)'+CHAR(10)+
			  'as (	select CASEID, NAMETYPE, MIN(SEQUENCE)'+CHAR(10)+
			  '	from CASENAME with (NOLOCK)'+CHAR(10)+
			  '	where EXPIRYDATE is null or EXPIRYDATE>GETDATE()'+CHAR(10)+
			  '	group by CASEID, NAMETYPE)'+CHAR(10)
			  
		If @pbSingleResultSet=1
		Begin
			If @sNameSelectList1 is not null
			Begin
				Set @sDerivedStart1 =char(10)+"left join ("
				Set @sDerivedEnd1   =") N on ("+@sNameKeyLabel+"=Conflict.NameKey)"+char(10)
			End

			If @sCaseSelectList1 is not null
			Begin
				Set @sDerivedStart2 =char(10)+"left join ("
				Set @sDerivedEnd2   =") C on ("+@sCaseKeyLabel+"=Conflict.CaseKey)"+char(10)
			End

			If @pbPrintSQL = 1
			Begin
				-- Print out the executed SQL statement:
				Print	''
	
				Print 	'SET ANSI_NULLS OFF; '+
					@sCTE+
					@sSelectList+
					@sDerivedStart1+
					@sNameSelectList1+@sNameSelectList2+@sNameSelectList3+@sNameSelectList4+
					@sNameSelectList5+@sNameSelectList6+@sNameSelectList7+@sNameSelectList8+
					@sNameFrom1+@sNameFrom2+@sNameFrom3+@sNameFrom4+
					@sNameFrom5+@sNameFrom6+@sNameFrom7+@sNameFrom8+
					@sNameFrom9+@sNameFrom10+@sNameFrom11+@sNameFrom12 +
					@sNameWhere+@sDerivedEnd1+
					@sDerivedStart2+
					@sCaseSelectList1+@sCaseSelectList2+@sCaseSelectList3+@sCaseSelectList4+
					@sCaseSelectList5+@sCaseSelectList6+@sCaseSelectList7+@sCaseSelectList8+
					@sCaseFrom1+@sCaseFrom2+@sCaseFrom3+@sCaseFrom4+
					@sCaseFrom5+@sCaseFrom6+@sCaseFrom7+@sCaseFrom8+
					@sCaseFrom9+@sCaseFrom10+@sCaseFrom11+@sCaseFrom12 +
					@sCaseWhere+@sDerivedEnd2+
					@sOrder
			End
	
			exec (	'SET ANSI_NULLS OFF; '+
				@sCTE+
				@sSelectList+
				@sDerivedStart1+
				@sNameSelectList1+@sNameSelectList2+@sNameSelectList3+@sNameSelectList4+
				@sNameSelectList5+@sNameSelectList6+@sNameSelectList7+@sNameSelectList8+
				@sNameFrom1+@sNameFrom2+@sNameFrom3+@sNameFrom4+
				@sNameFrom5+@sNameFrom6+@sNameFrom7+@sNameFrom8+
				@sNameFrom9+@sNameFrom10+@sNameFrom11+@sNameFrom12 +
				@sNameWhere+@sDerivedEnd1+
				@sDerivedStart2+
				@sCaseSelectList1+@sCaseSelectList2+@sCaseSelectList3+@sCaseSelectList4+
				@sCaseSelectList5+@sCaseSelectList6+@sCaseSelectList7+@sCaseSelectList8+
				@sCaseFrom1+@sCaseFrom2+@sCaseFrom3+@sCaseFrom4+
				@sCaseFrom5+@sCaseFrom6+@sCaseFrom7+@sCaseFrom8+
				@sCaseFrom9+@sCaseFrom10+@sCaseFrom11+@sCaseFrom12 +
				@sCaseWhere+@sDerivedEnd2+
				@sOrder)
	
			Select 	@ErrorCode =@@Error,
				@pnRowCount=@@Rowcount
		End
		Else Begin

			If @sNameSelectList1 is not null
			Begin
				Set @sDerivedStart1 =char(10)+"join ("
				Set @sDerivedEnd1   =") N on ("+@sNameKeyLabel+"=Conflict.NameKey)"+char(10)+
						     "Where Conflict.CaseKey is null"+char(10)
			End

			If @pbPrintSQL = 1
			Begin
				-- Print out the executed SQL statement:
				Print ''
	
				Print 	'SET ANSI_NULLS OFF; '+
					@sCTE+
					@sSelectList+
					@sDerivedStart1+
					@sNameSelectList1+@sNameSelectList2+@sNameSelectList3+@sNameSelectList4+
					@sNameSelectList5+@sNameSelectList6+@sNameSelectList7+@sNameSelectList8+
					@sNameFrom1+@sNameFrom2+@sNameFrom3+@sNameFrom4+
					@sNameFrom5+@sNameFrom6+@sNameFrom7+@sNameFrom8+
					@sNameFrom9+@sNameFrom10+@sNameFrom11+@sNameFrom12 +
					@sNameWhere+@sDerivedEnd1+
					@sOrder

				Print ''
	
				Print 'SET ANSI_NULLS OFF; '+@sCTE+@sCaseSelectList1+@sCaseSelectList2+@sCaseSelectList3+@sCaseSelectList4+
				      @sCaseSelectList5+@sCaseSelectList6+@sCaseSelectList7+@sCaseSelectList8+
				      @sCaseFrom1+@sCaseFrom2+@sCaseFrom3+@sCaseFrom4+
				      @sCaseFrom5+@sCaseFrom6+@sCaseFrom7+@sCaseFrom8+
				      @sCaseFrom9+@sCaseFrom10+@sCaseFrom11+@sCaseFrom12 +
				      @sCaseWhere+@sCaseWhereFilter+
				      @sCaseOrder
			End
	
			exec (	'SET ANSI_NULLS OFF; '+
				@sCTE+
				@sSelectList+
				@sDerivedStart1+
				@sNameSelectList1+@sNameSelectList2+@sNameSelectList3+@sNameSelectList4+
				@sNameSelectList5+@sNameSelectList6+@sNameSelectList7+@sNameSelectList8+
				@sNameFrom1+@sNameFrom2+@sNameFrom3+@sNameFrom4+
				@sNameFrom5+@sNameFrom6+@sNameFrom7+@sNameFrom8+
				@sNameFrom9+@sNameFrom10+@sNameFrom11+@sNameFrom12 +
				@sNameWhere+@sDerivedEnd1+
				@sOrder)
	
			Select 	@ErrorCode =@@Error,
				@pnRowCount=@@Rowcount
	
			If @ErrorCode=0
			Begin
				exec ('SET ANSI_NULLS OFF; '+@sCTE+@sCaseSelectList1+@sCaseSelectList2+@sCaseSelectList3+@sCaseSelectList4+
				      @sCaseSelectList5+@sCaseSelectList6+@sCaseSelectList7+@sCaseSelectList8+
				      @sCaseFrom1+@sCaseFrom2+@sCaseFrom3+@sCaseFrom4+
				      @sCaseFrom5+@sCaseFrom6+@sCaseFrom7+@sCaseFrom8+
				      @sCaseFrom9+@sCaseFrom10+@sCaseFrom11+@sCaseFrom12 +
				      @sCaseWhere+@sCaseWhereFilter+
				      @sCaseOrder)
		
				Select 	@ErrorCode =@@Error,
					@pnCaseRowCount=@@Rowcount
			End
		End
	
		-- Now drop the temporary table holding the results only if the stored procedure
		-- was not called from Centura
		if exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
		and @ErrorCode=0
		Begin
			Set @sSql = "drop table "+@sCurrentTable
		
			exec @ErrorCode=sp_executesql @sSql
		End
	End
End

RETURN @ErrorCode

go

grant execute on dbo.ip_ListConflict  to public
go

