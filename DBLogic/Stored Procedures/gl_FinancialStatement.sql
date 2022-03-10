-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_FinancialStatement
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[gl_FinancialStatement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.gl_FinancialStatement.'
	drop procedure dbo.gl_FinancialStatement
End
go
print '**** Creating procedure dbo.gl_FinancialStatement...'
print ''

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.gl_FinancialStatement
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@pnCallinglevel			int,
	@pbGenerateReportCriteria 	bit 		= 0
)		
as
-- PROCEDURE:	gl_FinancialStatement
-- VERSION:	8
-- SCOPE:	Centura
-- DESCRIPTION:	Financial Statement report writer main program
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 31-Aug-2004  MB	9658	1	Procedure created
-- 23-May-2005  MB	11278	2	Performance improvement
-- 06 Jun 2005	TM	RFC2630	3	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 22 May 2006	AT	12563	4	Change TABLECODES table to in-line select to avoid problem casting USERCODE.
-- 20 Dec 2006	AT	14039	5	Add order by clause to #TEMPALLLINES insert to ensure report lines come in correct order.
-- 28 Mar 2007	CR	10252	6	Unsure as many temporary tables are dropped once the Stored procedure is complete.
--27 Mar 2012		DL	20439	7	Fix syntax error when column ‘Budget Movement’ is included
-- 13 Apr 2012	DL	R12172	8	Revisit 20439.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sCurrentTable 		nvarchar(50)	
Declare @bTempTableExists	bit
Declare	@bExternalUser		bit
Declare @pbExists		bit
Declare @sSql			nvarchar(4000)
Declare @sSQLString		nvarchar(4000)
Declare @sSelectList1		nvarchar(4000)  -- the SQL list of columns to return
Declare @sSelectList2		nvarchar(4000)  -- the SQL list of columns to return
Declare	@sFrom1			nvarchar(4000)	-- the SQL to list tables and joins
Declare	@sFrom2			nvarchar(4000)
Declare @sWhere			nvarchar(4000) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseSelect)
Declare @sOrderBy1		nvarchar(4000)	-- the SQL sort order
Declare @sOrderBy2		nvarchar(4000)	-- the SQL sort order
Declare @sGroupBy1		nvarchar(4000)	-- the SQL group by
Declare @sGroupBy2		nvarchar(4000)	-- the SQL group by
Declare @sUnionSelect		nvarchar(4000)  -- the SQL list of columns to return for the UNION
Declare	@sUnionFrom1		nvarchar(4000)	-- the SQL to list tables and joins for the UNION
Declare @sUnionWhere		nvarchar(4000) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseSelect) for the UNION
Declare @sUnionFilter		nvarchar(4000) 	-- the SQL to filter (To store the output "Where" from the csw_FilterCases) for the UNION
Declare @sUnionGroupBy		nvarchar(4000)	-- the SQL for grouping columns of like values for the UNION

Declare	@sSelectClause		nvarchar(4000)	
Declare @sListOfColumn		nvarchar(4000)		-- List of column used in the Total calculation
Declare @sListOfPersentageColumns nvarchar(4000)	-- list of column Ids where result is a percentage
Declare	@sTempLedgerAccount	nvarchar(30)
Declare @nXMLLinePositionNo	int
Declare @nQueryId 		int

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int 	
Declare @nLineCount 		int
Declare @nLineIndex		int
Declare @nLineId		int
Declare @nPeriodFrom		int
Declare @nPeriodTo		int
Declare @nCurrentPostingPeriod	int
Declare @sConsolidatedTempTable	nvarchar(50)

-- Declare constants for different Line Types
Declare @IDC_LINETYPE_ACCOUNTS 		int
Declare @IDC_LINETYPE_TOTALS 		int
Declare @IDC_LINETYPE_COMMENTS 		int
Declare @IDC_LINETYPE_LINE 		int
Declare @IDC_LINETYPE_TITLE 		int
Declare @IDC_LINETYPE_PERIOD 		int
Declare @IDC_LINETYPE_COLUMNTITLE	int

