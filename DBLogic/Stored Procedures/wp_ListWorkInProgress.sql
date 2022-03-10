-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ListWorkInProgress
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[wp_ListWorkInProgress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.wp_ListWorkInProgress.'
	drop procedure dbo.wp_ListWorkInProgress
End
print '**** Creating procedure dbo.wp_ListWorkInProgress...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.wp_ListWorkInProgress
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 200,	-- The key for the context of the query (default output requests).	
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbPrintSQL			bit		= null,	-- When set to 1, the executed SQL statement is printed out. 
	@pbCalledFromCentura		bit		= 0,
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null
)	
AS
-- PROCEDURE :	wp_ListWorkInProgress
-- VERSION :	31
-- DESCRIPTION:	Returns the requested information, for Work In Progress that matches the filter criteria provided.  
--		Caters for aggregate columns, group by and having clauses.
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2005  TM	RFC1896	1	Skeleton implementation
-- 11 Apr 2005	TM	RFC1896	2	Implement new new QueryDataItem.IsAggregate column.
-- 13 Apr 2005	TM	RFC1896	3	Implement the rest of the columns. Replace the call to the wp_ConstructWipWhere
--					with wp_FilterWip. 
-- 18 Apr 2005	TM	RFC1896	4	If no aggregate column has been selected, append a COUNT(*) as Count column.
-- 22 Apr 2005	TM	RFC1896	5	Set ErrorCode and RowCount.
-- 15 May 2005	JEK	RFC2508	6	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	7	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 20 Oct 2005	TM	RFC3024	8	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 10 Mar 2006	TM	RFC3465	9	Add two new parameters @pnPageStartRow, @pnPageEndRow and implement
--					SQL Server Paging.
-- 30 Mar 2006	JEK	RFC3465	10	Paging was implemented using a derived table which cannot be used with a group by clause.
--					Do not perform paging at all if there is a group by clause required, and thus do not need to
--					extract count from a derived table.
-- 13 Dec 2006	MF	14002	11	Paging should not do a separate count() on the database if the rows returned
--					are less than the maximum allowed for.
-- 15 Dec 2008	MF	17136	12	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 12 Jul 2010	KR	9080	13	Added Debtor Key
-- 13 Jul 2011	DL	R10830	14	Specify collation default in temp table.
-- 06 Feb 2013	vql	R12904	15	Return Debtor Name and Name Code.
-- 13 Sep 2013	MS	DR143	16	Consider multi debtor WIP criteria while returning debtor
-- 24 Sep 2013  MS      DR1246  17      Return unallocated debtor as null if there are multiple debtors
-- 10 Dec 2013	AT	RC28058	18	Return Allocated Debtor.
-- 17 Apr 2015	MF	45848	19	When returning Case related columns the WHERE clause for the WIP was being embedded a second time
--					within the derived table returning Case details. This is not required as all we need to know is
--					the CaseId from the WORKINGPROGRESS that has already been filtered.
-- 23 Apr 2015	MS	R46603	20	Set size of variables for case filter to nvarchar(max)
-- 02 Nov 2015	vql	R53910	21	Adjust formatted names logic (DR-15543).
-- 14 Jul 2016	MF	62317	21	Performance improvement using a CTE to get the minimum SEQUENCE by Caseid and NameType.
-- 16 Jul 2016	MF	63576	23	Allow the Draft Invoice No to be returned.
-- 29 May 2017	MF	71492	24	Allow the WIP amount in the currency it is likely to be billed in.
-- 24 Aug 2017	MF	71721	25	Ethical Walls rules applied for logged on user.
-- 19 Sep 2017	MF	72435	26	Add Row Level Security restrictions for cases.
-- 02 Apr 2018	MS	72435   27      Add Row Level Security restrictions for names.
-- 19 Oct 2018	MF	DR-45039 28	Staff Responsible was incorrectly using NameType ='I' when it should be 'EMP'.
-- 16 Nov 2018	MF	DR-45648 29	Staff Responsible for debtor only WIP also needs to be catered for.
-- 28 Jun 2019	vql	DR-48772 30	Ability to add a case name to WIP Overview.
-- 01 Apr 2020	AK	DR-56385 31	Added logic to enable paging.

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	CaseKey
--	BilledCurrencyCode
--	DraftInvoiceNo
--	EntityCode
--	EntityKey
--	EntityName
-- 	ResponsibleName
--	ResponsibleNameCode
-- 	ResponsibleNameKey
--	SumBillingBalance
--	SumLocalBalance
--	SumActiveLocalBalance
--	SumActiveBillingBalance
--	LocalCurrencyCode
--	NULL
--	WipName
--	WipNameCode
--	WipNameKey
--	DebtorKey
--	DebtorName
--	DebtorNameCode
--  	AllocatedDebtorKey


-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	SCUR
--	CC
--	CNE
-- 	CNI
-- 	CND
--	IP
--	NE
--	NI
--	NW
--	RES

-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare	@nRowCount			int
Declare @sAlertXML	 		nvarchar(400)

-- The SQL used by the csw_ListCase stored procedure
Declare @sSql				nvarchar(max)
Declare @sSQLString			nvarchar(max)
Declare	@sSelectList1			nvarchar(max)	-- the SQL list of columns to return
Declare	@sSelectList2			nvarchar(max)
Declare	@sSelectList3			nvarchar(max)
Declare	@sSelectList4			nvarchar(max)
Declare	@sSelectList5			nvarchar(max)	-- the SQL list of columns to return
Declare	@sSelectList6			nvarchar(max)
Declare	@sSelectList7			nvarchar(max)
Declare	@sSelectList8			nvarchar(max)
Declare	@sFrom1				nvarchar(max)	-- the SQL to list tables and joins
Declare	@sFrom2				nvarchar(max)
Declare	@sFrom3				nvarchar(max)
Declare	@sFrom4				nvarchar(max)
Declare	@sFrom5				nvarchar(max)	-- the SQL to list tables and joins
Declare	@sFrom6				nvarchar(max)
Declare	@sFrom7				nvarchar(max)
Declare	@sFrom8				nvarchar(max)
Declare	@sFrom9				nvarchar(max)	-- the SQL to list tables and joins
Declare	@sFrom10			nvarchar(max)
Declare	@sFrom11			nvarchar(max)
Declare	@sFrom12			nvarchar(max)
Declare @sWhereCase			nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseSelect)
Declare @sWhereFilter			nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_FilterCases)
Declare @sCTE				nvarchar(max)

