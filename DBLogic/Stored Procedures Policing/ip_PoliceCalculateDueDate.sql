-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceCalculateDueDate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceCalculateDueDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceCalculateDueDate.'
	drop procedure dbo.ip_PoliceCalculateDueDate
end
print '**** Creating procedure dbo.ip_PoliceCalculateDueDate...'
print ''
go

set QUOTED_IDENTIFIER off
GO
set ANSI_NULLS on
go

create procedure [dbo].[ip_PoliceCalculateDueDate]
				@pnCountStateC			int=0	OUTPUT,
				@pnCountStateI			int=0	OUTPUT,
				@pnCountStateR			int=0	OUTPUT,
				@pnCountStateRX			int=0	OUTPUT,
				@pnCountStateD			int=0	OUTPUT,
				@nCountParentUpdate		int=0	OUTPUT,
				@pdtUntilDate			datetime,
			 	@pnDebugFlag			tinyint
as
-- PROCEDURE :	ip_PoliceCalculateDueDate
-- VERSION :	74
-- DESCRIPTION:	A procedure to perform the due date calculations and then update the TEMPCASEEVENT
--		table with the appropriate Due Date (earliest or latest)
--		The steps involved are :
--		1. Perform all calculculations and store result in a temporary table
--		2. Adjust any of the calculations that require adjusting
--		3. Delete any calculated rows where a Must Exist rule failed or no due date was calculated
--		4. Further adjust the remaining calculations for holidays and weekends as required
--		5. Update the TEMPCASEEVENT row from the TEMPCASEDUEDATE based on the Earliest or Latest rule
--		6. Perform a Date Comparison check to determine if the calculation can be performed.  Note that
--		   this is performed AFTER the calculation because the calculated date may form part of the 
--		   date comparison rules.
-- CALLED BY :	ipu_PoliceRecalc

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 13/07/2000	MF			Procedure created
-- 02/10/2001	MF	7094		Any event that has been cleared out and marked as C1 because it is not required 
--					to be recalculated (because it does not have an open action) is to have its 
--					State change to "R" to indicate that its processing is complete.
-- 17/10/2001	MF	7123		Check that any TEMPCASEEVENT row to be recalculated has a valid Criteriano 
--					and if not then attempt to update it with a Criteriano of an OPENACTION
--					against the Case.
-- 18/10/2001	MF	7129		When a manually entered Due Date is recalculated it is resulting in the 
--					due date being cleared.  The State needs to be changed before the calculation.		
-- 30/10/2001	MF	7153		When the Maximimum Cycle is required in a calculation, Policing must ignore
--					any CaseEvents that have been earmarked to be deleted or recalculated.
-- 14/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 16/11/2001	MF	7203		Calculations are allowed even if the Governing Event is marked to be calculated.
--					When these were supressed it resulted in a looping situation.
-- 03/12/2001	MF	7254		When adjusting a calculated Due Date back to a working day, only consider those
--					countries where the working days have been defined otherwise an endless loop can 
--					occur.
-- 04/01/2002	MF	7318		When calculating the due date of an event make sure that the correct due date 
--					calculation is used in the situation where an Event belongs to more than one 
--					open action.
-- 12/01/2002	MF	7109		An Adjustment may be linked to a Site Control where the CONTROLID is 
--					'Adjustment '+ADJUSTMENT+' Event' (e.g. 'Adjustment Z Event').  This sitecontrol
--					will point to an EVENTNO from its COLINTEGER column.  The DAY and MONTH of the
--					associated Event will then be used to adjust the calculated DueDate to set its
--					Day and Month to that of associated Event.
-- 13/05/2002	MF	7659		Calculation of the due date was not correctly considering the status of
--					designated countries.
-- 17/05/2002	MF	7668		Revisit 7318 and use TEMPOPENACTION instead of OPENACTION in case the
--					Criteriano for the openaction has just been changed.
-- 09/08/2002	MF	7392		Allow specific Periods of time to be saved against Standing Instructions
--					so that they may be used in Due Date calculations.
-- 13/08/2002	MF	7392		(revisit) Change new period types from P1, P2, P3 to 1,2 & 3 respectively
-- 22/08/2002	MF	7392		(revisit) If no period defined then do not calculate the due date.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 23/10/2002	AB			Changed @SSQLString to @sSQLString for case sensitive databases (our IPDEV).
-- 06/11/2002	MF	8162		A SQL Error is being returned where an Event is being updated from another 
--					Event and the from Event has also been Policed and is reference by more than 
--					one Criteria.  This is because a subselect was returning multiple rows.
-- 11/11/2002	MF	8205		Calculation using entered Period had an introduced error where the Period Type
-- 					of the Governing Event was being tested instead of Event being calculated
-- 13/03/2002	MF	8537		Date comparison rules should not use Events that have not fully completed the
--					calculation phase
-- 11/06/2003	MF	8896		Before performing an Adjustment ensure that there is enough data available
--					so that the adjustment will not try and convert NULL to a datetime
-- 16 JUL 2003	MF	8987	11	Return a count of rows in STATE 'RX'
-- 17 JUL 2003	MF	9008	12	Case Event rows that have been flagged to save the due date are normally excluded
--					from various calculation restrictions such as checking Standing Instructions 
--					and checking the Date Comparison calculations.  This exlusion of rules should
--					only apply if the Due Date has previously been saved away and is not being 
--					calculated for the first time.
-- 24 JUL 2003	MF	8260	13	Get the PTADELAY from the EventControl table for Patent Term Adjustment calculations.
-- 19 Sep 2003  AB	8394		Add go to end of procedure so security is applied.
-- 01 Oct 2003	MF	9298	14	The OCCURREDFLAG was not being set correctly when Event from another Case
--					was used to update the Event.
-- 26 NOV 2003	MF	9490	15	Where a calculation is based on the Due Date of an Event, make certain that
--					the Event has not occurred.
-- 12 Feb 2004	MF	9696	16	Missing comma on UPDATE statement.
-- 27 Apr 2004	MF	9961	17	SQL Error on Adjustment of Due Date where the Due Date had not been calculated.
-- 24 Jun 2004	MF	9880	18	Increase the size of the ADJUSTMENT column in temporary table to nvarchar(4)
-- 06 Aug 2004	AB	8035	19	Add collate database_default to temp table definitions
-- 20 Oct 2004	MF	10572	20	Satisfied Event with a manually entered due date was not being reinstated. The
--					STATE should be set to "R" if the EventDate has been cleared out even if the new
--					due date is the same as what it previously was.
-- 03 Nov 2004	MF	10385	21	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 06 Dec 2004	MF	10770	22	Related Case Events used in update of an Event were being used even though
--					there was no appropriate Related Case in existence.
-- 13 Jan 2005	MF	10866	23	If the calculated Due Date is used to trigger another calculation where
--					a new Cycle is likely to be determined then set the STATE to "R" even 
--					if the calculated due date has not changed its value.  Previously the STATE 
--					would be set to "RX" if the DueDate had not changed so as not to trigger
--					any further calculations.
-- 24 Jan 2005	MF	10916	24	A Warning message was appearing in an aggregate statement.  Added the clause:
--					"Having max(NEWEVENTDATE) is not null" and the warning has now gone.
-- 14 Jul 2005	MF	11631	25	Do not set the State to RX if there is any Event that is to be calculated
--					from the Due Date of the Event just calculated.
-- 14 Jul 2005	MF	11631	26	Revisit. Use the NewCriteriaNo of the OpenAction in case it has changed.
-- 05 Sep 2005	MF	11716	27	When extending the due date forward automatically, it should extend from the 
--					originally calculated due date by looping through the calculations.  While this
--					is not as fast as assuming the extension is from the current system date, it 
--					avoids problems that occur when the Event is being recalculated.
-- 18 Jan 2006	MF	11971	28	If the CaseEvent row is being recalculated after having its EventDate cleared
--					out then do not reset the EventDate from itself if no related Case is found.
-- 24 Apr 2006	MF	12319	29	Allow adjustments determined from the Standing Instructions to be applied.
--					This provides for a form of dynamic adjustments.
-- 15 May 2006	MF	12315	30	New EventControl columns to allow CASENAME changes to occur on updat of Event.
-- 07 Jun 2006	MF	12417	31	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	32	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 05 Sep 2006	MF	13378	33	If a cyclic Event is to be calculated from a Related Case and that Event is
--					also cyclic then the calculation should default to using the same Cycle as
--					the Event trying to be calculated.  If the Related Case event is not cyclic
--					then Cycle 1 may be used.
-- 26 Sep 2006	MF	13441	34	The Adjustment that changes the Day and Month to that of another Event should
--					only move the Year forward 1 year if the adjusted Day and Month are earlier than
--					the original day and month.  This means a Due Date that is to be adjusted to the
--					same Day and Month will end up with exactly the same date rather than a date one
--					year later.
-- 19 Oct 2006	MF	13089	35	Revisit 13089.  Remove reference to DIRECTPAYFLAG from this release.
-- 11 Dec 2006	MF	13998	36	A calculation that considers the status of designated countries needs to allow
--					for the due date calculation to be on one Criteria but the country check rule
--					to be on a different Criteria.  This is particularly because the law updates
--					may be delivered without the designated country rules.
-- 24 May 2007	MF	14812	37	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	38	Reserve word [STATE]
-- 11 Apr 2008	MF	16234	39	The WHICHDUEDATE option was not consistently working where the Event belonged
--					to multiple Actions.
-- 18 Apr 2008	MF	16283	40	Performance improvement by using an interim table
-- 04 Sep 2008	MF	16888	41	Adjustment where the Day and Month is being adjusted to the day and month
--					of another Event is resulting in the calculated due date being cleared.
-- 23 Jan 2009	MF	17316	42	Adjustment of Due Date is only to be applied if the due date is able to be initially
--					calculated from the governing event.
-- 19 Feb 2009	MF	17345	43	If a calculated due date is the same as what it previously was calculated as however
--					the Event is included in a date comparison rule then change the STATE to 'R' to indicate
--					that a change has occurred rather than 'RX' which indicates no change occurred. This is
--					because date comparisons ignore Events that are in the process of being calculated so we 
--					need to retrigger those events that might be affected by this calculation.
-- 15 Oct 2009	MF	17773	44	An Event that may gets its date from a related Case is also now able to get an official number from the
--					same Case.
-- 26 Mar 2010	MF	18576	45	Do not calculate from an Event that is in the process of being calculated or deleted
--					by ensuring the State is not like 'C%' or 'D%'.
-- 23 Apr 2010	MF	18643	46	Revisit of 18576. When Events in the process of being calculated or deleted were excluded from
--					being considered in a calculation of another Event this caused a problem when the first event 
--					completed its calculation with the same result as its previous due date. This would cause the STATE
--					to be set to RX so that no other events were then triggered from it. Code has been changed now to 
--					acknowledge that if another event was originally being calculated from the first Event then we need
--					the STATE to be set to R so that other Events can then be triggered for recalculation.
-- 02 Dec 2010	MF	R10043	47	Allow other columns to be extracted from other OpenActions
-- 12 Jan 2011	MF	R10162	48	Event date inherited from Related Case is not always being cleared when parent is cleared.
-- 08 Aug 2011	MF	R11092	49	Track what the previous calculated Due Date for the Event was. If it was NULL and then it ends up being
--					NULL again then the STATE may be able to be set to RX to avoid retriggering other Events again. This will
--					improve performance and in some instances it could avoid the generation of a rule based loop.
-- 13 Sep 2011	MF	R11092	50	Revisit after failed test.
-- 17 Oct 2011	MF	R11415	51	Further improvement to code introduced with RFC11092	
-- 17 Oct 2011	MF	R11092	52	Track what the previous calculated Due Date for the Event was. If it was NULL and then it ends up being
--					NULL again then the STATE may be able to be set to RX to avoid retriggering other Events again. This will
--					improve performance and in some instances it could avoid the generation of a rule based loop.
-- 18 Oct 2011	MF	18798	53	Use OPTION(MAXDOP 1) to manually set the Maximum Degrees of Parallelism to a single processor. This will allow
--					the database to be set to use parallelism but those complex problem queries with this option will then
--					revert to no parallelism in order to get enhanced performance.
-- 16 Dec 2011	MF	R11717	53	Revisit R11092. Some Events not calculating as a result of a high loop count and a late opening Action. State is
--					being set to RX when eventduedate is being repeated calculated. Increase the number of time the repeating 
--					calculation is tolerated in order to give a subsequently opened Action the chance to calculate other Events.
-- 19 Dec 2011	MF	R11717	54	Revisit to increase the allowed loop count to 10.
-- 04 Jan 2012	MF	R11754	55	#TEMPCASEEVENT was incorrectly being left with STATE of 'I' when both the EVENTDATE and EVENTDUEDATE were set to null.
-- 12 Jan 2012	MF	R11717	56	Revisit to increase the allowed loop count to 20.
-- 06 Feb 2012	MF	S20336	57	After calculating the due date make sure all #TEMPCASEEVENT rows for the CASEID, EVENTNO and CYCLE are updated with the
--					newly calculated due date.  It is possible that multiple rows may exists if the Event is referenced by more than 1 Action.
-- 07 Mar 2012	MF	R12049	58	Where an Event is defined under multiple Actions it is possible for each of those Actions to indicate differently whether the
--					earliest or latest calculated due date should be used. The criteria that actually contains the due date calculation is the only
--					rule to be consider.
-- 13 Mar 2012	MF	R11717	59	Revisit to increase the allowed loop count to 20.
-- 05 Jun 2012	MF	S19025	60	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 16 Jul 2012	MF	S20741	61	Implementation of RFC10162 on CPA version. Event date inherited from Related Case is not always being cleared when parent is cleared.
-- 04 Sep 2012	MF	R12692	62	Recalculation of Event should also consider if date can come from RelatedCase where the related Case is not on the database.
-- 25 Mar 2013	MF	S21299	63	Extend the ADJUSTMENT capability to allow user defined adjustment amounts by specified period type.
-- 05 Jul 2013	vql	R13629	64	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 06 Jun 2013	MF	S21404	65	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 30 Aug 2016	MF	66054	66	When getting a date from a related case using the FROMRELATIONSHIP, it is possible for more than one related
--					case to exist.  Use the related case with earliest date.
-- 21 Dec 2016	MF	70250	67	Looping problem was being caused by previous change around FROMRELATIONSHIP. We were ignoring related Case where the EVENTDATE was null
--					however this is equally valid as clearing in the parent case can flow to the child case.
-- 09 Jan 2017	MF	70374	68	If an EventDate is being cleared out by parent Case then mark the [STATE] as 'R' so the clearing of EVENTDATE correctly flows through.
-- 15 Mar 2017	MF	70049	69	Allow Renewal Status to be separately specified to be updated by an Event.
-- 24 Jul 2017	MF	72034	70	If an Event is defined under multiple Actions, then the Action in which the Event is allowed to calculate (SUPPRESSCALCULATION=0)
--					is to take precedence over Action(s) where the calculation is suppressed (SUPPRESSCALCULATION=1).
-- 31 Jul 2017	MF	71946	70	When checking if Event can be calculated by a better Criteria, the Due Date Calculation must be for a calculation and not a Date Comparison.
-- 02 Oct 2018	MF	75167	71	A new hardcoded adjustment (~PA) can be used to add the number of days delay provided by the IPO as the Patent Term Adjustment and held
--					for the Case in the IPOPTA column.
-- 14 Nov 2018  AV	DR-45358 72	Date conversion errors when creating cases and opening names in Chinese DB
-- 22 Jan 2019	MF	DR-46611 73	Allow the Relative Cycle of All Cycles (5) to be used in the caculation of a due date.
-- 13 Jul2019	MF	DR-50297 74	In certain situations, the Next Workday was not being calculated correctly.

