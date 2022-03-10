-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCaseCharges
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_ListCaseCharges]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_ListCaseCharges.'
	drop procedure dbo.cs_ListCaseCharges
end
print '**** Creating procedure dbo.cs_ListCaseCharges...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_ListCaseCharges
	@pnRowCount			int		= 0 output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbSavedEstimate		tinyint		= 0,	-- When ON also get the saved estimates as a second row.
	@psGlobalTempTable		nvarchar(60)	= null, -- optional name of temporary table of CASEIDs, may include CYCLE column for specific Renewal Cycle. 
	@pnCaseId			int		= null, -- Case whose fee information is to be explicitly reported on
	@pnYearNo			tinyint		= null, -- If only one years data is required then it can be restricted by this parameter
	@pnRateNo			int		= null, -- Mutually exclusive with @pnChargeTypeNo (one must be entered)
	@pnChargeTypeNo			int		= null, -- Mutually exclusive with @pnRateNo (one must be entered unless @psGlobalTempTable includes ChargeTypeNo)
	--SQA12361 allow variables to be entered instead of a CaseId.
	--         This is to allow a "what if" style of enquiry
	@psCaseType			nchar(1)	= null,	-- User entered CaseType
	@psCountryCode			nvarchar(3)	= null, -- User entered Country
	@psPropertyType			nchar(1)	= null, -- User entered Property Type
	@psCaseCategory			nvarchar(2)	= null, -- User entered Category
	@psSubType			nvarchar(2)	= null, -- User entered Sub Type
	@pnEntitySize			int		= null, -- User entered Entity Size
	@pnInstructor			int		= null, -- User entered Instructor
	@pnDebtor			int		= null, -- User entered Debtor
	@pnDebtorType			int		= null, -- User entered Debtor Type
	@pnAgent			int		= null, -- User entered Agent
	@psCurrency			nvarchar(3)	= null, -- User entered Currency
	@pnExchScheduleId		int		= null,	-- User entered Exchange Rate Schedule
	@pdtRenewalDate			datetime	= null,	-- User entered Renewal Date
	@pnQuantity			int		= null,	-- User entered quantity to be used in calculations

	@pdtFromDate			datetime	= null,	-- Starting date range to filter on
	@pdtUntilDate			datetime	= null, -- Ending date range to filter on

	@pbCalledFromCentura		bit		= 1,	-- Indicates whether called from client/server
	@pbDyamicChargeType		bit		= 0,	-- Indicates that ChargeType may vary by row in @psGlobalTempTable
	@pbPrintSQL			bit		= null,	-- When set to 1, the executed SQL statement is printed out.
	@psBasis			nvarchar(2)	= null,  -- User entered Basis
	@pdtWhenRequested		datetime	= null,	-- Index to CASECHARGESCACHE that requires fee calculation.
	@pnSPID				int		= null,	-- Index to CASECHARGESCACHE that requires fee calculation.
	@psEmailAddress			nvarchar(100)	= null,	-- Email address used when background task completes
	@pnQueryId			int		= null	-- Key of the QUERY row created when background calculation started.

	
AS
-- PROCEDURE :	cs_ListCaseCharges
-- VERSION :	83
-- DESCRIPTION:	Returns details of charges that will apply for a restricted set of Clients 
--		for an explicit Rate.
--		The report will be sorted by PropertyType
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 03/07/2002	MF		1	Procedure created
-- 17/07/2002	MF		2	Allow all the Cases in a temporary table to be reported on.
-- 01/08/2002	MF		3	Allow restriction on YearNo and return total Estimates
-- 18/08/2002	MF		4	Add the CaseId, Instructor, and Case Type
-- 26/03/2003	dw	8116	5	Adjusted calculation of tax rate
-- 23/06/2003	MF	8927	6	Revisit SQA8116.  Error introduced in SQL.
-- 28 Aug 2003	MF	9169	7	If a specific YearNo is passed as a parameter also return any FEESCALCULATION
--					rows where the CycleNumber is null
-- 05 Aug 2004	AB	8035	8	Add collate database_default to temp table definitions
-- 15 Jun 2006	MF	12361	9	Extend the procedure to allow all RateNo within a ChargeType and/or all
--					ChargeTypes within an Action to be determined.
--					Also check for any rate calculations that may vary by date and generate a
--					a calculation for each date at which the calculation will vary.
-- 29 Sep 2006	JEK	RFC3218	10	Create a dummy version of the result sets for WorkBenches.
-- 08 Dec 2006	MF	12361	11	Continuation of requirements for 12361 and correct the output results.
-- 12 Dec 2006	MF	12361	12	Case sensitivity bug on @dtUntilDate
-- 12 Dec 2006	MF	12361	13	External users are to have their fees calculated as at todays date.
-- 13 Dec 2006	JEK	RFC3218	14	Revise WorkBench result sets.
-- 02 Jan 2007	MF	RFC2982	15	Result set to be optionally provided in temporary table used by Case query
-- 09 Jan 2007	MF	RFC2982	16	If called to fetch extended Case details and the InstructionCycleAny
--					exists as a column in the temporary table, then restrict the fees to be
--					calculated to match the cycle.
-- 03 Feb 2007	MF	12361	17	Revisit to include input parameter @pnQuantity that can be passed to FEESCALC
-- 09 Feb 2007	MF	RFC2982	18	Performance improvement by checking to see if Standing Instructions 
--					are required for ChargeType(s) being processed and to modify the code to 
--					avoid getting this information if it is not necessary.
-- 27 Feb 2007	MF	14448	19	Failed testing on RFC282
-- 01 Mar 2007	PY	14425 	20	Reserved word [date]
-- 30 Mar 2007	LP	RFC5246	21	Add new DateRowKey column in Totals By WIP Category result sets
--					Rename CategoryRowKey to WipRowKey and add this to Rates Calculation result set
-- 31 May 2007	MF	12361	22	Add WIP Type Description to result set for Centura version
-- 16 Jul 2007	MF	14965	23	Revisit 12361.  Should have been WIP Category Description not WIP Type.
-- 31 Jul 2007	MF	15103	24	When inserting rows that vary by date consider if in fact the actual calculation
--					will use the period in the calculation. It might be that the fee varies by number
--					of days but could only say vary every 3rd day in which case there is no point 
--					calculating a fee for dates that are incrementing less than 3 days.
--					Also consider the situation where the Source of Quantity for each of the Service
--					and Disbursement components of the calculations are based on a period of time
--					between two dates however the base date for each component is a different Event.
-- 15 Aug 2007	MF	15103	25	Revisit to include @pdtTransactionDate parameter to call to FEESCALC.
-- 17 Aug 2007	MF	15103	26	Revisit to correct problem when fees being run for explicit cycle.
-- 17 Aug 2007	MF	15103	27	Discount needs to be included in the Source Value.
-- 28 Aug 2007	MF	15276	28	The event used in the Fees Calculation to determine when fee increases are to
--					occur needs to be calculated for simulated Cases and where the date of the fee 
--					change is to occur.
-- 21 Sep 2007	MF	15384	29	Display result for Fee Enquiry even if Event indicates the Fee is no longer
--					required if the procedure is called from Centura.
-- 28 Sep 2007	CR	14901	30	Changed Exchange Rate field sizes to (8,4)
-- 03 Oct 2007	MF	15384	31	Generate simulated dates even if user defined stored procedure is used in calculation.
-- 23 Nov 2007	MF	RFC5991	32	The Incurred Event associated with a Charge Type is not to suppress the fee
--					calculations if the fee is being displayed for one specific Case.
-- 27 Nov 2007	MF	15642	33	Ensure the date used to determine the fee to use is calculated for each different
--					fee calculation.
-- 03 Dec 2007	MF	15657	34	Margins are able to take into consideration the Action that raised the charge. For
--					fee enquiries the Action is not known so the only way to simulate the margin is
--					to consider the ChargeDueEvent associated with the the ChargeType and use the 
--					Action for that Event.
-- 05 Dec 2007	CR	14649	35	Extended to cater for Multi-Tier Tax. Tax returned is the total of Federal and State Tax
-- 22 Jan 2008	MF	15851	36	Allow the Basis to be passed as a parameter.
-- 30 Jan 2008	MF	15893	37	A fee needs to be calculated as at the date of a possible scheduled fee change.
-- 01 Feb 2008	MF	15899	38	Simulated dates at which fees may vary for a simulated Case are to be
--					calculated from the entered Renewal Date if the real EventNo used in the 
--					calculation is listed in the Site Control "Substitute In Renewal Date" 
-- 05 Feb 2008	MF	14649	39	Revisit 14649 as the changes resulted in SQL code being truncated.
-- 11 Feb 2008	MF	15943	40	Do not use historical exchange rates for Fee Enquiries.  Use the current exchange rate.
-- 27 Feb 2008	MF	16034	41	Do not remove rows whose fees match the immediately earlier fees unless the
--					date for which the fee is being calculated is a simulated date indicated 
--					by STEPDATEFLAG=1.
-- 26 Mar 2008	MF	RFC6353	42	Incorrect fee was being calculated in some situations where a temporary table of
--					Cases was being passed as a parameter along with different ChargeTypeNo. The
--					procedure was attempting to use the @pnChargeTypeNo when simulating date 
--					variations when it should have been using the CHARGETYPENO in the temp table.
-- 26 May 2008	MF	16455	43	Revisit SQA14649 as results returned were incorrect.
-- 08 Oct 2008	MF	16956	44	Need to get the exact FEESCALCULATION row that will be used so that we can correctly
--					determine if there are fees that will vary by date. Previously we were just taking the
--					first FEESCALCULATION row for the correct CriteriaNo (for performance) as we assumed that
--					the basic structure of the calculation would be the same.  This was an incorrect assumption
--					as some Agent specific fees calculate their extension fees (fines) differently.
-- 11 Sep 2008	MF	16914	45	When fees for all cycles are to be displayed the wrong result was returned.
-- 18 Nov 2008	MF	RFC7302	46	Fees that have a variable calculation that effectively works as a minimum value are to be
--					considered. If the Service Charge is less than the Variable Fee then replace with the Variable fee.
-- 11 Dec 2008	MF	17136	47	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 29 Jan 2009	MF	RFC7565	48	SQL Error when data being translated because @sSQLString not large enough for dynamic SQL.
-- 01 May 2009  LP      RFC7957 49      Fix STEPDATEFLAG such that rates incurred in the past but still applicable for
--                                      the current date are not flagged and therefore displayed to external WorkBenches users.
-- 10 Jun 2009	MF	17748	50	Reduce locking level to ensure other activities are not blocked.
-- 12 Jun 2009	MF	17781	51	'All' years on annuities/fees and charges screen (case program) are not displaying
-- 01 Dec 2009	MF/LP	RFC8260	52	Implement logic to cache any calculated fees for matching cases
--					depending on when they were last calculated.
-- 09 Dec 2009	MF	RFC8260	53	Revisit as some background fee calculations were failing.
-- 21 Jan 2010	MF	RFC8830	54	Change of name of QUERY table row as potential existed for duplicate name.
-- 29 Jan 2010	MS	RFC100182 55	Change the size of sqlString variabe to nvarchar(max)
-- 02 Feb 2010	MF	SQA18429 56	Budget forcast that includes multiple Charge Types are showing an increase fee calculation
--					because the rate calculations from the other Charge Type(s) were being backloaded incorrectly
--					into the other Charge Type(s).
--					Also the FeeDueDateAny column was not returning a value if no date range was supplied.
-- 08 Feb 2010	MF	RFC8883	57	Allow user control over the wording used on email generated to indicate that 
--					fee calculations are being done in background and change the format of the address
--					used in the name of the saved query.                                  
-- 23 Feb 2010	vql	18470	58	Bug in fees and charges reports.
-- 22 Apr 2010	MF	18127	59	Previously saved estimates not being reported correctly.
-- 14 May 2010	MF	RFC9071	60	When multiple actions are open use the highest cycle for determining the fee. This is likely to 
--					occur where an earlier cycle has not been closed when fees for the next cycle need to be displayed.
-- 31 May 2010	MF	18615	61	No results were being returned when @pnRateNo and @psGlobalTempTable being passed as parameters.
-- 18 Jun 2010	MF	18615	62	Revisit. Return fees for all following cycles if @pnRateNo is provided.
-- 25 Jun 2010	MF	18826	63	Allow the temporary table of Cases passed to the procedure to also include a CYCLE if the fee to be calculated is
--					to use a specific CYCLE.
-- 25 Jun 2010	MF	18833	64	Where multiple cycles are being displayed for a Case and a specific Event indicating when charge variations occur is
--					not available then use the Renewal Date for the Cycle to indicate when the charge is valid from.
-- 01 Jul 2010	MF	18758 	65	Increase the column size of Instruction Type to allow for expanded list.
-- 13 Aug 2010	MF	 18980	66	The highest cycle for a multi cycle Event was not being used because the rate being calculated did not have a
--					Renewal rate type but the cycle for the Next Renewal date was still being used.
--					Also add CYCLE to the #TEMPBACKGROUNDCASES temporary table
-- 27 Aug 2010	MF	RFC9707  66	When a @pdtFromDate and/or @pdtUntilDate were being included, it was possible for multiple cycles to match which
--					SQLServer would randomly apply. If the different Rate Calculations making up the Charge received different cycles
--					then an incorrect final fee would result.
-- 14 Jan 2011	MF	19318	67	When getting estimate need to consider that TAXRATESCOUNTRY may hold tax rates that start from an effective date.
-- 03 Mar 2011	MF	19453	68	When determining the Cycle to use for a particular Year, make sure Country and PropertyType of the passed Case is considered.
-- 27 May 2011	MF	19631	69	If @pbDyamicChargeType=0 then make sure you do not refer to the CHARGETYPENO on the temporary table passed in as the column
--					will not exist.
-- 07 Jul 2011	DL	RFC10830 70	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 03 Nov 2011	MF	R11501	71	Fees being displayed are duplicated in some situations.
-- 27 Aug 2012	MF	R12656	72	Ensure non cyclic Events use cycle 1 when determining the dates to be used for which charges are to be calculated.
-- 03 Oct 2012	MF	R12806	73	Allow dynamic SQL to exceed 4000 bytes.
                                        
-- 22 Feb 2013	MF	R13222	74	Fee with different calculations depending on age of case is not being calculated.
-- 01 Mar 2013	MF	R13222	75	Also change to loading of CASECHARGESCACHE to due to duplicate key error when multiple FROMDATE values were loaded.
-- 28 May 2013	MF	R13540	76	Removed reference to xp_SendMail which is unsupported from SQLServer 2012.
-- 07 Feb 2014	DL	21903	77	Incorrect estimate for Professional Fees 
-- 17 Dec 2014	MF	R42619	78	Ensure the USERDEFINEDRULE flag is considered when determining the best CRITERIA to use.
-- 29 Dec 2014	MF	R42684	79	Estimated fee not being returned where it has been saved for a Cycle but the fees are not configured by year.
-- 20 Oct 2015  MS      R53933  80      Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 07 Jul 2016	MF	63861	81	A null LOCALCLIENTFLAG should default to 0.
-- 23 Mar 2017  Team2	R70762  82	Minor modification to address an issue where tax was not calculated for some estimates due to missing Tax Code.
-- 07 Sep 2018	AV	74738	83	Set isolation level to read uncommited.

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- If standing instructions are required to determine what are
-- the Rates to use for a particularul Charge Type then the
-- following temporary table will be required to store the
-- derived instructions.
Create table #TEMPCASEINSTRUCTIONS (
			CASEID			int		NOT NULL,
			INSTRUCTIONTYPE		nvarchar(3)	collate database_default NULL, 
			INSTRUCTIONCODE		smallint	NULL)

-- A table is required to expand the CHARGETYPENO out
-- into the multiple derived RATENOs for each Case.
-- This interim table was included while performance tuning.
create table #TEMPCASERATES(
			CASEID			INT	NULL,
			CHARGETYPENO		INT	NULL,
			RATENO			INT	NOT NULL,
			AGENTNAMETYPE		nvarchar(3) collate database_default NULL,
			DEBTORNAMETYPE		nvarchar(3) collate database_default NULL,
			CRITERIANO		INT	NULL,
			AGENT			INT	NULL,
			DEBTOR			INT	NULL,
			DEBTORTYPE		INT	NULL,
			OWNER			INT	NULL,
			INSTRUCTOR		INT	NULL)

-- We will need a unique set of Case characteristics for each debtor that potentially
-- could have different fee calcualtions associated with them.

create table #TEMPCASECHARGES
		(	SEQUENCENO		int		null,
			NOCALCFLAG		bit		null	default 0,
			CASEID			int		null,
			IRN			nvarchar(30)	collate database_default null,
			YEARNO			smallint	null,
			CYCLE			smallint	null,
			RENEWALDATE		datetime	null,
			FROMDATE		datetime	null,
			STARTDATE1		datetime	null,	-- Starting date for fees that vary by date for Disbursement part of calculation
			STARTDATE2		datetime	null,	-- Starting date for fees that vary by date for Service charge part of calculation
			STEPDATEFLAG		bit		null	default 0,
			ISEXPIREDSTEP		bit 		null	default 0, -- Indicates a stepped calculation that is out of date
			BASEDATE1		datetime	null,	-- date from which quantity 1 date variations occur
			BASEDATE2		datetime	null,	-- date from which quantity 2 date variations occur
			CHARGETYPENO		int		null,
			RATENO			int		null,
			RATETYPE		int		null,
			RATEDESC		nvarchar(50)	collate database_default null,
			CALCLABEL1		nvarchar(30)	collate database_default null,
			CALCLABEL2		nvarchar(30)	collate database_default null,
			FROMEVENTNO1		int		null,
			UNTILEVENTNO1		int		null,
			PERIODTYPE1		nchar(1)	collate database_default null,
			FROMEVENTNO2		int		null,
			UNTILEVENTNO2		int		null,
			PERIODTYPE2		nchar(1)	collate database_default null,
			EXTENSIONPERIOD		smallint	null,
			CRITERIANO		int		null,
			UNIQUEID		int		null,
			DISBBASEFEE		decimal(11,2)	null,
			DISBBASEUNITS		smallint	null,
			DISBVARIABLEFEE		decimal(11,2)	null,
			DISBUNITSIZE		smallint	null,
			DISBMAXUNITS		smallint	null,
			SERVBASEFEE		decimal(11,2)	null,
			SERVBASEUNITS		smallint	null,
			SERVVARIABLEFEE		decimal(11,2)	null,
			SERVUNITSIZE		smallint	null,
			SERVMAXUNITS		smallint	null,
			ESTIMATEFLAG		bit		null	default 0,
			ESTIMATEDATE		datetime	null,
			DISBCURRENCY		nvarchar(3)	collate database_default null,
			SERVCURRENCY		nvarchar(3)	collate database_default null,
			BILLCURRENCY		nvarchar(3)	collate database_default null,
			DISBAMOUNT		decimal(11,2)	null	default 0,
			DISBHOMEAMOUNT		decimal(11,2)	null	default 0,
			DISBBILLAMOUNT		decimal(11,2)	null	default 0,
			SERVAMOUNT		decimal(11,2)	null	default 0,
			SERVHOMEAMOUNT		decimal(11,2)	null	default 0,
			SERVBILLAMOUNT		decimal(11,2)	null	default 0,
			DISBDISCORIGINAL	decimal(11,2)	null	default 0,
			DISBHOMEDISCOUNT	decimal(11,2)	null	default 0,
			DISBBILLDISCOUNT	decimal(11,2)	null	default 0,
			SERVDISCORIGINAL	decimal(11,2)	null	default 0,
			SERVHOMEDISCOUNT	decimal(11,2)	null	default 0,
			SERVBILLDISCOUNT	decimal(11,2)	null	default 0,
			TOTHOMEDISCOUNT		decimal(11,2)	null	default 0,
			TOTBILLDISCOUNT		decimal(11,2)	null	default 0,
			DISBMARGIN		decimal(11,2)	null	default 0,
			DISBHOMEMARGIN		decimal(11,2)	null	default 0,
			DISBBILLMARGIN		decimal(11,2)	null	default 0,
			SERVMARGIN		decimal(11,2)	null	default 0,
			SERVHOMEMARGIN		decimal(11,2)	null	default 0,
			SERVBILLMARGIN		decimal(11,2)	null	default 0,
			DISBTAXAMT		decimal(11,2)	null	default 0,
			DISBTAXHOMEAMT		decimal(11,2)	null	default 0,
			DISBTAXBILLAMT		decimal(11,2)	null	default 0,
			SERVTAXAMT		decimal(11,2)	null	default 0,
			SERVTAXHOMEAMT		decimal(11,2)	null	default 0,
			SERVTAXBILLAMT		decimal(11,2)	null	default 0,
			DISBSTATETAXAMT		decimal(11,2)	null	default 0, -- 14649 State amounts from multi-tier tax processing
			DISBSTATETAXHOMEAMT	decimal(11,2)	null	default 0,
			DISBSTATETAXBILLAMT	decimal(11,2)	null	default 0,
			SERVSTATETAXAMT		decimal(11,2)	null	default 0,
			SERVSTATETAXHOMEAMT	decimal(11,2)	null	default 0,
			SERVSTATETAXBILLAMT	decimal(11,2)	null	default 0,
			DISBSOURCEAMT		decimal(11,2)	null	default	0,
			SERVSOURCEAMT		decimal(11,2)	null	default	0,
			DISBTAXCODE		nvarchar(3)	collate database_default null,
			SERVTAXCODE		nvarchar(3)	collate database_default null,
			DISBSTATETAXCODE	nvarchar(3)	collate database_default null, -- 14649 State Tax Codes
			SERVSTATETAXCODE	nvarchar(3)	collate database_default null,
			SOURCECOUNTRY		nvarchar(3)	collate database_default null,
			SOURCESTATE		nvarchar(20)	collate database_default null, -- 14649 Source state
			DISBWIPCODE		nvarchar(6)	collate database_default null, -- RFC3218
			SERVWIPCODE		nvarchar(6)	collate database_default null, -- RFC3218
			USEEVENTNO		int		null,
			CHARGEEVENT		int		null,
			CHARGEACTION		nvarchar(2)	collate database_default null
		)

 CREATE INDEX XIE1TEMPCHARGES ON #TEMPCASECHARGES
 (
        CASEID, 
	YEARNO, 
	ESTIMATEFLAG
 )

-- A temporary table used to generate a sequence numbers is required
Create table #TEMPSEQUENCE(
			SEQUENCENO		smallint	identity(0,1),
			TINYBIT			bit
			)
-- A temporary table to used to store simulated Event Due Date
-- for What If cases.
Create table #TEMPDUMMYEVENTS(
			SEQUENCENO		smallint	identity(1,1),
			EVENTNO			int		NOT NULL,
			EVENTDUEDATE		datetime	NULL
			)
			
-- A temporary table for holding the Cases and Charges
-- to be calculated when this process is running as a
-- background task.

Create table #TEMPBACKGROUNDCASES 
			(
			CASEID			int		NOT NULL,
			CHARGETYPENO		int		NOT NULL,
			ROWNUMBER		int		identity(1,1),
			DEFINITIONID		int		NULL,
			InstructionCycleAny	int		NULL,	-- Leave as lowercase
			FeeYearNoAny		decimal(11,2)	NULL,	-- Leave as lowercase
			FeeDueDateAny		datetime	NULL,	-- Leave as lowercase
			CYCLE			int		NULL
			)

declare @tblExtendedColumns table (COLUMNNAME	nvarchar(60) collate database_default not null)

DECLARE	@ErrorCode		int,
	@nRowCount		int,
	@nInsertedRows		int,
	@nCurrentRow		int,
	@nMaxRowNumber		int,
	@nRateNo		int,
	@sSQLString		nvarchar(max),
	@sSQLString1		nvarchar(max),
	@sSelect		nvarchar(max),
	@sFrom			nvarchar(max),
	@sWhere			nvarchar(max),
	@sOrderBy		nvarchar(100),
	@sColumnList		nvarchar(1000),
	@sSelectList		nvarchar(1000),
	@sInstructionTypes	nvarchar(200),
	@sSubject		nvarchar(100),
	@sQuery			nvarchar(50),
	@sIRN			nvarchar(30),
	@nYearNo		smallint,
	@nCycle			tinyint,
	@nExtensionPeriod	smallint,
	@sSourceCountryCode 	nvarchar(3),
	@sSourceState	 	nvarchar(20), -- 14649 Source State used for Multi-tier tax
	@nEventNo		int,
	@nEmployeeNo		int,
	@nLapseEventNo		int,
	@nUseEventNo		int,
	@nChargeEventNo		int,
	@nCriteriaNo		int,
	@sAction		nvarchar(2),
	@sSavedAction		nvarchar(2),
	@dtRenewalDate		datetime,
	@dtLapseDate		datetime,
	@dtFromDateDisb		datetime,
	@dtFromDateServ		datetime,
	@dtUntilDate		datetime,
	@dtDueDate		datetime,
	@dtNow			datetime,
	@bNoCalcFlag		bit,
	@bBackgroundTask	bit,
	@nSequenceNo		int,
	@nFromEventNoDisb	int,
	@nFromEventNoServ	int,
	@nSaveCheckSum		int,
	@nSaveCheckSum1		int,
	@nDateFormat		tinyint,
	@sProfileName		nvarchar(254),
	@sSQLDocItem		nvarchar(4000),
	@sBody			nvarchar(4000)

-- Variable to be returned as output parameters from FEESCALC.

declare @prsDisbCurrency 	varchar(3),	
	@prnDisbExchRate 	decimal(11,4), 
	@prsServCurrency 	varchar(3) , 	
	@prnServExchRate 	decimal(11,4) , 
	@prsBillCurrency 	varchar(3) , 	
	@prnBillExchRate 	decimal(11,4) , 
	@prnDisbNarrative 	int 	, 		
	@prnServNarrative 	int 	, 
	@prsDisbWIPCode 	varchar(6) , 	
	@prsServWIPCode 	varchar(6) , 
	@prnDisbAmount 		decimal(11,2) , 	
	@prnDisbHomeAmount 	decimal(11,2) , 
	@prnDisbBillAmount 	decimal(11,2) ,
	@prnServAmount 		decimal(11,2) , 
	@prnServHomeAmount 	decimal(11,2) ,
	@prnServBillAmount 	decimal(11,2) , 
	@prnTotHomeDiscount 	decimal(11,2) ,
	@prnTotBillDiscount 	decimal(11,2) , 
	@prsDisbTaxCode 	varchar(3) , 	
	@prsServTaxCode 	varchar(3) , 
	@prnDisbTaxAmt 		decimal(11,2) , 	
	@prnDisbTaxHomeAmt 	decimal(11,2) , 
	@prnDisbTaxBillAmt 	decimal(11,2) ,
	@prnServTaxAmt 		decimal(11,2) , 	
	@prnServTaxHomeAmt 	decimal(11,2) ,
	@prnServTaxBillAmt 	decimal(11,2) ,	
	@prnVariableFeeAmt	decimal(11,2) ,
	@prnVarHomeFeeAmt	decimal(11,2) ,
	@prnVarBillFeeAmt	decimal(11,2) ,
	@prnVarTaxAmt		decimal(11,2) ,
	@prnVarTaxHomeAmt	decimal(11,2) ,
	@prnVarTaxBillAmt	decimal(11,2) ,
	@prnDisbDiscOriginal	decimal(11,2) ,
	@prnDisbHomeDiscount 	decimal(11,2) ,
	@prnDisbBillDiscount 	decimal(11,2) ,
	@prnServDiscOriginal	decimal(11,2) ,
	@prnServHomeDiscount 	decimal(11,2) ,
	@prnServBillDiscount 	decimal(11,2) ,
	@prnDisbCostHome	decimal(11,2) ,
	@prnDisbCostOriginal	decimal(11,2) ,
	@prnDisbMargin		decimal(11,2) ,
	@prnDisbHomeMargin	decimal(11,2) ,
	@prnDisbBillMargin	decimal(11,2) ,
	@prnServMargin		decimal(11,2) ,
	@prnServHomeMargin	decimal(11,2) ,
	@prnServBillMargin	decimal(11,2) ,
	@pnDisbSourceAmt	decimal(11,2) ,
	@pnServSourceAmt	decimal(11,2) ,
	-- 14649 Multi-tier Tax
	@prsDisbStateTaxCode 	nvarchar(3), 
	@prsServStateTaxCode 	nvarchar(3), 
	@prnDisbStateTaxAmt 	decimal(11,2), 
	@prnDisbStateTaxHomeAmt decimal(11,2), 
	@prnDisbStateTaxBillAmt decimal(11,2), 
	@prnServStateTaxAmt 	decimal(11,2), 
	@prnServStateTaxHomeAmt decimal(11,2), 
	@prnServStateTaxBillAmt decimal(11,2)


-- WorkBenches
Declare @bIsExternalUser	bit
Declare	@bCanViewCalculations	bit
Declare	@bCanViewByCategory	bit
Declare	@bCanViewByRate		bit
Declare	@bCanViewElements	bit
Declare	@bCanViewEstimates	bit
Declare	@bTaxRequired		bit
Declare @dtToday		datetime
Declare @sLookupCulture		nvarchar(10)
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint
Declare @sDerivedTableSQL	nvarchar(max)

set transaction isolation level read uncommitted

Set @ErrorCode =0
Set @sSQLString=0
Set @bBackgroundTask=0
Set @dtToday=getdate()

-- Is Tax in use?
If @ErrorCode=0
Begin
	Set @sSQLString = "
	select @bTaxRequired = COLBOOLEAN
	from	SITECONTROL
	where	CONTROLID='TAXREQUIRED'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@bTaxRequired			bit		OUTPUT',
					  @bTaxRequired			= @bTaxRequired	OUTPUT

End

