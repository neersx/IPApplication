-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetExtendedCaseDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[csw_GetExtendedCaseDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.csw_GetExtendedCaseDetails.'
	drop procedure dbo.csw_GetExtendedCaseDetails
end
print '**** Creating Stored Procedure dbo.csw_GetExtendedCaseDetails...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.csw_GetExtendedCaseDetails
	@psWhereFilter			nvarchar(max)  	OUTPUT,	-- the Where clause that will return all of the Cases
	@psTempTableName		nvarchar(60)	= null	OUTPUT, -- temporary table holding Cases and extended data
	@pnCaseTotal			int		= null  OUTPUT,	-- the total number of Case rows that matches the filter
	@pbPagingApplied		bit		= 0	OUTPUT, -- flag to indicate that the the specific page requests have been applied to the result
	@pnCaseChargeCount		int		= 0	OUTPUT,	-- number of Case Charges being calculated in background
	@psEmailAddress			nvarchar(100)	= null	OUTPUT, -- email to be notified on completion of background fee calculation
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbExternalUser			bit,			-- Mandatory. Flag to indicate if user is external.  Default on as this is the lowest security level
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set. 
	@ptXMLFilterCriteria		ntext		= null, -- Contains filtering to be applied to the selected columns
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@pbPrintSQL			bit		= null,	-- When set to 1, the executed SQL statement is printed out.
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null

AS
-- PROCEDURE :	csw_GetExtendedCaseDetails
-- VERSION :	41
-- DESCRIPTION:	Gets additional details for each Case being enquired/reported on.  This caters for column
--		requests that cannot easily be incorporated into a single SELECT statement.
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who	Number	Version	Change
-- ------------ ---- 	------	-------	------------------------------------------ 
-- 24 Feb 2004	MF  	SQA9663	1	Procedure created
-- 15 Mar 2004	MF	RFC1122	2	Return Narrative as text rather than as a pointer to the Narrative table.
-- 15 Mar 2004	MF	SQA9789	3	Allow the same column to be selected multiple times with a different Publish Name.
-- 15 Mar 2004	MF	SQA9793	4	Get additional columns for Net Service and Disbursement (less discount) & tax 
--					not included.
--  3 May 2004	MF	RFC1371	5	SQL error caused by changes to @psWhereFilter parameter which is now
--					missing the WHERE clause.  Corrected by inserting WHERE 1=1
-- 16 Jun 2004	TM	RFC1384	6	Modify the logic to treat the new TelecomNumber data format the same way 
--					it treats the Email data format.
-- 06 Jul 2004	JB	10267 	7	Modification to call FEESCALC with named paramters (rather than by position)
-- 18 Aug 2004	AB	8035	8	Add collate database_default syntax to temp tables.
-- 30 Sep 2004	JEK	RFC1695 9	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 15 Apr 2004  AB	11271	10	Collation conflict caused by stored procedures
-- 06 Jun 2005	TM	RFC2630	11	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 18 Aug 2005	MF	11771	12	If a DocItem has been used to define a column it is to be allowed to accept
--					more than one parameter if the parameter is separated by a ^ character.
-- 24 Feb 2006	MF	12336	13	The ChargeTypeNo is now being passed as the parameter to display columns that
--					require Fees to be calculated.  The ChargeTypeNo will then be expanded into the
--					associated RateNo(s) that are relevant to the case being processed.
-- 21 Jun 2006	MF	11777	14	Revisit.  The best fit rule was incorrect and too many Rates may have been returned.
-- 27 Oct 2006	MF	13645	15	Extend the best fit for getting the Rates to also consider the Standing Instruction.
-- 20 Dec 2006	MF	RFC2982	16	Get Fees details using the cs_ListCaseCharges procedure.
-- 09 Jan 2007	MF	RFC2982	17	Revisit. Failed test.
-- 18 Jan 2007	MF	RFC2982	18	Performance issue introduced by RFC2982.  Need to create a UNION to avoid
--					an OR which is causing major performance problems.
-- 01 Feb 2007	MF	RFC2982	19	Further performance tuning.
-- 07 Feb 2007	MF	RFC2982	20	Add an index HINT to CASEEVENT to improve performance.
-- 13 Feb 2007	MF	RFC2982	21	If limited rows are required for paging then only extract details for the
--					Cases that will be displayed.
-- 20 Feb 2007	MF	RFC2982	22	Required a new output parameter (@pbPagingApplied) to indicate that Paging 
--					has been applied.
-- 11 Apr 2007	MF	14676	23	SQL error occurring when a column linked to a DocItem selected along with a 
--					CaseText column that could return multiple rows.  Resulted in duplicate key
--					error. Fixed by changing primary key on #TEMPCASES.
-- 16 Jul 2007	MF	14957	24	SQL Error on Due Date enquiry with Alerts and user defined column.  Required the
--					temporary table name of case results to be replaced.  Also found problem in
--					pagination.
-- 28 Sep 2007	CR	14901	25	Changed Exchange Rate field sizes to (8,4)
-- 13 Oct 2009  LP      RFC100085 26    Increase substring start for ProvideInstructions from 47 to 59 to remove WITH (NOLOCK)
-- 26 Oct 2009	MF	RFC8260	27	Provide ability to calculate fees in background to avoid long running queries.
-- 27 Jul 2010	MF	18918	28	Fee not being returned because @psIRN was nvarchar(12) instead of nvarchar(30).
-- 01 Nov 2010	MF	RFC9911	29	Extended rows were previously being deleted if they fell outside of the rows to actually be
--					returned to the user.  This was a performance technique to avoid calculating additional 
--					information for rows that were not going to be displayed. Unfortunately it caused problems
--					with the new form of paging introduced recently.  The new solution is to flag those rows that
--					are to be igornored.
-- 28 Feb 2010	MF	19450	30	Syntax error introduced by RFC9911 due to missing comma.
-- 02 Apr 2011	MF	10437	31	If the user defined column has been defined as a TEXT column then it will be stored in 
--					a nvarchar(max) column so that we can still use the DISTINCT clause.
-- 23 Jul 2012	MF	R12399	32	Case Fee is being displayed even if fee due event is a due date that is not attached to an open action.
-- 02 Aug 2012	MF	R12571	33	When getting an extended column associated with a DocItem, the IGNOREFLAG on the temporary table is to be ignored.
--					Data extracts for these columns are reasonably efficient anyway and this will get around a problem where the main 
--					generated SELECT returns multiple rows for a CASEID which in combination with paging being used can lead to some Cases
--					not returning data in an extended column.  RFC12575 will also address this problem when it is implemented in the 
--					front end. 
-- 05 Jul 2013	vql	R13629	35	Remove string length restriction and use nvarchar on datetime conversions using 106 format.'
-- 17 Apr 2015	MS	R46603	36	Set size of some variables to nvarchar(max)
-- 20 Oct 2015  MS      R53933  37      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 20 May 2015	MF	R61880	38	Correction to code problem caused for external users because of ethical wall change.
-- 07 Sep 2018	AV	74738	39	Set isolation level to read uncommited.
-- 14 Nov 2018  AV  75198/DR-45358	40   Date conversion errors when creating cases and opening names in Chinese DB
-- 13 Apr 2020  RK  DR-55946	41  Modify stored procedure to cater for URL Data Format type 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- A table holding the interim list of Cases to be reported on
-- in the sequence that the user user has elected
Create table #TEMPCASES	(CASEID		int	not null,
			 SEQUENCENO	int	identity(1,1)
			UNIQUE(CASEID, SEQUENCENO))	-- SQA14676

declare @ErrorCode		int
declare	@sSQLString		nvarchar(max)
declare	@sSQLString1		nvarchar(max)
declare @sSQLSelect		nvarchar(max)
declare @sSQLSelectUnion	nvarchar(max)
declare @sSQLFrom		nvarchar(max)
declare @sSQLFromUnion		nvarchar(max)
declare @sAddWhereString	nvarchar(max)
declare @sAddWhereStringUnion	nvarchar(max)
declare @sLoadCases		nvarchar(max)
declare @sQualifier		nvarchar(50)
declare @sTableColumn		nvarchar(1000)
declare @sCorrelationSuffix	nvarchar(20)
declare @sResultTable		nvarchar(60)
declare @sList			nvarchar(max)	-- Variable to prepare a comma separated list of values

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
declare @idoc 			int 		

declare	@nTempCases		int
declare @nOutRequestsRowCount	int
declare @nCaseRowNumber		int
declare @nCount			int
declare @nLoopCount		tinyint
declare	@sIRN			nvarchar(30)
declare @nCaseId		int
declare @nRateNo 		int
declare @nChargeTypeNo		int 
declare @nDocItemKey		int
declare @bCallFeesCalc		bit
declare @bGetInstructions	bit
declare @bTempCasesLoaded	bit
declare @bTempCasesSorted	bit
declare	@bIgnoreFlag		bit
declare	@sColumn		nvarchar(100)
declare	@sColumnName		nvarchar(102)
declare @sUserSQL		nvarchar(max)
declare @sLookupCulture		nvarchar(10)
declare @dtFromDate		datetime
declare @dtUntilDate		datetime

-- RFC2982 Provide Instructions criteria
declare @bInstructionsForMultiCase		bit
declare @bInstructionsForSingleCase		bit
declare @bInstructionsForDueEvent		bit
declare @bIncludeUnknownDueDates		bit
declare	@nInstructionsDateRangeOperator		tinyint
declare	@nInstructionsPeriodRangeOperator	tinyint
declare	@nInstructionsPeriodRangeFrom		smallint
declare	@nInstructionsPeriodRangeTo		smallint
declare	@dtInstructionsDateRangeFrom		datetime
declare	@dtInstructionsDateRangeTo		datetime
declare	@sInstructionsPeriodRangeType		nvarchar(2)
declare	@nInstructionDefinitionOperator		tinyint
declare	@nInstructionDefinitionKey		int
declare @nDueEventCaseKey			int
declare @nDueEventKey				int
declare @nDueEventCycle				smallint
declare @nReminderEmployeeKey			int
declare @dtReminderDateCreated			datetime
declare @nAvailabilityFlags			int
-- RFC2984 Fees criteria
declare @bUntilExpiry				bit
declare	@nFeesDateRangeOperator			tinyint
declare	@nFeesPeriodRangeOperator		tinyint
declare	@nFeesPeriodRangeFrom			smallint
declare	@nFeesPeriodRangeTo			smallint
declare	@dtFeesDateRangeFrom			datetime
declare	@dtFeesDateRangeTo			datetime
declare	@sFeesPeriodRangeType			nvarchar(2)
declare	@nChargeTypeOperator			tinyint
declare	@nChargeTypeKey				int

declare	@bProvideInstructionsRequired	bit --RFC2982
declare	@bFeesRequired			bit --RFC2984

-- Variables used to replace parameters in DocItem
declare	@sParameter		nvarchar(50)
declare @nParameterNo		int
declare	@nInsertOrder		int

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
declare @tblOutputRequests table 
			 (	ROWNUMBER	int 		identity(1,1),
		    		ID		nvarchar(100)	collate database_default not null,
				SORTORDER	tinyint		null,
				PUBLISHNAME	nvarchar(100)	collate database_default null,
				QUALIFIER	nvarchar(100)	collate database_default null,
				DOCITEMKEY	int		null,
				COLUMNNAME	nvarchar(102)	collate database_default null,
				DATATYPE	nvarchar(20)	collate database_default null,
				CALLFEESCALC	bit		null,
				LISTCHARGES	bit		null
			  )

-- The following are the parameters used by the FEESCALC stored procedure
Declare @psIRN 			varchar(30)
Declare @pnRateNo 		int 
Declare @psAction 		varchar(2) 
Declare @pnCheckListType 	smallint
Declare @pnCycle 		smallint
Declare @pnEventNo 		int
Declare @pdtLetterDate 		datetime
Declare @pnEnteredQuantity 	int
Declare @pnEnteredAmount 	decimal(11,2) 
Declare @pnARQuantity 		smallint
Declare @pnARAmount 		decimal(11,2) 
Declare @prsDisbCurrency 	varchar(3)	
Declare @prnDisbExchRate 	decimal(11,4) 
Declare @prsServCurrency 	varchar(3) 	
Declare @prnServExchRate 	decimal(11,4) 
Declare @prsBillCurrency 	varchar(3) 	
Declare @prnBillExchRate 	decimal(11,4) 
Declare @prsDisbTaxCode 	varchar(3) 	
Declare @prsServTaxCode 	varchar(3) 
Declare @prnDisbNarrative 	int
Declare @prnServNarrative 	int
Declare @prsDisbWIPCode 	varchar(6) 	
Declare @prsServWIPCode 	varchar(6) 
Declare @prnDisbAmount 		decimal(11,2) 	
Declare @prnDisbHomeAmount 	decimal(11,2) 
Declare @prnDisbBillAmount 	decimal(11,2)
Declare @prnServAmount 		decimal(11,2) 
Declare @prnServHomeAmount 	decimal(11,2)
Declare @prnServBillAmount 	decimal(11,2) 
Declare @prnTotHomeDiscount 	decimal(11,2)
Declare @prnTotBillDiscount 	decimal(11,2) 
Declare @prnDisbTaxAmt 		decimal(11,2) 	
Declare @prnDisbTaxHomeAmt 	decimal(11,2) 
Declare @prnDisbTaxBillAmt 	decimal(11,2)
Declare @prnServTaxAmt 		decimal(11,2) 	
Declare @prnServTaxHomeAmt 	decimal(11,2)
Declare @prnServTaxBillAmt 	decimal(11,2)				
Declare @prnDisbDiscOriginal	decimal(11,2)
Declare @prnDisbHomeDiscount 	decimal(11,2)
Declare @prnDisbBillDiscount 	decimal(11,2)
Declare @prnServDiscOriginal	decimal(11,2)
Declare @prnServHomeDiscount 	decimal(11,2)
Declare @prnServBillDiscount 	decimal(11,2)
Declare @prnDisbCostHome	decimal(11,2)
Declare @prnDisbCostOriginal	decimal(11,2)
-- Variables to total
Declare @nDisbAmount 		decimal(11,2) 	
Declare @nDisbHomeAmount 	decimal(11,2) 
Declare @nDisbBillAmount 	decimal(11,2)
Declare @nServAmount 		decimal(11,2) 
Declare @nServHomeAmount 	decimal(11,2)
Declare @nServBillAmount 	decimal(11,2) 
Declare @nTotHomeDiscount 	decimal(11,2)
Declare @nTotBillDiscount 	decimal(11,2) 
Declare @nDisbTaxAmt 		decimal(11,2) 	
Declare @nDisbTaxHomeAmt 	decimal(11,2) 
Declare @nDisbTaxBillAmt 	decimal(11,2)
Declare @nServTaxAmt 		decimal(11,2) 	
Declare @nServTaxHomeAmt 	decimal(11,2)
Declare @nServTaxBillAmt 	decimal(11,2)
Declare @nDisbDiscOriginal	decimal(11,2)
Declare @nDisbHomeDiscount 	decimal(11,2)
Declare @nDisbBillDiscount 	decimal(11,2)
Declare @nServDiscOriginal	decimal(11,2)
Declare @nServHomeDiscount 	decimal(11,2)
Declare @nServBillDiscount 	decimal(11,2)
Declare @nDisbCostHome		decimal(11,2)
Declare @nDisbCostOriginal	decimal(11,2)