-- The SQL used by the wp_ListWorkInProgress stored procedure
Declare @nCount				int	 	-- Current table row being processed.
Declare @sWIPSelect			nvarchar(max)
Declare @sWIPFrom			nvarchar(max)
Declare @sWIPCaseWhere			nvarchar(max)	-- Used for the Case derived table.
Declare @sWIPNameWhere			nvarchar(max)	-- Used to ensure Names are not blocked by ethical wall
Declare @sWorkInProgressWhere		nvarchar(max)	-- Used for the outer Select statment.
Declare @sWIPWhere			nvarchar(max)
Declare @sWIPGroupBy			nvarchar(max)
Declare @sWIPHaving			nvarchar(max)
Declare @sWIPOrderBy			nvarchar(max)
Declare @sAlias				nvarchar(max)
Declare	@sOpenWrapper			nvarchar(1000)
Declare @sCloseWrapper			nvarchar(100)

Declare @sCountSelect			nvarchar(max)	-- A part of the Select statement required to calculate the @pnSearchSetTotalRows - Potential number of rows in the search result set
Declare	@sTopSelectList1		nvarchar(max)	-- the SQL list of columns to return modified for paging
Declare @bIsSplitMultiDebtor		bit
Declare @sDebtorWhere                   nvarchar(max)

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests 	table 
			 	(	ROWNUMBER	int 		not null,
		    			ID		nvarchar(100)	collate database_default not null,
		    			SORTORDER	tinyint		null,
		    			SORTDIRECTION	nvarchar(1)	collate database_default null,
					PUBLISHNAME	nvarchar(100)	collate database_default null,
					QUALIFIER	nvarchar(100)	collate database_default null,				
					DOCITEMKEY	int		null,
					PROCEDURENAME	nvarchar(50)	collate database_default null,
					ISAGGREGATE	bit		null,
					DATAFORMATID    int 		null
			 	)

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
Declare @tbOrderBy 	table (
					Position	tinyint		not null,
					Direction	nvarchar(5)	collate database_default not null,
					ColumnName	nvarchar(1000)	collate database_default not null,
					PublishName	nvarchar(50)	collate database_default null,
					ColumnNumber	tinyint		not null
				)
-- SQA9664
-- Create a temporary table to be used in the construction of the SELECT.
Create table #TempConstructSQL 	       
				(
					Position	smallint	identity(1,1),
					ComponentType	char(1)		collate database_default,
					SavedString	nvarchar(4000) 	collate database_default 
				 )
Declare @sCurrentCaseTable 		nvarchar(60)	
Declare @sCurrentWipTable		nvarchar(60)

Declare @nOutRequestsRowCount		int
Declare @sCaseXMLOutputRequests		nvarchar(4000)	-- The XML Output Requests prepared for the case search procedure.

Declare @nTableCount			tinyint
Declare @nNumberOfBrakets		tinyint
Declare @nColumnNo			tinyint
Declare @sColumn			nvarchar(100)
Declare @sPublishName			nvarchar(50)
Declare @sPublishNameForXML		nvarchar(50)	-- Publish name with such characters as '.' and ' ' removed.
Declare @sQualifier			nvarchar(50)
Declare @sProcedureName			nvarchar(50)
Declare @sCorrelationSuffix		nvarchar(50)
Declare @nOrderPosition			tinyint
Declare @sOrderDirection		nvarchar(5)
Declare @bIsAggregate			bit
Declare @nDataFormatID			int
Declare @sTableColumn			nvarchar(1000)
Declare	@bExternalUser			bit
Declare	@bRowLevelSecurity		bit
Declare	@bCaseOffice			bit
Declare	@bBlockCaseAccess		bit
Declare @bNeedGroupBy			bit		-- Set to 1 when the 'group by' clause is required
Declare	@bRowLevelNameSecurity		bit

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

Set	@String 			= 'S'
Set	@Date   			= 'DT'
Set	@Numeric			= 'N'
Set	@Text   			= 'T'
Set	@CommaString			= 'CS'

Set 	@nErrorCode			= 0
Set	@nRowCount			= 0
Set	@bRowLevelSecurity		= 0
Set	@bBlockCaseAccess		= 0
Set     @nCount				= 1
Set	@nNumberOfBrakets		= 0
Set     @bNeedGroupBy			= 0
Set     @sCaseXMLOutputRequests 	= '<?xml version="1.0"?>'
				  	+char(10)+'	<OutputRequests>'
					
-- Initialise the 'From' and the 'Where' clauses
Set     @sWIPFrom			= 'from WORKINPROGRESS W'

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString='
	Select	@bExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser=@bExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId

	Set @nRowCount =@@ROWCOUNT
End

If  @nErrorCode=0
and @nRowCount>0
Begin
	---------------------------------------
	-- Check to see if the user is impacted
	-- by Row Level Security
	---------------------------------------
	Select @bRowLevelSecurity = 1
	from IDENTITYROWACCESS U 
	join ROWACCESSDETAIL R on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @pnUserIdentityId

	Set @nErrorCode=@@ERROR
End

If  @nErrorCode=0
and @nRowCount>0
Begin
        ---------------------------------------
	-- Check to see if the user is impacted
	-- by Row Level Name Security
	---------------------------------------
	Select @bRowLevelNameSecurity = 1
	from IDENTITYROWACCESS U 
	join ROWACCESSDETAIL R on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'N'
	and U.IDENTITYID = @pnUserIdentityId

	Set @nErrorCode=@@ERROR
End

If @nErrorCode=0
Begin
	If @bRowLevelSecurity=1
	Begin
		---------------------------------------------
		-- If Row Level Security is in use for user,
		-- determine how/if Office is stored against 
		-- Cases.  It is possible to store the office
		-- directly in the CASES table or if a Case 
		-- is to have multiple offices then it is
		-- stored in TABLEATTRIBUTES.
		---------------------------------------------
		Select  @bCaseOffice = COLBOOLEAN
		from SITECONTROL
		where CONTROLID = 'Row Security Uses Case Office'

		Set @nErrorCode=@@ERROR
				
	
		---------------------------------------------
		-- Check to see if there are any Offices 
		-- held as TABLEATRRIBUTES of the Case. If
		-- not then treat as if Office is stored 
		-- directly in the CASES table.
		---------------------------------------------
		If(@bCaseOffice=0 or @bCaseOffice is null)
		and not exists (select 1 from TABLEATTRIBUTES where PARENTTABLE='CASES' and TABLETYPE=44)
			Set @bCaseOffice=1
	End
	Else Begin
		---------------------------------------------
		-- If Row Level Security is NOT in use for
		-- the current user, then check if any other 
		-- users are configured.  If they are, then 
		-- internal users that have no configuration 
		-- will be blocked from ALL cases.
		---------------------------------------------
		If @nRowCount=0
		Begin
			-------------------------------
			-- Also block result if the 
			-- @pnUserIdentityID is unknown
			-------------------------------
			Set @bBlockCaseAccess=1
		End
		ELSE
		If @bExternalUser=0
		Begin
			Select @bBlockCaseAccess = 1
			from IDENTITYROWACCESS U
			join USERIDENTITY UI	on (U.IDENTITYID = UI.IDENTITYID) 
			join ROWACCESSDETAIL R	on (R.ACCESSNAME = U.ACCESSNAME) 
			where R.RECORDTYPE = 'C' 
			and isnull(UI.ISEXTERNALUSER,0) = 0

			Set @nErrorCode=@@ERROR
		End
	End