-- SQA11278
Declare @nOutputRequestRowCount		int
Declare @sEntityTableName		varchar(30)	
Declare @sProfitCentreTableName		varchar(30)
Declare @sLedgerAccountTableName	varchar(30)
Declare @sFilterCriteriaTableName	varchar(30)
Declare @sOutputRequestTable		varchar(30)

Declare @nYTDMinPeriod 			int
Declare @nYTDMaxPeriod			int
Declare @nPreviousYTDMinPeriod		int
Declare @nPreviousYTDMaxPeriod		int

Declare @nPreviousFinancialYear 	int 
Declare @nPreviousPeriodFrom 		int
Declare @nPreviousPeriodTo 		int
Declare @nFinancialYear			int

Declare  @tblAccountsLines 	TABLE
(
	ROWNUMBER	int IDENTITY		not null,
	XMLLINEPOSITION	int 			not null,
	LINEID		int			not null
)


Set @nErrorCode			= 0
set @nOutputRequestRowCount	= 0
-- Define Line Type Constants
Set @IDC_LINETYPE_ACCOUNTS	= 1
Set @IDC_LINETYPE_TOTALS 	= 2
Set @IDC_LINETYPE_COMMENTS	= 3
Set @IDC_LINETYPE_LINE 		= 4
Set @IDC_LINETYPE_TITLE 	= 5
Set @IDC_LINETYPE_PERIOD 	= 6
Set @IDC_LINETYPE_COLUMNTITLE 	= 7

Create table  #TEMPALLLINES  (
 		ROWNUMBER	int IDENTITY	not null,
 		LINEID		int		not null,
		LINEPOSITION	int		null,
		LINETYPE	int		null  )


-- Create temp table to hold ledger accounts
set @sTempLedgerAccount = '##TEMPLEDGERACCOUNT' + Cast(@@SPID as nvarchar(30))


If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sTempLedgerAccount )
Begin 
	Set @sSql = 'DROP TABLE ' + @sTempLedgerAccount

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode=0
Begin
	Set @sSql = 'Create table ' + @sTempLedgerAccount + '(
			ENTITYNO 		int NOT NULL ,
			PROFITCENTRECODE 	nvarchar(6) collate database_default NOT NULL ,
			ACCOUNTID		int NOT NULL  )'

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode=0
Begin
	Set @sSql = 'Create index  XIETEMP on ' + @sTempLedgerAccount + '(
			ENTITYNO 		  ,
			PROFITCENTRECODE 	 ,
			ACCOUNTID	  )'

	Exec @nErrorCode=sp_executesql @sSql
End

Set @sConsolidatedTempTable = '##CONSOLIDATEDRESULT' + Cast(@@SPID as nvarchar(30))

	
If @nErrorCode=0 and  exists(select * from tempdb.dbo.sysobjects where name = @sConsolidatedTempTable )
Begin 
	Set @sSql = 'Drop table ' + @sConsolidatedTempTable

	Exec @nErrorCode=sp_executesql @sSql
End


If @nErrorCode=0
Begin
	Set @sSql = 'Create table  ' + @sConsolidatedTempTable + '(
	 		LINEID	int not null,
			POSITION int  not null)'

	Exec @nErrorCode=sp_executesql @sSql
End

-- SQA11278
Set @sEntityTableName		='##ENTITY'
Set @sProfitCentreTableName	='##PROFITCENTRE'
Set @sLedgerAccountTableName	='##LEDGERACCOUNT'
Set @sFilterCriteriaTableName	='##FILTERCRITERIA'
Set @sOutputRequestTable	='##OUTPUTREQUESTTABLE'

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sEntityTableName )
Begin 
	Set @sSql = 'Drop table ' + @sEntityTableName

	Exec @nErrorCode=sp_executesql @sSql
End
If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sProfitCentreTableName )
Begin 
	Set @sSql = 'Drop table ' + @sProfitCentreTableName

	Exec @nErrorCode=sp_executesql @sSql
End
If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sLedgerAccountTableName )
Begin 
	Set @sSql = 'Drop table ' + @sLedgerAccountTableName

	Exec @nErrorCode=sp_executesql @sSql