set nocount on

-- set ansi_warnings off

-- Create a temporary table to be used to store each due date calculation.  This is required due
-- to certain restrictions on an UPDATE statement.

	CREATE TABLE #TEMPCASEDUEDATE (
            CASEID               int		NOT NULL,
            EVENTNO              int		NOT NULL,
            CYCLE                smallint	NOT NULL,
            EVENTDUEDATE         datetime	NULL,
            SEQUENCENO           int		identity(1,1),
            ADJUSTMENT           nvarchar(4)	collate database_default NULL,
            MUSTEXIST            decimal(1,0)	NULL,
            WORKDAY              decimal(1,0)	NULL,
            MESSAGE2FLAG         decimal(1,0)	NULL,
            SUPPRESSREMINDERS    decimal(1,0)	NULL,
            OVERRIDELETTER       smallint	NULL,
            GOVERNINGEVENTNO     int		NULL,
            COUNTRYCODE          nvarchar(3)	collate database_default NULL,
            NEWCRITERIANO        int		NULL, 
            WHICHDUEDATE	 nchar(1)       collate database_default NULL,
            EXTENDPERIOD         smallint	NULL,	
            EXTENDPERIODTYPE     nchar(1)	collate database_default NULL,
            SAVEDUEDATE          smallint	NULL,
	    ADJUSTDAY		tinyint		NULL,
	    ADJUSTSTARTMONTH	tinyint		NULL,
	    ADJUSTDAYOFWEEK	tinyint		NULL,
	    ADJUSTTODATE	datetime	NULL
 
	)	

	CREATE INDEX XPKTEMPCASEDUEDATE ON #TEMPCASEDUEDATE
 	(
        	CASEID,
		EVENTNO,
		CYCLE,
		EVENTDUEDATE
 	)

	CREATE TABLE #TEMPDERIVEDCASEEVENTS (
		CASEID			int NOT NULL, 
		EVENTNO			int NOT NULL, 
		CYCLE			int NOT NULL, 
		CRITERIANO		int NOT NULL, 
		UNIQUEID		int NOT NULL, 
		CURRENTDUEDATE		datetime NULL,
		COUNTRYCODE		nvarchar(3) collate database_default NOT NULL	-- RFC11092
	)	

	CREATE INDEX XPKTEMPDERIVEDCASEEVENTS ON #TEMPDERIVEDCASEEVENTS
 	(
        	CASEID,
		EVENTNO,
		CYCLE,
		CURRENTDUEDATE
	)


DECLARE	@ErrorCode		int,
	@nRowCount		int,
	@nExtensionCount	int,
	@nCaseId		int,
	@dtNewDueDate		datetime,
	@sSQLString		nvarchar(max),
	@sSQLString1		nvarchar(4000),
	@sSQLString2		nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode         =0
Set @nRowCount         =0
Set @nExtensionCount   =1
Set @pnCountStateRX    =0

-- SQA 7129	Any events that have had their event date manually updated can have their STATE changed to
-- 		"R" so they will not recalculate

If   @ErrorCode=0
and  @pnCountStateC>0
Begin
	Set @sSQLString="
	Update	#TEMPCASEEVENT
	set	[STATE]='R'
	where 	[STATE]='C'
	and	DATEDUESAVED=1
 	and	NEWEVENTDUEDATE is not null"

	Exec @ErrorCode=sp_executesql @sSQLString
	Select	@pnCountStateC=@pnCountStateC-@@Rowcount,
		@pnCountStateR=@pnCountStateR+@@Rowcount
End