-----------------------------------------
-- Special processing when the procedure
-- is being executed as a background task
-----------------------------------------
If @psGlobalTempTable is null
and @pdtWhenRequested is not null
and @pnSPID           is not null
and @ErrorCode=0
Begin	
	Set @bBackgroundTask=1
	-----------------------------------------------------
	-- When the procedure is run as a background task
	-- it is not possible to pass a global temporary 
	-- table with the Cases and Charges to be calculated.
	-- This is because the temporary table will be 
	-- distroyed as soon as the calling connection is
	-- closed.
	-- The CASECHARGESCACHE table is used to pass this
	-- information to the background task.  It is then
	-- loaded into a temporary table created within the
	-- background task.
	-----------------------------------------------------
	Set @psGlobalTempTable='#TEMPBACKGROUNDCASES'

	Set @sSQLString="
	insert into #TEMPBACKGROUNDCASES(CASEID,CHARGETYPENO,DEFINITIONID,InstructionCycleAny,FeeYearNoAny,FeeDueDateAny)
	select CASEID,CHARGETYPENO,DEFINITIONID,INSTRUCTIONCYCLEANY,FEEYEARNOANY,FEEDUEDATEANY
	from CASECHARGESCACHE
	where WHENCALCULATED=@pdtWhenRequested
	and SPIDREQUEST=@pnSPID"
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pdtWhenRequested	datetime,
					  @pnSPID		int',
					  @pdtWhenRequested=@pdtWhenRequested,
					  @pnSPID          =@pnSPID
	-------------------------------------------
	-- Drop the columns that are not being used
	-- as this will have an impact on how the
	-- fees are to be calculated.
	-------------------------------------------
	Set @sSQLString=null
	If not exists (select 1 from #TEMPBACKGROUNDCASES where DEFINITIONID is not null)
		Set @sSQLString='DEFINITIONID'
		
	If not exists(select 1 from #TEMPBACKGROUNDCASES where InstructionCycleAny is not null)
	Begin
		If @sSQLString is not null
			set @sSQLString=@sSQLString+','+'InstructionCycleAny'
		Else
			set @sSQLString='InstructionCycleAny'
	End
		
	If not exists(select 1 from #TEMPBACKGROUNDCASES where FeeYearNoAny=1)
	Begin
		If @sSQLString is not null
			set @sSQLString=@sSQLString+','+'FeeYearNoAny'
		Else
			set @sSQLString='FeeYearNoAny'
	End
		
	If not exists(select 1 from #TEMPBACKGROUNDCASES where FeeDueDateAny is not null)
	Begin
		If @sSQLString is not null
			set @sSQLString=@sSQLString+','+'FeeDueDateAny'
		Else
			set @sSQLString='FeeDueDateAny'
	End

	If @sSQLString is not null
	Begin
		Set @sSQLString='ALTER TABLE #TEMPBACKGROUNDCASES drop column '+@sSQLString
		exec @ErrorCode=sp_executesql @sSQLString
	End
End

---------------------------------------------
-- SQA18826
-- If a temporary table of Cases has been
-- supplied then check if the table includes
-- the CYCLE column. If not then add this to 
-- the table for consistency.
---------------------------------------------
If  @ErrorCode=0
and @psGlobalTempTable is not null
Begin
	If not exists(SELECT 1 FROM tempdb.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_CATALOG='tempdb' and TABLE_NAME like @psGlobalTempTable+'%' AND COLUMN_NAME = 'CYCLE')
	begin
		set @sSQLString='ALTER TABLE '+@psGlobalTempTable+' add CYCLE int null'
		exec(@sSQLString)
		Set @ErrorCode=@@Error
	End
End

-- Extended Case details are identified by the DynamicChargeType
-- flag being on.  Get the columns required to be extracted.
If @pbDyamicChargeType=1
and @ErrorCode=0
Begin
	-- Load the columns that are to be extracted 
	Insert into @tblExtendedColumns(COLUMNNAME)
	Select COLUMN_NAME 
	From tempdb.INFORMATION_SCHEMA.COLUMNS 
	Where TABLE_NAME = @psGlobalTempTable
	and COLUMN_NAME<>'ROWNUMBER'
	
	Set @ErrorCode=@@Error
End

-- Check user's security to view the data
If @ErrorCode=0
and @pbCalledFromCentura = 1
Begin
	Set @bCanViewCalculations=1
	Set @bCanViewEstimates=1
End
Else If @ErrorCode=0
and @pbCalledFromCentura = 0
Begin
	set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

	-- Is user internal or external?
	Set @sSQLString = "
	Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @bIsExternalUser		bit			OUTPUT',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @bIsExternalUser		= @bIsExternalUser	OUTPUT

	-- Check subject security for Fees and Charges Calculations
	If @ErrorCode=0
	Begin
		Set @sSQLString = "
		select 	@bCanViewCalculations	= sum(case when TopicKey=1 then IsAvailable else 0 end),
			@bCanViewByCategory	= sum(case when TopicKey=4 then IsAvailable else 0 end),
			@bCanViewByRate		= sum(case when TopicKey=5 then IsAvailable else 0 end),
			@bCanViewElements	= sum(case when TopicKey=6 then IsAvailable else 0 end),
			@bCanViewEstimates	= sum(case when TopicKey=3 then IsAvailable else 0 end)
		from	dbo.fn_GetTopicSecurity(@pnUserIdentityId, '1,3,4,5,6', 0, @dtToday)"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId		int,
						  @bCanViewCalculations		bit			OUTPUT,
						  @bCanViewByCategory		bit			OUTPUT,
						  @bCanViewByRate		bit			OUTPUT,
						  @bCanViewElements		bit			OUTPUT,
						  @bCanViewEstimates		bit			OUTPUT,
						  @dtToday			datetime',
						  @pnUserIdentityId		= @pnUserIdentityId,
						  @bCanViewCalculations		= @bCanViewCalculations	OUTPUT,
						  @bCanViewByCategory		= @bCanViewByCategory	OUTPUT,
						  @bCanViewByRate		= @bCanViewByRate	OUTPUT,
						  @bCanViewElements		= @bCanViewElements	OUTPUT,
						  @bCanViewEstimates		= @bCanViewEstimates	OUTPUT,
						  @dtToday			= @dtToday
	End

	-- Does user have access to the charge?
	If @ErrorCode=0
	and @bIsExternalUser=1
	and not exists (select 1 from dbo.fn_FilterUserChargeTypes(@pnUserIdentityId,1,null,@pbCalledFromCentura) where CHARGETYPENO=@pnChargeTypeNo)
	Begin
		-- Return empty result sets
		Set @pnChargeTypeNo=null
	End

End

-- Only perform the calculations if the user has appropriate permissions
If @ErrorCode = 0
and @bCanViewCalculations=1
Begin
	-- Check to see if standing instructions are required to be derived for the Case(s)
	-- in order to determine what RateNos are associated with the Charge Types.
	If @pbDyamicChargeType=1
	Begin
		Set @sSQLString="
		Select @sInstructionTypes=CASE WHEN(@sInstructionTypes is not null) 
							THEN @sInstructionTypes+','+C.INSTRUCTIONTYPE
							ELSE C.INSTRUCTIONTYPE
					  END
		from (	select distinct CR.INSTRUCTIONTYPE
			from "+@psGlobalTempTable+" T
			join CHARGERATES CR	on (CR.CHARGETYPENO=T.CHARGETYPENO)
			where CR.INSTRUCTIONTYPE is not null) C"
	
		Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@sInstructionTypes	nvarchar(200)	output',
					  @sInstructionTypes=@sInstructionTypes	output
	End
	Else If @pnChargeTypeNo is not Null
	Begin
		Set @sSQLString="
		Select @sInstructionTypes=CASE WHEN(@sInstructionTypes is not null) 
							THEN @sInstructionTypes+','+C.INSTRUCTIONTYPE
							ELSE C.INSTRUCTIONTYPE
					  END
		from ( 	select distinct INSTRUCTIONTYPE
			from CHARGERATES C
			where C.CHARGETYPENO=@pnChargeTypeNo
			and   C.INSTRUCTIONTYPE is not null) C"
	
		Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@sInstructionTypes	nvarchar(200)	output,
					  @pnChargeTypeNo	int',
					  @sInstructionTypes=@sInstructionTypes	output,
					  @pnChargeTypeNo   =@pnChargeTypeNo
	End

	-- Now get the Standing Instructions if they are required
	If @sInstructionTypes is not null
	and @ErrorCode=0
	Begin
		If  @psGlobalTempTable is not null
		Begin
			Exec @ErrorCode=dbo.cs_GetStandingInstructionsBulk 
						@psInstructionTypes=@sInstructionTypes,
						@psCaseTableName   =@psGlobalTempTable
		End
		Else If	@pnCaseId is not null
		Begin
			Set @sSQLString="
			Insert into #TEMPCASEINSTRUCTIONS(CASEID, INSTRUCTIONTYPE,INSTRUCTIONCODE)
			select @pnCaseId, I.INSTRUCTIONTYPE, dbo.fn_StandingInstruction(@pnCaseId,I.INSTRUCTIONTYPE)
			from INSTRUCTIONTYPE I
			where INSTRUCTIONTYPE "+dbo.fn_ConstructOperator(0,'CS',@sInstructionTypes, null,0)
	
			Exec @ErrorCode=sp_executesql @sSQLString, 
						N'@pnCaseId	int',
						  @pnCaseId   =@pnCaseId
		End
	End

	-- Derive the RATENOs for each CHARGETYPENO and CASE combination
	If @ErrorCode=0
	and @pnRateNo is not null
	and @pnCaseId is not null
	Begin
		Set @sSelect="Insert into #TEMPCASERATES(CASEID, RATENO) Values (@pnCaseId, @pnRateNo)"
	End
	Else If @ErrorCode=0
	     and @pnRateNo is not null
	     and @psGlobalTempTable is not null
	Begin
		Set @sSelect="Insert into #TEMPCASERATES(CASEID, RATENO)"+char(10)+
			     "Select T.CASEID, @pnRateNo "+char(10)+
			     "From "+@psGlobalTempTable+' T'+char(10)+
			     "join CASES C on (C.CASEID=T.CASEID)"
	End
	Else If @ErrorCode=0
	Begin
		Set @sSelect="Insert into #TEMPCASERATES(CASEID,CHARGETYPENO,RATENO,AGENTNAMETYPE,DEBTORNAMETYPE)"+char(10)+
			     "Select C.CASEID,H.CHARGETYPENO,H.RATENO,R.AGENTNAMETYPE,CASE WHEN(R.RATETYPE=1601) THEN 'Z' ELSE 'D' END"

		If @psGlobalTempTable is not null
		Begin
			Set @sFrom="From "+@psGlobalTempTable+' T'+char(10)+
				   "join CASES C on (C.CASEID=T.CASEID)"
		End
		Else If @pnCaseId is not null
		Begin
			Set @sFrom="From CASES C"
	
			Set @sWhere	="Where C.CASEID=@pnCaseId"
		End

		If @psGlobalTempTable is not null
		OR @pnCaseId is not null
		Begin			
			Set @sFrom=@sFrom+char(10)+
			"left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID=C.CASEID)"+char(10)+
			"left join INSTRUCTIONFLAG FL       on (FL.INSTRUCTIONCODE=CI.INSTRUCTIONCODE)"+char(10)+
			"join CHARGERATES H on (H.CHARGETYPENO="+CASE WHEN(@pbDyamicChargeType=1) THEN "T.CHARGETYPENO" ELSE "@pnChargeTypeNo" END+char(10)+
			"		and(CASE WHEN(H.CASETYPE     is null) THEN '0' ELSE '1' END+"+char(10)+
			"		    CASE WHEN(H.PROPERTYTYPE is null) THEN '0' ELSE '1' END+"+char(10)+
			"		    CASE WHEN(H.COUNTRYCODE  is null) THEN '0' ELSE '1' END+"+char(10)+
			"		    CASE WHEN(H.CASECATEGORY is null) THEN '0' ELSE '1' END+"+char(10)+
			"		    CASE WHEN(H.SUBTYPE      is null) THEN '0' ELSE '1' END+"+char(10)+
			"		    CASE WHEN(H.FLAGNUMBER   is null) THEN '0' ELSE '1' END)"+char(10)+
			"				=(select max(CASE WHEN(H1.CASETYPE     is null) THEN '0' ELSE '1' END+"+char(10)+
			"					     CASE WHEN(H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+"+char(10)+
			"					     CASE WHEN(H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+"+char(10)+
			"					     CASE WHEN(H1.CASECATEGORY is null) THEN '0' ELSE '1' END+"+char(10)+
			"					     CASE WHEN(H1.SUBTYPE      is null) THEN '0' ELSE '1' END+"+char(10)+
			"		    			     CASE WHEN(H1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)"+char(10)+
			"				from CHARGERATES H1"+char(10)+
			"				where H1.CHARGETYPENO   =H.CHARGETYPENO"+char(10)+
			"				and   H1.RATENO         =H.RATENO"+char(10)+
			"				and  (H1.CASETYPE       =C.CASETYPE         OR H1.CASETYPE        is null)"+char(10)+
			"				and  (H1.PROPERTYTYPE   =C.PROPERTYTYPE     OR H1.PROPERTYTYPE    is null)"+char(10)+
			"				and  (H1.COUNTRYCODE    =C.COUNTRYCODE	    OR H1.COUNTRYCODE     is null)"+char(10)+
			"				and  (H1.CASECATEGORY   =C.CASECATEGORY     OR H1.CASECATEGORY    is null)"+char(10)+
			"				and  (H1.SUBTYPE        =C.SUBTYPE          OR H1.SUBTYPE         is null)"+char(10)+
			"				and  (H1.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H1.INSTRUCTIONTYPE is null)"+char(10)+
			"				and  (H1.FLAGNUMBER     =FL.FLAGNUMBER      OR H1.FLAGNUMBER      is null))"+char(10)+
			"		and  (H.CASETYPE       =C.CASETYPE         OR H.CASETYPE        is null)"+char(10)+
			"		and  (H.PROPERTYTYPE   =C.PROPERTYTYPE     OR H.PROPERTYTYPE    is null)"+char(10)+
			"		and  (H.COUNTRYCODE    =C.COUNTRYCODE      OR H.COUNTRYCODE     is null)"+char(10)+
			"		and  (H.CASECATEGORY   =C.CASECATEGORY     OR H.CASECATEGORY    is null)"+char(10)+
			"		and  (H.SUBTYPE        =C.SUBTYPE          OR H.SUBTYPE         is null)"+char(10)+
			"		and  (H.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H.INSTRUCTIONTYPE is null)"+char(10)+
			"		and  (H.FLAGNUMBER     =FL.FLAGNUMBER      OR H.FLAGNUMBER      is null))"+char(10)+
			"join RATES R on (R.RATENO=H.RATENO)"
		End
		Else Begin
			-- A simulated set of Case characteristics is being used rather than a real Case
	
			Set @sSelect="Insert into #TEMPCASERATES(CHARGETYPENO, RATENO, AGENT, DEBTOR, DEBTORTYPE, INSTRUCTOR)"+char(10)+
				     "Select H.CHARGETYPENO, H.RATENO,@pnAgent,@pnDebtor,@pnDebtorType,@pnInstructor"

			Set @sFrom="From CHARGERATES H"

			Set @sWhere="Where H.CHARGETYPENO=@pnChargeTypeNo"+char(10)+
				"and(CASE WHEN(H.CASETYPE     is null) THEN '0' ELSE '1' END+"+char(10)+
				"    CASE WHEN(H.PROPERTYTYPE is null) THEN '0' ELSE '1' END+"+char(10)+
				"    CASE WHEN(H.COUNTRYCODE  is null) THEN '0' ELSE '1' END+"+char(10)+
				"    CASE WHEN(H.CASECATEGORY is null) THEN '0' ELSE '1' END+"+char(10)+
				"    CASE WHEN(H.SUBTYPE      is null) THEN '0' ELSE '1' END+"+char(10)+
				"    CASE WHEN(H.FLAGNUMBER   is null) THEN '0' ELSE '1' END)"+char(10)+
				"		=(select max(CASE WHEN(H1.CASETYPE     is null) THEN '0' ELSE '1' END+"+char(10)+
				"			     CASE WHEN(H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+"+char(10)+
				"			     CASE WHEN(H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+"+char(10)+
				"			     CASE WHEN(H1.CASECATEGORY is null) THEN '0' ELSE '1' END+"+char(10)+
				"			     CASE WHEN(H1.SUBTYPE      is null) THEN '0' ELSE '1' END+"+char(10)+
				"    			     CASE WHEN(H1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)"+char(10)+
				"		from CHARGERATES H1"+char(10)+
				"		where H1.CHARGETYPENO   =H.CHARGETYPENO"+char(10)+
				"		and   H1.RATENO         =H.RATENO"+char(10)+
				"		and  (H1.CASETYPE       =@psCaseType     OR H1.CASETYPE     is null)"+char(10)+
				"		and  (H1.PROPERTYTYPE   =@psPropertyType OR H1.PROPERTYTYPE is null)"+char(10)+
				"		and  (H1.COUNTRYCODE    =@psCountryCode	 OR H1.COUNTRYCODE  is null)"+char(10)+
				"		and  (H1.CASECATEGORY   =@psCaseCategory OR H1.CASECATEGORY is null)"+char(10)+
				"		and  (H1.SUBTYPE        =@psSubType	 OR H1.SUBTYPE      is null)"+char(10)+
				"		and   H1.INSTRUCTIONTYPE is null"+char(10)+
				"		and   H1.FLAGNUMBER      is null)"+char(10)+
				"and  (H.CASETYPE       =@psCaseType     OR H.CASETYPE     is null)"+char(10)+
				"and  (H.PROPERTYTYPE   =@psPropertyType OR H.PROPERTYTYPE is null)"+char(10)+
				"and  (H.COUNTRYCODE    =@psCountryCode  OR H.COUNTRYCODE  is null)"+char(10)+
				"and  (H.CASECATEGORY   =@psCaseCategory OR H.CASECATEGORY is null)"+char(10)+
				"and  (H.SUBTYPE        =@psSubType	 OR H.SUBTYPE      is null)"+char(10)+
				"and   H.INSTRUCTIONTYPE is null"+char(10)+
				"and   H.FLAGNUMBER      is null"
		End
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString=@sSelect+char(10)+
				@sFrom+char(10)+
				isnull(@sWhere,'')

		If @pbPrintSQL=1
			Print @sSQLString

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseId		int,
					  @pnChargeTypeNo	int,
					  @psCaseType		nchar(1),
					  @psCountryCode	nvarchar(3),
					  @psPropertyType	nchar(1),
					  @psCaseCategory	nvarchar(2),
					  @psSubType		nvarchar(2),
					  @pnRateNo		int,
					  @pnAgent		int,
					  @pnDebtor		int,
					  @pnDebtorType		int,
					  @pnInstructor		int,
					  @pdtFromDate		datetime',
					  @pnCaseId		=@pnCaseId,
					  @pnChargeTypeNo	=@pnChargeTypeNo,
					  @psCaseType		=@psCaseType,
					  @psCountryCode	=@psCountryCode,
					  @psPropertyType	=@psPropertyType,
					  @psCaseCategory	=@psCaseCategory,
					  @psSubType		=@psSubType,
					  @pnRateNo		=@pnRateNo,
					  @pnAgent		=@pnAgent,
					  @pnDebtor		=@pnDebtor,
					  @pnDebtorType		=@pnDebtorType,
					  @pnInstructor		=@pnInstructor,
					  @pdtFromDate		=@pdtFromDate
	End
	
	-- Now determine the CRITERIANO that will apply for each Case and RateNo
	-- to be calculated and also extract additional characteristics that will 
	-- be required to determine the best FEESCALCULATION row to use.
	If (@psGlobalTempTable is not null
	 OR @pnCaseId is not null)
	Begin
		Set @sSQLString="
		Update T
		Set	AGENT	  =A.NAMENO,
			DEBTOR	  =D.NAMENO,
			DEBTORTYPE=DT.DEBTORTYPE,
			OWNER	  =O.NAMENO,
			INSTRUCTOR=I.NAMENO,
			CRITERIANO=
				(select 
				convert(int,
				Substring ( max(
				CASE WHEN C.CASEOFFICEID    is null THEN '0' ELSE '1' END +
				CASE WHEN C.CASETYPE	    is null THEN '0' ELSE '1' END +
				CASE WHEN C.PROPERTYTYPE    is null THEN '0' ELSE '1' END +
				CASE WHEN C.COUNTRYCODE	    is null THEN '0' ELSE '1' END +
				CASE WHEN C.CASECATEGORY    is null THEN '0' ELSE '1' END +
				CASE WHEN C.SUBTYPE	    is null THEN '0' ELSE '1' END +
				CASE WHEN C.LOCALCLIENTFLAG is null THEN '0' ELSE '1' END +
				CASE WHEN C.TYPEOFMARK      is null THEN '0' ELSE '1' END +
				CASE WHEN C.TABLECODE	    is null THEN '0' ELSE '1' END +
				isnull(convert(char(8),C.DATEOFACT,112),'00000000')+		-- valid from date in YYYYMMDD format
				CASE WHEN (C.USERDEFINEDRULE is NULL
					OR C.USERDEFINEDRULE = 0)   THEN '0' ELSE '1' END +
				convert(char(11),C.CRITERIANO)),19,11))
				from CRITERIA C
				WHERE C.RULEINUSE	  = 1  
				AND C.PURPOSECODE = 'F'  
				AND C.RATENO      = T.RATENO
				AND ( C.CASEOFFICEID	= CS.OFFICEID		OR C.CASEOFFICEID	IS NULL) 
				AND ( C.CASETYPE	= CS.CASETYPE		OR C.CASETYPE		IS NULL) 
				AND ( C.PROPERTYTYPE	= CS.PROPERTYTYPE	OR C.PROPERTYTYPE	IS NULL) 
				AND ( C.COUNTRYCODE	= CS.COUNTRYCODE	OR C.COUNTRYCODE	IS NULL)  
				AND ( C.CASECATEGORY	= CS.CASECATEGORY	OR C.CASECATEGORY	IS NULL) 
				AND ( C.SUBTYPE		= CS.SUBTYPE		OR C.SUBTYPE		IS NULL) 
				AND ( C.LOCALCLIENTFLAG = isnull(CS.LOCALCLIENTFLAG,0)	
										OR C.LOCALCLIENTFLAG	IS NULL) 
				AND ( C.TYPEOFMARK	= CS.TYPEOFMARK		OR C.TYPEOFMARK		IS NULL) 
				AND ( C.TABLECODE	= CS.ENTITYSIZE		OR C.TABLECODE		IS NULL) 
				AND ( C.DATEOFACT      <= getdate()		OR C.DATEOFACT		IS NULL) )
		From #TEMPCASERATES T
		     join CASES CS	on (CS.CASEID=T.CASEID)
		left join CASENAME A	on (A.CASEID = T.CASEID
					and A.EXPIRYDATE is null
					and A.NAMETYPE = T.AGENTNAMETYPE
					and A.SEQUENCE = (	SELECT MIN(A2.SEQUENCE)
								FROM CASENAME A2
								WHERE A2.CASEID = T.CASEID
								AND A2.NAMETYPE = T.AGENTNAMETYPE
								AND A2.EXPIRYDATE is null))
		left join CASENAME D	on (D.CASEID = T.CASEID
					and D.EXPIRYDATE is null
					and D.NAMETYPE = T.DEBTORNAMETYPE
					and D.SEQUENCE = (	SELECT MIN(D2.SEQUENCE)
								FROM CASENAME D2
								WHERE D2.CASEID = T.CASEID
								AND D2.NAMETYPE = T.DEBTORNAMETYPE
								AND D2.EXPIRYDATE is null))
		left join IPNAME DT	on (DT.NAMENO=D.NAMENO)
		left join CASENAME O	on (O.CASEID = T.CASEID
					and O.EXPIRYDATE is null
					and O.NAMETYPE = 'O'
					and O.SEQUENCE = (	SELECT MIN(O2.SEQUENCE)
								FROM CASENAME O2
								WHERE O2.CASEID = T.CASEID
								AND O2.NAMETYPE = 'O'
								AND O2.EXPIRYDATE is null))
		left join CASENAME I	on (I.CASEID = T.CASEID
					and I.EXPIRYDATE is null
					and I.NAMETYPE = 'I'
					and I.SEQUENCE = (	SELECT MIN(I2.SEQUENCE)
								FROM CASENAME I2
								WHERE I2.CASEID = T.CASEID
								AND I2.NAMETYPE = 'I'
								AND I2.EXPIRYDATE is null))"
	End
	Else Begin
		Set @sSQLString="
		Update T
		Set	CRITERIANO=
				(select 
				convert(int,
				Substring ( max(
				CASE WHEN C.CASEOFFICEID    is null THEN '0' ELSE '1' END +
				CASE WHEN C.CASETYPE	    is null THEN '0' ELSE '1' END +
				CASE WHEN C.PROPERTYTYPE    is null THEN '0' ELSE '1' END +
				CASE WHEN C.COUNTRYCODE	    is null THEN '0' ELSE '1' END +
				CASE WHEN C.CASECATEGORY    is null THEN '0' ELSE '1' END +
				CASE WHEN C.SUBTYPE	    is null THEN '0' ELSE '1' END +
				CASE WHEN C.LOCALCLIENTFLAG is null THEN '0' ELSE '1' END +
				CASE WHEN C.TYPEOFMARK      is null THEN '0' ELSE '1' END +
				CASE WHEN C.TABLECODE	    is null THEN '0' ELSE '1' END +
				isnull(convert(char(8),C.DATEOFACT,112),'00000000')+		-- valid from date in YYYYMMDD format
				convert(char(11),C.CRITERIANO)),18,11))
				from CRITERIA C
				WHERE C.RULEINUSE   = 1  
				AND   C.PURPOSECODE = 'F'  
				AND   C.RATENO      = T.RATENO
				AND ( C.CASEOFFICEID	IS NULL) 
				AND ( C.CASETYPE	= @psCaseType		OR C.CASETYPE		IS NULL) 
				AND ( C.PROPERTYTYPE	= @psPropertyType	OR C.PROPERTYTYPE	IS NULL) 
				AND ( C.COUNTRYCODE	= @psCountryCode	OR C.COUNTRYCODE	IS NULL)  
				AND ( C.CASECATEGORY	= @psCaseCategory	OR C.CASECATEGORY	IS NULL) 
				AND ( C.SUBTYPE		= @psSubType		OR C.SUBTYPE		IS NULL) 
				AND ( C.LOCALCLIENTFLAG	IS NULL) 
				AND ( C.TYPEOFMARK	IS NULL) 
				AND ( C.TABLECODE	= @pnEntitySize		OR C.TABLECODE		IS NULL) 
				AND ( C.DATEOFACT      <= getdate()		OR C.DATEOFACT		IS NULL) )
		From #TEMPCASERATES T"
	End
	
	If  @ErrorCode=0
	begin
		If @pbPrintSQL=1
			Print @sSQLString

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@psCaseType		nchar(1),
						  @psCountryCode	nvarchar(3),
						  @psPropertyType	nchar(1),
						  @psCaseCategory	nvarchar(2),
						  @psSubType		nvarchar(2),
						  @pnEntitySize		int',
						  @psCaseType,
						  @psCountryCode,
						  @psPropertyType,
						  @psCaseCategory,
						  @psSubType,
						  @pnEntitySize
	end

	-- Load the #TEMPCASECHARGES for each Case that has a Fees & Charges
	-- criteria defined. If there are multiple cycles defined on the FEESCALCULATION
	-- then return a row for each Cycle in order to extract all of the possible
	-- fees unless a specific year has been requested.
	
	If @ErrorCode=0
	begin
		Set @sSQLString	=
		"Insert into #TEMPCASECHARGES(CASEID,IRN,YEARNO,CHARGETYPENO,RATENO,RATETYPE,RATEDESC,STEPDATEFLAG,CALCLABEL1,CALCLABEL2,FROMEVENTNO1,FROMEVENTNO2,UNTILEVENTNO1,UNTILEVENTNO2,PERIODTYPE1,PERIODTYPE2,EXTENSIONPERIOD,"+char(10)+
		"                             CRITERIANO,UNIQUEID,DISBBASEFEE,DISBBASEUNITS,DISBVARIABLEFEE,DISBUNITSIZE,DISBMAXUNITS,SERVBASEFEE,SERVBASEUNITS,SERVVARIABLEFEE,SERVUNITSIZE,SERVMAXUNITS,USEEVENTNO)"+char(10)+
		"Select distinct C.CASEID,C.IRN,F.CYCLENUMBER,T.CHARGETYPENO,R.RATENO,R.RATETYPE,R.RATEDESC,0,isnull(R.CALCLABEL1,'Disbursement'),isnull(R.CALCLABEL2,'Service Charge'),Q1.FROMEVENTNO,Q2.FROMEVENTNO,Q1.UNTILEVENTNO,Q2.UNTILEVENTNO,Q1.PERIODTYPE, Q2.PERIODTYPE,0,"+char(10)+
		"                F.CRITERIANO,F.UNIQUEID,F.DISBBASEFEE,F.DISBBASEUNITS,F.DISBVARIABLEFEE,F.DISBUNITSIZE,F.DISBMAXUNITS,F.SERVBASEFEE,F.SERVBASEUNITS,F.SERVVARIABLEFEE,F.SERVUNITSIZE,F.SERVMAXUNITS,F.FROMEVENTNO"+char(10)+
		"From #TEMPCASERATES T"+char(10)+
		"join RATES R on (R.RATENO=T.RATENO)"+char(10)+
		"join FEESCALCULATION F	on (F.CRITERIANO=T.CRITERIANO)"+char(10)+
		"left join QUANTITYSOURCE Q1	on (Q1.QUANTITYSOURCEID=F.PARAMETERSOURCE)"+char(10)+
		"left join QUANTITYSOURCE Q2	on (Q2.QUANTITYSOURCEID=F.PARAMETERSOURCE2)"+char(10)+
		"left join CASES C on (C.CASEID=T.CASEID)"+char(10)+
		"WHERE F.UNIQUEID= convert(smallint,"+char(10)+
		"			substring ("+char(10)+
		"			(SELECT max (	CASE WHEN F1.AGENT	is null THEN '0' ELSE '1' END +"+char(10)+
		"					CASE WHEN F1.DEBTOR	is null THEN '0' ELSE '1' END +"+char(10)+
		"					CASE WHEN F1.DEBTORTYPE	is null THEN '0' ELSE '1' END +"+char(10)+
		"					CASE WHEN F1.OWNER	is null THEN '0' ELSE '1' END +"+char(10)+
		"					CASE WHEN F1.INSTRUCTOR	is null THEN '0' ELSE '1' END +"+char(10)+
		"					isnull(convert(char(8), F1.VALIDFROMDATE,112),'00000000')+"+char(10)+
		"					convert(char(5),F1.UNIQUEID) )"+char(10)+
		"			FROM   FEESCALCULATION F1"+char(10)+
		"			left join CASEEVENT CE	on (CE.CASEID=T.CASEID"+char(10)+
		"						and CE.EVENTNO=F1.FROMEVENTNO"+char(10)+
		"						and CE.CYCLE=isnull(F1.CYCLENUMBER,1))"+char(10)+
		"			WHERE  F1.CRITERIANO	= F.CRITERIANO"+char(10)+
		"			AND    F1.UNIQUEID       is not null"+char(10)+
		CASE WHEN(@pnYearNo is not null) THEN
		"			AND   (F1.CYCLENUMBER=(select max(F2.CYCLENUMBER) from FEESCALCULATION F2 WHERE F2.CRITERIANO=F.CRITERIANO and F2.CYCLENUMBER<="+convert(varchar,@pnYearNo)+") OR F1.CYCLENUMBER is null)"+char(10)
		END+ 
		"			AND   (F1.AGENT		= T.AGENT	OR F1.AGENT	 IS NULL )"+char(10)+
		"			AND   (F1.DEBTOR	= T.DEBTOR	OR F1.DEBTOR	 IS NULL )"+char(10)+
		"			AND   (F1.DEBTORTYPE	= T.DEBTORTYPE	OR F1.DEBTORTYPE IS NULL )"+char(10)+
		"			AND   (F1.OWNER		= T.OWNER	OR F1.OWNER 	 IS NULL )"+char(10)+
		"			AND   (F1.INSTRUCTOR	= T.INSTRUCTOR	OR F1.INSTRUCTOR IS NULL )"+char(10)+			
		"			AND   (F1.VALIDFROMDATE   <=coalesce(@pdtFromDate,CE.EVENTDATE,getdate()) OR F1.VALIDFROMDATE IS NULL ) ), 14,5))"

		If @pbPrintSQL=1
			Print @sSQLString

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pdtFromDate		datetime',
						  @pdtFromDate
	end

	If (@pnCaseId is not null or @pnRateNo is not null --SQA18615
	  OR exists (select 1 from #TEMPCASECHARGES where YEARNO is not null))  -- RFC13222
	and @pnYearNo is null
	Begin
		Set @sSQLString	="Insert into #TEMPCASECHARGES(CASEID,IRN,YEARNO,CHARGETYPENO,RATENO,RATETYPE,RATEDESC,STEPDATEFLAG,CALCLABEL1,CALCLABEL2,FROMEVENTNO1,FROMEVENTNO2,UNTILEVENTNO1,UNTILEVENTNO2,PERIODTYPE1,PERIODTYPE2,EXTENSIONPERIOD,"+char(10)+
				 "                             CRITERIANO,UNIQUEID,DISBBASEFEE,DISBBASEUNITS,DISBVARIABLEFEE,DISBUNITSIZE,DISBMAXUNITS,SERVBASEFEE,SERVBASEUNITS,SERVVARIABLEFEE,SERVUNITSIZE,SERVMAXUNITS,USEEVENTNO)"+char(10)+
				 "Select distinct T.CASEID,T.IRN,F.CYCLENUMBER,T.CHARGETYPENO,T.RATENO,T.RATETYPE,T.RATEDESC,T.STEPDATEFLAG,T.CALCLABEL1,T.CALCLABEL2,T.FROMEVENTNO1,T.FROMEVENTNO2,T.UNTILEVENTNO1,T.UNTILEVENTNO2,T.PERIODTYPE1, T.PERIODTYPE2,T.EXTENSIONPERIOD,"+char(10)+
				 "                F.CRITERIANO,F.UNIQUEID,F.DISBBASEFEE,F.DISBBASEUNITS,F.DISBVARIABLEFEE,F.DISBUNITSIZE,F.DISBMAXUNITS,F.SERVBASEFEE,F.SERVBASEUNITS,F.SERVVARIABLEFEE,F.SERVUNITSIZE,F.SERVMAXUNITS,F.FROMEVENTNO"+char(10)+
				 "from #TEMPCASECHARGES T"+char(10)+
				 "join FEESCALCULATION F1	on (F1.CRITERIANO=T.CRITERIANO"+char(10)+
				 "				and F1.UNIQUEID  =T.UNIQUEID"+char(10)+
				 "				and F1.CYCLENUMBER is not null)"+char(10)+
				 "join FEESCALCULATION F	on (F.CRITERIANO  =T.CRITERIANO"+char(10)+
				 "				and F.UNIQUEID   <>T.UNIQUEID"+char(10)+
				 "				and F.CYCLENUMBER<>F1.CYCLENUMBER"+char(10)+
				 "				and isnull(F.AGENT        ,'')=isnull(F1.AGENT        ,'')"+char(10)+
				 "				and isnull(F.DEBTOR       ,'')=isnull(F1.DEBTOR       ,'')"+char(10)+
				 "				and isnull(F.DEBTORTYPE   ,'')=isnull(F1.DEBTORTYPE   ,'')"+char(10)+
				 "				and isnull(F.OWNER        ,'')=isnull(F1.OWNER        ,'')"+char(10)+
				 "				and isnull(F.INSTRUCTOR   ,'')=isnull(F1.INSTRUCTOR   ,'')"+char(10)+
				 "				and isnull(F.VALIDFROMDATE,'')=isnull(F1.VALIDFROMDATE,'') )"
				 
		If @pbPrintSQL=1
		Begin
			Print 'Load the #TEMPCASECHARGES for where Fee charges are defined by Year'
			Print @sSQLString
			Print ''
		End
				 
		exec @ErrorCode=sp_executesql @sSQLString
	End
	
	-- If any fees involve charges that change based on a period of time
	-- then get the eventno used to indicate the Lapse date as this will
	-- be used as the upper limit for the date increments to be shown.
	If @ErrorCode=0
	and exists(select 1 
		   from #TEMPCASECHARGES 
		   where (FROMEVENTNO1 is not null and PERIODTYPE1 is not null)
		     OR  (FROMEVENTNO2 is not null and PERIODTYPE2 is not null))
	Begin
		Set @sSQLString="
		Select @nLapseEventNo=COLINTEGER
		from SITECONTROL
		where CONTROLID='Lapse Event'"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nLapseEventNo	int	OUTPUT',
					  @nLapseEventNo=@nLapseEventNo	OUTPUT

		-- Get the cycle that matches the YearNo passed as a parameter
		If @pnYearNo is not null
		and @ErrorCode=0
		Begin
			Set @sSQLString="
			Select @nCycle=	CASE WHEN(@pnYearNo>VP.CYCLEOFFSET) 
						THEN @pnYearNo-VP.CYCLEOFFSET 
						ELSE @pnYearNo
					END
			from VALIDPROPERTY VP
			left join CASES C on (C.CASEID=@pnCaseId)			--SQA19453
			where VP.PROPERTYTYPE=isnull(C.PROPERTYTYPE,@psPropertyType)
			and VP.COUNTRYCODE=(	select min(VP1.COUNTRYCODE)
						from VALIDPROPERTY VP1
						where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
						and VP1.COUNTRYCODE in (isnull(C.COUNTRYCODE,@psCountryCode), 'ZZZ'))"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCycle		tinyint		OUTPUT,
						  @psPropertyType	nchar(1),
						  @psCountryCode	nvarchar(3),
						  @pnYearNo		tinyint,
						  @pnCaseId		int',
						  @nCycle	 =@nCycle		OUTPUT,
						  @psPropertyType=@psPropertyType,
						  @psCountryCode =@psCountryCode,
						  @pnYearNo      =@pnYearNo,
						  @pnCaseId      =@pnCaseId
		End

		-- If an Event for the Lapse Date is found but the calculation 
		-- is for a "what if" virtual Case, then attempt to calculate
		-- the lapse date
		If @ErrorCode=0
		and @nLapseEventNo is not null
		and @psGlobalTempTable is null
		and @pnCaseId          is null
		Begin
			exec @ErrorCode=cs_CalculateEventDueDate
						@pdtCalculatedDate=@dtLapseDate	OUTPUT,
						@psCaseType	  =@psCaseType,
						@psCountryCode	  =@psCountryCode,
						@psPropertyType	  =@psPropertyType,
						@psCaseCategory	  =@psCaseCategory,
						@psSubType	  =@psSubType,
						@psBasis	  =@psBasis,
						@pnCycle	  =@nCycle,
						@pnEventToCalc	  =@nLapseEventNo,
						@pnFromEventNo1	  =-11,
						@pdtFromDate1	  =@pdtRenewalDate


			-- We now need to loop through each different rate calculation that requires 
			-- a date from which simulated fee changes can occur. The date entered by 
			-- the operator is the Next Renewal Date so we only need to calculate
			-- the base date if it is not the NRD (as we already have it). A date will
			-- only be calculated if it can be calculated from the NRD or where the NRD
			-- may be substituted for the actual event (see SiteControl "Substitute In Renewal Date").
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPDUMMYEVENTS(EVENTNO)
				select FROMEVENTNO1
				from #TEMPCASECHARGES
				where FROMEVENTNO1 is not null
				UNION
				select FROMEVENTNO2
				from #TEMPCASECHARGES
				where FROMEVENTNO2 is not null"
	
				exec @ErrorCode=sp_executesql @sSQLString

				Set @nRowCount=@@rowcount
			End

			Set @nCurrentRow=1
			
			While @nCurrentRow<=@nRowCount
			and   @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @nEventNo=EVENTNO
				from #TEMPDUMMYEVENTS
				where SEQUENCENO=@nCurrentRow"

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@nEventNo		int	OUTPUT,
							  @nCurrentRow		int',
							  @nEventNo=@nEventNo		OUTPUT,
							  @nCurrentRow =@nCurrentRow

				If @nEventNo=-11
				Begin
					Set @dtDueDate=@pdtRenewalDate
				End
				Else If @ErrorCode=0
				Begin
					exec @ErrorCode=cs_CalculateEventDueDate
								@pdtCalculatedDate=@dtDueDate	OUTPUT,
								@psCaseType	  =@psCaseType,
								@psCountryCode	  =@psCountryCode,
								@psPropertyType	  =@psPropertyType,
								@psCaseCategory	  =@psCaseCategory,
								@psSubType	  =@psSubType,
								@psBasis	  =@psBasis,
								@pnCycle	  =@nCycle,
								@pnEventToCalc	  =@nEventNo,
							--	@pnFromEventNo1	  =-11,		-- SQA15899 comment out so Substitue In Renewal Date events will be use
								@pdtFromDate1	  =@pdtRenewalDate
				End

				-- Now save the calculated date

				If @dtDueDate is not null
				and @ErrorCode=0
				Begin
					Set @sSQLString="
					Update #TEMPDUMMYEVENTS
					Set EVENTDUEDATE=@dtDueDate
					Where SEQUENCENO=@nCurrentRow"

					Exec @ErrorCode=sp_executesql @sSQLString,
								N'@dtDueDate	datetime,
								  @nCurrentRow	int',
								  @dtDueDate  =@dtDueDate,
								  @nCurrentRow=@nCurrentRow
				End

				Set @nCurrentRow=@nCurrentRow+1
			End
		End
	End

	-- Now determine the current Next Renewal Date for each Case.  The Annuity can then be determined and
	-- the NRD assigned to the Fee Calculation for that Annuity.
	-- Also set the FROMDATE to the earliest of the two possible Events that can be used to calculate the 
	-- components of the fee.

	If @ErrorCode=0
	and (@psGlobalTempTable is not null or @pnCaseId is not null)	
	Begin
		Set @sSQLString="
		Update #TEMPCASECHARGES
		Set	RENEWALDATE=isnull(NR.EVENTDATE,NR.EVENTDUEDATE),
			FROMDATE   =CASE WHEN(T.YEARNO is not null and CE1.CASEID is null and CE2.CASEID is null and NR.CASEID is NOT NULL)
						THEN isnull(NR.EVENTDATE,NR.EVENTDUEDATE)
					 WHEN(getdate()<=coalesce(CE1.EVENTDATE,CE1.EVENTDUEDATE,getdate())
					  and getdate()<=coalesce(CE2.EVENTDATE,CE2.EVENTDUEDATE,getdate()))
					 	THEN  convert(varchar,getdate(),112) 
					 WHEN(isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE)<coalesce(CE2.EVENTDATE,CE2.EVENTDUEDATE,getdate()))
						THEN isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE)
						ELSE isnull(CE2.EVENTDATE,CE2.EVENTDUEDATE)
				    END,
			BASEDATE1  =isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE),
			BASEDATE2  =isnull(CE2.EVENTDATE,CE2.EVENTDUEDATE),
			STARTDATE1 =isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE),
			STARTDATE2 =isnull(CE2.EVENTDATE,CE2.EVENTDUEDATE),
			CYCLE      =NR.CYCLE,
			CHARGEEVENT=CT.CHARGEDUEEVENT"

		If @pbCalledFromCentura<>1
		and @pnCaseId is null
			Set @sSQLString=@sSQLString+",
			NOCALCFLAG =convert(bit, isnull(ID.OCCURREDFLAG,0))"

		Set @sSQLString=@sSQLString+"
		From #TEMPCASECHARGES T
		Join CASES C		on (C.CASEID=T.CASEID)
		Left Join CHARGETYPE CT	on (CT.CHARGETYPENO=T.CHARGETYPENO) 
		Left Join (select max(CYCLE) as MAXCYCLE, min(CYCLE) as MINCYCLE, CASEID
			from OPENACTION
			join SITECONTROL on (CONTROLID='Main Renewal Action')
			where ACTION=COLCHARACTER
			and POLICEEVENTS=1
			group by CASEID) OA 
					on (OA.CASEID =T.CASEID
					and T.RATETYPE=1601)"	--SQA18980 Only get the cycle for Renewal rate calculations.

		-- If the calculations are being performed for an Instruction Definition 
		-- then look at the Instruction Definition to determine if the maximum or
		-- the minimum cycle is to be used.
		If exists(select 1 from @tblExtendedColumns where COLUMNNAME='DEFINITIONID')
		and @pdtFromDate  is null
		and @pdtUntilDate is null
		Begin
			Set @sSQLString=@sSQLString+char(10)+
			"left join "+@psGlobalTempTable+" GT	on (GT.CASEID=T.CASEID"+
			CASE WHEN(@pbDyamicChargeType=1)
				THEN char(10)+char(9)+char(9)+"					and GT.CHARGETYPENO=T.CHARGETYPENO)"
				ELSE ")"
			END+char(10)+char(9)+char(9)+
			"left join INSTRUCTIONDEFINITION IND	on (IND.DEFINITIONID=GT.DEFINITIONID)"+char(10)+char(9)+char(9)+
			"Join CASEEVENT NR	on (NR.CASEID =T.CASEID"+char(10)+char(9)+char(9)+
						-- If rate type indicates Renewal then get renewal date
						-- otherwise the event associated with the ChargeType
			"			and NR.EVENTNO=CASE WHEN(T.RATETYPE=1601) THEN -11 ELSE isnull(CT.CHARGEDUEEVENT,-11) END"+char(10)+char(9)+char(9)+
						-- if fees are by YEARNO then all Renewal Dates are to be returned,
						-- unless a date range has been provided as a filter, then return all
						-- casevents here so they can be filtered in the WHERE clause,
						-- otherwise use the earliest open renewal cycle if it exists,
						-- otherwise use the lowest cycle NRD
			"			and NR.CYCLE=CASE WHEN(T.YEARNO is not null)"+char(10)+char(9)+char(9)+
			"						THEN NR.CYCLE"+char(10)+char(9)+char(9)+
			"						ELSE CASE WHEN(IND.USEMAXCYCLE=0)"+char(10)+char(9)+char(9)+
			"							THEN isnull(OA.MINCYCLE,(select min(NR1.CYCLE)"+char(10)+char(9)+char(9)+
			"										 from CASEEVENT NR1"+char(10)+char(9)+char(9)+
			"										 where NR1.CASEID=NR.CASEID"+char(10)+char(9)+char(9)+
			"										 and   NR1.EVENTNO=NR.EVENTNO))"+char(10)+char(9)+char(9)+
			"							ELSE isnull(OA.MAXCYCLE,(select max(NR1.CYCLE)"+char(10)+char(9)+char(9)+
			"										 from CASEEVENT NR1"+char(10)+char(9)+char(9)+
			"										 where NR1.CASEID=NR.CASEID"+char(10)+char(9)+char(9)+
			"										 and   NR1.EVENTNO=NR.EVENTNO))"+char(10)+char(9)+char(9)+
			"						     END"+char(10)+char(9)+char(9)+
			"				     END)"
		End
		Else If @psGlobalTempTable is not null
		Begin
			-- SQA18826
			-- Need to join to the supplied @psGlobalTempTable and use the CYCLE
			-- if it has been supplied.
			Set @sSQLString=@sSQLString+char(10)+
			"join "+@psGlobalTempTable+" GT	on (GT.CASEID=T.CASEID"+char(10)+char(9)+char(9)+
			CASE WHEN(@pbDyamicChargeType=1)
				THEN char(10)+char(9)+char(9)+"                               and GT.CHARGETYPENO=T.CHARGETYPENO)"
				ELSE ")"
			END+char(10)+char(9)+char(9)+
			-- Get the Event associated with the Charge Type
			"Join CASEEVENT NR	on (NR.CASEID =T.CASEID"+char(10)+char(9)+char(9)+
						-- If rate type indicates Renewal then get renewal date
						-- otherwise the event associated with the ChargeType
			"			and NR.EVENTNO=CASE WHEN(T.RATETYPE=1601) THEN -11 ELSE isnull(CT.CHARGEDUEEVENT,-11) END"+char(10)+char(9)+char(9)+
						-- If temporary table has specified a cycle for the Case then use
						-- the Renewal Date associated with that cycle; 
						-- if fees are by YEARNO then all Renewal Dates are to be returned,
						-- unless a date range has been provided as a filter, then return all
						-- casevents here so they can be filtered in the WHERE clause,
						-- otherwise use the latest open renewal cycle if it exists,
						-- otherwise use the lowest cycle NRD
			"			and NR.CYCLE=CASE WHEN(GT.CYCLE>0) THEN GT.CYCLE"+char(10)+char(9)+char(9)+
			"					  WHEN(T.YEARNO is not null)"+char(10)+char(9)+char(9)+
			"						THEN NR.CYCLE"+char(10)+char(9)+char(9)+
			"					  WHEN(@pdtFromDate is not null OR @pdtUntilDate is not null)"+char(10)+char(9)+char(9)+
			"					  	Then (	select max(NR1.CYCLE)"+char(10)+char(9)+char(9)+
			"					  		from CASEEVENT NR1"+char(10)+char(9)+char(9)+
			"					  		where NR1.CASEID=NR.CASEID"+char(10)+char(9)+char(9)+
			"					  		and   NR1.EVENTNO=NR.EVENTNO"+char(10)+char(9)+char(9)+
			"					  		and   isnull(NR1.EVENTDATE,NR1.EVENTDUEDATE) between isnull(@pdtFromDate,'20000101') and  isnull(@pdtUntilDate,'21001231'))"+char(10)+char(9)+char(9)+
			"						ELSE CASE WHEN(OA.MAXCYCLE is not null)"+char(10)+char(9)+char(9)+	-- RFC9071 changed to MAXCYCLE
			"							THEN OA.MAXCYCLE"+char(10)+char(9)+char(9)+			-- RFC9071 changed to MAXCYCLE
			"							ELSE (	select max(NR1.CYCLE)"+char(10)+char(9)+char(9)+	-- SQA18980
			"								from CASEEVENT NR1"+char(10)+char(9)+char(9)+
			"								where NR1.CASEID=NR.CASEID"+char(10)+char(9)+char(9)+
			"								and   NR1.EVENTNO=NR.EVENTNO)"+char(10)+char(9)+char(9)+
			"						     END"+char(10)+char(9)+char(9)+
			"				     END)"
		End
		Else Begin
			Set @sSQLString=@sSQLString+char(10)+char(9)+char(9)+
			-- Get the Event associated with the Charge Type
			"Join CASEEVENT NR	on (NR.CASEID =T.CASEID"+char(10)+char(9)+char(9)+
						-- If rate type indicates Renewal then get renewal date
						-- otherwise the event associated with the ChargeType
			"			and NR.EVENTNO=CASE WHEN(T.RATETYPE=1601) THEN -11 ELSE isnull(CT.CHARGEDUEEVENT,-11) END"+char(10)+char(9)+char(9)+
						-- if fees are by YEARNO then all Renewal Dates are to be returned,
						-- unless a date range has been provided as a filter, then return all
						-- casevents here so they can be filtered in the WHERE clause,
						-- otherwise use the earliest open renewal cycle if it exists,
						-- otherwise use the lowest cycle NRD
			"			and NR.CYCLE=CASE WHEN(T.YEARNO is not null)"+char(10)+char(9)+char(9)+
			"						THEN NR.CYCLE"+char(10)+char(9)+char(9)+
			"					  WHEN(@pdtFromDate is not null OR @pdtUntilDate is not null)"+char(10)+char(9)+char(9)+
			"					  	Then (	select max(NR1.CYCLE)"+char(10)+char(9)+char(9)+
			"					  		from CASEEVENT NR1"+char(10)+char(9)+char(9)+
			"					  		where NR1.CASEID=NR.CASEID"+char(10)+char(9)+char(9)+
			"					  		and   NR1.EVENTNO=NR.EVENTNO"+char(10)+char(9)+char(9)+
			"					  		and   isnull(NR1.EVENTDATE,NR1.EVENTDUEDATE) between isnull(@pdtFromDate,'20000101') and  isnull(@pdtUntilDate,'21001231'))"+char(10)+char(9)+char(9)+
			"						ELSE CASE WHEN(OA.MAXCYCLE is not null)"+char(10)+char(9)+char(9)+	-- RFC9071 changed to MAXCYCLE
			"							THEN OA.MAXCYCLE"+char(10)+char(9)+char(9)+			-- RFC9071 changed to MAXCYCLE
			"							ELSE (	select max(NR1.CYCLE)"+char(10)+char(9)+char(9)+	-- SQA18980
			"								from CASEEVENT NR1"+char(10)+char(9)+char(9)+
			"								where NR1.CASEID=NR.CASEID"+char(10)+char(9)+char(9)+
			"								and   NR1.EVENTNO=NR.EVENTNO)"+char(10)+char(9)+char(9)+
			"						     END"+char(10)+char(9)+char(9)+
			"				     END)"
		End
		

		If @pbCalledFromCentura<>1
			Set @sSQLString=@sSQLString+char(10)+char(9)+char(9)+
			"Left Join CASEEVENT ID	on (ID.CASEID =T.CASEID
					and ID.EVENTNO=CT.CHARGEINCURREDEVENT
					and ID.CYCLE  =NR.CYCLE)"

		Set @sSQLString=@sSQLString+"
		Left Join CASEEVENT RS	on (RS.CASEID =T.CASEID
					and RS.EVENTNO=-9
					and RS.CYCLE  =1)
		Join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
					and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
							    from VALIDPROPERTY VP1
							    where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
							    and VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
		left join EVENTS E1	on (E1.EVENTNO=T.FROMEVENTNO1)
		left join EVENTS E2	on (E2.EVENTNO=T.FROMEVENTNO2)							    
		-- Get the date used to determine the fee that varies by date
		left join CASEEVENT CE1	on (CE1.CASEID = T.CASEID
					and CE1.EVENTNO= T.FROMEVENTNO1
					and CE1.CYCLE  = CASE WHEN(E1.NUMCYCLESALLOWED=1) THEN 1 ELSE NR.CYCLE END)
		-- Get the date used to determine the fee that varies by date
		left join CASEEVENT CE2	on (CE2.CASEID = T.CASEID
					and CE2.EVENTNO= T.FROMEVENTNO2
					and CE2.CYCLE  = CASE WHEN(E2.NUMCYCLESALLOWED=1) THEN 1 ELSE NR.CYCLE END)
		-- If there is an open renewal action then only align
		-- the reneweal date from that cycle on
		Where(OA.MINCYCLE<=NR.CYCLE or OA.MINCYCLE is null) 
			-- Find the Annuity (YEARNO) that matches the calculated Renewal Date
			-- if the fees vary by year
		and  (T.YEARNO is null
		  OR  T.YEARNO=	CASE(VP.ANNUITYTYPE)
					WHEN(0) THEN NULL
					WHEN(1) THEN floor(datediff(mm,isnull(RS.EVENTDATE,RS.EVENTDUEDATE), isnull(NR.EVENTDATE,NR.EVENTDUEDATE))/12) + ISNULL(VP.OFFSET, 0)
					WHEN(2) THEN NR.CYCLE+isnull(VP.CYCLEOFFSET,0)
				END)"

		If @pdtFromDate is not null
			Set @sSQLString=@sSQLString+char(10)+
			"		and isnull(NR.EVENTDATE,NR.EVENTDUEDATE)>=@pdtFromDate"

		If @pdtUntilDate is not null
			Set @sSQLString=@sSQLString+char(10)+
			"		and isnull(NR.EVENTDATE,NR.EVENTDUEDATE)<=@pdtUntilDate"

		If @pbPrintSQL=1
		Begin
			Print 'Update #TEMPCASECHARGES with relevant dates'
			Print @sSQLString
			Print ''
		End

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pdtFromDate		datetime,
						  @pdtUntilDate		datetime',
						  @pdtFromDate =@pdtFromDate,
						  @pdtUntilDate=@pdtUntilDate  
	End
	Else If @ErrorCode =0
	Begin
		-- The "what if" case will have passed a Renewal Date to use
		Set @sSQLString="
		Update #TEMPCASECHARGES
		Set	RENEWALDATE=@pdtRenewalDate,
			FROMDATE   =CASE WHEN(getdate()<=coalesce(E1.EVENTDUEDATE,getdate())
					  and getdate()<=coalesce(E2.EVENTDUEDATE,getdate()))
					 	THEN  convert(varchar,getdate(),112) 
					 WHEN(E1.EVENTDUEDATE<coalesce(E2.EVENTDUEDATE,getdate()))
						THEN E1.EVENTDUEDATE
						ELSE coalesce(E2.EVENTDUEDATE,convert(varchar,getdate(),112))
				    END,
			BASEDATE1  =E1.EVENTDUEDATE,
			BASEDATE2  =E2.EVENTDUEDATE,
			STARTDATE1 =E1.EVENTDUEDATE,
			STARTDATE2 =E2.EVENTDUEDATE,
			CYCLE      =isnull(@nCycle,1),
			NOCALCFLAG =0,
			CHARGEEVENT=CT.CHARGEDUEEVENT
		From #TEMPCASECHARGES T
		Left Join CHARGETYPE CT	on (CT.CHARGETYPENO=@pnChargeTypeNo)
		Left join #TEMPDUMMYEVENTS E1 on (E1.EVENTNO=T.FROMEVENTNO1)
		Left join #TEMPDUMMYEVENTS E2 on (E2.EVENTNO=T.FROMEVENTNO2)
		Where T.YEARNO is null
		  OR  T.YEARNO=	CASE WHEN(@pnYearNo is not null)
					THEN @pnYearNo
					ELSE (select min(T1.YEARNO) from #TEMPCASECHARGES T1 where T1.RATENO=T.RATENO)
				END"
	
		If @pbPrintSQL=1
		Begin
			Print 'Update #TEMPCASECHARGES with relevant dates for a simulated Case'
			Print @sSQLString
			Print ''
		End

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pdtRenewalDate	datetime,
						  @pnYearNo		smallint,
						  @nCycle		tinyint,
						  @pnChargeTypeNo	int',
						  @pdtRenewalDate=@pdtRenewalDate,
						  @pnYearNo      =@pnYearNo,
						  @nCycle	 =@nCycle,
						  @pnChargeTypeNo=@pnChargeTypeNo

	End


	-- Remove any #TEMPCASECHARGES rows that are annuity based if
	-- the Case has already moved beyond that annuity or if an
	-- explicit date range has been provided.
	-- Removing these details now reduces the amount of work
	-- required to calculate the actual fees.

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Delete #TEMPCASECHARGES
		from #TEMPCASECHARGES T
		join (	select CASEID, min(YEARNO) as YEARNO
			from #TEMPCASECHARGES
			where YEARNO is not null
			and RENEWALDATE is not null
			group by CASEID) T1 on (T1.CASEID=T.CASEID)
		where T.YEARNO<T1.YEARNO"

		-- If an explicit date range has been provided then
		-- remove any rows where the associated date is
		-- missing.
		If @pdtFromDate  is not null
		or @pdtUntilDate is not null
			Set @sSQLString=@sSQLString+char(10)+
			"		or T.RENEWALDATE is null"

		If @pbPrintSQL=1
		Begin
			Print 'Remove any #TEMPCASECHARGES rows that are annuity based if
			-- the Case has already moved beyond that annuity or if an
			-- explicit date range has been provided.'
			Print @sSQLString
			Print ''
		End

		Exec @ErrorCode=sp_executesql @sSQLString
	End

	-- SQA15657----------------------------------------------------
	-- One of the parameters for determining the Margin is the
	-- Action that raised the charge.  In a fee enquiry situation
	-- we do not have an explicit Action to use so to simulate
	-- the most likely Action we will determine the Action from any
	-- CharegeDueEvent that was associated with the ChargeType.
	---------------------------------------------------------------
	If  @ErrorCode=0
	Begin
		Set @sSQLString="
		Update #TEMPCASECHARGES
		Set CHARGEACTION=CE.CREATEDBYACTION
		From #TEMPCASECHARGES T
		join (	select CASEID, EVENTNO, CREATEDBYACTION, max(CYCLE) as CYCLE
			from CASEEVENT
			where CREATEDBYACTION is not null
			group by CASEID, EVENTNO, CREATEDBYACTION) CE	on (CE.CASEID=T.CASEID
									and CE.EVENTNO=T.CHARGEEVENT)
		where CHARGEACTION is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- For each RATENO that calculates a period of time between two dates in order to determine the
	-- extension fee, we need to calculate the date at which there will be a fee change.
	-- It is possible for either the Disbursement or the Service component of the calculation to vary
	-- by date depending upon the source of quantity used in the calculation.
	-- The date from which the variation in dates can occur is a fixed date and is relative to either the
	-- disbursement or the service part of the calculation (there can be 2 different dates). So what we are
	-- trying to achieve is a full set of dates where either the Disbursement or Service charge will vary
	-- as a result of the date difference to the respective fixed dates (BaseDate1 and BaseDate2).
	-- The first "Extension Fee" will be due 1 day after the From Event and then calculate each new date
	-- by using the Period Type up until (but not including) we hit a date that is either after the Lapse date
	-- or where we predict no further variations in fees to be generated.
	-- This expansion will only occur for the first renewal cycle whose fees are being calculated.

	If @ErrorCode=0
	and @nLapseEventNo is not null
	Begin
		-- Generate a dummy table to create a list of sequential numbers from 0 for each row in the 
		-- Country table (around 200 rows).  Country table is only being used because it limits the
		-- number of rows to be inserted.
		-- This is just a programming technique to assist in the generation of an unknown number of
		-- rows for each of the extension fees.
		Set @sSQLString=
		"Insert into #TEMPSEQUENCE(TINYBIT)"+char(10)+
		"select 0"+char(10)+
		"from COUNTRY"
	
		exec @ErrorCode=sp_executesql @sSQLString

		If @dtLapseDate is null
		and @pdtRenewalDate is not null
			set @dtLapseDate=dateadd(month,6,@pdtRenewalDate)

		If @ErrorCode=0
		Begin	
			Set @sSQLString=
			"Insert into #TEMPCASECHARGES(	CASEID, IRN, YEARNO, CRITERIANO, CHARGETYPENO, RATENO, RATEDESC, CALCLABEL1, CALCLABEL2,"+char(10)+
			"				FROMEVENTNO1, UNTILEVENTNO1, PERIODTYPE1,"+char(10)+
			"				FROMEVENTNO2, UNTILEVENTNO2, PERIODTYPE2,"+char(10)+
			"				RENEWALDATE, CYCLE, EXTENSIONPERIOD, BASEDATE1, BASEDATE2, FROMDATE, STEPDATEFLAG, USEEVENTNO,CHARGEEVENT,CHARGEACTION)"+char(10)+
			"Select distinct T.CASEID, T.IRN, T.YEARNO, T.CRITERIANO, T.CHARGETYPENO, T.RATENO, T.RATEDESC, T.CALCLABEL1, T.CALCLABEL2,"+char(10)+
			"                T.FROMEVENTNO1, T.UNTILEVENTNO1, T.PERIODTYPE1,"+char(10)+
			"                T.FROMEVENTNO2, T.UNTILEVENTNO2, T.PERIODTYPE2,"+char(10)+
			"		 T.RENEWALDATE, T.CYCLE, S.SEQUENCENO+1, T.STARTDATE1,T.STARTDATE2,"+char(10)+
			"		 CASE(T.PERIODTYPE1)"+char(10)+
			"			WHEN('D') THEN dateadd(dd, S.SEQUENCENO+1,   T.STARTDATE1)"+char(10)+
			"			WHEN('W') THEN dateadd(dd,(S.SEQUENCENO*7)+1,T.STARTDATE1)"+char(10)+
			"			WHEN('M') THEN dateadd(mm, S.SEQUENCENO     ,dateadd(dd,1,T.STARTDATE1))"+char(10)+
			"			WHEN('Y') THEN dateadd(yy, S.SEQUENCENO     ,dateadd(dd,1,T.STARTDATE1))"+char(10)+
			"		 END, 0, T.USEEVENTNO,T.CHARGEEVENT,T.CHARGEACTION"+char(10)+
			"from #TEMPCASECHARGES T"+char(10)+
			-- get the date the Case will lapse if a real Case exists
			"left join CASEEVENT CE	on (CE.CASEID =T.CASEID"+char(10)+
			"			and CE.EVENTNO=@nLapseEventNo"+char(10)+
			"			and CE.CYCLE  =T.CYCLE)"+char(10)+
			"left join(	select distinct CRITERIANO as CRITERIANO"+char(10)+
			"	   	from FEESCALCALT"+char(10)+
			"		where COMPONENTTYPE=1) F on (F.CRITERIANO=T.CRITERIANO)"+char(10)+
			"cross join #TEMPSEQUENCE S"+char(10)+
			"where T.FROMEVENTNO1 is not null"+char(10)+
			"and T.PERIODTYPE1 is not null"+char(10)+
			"and isnull(T.NOCALCFLAG,0)=0"+char(10)+
			"and coalesce(CE.EVENTDATE, CE.EVENTDUEDATE, @dtLapseDate,getdate())"+char(10)+
			"	>CASE(T.PERIODTYPE1)"+char(10)+
			"		WHEN('D') THEN dateadd(dd, S.SEQUENCENO+1,   T.STARTDATE1)"+char(10)+
			"		WHEN('W') THEN dateadd(dd,(S.SEQUENCENO*7)+1,T.STARTDATE1)"+char(10)+
			"		WHEN('M') THEN dateadd(mm, S.SEQUENCENO     ,dateadd(dd,1,T.STARTDATE1))"+char(10)+
			"		WHEN('Y') THEN dateadd(yy, S.SEQUENCENO     ,dateadd(dd,1,T.STARTDATE1))"+char(10)+
			"	 END"+char(10)+
			"and (S.SEQUENCENO=0 OR F.CRITERIANO is not null OR (T.DISBVARIABLEFEE<>0 and T.DISBUNITSIZE>0 and (S.SEQUENCENO-T.DISBBASEUNITS)%T.DISBUNITSIZE=0))"+char(10)+
			"and isnull(T.DISBMAXUNITS,300)>=CASE(T.PERIODTYPE1)"+char(10)+
			"					WHEN('D') THEN S.SEQUENCENO+1"+char(10)+
			"					WHEN('W') THEN S.SEQUENCENO+1"+char(10)+
			"						  ELSE S.SEQUENCENO"+char(10)+
			"				 END"+char(10)+
			"UNION"+char(10)+
			"Select distinct T.CASEID, T.IRN, T.YEARNO, T.CRITERIANO, T.CHARGETYPENO, T.RATENO, T.RATEDESC, T.CALCLABEL1, T.CALCLABEL2,"+char(10)+
			"                T.FROMEVENTNO1, T.UNTILEVENTNO1, T.PERIODTYPE1,"+char(10)+
			"                T.FROMEVENTNO2, T.UNTILEVENTNO2, T.PERIODTYPE2,"+char(10)+
			"		 T.RENEWALDATE, T.CYCLE, S.SEQUENCENO+1, T.STARTDATE1,T.STARTDATE2,"+char(10)+
			"		 CASE(T.PERIODTYPE2)"+char(10)+
			"			WHEN('D') THEN dateadd(dd, S.SEQUENCENO+1,   T.STARTDATE2)"+char(10)+
			"			WHEN('W') THEN dateadd(dd,(S.SEQUENCENO*7)+1,T.STARTDATE2)"+char(10)+
			"			WHEN('M') THEN dateadd(mm, S.SEQUENCENO     ,dateadd(dd,1,T.STARTDATE2))"+char(10)+
			"			WHEN('Y') THEN dateadd(yy, S.SEQUENCENO     ,dateadd(dd,1,T.STARTDATE2))"+char(10)+
			"		 END, 0, T.USEEVENTNO,T.CHARGEEVENT,T.CHARGEACTION"+char(10)+
			"from #TEMPCASECHARGES T"+char(10)+
			-- get the date the Case will lapse if a real Case exists
			"left join CASEEVENT CE	on (CE.CASEID =T.CASEID"+char(10)+
			"			and CE.EVENTNO=@nLapseEventNo"+char(10)+
			"			and CE.CYCLE  =T.CYCLE)"+char(10)+
			"left join(	select distinct CRITERIANO as CRITERIANO"+char(10)+
			"	   	from FEESCALCALT"+char(10)+
			"		where COMPONENTTYPE=0) F on (F.CRITERIANO=T.CRITERIANO)"+char(10)+
			"cross join #TEMPSEQUENCE S"+char(10)+
			"where T.FROMEVENTNO2 is not null"+char(10)+
			"and T.PERIODTYPE2 is not null"+char(10)+
			"and isnull(T.NOCALCFLAG,0)=0"+char(10)+
			"and coalesce(CE.EVENTDATE, CE.EVENTDUEDATE, @dtLapseDate,getdate())"+char(10)+
			"	>CASE(T.PERIODTYPE2)"+char(10)+
			"		WHEN('D') THEN dateadd(dd, S.SEQUENCENO+1,   T.STARTDATE2)"+char(10)+
			"		WHEN('W') THEN dateadd(dd,(S.SEQUENCENO*7)+1,T.STARTDATE2)"+char(10)+
			"		WHEN('M') THEN dateadd(mm, S.SEQUENCENO     ,dateadd(dd,1,T.STARTDATE2))"+char(10)+
			"		WHEN('Y') THEN dateadd(yy, S.SEQUENCENO     ,dateadd(dd,1,T.STARTDATE2))"+char(10)+
			"	 END"+char(10)+
			"and (S.SEQUENCENO=0 OR F.CRITERIANO is not null OR (T.SERVVARIABLEFEE<>0 and T.SERVUNITSIZE>0 and (S.SEQUENCENO-T.SERVBASEUNITS)%T.SERVUNITSIZE=0))"+char(10)+
			"and isnull(T.SERVMAXUNITS,300)>=CASE(T.PERIODTYPE2)"+char(10)+
			"					WHEN('D') THEN S.SEQUENCENO+1"+char(10)+
			"					WHEN('W') THEN S.SEQUENCENO+1"+char(10)+
			"						  ELSE S.SEQUENCENO"+char(10)+
			"				 END"
	
			If @pbPrintSQL=1
			Begin
				Print 'For each RATENO that calculates a period of time between two dates in order to determine the extension fee, we need to calculate the date at which there will be a fee change.'
				Print @sSQLString
				Print ''
			End


			exec @ErrorCode=sp_executesql @sSQLString,
							N'@nLapseEventNo	int,
							  @dtLapseDate		datetime',
							  @nLapseEventNo=@nLapseEventNo,
							  @dtLapseDate  =@dtLapseDate
		End
	End

	-- SQA15893
	-- For each RATENO that has a fee change occurring as at an effective date, we need to 
	-- insert a row as at that effective date to ensure all fee changes are catered for.
	If @ErrorCode=0
	Begin
		Set @sSQLString=
		"Insert into #TEMPCASECHARGES(	CASEID, IRN, YEARNO, CRITERIANO, CHARGETYPENO, RATENO, RATEDESC, CALCLABEL1, CALCLABEL2,"+char(10)+
		"				FROMEVENTNO1, UNTILEVENTNO1, PERIODTYPE1,"+char(10)+
		"				FROMEVENTNO2, UNTILEVENTNO2, PERIODTYPE2,"+char(10)+
		"				RENEWALDATE, CYCLE, EXTENSIONPERIOD, BASEDATE1, BASEDATE2, FROMDATE, STEPDATEFLAG, USEEVENTNO,CHARGEEVENT,CHARGEACTION)"+char(10)+
		"Select distinct T.CASEID, T.IRN, T.YEARNO, T.CRITERIANO, T.CHARGETYPENO, T.RATENO, T.RATEDESC, T.CALCLABEL1, T.CALCLABEL2,"+char(10)+
		"                T.FROMEVENTNO1, T.UNTILEVENTNO1, T.PERIODTYPE1,"+char(10)+
		"                T.FROMEVENTNO2, T.UNTILEVENTNO2, T.PERIODTYPE2,"+char(10)+
		"		 T.RENEWALDATE, T.CYCLE, T.EXTENSIONPERIOD, T.BASEDATE1, T.BASEDATE2,"+char(10)+
		"		 F.VALIDFROMDATE,"+char(10)+
		"		 T.STEPDATEFLAG, T.USEEVENTNO,T.CHARGEEVENT,T.CHARGEACTION"+char(10)+
		"from #TEMPCASECHARGES T"+char(10)+
		"join ( select CASEID, YEARNO, CYCLE, RATENO, min(FROMDATE) as MINDATE, max(FROMDATE) as MAXDATE"+char(10)+
		"	from #TEMPCASECHARGES"+char(10)+
		"	group by CASEID, YEARNO, CYCLE, RATENO) T1"+char(10)+
		"				on (isnull(T1.CASEID,'')=isnull(T.CASEID,'')"+char(10)+
		"				and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
		"				and isnull(T1.CYCLE, '')=isnull(T.CYCLE, '')"+char(10)+
		"				and T1.RATENO=T.RATENO)"+char(10)+
		-- get the date the Case will lapse if a real Case exists to limit the fees for consideration
		"left join CASEEVENT CE		on (CE.CASEID =T.CASEID"+char(10)+
		"				and CE.EVENTNO=@nLapseEventNo"+char(10)+
		"				and CE.CYCLE  =T.CYCLE)"+char(10)+
		"join FEESCALCULATION F	on (F.CRITERIANO=T.CRITERIANO)"+char(10)+
		"left join #TEMPCASECHARGES T2	on (isnull(T2.CASEID,'')=isnull(T.CASEID,'')"+char(10)+
		"				and isnull(T2.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
		"				and isnull(T2.CYCLE, '')=isnull(T.CYCLE, '')"+char(10)+
		"				and T2.RATENO=T.RATENO"+char(10)+
		"				and T2.FROMDATE=F.VALIDFROMDATE)"+char(10)+
		"where F.VALIDFROMDATE between T1.MINDATE and coalesce(CE.EVENTDATE,CE.EVENTDUEDATE,@dtLapseDate,getdate())"+char(10)+
		"and T2.RATENO is null"+char(10)+ -- to check simulated FROMDATE does not already exist
		-- get the details from row with the highest FROMDATE before VALIDFROMDATE
		"and T.FROMDATE=(select max(T3.FROMDATE)"+char(10)+
		"		 from #TEMPCASECHARGES T3"+char(10)+
		"		 where isnull(T3.CASEID,'')=isnull(T.CASEID,'')"+char(10)+
		"		 and   isnull(T3.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
		"		 and   isnull(T3.CYCLE, '')=isnull(T.CYCLE, '')"+char(10)+
		"		 and   T3.RATENO=T.RATENO"+char(10)+
		"		 and   T3.FROMDATE<F.VALIDFROMDATE)"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@nLapseEventNo	int,
						  @dtLapseDate		datetime',
						  @nLapseEventNo=@nLapseEventNo,
						  @dtLapseDate  =@dtLapseDate	
	End

	-- We only need to calculate fees as at the earliest date (to show the minimum cost), the current date
	-- and then as they increase.  By removing the unrequired From Dates before calling FEESCALC to do the
	-- calculation then we reduce the total time to get a result.

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Delete #TEMPCASECHARGES
		From #TEMPCASECHARGES T
		-- Get the earliest FROMDATE as we will need to keep calculations as at that date
		join (	select CASEID,YEARNO,CYCLE,CHARGETYPENO,RATENO, min(FROMDATE) as FROMDATE
			from #TEMPCASECHARGES
			where ESTIMATEFLAG=0
			and FROMDATE is not null
			group by CASEID,YEARNO,CYCLE,CHARGETYPENO,RATENO) T1
					on (isnull(T1.CASEID,'')=isnull(T.CASEID,'')
					and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')
					and isnull(T1.CYCLE,'') =isnull(T.CYCLE, '')
					and T1.CHARGETYPENO=T.CHARGETYPENO
					and T1.RATENO      =T.RATENO
					and T1.FROMDATE<T.FROMDATE)
		join (	select CASEID,YEARNO,CYCLE,CHARGETYPENO,RATENO, max(FROMDATE) as FROMDATE
			from #TEMPCASECHARGES
			where ESTIMATEFLAG=0
			and FROMDATE<=convert(varchar,getdate(),112)
			group by CASEID,YEARNO,CYCLE,CHARGETYPENO,RATENO) T2
					on (isnull(T2.CASEID,'')=isnull(T.CASEID,'')
					and isnull(T2.YEARNO,'')=isnull(T.YEARNO,'')
					and isnull(T2.CYCLE,'') =isnull(T.CYCLE, '')
					and T2.CHARGETYPENO=T.CHARGETYPENO
					and T2.RATENO      =T.RATENO
					and T2.FROMDATE    >T.FROMDATE)"

		Exec @ErrorCode=sp_executesql @sSQLString
	End

	---------------------------------------------------------------------------------------
	-- User Defined Alternate Stored Procedure
	-- ---------------------------------------
	-- Calculations that utilise a user defined stored procedure to perform the calculation
	-- may vary depending on the date of calculation. If a Source of Quantity with a Period
	-- Type has not been provided then these rate calculations must be performed for each 
	-- different date that other calculations are being performed to ensure that any 
	-- possible variation in result is catered for.
	---------------------------------------------------------------------------------------
	If  @ErrorCode=0
	Begin
		Set @sSQLString=
		"Insert into #TEMPCASECHARGES(	CASEID, IRN, YEARNO, CRITERIANO, CHARGETYPENO, RATENO, RATEDESC, CALCLABEL1, CALCLABEL2,"+char(10)+
		"				RENEWALDATE, CYCLE, FROMDATE, STEPDATEFLAG, USEEVENTNO,CHARGEEVENT,CHARGEACTION)"+char(10)+
		"Select	T.CASEID, T.IRN, T.YEARNO, T.CRITERIANO, T.CHARGETYPENO, T.RATENO, T.RATEDESC, T.CALCLABEL1, T.CALCLABEL2,"+char(10)+
		"	T.RENEWALDATE, T.CYCLE,T1.FROMDATE, 0, T.USEEVENTNO,T.CHARGEEVENT,T.CHARGEACTION"+char(10)+
		"from #TEMPCASECHARGES T"+char(10)+
		"join (	select distinct CASEID, FROMDATE"+char(10)+
		"	from #TEMPCASECHARGES"+char(10)+
		"	where FROMDATE is not null) T1 on (isnull(T1.CASEID,'')=isnull(T.CASEID,''))"+char(10)+
		"left join #TEMPCASECHARGES T2	on (isnull(T2.CASEID,'')=isnull(T.CASEID,'')"+char(10)+
		"				and T2.FROMDATE=T1.FROMDATE"+char(10)+
		"				and T2.RATENO=T.RATENO)"+char(10)+
		"where T2.FROMDATE is null"+char(10)+
		"and T.PERIODTYPE1 is null"+char(10)+
		"and exists"+char(10)+
		"(select 1 from FEESCALCALT F"+char(10)+
		" where F.CRITERIANO=T.CRITERIANO"+char(10)+
		" and F.COMPONENTTYPE=1)"+char(10)+
		"UNION"+char(10)+
		"Select	T.CASEID, T.IRN, T.YEARNO, T.CRITERIANO, T.CHARGETYPENO, T.RATENO, T.RATEDESC, T.CALCLABEL1, T.CALCLABEL2,"+char(10)+
		"	T.RENEWALDATE, T.CYCLE,T1.FROMDATE, 0, T.USEEVENTNO,T.CHARGEEVENT,T.CHARGEACTION"+char(10)+
		"from #TEMPCASECHARGES T"+char(10)+
		"join (	select distinct CASEID, FROMDATE"+char(10)+
		"	from #TEMPCASECHARGES"+char(10)+
		"	where FROMDATE is not null) T1 on (isnull(T1.CASEID,'')=isnull(T.CASEID,''))"+char(10)+
		"left join #TEMPCASECHARGES T2	on (isnull(T2.CASEID,'')=isnull(T.CASEID,'')"+char(10)+
		"				and T2.FROMDATE=T1.FROMDATE"+char(10)+
		"				and T2.RATENO=T.RATENO)"+char(10)+
		"where T2.FROMDATE is null"+char(10)+
		"and T.PERIODTYPE2 is null"+char(10)+
		"and exists"+char(10)+
		"(select 1 from FEESCALCALT F"+char(10)+
		" where F.CRITERIANO=T.CRITERIANO"+char(10)+
		" and F.COMPONENTTYPE=0)"

		Exec @ErrorCode=sp_executesql @sSQLString
	End

	-- For each case and calculation identify which ones do not 
	-- apply as at the current date and set the STEPDATEFLAG on
	If  @ErrorCode=0
	and exists(select 1 from @tblExtendedColumns where COLUMNNAME='InstructionCycleAny')
	Begin
		-- If a specific InstructionCycle can be identified then align the
		-- fees to be calculated by cycle
		Set @sSQLString="
		Update #TEMPCASECHARGES
		Set STEPDATEFLAG=1
		from #TEMPCASECHARGES T
		join "+@psGlobalTempTable+" C 	on (C.CASEID=T.CASEID"+
		CASE WHEN(@pbDyamicChargeType=1)
			THEN " and C.CHARGETYPENO=T.CHARGETYPENO)"
			ELSE ")"
		END+"
		where T.CYCLE<>C.InstructionCycleAny
		or (T.YEARNO is not null and T.CYCLE is NULL)"

		If @pbPrintSQL=1
		Begin
			Print 'For each case and calculation identify which ones do not apply as at the current date and set the STEPDATEFLAG on'
			Print @sSQLString
			Print ''
		End

		Exec @ErrorCode=sp_executesql @sSQLString
	End
	Else If @ErrorCode=0
	Begin
		-- Update any calculation that are as at a future
		-- date as long as there is a calculation that will
		-- apply before this date.
		Set @sSQLString="
		Update #TEMPCASECHARGES
		Set STEPDATEFLAG=1
		from #TEMPCASECHARGES T
		where T.FROMDATE>getdate()
		and exists
		(select 1
		 from #TEMPCASECHARGES T1
		 where isnull(T1.CASEID,'')=isnull(T.CASEID,'')
		 and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')
		 and T1.FROMDATE<T.FROMDATE)"

		If @pbPrintSQL=1
		Begin
			Print 'Update any calculation that are as at a future
		-- date as long as there is a calculation that will
		-- apply before this date.'
			Print @sSQLString
			Print ''
		End

		Exec @ErrorCode=sp_executesql @sSQLString

		If @ErrorCode=0
		Begin
			-- Now update any calculations where there is a
			-- later calculation  that is still earlier than 
			-- the current system date.
			Set @sSQLString="
			Update #TEMPCASECHARGES
			Set 	STEPDATEFLAG=1,
				ISEXPIREDSTEP=1
			from #TEMPCASECHARGES T
			where T.STEPDATEFLAG=0
			and exists
			(select 1
			 from #TEMPCASECHARGES T1
			 where isnull(T1.CASEID,'')=isnull(T.CASEID,'')
			 and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')
			 and isnull(T1.RATENO,'')=isnull(T.RATENO,'')
			 and T1.STEPDATEFLAG=0
			 and T1.FROMDATE>T.FROMDATE
			 and T1.FROMDATE<getdate())"			 
	
			Exec @ErrorCode=sp_executesql @sSQLString
		End
	End

	-- External Users will only see fees that apply as at
	-- todays date so delete any with the STEPDATEFLAG on.
	If  @bIsExternalUser=1
	and @ErrorCode=0
	Begin
		-- Delete any calculation that are as at a future
		-- date as long as there is a calculation that will
		-- apply before this date.
		Set @sSQLString="
		Delete #TEMPCASECHARGES
		where STEPDATEFLAG=1"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
	-- For extended Case data we do not require any stepped data unless the
	-- specific presentation columns indicate that this data is to be reported
	Else 
	If @pbDyamicChargeType=1
	and @ErrorCode=0
	and not exists(select 1 from @tblExtendedColumns where COLUMNNAME in ('FeeYearNoAny','FeeDueDateAny'))
	Begin
		-- Delete any calculation that are as at a future
		-- date as long as there is a calculation that will
		-- apply before this date.
		Set @sSQLString="
		Delete #TEMPCASECHARGES
		where STEPDATEFLAG=1"

		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		-- set a contiguous sequence no on the temporary
		-- table to make processing each row easier
		Set @nSequenceNo=0
		
		Set @sSQLString="
		Update #TEMPCASECHARGES
		Set @nSequenceNo=@nSequenceNo+1,
		SEQUENCENO=@nSequenceNo"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nSequenceNo		int	OUTPUT',
					  @nSequenceNo=@nSequenceNo	OUTPUT

		Set @nRowCount=@@rowcount

		-- Generate an index now the SequenceNo has been loaded
		CREATE INDEX XIECASECHARGES ON #TEMPCASECHARGES(SEQUENCENO	ASC)
	End

	-- Get the sequence number of the first row to processs

	Set @nCurrentRow=0

	-- Now loop through each row and call the procedures to do the calculations	
	While @nCurrentRow<@nRowCount
	and   @ErrorCode=0
	begin
		Set @nCurrentRow=@nCurrentRow+1
	
		set @sSQLString ="
		Select @sIRN            =IRN,
		       @nRateNo         =RATENO,
		       @nYearNo         =YEARNO,
		       @dtFromDateDisb	=BASEDATE1,	-- this is the date from which extension period is calculated
		       @nFromEventNoDisb=FROMEVENTNO1,	-- this is the EventNo used for Disbursements
		       @dtFromDateServ	=BASEDATE2,	-- this is the date from which extension period is calculated
		       @nFromEventNoServ=FROMEVENTNO2,	-- this is the EventNo used for Service charges
		       @dtUntilDate	=FROMDATE,	-- this is the date from which the charge applies
		       @nExtensionPeriod=EXTENSIONPERIOD,
		       @bNoCalcFlag     =isnull(NOCALCFLAG,0),
		       @nUseEventNo	=USEEVENTNO,
		       @dtRenewalDate	=RENEWALDATE,
		       @nChargeEventNo	=CHARGEEVENT,
		       @sAction		=CHARGEACTION	
		from #TEMPCASECHARGES
		where SEQUENCENO=@nCurrentRow"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIRN			nvarchar(30)	OUTPUT,
						  @nRateNo		int		OUTPUT,
						  @nYearNo		int		OUTPUT,
						  @nExtensionPeriod	smallint	OUTPUT,
						  @dtFromDateDisb	datetime	OUTPUT,
						  @dtFromDateServ	datetime	OUTPUT,
						  @nFromEventNoDisb	int		OUTPUT,
						  @nFromEventNoServ	int		OUTPUT,
						  @dtUntilDate		datetime	OUTPUT,
						  @bNoCalcFlag		bit		OUTPUT,
						  @nUseEventNo		int		OUTPUT,
						  @dtRenewalDate	datetime	OUTPUT,
						  @nChargeEventNo	int		OUTPUT,
						  @sAction		nvarchar(2)	OUTPUT,
						  @nCurrentRow		int',
						  @sIRN      	   =@sIRN		OUTPUT,
						  @nRateNo	   =@nRateNo		OUTPUT,
						  @nYearNo    	   =@nYearNo		OUTPUT,
						  @nExtensionPeriod=@nExtensionPeriod	OUTPUT,
						  @dtFromDateDisb  =@dtFromDateDisb	OUTPUT,
						  @dtFromDateServ  =@dtFromDateServ	OUTPUT,
						  @nFromEventNoDisb=@nFromEventNoDisb	OUTPUT,
						  @nFromEventNoServ=@nFromEventNoServ	OUTPUT,
						  @dtUntilDate     =@dtUntilDate	OUTPUT,
						  @bNoCalcFlag	   =@bNoCalcFlag	OUTPUT,
						  @nUseEventNo	   =@nUseEventNo	OUTPUT,
						  @dtRenewalDate   =@dtRenewalDate	OUTPUT,
						  @nChargeEventNo  =@nChargeEventNo	OUTPUT,
						  @sAction         =@sAction		OUTPUT,
						  @nCurrentRow	   =@nCurrentRow

		-------------------------------------------------------------
		-- Bypass the calcualtion if the NoCalcFlag is set indicating
		-- that the Case has already incurred the charge.
		-------------------------------------------------------------
		If @bNoCalcFlag=0
		Begin
			-- Now determine the source country and state (14649) to use for the tax rate
			If  @ErrorCode=0 
			and @sIRN is not null
			Begin
				-- First find the employee for case
				-- and get the Country of the Office
				-- get the State of the Office
				Set @sSQLString="
				Select	@nEmployeeNo       = CN.NAMENO,
					@sSourceCountryCode = O.COUNTRYCODE, 
					@sSourceState = A.STATE 
				from CASES C
				join CASENAME CN 		on (CN.CASEID=C.CASEID)
				left join TABLEATTRIBUTES TA	on (TA.PARENTTABLE= 'NAME'
								and TA.GENERICKEY = cast(CN.NAMENO as nvarchar)
								and TA.TABLETYPE  = 44)
				left join OFFICE O		on (O.OFFICEID=TA.TABLECODE)
				left join NAME N		on (N.NAMENO = O.ORGNAMENO)
				join ADDRESS A			on (A.ADDRESSCODE=N.POSTALADDRESS)
				Where C.IRN = @sIRN 
				and CN.NAMETYPE = 'EMP'
				and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())"
		
				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nEmployeeNo		int		OUTPUT,
							  @sSourceCountryCode	nvarchar(3)	OUTPUT,
							  @sSourceState		nvarchar(20)	OUTPUT,
							  @sIRN			nvarchar(30)',
							  @nEmployeeNo,
							  @sSourceCountryCode,
							  @sSourceState,
							  @sIRN
			End
	
			If  @ErrorCode=0 
			and @sSourceCountryCode is null
				-- Could be a host of reasons: 
				--	no case, no employee on case, no office on employee, no country on office
			Begin
				Set @sSourceCountryCode = 'ZZZ' -- Default country
			End

			If  @ErrorCode=0
			and @psGlobalTempTable is null
			and @nUseEventNo   is not null
			and @dtRenewalDate is not null
			Begin
				--------------------------------------------------------------
				-- If an Event is used to determine the Fees Calculation
				-- then we are going to attempt to calculate it.
				-- This can occur for an existing Case where we are simulating
				-- different dates the fee is being paid or it can be for a
				-- simulated "what if" Case where the current date is being 
				-- used as the date date the renewal is being applied for.
				--------------------------------------------------------------
				If @nSaveCheckSum<>CHECKSUM(@psCaseType,@psCountryCode,@psPropertyType,@psCaseCategory,@psSubType,@nCycle,@pnCaseId,@nUseEventNo,@dtRenewalDate,@dtUntilDate)
				or @nSaveCheckSum is null
				Begin
					Set @nSaveCheckSum=CHECKSUM(@psCaseType,@psCountryCode,@psPropertyType,@psCaseCategory,@psSubType,@nCycle,@pnCaseId,@nUseEventNo,@dtRenewalDate,@dtUntilDate)

					exec @ErrorCode=cs_CalculateEventDueDate
								@pdtCalculatedDate=@dtDueDate	OUTPUT,
								@psCaseType	  =@psCaseType,
								@psCountryCode	  =@psCountryCode,
								@psPropertyType	  =@psPropertyType,
								@psCaseCategory	  =@psCaseCategory,
								@psSubType	  =@psSubType,
								@psBasis	  =@psBasis,
								@pnCycle	  =@nCycle,
								@pnCaseId	  =@pnCaseId,	-- A specific CaseId is known
								@pnEventToCalc	  =@nUseEventNo,
								@pnFromEventNo1	  =null,
								@pdtFromDate1	  =@dtRenewalDate,
								@pnFromEventNo2	  =null,
								@pdtFromDate2	  =@dtUntilDate
				End
				
			End

			-- If the Action associated with the ChargeDueEvent is not known
			-- then get the Criteria that would calculate that Event and then
			-- use the Action.  This is required because Action can be used to
			-- determine a specific Margin to use.

			If @ErrorCode=0
			and @sAction is null
			and @nChargeEventNo is not null
			Begin
				-- Try and find the Action used to calculate the ChargeDueEventNo
				-- if the characteristics have changed
				If @nSaveCheckSum1=CHECKSUM(@psCaseType,@psCountryCode,@psPropertyType,@psCaseCategory,@psSubType,@nCycle,@pnCaseId,@nChargeEventNo)
				Begin
					Set @sAction=@sSavedAction
				End
				Else Begin
					Set @nSaveCheckSum1=CHECKSUM(@psCaseType,@psCountryCode,@psPropertyType,@psCaseCategory,@psSubType,@nCycle,@pnCaseId,@nChargeEventNo)
					exec @ErrorCode=cs_CalculateEventDueDate
								@pnCriteriaNo     =@nCriteriaNo	OUTPUT,
								@psCaseType	  =@psCaseType,
								@psCountryCode	  =@psCountryCode,
								@psPropertyType	  =@psPropertyType,
								@psCaseCategory	  =@psCaseCategory,
								@psSubType	  =@psSubType,
								@psBasis	  =@psBasis,
								@pnCycle	  =@nCycle,
								@pnCaseId	  =@pnCaseId,	-- A specific CaseId if known
								@pnEventToCalc	  =@nChargeEventNo,
								@pbCriteriaOnly   =1

					If @nCriteriaNo is null
						Set @sSavedAction=null
					Else If @ErrorCode=0
					Begin
						Set @sSQLString="
						Select	@sSavedAction=ACTION,
							@sAction     =ACTION
						from CRITERIA
						Where CRITERIANO=@nCriteriaNo"

						Exec @ErrorCode=sp_executesql @sSQLString,
									N'@sSavedAction		nvarchar(2)	OUTPUT,
									  @sAction		nvarchar(2)	OUTPUT,
									  @nCriteriaNo		int',
									  @sSavedAction	=@sSavedAction		OUTPUT,
									  @sAction	=@sAction		OUTPUT,
									  @nCriteriaNo	=@nCriteriaNo
					End
				End
			End


			-- Now use the FEESCALC stored procedure to determine the fees and 
			-- charges
			If @ErrorCode=0
			Begin
				If  @nFromEventNoDisb  is null
				and @dtFromDateDisb    is null
				and @dtRenewalDate is not null
					Set @dtFromDateDisb=@dtRenewalDate

				If  @nFromEventNoServ  is null
				and @dtFromDateServ    is null
				and @dtRenewalDate is not null
					Set @dtFromDateServ=@dtRenewalDate

				exec @ErrorCode=FEESCALC 
					@psIRN			=@sIRN,
					@pnRateNo		=@nRateNo,
					@psAction		=@sAction,
					@pnCycle		=@nYearNo,
					@pdtLetterDate		=@dtUntilDate,	-- date at which fee will be calculated
					@pnEnteredQuantity	=@pnQuantity,
					@prsDisbCurrency	=@prsDisbCurrency 	output,	
					@prnDisbExchRate	=@prnDisbExchRate 	output, 
					@prsServCurrency	=@prsServCurrency 	output, 	
					@prnServExchRate	=@prnServExchRate 	output, 
					@prsBillCurrency	=@prsBillCurrency 	output, 	
					@prnBillExchRate	=@prnBillExchRate 	output, 
					@prsDisbTaxCode		=@prsDisbTaxCode 	output, 	
					@prsServTaxCode		=@prsServTaxCode 	output, 
					@prnDisbNarrative	=@prnDisbNarrative 	output, 		
					@prnServNarrative	=@prnServNarrative 	output, 
					@prsDisbWIPCode		=@prsDisbWIPCode 	output, 	
					@prsServWIPCode		=@prsServWIPCode 	output, 
					@prnDisbAmount		=@prnDisbAmount 	output, 	
					@prnDisbHomeAmount	=@prnDisbHomeAmount 	output, 
					@prnDisbBillAmount	=@prnDisbBillAmount 	output,
					@prnServAmount		=@prnServAmount 	output, 
					@prnServHomeAmount	=@prnServHomeAmount 	output,
					@prnServBillAmount	=@prnServBillAmount 	output, 
					@prnTotHomeDiscount	=@prnTotHomeDiscount	output,
					@prnTotBillDiscount	=@prnTotBillDiscount	output, 
					@prnDisbTaxAmt		=@prnDisbTaxAmt 	output, 	
					@prnDisbTaxHomeAmt	=@prnDisbTaxHomeAmt 	output, 
					@prnDisbTaxBillAmt	=@prnDisbTaxBillAmt 	output,
					@prnServTaxAmt		=@prnServTaxAmt 	output, 	
					@prnServTaxHomeAmt	=@prnServTaxHomeAmt 	output,
					@prnServTaxBillAmt	=@prnServTaxBillAmt 	output,
					@prnDisbDiscOriginal	=@prnDisbDiscOriginal 	output,
					@prnDisbHomeDiscount	=@prnDisbHomeDiscount 	output,
					@prnDisbBillDiscount	=@prnDisbBillDiscount 	output, 
					@prnServDiscOriginal	=@prnServDiscOriginal	output,
					@prnServHomeDiscount	=@prnServHomeDiscount 	output,
					@prnServBillDiscount	=@prnServBillDiscount 	output,
					@prnDisbMargin		=@prnDisbMargin		output,
					@prnDisbHomeMargin	=@prnDisbHomeMargin	output,
					@prnDisbBillMargin	=@prnDisbBillMargin	output,
					@prnServMargin		=@prnServMargin		output,
					@prnServHomeMargin	=@prnServHomeMargin	output,
					@prnServBillMargin	=@prnServBillMargin	output,
					@prnDisbCostHome	=@prnDisbCostHome	output,
					@prnDisbCostOriginal	=@prnDisbCostOriginal	output,
					@prnVariableFeeAmt	=@prnVariableFeeAmt	output,
					@prnVarHomeFeeAmt	=@prnVarHomeFeeAmt	output,
					@prnVarBillFeeAmt	=@prnVarBillFeeAmt	output,
					@prnVarTaxAmt		=@prnVarTaxAmt		output,
					@prnVarTaxHomeAmt	=@prnVarTaxHomeAmt	output,
					@prnVarTaxBillAmt	=@prnVarTaxBillAmt	output,
					-- Simulated date the fee applies at.
					@pdtTransactionDate	=@dtUntilDate,
					@pdtFromEventDate	=@dtDueDate, -- Use the calculated Due Date if available
					--SQA12361 allow variables to be entered instead of a CaseId.
					--         This is to allow a "what if" style of enquiry
					@psCaseType	 =@psCaseType,
					@psCountryCode	 =@psCountryCode,
					@psPropertyType	 =@psPropertyType,
					@psCaseCategory	 =@psCaseCategory,
					@psSubType	 =@psSubType,
					@pnEntitySize	 =@pnEntitySize,
					@pnInstructor	 =@pnInstructor,
					@pnForDebtor	 =@pnDebtor,
					@pnDebtorType	 =@pnDebtorType,
					@pnAgent	 =@pnAgent,
					@psCurrency	 =@psCurrency,
					@pnExchScheduleId=@pnExchScheduleId,
					@pdtFromDateDisb =@dtFromDateDisb,
					@pdtFromDateServ =@dtFromDateServ,
					@pdtUntilDate	 =@dtUntilDate,
					-- Return pre discount and marging adjusted value
					@pnDisbSourceAmt =@pnDisbSourceAmt	output,
					@pnServSourceAmt =@pnServSourceAmt	output,
					@pbUseTodaysExchangeRate=1,	--SQA15943
					-- SQA14649 New Output parameters for multi-tier tax
					@prsDisbStateTaxCode 	=@prsDisbStateTaxCode	  output, 
					@prsServStateTaxCode 	=@prsServStateTaxCode	  output, 
					@prnDisbStateTaxAmt 	=@prnDisbStateTaxAmt	  output, 
					@prnDisbStateTaxHomeAmt =@prnDisbStateTaxHomeAmt  output, 
					@prnDisbStateTaxBillAmt =@prnDisbStateTaxBillAmt  output, 
					@prnServStateTaxAmt 	=@prnServStateTaxAmt	  output, 
					@prnServStateTaxHomeAmt =@prnServStateTaxHomeAmt  output,
					@prnServStateTaxBillAmt =@prnServStateTaxBillAmt  output,
					-- RFC13222
					@pbCycleIsAgeOfCase     =1

				-- Update the row just processed with the extracted charges or
				-- remove it if an error was returned.
			
				If @ErrorCode<>0
				Begin 
					-- Reset the Error Code for the next row to process
					Set @ErrorCode=0
		
					-- Delete the #TEMPCASECHARGES row
					Set @sSQLString="
					delete #TEMPCASECHARGES
					where SEQUENCENO=@nCurrentRow"
		
					exec @ErrorCode=sp_executesql @sSQLString,
								N'@nCurrentRow	int',
								  @nCurrentRow=@nCurrentRow
				End
				Else Begin
					-- RFC7302
					-- Variable fees that are effectively a minimal
					-- charge are to replace the calculated service
					-- charge if greater in value
					If abs(@prnServAmount)<abs(@prnVariableFeeAmt)
					begin
						Set @prnServAmount	=@prnVariableFeeAmt
						Set @prnServHomeAmount	=@prnVarHomeFeeAmt
						Set @prnServBillAmount	=@prnVarBillFeeAmt
						Set @prnServTaxAmt	=@prnVarTaxAmt
						Set @prnServTaxHomeAmt	=@prnVarTaxHomeAmt
						Set @prnServTaxBillAmt	=@prnVarTaxBillAmt
						set @pnServSourceAmt	=null			-- value unavailable
					End
					
					
					-- 14649 extended to include new multi-tier tax details
					set @sSQLString="
					update #TEMPCASECHARGES
					set	ESTIMATEFLAG		= 0,
						DISBCURRENCY		=@prsDisbCurrency,
						SERVCURRENCY		=@prsServCurrency,
						BILLCURRENCY		=@prsBillCurrency,
						DISBAMOUNT		=@prnDisbAmount,
						DISBHOMEAMOUNT		=@prnDisbHomeAmount,
						DISBBILLAMOUNT		=@prnDisbBillAmount,
						SERVAMOUNT		=@prnServAmount,
						SERVHOMEAMOUNT		=@prnServHomeAmount,
						SERVBILLAMOUNT		=@prnServBillAmount,
						DISBDISCORIGINAL	=@prnDisbDiscOriginal,
						DISBHOMEDISCOUNT	=@prnDisbHomeDiscount,
						DISBBILLDISCOUNT	=@prnDisbBillDiscount,
						SERVDISCORIGINAL	=@prnServDiscOriginal,
						SERVHOMEDISCOUNT	=@prnServHomeDiscount,
						SERVBILLDISCOUNT	=@prnServBillDiscount,
						TOTHOMEDISCOUNT		=@prnTotHomeDiscount,
						TOTBILLDISCOUNT		=@prnTotBillDiscount,
						DISBMARGIN		=@prnDisbMargin,
						DISBHOMEMARGIN		=@prnDisbHomeMargin,
						DISBBILLMARGIN		=@prnDisbBillMargin,
						SERVMARGIN		=@prnServMargin,
						SERVHOMEMARGIN		=@prnServHomeMargin,
						SERVBILLMARGIN		=@prnServBillMargin,
						DISBTAXAMT		=@prnDisbTaxAmt,
						DISBTAXHOMEAMT		=@prnDisbTaxHomeAmt,
						DISBTAXBILLAMT		=@prnDisbTaxBillAmt,
						SERVTAXAMT		=@prnServTaxAmt,
						SERVTAXHOMEAMT		=@prnServTaxHomeAmt,
						SERVTAXBILLAMT		=@prnServTaxBillAmt,
						DISBSTATETAXAMT		=@prnDisbTaxAmt,
						DISBSTATETAXHOMEAMT	=@prnDisbStateTaxHomeAmt,
						DISBSTATETAXBILLAMT	=@prnDisbStateTaxBillAmt,
						SERVSTATETAXAMT		=@prnDisbStateTaxBillAmt,
						SERVSTATETAXHOMEAMT	=@prnServStateTaxHomeAmt,
						SERVSTATETAXBILLAMT	=@prnServStateTaxBillAmt,
						DISBTAXCODE		=@prsDisbTaxCode,
						SERVTAXCODE		=@prsServTaxCode,
						DISBSTATETAXCODE	=@prsDisbStateTaxCode,
						SERVSTATETAXCODE	=@prsServStateTaxCode,
						SOURCECOUNTRY   	=@sSourceCountryCode,
						SOURCESTATE		=@sSourceState,
						DISBWIPCODE		=@prsDisbWIPCode,
						SERVWIPCODE		=@prsServWIPCode,
						DISBSOURCEAMT		=@pnDisbSourceAmt,
						SERVSOURCEAMT		=@pnServSourceAmt
					where SEQUENCENO=@nCurrentRow"
			
					exec @ErrorCode=sp_executesql @sSQLString,
								N'@prsDisbCurrency		nvarchar(3),
				 				  @prsServCurrency		nvarchar(3),
								  @prsBillCurrency		nvarchar(3),
								  @prnDisbAmount		decimal(11,2),
								  @prnDisbHomeAmount		decimal(11,2),
								  @prnDisbBillAmount		decimal(11,2),
								  @prnServAmount		decimal(11,2),
								  @prnServHomeAmount		decimal(11,2),
								  @prnServBillAmount		decimal(11,2),
								  @prnDisbDiscOriginal		decimal(11,2),
								  @prnDisbHomeDiscount		decimal(11,2),
								  @prnDisbBillDiscount		decimal(11,2),
								  @prnServDiscOriginal		decimal(11,2),
								  @prnServHomeDiscount		decimal(11,2),
								  @prnServBillDiscount		decimal(11,2),
								  @prnTotHomeDiscount		decimal(11,2),
								  @prnTotBillDiscount		decimal(11,2),
								  @prnDisbMargin		decimal(11,2),
								  @prnDisbHomeMargin		decimal(11,2),
								  @prnDisbBillMargin		decimal(11,2),
								  @prnServMargin		decimal(11,2),
								  @prnServHomeMargin		decimal(11,2),
								  @prnServBillMargin		decimal(11,2),
								  @prnDisbTaxAmt		decimal(11,2),
								  @prnDisbTaxHomeAmt		decimal(11,2),
								  @prnDisbTaxBillAmt		decimal(11,2),
								  @prnServTaxAmt		decimal(11,2),
								  @prnServTaxHomeAmt		decimal(11,2),
								  @prnServTaxBillAmt		decimal(11,2),
								  @prnDisbStateTaxAmt		decimal(11,2),
								  @prnDisbStateTaxHomeAmt	decimal(11,2),
								  @prnDisbStateTaxBillAmt	decimal(11,2),
								  @prnServStateTaxAmt		decimal(11,2),
								  @prnServStateTaxHomeAmt	decimal(11,2),
								  @prnServStateTaxBillAmt	decimal(11,2),						
								  @prsDisbTaxCode		nvarchar(3),
								  @prsServTaxCode		nvarchar(3),
								  @prsDisbStateTaxCode		nvarchar(3),
								  @prsServStateTaxCode		nvarchar(3),
								  @sSourceCountryCode		nvarchar(3),
								  @sSourceState			nvarchar(20),
								  @prsDisbWIPCode		nvarchar(6),
								  @prsServWIPCode		nvarchar(6),
								  @pnDisbSourceAmt		decimal(11,2),
								  @pnServSourceAmt		decimal(11,2),
								  @nCurrentRow			int',
								  @prsDisbCurrency,
								  @prsServCurrency,
								  @prsBillCurrency,
								  @prnDisbAmount,
								  @prnDisbHomeAmount,
								  @prnDisbBillAmount,
								  @prnServAmount,
								  @prnServHomeAmount,
								  @prnServBillAmount,
								  @prnDisbDiscOriginal,
								  @prnDisbHomeDiscount,
								  @prnDisbBillDiscount,
								  @prnServDiscOriginal,
								  @prnServHomeDiscount,
								  @prnServBillDiscount,
								  @prnTotHomeDiscount,
								  @prnTotBillDiscount,
								  @prnDisbMargin,
								  @prnDisbHomeMargin,
								  @prnDisbBillMargin,
								  @prnServMargin,
								  @prnServHomeMargin,
								  @prnServBillMargin,
								  @prnDisbTaxAmt,
								  @prnDisbTaxHomeAmt,
								  @prnDisbTaxBillAmt,
								  @prnServTaxAmt,
								  @prnServTaxHomeAmt,
								  @prnServTaxBillAmt,
								  @prnDisbStateTaxAmt,
								  @prnDisbStateTaxHomeAmt,
								  @prnDisbStateTaxBillAmt,
								  @prnServStateTaxAmt,
								  @prnServStateTaxHomeAmt,
								  @prnServStateTaxBillAmt,
								  @prsDisbTaxCode,
								  @prsServTaxCode,
								  @prsDisbStateTaxCode,
								  @prsServStateTaxCode,
								  @sSourceCountryCode,
								  @sSourceState,
								  @prsDisbWIPCode,
								  @prsServWIPCode,
								  @pnDisbSourceAmt,
								  @pnServSourceAmt,
								  @nCurrentRow
				End
					
			End

			-- For each row extracted check if an estimate has been saved and extract it
			-- if the user has requested this information.
			/*******	
				NOTE: SQA14649 If the StateTaxAmount has been set then this means:
				Multi-Tier Tax is applicable and Federal Tax was NOT harmonised
				If the State Tax was harmonised Federal Tax Amounts would be 0 or NULL
				As a result the StateTaxAmt in Billing Currency needs to be calculated 
				taking into account the TaxOnTax option.			
			*******/
			
			If  @pbSavedEstimate=1
			and @bCanViewEstimates=1
			and @ErrorCode=0
			Begin
				-- 21903 estimates for tax should exclude discount
				select @sSQLString="INSERT INTO #TEMPCASECHARGES (CASEID, YEARNO, IRN, CHARGETYPENO, RATENO, ESTIMATEFLAG, ESTIMATEDATE,"+char(10)+
				"DISBCURRENCY,SERVCURRENCY,BILLCURRENCY,DISBAMOUNT,DISBHOMEAMOUNT,DISBBILLAMOUNT,SERVAMOUNT,SERVHOMEAMOUNT,"+char(10)+
				"SERVBILLAMOUNT,DISBDISCORIGINAL,DISBHOMEDISCOUNT,DISBBILLDISCOUNT,SERVDISCORIGINAL,SERVHOMEDISCOUNT,"+char(10)+
				"SERVBILLDISCOUNT,TOTHOMEDISCOUNT,TOTBILLDISCOUNT,DISBTAXAMT,DISBTAXHOMEAMT,DISBTAXBILLAMT,SERVTAXAMT,"+char(10)+
				"SERVTAXHOMEAMT,SERVTAXBILLAMT,DISBSTATETAXAMT,DISBSTATETAXHOMEAMT,DISBSTATETAXBILLAMT, "+char(10)+
				"SERVSTATETAXAMT, SERVSTATETAXHOMEAMT,SERVSTATETAXBILLAMT)"+char(10)+
				"SELECT T.CASEID, T.YEARNO, T.IRN, T.CHARGETYPENO, A.RATENO, 1, A.WHENOCCURRED,A.DISBCURRENCY, A.SERVICECURRENCY,"+char(10)+
				"A.BILLCURRENCY, A.DISBORIGINALAMOUNT, A.DISBAMOUNT, isnull(A.DISBBILLAMOUNT, A.DISBAMOUNT*A.BILLEXCHANGERATE),"+char(10)+
				"A.SERVORIGINALAMOUNT, A.SERVICEAMOUNT, isnull(A.SERVBILLAMOUNT, A.SERVICEAMOUNT*A.BILLEXCHANGERATE), A.DISBDISCORIGINAL,"+char(10)+
				"A.DISBDISCOUNT, isnull(A.DISBBILLDISCOUNT, A.DISBDISCOUNT*A.BILLEXCHANGERATE), A.SERVDISCORIGINAL, A.SERVDISCOUNT,"+char(10)+
				"isnull(A.SERVBILLDISCOUNT, A.SERVDISCOUNT*A.BILLEXCHANGERATE), A.TOTALDISCOUNT, isnull(A.DISCBILLAMOUNT, "+char(10)+
				"A.TOTALDISCOUNT*A.BILLEXCHANGERATE), A.DISBTAXAMOUNT, A.DISBTAXAMOUNT / A.DISBEXCHANGERATE,"+char(10)+
				"isnull(A.DISBBILLAMOUNT-A.DISBBILLDISCOUNT, (A.DISBAMOUNT-A.DISBDISCOUNT)*A.BILLEXCHANGERATE) * isnull(TDC1.RATE, 0) / 100  'DISBTAXBILLAMT',"+char(10)+
				"A.SERVICETAXAMOUNT, A.SERVICETAXAMOUNT / A.SERVEXCHANGERATE,"+char(10)+
				"isnull(A.SERVBILLAMOUNT-A.SERVBILLDISCOUNT, (A.SERVICEAMOUNT-A.SERVDISCOUNT)*A.BILLEXCHANGERATE) * isnull(TSC1.RATE, 0) / 100 as  'SERVTAXBILLAMT',"+char(10)+
				"A.DISBSTATETAXAMT, A.DISBSTATETAXAMT / A.DISBEXCHANGERATE,"+char(10)+
				"CASE WHEN A.DISBSTATETAXAMT IS NOT NULL THEN"+char(10)+
				"	CASE WHEN TDC3.TAXONTAX = 1 THEN"+char(10)+
				"		(isnull(A.DISBBILLAMOUNT, A.DISBAMOUNT*A.BILLEXCHANGERATE)+ "+char(10)+
				"		isnull(A.DISBBILLAMOUNT, A.DISBAMOUNT*A.BILLEXCHANGERATE) * isnull(TDC1.RATE, 0) / 100) "+char(10)+
				"			* isnull(TDC3.RATE, 0) / 100"+char(10)+
				"	ELSE isnull(A.DISBBILLAMOUNT, A.DISBAMOUNT*A.BILLEXCHANGERATE)* isnull(TDC3.RATE, 0) / 100"+char(10)+
				"	END ELSE NULL END,"+char(10)+
				"A.SERVSTATETAXAMT, A.SERVSTATETAXAMT / A.SERVEXCHANGERATE,"+char(10)+
				"CASE WHEN A.SERVSTATETAXAMT IS NOT NULL THEN"+char(10)+
				"	CASE WHEN TSC3.TAXONTAX = 1 THEN"+char(10)+
				"		(isnull(A.SERVBILLAMOUNT, A.SERVICEAMOUNT*A.BILLEXCHANGERATE)+ "+char(10)+
				"		isnull(A.SERVBILLAMOUNT, A.SERVICEAMOUNT*A.BILLEXCHANGERATE) * isnull(TSC1.RATE, 0) / 100) "+char(10)+
				"			* isnull(TSC3.RATE, 0) / 100"+char(10)+
				"	ELSE isnull(A.SERVBILLAMOUNT, A.SERVICEAMOUNT*A.BILLEXCHANGERATE)* isnull(TSC3.RATE, 0) / 100"+char(10)+
				"	END ELSE NULL END"+char(10)+
				"from	#TEMPCASECHARGES T"+char(10)+
				"join	ACTIVITYHISTORY A on (A.CASEID=T.CASEID"+char(10)+
				"			  and A.RATENO=T.RATENO)"+char(10)+
				"left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID"+char(10)+
				"				and(T1.YEARNO=T.YEARNO or (T1.YEARNO is null and T.YEARNO is null))"+char(10)+
				"				and T1.RATENO=T.RATENO"+char(10)+
				"				and T1.ESTIMATEFLAG=1)"+char(10)+
				-- R70762 added isnull next line to get Tax Code from estimate if not set
				"left join TAXRATESCOUNTRY TDC1	ON (TDC1.TAXCODE = isnull(T.DISBTAXCODE,A.DISBTAXCODE)"+char(10)+
				"				AND TDC1.COUNTRYCODE="+char(10)+
				"					(select min(TDC2.COUNTRYCODE)"+char(10)+
				"					from TAXRATESCOUNTRY TDC2"+char(10)+
				"					where TDC2.TAXCODE=TDC1.TAXCODE"+char(10)+
				"					and TDC2.COUNTRYCODE in (T.SOURCECOUNTRY,'ZZZ'))"+char(10)+
				"				and isnull(TDC1.EFFECTIVEDATE,'')="+char(10)+
				"					isnull((select max(isnull(TDC2.EFFECTIVEDATE,''))"+char(10)+
				"					from TAXRATESCOUNTRY TDC2"+char(10)+
				"					where TDC2.TAXCODE=TDC1.TAXCODE"+char(10)+
				"					and TDC2.COUNTRYCODE=TDC1.COUNTRYCODE"+char(10)+
				"					and TDC2.EFFECTIVEDATE<=isnull(A.WHENOCCURRED,getdate())),''))"+char(10)+
				"left join TAXRATESCOUNTRY TDC3 ON (TDC3.TAXCODE = T.DISBSTATETAXCODE AND TDC3.COUNTRYCODE = T.SOURCECOUNTRY AND TDC3.STATE = T.SOURCESTATE)"+char(10)+
				-- R70762 added isnull next line to get Tax Code from estimate if not set
				"left join TAXRATESCOUNTRY TSC1	ON (TSC1.TAXCODE = isnull(T.SERVTAXCODE,A.SERVICETAXCODE)"+char(10)+
				"				AND TSC1.COUNTRYCODE="+char(10)+
				"					(select min(TSC2.COUNTRYCODE)"+char(10)+
				"					from TAXRATESCOUNTRY TSC2"+char(10)+
				"					where TSC2.TAXCODE=TSC1.TAXCODE"+char(10)+
				"					and TSC2.COUNTRYCODE in (T.SOURCECOUNTRY,'ZZZ'))"+char(10)+
				"				and isnull(TSC1.EFFECTIVEDATE,'')="+char(10)+
				"					isnull((select max(isnull(TSC2.EFFECTIVEDATE,''))"+char(10)+
				"					from TAXRATESCOUNTRY TSC2"+char(10)+
				"					where TSC2.TAXCODE=TSC1.TAXCODE"+char(10)+
				"					and TSC2.COUNTRYCODE=TSC1.COUNTRYCODE"+char(10)+
				"					and TSC2.EFFECTIVEDATE<=isnull(A.WHENOCCURRED,getdate())),''))"+char(10)+
				"left join TAXRATESCOUNTRY TSC3 ON (TSC3.TAXCODE = T.DISBSTATETAXCODE AND TSC3.COUNTRYCODE = T.SOURCECOUNTRY AND TSC3.STATE = T.SOURCESTATE)"+char(10)+
				"left join dbo.fn_GetAgeOfCase(0,default) AC on (AC.CASEID=T.CASEID"+char(10)+
				"					     and AC.CYCLE =T.CYCLE)"+char(10)+
				"where T1.CASEID is null -- do not extract the estimate more than once"+char(10)+
				"and T.RATENO = @nRateNo"+char(10)+
				"and A.ACTIVITYCODE = 3202"+char(10)+
				"and A.ESTIMATEFLAG = 1"+char(10)+
				"and A.PAYFEECODE is null"+char(10)+
				"and (A.CYCLE = isnull(T.YEARNO,AC.ANNUITY) OR (A.CYCLE is null and isnull(T.YEARNO,AC.ANNUITY) is null))"+char(10)+
				"and A.WHENREQUESTED =( select max(WHENREQUESTED)"+char(10)+
				"			from ACTIVITYHISTORY A1"+char(10)+
				"			where A1.CASEID = A.CASEID"+char(10)+
				"			and A1.RATENO = A.RATENO"+char(10)+
				"			and A1.ACTIVITYCODE = A.ACTIVITYCODE"+char(10)+
				"			and A1.ESTIMATEFLAG = 1"+char(10)+
				"			and A1.PAYFEECODE is null"+char(10)+
				"			and (A1.CYCLE = A.CYCLE OR (A1.CYCLE is null and A.CYCLE is null)))"
			

				If @pbPrintSQL=1
				Begin
					Print 'For each row extracted check if an estimate has been saved and extract it
			-- if the user has requested this information.'
					Print @sSQLString
					Print ''
				End

				exec @ErrorCode=sp_executesql @sSQLString,
								N'@nRateNo		int',
								  @nRateNo=@nRateNo


			
			End
		End  -- End of @bNoCalcFlag=0
	End	-- End of WHILE loop
End

-- We have calculated the individual charges which now need to be combined
-- together so for each Annuity there exists the full set of charges that
-- have a value and also if there were any stepped charges (by From Date)
-- then each step will also require the other charges that would also
-- apply at each step.
If @ErrorCode=0
Begin
	-----------------------------------------------------
	-- Step 1: Set the YEARNO by matching on Renewal Date
	-----------------------------------------------------
	Set @sSQLString="
	Update #TEMPCASECHARGES
	Set YEARNO=T1.YEARNO
	from #TEMPCASECHARGES T
	join (	select distinct YEARNO, CASEID, CYCLE, RENEWALDATE
		from #TEMPCASECHARGES
		where YEARNO is not null
		and CYCLE is not null
		and RENEWALDATE is not null) T1	on (T1.CYCLE=T.CYCLE
						and T1.RENEWALDATE=T.RENEWALDATE
						and(T1.CASEID=T.CASEID OR (T1.CASEID is null and T.CASEID is null)))
	where T.YEARNO is null"

	If @pbPrintSQL=1
	Begin
		Print 'Set the YEARNO by matching on Renewal Date'
		Print @sSQLString
		Print ''
	End

	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	--------------------------------------------------------------------------------
	-- Step 2: Now for each YEARNO ensure there is a full complement of other RATENO
	--	   rows (if they have values)
	--------------------------------------------------------------------------------
	Set @sSQLString="
	Insert into #TEMPCASECHARGES(CASEID,IRN,YEARNO,CYCLE,RENEWALDATE,FROMDATE,STEPDATEFLAG,ISEXPIREDSTEP,CHARGETYPENO,RATENO,RATEDESC,CALCLABEL1,CALCLABEL2,FROMEVENTNO1,UNTILEVENTNO1,PERIODTYPE1,FROMEVENTNO2,UNTILEVENTNO2,PERIODTYPE2,EXTENSIONPERIOD,ESTIMATEFLAG,ESTIMATEDATE,DISBCURRENCY,SERVCURRENCY,BILLCURRENCY,DISBAMOUNT,DISBHOMEAMOUNT,DISBBILLAMOUNT,SERVAMOUNT,SERVHOMEAMOUNT,SERVBILLAMOUNT,DISBDISCORIGINAL,DISBHOMEDISCOUNT,DISBBILLDISCOUNT,SERVDISCORIGINAL,SERVHOMEDISCOUNT,SERVBILLDISCOUNT,TOTHOMEDISCOUNT,TOTBILLDISCOUNT,DISBMARGIN,DISBHOMEMARGIN,DISBBILLMARGIN,SERVMARGIN,SERVHOMEMARGIN,SERVBILLMARGIN,DISBTAXAMT,DISBTAXHOMEAMT,DISBTAXBILLAMT,SERVTAXAMT,SERVTAXHOMEAMT,SERVTAXBILLAMT,DISBSTATETAXAMT,DISBSTATETAXHOMEAMT,DISBSTATETAXBILLAMT,SERVSTATETAXAMT,SERVSTATETAXHOMEAMT,SERVSTATETAXBILLAMT,DISBTAXCODE,SERVTAXCODE,DISBSTATETAXCODE,SERVSTATETAXCODE,SOURCECOUNTRY,SOURCESTATE,DISBWIPCODE,SERVWIPCODE,DISBSOURCEAMT,SERVSOURCEAMT)
	select distinct T.CASEID,T.IRN,T1.YEARNO,T1.CYCLE,T1.RENEWALDATE,T1.RENEWALDATE,T1.STEPDATEFLAG,T1.ISEXPIREDSTEP,T.CHARGETYPENO,T.RATENO,T.RATEDESC,T.CALCLABEL1,T.CALCLABEL2,T.FROMEVENTNO1,T.UNTILEVENTNO1,T.PERIODTYPE1,T.FROMEVENTNO2,T.UNTILEVENTNO2,T.PERIODTYPE2,T.EXTENSIONPERIOD,T.ESTIMATEFLAG,T.ESTIMATEDATE,T.DISBCURRENCY,T.SERVCURRENCY,T.BILLCURRENCY,T.DISBAMOUNT,T.DISBHOMEAMOUNT,T.DISBBILLAMOUNT,T.SERVAMOUNT,T.SERVHOMEAMOUNT,T.SERVBILLAMOUNT,T.DISBDISCORIGINAL,T.DISBHOMEDISCOUNT,T.DISBBILLDISCOUNT,T.SERVDISCORIGINAL,T.SERVHOMEDISCOUNT,T.SERVBILLDISCOUNT,T.TOTHOMEDISCOUNT,T.TOTBILLDISCOUNT,T.DISBMARGIN,T.DISBHOMEMARGIN,T.DISBBILLMARGIN,T.SERVMARGIN,T.SERVHOMEMARGIN,T.SERVBILLMARGIN,T.DISBTAXAMT,T.DISBTAXHOMEAMT,T.DISBTAXBILLAMT,T.SERVTAXAMT,T.SERVTAXHOMEAMT,T.SERVTAXBILLAMT,T.DISBSTATETAXAMT,T.DISBSTATETAXHOMEAMT,T.DISBSTATETAXBILLAMT,T.SERVSTATETAXAMT,T.SERVSTATETAXHOMEAMT,T.SERVSTATETAXBILLAMT,T.DISBTAXCODE,T.SERVTAXCODE,T.DISBSTATETAXCODE,T.SERVSTATETAXCODE,T.SOURCECOUNTRY,T.SOURCESTATE,T.DISBWIPCODE,T.SERVWIPCODE,T.DISBSOURCEAMT,T.SERVSOURCEAMT
	from #TEMPCASECHARGES T
	join #TEMPCASECHARGES T1 	on ((T1.CASEID=T.CASEID OR (T1.CASEID is null and T.CASEID is null))
					and  T1.CHARGETYPENO=T.CHARGETYPENO	-- SQA18429
					and  T1.YEARNO>T.YEARNO
					and  T1.RATENO<>T.RATENO)
	left join #TEMPCASECHARGES T2	on ((T2.CASEID=T.CASEID OR (T2.CASEID is null and T.CASEID is null))
					and  T2.CHARGETYPENO=T1.CHARGETYPENO	-- SQA18429
					and  T2.YEARNO=T1.YEARNO
					and  T2.RATENO=T.RATENO)
	Where T2.RATENO is null -- the new row does not already exist
	and T.ESTIMATEFLAG=0	-- don't copy the estimates
	and T.FROMDATE is null
	-- Copy the Rates from the lowest YearNo against this Case
	and isnull(T.YEARNO,'')
		= isnull((select min(T3.YEARNO)
			from #TEMPCASECHARGES T3
			where isnull(T3.CASEID,'')=isnull(T.CASEID,'')
			and T3.YEARNO is not null),'')
	-- Only copy rows if a billing amount has been calculated
	and(T.DISBBILLAMOUNT<>0 OR T.SERVBILLAMOUNT<>0)"

	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	----------------------------------------------------------------------------------
	-- Step 3: Now for each FROMDATE ensure there is a full complement of other RATENO
	--	   rows (if they have values).
	--	   This step will add Rates with no From Date
	----------------------------------------------------------------------------------
	Set @sSQLString="
	Insert into #TEMPCASECHARGES(CASEID,IRN,YEARNO,CYCLE,RENEWALDATE,FROMDATE,STEPDATEFLAG,ISEXPIREDSTEP,CHARGETYPENO,RATENO,RATEDESC,CALCLABEL1,CALCLABEL2,FROMEVENTNO1,UNTILEVENTNO1,PERIODTYPE1,FROMEVENTNO2,UNTILEVENTNO2,PERIODTYPE2,EXTENSIONPERIOD,ESTIMATEFLAG,ESTIMATEDATE,DISBCURRENCY,SERVCURRENCY,BILLCURRENCY,DISBAMOUNT,DISBHOMEAMOUNT,DISBBILLAMOUNT,SERVAMOUNT,SERVHOMEAMOUNT,SERVBILLAMOUNT,DISBDISCORIGINAL,DISBHOMEDISCOUNT,DISBBILLDISCOUNT,SERVDISCORIGINAL,SERVHOMEDISCOUNT,SERVBILLDISCOUNT,TOTHOMEDISCOUNT,TOTBILLDISCOUNT,DISBMARGIN,DISBHOMEMARGIN,DISBBILLMARGIN,SERVMARGIN,SERVHOMEMARGIN,SERVBILLMARGIN,DISBTAXAMT,DISBTAXHOMEAMT,DISBTAXBILLAMT,SERVTAXAMT,SERVTAXHOMEAMT,SERVTAXBILLAMT,DISBTAXCODE,SERVTAXCODE,SOURCECOUNTRY,DISBWIPCODE,SERVWIPCODE,DISBSOURCEAMT,SERVSOURCEAMT)
	select distinct T.CASEID,T.IRN,T.YEARNO,T1.CYCLE,T.RENEWALDATE,T1.FROMDATE,T1.STEPDATEFLAG,T1.ISEXPIREDSTEP,T.CHARGETYPENO,T.RATENO,T.RATEDESC,T.CALCLABEL1,T.CALCLABEL2,T.FROMEVENTNO1,T.UNTILEVENTNO1,T.PERIODTYPE1,T.FROMEVENTNO2,T.UNTILEVENTNO2,T.PERIODTYPE2,T.EXTENSIONPERIOD,T.ESTIMATEFLAG,T.ESTIMATEDATE,T.DISBCURRENCY,T.SERVCURRENCY,T.BILLCURRENCY,T.DISBAMOUNT,T.DISBHOMEAMOUNT,T.DISBBILLAMOUNT,T.SERVAMOUNT,T.SERVHOMEAMOUNT,T.SERVBILLAMOUNT,T.DISBDISCORIGINAL,T.DISBHOMEDISCOUNT,T.DISBBILLDISCOUNT,T.SERVDISCORIGINAL,T.SERVHOMEDISCOUNT,T.SERVBILLDISCOUNT,T.TOTHOMEDISCOUNT,T.TOTBILLDISCOUNT,T.DISBMARGIN,T.DISBHOMEMARGIN,T.DISBBILLMARGIN,T.SERVMARGIN,T.SERVHOMEMARGIN,T.SERVBILLMARGIN,T.DISBTAXAMT,T.DISBTAXHOMEAMT,T.DISBTAXBILLAMT,T.SERVTAXAMT,T.SERVTAXHOMEAMT,T.SERVTAXBILLAMT,T.DISBTAXCODE,T.SERVTAXCODE,T.SOURCECOUNTRY,T.DISBWIPCODE,T.SERVWIPCODE,T.DISBSOURCEAMT,T.SERVSOURCEAMT
	from #TEMPCASECHARGES T
	join #TEMPCASECHARGES T1 	on ((T1.CASEID=T.CASEID OR (T1.CASEID is null and T.CASEID is null))
					and  T1.CHARGETYPENO=T.CHARGETYPENO	-- SQA18429
					and  isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')
					and  T1.RATENO<>T.RATENO)
	left join #TEMPCASECHARGES T2	on ((T2.CASEID=T.CASEID OR (T2.CASEID is null and T.CASEID is null))
					and  T2.CHARGETYPENO=T1.CHARGETYPENO	-- SQA18429
					and  T2.FROMDATE=T1.FROMDATE
					and  T2.RATENO=T.RATENO)
	Where T2.RATENO is null		-- the new row does not already exist
	and T.ESTIMATEFLAG=0		-- don't copy estimates
	and T.FROMDATE is null		-- copying from RATES that do not have a FROMDATE
	and T1.FROMDATE is not null	-- copying to be adjacent with RATES that do have a FROMDATE
	-- Copy the Rates from the lowest YearNo against this Case
	and isnull(T.YEARNO,'')
		= isnull((select min(T3.YEARNO)
			from #TEMPCASECHARGES T3
			where isnull(T3.CASEID,'')=isnull(T.CASEID,'')
			and T3.YEARNO is not null),'')
	-- Only copy rows if a billing amount has been calculated

	and(T.DISBBILLAMOUNT<>0 OR T.SERVBILLAMOUNT<>0)"


	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	-----------------------------------------------------------------------------------
	-- Step 3A: Now for each FROMDATE ensure there is a full complement of other RATENO
	--	    rows (if they have values).
	--	    This step will add Rates with the highest From Date earlier than the
	--	    From Date being added.
	-----------------------------------------------------------------------------------
	Set @sSQLString="
					
	Insert into #TEMPCASECHARGES(CASEID,IRN,YEARNO,CYCLE,RENEWALDATE,FROMDATE,STEPDATEFLAG,ISEXPIREDSTEP,CHARGETYPENO,RATENO,RATEDESC,CALCLABEL1,CALCLABEL2,FROMEVENTNO1,UNTILEVENTNO1,PERIODTYPE1,FROMEVENTNO2,UNTILEVENTNO2,PERIODTYPE2,EXTENSIONPERIOD,ESTIMATEFLAG,ESTIMATEDATE,DISBCURRENCY,SERVCURRENCY,BILLCURRENCY,DISBAMOUNT,DISBHOMEAMOUNT,DISBBILLAMOUNT,SERVAMOUNT,SERVHOMEAMOUNT,SERVBILLAMOUNT,DISBDISCORIGINAL,DISBHOMEDISCOUNT,DISBBILLDISCOUNT,SERVDISCORIGINAL,SERVHOMEDISCOUNT,SERVBILLDISCOUNT,TOTHOMEDISCOUNT,TOTBILLDISCOUNT,DISBMARGIN,DISBHOMEMARGIN,DISBBILLMARGIN,SERVMARGIN,SERVHOMEMARGIN,SERVBILLMARGIN,DISBTAXAMT,DISBTAXHOMEAMT,DISBTAXBILLAMT,SERVTAXAMT,SERVTAXHOMEAMT,SERVTAXBILLAMT,DISBSTATETAXAMT,DISBSTATETAXHOMEAMT,DISBSTATETAXBILLAMT,SERVSTATETAXAMT,SERVSTATETAXHOMEAMT,SERVSTATETAXBILLAMT,DISBTAXCODE,SERVTAXCODE,DISBSTATETAXCODE,SERVSTATETAXCODE,SOURCECOUNTRY,SOURCESTATE,DISBWIPCODE,SERVWIPCODE,DISBSOURCEAMT,SERVSOURCEAMT)
	select distinct T.CASEID,T.IRN,T.YEARNO,T.CYCLE,T.RENEWALDATE,T.FROMDATE,T.STEPDATEFLAG,T.ISEXPIREDSTEP,T.CHARGETYPENO,T1.RATENO,T1.RATEDESC,T1.CALCLABEL1,T1.CALCLABEL2,T1.FROMEVENTNO1,T1.UNTILEVENTNO1,T1.PERIODTYPE1,T1.FROMEVENTNO2,T1.UNTILEVENTNO2,T1.PERIODTYPE2,T1.EXTENSIONPERIOD,T1.ESTIMATEFLAG,T1.ESTIMATEDATE,T1.DISBCURRENCY,T1.SERVCURRENCY,T1.BILLCURRENCY,T1.DISBAMOUNT,T1.DISBHOMEAMOUNT,T1.DISBBILLAMOUNT,T1.SERVAMOUNT,T1.SERVHOMEAMOUNT,T1.SERVBILLAMOUNT,T1.DISBDISCORIGINAL,T1.DISBHOMEDISCOUNT,T1.DISBBILLDISCOUNT,T1.SERVDISCORIGINAL,T1.SERVHOMEDISCOUNT,T1.SERVBILLDISCOUNT,T1.TOTHOMEDISCOUNT,T1.TOTBILLDISCOUNT,T1.DISBMARGIN,T1.DISBHOMEMARGIN,T1.DISBBILLMARGIN,T1.SERVMARGIN,T1.SERVHOMEMARGIN,T1.SERVBILLMARGIN,T1.DISBTAXAMT,T1.DISBTAXHOMEAMT,T1.DISBTAXBILLAMT,T1.SERVTAXAMT,T1.SERVTAXHOMEAMT,T1.SERVTAXBILLAMT,T1.DISBSTATETAXAMT,T1.DISBSTATETAXHOMEAMT,T1.DISBSTATETAXBILLAMT,T1.SERVSTATETAXAMT,T1.SERVSTATETAXHOMEAMT,T1.SERVSTATETAXBILLAMT,T1.DISBTAXCODE,T1.SERVTAXCODE,T1.DISBSTATETAXCODE,T1.SERVSTATETAXCODE,T1.SOURCECOUNTRY,T1.SOURCESTATE,T1.DISBWIPCODE,T1.SERVWIPCODE,T1.DISBSOURCEAMT,T1.SERVSOURCEAMT
	from #TEMPCASECHARGES T
	join #TEMPCASECHARGES T1 	on (isnull(T1.CASEID,'')=isnull(T.CASEID,'')
					and T1.CHARGETYPENO=T.CHARGETYPENO	-- SQA18429
					and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')
					and T1.RATENO<>T.RATENO
					and T1.FROMDATE=( select max(T1A.FROMDATE)
							  from #TEMPCASECHARGES T1A
							  where isnull(T1A.CASEID,'')=isnull(T1.CASEID,'')
							  and   T1A.CHARGETYPENO=T1.CHARGETYPENO	-- SQA18429
							  and   isnull(T1A.YEARNO,'')=isnull(T1.YEARNO,'')
							  and   T1A.ESTIMATEFLAG=0
							  and   T1A.RATENO=T1.RATENO
							  and   T1A.FROMDATE<T.FROMDATE))
	left join #TEMPCASECHARGES T2	on (isnull(T2.CASEID,'')=isnull(T.CASEID,'')
					and T2.CHARGETYPENO=T1.CHARGETYPENO	-- SQA18429
					and T2.FROMDATE=T.FROMDATE
					and T2.RATENO=T1.RATENO)
	Where T2.RATENO is null		-- the new row does not already exist
	and T1.ESTIMATEFLAG=0		-- don't copy estimates
	-- Copy the Rates from the lowest YearNo against this Case
	and isnull(T.YEARNO,'')
		= isnull((select min(T3.YEARNO)
			from #TEMPCASECHARGES T3
			where isnull(T3.CASEID,'')=isnull(T.CASEID,'')
			and T3.YEARNO is not null),'')
	-- Only copy rows if a billing amount has been calculated

	and(T1.DISBBILLAMOUNT<>0 OR T1.SERVBILLAMOUNT<>0)"


	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	-----------------------------------------------------------------------------------
	-- Step 3B: Now for each FROMDATE ensure there is a full complement of other RATENO
	--	    rows (if they have values).
	--	    This step will add Rates with the lowest From Date after the From Date 
	--	    being added. This row is only added if no lower From Date row existed.
	-----------------------------------------------------------------------------------
	Set @sSQLString="
	Insert into #TEMPCASECHARGES(CASEID,IRN,YEARNO,CYCLE,RENEWALDATE,FROMDATE,STEPDATEFLAG,ISEXPIREDSTEP,CHARGETYPENO,RATENO,RATEDESC,CALCLABEL1,CALCLABEL2,FROMEVENTNO1,UNTILEVENTNO1,PERIODTYPE1,FROMEVENTNO2,UNTILEVENTNO2,PERIODTYPE2,EXTENSIONPERIOD,ESTIMATEFLAG,ESTIMATEDATE,DISBCURRENCY,SERVCURRENCY,BILLCURRENCY,DISBAMOUNT,DISBHOMEAMOUNT,DISBBILLAMOUNT,SERVAMOUNT,SERVHOMEAMOUNT,SERVBILLAMOUNT,DISBDISCORIGINAL,DISBHOMEDISCOUNT,DISBBILLDISCOUNT,SERVDISCORIGINAL,SERVHOMEDISCOUNT,SERVBILLDISCOUNT,TOTHOMEDISCOUNT,TOTBILLDISCOUNT,DISBMARGIN,DISBHOMEMARGIN,DISBBILLMARGIN,SERVMARGIN,SERVHOMEMARGIN,SERVBILLMARGIN,DISBTAXAMT,DISBTAXHOMEAMT,DISBTAXBILLAMT,SERVTAXAMT,SERVTAXHOMEAMT,SERVTAXBILLAMT,DISBSTATETAXAMT,DISBSTATETAXHOMEAMT,DISBSTATETAXBILLAMT,SERVSTATETAXAMT,SERVSTATETAXHOMEAMT,SERVSTATETAXBILLAMT,DISBTAXCODE,SERVTAXCODE,DISBSTATETAXCODE,SERVSTATETAXCODE,SOURCECOUNTRY,SOURCESTATE,DISBWIPCODE,SERVWIPCODE,DISBSOURCEAMT,SERVSOURCEAMT)
	select distinct T.CASEID,T.IRN,T.YEARNO,T.CYCLE,T.RENEWALDATE,T.FROMDATE,T.STEPDATEFLAG,T.ISEXPIREDSTEP,T.CHARGETYPENO,T1.RATENO,T1.RATEDESC,T1.CALCLABEL1,T1.CALCLABEL2,T1.FROMEVENTNO1,T1.UNTILEVENTNO1,T1.PERIODTYPE1,T1.FROMEVENTNO2,T1.UNTILEVENTNO2,T1.PERIODTYPE2,T1.EXTENSIONPERIOD,T1.ESTIMATEFLAG,T1.ESTIMATEDATE,T1.DISBCURRENCY,T1.SERVCURRENCY,T1.BILLCURRENCY,T1.DISBAMOUNT,T1.DISBHOMEAMOUNT,T1.DISBBILLAMOUNT,T1.SERVAMOUNT,T1.SERVHOMEAMOUNT,T1.SERVBILLAMOUNT,T1.DISBDISCORIGINAL,T1.DISBHOMEDISCOUNT,T1.DISBBILLDISCOUNT,T1.SERVDISCORIGINAL,T1.SERVHOMEDISCOUNT,T1.SERVBILLDISCOUNT,T1.TOTHOMEDISCOUNT,T1.TOTBILLDISCOUNT,T1.DISBMARGIN,T1.DISBHOMEMARGIN,T1.DISBBILLMARGIN,T1.SERVMARGIN,T1.SERVHOMEMARGIN,T1.SERVBILLMARGIN,T1.DISBTAXAMT,T1.DISBTAXHOMEAMT,T1.DISBTAXBILLAMT,T1.SERVTAXAMT,T1.SERVTAXHOMEAMT,T1.SERVTAXBILLAMT,T1.DISBSTATETAXAMT,T1.DISBSTATETAXHOMEAMT,T1.DISBSTATETAXBILLAMT,T1.SERVSTATETAXAMT,T1.SERVSTATETAXHOMEAMT,T1.SERVSTATETAXBILLAMT,T1.DISBTAXCODE,T1.SERVTAXCODE,T1.DISBSTATETAXCODE,T1.SERVSTATETAXCODE,T1.SOURCECOUNTRY,T1.SOURCESTATE,T1.DISBWIPCODE,T1.SERVWIPCODE,T1.DISBSOURCEAMT,T1.SERVSOURCEAMT
	from #TEMPCASECHARGES T
	join #TEMPCASECHARGES T1 	on (isnull(T1.CASEID,'')=isnull(T.CASEID,'')
					and T1.CHARGETYPENO=T.CHARGETYPENO	-- SQA18429
					and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')
					and T1.RATENO<>T.RATENO
					and T1.FROMDATE=( select min(T1A.FROMDATE)
							  from #TEMPCASECHARGES T1A
							  where isnull(T1A.CASEID,'')=isnull(T1.CASEID,'')
							  and   isnull(T1A.YEARNO,'')=isnull(T1.YEARNO,'')
							  and   T1A.CHARGETYPENO=T1.CHARGETYPENO	-- SQA18429
							  and   T1A.ESTIMATEFLAG=0
							  and   T1A.RATENO=T1.RATENO
							  and   T1A.FROMDATE>T.FROMDATE))
	left join #TEMPCASECHARGES T2	on (isnull(T2.CASEID,'')=isnull(T.CASEID,'')
					and T2.CHARGETYPENO=T1.CHARGETYPENO	-- SQA18429
					and T2.FROMDATE=T.FROMDATE
					and T2.RATENO=T1.RATENO)
	Where T2.RATENO is null		-- the new row does not already exist
	and T1.ESTIMATEFLAG=0		-- don't copy estimates
	-- Copy the Rates from the lowest YearNo against this Case
	and isnull(T.YEARNO,'')
		= isnull((select min(T3.YEARNO)
			from #TEMPCASECHARGES T3
			where isnull(T3.CASEID,'')=isnull(T.CASEID,'')
			and T3.YEARNO is not null),'')
	-- Only copy rows if a billing amount has been calculated

	and(T1.DISBBILLAMOUNT<>0 OR T1.SERVBILLAMOUNT<>0)"


	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	-------------------------------------------------------------------------
	-- Step 4: Remove any rows with no FROMDATE where there is a matching row
	--	   with a FROMDATE or no billing value was calculated.
	-------------------------------------------------------------------------
	Set @sSQLString="
	Delete #TEMPCASECHARGES
	from #TEMPCASECHARGES T
	Where (isnull(T.DISBBILLAMOUNT,0)=0 and isnull(T.SERVBILLAMOUNT,0)=0 and T.NOCALCFLAG=0)
	OR (T.FROMDATE is null and isnull(T.ESTIMATEFLAG,0)=0
	    and exists
	   (select 1 from #TEMPCASECHARGES T1
	    where(T1.CASEID=T.CASEID OR (T1.CASEID is null and T.CASEID is null))
	    and   isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')
	    and   T1.CHARGETYPENO=T.CHARGETYPENO
	    and   T1.RATENO=T.RATENO
	    and   T1.FROMDATE is not null))"

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	-- Step 5: Set the FROMDATE to match the RENEWALDATE

	Set @sSQLString="
	Update #TEMPCASECHARGES
	Set FROMDATE=RENEWALDATE
	Where FROMDATE  is null
	and RENEWALDATE is not null"

	exec @ErrorCode=sp_executesql @sSQLString