End
If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sFilterCriteriaTableName )
Begin 
	Set @sSql = 'Drop table ' + @sFilterCriteriaTableName

	Exec @nErrorCode=sp_executesql @sSql
End


If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sOutputRequestTable )
Begin 
	Set @sSql = 'Drop table ' + @sOutputRequestTable

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode=0
Begin
	Set @sSql = 'Create table ' + @sEntityTableName + '(
			LINEID int not null, 
			FILTERID nvarchar(40) collate database_default not null, 
			ENTITYNO int )'

	Exec @nErrorCode=sp_executesql @sSql
End
If @nErrorCode=0
Begin
	Set @sSql = 'Create table ' + @sProfitCentreTableName + '(
			LINEID int not null, 
			FILTERID nvarchar(40) collate database_default not null, 
			PROFITCENTRECODE nvarchar(30) collate database_default not null )'

	Exec @nErrorCode=sp_executesql @sSql
End
If @nErrorCode=0
Begin
	Set @sSql = 'Create table ' + @sLedgerAccountTableName + '(
			LINEID int not null, 
			FILTERID nvarchar(40) collate database_default not null, 
			ACCOUNTID int not null )'

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode=0
Begin
	Set @sSql = 'Create table ' + @sFilterCriteriaTableName + '(
			LINEID int not null, 
			FILTERID nvarchar(40) collate database_default not null, 
			BOOLEANOPERATOR nvarchar(3) )'

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode=0
Begin
	Set @sSql = 'Create table ' + @sOutputRequestTable + '(
			ROWNUMBER	int 	IDENTITY	not null,
		    	PROCEDUREITEMID	nvarchar(50)	collate database_default not null,
			DATAITEMID	int not null)'

	Exec @nErrorCode=sp_executesql @sSql
End

---------------------------------------------------------------------
--	Populate Output Request Table (requested columns from Presentation tab)
---------------------------------------------------------------------

If @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	Exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into ##OUTPUTREQUESTTABLE (PROCEDUREITEMID, DATAITEMID)
	( Select distinct F.COLUMNID , B.DATAITEMID
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null) F
	-- R12172 - add filter and B.PROCEDURENAME = 'gl_FinancialStatement' to eliminate duplicate columns from other reports.
	join QUERYDATAITEM B on (F.COLUMNID = B.PROCEDUREITEMID and B.PROCEDURENAME = 'gl_FinancialStatement' )
	
	where F.PUBLISHNAME is not null
	)

	Select  @nErrorCode = @@ERROR, @nOutputRequestRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	Exec sp_xml_removedocument @idoc
End


If @nErrorCode=0
Begin
	Exec @nErrorCode = dbo.gl_FSAlterTempTable
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pnQueryContextKey		= @pnQueryContextKey,
		@ptXMLOutputRequests		= @ptXMLOutputRequests, 
		@psTempTableName		= @sTempLedgerAccount,
		@psConsolidatedTempTable 	= @sConsolidatedTempTable,
		@psSelectClause			= @sSelectClause output,
		@psListOfColumns		= @sListOfColumn output, -- List of column used in the Total calculation
		@psListOfPercentageColumns 	= @sListOfPersentageColumns output
End


-- Start Processing Accounts type records

If @nErrorCode=0
Begin
	Exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	Set @sSql =	"Insert into #TEMPALLLINES  
		(LINEID, LINEPOSITION, LINETYPE )
		Select  B.LINEID,    B.LINEPOSITION, CAST (C.USERCODE as int)
		from	OPENXML(@idoc, '//Line' ,1)
		WITH (
			      LINEID		int		'@Id/text()'
		     )	A join QUERYLINE B on ( A.LINEID = B.LINEID)
			join (SELECT TABLECODE, USERCODE FROM TABLECODES WHERE TABLETYPE = 100) as C on  (B.LINETYPE = C.TABLECODE)
		ORDER BY B.LINEPOSITION
	 "

	Exec @nErrorCode = sp_executesql @sSql,
				N'@idoc	int',
				  @idoc	= @idoc	
End