-- Any due date calculations that cannot be calculated with the existing Criteria are to be changed if
-- a better Criteria exists
If  @ErrorCode=0
and @pnCountStateC>0
Begin
	Set @sSQLString="
	update	#TEMPCASEEVENT
	set	CREATEDBYCRITERIA=EC.CRITERIANO,
		CREATEDBYACTION  =OA.ACTION,
		IMPORTANCELEVEL	 =EC.IMPORTANCELEVEL,
		WHICHDUEDATE	 =EC.WHICHDUEDATE,
		COMPAREBOOLEAN	 =EC.COMPAREBOOLEAN,
		CHECKCOUNTRYFLAG =EC.CHECKCOUNTRYFLAG,
		SAVEDUEDATE	 =EC.SAVEDUEDATE,
		STATUSCODE	 =EC.STATUSCODE,
		RENEWALSTATUS	 =EC.RENEWALSTATUS,
		SPECIALFUNCTION	 =EC.SPECIALFUNCTION,
		INITIALFEE	 =EC.INITIALFEE,
		PAYFEECODE	 =EC.PAYFEECODE,
		CREATEACTION	 =EC.CREATEACTION,
		STATUSDESC	 =EC.STATUSDESC,
		CLOSEACTION	 =EC.CLOSEACTION,
		RELATIVECYCLE	 =EC.RELATIVECYCLE,
		INSTRUCTIONTYPE	 =EC.INSTRUCTIONTYPE,
		FLAGNUMBER	 =EC.FLAGNUMBER,
		SETTHIRDPARTYON	 =EC.SETTHIRDPARTYON,
		ESTIMATEFLAG	 =EC.ESTIMATEFLAG,
		PTADELAY	 =EC.PTADELAY,
		SETTHIRDPARTYOFF =EC.SETTHIRDPARTYOFF,
		CHANGENAMETYPE	 =EC.CHANGENAMETYPE, 
		COPYFROMNAMETYPE =EC.COPYFROMNAMETYPE, 
		COPYTONAMETYPE   =EC.COPYTONAMETYPE, 
		DELCOPYFROMNAME  =EC.DELCOPYFROMNAME,
		RECALCEVENTDATE  =EC.RECALCEVENTDATE,
		SUPPRESSCALCULATION=EC.SUPPRESSCALCULATION
	from	#TEMPCASEEVENT T
	join	#TEMPOPENACTION OA	on (OA.CASEID=T.CASEID
					and OA.POLICEEVENTS=1)
	join 	DUEDATECALC DD		on (DD.CRITERIANO=OA.CRITERIANO
					and DD.EVENTNO   =T.EVENTNO
					and DD.COMPARISON is null)
	join	EVENTCONTROL EC		on (EC.CRITERIANO=OA.CRITERIANO
					and EC.EVENTNO   =T.EVENTNO)
	where T.[STATE]='C'
	-- NOTE : Not Exists is performing faster (in this instance) than using
	--	  a LEFT JOIN and testing for NULL
	and not exists
	(select 1 from DUEDATECALC DD1
	 where DD1.CRITERIANO=T.CREATEDBYCRITERIA
	 and DD1.EVENTNO=T.EVENTNO
	 and DD1.COMPARISON is null)"

	Exec @ErrorCode=sp_executesql @sSQLString

	-- SQA13998
	-- If the Event being calculated exists under a different Open Action then where
	-- characteristics exists in the alternate Criteria that do not exist in the 
	-- calculating Criteria then merge in the additional characteristics
	If  @ErrorCode=0
	Begin
		Set @sSQLString="
		update	#TEMPCASEEVENT
		set	CHECKCOUNTRYFLAG =CASE WHEN(T.CHECKCOUNTRYFLAG is NOT NULL) THEN T.CHECKCOUNTRYFLAG ELSE EC.CHECKCOUNTRYFLAG END,
			INITIALFEE	 =CASE WHEN(T.INITIALFEE       is NOT NULL) THEN T.INITIALFEE       ELSE EC.INITIALFEE       END,
			PAYFEECODE	 =CASE WHEN(T.PAYFEECODE       is NOT NULL) THEN T.PAYFEECODE       ELSE EC.PAYFEECODE       END,
			CREATEACTION	 =CASE WHEN(T.CREATEACTION     is NOT NULL) THEN T.CREATEACTION     ELSE EC.CREATEACTION     END,
			CLOSEACTION	 =CASE WHEN(T.CLOSEACTION      is NOT NULL) THEN T.CLOSEACTION      ELSE EC.CLOSEACTION      END,
			SETTHIRDPARTYON	 =CASE WHEN(T.SETTHIRDPARTYON  is NOT NULL) THEN T.SETTHIRDPARTYON  ELSE EC.SETTHIRDPARTYON  END,
			ESTIMATEFLAG	 =CASE WHEN(T.ESTIMATEFLAG     is NOT NULL) THEN T.ESTIMATEFLAG     ELSE EC.ESTIMATEFLAG     END,
			PTADELAY	 =CASE WHEN(T.PTADELAY         is NOT NULL) THEN T.PTADELAY         ELSE EC.PTADELAY         END,
			SETTHIRDPARTYOFF =CASE WHEN(T.SETTHIRDPARTYOFF is NOT NULL) THEN T.SETTHIRDPARTYOFF ELSE EC.SETTHIRDPARTYOFF    END,

			--RFC10043 allow other columns to be extracted from other OpenActions
		        SAVEDUEDATE	 =CASE WHEN(T.SAVEDUEDATE      > 0        ) THEN T.SAVEDUEDATE      ELSE EC.SAVEDUEDATE         END,
		        EXTENDPERIOD	 =CASE WHEN(T.EXTENDPERIOD     is NOT NULL) THEN T.EXTENDPERIOD     ELSE EC.EXTENDPERIOD        END,
		        EXTENDPERIODTYPE =CASE WHEN(T.EXTENDPERIODTYPE is NOT NULL) THEN T.EXTENDPERIODTYPE ELSE EC.EXTENDPERIODTYPE    END,
		        INITIALFEE2	 =CASE WHEN(T.INITIALFEE2      is NOT NULL) THEN T.INITIALFEE2      ELSE EC.INITIALFEE2         END,
		        PAYFEECODE2	 =CASE WHEN(T.PAYFEECODE2      is NOT NULL) THEN T.PAYFEECODE2      ELSE EC.PAYFEECODE2         END,
		        ESTIMATEFLAG2	 =CASE WHEN(T.ESTIMATEFLAG2    is NOT NULL) THEN T.ESTIMATEFLAG2    ELSE EC.ESTIMATEFLAG2       END,
		        CHANGENAMETYPE	 =CASE WHEN(T.CHANGENAMETYPE   is NOT NULL) THEN T.CHANGENAMETYPE   ELSE EC.CHANGENAMETYPE      END,
		        COPYFROMNAMETYPE =CASE WHEN(T.COPYFROMNAMETYPE is NOT NULL) THEN T.COPYFROMNAMETYPE ELSE EC.COPYFROMNAMETYPE    END,
		        COPYTONAMETYPE	 =CASE WHEN(T.COPYTONAMETYPE   is NOT NULL) THEN T.COPYTONAMETYPE   ELSE EC.COPYTONAMETYPE      END,
		        DELCOPYFROMNAME	 =CASE WHEN(T.DELCOPYFROMNAME  is NOT NULL) THEN T.DELCOPYFROMNAME  ELSE EC.DELCOPYFROMNAME     END,
		        DIRECTPAYFLAG	 =CASE WHEN(T.DIRECTPAYFLAG    is NOT NULL) THEN T.DIRECTPAYFLAG    ELSE EC.DIRECTPAYFLAG       END,
		        DIRECTPAYFLAG2	 =CASE WHEN(T.DIRECTPAYFLAG2   is NOT NULL) THEN T.DIRECTPAYFLAG2   ELSE EC.DIRECTPAYFLAG2      END,
		        RESPNAMENO	 =CASE WHEN(T.RESPNAMENO       is NOT NULL) THEN T.RESPNAMENO       ELSE EC.DUEDATERESPNAMENO   END,
		        RESPNAMETYPE	 =CASE WHEN(T.RESPNAMETYPE     is NOT NULL) THEN T.RESPNAMETYPE     ELSE EC.DUEDATERESPNAMETYPE END,
		        LOADNUMBERTYPE	 =CASE WHEN(T.LOADNUMBERTYPE   is NOT NULL) THEN T.LOADNUMBERTYPE   ELSE EC.LOADNUMBERTYPE      END,
		        RECALCEVENTDATE	   =CASE WHEN(T.RECALCEVENTDATE    =1)      THEN T.RECALCEVENTDATE     ELSE coalesce(EC.RECALCEVENTDATE,     T.RECALCEVENTDATE,    0) END,
		        SUPPRESSCALCULATION=CASE WHEN(T.SUPPRESSCALCULATION=1 OR DD.CRITERIANO is not NULL)
										    THEN T.SUPPRESSCALCULATION ELSE coalesce(EC.SUPPRESSCALCULATION, T.SUPPRESSCALCULATION,0) END

		from	#TEMPCASEEVENT T
		left join (select distinct CRITERIANO, EVENTNO
			   from DUEDATECALC
			   where OPERATOR is not null) DD
						on (DD.CRITERIANO=T.CREATEDBYCRITERIA
						and DD.EVENTNO=T.EVENTNO)
		join	#TEMPOPENACTION OA	on (OA.CASEID=T.CASEID
						and OA.ACTION<>T.CREATEDBYACTION
						and OA.POLICEEVENTS=1)
		join	EVENTCONTROL EC		on (EC.CRITERIANO=OA.CRITERIANO
						and EC.EVENTNO   =T.EVENTNO)
		where 	T.[STATE]='C'
		and ( ( EC.CHECKCOUNTRYFLAG is not null and T.CHECKCOUNTRYFLAG is null)
		  OR  ( EC.INITIALFEE	    is not null and T.INITIALFEE       is null)
		  OR  ( EC.PAYFEECODE	    is not null and T.PAYFEECODE       is null)
		  OR  ( EC.CREATEACTION	    is not null and T.CREATEACTION     is null)
		  OR  ( EC.CLOSEACTION	    is not null and T.CLOSEACTION      is null)
		  OR  ( EC.SETTHIRDPARTYON  is not null and T.SETTHIRDPARTYON  is null)
		  OR  ( EC.ESTIMATEFLAG	    is not null and T.ESTIMATEFLAG     is null)
		  OR  ( EC.PTADELAY	    is not null and T.PTADELAY	       is null)
		  OR  ( EC.SETTHIRDPARTYOFF is not null and T.SETTHIRDPARTYOFF is null)

		  --RFC10043 allow other columns to be extracted from other OpenActions
		  OR  ( EC.SAVEDUEDATE         >0          and T.SAVEDUEDATE      = 0    )
		  OR  ( EC.EXTENDPERIOD        is not null and T.EXTENDPERIOD     is NULL)
		  OR  ( EC.EXTENDPERIODTYPE    is not null and T.EXTENDPERIODTYPE is NULL)
		  OR  ( EC.INITIALFEE2         is not null and T.INITIALFEE2      is NULL)
		  OR  ( EC.PAYFEECODE2         is not null and T.PAYFEECODE2      is NULL)
		  OR  ( EC.ESTIMATEFLAG2       is not null and T.ESTIMATEFLAG2    is NULL)
		  OR  ( EC.CHANGENAMETYPE      is not null and T.CHANGENAMETYPE   is NULL)
		  OR  ( EC.COPYFROMNAMETYPE    is not null and T.COPYFROMNAMETYPE is NULL)
		  OR  ( EC.COPYTONAMETYPE      is not null and T.COPYTONAMETYPE   is NULL)
		  OR  ( EC.DELCOPYFROMNAME     is not null and T.DELCOPYFROMNAME  is NULL)
		  OR  ( EC.DIRECTPAYFLAG       is not null and T.DIRECTPAYFLAG    is NULL)
		  OR  ( EC.DIRECTPAYFLAG2      is not null and T.DIRECTPAYFLAG2   is NULL)
		  OR  ( EC.DUEDATERESPNAMENO   is not null and T.RESPNAMENO       is NULL)
		  OR  ( EC.DUEDATERESPNAMETYPE is not null and T.RESPNAMETYPE     is NULL)
		  OR  ( EC.LOADNUMBERTYPE      is not null and T.LOADNUMBERTYPE   is NULL) 
		  OR  ( EC.RECALCEVENTDATE     = 1         and isnull(T.RECALCEVENTDATE,    0)=0)
		  OR  ( EC.SUPPRESSCALCULATION = 1         and isnull(T.SUPPRESSCALCULATION,0)=0))"
	
		Exec @ErrorCode=sp_executesql @sSQLString
	End
	
	-- Any due date calculations that do not have the required Standing Instruction are 
	-- to be flagged to not calculate
	
	If   @ErrorCode=0
	Begin
		Set @sSQLString="
		Update	#TEMPCASEEVENT
		set	[STATE]='R',
			NEWEVENTDUEDATE=null
		where [STATE] like 'C%'
		and   isnull(DATEDUESAVED,0)=0
		and   INSTRUCTIONTYPE is not null
		and   FLAGNUMBER      is not null
		and not exists
		(select * from #TEMPCASEINSTRUCTIONS CI
		 join INSTRUCTIONFLAG F	on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE
					and F.FLAGNUMBER     =#TEMPCASEEVENT.FLAGNUMBER)
		 where CI.CASEID         =#TEMPCASEEVENT.CASEID
		 and   CI.INSTRUCTIONTYPE=#TEMPCASEEVENT.INSTRUCTIONTYPE)"
	
		Exec @ErrorCode=sp_executesql @sSQLString
		Select	@pnCountStateC=@pnCountStateC-@@Rowcount,
			@pnCountStateR=@pnCountStateR+@@Rowcount
	End
	
	-- Any Events that are flagged to suppress the calculation
	-- are to be flagged to not calculate
	
	If   @ErrorCode=0
	Begin
		Set @sSQLString="
		Update	#TEMPCASEEVENT
		set	[STATE]='R',
			NEWEVENTDUEDATE=null
		where [STATE] like 'C%'
		and   isnull(DATEDUESAVED,0)=0
		and   SUPPRESSCALCULATION=1"
	
		Exec @ErrorCode=sp_executesql @sSQLString
		Select	@pnCountStateC=@pnCountStateC-@@Rowcount,
			@pnCountStateR=@pnCountStateR+@@Rowcount
	End
End

------------------------------------------------------------------------------------------------------------
-- From State    | Action Performed                                                       | Change to State |
--===============|========================================================================|=================|
-- Calculate (C) | 1. Update the Event from a related case if it exists.                  | Reminder (I)    |
--               | 2. Calculate the due date of the Event. If the Event is not calculated | Reminder (R)    |
--               |    it will be set to NULL which may result in it being deleted.        |                 |
------------------------------------------------------------------------------------------------------------

-- Rows that have the UPDATEFROMPARENT flag set are to be updated from the Related Case Event.

If  @ErrorCode=0
and @nCountParentUpdate>0
and @pnCountStateC+@pnCountStateR>0
Begin
	Set @sSQLString="
	Update	#TEMPCASEEVENT
	Set	@pnCountStateC	=@pnCountStateC-CASE WHEN([STATE]='C' and PARENTEVENTDATE is not null) THEN 1 ELSE 0 END,
		@pnCountStateR	=@pnCountStateR-CASE WHEN([STATE]='R' and PARENTEVENTDATE is not null) THEN 1 ELSE 0 END,
		@pnCountStateI	=@pnCountStateI+CASE WHEN(PARENTEVENTDATE is not null) THEN 1 ELSE 0 END,
		@nCountParentUpdate=@nCountParentUpdate-1,
		NEWEVENTDATE	=PARENTEVENTDATE,
		[STATE]		=CASE WHEN(PARENTEVENTDATE is not null) THEN 'I' ELSE T.[STATE] END,
		PARENTEVENTDATE	=null, 
		UPDATEFROMPARENT=0,
		OCCURREDFLAG	=CASE WHEN(PARENTEVENTDATE is not null) THEN 1 ELSE 0 END
	from	#TEMPCASEEVENT T
	where	UPDATEFROMPARENT=1
	and     T.[STATE] in ('C','R')"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCountStateC	int	OUTPUT,
					  @pnCountStateR	int	OUTPUT,
					  @pnCountStateI	int	OUTPUT,
					  @nCountParentUpdate	int	OUTPUT',
					  @pnCountStateC		OUTPUT,
					  @pnCountStateR		OUTPUT,
					  @pnCountStateI		OUTPUT,
					  @nCountParentUpdate		OUTPUT
End

-- Before attempting to calculate the due date first attempt to update the Event if it can be loaded from 
-- another Event and set the STATE to 'I' if NEWEVENTDATE is set or 'R' if NEWEVENTDATE is cleared.

If  @ErrorCode=0
and @pnCountStateC>0
Begin

	Set @sSQLString="
	update TC1

	-- If no Event exists to update	the Case Event then do not change the current value of	
	-- State otherwise change it to	'I'.				
	set 
	-- Update the event with the Event from TEMPCASEEVENT if it has occurred.
	NEWEVENTDATE	= CASE WHEN(TC.CASEID  is not null) THEN TC.NEWEVENTDATE 
			       WHEN(CE.CASEID  is not null) THEN CE.EVENTDATE
			       WHEN(CR.EVENTNO is not null) THEN R.PRIORITYDATE		-- RFC12692
			  END,	-- RFC10162
	ADJUSTMENT	= E.ADJUSTMENT,
	OCCURREDFLAG	= CASE WHEN(TC.CASEID  is not null and TC.NEWEVENTDATE is not null)                                 THEN 1
			       WHEN(TC.CASEID  is null     and CE.CASEID       is not null and CE.EVENTDATE is not null)    THEN 1
			       WHEN(CE.CASEID  is null     and CR.EVENTNO      is not null and R.PRIORITYDATE  is not null) THEN 1
			       ELSE 0
			  END,

	[STATE]		= CASE WHEN(TC.CASEID  is not null and TC.NEWEVENTDATE is not null)                                 THEN 'I'
			       WHEN(TC.CASEID  is null     and CE.CASEID       is not null and CE.EVENTDATE is not null)    THEN 'I'
			       WHEN(CE.CASEID  is null     and CR.EVENTNO      is not null and R.PRIORITYDATE  is not null) THEN 'I'
			       ELSE 'R'
			  END,
	LOADNUMBERTYPE	= E.LOADNUMBERTYPE,
	PARENTNUMBER	= O.OFFICIALNUMBER,
	
	@pnCountStateI	= @pnCountStateI + CASE WHEN(TC.CASEID  is not null and TC.NEWEVENTDATE is not null)                                 THEN 1
					        WHEN(TC.CASEID  is null     and CE.CASEID       is not null and CE.EVENTDATE is not null)    THEN 1
					        WHEN(CE.CASEID  is null     and CR.EVENTNO      is not null and R.PRIORITYDATE  is not null) THEN 1
					        ELSE 0
					   END,
	@pnCountStateR	= @pnCountStateR + CASE WHEN(TC.CASEID  is not null and TC.NEWEVENTDATE is not null)                                 THEN 0
					        WHEN(TC.CASEID  is null     and CE.CASEID       is not null and CE.EVENTDATE is not null)    THEN 0
					        WHEN(CE.CASEID  is null     and CR.EVENTNO      is not null and R.PRIORITYDATE  is not null) THEN 0
					        ELSE 1
					   END
	from		#TEMPCASEEVENT TC1
	join 		#TEMPOPENACTION T
					on (T.CASEID=TC1.CASEID)
	join		CASES C 	on (C.CASEID=TC1.CASEID)
	join		EVENTCONTROL E	on (E.CRITERIANO=T.NEWCRITERIANO and E.EVENTNO=TC1.EVENTNO)
	left join 	EVENTS EV	on (EV.EVENTNO=E.UPDATEFROMEVENT)
	left join	RELATEDCASE  R	on (R.CASEID=TC1.CASEID 
					and R.RELATIONSHIP=E.FROMRELATIONSHIP
					and R.RELATIONSHIPNO=(	select	convert(int,
									substring(
									min(
									    convert(nvarchar(8), coalesce(TC.NEWEVENTDATE,CE.EVENTDATE, R1.PRIORITYDATE), 112) -- Choose the EARLIEST date
									  + convert(nvarchar(11), R1.RELATIONSHIPNO)
									    ), 9,11))
								from RELATEDCASE R1
								left join CASEEVENT CE	on (CE.CASEID =R1.RELATEDCASEID
											and CE.EVENTNO=E.UPDATEFROMEVENT
											and CE.CYCLE  =CASE WHEN(EV.NUMCYCLESALLOWED>1) THEN TC1.CYCLE ELSE 1 END)
								left join #TEMPCASEEVENT TC	
											on (TC.CASEID =R1.RELATEDCASEID
											and TC.EVENTNO=E.UPDATEFROMEVENT
											and TC.CYCLE  =CASE WHEN(EV.NUMCYCLESALLOWED>1) THEN TC1.CYCLE ELSE 1 END)
								where R1.CASEID=R.CASEID
								and   R1.RELATIONSHIP=R.RELATIONSHIP
								and   coalesce(TC.NEWEVENTDATE, CE.EVENTDATE, R1.PRIORITYDATE) is not null)
								)
	left join	CASEEVENT CE	on (CE.EVENTNO=E.UPDATEFROMEVENT
					and CE.CYCLE = CASE WHEN(EV.NUMCYCLESALLOWED>1) THEN TC1.CYCLE ELSE 1 END
					and CE.CASEID= 	CASE WHEN (E.FROMANCESTOR=1) 		   THEN C.PREDECESSORID
							     WHEN (E.FROMRELATIONSHIP is not null) THEN R.RELATEDCASEID
											/***	   ELSE TC1.CASEID  ***/ --SQA11971
							END)
	left join	CASERELATION CR	on (CR.RELATIONSHIP=E.FROMRELATIONSHIP	-- RFC12692
					and CR.EVENTNO     =E.EVENTNO		-- The To Event for the Relationship matches the Event to be calculated
					and E.UPDATEFROMEVENT is not null
					and R.RELATEDCASEID is null)		-- indicates related Case is not in database
	left join	OFFICIALNUMBERS O
					on (O.NUMBERTYPE=E.LOADNUMBERTYPE
					and O.ISCURRENT=1
					and O.CASEID= 	CASE WHEN (E.FROMANCESTOR=1) 		   THEN C.PREDECESSORID
							     WHEN (E.FROMRELATIONSHIP is not null) THEN R.RELATEDCASEID
							END)
	left join      (select min(NEWEVENTDATE) as NEWEVENTDATE, CASEID, EVENTNO, CYCLE
			from #TEMPCASEEVENT
			group by CASEID, EVENTNO, CYCLE) TC
					on (TC.EVENTNO=E.UPDATEFROMEVENT
					and TC.CYCLE  = CASE WHEN(EV.NUMCYCLESALLOWED>1) THEN TC1.CYCLE ELSE 1 END
					and TC.CASEID =	CASE WHEN (E.FROMANCESTOR=1) 		   THEN C.PREDECESSORID
							     WHEN (E.FROMRELATIONSHIP is not null) THEN R.RELATEDCASEID
											/***	   ELSE TC1.CASEID  ***/ --SQA11971
							END)
	left join	#TEMPCASEINSTRUCTIONS CI
					on (CI.CASEID=T.CASEID and CI.INSTRUCTIONTYPE=E.INSTRUCTIONTYPE)
	left join	INSTRUCTIONFLAG F
					on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE and F.FLAGNUMBER=E.FLAGNUMBER)
		-- Only process rows that are to be calculated. STATE='C'	
		-- and that can be updated from another Event.		
	Where	TC1.[STATE] ='C'
	and	TC1.NEWEVENTDATE is null
	and	E.UPDATEFROMEVENT is not null
	and    (TC.CASEID is not null OR (TC.CASEID is null and CE.CASEID is not null) OR (CR.EVENTNO is not null and R.PRIORITYDATE is not null)) -- RFC12692

		-- if there is a FLAGNUMBER then it must match the Flagnumber of the standing instruction
		-- against the Case.
	and	(E.FLAGNUMBER IS NULL OR E.FLAGNUMBER=F.FLAGNUMBER)"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCountStateI	int	OUTPUT,
					  @pnCountStateR	int	OUTPUT',
					  @pnCountStateI=@pnCountStateI	OUTPUT,
					  @pnCountStateR=@pnCountStateR	OUTPUT
	
	Select	@pnCountStateC=@pnCountStateC-@@Rowcount