End


If @ErrorCode=0
Begin
	---------------------------------------------------------------
	-- Step 6: Delete all of the rows with a particular FROMDATE,
	--         if the immediately earlier FROMDATE has an identical
	--	   set of values.
	---------------------------------------------------------------

	Set @sSQLString="
	Delete #TEMPCASECHARGES
	From #TEMPCASECHARGES T
	join (	select CASEID,FROMDATE,YEARNO,CYCLE,CHARGETYPENO,sum(isnull(DISBBILLAMOUNT,0)) as DISBBILLAMOUNT,sum(isnull(SERVBILLAMOUNT,0)) as SERVBILLAMOUNT,sum(isnull(DISBBILLMARGIN,0)) as DISBBILLMARGIN,sum(isnull(SERVBILLMARGIN,0)) as SERVBILLMARGIN,sum(isnull(DISBTAXBILLAMT,0)) as DISBTAXBILLAMT,sum(isnull(SERVTAXBILLAMT,0)) as SERVTAXBILLAMT
		from #TEMPCASECHARGES
		where ESTIMATEFLAG=0
		group by CASEID,FROMDATE,YEARNO,CYCLE,CHARGETYPENO) T1
				on (isnull(T1.CASEID,'')=isnull(T.CASEID,'')
				and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')
				and isnull(T1.CYCLE,'') =isnull(T.CYCLE, '')
				and T1.CHARGETYPENO=T.CHARGETYPENO
				and T1.FROMDATE=T.FROMDATE)
	join (	select CASEID,FROMDATE,YEARNO,CYCLE,CHARGETYPENO,sum(isnull(DISBBILLAMOUNT,0)) as DISBBILLAMOUNT,sum(isnull(SERVBILLAMOUNT,0)) as SERVBILLAMOUNT,sum(isnull(DISBBILLMARGIN,0)) as DISBBILLMARGIN,sum(isnull(SERVBILLMARGIN,0)) as SERVBILLMARGIN,sum(isnull(DISBTAXBILLAMT,0)) as DISBTAXBILLAMT,sum(isnull(SERVTAXBILLAMT,0)) as SERVTAXBILLAMT
		from #TEMPCASECHARGES
		where ESTIMATEFLAG=0
		group by CASEID,FROMDATE,YEARNO,CYCLE,CHARGETYPENO) T2
				on (isnull(T2.CASEID,'')=isnull(T.CASEID,'')
				and isnull(T2.YEARNO,'')=isnull(T.YEARNO,'')
				and isnull(T2.CYCLE,'') =isnull(T.CYCLE, '')
				and T2.CHARGETYPENO=T.CHARGETYPENO
				and T2.FROMDATE=(select max(T3.FROMDATE)
						 from #TEMPCASECHARGES T3
						 where isnull(T3.CASEID,'')=isnull(T.CASEID,'')
						 and   isnull(T3.YEARNO,'')=isnull(T.YEARNO,'')
						 and   isnull(T3.CYCLE,'') =isnull(T.CYCLE, '')
						 and   T3.CHARGETYPENO=T.CHARGETYPENO
						 and   T3.FROMDATE<T.FROMDATE))
	Where T1.DISBBILLAMOUNT=T2.DISBBILLAMOUNT
	and   T1.SERVBILLAMOUNT=T2.SERVBILLAMOUNT
	and   T1.DISBBILLMARGIN=T2.DISBBILLMARGIN
	and   T1.SERVBILLMARGIN=T2.SERVBILLMARGIN
	and   T1.DISBTAXBILLAMT=T2.DISBTAXBILLAMT
	and   T1.SERVTAXBILLAMT=T2.SERVTAXBILLAMT
	and   T.STEPDATEFLAG=1
	and   isnull(T.ESTIMATEFLAG,0)=0"

	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	------------------------------------------------------------
	-- Step 7: Remove any calculations that are earlier than
	--         todays date but are not the very earliest date
	--	   of calculations. 
	--	   Note: A similar delete occurred before the 
	--		 calculations were made however all of
	--		 the calculations have now been consolidated
	--		 as at the earliest date. 
	------------------------------------------------------------
	Set @sSQLString="
	Delete #TEMPCASECHARGES
	From #TEMPCASECHARGES T
	-- Get the earliest FROMDATE as we will need to keep calculations as at that date
	join (	select CASEID,YEARNO,CYCLE,CHARGETYPENO, min(FROMDATE) as FROMDATE
		from #TEMPCASECHARGES
		where ESTIMATEFLAG=0
		and FROMDATE is not null
		group by CASEID,YEARNO,CYCLE,CHARGETYPENO) T1
				on (isnull(T1.CASEID,'')=isnull(T.CASEID,'')
				and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')
				and isnull(T1.CYCLE,'') =isnull(T.CYCLE, '')
				and T1.CHARGETYPENO=T.CHARGETYPENO
				and T1.FROMDATE<T.FROMDATE)
	join (	select CASEID,YEARNO,CYCLE,CHARGETYPENO,RATENO, max(FROMDATE) as FROMDATE
		from #TEMPCASECHARGES
		where ESTIMATEFLAG=0
		and FROMDATE<=convert(varchar,getdate(),112)
		group by CASEID,YEARNO,CYCLE,CHARGETYPENO,RATENO) T2
				on (isnull(T2.CASEID,'')=isnull(T.CASEID,'')
				and isnull(T2.YEARNO,'')=isnull(T.YEARNO,'')
				and isnull(T2.CYCLE,'') =isnull(T.CYCLE, '')
				and T2.CHARGETYPENO=T.CHARGETYPENO
				and T2.RATENO      =T.RATENO
				and T2.FROMDATE    >T.FROMDATE)
	where isnull(T.ESTIMATEFLAG,0)=0"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	---------------------------------------------------------
	-- Step 8: Set the FROMDATE to the current system date
	--         for the set of calculations that apply as at
	--	   todays date. They may be showing an earlier 
	--	   date to indicate when the calculation changed.
	---------------------------------------------------------

	Set @sSQLString="
	Update #TEMPCASECHARGES
	Set FROMDATE=convert(varchar,getdate(),112)
	From #TEMPCASECHARGES T
	join (	select CASEID,YEARNO,CYCLE,CHARGETYPENO,RATENO, max(FROMDATE) as FROMDATE
		from #TEMPCASECHARGES
		where ESTIMATEFLAG=0
		and FROMDATE<=convert(varchar,getdate(),112)
		group by CASEID,YEARNO,CYCLE,CHARGETYPENO,RATENO) T2
				on (isnull(T2.CASEID,'')=isnull(T.CASEID,'')
				and isnull(T2.YEARNO,'')=isnull(T.YEARNO,'')
				and isnull(T2.CYCLE,'') =isnull(T.CYCLE, '')
				and T2.CHARGETYPENO=T.CHARGETYPENO
				and T2.RATENO      =T.RATENO
				and T2.FROMDATE    =T.FROMDATE)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	---------------------------------------------------------
	-- Step 9: Set a contiguous sequence no on the temporary
	--         table.  This is required to help generate a
	--	   unique row id.
	---------------------------------------------------------
	Set @nSequenceNo=0
	
	Set @sSQLString="
	Update #TEMPCASECHARGES
	Set @nSequenceNo=@nSequenceNo+1,
	SEQUENCENO=@nSequenceNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nSequenceNo		int	OUTPUT',
				  @nSequenceNo=@nSequenceNo	OUTPUT