-- Variables to Save
Declare @nDisbExchRate		decimal(11,4)
Declare @nServExchRate		decimal(11,4)
Declare @sDisbCurrency 		nvarchar(3)
Declare @sServCurrency 		nvarchar(3)
Declare @sDisbTaxCode 		nvarchar(3)
Declare @sServTaxCode 		nvarchar(3)
Declare @sDisbWIPCode 		nvarchar(6)
Declare @sServWIPCode 		nvarchar(6)
Declare @nDisbNarrative		int
Declare @nServNarrative		int

Declare @bDisbTaxCodeSaved	bit
Declare @bServTaxCodeSaved	bit
Declare @bDisbNarrativeSaved	bit
Declare @bServNarrativeSaved	bit
Declare @bDisbWIPCodeSaved	bit
Declare @bServWIPCodeSaved	bit
Declare @bDisbCurrencySaved	bit
Declare	@bServCurrencySaved	bit

-- Initialisation
set @ErrorCode=0
set @bTempCasesLoaded=0
set @bTempCasesSorted=0
set @bGetInstructions=0
set @pbPagingApplied =0
set @bProvideInstructionsRequired=0
set @bFeesRequired=0
set @sAddWhereString  = ''
set @sLookupCulture   = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation 
-- from the database
If datalength(@ptXMLOutputRequests) = 0
or datalength(@ptXMLOutputRequests) is null
Begin
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 2)

	Insert into @tblOutputRequests (ID,SORTORDER,PUBLISHNAME,QUALIFIER,DOCITEMKEY,COLUMNNAME,DATATYPE,CALLFEESCALC,LISTCHARGES)
	Select F.COLUMNID, F.SORTORDER, F.PUBLISHNAME, F.QUALIFIER, F.DOCITEMKEY,
	CASE WHEN(F.COLUMNID in 
		       ('InstructionBillCurrencyAny',
			'InstructionCycleAny',
			'InstructionDefinitionAny',
			'InstructionDefinitionKeyAny',
			'InstructionDueDateAny',
			'InstructionDueEventAny',
			'InstructionIsPastDueAny',
			'InstructionExplanationAny',
			'InstructionFeeBilledAny',
			'ChargeDueEventAny',
			'FeesChargeTypeAny',
			'FeeBillCurrencyAny',
			'FeeBilledAmountAny',
			'FeeBilledPerYearAny',
			'FeeDueDateAny',
			'FeeYearNoAny'))
		THEN F.COLUMNID
		ELSE '['+F.PUBLISHNAME+']'
	END,
	CASE(Q.DATAFORMATID)
		WHEN(9100) THEN 'nvarchar(255)'
		WHEN(9101) THEN 'int'
		WHEN(9102) THEN 'decimal(11,'+convert(varchar,isnull(Q.DECIMALPLACES,0))+')'
		WHEN(9103) THEN 'datetime'
		WHEN(9104) THEN 'datetime'
		WHEN(9105) THEN 'datetime'
		WHEN(9106) THEN 'bit'
		WHEN(9107) THEN 'nvarchar(max)'
		WHEN(9108) THEN 'decimal(11,2)'
		WHEN(9109) THEN 'decimal(11,2)'
		WHEN(9110) THEN 'int'
		WHEN(9111) THEN 'image'
		WHEN(9112) THEN 'nvarchar(100)'
		WHEN(9113) THEN 'nvarchar(100)'
	END, 
	CASE WHEN(Q.QUALIFIERTYPE=12) THEN 1 ELSE 0 END,
	-- Identify the column requests that require the
	-- cs_ListCaseCharges procedure to be called
	CASE WHEN(F.COLUMNID in 
		       ('InstructionBillCurrencyAny',
			'InstructionCycleAny',
			'InstructionDefinitionAny',
			'InstructionDefinitionKeyAny',
			'InstructionDueDateAny',
			'InstructionDueEventAny',
			'InstructionIsPastDueAny',
			'InstructionExplanationAny',
			'InstructionFeeBilledAny',
			'ChargeDueEventAny',
			'FeesChargeTypeAny'))		
		THEN 2
	     WHEN(F.COLUMNID in 
		       ('InstructionBillCurrencyAny',
			'InstructionFeeBilledAny',
			'FeeBillCurrencyAny',
			'FeeBilledAmountAny',
			'FeeBilledPerYearAny',
			'FeeDueDateAny',
			'FeeYearNoAny'))		
		THEN 1 
		ELSE 0
	END
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null) F
	join QUERYDATAITEM Q	on (Q.PROCEDURENAME='csw_ListCase'
				and Q.PROCEDUREITEMID=F.COLUMNID)
	where Q.QUALIFIERTYPE=12  -- indicates FEESCALC to be called
	OR F.DOCITEMKEY is not null
	OR F.COLUMNID in 
		       ('InstructionBillCurrencyAny',
			'InstructionCycleAny',
			'InstructionDefinitionAny',
			'InstructionDefinitionKeyAny',
			'InstructionDueDateAny',
			'InstructionDueEventAny',
			'InstructionIsPastDueAny',
			'InstructionExplanationAny',
			'InstructionFeeBilledAny',
			'ChargeDueEventAny',
			'FeesChargeTypeAny',
			'FeeBillCurrencyAny',
			'FeeBilledAmountAny',
			'FeeBilledPerYearAny',
			'FeeDueDateAny',
			'FeeYearNoAny')
	Order by
	CASE WHEN(F.COLUMNID in 
		       ('InstructionCycleAny',
			'InstructionDefinitionAny',
			'InstructionDefinitionKeyAny',
			'InstructionDueDateAny',
			'InstructionDueEventAny',
			'InstructionIsPastDueAny',
			'InstructionExplanationAny',
			'ChargeDueEventAny',
			'FeesChargeTypeAny'))		
		THEN 2
	     WHEN(F.COLUMNID in 
		       ('InstructionBillCurrencyAny',
			'InstructionFeeBilledAny',
			'FeeBillCurrencyAny',
			'FeeBilledAmountAny',
			'FeeBilledPerYearAny',
			'FeeDueDateAny',
			'FeeYearNoAny'))		
		THEN 1 
		ELSE 0
	END

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End
Else Begin
	--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ID,SORTORDER,PUBLISHNAME,QUALIFIER,DOCITEMKEY,COLUMNNAME,DATATYPE,CALLFEESCALC,LISTCHARGES)
	Select F.COLUMNID, F.SORTORDER, F.PUBLISHNAME, F.QUALIFIER, F.DOCITEMKEY,
	CASE WHEN(F.COLUMNID in 
		       ('InstructionBillCurrencyAny',
			'InstructionCycleAny',
			'InstructionDefinitionAny',
			'InstructionDefinitionKeyAny',
			'InstructionDueDateAny',
			'InstructionDueEventAny',
			'InstructionIsPastDueAny',
			'InstructionExplanationAny',
			'InstructionFeeBilledAny',
			'ChargeDueEventAny',
			'FeesChargeTypeAny',
			'FeeBillCurrencyAny',
			'FeeBilledAmountAny',
			'FeeBilledPerYearAny',
			'FeeDueDateAny',
			'FeeYearNoAny'))
		THEN F.COLUMNID
		ELSE '['+F.PUBLISHNAME+']'
	END,
	CASE(Q.DATAFORMATID)
		WHEN(9100) THEN 'nvarchar(255)'
		WHEN(9101) THEN 'int'
		WHEN(9102) THEN 'decimal(11,'+convert(varchar,isnull(Q.DECIMALPLACES,0))+')'
		WHEN(9103) THEN 'datetime'
		WHEN(9104) THEN 'datetime'
		WHEN(9105) THEN 'datetime'
		WHEN(9106) THEN 'bit'
		WHEN(9107) THEN 'nvarchar(max)'
		WHEN(9108) THEN 'decimal(11,2)'
		WHEN(9109) THEN 'decimal(11,2)'
		WHEN(9110) THEN 'int'
		WHEN(9111) THEN 'image'
		WHEN(9112) THEN 'nvarchar(100)'
		WHEN(9113) THEN 'nvarchar(100)'
		WHEN(9117) THEN 'nvarchar(max)' 
	END, 
	CASE WHEN(Q.QUALIFIERTYPE=12) THEN 1 ELSE 0 END,
	-- Identify the column requests that require the
	-- cs_ListCaseCharges procedure to be called
	CASE WHEN(F.COLUMNID in 
		       ('InstructionBillCurrencyAny',
			'InstructionFeeBilledAny',
			'FeeBillCurrencyAny',
			'FeeBilledAmountAny',
			'FeeBilledPerYearAny',
			'FeeDueDateAny',
			'FeeYearNoAny'))		
		THEN 1 
		ELSE 0
	END
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null) F
	join QUERYDATAITEM Q	on (Q.PROCEDURENAME='csw_ListCase'
				and Q.PROCEDUREITEMID=F.COLUMNID)
	where Q.QUALIFIERTYPE=12  -- indicates that FEESCALC is to be called
	OR F.DOCITEMKEY is not null
	OR F.COLUMNID in 
		       ('InstructionBillCurrencyAny',
			'InstructionCycleAny',
			'InstructionDefinitionAny',
			'InstructionDefinitionKeyAny',
			'InstructionDueDateAny',
			'InstructionDueEventAny',
			'InstructionIsPastDueAny',
			'InstructionExplanationAny',
			'InstructionFeeBilledAny',
			'ChargeDueEventAny',
			'FeesChargeTypeAny',
			'FeeBillCurrencyAny',
			'FeeBilledAmountAny',
			'FeeBilledPerYearAny',
			'FeeDueDateAny',
			'FeeYearNoAny')
	Order by 
	CASE WHEN(F.COLUMNID in 
		       ('InstructionCycleAny',
			'InstructionDefinitionAny',
			'InstructionDefinitionKeyAny',
			'InstructionDueDateAny',
			'InstructionDueEventAny',
			'InstructionIsPastDueAny',
			'InstructionExplanationAny',
			'ChargeDueEventAny',
			'FeesChargeTypeAny'))		
		THEN 2
	     WHEN(F.COLUMNID in 
		       ('InstructionBillCurrencyAny',
			'InstructionFeeBilledAny',
			'FeeBillCurrencyAny',
			'FeeBilledAmountAny',
			'FeeBilledPerYearAny',
			'FeeDueDateAny',
			'FeeYearNoAny'))		
		THEN 1 
		ELSE 0
	END
	
	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End

