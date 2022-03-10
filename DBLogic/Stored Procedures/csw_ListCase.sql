-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[csw_ListCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.csw_ListCase.'
	drop procedure dbo.csw_ListCase
end
print '**** Creating procedure dbo.csw_ListCase...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_ListCase
(
	@pnRowCount			int			OUTPUT,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@pnCallingLevel			smallint	= null,	-- Optional number that acknowledges multiple calls of 
								-- the stored procedure from the one connection and
								-- ensures there is not temporary table conflict
	@pbPrintSQL			bit		= null,	-- When set to 1, the executed SQL statement is printed out. 
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null,
	@pbGenerateReportCriteria 	bit 		= 0,	-- When set to 1, the report criteria is to be generated based on the input filter criteria. 
	@pnCaseChargeCount		int		= 0	OUTPUT,	-- number of Case Charges being calculated in background
	@psEmailAddress			nvarchar(100)	= null	OUTPUT, -- email to be notified on completion of background fee calculation
	@pbReturnResultSet		bit		= 1,	-- Allows explicit control of whether the Case result list should be returned.
	@pbGetTotalCaseCount		bit		= 1	-- Allows explicit control of execution of Count against constructed SQL.
)		
as
-- PROCEDURE :	csw_ListCase
-- VERSION :	66
-- DESCRIPTION:	Lists Cases that match the selection parameters.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Version	Mod	Details
-- ----		---	-------	---	-------------------------------------
-- 02 Oct 2003	JEK	1		New .net version based on v24 of cs_ListCase.
-- 10 Oct 2003	MF	2	RFC337	Determine if the user is external or internal.  
--					Provide new filter parameters @psClientKeys & @pnClientKeysOperator
-- 28 Oct 2003	TM	3	RFC537	Change filter functions to stored procedures. 
--					Call new csw_FilterCases stored procedure instead of 
--					the fnw_FilterCases function.
-- 31 Oct 2003	TM	4		Implement  hard coded parameters for the csw_ConstractCaseSelect. 
--					Add new parameters @pnQueryContextKey, @ptXMLOutputRequests, @ptXMLFilterCriteria	
-- 12-Nov-2003	TM	5	RFC509	Implement XML parameters in Case Search.
-- 19-Nov-2003	TM	6	RFC509	Implement Julie's feedback
-- 21-Nov-2003	TM	7       RFC509	Move defaulting to some hard coded columns to be returned to fn_GetOutputRequests.
-- 24-nOV-2003	TM	8	RFC509	Implement the logic thet manages the multiple occurrences of the filter criteria and 
--					the production of an appropriate result set in the new csw_FilterCases.  
-- 09-Dec-2003	JEK	9	RFC643	Change type of QueryContextKey.
-- 04-Feb-2004	MF	10	9661	Modifications to allow Centura program to call the stored procedure
-- 19-Feb-2004	TM	11	RFC976	Pass the @pbCalledFromCentura parameter to csw_FilterCases and csw_ConstructCaseSelect.
-- 15-Mar-2004	MF	12	9689	Allow for additional Cases to be added or removed from result and also
--					for Cases within the result set to be included or excluded. Change required 
--					to drop temporary table @sCopyTable.
-- 24-Mar-2004	MF	13	9843	Implement new input parameter @pnCallingLevel to be used in the generation
--					of the temporary table name.
-- 02-Apr-2004	MF	14	9664	Provid a temporary table to be used in the construction of the SQL
-- 25-Apr-2004	MF	15	RFC1334	Allow for addional components of the final SELECT to include a UNION
-- 10-Apr-2004	MF	16	RFC1334	Coding correction
-- 05 Aug 2004	AB	17	8035	Add collate database_default to temp table definitions
-- 20 Sep 2004	TM	18	RFC886	Cater for multiple Select rows in the #TempConstructSQL temporary table 
--					and assume that the 'Where' type will only have one row. 
-- 08 Nov 2004	TM	19	RFC1980 Save the fn_GetLookupCulture in @psCulture to improve performance.
-- 20 Dec 2004	TM	20	RFC1837	Increase the number of 'From' hard coded variables from 4 to 12 and 'Select'
--					variables from 4 to 8. Add new optional @pbPrintSQL bit parameter. 
-- 15 May 2005	JEK	21	RFC2508	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 02 Sep 2005	MF	22	SQA11833 Allow NULLS to be consdered in data comparisons by SET ANSI_NULLS OFF
-- 20 Oct 2005	TM	23	RFC3024 Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 09 Mar 2006	TM	24	RFC3465	Add two new parameters @pnPageStartRow, @pnPageEndRow and implement
--					SQL Server Paging.
-- 16 May 2006  DL	25	SQA11472 Add optional parameter @pbGenerateReportCriteria and return ReportCriteria 
--					in Centura result set.
-- 13 Dec 2006	MF	26	14002	Paging should not do a separate count() on the database if the rows returned
--					are less than the maximum allowed for.
-- 03 Jan 2007	MF	27	RFC2982	Pass the Filter Criteria to csw_GetExtendedCaseDetails
-- 18 Jan 2007	MF	28	RFC2982	Pass @pbPrintSQL to csw_GetExtendedDetails
-- 13 Feb 2007	MF	29	RFC2982	The extraction of extended details (csw_GetExtendedCaseDetails) is to occur
--					after the construction of the SELECT and ORDER BY clauses(csw_ConstructCaseSelect).  
--					This will then allow large result sets that are only returning explicit pages of 
--					information to be limited to return extended details only for the rows that will
--					actually appear on the required pages.
-- 20 Feb 2007	MF	30	RFC2982	Allow the pageing requests to be applied withn the csw_GetExtendedCaseDetail procedure.
-- 12 Mar 2007	MF	31	14551	Revisit of RFC3465 to correct erroneous use of REPLACE statement when paging
--					required.
-- 16 Jul 2007	MF	32	14957	SQL Error on Due Date enquiry with Alerts and user defined column.  Required the
--					temporary table name of case results to be replaced.  Also found problem in
--					pagination.
-- 12 Oct 2007	MF	33	14957	Revisit the pagination problem previously found.
-- 10 Jun 2009	MF	34	17748	Reduce locking level to ensure other activities are not blocked.
-- 16 Jun 2009	MF	35	RFC8159	Check if JOIN to fn_FilterUserCases has already occurred and remove any subsequent join.
--					This will improve performance for external user queries.
-- 13 Jul 2009	MF	36	RFC8235	Revisit 8159. Move the code that removes subsequent fn_FilterUserCases to after the point that
--					extended columns are extracted as it was causing an error in some situations.
-- 26 Oct 2009	MF	37	RFC8260	Provide ability to calculate fees in background to avoid long running queries.
-- 03 Nov 2009	LP	38	RFC8260	Rearranged sequence of new output parameters to avoid client-server breakage.
-- 01 Dec 2009	MF	39	RFC6208	Improve performance by allowing control of whether the count for the entire result set should be executed and
--					also introduce a new paging mechanism now available from SQLServer 2005.
-- 10 Dec 2009	MF	40	RFC6208	Revisit to return -1 if the count of result set is not required and we know that there are more rows
--					than what was requested in the page size.
-- 12 Feb 2010	MF	41	RFC8846	For external users we need to perform an interim load into temporary tables of the Cases and Events
--					that the user has access to.
-- 09 Jul 2010	MF	42	RFC9537	When Reminder or Due Dates are being filtered, duplicate rows were being returned. Needed to introduce DISTINCT
--					into the SELECT. Any paging using the TOP keyword needs to occur after the DISTINCT keyword.
-- 12 Jul 2010	MF	43	RFC9507	Special code for Paging is required now, even if Extended columns have been applied.  This is because the TOP 
--					keyword is required to avoid a SQL Error resulting from the use of ORDER BY in the subselect.
-- 29 Jul 2010	MF	44	18421	Remove 4000 character limit on components making up constructed dynamic SQL. This is an initial quick fix to swap
--					nvarchar(max) for nvarchar(max). A more thorough approach for the future could consider removing the multiple
--					variables for Select and From .
-- 20 Jul 2011  DV      45      RFC10984 Rename temporary table #TEMPCASES to #TEMPCASESEXT as a table with same name is already 
--                                      getting created in csw_GetExtendedCaseDetails stored proc
-- 28 Sep 2011	MF	46	R11351	In order to be able to include a DISTINCT clause in a Select where the ORDER BY includes columns that are not to be
--					displayed then we now need to include those Sort Columns within an internal result list that the ORDER BY references
--					and then exclude those columns from the actual list of columns to be displayed.
-- 05 Oct 2011	MF	47	R11351	Extend length of @sCloseWrapper to 1000.
-- 14 Oct 2011	LP	48	R11428  Always return the total number of rows as the SearchTotalRows.
--					The reason here is that if we only return the number of distinct cases, only the corresponding
--					number of due dates will be returned.
-- 02 Nov 2011	DV	49	R11493	Extend length of @sOpenWrapper to nvarchar(max).
-- 13 Dec 2011	LP	50	R11683	Fix SearchResultTotal count when UnionSelect is null.
-- 15 Dec 2011	MF	51	S20215	When called by Centura ensure that only the published Order By list appears in the OrderBy column returned to Centura.
-- 01 Feb 2012	LP	52	R11872	Extend length of @sOpenWrapper to nvarchar(max).
-- 03 Feb 2012	MF	53	S20287	Revisit of SQA20215. The UNION generated on a due date report needs to be prefixed with a carriage return as it was being
--					concatenated to a preceding column name and being ignored which resulted in the the output being treated as 2 Select statements.
-- 04 Feb 2012	MF	54	S20287	Failed beta test.  Only prefix with the carriage return if there is actually going to be a UNION.
-- 29 Feb 2012	LP	55	S20382	Fixed ORDER BY error when running Ad Hoc Date report from client-server.
-- 23 Mar 2012 DL	56	S20245	Fixed sort order to ensure can sort by Case CLASS Alphabetical then Numberical (ref R11351)
-- 27 Mar 2012	LP	57	R10987	Fixed logic when returning SearchResultRows asynchronously;
--					i.e. @pnPageEndRows = 0, @pbReturnResultSet = 0, @pbGetTotalCaseCount = 1
-- 16 Apr 2012	MF	58	R12182	Revisit of SQA20245. Do not return the RowKey in the result if csw_ListCase is called from Centura Picklist which can be 
--					determined when @pnCallingLevel<>1 	.
-- 11 May 2012	MF	59	R12296	Further revisit of SQA20245. Only exclude RowKey if @pnCallingLevel=2 and also handle the situation where Due Date report
--					generates a SELECT with UNION.
-- 27 Jul 2012	MF	60	R12432	When the number of rows in the result has been requested using the @pbGetTotalCaseCount=1 parameter then the number of rows must
--					cater for the possibility that multiple columns in the result with a DISTINCT clause can impact the actually rows returned.
-- 03 Aug 2012  MS      61      R12582  Fix error related to SearhSetTotalRows returning null value
-- 16 Aug 2012	DL	62	S20833	Use of RowKey gives a distinct result set so  Distinct and RowKey are no longer required in the search query.  Only apply to Client Server Case search.
-- 31 Aug 2012	MF	63	R12485	If IMAGEDATA is being returned then a DISTINCT clause may not be used as it will cause the query to return an error.
-- 14 Jul 2016	MF	64	62317	Performance improvement using a CTE to get the minimum SEQUENCE by Caseid and NameType. 
-- 08 Feb 2016	MF	65	70583	Performance improvement. When we are using the maximum RowKey to get the number of rows the query returns, the ORDER BY clause needs to exist however it can simplified to just one column.
-- 07 Sep 2018	AV	74738	66	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- SQA9664
-- Create a temporary table to be used in the construction of the SELECT.
Create table #TempConstructSQL (Position	smallint	identity(1,1),
				ComponentType	char(1)		collate database_default,
				SavedString	nvarchar(max)	collate database_default
				)