End
--------------------------------			
-- Initialise the 'From' clause
-- with consideration for both:
--     Ethical Walls; and
--     Row Level Security
--------------------------------
Set @sWIPFrom = 'from WORKINPROGRESS W'+char(10)+
		'left join dbo.fn_CasesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') CS on (CS.CASEID=W.CASEID)' + 
		
		CASE WHEN(@bRowLevelSecurity = 1 AND @bCaseOffice = 1)
			THEN char(10)+'left join dbo.fn_CasesRowSecurity('+cast(@pnUserIdentityId as nvarchar)+') RS on (RS.CASEID=W.CASEID AND RS.READALLOWED=1)'
		     WHEN(@bRowLevelSecurity = 1)
			THEN char(10)+'left join dbo.fn_CasesRowSecurityMultiOffice('+cast(@pnUserIdentityId as nvarchar)+') RS on (RS.CASEID=W.CASEID AND RS.READALLOWED=1)'
			ELSE ''
		END +
                CASE WHEN @bRowLevelNameSecurity = 1
                        THEN char(10)+'left join dbo.fn_NamesRowSecurity('+cast(@pnUserIdentityId as nvarchar)+') RNS on (RNS.NAMENO=W.ACCTCLIENTNO AND RNS.READALLOWED=1)'
                ELSE ''
		END

If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select @bIsSplitMultiDebtor = COLBOOLEAN
	from SITECONTROL 	
	where CONTROLID = 'WIP Split Multi Debtor'"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsSplitMultiDebtor	bit	OUTPUT',
				  @bIsSplitMultiDebtor	= @bIsSplitMultiDebtor	OUTPUT
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****    AND GROUP BY CLAUSE		    ****/
/****                                       ****/
/***********************************************/

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE, DATAFORMATID)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE, DATAFORMATID
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
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, null)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE, DATAFORMATID)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE, DATAFORMATID 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)	
End

-- Additional columns may be required by the outer SQL. These are added if not already present.
If   @nErrorCode=0
and (PATINDEX ('%<csw_ListCase>%', @ptXMLFilterCriteria)>0
 or  PATINDEX ('%csw_ListCase%', @ptXMLOutputRequests)>0)
Begin 
	-- Make sure that the CaseKey is always returned by the csw_ListCase
	-- to be able to join on it.
	If not exists ( Select 1 
			from @tblOutputRequests
			where ID = 'CaseKey'
			and   PROCEDURENAME = 'csw_ListCase')
	Begin
		insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME)
		select isnull(max(ROWNUMBER),0)+1, 'CaseKey', null, null, null, null, null, 'csw_ListCase'
		from @tblOutputRequests
	End
End

-- Is 'group by' clause required?  
If  @nErrorCode=0
and (PATINDEX ('%<AggregateFilterCriteria>%', @ptXMLFilterCriteria)>0
 or  exists(Select 1 from @tblOutputRequests where ISAGGREGATE = 1))
Begin
	Set @bNeedGroupBy = 1
End

-- Is COUNT(*) coumn required to avoide an SQL error?
If  @nErrorCode=0
and @bNeedGroupBy = 1
and not exists(Select 1 from @tblOutputRequests where ISAGGREGATE = 1)
Begin
	insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE)
	select isnull(max(ROWNUMBER),0)+1, 'Count', null, null, 'Count', null, null, 'wp_ListWorkInProgress', 1
	from @tblOutputRequests
End