End

---------------------------------------------------------------------------------
-- Now that the data has been extracted return each row that actually has values.
-- Various formats will be used for the output depending on how the procedure
-- has been called.
---------------------------------------------------------------------------------

------------------------
-- Client/server version
-- RateNo as parameter
------------------------
If  @ErrorCode=0
and @pnChargeTypeNo is null
and @pnRateNo is not null
and @pbCalledFromCentura = 1
Begin 
	set @sSQLString="
	select	distinct
		C.CASEID,
		N.NAME+CASE WHEN(N.FIRSTNAME is not null) THEN ', '+N.FIRSTNAME END as Instructor,
		CT.CASETYPEDESC,
		VP.PROPERTYNAME,
		CY.COUNTRY,
		C.IRN,
		C.TITLE,
		T.YEARNO,
		T.ESTIMATEFLAG,
		T.ESTIMATEDATE,
		T.DISBCURRENCY,
		T.SERVCURRENCY,
		T.BILLCURRENCY,
		T.DISBAMOUNT,
		T.DISBHOMEAMOUNT,
		T.DISBBILLAMOUNT,
		T.SERVAMOUNT,
		T.SERVHOMEAMOUNT,
		T.SERVBILLAMOUNT,
		T.DISBDISCORIGINAL,
		T.DISBHOMEDISCOUNT,
		T.DISBBILLDISCOUNT,
		T.SERVDISCORIGINAL,
		T.SERVHOMEDISCOUNT,
		T.SERVBILLDISCOUNT,
		ISNULL(T.DISBTAXAMT, 0) + ISNULL(T.DISBSTATETAXAMT, 0),
		ISNULL(T.DISBTAXHOMEAMT, 0) + ISNULL(T.DISBSTATETAXHOMEAMT, 0),
		ISNULL(T.DISBTAXBILLAMT, 0) + ISNULL(T.DISBSTATETAXBILLAMT, 0),
		ISNULL(T.SERVTAXAMT, 0) + ISNULL(T.SERVSTATETAXAMT, 0),
		ISNULL(T.SERVTAXHOMEAMT, 0) + ISNULL(T.SERVSTATETAXHOMEAMT, 0),
		ISNULL(T.SERVTAXBILLAMT, 0) + ISNULL(T.SERVSTATETAXBILLAMT, 0),
		isnull(T1.DISBHOMEAMOUNT,0)+isnull(T1.SERVHOMEAMOUNT,0)-isnull(T1.DISBHOMEDISCOUNT,0)-isnull(T1.SERVHOMEDISCOUNT,0)+isnull(T1.DISBTAXHOMEAMT,0)+isnull(T1.SERVTAXHOMEAMT,0)+isnull(T1.DISBSTATETAXHOMEAMT,0)+isnull(T1.SERVSTATETAXHOMEAMT,0) as TOTALHOMEESTIMATE,
		isnull(T1.DISBBILLAMOUNT,0)+isnull(T1.SERVBILLAMOUNT,0)-isnull(T1.DISBBILLDISCOUNT,0)-isnull(T1.SERVBILLDISCOUNT,0)+isnull(T1.DISBTAXBILLAMT,0)+isnull(T1.SERVTAXBILLAMT,0)+isnull(T1.DISBSTATETAXBILLAMT,0)+isnull(T1.SERVSTATETAXBILLAMT,0) as TOTALBILLESTIMATE
	from #TEMPCASECHARGES T
	Left Join CASES C 		on (C.CASEID=T.CASEID)
	Left Join CASETYPE CT		on (CT.CASETYPE=isnull(C.CASETYPE,@psCaseType))
	Left Join COUNTRY CY		on (CY.COUNTRYCODE=isnull(C.COUNTRYCODE,@psCountryCode))
	Left Join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=isnull(C.PROPERTYTYPE,@psPropertyType)
					and VP.COUNTRYCODE =(	select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.COUNTRYCODE in ('ZZZ',isnull(C.COUNTRYCODE,@psCountryCode))
								and   VP1.PROPERTYTYPE=VP.PROPERTYTYPE))
	Left Join CASENAME CN		on (CN.CASEID=T.CASEID
					and CN.NAMETYPE='I'
					and CN.EXPIRYDATE is null)
	Left Join NAME N		on (N.NAMENO=CN.NAMENO)
	-- get matching estimate if it exists
	left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID
					and(T1.YEARNO=T.YEARNO OR (T1.YEARNO is null and T.YEARNO is null))
					and T1.RATENO=T.RATENO
					and T1.ESTIMATEFLAG=1)
	left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID
					and(T2.YEARNO=T.YEARNO OR (T2.YEARNO is null and T.YEARNO is null))
					and T2.RATENO=T.RATENO
					and T2.ESTIMATEFLAG=0)
	-- If the main TEMPCASECHARGES (T) row is an estimate then there
	-- should not be a non estimate version (T2)
	Where T.ESTIMATEFLAG=0
	  OR (T.ESTIMATEFLAG=1 and T2.CASEID is null)
	order by VP.PROPERTYNAME, CY.COUNTRY, 2,C.IRN, T.ESTIMATEFLAG, T.YEARNO"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psCaseType		nchar(1),
					  @psPropertyType	nchar(1),
					  @psCountryCode	nvarchar(3)',
					  @psCaseType	 =@psCaseType,
					  @psPropertyType=@psPropertyType,
					  @psCountryCode =@psCountryCode
	set @pnRowCount=@@Rowcount