-- RFC8846
-- Create a temporary table to hold the possible
-- Cases that an external user may see. This is being
-- done as a performance improvement.
Create table #TEMPCASESEXT (	CASEID			int		not null primary key, 
				CLIENTCORRESPONDNAME	int		null, 
				CLIENTREFERENCENO	nvarchar(100)	collate database_default NULL, 
				CLIENTMAINCONTACT	int		null
			)
-- Create a temporary table to hold the possible
-- Events that an external user may see. This is being
-- done as a performance improvement.
Create table #TEMPEVENTS (	EVENTNO			int		NOT NULL primary key,
				EVENTCODE		nvarchar(10)	collate database_default NULL,
				EVENTDESCRIPTION	nvarchar(254)	collate database_default NULL,
				NUMCYCLESALLOWED	smallint	NULL,
				IMPORTANCELEVEL		nvarchar(2)	collate database_default NULL,
				CONTROLLINGACTION	nvarchar(2)	collate database_default NULL,
				DEFINITION		nvarchar(254)	collate database_default NULL
			)

Declare @ErrorCode		int

Declare @nTableCount		tinyint
Declare @nFromCount		tinyint
Declare @nSelectCount		tinyint
Declare @nUnionSelectCount	tinyint
Declare @nCaseTotal		int

Declare @sCurrentTable 		nvarchar(60)	
Declare @sResultTable		nvarchar(60)
Declare @sCopyTable		nvarchar(60)
Declare @sOldTable		nvarchar(60)