-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
-- while constructing the "Select" list   
If @nErrorCode=0
Begin
	Set @nOutRequestsRowCount = (Select count(*) from @tblOutputRequests)

	-- Reset the @nCount.
	Set @nCount = 1
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
		@sQualifier		= QUALIFIER,
		@sProcedureName		= PROCEDURENAME,
		@bIsAggregate		= ISAGGREGATE,
		@nDataFormatID		= DATAFORMATID
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	-- If a Qualifier exists then generate a value from it that can be used
	-- to create a unique Correlation name for the table

	If  @nErrorCode=0
	and @sQualifier is null
	Begin
		Set @sCorrelationSuffix=NULL
	End
	Else Begin			
		Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
	End

	If @nErrorCode=0	 
	Begin
		If @sProcedureName = 'wp_ListWorkInProgress'
		Begin
			If @sColumn='NULL'		
			Begin
				Set @sTableColumn='NULL'
			End

			If @sColumn='Count'		
			Begin
				Set @sTableColumn='COUNT(*)'
			End

			
			Else If @sColumn in (	'ResponsibleNameKey',
						'ResponsibleName',
						'ResponsibleNameCode')
			Begin
				If charindex('left join CASENAME CNE',@sWIPFrom)=0	
				Begin
					Set @sWIPFrom=@sWIPFrom +char(10)+"left join CASENAME CNE	on  (CNE.CASEID = W.CASEID"
								+char(10)+"				and  CNE.NAMETYPE = 'EMP'"
								+char(10)+"				and  CNE.SEQUENCE=(select SEQUENCE from CTE_CaseNameSequence where CASEID=CNE.CASEID and NAMETYPE=CNE.NAMETYPE))"
				End
				If charindex('left join ASSOCIATEDNAME ASN',@sWIPFrom)=0	
				Begin
					Set @sWIPFrom=@sWIPFrom +char(10)+"left join ASSOCIATEDNAME ASN on  (ASN.NAMENO = W.ACCTCLIENTNO"
								+char(10)+"				and  ASN.RELATIONSHIP='RES'"
								+char(10)+"				and  W.CASEID is null"
								+char(10)+"				and  ASN.SEQUENCE=(select SEQUENCE from CTE_RespNameSequence where NAMENO=W.ACCTCLIENTNO))"
				End						

				If @sColumn='ResponsibleNameKey'
				Begin
					Set @sTableColumn='CASE WHEN W.CASEID is not null THEN CNE.NAMENO ELSE NULL END' 									
				End
				Else If @sColumn='ResponsibleName'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(RES.NAMENO, null)' 						
					
					If charindex('left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') RES',@sWIPFrom)=0	
					Begin
						Set @sWIPFrom=@sWIPFrom +char(10)+'left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') RES on (RES.NAMENO = isnull(CNE.NAMENO,ASN.RELATEDNAME))'
					End	
					
				End
				Else If @sColumn='ResponsibleNameCode'
				Begin
					Set @sTableColumn='RES.NAMECODE' 						
					
					If charindex('left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') RES',@sWIPFrom)=0
					Begin
						Set @sWIPFrom=@sWIPFrom +char(10)+'left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') RES on (RES.NAMENO = isnull(CNE.NAMENO,ASN.RELATEDNAME))'
					End	
				End		
			End	

			Else If @sColumn='DisplayName'
			and @sQualifier is not NULL -- A parameter MUST exist 
			Begin
				Set @sAlias = 'DCN'+cast(@nCount as nvarchar(max))
				If charindex('left join CASENAME '+@sAlias, @sWIPFrom)=0	
				Begin
					Set @sWIPFrom=@sWIPFrom +char(10)+"left join CASENAME "+@sAlias+"	on  ("+@sAlias+".CASEID = W.CASEID"
								+char(10)+"				and  "+@sAlias+".NAMETYPE = '"+@sQualifier+"'"
								+char(10)+"				and  "+@sAlias+".SEQUENCE=(select SEQUENCE from CTE_CaseNameSequence where CASEID="+@sAlias+".CASEID and NAMETYPE="+@sAlias+".NAMETYPE))"
				End

				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sAlias+'.NAMENO, null)'
			End

			
			Else If @sColumn='DraftInvoiceNo'
			Begin			
				Set @sTableColumn='O.OPENITEMNO'						
					
				If charindex('left join BILLEDITEM BI',@sWIPFrom)=0	
				Begin
					Set @sWIPFrom=@sWIPFrom +char(10)+'left join BILLEDITEM BI on (BI.WIPENTITYNO = W.ENTITYNO'
								+char(10)+'                        and BI.WIPTRANSNO  = W.TRANSNO'
								+char(10)+'                        and BI.WIPSEQNO    = W.WIPSEQNO)'
								+char(10)+'left join OPENITEM O    on (O.ITEMENTITYNO = BI.ENTITYNO'
								+char(10)+'                        and O.ITEMTRANSNO  = BI.TRANSNO)'
				End
			End	
	
			Else If @sColumn='CaseKey'
			Begin
				Set @sTableColumn='W.CASEID'
			End

			Else If @sColumn='SumLocalBalance'
			Begin
				Set @sTableColumn='SUM(ISNULL(W.BALANCE,0))'														
			End

			Else If @sColumn='SumActiveLocalBalance'
			Begin
				Set @sTableColumn='SUM(CASE WHEN W.STATUS = 1 THEN ISNULL(W.BALANCE,0) ELSE 0 END)'														
			End

			Else If @sColumn='LocalCurrencyCode'
			Begin
				Set @sTableColumn='SCUR.COLCHARACTER'

				If charindex('Left Join SITECONTROL SCUR',@sWIPFrom)=0	
				Begin
					Set @sWIPFrom=@sWIPFrom +char(10)+'Left Join SITECONTROL SCUR 	on (SCUR.CONTROLID = ''CURRENCY'')'
				End				
			End
			Else If @sColumn in (	'DebtorKey',
						'DebtorName',
						'DebtorNameCode',
						'AllocatedDebtorKey',
						'SumBillingBalance',
						'SumActiveBillingBalance',
						'BilledCurrencyCode')
			Begin	
				If charindex('left join CASENAME CND',@sWIPFrom)=0	
				Begin
					Set @sWIPFrom=@sWIPFrom +char(10)+"left join CASENAME CND	on  (CND.CASEID = W.CASEID"
								+char(10)+"				and  CND.NAMETYPE='D'"
								+char(10)+"				and  CND.SEQUENCE=(select SEQUENCE from CTE_CaseNameSequence where CASEID=CND.CASEID and NAMETYPE=CND.NAMETYPE))"
				End
									
				If charindex('left join CASENAME CNSD',@sWIPFrom)=0	
				Begin							            
					Set @sWIPFrom=@sWIPFrom +char(10)+"left join CASENAME CNSD	on  (CNSD.CASEID = W.CASEID"
								+char(10)+"				and CNSD.NAMETYPE='D'"
								+char(10)+"				and (CNSD.EXPIRYDATE is null or CNSD.EXPIRYDATE >getdate())"
								+char(10)+"				and  1=(select count(SEQUENCE)
												              from CASENAME CNSD1
												              where CNSD1.CASEID=CNSD.CASEID
												              and CNSD1.NAMETYPE=CNSD.NAMETYPE
												              and (CNSD1.EXPIRYDATE is null or CNSD1.EXPIRYDATE >getdate()) )) "				
				End
				
				Select @sDebtorWhere = CASE WHEN @bIsSplitMultiDebtor = 1 
				                          THEN 'COALESCE(W.ACCTCLIENTNO, CNSD.NAMENO)'
				                          ELSE 'COALESCE(W.ACCTCLIENTNO, CND.NAMENO)'
				                       END

				If @sColumn in ('DebtorName',
						'DebtorNameCode',
						'SumBillingBalance',
						'SumActiveBillingBalance',
						'BilledCurrencyCode')
				Begin
					---------------------------------------
					-- We need to get the Debtor associated
					-- with the WIP.
					---------------------------------------			
					
					If charindex('left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') ND',@sWIPFrom)=0
					Begin
						Set @sWIPFrom=@sWIPFrom +char(10)+'left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') ND on (ND.NAMENO = '+@sDebtorWhere+')'

						Set @sWIPNameWhere=isnull(@sWIPNameWhere,'')+char(10)+'and (ND.NAMENO is not null OR '+@sDebtorWhere+' is null)'
					End	
				End

				If @sColumn in ('SumBillingBalance',
						'SumActiveBillingBalance',
						'BilledCurrencyCode')
				Begin
					---------------------------------------
					-- We need to get the home currency.
					---------------------------------------
					If charindex('Left Join SITECONTROL SCUR',@sWIPFrom)=0	
					Begin
						Set @sWIPFrom=@sWIPFrom +char(10)+'Left Join SITECONTROL SCUR 	on (SCUR.CONTROLID = ''CURRENCY'')'
					End
					---------------------------------------
					-- We need to get the currency of the
					-- debtor.
					---------------------------------------
					If charindex('left join IPNAME',@sWIPFrom)=0	
					Begin
						Set @sWIPFrom=@sWIPFrom +char(10)+'left join IPNAME   IP on (IP.NAMENO   = ND.NAMENO)'
							                +char(10)+'left join CURRENCY CC on (CC.CURRENCY = isnull(IP.CURRENCY,SCUR.COLCHARACTER))'
					End
				End
				
				If @sColumn='DebtorKey'
				Begin
					Set @sTableColumn= @sDebtorWhere							
				End
				Else If @sColumn='AllocatedDebtorKey'
				Begin
					Set @sTableColumn='W.ACCTCLIENTNO'
				End
				Else If @sColumn='DebtorName'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(ND.NAMENO, null)'
				End
				Else If @sColumn='DebtorNameCode'
				Begin
					Set @sTableColumn='ND.NAMECODE' 
				End

				Else If @sColumn='SumBillingBalance'
				Begin
					Set @sTableColumn='SUM(CASE WHEN(IP.CURRENCY =W.FOREIGNCURRENCY) THEN isnull(W.FOREIGNBALANCE,0)'+char(10)+
							  '         WHEN(IP.CURRENCY =SCUR.COLCHARACTER) THEN isnull(W.BALANCE,0)'+char(10)+
							  '         WHEN(CC.SELLRATE<>0)                 THEN isnull(W.BALANCE,0) / CC.SELLRATE'+char(10)+
							  '                                              ELSE isnull(W.BALANCE,0)'+char(10)+
							  '    END)'													 														
				End

				Else If @sColumn='SumActiveBillingBalance'
				Begin
					Set @sTableColumn='SUM(CASE WHEN(W.STATUS<>1) THEN 0'+char(10)+
					                  '         WHEN(IP.CURRENCY =W.FOREIGNCURRENCY) THEN isnull(W.FOREIGNBALANCE,0)'+char(10)+
							  '         WHEN(IP.CURRENCY =SCUR.COLCHARACTER) THEN isnull(W.BALANCE,0)'+char(10)+
							  '         WHEN(CC.SELLRATE<>0)                 THEN isnull(W.BALANCE,0) / CC.SELLRATE'+char(10)+
							  '                                              ELSE isnull(W.BALANCE,0)'+char(10)+
							  '    END)'														
				End

				Else If @sColumn='BilledCurrencyCode'
				Begin
					Set @sTableColumn='CC.CURRENCY'			
				End
			End
			Else If @sColumn='EntityKey'
			Begin
				Set @sTableColumn='W.ENTITYNO' 									
			End

			Else If @sColumn in (	'EntityName',
						'EntityCode')
			Begin
				If @sColumn='EntityName'
				Begin
					Set @sTableColumn='dbo.fn_FormatName (NE.NAME, NE.FIRSTNAME, NE.TITLE, null)' 	
					
					If charindex('left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') NE',@sWIPFrom)=0
					Begin
						Set @sWIPFrom=@sWIPFrom +char(10)+'left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') NE on (NE.NAMENO = W.ENTITYNO)'

						Set @sWIPNameWhere=isnull(@sWIPNameWhere,'')+char(10)+'and (NE.NAMENO is not null OR W.ENTITYNO is null)'
					End
					
				End
				Else If @sColumn='EntityCode'
				Begin
					Set @sTableColumn='NE.NAMECODE' 						
					
					If charindex('left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') NE',@sWIPFrom)=0
					Begin
						Set @sWIPFrom=@sWIPFrom +char(10)+'left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') NE on (NE.NAMENO = W.ENTITYNO)'

						Set @sWIPNameWhere=isnull(@sWIPNameWhere,'')+char(10)+'and (NE.NAMENO is not null OR W.ENTITYNO is null)'
					End
				End				
			End

			Else If @sColumn='WipNameKey'
			Begin
				Set @sTableColumn='W.ACCTCLIENTNO' 									
			End

			Else If @sColumn in (	'WipName',
						'WipNameCode')
			Begin
				If @sColumn='WipName'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NW.NAMENO, null)'							
					
					If charindex('left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') NW',@sWIPFrom)=0
					Begin
						Set @sWIPFrom=@sWIPFrom +char(10)+'left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') NW on (NW.NAMENO = W.ACCTCLIENTNO)'

						Set @sWIPNameWhere=isnull(@sWIPNameWhere,'')+char(10)+'and (NW.NAMENO is not null OR W.ACCTCLIENTNO is null)'
					End
					
				End
				Else If @sColumn='WipNameCode'
				Begin
					Set @sTableColumn='NW.NAMECODE' 								
					
					If charindex('left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') NW',@sWIPFrom)=0
					Begin
						Set @sWIPFrom=@sWIPFrom +char(10)+'left join dbo.fn_NamesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') NW on (NW.NAMENO = W.ACCTCLIENTNO)'

						Set @sWIPNameWhere=isnull(@sWIPNameWhere,'')+char(10)+'and (NW.NAMENO is not null OR W.ACCTCLIENTNO is null)'
					End	
				End				
			End

			If datalength(@sPublishName)>0
			Begin
				-- Cast the text type columns as nvarchar(4000) if they are used in the 
				-- 'group by' clause:
				If  @nDataFormatID = 9107 
				and @bNeedGroupBy = 1
				Begin
					Set @sTableColumn = 'CAST('+@sTableColumn+' as nvarchar(4000))'
				End

				Set @sWIPSelect=@sWIPSelect+nullif(',', ',' + @sWIPSelect)+@sTableColumn+' as ['+@sPublishName+']'					
			End
			Else Begin
				Set @sPublishName=NULL
			End

			-- Contruct the 'Group by' clause:
			If  @bIsAggregate <> 1 
			and @sTableColumn <> 'NULL'
			and @bNeedGroupBy = 1
			Begin
				Set @sWIPGroupBy=@sWIPGroupBy+nullif(',', ',' + @sWIPGroupBy)+@sTableColumn				
			End
		End				
		
		-- If Procedure Name is csw_ListCase
		Else 
		If  @sProcedureName = 'csw_ListCase'
		Begin	
			-- Remove spaces, quotes, dots, and any special characters from the Derived Table 
			-- column names to avoide SQL error:
			Set @sTableColumn=CASE WHEN @nDataFormatID = 9107 
					       -- cast text type columns as nvarchar(4000) to avoid SQL error:
					       THEN 'CAST(C.' + dbo.fn_ConvertToAlphanumeric(@sPublishName)+' as nvarchar(4000))'	
					       ELSE 'C.' + dbo.fn_ConvertToAlphanumeric(@sPublishName)
					  END

			-- If the column is being published then concatenate it to the Select list

			If datalength(@sPublishName)>0
			Begin
				Set @sWIPSelect=@sWIPSelect+nullif(',', ',' + @sWIPSelect)+@sTableColumn+' as ['+@sPublishName+']'					
			End
			Else Begin
				Set @sPublishName=NULL
			End

			-- Any case column that is sort only needs to be produced by the inner SQL 
			-- for sorting by the outer SQL.
			If @sPublishName is null
			Begin  
				Set @sPublishName=@sColumn + @sCorrelationSuffix   
				
				-- Remove spaces, quotes, dots, and any special characters from the Derived Table 
				-- publish names to avoide SQL error:
				Set @sPublishName=dbo.fn_ConvertToAlphanumeric(@sPublishName)	
			End	
			
			-- Remove spaces, quotes, dots, and any special characters from the Derived Table 
			-- publish names to avoide SQL error:			
			Set @sPublishNameForXML=dbo.fn_ConvertToAlphanumeric(@sPublishName)		

			Set @sCaseXMLOutputRequests = @sCaseXMLOutputRequests + char(10) + 
			'	<Column ID="' + @sColumn + '" ProcedureName="' + @sProcedureName + '" Qualifier="' + @sQualifier + '" PublishName="' + @sPublishNameForXML + '" />'

			-- Contruct the 'Group by' clause:
			If  @bIsAggregate <> 1 
			and @sTableColumn <> 'NULL'
			and @bNeedGroupBy = 1
			Begin
				Set @sWIPGroupBy=@sWIPGroupBy+nullif(',', ',' + @sWIPGroupBy)+@sTableColumn	
			End
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
/****    CONSTRUCTION OF THE WHERE  clause  ****/
/****                                       ****/
/***********************************************/