End
------------------------------------------
-- csw_ListCase version
-- Calculated values are to be loaded into
-- a global temporary table for inclusion
-- into a Case query.
------------------------------------------
Else If @ErrorCode=0
and @pbDyamicChargeType=1
Begin
	-- String together the column to be inserted for the 
	-- extended Case details
	select @sColumnList=ISNULL(NULLIF(@sColumnList + ',', ','),'') + COLUMNNAME
	from @tblExtendedColumns

	Set @ErrorCode=@@Error

	-- Save the highest ROWNUMBER in the global temporary table
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Select @nMaxRowNumber=max(ROWNUMBER)
		from "+@psGlobalTempTable

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nMaxRowNumber	int	OUTPUT',
					  @nMaxRowNumber=@nMaxRowNumber	OUTPUT
	End

	-- Insert rows into CASECHARGESCACHE. This will then
	-- be available for reporting these fees if the same
	-- charge and Case information is required within a 
	-- a firm define time period.

	If @ErrorCode=0
	Begin
		Set @dtNow=getdate()
		Set @sSQLString="
			insert into CASECHARGESCACHE(CASEID,CHARGETYPENO,YEARNO,FROMDATE,BILLCURRENCY,TOTALYEARVALUE,TOTALVALUE,WHENCALCULATED)
			select distinct T.CASEID,T.CHARGETYPENO,Y.YEARNO,Y.FROMDATE,  Y.BILLCURRENCY,Y.TotalYearValue,TOT.TotalValue,@dtNow
			from "+@psGlobalTempTable+" T
			join (	select T1.CASEID,T1.CHARGETYPENO,T1.YEARNO,T1.FROMDATE,T1.BILLCURRENCY,
				sum(isnull(T1.DISBBILLAMOUNT,0)-isnull(T1.DISBBILLDISCOUNT,0)
				   +isnull(T1.SERVBILLAMOUNT,0)-isnull(T1.SERVBILLDISCOUNT,0)
				   +isnull(T1.DISBTAXBILLAMT,0)+isnull(T1.SERVTAXBILLAMT,0)) as TotalYearValue
				from #TEMPCASECHARGES T1
				where T1.STEPDATEFLAG=0
				and T1.ISEXPIREDSTEP=0
				and T1.NOCALCFLAG=0
				and T1.FROMDATE=(select min(T2.FROMDATE)
						 from #TEMPCASECHARGES T2
						 where T2.CASEID=T1.CASEID
						 and T2.CHARGETYPENO=T1.CHARGETYPENO
						 and (T2.YEARNO=T1.YEARNO OR (T2.YEARNO is null and T1.YEARNO is NULL))
						 and T2.FROMDATE>=convert(varchar,getdate(),112))
				group by T1.CASEID,T1.CHARGETYPENO,T1.YEARNO,T1.FROMDATE,T1.BILLCURRENCY) Y
						on (Y.CASEID=T.CASEID
						and Y.CHARGETYPENO=T.CHARGETYPENO)
			join (	select T1.CASEID,T1.CHARGETYPENO,
				sum(isnull(T1.DISBBILLAMOUNT,0)-isnull(T1.DISBBILLDISCOUNT,0)
				   +isnull(T1.SERVBILLAMOUNT,0)-isnull(T1.SERVBILLDISCOUNT,0)
				   +isnull(T1.DISBTAXBILLAMT,0)+isnull(T1.SERVTAXBILLAMT,0)) as TotalValue
				from #TEMPCASECHARGES T1
				where T1.STEPDATEFLAG=0
				and T1.ISEXPIREDSTEP=0
				and T1.NOCALCFLAG=0
				and T1.FROMDATE=(select min(T2.FROMDATE)
						 from #TEMPCASECHARGES T2
						 where T2.CASEID=T1.CASEID
						 and T2.CHARGETYPENO=T1.CHARGETYPENO
						 and (T2.YEARNO=T1.YEARNO OR (T2.YEARNO is null and T1.YEARNO is NULL))
						 and T2.FROMDATE>=convert(varchar,getdate(),112))
				group by T1.CASEID,T1.CHARGETYPENO) TOT
						on (TOT.CASEID=T.CASEID
						and TOT.CHARGETYPENO=T.CHARGETYPENO)"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@dtNow	datetime',
						  @dtNow=@dtNow

		Set @nInsertedRows=@@rowcount
	End
	
	If @bBackgroundTask=1
	and @ErrorCode=0
	Begin
		---------------------------------------------
		-- Insert a CASECHARGESCACHE rows for Cases
		-- and ChargeType that were requested to be 
		-- calculated in background but did not return
		-- any data.
		---------------------------------------------
		Set @sSQLString="
		insert into CASECHARGESCACHE(CASEID,CHARGETYPENO,FROMDATE,WHENCALCULATED)
		select distinct T.CASEID,T.CHARGETYPENO,@pdtFromDate,@dtNow
		from "+@psGlobalTempTable+" T
		left join CASECHARGESCACHE C	on (C.CASEID=T.CASEID
						and C.CHARGETYPENO=T.CHARGETYPENO
						and C.WHENCALCULATED=@dtNow)
		where C.CASEID is null"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@dtNow	datetime,
						  @pdtFromDate	datetime',
						  @dtNow=@dtNow,
						  @pdtFromDate=@pdtFromDate

		If @ErrorCode=0
		Begin
			--------------------------------------
			-- Delete the rows in CASECHARGESCACHE
			-- used in this background request.
			--------------------------------------
			Set @sSQLString="
			Delete CASECHARGESCACHE
			where WHENCALCULATED=@pdtWhenRequested
			and SPIDREQUEST     =@pnSPID"
			
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@pdtWhenRequested	datetime,
							  @pnSPID		int',
							  @pdtWhenRequested=@pdtWhenRequested,
							  @pnSPID          =@pnSPID
		End
		
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update QUERY
			set QUERYNAME=replace(QUERYNAME,'** Calculation Running **','Budget Forecast'),
			    @sQuery  =replace(QUERYNAME,'** Calculation Running **','Budget Forecast'),
				ISREADONLY = 0
			Where QUERYID=@pnQueryId"
			
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@sQuery		nvarchar(50)	OUTPUT,
							  @pnQueryId		int',
							  @sQuery=@sQuery			OUTPUT,
							  @pnQueryId=@pnQueryId
		End
		
		-------------------------------------------------
		-- E M A I L   N O T I F I C A T I O N
		-- Generate an email to the user to indicate that
		-- the Fee Calculations have occurred and the
		-- query may now be viewed.
		-------------------------------------------------		
		If @psEmailAddress is not null
		and @ErrorCode=0
		Begin
			--------------------------------------
			-- Get the site control that indicates
			-- that SQLServer 2005 is in use
			-- and also the name of the DocItem 
			-- used to format the body of the
			-- generated email.
			--------------------------------------
			Set @sSQLString="
			Select  @sProfileName=S1.COLCHARACTER
			from SITECONTROL S1
			Where S1.CONTROLID='Database Email Profile'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sProfileName		nvarchar(254)		Output',
						  @sProfileName		=@sProfileName		Output
						  
			---------------------------
			-- Format the Email Message
			---------------------------
			If @sQuery is not null
				Set @sSubject='"'+@sQuery+'" now available for review.'
			Else
				Set @sSubject='Budget Forecast now available for review.'

			-------------------------------
			-- Get the body of the email by 
			-- executing the docitem that
			-- found from the SiteControl
			-------------------------------
			If @ErrorCode=0
			Begin
				-- Get Doc Item 1
				Set @sSQLString="
				Select @sSQLDocItem=convert(nvarchar(4000),SQL_QUERY)
				From SITECONTROL S
				join ITEM I on (I.ITEM_NAME=S.COLCHARACTER
					    and I.ITEM_TYPE=0)
				Where S.CONTROLID='Email Fee Query Body'"

				exec @ErrorCode=sp_executesql @sSQLString,
						N'@sSQLDocItem		nvarchar(4000)		Output',
						  @sSQLDocItem		=@sSQLDocItem		Output
			End

			If  @ErrorCode=0
			and @sSQLDocItem is not null
			Begin
				Set @sSQLDocItem=replace(@sSQLDocItem,':gstrEntryPoint','@pnUserIdentityId')
			
				Set @sSQLString="
				Set @sBody=("+@sSQLDocItem+")"

				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@sBody		nvarchar(4000)	OUTPUT,
							  @pnUserIdentityId	int',
							  @sBody           =@sBody		OUTPUT,
							  @pnUserIdentityId=@pnUserIdentityId
			End

			If @sBody is null
				Set @sBody='The results of the Budget Forecast query are available to review for the next 24 hours after which they will need to be recalculated.'	

			-----------------------------------------------
			-- If the @sProfileName has been set then this
			-- indicates that the firm is running SQLServer 
			-- 2005 or higher and has elected to use 
			-- sp_send_dbmail
			-----------------------------------------------
			if @sProfileName is not null
			and @ErrorCode=0
			begin
				exec msdb.dbo.sp_send_dbmail
					@profile_name = @sProfileName,
					@recipients   = @psEmailAddress, 
					@subject      = @sSubject, 
					@body         = @sBody
			end

			Select @ErrorCode=@@error
		End
	End

	-- Now copy rows into the global temporary table from 
	-- CASECHARGESCACHE which holds the calculation.  There 
	-- may be multiple rows for each CASEID and CHARGETYPE
	-- if due date or year are to be returned.

	If  @ErrorCode=0
	and @nInsertedRows>0
	and @bBackgroundTask=0
	Begin
		Set @sSelectList='T.'+replace(@sColumnList,',',',T.')
		Set @sSelectList=     replace(@sSelectList,'T.FeeYearNoAny', 'C.YEARNO')
		Set @sSelectList=     replace(@sSelectList,'T.FeeDueDateAny','C.FROMDATE')
		Set @sSelectList=     replace(@sSelectList,'T.FeeBillCurrencyAny','C.BILLCURRENCY')
		Set @sSelectList=     replace(@sSelectList,'T.InstructionBillCurrencyAny','C.BILLCURRENCY')
		Set @sSelectList=     replace(@sSelectList,'T.FeeBilledPerYearAny','C.TOTALYEARVALUE')
		Set @sSelectList=     replace(@sSelectList,'T.InstructionFeeBilledAny','C.TOTALYEARVALUE')
		Set @sSelectList=     replace(@sSelectList,'T.FeeBilledAmountAny','C.TOTALVALUE')

		Set @sSQLString="
			insert into "+@psGlobalTempTable+"("+@sColumnList+")
			select distinct "+@sSelectList+"
			from "+@psGlobalTempTable+" T
			join CASECHARGESCACHE C on (C.CASEID=T.CASEID
						and C.CHARGETYPENO=T.CHARGETYPENO
						and C.WHENCALCULATED=@dtNow)"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@dtNow	datetime',
						  @dtNow=@dtNow

		-- Remove the pre-existing rows from the global temporary table.
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"Delete "+@psGlobalTempTable+char(10)+
			"from "+@psGlobalTempTable+" T"+char(10)+
			"where T.ROWNUMBER<=@nMaxRowNumber"+char(10)+
			"and exists"+char(10)+
			"(select 1 from "+@psGlobalTempTable+" T1"+char(10)+
			" where T1.ROWNUMBER>@nMaxRowNumber"+char(10)+
			" and T1.CASEID=T.CASEID"+char(10)+
			" and T1.CHARGETYPENO=T.CHARGETYPENO)"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nMaxRowNumber	int',
						  @nMaxRowNumber=@nMaxRowNumber
		End
	End