Declare @bPagingApplied		bit
Declare @bTempTableExists	bit
Declare	@bExternalUser		bit
Declare @pbExists		bit
Declare	@bDistinctNotAllowed	bit

Declare @sSQLString		nvarchar(max)

Declare	@sSelectList		nvarchar(max)
Declare	@sFromClause		nvarchar(max)
Declare	@sWhereClause		nvarchar(max)
Declare @sWhereFilter		nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_FilterCases)
Declare @sGroupBy		nvarchar(max)	-- the SQL for grouping columns of like values
Declare	@sUnionSelect		nvarchar(max)
Declare	@sUnionFrom		nvarchar(max)
Declare @sUnionWhere		nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseSelect) for the UNION
Declare @sUnionFilter		nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_FilterCases) for the UNION
Declare @sUnionGroupBy		nvarchar(max)	-- the SQL for grouping columns of like values for the UNION
Declare @sOrder			nvarchar(max)	-- the SQL sort order
Declare	@sFirstColumn		nvarchar(max)	-- the first column in the result set.  Will use this to simplify query that is determining the number of rows returned.
Declare	@sReportCriteria	nvarchar(max)

Declare @sCountSelect		nvarchar(max)	-- A part of the Select statement required to calculate the @pnSearchSetTotalRows - Potential number of rows in the search result set
Declare	@sCloseCount		nvarchar(100)
Declare	@sOpenWrapper		nvarchar(max)
Declare @sCloseWrapper		nvarchar(1000)
Declare @sCTE			nvarchar(1000)

Declare	@sTopUnionSelect	nvarchar(max)	-- the SQL list of columns to return for the UNION modified for paging
Declare	@sTopSelectList		nvarchar(max)	-- the SQL list of columns to return modified for paging

Declare @sPublishedColumns	nvarchar(max)	-- the actual columns to appear in the result set
Declare @sPublishedOrderBy	nvarchar(max)	-- the ORDER BY that only contains the columns to be actually displayed.

Declare @sLookupCulture		nvarchar(10)

set transaction isolation level read uncommitted
	
Set @ErrorCode=0

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

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

-- Construct the name of the temporary table used to hold Cases for complex searches.

Set @sCurrentTable = '##SEARCHCASE_' + Cast(@@SPID as varchar(10))+'_' + Cast(@pnQueryContextKey as varchar(15))
				     + CASE WHEN(@pnCallingLevel is not null) THEN '_'+Cast(@pnCallingLevel as varchar(6)) END
Set @sResultTable  = @sCurrentTable+'_RESULT'
Set @sCopyTable    = @sCurrentTable+'_COPY'

-- Now drop the temporary table holding the results.  
-- This is because the temporary table must persist after the completion of the stored procedure when it
-- has been called from Centura to allow for scrolling of table windows within Centura.
If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
and @ErrorCode=0
Begin
	Set @sSQLString = "drop table "+@sCurrentTable

	exec @ErrorCode=sp_executesql @sSQLString
End

-- The temporary table name may have changed when additional Cases have been 
-- added or ticked Cases used.
If exists(select * from tempdb.dbo.sysobjects where name = @sCopyTable)
and @ErrorCode=0
Begin
	Set @sSQLString = "drop table "+@sCopyTable

	exec @ErrorCode=sp_executesql @sSQLString
End

-- The temporary table name may have changed when extended column details were requested
-- in the previous execution.
If exists(select * from tempdb.dbo.sysobjects where name = @sResultTable)
and @ErrorCode=0
Begin
	Set @sSQLString = "drop table "+@sResultTable

	exec @ErrorCode=sp_executesql @sSQLString
End