If   @nErrorCode=0
and (datalength(@ptXMLFilterCriteria) <> 0
or   datalength(@ptXMLFilterCriteria) is not null)
Begin
	exec @nErrorCode=dbo.wp_FilterWip
				@psReturnClause		= @sWIPWhere	  	OUTPUT, 
				@psCurrentCaseTable	= @sCurrentCaseTable 	OUTPUT,	
				@psCurrentWipTable	= @sCurrentWipTable	OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,		
				@pbIsExternalUser	= @bExternalUser,	
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,	
				@pbCalledFromCentura	= @pbCalledFromCentura	
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE HAVING  clause ****/
/****                                       ****/
/***********************************************/

If  PATINDEX ('%<AggregateFilterCriteria>%', @ptXMLFilterCriteria)>0
and @nErrorCode=0
Begin
	exec @nErrorCode=dbo.wp_ConstructWipHaving	
				@psWIPHaving		= @sWIPHaving	  	OUTPUT, 			
				@pnUserIdentityId	= @pnUserIdentityId,	
				@psCulture		= @psCulture,	
				@pbExternalUser		= @bExternalUser,
				@pnQueryContextKey	= @pnQueryContextKey,
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
				@pbCalledFromCentura	= @pbCalledFromCentura
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
	Select @sWIPOrderBy= 	ISNULL(NULLIF(@sWIPOrderBy+',', ','),'')			
			  	+CASE WHEN(PublishName is null) 
			       	      THEN ColumnName
			       	      ELSE '['+PublishName+']'
			  	END
				+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
				from @tbOrderBy
				order by Position			

	If @sWIPOrderBy is not null
	Begin
		Set @sWIPOrderBy = ' Order by ' + @sWIPOrderBy
	End

	Set @nErrorCode=@@Error