If @nErrorCode=0
Begin


	Set @sSql =	"Insert into " +  @sConsolidatedTempTable + "  
			(LINEID, POSITION )
	(	Select  LINEID, ROWNUMBER
		from	#TEMPALLLINES  
		where LINETYPE 	in ( @IDC_LINETYPE_COMMENTS, @IDC_LINETYPE_LINE, @IDC_LINETYPE_TITLE,
				@IDC_LINETYPE_PERIOD, @IDC_LINETYPE_COLUMNTITLE, @IDC_LINETYPE_TOTALS )
	 )"

	Exec @nErrorCode = sp_executesql @sSql,
				N'@IDC_LINETYPE_COMMENTS	int,
				@IDC_LINETYPE_LINE 		int,
				@IDC_LINETYPE_TITLE 		int,
				@IDC_LINETYPE_PERIOD 		int, 
				@IDC_LINETYPE_COLUMNTITLE 	int,
				@IDC_LINETYPE_TOTALS		int',
				@IDC_LINETYPE_COMMENTS 		= @IDC_LINETYPE_COMMENTS,
				@IDC_LINETYPE_LINE 		= @IDC_LINETYPE_LINE,
				@IDC_LINETYPE_TITLE 		= @IDC_LINETYPE_TITLE,
				@IDC_LINETYPE_PERIOD 		= @IDC_LINETYPE_PERIOD,
				@IDC_LINETYPE_COLUMNTITLE 	= @IDC_LINETYPE_COLUMNTITLE,
				@IDC_LINETYPE_TOTALS		= @IDC_LINETYPE_TOTALS
End

-- exec (' select * from ' +  @sConsolidatedTempTable )

If @nErrorCode=0
Begin
-- extract QueryId from Filter

	Set @sSql =" 
		Select  @nQueryId = QUERYID,
			 @nPeriodFrom = PeriodFrom, 
			 @nPeriodTo = PeriodTo  
		from	OPENXML(@idoc, '/gl_FinancialStatement' ,2)
			WITH (
			      	QUERYID		int	'QueryId/text()',
 				PeriodFrom	int	'PeriodFrom/text()', 
			  	PeriodTo	int	'PeriodTo/text()')"

	Exec @nErrorCode = sp_executesql @sSql,
				N'@idoc		int,
				  @nQueryId 	int	output,
				  @nPeriodFrom 	int	output,
				  @nPeriodTo 	int	output',
				  @idoc		= @idoc,
				  @nQueryId 	= @nQueryId	output,
				  @nPeriodFrom 	= @nPeriodFrom	output,
				  @nPeriodTo 	= @nPeriodTo	output	
End

-- SQA11278 Load Filter information to the temporary tables
	-- POPULATE ##ENTITY temporary table
If @nErrorCode=0
Begin
	Set @sSql = 	
		"Insert into " + @sEntityTableName  + " (LINEID, FILTERID, ENTITYNO) " + 
		"Select  LineId, GroupId, Entity 
		from	OPENXML (@idoc, 
		'//FilterCriteria',2) "+CHAR(10)+
		" WITH (  
			LineId	int 		'../../../ @Id',
			GroupId	varchar(40) 	'@ID',	
			Entity	int		'Entity/text()' ) 
		where Entity is not null "

	Exec @nErrorCode = sp_executesql @sSql,
				N'@idoc	int',
				  @idoc	= @idoc
End

	-- POPULATE ##PROFITCENTRE temporary table
If @nErrorCode=0
Begin		

	Set @sSql = 
		"Insert into " + @sProfitCentreTableName + " (LINEID, FILTERID, PROFITCENTRECODE) 
		Select	LineId, GroupId, ProfitCentreCode
		from	OPENXML (@idoc, 
		'//FilterCriteria/ProfitCentreGroup/ProfitCentre', 2)
		WITH ( 
			LineId			int 		'../../../../../ @Id',
			GroupId			varchar(40) 	'../../ @ID',
			ProfitCentreCode	nvarchar(6)	'Code/text()' )
		where ProfitCentreCode is not null"

	Exec @nErrorCode = sp_executesql @sSql,
				N'@idoc	int',
				  @idoc	= @idoc