if @bExternalUser=1
and @ErrorCode=0
Begin
	-------------------------------------------------------
	-- RFC8846
	-- For external users we need to populate the following
	-- temporary tables with the restricted data that the 
	-- external user may see.
	-- This is a performance improvement step because we 
	-- found that on large databases the embedding of the 
	-- table valued user defined function would sometimes
	-- significantly slow down the query.
	-------------------------------------------------------
	Set @sSQLString = "	insert into #TEMPCASESEXT(CASEID,CLIENTCORRESPONDNAME,CLIENTREFERENCENO,CLIENTMAINCONTACT)
				select CASEID,CLIENTCORRESPONDNAME,CLIENTREFERENCENO,CLIENTMAINCONTACT
				from dbo.fn_FilterUserCases(@pnUserIdentityId,1,null)"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int',
				  @pnUserIdentityId=@pnUserIdentityId

	If @ErrorCode=0
	Begin
		Set @sSQLString = "	insert into #TEMPEVENTS(EVENTNO,EVENTCODE,EVENTDESCRIPTION,NUMCYCLESALLOWED,IMPORTANCELEVEL,CONTROLLINGACTION,DEFINITION)
					select EVENTNO,EVENTCODE,EVENTDESCRIPTION,NUMCYCLESALLOWED,IMPORTANCELEVEL,CONTROLLINGACTION,DEFINITION
					from dbo.fn_FilterUserEvents(@pnUserIdentityId,@psCulture,1,0)"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @psCulture		nvarchar(10)',
					  @pnUserIdentityId=@pnUserIdentityId,
					  @psCulture       =@psCulture
	End
End

-- Call the csw_FilterCases that is responsible for the management of the multiple occurrences of the filter criteria 
-- and the production of an appropriate result set. It calls csw_ConstructCaseWhere to obtain the where clause for each
-- separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the name of the the global temporary
-- table that may hold the filtered list of cases.

If @ErrorCode = 0
Begin
	exec @ErrorCode = dbo.csw_FilterCases	@psReturnClause 	= @sWhereFilter	  	OUTPUT, 			
						@psTempTableName 	= @sCurrentTable	OUTPUT,	
						@pnUserIdentityId	= @pnUserIdentityId,	
						@psCulture		= @psCulture,	
						@pbIsExternalUser	= @bExternalUser,
						@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
					    	@pbCalledFromCentura	= @pbCalledFromCentura	
End

-- Construct the "Select", "From" and the "Order by" clauses 
	
if @ErrorCode=0 
Begin
	exec @ErrorCode=dbo.csw_ConstructCaseSelect	@pnTableCount		= @nTableCount		OUTPUT,
							@pnUserIdentityId	= @pnUserIdentityId,
							@psCulture		= @psCulture,
							@pbExternalUser		= @bExternalUser, 			
							@psTempTableName	= @sCurrentTable,	
							@pnQueryContextKey	= @pnQueryContextKey,
							@ptXMLOutputRequests	= @ptXMLOutputRequests,
							@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
							@pbCalledFromCentura	= @pbCalledFromCentura,
							@psPublishedColumns	= @sPublishedColumns	OUTPUT,
							@psPublishedOrderBy	= @sPublishedOrderBy	OUTPUT
End

-- Check to see if any of the required columns are ones that cannot be incorporated into the main SELECT
-- being constructed.  If not then the additional details will be loaded into a temporary table for later
-- inclusion into the main SELECT
If @ErrorCode=0
Begin
	-- Save the current table name
	Set @sOldTable=@sCurrentTable
	exec @ErrorCode=dbo.csw_GetExtendedCaseDetails	@psWhereFilter		= @sWhereFilter	  	OUTPUT, 			
							@psTempTableName 	= @sCurrentTable	OUTPUT,	
							@pnCaseTotal		= @nCaseTotal		OUTPUT,
							@pbPagingApplied	= @bPagingApplied	OUTPUT,
							@pnCaseChargeCount	= @pnCaseChargeCount	OUTPUT,
							@psEmailAddress		= @psEmailAddress	OUTPUT,
							@pnUserIdentityId	= @pnUserIdentityId,	
							@psCulture		= @psCulture,	
							@pbExternalUser		= @bExternalUser,
							@pnQueryContextKey	= @pnQueryContextKey,
							@ptXMLOutputRequests	= @ptXMLOutputRequests,
							@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
							@pbCalledFromCentura	= @pbCalledFromCentura,
							@pbPrintSQL		= @pbPrintSQL,
							@pnPageStartRow		= @pnPageStartRow,
							@pnPageEndRow		= @pnPageEndRow
End