End

-- Close the <OutputRequest> tag to be able to pass constructed output requests to the List Case procedures.
If @nErrorCode = 0
Begin   
	Set @sCaseXMLOutputRequests = @sCaseXMLOutputRequests + char(10) + '	</OutputRequests>'
End

-- Implement validation to ensure that the @sCaseXMLOutputRequests has not overflown.
If @nErrorCode = 0 
and right(@sCaseXMLOutputRequests, 17) <> '</OutputRequests>'
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP46', 'There are more Case columns selected than the system is able to process. Please reduce the number of columns selected and retry.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = @@ERROR
End

If  @nErrorCode = 0
Begin
	-- Check to see if any of the required columns are ones that cannot be incorporated into the main SELECT
	-- being constructed.  If not then the additional details will be loaded into a temporary table for later
	-- inclusion into the main SELECT
	
	If @nErrorCode=0
	Begin
		exec @nErrorCode=dbo.csw_GetExtendedCaseDetails	@psWhereFilter		= @sWhereFilter	  	OUTPUT, 			
								@psTempTableName 	= @sCurrentCaseTable	OUTPUT,	
								@pnUserIdentityId	= @pnUserIdentityId,	
								@psCulture		= @psCulture,	
								@pbExternalUser		= @bExternalUser,
								@pnQueryContextKey	= @pnQueryContextKey,
								@ptXMLOutputRequests	= @sCaseXMLOutputRequests,
								@pbCalledFromCentura	= @pbCalledFromCentura
	End
	
	
	-- Construct the "Select", "From" and the "Order by" clauses 
		
	if @nErrorCode=0 
	and @sCaseXMLOutputRequests is not null
	Begin	
		exec @nErrorCode=dbo.csw_ConstructCaseSelect	@nTableCount	OUTPUT,
								@pnUserIdentityId,
								@psCulture,
								@bExternalUser, 			
								@sCurrentCaseTable,	
								@pnQueryContextKey,
								@sCaseXMLOutputRequests,
								@ptXMLFilterCriteria,
								@pbCalledFromCentura
	End
	
	If @nErrorCode=0 
	Begin 	
		Set @sSQLString="
		Select 	@sSelectList1=S.SavedString, 
			@sFrom       =F.SavedString, 
			@sWhere      =W.SavedString
		from #TempConstructSQL W	
		left join #TempConstructSQL F	on (F.ComponentType='F'
						and F.Position=(select min(F1.Position)
								from #TempConstructSQL F1
								where F1.ComponentType=F.ComponentType))
		left join #TempConstructSQL S	on (S.ComponentType='S'
						and S.Position=(select min(S1.Position)
								from #TempConstructSQL S1
								where S1.ComponentType=S.ComponentType))	
		Where W.ComponentType='W'"				-- there will only be 1 Where row
	
		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@sSelectList1		nvarchar(4000)	OUTPUT,
						  @sFrom		nvarchar(4000)	OUTPUT,
						  @sWhere		nvarchar(4000)	OUTPUT',
						  @sSelectList1=@sSelectList1		OUTPUT,
						  @sFrom       =@sFrom1			OUTPUT,
						  @sWhere      =@sWhereCase		OUTPUT
	
		-- Now get the additial SELECT clause components.  
		-- A fixed number have been provided for at this point however this can 
		-- easily be increased
		
		If  @sSelectList1 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=1"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList2		OUTPUT
	
		End
		
		If  @sSelectList2 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=2"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList3		OUTPUT
		End
		
		If  @sSelectList3 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=3"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList4		OUTPUT
		End
	
		If  @sSelectList4 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=4"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList5		OUTPUT
	
		End
		
		If  @sSelectList5 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=5"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList6		OUTPUT
		End
		
		If  @sSelectList6 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=6"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList7		OUTPUT
		End
	
		If  @sSelectList7 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=7"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList8		OUTPUT
		End
	
		-- Now get the additial FROM clause components.  
		-- A fixed number have been provided for at this point however this can 
		-- easily be increased
		
		If  @sFrom1 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=1"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom2		OUTPUT
		End
		
		If  @sFrom2 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=2"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom3		OUTPUT
		End
		
		If  @sFrom3 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=3"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom4		OUTPUT
		End
	
		If  @sFrom4 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=4"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom5		OUTPUT
		End
		
		If  @sFrom5 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=5"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom6		OUTPUT
		End
		
		If  @sFrom6 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=6"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom7		OUTPUT
		End
	
		If  @sFrom7 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=7"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom8		OUTPUT
		End
		
		If  @sFrom8 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=8"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom9		OUTPUT
		End
	
		If  @sFrom9 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=9"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom10		OUTPUT
		End
		
		If  @sFrom10 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=10"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom11		OUTPUT
		End
	
		If  @sFrom11 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=11"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom12		OUTPUT
		End			
	End