End

----------------------
-- WorkBenches version
----------------------
Else If @ErrorCode=0
and @pbCalledFromCentura = 0
Begin
	-- Retrieve Local Currency information
	If @ErrorCode=0
	Begin
		exec @ErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
								@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
								@pnUserIdentityId 	= @pnUserIdentityId,
								@pbCalledFromCentura	= @pbCalledFromCentura
	End

	-- A. Home Currency
	-- Only returned for internal users.  
	-- Should be empty if the same as billing currency, or the user does not have
	-- access to Fees and Charges Elements subject.

	If @bIsExternalUser=0
	Begin
		-- A1. Return the total of all years and calculations
		set @sSQLString="
		select	cast(T.CASEID as nvarchar)
					as RowKey,
			T.CASEID	as CaseKey,
			@sLocalCurrencyCode
					as CurrencyCode,
			-- Using home  currency, need to include
			-- both service and disbursements values
			-- less corresponding discounts
			-- plus corresponding tax
			sum(	isnull(T.DISBHOMEAMOUNT,0)-isnull(T.DISBHOMEDISCOUNT,0)
				+isnull(T.SERVHOMEAMOUNT,0)-isnull(T.SERVHOMEDISCOUNT,0)
				+isnull(T.DISBTAXHOMEAMT,0)+isnull(T.SERVTAXHOMEAMT,0)
				+isnull(T.DISBSTATETAXHOMEAMT,0)+isnull(T.SERVSTATETAXHOMEAMT,0))
					as TotalValue,"+char(10)+
			-- TaxValue and BeforeTaxValue are null if tax is not in use
			case when @bTaxRequired=1
				then "	sum(isnull(T.DISBTAXHOMEAMT,0)+isnull(T.SERVTAXHOMEAMT,0)+isnull(T.DISBSTATETAXHOMEAMT,0)+isnull(T.SERVSTATETAXHOMEAMT,0)) as TaxValue,"+char(10)+
				     "	sum(isnull(T.DISBHOMEAMOUNT,0)-isnull(T.DISBHOMEDISCOUNT,0)+isnull(T.SERVHOMEAMOUNT,0)-isnull(T.SERVHOMEDISCOUNT,0)) as BeforeTaxValue,"
				else "	null as TaxValue,"+char(10)+
				     "	null as BeforeTaxValue,"
				end+char(10)+
			case when @bCanViewEstimates=0
				then "null	as EstimateValue"
				else "sum(isnull(T1.DISBHOMEAMOUNT,0)+isnull(T1.SERVHOMEAMOUNT,0)-isnull(T1.DISBHOMEDISCOUNT,0)-isnull(T1.SERVHOMEDISCOUNT,0)+isnull(T1.DISBTAXHOMEAMT,0)+isnull(T1.SERVTAXHOMEAMT,0)+isnull(T1.DISBSTATETAXHOMEAMT,0)+isnull(T1.SERVSTATETAXHOMEAMT,0))
					as EstimateValue"
				end+"
		from #TEMPCASECHARGES T
		-- get matching estimate if it exists
		left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID
						and(T1.YEARNO=T.YEARNO OR (T1.YEARNO is null and T.YEARNO is null))
						and T1.RATENO=T.RATENO
						and T1.ESTIMATEFLAG=1)
		left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID
						and(T2.YEARNO=T.YEARNO     OR (T2.YEARNO   is null and T.YEARNO   is null))
						--and(T2.FROMDATE=T.FROMDATE OR (T2.FROMDATE is null and T.FROMDATE is null))
						and T2.RATENO=T.RATENO
						and T.ESTIMATEFLAG=1
						and T2.ESTIMATEFLAG=0)
		-- If the main TEMPCASECHARGES (T) row is an estimate then there
		-- should not be a non estimate version (T2)
		Where(T.ESTIMATEFLAG=0
		  OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))
		-- Exclude any stepped calculations from the total
		and T.STEPDATEFLAG=0
		and @sLocalCurrencyCode<>T.BILLCURRENCY
		and @bCanViewElements=1
		group by T.CASEID"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sLocalCurrencyCode	nvarchar(3),
						  @nLocalDecimalPlaces	tinyint,
						  @bCanViewElements	bit',
						  @sLocalCurrencyCode	=@sLocalCurrencyCode,
						  @nLocalDecimalPlaces	=@nLocalDecimalPlaces,
						  @bCanViewElements	=@bCanViewElements
	
		-- A2. Return the totals by year and stepped calculation date
		If @ErrorCode=0
		Begin
			set @sSQLString="
			select	cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+
				convert(nvarchar(10),T.FROMDATE,112)
						as RowKey,
				T.CASEID	as CaseKey,
				T.YEARNO	as YearNo,
				T.FROMDATE	as [Date],
				isnull(T.ISEXPIREDSTEP,0) as IsPastDue,
				@sLocalCurrencyCode
						as CurrencyCode,
				-- Using billing currency, need to include
				-- both service and disbursements values
				-- less corresponding discounts
				-- plus corresponding tax
				sum(	isnull(T.DISBHOMEAMOUNT,0)-isnull(T.DISBHOMEDISCOUNT,0)
					+isnull(T.SERVHOMEAMOUNT,0)-isnull(T.SERVHOMEDISCOUNT,0)
					+isnull(T.DISBTAXHOMEAMT,0)+isnull(T.SERVTAXHOMEAMT,0)
					+isnull(T.DISBSTATETAXHOMEAMT,0)+isnull(T.SERVSTATETAXHOMEAMT,0))
						as TotalValue,"+char(10)+
				-- TaxValue and BeforeTaxValue are null if tax is not in use
				case when @bTaxRequired=1
					then "	sum(isnull(T.DISBTAXHOMEAMT,0)+isnull(T.SERVTAXHOMEAMT,0)+isnull(T.DISBSTATETAXHOMEAMT,0)+isnull(T.SERVSTATETAXHOMEAMT,0)) as TaxValue,"+char(10)+
					     "	sum(isnull(T.DISBHOMEAMOUNT,0)-isnull(T.DISBHOMEDISCOUNT,0)+isnull(T.SERVHOMEAMOUNT,0)-isnull(T.SERVHOMEDISCOUNT,0)) as BeforeTaxValue,"
					else "	null as TaxValue,"+char(10)+
					     "	null as BeforeTaxValue,"
					end+char(10)+
				case when @bCanViewEstimates=0
					then char(9)+char(9)+char(9)+"null	as EstimateValue"
					else char(9)+char(9)+char(9)+"sum(isnull(T1.DISBHOMEAMOUNT,0)+isnull(T1.SERVHOMEAMOUNT,0)-isnull(T1.DISBHOMEDISCOUNT,0)-isnull(T1.SERVHOMEDISCOUNT,0)+isnull(T1.DISBTAXHOMEAMT,0)+isnull(T1.SERVTAXHOMEAMT,0)+isnull(T1.DISBSTATETAXHOMEAMT,0)+isnull(T1.SERVSTATETAXHOMEAMT,0))
						as EstimateValue"
					end+"
			from #TEMPCASECHARGES T
			-- get matching estimate if it exists
			left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID
							and(T1.YEARNO=T.YEARNO OR (T1.YEARNO is null and T.YEARNO is null))
							and T1.RATENO=T.RATENO
							and T1.ESTIMATEFLAG=1)
			left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID
							and(T2.YEARNO=T.YEARNO     OR (T2.YEARNO   is null and T.YEARNO   is null))
							--and(T2.FROMDATE=T.FROMDATE OR (T2.FROMDATE is null and T.FROMDATE is null))
							and T2.RATENO=T.RATENO
							and T.ESTIMATEFLAG=1
							and T2.ESTIMATEFLAG=0)
			-- If the main TEMPCASECHARGES (T) row is an estimate then there
			-- should not be a non estimate version (T2)
			Where(T.ESTIMATEFLAG=0
			  OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))
			and @sLocalCurrencyCode<>T.BILLCURRENCY
			and @bCanViewElements=1
			group by T.CASEID,T.YEARNO,T.FROMDATE,T.ISEXPIREDSTEP,cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+convert(nvarchar(10),T.FROMDATE,112)
			order by T.CASEID,T.YEARNO,T.FROMDATE"
	
			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sLocalCurrencyCode	nvarchar(3),
						  @nLocalDecimalPlaces	tinyint,
						  @bCanViewElements	bit',
						  @sLocalCurrencyCode	=@sLocalCurrencyCode,
						  @nLocalDecimalPlaces	=@nLocalDecimalPlaces,
						  @bCanViewElements	=@bCanViewElements
	
		End
	
		-- A3. If the user has security, return data by WIP Category
		-- Each row in the temp table optionally contains two components.
		-- While labelled Service and Disbursement in the parameters,
		-- they need not be in those categories.
		-- Create a derived table containing a union of the two components
		-- and then sum as necessary.
		If @ErrorCode=0
		Begin
			-- Create SQL for derived table (used for summary by WIP Category
			-- and for detail rows.

			-- Note: with translations the following SQL reaches 3912 chars.
	
			-- Start with the 'Disbursement' component
			set @sDerivedTableSQL=
			"select	'A'+cast(T.SEQUENCENO as nvarchar) as RowKey,"+char(10)+
				"cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+convert(nvarchar(10),T.FROMDATE,112)+'^'+WT.CATEGORYCODE as WipRowKey,"+char(10)+
				"T.CASEID as CaseKey,"+char(10)+
				"T.YEARNO as YearNo,"+char(10)+
				"T.RATENO as RateKey,"+char(10)+
				"T.FROMDATE	as [Date],"+char(10)+
				"WT.CATEGORYCODE as WipCategoryCode,"+char(10)+
				"'"+@sLocalCurrencyCode+"' as CurrencyCode,"+char(10)+
				dbo.fn_SqlTranslatedColumn('RATES','CALCLABEL1',null,'R',@sLookupCulture,@pbCalledFromCentura)+" as ComponentDescription,"+char(10)+
				-- Need to include
				-- disbursements values less corresponding discounts
				-- plus corresponding tax
				"isnull(T.DISBHOMEAMOUNT,0)-isnull(T.DISBHOMEDISCOUNT,0)+isnull(T.DISBTAXHOMEAMT,0)+isnull(T.DISBSTATETAXHOMEAMT,0) as TotalValue,"+char(10)+
				"isnull(T.DISBTAXHOMEAMT,0)+isnull(T.DISBSTATETAXHOMEAMT,0) as TaxValue,"+char(10)+
				"isnull(T.DISBHOMEAMOUNT,0)-isnull(T.DISBHOMEDISCOUNT,0) as BeforeTaxValue,"+char(10)+
				"isnull(T1.DISBHOMEAMOUNT,0)-isnull(T1.DISBHOMEDISCOUNT,0)+isnull(T1.DISBTAXHOMEAMT,0)+isnull(T1.DISBSTATETAXHOMEAMT,0) as EstimateValue,"+char(10)+
				case when @bCanViewElements=1
				     then "T.DISBHOMEMARGIN as MarginValue,"+char(10)+
					  "T.DISBSOURCEAMT as SourceValue,"+char(10)+
					  "T.DISBCURRENCY as SourceCurrencyCode"
				     else "null as MarginValue,"+char(10)+
					  "null as SourceValue,"+char(10)+
					  "null as SourceCurrencyCode"
				     end+char(10)+
			"from #TEMPCASECHARGES T"+char(10)+
			"left join WIPTEMPLATE W on (W.WIPCODE=T.DISBWIPCODE)"+char(10)+
			"left join WIPTYPE WT on (WT.WIPTYPEID=W.WIPTYPEID)"+char(10)+
			"left join RATES R on (R.RATENO=T.RATENO)"+char(10)+
			-- get matching estimate if it exists
			"left join #TEMPCASECHARGES T1 on (T1.CASEID=T.CASEID"+char(10)+
							"and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
							"and T1.RATENO=T.RATENO"+char(10)+
							"and T1.ESTIMATEFLAG=1)"+char(10)+
			"left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID"+char(10)+
							"and isnull(T2.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
							--"and isnull(T2.FROMDATE,'')=isnull(T.FROMDATE,'')"+char(10)+
							"and T2.RATENO=T.RATENO"+char(10)+
							"and T.ESTIMATEFLAG=1"+char(10)+
							"and T2.ESTIMATEFLAG=0)"+char(10)+
			-- If the main TEMPCASECHARGES (T) row is an estimate then there
			-- should not be a non estimate version (T2)
			"Where(T.ESTIMATEFLAG=0"+char(10)+
			"  OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))"+char(10)+
			"and T.DISBHOMEAMOUNT<>0"+CHAR(10)+
			"and T.BILLCURRENCY<>'"+@sLocalCurrencyCode+"'"+char(10)+
			Case When(@bCanViewElements=1)
				Then "and 1=1"
				Else "and 1=0"
			End+char(10)+
			"UNION ALL"+char(10)+
			-- Handle 'Service' component
			"select	'B'+cast(T.SEQUENCENO as nvarchar) as RowKey,"+char(10)+
				"cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+convert(nvarchar(10),T.FROMDATE,112)+'^'+WT.CATEGORYCODE as WipRowKey,"+char(10)+
				"T.CASEID as CaseKey,"+char(10)+
				"T.YEARNO as YearNo,"+char(10)+
				"T.RATENO as RateKey,"+char(10)+
				"T.FROMDATE	as [Date],"+char(10)+
				"WT.CATEGORYCODE as WipCategoryCode,"+char(10)+
				"'"+@sLocalCurrencyCode+"' as CurrencyCode,"+char(10)+
				dbo.fn_SqlTranslatedColumn('RATES','CALCLABEL2',null,'R',@sLookupCulture,@pbCalledFromCentura)+" as ComponentDescription,"+char(10)+
				-- Need to include
				-- service value less corresponding discounts
				-- plus corresponding tax
				"isnull(T.SERVHOMEAMOUNT,0)-isnull(T.SERVHOMEDISCOUNT,0)+isnull(T.SERVTAXHOMEAMT,0)+isnull(T.SERVSTATETAXHOMEAMT,0)"+char(10)+
					"as TotalValue,"+char(10)+
				"isnull(T.SERVTAXHOMEAMT,0)+isnull(T.SERVSTATETAXHOMEAMT,0) as TaxValue,"+char(10)+
				"isnull(T.SERVHOMEAMOUNT,0)-isnull(T.SERVHOMEDISCOUNT,0)"+char(10)+
					"as BeforeTaxValue,"+char(10)+
				"isnull(T1.SERVHOMEAMOUNT,0)-isnull(T1.SERVHOMEDISCOUNT,0)+isnull(T1.SERVTAXHOMEAMT,0)+isnull(T1.SERVSTATETAXHOMEAMT,0)"+char(10)+
					"as EstimateValue,"+char(10)+
				case when @bCanViewElements=1
				     then "T.SERVHOMEMARGIN as MarginValue,"+char(10)+
					  "T.SERVSOURCEAMT as SourceValue,"+char(10)+
					  "T.SERVCURRENCY as SourceCurrencyCode"
				     else "null as MarginValue,"+char(10)+
					  "null as SourceValue,"+char(10)+
					  "null	as SourceCurrencyCode"
				     end+char(10)+
			"from #TEMPCASECHARGES T"+char(10)+
			"left join WIPTEMPLATE W on (W.WIPCODE=T.SERVWIPCODE)"+char(10)+
			"left join WIPTYPE WT on (WT.WIPTYPEID=W.WIPTYPEID)"+char(10)+
			"left join RATES R on (R.RATENO=T.RATENO)"+char(10)+
			-- get matching estimate if it exists
			"left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID"+char(10)+
							"and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
							"and T1.RATENO=T.RATENO"+char(10)+
							"and T1.ESTIMATEFLAG=1)"+char(10)+
			"left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID"+char(10)+
							"and isnull(T2.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
							--"and isnull(T2.FROMDATE,'')=isnull(T.FROMDATE,'')"+char(10)+
							"and T2.RATENO=T.RATENO"+char(10)+
							"and T.ESTIMATEFLAG=1"+char(10)+
							"and T2.ESTIMATEFLAG=0)"+char(10)+
			-- If the main TEMPCASECHARGES (T) row is an estimate then there
			-- should not be a non estimate version (T2)
			"Where(T.ESTIMATEFLAG=0"+char(10)+
			"  OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))"+char(10)+
			"and T.SERVHOMEAMOUNT<>0"+CHAR(10)+
			"and T.BILLCURRENCY<>'"+@sLocalCurrencyCode+"'"+char(10)+
			Case When(@bCanViewElements=1)
				Then "and 1=1"
				Else "and 1=0"
			End
	
			-- Prepare main SQL utilising derived table
			Set @sSQLString=
			"select	D.WipRowKey as RowKey,"+char(10)+
			"cast(D.CaseKey as nvarchar)+'^'+cast(D.YearNo as nvarchar)+'^'+"+char(10)+
			"convert(nvarchar(10),D.Date,112) as DateRowKey,"+char(10)+
			"D.CaseKey as CaseKey,"+char(10)+
			"D.YearNo as YearNo,"+char(10)+
			"D.Date	as [Date],"+char(10)+
			"D.CurrencyCode	as CurrencyCode,"+char(10)+
			"D.WipCategoryCode as WipCategoryCode,"+char(10)+char(9)+
			+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)
						+ " as WipCategory,"+char(10)+
			case when @bTaxRequired=1
				then "	sum(isnull(D.TaxValue,0)) as TaxValue,"+char(10)+
				     "	sum(D.BeforeTaxValue) as BeforeTaxValue,"
				else "	null as TaxValue,"+char(10)+
				     "	null as BeforeTaxValue,"
				end+char(10)+
			case when @bCanViewEstimates=0
				then "null	as EstimateValue,"
				else "sum(D.EstimateValue)	as EstimateValue,"
				end+char(10)+
			"	sum(D.TotalValue) as TotalValue"+char(10)+
			"from ("
			
			Set @sSQLString1=
			") D"+char(10)+
			"left join WIPCATEGORY WC on (WC.CATEGORYCODE=D.WipCategoryCode)"+char(10)+
			-- Result set should be empty if user does not have access to
			-- Fees and Charges Calculations by WIP Category
			Case When(@pnUserIdentityId is not null)
				then Case When(@bCanViewByCategory=1)
					then "where 1 = 1"
					else "where 0 = 1"
				     End
			End+char(10)+
			"group by D.CaseKey,D.YearNo,D.Date,D.CurrencyCode,D.WipCategoryCode,WC.CATEGORYSORT,"+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)+",D.WipRowKey"+char(10)+
			"order by D.CaseKey,D.YearNo,D.Date,WC.CATEGORYSORT"

			exec(@sSQLString+@sDerivedTableSQL+@sSQLString1)
			
			Set @ErrorCode=@@Error	
		End

		-- A4. If the user has security, return data by Rate Calculation
		If @ErrorCode=0
		Begin
			-- Uses derived table prepared in previous step.
			Set @sSQLString=
			"select	D.WipRowKey+'^'+cast(D.RateKey as nvarchar)+'^'+D.RowKey as RowKey,"+char(10)+
				"D.WipRowKey as WipRowKey,"+CHAR(10)+
				"D.CaseKey as CaseKey,"+char(10)+
				"D.YearNo as YearNo,"+char(10)+
				"D.Date	as [Date],"+char(10)+
				"D.CurrencyCode	as CurrencyCode,"+char(10)+
				"D.WipCategoryCode	as WipCategoryCode,"+char(10)+
				dbo.fn_SqlTranslatedColumn('RATES','RATEDESC',null,'R',@sLookupCulture,@pbCalledFromCentura)
						+ " as CalculationDescription,"+char(10)+
				"D.ComponentDescription as ComponentDescription,"+char(10)+
			case when @bTaxRequired=1
				then "D.TaxValue as TaxValue,"+char(10)+
				     "D.BeforeTaxValue as BeforeTaxValue,"
				else "null as TaxValue,"+char(10)+
				     "null as BeforeTaxValue,"
				end+char(10)+
			case when @bCanViewEstimates=0
				then "	null	as EstimateValue,"
				else "	D.EstimateValue as EstimateValue,"
				end+char(10)+
				"D.TotalValue 	as TotalValue,"+char(10)+
				"D.MarginValue 	as MarginValue,"+char(10)+
				"D.SourceCurrencyCode as SourceCurrencyCode,"+char(10)+
				"D.SourceValue	as SourceValue"+char(10)+
			"from ("+@sDerivedTableSQL
			+") D"+char(10)+
			"left join RATES R		on (R.RATENO=D.RateKey)"+char(10)+
			-- Result set should be empty if user does not have access to
			-- Fees and Charges Calculations by WIP Category or by Rate Calculation
			Case When(@pnUserIdentityId is not null)
				then "where @bCanViewByCategory = 1"+char(10)+
				     "and   @bCanViewByRate = 1"
			End+char(10)+
			"order by D.CaseKey,D.YearNo,D.Date,CalculationDescription,ComponentDescription"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sLocalCurrencyCode	nvarchar(3),
						  @nLocalDecimalPlaces	tinyint,
						  @pnUserIdentityId	int,
						  @dtToday		datetime,
						  @bCanViewByCategory	bit,
						  @bCanViewByRate	bit,
						  @bCanViewElements	bit',
						  @sLocalCurrencyCode	=@sLocalCurrencyCode,
						  @nLocalDecimalPlaces	=@nLocalDecimalPlaces,
						  @pnUserIdentityId	=@pnUserIdentityId,
						  @dtToday		=@dtToday,
						  @bCanViewByCategory	=@bCanViewByCategory,
						  @bCanViewByRate	=@bCanViewByRate,
						  @bCanViewElements	=@bCanViewElements

		End
	End

	-- B. Billing Currency
	-- Always returned for both internal and external users.

	-- B1. Return the total of all years and calculations
	If @ErrorCode=0
	Begin
		set @sSQLString="
		select	cast(T.CASEID as nvarchar)
					as RowKey,
			T.CASEID	as CaseKey,
			isnull(T.BILLCURRENCY,@sLocalCurrencyCode)
					as CurrencyCode,
			-- Using billing currency, need to include
			-- both service and disbursements values
			-- less corresponding discounts
			-- plus corresponding tax
			sum(	isnull(T.DISBBILLAMOUNT,0)-isnull(T.DISBBILLDISCOUNT,0)
				+isnull(T.SERVBILLAMOUNT,0)-isnull(T.SERVBILLDISCOUNT,0)
				+isnull(T.DISBTAXBILLAMT,0)+isnull(T.SERVTAXBILLAMT,0)
				+isnull(T.DISBSTATETAXBILLAMT,0)+isnull(T.SERVSTATETAXBILLAMT,0))
					as TotalValue,"+char(10)+
			-- TaxValue and BeforeTaxValue are null if tax is not in use
			case when @bTaxRequired=1
				then "	sum(isnull(T.DISBTAXBILLAMT,0)+isnull(T.SERVTAXBILLAMT,0)+isnull(T.DISBSTATETAXBILLAMT,0)+isnull(T.SERVSTATETAXBILLAMT,0)) as TaxValue,"+char(10)+
				     "	sum(isnull(T.DISBBILLAMOUNT,0)-isnull(T.DISBBILLDISCOUNT,0)+isnull(T.SERVBILLAMOUNT,0)-isnull(T.SERVBILLDISCOUNT,0)) as BeforeTaxValue,"
				else "	null as TaxValue,"+char(10)+
				     "	null as BeforeTaxValue,"
				end+char(10)+
			case when @bCanViewEstimates=0
				then "null	as EstimateValue"
				else "sum(isnull(T1.DISBBILLAMOUNT,0)+isnull(T1.SERVBILLAMOUNT,0)-isnull(T1.DISBBILLDISCOUNT,0)-isnull(T1.SERVBILLDISCOUNT,0)+isnull(T1.DISBTAXBILLAMT,0)+isnull(T1.SERVTAXBILLAMT,0)+isnull(T1.DISBSTATETAXBILLAMT,0)+isnull(T1.SERVSTATETAXBILLAMT,0))
					as EstimateValue"
				end+"
		from #TEMPCASECHARGES T
		-- get matching estimate if it exists
		left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID
						and(T1.YEARNO=T.YEARNO OR (T1.YEARNO is null and T.YEARNO is null))
						and T1.RATENO=T.RATENO
						and T1.ESTIMATEFLAG=1)

		left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID
						and(T2.YEARNO=T.YEARNO     OR (T2.YEARNO   is null and T.YEARNO   is null))
					      --and(T2.FROMDATE=T.FROMDATE OR (T2.FROMDATE is null and T.FROMDATE is null))
						and T2.RATENO=T.RATENO
						and T.ESTIMATEFLAG=1
						and T2.ESTIMATEFLAG=0)
		-- If the main TEMPCASECHARGES (T) row is an estimate then there
		-- should not be a non estimate version (T2)
		Where(T.ESTIMATEFLAG=0
		  OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))
		-- Exclude any stepped calculations
		and	T.STEPDATEFLAG=0
		group by T.CASEID,isnull(T.BILLCURRENCY,@sLocalCurrencyCode)"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sLocalCurrencyCode	nvarchar(3),
						  @nLocalDecimalPlaces	tinyint',
						  @sLocalCurrencyCode	=@sLocalCurrencyCode,
						  @nLocalDecimalPlaces	=@nLocalDecimalPlaces
	End

	-- B2. Return the totals by year and stepped calculation date
	--	Note: 	External users should not see stepped calculations
	--		i.e. exclude FROMDATE
	If @ErrorCode=0
	Begin
		set @sSQLString="
		select	cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+
			convert(nvarchar(10),T.FROMDATE,112)
					as RowKey,
			T.CASEID	as CaseKey,
			T.YEARNO	as YearNo,
			T.FROMDATE	as [Date],
			isnull(T.ISEXPIREDSTEP,0)	as IsPastDue,
			isnull(T.BILLCURRENCY,@sLocalCurrencyCode)
					as CurrencyCode,
			-- Using billing currency, need to include
			-- both service and disbursements values
			-- less corresponding discounts
			-- plus corresponding tax
			sum(	isnull(T.DISBBILLAMOUNT,0)-isnull(T.DISBBILLDISCOUNT,0)
				+isnull(T.SERVBILLAMOUNT,0)-isnull(T.SERVBILLDISCOUNT,0)
				+isnull(T.DISBTAXBILLAMT,0)+isnull(T.SERVTAXBILLAMT,0)
				+isnull(T.DISBSTATETAXBILLAMT,0)+isnull(T.SERVSTATETAXBILLAMT,0))
					as TotalValue,"+char(10)+
			-- TaxValue and BeforeTaxValue are null if tax is not in use
			case when @bTaxRequired=1
				then "	sum(isnull(T.DISBTAXBILLAMT,0)+isnull(T.SERVTAXBILLAMT,0)+isnull(T.DISBSTATETAXBILLAMT,0)+isnull(T.SERVSTATETAXBILLAMT,0)) as TaxValue,"+char(10)+
				     "	sum(isnull(T.DISBBILLAMOUNT,0)-isnull(T.DISBBILLDISCOUNT,0)+isnull(T.SERVBILLAMOUNT,0)-isnull(T.SERVBILLDISCOUNT,0)) as BeforeTaxValue,"
				else "	null as TaxValue,"+char(10)+
				     "	null as BeforeTaxValue,"
				end+char(10)+
			case when @bCanViewEstimates=0
				then "null	as EstimateValue"
				else "sum(isnull(T1.DISBBILLAMOUNT,0)+isnull(T1.SERVBILLAMOUNT,0)-isnull(T1.DISBBILLDISCOUNT,0)-isnull(T1.SERVBILLDISCOUNT,0)+isnull(T1.DISBTAXBILLAMT,0)+isnull(T1.SERVTAXBILLAMT,0)+isnull(T1.DISBSTATETAXBILLAMT,0)+isnull(T1.SERVSTATETAXBILLAMT,0))
					as EstimateValue"
				end+"
		from #TEMPCASECHARGES T
		-- get matching estimate if it exists
		left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID
						and(T1.YEARNO=T.YEARNO OR (T1.YEARNO is null and T.YEARNO is null))
						and T1.RATENO=T.RATENO
						and T1.ESTIMATEFLAG=1)
		left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID
						and(T2.YEARNO=T.YEARNO     OR (T2.YEARNO   is null and T.YEARNO   is null))
						and(T2.FROMDATE=T.FROMDATE OR (T2.FROMDATE is null and T.FROMDATE is null))
						and T2.RATENO=T.RATENO
						and T.ESTIMATEFLAG=1
						and T2.ESTIMATEFLAG=0)
		-- If the main TEMPCASECHARGES (T) row is an estimate then there
		-- should not be a non estimate version (T2)
		Where(T.ESTIMATEFLAG=0
		  OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))"+CHAR(10)+
		-- Exclude any stepped calculations that are before the current date
		case when @bIsExternalUser=1
		then +" and T.STEPDATEFLAG=0 and dbo.fn_DateOnly(T.FROMDATE) >= dbo.fn_DateOnly(getdate())"
		end+"
		group by T.CASEID,T.YEARNO,T.FROMDATE,T.ISEXPIREDSTEP,isnull(T.BILLCURRENCY,@sLocalCurrencyCode),cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+convert(nvarchar(10),T.FROMDATE,112)
		order by T.CASEID,T.YEARNO,T.FROMDATE"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint',
					  @sLocalCurrencyCode	=@sLocalCurrencyCode,
					  @nLocalDecimalPlaces	=@nLocalDecimalPlaces

	End

	-- B3. If the user has security, return data by WIP Category
	-- Each row in the temp table optionally contains two components.
	-- While labelled Service and Disbursement in the parameters,
	-- they need not be in those categories.
	-- Create a derived table containing a union of the two components
	-- and then sum as necessary.
	If @ErrorCode=0
	Begin
		-- Create SQL for derived table (used for summary by WIP Category
		-- and for detail rows.

		-- Note: with translation the following SQL is 3962 chars

		-- Start with the 'Disbursement' component
		set @sDerivedTableSQL=
		"select	'A'+cast(T.SEQUENCENO as nvarchar) as RowKey,"+char(10)+
			"cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+convert(nvarchar(10),T.FROMDATE,112)+'^'+WT.CATEGORYCODE as WipRowKey,"+char(10)+
			"T.CASEID	as CaseKey,"+char(10)+
			"T.YEARNO	as YearNo,"+char(10)+
			"T.RATENO	as RateKey,"+char(10)+
			"T.FROMDATE	as [Date],"+char(10)+
			"WT.CATEGORYCODE	as WipCategoryCode,"+char(10)+
			"isnull(T.BILLCURRENCY,'"+@sLocalCurrencyCode+"') as CurrencyCode,"+char(10)+
			+dbo.fn_SqlTranslatedColumn('RATES','CALCLABEL1',null,'R',@sLookupCulture,@pbCalledFromCentura)+char(10)+
			"	as ComponentDescription,"+char(10)+
			-- Need to include
			-- disbursements values less corresponding discounts
			-- plus corresponding tax
			"isnull(T.DISBBILLAMOUNT,0)-isnull(T.DISBBILLDISCOUNT,0)+isnull(T.DISBTAXBILLAMT,0)+isnull(T.DISBSTATETAXBILLAMT,0) as TotalValue,"+char(10)+
			"isnull(T.DISBTAXBILLAMT,0)+isnull(T.DISBSTATETAXBILLAMT,0) as TaxValue,"+char(10)+
			"isnull(T.DISBBILLAMOUNT,0)-isnull(T.DISBBILLDISCOUNT,0) as BeforeTaxValue,"+char(10)+
			"isnull(T1.DISBBILLAMOUNT,0)-isnull(T1.DISBBILLDISCOUNT,0)+isnull(T1.DISBTAXBILLAMT,0)+isnull(T1.DISBSTATETAXBILLAMT,0) as EstimateValue,"+char(10)+
			case when @bCanViewElements=1
			     then "T.DISBBILLMARGIN as MarginValue,"+char(10)+
				  "T.DISBSOURCEAMT as SourceValue,"+char(10)+
				  "T.DISBCURRENCY as SourceCurrencyCode"
			     else "null	as MarginValue,"+char(10)+
				  "null	as SourceValue,"+char(10)+
				  "null	as SourceCurrencyCode"
			     end+char(10)+	
		"from #TEMPCASECHARGES T"+char(10)+
		"left join WIPTEMPLATE W on (W.WIPCODE=T.DISBWIPCODE)"+char(10)+
		"left join WIPTYPE WT	on (WT.WIPTYPEID=W.WIPTYPEID)"+char(10)+
		"left join RATES R	on (R.RATENO=T.RATENO)"+char(10)+
		-- get matching estimate if it exists
		"left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID"+char(10)+
						"and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
						"and T1.RATENO=T.RATENO"+char(10)+
						"and T1.ESTIMATEFLAG=1)"+char(10)+
		"left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID"+char(10)+
						"and isnull(T2.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
						--"and isnull(T2.FROMDATE,'')=isnull(T.FROMDATE,'')"+char(10)+
						"and T2.RATENO=T.RATENO"+char(10)+
						"and T.ESTIMATEFLAG=1"+char(10)+
						"and T2.ESTIMATEFLAG=0)"+char(10)+
		-- If the main TEMPCASECHARGES (T) row is an estimate then there
		-- should not be a non estimate version (T2)
		"Where(T.ESTIMATEFLAG=0"+char(10)+
		"  OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))"+char(10)+
		"and T.DISBBILLAMOUNT<>0"+CHAR(10)+
		-- Exclude any stepped calculations for past dates for external users
		case when @bIsExternalUser=1
		then +"and T.STEPDATEFLAG=0 and dbo.fn_DateOnly(T.FROMDATE) >= dbo.fn_DateOnly(getdate())"
		end+char(10)+
		"UNION ALL"+char(10)+
		-- Handle 'Service' component
		"select	'B'+cast(T.SEQUENCENO as nvarchar) as RowKey,"+char(10)+
			"cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+convert(nvarchar(10),T.FROMDATE,112)+'^'+WT.CATEGORYCODE as WipRowKey,"+char(10)+
			"T.CASEID	as CaseKey,"+char(10)+
			"T.YEARNO	as YearNo,"+char(10)+
			"T.RATENO	as RateKey,"+char(10)+
			"T.FROMDATE	as [Date],"+char(10)+
			"WT.CATEGORYCODE	as WipCategoryCode,"+char(10)+
			"isnull(T.BILLCURRENCY,'"+@sLocalCurrencyCode+"') as CurrencyCode,"+char(10)+
			dbo.fn_SqlTranslatedColumn('RATES','CALCLABEL2',null,'R',@sLookupCulture,@pbCalledFromCentura)+char(10)+
			" as ComponentDescription,"+char(10)+
			-- Need to include
			-- service value less corresponding discounts
			-- plus corresponding tax
			"isnull(T.SERVBILLAMOUNT,0)-isnull(T.SERVBILLDISCOUNT,0)+isnull(T.SERVTAXBILLAMT,0)+isnull(T.SERVSTATETAXBILLAMT,0) as TotalValue,"+char(10)+
			"isnull(T.SERVTAXBILLAMT,0)+isnull(T.SERVSTATETAXBILLAMT,0) as TaxValue,"+char(10)+
			"isnull(T.SERVBILLAMOUNT,0)-isnull(T.SERVBILLDISCOUNT,0) as BeforeTaxValue,"+char(10)+
			"isnull(T1.SERVBILLAMOUNT,0)-isnull(T1.SERVBILLDISCOUNT,0)+isnull(T1.SERVTAXBILLAMT,0)+isnull(T1.SERVSTATETAXBILLAMT,0) as EstimateValue,"+char(10)+
			case when @bCanViewElements=1
			     then "T.SERVBILLMARGIN as MarginValue,"+char(10)+
				  "T.SERVSOURCEAMT as SourceValue,"+char(10)+
				  "T.SERVCURRENCY as SourceCurrencyCode"
			     else "null	as MarginValue,"+char(10)+
				  "null	as SourceValue,"+char(10)+
				  "null	as SourceCurrencyCode"
			     end+char(10)+	
		"from #TEMPCASECHARGES T"+char(10)+
		"left join WIPTEMPLATE W on (W.WIPCODE=T.SERVWIPCODE)"+char(10)+
		"left join WIPTYPE WT	on (WT.WIPTYPEID=W.WIPTYPEID)"+char(10)+
		"left join RATES R	on (R.RATENO=T.RATENO)"+char(10)+
		-- get matching estimate if it exists
		"left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID"+char(10)+
						"and isnull(T1.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
						"and T1.RATENO=T.RATENO"+char(10)+
						"and T1.ESTIMATEFLAG=1)"+char(10)+
		"left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID"+char(10)+
						"and isnull(T2.YEARNO,'')=isnull(T.YEARNO,'')"+char(10)+
						--"and isnull(T2.FROMDATE,'')=isnull(T.FROMDATE,'')"+char(10)+
						"and T2.RATENO=T.RATENO"+char(10)+
						"and T.ESTIMATEFLAG=1"+char(10)+
						"and T2.ESTIMATEFLAG=0)"+char(10)+
		-- If the main TEMPCASECHARGES (T) row is an estimate then there
		-- should not be a non estimate version (T2)
		"Where(T.ESTIMATEFLAG=0"+char(10)+
		"  OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))"+char(10)+
		"and T.SERVBILLAMOUNT<>0"+CHAR(10)+
		-- Exclude any stepped calculations for external users
		case when @bIsExternalUser=1
		then +"and T.STEPDATEFLAG=0 and dbo.fn_DateOnly(T.FROMDATE) >= dbo.fn_DateOnly(getdate())"
		end

		-- Prepare main SQL utilising derived table
		Set @sSQLString=
		"select	D.WipRowKey	as RowKey,"+CHAR(10)+
		"cast(D.CaseKey as nvarchar)+'^'+cast(D.YearNo as nvarchar)+'^'+"+CHAR(10)+
		"convert(nvarchar(10),D.Date,112)"+CHAR(10)+
		"		as DateRowKey,"+CHAR(10)+
		"D.CaseKey	as CaseKey,"+CHAR(10)+
		"D.YearNo	as YearNo,"+CHAR(10)+
		"D.Date		as [Date],"+CHAR(10)+
		"D.CurrencyCode	as CurrencyCode,"+CHAR(10)+
		"D.WipCategoryCode"+CHAR(10)+
		"		as WipCategoryCode,"+CHAR(10)+
		+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)
				+ " as WipCategory,"+CHAR(10)+
		case when @bTaxRequired=1
			then "	sum(isnull(D.TaxValue,0)) as TaxValue,"+char(10)+
			     "	sum(D.BeforeTaxValue) as BeforeTaxValue,"
			else "	null as TaxValue,"+char(10)+
			     "	null as BeforeTaxValue,"
			end+char(10)+
		case when @bCanViewEstimates=0
			then "null	as EstimateValue,"
			else "sum(D.EstimateValue)	as EstimateValue,"
			end+char(10)+
		"	sum(D.TotalValue) as TotalValue"+char(10)+
		"from ("
		
		Set @sSQLString1=
		") D"+char(10)+
		-- Result set should be empty if user does not have access to
		-- Fees and Charges Calculations by WIP Category
		Case When(@pnUserIdentityId is not null)
			then "join dbo.fn_GetTopicSecurity("+cast(@pnUserIdentityId as varchar)+",4,0,'"+convert(varchar, @dtToday,121)+"') on (IsAvailable=1)"
		End+char(10)+
		"left join WIPCATEGORY WC	on (WC.CATEGORYCODE=D.WipCategoryCode)"+CHAR(10)+
		-- Result set should be empty if user does not have access to
		-- Fees and Charges Calculations by WIP Category
		Case When(@pnUserIdentityId is not null)
			then Case When(@bCanViewByCategory=1)
				then "where 1 = 1"
				else "where 0 = 1"
			     End
		End+char(10)+
		"group by D.CaseKey,D.YearNo,D.Date,D.CurrencyCode,D.WipCategoryCode,WC.CATEGORYSORT,"+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)+",D.WipRowKey"+char(10)+
		"order by D.CaseKey,D.YearNo,D.Date,WC.CATEGORYSORT"

		exec(@sSQLString+@sDerivedTableSQL+@sSQLString1)
		
		Set @ErrorCode=@@Error
	End

	-- B4. If the user has security, return data by Rate Calculation
	If @ErrorCode=0
	Begin
		-- Uses derived table prepared in previous step.
		Set @sSQLString=
		"select	D.WipRowKey+'^'+cast(D.RateKey as nvarchar)+'^'+D.RowKey as RowKey,"+char(10)+
			"D.WipRowKey as WipRowKey,"+CHAR(10)+
			"D.CaseKey	as CaseKey,"+char(10)+
			"D.YearNo	as YearNo,"+char(10)+
			"D.Date		as [Date],"+char(10)+
			"D.CurrencyCode	as CurrencyCode,"+char(10)+
			"D.WipCategoryCode	as WipCategoryCode,"+char(10)+
			dbo.fn_SqlTranslatedColumn('RATES','RATEDESC',null,'R',@sLookupCulture,@pbCalledFromCentura)
					+ " as CalculationDescription,"+char(10)+
			"D.ComponentDescription as ComponentDescription,"+char(10)+
		case when @bTaxRequired=1
			then "	D.TaxValue as TaxValue,"+char(10)+
			     "	D.BeforeTaxValue as BeforeTaxValue,"
			else "	null as TaxValue,"+char(10)+
			     "	null as BeforeTaxValue,"
			end+char(10)+
		case when @bCanViewEstimates=0
			then "	null	as EstimateValue,"
			else "	D.EstimateValue as EstimateValue,"
			end+char(10)+
			"D.TotalValue 	as TotalValue,"+char(10)+
			"D.MarginValue 	as MarginValue,"+char(10)+
			"D.SourceCurrencyCode as SourceCurrencyCode,"+char(10)+
			"D.SourceValue	as SourceValue"+char(10)+		"from ("+@sDerivedTableSQL
		+") D"+char(10)+
		"left join RATES R		on (R.RATENO=D.RateKey)"+char(10)+
		-- Result set should be empty if user does not have access to
		-- Fees and Charges Calculations by WIP Category or by Rate Calculation
		Case When(@pnUserIdentityId is not null)
			then "where @bCanViewByCategory = 1"+char(10)+
			     "and   @bCanViewByRate = 1"
		End+char(10)+
		"order by D.CaseKey,D.YearNo,D.Date,CalculationDescription,ComponentDescription"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint,
					  @pnUserIdentityId	int,
					  @dtToday		datetime,
					  @bCanViewByCategory	bit,
					  @bCanViewByRate	bit',
					  @sLocalCurrencyCode	=@sLocalCurrencyCode,
					  @nLocalDecimalPlaces	=@nLocalDecimalPlaces,
					  @pnUserIdentityId	=@pnUserIdentityId,
					  @dtToday		=@dtToday,
					  @bCanViewByCategory	=@bCanViewByCategory,
					  @bCanViewByRate	=@bCanViewByRate
	End