End

	-- POPULATE ##LEDGERACCOUNT temporary table
If @nErrorCode=0
Begin	
	Set @sSql = "
		Insert into " + @sLedgerAccountTableName + " (LINEID, FILTERID, ACCOUNTID) 
		Select	LineId, GroupId, AccountId
		from	OPENXML (@idoc, 
		'//FilterCriteria/LedgerAccountGroup/LedgerAccount', 2)
		WITH (
			LineId	int '../../../../../ @Id',
			GroupId	varchar(40) '../../ @ID',
		      	AccountId	int 'AccountId/text()'	
		     ) 
		where AccountId is not null"

	Exec @nErrorCode = sp_executesql @sSql,
			N'@idoc	int',
			  @idoc	= @idoc
End

	-- POPULATE ##FILTERCRITERIA temporary table

If @nErrorCode=0
Begin	

	Set @sSql = "
		Insert into " + @sFilterCriteriaTableName + " (LINEID, FILTERID, BOOLEANOPERATOR) 
		Select	LineId, FilterCriteriaId, BooleanOperator
		from	OPENXML (@idoc, 
		'//Line/gl_FinancialStatement/FilterCriteriaGroup/FilterCriteria', 2)
		WITH (
			LineId		int		'../../../@Id/text()',
			FilterCriteriaId nvarchar(40)	'@ID/text()',
			BooleanOperator	nvarchar(3)	'@BooleanOperator/text()'
	 	     ) 
		where FilterCriteriaId is not null"

	Exec @nErrorCode = sp_executesql @sSql,
			N'@idoc	int',
			  @idoc	= @idoc
End

Exec sp_xml_removedocument @idoc

If @nErrorCode = 0 and (@nPeriodTo is null or @nPeriodFrom is null)
Begin
	Set @sSql = '	Select @nCurrentPostingPeriod = PERIODID 
			from PERIOD 
			where POSTINGCOMMENCED = (select MAX (POSTINGCOMMENCED) from PERIOD)'

	Exec @nErrorCode = sp_executesql @sSql,
		N'@nCurrentPostingPeriod int output',
		  @nCurrentPostingPeriod = @nCurrentPostingPeriod	output	
End

If @nErrorCode = 0 and @nPeriodFrom is null
	Set @nPeriodFrom = @nCurrentPostingPeriod

If @nErrorCode = 0 and @nPeriodTo is null
	Set @nPeriodTo = @nCurrentPostingPeriod


-- select number of lines where line type : accounts

If @nErrorCode=0
Begin

	Set @sSql ='	Select @nLineCount = count (1)  
			from     #TEMPALLLINES   
			where  LINETYPE = @IDC_LINETYPE_ACCOUNTS '

	Exec @nErrorCode = sp_executesql @sSql,
				N'@IDC_LINETYPE_ACCOUNTS	int,
				  @nLineCount 			int output',
				  @IDC_LINETYPE_ACCOUNTS	= @IDC_LINETYPE_ACCOUNTS,
				  @nLineCount 			= @nLineCount output
End

If @nErrorCode=0 and @nLineCount > 0
Begin

	Insert into  @tblAccountsLines  ( XMLLINEPOSITION, LINEID )
			( select ROWNUMBER, LINEID 
			from   #TEMPALLLINES   
			where  LINETYPE = @IDC_LINETYPE_ACCOUNTS )
	Set @nErrorCode = @@ERROR
End

----------------------------------------------------------------------
-- Prepare Period
---------------------------------------------------------------------