End

If  @nErrorCode = 0
Begin
	-- Assemble the constructed SQL clauses:
	Set @sWIPSelect 		= 'Select ' 	+ @sWIPSelect

	If @sWIPGroupBy is not null
	Begin
		Set @sWIPGroupBy	= 'Group by ' 	+ @sWIPGroupBy
	End
	
	If  PATINDEX ('%<csw_ListCase>%', @ptXMLFilterCriteria)>0
	or  PATINDEX ('%csw_ListCase%', @ptXMLOutputRequests)>0
	Begin
		Set @sSelectList1 	= 'left join (' + @sSelectList1

		-------------------------------------------------------
		-- RFC45848
		-- Commented out the following code.  The @sWIPWhere
		-- is not required to be embededded in the where clause
		-- returnting the Case details.  All we need to know is
		-- the CaseId being returen in WORKINPROGRESS
		-------------------------------------------------------
		--Set @sWIPCaseWhere	= char(10) + 
		--			  'where exists(Select 1' + char(10) +
		--			  @sWIPWhere	+ char(10) +
		--			  ')) C on (C.CaseKey = W.CASEID)'
		
		Set @sWIPCaseWhere	= ') C on (C.CaseKey = W.CASEID)'
	End
	Else Begin
		Set @sSelectList1 	= null
		Set @sWIPCaseWhere	= null
		Set @sFrom1		= null	
	End

	Set @sWorkInProgressWhere
					= + char(10) 	+ 'WHERE (W.CASEID is null OR CS.CASEID is not null)' 
							+ CASE WHEN(@bRowLevelSecurity=1) THEN ' AND (W.CASEID is null OR RS.CASEID is not null)' ELSE '' END
							+ CASE WHEN(@bBlockCaseAccess=1)  THEN char(10)+' and 1=0' ELSE '' END
                                                        + CASE WHEN(@bRowLevelNameSecurity=1) THEN ' AND (W.CASEID is not null or (W.ACCTCLIENTNO is null OR RNS.NAMENO is not null))' ELSE '' END
						        + isnull(@sWIPNameWhere,'')	-- Ensure ethical wall on names are considered
					  + char(10)    + 'and exists (Select 1' 
				 	  + char(10) 	+ @sWIPWhere
				  	  + char(10)	+ 'and XW.ENTITYNO=W.ENTITYNO'
				  	  + char(10) 	+ 'and XW.TRANSNO=W.TRANSNO'		
				  	  + char(10)	+ 'and XW.WIPSEQNO=W.WIPSEQNO)'
End

If @nErrorCode=0
Begin				     
	-------------------------------------------------
	-- RFC62317
	-- Add a common table expression (CTE) to get the 
	-- minimum sequence for a CASEID and NAMETYPE
	------------------------------------------------- 	
	Set @sCTE='with CTE_CaseNameSequence (CASEID, NAMETYPE, SEQUENCE)'+CHAR(10)+
		  'as (	select CASEID, NAMETYPE, MIN(SEQUENCE)'+CHAR(10)+
		  '	from CASENAME with (NOLOCK)'+CHAR(10)+
		  '	where EXPIRYDATE is null or EXPIRYDATE>GETDATE()'+CHAR(10)+
		  '	group by CASEID, NAMETYPE),'+CHAR(10)+

		  '     CTE_RespNameSequence (NAMENO, SEQUENCE)'+CHAR(10)+
		  'as ( select NAMENO, MIN(SEQUENCE)'+CHAR(10)+
		  '     from ASSOCIATEDNAME with (NOLOCK)'+CHAR(10)+
		  '     where RELATIONSHIP=''RES'''+CHAR(10)+
		  '     and PROPERTYTYPE is NULL'+CHAR(10)+
		  '     and COUNTRYCODE  is NULL'+CHAR(10)+
		  '     and ACTION       is NULL'+CHAR(10)+
		  '     group by NAMENO)'+CHAR(10)

End

-- Assemble and execute the constructed SQL to return the result set
If  @nErrorCode = 0
-- No paging required
and (@pnPageStartRow is null or
     @pnPageEndRow is null)