End

-- Update any of the Case Event rows just inserted that need adjusting. 

If  @ErrorCode=0
and @pnCountStateI>0
Begin
	Set @sSQLString="
	update	#TEMPCASEEVENT
	set ADJUSTMENT= null,
	    NEWEVENTDATE = 
		CASE 	
			WHEN(A.PERIODTYPE='D') Then dateadd( day,   A.ADJUSTAMOUNT, NEWEVENTDATE )
			WHEN(A.PERIODTYPE='W') Then dateadd( week,  A.ADJUSTAMOUNT, NEWEVENTDATE )
			WHEN(A.PERIODTYPE='M') Then dateadd( month, A.ADJUSTAMOUNT, NEWEVENTDATE )
			WHEN(A.PERIODTYPE='Y') Then dateadd( year,  A.ADJUSTAMOUNT, NEWEVENTDATE )
			WHEN(A.ADJUSTMENT='E') Then dateadd( day, -1, cast(cast(MONTH (dateadd (month, 1, NEWEVENTDATE)) as nvarchar)+'/1/'+ cast(YEAR (dateadd (month, 1, NEWEVENTDATE))as nvarchar) as datetime))
			WHEN(A.ADJUSTMENT='~PA')
					       Then dateadd( day,   coalesce(C.IPOPTA,0), NEWEVENTDATE )
					       Else cast(cast( isnull (A.ADJUSTMONTH, MONTH (NEWEVENTDATE)) as nvarchar)+'/'+cast( isnull (A.ADJUSTDAY, DAY (NEWEVENTDATE)) as nvarchar)+'/'+ cast( isnull (A.ADJUSTYEAR, YEAR (NEWEVENTDATE)) as nvarchar) as datetime)
		END
	from 	#TEMPCASEEVENT T
	join	ADJUSTMENT A on A.ADJUSTMENT=T.ADJUSTMENT
	join	CASES C      on C.CASEID=T.CASEID
	where 	T.NEWEVENTDATE is not null
	and	T.[STATE]='I'"

	Exec @ErrorCode=sp_executesql @sSQLString
End

--If the Event has not already been updated from a related Event then continue with the Due Date calculation.
--The first step in the calculation is to calculate Every possible Due Date.  A temporary table is used to do this.
--TEMPCASEEVENT rows that have been flagged for deletion will not be used in the calculation.
--Where a due date is not able to be calculated a row will still be returned.  This will allow all of 
--the rows for the same CASEID, EVENTNO, CYCLE to be deleted if a calculation that MUST EXIST fails.

If @ErrorCode=0
and @pnCountStateC>0
Begin
	-- For performance reasons the following derived table has been pulled out into an 
	-- explicit temp table.  The table variable is then referenced from the following query.
	Set @sSQLString="
	Insert into #TEMPDERIVEDCASEEVENTS (CASEID, EVENTNO, CYCLE, CRITERIANO, UNIQUEID, CURRENTDUEDATE, COUNTRYCODE)
	select	T.CASEID, T.EVENTNO, T.CYCLE, T.CREATEDBYCRITERIA, T.UNIQUEID,
		CASE WHEN(T.LOOPCOUNT=0) THEN T.OLDEVENTDUEDATE ELSE T.NEWEVENTDUEDATE END,
		max(isnull(DD1.COUNTRYCODE,'000')) as COUNTRYCODE
	from #TEMPCASEEVENT T
	join DUEDATECALC DD1	on (DD1.CRITERIANO=T.CREATEDBYCRITERIA
				and DD1.EVENTNO=T.EVENTNO)
	where DD1.COMPARISON is null
	and (DD1.COUNTRYCODE=T.COUNTRYCODE or DD1.COUNTRYCODE is null)
	and T.[STATE] = 'C'
	and isnull(T.DATEDUESAVED,0)=0 
	group by T.CASEID, T.EVENTNO, T.CYCLE, T.CREATEDBYCRITERIA, T.UNIQUEID, CASE WHEN(T.LOOPCOUNT=0) THEN T.OLDEVENTDUEDATE ELSE T.NEWEVENTDUEDATE END"

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @nRowCount=@@rowcount
End