If @nErrorCode = 0
Begin
	Set @nPreviousPeriodTo = cast ( (cast ( cast ( left (cast (@nPeriodTo as nvarchar),4) as int) - 1 as nvarchar) + right (cast (@nPeriodTo as nvarchar),2) ) as int )
	Set @nPreviousPeriodFrom = cast ( (cast ( cast ( left (cast (@nPeriodFrom as nvarchar),4) as int) - 1 as nvarchar) + right (cast (@nPeriodFrom as nvarchar),2) ) as int )
	Set @nPreviousFinancialYear = cast (left (Cast (@nPreviousPeriodFrom as  nvarchar),4) as int)

	Exec @nErrorCode = gl_FinancialYearToPeriodRange 
				@pnFinancialYearFrom 	= @nPreviousFinancialYear, 
				@pnFinancialYearTo 	= @nPreviousFinancialYear, 
				@pnPeriodFrom 		= @nPreviousYTDMinPeriod output, 
				@pnPeriodTo 		= @nPreviousYTDMaxPeriod output
End


-- get first period of the financial year
If @nErrorCode = 0
Begin
	Set @nFinancialYear = cast (left (cast (@nPeriodTo as  nvarchar),4) as int)

	Exec @nErrorCode = gl_FinancialYearToPeriodRange 
		@pnFinancialYearFrom 	= @nFinancialYear, 
		@pnFinancialYearTo 	= @nFinancialYear, 
		@pnPeriodFrom 		= @nYTDMinPeriod output, 
		@pnPeriodTo 		= @nYTDMaxPeriod output
End


-- Loop over the Accounts type lines

Set @nLineIndex = 1
While @nLineIndex <= @nLineCount and @nErrorCode = 0
Begin
	If @nErrorCode = 0
	Begin
		Select	@nXMLLinePositionNo = XMLLINEPOSITION,
			@nLineId = LINEID
		from	@tblAccountsLines 
		where	ROWNUMBER = @nLineIndex
		Set @nErrorCode = @@ERROR
	End

	if @nErrorCode = 0
		Exec @nErrorCode = dbo.gl_FSFilterAccounts	
				@pnLineId			= @nLineId,	
				@psTempTableName  		= @sTempLedgerAccount,	
				@pnUserIdentityId		= @pnUserIdentityId,	
				@psCulture			= @psCulture,	
				@psEntityTableName 		= @sEntityTableName,
				@psProfitCentreTableName 	= @sProfitCentreTableName,
				@psLedgerAccountTableName 	= @sLedgerAccountTableName,
				@psFilterCriteriaTableName 	= @sFilterCriteriaTableName
	if @nErrorCode = 0
		Exec @nErrorCode=dbo.gl_FSCalculateAccounts 
				@pnUserIdentityId 	= @pnUserIdentityId,
				@psCulture 		= @psCulture,
				@psOutputRequestTable 	= @sOutputRequestTable,
				@psTempTableName 	= @sTempLedgerAccount,
				@pnPeriodFrom 		= @nPeriodFrom,
				@pnPeriodTo 		= @nPeriodTo,
				@pnOutputRequestRowCount = @nOutputRequestRowCount,
				@pnYTDMinPeriod		= @nYTDMinPeriod,
				@pnPreviousYTDMinPeriod = @nPreviousYTDMinPeriod,
				@pnPreviousYTDMaxPeriod = @nPreviousYTDMaxPeriod,
				@pnPreviousPeriodFrom	= @nPreviousPeriodFrom,	
				@pnPreviousPeriodTo	= @nPreviousPeriodTo,
				@psSelectClause1	= @sSelectList1 output,
				@psSelectClause2	= @sSelectList2 output
				

	If @nErrorCode=0 
	Begin
		-- SQA20439  Remove leading space, tab, carriage return chars from the string.
		Set @sSelectList1 =  ltrim(replace(replace(replace(@sSelectList1, char(9),''), char(10), ''), char(13), ''))

		--  SQA20439 - insert  ',' only if @sSelectList1 does contain a leading ','
		set @sSql = 'Insert into ' + @sConsolidatedTempTable + ' select ' + cast(@nLineId as varchar(50)) + ', ' + cast(@nXMLLinePositionNo as nvarchar(50)) + 
			case when charindex( ',',@sSelectList1)=1  then @sSelectList1 else ', '  + @sSelectList1 end + @sSelectList2 
		Exec @nErrorCode=sp_executesql @sSql
		
	End

	If @nErrorCode=0 
	Begin
		Set @sSql = 'Truncate table '+ @sTempLedgerAccount
		Exec @nErrorCode = sp_executesql @sSql
	End
	
	Set @nLineIndex = @nLineIndex + 1