End

------------------------
-- Client/Server version

-- Note: following SQLString(s) are maxed out. Beware of adding anything else to these
------------------------
Else If @ErrorCode=0
and @pbCalledFromCentura = 1
Begin

	-- Retrieve Local Currency information
	If @ErrorCode=0
	Begin
		exec @ErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
								@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
								@pnUserIdentityId 	= @pnUserIdentityId,
								@pbCalledFromCentura	= @pbCalledFromCentura
	End

	-- A. Home Currency
	-- Should be empty if the same as billing currency

	-- A3. Return data by WIP Category
	-- Each row in the temp table optionally contains two components.
	-- While labelled Service and Disbursement in the parameters,
	-- they need not be in those categories.
	-- Create a derived table containing a union of the two components
	-- and then sum as necessary.
	If @ErrorCode=0
	Begin
		-- Create SQL for derived table (used for summary by WIP Category
		-- and for detail rows.

		-- Note: with translations the following SQL reaches 3912 chars.

		-- Start with the 'Disbursement' component
		set @sDerivedTableSQL=
		"select	'A'+cast(T.SEQUENCENO as nvarchar) as RowKey,"+char(10)+
		"cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+"+char(10)+
		"convert(nvarchar(10),T.FROMDATE,112)+'^'+WT.CATEGORYCODE as CategoryRowKey,"+char(10)+
		"T.CASEID as CaseKey,T.YEARNO,T.RATENO as RateKey,T.FROMDATE as [Date],"+char(10)+
		"isnull(T.ISEXPIREDSTEP,0) as IsPastDue,WT.CATEGORYCODE,WC.DESCRIPTION,"+char(10)+
		"WC.CATEGORYSORT,@sLocalCurrencyCode as CurrencyCode,R.CALCLABEL1 as ComponentDescription,"+char(10)+
		-- Need to include
		-- disbursements values less corresponding discounts
		-- plus corresponding tax
		"isnull(T.DISBHOMEAMOUNT,0)-isnull(T.DISBHOMEDISCOUNT,0)+isnull(T.DISBTAXHOMEAMT,0)+isnull(T.DISBSTATETAXHOMEAMT,0) as TotalValue,"+char(10)+
		"isnull(T.DISBTAXHOMEAMT,0)+isnull(T.DISBSTATETAXHOMEAMT,0) as TaxValue,"+char(10)+
		"isnull(T.DISBHOMEAMOUNT,0)-isnull(T.DISBHOMEDISCOUNT,0)as BeforeTaxValue,"+char(10)+
		"isnull(T1.DISBHOMEAMOUNT,0)-isnull(T1.DISBHOMEDISCOUNT,0)+isnull(T1.DISBTAXHOMEAMT,0)+isnull(T1.DISBSTATETAXHOMEAMT,0) as EstimateValue,"+char(10)+
		"T.DISBHOMEMARGIN as MarginValue,"+char(10)+
		"CASE WHEN(T.DISBCURRENCY<>@sLocalCurrencyCode) THEN T.DISBAMOUNT-isnull(T.DISBDISCORIGINAL,0) END as SourceValue,"+char(10)+
		"T.DISBCURRENCY	as SourceCurrencyCode"+char(10)+
		"from #TEMPCASECHARGES T"+char(10)+
		"left join WIPTEMPLATE W on (W.WIPCODE=T.DISBWIPCODE)"+char(10)+
		"left join WIPTYPE WT on (WT.WIPTYPEID=W.WIPTYPEID)"+char(10)+
		"left join WIPCATEGORY WC on (WC.CATEGORYCODE=WT.CATEGORYCODE)"+char(10)+
		"left join RATES R on (R.RATENO=T.RATENO)"+char(10)+
		-- get matching estimate if it exists
		"left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID"+char(10)+
						"and(T1.YEARNO=T.YEARNO OR (T1.YEARNO is null and T.YEARNO is null))"+char(10)+
						"and T1.RATENO=T.RATENO"+char(10)+
						"and T1.ESTIMATEFLAG=1)"+char(10)+
		"left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID"+char(10)+
						"and(T2.YEARNO=T.YEARNO OR (T2.YEARNO is null and T.YEARNO is null))"+char(10)+
						"and T2.RATENO=T.RATENO"+char(10)+
						"and T.ESTIMATEFLAG=1"+char(10)+
						"and T2.ESTIMATEFLAG=0)"+char(10)+
		-- If the main TEMPCASECHARGES (T) row is an estimate then there
		-- should not be a non estimate version (T2)
		"Where(T.ESTIMATEFLAG=0 OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))"+char(10)+
		"and T.DISBHOMEAMOUNT<>0"+CHAR(10)+
		"and @sLocalCurrencyCode<>T.BILLCURRENCY"+char(10)+
		"UNION ALL"+char(10)+
		-- Handle 'Service' component
		"select	'B'+cast(T.SEQUENCENO as nvarchar),"+char(10)+
		"cast(T.CASEID as nvarchar)+'^'+cast(T.YEARNO as nvarchar)+'^'+"+char(10)+
		"convert(nvarchar(10),T.FROMDATE,112)+'^'+WT.CATEGORYCODE,"+char(10)+
		"T.CASEID,T.YEARNO,T.RATENO,T.FROMDATE,isnull(T.ISEXPIREDSTEP,0),"+char(10)+
		"WT.CATEGORYCODE,WC.DESCRIPTION,WC.CATEGORYSORT,@sLocalCurrencyCode,"+char(10)+
		"R.CALCLABEL2,"+char(10)+
		-- Need to include
		-- service value less corresponding discounts
		-- plus corresponding tax
		"isnull(T.SERVHOMEAMOUNT,0)-isnull(T.SERVHOMEDISCOUNT,0)+isnull(T.SERVTAXHOMEAMT,0)+isnull(T.SERVSTATETAXHOMEAMT,0),"+char(10)+
		"isnull(T.SERVTAXHOMEAMT,0)+isnull(T.SERVSTATETAXHOMEAMT,0),"+char(10)+
		"isnull(T.SERVHOMEAMOUNT,0)-isnull(T.SERVHOMEDISCOUNT,0),"+char(10)+
		"isnull(T1.SERVHOMEAMOUNT,0)-isnull(T1.SERVHOMEDISCOUNT,0)+isnull(T1.SERVTAXHOMEAMT,0)+isnull(T1.SERVSTATETAXHOMEAMT,0),"+char(10)+
		"T.SERVHOMEMARGIN,"+char(10)+
		"CASE WHEN(T.SERVCURRENCY<>@sLocalCurrencyCode) THEN T.SERVAMOUNT-isnull(T.SERVDISCORIGINAL,0) END,"+char(10)+
		"T.SERVCURRENCY"+char(10)+
		"from #TEMPCASECHARGES T"+char(10)+
		"left join WIPTEMPLATE W on (W.WIPCODE=T.SERVWIPCODE)"+char(10)+
		"left join WIPTYPE WT on (WT.WIPTYPEID=W.WIPTYPEID)"+char(10)+
		"left join WIPCATEGORY WC on (WC.CATEGORYCODE=WT.CATEGORYCODE)"+char(10)+
		"left join RATES R on (R.RATENO=T.RATENO)"+char(10)+
		-- get matching estimate if it exists
		"left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID"+char(10)+
						"and(T1.YEARNO=T.YEARNO OR (T1.YEARNO is null and T.YEARNO is null))"+char(10)+
						"and T1.RATENO=T.RATENO"+char(10)+
						"and T1.ESTIMATEFLAG=1)"+char(10)+
		"left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID"+char(10)+
						"and(T2.YEARNO=T.YEARNO OR (T2.YEARNO is null and T.YEARNO is null))"+char(10)+
						"and T2.RATENO=T.RATENO"+char(10)+
						"and T.ESTIMATEFLAG=1"+char(10)+
						"and T2.ESTIMATEFLAG=0)"+char(10)+
		-- If the main TEMPCASECHARGES (T) row is an estimate then there
		-- should not be a non estimate version (T2)
		"Where(T.ESTIMATEFLAG=0 OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))"+char(10)+
		"and T.SERVHOMEAMOUNT<>0"+CHAR(10)+
		"and @sLocalCurrencyCode<>T.BILLCURRENCY"

		-- Uses derived table prepared in previous step.
		Set @sSQLString=
		"select	D.RowKey,D.CaseKey,D.YEARNO,D.Date,"+char(10)+
			"D.IsPastDue,D.CurrencyCode,D.CATEGORYCODE,"+char(10)+
			"D.DESCRIPTION,R.RATEDESC,"+char(10)+
			"D.ComponentDescription,"+char(10)+
		case when @bTaxRequired=1
			then "D.TaxValue,"+char(10)+
			     "D.BeforeTaxValue,"
			else "null,"+char(10)+
			     "null,"
			end+char(10)+
			"D.EstimateValue,"+char(10)+
			"D.TotalValue,"+char(10)+
			"D.MarginValue,"+char(10)+
			"CASE WHEN(D.SourceValue<>0) THEN D.SourceCurrencyCode END as SourceCurrencyCode,"+char(10)+
			"CASE WHEN(D.SourceValue<>0) THEN D.SourceValue END as SourceValue"+char(10)+
		"from ("+@sDerivedTableSQL
		+") D"+char(10)+
		"left join RATES R on (R.RATENO=D.RateKey)"+char(10)+
		"order by D.CaseKey,D.YEARNO,D.Date,D.CATEGORYSORT,R.RATEDESC,D.ComponentDescription"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint,
					  @dtToday		datetime',
					  @sLocalCurrencyCode	=@sLocalCurrencyCode,
					  @nLocalDecimalPlaces	=@nLocalDecimalPlaces,
					  @dtToday		=@dtToday
	End

	-- B. Billing Currency

	-- B3. Return data by WIP Category
	-- Each row in the temp table optionally contains two components.
	-- While labelled Service and Disbursement in the parameters,
	-- they need not be in those categories.
	-- Create a derived table containing a union of the two components
	-- and then sum as necessary.
	If @ErrorCode=0
	Begin
		-- Create SQL for derived table (used for summary by WIP Category
		-- and for detail rows.

		-- Start with the 'Disbursement' component
		set @sDerivedTableSQL=
		"select	'A'+cast(T.SEQUENCENO as nvarchar) as RowKey,"+char(10)+
		"T.CASEID as CaseKey,T.YEARNO,T.RATENO as RateKey,"+char(10)+
		"T.FROMDATE as [Date],isnull(T.ISEXPIREDSTEP,0) as IsPastDue,"+char(10)+
		"WT.CATEGORYCODE,WC.DESCRIPTION,WC.CATEGORYSORT,"+char(10)+
		"isnull(T.BILLCURRENCY,@sLocalCurrencyCode) as CurrencyCode,"+char(10)+
		"R.CALCLABEL1 as ComponentDescription,"+char(10)+
		-- Need to include
		-- disbursements values less corresponding discounts
		-- plus corresponding tax
		"isnull(T.DISBBILLAMOUNT,0)-isnull(T.DISBBILLDISCOUNT,0)+isnull(T.DISBTAXBILLAMT,0)+isnull(T.DISBSTATETAXBILLAMT,0) as TotalValue,"+char(10)+
		"isnull(T.DISBTAXBILLAMT,0)+isnull(T.DISBSTATETAXBILLAMT,0) as TaxValue,"+char(10)+
		"isnull(T.DISBBILLAMOUNT,0)-isnull(T.DISBBILLDISCOUNT,0) as BeforeTaxValue,"+char(10)+
		"isnull(T1.DISBBILLAMOUNT,0)-isnull(T1.DISBBILLDISCOUNT,0)+isnull(T1.DISBTAXBILLAMT,0)+isnull(T1.DISBSTATETAXBILLAMT,0) as EstimateValue,"+char(10)+
		"T.DISBBILLMARGIN as MarginValue,"+char(10)+
		"CASE WHEN(T.DISBCURRENCY<>T.BILLCURRENCY) THEN T.DISBAMOUNT-isnull(T.DISBDISCORIGINAL,0) END as SourceValue,"+char(10)+
		"T.DISBCURRENCY	as SourceCurrencyCode"+char(10)+	
		"from #TEMPCASECHARGES T"+char(10)+
		"left join WIPTEMPLATE W on (W.WIPCODE=T.DISBWIPCODE)"+char(10)+
		"left join WIPTYPE WT on (WT.WIPTYPEID=W.WIPTYPEID)"+char(10)+
		"left join WIPCATEGORY WC on (WC.CATEGORYCODE=WT.CATEGORYCODE)"+char(10)+
		"left join RATES R on (R.RATENO=T.RATENO)"+char(10)+
		-- get matching estimate if it exists
		"left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID"+char(10)+
						"and(T1.YEARNO=T.YEARNO OR (T1.YEARNO is null and T.YEARNO is null))"+char(10)+
						"and T1.RATENO=T.RATENO"+char(10)+
						"and T1.ESTIMATEFLAG=1)"+char(10)+
		"left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID"+char(10)+
						"and(T2.YEARNO=T.YEARNO OR (T2.YEARNO is null and T.YEARNO is null))"+char(10)+
						"and T2.RATENO=T.RATENO"+char(10)+
						"and T.ESTIMATEFLAG=1"+char(10)+
						"and T2.ESTIMATEFLAG=0)"+char(10)+
		-- If the main TEMPCASECHARGES (T) row is an estimate then there
		-- should not be a non estimate version (T2)
		"Where(T.ESTIMATEFLAG=0 OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))"+char(10)+
		"and T.DISBBILLAMOUNT<>0"+CHAR(10)+
		"UNION ALL"+char(10)+
		-- Handle 'Service' component
		"select	'B'+cast(T.SEQUENCENO as nvarchar),T.CASEID,T.YEARNO,T.RATENO,T.FROMDATE,isnull(T.ISEXPIREDSTEP,0),"+char(10)+
		"WT.CATEGORYCODE,WC.DESCRIPTION,WC.CATEGORYSORT,isnull(T.BILLCURRENCY,@sLocalCurrencyCode),R.CALCLABEL2,"+char(10)+
		-- Need to include
		-- service value less corresponding discounts
		-- plus corresponding tax
		"isnull(T.SERVBILLAMOUNT,0)-isnull(T.SERVBILLDISCOUNT,0)+isnull(T.SERVTAXBILLAMT,0)+isnull(T.SERVSTATETAXBILLAMT,0),"+char(10)+
		"isnull(T.SERVTAXBILLAMT,0)+isnull(T.SERVSTATETAXBILLAMT,0),"+char(10)+
		"isnull(T.SERVBILLAMOUNT,0)-isnull(T.SERVBILLDISCOUNT,0),"+char(10)+
		"isnull(T1.SERVBILLAMOUNT,0)-isnull(T1.SERVBILLDISCOUNT,0)+isnull(T1.SERVTAXBILLAMT,0)+isnull(T1.SERVSTATETAXBILLAMT,0),"+char(10)+
		"T.SERVBILLMARGIN,"+char(10)+
		"CASE WHEN(T.SERVCURRENCY<>T.BILLCURRENCY) THEN T.SERVAMOUNT-isnull(T.SERVDISCORIGINAL,0) END,"+char(10)+
		"T.SERVCURRENCY"+char(10)+
		"from #TEMPCASECHARGES T"+char(10)+
		"left join WIPTEMPLATE W on (W.WIPCODE=T.SERVWIPCODE)"+char(10)+
		"left join WIPTYPE WT on (WT.WIPTYPEID=W.WIPTYPEID)"+char(10)+
		"left join WIPCATEGORY WC on (WC.CATEGORYCODE=WT.CATEGORYCODE)"+char(10)+
		"left join RATES R on (R.RATENO=T.RATENO)"+char(10)+
		-- get matching estimate if it exists
		"left join #TEMPCASECHARGES T1	on (T1.CASEID=T.CASEID"+char(10)+
						"and(T1.YEARNO=T.YEARNO OR (T1.YEARNO is null and T.YEARNO is null))"+char(10)+
						"and T1.RATENO=T.RATENO"+char(10)+
						"and T1.ESTIMATEFLAG=1)"+char(10)+
		"left join #TEMPCASECHARGES T2	on (T2.CASEID=T.CASEID"+char(10)+
						"and(T2.YEARNO=T.YEARNO OR (T2.YEARNO is null and T.YEARNO is null))"+char(10)+
						"and T2.RATENO=T.RATENO"+char(10)+
						"and T.ESTIMATEFLAG=1"+char(10)+
						"and T2.ESTIMATEFLAG=0)"+char(10)+
		-- If the main TEMPCASECHARGES (T) row is an estimate then there
		-- should not be a non estimate version (T2)
		"Where(T.ESTIMATEFLAG=0 OR (T.ESTIMATEFLAG=1 and T2.CASEID is null))"+char(10)+
		"and T.SERVBILLAMOUNT<>0"

		-- Uses derived table prepared in previous step.
		Set @sSQLString=
		"select	D.RowKey,D.CaseKey,D.YEARNO,D.Date,D.IsPastDue,D.CurrencyCode,"+char(10)+
		"D.CATEGORYCODE,D.DESCRIPTION,R.RATEDESC,D.ComponentDescription,"+char(10)+
		case when @bTaxRequired=1
			then "D.TaxValue,"+char(10)+
			     "D.BeforeTaxValue,"
			else "null,"+char(10)+
			     "null,"
			end+char(10)+
		"D.EstimateValue,D.TotalValue,D.MarginValue,"+char(10)+
		"CASE WHEN(D.SourceValue<>0) THEN D.SourceCurrencyCode END as SourceCurrencyCode,"+char(10)+
		"CASE WHEN(D.SourceValue<>0) THEN D.SourceValue END as SourceValue"+char(10)+
		"from ("+@sDerivedTableSQL
		+") D"+char(10)+
		"left join RATES R on (R.RATENO=D.RateKey)"+char(10)+
		"order by D.CaseKey,D.YEARNO,D.Date,D.CATEGORYSORT,R.RATEDESC,ComponentDescription"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint,
					  @dtToday		datetime',
					  @sLocalCurrencyCode	=@sLocalCurrencyCode,
					  @nLocalDecimalPlaces	=@nLocalDecimalPlaces,
					  @dtToday		=@dtToday
	End
End
RETURN @ErrorCode
go

grant execute on dbo.cs_ListCaseCharges  to public
go