If  @ErrorCode=0
and @pnCountStateC>0
and @nRowCount>0
Begin
	Exec("
	Insert into #TEMPCASEDUEDATE (	CASEID, EVENTNO, CYCLE, ADJUSTMENT, ADJUSTDAY, ADJUSTSTARTMONTH, ADJUSTDAYOFWEEK,
					ADJUSTTODATE, MUSTEXIST, WORKDAY, MESSAGE2FLAG, SUPPRESSREMINDERS,
					OVERRIDELETTER, GOVERNINGEVENTNO,  COUNTRYCODE, EVENTDUEDATE, 
					NEWCRITERIANO, WHICHDUEDATE, EXTENDPERIOD, EXTENDPERIODTYPE, SAVEDUEDATE )
	
	Select	distinct
		T.CASEID, T.EVENTNO, T.CYCLE,
		CASE WHEN(DD.ADJUSTMENT='~0') THEN CI.ADJUSTMENT       ELSE DD.ADJUSTMENT END,
		CASE WHEN(DD.ADJUSTMENT='~0') THEN CI.ADJUSTDAY        ELSE NULL          END, 
		CASE WHEN(DD.ADJUSTMENT='~0') THEN CI.ADJUSTSTARTMONTH ELSE NULL          END, 
		CASE WHEN(DD.ADJUSTMENT='~0') THEN CI.ADJUSTDAYOFWEEK  ELSE NULL          END, 
		CASE WHEN(DD.ADJUSTMENT='~0') THEN CI.ADJUSTTODATE     ELSE NULL          END, 
		DD.MUSTEXIST, DD.WORKDAY, isnull(DD.MESSAGE2FLAG,0),
		isnull(DD.SUPPRESSREMINDERS,0), DD.OVERRIDELETTER, DD.FROMEVENT, T.COUNTRYCODE, 
										-- If the TEMPCASEEVENT row 	
										-- exists then it will be used  
										-- in preference to CASEEVENT	
		CASE WHEN (T1.CASEID is not null) THEN
										-- If the TEMPCASEEVENT row is 	
										-- flagged for deletion then it 
										-- will not be used in the calculation	
			CASE WHEN(T1.[STATE] like 'D%') 
				THEN	NULL
				ELSE	CASE
										-- EVENTDATEFLAG of 1 indicates	
										-- the EVENTDATE is to be used  
										-- in the calculation.	 	
						WHEN(DD.EVENTDATEFLAG=1)
							THEN CASE DD.PERIODTYPE
								WHEN('D') THEN dateadd(  day, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE) 
								WHEN('W') THEN dateadd( week, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
								WHEN('M') THEN dateadd(month, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
								WHEN('Y') THEN dateadd( year, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)	
								WHEN('1') THEN CASE CI.PERIOD1TYPE
										WHEN('D') THEN dateadd(  day, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('W') THEN dateadd( week, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('M') THEN dateadd(month, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('Y') THEN dateadd( year, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
											  ELSE NULL
								       	       END
								WHEN('2') THEN CASE CI.PERIOD2TYPE
										WHEN('D') THEN dateadd(  day, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('W') THEN dateadd( week, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('M') THEN dateadd(month, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('Y') THEN dateadd( year, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
											  ELSE NULL
								       	       END
								WHEN('3') THEN CASE CI.PERIOD3TYPE
										WHEN('D') THEN dateadd(  day, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('W') THEN dateadd( week, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('M') THEN dateadd(month, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('Y') THEN dateadd( year, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
											  ELSE NULL
								       	       END
										-- If the PERIODTYPE is none of	
										-- the above then it will be 'E'
										-- which indicates that the 	
										-- PeriodType to use will have 	
										-- entered against the Event  	
										-- being calculated along with	
										-- the deadline amount.	 	
									  ELSE CASE T.PERIODTYPE
										-- The OPERATOR can be 'S' to 	
										-- indicate that the DEADLINE is
										-- to be subtracted rather than	
										-- added.			
										WHEN('D') THEN dateadd(  day, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('W') THEN dateadd( week, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('M') THEN dateadd(month, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
										WHEN('Y') THEN dateadd( year, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDATE)
								       	       END
							     END
										-- EVENTDATEFLAG of 2 indicates	
										-- the EVENTDUEDATE is to be	
										-- used in the calculation.	
						WHEN(DD.EVENTDATEFLAG=2 AND T1.OCCURREDFLAG=0)
							THEN CASE DD.PERIODTYPE
								WHEN('D') THEN dateadd(  day, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE) 
								WHEN('W') THEN dateadd( week, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
								WHEN('M') THEN dateadd(month, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
								WHEN('Y') THEN dateadd( year, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
								WHEN('1') THEN CASE CI.PERIOD1TYPE
										WHEN('D') THEN dateadd(  day, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('W') THEN dateadd( week, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('M') THEN dateadd(month, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('Y') THEN dateadd( year, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
											  ELSE NULL
								       	       END
								WHEN('2') THEN CASE CI.PERIOD2TYPE
										WHEN('D') THEN dateadd(  day, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('W') THEN dateadd( week, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('M') THEN dateadd(month, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('Y') THEN dateadd( year, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
											  ELSE NULL
								       	       END
								WHEN('3') THEN CASE CI.PERIOD3TYPE
										WHEN('D') THEN dateadd(  day, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('W') THEN dateadd( week, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('M') THEN dateadd(month, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('Y') THEN dateadd( year, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
											  ELSE NULL
								       	       END
									  ELSE CASE T.PERIODTYPE
										WHEN('D') THEN dateadd(  day, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('W') THEN dateadd( week, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('M') THEN dateadd(month, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
										WHEN('Y') THEN dateadd( year, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), T1.NEWEVENTDUEDATE)
								       	       END
							     END
										-- EVENTDATEFLAG of 3 indicates	
										-- the EVENTDATE is to be used  
										-- if it exists otherwise the 	
										-- EVENTDUEDATE will be used in	
										-- the calculation.
						WHEN(DD.EVENTDATEFLAG=3)
							THEN CASE DD.PERIODTYPE
								WHEN('D') THEN dateadd(  day, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) ) 
								WHEN('W') THEN dateadd( week, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
								WHEN('M') THEN dateadd(month, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
								WHEN('Y') THEN dateadd( year, DD.DEADLINEPERIOD * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
								WHEN('1') THEN CASE CI.PERIOD1TYPE
										WHEN('D') THEN dateadd(  day, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('W') THEN dateadd( week, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('M') THEN dateadd(month, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('Y') THEN dateadd( year, isnull(CI.PERIOD1AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
											  ELSE NULL
								       	       END
								WHEN('2') THEN CASE CI.PERIOD2TYPE
										WHEN('D') THEN dateadd(  day, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('W') THEN dateadd( week, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('M') THEN dateadd(month, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('Y') THEN dateadd( year, isnull(CI.PERIOD2AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
											  ELSE NULL
								       	       END
								WHEN('3') THEN CASE CI.PERIOD3TYPE
										WHEN('D') THEN dateadd(  day, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('W') THEN dateadd( week, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('M') THEN dateadd(month, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('Y') THEN dateadd( year, isnull(CI.PERIOD3AMT,0) * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
											  ELSE NULL
								       	       END
									  ELSE CASE T.PERIODTYPE
										WHEN('D') THEN dateadd(  day, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('W') THEN dateadd( week, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('M') THEN dateadd(month, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
										WHEN('Y') THEN dateadd( year, T.ENTEREDDEADLINE * (CASE DD.OPERATOR WHEN('S') THEN -1 ELSE 1 END), isnull(T1.NEWEVENTDATE, T1.NEWEVENTDUEDATE) )
								       	       END
							     END
					END 
			END
		END,
		T.CREATEDBYCRITERIA, T.WHICHDUEDATE, T.EXTENDPERIOD, T.EXTENDPERIODTYPE, T.SAVEDUEDATE
	from #TEMPDERIVEDCASEEVENTS TX
	join DUEDATECALC DD	on (DD.CRITERIANO=TX.CRITERIANO
				and DD.EVENTNO=TX.EVENTNO
				and DD.COMPARISON is null
				and isnull(DD.COUNTRYCODE,'000')=TX.COUNTRYCODE
			        and DD.CYCLENUMBER=(	select max(CYCLENUMBER) 
							from DUEDATECALC DD1 
							where DD1.CRITERIANO=DD.CRITERIANO 
							and DD1.EVENTNO=DD.EVENTNO 
							and DD1.COMPARISON is null 
							and isnull(DD1.COUNTRYCODE,'000')=TX.COUNTRYCODE
							and DD1.CYCLENUMBER<=TX.CYCLE)
				     )
	join #TEMPCASEEVENT T	on (T.CASEID=TX.CASEID
				and T.EVENTNO=TX.EVENTNO
				and T.CYCLE=TX.CYCLE
				and T.UNIQUEID=TX.UNIQUEID)
	left join #TEMPCASEEVENT T1
				 on (T1.CASEID=T.CASEID
				and  T1.EVENTNO=DD.FROMEVENT
				and (T1.OCCURREDFLAG<9 or T1.OCCURREDFLAG is null)	-- Satisfied Events will not be used in the calculation	
				and  T1.[STATE] not like 'D%' --SQA18576
				and  T1.[STATE] not like 'C%' --SQ18576
				and  T1.CYCLE =	CASE DD.RELATIVECYCLE
							WHEN(0)	THEN T.CYCLE
							WHEN(1) THEN T.CYCLE-1
							WHEN(2) THEN T.CYCLE+1
							WHEN(3) THEN 1
							WHEN(5)	THEN T1.CYCLE		-- DR-46611 Relative Cycle of 5 means consider all Cycles
								ELSE (	select max(T2.CYCLE) 
								      	from  #TEMPCASEEVENT T2
							 		where T2.CASEID=T.CASEID 
									and   T2.EVENTNO=DD.FROMEVENT
									and  (T2.OCCURREDFLAG<9 or T2.OCCURREDFLAG is NULL)
									and   T2.[STATE] not like 'D%'
									and   T2.[STATE] not like 'C%'
									and ((DD.EVENTDATEFLAG=1 and  T2.NEWEVENTDATE is not null)
									 or  (DD.EVENTDATEFLAG=2 and  T2.NEWEVENTDUEDATE is not null)
									 or  (DD.EVENTDATEFLAG=3 and (T2.NEWEVENTDUEDATE is not null or T2.NEWEVENTDATE is not null))))
						END)
	left join #TEMPCASEINSTRUCTIONS CI
				on (CI.CASEID=T.CASEID
				and CI.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
	where  T.[STATE]='C'
	and   isnull(T.DATEDUESAVED,0)=0 
	and   (T1.CASEID is not null OR DD.MUSTEXIST =1)
							-- If the CHECKCOUNTRYFLAG column has a value then the	
							-- due date can only be calculated if there are 1 or	
							-- more designated countries for the case that have a 	
							-- status less than the CHECKCOUNTRYFLAG value.		
	and   (T.CHECKCOUNTRYFLAG is NULL
	 or    0<      (select count(*)
			from #TEMPOPENACTION OA						-- SQA13998
			join EVENTCONTROL EC 	on (EC.CRITERIANO=OA.NEWCRITERIANO)	-- SQA13998
			join DUEDATECALC DD1	on (DD1.CRITERIANO=EC.CRITERIANO
						and DD1.EVENTNO=EC.EVENTNO
						and DD1.FROMEVENT is null)
			join RELATEDCASE RC 	on (RC.CASEID      =OA.CASEID
						and RC.COUNTRYCODE =DD1.COUNTRYCODE
						and isnull(RC.CURRENTSTATUS,RC.COUNTRYFLAGS)<T.CHECKCOUNTRYFLAG)
			where	OA.CASEID=T.CASEID
			and	OA.POLICEEVENTS=1
			and	EC.EVENTNO=T.EVENTNO))
	OPTION (MAXDOP 1)")

	Select	@ErrorCode=@@Error,
		@nRowCount=@@Rowcount

End

--Delete any rows that have the same CASEID, EVENTNO and CYCLE where a calculation marked as MUST EXISTS
--could not be calculated.  Also delete any rows where no EVENTDUEDATE was calculated.

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	Delete from #TEMPCASEDUEDATE
	where	EVENTDUEDATE is null
	OR exists
	(select * from #TEMPCASEDUEDATE T
	 Where	T.EVENTDUEDATE is null
	 and	T.MUSTEXIST	=1
	 and	T.CASEID	=#TEMPCASEDUEDATE.CASEID
	 and	T.EVENTNO	=#TEMPCASEDUEDATE.EVENTNO
	 and	T.CYCLE		=#TEMPCASEDUEDATE.CYCLE)"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@Rowcount
End

--Update any of the calculated due dates that need adjusting.
--There are a number of hardcoded Adjustments as well as adjustments that can set the Day, Month or Year to
--specific values.  The hardcode Adjusments are as follows:
--	
--	Adjustment	Description
--	==========	===========
--	     E		Set date to end of month
--
--	    ~1		Annual		ADJUSTDAY & ADJUSTSTARTMONTH will indicate the day and month to be adjusted
--					earlier than the calculated due date up to a maximum of 1 year
-- 
--	    ~2		Half-yearly	ADJUSTDAY & ADJUSTSTARTMONTH will indicate the day and month (+/- 6 months)
--
--	    ~3		Quarterly	ADJUSTDAY & ADJUSTSTARTMONTH will indicate the day and month (+/- 3 months)
--
--	    ~4		Bi-monthly	ADJUSTDAY & ADJUSTSTARTMONTH will indicate the day and month (+/- 2 months)
--
--	    ~5		Monthly		ADJUSTDAY & ADJUSTSTARTMONTH will indicate the day and month (+/- 1 months)
--
--	    ~6		Fortnightly	ADJUSTDAYOFWEEK will indicate the day of the week on or prior to the calculated
--					due date. All fortnightly batches will fall on the Event numbered weeks.
--
--	    ~7		Weekly		ADJUSTDAYOFWEEK will indicate the day of the week on or prior to the due date
--					that the date will be adjusted to
--
--	    ~8		User Date	ADJUSTTODATE will be used to replace the calculated due date.
--
--          ~PA		Patent Term	Adjustment by adding the Patent Term Adjustment days provide by the IP Office.

If  @ErrorCode=0
and @nRowCount>0
Begin
	Exec("
	update	#TEMPCASEDUEDATE
	set EVENTDUEDATE =	CASE 	
					-- Adjust by a user defined Period held in the ADJUSTMENT row
					WHEN(A.PERIODTYPE='D')   Then dateadd( day,   A.ADJUSTAMOUNT, T.EVENTDUEDATE )
					WHEN(A.PERIODTYPE='W')   Then dateadd( week,  A.ADJUSTAMOUNT, T.EVENTDUEDATE )
					WHEN(A.PERIODTYPE='M')   Then dateadd( month, A.ADJUSTAMOUNT, T.EVENTDUEDATE )
					WHEN(A.PERIODTYPE='Y')   Then dateadd( year,  A.ADJUSTAMOUNT, T.EVENTDUEDATE )
					-- Add the number of Patent Term Adjustment days provided by the IP Office
					WHEN(A.ADJUSTMENT='~PA') Then dateadd( day,   coalesce(C.IPOPTA,0), T.EVENTDUEDATE )
					-- Set the date to the end of the month calculated by 	
					-- adding 1 month and setting the date to the 1st and then	
					-- subtracting 1 day. Note that the format of the  
					-- date under construction is MM/DD/YYYY			
					WHEN(T.ADJUSTMENT='E') Then	dateadd( day, -1, cast(cast(MONTH (dateadd (month, 1, T.EVENTDUEDATE)) as nvarchar)+'/1/'+ cast(YEAR (dateadd (month, 1, T.EVENTDUEDATE))as nvarchar) as datetime))
					-- ~1	Annual
					WHEN(T.ADJUSTMENT='~1') Then	cast(	cast( T.ADJUSTSTARTMONTH as nvarchar)+'/'+
										cast( T.ADJUSTDAY        as nvarchar)+'/'+ 
										CASE WHEN(MONTH(T.EVENTDUEDATE)<T.ADJUSTSTARTMONTH) THEN cast(YEAR(T.EVENTDUEDATE)-1 as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)>T.ADJUSTSTARTMONTH) THEN cast(YEAR(T.EVENTDUEDATE)   as nvarchar)
										     WHEN(DAY  (T.EVENTDUEDATE)<T.ADJUSTDAY)        THEN cast(YEAR(T.EVENTDUEDATE)-1 as nvarchar)
																    ELSE cast(YEAR(T.EVENTDUEDATE)   as nvarchar)
										END
									as datetime)
					-- ~2	Half-yearly
					WHEN(T.ADJUSTMENT='~2') Then	cast(	CASE WHEN(MONTH(T.EVENTDUEDATE)>T.ADJUSTSTARTMONTH)     THEN cast(T.ADJUSTSTARTMONTH as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)=T.ADJUSTSTARTMONTH)
											THEN CASE WHEN(DAY(T.EVENTDUEDATE)<T.ADJUSTDAY) THEN cast(T.ADJUSTSTARTMONTH-6 as nvarchar)
																	ELSE cast(T.ADJUSTSTARTMONTH   as nvarchar)
											     END
										     WHEN(MONTH(T.EVENTDUEDATE)>T.ADJUSTSTARTMONTH-6)   THEN cast(T.ADJUSTSTARTMONTH-6 as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)<T.ADJUSTSTARTMONTH-6)   THEN cast(T.ADJUSTSTARTMONTH   as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)=T.ADJUSTSTARTMONTH-6)
											THEN CASE WHEN(DAY(T.EVENTDUEDATE)<T.ADJUSTDAY) THEN cast(T.ADJUSTSTARTMONTH   as nvarchar)
																	ELSE cast(T.ADJUSTSTARTMONTH-6 as nvarchar)
											     END
										END+'/'+
										cast( T.ADJUSTDAY        as nvarchar)+'/'+ 
										CASE WHEN(MONTH(T.EVENTDUEDATE)<T.ADJUSTSTARTMONTH-6)   THEN cast(YEAR(T.EVENTDUEDATE)-1 as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)=T.ADJUSTSTARTMONTH-6
										      AND DAY  (T.EVENTDUEDATE)<T.ADJUSTDAY)            THEN cast(YEAR(T.EVENTDUEDATE)-1 as nvarchar)
																	ELSE cast(YEAR(T.EVENTDUEDATE)   as nvarchar)
										END
									as datetime)
					-- ~3	Quarterly
					WHEN(T.ADJUSTMENT='~3') Then	cast(	CASE WHEN(MONTH(T.EVENTDUEDATE)>T.ADJUSTSTARTMONTH)     THEN cast(T.ADJUSTSTARTMONTH as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)=T.ADJUSTSTARTMONTH)
											THEN CASE WHEN(DAY(T.EVENTDUEDATE)<T.ADJUSTDAY) THEN cast(T.ADJUSTSTARTMONTH-3 as nvarchar)
																	ELSE cast(T.ADJUSTSTARTMONTH   as nvarchar)
											     END
										     WHEN(MONTH(T.EVENTDUEDATE)>T.ADJUSTSTARTMONTH-3)   THEN cast(T.ADJUSTSTARTMONTH-3 as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)=T.ADJUSTSTARTMONTH-3)
											THEN CASE WHEN(DAY(T.EVENTDUEDATE)<T.ADJUSTDAY) THEN cast(T.ADJUSTSTARTMONTH-6 as nvarchar)
																	ELSE cast(T.ADJUSTSTARTMONTH-3 as nvarchar)
											     END
										     WHEN(MONTH(T.EVENTDUEDATE)>T.ADJUSTSTARTMONTH-6)   THEN cast(T.ADJUSTSTARTMONTH-6 as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)=T.ADJUSTSTARTMONTH-6)
											THEN CASE WHEN(DAY(T.EVENTDUEDATE)<T.ADJUSTDAY) THEN cast(T.ADJUSTSTARTMONTH-9 as nvarchar)
																	ELSE cast(T.ADJUSTSTARTMONTH-6 as nvarchar)
											     END
										     WHEN(MONTH(T.EVENTDUEDATE)>T.ADJUSTSTARTMONTH-9)   THEN cast(T.ADJUSTSTARTMONTH-9 as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)<T.ADJUSTSTARTMONTH-9)   THEN cast(T.ADJUSTSTARTMONTH   as nvarchar)
										     WHEN(MONTH(T.EVENTDUEDATE)=T.ADJUSTSTARTMONTH-9)
											THEN CASE WHEN(DAY(T.EVENTDUEDATE)<T.ADJUSTDAY) THEN cast(T.ADJUSTSTARTMONTH   as nvarchar)
																	ELSE cast(T.ADJUSTSTARTMONTH-9 as nvarchar)
											     END
										END+'/'+
									cast( T.ADJUSTDAY        as nvarchar)+'/'+ 
									CASE WHEN(MONTH(T.EVENTDUEDATE)<T.ADJUSTSTARTMONTH-9)   THEN cast(YEAR(T.EVENTDUEDATE)-1 as nvarchar)
									     WHEN(MONTH(T.EVENTDUEDATE)=T.ADJUSTSTARTMONTH-9
									      AND DAY  (T.EVENTDUEDATE)<T.ADJUSTDAY)            THEN cast(YEAR(T.EVENTDUEDATE)-1 as nvarchar)
																ELSE cast(YEAR(T.EVENTDUEDATE)   as nvarchar)
									END
								as datetime)
					-- ~4	Bi-monthly
					WHEN(T.ADJUSTMENT='~4') Then	cast(	CASE WHEN(MONTH(T.EVENTDUEDATE)%2=T.ADJUSTSTARTMONTH%2)
											THEN CASE WHEN(DAY(T.EVENTDUEDATE)>=T.ADJUSTDAY)
												THEN cast(MONTH(T.EVENTDUEDATE) as nvarchar)
												ELSE CASE WHEN(MONTH(T.EVENTDUEDATE)-2>0) THEN cast(MONTH(T.EVENTDUEDATE)-2 as nvarchar)
													  WHEN(MONTH(T.EVENTDUEDATE)-2=0) THEN '12'
													                                  ELSE '11'
												     END
											     END
											ELSE CASE WHEN(MONTH(T.EVENTDUEDATE)-1>0)	THEN cast(MONTH(T.EVENTDUEDATE)-1 as nvarchar)
												  WHEN(MONTH(T.EVENTDUEDATE)-1=0)	THEN '12'
																	ELSE '11'
											     END
										END+'/'+
									cast( T.ADJUSTDAY        as nvarchar)+'/'+ 
								
									CASE WHEN(MONTH(T.EVENTDUEDATE)%2=T.ADJUSTSTARTMONTH%2)
										THEN CASE WHEN(DAY(T.EVENTDUEDATE)>=T.ADJUSTDAY)
											THEN cast(YEAR(T.EVENTDUEDATE) as nvarchar)
											ELSE CASE WHEN(MONTH(T.EVENTDUEDATE)-2>0) THEN cast(YEAR(T.EVENTDUEDATE)   as nvarchar)
																  ELSE cast(YEAR(T.EVENTDUEDATE)-1 as nvarchar)
											     END
										     END
										ELSE	     CASE WHEN(MONTH(T.EVENTDUEDATE)-1>0) THEN cast(YEAR(T.EVENTDUEDATE)   as nvarchar)
																  ELSE cast(YEAR(T.EVENTDUEDATE)-1 as nvarchar)
											     END
									END
								as datetime)
					-- ~5	Monthly
					WHEN(T.ADJUSTMENT='~5') Then	cast(	CASE WHEN(DAY(T.EVENTDUEDATE)>=T.ADJUSTDAY)
											THEN cast(MONTH(T.EVENTDUEDATE) as nvarchar)
											ELSE CASE WHEN(MONTH(T.EVENTDUEDATE)=1)
												THEN '12'
												ELSE cast(MONTH(T.EVENTDUEDATE)-1 as nvarchar)
											     END
										END+'/'+
									cast( T.ADJUSTDAY        as nvarchar)+'/'+ 
								
									CASE WHEN(DAY(T.EVENTDUEDATE)>=T.ADJUSTDAY)
										THEN cast(YEAR(T.EVENTDUEDATE) as nvarchar)
										ELSE CASE WHEN(MONTH(T.EVENTDUEDATE)=1)
											THEN cast(YEAR(T.EVENTDUEDATE)-1 as nvarchar)
											ELSE cast(YEAR(T.EVENTDUEDATE)   as nvarchar)
										     END
									END
								as datetime)
					-- ~6	Fortnightly
					WHEN(T.ADJUSTMENT='~6') Then	CASE WHEN(datepart(wk,T.EVENTDUEDATE)%2=0)
										THEN CASE WHEN(datepart(dw,T.EVENTDUEDATE)>=T.ADJUSTDAYOFWEEK)
											THEN dateadd(dd,-1*(   datepart(dw,T.EVENTDUEDATE)-T.ADJUSTDAYOFWEEK),T.EVENTDUEDATE)
											ELSE dateadd(dd,-1*(14+datepart(dw,T.EVENTDUEDATE)-T.ADJUSTDAYOFWEEK),T.EVENTDUEDATE)
										     END
										ELSE dateadd(dd,-1*(7+datepart(dw,T.EVENTDUEDATE)-T.ADJUSTDAYOFWEEK),T.EVENTDUEDATE)
									END
					-- ~7	Weekly
					WHEN(T.ADJUSTMENT='~7') Then	CASE WHEN(datepart(dw,T.EVENTDUEDATE)>=T.ADJUSTDAYOFWEEK)
										THEN dateadd(dd,-1*(   datepart(dw,T.EVENTDUEDATE)-T.ADJUSTDAYOFWEEK),T.EVENTDUEDATE)
										ELSE dateadd(dd,-1*(7+datepart(dw,T.EVENTDUEDATE)-T.ADJUSTDAYOFWEEK),T.EVENTDUEDATE)
									END
					-- ~8	User Date
					WHEN(T.ADJUSTMENT='~8') Then	isnull(T.ADJUSTTODATE,T.EVENTDUEDATE)
					-- Construct a date by swapping	in the values held in the	
					-- AdjustMonth, AdjustDay and AdjustYear fields if they    
					-- exist otherwise leave that part of the date intact.	
					WHEN(A.ADJUSTDAY is not null OR A.ADJUSTMONTH is not null OR A.ADJUSTYEAR is not null)
						Then	cast(cast( isnull (A.ADJUSTMONTH, MONTH (T.EVENTDUEDATE)) as nvarchar)+'/'+cast( isnull (A.ADJUSTDAY, DAY (T.EVENTDUEDATE)) as nvarchar)+'/'+ cast( isnull (A.ADJUSTYEAR, YEAR (T.EVENTDUEDATE)) as nvarchar) as datetime)
					-- Construct a date by swapping	in the values for the Day and
					-- Month of a specific Event	
					WHEN(upper(S.CONTROLID)=upper('ADJUSTMENT ' +T.ADJUSTMENT+' EVENT')
					 and TC.NEWEVENTDATE is not null)
						-- If the Event used in the 	
						-- adjustment is dated the 29th 
						-- February and the year of the 
						-- date to be adjusted is not a 
						-- leap year then adjust the	
						-- date to 28th February.	
						Then CASE WHEN(MONTH(TC.NEWEVENTDATE)=2 
							   AND   DAY(TC.NEWEVENTDATE)=29
							   AND (YEAR(T.EVENTDUEDATE)%4>0 OR YEAR(T.EVENTDUEDATE) in (1700,1800,1900,2100,2200)))
								Then cast('02/28/'+ cast( YEAR (T.EVENTDUEDATE) as nvarchar) as datetime)
								Else cast(cast( MONTH (TC.NEWEVENTDATE) as nvarchar)+'/'+cast( DAY(TC.NEWEVENTDATE) as nvarchar)+'/'+ cast( YEAR (T.EVENTDUEDATE) as nvarchar) as datetime)
						     END
					-- Construct a date by swapping	in the values for the Day and
					-- Month of a specific Event and making sure that the date
					-- that results is greater than or equal to the event being adjusted.	
					WHEN(upper(S.CONTROLID)=upper('ADJUST NEXT '+T.ADJUSTMENT+' EVENT')
					 and TC.NEWEVENTDATE is not null)
						-- if the Day and Month of the Event used in the adjustment	
						-- are less than the Day and Month of the Event being	
						-- adjusted then the Year will need to be incremented.	
					   then CASE WHEN(TC.NEWEVENTDATE is not null)
							then CASE WHEN(MONTH(TC.NEWEVENTDATE)*100 + DAY(TC.NEWEVENTDATE)<MONTH(T.EVENTDUEDATE)*100 + DAY(T.EVENTDUEDATE))
								-- check for leap year		
								then CASE WHEN(MONTH(TC.NEWEVENTDATE)=2
									   AND   DAY(TC.NEWEVENTDATE)=29
									   AND ((YEAR(T.EVENTDUEDATE)+1)%4>0 OR (YEAR(T.EVENTDUEDATE)+1) in (1700,1800,1900,2100,2200)))
									then cast('02/28/'+ cast( (YEAR (T.EVENTDUEDATE)+1) as nvarchar) as datetime)
									else cast(cast( MONTH (TC.NEWEVENTDATE) as nvarchar)+'/'+cast( DAY(TC.NEWEVENTDATE) as nvarchar)+'/'+ cast( (YEAR(T.EVENTDUEDATE)+1) as nvarchar) as datetime)
								     End
								-- check for leap year		
								else CASE WHEN(MONTH(TC.NEWEVENTDATE)=2
									   AND   DAY(TC.NEWEVENTDATE)=29
									   AND (YEAR(T.EVENTDUEDATE)%4>0 OR YEAR(T.EVENTDUEDATE) in (1700,1800,1900,2100,2200)))
									then cast('02/28/'+ cast( YEAR (T.EVENTDUEDATE) as nvarchar) as datetime)
									else cast(cast( MONTH (TC.NEWEVENTDATE) as nvarchar)+'/'+cast( DAY(TC.NEWEVENTDATE) as nvarchar)+'/'+ cast( YEAR(T.EVENTDUEDATE) as nvarchar) as datetime)
								     End
							     End
						End
					-- Adjust the date to today.	
					WHEN(upper(S.CONTROLID)=upper('ADJUST '+T.ADJUSTMENT+' AS TODAY'))
					   then convert(nvarchar,getdate(),112)
						-- if no adjustment is defined	
						-- then do not adjust the date	
					   else T.EVENTDUEDATE
				End
	from #TEMPCASEDUEDATE T
	     join ADJUSTMENT A 	on (A.ADJUSTMENT=T.ADJUSTMENT)
	     join CASES C       on (C.CASEID    =T.CASEID)
	left join SITECONTROL S	on (upper(S.CONTROLID)=upper('ADJUSTMENT ' +T.ADJUSTMENT+' EVENT')
				or  upper(S.CONTROLID)=upper('ADJUST NEXT '+T.ADJUSTMENT+' EVENT')
				or  upper(S.CONTROLID)=upper('ADJUST '     +T.ADJUSTMENT+' AS TODAY'))
	left join #TEMPCASEEVENT TC
				on (TC.CASEID = T.CASEID
				and TC.CYCLE  = 1
				and TC.EVENTNO= S.COLINTEGER)
	where	T.EVENTDUEDATE is not null")
	
	Set @ErrorCode=@@Error
End

--Delete any rows that have the same CASEID, EVENTNO and CYCLE where a calculation marked as MUST EXISTS
--could not be calculated.  Also delete any rows where no EVENTDUEDATE was calculated.

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	Delete from #TEMPCASEDUEDATE
	where	EVENTDUEDATE is null
	OR exists
	(select * from #TEMPCASEDUEDATE T
	 Where	T.EVENTDUEDATE is null
	 and	T.MUSTEXIST	=1
	 and	T.CASEID	=#TEMPCASEDUEDATE.CASEID
	 and	T.EVENTNO	=#TEMPCASEDUEDATE.EVENTNO
	 and	T.CYCLE		=#TEMPCASEDUEDATE.CYCLE)"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@Rowcount
End

-- Update the Calculated Due Dates that have been flagged to be extended automatically whenever the
-- calculated due date is no longer in the future.  To keep processing simple always calculate the 
-- extension from the current system date

If  @ErrorCode=0
and @nRowCount>0
Begin
	-- Loop through the incremental extensions until no more updates occur.
	While @nExtensionCount>0
	and @ErrorCode=0
	Begin
		Set @sSQLString="
		Update #TEMPCASEDUEDATE
		set EVENTDUEDATE=CASE(EXTENDPERIODTYPE)
					WHEN ('D') THEN dateadd(day,   T.EXTENDPERIOD, convert(nvarchar,T.EVENTDUEDATE,112))
					WHEN ('W') THEN dateadd(week,  T.EXTENDPERIOD, convert(nvarchar,T.EVENTDUEDATE,112))
					WHEN ('M') THEN dateadd(month, T.EXTENDPERIOD, convert(nvarchar,T.EVENTDUEDATE,112))
					WHEN ('Y') THEN dateadd(year,  T.EXTENDPERIOD, convert(nvarchar,T.EVENTDUEDATE,112))
				 END
		FROM #TEMPCASEDUEDATE T
		Where T.EVENTDUEDATE<=getdate()
		and   T.SAVEDUEDATE=8  -- indicates the duedate is to be extended
		and   T.EXTENDPERIOD>0
		and   T.EXTENDPERIODTYPE in ('D','W','M','Y')
				-- do not extend calculated due dates where
				-- the Latest due date is to be used and a future
				-- due date already exists
		and not exists
		(select * from #TEMPCASEDUEDATE T1
		 where T1.CASEID=T.CASEID
	         and   T1.EVENTNO=T.EVENTNO
	         and   T1.CYCLE  =T.CYCLE
	         and   T1.WHICHDUEDATE='L'
	         and   T1.EVENTDUEDATE>getdate())"
	
		Exec @ErrorCode=sp_executesql @sSQLString
		Set @nExtensionCount=@@Rowcount
	End
End

--Update the calculated due dates that must fall on a working day and either move forward or back
--by one day.  Continue this process until all due dates that must fall on a work day are adjusted.
--A non working day is determined by comparing the date against the Holidays for the country of the
--case.  The working day of the week is determined for the country which is stored in a bit position
--which can be compared to the day of the week number returned.

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString1="
	Select @nCaseIdOUT=min(T.CASEID) 
	from #TEMPCASEDUEDATE T
	     join #TEMPCASES CS on (CS.CASEID=T.CASEID)
	     join COUNTRY C	on (C.COUNTRYCODE=CS.COUNTRYCODE
				and C.WORKDAYFLAG>0)		-- SQA 7254
	left join HOLIDAYS H	on (H.COUNTRYCODE=C.COUNTRYCODE and H.HOLIDAYDATE=convert(nvarchar(11),T.EVENTDUEDATE))
	where T.WORKDAY in (1,2)
	and  (H.HOLIDAYDATE is not null	
	 OR   'Weekend'=CASE (datepart(weekday,T.EVENTDUEDATE))
				WHEN 7 	THEN CASE WHEN (WORKDAYFLAG&1=1)	THEN 'Workday'
						  WHEN (WORKDAYFLAG is null)	THEN 'Workday' 
										ELSE 'Weekend' 
					     END 
					ELSE CASE WHEN (WORKDAYFLAG&POWER(2,datepart(weekday,T.EVENTDUEDATE))=POWER(2,datepart(weekday,T.EVENTDUEDATE))) 
										THEN 'Workday'
						  WHEN (WORKDAYFLAG is null)	THEN 'Workday' 
										ELSE 'Weekend' 
					     END
			END  )"

	Execute @ErrorCode=sp_executesql @sSQLString1, 
					N'@nCaseIdOUT	int OUTPUT',
					  @nCaseIdOUT=@nCaseId OUTPUT
End

WHILE @ErrorCode=0
and   @nRowCount>0
and   @nCaseId is not Null

BEGIN
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Update #TEMPCASEDUEDATE
										-- Either move forward by 1 day	
										-- or back by 1 day depending on
										-- the WORKDAY value.		
		set EVENTDUEDATE= dateadd (day, CASE T.WORKDAY WHEN(1) THEN 1 ELSE -1 END, T.EVENTDUEDATE)
		from #TEMPCASEDUEDATE T
		     join #TEMPCASES CS on (CS.CASEID=T.CASEID)
		     join COUNTRY C	on (C.COUNTRYCODE=CS.COUNTRYCODE
					and C.WORKDAYFLAG>0)		-- SQA 7254
		left join HOLIDAYS H	on (H.COUNTRYCODE=C.COUNTRYCODE and H.HOLIDAYDATE=convert(nvarchar(11),T.EVENTDUEDATE))
		where T.WORKDAY in (1,2)
		and  (H.HOLIDAYDATE is not null	
										-- The DATEPART function returns
										-- a value between 1 and 7 that	
										-- represents the day of the	
										-- week. This can then be	
										-- compared against the flags	
										-- held for the Country that	
										-- indicate what days are work	
										-- days or not.				
		 OR   'Weekend'=CASE (datepart(weekday,T.EVENTDUEDATE))
					WHEN 7 	THEN CASE WHEN (WORKDAYFLAG&1=1) THEN 'Workday' ELSE 'Weekend' END 
						ELSE CASE WHEN (WORKDAYFLAG&POWER(2,datepart(weekday,T.EVENTDUEDATE))=POWER(2,datepart(weekday,T.EVENTDUEDATE))) THEN 'Workday' ELSE 'Weekend' END
				END  )"

		Exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Check to see if the loop should continue by re-executing the previously saved SQL
	-- to see if any more rows require adjusting

	Execute @ErrorCode=sp_executesql @sSQLString1, 
					N'@nCaseIdOUT	int OUTPUT',
					  @nCaseIdOUT=@nCaseId OUTPUT
END

-- Every TEMPCASEEVENT row that currently has a state of "C" (Calculate) is now to be updated from the calculated
-- due dates.  If no due date has been calculated then the NEWEVENTDUEDATE will be set to null.  If the WHICHDUEDATE
-- column is set to "L" (latest) then the latest of the calculated dates for the Caseid, Eventno and 
-- Cycle combination will be used otherwise the earliest date will be used.

If  @ErrorCode=0
and @pnCountStateC>0
Begin
	Set @sSQLString="
	Update 	T
	
										-- Get the calculated date 	
										-- depending on whether the 	
										-- Latest or Earliest date is	
										-- required. Strip off time.
	set	@dtNewDueDate=convert(varchar,
				(select CASE CE.WHICHDUEDATE WHEN('L')		-- RFC12049
						THEN max(T1.EVENTDUEDATE)
						ELSE min(T1.EVENTDUEDATE)
					END
				 from #TEMPCASEDUEDATE T1
				 where T1.CASEID =T.CASEID
				 and   T1.EVENTNO=T.EVENTNO
				 and   T1.CYCLE  =T.CYCLE),112),
										-- Change the State of the	
										-- event to 'R' to indicate that
										-- the calculation has been 	
										-- performed and the row is now	
										-- ready to calculate reminders.
										-- Use State 'RX' if the calculated
										-- date has not changed and the Event
										-- just calculated is not involved in
										-- another calculation that uses a 
										-- relative cycle to determine a 
										-- different cycle
		[STATE]=CASE	WHEN(T.LOOPCOUNT<20)	-- R11717 increased to 20
					THEN 'R'
				WHEN(D.CURRENTDUEDATE is not null and @dtNewDueDate is null)-- RFC11092
					THEN 'R'
				WHEN(D.CURRENTDUEDATE is null     and @dtNewDueDate is not null)-- RFC11092
					THEN 'R'
				WHEN(D.CURRENTDUEDATE<>@dtNewDueDate)	-- RFC11092
					THEN 'R'				 
				WHEN(T.NEWEVENTDUEDATE<=@pdtUntilDate)
					THEN 'R'
				WHEN(T.NEWEVENTDATE is null and T.OLDEVENTDATE is not null)
					THEN 'R'
				WHEN(D.CURRENTDUEDATE is null and @dtNewDueDate is null)	-- RFC11092
					THEN 'RX'
				WHEN(D.CURRENTDUEDATE=@dtNewDueDate)	-- RFC11092
					THEN 'RX'
				WHEN(T.NEWEVENTDUEDATE<>@dtNewDueDate)
					THEN 'R'WHEN(EXISTS(	select * from #TEMPOPENACTION OA
							join DUEDATECALC DD on (DD.CRITERIANO=OA.NEWCRITERIANO
									    and(DD.FROMEVENT=T.EVENTNO
									     or DD.COMPAREEVENT=T.EVENTNO)) 
							-- SQA18643 Add the following Left Join
							left join #TEMPCASEEVENT CE
										on (CE.CASEID=T.CASEID
										and CE.EVENTNO=DD.EVENTNO
										and CE.[STATE]='C')
							where OA.CASEID=T.CASEID
							and OA.POLICEEVENTS=1
							and (DD.EVENTDATEFLAG in (2,3) or DD.COMPAREEVENTFLAG in (2,3))
						and (DD.RELATIVECYCLE>0 or DD.COMPARECYCLE>0 or DD.COMPARISON is not null or CE.EVENTNO=DD.EVENTNO)	
							))
				THEN 'R'
				ELSE 'RX'
			END,
										-- Set the NEWEVENTDUEDATE to 
										-- the calculated date 	
		NEWEVENTDUEDATE  =@dtNewDueDate,
		WHICHDUEDATE     =CE.WHICHDUEDATE,				-- RFC12049,
		CREATEDBYCRITERIA=CE.CREATEDBYCRITERIA,				-- RFC12049
		CREATEDBYACTION  =CE.CREATEDBYACTION				-- RFC12049
		
		------------------------------------------------
		-- The row to be updated (irrespective of STATE)
		-- This is required because an Event may reside 
		-- under multiple Actions
		------------------------------------------------
	From	#TEMPCASEEVENT T
	left join #TEMPDERIVEDCASEEVENTS D	on (D.CASEID =T.CASEID		-- RFC11092
						and D.EVENTNO=T.EVENTNO
						and D.CYCLE  =T.CYCLE)
		-------------------------------------------------
		-- The row that provided the calculation details.
		-- SQA20336
		-- This method ensures all occurrences of this
		-- CASEID, EVENTNO, CYCLE are updated.
		-------------------------------------------------
	join (	select * 
		from #TEMPCASEEVENT
		where [STATE]='C') CE	on (CE.CASEID =T.CASEID
					and CE.EVENTNO=T.EVENTNO
					and CE.CYCLE  =T.CYCLE)"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pdtUntilDate		datetime,
					  @dtNewDueDate		datetime',
					  @pdtUntilDate=@pdtUntilDate,
					  @dtNewDueDate=@dtNewDueDate
	Select  @pnCountStateC=@pnCountStateC-@@Rowcount,
		@pnCountStateR=@pnCountStateR+@@Rowcount
End

-- SQA 7094 Update the STATE to "R" for cleared events that have not been recalculated.

If  @ErrorCode=0
and @pnCountStateC>0
Begin
	Set @sSQLString="
	Update 	#TEMPCASEEVENT 
	set 	[STATE]='R'
	Where	[STATE]='C1'"

	Exec @ErrorCode=sp_executesql @sSQLString
	Select  @pnCountStateC=@pnCountStateC-@@Rowcount,
		@pnCountStateR=@pnCountStateR+@@Rowcount
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceCalculateDueDate',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,INITIALFEE, SAVEDUEDATE, T.*, @pnCountStateC as 'CountStateC', @pnCountStateI as 'CountStateI', @pnCountStateR as 'CountStateR', @pnCountStateD as 'CountStateD' 
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		Exec @ErrorCode = sp_executesql @sSQLString,
						N'@pnCountStateC	int,
						  @pnCountStateI	int,
						  @pnCountStateR	int,
						  @pnCountStateD	int',
						  @pnCountStateC,
						  @pnCountStateI,
						  @pnCountStateR,
						  @pnCountStateD
	End
End
	
-- Now that Due Dates have been calculated the Date Comparisons need to be performed to ensure that the due date
-- calculation is eligible.  Note that this is performed after the Due Date Calculation because it is possible 
-- that the calculated date may be included in the Date Comparison.


If  @ErrorCode=0
and @pnCountStateR>0
Begin
	execute @ErrorCode=dbo.ip_PoliceCheckDateComparisons @pnDebugFlag

	-- Use the Due Date calculation previously used in the update to also update details associated with 
	-- the specific due date calculation.  Also flag any Due Dates that are now to be saved.
	
	If  @ErrorCode=0
	Begin
		Set @sSQLString="
		Update 	#TEMPCASEEVENT
	
		set 	
			-- Get the Event that was	
			-- used to calculate the date.	
			GOVERNINGEVENTNO=T1.GOVERNINGEVENTNO,
			-- Determine which reminder message to use
			USEMESSAGE2FLAG=T1.MESSAGE2FLAG,
			-- Some calculations can cause the reminders to be suppressed
			SUPPRESSREMINDERS=T1.SUPPRESSREMINDERS,
			-- Some calculations will cause a particular letter to be replaced.
			OVERRIDELETTER=T1.OVERRIDELETTER,
			-- Flag the Event as having a saved due date if the rule requies this
			DATEDUESAVED=CASE WHEN(T.SAVEDUEDATE in (1,3,5)) THEN 1 ELSE 0 END,
			-- Reset the STATE flag for  Events that have failed the Date Comparison
			[STATE]=CASE WHEN(T.NEWEVENTDUEDATE is NULL and D.CURRENTDUEDATE is NULL and T.LOOPCOUNT>20)	-- RFC11717
									THEN 'RX' 
				     WHEN(T.NEWEVENTDUEDATE is NULL)	THEN 'R'
									ELSE T.[STATE] 
				END,
			@pnCountStateR =@pnCountStateR +CASE WHEN(T.[STATE]='RX')
							   THEN	CASE WHEN(T.NEWEVENTDUEDATE is NULL and D.CURRENTDUEDATE is NULL and T.LOOPCOUNT>20)	-- RFC11717
													THEN 0 
								     WHEN(T.NEWEVENTDUEDATE is NULL)	THEN 1
													ELSE 0 
								END
							END,
			@pnCountStateRX=@pnCountStateRX-CASE WHEN(T.[STATE]='RX')
							   THEN	CASE WHEN(T.NEWEVENTDUEDATE is NULL and D.CURRENTDUEDATE is NULL and T.LOOPCOUNT>20)	-- RFC11717
													THEN 0 
								     WHEN(T.NEWEVENTDUEDATE is NULL)	THEN 1
													ELSE 0 
								END
							END,
			-- Set the Occurredflag
			OCCURREDFLAG=0
		from	#TEMPCASEEVENT T
		join	#TEMPDERIVEDCASEEVENTS D on (D.CASEID =T.CASEID
						 and D.EVENTNO=T.EVENTNO
						 and D.CYCLE  =T.CYCLE)
		join	#TEMPCASEDUEDATE T1	on (T1.CASEID=T.CASEID
						and T1.EVENTNO=T.EVENTNO
						and T1.CYCLE  =T.CYCLE
						and convert(varchar,T1.SEQUENCENO) = substring(
								(	select 	CASE T.WHICHDUEDATE WHEN('L') 
										  THEN max(convert(varchar,T2.EVENTDUEDATE,112)+convert(varchar, T2.SEQUENCENO))
										  ELSE min(convert(varchar,T2.EVENTDUEDATE,112)+convert(varchar, T2.SEQUENCENO))
										END
									from #TEMPCASEDUEDATE T2
									where T2.CASEID =T.CASEID
									and   T2.EVENTNO=T.EVENTNO
									and   T2.CYCLE =T.CYCLE), 9,6 ) )
		Where	T.[STATE] in ('R', 'RX')"
	
		Exec @ErrorCode=sp_executesql @sSQLString, 
						N'@pnCountStateR	int	OUTPUT,
						  @pnCountStateRX	int	OUTPUT',
						  @pnCountStateR		OUTPUT,
						  @pnCountStateRX		OUTPUT
	End
End


drop table #TEMPCASEDUEDATE
return @ErrorCode
go

grant execute on dbo.ip_PoliceCalculateDueDate  to public
go