----------------------------------------------------------
-- If query is for an external user and the constructed
-- SELECT has already joined on the filtered list of user
-- allowed Cases returned by dbo.fn_FilterUserCases, 
-- then comment out any other joins to that same user 
-- define function as they are redundant and are causing
-- poor performance
----------------------------------------------------------
If @ErrorCode=0
and @bExternalUser=1
and exists(select 1 from #TempConstructSQL T where T.SavedString like '%Join dbo.fn_FilterUserCases%')
	Set @sWhereFilter=replace(@sWhereFilter,'join dbo.fn_FilterUserCases','--join dbo.fn_FilterUserCases')

------------------------------------------------
-- Concatenate the components of the SELECT into 
-- separate variables in preparation for them 
-- to be executed.
------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	SELECT @sSelectList = CASE WHEN(@sSelectList is not null) THEN @sSelectList+' ' ELSE '' END  + SavedString
	FROM #TempConstructSQL
	WHERE ComponentType='S'
	order by Position"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@sSelectList		nvarchar(max)	OUTPUT',
					  @sSelectList=@sSelectList		OUTPUT
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		SELECT @sFromClause = CASE WHEN(@sFromClause is not null) THEN @sFromClause+' ' ELSE '' END  + replace(SavedString,@sOldTable,@sCurrentTable)
		FROM #TempConstructSQL
		WHERE ComponentType='F'
		order by Position"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sFromClause		nvarchar(max)	OUTPUT,
						  @sOldTable		nvarchar(60),
						  @sCurrentTable	nvarchar(60)',
						  @sFromClause  =@sFromClause		OUTPUT,
						  @sOldTable    =@sOldTable, 
						  @sCurrentTable=@sCurrentTable
	End
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		SELECT @sWhereClause = CASE WHEN(@sWhereClause is not null) THEN @sWhereClause+' ' ELSE '' END  + SavedString
		FROM #TempConstructSQL
		WHERE ComponentType='W'
		order by Position"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sWhereClause		nvarchar(max)	OUTPUT',
						  @sWhereClause=@sWhereClause		OUTPUT
	End
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		SELECT @sUnionSelect = CASE WHEN(@sUnionSelect is not null) THEN @sUnionSelect+' ' ELSE '' END  + SavedString
		FROM #TempConstructSQL
		WHERE ComponentType='U'
		order by Position"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sUnionSelect		nvarchar(max)	OUTPUT',
						  @sUnionSelect=@sUnionSelect		OUTPUT

		If @sUnionSelect is not null
		Begin
			Set @sUnionFilter =@sWhereFilter
			Set @sUnionGroupBy=@sUnionGroupBy
		End
	End
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		SELECT @sUnionFrom = CASE WHEN(@sUnionFrom is not null) THEN @sUnionFrom+' ' ELSE '' END  + replace(SavedString,@sOldTable,@sCurrentTable)
		FROM #TempConstructSQL
		WHERE ComponentType='V'
		order by Position"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sUnionFrom		nvarchar(max)	OUTPUT,
						  @sOldTable		nvarchar(60),
						  @sCurrentTable	nvarchar(60)',
						  @sUnionFrom   =@sUnionFrom		OUTPUT,
						  @sOldTable    =@sOldTable, 
						  @sCurrentTable=@sCurrentTable
	End
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		SELECT @sUnionWhere = CASE WHEN(@sUnionWhere is not null) THEN @sUnionWhere+' ' ELSE '' END  + SavedString
		FROM #TempConstructSQL
		WHERE ComponentType='X'
		order by Position"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sUnionWhere		nvarchar(max)	OUTPUT',
						  @sUnionWhere=@sUnionWhere		OUTPUT
	End
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		SELECT @sOrder = CASE WHEN(@sOrder is not null) THEN @sOrder+' ' ELSE '' END  + SavedString
		FROM #TempConstructSQL
		WHERE ComponentType='O'
		order by Position"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sOrder		nvarchar(max)	OUTPUT',
						  @sOrder=@sOrder			OUTPUT
	End
End

-- Now get the constructed SQL to return the result set
If @pbCalledFromCentura=1
and @ErrorCode=0
Begin
	If @ErrorCode=0
	Begin
		If @sSelectList like '%Select DISTINCT%'
		Begin
			set @sSelectList=replace(left(@sSelectList,16),'Select DISTINCT', 'Select DISTINCT TOP 100 PERCENT ') + substring(@sSelectList,17,400000)
		End
		Else Begin
			set @sSelectList=replace(left(@sSelectList,7),'Select', 'Select TOP 100 PERCENT ') + substring(@sSelectList,8,400000)
		End

		If substring(@sUnionSelect,15,15)='Select DISTINCT'
		Begin
			set @sUnionSelect=replace(left(@sUnionSelect,30),'Select DISTINCT', 'Select DISTINCT TOP 100 PERCENT ') + substring(@sUnionSelect,31,400000)
		End
		Else Begin
			set @sUnionSelect=replace(left(@sUnionSelect,20),'Select ', 'Select  TOP 100 PERCENT ') + substring(@sUnionSelect,21,400000)
		End
	End
	
	Set @sSelectList = char(10)+
		    'select   ' +@sPublishedColumns+char(10)+ 
		    'from ('+char(10)+
		    'select '+@sPublishedColumns+', ROW_NUMBER() OVER ('+@sOrder+') as RowKey'+char(10)+
		    'FROM ('+char(10)+
		    @sSelectList

	If @sUnionSelect is not null
	Begin
		Set @sUnionGroupBy = isnull(@sUnionGroupBy,'')+char(10)+ 
				     @sOrder+char(10)+
				     ') as CasesSorted'+char(10)+
				     ') as CasesWithRow'
	End
	Else Begin
		Set @sGroupBy =	@sGroupBy+char(10)+ 
				@sOrder+char(10)+
				  ') as CasesSorted'+char(10)+
				  ') as CasesWithRow'
	End

	-- SQA20245  Sort by RowKey instead of the selected sort column from the presentation tab to handle hidden sort column like CLASS.
	If  @sPublishedOrderBy is not null
	and @pnCallingLevel<>2
		Set @sPublishedOrderBy=char(10)+ ' ORDER BY RowKey '
	Else 	
	
		Set @sPublishedOrderBy=char(10)+ @sPublishedOrderBy
		
	
	If @sUnionSelect is not null
		Set @sUnionSelect     =char(10)+@sUnionSelect		--SQA20287
		
	-- Now Select the components of the constructed SELECT to return to the calling program
	If @ErrorCode=0
	Begin
		-- SQA11472 Added ReportCriteria
		Select	@sSelectList		as SelectList, 
			@sFromClause		as FromClause, 
			@sWhereClause		as WhereClause,
			@sWhereFilter		as WhereFilter,
			@sGroupBy		as GroupBy,
			@sPublishedOrderBy	as OrderBy,	-- SQA20215
		        @sUnionSelect		as UnionSelect, 
			@sUnionFrom		as UnionFrom,
			@sUnionWhere		as UnionWhere,
			@sUnionFilter		as UnionFilter, 
			@sUnionGroupBy		as UnionGroupBy, 
			@sReportCriteria	as ReportCriteria	

		Select	@ErrorCode=@@Error,
			@pnRowCount=@@RowCount
	End
End
Else If @ErrorCode=0 
Begin 
	-----------------------------------------------------
	-- Check to seet if IMAGEDATA is going to be included
	-- in the result set. If so then the DISTINCT clause
	-- will not be able to be used.
	-----------------------------------------------------
	If @sSelectList like '%IMAGEDATA%'
		set @bDistinctNotAllowed=1
	Else
		set @bDistinctNotAllowed=0
		
	-- No paging required
	If (@pnPageStartRow is null or
	    @pnPageEndRow is null)
	Begin
		If @sUnionSelect is not null
		Begin
			if left(@sSelectList,15)='Select DISTINCT'
				Set @sSelectList  = replace(left(@sSelectList,15),'Select DISTINCT', 'Select DISTINCT TOP 100 PERCENT ') + substring(@sSelectList,16,400000)
			else
				Set @sSelectList  = replace(left(@sSelectList,6),'Select', 'Select TOP 100 PERCENT ') + substring(@sSelectList,7,400000)

			If substring(@sUnionSelect,15,15)='Select DISTINCT'
				Set @sUnionSelect = replace(left(@sUnionSelect,30),'Select DISTINCT', 'Select DISTINCT TOP 100 PERCENT ') + substring(@sUnionSelect,31,400000)
			else
				Set @sUnionSelect = replace(left(@sUnionSelect,20),'Select ', 'Select  TOP 100 PERCENT ') + substring(@sUnionSelect,21,400000)
		End
		Else Begin
			If @sSelectList like '%Select DISTINCT%'
				Set @sSelectList = replace(@sSelectList,'Select DISTINCT', 'Select DISTINCT TOP 100 PERCENT')
			Else
				Set @sSelectList = replace(@sSelectList,'Select', 'Select TOP 100 PERCENT')
		End

		-- SQA20245  add RowKey in the main select to allow sorting by this column.  This change enable sorting on hidden column like CLASS.
		If @bDistinctNotAllowed=1
			Set @sOpenWrapper = char(10)+
					    'select RowKey,'+@sPublishedColumns+char(10)+
					    'from ('+char(10)+
					    'select '+@sPublishedColumns+', ROW_NUMBER() OVER ('+@sOrder+') as RowKey'+char(10)+
					    'FROM ('+char(10)
		Else
			Set @sOpenWrapper = char(10)+
				    'select DISTINCT RowKey,'+@sPublishedColumns+char(10)+
				    'from ('+char(10)+
				    'select '+@sPublishedColumns+', ROW_NUMBER() OVER ('+@sOrder+') as RowKey'+char(10)+
				    'FROM ('+char(10)

		-- SQA20245  Sort by RowKey instead of the selected sort column from the presentation tab to handle hidden sort column like CLASS.
		If @sPublishedOrderBy is not null
			Set @sPublishedOrderBy=char(10)+ ' ORDER BY RowKey '
				 

		Set @sCloseWrapper = ') as CasesSorted'+char(10)+
				     ') as CasesWithRow'+char(10)+
				     @sPublishedOrderBy
				     
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

		If @pbPrintSQL = 1
		Begin
			-- Print out the executed SQL statement:
			Print	''
			Print	'SET ANSI_NULLS OFF; '+char(10)+
				@sCTE+
				@sOpenWrapper+
				@sSelectList+
				@sFromClause+
				@sWhereClause+
				@sWhereFilter+
				@sGroupBy+
				@sUnionSelect+
				@sUnionFrom+
				@sUnionWhere+
				@sUnionFilter+
				@sUnionGroupBy+
				@sOrder+
				@sCloseWrapper
		End

		/* RFC12092 @pbReturnResultSet should always be equal to 1 when returning search results*/
		If @pbReturnResultSet=1
		Begin
			exec (	'SET ANSI_NULLS OFF; '+
				@sCTE+
				@sOpenWrapper+
				@sSelectList+
				@sFromClause+
				@sWhereClause+
				@sWhereFilter+
				@sGroupBy+
				@sUnionSelect+
				@sUnionFrom+
				@sUnionWhere+
				@sUnionFilter+
				@sUnionGroupBy+
				@sOrder+
				@sCloseWrapper)
		
			Select 	@ErrorCode =@@Error,
				@pnRowCount=@@Rowcount
		End
		
		/* RFC12092 Return count with respect to search results */	
		Set @sCountSelect = ' Select count(*) as SearchSetTotalRows '
		If  @pnRowCount is not null
		and @pnRowCount<@pnPageEndRow 
		and isnull(@pnPageStartRow,1)=1
		and @ErrorCode=0
		Begin
			set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnRowCount	int',
						  @pnRowCount=@pnRowCount
		End
		Else If isnull(@pbGetTotalCaseCount,0)=0
		     and @ErrorCode=0
		Begin
			set @sSQLString='select -1 as SearchSetTotalRows' 
			exec @ErrorCode=sp_executesql @sSQLString
		End	
		Else If @ErrorCode = 0
		Begin
			If @pbPrintSQL = 1
			Begin
				-- Print out the executed SQL statement:
				Print	''
				Print	'SET ANSI_NULLS OFF; '+
					@sCTE+
					@sCountSelect+' from ('+
					@sOpenWrapper+
					@sSelectList+
					@sFromClause+
					@sWhereClause+
					@sWhereFilter+
					@sGroupBy+
					@sUnionSelect+
					@sUnionFrom+
					@sUnionWhere+
					@sUnionFilter+
					@sUnionGroupBy+') as CasesSorted) as CasesWithRow) as C'
			End
			
			exec (	'SET ANSI_NULLS OFF; '+
				@sCTE+
				@sCountSelect+' from ('+
				@sOpenWrapper+
				@sSelectList+
				@sFromClause+
				@sWhereClause+
				@sWhereFilter+
				@sGroupBy+
				@sUnionSelect+
				@sUnionFrom+
				@sUnionWhere+
				@sUnionFilter+
				@sUnionGroupBy+') as CasesSorted) as CasesWithRow) as C')

			Set @ErrorCode =@@Error
		End	

	End
	-- Paging is required
	Else Begin
		If @sUnionSelect is not null
		Begin
			if left(@sSelectList,15)='Select DISTINCT'
				Set @sTopSelectList  = replace(left(@sSelectList,15),'Select DISTINCT', 'Select DISTINCT TOP 100 PERCENT ') + substring(@sSelectList,16,400000)
			else
				Set @sTopSelectList  = replace(left(@sSelectList,6),'Select', 'Select TOP 100 PERCENT ') + substring(@sSelectList,7,400000)

			If substring(@sUnionSelect,15,15)='Select DISTINCT'
				Set @sTopUnionSelect = replace(left(@sUnionSelect,30),'Select DISTINCT', 'Select DISTINCT TOP 100 PERCENT ') + substring(@sUnionSelect,31,400000)
			else
				Set @sTopUnionSelect = replace(left(@sUnionSelect,20),'Select ', 'Select TOP 100 PERCENT ') + substring(@sUnionSelect,21,400000)

		End
		Else Begin
			If @sSelectList like '%Select DISTINCT%'
				If @pbGetTotalCaseCount=1
					Set @sTopSelectList = replace(@sSelectList,'Select DISTINCT', 'Select DISTINCT TOP 100 PERCENT ')
				Else
					Set @sTopSelectList = replace(@sSelectList,'Select DISTINCT', 'Select DISTINCT TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
			Else
				If @pbGetTotalCaseCount=1
					Set @sTopSelectList = replace(@sSelectList,'Select', 'Select TOP 100 PERCENT ')
				Else
					Set @sTopSelectList = replace(@sSelectList,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
		End
		-- RFC70583
		-- When getting the number of rows for the total query we can simplify the query by generating the ROW_NUMBER
		-- using an ORDER BY on just the first column of the Published Columns. This can simplify the work that the
		-- query optimiser has to perform.
		-- There is also no need to return the Published Columns with the ROW_NUMBER so I have commented the @sPublishedColumns out.
		Set @sFirstColumn=SUBSTRING(@sPublishedColumns, 
					    1, 
					    CASE WHEN(CHARINDEX(',',@sPublishedColumns)>1) 
						 THEN CHARINDEX(',',@sPublishedColumns)-1
						 ELSE LEN(@sPublishedColumns)
					    END
					    )
					    
		Set @sCountSelect = char(10)+
				    'select ISNULL(max(RowKey),0) as SearchSetTotalRows '+char(10)+
				    'from ('+char(10)+
				    --'select '+@sPublishedColumns+', ROW_NUMBER() OVER (Order by '+@sFirstColumn+') as RowKey'+char(10)+
				    'select ROW_NUMBER() OVER (Order by '+@sFirstColumn+') as RowKey'+char(10)+
				    'FROM ('+char(10)

		-- SQA20245  add RowKey in the main select to allow sorting by this column.  This change enable sorting on hidden column like CLASS.
		If @bDistinctNotAllowed=1
			Set @sOpenWrapper = char(10)+
					    'select RowKey,'+@sPublishedColumns+char(10)+
					    'from ('+char(10)+
					    'select '+@sPublishedColumns+', ROW_NUMBER() OVER ('+@sOrder+') as RowKey'+char(10)+
					    'FROM ('+char(10)
		Else
			Set @sOpenWrapper = char(10)+
					    'select DISTINCT RowKey,'+@sPublishedColumns+char(10)+
					    'from ('+char(10)+
					    'select '+@sPublishedColumns+', ROW_NUMBER() OVER ('+@sOrder+') as RowKey'+char(10)+
					    'FROM ('+char(10)

		-- SQA20245  Sort by RowKey instead of the selected sort columns from the presentation tab to handle hidden sort column like CLASS.
		If @sPublishedOrderBy is not null
			Set @sPublishedOrderBy=char(10)+ ' ORDER BY RowKey '
			 
			 

		Set @sCloseCount = ') as CasesSorted'+char(10)+
				   ') as CasesWithRow'


		Set @sCloseWrapper = ') as CasesSorted'+char(10)+
				     ') as CasesWithRow'+char(10)+
				     'where RowKey>='+cast(@pnPageStartRow as varchar)+' and RowKey<='+cast(@pnPageEndRow as varchar)+char(10)+
				     @sPublishedOrderBy
				     
		-------------------------------------------------
		-- RFC62317
		-- Add a common table expression (CTE) to get the 
		-- minimum sequence for a CASEID and NAMETYPE
		------------------------------------------------- 	
		If @pbReturnResultSet=1
			Set @sOpenWrapper='with CTE_CaseNameSequence (CASEID, NAMETYPE, SEQUENCE)'+CHAR(10)+
					 'as (	select CASEID, NAMETYPE, MIN(SEQUENCE)'+CHAR(10)+
					 '	from CASENAME with (NOLOCK)'+CHAR(10)+
					 '	where EXPIRYDATE is null or EXPIRYDATE>GETDATE()'+CHAR(10)+
					 '	group by CASEID, NAMETYPE)'+CHAR(10)+
					 @sOpenWrapper
					 
		If @pbGetTotalCaseCount=1
			Set @sCountSelect='with CTE_CaseNameSequence (CASEID, NAMETYPE, SEQUENCE)'+CHAR(10)+
					 'as (	select CASEID, NAMETYPE, MIN(SEQUENCE)'+CHAR(10)+
					 '	from CASENAME with (NOLOCK)'+CHAR(10)+
					 '	where EXPIRYDATE is null or EXPIRYDATE>GETDATE()'+CHAR(10)+
					 '	group by CASEID, NAMETYPE)'+CHAR(10)+
					 @sCountSelect


		If @pbPrintSQL = 1
		Begin
			-- Print out the executed SQL statement:
			If @sUnionSelect is not null
			Begin
				If @pbReturnResultSet=1
				Begin
					Print ''
					Print	'SET ANSI_NULLS OFF; '+char(10)+
						@sOpenWrapper+
						@sTopSelectList+
						@sFromClause+
						@sWhereClause+
						@sWhereFilter+
						@sGroupBy+
						@sTopUnionSelect+
						@sUnionFrom+
						@sUnionWhere+
						@sUnionFilter+
						@sUnionGroupBy+
						@sOrder+
						@sCloseWrapper
				End

				If @pbGetTotalCaseCount=1
				Begin
					Print	''
					Print	'SET ANSI_NULLS OFF; '+char(10)+
						@sCountSelect+
						@sTopSelectList+
						@sFromClause+
						@sWhereClause+
						@sWhereFilter+
						@sGroupBy+
						@sTopUnionSelect+
						@sUnionFrom+
						@sUnionWhere+
						@sUnionFilter+
						@sUnionGroupBy+
						@sOrder+
						@sCloseCount
				End
			End
			Else Begin
				If @pbReturnResultSet=1
				Begin
					Print	''
					Print	'SET ANSI_NULLS OFF; '+char(10)+
						@sOpenWrapper+
						@sTopSelectList+
						@sFromClause+
						@sWhereClause+
						@sWhereFilter+
						@sGroupBy+
						@sTopUnionSelect+
						@sUnionFrom+
						@sUnionWhere+
						@sUnionFilter+
						@sUnionGroupBy+
						@sOrder+
						@sCloseWrapper
				End
	
				If @nCaseTotal is null
				and @pbGetTotalCaseCount=1
				Begin
					Print	''
					Print	'SET ANSI_NULLS OFF '+char(10)+
						@sCountSelect+
						@sTopSelectList+
						@sFromClause+
						@sWhereClause+
						@sWhereFilter+
						@sGroupBy+
						@sTopUnionSelect+
						@sUnionFrom+
						@sUnionWhere+
						@sUnionFilter+
						@sUnionGroupBy+
						@sOrder+
						@sCloseCount
				End
			End			
		End

		If @sUnionSelect is not null
		Begin
			If @pbReturnResultSet=1
			Begin
				exec (	'SET ANSI_NULLS OFF; '+
					@sOpenWrapper+
					@sTopSelectList+
					@sFromClause+
					@sWhereClause+
					@sWhereFilter+
					@sGroupBy+
					@sTopUnionSelect+
					@sUnionFrom+
					@sUnionWhere+
					@sUnionFilter+
					@sUnionGroupBy+
					@sOrder+
					@sCloseWrapper )
	
				Select 	@ErrorCode =@@Error,
					@pnRowCount=@@Rowcount
			End

/**** Commented out because need know total row count for UNION and not just number of Cases.
			If @nCaseTotal is not null
			and @ErrorCode=0
			Begin
				Set @sSQLString='select @nCaseTotal as SearchSetTotalRows'

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCaseTotal	int',
							  @nCaseTotal=@nCaseTotal
			End
			Else 
*/
			If  @pnRowCount<@pnPageEndRow 
			and isnull(@pnPageStartRow,1)=1
			and @ErrorCode=0
			Begin
				set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnRowCount	int',
							  @pnRowCount=@pnRowCount
			End
			Else If isnull(@pbGetTotalCaseCount,0)=0
			     and @ErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @ErrorCode=sp_executesql @sSQLString
			End	
			Else If @ErrorCode = 0
			Begin	
				exec (	'SET ANSI_NULLS OFF; '+
					@sCountSelect+ 
					@sTopSelectList+
					@sFromClause+
					@sWhereClause+
					@sWhereFilter+
					@sGroupBy+
					@sTopUnionSelect+
					@sUnionFrom+
					@sUnionWhere+
					@sUnionFilter+
					@sUnionGroupBy+
					@sOrder+
					@sCloseCount )

				Set @ErrorCode =@@Error
			End
		End
		Else Begin
			If @pbReturnResultSet=1
			Begin
				exec (	'SET ANSI_NULLS OFF; '+
					@sOpenWrapper+
					@sTopSelectList+
					@sFromClause+
					@sWhereClause+
					@sWhereFilter+
					@sGroupBy+
					@sUnionSelect+
					@sUnionFrom+
					@sUnionWhere+
					@sUnionFilter+
					@sUnionGroupBy+
					@sOrder+
					@sCloseWrapper)
	
				Select 	@ErrorCode =@@Error,
					@pnRowCount=@@Rowcount
			End
		
			If  @pnRowCount<@pnPageEndRow 
			     and isnull(@pnPageStartRow,1)=1
			     and @ErrorCode=0
			Begin
				set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnRowCount	int',
							  @pnRowCount=@pnRowCount
			End
			Else If isnull(@pbGetTotalCaseCount,0)=0
			     and @ErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @ErrorCode=sp_executesql @sSQLString
			End
			Else If @ErrorCode = 0
			Begin

				exec (	'SET ANSI_NULLS OFF; '+
					@sCountSelect+
					@sTopSelectList+
					@sFromClause+
					@sWhereClause+
					@sWhereFilter+
					@sGroupBy+
					@sUnionSelect+
					@sUnionFrom+
					@sUnionWhere+
					@sUnionFilter+
					@sUnionGroupBy+
					@sOrder+
					@sCloseCount)

				Set @ErrorCode =@@Error
			End
		End					
	End
/*	
	-- Now drop the temporary table holding the results only if the stored procedure
	-- was not called from Centura
	if exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
	and @ErrorCode=0
	Begin
		Set @sSQLString = "drop table "+@sCurrentTable
	
		exec @ErrorCode=sp_executesql @sSQLString
	End
*/

End

if @bExternalUser=1
and @ErrorCode=0
Begin
	Drop table #TEMPCASESEXT

	Drop table #TEMPEVENTS
End

RETURN @ErrorCode
go

grant execute on dbo.csw_ListCase  to public
go