---------------------------------------------
-- Extract any filter criteria required for
-- Instruction or Fee columns.  This is done
-- deliberately outside of the filter that
-- returns Cases
---------------------------------------------
-- RFC2982 Provide Instructions filter criteria
If PATINDEX ('%<ProvideInstructions>%', @ptXMLFilterCriteria)>0
and @ErrorCode=0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria 	-- Retrieve the Instruction related parameters

	Set @sSQLString = 	
	"Select @bInstructionsForMultiCase	= isnull(IsMultiCase,0),"+CHAR(10)+
	"	@bInstructionsForSingleCase	= isnull(IsSingleCase,0),"+CHAR(10)+
	"	@bInstructionsForDueEvent	= isnull(IsDueEvent,0),"+CHAR(10)+
	"	@bIncludeUnknownDueDates	= IncludeUnknown,"+CHAR(10)+
	"	@nDateRangeOperator		= DateRangeOperator,"+char(10)+
	"	@dtDateRangeFrom		= DateRangeFrom,"+char(10)+
	"	@dtDateRangeTo			= DateRangeTo,"+char(10)+
	"	@nPeriodRangeOperator		= PeriodRangeOperator,"+CHAR(10)+
	"	@sPeriodRangeType		= PeriodRangeType,"+CHAR(10)+
	"	@nPeriodRangeFrom		= PeriodRangeFrom,"+CHAR(10)+
	"	@nPeriodRangeTo			= PeriodRangeTo,"+CHAR(10)+
	"	@nInstructionDefinitionOperator	= InstructionDefinitionOperator,"+CHAR(10)+
	"	@nInstructionDefinitionKey	= InstructionDefinitionKey,"+CHAR(10)+
	"	@nDueEventCaseKey		= DueEventCaseKey,"+CHAR(10)+
	"	@nDueEventKey			= DueEventKey,"+CHAR(10)+
	"	@nDueEventCycle			= DueEventCycle,"+CHAR(10)+
	"	@nReminderEmployeeKey		= ReminderEmployeeKey,"+char(10)+
	"	@dtReminderDateCreated		= ReminderDateCreated"+char(10)+
	"from	OPENXML (@idoc, '/csw_ListCase/ColumnFilterCriteria/ProvideInstructions',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      IsMultiCase		bit		'AvailabilityFlags/IsMultiCase/text()',"+CHAR(10)+
	"	      IsSingleCase		bit		'AvailabilityFlags/IsSingleCase/text()',"+CHAR(10)+
	"	      IsDueEvent		bit		'AvailabilityFlags/IsDueEvent/text()',"+CHAR(10)+
	"	      IncludeUnknown		bit		'DueDates/@IncludeUnknown',"+CHAR(10)+
	"	      DateRangeOperator		tinyint		'DueDates/DateRange/@Operator/text()',"+char(10)+
	"	      DateRangeFrom		datetime	'DueDates/DateRange/From/text()',"+char(10)+
	"	      DateRangeTo		datetime	'DueDates/DateRange/To/text()',"+char(10)+
	"	      PeriodRangeOperator	tinyint		'DueDates/PeriodRange/@Operator/text()',"+char(10)+
	"	      PeriodRangeType		nchar(1)	'DueDates/PeriodRange/Type/text()',"+CHAR(10)+
	"	      PeriodRangeFrom		smallint	'DueDates/PeriodRange/From/text()',"+CHAR(10)+
	"	      PeriodRangeTo		smallint	'DueDates/PeriodRange/To/text()',"+CHAR(10)+
	"	      InstructionDefinitionOperator tinyint	'InstructionDefinitionKey/@Operator/text()',"+CHAR(10)+
	"	      InstructionDefinitionKey	int		'InstructionDefinitionKey/text()',"+CHAR(10)+
	"	      DueEventCaseKey		int		'DueEvent/CaseKey/text()',"+CHAR(10)+
	"	      DueEventKey		int		'DueEvent/EventKey/text()',"+CHAR(10)+
	"	      DueEventCycle		smallint	'DueEvent/Cycle/text()',"+CHAR(10)+
	"	      ReminderEmployeeKey	int		'Reminder/EmployeeKey/text()',"+CHAR(10)+
	"	      ReminderDateCreated	datetime	'Reminder/ReminderDateCreated/text()'"+CHAR(10)+
     	"	     )"

	exec @ErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @bInstructionsForMultiCase	bit		output,
				  @bInstructionsForSingleCase	bit		output,
				  @bInstructionsForDueEvent	bit		output,
				  @bIncludeUnknownDueDates	bit		output,
				  @nDateRangeOperator		tinyint		output,
				  @dtDateRangeFrom		datetime	output,
				  @dtDateRangeTo		datetime	output,
				  @nPeriodRangeOperator		tinyint		output,
				  @sPeriodRangeType		nchar(1)	output,
				  @nPeriodRangeFrom		smallint	output,
				  @nPeriodRangeTo		smallint	output,
				  @nInstructionDefinitionOperator tinyint		output,
				  @nInstructionDefinitionKey	int		output,
				  @nDueEventCaseKey		int		output,
				  @nDueEventKey			int		output,
				  @nDueEventCycle		smallint	output,
				  @nReminderEmployeeKey		int		output,
				  @dtReminderDateCreated	datetime	output',
				  @idoc				= @idoc,
				  @bInstructionsForMultiCase	= @bInstructionsForMultiCase		output,
				  @bInstructionsForSingleCase	= @bInstructionsForSingleCase		output,
				  @bInstructionsForDueEvent	= @bInstructionsForDueEvent		output,
				  @bIncludeUnknownDueDates	= @bIncludeUnknownDueDates		output,
				  @nDateRangeOperator		= @nInstructionsDateRangeOperator	output,
				  @dtDateRangeFrom		= @dtInstructionsDateRangeFrom		output,
				  @dtDateRangeTo		= @dtInstructionsDateRangeTo		output,
				  @nPeriodRangeOperator		= @nInstructionsPeriodRangeOperator	output,
				  @sPeriodRangeType		= @sInstructionsPeriodRangeType		output,
				  @nPeriodRangeFrom		= @nInstructionsPeriodRangeFrom		output,
				  @nPeriodRangeTo		= @nInstructionsPeriodRangeTo		output,
				  @nInstructionDefinitionOperator = @nInstructionDefinitionOperator	output,
				  @nInstructionDefinitionKey	= @nInstructionDefinitionKey		output,
				  @nDueEventCaseKey		= @nDueEventCaseKey			output,
				  @nDueEventKey			= @nDueEventKey				output,
				  @nDueEventCycle		= @nDueEventCycle			output,
				  @nReminderEmployeeKey		= @nReminderEmployeeKey			output,
				  @dtReminderDateCreated	= @dtReminderDateCreated		output

	If (@bInstructionsForMultiCase|@bInstructionsForSingleCase|@bInstructionsForDueEvent=1)
	Begin
		Set @bProvideInstructionsRequired=1
	End
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End

-- RFC2982 Fees filter criteria
If PATINDEX ('%<Fees>%', @ptXMLFilterCriteria)>0
and @ErrorCode=0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria 	-- Retrieve the Fees related parameters

	Set @sSQLString = 	
	"Select @bUntilExpiry			= IsUntilExpiry,"+CHAR(10)+
	"	@nDateRangeOperator		= DateRangeOperator,"+char(10)+
	"	@dtDateRangeFrom		= DateRangeFrom,"+char(10)+
	"	@dtDateRangeTo			= DateRangeTo,"+char(10)+
	"	@nPeriodRangeOperator		= PeriodRangeOperator,"+CHAR(10)+
	"	@sPeriodRangeType		= PeriodRangeType,"+CHAR(10)+
	"	@nPeriodRangeFrom		= PeriodRangeFrom,"+CHAR(10)+
	"	@nPeriodRangeTo			= PeriodRangeTo,"+CHAR(10)+
	"	@nChargeTypeOperator		= ChargeTypeOperator,"+CHAR(10)+
	"	@nChargeTypeKey			= ChargeTypeKey"+CHAR(10)+
	"from	OPENXML (@idoc, '/csw_ListCase/ColumnFilterCriteria/Fees',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      IsUntilExpiry		bit		'Dates/@IsUntilExpiry',"+CHAR(10)+
	"	      DateRangeOperator		tinyint		'Dates/DateRange/@Operator/text()',"+char(10)+
	"	      DateRangeFrom		datetime	'Dates/DateRange/From/text()',"+char(10)+
	"	      DateRangeTo		datetime	'Dates/DateRange/To/text()',"+char(10)+
	"	      PeriodRangeOperator	tinyint		'Dates/PeriodRange/@Operator/text()',"+char(10)+
	"	      PeriodRangeType		nchar(1)	'Dates/PeriodRange/Type/text()',"+CHAR(10)+
	"	      PeriodRangeFrom		smallint	'Dates/PeriodRange/From/text()',"+CHAR(10)+
	"	      PeriodRangeTo		smallint	'Dates/PeriodRange/To/text()',"+CHAR(10)+
	"	      ChargeTypeOperator 	tinyint		'ChargeTypeKey/@Operator/text()',"+CHAR(10)+
	"	      ChargeTypeKey		int		'ChargeTypeKey/text()'"+CHAR(10)+
     	"	     )"

	exec @ErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @bUntilExpiry			bit		output,
				  @nDateRangeOperator		tinyint		output,
				  @dtDateRangeFrom		datetime	output,
				  @dtDateRangeTo		datetime	output,
				  @nPeriodRangeOperator		tinyint		output,
				  @sPeriodRangeType		nchar(1)	output,
				  @nPeriodRangeFrom		smallint	output,
				  @nPeriodRangeTo		smallint	output,
				  @nChargeTypeOperator 		tinyint		output,
				  @nChargeTypeKey		int		output',
				  @idoc				= @idoc,
				  @bUntilExpiry			= @bUntilExpiry			output,
				  @nDateRangeOperator		= @nFeesDateRangeOperator	output,
				  @dtDateRangeFrom		= @dtFeesDateRangeFrom		output,
				  @dtDateRangeTo		= @dtFeesDateRangeTo		output,
				  @nPeriodRangeOperator		= @nFeesPeriodRangeOperator	output,
				  @sPeriodRangeType		= @sFeesPeriodRangeType		output,
				  @nPeriodRangeFrom		= @nFeesPeriodRangeFrom		output,
				  @nPeriodRangeTo		= @nFeesPeriodRangeTo		output,
				  @nChargeTypeOperator 		= @nChargeTypeOperator		output,
				  @nChargeTypeKey		= @nChargeTypeKey		output
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End