Begin  		
	If @pbPrintSQL = 1
	Begin
		-- Print out the executed SQL statement:			
		Print 'SET ANSI_NULLS OFF; ' 
		Print @sCTE
		Print @sWIPSelect
		Print @sWIPFrom
		Print @sSelectList1
		Print @sSelectList2
		Print @sSelectList3
		Print @sSelectList4
		Print @sSelectList5
		Print @sSelectList6
		Print @sSelectList7
		Print @sSelectList8
		Print @sFrom1
		Print @sFrom2
		Print @sFrom3
		Print @sFrom4
		Print @sFrom5
		Print @sFrom6
		Print @sFrom7
		Print @sFrom8
		Print @sFrom9
		Print @sFrom10
		Print @sFrom11
		Print @sFrom12
		Print @sWIPCaseWhere
		Print @sWorkInProgressWhere			
		Print @sWIPGroupBy	
		Print @sWIPHaving
		Print @sWIPOrderBy		
	End

	-- execute the constructed SQL:
	exec (	'SET ANSI_NULLS OFF; '+@sCTE + @sWIPSelect + @sWIPFrom + @sSelectList1 + @sSelectList2 + @sSelectList3 +
		@sSelectList4 + @sSelectList5 + @sSelectList6 + @sSelectList7 + @sSelectList8 +
		@sFrom1 + @sFrom2 + @sFrom3 + @sFrom4 + @sFrom5 + @sFrom6 + @sFrom7 + @sFrom8 +
		@sFrom9 + @sFrom10 + @sFrom11 + @sFrom12 + @sWIPCaseWhere + @sWorkInProgressWhere +			
		@sWIPGroupBy + @sWIPHaving + @sWIPOrderBy)

	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End
-- Paging required
Else If @nErrorCode = 0
Begin 
	Set @sTopSelectList1 = replace(@sWIPSelect,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
	
	Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sWIPOrderBy+') as RowKey'+char(10)+
					    'FROM ('+char(10)
					 
	Set @sCloseWrapper = ') as OutputSorted'+char(10)+
					     ') as OutputWithRow'+char(10)+
					     'where RowKey>='+cast(@pnPageStartRow as varchar)+' and RowKey<='+cast(@pnPageEndRow as varchar)
						 
	If @pbPrintSQL = 1
	Begin
		-- Print out the executed SQL statement:			
		Print 'SET ANSI_NULLS OFF; ' 
		Print @sCTE
		print @sOpenWrapper
		Print @sTopSelectList1
		Print @sWIPFrom
		Print @sSelectList1
		Print @sSelectList2
		Print @sSelectList3
		Print @sSelectList4
		Print @sSelectList5
		Print @sSelectList6
		Print @sSelectList7
		Print @sSelectList8
		Print @sFrom1
		Print @sFrom2
		Print @sFrom3
		Print @sFrom4
		Print @sFrom5
		Print @sFrom6
		Print @sFrom7
		Print @sFrom8
		Print @sFrom9
		Print @sFrom10
		Print @sFrom11
		Print @sFrom12
		Print @sWIPCaseWhere
		Print @sWorkInProgressWhere			
		Print @sWIPGroupBy	
		Print @sWIPHaving
		Print @sWIPOrderBy		
		print @sCloseWrapper		
	End
				
	-- execute the constructed SQL:
	exec (	'SET ANSI_NULLS OFF; ' + @sCTE + @sOpenWrapper + @sTopSelectList1 + @sWIPFrom + @sSelectList1 + @sSelectList2 + @sSelectList3 +
		@sSelectList4 + @sSelectList5 + @sSelectList6 + @sSelectList7 + @sSelectList8 +
		@sFrom1 + @sFrom2 + @sFrom3 + @sFrom4 + @sFrom5 + @sFrom6 + @sFrom7 + @sFrom8 +
		@sFrom9 + @sFrom10 + @sFrom11 + @sFrom12 + @sWIPCaseWhere + @sWorkInProgressWhere +			
		@sWIPGroupBy + @sWIPHaving + @sWIPOrderBy + @sCloseWrapper) 

	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT
			
	If @pnRowCount < @pnPageEndRow 
	and isnull(@pnPageStartRow,1)=1
	and @nErrorCode=0
	Begin	
		set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRowCount	int',
					  @pnRowCount=@pnRowCount
	End
	Else If @nErrorCode=0
	Begin	

		Set @sOpenWrapper = char(10)+
					    'select Count(*) as SearchSetTotalRows '+char(10)+
					    'from ( select 1 as row '+char(10)				   
					 
		Set @sCloseWrapper = ') as WIP';
	   	
		If @pbPrintSQL = 1
		Begin

			print 'SET ANSI_NULLS OFF; ' + @sCTE + @sOpenWrapper +  @sWIPFrom + @sSelectList1 + @sSelectList2 + @sSelectList3 +
			@sSelectList4 + @sSelectList5 + @sSelectList6 + @sSelectList7 + @sSelectList8 +
			@sFrom1 + @sFrom2 + @sFrom3 + @sFrom4 + @sFrom5 + @sFrom6 + @sFrom7 + @sFrom8 +
			@sFrom9 + @sFrom10 + @sFrom11 + @sFrom12 + @sWIPCaseWhere + @sWorkInProgressWhere +			
			@sWIPGroupBy + @sWIPHaving + @sCloseWrapper

		End

		exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sOpenWrapper +  
			@sWIPFrom + @sSelectList1 + @sSelectList2 + @sSelectList3 +
			@sSelectList4 + @sSelectList5 + @sSelectList6 + @sSelectList7 + @sSelectList8 +
			@sFrom1 + @sFrom2 + @sFrom3 + @sFrom4 + @sFrom5 + @sFrom6 + @sFrom7 + @sFrom8 +
			@sFrom9 + @sFrom10 + @sFrom11 + @sFrom12 + @sWIPCaseWhere + @sWorkInProgressWhere +			
			@sWIPGroupBy + @sWIPHaving + @sCloseWrapper )
		
		Set @nErrorCode =@@ERROR
	End
End

-- Now drop the temporary table holding Cases :
If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentCaseTable)
and @nErrorCode=0
Begin
	Set @sSql = "drop table "+@sCurrentCaseTable

	exec @nErrorCode=sp_executesql @sSql
End

-- Now drop the temporary table holding the WIP results:
If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentWipTable)
and @nErrorCode=0
Begin
	Set @sSql = "drop table "+@sCurrentWipTable
		
	exec @nErrorCode=sp_executesql @sSql
End

RETURN @nErrorCode
GO

Grant execute on dbo.wp_ListWorkInProgress  to public
GO