End

-- Start Processings Totals

If @nErrorCode=0
Begin
	Exec @nErrorCode = dbo.gl_FSCalculateTotals	
				@pnUserIdentityId		= @pnUserIdentityId,	
				@psCulture			= @psCulture,
				@pnQueryId			= @nQueryId,
				@psConsolidatedTable  		= @sConsolidatedTempTable,	
				@psListOfColumns		= @sListOfColumn,
				@psListOfPersentageColumns 	= @sListOfPersentageColumns
End


If @pbCalledFromCentura = 1
Begin
	Select 
		cast ('select   CAST(TC.USERCODE as int) AS LINETYPE,B.ALIGNDESCRIPTION, B.FONTNAME, 
		B.FONTSIZE, B.BOLDSTYLE, B.ITALICSTYLE, B.UNDERLINESTYLE, B.SHOWCURRENCYSYMBOL, 
		B.NEGATIVESIGNTYPE, B.NEGATIVESIGNCOLOUR,
		B.DESCRIPTION,' +  @sSelectClause  as ntext),
		cast (' from ' + @sConsolidatedTempTable + ' A join QUERYLINE B on (A.LINEID = B.LINEID)
			join (SELECT TABLECODE, USERCODE FROM TABLECODES WHERE TABLETYPE = 100) as TC on (B.LINETYPE = TC.TABLECODE ) ' as ntext),
		cast (' WHERE B.ISPRINTABLE = 1 ' as ntext), 
		cast(null as ntext), cast(null as ntext) As GroupBy, 
		cast (' order by A.POSITION' as ntext),
		cast(null as ntext) As UnionSelect, 
		cast(null as ntext) As UnionFrom, 
		cast(null as ntext) As UnionWhere, 
		cast(null as ntext) As UnionFilter, 
		cast(null as ntext) As UnionGroupBy,
		cast(null as ntext) As ReportCriteria
	Set @nErrorCode = @@ERROR
End
Else
Begin
	Exec ('select  CAST(TC.USERCODE as int) AS LINETYPE, B.ALIGNDESCRIPTION, B.FONTNAME, 
		B.FONTSIZE, B.BOLDSTYLE, B.ITALICSTYLE, B.UNDERLINESTYLE, B.SHOWCURRENCYSYMBOL, 
		B.NEGATIVESIGNTYPE, B.NEGATIVESIGNCOLOUR, B.DESCRIPTION,' + 
		@sSelectClause  +' 
		from ' + @sConsolidatedTempTable + ' LJL join  QUERYLINE B on ( LJL.LINEID = B.LINEID )
			join (SELECT TABLECODE, USERCODE FROM TABLECODES WHERE TABLETYPE = 100) as TC on (B.LINETYPE = TC.TABLECODE )
		where  B.ISPRINTABLE = 1 
		order by LJL.POSITION ') 
	Set @nErrorCode = @@ERROR
End

-- SQA10252 ensure as many of these tables are dropped once the stored procedure is complete
If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sTempLedgerAccount )
Begin 
	Set @sSql = 'DROP TABLE ' + @sTempLedgerAccount

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sEntityTableName )
Begin 
	Set @sSql = 'Drop table ' + @sEntityTableName

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sProfitCentreTableName )
Begin 
	Set @sSql = 'Drop table ' + @sProfitCentreTableName

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sLedgerAccountTableName )
Begin 
	Set @sSql = 'Drop table ' + @sLedgerAccountTableName

	Exec @nErrorCode=sp_executesql @sSql
End

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sFilterCriteriaTableName )
Begin 
	Set @sSql = 'Drop table ' + @sFilterCriteriaTableName

	Exec @nErrorCode=sp_executesql @sSql
End


If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sOutputRequestTable )
Begin 
	Set @sSql = 'Drop table ' + @sOutputRequestTable

	Exec @nErrorCode=sp_executesql @sSql
End


Return @nErrorCode
go

Grant execute on dbo.gl_FinancialStatement  to public
go