-- If we need to get extended details then every Case that will be returned by the constructed Case filter
-- must be loaded into a global temporary table.  A temporary table may already exist to hold the penultimate
-- result set which must now be combined with the final filter to get the final list of Cases.  A second table
-- will be required to achieve this.
If @nOutRequestsRowCount>0
and @ErrorCode=0
Begin
	-- If the user is external then the Cases to be reported will stored in a table variable.
	-- This is a performance improvement because the functions that restrict Cases to external
	-- users degrades in performance as the SQL becomes more complex.

	-- Get the name of the temporary table passed in as a parameter and derive a Result Table name 
	If @psTempTableName is null
	Begin
		Set @sResultTable  = '##SEARCHCASE_' + Cast(@@SPID as varchar(10))+'_RESULT'
	End
	Else Begin		
		Set @sResultTable =@psTempTableName+'_RESULT'
	End

	-- Generate the Create statement for the global temporary table to hold the final list of Cases
	Set @sSQLString=null

	select @sSQLString=ISNULL(NULLIF(@sSQLString + ','+char(10), ','+char(10)),'') 
			   + COLUMNNAME+CHAR(9)+DATATYPE+CASE WHEN(DATATYPE like '%char%') THEN ' collate database_default' END+' NULL'
	from @tblOutputRequests

	-- Ensure the column InstructionCycleAny is included in the table if either of
	-- InstructionFeeBilledAny or InstructionBillCurrencyAny exists

	If   PATINDEX ('%InstructionCycleAny%',       @sSQLString)=0
	and (PATINDEX ('%InstructionFeeBilledAny%',   @sSQLString)>0
	 or  PATINDEX ('%InstructionBillCurrencyAny%',@sSQLString)>0)
		Set @sSQLString=@sSQLString+','+char(10)+'InstructionCycleAny	smallint NULL'

	set @sSQLString='Create table '+@sResultTable+'('
		+char(10)+'CASEID	int not null,'
		+char(10)+'SEQUENCENO	int null,'
		+char(10)+'ROWNUMBER	int	identity(1,1),'
		+char(10)+'IGNOREFLAG	bit	default(0),'
		+char(10)+'IRN		nvarchar(30) collate database_default null,'
		+char(10)+@sSQLString

	-- If details relating to user instructions are required then
	-- also get the CHARGETYPENO
	If exists(select 1 from @tblOutputRequests
		  where ID in  ('InstructionBillCurrencyAny',
				'InstructionCycleAny',
				'InstructionDefinitionAny',
				'InstructionDefinitionKeyAny',
				'InstructionDueDateAny',
				'InstructionDueEventAny',
				'InstructionIsPastDueAny',
				'InstructionExplanationAny',
				'InstructionFeeBilledAny') )
	Begin
		Set @bGetInstructions=1
		Set @sSQLString=@sSQLString+','+char(10)+'CHARGETYPENO	int null,'
					       +char(10)+'DEFINITIONID	int null'
					       +char(10)+'UNIQUE (CASEID, CHARGETYPENO, ROWNUMBER) )'	
	End
	Else If exists(select 1 from @tblOutputRequests
		  where ID in  ('ChargeDueEventAny',
				'FeeBillCurrencyAny',
				'FeeBilledAmountAny',
				'FeeBilledPerYearAny',
				'FeeDueDateAny',
				'FeesChargeTypeAny',
				'FeeYearNoAny') )
	Begin
		Set @bFeesRequired=1

		Set @sSQLString=@sSQLString+','+char(10)+'CHARGETYPENO	int null'
					       +char(10)+'UNIQUE (CASEID, CHARGETYPENO'

		If exists(select 1 from @tblOutputRequests
			  where ID = 'FeeYearNoAny')
			Set @sSQLString=@sSQLString+', FeeYearNoAny'	

		If exists(select 1 from @tblOutputRequests
			  where ID = 'FeeDueDateAny')
			Set @sSQLString=@sSQLString+', FeeDueDateAny'

		Set @sSQLString=@sSQLString+', ROWNUMBER) )'	
	End
	Else Begin
		Set @sSQLString=@sSQLString+char(10)+'UNIQUE(CASEID, ROWNUMBER) )'
	End

	If @pbPrintSQL=1
		Print @sSQLString

	exec @ErrorCode=sp_executesql @sSQLString

	-------------------------------------------------------------------------------------
	-- If a page limitation is set then only a subset of data will ultimately be returned
	-- to the front end calling program.  Extraction of the extended Case details will 
	-- run faster if only the actual Cases to be returned are extended.
	-- In order to determine what Cases are to be returned within the page limitation the
	-- Check to see if any of the extended Case columns have also been included in the 
	-- entire result set first needs to be extracted and sorted into the desired order.
	-- If any of the extended Case columns are included in the sort order then the entire
	-- result will need to have the extended columns extracted so they can be included in
	-- the ORDER BY clause.
	-- So if the extended Case columns are NOT included in the Sort Order and a page 
	-- limitation applies, then get the interim ordered result set.
	-------------------------------------------------------------------------------------
	If  @ErrorCode=0
	and @pnPageStartRow is not null
	and @pnPageEndRow   is not null
	and not exists (select 1 from @tblOutputRequests 
			where SORTORDER is not null
			and ID not in (	'FeeDueDateAny',
					'FeeBillCurrencyAny',
					'FeeBilledAmountAny',
					'FeeBilledPerYearAny',
					'FeeDueDateAny',
					'FeesChargeTypeAny',
					'FeeYearNoAny'))
	-- cannot pre-sort results if UNION is used
	and not exists (select 1 from #TempConstructSQL
			where ComponentType='V')
	Begin
		exec @ErrorCode=dbo.csw_LoadSortedResult
					@pnRowCount		=@nTempCases	OUTPUT,
					@psWhereFilter		=@psWhereFilter,
					@psTempTableName	=@psTempTableName,
					@pbGetInstructions	=@bGetInstructions,
					@pnUserIdentityId	=@pnUserIdentityId,
					@pbExternalUser		=@pbExternalUser,
					@pbPrintSQL		=@pbPrintSQL

		Set @bTempCasesLoaded=1
		Set @bTempCasesSorted=1

		-- The Where filter can be cleared out because the 
		-- results are now held in #TEMPCASES
		Set @psWhereFilter=null
	End

	-- Now load the result temporary table with all of the Cases to be reported on
	If @ErrorCode=0
	Begin
		If  @bGetInstructions=0
		and @bFeesRequired=0
		Begin
			Set @sSQLString = "insert into "+@sResultTable+" (CASEID, IRN, SEQUENCENO)"

			If @bTempCasesLoaded=1
			Begin
				Set @sSQLSelect = "select distinct C.CASEID, C.IRN, TC.SEQUENCENO" +char(10)+
						  "from #TEMPCASES TC"+char(10)+
						  "join CASES C on (C.CASEID=TC.CASEID)"
			End
			Else Begin
				Set @sSQLSelect = "select distinct C.CASEID, C.IRN, null" +char(10)+
						  "from CASES C"
			End
		End

		-- If the user is external and the Cases have not already been loaded into a temp table
		-- then the Cases to be reported will be loaded in a temporary table.
		-- This is a performance improvement because the functions that restrict Cases to external
		-- users degrades in performance as the SQL becomes more complex.
		Else If  @pbExternalUser=1
		     and @bTempCasesLoaded=0
		Begin
			Set @sLoadCases=replace(substring(@psWhereFilter,
							  CHARINDEX('join #TEMPCASESEXT XFC',@psWhereFilter) - 2, -- locate the starting position subtracting 2 for line feed and tab
							  len(@psWhereFilter)),
							  'and XC.CASEID=C.CASEID)','')

			Set @sLoadCases='Insert into #TEMPCASES(CASEID)'+char(10)+
					'Select distinct XC.CASEID'+char(10)+
					'from CASES XC'+
					CASE WHEN(@bGetInstructions=1)
						THEN char(10)+
						     'cross join INSTRUCTIONDEFINITION IND'+char(10)+
						     'join CASENAME CN	on (CN.CASEID=XC.CASEID'+char(10)+
						     '			and CN.NAMETYPE=IND.INSTRUCTNAMETYPE)'+char(10)+
						     'join dbo.fn_FilterUserNames('+convert(varchar,@pnUserIdentityId)+',1) INUN	on (INUN.NAMENO=CN.NAMENO)'
					END
					+char(10)+@sLoadCases

			If @pbPrintSQL = 1
			Begin
				Print ''
				Print @sLoadCases
			End

			exec @ErrorCode=sp_executesql @sLoadCases
	
			Set @nTempCases=@@rowcount
			Set @bTempCasesLoaded=1

			-- The Where filter can be cleared out because the 
			-- results are now held in #TEMPCASES
			Set @psWhereFilter=null
		End

		-------------------------------
		-- Prepare SQL for getting fees
		-- and charges for a range of
		-- charge types
		-------------------------------
		If @bFeesRequired=1
		and @ErrorCode=0
		Begin
			Set @sSQLString = "insert into "+@sResultTable+" (CASEID, IRN, SEQUENCENO, CHARGETYPENO"			
			
			-- Restricted to a previously resolved
			-- list of Cases held in a temporary table
			If @bTempCasesLoaded=1
			Begin
				Set @sSQLSelect = "select distinct C.CASEID, C.IRN, TC.SEQUENCENO, FC.CHARGETYPENO"

				Set @sSQLFrom="from #TEMPCASES TC"+char(10)+
					      "join CASES C on (C.CASEID=TC.CASEID)"
			End
			Else Begin
				Set @sSQLSelect = "select distinct C.CASEID, C.IRN, NULL, FC.CHARGETYPENO"

				Set @sSQLFrom="from CASES C"
			End
	
			If @pbExternalUser=1
			Begin
				-- External users may only view a specific list of charge types
				-- Create a comma separated list of the charge types
				Set @sList = ''
				Select 	@sList = @sList + nullif(',', ',' + @sList) + cast(C.CHARGETYPENO as nvarchar(12))
				From dbo.fn_FilterUserChargeTypes(@pnUserIdentityId,null, 1,@pbCalledFromCentura) C
				join CHARGETYPE CT on (CT.CHARGETYPENO=C.CHARGETYPENO)

				Set @sSQLFrom = @sSQLFrom
					+char(10)+"join CHARGETYPE FC		on (FC.CHARGETYPENO in ("+CASE WHEN(@sList='') THEN 'null' ELSE @sList END+"))"
			End
			Else Begin
				Set @sSQLFrom = @sSQLFrom
					+char(10)+"cross join CHARGETYPE FC"
			End
			
			-- Charge must be associated with a due event (either due or occurred)
			-- If the CASEEVENT has not occurred then it must be associated with
			-- an OPENACTION
			-- This may be further qualified by date range filter criteria
			Set @sSQLFrom = @sSQLFrom
				+char(10)+"join CASEEVENT CE on (CE.CASEID=C.CASEID"
				+char(10)+"                  and CE.EVENTNO=FC.CHARGEDUEEVENT)"
				--------------------------------------------------------
				-- RFC12399
				-- If the fee is being triggered by a due date then the
				-- Event must be attached to an open action
				--------------------------------------------------------
				+CHAR(10)+"join EVENTS E     on (E.EVENTNO=CE.EVENTNO)"
				+CHAR(10)+"left join OPENACTION OA   on (OA.CASEID=CE.CASEID"
				+CHAR(10)+"                          and OA.POLICEEVENTS=1)"
				+CHAR(10)+"left join EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO"
				+CHAR(10)+"                          and EC.EVENTNO   =E.EVENTNO)"
				+CHAR(10)+"left join ACTIONS A       on (A.ACTION=OA.ACTION)"

			Set @sColumnName=null

			Select @sColumnName=COLUMNNAME
			from @tblOutputRequests
			where ID = 'FeesChargeTypeAny'

			If @sColumnName is not null
			Begin
				Set @sSQLString = @sSQLString + ", "+@sColumnName
	
				Set @sSQLSelect = @sSQLSelect + ", "+dbo.fn_SqlTranslatedColumn('CHARGETYPE','CHARGEDESC',null,'FC',@sLookupCulture,@pbCalledFromCentura)
				Set @sColumnName=null
			End

			Select @sColumnName=COLUMNNAME
			from @tblOutputRequests
			where ID = 'ChargeDueEventAny'

			If @sColumnName is not null
			Begin
				Set @sSQLString = @sSQLString + ", "+@sColumnName
	
				Set @sSQLSelect = @sSQLSelect + ', isnull('+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'FEC',@sLookupCulture,@pbCalledFromCentura)
										 +','+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'FE',@sLookupCulture,@pbCalledFromCentura)+')'

				Set @sSQLFrom = @sSQLFrom
					+char(10)+"left join CASEEVENT FD	on (FD.CASEID=C.CASEID"
					+char(10)+"				and FD.EVENTNO=FC.CHARGEDUEEVENT"
					+char(10)+"				and FD.CYCLE = (select max(FD2.CYCLE)"
					+char(10)+"						from CASEEVENT FD2"
					+char(10)+"						where FD2.CASEID=FD.CASEID"
					+char(10)+"						and   FD2.EVENTNO=FD.EVENTNO))"
					+char(10)+"left join EVENTS FE		on (FE.EVENTNO=FD.EVENTNO)"
					+char(10)+"left join EVENTCONTROL FEC	on (FEC.CRITERIANO=FD.CREATEDBYCRITERIA"
					+char(10)+"				and FEC.EVENTNO=FD.EVENTNO)"
				Set @sColumnName=null
			End
		
			Set @sSQLString=@sSQLString+')'
		End

		------------------------------------------
		-- Prepare SQL for getting fees associated
		-- with user entered instructions
		------------------------------------------
		Else If @bGetInstructions=1
		     and @ErrorCode=0
		Begin
			Set @sSQLString = "insert into "+@sResultTable+" (CASEID, IRN, SEQUENCENO, CHARGETYPENO, DEFINITIONID"

			If @bTempCasesLoaded=1
			Begin
				Set @sSQLSelect = "select C.CASEID, C.IRN, TC.SEQUENCENO, IND.CHARGETYPENO, IND.DEFINITIONID"

				-- Restricted to a previously resolved
				-- list of Cases held in a temporary table
				Set @sSQLFrom="from #TEMPCASES TC"+char(10)+
					      "join CASES C on (C.CASEID=TC.CASEID)"
			End
			Else Begin
				Set @sSQLSelect = "select C.CASEID, C.IRN, NULL, IND.CHARGETYPENO, IND.DEFINITIONID"

				Set @sSQLFrom="from CASES C"
			End

			Set @sSQLSelectUnion = @sSQLSelect

			Set @sSQLFromUnion=@sSQLFrom

			Set @sSQLFrom=@sSQLFrom
				+char(10)+"join CASEINSTRUCTALLOWED CI    on (CI.CASEID=C.CASEID)"
				+char(10)+"join INSTRUCTIONDEFINITION IND on (IND.DEFINITIONID=CI.DEFINITIONID"
				+char(10)+"                               and IND.PREREQUISITEEVENTNO=CI.EVENTNO)"

			-- Found a significant performance improvement if a specific
			-- index is specified for external user queries
			-- Would have preferred to let the optimiser work out the best index
			-- however it was consistently making a bad choice.
			If @pbExternalUser=1
				Set @sSQLFrom=@sSQLFrom
				-- Locate the driving case event
				+char(10)+"Join CASEEVENT INCE with(INDEX(XPKCASEEVENT)) on (INCE.CASEID=CI.CASEID"
				+char(10)+"                                              and INCE.EVENTNO=CI.EVENTNO"
				+char(10)+"                                              and INCE.CYCLE=CI.CYCLE)"
			Else
				Set @sSQLFrom=@sSQLFrom
				-- Locate the driving case event
				+char(10)+"Join CASEEVENT INCE on (INCE.CASEID=CI.CASEID"
				+char(10)+"                    and INCE.EVENTNO=CI.EVENTNO"
				+char(10)+"                    and INCE.CYCLE=CI.CYCLE)"

			-- For the ProvideInstructions range of columns a UNION is required
			-- to ensure that only appropriate instructions are returned.  The UNION
			-- allows us to avoid the use of an OR which was causing significant 
			-- performance issues.

			Set @sSQLFromUnion=@sSQLFromUnion
				+char(10)+"join CASEINSTRUCTALLOWED CI    on (CI.CASEID=C.CASEID)"
				+char(10)+"join INSTRUCTIONDEFINITION IND on (IND.DEFINITIONID=CI.DEFINITIONID)"
				+char(10)+"join EVENTS INDE		  on (INDE.EVENTNO=IND.DUEEVENTNO)"

			-- Found a significant performance improvement if a specific
			-- index is specified for external user queries
			-- Would have preferred to let the optimiser work out the best index
			-- however it was consistently making a bad choice.
			If @pbExternalUser=1
				Set @sSQLFromUnion=@sSQLFromUnion
				+char(10)+"join CASEEVENT INDCE with(INDEX(XPKCASEEVENT)) on (INDCE.CASEID=C.CASEID"
				+char(10)+"                                               and INDCE.EVENTNO=IND.DUEEVENTNO"
				+char(10)+"                                               and INDCE.CYCLE=CI.CYCLE)"
				+char(10)+"left join EVENTCONTROL INEC on (INEC.CRITERIANO=INDCE.CREATEDBYCRITERIA"
				+char(10)+"                            and INEC.EVENTNO=INDCE.EVENTNO)"
			Else
				Set @sSQLFromUnion=@sSQLFromUnion
				+char(10)+"join CASEEVENT INDCE		  on (INDCE.CASEID=C.CASEID"
				+char(10)+"				  and INDCE.EVENTNO=INDE.EVENTNO"
				+char(10)+"				  and INDCE.CYCLE=CI.CYCLE)"
				+char(10)+"left join EVENTCONTROL INEC	  on (INEC.CRITERIANO=INDCE.CREATEDBYCRITERIA"
				+char(10)+"				  and INEC.EVENTNO=INDCE.EVENTNO)"

			Set @sColumnName=null

			-- The cycle is required in the interim table if any of the listed
			-- columns is included in the output.  Even if the Cycle is not being
			-- displayed in the output it will be used to align the extracted data
			-- with the fees being calculated.

			If exists (Select 1
				   from @tblOutputRequests
				   where ID in ('InstructionCycleAny',
						'InstructionFeeBilledAny',
						'InstructionBillCurrencyAny') )

			Begin
				Set @sSQLString = @sSQLString + ", InstructionCycleAny"

				Set @sSQLSelect      = @sSQLSelect + ", CI.CYCLE"
				Set @sSQLSelectUnion = @sSQLSelect
			End

			Select @sColumnName=COLUMNNAME
			from @tblOutputRequests
			where ID = 'InstructionDefinitionAny'

			If @sColumnName is not null
			Begin
				Set @sSQLString = @sSQLString + ", "+@sColumnName
	
				Set @sSQLSelect      = @sSQLSelect + ", "+dbo.fn_SqlTranslatedColumn('INSTRUCTIONDEFINITION','INSTRUCTIONNAME',null,'IND',@sLookupCulture,@pbCalledFromCentura)
				Set @sSQLSelectUnion = @sSQLSelect
				Set @sColumnName=null
			End

			Select @sColumnName=COLUMNNAME
			from @tblOutputRequests
			where ID = 'InstructionDefinitionKeyAny'

			If @sColumnName is not null
			Begin
				Set @sSQLString = @sSQLString + ", "+@sColumnName
	
				Set @sSQLSelect      = @sSQLSelect + ", IND.DEFINITIONID"
				Set @sSQLSelectUnion = @sSQLSelect
				Set @sColumnName     = null
			End

			Select @sColumnName=COLUMNNAME
			from @tblOutputRequests
			where ID = 'InstructionExplanationAny'

			If @sColumnName is not null
			Begin
				Set @sSQLString = @sSQLString + ", "+@sColumnName
	
				Set @sSQLSelect      = @sSQLSelect + ", "+dbo.fn_SqlTranslatedColumn('INSTRUCTIONDEFINITION','EXPLANATION',null,'IND',@sLookupCulture,@pbCalledFromCentura)
				Set @sSQLSelectUnion = @sSQLSelect
				Set @sColumnName     = null
			End

			If exists(select 1 from @tblOutputRequests
				  where ID in  ('InstructionDueDateAny',
						'InstructionDueEventAny',
						'InstructionIsPastDueAny') )
			Begin
				Set @sSQLFrom=@sSQLFrom
				+char(10)+"left join EVENTS INDE	  on (INDE.EVENTNO=IND.DUEEVENTNO)"
				+char(10)+"left join CASEEVENT INDCE	  on (INDCE.CASEID=C.CASEID"
				+char(10)+"				  and INDCE.EVENTNO=INDE.EVENTNO"
				+char(10)+"				  and INDCE.CYCLE=CASE WHEN INDE.NUMCYCLESALLOWED=1 THEN 1 ELSE CI.CYCLE END)"
			End

			Select @sColumnName=COLUMNNAME
			from @tblOutputRequests
			where ID = 'InstructionDueDateAny'

			If @sColumnName is not null
			Begin
				Set @sSQLString = @sSQLString + ", "+@sColumnName
	
				Set @sSQLSelect      = @sSQLSelect + ", isnull(INDCE.EVENTDATE,INDCE.EVENTDUEDATE)"
				Set @sSQLSelectUnion = @sSQLSelect
				Set @sColumnName=null
			End

			Select @sColumnName=COLUMNNAME
			from @tblOutputRequests
			where ID = 'InstructionDueEventAny'

			If @sColumnName is not null
			Begin
				Set @sSQLString = @sSQLString + ", "+@sColumnName
	
				Set @sSQLSelect = @sSQLSelect + ', isnull('+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'INEC',@sLookupCulture,@pbCalledFromCentura)
										 +','+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'INDE',@sLookupCulture,@pbCalledFromCentura)+')'
				Set @sSQLSelectUnion=@sSQLSelect

				Set @sSQLFrom = @sSQLFrom
					+char(10)+"left join EVENTCONTROL INEC	on (INEC.CRITERIANO=INDCE.CREATEDBYCRITERIA"
					+char(10)+"				and INEC.EVENTNO=INDCE.EVENTNO)"

				Set @sColumnName=null

			End

			Select @sColumnName=COLUMNNAME
			from @tblOutputRequests
			where ID = 'InstructionIsPastDueAny'

			If @sColumnName is not null
			Begin
				Set @sSQLString = @sSQLString + ", "+@sColumnName
	
				Set @sSQLSelect      = @sSQLSelect      + ", case when (isnull(INDCE.EVENTDATE,INDCE.EVENTDUEDATE)"+dbo.fn_ConstructOperator(8,'DT',convert(nvarchar,getdate(),112), NULL,0)+") THEN 1 ELSE 0 END"
				Set @sSQLSelectUnion = @sSQLSelect
			End
		
			Set @sSQLString=@sSQLString+')'
		End

		----------------------
		-- Filter Fees columns
		----------------------
		If @bFeesRequired=1
		and @ErrorCode=0
		Begin	
			-- Translate the FeesPeriodRangeType if it exists
			Set @sFeesPeriodRangeType=Case(@sFeesPeriodRangeType)
							When('D') Then 'dd'
							When('W') Then 'wk'
							When('M') Then 'mm'
							When('Y') Then 'yy'
						End
		
			-- If FeesPeriodRangeType and either FeesPeriodRangeFrom or FeesPeriodRangeTo are supplied, then
			-- these are used to calculate FeesDateRangeFrom date and the FeesDateRangeTo before proceeding.
			-- The dates are calculated by adding the period and type to the 
			-- current date.
		
			If @sFeesPeriodRangeType is not null
			Begin
				If @nFeesPeriodRangeFrom is not null
				Begin
					Set @sSQLString1 = "Set @dtDateRangeFrom = dateadd("+@sFeesPeriodRangeType+", @nPeriodRangeFrom, '" + convert(nvarchar,getdate(),112) + "')"
		
					execute sp_executesql @sSQLString1,
							N'@dtDateRangeFrom	datetime 		output,
							  @nPeriodRangeFrom	smallint',
			  				  @dtDateRangeFrom	= @dtFeesDateRangeFrom 	output,
							  @nPeriodRangeFrom	= @nFeesPeriodRangeFrom		
			  
				End
		
				If @nFeesPeriodRangeTo is not null
				Begin
					Set @sSQLString1 = "Set @dtDateRangeTo = dateadd("+@sFeesPeriodRangeType+", @nPeriodRangeTo, '" + convert(nvarchar,getdate(),112) + "')"
		
					execute sp_executesql @sSQLString1,
							N'@dtDateRangeTo	datetime 		output,
							  @nPeriodRangeTo	smallint',
			  				  @dtDateRangeTo	= @dtFeesDateRangeTo 	output,
							  @nPeriodRangeTo	= @nFeesPeriodRangeTo				  
				End
		
				Set @nFeesDateRangeOperator=@nFeesPeriodRangeOperator
			End

			If (@dtFeesDateRangeFrom is not null
			 or  @dtFeesDateRangeTo   is not null)
			Begin
				Set @sAddWhereString= @sAddWhereString
				+char(10)+"and isnull(CE.EVENTDATE,CE.EVENTDUEDATE)"+dbo.fn_ConstructOperator(isnull(@nFeesDateRangeOperator,7),'DT',convert(nvarchar,@dtFeesDateRangeFrom,112), convert(nvarchar,@dtFeesDateRangeTo,112),@pbCalledFromCentura)

				-- Save the date range in order to pass it to 
				-- cs_ListCaseCharges for fee calculation
				Set @dtFromDate =@dtFeesDateRangeFrom
				Set @dtUntilDate=@dtFeesDateRangeTo
			End
	
		
			If @nChargeTypeKey is not null
			Begin
				Set @sAddWhereString=@sAddWhereString
					+char(10)+"and FC.CHARGETYPENO"+dbo.fn_ConstructOperator(isnull(@nChargeTypeOperator,0),'N',@nChargeTypeKey, null,@pbCalledFromCentura)
			End
		
			If @bUntilExpiry=1
			Begin
				-- Expiry date must exist if this option is on
				Set @sSQLFrom = @sSQLFrom
					+char(10)+"join CASEEVENT FEX		on (FEX.CASEID=C.CASEID"
					+char(10)+"				and FEX.EVENTNO=-12"
					+char(10)+"				and FEX.CYCLE=1)"
			End
			-------------------------------------------------------------
			-- RFC12399
			-- Need to ensure a fee that is being driven by the existence
			-- of a Due Date has the appropriate OpenAction to ensure the
			-- Event is in fact considered to be due.
			-------------------------------------------------------------
			Set @sAddWhereString=@sAddWhereString
				+char(10)+"and (CE.OCCURREDFLAG=1 OR (CE.OCCURREDFLAG=0 and EC.EVENTNO=E.EVENTNO and OA.ACTION=ISNULL(E.CONTROLLINGACTION,OA.ACTION) and OA.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN CE.CYCLE ELSE 1 END))"
		End
		-------------------------------------
		-- Filter ProvideInstructions columns
		-------------------------------------
		Else If @bProvideInstructionsRequired=1
		     and @ErrorCode=0
		Begin
			-- Availability flags are mandatory
			Set @nAvailabilityFlags=
				(@bInstructionsForMultiCase*1)+
				(@bInstructionsForSingleCase*2)+
				(@bInstructionsForDueEvent*4)
		
			Set @sAddWhereString="and IND.AVAILABILITYFLAGS&"+CAST(@nAvailabilityFlags as varchar)+">0"
			
			-- Translate the InstructionsPeriodRangeType if it exists
			Set @sInstructionsPeriodRangeType=Case(@sInstructionsPeriodRangeType)
							When('D') Then 'dd'
							When('W') Then 'wk'
							When('M') Then 'mm'
							When('Y') Then 'yy'
						End
		
			-- If InstructionsPeriodRangeType and either InstructionsPeriodRangeFrom or InstructionsPeriodRangeTo are supplied, then
			-- these are used to calculate InstructionsDateRangeFrom date and the InstructionsDateRangeTo before proceeding.
			-- The dates are calculated by adding the period and type to the 
			-- current date.
		
			If @sInstructionsPeriodRangeType is not null
			Begin
				If @nInstructionsPeriodRangeFrom is not null
				Begin
					Set @sSQLString1 = "Set @dtDateRangeFrom = dateadd("+@sInstructionsPeriodRangeType+", @nPeriodRangeFrom, '" + convert(nvarchar,getdate(),112) + "')"
		
					execute sp_executesql @sSQLString1,
							N'@dtDateRangeFrom	datetime 		output,
							  @nPeriodRangeFrom	smallint',
			  				  @dtDateRangeFrom	= @dtInstructionsDateRangeFrom 	output,
							  @nPeriodRangeFrom	= @nInstructionsPeriodRangeFrom		
			  
				End
		
				If @nInstructionsPeriodRangeTo is not null
				Begin
					Set @sSQLString1 = "Set @dtDateRangeTo = dateadd("+@sInstructionsPeriodRangeType+", @nPeriodRangeTo, '" + convert(nvarchar,getdate(),112) + "')"
		
					execute sp_executesql @sSQLString1,
							N'@dtDateRangeTo	datetime 		output,
							  @nPeriodRangeTo	smallint',
			  				  @dtDateRangeTo	= @dtInstructionsDateRangeTo 	output,
							  @nPeriodRangeTo	= @nInstructionsPeriodRangeTo				  
				End
		
				Set @nInstructionsDateRangeOperator=@nInstructionsPeriodRangeOperator
			End
		
			-- Locate the event from the reminder (then filter on the event)
			If @ErrorCode=0
			Begin
				Set @sSQLString1 = "
				Select  @nDueEventCaseKey = E.CASEID,
					@nDueEventKey	  = E.EVENTNO,
					@nDueEventCycle   = E.CYCLENO
				from EMPLOYEEREMINDER E
				where E.EMPLOYEENO = @nReminderEmployeeKey
				and   E.MESSAGESEQ = @dtReminderDateCreated"
				
				exec @ErrorCode = sp_executesql @sSQLString1,
							N'@nDueEventCaseKey		int		output,
							  @nDueEventKey			int		output,
						 	  @nDueEventCycle		smallint	output,
							  @nReminderEmployeeKey		int,
							  @dtReminderDateCreated 	datetime',
							  @nDueEventCaseKey		= @nDueEventCaseKey output,
							  @nDueEventKey			= @nDueEventKey output,
							  @nDueEventCycle		= @nDueEventCycle output,
							  @nReminderEmployeeKey		= @nReminderEmployeeKey,
							  @dtReminderDateCreated	= @dtReminderDateCreated 
		
			End
		
			-- Filter on the due event
			If   @ErrorCode=0
			and (@dtInstructionsDateRangeFrom is not null
			 or  @dtInstructionsDateRangeTo   is not null
			 or  @nDueEventCaseKey		  is not null)
			Begin
				-- If filtering is required on instruction due date, and the table is not
				-- yet available, add it.
				If CHARINDEX('left join EVENTS INDE', isnull(@sSQLFrom,''))=0
				Begin
					-- Locate the due event (which may not be the driving event INCE above)
					Set @sSQLFrom=@sSQLFrom
					+char(10)+"left join EVENTS INDE	on (INDE.EVENTNO=IND.DUEEVENTNO)"

					If @pbExternalUser=1
						Set @sSQLFrom=@sSQLFrom
						+char(10)+"left join CASEEVENT INDCE with(INDEX(XPKCASEEVENT)) on (INDCE.CASEID=C.CASEID"
						+char(10)+"                                                    and INDCE.EVENTNO=INDE.EVENTNO"
						+char(10)+"                                                    and INDCE.CYCLE=CASE WHEN INDE.NUMCYCLESALLOWED=1 THEN 1 ELSE CI.CYCLE END)"
					Else
						Set @sSQLFrom=@sSQLFrom
						+char(10)+"left join CASEEVENT INDCE on (INDCE.CASEID=C.CASEID"
						+char(10)+"                          and INDCE.EVENTNO=INDE.EVENTNO"
						+char(10)+"                          and INDCE.CYCLE=CASE WHEN INDE.NUMCYCLESALLOWED=1 THEN 1 ELSE CI.CYCLE END)"
				End
			End

			-- Copy the Where clause so far to a variable that will be used in the UNION
			-- as the details of the Where may vary from this point
			Set @sAddWhereStringUnion = @sAddWhereString

			If   @ErrorCode=0
			and (@dtInstructionsDateRangeFrom is not null
			 or  @dtInstructionsDateRangeTo   is not null
			 or  @bIncludeUnknownDueDates	  is not null)
			Begin
				If (@dtInstructionsDateRangeFrom is not null
				 or  @dtInstructionsDateRangeTo  is not null)
				Begin
					Set @sAddWhereString= @sAddWhereString+char(10)+"and ("
					Set @sAddWhereString= @sAddWhereString
					+"isnull(INDCE.EVENTDATE,INDCE.EVENTDUEDATE)"+dbo.fn_ConstructOperator(isnull(@nInstructionsDateRangeOperator,7),'DT',convert(nvarchar,@dtInstructionsDateRangeFrom,112), convert(nvarchar,@dtInstructionsDateRangeTo,112),@pbCalledFromCentura)

					Set @sAddWhereStringUnion= @sAddWhereStringUnion+char(10)+"and "
					+"isnull(INDCE.EVENTDATE,INDCE.EVENTDUEDATE)"+dbo.fn_ConstructOperator(isnull(@nInstructionsDateRangeOperator,7),'DT',convert(nvarchar,@dtInstructionsDateRangeFrom,112), convert(nvarchar,@dtInstructionsDateRangeTo,112),@pbCalledFromCentura)
		
					If @bIncludeUnknownDueDates=1
					Begin
						Set @sAddWhereString= @sAddWhereString
						+char(10)+"or IND.DUEEVENTNO is null"
					End
		
					Set @sAddWhereString= @sAddWhereString+")"
				End
				Else If @bIncludeUnknownDueDates=0
				Begin
					Set @sAddWhereString=@sAddWhereString+char(10)+"and INDCE.EVENTNO is not null"
				End
		
			End
		
			If  @ErrorCode=0
			and (@nDueEventCaseKey is not null)
			Begin
				Set @sAddWhereString=@sAddWhereString
					+char(10)+"and INDCE.CASEID="+cast(@nDueEventCaseKey as nvarchar)
					+char(10)+"and INDCE.EVENTNO="+cast(@nDueEventKey as nvarchar)
					+char(10)+"and INDCE.CYCLE="+cast(@nDueEventCycle as nvarchar)

				Set @sAddWhereStringUnion=@sAddWhereStringUnion
					+char(10)+"and INDCE.CASEID="+cast(@nDueEventCaseKey as nvarchar)
					+char(10)+"and INDCE.EVENTNO="+cast(@nDueEventKey as nvarchar)
					+char(10)+"and INDCE.CYCLE="+cast(@nDueEventCycle as nvarchar)
			End	
		
			If  @ErrorCode=0
			and (@nInstructionDefinitionOperator is not null
			     or @nInstructionDefinitionKey is not null)
			Begin
				Set @sAddWhereString=@sAddWhereString
					+char(10)+"and IND.DEFINITIONID"+dbo.fn_ConstructOperator(@nInstructionDefinitionOperator,'N',@nInstructionDefinitionKey, null,@pbCalledFromCentura)

				Set @sAddWhereStringUnion=@sAddWhereStringUnion
					+char(10)+"and IND.DEFINITIONID"+dbo.fn_ConstructOperator(@nInstructionDefinitionOperator,'N',@nInstructionDefinitionKey, null,@pbCalledFromCentura)
			End	
		End
		---------------------------------------
		-- Now construct the SQL and execute it
		-- This will load the global temporary
		-- table with the rows to be reported.
		---------------------------------------
		If @ErrorCode=0
		Begin
			If @bProvideInstructionsRequired=1
			Begin
				If @pbPrintSQL = 1
				Begin
					Print ''
					Print 	@sSQLString
						+char(10)+@sSQLSelect
						+char(10)+@sSQLFrom
						+char(10)+"Where 1=1"
						+char(10)+@psWhereFilter
						+char(10)+@sAddWhereString
					Print	'UNION'
						+char(10)+@sSQLSelectUnion
						+char(10)+@sSQLFromUnion
						+char(10)+"Where 1=1"
						+char(10)+@psWhereFilter
						+char(10)+@sAddWhereStringUnion
						+char(10)+"ORDER BY 3"
				End

				Exec(	@sSQLString
					+' '+@sSQLSelect
					+' '+@sSQLFrom
					+' '+"Where 1=1"
					+' '+@psWhereFilter
					+' '+@sAddWhereString
					+' '+'UNION'
					+' '+@sSQLSelectUnion
					+' '+@sSQLFromUnion
					+' '+"Where 1=1"
					+' '+@psWhereFilter
					+' '+@sAddWhereStringUnion
					+' '+"ORDER BY 3")
				
				set @pnCaseTotal=@@Rowcount
			End
			Else Begin
				If @pbPrintSQL = 1
				Begin
					Print ''
					Print 	@sSQLString
						+char(10)+@sSQLSelect
						+char(10)+@sSQLFrom
						+char(10)+"Where 1=1"
						+char(10)+@psWhereFilter
						+char(10)+@sAddWhereString
						+char(10)+"ORDER BY 3"
				End

				Exec(	@sSQLString
					+' '+@sSQLSelect
					+' '+@sSQLFrom
					+' '+"Where 1=1"
					+' '+@psWhereFilter
					+' '+@sAddWhereString
					+' '+"ORDER BY 3")
				
				set @pnCaseTotal=@@Rowcount
			End
		End
	End

	-- If there was a temporary table when the procedure was called, it can now be dropped
	If @ErrorCode=0
	and exists(select * from tempdb.dbo.sysobjects where name = @psTempTableName)
	Begin
		Set @sSQLString='drop table '+@psTempTableName

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Change the temporary table name
	Set @psTempTableName=@sResultTable

	-- Clear out the existing WHERE clause as all of the Cases are now held in a 
	-- temporary table
	Set @psWhereFilter=NULL

	-- If the number of Case rows extracted exceeds the Cases
	-- requested by the front end, then remove the rows that
	-- are not required.  This only applies if the rows had 
	-- already been extracted and sorted.
	If @bTempCasesSorted=1
	and(@pnPageStartRow>1
	 or @pnPageEndRow<@pnCaseTotal)
	Begin
		Set @sSQLString="
		Update "+@sResultTable+"
		Set IGNOREFLAG=1
		Where ROWNUMBER<isnull(@pnPageStartRow,1)
		or    ROWNUMBER>isnull(@pnPageEndRow,@pnCaseTotal)"

		If @pbPrintSQL = 1
		Begin
			Print ''
			Print 	@sSQLString
				+char(10)+@sSQLSelect
				+char(10)+@sSQLFrom
				+char(10)+"Where 1=1"
				+char(10)+@psWhereFilter
				+char(10)+@sAddWhereString
				+char(10)+"ORDER BY 3"
		End

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnPageStartRow	int,
						  @pnPageEndRow		int,
						  @pnCaseTotal		int',
						  @pnPageStartRow=@pnPageStartRow,
						  @pnPageEndRow  =@pnPageEndRow,
						  @pnCaseTotal    =@pnCaseTotal

		Set @pbPagingApplied=1
	End
End

-- Now start extracting the addditional columns of data for each Case
-- Commence with the columns that require FEESCALC to be called as these will have to be processed
-- one Case row at a time because a stored procedure must be called.  Where there are multiple columns
-- using the same RATENO qualifier then the FEESCALC stored procedure will only be called once per Case.

If exists(select * from @tblOutputRequests where CALLFEESCALC=1)
and @ErrorCode=0
Begin
	Set @bIgnoreFlag=0

	Set @sSQLString="
	Select @nCaseRowNumber=min(ROWNUMBER)
	from "+@sResultTable+"
	where IGNOREFLAG=0"
	
	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCaseRowNumber	int		OUTPUT',
				  @nCaseRowNumber=@nCaseRowNumber	OUTPUT


	While @nCaseRowNumber<=@pnCaseTotal
	and   @bIgnoreFlag=0
	and   @ErrorCode=0
	Begin
		-- Get the Case details

		Set @sSQLString="
		Select  @sIRN=IRN,
			@nCaseId=CASEID,
			@bIgnoreFlag=IGNOREFLAG
		from "+@sResultTable+"
		where ROWNUMBER=@nCaseRowNumber"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sIRN		nvarchar(30)	OUTPUT,
					  @nCaseId	int		OUTPUT,
					  @bIgnoreFlag	bit		OUTPUT,
					  @nCaseRowNumber int',
					  @sIRN	 	 =@sIRN		OUTPUT,
					  @nCaseId	 =@nCaseId	OUTPUT,
					  @bIgnoreFlag   =@bIgnoreFlag	OUTPUT,
					  @nCaseRowNumber=@nCaseRowNumber

		-- Now we need to loop through the columns and process those requiring FEESCALC
		Set @nCount=1
		Set @sSQLString=NULL

		While @nCount<=@nOutRequestsRowCount
		and   @bIgnoreFlag=0
		and   @ErrorCode=0
		Begin
			Select	@sColumn	=ID,
				@sColumnName	=COLUMNNAME,
				@sQualifier	=QUALIFIER,
				@bCallFeesCalc	=CALLFEESCALC
			from @tblOutputRequests
			where ROWNUMBER=@nCount

			If @bCallFeesCalc=1
			and isnumeric(@sQualifier)=1
			Begin
				-- Initialise the variables used to sum the
				-- Rate Calcuation values

				Set @nDisbAmount 	=0 	
				Set @nDisbHomeAmount 	=0 
				Set @nDisbBillAmount 	=0
				Set @nServAmount 	=0 
				Set @nServHomeAmount 	=0
				Set @nServBillAmount 	=0 
				Set @nTotHomeDiscount 	=0
				Set @nTotBillDiscount 	=0 
				Set @nDisbTaxAmt 	=0 	
				Set @nDisbTaxHomeAmt 	=0 
				Set @nDisbTaxBillAmt 	=0
				Set @nServTaxAmt 	=0 	
				Set @nServTaxHomeAmt 	=0
				Set @nServTaxBillAmt 	=0
				Set @nDisbDiscOriginal	=0
				Set @nDisbHomeDiscount 	=0
				Set @nDisbBillDiscount 	=0
				Set @nServDiscOriginal	=0
				Set @nServHomeDiscount 	=0
				Set @nServBillDiscount 	=0
				Set @nDisbCostHome	=0
				Set @nDisbCostOriginal	=0

				-- Now we have to determine what RateNo(s) will require calculation.
				-- This is done by taking the ChargeType passed as a parameter and then
				-- finding the associated RateNo(s) that apply for the characteristics
				-- of the Case.

				Set @nChargeTypeNo=convert(int,@sQualifier)

				Set @sSQLString1="
				Select @nRateNo=min(CR.RATENO)
				from CASES C 
				join (	select CHARGETYPENO,RATENO,SEQUENCENO,CASETYPE,PROPERTYTYPE,
						COUNTRYCODE,CASECATEGORY,SUBTYPE,INSTRUCTIONTYPE,FLAGNUMBER,
						CASE WHEN(INSTRUCTIONTYPE is not null) 
							THEN dbo.fn_StandingInstruction(@nCaseId,INSTRUCTIONTYPE)
							ELSE null
						END as INSTRUCTIONCODE
						from CHARGERATES) CR on (CR.CHARGETYPENO=@nChargeTypeNo)
				left join INSTRUCTIONFLAG F  on (F.INSTRUCTIONCODE=CR.INSTRUCTIONCODE)
				where C.CASEID=@nCaseId
				and(CASE WHEN(CR.CASETYPE     is null) THEN '0' ELSE '1' END+
				    CASE WHEN(CR.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
				    CASE WHEN(CR.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
				    CASE WHEN(CR.CASECATEGORY is null) THEN '0' ELSE '1' END+
				    CASE WHEN(CR.SUBTYPE      is null) THEN '0' ELSE '1' END+
				    CASE WHEN(CR.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
					=(	select max(CASE WHEN(CR1.CASETYPE     is null) THEN '0' ELSE '1' END+
							   CASE WHEN(CR1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
							   CASE WHEN(CR1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
							   CASE WHEN(CR1.CASECATEGORY is null) THEN '0' ELSE '1' END+
							   CASE WHEN(CR1.SUBTYPE      is null) THEN '0' ELSE '1' END+
							   CASE WHEN(CR1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
						from CHARGERATES CR1
						where CR1.CHARGETYPENO=CR.CHARGETYPENO
						and   CR1.RATENO      =CR.RATENO
						and  (CR1.CASETYPE    =C.CASETYPE     OR CR1.CASETYPE     is null)
						and  (CR1.PROPERTYTYPE=C.PROPERTYTYPE OR CR1.PROPERTYTYPE is null)
						and  (CR1.COUNTRYCODE =C.COUNTRYCODE  OR CR1.COUNTRYCODE  is null)
						and  (CR1.CASECATEGORY=C.CASECATEGORY OR CR1.CASECATEGORY is null)
						and  (CR1.SUBTYPE     =C.SUBTYPE      OR CR1.SUBTYPE      is null)
						and  (CR1.FLAGNUMBER  =F.FLAGNUMBER   OR CR1.FLAGNUMBER   is null))
				and (CR.CASETYPE    = C.CASETYPE     OR CR.CASETYPE     is null)
				and (CR.PROPERTYTYPE= C.PROPERTYTYPE OR CR.PROPERTYTYPE is null)
				and (CR.COUNTRYCODE = C.COUNTRYCODE  OR CR.COUNTRYCODE  is null)
				and (CR.CASECATEGORY= C.CASECATEGORY OR CR.CASECATEGORY is null)
				and (CR.SUBTYPE     = C.SUBTYPE      OR CR.SUBTYPE      is null)
				and (CR.FLAGNUMBER  = F.FLAGNUMBER   OR CR.FLAGNUMBER   is null)"

				Exec @ErrorCode=sp_executesql @sSQLString1,
							N'@nRateNo		int	output,
							  @nCaseId		int,
							  @nChargeTypeNo	int',
							  @nRateNo=@nRateNo		output,
							  @nCaseId=@nCaseId,
							  @nChargeTypeNo=@nChargeTypeNo

				-- Initialise variables used within the loop
				Set @sDisbCurrency =NULL
				Set @nDisbExchRate =NULL
				Set @sServCurrency =NULL
				Set @nServExchRate =NULL
				Set @sDisbTaxCode  =NULL
				Set @sServTaxCode  =NULL
				Set @nDisbNarrative=NULL
				Set @nServNarrative=NULL
				Set @sDisbWIPCode  =NULL
				Set @sServWIPCode  =NULL

				Set @bDisbTaxCodeSaved  =0
				Set @bServTaxCodeSaved  =0
				Set @bDisbNarrativeSaved=0
				Set @bServNarrativeSaved=0
				Set @bDisbWIPCodeSaved  =0
				Set @bServWIPCodeSaved  =0
				Set @bDisbCurrencySaved =0
				Set @bServCurrencySaved =0

				Set @nLoopCount=0

				-- Now loop through each RateNo to process

				While @nRateNo is not null
				and @ErrorCode=0
				Begin
					-- Only call the FEESCALC stored procedure if the Case or Rateno
					-- are different from the last time it was called
					If @sIRN<>@psIRN
					or @nRateNo<>@pnRateNo 
					or @nLoopCount=0
					Begin
						Set @psIRN     =@sIRN
						Set @pnRateNo  =@nRateNo
						Set @nLoopCount=@nLoopCount+1
						-- Reset the output parameters
						Set @prsDisbCurrency	= null
						Set @prnDisbExchRate	= null
						Set @prsServCurrency	= null
						Set @prnServExchRate	= null
						Set @prsBillCurrency	= null
						Set @prnBillExchRate	= null
						Set @prsDisbTaxCode	= null
						Set @prsServTaxCode	= null
						Set @prnDisbNarrative	= null
						Set @prnServNarrative	= null
						Set @prsDisbWIPCode	= null
						Set @prsServWIPCode	= null
						Set @prnDisbAmount	= 0
						Set @prnDisbHomeAmount	= 0
						Set @prnDisbBillAmount	= 0
						Set @prnServAmount	= 0
						Set @prnServHomeAmount	= 0
						Set @prnServBillAmount	= 0
						Set @prnTotHomeDiscount = 0
						Set @prnTotBillDiscount = 0
						Set @prnDisbTaxAmt	= 0
						Set @prnDisbTaxHomeAmt	= 0
						Set @prnDisbTaxBillAmt	= 0
						Set @prnServTaxAmt	= 0
						Set @prnServTaxHomeAmt	= 0
						Set @prnServTaxBillAmt	= 0
						Set @prnDisbDiscOriginal= 0
						Set @prnDisbHomeDiscount= 0
						Set @prnDisbBillDiscount= 0
						Set @prnServDiscOriginal= 0
						Set @prnServHomeDiscount= 0
						Set @prnServBillDiscount= 0
						Set @prnDisbCostHome	= 0
						Set @prnDisbCostOriginal= 0
	
						exec @ErrorCode=FEESCALC 	
							@psIRN			= @psIRN,
							@pnRateNo		= @pnRateNo,
							@psAction		= NULL,
							@pnCheckListType	= NULL,
							@pnCycle		= NULL,
							@pnEventNo		= NULL,
							@pdtLetterDate		= NULL,
							@pnEnteredQuantity	= NULL,
							@pnEnteredAmount	= NULL,
							@pnARQuantity		= NULL,
							@pnARAmount		= NULL,
							@pnDebtor		= NULL,				-- Added JB 5/7/2004
							@prsDisbCurrency	= @prsDisbCurrency 	output,	
							@prnDisbExchRate	= @prnDisbExchRate 	output, 
							@prsServCurrency	= @prsServCurrency 	output, 	
							@prnServExchRate	= @prnServExchRate 	output, 
							@prsBillCurrency	= @prsBillCurrency 	output, 	
							@prnBillExchRate	= @prnBillExchRate 	output, 
							@prsDisbTaxCode		= @prsDisbTaxCode 	output, 	
							@prsServTaxCode		= @prsServTaxCode 	output, 
							@prnDisbNarrative	= @prnDisbNarrative 	output, 		
							@prnServNarrative	= @prnServNarrative 	output, 
							@prsDisbWIPCode		= @prsDisbWIPCode 	output, 	
							@prsServWIPCode		= @prsServWIPCode 	output, 
							@prnDisbAmount		= @prnDisbAmount 	output, 	
							@prnDisbHomeAmount	= @prnDisbHomeAmount 	output, 
							@prnDisbBillAmount	= @prnDisbBillAmount 	output,
							@prnServAmount		= @prnServAmount 	output, 
							@prnServHomeAmount	= @prnServHomeAmount 	output,
							@prnServBillAmount	= @prnServBillAmount 	output, 
							@prnTotHomeDiscount 	= @prnTotHomeDiscount 	output,
							@prnTotBillDiscount 	= @prnTotBillDiscount 	output, 
							@prnDisbTaxAmt		= @prnDisbTaxAmt 	output, 	
							@prnDisbTaxHomeAmt	= @prnDisbTaxHomeAmt 	output, 
							@prnDisbTaxBillAmt	= @prnDisbTaxBillAmt 	output,
							@prnServTaxAmt		= @prnServTaxAmt 	output, 	
							@prnServTaxHomeAmt	= @prnServTaxHomeAmt 	output,
							@prnServTaxBillAmt	= @prnServTaxBillAmt 	output,
							@prnDisbDiscOriginal 	= @prnDisbDiscOriginal	output,
							@prnDisbHomeDiscount 	= @prnDisbHomeDiscount 	output,
							@prnDisbBillDiscount 	= @prnDisbBillDiscount 	output, 
							@prnServDiscOriginal 	= @prnServDiscOriginal	output,
							@prnServHomeDiscount 	= @prnServHomeDiscount 	output,
							@prnServBillDiscount 	= @prnServBillDiscount 	output,
							@prnDisbCostHome	= @prnDisbCostHome	output,
							@prnDisbCostOriginal 	= @prnDisbCostOriginal	output				
					End -- call to FeesCalc

					-- Save the Disbursement Tax Code the first time a value is defined
					If  @sDisbTaxCode   is NULL
					and @prsDisbTaxCode is not NULL
					and @bDisbTaxCodeSaved=0
					Begin
						Set @sDisbTaxCode=@prsDisbTaxCode
						Set @bDisbTaxCodeSaved=1
					End

					-- Now if the DisbTaxCode does not match a previously
					-- saved value then clear out the saved value so as not 
					-- to inaccurately report a mixed value
					If @sDisbTaxCode<>@prsDisbTaxCode
						Set @sDisbTaxCode=NULL

					-- Save the Service Tax Code the first time a value is defined
					If  @sServTaxCode   is NULL
					and @prsServTaxCode is not NULL
					and @bServTaxCodeSaved=0
					Begin
						Set @sServTaxCode=@prsServTaxCode
						Set @bServTaxCodeSaved=1
					End

					-- Now if the ServTaxCode does not match a previously
					-- saved value then clear out the saved value so as not 
					-- to inaccurately report a mixed value
					If @sServTaxCode<>@prsServTaxCode
						Set @sServTaxCode=NULL

					-- Save the Disbursement Narrative the first time a value is defined
					If  @nDisbNarrative   is NULL
					and @prnDisbNarrative is not NULL
					and @bDisbNarrativeSaved=0
					Begin
						Set @nDisbNarrative=@prnDisbNarrative
						Set @bDisbNarrativeSaved=1
					End

					-- Now if the DisbNarrative does not match a previously
					-- saved value then clear out the saved value so as not 
					-- to inaccurately report a mixed value
					If @nDisbNarrative<>@prnDisbNarrative
						Set @nDisbNarrative=NULL

					-- Save the Service Narrative the first time a value is defined
					If  @nServNarrative   is NULL
					and @prnServNarrative is not NULL
					and @bServNarrativeSaved=0
					Begin
						Set @nServNarrative=@prnServNarrative
						Set @bServNarrativeSaved=1
					End

					-- Now if the ServNarrative does not match a previously
					-- saved value then clear out the saved value so as not 
					-- to inaccurately report a mixed value
					If @nServNarrative<>@prnServNarrative
						Set @nServNarrative=NULL

					-- Save the Disbursement WIP Code the first time a value is defined
					If  @sDisbWIPCode   is NULL
					and @prsDisbWIPCode is not NULL
					and @bDisbWIPCodeSaved=0
					Begin
						Set @sDisbWIPCode=@prsDisbWIPCode
						Set @bDisbWIPCodeSaved=1
					End

					-- Now if the DisbWIPCode does not match a previously
					-- saved value then clear out the saved value so as not 
					-- to inaccurately report a mixed value
					If @sDisbWIPCode<>@prsDisbWIPCode
						Set @sDisbWIPCode=NULL

					-- Save the Service WIP Code the first time a value is defined
					If  @sServWIPCode   is NULL
					and @prsServWIPCode is not NULL
					and @bServWIPCodeSaved=0
					Begin
						Set @sServWIPCode=@prsServWIPCode
						Set @bServWIPCodeSaved=1
					End

					-- Now if the ServWIPCode does not match a previously
					-- saved value then clear out the saved value so as not 
					-- to inaccurately report a mixed value
					If @sServWIPCode<>@prsServWIPCode
						Set @sServWIPCode=NULL						

					-- Save the Disbursement Currency and exchange rate the first time
					-- a value is defined
					If  @sDisbCurrency   is NULL
					and @prsDisbCurrency is not NULL
					and @bDisbCurrencySaved=0
					Begin
						Set @sDisbCurrency=@prsDisbCurrency
						Set @nDisbExchRate=@prnDisbExchRate
						Set @bDisbCurrencySaved=1
					End

					-- Aggregate the values in the disbursement currency only if 
					-- there is commonality between the currency code
					If checksum(@sDisbCurrency)=checksum(@prsDisbCurrency)
					Begin
						Set @nDisbAmount 	= @nDisbAmount      +@prnDisbAmount
						Set @nDisbTaxAmt 	= @nDisbTaxAmt      +@prnDisbTaxAmt
						Set @nDisbDiscOriginal	= @nDisbDiscOriginal+@prnDisbDiscOriginal
						Set @nDisbCostOriginal	= @nDisbCostOriginal+@prnDisbCostOriginal
					End
					-- If the currency has changed and there are values to be accumulated
					-- then we cannot add values that have a mixed currency so the current
					-- accumulated values will be cleared out
					Else 
					If checksum(@sDisbCurrency)<>checksum(@prsDisbCurrency)
					and (@prnDisbAmount <> 0 
					  or @prnDisbTaxAmt <> 0
					  or @prnDisbDiscOriginal<>0
					  or @prnDisbCostOriginal<>0)
					Begin
						Set @sDisbCurrency	= null
						Set @nDisbExchRate	= null
						Set @nDisbAmount 	= null
						Set @nDisbTaxAmt 	= null
						Set @nDisbDiscOriginal	= null
						Set @nDisbCostOriginal	= null
					End

					-- Save the Service Currency and exchange rate the first time
					-- a value is defined
					If  @sServCurrency   is NULL
					and @prsServCurrency is not NULL
					and @bServCurrencySaved=0
					Begin
						Set @sServCurrency=@prsServCurrency
						Set @nServExchRate=@prnServExchRate
						Set @bServCurrencySaved=1
					End

					-- Aggregate the values in the service currency only if 
					-- there is commonality between the currency code
					If checksum(@sServCurrency)=checksum(@prsServCurrency)
					Begin
						Set @nServAmount 	= @nServAmount      +@prnServAmount
						Set @nServTaxAmt 	= @nServTaxAmt      +@prnServTaxAmt
						Set @nServDiscOriginal	= @nServDiscOriginal+@prnServDiscOriginal
					End
					-- If the currency has changed and there are values to be accumulated
					-- then we cannot add values that have a mixed currency so the current
					-- accumulated values will be cleared out
					Else 
					If checksum(@sServCurrency)<>checksum(@prsServCurrency)
					and (@prnServAmount <> 0 
					  or @prnServTaxAmt <> 0
					  or @prnServDiscOriginal<>0)
					Begin
						Set @sServCurrency	= null
						Set @nServExchRate	= null
						Set @nServAmount 	= null
						Set @nServTaxAmt 	= null
						Set @nServDiscOriginal	= null
					End

					-- Bill currency is a common currency so amounts can be summed
					Set @nDisbBillDiscount 	= @nDisbBillDiscount+@prnDisbBillDiscount
					Set @nServBillDiscount 	= @nServBillDiscount+@prnServBillDiscount
					Set @nDisbTaxBillAmt 	= @nDisbTaxBillAmt  +@prnDisbTaxBillAmt
					Set @nTotBillDiscount 	= @nTotBillDiscount +@prnTotBillDiscount
					Set @nServBillAmount 	= @nServBillAmount  +@prnServBillAmount
					Set @nDisbBillAmount 	= @nDisbBillAmount  +@prnDisbBillAmount
					Set @nServTaxBillAmt 	= @nServTaxBillAmt  +@prnServTaxBillAmt

					-- Home currency is a common currency so amounts can be summed
					Set @nServHomeDiscount 	= @nServHomeDiscount+@prnServHomeDiscount
					Set @nDisbHomeDiscount 	= @nDisbHomeDiscount+@prnDisbHomeDiscount
					Set @nServTaxHomeAmt 	= @nServTaxHomeAmt  +@prnServTaxHomeAmt
					Set @nDisbTaxHomeAmt 	= @nDisbTaxHomeAmt  +@prnDisbTaxHomeAmt
					Set @nTotHomeDiscount 	= @nTotHomeDiscount +@prnTotHomeDiscount
					Set @nServHomeAmount 	= @nServHomeAmount  +@prnServHomeAmount
					Set @nDisbHomeAmount 	= @nDisbHomeAmount  +@prnDisbHomeAmount
					Set @nDisbCostHome	= @nDisbCostHome    +@prnDisbCostHome

					-- Now get the next RateNo for the ChargeTypeNo
					Set @sSQLString1="
					Select @nRateNo=min(CR.RATENO)
					from CASES C 
					join (	select CHARGETYPENO,RATENO,SEQUENCENO,CASETYPE,PROPERTYTYPE,
							COUNTRYCODE,CASECATEGORY,SUBTYPE,INSTRUCTIONTYPE,FLAGNUMBER,
							CASE WHEN(INSTRUCTIONTYPE is not null) 
								THEN dbo.fn_StandingInstruction(@nCaseId,INSTRUCTIONTYPE)
								ELSE null
							END as INSTRUCTIONCODE
							from CHARGERATES) CR on (CR.CHARGETYPENO=@nChargeTypeNo)
					left join INSTRUCTIONFLAG F  on (F.INSTRUCTIONCODE=CR.INSTRUCTIONCODE)
					where C.CASEID=@nCaseId
					and CR.RATENO>@nRateNo
					and(CASE WHEN(CR.CASETYPE     is null) THEN '0' ELSE '1' END+
					    CASE WHEN(CR.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
					    CASE WHEN(CR.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
					    CASE WHEN(CR.CASECATEGORY is null) THEN '0' ELSE '1' END+
					    CASE WHEN(CR.SUBTYPE      is null) THEN '0' ELSE '1' END+
					    CASE WHEN(CR.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
						=(	select max(CASE WHEN(CR1.CASETYPE     is null) THEN '0' ELSE '1' END+
								   CASE WHEN(CR1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
								   CASE WHEN(CR1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
								   CASE WHEN(CR1.CASECATEGORY is null) THEN '0' ELSE '1' END+
								   CASE WHEN(CR1.SUBTYPE      is null) THEN '0' ELSE '1' END+
								   CASE WHEN(CR1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
							from CHARGERATES CR1
							where CR1.CHARGETYPENO=CR.CHARGETYPENO
							and   CR1.RATENO      =CR.RATENO
							and  (CR1.CASETYPE    =C.CASETYPE     OR CR1.CASETYPE     is null)
							and  (CR1.PROPERTYTYPE=C.PROPERTYTYPE OR CR1.PROPERTYTYPE is null)
							and  (CR1.COUNTRYCODE =C.COUNTRYCODE  OR CR1.COUNTRYCODE  is null)
							and  (CR1.CASECATEGORY=C.CASECATEGORY OR CR1.CASECATEGORY is null)
							and  (CR1.SUBTYPE     =C.SUBTYPE      OR CR1.SUBTYPE      is null)
							and  (CR1.FLAGNUMBER  =F.FLAGNUMBER   OR CR1.FLAGNUMBER   is null))
					and (CR.CASETYPE    = C.CASETYPE     OR CR.CASETYPE     is null)
					and (CR.PROPERTYTYPE= C.PROPERTYTYPE OR CR.PROPERTYTYPE is null)
					and (CR.COUNTRYCODE = C.COUNTRYCODE  OR CR.COUNTRYCODE  is null)
					and (CR.CASECATEGORY= C.CASECATEGORY OR CR.CASECATEGORY is null)
					and (CR.SUBTYPE     = C.SUBTYPE      OR CR.SUBTYPE      is null)
					and (CR.FLAGNUMBER  = F.FLAGNUMBER   OR CR.FLAGNUMBER   is null)"
	
					Exec @ErrorCode=sp_executesql @sSQLString1,
								N'@nRateNo		int	output,
								  @nCaseId		int,
								  @nChargeTypeNo	int',
								  @nRateNo=@nRateNo		output,
								  @nCaseId=@nCaseId,
								  @nChargeTypeNo=@nChargeTypeNo
				End -- End of Loop through RateNo(s)

				-- Now construct the Update statement to set the column with the value
				-- returned from the FEESCALC stored procedure
				Set @sSQLString=ISNULL(NULLIF(@sSQLString + ','+char(10), ','+char(10)),'') 
			   			+ @sColumnName+'='
						+ CASE(@sColumn)
							WHEN('FeesDisbCurrency')       THEN CASE WHEN(@sDisbCurrency  is null) THEN 'NULL' ELSE "'"+@sDisbCurrency+"'" END
							WHEN('FeesDisbExchRate')       THEN isnull(convert(varchar,@nDisbExchRate), 'NULL')
							WHEN('FeesServCurrency')       THEN CASE WHEN(@sServCurrency  is null) THEN 'NULL' ELSE "'"+@sServCurrency+"'" END
							WHEN('FeesServExchRate')       THEN isnull(convert(varchar,@nServExchRate), 'NULL')
							WHEN('FeesBillCurrency')       THEN CASE WHEN(@prsBillCurrency  is null) THEN 'NULL' ELSE "'"+@prsBillCurrency+"'" END
							WHEN('FeesBillExchRate')       THEN isnull(convert(varchar,@prnBillExchRate), 'NULL')
							WHEN('FeesDisbTaxCode')        THEN CASE WHEN(@sDisbTaxCode   is null) THEN 'NULL' ELSE "'"+@sDisbTaxCode+"'" END
							WHEN('FeesServTaxCode')        THEN CASE WHEN(@sServTaxCode   is null) THEN 'NULL' ELSE "'"+@sServTaxCode+"'" END
							WHEN('FeesDisbNarrative')      THEN CASE WHEN(@nDisbNarrative is null) THEN 'NULL' ELSE '(select cast(NARRATIVETEXT as nvarchar(4000)) from NARRATIVE where NARRATIVENO='+convert(varchar,@nDisbNarrative)+')' END
							WHEN('FeesServNarrative')      THEN CASE WHEN(@nServNarrative is null) THEN 'NULL' ELSE '(select cast(NARRATIVETEXT as nvarchar(4000)) from NARRATIVE where NARRATIVENO='+convert(varchar,@nServNarrative)+')' END
							WHEN('FeesDisbWIPCode')        THEN CASE WHEN(@sDisbWIPCode   is null) THEN 'NULL' ELSE "'"+@sDisbWIPCode+"'" END
							WHEN('FeesServWIPCode')        THEN CASE WHEN(@sServWIPCode   is null) THEN 'NULL' ELSE "'"+@sServWIPCode+"'" END
							WHEN('FeesDisbAmount')         THEN isnull(convert(varchar,@nDisbAmount),      'NULL')
							WHEN('FeesDisbLocalAmount')    THEN isnull(convert(varchar,@nDisbHomeAmount),  'NULL')
							WHEN('FeesDisbBillAmount')     THEN isnull(convert(varchar,@nDisbBillAmount),  'NULL')
							WHEN('FeesDisbNetBillAmount')  THEN isnull(convert(varchar,@nDisbBillAmount-@nDisbBillDiscount),'NULL') --SQA9793
							WHEN('FeesServAmount')         THEN isnull(convert(varchar,@nServAmount),      'NULL')
							WHEN('FeesServLocalAmount')    THEN isnull(convert(varchar,@nServHomeAmount),  'NULL')
							WHEN('FeesServBillAmount')     THEN isnull(convert(varchar,@nServBillAmount),  'NULL')
							WHEN('FeesServNetBillAmount')  THEN isnull(convert(varchar,@nServBillAmount-@nServBillDiscount),'NULL') --SQA9793
							WHEN('FeesTotLocalDiscount')   THEN isnull(convert(varchar,@nTotHomeDiscount), 'NULL')
							WHEN('FeesTotBillDiscount')    THEN isnull(convert(varchar,@nTotBillDiscount), 'NULL')
							WHEN('FeesDisbTaxAmt')         THEN isnull(convert(varchar,@nDisbTaxAmt),      'NULL')
							WHEN('FeesDisbTaxLocalAmt')    THEN isnull(convert(varchar,@nDisbTaxHomeAmt),  'NULL')
							WHEN('FeesDisbTaxBillAmt')     THEN isnull(convert(varchar,@nDisbTaxBillAmt),  'NULL')
							WHEN('FeesServTaxAmt')         THEN isnull(convert(varchar,@nServTaxAmt),      'NULL')
							WHEN('FeesServTaxLocalAmt')    THEN isnull(convert(varchar,@nServTaxHomeAmt),  'NULL')
							WHEN('FeesServTaxBillAmt')     THEN isnull(convert(varchar,@nServTaxBillAmt),  'NULL')
							WHEN('FeesDisbDiscOriginal')   THEN isnull(convert(varchar,@nDisbDiscOriginal),'NULL')
							WHEN('FeesDisbLocalDiscount')  THEN isnull(convert(varchar,@nDisbHomeDiscount),'NULL')
							WHEN('FeesDisbBillDiscount')   THEN isnull(convert(varchar,@nDisbBillDiscount),'NULL')
							WHEN('FeesServDiscOriginal')   THEN isnull(convert(varchar,@nServDiscOriginal),'NULL')
							WHEN('FeesServLocalDiscount')  THEN isnull(convert(varchar,@nServHomeDiscount),'NULL')
							WHEN('FeesServBillDiscount')   THEN isnull(convert(varchar,@nServBillDiscount),'NULL')
							WHEN('FeesDisbCostLocal')      THEN isnull(convert(varchar,@nDisbCostHome),    'NULL')
							WHEN('FeesDisbCostOriginal')   THEN isnull(convert(varchar,@nDisbCostOriginal),'NULL')
							WHEN('FeesTotalBillAmount')    THEN isnull(convert(varchar,@nDisbBillAmount+@nServBillAmount),'NULL')
							WHEN('FeesTotalNetBillAmount') THEN isnull(convert(varchar,@nDisbBillAmount+@nServBillAmount-@nTotBillDiscount),'NULL')
							WHEN('FeesTotalTaxBillAmt')    THEN isnull(convert(varchar,@nDisbTaxBillAmt+@nServTaxBillAmt),'NULL')
						END

			End -- Column requires FeesCalc

			-- Increment the row counter
			Set @nCount=@nCount+1
		End -- loop through @tblOutputRequests

		-- Complete the Update for the Case
		If @bIgnoreFlag=0
		and @ErrorCode=0
		Begin
			Set @sSQLString='Update '+@sResultTable+char(10)+'Set '+@sSQLString+char(10)+
					'where ROWNUMBER=@nCaseRowNumber'+char(10)+
					'and IGNOREFLAG=0'

			exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCaseRowNumber	int',
							  @nCaseRowNumber=@nCaseRowNumber
		End

		-- Increment the Case loop counter
		Set @nCaseRowNumber=@nCaseRowNumber+1
	End
End

-- Loop through each column and where the column is pointing to a DocItem, extract the underlying
-- SQL and update every Case
Set @nCount=1

While @nCount < @nOutRequestsRowCount + 1
and   @ErrorCode=0
Begin
	-- Get details about the column  
	Select	@sColumnName	=COLUMNNAME,
		@sQualifier	=QUALIFIER,
		@nDocItemKey	=DOCITEMKEY
	from @tblOutputRequests
	where ROWNUMBER=@nCount
 
	-- If the column is pointing to a DocItem then this will indicate some
	-- user defined SQL that is to be extracted for each case

	If @nDocItemKey is not null
	Begin
		-- Get the user defined SELECT statement that will be used to extract
		-- data for each Case
	
		Set @sUserSQL=null

		Set @sSQLString="
		Select @sUserSQL=convert(nvarchar(4000),SQL_QUERY)
		From ITEM I 
		Where I.ITEM_ID=@nDocItemKey"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUserSQL		nvarchar(4000)	Output,
					  @nDocItemKey		int',
					  @sUserSQL=@sUserSQL			Output,
					  @nDocItemKey=@nDocItemKey

		If  @sUserSQL is not null
		and @ErrorCode=0
		Begin
			-- In the user defined SQL replace the constants
			Set @sUserSQL=replace(@sUserSQL,':gstrEntryPoint','XX.IRN')

			-- There may be multiple parameters defined delimited by '^'.
			-- Separate out each different parameter and then replace the
			-- appropriate parameter place holder.

			Set @nParameterNo=0
			Set @nInsertOrder=0

			While @sQualifier is not null
			and @nParameterNo=@nInsertOrder
			Begin
				Set @nInsertOrder=@nInsertOrder+1

				SELECT	@nParameterNo=InsertOrder,
				 	@sParameter=Parameter
				FROM	dbo.fn_Tokenise (@sQualifier, '^')
				where	InsertOrder=@nInsertOrder

				If @nParameterNo=@nInsertOrder
					Set @sUserSQL=replace(@sUserSQL,':p'+convert(varchar,@nParameterNo),"'"+@sParameter+"'")
			End

			-- Now update the current column for every row in the table by
			-- embedding the SELECT statement extracted
			exec("
			Update "+@sResultTable+"
			Set "+@sColumnName+"=("+@sUserSQL+")
			From "+@sResultTable+" XX")
			
			Set @ErrorCode=@@Error
		End
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
End

-----------------------------------------------
-- Pass the global temporary table to calculate
-- the charges for each row
-----------------------------------------------

If exists (select 1 from @tblOutputRequests where LISTCHARGES=1)
and @ErrorCode=0
and @pnCaseTotal>0
Begin
	Exec @ErrorCode=dbo.cs_CacheCaseCharges
			@pnBackgroundCount	=@pnCaseChargeCount output,
			@psEmailAddress		=@psEmailAddress    output,
			@pnUserIdentityId	=@pnUserIdentityId,
			@psCulture		=@psCulture,
			@psGlobalTempTable	=@sResultTable,
			@pdtFromDate		=@dtFromDate,
			@pdtUntilDate		=@dtUntilDate,
			@pbPrintSQL		=@pbPrintSQL,
			@ptXMLOutputRequests	= @ptXMLOutputRequests,
			@ptXMLFilterCriteria	= @ptXMLFilterCriteria
End 

RETURN @ErrorCode
go

grant execute on dbo.csw_GetExtendedCaseDetails  to public
go
