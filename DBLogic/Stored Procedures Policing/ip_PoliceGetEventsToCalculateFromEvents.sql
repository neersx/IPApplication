-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetEventsToCalculateFromEvents
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetEventsToCalculateFromEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetEventsToCalculateFromEvents.'
	drop procedure dbo.ip_PoliceGetEventsToCalculateFromEvents
end
print '**** Creating procedure dbo.ip_PoliceGetEventsToCalculateFromEvents...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetEventsToCalculateFromEvents
				@pnRowCount		int	OUTPUT,
				@pbRecalcEventDate	bit	= 0,	-- SQA19252 Indicates some Events may trigger to recalculate by changes to their governing event
				@pnDebugFlag		tinyint

as
-- PROCEDURE :	ip_PoliceGetEventsToCalculateFromEvents
-- VERSION :	97
-- DESCRIPTION:	A procedure to get the Case Event rows that are to be calculated
--              as a result of changes to another Event
-- CALLED BY :	ipu_PoliceRecalc

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13/07/2000	MF			Procedure created
--
-- 29/05/2001	MF			Find events that are to be recalculated as a result of a related
--					case and its linked event being updated in some way.
-- 11/09/2001	MF	7041		Events may be flagged as having occurred when their OCCURREDFLAG is any 
--					value from 1 through 8
-- 12/09/2001	MF	7053		Make sure that the CycleNumber of the Due Date Calculation is taken into consieration
-- 17/09/2001	MF	7059		Compare the number of cycles allowed for the Event against the cycle of the 
--					event to be calculated.
-- 02/10/2001	MF	7094		Events that exist on the database but have been marked to be deleted
--					should also be returned for recalculation if triggered by another event
-- 26/10/2001	MF	7149		When an Event is deleted this should trigger the recalculation of Events 
--					that it is either used in the calculation of or if it is a satisfying event.
-- 5/11/2001	MF	7154		If the triggering Event has been marked for Deletion and the Event to calculate 
--					is  marked for Deletion then it does not need to be recalculated as there is no 
--					liklihood that the Event will be recalculated.
--					If the triggering Event has been marked for Deletion and it satisifies other 
--					events then do not recalculate any Events that have only just been marked for 
--					Deletion (State = 'D') as these must be getting deleted for some other reason.  
--					You can however return Events that were previously marked for Deletion (State = 'D1')
-- 15/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 13/12/2001	MF	7291		Compare the number of cycles allowed for Events when the event is being triggered
--					by a date comparison event.
-- 14/01/2002	MF	7344		Check the NUMCYCLESALLOWED of events triggered to be calculated when a satisfying 
--					event is deleted.
-- 16/01/2002	MF	7154		This SQA is being revisited to improve the code.
-- 30/01/2002	MF	7380		Also return TEMPCASEEVENT rows that have been previously satisfied after
--					having their due date manually entered.
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 30/06/2002	MF	7880		An EventNo and Cycle combination should not trigger itself to recalculate
--					as this will cause a loop to occur.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 21/08/2002	MF	7946		Extend the size of the USERID field to avoid truncation errors.
-- 23/10/2002	MF	8108		Events calculated from more than one Event are causing multiple Fee Requests
--					to be generated.  This was introduced by 7880 because the UNION was no longer 
--					removing DISTINCT rows because of the introduction of a the GOVERNINGEVENTNO
-- 18/12/2002	MF	8326		When an Event Date is cleared, an Event that has a due date calculated from 
--					the Event Date isn't being calculated.
-- 01/04/2003	MF	8598		When an event used in a date comparison changes make certain Events that use 
--					the comparison are recalculated.  The SQL was previously using the RELATIVECYLCE
--					instead of the COMPARECYCLE.
-- 10/04/2003	MF	8326		Revisted. The existence of the EventDate or EventDueDate is not required in
--					order to recalculate an Event.
-- 12/06/2003	MF	8900		GOVERNINGEVENTNO and GOVERNINGCYCLE are allowed to be NULL
-- 24 Jul 2003	MF	8260	10	Get PTADELAY from EventControl table for Patent Term Adjustment
-- 28 Jul 2003	MF	8673	10	Get the OFFICE associated with the Case so it can be used to determine the
--					best CriteriaNo for an Action.
-- 12 Nov 2003	MF	9450	11	Set the CRITERIANO on the #TEMPCASEEVENT table when inserting rows.
-- 26 Feb 2004	MF	9751	12	Only push an Event Date into a related Case if the Status of that related
--					cases is not explicitly set to no longer Police.
-- 26 Feb 2004	MF	RFC709	13	Get the IDENTITYID to identify workbench users
-- 15 Mar 2004	MF	9806	14	Where the Due Date Calculation uses RelativeCycle>2 then determine the Cycle
--					to calculate as 1 higher than the current maximum cycle for the Event or if
--					none exists then use the cycle of the DueDateCalculation rule.
-- 24 Jun 2004	MF	9880	15	Increase the size of the ADJUSTMENT column in temporary table to nvarchar(4)
-- 02 Jul 2004	MF	10266	16	Only return Events for recalculation if the appropriate EventDate or EventDueDate
--					exists for the calculation.
-- 05 Jul 2004	MF	10254	17	Enable the "push" event functionality that allows one event to push its Event
--					into another event (or clear out another Event), even if the pushing Event 
--					belongs to the same Case.  Previously this functionality was only implemented 
--					for Related Cases.
-- 05 Jul 2004	MF	10056	17	The Load Event from Another Event function ("push" event) previously only
--					worked for Cycle 1.  This change allows for the cycle of the pushing Event
--					to update the same cycle of the receiving Event and is no longer limited to
--					cycle 1.
-- 23 Jul 2004	MF	10314	18	Code error when getting DueDateCalc.  Only accept a null countrycode if there
--					are no other DueDateCalc rows for the Event in question that have a matching 
--					CountryCode.
-- 13 Aug 2004	MF	10377	19	Problem introduced in 10266.  If the triggering event has been deleted then
--					it should cause a recalc of the calculated Events irrespective of the content
--					of the Event Date or Due Date.
-- 06 Aug 2004	AB	8035	19	Add collate database_default to temp table definitions
-- 20 Oct 2004	MF	10572	20	Satisfied Event with a manually entered due date was not being reinstated.
-- 28 Oct 2004	MF	10605	21	When an Event has been cleared out and immediately recalculated then any
--					Events that were originally calculated from the Event date need to be 
--					recalculated.
-- 03 Nov 2004	MF	10385	22	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 01 Dec 2004	MF	10756	23	Only recalulate Events where the Satisfying Event has been Deleted or cleared
--					out and the current State indicates this change has just occurred.
-- 20 Jan 2005	MF	10908	24	When pushing an Event down into a related case, need to check if the related
--					case is currently being processed by Policing by considering the
--					TEMPOPENACTION table.
-- 21 Jan 2005	MF	10917	25	Trigger the calculation of Case Events where the due data rule refers to 
--					explicit cycles.  This will allow a single governing Event to trigger multiple
--					cycles of an Event
-- 25 Jan 2005	MF	10928	26	When pushing an Event into a related Case then use the CYCLE that is specified
--					on the RELATEDCASE table if it exists, otherwiswe use the CYCLE of the 
--					current CaseEvent row that triggered this.
-- 28 Jan 2005	MF	10931	27	A related case may now be referred to in a Date Comparison rule.  When an Event
--					occurs or is cleared out we must trigger the recalculation of any Case Event
--					where the date comparison rule applies.
-- 08 Feb 2005	MF	10931	28	Revisit to correct error in testing.
-- 14 Feb 2005	MF	10917	29	Revisit to correct error in testing.
-- 23 Feb 2005	MF	11063	30	Only trigger recalc if satisfying Event has been removed.
-- 07 Mar 2005	MF	11115	31	An Event that exists on the live CASEEVENT may be triggered for a recalc
--					if it has either previously been deleted or Recalculated.
-- 08 Mar 2005	MF	11122	32	Load the USERID and IDENTITYID into the #TEMPCASES table
-- 10 Mar 2005	MF	11126	33	When looking for Events that have been satisfied, consider all of the current
--					openactions against the case and not just the Action that originally 
--					created the CaseEvent.
-- 29 Mar 2005	MF	11212	34	Revisit SQA10908.  Ensure that at least the TEMPOPENACTION or OPENACTION row
--					exists for the CriteriaNo being recalculated where an Event is being
--					pushed into a related event.
-- 30 Jun 2005	MF	11582	35	When an Event is cleared out and its due date is recalculated Policing
--					should trigger recalculations of Events that are calculated from the
--					Event date (even though it is now clear) as this may impact on whether
--					a due date is actually able to be calculated.
-- 05 Oct 2005	MF	11937	36	Satisfied events that have a manually entered due date are to be reinstated
--					as due if the satisfying event is marked for deletion.
-- 15 May 2006	MF	12315	37	New EventControl columns to update CASENAME when Event occurs.
-- 06 Jun 2006	MF	12723	38	When inserting rows into #TEMPCASES ensure that NULLs are replaced with
--					zero for RECALCULATEPTA, IPODELAY and APPLICANTDELAY
-- 07 Jun 2006	MF	12417	39	Change order of columns returned in debug mode to make it easier to review
-- 23 Jun 2006	MF	12867	40	A CaseEvent that had already occurred was being triggered to recalculate.
--					This occurred when there were multi cycles defined for the due data calculation
--					and the triggering event occurred in more than one cycle using the Relative
--					cycle rule of Current.
-- 21 Aug 2006	MF	13089	41	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 11 Sep 2006	MF	13422	42	Remove the block that stops an Event used in a date comparison from
--					triggering a recalculation if both Events have just been recalculated.  This is 
--					because the Event in the Date Comparison may have its own Date Comparison rule
--					which could have failed subsequent to the due date calculation occurring.  In 
--					this situation a recalculation is called for.
-- 10 Jan 2007	MF	12548	43	Load #TEMPCASES.OFFICEID
-- 12 Jan 2007	MF	14140	44	When Event used in Date Comparison is triggering an event to recalculate, the
--					due date calculation rules are to be extracted and the Cycle for the event to
--					recalculate determined from those rules instead of relative to the date
--					comparison rule.  This will give a similar result to a recalculation of an
--					event triggered from an Action.
-- 28 Feb 2007	PY	14425	45 	Reserved word [state]
-- 03 Jun 2007	MF	14841	46	An event that may be pushed into another related case Event should only push
--					and empty Event Date if the receiving Case Event already has an Event Date.
-- 24 May 2007	MF	14812	47	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	48	Reserve word [STATE]
-- 29 Oct 2007	MF	15518 	49	Insert LIVEFLAG on #TEMPCASEEVENT
-- 10 Apr 2008	MF	16234	50	Only change the STATE on #TEMPCASEEVENT to 'C' if the row belongs to the 
--					action that is to be recalculated.
-- 16 Apr 2008	MF	16249	51	Revisit 14812 to better handle Events under multiple Actions.
-- 28 Oct 2008	MF	17073	52	Improve performance by loading DUEDATECALC rows into a temporary table.
-- 13 Nov 2008	MF	17115	53	Date not being triggered to recalculate
-- 16 Dec 2008	MF	17231	54	Incorrect cycle being returned for event to recalculate when the CaseEvent had
--					previously been marked for deletion.
-- 30 Jun 2009	MF	17839	55	Policing looping problem when two Events referencing each other in a particular way. Related
--					to SQA11582
-- 27 Jul 2009	MF	17922	56	Ensure rows inserted into #TEMPCASEEVENT have the ACTION column initialised to the same as CREATEDBYACTION.
-- 10 Aug 2009	MF	17935	57	Correct collation error on #TEMPDUEDATECALC
-- 27 Aug 2009	MF	17980	58	Where there is potential for multiple cycles of an event to be triggered for recalculation
--					then we need to ensure that there is an appropriate OpenAction in existence to allow
--					the recalculation to occur. Related to SQA10917.
-- 11 Sep 2009	MF	18028	59	In a sense this is a revisit of 14140 that adds back in the code that was removed at that time as an 
--					additional step.  When a Comparison Event changes and triggers a recalculation of an Event then we also
--					need to consider the explicit Cycle calculated by the cycle of the comparison Event.
-- 16 Sep 2009	MF	17773	60	An Event that may push a date into another Case is also now able to push an official number into the
--					same Case.
-- 15 Jan 2010	MF	18182	61	An Event that has been loaded from a related Case is to also be updated if the parent Case's event
--					date is modified.
-- 20 Jan 2010	MF	18388	62	Backfill #TEMPDUEDATECALC with rules for the next higher cycle to those rows that we know will trigger
--					calculations.  This will allow the algorithm to check that the due date calculation being used is for the
--					correct cycle.
-- 16 Mar 2010	MF	18552	63	Retrofit of SQA18182
--					An Event that has been loaded from a related Case is to also be updated if the parent Case's event
--					date is modified.
-- 16 Apr 2010	MF	18633	64	Policing crashed because a Case was related to itself and was trying to push an Event. While it is not legal 
--					for a Case to be related to itself the problem did occur as a result of badly converted data. A change here will
--					avoid this in the future.
-- 19 May 2010	MF	18756	65	Added query Option (Force Order) to SELECT to improve performance.
-- 01 Jul 2010	MF	18758	66	Increase the column size of Instruction Type to allow for expanded list.
-- 26 Oct 2010	MF	19137	67	An event that is used in a Not Exists comparison rule should trigger the calculation of Events that have not occurred.
-- 01 Jul 2011	MF	10929	68	Keep track of when the CASES and PROPERTY rows were last updated so that we can check that no changes
--					have been applied to the database when Policing attempts to update these.
-- 13 Sep 2011	MF	R11285	69	Satisfied event with saved due date is not being reset to due when satisfying event is cleared out. This occurred when
--					the Satsified By rule was for a different Action to the Action that calculated the Event.
-- 13 Sep 2011	MF	R11288	67	Changes requiring a related Case to be recalculated are not correctly loading the #TEMPCASEEVENT and #TEMPOPENACTION
--					table for the related Case.
-- 20 Sep 2011	MF	19997	68	Event with multiple cycle calculations is not being triggered from an Event in the date comparison rule.
-- 23 Sep 2011	MF	R11325	70	Removing an Event that satisfied another Event that had it due date manually entered is not reinstating the manually
--					entered due date. This problem occurred only when the manually entered due date did not also have a due date calculation.
-- 30 Sep 2011	MF	R11370	71	When an Event Date is manually cleared out but a due date continues to exist then the procedure was not correctly
--					triggering the recalculation of an Event that was satisfied by the Event that was just cleared. 
-- 18 Oct 2011	MF	18798	72	Use OPTION(MAXDOP 1) to manually set the Maximum Degrees of Parallelism to a single processor. This will allow
--					the database to be set to use parallelism but those complex problem queries with this option will then
--					revert to no parallelism in order to get enhanced performance.
-- 12 Dec 2011	MF	R11682	73	When a CaseEvent exists multiple times because it is referenced by more than one Action then the OCCURREDFLAG should
--					only be set to zero if the STATE column is being changed. This is because on the #TEMPCASEEVENT row for the explicit
--					Action will be flagged to recalculate.
-- 13 Dec 2011	MF	R11684	74	Some event cycles were being returned prematurely for calculations where the Due Date Calculation had rules for multiple
--					countries because the country of the DueDateCalc was not being considered in some instances.
-- 30 Mar 2012	MF	R12128	75	This procedure was corrected at the same time as RFC12128 although not directly related. Discovered that the ACTION on the 
--					#TEMPCASEEVENT row was being modified which was incorrect and ultimately resulting in the same row for the original Action 
--					being reinserted
-- 02 Apr 2012	MF	R12137	76	Revisit of RFC11325. When an Event is being triggered to recalculate, ensure the OpenAction exists that is appropriate to the
--					of the CaseEvent.
-- 07 Jun 2012	MF	S19252	77	Provide an option to enable Events that may recalculate after they have occurred to be triggered as a result of changes to the
--					governing date.
-- 12 Jun 2012	MF	R12407	77	Revisit R12128.  Allow the Action to be changed for an event being recalculated if the original #TEMPCASEEVENT row is flagged
--					to be deleted even though the Action is different from the Action that caused the recalculation.
-- 25 Jun 2012	MF	R12447	78	When inserting a new #TEMPCASEEVENT row to calculate, get the COUNTRYCODE associated with the Case rather than the due date rule
--					to reduce the possibilty of creating additional rows for the same CASEID, EVENTNO, CYCLE
-- 13 Jul 2012	MF	R12518	79	An Event that has its DueDateSaved flag set on and is able to have its saved due date reinstated because a satisfying event has been
--					removed, should have its STATE changed to 'C' instead of 'R'. Policing will know not to recalculate the row because of the DueDateSaved
--					flag. This change will then ensure any other Events that can be triggered from the reinstated date will occur.
-- 30 Aug 2012	MF	R12679	80	If an Event is to be recalculated after the removal of a Satisfying Event then consideration should be given to the cycle of the OpenAction
--					under which the Event is to be calculated.
-- 03 Sep 2012	MF	R12690	81	Child case getting date from Parent is not always being triggered to recalculate if Parent & Child Cases are recalculated together. This was
--					because #TEMPCASEEVENT not being checked for the child case.
-- 20 Mar 2013	MF	S21294	82	This is actually a revisit of RFC 12679. That correction extended the recalculation of CaseEvents for other cycles but failed to check that an
--					Open Action for that Cycle exists to allow the calculation. The result was that due dates without an appropriate OpenAction are being calculated.
-- 10 Apr 2013	MF	R13246	83	When the Event that was satisfied has a manually entered due date and the satisfying rule is defined in different Action to the Action that 
--					contains the due date calculation the OCCURREDFLAG was staying as 8 instead of being reset to 0 when the Event was triggered to recalculate.
-- 30 May 2013	MF	R13545	84	Date Comparison rules are not able to be specified for a particular Country or Cycle whereas Due Date Calculations are able.  When an event is
--					being triggered to calculate because an Event referenced in the Date Comparison has changed, then we need to also consider the cycles that could
--					be calculated for a country that matches the Case. Currently the Date Comparison rule with no country was being used to also determine the cycles.
-- 06 Jun 2013	MF	S21404	85	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 13 Sep 2013	MF	R13755	86	Satisfying event rules currently consider all Actions for the case even if they are closed. This is correct however of the Action is cyclic
--					and there are open cycles available then the closed cycles will be ignored. This is because it is possible for the CRITERIANO to be different
--					for the open cycles compared to the older closed cycles.
-- 20 Oct 2014	MF	R40624	85	An Event triggered to calculate may already exist in #TEMPCASEEVENT under a different (and potentially incorrect) Action. Allow a new row to 
--					flag the calculation of the EventNo to be inserted for the correct Action.
-- 19 Nov 2014	MF	R40815	86	An Event that has been deleted may trigger the recalculation of another Event, however this does not occur if the other event is already flagged
--					to be deleted.  This however is not taking into consideration if the triggering rule is a date comparison rule of NOT EXISTS. In this situation
--					the deletion of the triggering event may in fact allow the other Event to now calculate.
-- 08 May 2015	MF	R47384	87	A situation arose in some databases where RFC40815 resulted in what appeared to be endless looping occurring.  The issue resulted from a rule
--					where an event being deleted is triggering the calculation of the next cycle of the same event which then fails to calculate and is marked
--					for deletion and then triggers the next cycle again.  If the NumberOfCycles allowed is a huge number (e.g. 9999) then the system will appear to
--					loop. The problem is being resolved by only triggering a recalculation from an event being marked as Deleted, if the event to be recalculated
--					already exists, or if the deleted event is being explicitly used in a Not Exists date comparison rule.
-- 03 Jul 2015	MF	R50806	88	Performance problem on a client database with a large number of DUEDATECALC rows. Refactored code to improve.
-- 15 Mar 2017	MF	70049	89	Allow Renewal Status to be separately specified to be updated by an Event.
-- 08 Feb 2018	MF	73065	90	When parent case event date has changed and needs to be pused down to child, we need to consider the possibility that the child case has more
--					than one related case, in which case the earliest date is taken.
-- 18 Jul 2018	MF	74547	91	Revisit of 73065.  Case Event to be triggered to recalculate, was not correctly checking to see if the date was actually being changed.
-- 17 Aug 2018	MF	74735	92	The change introduced with 73065 to handle multiple related Case with the same relationship broke the ability to push the removal of a date
--					down into a related Case.
-- 14 Nov 2018  AV	DR-45358 93	Date conversion errors when creating cases and opening names in Chinese DB
-- 12 Dec 2018	DL	DR-45709 94	Performance enhancement 
-- 26 Aug 2019	MF	DR-51282 95	Revisit of DR-45358 as one date format had not been changed from 113 to 126.
-- 29 Nov 2019	MF	DR-54681 96	Problems caused when an Event exists against multiple Actions. Each TEMPCASEEVENT records the ACTION the Event exists under.  This ACTION was being 
--					changed at times and as a result caused another TEMPCASEEVENT row to be inserted for that same ACTION resulting in exponential growth of TEMPCASEEVENT.
--					The ACTION should not have been changed.
-- 19 May 2020	DL	DR-58943 97	Ability to enter up to 3 characters for Number type code via client server	


set nocount on

-- Create a temporary table to load the Due Date calculation rules that will apply.  This will
-- leave only the relevant rules for the specific country and cycle and avoid the use of 
-- complex sub-select that are causing a performance drain

-- Create a temporary table to load all of the events that are potentially required to calculate

	create table #TEMPEVENTSTOCALCULATE (
		CASEID			int, 
		EVENTNO			int,
		CYCLE			smallint, 
		CRITERIANO		int,
		ACTION			nvarchar(2)	collate database_default ,
		COUNTRYCODE		nvarchar(3)	collate database_default ,
		UPDATEFROMPARENT	tinyint		NULL,
		PARENTEVENTDATE		datetime	NULL,
		PARENTADJUSTMENT	nvarchar(4)	collate database_default NULL,
		USERID			nvarchar(255)	collate database_default NULL,
		GOVERNINGEVENTNO	int		NULL,
		GOVERNINGCYCLE		smallint	NULL,
                INSTRUCTIONTYPE         nvarchar(3)     collate database_default NULL,
                FLAGNUMBER              smallint	NULL,
		IDENTITYID		int		NULL,
		LOADNUMBERTYPE		nvarchar(3)	collate database_default NULL,
		PARENTNUMBER		nvarchar(36)	collate database_default NULL
	)

	CREATE CLUSTERED INDEX XPKTEMPEVENTSTOCALCULATE ON #TEMPEVENTSTOCALCULATE
 	(
        	CASEID,
		EVENTNO,
		CYCLE
 	)
		
-- Create a temporary table to hold the potential DueDateCalc row. This has been done
-- as a performance improvement measure discovered on a database where there were over
-- 120,000 DUEDATECALC rows.
	Create table #TEMPDUEDATECALC(
		CRITERIANO	int		NOT NULL,
		EVENTNO		int		NOT NULL,
		COUNTRYCODE	nvarchar(3)	collate database_default NOT NULL,
		CYCLENUMBER	smallint	NULL,
 		FROMEVENT	int		NULL,
 		RELATIVECYCLE	smallint	NULL,
 		EVENTDATEFLAG	smallint	NULL,
 		COMPAREEVENT	int		NULL,
 		COMPARECYCLE	smallint	NULL,
 		COMPARISON	nvarchar(2)	collate database_default NULL )


	-- DR-45709 Temp table to hold events that have a Related Case relationship to this Case
	Create table #EVENTRELATEDCASES(
		CASEID			int,
		RELATIONSHIP	nvarchar(6) collate database_default,
		EVENTNO			int,
		CYCLE			smallint,
		NEWEVENTDATE	datetime,
		USERID			nvarchar(255)	collate database_default,
		IDENTITYID		int	)


DECLARE		@ErrorCode	int,
		@nRowCount	int,
		@nRowCount2	int,
		@nRelateCases	int,
		@nGetParent	tinyint,
	@sSQLString		nvarchar(max),
	@sRecalcEventDate	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- If due date calc rules makes reference to a related case then load the
-- related Case and associated CaseEvents into the temporary table
If @ErrorCode =0
Begin
	Set @sSQLString="
	insert #TEMPCASES (CASEID, STATUSCODE, RENEWALSTATUS, REPORTTOTHIRDPARTY, PREDECESSORID, ACTION,  
			   EVENTNO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
			   BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE,RENEWALTYPE, INSTRUCTIONSLOADED,IPODELAY,
			   APPLICANTDELAY,USERID,IDENTITYID,OFFICEID,CASELOGSTAMP,PROPERTYLOGSTAMP)

	select	distinct C.CASEID, C.STATUSCODE, P.RENEWALSTATUS, C.REPORTTOTHIRDPARTY,C.PREDECESSORID, null, 
			 null, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE,
			 P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, 0,isnull(C.IPODELAY,0),
			 isnull(C.APPLICANTDELAY,0),TC.USERID,TC.IDENTITYID,C.OFFICEID,C.LOGDATETIMESTAMP,P.LOGDATETIMESTAMP
	From #TEMPCASEEVENT TC
	join DUEDATECALC DD	on (DD.COMPAREEVENT =TC.EVENTNO)
	join RELATEDCASE RC	on (RC.RELATEDCASEID=TC.CASEID
				and RC.RELATIONSHIP =DD.COMPARERELATIONSHIP
				and(RC.CYCLE=TC.CYCLE or RC.CYCLE is null))
	join OPENACTION O	on (O.CASEID	  =RC.CASEID
				and O.CRITERIANO  =DD.CRITERIANO
				and O.POLICEEVENTS=1)
	join EVENTCONTROL E	on (E.CRITERIANO=DD.CRITERIANO 
				and E.EVENTNO=DD.EVENTNO)
	join CASES C		on (C.CASEID=RC.CASEID)
	left join PROPERTY P	on (P.CASEID=C.CASEID)
	left join #TEMPCASES T	on (T.CASEID=C.CASEID)
	where TC.[STATE] in ('R', 'I', 'D')
	and T.CASEID is null"

	Execute @ErrorCode=sp_executesql @sSQLString

	Set @nRelateCases=@@RowCount
End

-- If new Cases were loaded then load the associated CaseEvents

If @ErrorCode=0
and @nRelateCases>0
Begin	
	-- Load the #TEMPOPENACTIONS table
	Set @sSQLString="
	insert #TEMPOPENACTION
		(CASEID, ACTION, CYCLE, LASTEVENT, CRITERIANO, DATEFORACT, NEXTDUEDATE, POLICEEVENTS,
		 STATUSCODE, STATUSDESC, DATEENTERED, DATEUPDATED, CASETYPE, PROPERTYTYPE, COUNTRYCODE,
		 CASECATEGORY, SUBTYPE, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE, RENEWALTYPE,
		 CASEOFFICEID, NEWCRITERIANO, [STATE], USERID,IDENTITYID)
	select	distinct OA.CASEID,OA.ACTION,OA.CYCLE,OA.LASTEVENT,OA.CRITERIANO,OA.DATEFORACT,OA.NEXTDUEDATE,OA.POLICEEVENTS,
		OA.STATUSCODE,OA.STATUSDESC,OA.DATEENTERED,OA.DATEUPDATED,C.CASETYPE,C.PROPERTYTYPE,C.COUNTRYCODE,
		C.CASECATEGORY,C.SUBTYPE,P.BASIS,P.REGISTEREDUSERS,C.LOCALCLIENTFLAG,P.EXAMTYPE,P.RENEWALTYPE,
		C.OFFICEID,OA.CRITERIANO, 'C1', TC.USERID,TC.IDENTITYID
	from	#TEMPCASES TC
	join    OPENACTION OA  on (OA.CASEID    =TC.CASEID)
	join 	ACTIONS    A   on (A.ACTION     =OA.ACTION)
	join	CASES	   C   on (C.CASEID     =TC.CASEID)
	left join PROPERTY P   on (P.CASEID     =TC.CASEID)
	left join STATUS   S   on (S.STATUSCODE =C.STATUSCODE)
	left join STATUS   S1  on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join #TEMPOPENACTION TOA	on (TOA.CASEID=OA.CASEID
					and TOA.ACTION=OA.ACTION
					and TOA.CYCLE =OA.CYCLE)
	where	TOA.CASEID is null  -- Only load TEMPOPENACTION if it is not already loaded
	and	OA.POLICEEVENTS=1
	and    ((A.ACTIONTYPEFLAG  =0 and (S.POLICEOTHERACTIONS=1 or S.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =2 and (S.POLICEEXAM        =1 or S.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =1 and (S.POLICERENEWALS    =1 or S.STATUSCODE  is null) 
	                              and (S1.POLICERENEWALS   =1 or S1.STATUSCODE is null)))"

	Exec @ErrorCode=sp_executesql @sSQLString

	If @ErrorCode=0
		Execute @ErrorCode=ip_PoliceGetEventsForTempTable @pnDebugFlag
End

If @ErrorCode=0
Begin
	-- Load the DUEDATECALC row that are potentially required.  This is a performance improvement step
	-- for large batches of Cases being policed.
	Exec("
	insert into  #TEMPDUEDATECALC(CRITERIANO,EVENTNO,CYCLENUMBER,COUNTRYCODE,FROMEVENT,RELATIVECYCLE,EVENTDATEFLAG,COMPAREEVENT,COMPARECYCLE,COMPARISON)
	select DD.CRITERIANO,DD.EVENTNO,DD.CYCLENUMBER,isnull(DD.COUNTRYCODE,'000'),DD.FROMEVENT,DD.RELATIVECYCLE,DD.EVENTDATEFLAG,DD.COMPAREEVENT,DD.COMPARECYCLE,DD.COMPARISON
	From	#TEMPCASEEVENT	TC
	join	#TEMPOPENACTION T   on ( T.CASEID	=TC.CASEID
				    and  T.POLICEEVENTS	=1
				    and  T.[STATE] 	<>'E')	
	join	DUEDATECALC	DD  on (DD.CRITERIANO	=T.NEWCRITERIANO
				    and DD.FROMEVENT	=TC.EVENTNO
									-- If the Due Date calculation  
									-- specifies a Country then it  
									-- must match the Country of the
									-- case.			
				    and(DD.COUNTRYCODE	=T.COUNTRYCODE 
				     or(DD.COUNTRYCODE is null and DD.COMPARISON is not null)
				     or(DD.COUNTRYCODE is null and not exists (	select * from DUEDATECALC DD1
										where DD1.CRITERIANO =DD.CRITERIANO
										and   DD1.EVENTNO    =DD.EVENTNO
										and   DD1.COUNTRYCODE=T.COUNTRYCODE))
						))
	WHERE TC.[STATE] in ('R', 'I', 'D')
	UNION
	select DD.CRITERIANO,DD.EVENTNO,DD.CYCLENUMBER,isnull(DD.COUNTRYCODE,'000'),DD.FROMEVENT,DD.RELATIVECYCLE,DD.EVENTDATEFLAG,DD.COMPAREEVENT,DD.COMPARECYCLE,DD.COMPARISON
	From	#TEMPCASEEVENT	TC
	join	#TEMPOPENACTION T   on ( T.CASEID	=TC.CASEID
				    and  T.POLICEEVENTS	=1
				    and  T.[STATE] 	<>'E')	
	join	DUEDATECALC	DD1 on (DD1.CRITERIANO	=T.NEWCRITERIANO
				    and DD1.COMPAREEVENT=TC.EVENTNO)
					-- Now get the actual due date calculation rules for event 
					-- triggered by the date comparison.
	join	DUEDATECALC	DD  on (DD.CRITERIANO=DD1.CRITERIANO
				    and DD.EVENTNO   =DD1.EVENTNO)
	WHERE TC.[STATE] in ('R', 'I', 'D')
	UNION
	select DD.CRITERIANO,DD.EVENTNO,DD.CYCLENUMBER,isnull(DD.COUNTRYCODE,'000'),DD.FROMEVENT,DD.RELATIVECYCLE,DD.EVENTDATEFLAG,DD.COMPAREEVENT,DD.COMPARECYCLE,DD.COMPARISON
	From	#TEMPCASEEVENT	TC
	join	#TEMPOPENACTION T   on ( T.CASEID	=TC.CASEID
				    and  T.POLICEEVENTS	=1
				    and  T.[STATE] 	<>'E')	
	join	DUEDATECALC	DD  on (DD.CRITERIANO	=T.NEWCRITERIANO
				    and DD.COMPAREEVENT=TC.EVENTNO)
	WHERE TC.[STATE] in ('R', 'I', 'D')
	UNION
	select DD.CRITERIANO,DD.EVENTNO,DD.CYCLENUMBER,isnull(DD.COUNTRYCODE,'000'),DD.FROMEVENT,DD.RELATIVECYCLE,DD.EVENTDATEFLAG,DD.COMPAREEVENT,DD.COMPARECYCLE,DD.COMPARISON
	From	#TEMPCASEEVENT	TC
		-- We are only interested in calculating Events that are attached to an Open Action.	
	join	#TEMPOPENACTION T   on ( T.CASEID	=TC.CASEID
				    and  T.POLICEEVENTS	=1
				    and  T.[STATE] 	<>'E')
		-- Now get the possible Events that may be calculated.	
	join	DUEDATECALC	DD  on (DD.CRITERIANO	=T.NEWCRITERIANO
				    and((DD.FROMEVENT   =TC.EVENTNO AND DD.RELATIVECYCLE in (3,4)) OR
					(DD.COMPAREEVENT=TC.EVENTNO AND DD.COMPARECYCLE in (3,4)))
					-- The event to be calculated cannot be the same as the	
					-- event triggering the calc. To avoid a loop occurring.	
				    and DD.EVENTNO <> TC.EVENTNO
					-- If the Due Date calculation specifies a Country then it  
					-- must match the Country of the case.			
				    and(DD.COUNTRYCODE	=T.COUNTRYCODE 
				     or(DD.COUNTRYCODE is null and DD.COMPARISON is not null)
				     or(DD.COUNTRYCODE is null and not exists (	select * from DUEDATECALC DD1
										where DD1.CRITERIANO =DD.CRITERIANO
										and   DD1.EVENTNO    =DD.EVENTNO
										and   DD1.COUNTRYCODE=T.COUNTRYCODE))
					))
	WHERE TC.[STATE] in ('R', 'I')
	UNION
	select DD1.CRITERIANO,DD1.EVENTNO,DD1.CYCLENUMBER,isnull(DD1.COUNTRYCODE,'000'),DD1.FROMEVENT,DD1.RELATIVECYCLE,DD1.EVENTDATEFLAG,DD1.COMPAREEVENT,DD1.COMPARECYCLE,DD1.COMPARISON
	From	#TEMPCASEEVENT	TC
		-- We are only interested in calculating Events that are attached to an Open Action.	
	join	#TEMPOPENACTION T   on ( T.CASEID	=TC.CASEID
				    and  T.POLICEEVENTS	=1
				    and  T.[STATE] 	<>'E')
		-- Now get the possible Events that may be calculated.	
	join	DUEDATECALC	DD  on (DD.CRITERIANO	=T.NEWCRITERIANO
				    and((DD.FROMEVENT   =TC.EVENTNO AND DD.RELATIVECYCLE in (3,4)) OR
					(DD.COMPAREEVENT=TC.EVENTNO AND DD.COMPARECYCLE in (3,4)))
					-- The event to be calculated cannot be the same as the	
					-- event triggering the calc. To avoid a loop occurring.	
				    and DD.EVENTNO <> TC.EVENTNO
					-- If the Due Date calculation specifies a Country then it  
					-- must match the Country of the case.			
				    and(DD.COUNTRYCODE	=T.COUNTRYCODE 
				     or(DD.COUNTRYCODE is null and DD.COMPARISON is not null)
				     or(DD.COUNTRYCODE is null and not exists (	select * from DUEDATECALC DD1
										where DD1.CRITERIANO =DD.CRITERIANO
										and   DD1.EVENTNO    =DD.EVENTNO
										and   DD1.COUNTRYCODE=T.COUNTRYCODE))
					))
					-- Now get the Due Date Calcs defined for specific Cycles	
	join 	DUEDATECALC   	DD1 on (DD1.CRITERIANO=DD.CRITERIANO
				    and DD1.EVENTNO   =DD.EVENTNO
				    and DD1.COMPARISON is null
				    and(DD1.COUNTRYCODE=T.COUNTRYCODE  OR (DD1.COUNTRYCODE is null and DD.COUNTRYCODE is null))
				    and(DD1.CYCLENUMBER=DD.CYCLENUMBER OR DD.COMPARISON is not null))
	WHERE TC.[STATE] in ('R', 'I')
	OPTION (MAXDOP 1)
	
	
	CREATE INDEX XIE1TEMPDUEDATECALC ON #TEMPDUEDATECALC
	(
		CRITERIANO	ASC,
		EVENTNO		ASC,
		COUNTRYCODE	ASC
	)")
	
End

If @ErrorCode=0
Begin
	-------------------------------------------------
	-- SQS19252
	-- Additional code may be required if the option
	-- to allow events that have already occurred is
	-- turned on for the Event and the Site Control.
	-------------------------------------------------
	If @pbRecalcEventDate=1
		Set @sRecalcEventDate='  OR (TC1.RECALCEVENTDATE=1 AND TC1.SAVEDUEDATE between 2 and 5 and TC1.[STATE]=''X''))'
	Else
		Set @sRecalcEventDate=')'
	
	-- SQA18388
	-- Load the next highest DUEDATECALC cycle for any previously loaded DUEDATCALC row.
	-- This is required so that we can consider the next cycle rules.
	exec('
	Insert into #TEMPEVENTSTOCALCULATE (CASEID, EVENTNO, CYCLE, CRITERIANO, ACTION, COUNTRYCODE, USERID, GOVERNINGEVENTNO, GOVERNINGCYCLE, INSTRUCTIONTYPE, FLAGNUMBER,IDENTITYID)
	SELECT	distinct T.CASEID,  DD.EVENTNO,
										-- The cycle of the Event to be	
										-- calculated is determined as  
										-- follows:			

		CASE A.NUMCYCLESALLOWED
			WHEN(1) Then CASE WHEN (TC1.CYCLE is not null)
										-- a)If the Action in NON CYCLIC
										--   and a TempCaseEvent row has
										--   been returned then use its	
										--   Cycle unless it has 	
										--   occurred in which case we	
										--   increment the cycle.	
					THEN CASE WHEN (TC1.OCCURREDFLAG=0 or TC1.OCCURREDFLAG is NULL)
						THEN TC1.CYCLE
						ELSE TC1.CYCLE+1
					     END
										-- b)If the Action is NON CYCLIC
										--   and no CaseEvent row has   
										--   been returned then get the 
										--   cycle based on the Due Date
										--   calculation relative cycle.
					ELSE CASE DD.RELATIVECYCLE WHEN(0) Then TC.CYCLE
								   WHEN(1) Then TC.CYCLE+1
								   WHEN(2) Then TC.CYCLE-1
									--   When RELATIVECYCLE > 2 the 
									--   Cycle is calculated by	
									--   incrementing the current   
									--   live maximum cycle               
									   Else coalesce((select max(CE2.CYCLE)+1
											from  #TEMPCASEEVENT CE2
											where CE2.CASEID=T.CASEID
											and   CE2.LIVEFLAG=1
											and   CE2.[STATE] not like ''D%'' --SQA17231
											and   CE2.CYCLE is not null
											and   CE2.EVENTNO=DD.EVENTNO),DD.CYCLENUMBER,1)
					     END
				     END
										-- c)If the Action is CYCLIC 	
										--   then use Cycle of the Open	
										--   Action row.		
				Else T.CYCLE
		END,
	E.CRITERIANO, T.ACTION, T.COUNTRYCODE, TC.USERID, TC.EVENTNO, TC.CYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER,TC.IDENTITYID
	From		#TEMPCASEEVENT	TC
										-- We are only interested in	
										-- calculating Events that are	
										-- attached to an Open Action.	
	join		#TEMPOPENACTION T   on ( T.CASEID	=TC.CASEID
					    and  T.POLICEEVENTS	=1
					    and  T.[STATE] 	<>''E'')

										-- Now get the possible Events	
										-- that may be calculated.	

	join		#TEMPDUEDATECALC DD  on(DD.CRITERIANO	=T.NEWCRITERIANO
					    and DD.FROMEVENT	=TC.EVENTNO
										-- The event to be calculated   
										-- cannot be the same as the	
										-- event triggering the calc.   
										-- unless the relative cycle is 
										-- next or previous.  This is to
										-- avoid a loop occurring.	
					    and(DD.FROMEVENT   <>DD.EVENTNO or DD.RELATIVECYCLE in(1,2))
										-- If the Due Date calculation  
										-- specifies a Country then it  
										-- must match the Country of the
										-- case.			
					    and(DD.COUNTRYCODE	=T.COUNTRYCODE 
					     or(DD.COUNTRYCODE =''000'' and DD.COMPARISON is not null)
					     or(DD.COUNTRYCODE =''000'' and not exists (select * from #TEMPDUEDATECALC DD1
											where DD1.CRITERIANO =DD.CRITERIANO
											and   DD1.EVENTNO    =DD.EVENTNO
											and   DD1.COUNTRYCODE=T.COUNTRYCODE))
						))
										-- SQA 7053			
										-- Get the next highest cycle	
										-- defined for the due date calc
										-- to ensure that only those	
										-- Case Events within the Cycle	
										-- range are returned.
	left join 	#TEMPDUEDATECALC DD1 on(DD1.CRITERIANO=DD.CRITERIANO
					    and DD1.EVENTNO   =DD.EVENTNO			
					    and(DD1.COUNTRYCODE	=T.COUNTRYCODE 
					     or(DD1.COUNTRYCODE =''000'' and not exists (select * from #TEMPDUEDATECALC DD2
											where DD2.CRITERIANO =DD1.CRITERIANO
											and   DD2.EVENTNO    =DD1.EVENTNO
											and   DD2.COUNTRYCODE=T.COUNTRYCODE))
						)
					    and DD1.CYCLENUMBER=(	select min(CYCLENUMBER)
									from #TEMPDUEDATECALC DD2
									where DD2.CRITERIANO=DD.CRITERIANO
									and   DD2.EVENTNO=DD.EVENTNO
									and   DD2.CYCLENUMBER>DD.CYCLENUMBER
									and   DD2.COUNTRYCODE=DD.COUNTRYCODE ) )

	join		EVENTCONTROL 	E   on ( E.CRITERIANO=DD.CRITERIANO and E.EVENTNO=DD.EVENTNO)
	join		ACTIONS		A   on ( A.ACTION=T.ACTION)
										-- Check now to see if the	
										-- Event under consideration to	
										-- be calculated already exists 
	left join	#TEMPCASEEVENT 	TC1 on (TC1.CASEID =TC.CASEID
					    and TC1.EVENTNO=DD.EVENTNO
					    and TC1.CYCLE  =	CASE DD.RELATIVECYCLE	WHEN (0) Then TC.CYCLE
											WHEN (1) Then TC.CYCLE+1
											WHEN (2) Then TC.CYCLE-1
										-- If the RELATIVECYCLE is > 2	
										-- then return all cycles	
												 Else TC1.CYCLE
								END)-- SQA 7053
	WHERE	(TC.[STATE] in (''R'', ''I'')
			-- SQA7154 If the triggering Event is marked for Deletion then
			--         the Event to be calculated must not have already been 
			-- 	   marked for deletion UNLESS the triggering event is used
			--         in a Not Exists rule.
			
			-- RFC47384
			-- An event being deleted can only trigger a recalculation if the triggered
			-- event currently exists or if the deleted event could now cause the date
			-- comparison rule to be passed.
	or  	(TC.[STATE]=''D'' and (TC1.[STATE] not like ''D%'' OR DD.COMPARISON=''NE'')))
			-- Ensure that the cycle of the	CaseEvent row is within the	
			-- range of the Due Date calc	
	and (TC1.CASEID is null OR (TC1.CYCLE >=isnull(DD.CYCLENUMBER, 1)     -- SQA 7053
				and TC1.CYCLE  <isnull(DD1.CYCLENUMBER, 999)))-- SQA 7053
			-- Take into consideration whether the EVENTDUEDATE or	
			-- the EVENTDATE is required in the calculation.
	and    ((TC.NEWEVENTDATE is not null and DD.EVENTDATEFLAG in (1,3)) 
	     or (TC.NEWEVENTDATE is null     and DD.EVENTDATEFLAG in (2,3) and TC.NEWEVENTDUEDATE is not null) 
	     or (TC.OLDEVENTDATE is not null and DD.EVENTDATEFLAG in (1,3) and TC.NEWEVENTDATE    is null) 
	     or (TC.NEWEVENTDATE is null     and DD.EVENTDATEFLAG in (1,3) and isnull(DD.COMPARISON,'''')<>''NE'' and TC1.OCCURREDFLAG   =0) --SQA11582
	     or (                                DD.COMPARISON =''NE''       and isnull(TC1.OCCURREDFLAG,0)=0)				 --SQA19137
	     or  TC.[STATE]=''D'')  

	and    (DD.CYCLENUMBER<=CASE DD.RELATIVECYCLE	WHEN (0) Then TC.CYCLE			-- the due date rule to use	
							WHEN (1) Then TC.CYCLE+1		-- must have a cycle that is 	
							WHEN (2) Then TC.CYCLE-1		-- <= to the cycle of the event	
								 Else E.NUMCYCLESALLOWED	-- to be calculated.		
				 END
	 or	DD.CYCLENUMBER is null)		-- the CycleNumber can be null for Date Comparisons         

		----------------------------------------------------------------------------------------------------------------------
		-- The CaseEvent must fulfill one of the following conditions:
		-- 1. Not currently exist
		-- 2. Exists as a Due Date
		-- 3. Exists as a Cyclic Event with a Relative Cycle of First (3) or Last (4) so  that the next cycle is triggered
		-- 4. May exist if the RECALCEVENTDATE option is on and the Event has a rule showing it can be calculated and saved
		----------------------------------------------------------------------------------------------------------------------
	and   ((isnull(TC1.DATEDUESAVED,0)=0 and isnull(TC1.OCCURREDFLAG,0)=0)
	  OR	 TC1.[STATE] like ''D%'' 	-- SQA 7094 If the Event was previously marked for deletion it can be recalculated
	  OR	 TC1.[STATE] like ''R%'' 	-- SQA11115 If the Event has previously been recalculated then it can be recalculated again
	  OR   	(TC1.OCCURREDFLAG between 1 and 8 AND E.NUMCYCLESALLOWED>TC1.CYCLE AND DD.RELATIVECYCLE > 2
			and not exists
			(select * from #TEMPCASEEVENT TC2
			 where TC2.CASEID=TC1.CASEID
			 and   TC2.EVENTNO=TC1.EVENTNO
			 and   TC2.CYCLE  =TC1.CYCLE+1
			 and   TC2.OCCURREDFLAG > 0))
	'+@sRecalcEventDate+'
										-- the Cycle of the Event to be 
										-- calculated must be less than 
										-- or equal to the maximum      
										-- allowed for the Event.       
	and	E.NUMCYCLESALLOWED >=
		CASE A.NUMCYCLESALLOWED
			WHEN(1) Then CASE WHEN (TC1.CYCLE is not null)
										-- a)If the Action in NON CYCLIC
										--   and a TempCaseEvent row has
										--   been returned then use its	
										--   Cycle unless it has 	
										--   occurred in which case we	
										--   increment the cycle.	
					THEN CASE WHEN (isnull(TC1.OCCURREDFLAG,0)=0'+@sRecalcEventDate+'
						THEN TC1.CYCLE
						ELSE TC1.CYCLE+1
					     END

										-- b)If the Action is NON CYCLIC
										--   and no TempCaseEvent row has   
										--   been returned then get the 
										--   cycle based on the Due Date
										--   calculation relative cycle.
					ELSE CASE DD.RELATIVECYCLE WHEN(0) Then TC.CYCLE
								   WHEN(1) Then TC.CYCLE+1
								   WHEN(2) Then TC.CYCLE-1
									--   When RELATIVECYCLE > 2 the 
									--   Cycle is calculated by	
									--   incrementing the current   
									--   live maximum cycle              
									   Else coalesce((select max(CE2.CYCLE)+1
											from  #TEMPCASEEVENT CE2
											where CE2.CASEID=T.CASEID
											and   CE2.LIVEFLAG=1
											and   CE2.[STATE] not like ''D%''	--SQA17231
											and   CE2.CYCLE is not null
											and   CE2.EVENTNO=DD.EVENTNO),DD.CYCLENUMBER,1)
					     END
				     END
										-- c)If the Action is CYCLIC 	
										--   then use Cycle of the Open	
										--   Action row.		
				Else T.CYCLE
		END
										-- If the RelativeCycle is 2	
										-- then the Cycle of the Event  
										-- to calculate will be 1 less  
										-- than the Cycle of the Event  
										-- used in the calculation so it
										-- must be > 1 to avoid a cycle 
										-- of 0 being calculated.	
	and 	((TC.CYCLE >1 and DD.RELATIVECYCLE=2) or (DD.RELATIVECYCLE <>2))

	and	(A.NUMCYCLESALLOWED = 1 OR 
		(A.NUMCYCLESALLOWED >1 AND T.CYCLE=Case DD.RELATIVECYCLE 
								 WHEN(0) Then TC.CYCLE		-- if the action is non cyclic	
								 WHEN(1) Then TC.CYCLE+1	-- then the Event can be any    
								 WHEN(2) Then TC.CYCLE-1	-- cycle otherwise the cycle of 
								 WHEN(3) Then T.CYCLE		-- the event must match the     
									 Else T.CYCLE		-- cycle of the open action	
						    End))
		-------------------------------------------------------------
		-- The second Select is required to find the Date Comparisons 
		-- that will trigger the recalc  of Events
		-------------------------------------------------------------
	UNION
	SELECT	T.CASEID,  DD.EVENTNO,
		Case DD.RELATIVECYCLE	WHEN (0) Then CE.CYCLE
					WHEN (1) Then CE.CYCLE+1
					WHEN (2) Then CE.CYCLE-1
						 Else CASE WHEN (A.NUMCYCLESALLOWED>1)
							THEN T.CYCLE
							--   When RELATIVECYCLE > 2 the Cycle is calculated by	
							--   incrementing the current maximum cycle               
							Else coalesce((select max(CE2.CYCLE)+1
									from  #TEMPCASEEVENT CE2
									where CE2.CASEID=T.CASEID
									and   CE2.LIVEFLAG=1
									and   CE2.[STATE] not like ''D%''	--SQA17231
									and   CE2.EVENTNO=DD.EVENTNO),DD.CYCLENUMBER,1)
						     END
		End,
	E.CRITERIANO,T.ACTION,T.COUNTRYCODE,TC.USERID,TC.EVENTNO,TC.CYCLE,E.INSTRUCTIONTYPE,E.FLAGNUMBER,TC.IDENTITYID
	From		#TEMPCASEEVENT	TC
			-- We are only interested in calculating Events that are attached to an Open Action.	
	join		#TEMPOPENACTION T   on ( T.CASEID	=TC.CASEID
					    and  T.POLICEEVENTS	=1
					    and  T.[STATE] 	<>''E'')
			-- Now get the possible Events that may be calculated.	
	join		#TEMPDUEDATECALC DD1 on(DD1.CRITERIANO	=T.NEWCRITERIANO
					    and DD1.COMPAREEVENT=TC.EVENTNO
						-- The event to be calculated cannot be the same as the	
						-- event triggering the calc. unless the relative cycle is 
						-- next or previous.  This is to avoid a loop occurring.	
					    and(DD1.COMPAREEVENT<>DD1.EVENTNO or DD1.COMPARECYCLE in(1,2)))
						-- Now get the actual due date calculation rules for event 
						-- triggered by the date comparison.
	join		#TEMPDUEDATECALC DD on (DD.CRITERIANO=DD1.CRITERIANO
					    and DD.EVENTNO   =DD1.EVENTNO
					    and DD.COMPAREEVENT is null
										-- If the Due Date calculation  
										-- specifies a Country then it  
										-- must match the Country of the
										-- case.			
					    and(DD.COUNTRYCODE	=TC.COUNTRYCODE 
					     or(DD.COUNTRYCODE =''000'' and not exists (select * from #TEMPDUEDATECALC DD2
											where DD2.CRITERIANO =DD.CRITERIANO
											and   DD2.EVENTNO    =DD.EVENTNO
											and   DD2.COUNTRYCODE=TC.COUNTRYCODE))))
	join		EVENTCONTROL 	E   on ( E.CRITERIANO=DD.CRITERIANO and E.EVENTNO=DD.EVENTNO)
	join		ACTIONS		A   on ( A.ACTION=T.ACTION)
	join		#TEMPCASEEVENT  CE  on (CE.CASEID=T.CASEID
					    and CE.EVENTNO=DD.FROMEVENT)
						-- Check now to see if the Event under consideration to	
						-- be calculated already exists 
	left join	#TEMPCASEEVENT 	TC1 on (TC1.CASEID =TC.CASEID
					    and TC1.EVENTNO=DD.EVENTNO
					    and TC1.CYCLE  =	CASE DD.RELATIVECYCLE	WHEN (0) Then CE.CYCLE
											WHEN (1) Then CE.CYCLE+1
											WHEN (2) Then CE.CYCLE-1
												 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END
								END)
	WHERE	(TC.[STATE] in (''R'', ''I'')
			-- SQA7154 If the triggering Event is marked for Deletion then
			--         the Event to be calculated must not have already been 
			-- 	   marked for deletion
	 or  	(TC.[STATE]=''D'' and (TC1.[STATE] not like ''D%'' or TC1.[STATE] is null)))
			-- The cycle of the due date rule  must <= the cycle of the Event
			-- to be calculated	
	and	 DD.CYCLENUMBER<=CASE DD.RELATIVECYCLE	WHEN (0) Then CE.CYCLE
							WHEN (1) Then CE.CYCLE+1
							WHEN (2) Then CE.CYCLE-1
								 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END
				 END
			-- Take into consideration whether the EVENTDUEDATE or	
			-- the EVENTDATE is required in the calculation. Also the	
			-- RelativeCycle indicating the Next Cycle is required means	
			-- that the Cycle cannot be 1.	
	and     ((CE.NEWEVENTDATE is not null and DD.EVENTDATEFLAG in (1,3)) or (CE.NEWEVENTDUEDATE is not null and DD.EVENTDATEFLAG in (2,3)))
	and 	((CE.CYCLE >1 and DD.RELATIVECYCLE=2) or (DD.RELATIVECYCLE <>2))
		----------------------------------------------------------------------------------------------------------------------
		-- The CaseEvent must fulfill one of the following conditions:
		-- 1. Not currently exist
		-- 2. Exists as a Due Date
		-- 3. Exists as a Cyclic Event with a Relative Cycle of First (3) or Last (4) so  that the next cycle is triggered
		-- 4. May exist if the RECALCEVENTDATE option is on and the Event has a rule showing it can be calculated and saved
		----------------------------------------------------------------------------------------------------------------------
	and   ((isnull(TC1.DATEDUESAVED,0)=0 and isnull(TC1.OCCURREDFLAG,0)=0)
	  OR	 TC1.[STATE] like ''D%''
	  OR	 TC1.[STATE] like ''R%''
	  OR   	(TC1.OCCURREDFLAG between 1 and 8 AND E.NUMCYCLESALLOWED>TC1.CYCLE AND DD.COMPARECYCLE > 2
			and not exists
			(select * from #TEMPCASEEVENT TC2
			 where TC2.CASEID=TC1.CASEID
			 and   TC2.EVENTNO=TC1.EVENTNO
			 and   TC2.CYCLE  =TC1.CYCLE+1
			 and   TC2.OCCURREDFLAG > 0))
	'+@sRecalcEventDate+'
	and	(A.NUMCYCLESALLOWED = 1 OR 
		(A.NUMCYCLESALLOWED >1 AND T.CYCLE=Case DD.RELATIVECYCLE
								 WHEN(0) Then CE.CYCLE
								 WHEN(1) Then CE.CYCLE+1
								 WHEN(2) Then CE.CYCLE-1
								 WHEN(3) Then T.CYCLE
									 Else T.CYCLE
						    End))
	and	E.NUMCYCLESALLOWED >=	Case DD.RELATIVECYCLE	WHEN (0) Then CE.CYCLE
								WHEN (1) Then CE.CYCLE+1
								WHEN (2) Then CE.CYCLE-1
									 Else CASE WHEN (A.NUMCYCLESALLOWED>1)
										THEN T.CYCLE
										--   When RELATIVECYCLE > 2 the 
										--   Cycle is calculated by	
										--   incrementing the current   
										--   maximum cycle
										Else coalesce((select max(CE2.CYCLE)+1
												from  #TEMPCASEEVENT CE2
												where CE2.CASEID=T.CASEID
												and   CE2.LIVEFLAG=1
												and   CE2.[STATE] not like ''D%''	--SQA17231
												and   CE2.EVENTNO=DD.EVENTNO),DD.CYCLENUMBER,1)
									     END
					End
	OPTION (MAXDOP 1)')

	Select	@ErrorCode=@@ERROR,
		@nRowCount =@@Rowcount
End

-- SQA18028
-- Need to consider cyclic Events against a non cyclic Action being triggered by a cyclic
-- comparison Event.  These may not have been picked up for recalculation in the second
-- select of the above UNION.
If @ErrorCode=0
Begin
	Exec ('
	Insert into #TEMPEVENTSTOCALCULATE (CASEID, EVENTNO, CYCLE, CRITERIANO, ACTION, COUNTRYCODE, USERID, GOVERNINGEVENTNO, GOVERNINGCYCLE, INSTRUCTIONTYPE, FLAGNUMBER,IDENTITYID)
	SELECT	T.CASEID,  DD.EVENTNO,
		Case DD1.COMPARECYCLE	WHEN (0) Then TC.CYCLE
					WHEN (1) Then TC.CYCLE+1
					WHEN (2) Then TC.CYCLE-1
						 Else CASE WHEN (A.NUMCYCLESALLOWED>1)
							THEN T.CYCLE
							--   When RELATIVECYCLE > 2 the Cycle is calculated by	
							--   incrementing the current maximum cycle               
							Else coalesce((select max(CE2.CYCLE)+1
									from  #TEMPCASEEVENT CE2
									where CE2.CASEID=T.CASEID
									and   CE2.LIVEFLAG=1
									and   CE2.[STATE] not like ''D%''	--SQA17231
									and   CE2.EVENTNO=DD.EVENTNO),DD.CYCLENUMBER,1)
						     END
		End,
	E.CRITERIANO,T.ACTION,T.COUNTRYCODE,TC.USERID,TC.EVENTNO,TC.CYCLE,E.INSTRUCTIONTYPE,E.FLAGNUMBER,TC.IDENTITYID
	From		#TEMPCASEEVENT	TC
			-- We are only interested in calculating Events that are attached to an Open Action.	
	join		#TEMPOPENACTION T   on ( T.CASEID	=TC.CASEID
					    and  T.POLICEEVENTS	=1
					    and  T.[STATE] 	<>''E'')
			-- Now get the possible Events that may be calculated.	
	join		#TEMPDUEDATECALC DD1 on(DD1.CRITERIANO	=T.NEWCRITERIANO
					    and DD1.COMPAREEVENT=TC.EVENTNO
						-- The event to be calculated cannot be the same as the	
						-- event triggering the calc. unless the relative cycle is 
						-- next or previous.  This is to avoid a loop occurring.	
					    and(DD1.COMPAREEVENT<>DD1.EVENTNO or DD1.COMPARECYCLE in(1,2)))
						-- Now get the actual due date calculation rules for event 
						-- triggered by the date comparison.
	join		#TEMPDUEDATECALC DD on (DD.CRITERIANO=DD1.CRITERIANO
					    and DD.EVENTNO   =DD1.EVENTNO
					    and DD.COMPAREEVENT is null
										-- If the Due Date calculation  
										-- specifies a Country then it  
										-- must match the Country of the
										-- case.			
					    and(DD.COUNTRYCODE	=TC.COUNTRYCODE 
					     or(DD.COUNTRYCODE =''000'' and not exists (select * from #TEMPDUEDATECALC DD2
											where DD2.CRITERIANO =DD.CRITERIANO
											and   DD2.EVENTNO    =DD.EVENTNO
											and   DD2.COUNTRYCODE=TC.COUNTRYCODE))))
	join		EVENTCONTROL 	E   on ( E.CRITERIANO=DD.CRITERIANO 
					    and  E.EVENTNO=DD.EVENTNO
					    and  E.NUMCYCLESALLOWED>1)	-- only consider cyclic Events
	join		ACTIONS		A   on ( A.ACTION=T.ACTION
					    and  A.NUMCYCLESALLOWED=1)	-- only consider non cyclic Actions
	join		#TEMPCASEEVENT  CE  on (CE.CASEID=T.CASEID
					    and CE.EVENTNO=DD.FROMEVENT)
						-- Check now to see if the Event under consideration to	
						-- be calculated already exists as it will not be required	
						-- if it has already occurred.  
	left join	#TEMPCASEEVENT 	TC1 on (TC1.CASEID =TC.CASEID
					    and TC1.EVENTNO=DD.EVENTNO
					    and TC1.CYCLE  =	CASE DD1.COMPARECYCLE	WHEN (0) Then TC.CYCLE
											WHEN (1) Then TC.CYCLE+1
											WHEN (2) Then TC.CYCLE-1
												 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END
								END)
	left join #TEMPEVENTSTOCALCULATE TX on (TX.CASEID=TC.CASEID
					    and TX.EVENTNO=DD.EVENTNO
					    and TX.CYCLE  =	CASE DD1.COMPARECYCLE	WHEN (0) Then TC.CYCLE
											WHEN (1) Then TC.CYCLE+1
											WHEN (2) Then TC.CYCLE-1
												 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END
								END)
	WHERE	(TC.[STATE] in (''R'', ''I'')
			-- SQA7154 If the triggering Event is marked for Deletion then
			--         the Event to be calculated must not have already been 
			-- 	   marked for deletion
	 or  	(TC.[STATE]=''D'' and (TC1.[STATE] not like ''D%'' or TC1.[STATE] is null)))
			-- Check that a matching row has not already been
			-- inserted into #TEMPEVENTSTOCALCULATE
	and	TX.CASEID is null
			-- The cycle of the due date rule  must <= the cycle of the Event
			-- to be calculated	
	and	 DD.CYCLENUMBER<=CASE DD1.COMPARECYCLE	WHEN (0) Then TC.CYCLE
							WHEN (1) Then TC.CYCLE+1
							WHEN (2) Then TC.CYCLE-1
								 Else isnull(DD.CYCLENUMBER,1)
				 END
			-- Take into consideration whether the EVENTDUEDATE or	
			-- the EVENTDATE is required in the calculation. Also the	
			-- RelativeCycle indicating the Next Cycle is required means	
			-- that the Cycle cannot be 1.	
	and     ((CE.NEWEVENTDATE is not null and DD.EVENTDATEFLAG in (1,3)) or (CE.NEWEVENTDUEDATE is not null and DD.EVENTDATEFLAG in (2,3)))
	and 	((CE.CYCLE >1 and DD.RELATIVECYCLE=2) or (DD.RELATIVECYCLE <>2))
		----------------------------------------------------------------------------------------------------------------------
		-- The CaseEvent must fulfill one of the following conditions:
		-- 1. Not currently exist
		-- 2. Exists as a Due Date
		-- 3. Exists as a Cyclic Event with a Relative Cycle of First (3) or Last (4) so  that the next cycle is triggered
		-- 4. May exist if the RECALCEVENTDATE option is on and the Event has a rule showing it can be calculated and saved
		----------------------------------------------------------------------------------------------------------------------
	and   ((isnull(TC1.DATEDUESAVED,0)=0 and isnull(TC1.OCCURREDFLAG,0)=0)
	  OR	 TC1.[STATE] like ''D%''
	  OR	 TC1.[STATE] like ''R%''
	  OR   	(TC1.OCCURREDFLAG between 1 and 8 AND E.NUMCYCLESALLOWED>TC1.CYCLE AND DD.COMPARECYCLE > 2
			and not exists
			(select * from #TEMPCASEEVENT TC2
			 where TC2.CASEID=TC1.CASEID
			 and   TC2.EVENTNO=TC1.EVENTNO
			 and   TC2.CYCLE  =TC1.CYCLE+1
			 and   TC2.OCCURREDFLAG > 0))
	'+@sRecalcEventDate+'
	and	E.NUMCYCLESALLOWED >=	Case DD1.COMPARECYCLE	WHEN (0) Then TC.CYCLE
								WHEN (1) Then TC.CYCLE+1
								WHEN (2) Then TC.CYCLE-1
									 Else CASE WHEN (A.NUMCYCLESALLOWED>1)
										THEN T.CYCLE
										--   When RELATIVECYCLE > 2 the 
										--   Cycle is calculated by	
										--   incrementing the current   
										--   maximum cycle
										Else coalesce((select max(CE2.CYCLE)+1
												from  #TEMPCASEEVENT CE2
												where CE2.CASEID=T.CASEID
												and   CE2.LIVEFLAG=1
												and   CE2.[STATE] not like ''D%''	--SQA17231
												and   CE2.EVENTNO=DD.EVENTNO),DD.CYCLENUMBER,1)
									     END
					End option (force order, MAXDOP 1)')

	Select 	@ErrorCode=@@Error,
		@nRowCount=@nRowCount+@@Rowcount
	
End

-- SQA10931 
-- Case Events in related cases may be referred to in a Date Comparison test.  Whenever an Event has
-- either occurred or been cleared out we need to check if this Case Event should trigger a recalculation
-- of another CaseEvent whose date comparison rule refers to this Case Event just changed.

if @ErrorCode=0
Begin
	Exec ('
	Insert into #TEMPEVENTSTOCALCULATE (CASEID, EVENTNO, CYCLE, CRITERIANO, ACTION, COUNTRYCODE, USERID, GOVERNINGEVENTNO, GOVERNINGCYCLE, INSTRUCTIONTYPE, FLAGNUMBER,IDENTITYID)
	SELECT	RC.CASEID,  DD.EVENTNO,
										-- The cycle of the Event to be	
										-- calculated is determined as  
										-- follows:			
		CASE A.NUMCYCLESALLOWED
			WHEN(1) Then CASE WHEN (TC1.CYCLE is not null)
										-- a)If the Action in NON CYCLIC
										--   and a TempCaseEvent row has
										--   been returned then use its	
										--   Cycle unless it has 	
										--   occurred in which case we	
										--   increment the cycle.	
					THEN CASE WHEN (TC1.OCCURREDFLAG=0 or TC1.OCCURREDFLAG is NULL)
						THEN TC1.CYCLE
						ELSE TC1.CYCLE+1
					     END

										-- b)If the Action is NON CYCLIC
										--   and no CaseEvent row has   
										--   been returned then get the 
										--   cycle based on the Due Date
										--   calculation relative cycle.
					ELSE CASE DD.COMPARECYCLE  WHEN(0) Then TC.CYCLE
								   WHEN(1) Then TC.CYCLE+1
								   WHEN(2) Then TC.CYCLE-1
									--   When RELATIVECYCLE > 2 the 
									--   Cycle is calculated by	
									--   incrementing the current   
									--   maximum cycle                 
									   Else coalesce((select max(CE2.CYCLE)+1
											from  #TEMPCASEEVENT CE2
											where CE2.CASEID=RC.CASEID
											and   CE2.LIVEFLAG=1
											and   CE2.[STATE] not like ''D%'' --SQA17231
											and   CE2.CYCLE is not null
											and   CE2.EVENTNO=DD.EVENTNO),DD.CYCLENUMBER,1)
					     END
				     END
										-- c)If the Action is CYCLIC 	
										--   then use Cycle of the Open	
										--   Action row.		
				Else isnull(T.CYCLE,O.CYCLE)
		END,
	E.CRITERIANO, A.ACTION, C.COUNTRYCODE, TC.USERID, TC.EVENTNO, TC.CYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER,TC.IDENTITYID
	From		#TEMPCASEEVENT	TC
	join 		DUEDATECALC	DD  on (DD.COMPAREEVENT =TC.EVENTNO)
	join		RELATEDCASE     RC  on (RC.RELATEDCASEID=TC.CASEID
					    and RC.RELATIONSHIP =DD.COMPARERELATIONSHIP
					    and(RC.CYCLE=TC.CYCLE or RC.CYCLE is null))
	join		CASES           C   on (C.CASEID=RC.CASEID)
										-- We are only interested in	
										-- calculating Events that are	
										-- attached to an Open Action.	
	left join	#TEMPOPENACTION T   on ( T.CASEID	=RC.CASEID
					    and  T.NEWCRITERIANO=DD.CRITERIANO
					    and  T.[STATE] 	<>''E'')	
	left join	OPENACTION      O   on ( O.CASEID	=RC.CASEID
					    and  O.CRITERIANO   =DD.CRITERIANO
					    and  O.POLICEEVENTS	=1)
	
	join		EVENTCONTROL 	E   on ( E.CRITERIANO=DD.CRITERIANO 
					    and  E.EVENTNO=DD.EVENTNO)
	join		ACTIONS		A   on ( A.ACTION=isnull(T.ACTION, O.ACTION))
										-- Check now to see if the	
										-- Event under consideration to	
										-- be calculated already exists 
										-- as it will not be required	
										-- if it has already occurred.  
	left join	#TEMPCASEEVENT 	TC1 on (TC1.CASEID =RC.CASEID
					    and TC1.EVENTNO=DD.EVENTNO
					    and TC1.CYCLE  =	CASE DD.COMPARECYCLE	WHEN (0) Then TC.CYCLE
											WHEN (1) Then TC.CYCLE+1
											WHEN (2) Then TC.CYCLE-1
										-- If the RELATIVECYCLE is > 2	
										-- then return all cycles	
												 Else TC1.CYCLE
								END)
	WHERE	(TC.[STATE] in (''R'', ''I'', ''D'')
			-- SQA7154 If the triggering Event is marked for Deletion then
			--         the Event to be calculated must not have already been 
			-- 	   marked for deletion
	 or  	(TC.[STATE]=''D'' and (TC1.[STATE] not like ''D%'' or TC1.[STATE] is null)))
			-- An open TEMPOPENACTION row must exist or if there is no 
			-- row at all then it must be open in the OPENACTION table
	and	isnull(T.POLICEEVENTS, O.POLICEEVENTS)=1
			-- Take into consideration whether the EVENTDUEDATE or	
			-- the EVENTDATE is required in  the calculation. 
	and     DD.COMPAREEVENTFLAG=1

		----------------------------------------------------------------------------------------------------------------------
		-- The CaseEvent must fulfill one of the following conditions:
		-- 1. Not currently exist
		-- 2. Exists as a Due Date
		-- 3. Exists as a Cyclic Event with a Relative Cycle of First (3) or Last (4) so  that the next cycle is triggered
		-- 4. May exist if the RECALCEVENTDATE option is on and the Event has a rule showing it can be calculated and saved
		----------------------------------------------------------------------------------------------------------------------
	and   ((isnull(TC1.DATEDUESAVED,0)=0 and isnull(TC1.OCCURREDFLAG,0)=0)
	  OR	 TC1.[STATE] like ''D%'' 	-- SQA 7094 If the Event was previously marked for deletion it can be recalculated
	  OR   	(TC1.OCCURREDFLAG between 1 and 8 AND E.NUMCYCLESALLOWED>TC1.CYCLE AND DD.COMPARECYCLE > 2
			and not exists
			(select * from #TEMPCASEEVENT TC2
			 where TC2.CASEID=TC1.CASEID
			 and   TC2.EVENTNO=TC1.EVENTNO
			 and   TC2.CYCLE  =TC1.CYCLE+1
			 and   TC2.OCCURREDFLAG > 0))
	'+@sRecalcEventDate+'

			-- If the CompareCycle is 2 then the Cycle of the Event  
			-- to calculate will be 1 less than the Cycle of the Event  
			-- used in the calculation so it must be > 1 to avoid a cycle 
			-- of 0 being calculated.	
	and 	((TC.CYCLE >1 and DD.COMPARECYCLE=2) or (DD.COMPARECYCLE <>2))

	and	(A.NUMCYCLESALLOWED = 1 OR 
		(A.NUMCYCLESALLOWED >1 AND isnull(T.CYCLE,O.CYCLE)=
							Case DD.COMPARECYCLE
								WHEN(0) Then TC.CYCLE	-- if the action is non cyclic	
								WHEN(1) Then TC.CYCLE+1	-- then the Event can be any    
								WHEN(2) Then TC.CYCLE-1	-- cycle otherwise the cycle of 
								WHEN(3) Then isnull(T.CYCLE,O.CYCLE)-- the event must match the     
									Else isnull(T.CYCLE,O.CYCLE)-- cycle of the open action	
							End))
			-- the Cycle of the Event to be calculated must be less than 
			-- or equal to the maximum allowed for the Event.       
	and	E.NUMCYCLESALLOWED >=
		CASE A.NUMCYCLESALLOWED
			WHEN(1) Then CASE WHEN (TC1.CYCLE is not null)
										-- a)If the Action in NON CYCLIC
										--   and a TempCaseEvent row has
										--   been returned then use its	
										--   Cycle unless it has 	
										--   occurred in which case we	
										--   increment the cycle.	
					THEN CASE WHEN (TC1.OCCURREDFLAG=0 or TC1.OCCURREDFLAG is NULL)
						THEN TC1.CYCLE
						ELSE TC1.CYCLE+1
					     END
										-- b)If the Action is NON CYCLIC
										--   and no CaseEvent row has   
										--   been returned then get the 
										--   cycle based on the Due Date
										--   calculation relative cycle.
					ELSE CASE DD.COMPARECYCLE  WHEN(0) Then TC.CYCLE
								   WHEN(1) Then TC.CYCLE+1
								   WHEN(2) Then TC.CYCLE-1
									--   When RELATIVECYCLE > 2 the 
									--   Cycle is calculated by	
									--   incrementing the current   
									--   live maximum cycle              
									   Else coalesce((select max(CE2.CYCLE)+1
											from  #TEMPCASEEVENT CE2
											where CE2.CASEID=T.CASEID
											and   CE2.LIVEFLAG=1
											and   CE2.[STATE] not like ''D%'' --SQA17231
											and   CE2.CYCLE is not null
											and   CE2.EVENTNO=DD.EVENTNO),1)
					     END
				     END
										-- c)If the Action is CYCLIC 	
										--   then use Cycle of the Open	
										--   Action row.		
				Else isnull(T.CYCLE,O.CYCLE)
		END option (force order, MAXDOP 1)')

	Select 	@ErrorCode=@@Error,
		@nRowCount =@nRowCount+@@Rowcount
End

-- SQA10917
-- Where there are multiple Due Date Calculations defined for specific Cycles we need to ensure 
-- all of these Cycles get triggered for recalculation if they have not yet occurred.
If @ErrorCode=0
Begin
	Set @sSQLString='
	Insert into #TEMPEVENTSTOCALCULATE (CASEID, EVENTNO, CYCLE, CRITERIANO, ACTION, COUNTRYCODE, USERID, 
					    GOVERNINGEVENTNO, GOVERNINGCYCLE, INSTRUCTIONTYPE, FLAGNUMBER,IDENTITYID)
	Select 	DISTINCT
		TC.CASEID, DD1.EVENTNO, DD1.CYCLENUMBER, E.CRITERIANO, T.ACTION, T.COUNTRYCODE, TC.USERID, 
		TC.EVENTNO, TC.CYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER,TC.IDENTITYID
	From		#TEMPCASEEVENT	TC
			-- We are only interested in calculating Events that are attached to an Open Action.	
	join		#TEMPOPENACTION T   on ( T.CASEID	=TC.CASEID
					    and  T.POLICEEVENTS	=1
					    and  T.[STATE] 	<>''E'')
			-- Now get the possible Events that may be calculated.	
	join		#TEMPDUEDATECALC DD  on (DD.CRITERIANO	=T.NEWCRITERIANO
					    and((DD.FROMEVENT   =TC.EVENTNO AND DD.RELATIVECYCLE in (3,4)) OR
						(DD.COMPAREEVENT=TC.EVENTNO AND DD.COMPARECYCLE in (3,4)))
						-- The event to be calculated cannot be the same as the	
						-- event triggering the calc. To avoid a loop occurring.	
					    and DD.EVENTNO <> TC.EVENTNO
						-- If the Due Date calculation specifies a Country then it  
						-- must match the Country of the case.			
					    and(DD.COUNTRYCODE	=T.COUNTRYCODE 
					     or(DD.COUNTRYCODE=''000'' and DD.COMPARISON is not null)
					     or(DD.COUNTRYCODE=''000'' and not exists (	select * from #TEMPDUEDATECALC DD1
											where DD1.CRITERIANO =DD.CRITERIANO
											and   DD1.EVENTNO    =DD.EVENTNO
											and   DD1.COUNTRYCODE=T.COUNTRYCODE))
						))
					-- Now get the Due Date Calcs defined for specific Cycles	
	join 		#TEMPDUEDATECALC DD1 on(DD1.CRITERIANO=DD.CRITERIANO
					    and DD1.EVENTNO   =DD.EVENTNO
					    and DD1.COMPARISON is null
					    and(DD1.CYCLENUMBER=DD.CYCLENUMBER OR DD.COMPARISON is not null)
						-- If the Due Date calculation specifies a Country then it  
						-- must match the Country of the case.			
					    and(DD1.COUNTRYCODE	=T.COUNTRYCODE 
					     or(DD1.COUNTRYCODE=''000'' and not exists (select * from #TEMPDUEDATECALC DD2
											where DD2.CRITERIANO =DD1.CRITERIANO
											and   DD2.EVENTNO    =DD1.EVENTNO
											and   DD2.COUNTRYCODE=T.COUNTRYCODE))
						))
	join		EVENTCONTROL 	E   on ( E.CRITERIANO=DD.CRITERIANO and E.EVENTNO=DD.EVENTNO)
	join		ACTIONS		A   on ( A.ACTION=T.ACTION)
					-- Check now to see if the Event under consideration to
					-- be calculated already exists as it will not be required	
					-- if it has already occurred.  
	left join	#TEMPCASEEVENT 	TC1 on (TC1.CASEID =TC.CASEID
					    and TC1.EVENTNO=DD1.EVENTNO
					    and TC1.CYCLE  =DD1.CYCLENUMBER)
	left join #TEMPEVENTSTOCALCULATE TX on (TX.CASEID=TC.CASEID
					    and TX.EVENTNO=DD.EVENTNO
					    and TX.CYCLE=DD1.CYCLENUMBER)
	WHERE	(TC.[STATE] in (''R'', ''I'')
		-- If the triggering Event is marked for Deletion then
		-- the Event to be calculated must not have already been 
		-- marked for deletion
	 or  	(TC.[STATE]=''D'' and (TC1.[STATE] not like ''D%'' or TC1.[STATE] is null)))

	and TX.CASEID is null'

		----------------------------------------------------------------------------------------------------------------------
		-- The CaseEvent must fulfill one of the following conditions:
		-- 1. Not currently exist
		-- 2. Exists as a Due Date
		-- 3. May exist if the RECALCEVENTDATE option is on and the Event has a rule showing it can be calculated and saved
		----------------------------------------------------------------------------------------------------------------------
	+'
	and   ((isnull(TC1.DATEDUESAVED,0)=0 and isnull(TC1.OCCURREDFLAG,0)=0)
	  OR	 TC1.[STATE] like ''D%'''+CHAR(10)+CHAR(9)+@sRecalcEventDate+'

		-- The Cycle of the Event to be calculated must be less than 
		-- or equal to the maximum allowed for the Event.       
	and	E.NUMCYCLESALLOWED >=	CASE WHEN(A.NUMCYCLESALLOWED=1)
						Then DD1.CYCLENUMBER	
						Else T.CYCLE
					END
		-- SQA17980
		-- If the Action is cyclic then OpenAction cycle must match the cycle of the Event to be calculated
	and (A.NUMCYCLESALLOWED=1 or T.CYCLE=DD1.CYCLENUMBER)
	OPTION (MAXDOP 1)'

	exec @ErrorCode=sp_executesql @sSQLString

	Set @nRowCount=@nRowCount+@@Rowcount
End

-- Recalculate any rows that were previously satisified by an Event that has just
-- been deleted and there is a Due Date calculation for the Event   

If @ErrorCode=0
Begin
	Set @sSQLString='
	Insert into #TEMPEVENTSTOCALCULATE (CASEID, EVENTNO, CYCLE, CRITERIANO, ACTION, COUNTRYCODE, USERID,IDENTITYID)
	Select TC.CASEID, RE.EVENTNO,
	CASE WHEN (TC1.CYCLE is not null)
		THEN	TC1.CYCLE
		ELSE	CASE WHEN(RE.RELATIVECYCLE=0)	Then TC.CYCLE
			     WHEN(RE.RELATIVECYCLE=1)	Then TC.CYCLE+1
			     WHEN(RE.RELATIVECYCLE=2)	Then TC.CYCLE-1
			     WHEN(E.NUMCYCLESALLOWED=1) Then 1
			     WHEN(A.NUMCYCLESALLOWED>1)	Then T1.CYCLE
							Else isnull(CE.NEXTCYCLE,1)
			END
	END,
	T1.NEWCRITERIANO, T1.ACTION, TC.COUNTRYCODE, TC.USERID,TC.IDENTITYID
	From #TEMPCASEEVENT TC
										-- We are only interested in	
										-- calculating Events that are	
										-- attached to an Open Action.	
	     join #TEMPOPENACTION T   	on (T.CASEID      =TC.CASEID
					and T.POLICEEVENTS=1
					and T.[STATE] 	  <>''E'')
	     join RELATEDEVENTS RE	on (RE.CRITERIANO  =T.NEWCRITERIANO
					and RE.RELATEDEVENT=TC.EVENTNO
					and RE.SATISFYEVENT=1)
										-- RFC11285
										-- We are only interested in	
										-- calculating Events that are	
										-- able to be recalculated.	
	     join #TEMPOPENACTION T1  	on (T1.CASEID      =TC.CASEID
					and T1.POLICEEVENTS=1
					and T1.[STATE] 	  <>''E'')	
	     join ACTIONS A		on (A.ACTION       =T1.ACTION)
	     join EVENTCONTROL E	on (E.CRITERIANO   =T1.NEWCRITERIANO
					and E.EVENTNO      =RE.EVENTNO)
					
										-- Get the next Cycle number to use
										-- if it is cyclic and the RelativeCycle>2
	left join (	select CASEID, EVENTNO, max(CYCLE)+1 as NEXTCYCLE
			from  #TEMPCASEEVENT
			where LIVEFLAG=1
			and   [STATE] not like ''D%'' --SQA17231
			and   CYCLE is not null
			group by CASEID, EVENTNO ) CE	on (CE.CASEID=T.CASEID
							and CE.EVENTNO=RE.EVENTNO
							and RE.RELATIVECYCLE>2
							and E.NUMCYCLESALLOWED>1)
	
										-- Check now to see if the	
										-- Event under consideration to	
										-- be calculated already exists 
										-- as it will not be required	
										-- if it exists unless it has   
										-- been flagged for deletion.
	left join	#TEMPCASEEVENT 	TC1 on (TC1.CASEID =TC.CASEID
					    and TC1.EVENTNO=RE.EVENTNO
					    and TC1.CYCLE  =	CASE WHEN(RE.RELATIVECYCLE=0)	Then TC.CYCLE
								     WHEN(RE.RELATIVECYCLE=1)	Then TC.CYCLE+1
								     WHEN(RE.RELATIVECYCLE=2)	Then TC.CYCLE-1
								     WHEN(E.NUMCYCLESALLOWED=1) Then 1
								     WHEN(A.NUMCYCLESALLOWED>1)	Then T1.CYCLE	
												Else isnull(CE.NEXTCYCLE,1)
								END)
	Where (TC.[STATE]=''D'' OR (TC.[STATE]=''R'' AND TC.NEWEVENTDATE is NULL ))
	and  (TC1.CASEID is null or TC1.[STATE]=''D1'' or TC1.OCCURREDFLAG=9)
	
	-- Ensure an OpenAction exists for the cycle of the Event to be calculated
	and	(A.NUMCYCLESALLOWED = 1 OR 
		(A.NUMCYCLESALLOWED >1 AND T1.CYCLE=	CASE WHEN (TC1.CYCLE is not null)
								THEN	TC1.CYCLE
								ELSE	CASE WHEN(RE.RELATIVECYCLE=0)	Then TC.CYCLE
									     WHEN(RE.RELATIVECYCLE=1)	Then TC.CYCLE+1
									     WHEN(RE.RELATIVECYCLE=2)	Then TC.CYCLE-1
									     WHEN(E.NUMCYCLESALLOWED=1) Then 1
									     WHEN(A.NUMCYCLESALLOWED>1)	Then T1.CYCLE
													Else isnull(CE.NEXTCYCLE,1)
									END
							END))
	-- RFC50806
	-- Moved from JOIN into EXISTS clause
	-- to improve performance on a specific
	-- client database.							
	and exists(select 1
		   from DUEDATECALC
	           where COMPARISON is null
	           and CRITERIANO=T1.NEWCRITERIANO
	           and EVENTNO   =RE.EVENTNO)'

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount+@@Rowcount

End

-- Recalculate any rows that were previously satisified by an Event that has just
-- been deleted and the Event to be reinstated was previously entered manually.

If @ErrorCode=0
Begin
	Set @sSQLString='
	Insert into #TEMPEVENTSTOCALCULATE (CASEID, EVENTNO, CYCLE, CRITERIANO, ACTION, COUNTRYCODE, USERID,IDENTITYID)
	Select DISTINCT TC.CASEID, RE.EVENTNO,
	CASE WHEN (TC1.CYCLE is not null)
	THEN	TC1.CYCLE
	ELSE	CASE RE.RELATIVECYCLE	WHEN(0)	Then TC.CYCLE
					WHEN(1)	Then TC.CYCLE+1
					WHEN(2)	Then TC.CYCLE-1
								-- When RELATIVECYCLE > 2 the	
								-- Cycle is calculated by	
								-- incrementing the current	
								-- live maximum cycle	
						Else isnull((	select max(CE2.CYCLE)+1
								from  #TEMPCASEEVENT CE2
								where CE2.CASEID=T.CASEID
								and   CE2.LIVEFLAG=1
								and   CE2.[STATE] not like ''D%'' --SQA17231
								and   CE2.CYCLE is not null
								and   CE2.EVENTNO=RE.EVENTNO),1)
		END
	END,
	RE.CRITERIANO, T.ACTION, TC.COUNTRYCODE, TC.USERID,TC.IDENTITYID
	From #TEMPCASEEVENT TC
										-- We are only interested in	
										-- calculating Events that are	
										-- attached to an Open Action.	
	     join #TEMPOPENACTION T   	on (T.CASEID      =TC.CASEID
					and T.POLICEEVENTS=1
					and T.[STATE] 	  <>''E'')
	     join RELATEDEVENTS RE	on (RE.CRITERIANO  =T.NEWCRITERIANO
					and RE.RELATEDEVENT=TC.EVENTNO
					and RE.SATISFYEVENT=1)
										-- The event under consideration to	
										-- be calculated must exist with a
										-- manually entered due date that 
										-- has previously been satisfied.
	join	#TEMPCASEEVENT 	TC1	on (TC1.CASEID =TC.CASEID
					and TC1.EVENTNO=RE.EVENTNO
					and TC1.CYCLE=	CASE RE.RELATIVECYCLE	WHEN (0) Then TC.CYCLE
										WHEN (1) Then TC.CYCLE+1
										WHEN (2) Then TC.CYCLE-1
										-- If the RELATIVECYCLE is > 2	
										-- then return all cycles	
											 Else TC1.CYCLE
							END
					and TC1.OCCURREDFLAG=9)
	left join	#TEMPEVENTSTOCALCULATE C 
					on (C.CASEID =TC.CASEID
					and C.EVENTNO=RE.EVENTNO
					and C.CYCLE=	CASE RE.RELATIVECYCLE	WHEN (0) Then TC.CYCLE
										WHEN (1) Then TC.CYCLE+1
										WHEN (2) Then TC.CYCLE-1
										-- If the RELATIVECYCLE is > 2	
										-- then return all cycles	
											 Else TC1.CYCLE
							END)
	Where (TC.[STATE]=''D'' OR (TC.[STATE]=''R'' AND TC.NEWEVENTDATE is NULL))
	and C.CASEID is null'

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount+@@Rowcount

End

-- Remove any rows to be calculated where the Event is satisfied by the existence of another event

If @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString='
	delete #TEMPEVENTSTOCALCULATE
	from #TEMPEVENTSTOCALCULATE T
	where exists
	(Select 1
	 from #TEMPOPENACTION OA
	 -- If the OpenAction row is closed then check to see if an open row exists
	 -- for the same Action with a different cycle
	 left join #TEMPOPENACTION OA1
				on (OA1.CASEID=OA.CASEID
				and OA1.ACTION=OA.ACTION
				and OA1.CYCLE<>OA.CYCLE
				and OA1.POLICEEVENTS=1
				and  OA.POLICEEVENTS=0)
	 join RELATEDEVENTS RE	on (RE.CRITERIANO=OA.NEWCRITERIANO
				and RE.EVENTNO=T.EVENTNO
				and RE.SATISFYEVENT=1)
	 left join #TEMPCASEEVENT TC2	
				on (TC2.CASEID=	T.CASEID 
				and TC2.EVENTNO=RE.RELATEDEVENT
				--and TC2.STATE not like (''D%'')
				--and TC2.OCCURREDFLAG between 1 and 8
				and TC2.CYCLE =	CASE RE.RELATIVECYCLE	WHEN (0) Then T.CYCLE
									WHEN (1) Then T.CYCLE-1
									WHEN (2) Then T.CYCLE+1
									WHEN (3) Then 1
										 Else (	select max(TC3.CYCLE) 
											from #TEMPCASEEVENT TC3
											where TC3.CASEID=TC2.CASEID
											and   TC3.CYCLE is not null
											and   TC3.EVENTNO=TC2.EVENTNO)
						END)
	 where OA.CASEID  =T.CASEID
	 and  OA1.CASEID is null -- ignore closed actions if an open version exists for the same Action
	 and  (TC2.OCCURREDFLAG between 1 and 8 and TC2.[STATE] not like ''D%'') )'

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@Rowcount
end

-- RFC12137
-- Remove any #TEMPEVENTSTOCALCULATE rows where an OpenAction does not exists
-- that is appropriate for the cycle of the CaseEvent to be recalculated.
If @ErrorCode=0
Begin
	Set @sSQLString='
	delete T
	from #TEMPEVENTSTOCALCULATE T
	join CRITERIA C	on (C.CRITERIANO=T.CRITERIANO)
	join ACTIONS A	on (A.ACTION=C.ACTION)
	where not exists
	(select 1 from #TEMPOPENACTION OA
	 where OA.CASEID=T.CASEID
	 and OA.ACTION=A.ACTION
	 and OA.POLICEEVENTS=1
	 and((A.NUMCYCLESALLOWED>1 and OA.CYCLE=T.CYCLE) OR A.NUMCYCLESALLOWED=1) )'

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@Rowcount
end



-- Find any Events that have a Related Case relationship to this Case and Event and mark them for recalculation.
-- When an Event is updated from another Event via its related case this is the same as explicitly linking the 
-- two Events so that whatever happens to the Parent also happens to the child.

-- DR-45709 Use temp table instead of CTE to improve a performance 
If  @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #EVENTRELATEDCASES (CASEID, RELATIONSHIP, EVENTNO, CYCLE, NEWEVENTDATE, USERID, IDENTITYID)
	select distinct RC.CASEID, RC.RELATIONSHIP, TC.EVENTNO, TC.CYCLE, TC.NEWEVENTDATE, TC.USERID, TC.IDENTITYID
		from #TEMPCASEEVENT TC
		join EVENTCONTROL EC on (EC.UPDATEFROMEVENT=TC.EVENTNO)
		join RELATEDCASE RC  on (RC.RELATEDCASEID  =TC.CASEID
						and RC.CASEID        <>TC.CASEID	--18633 do not allow case related to itself
						and RC.RELATIONSHIP   =EC.FROMRELATIONSHIP)
		where TC.[STATE] in ('I','D','R')"
	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPEVENTSTOCALCULATE (CASEID, EVENTNO, CYCLE, CRITERIANO, ACTION, COUNTRYCODE, 
					    UPDATEFROMPARENT, PARENTEVENTDATE, PARENTADJUSTMENT, USERID,IDENTITYID, LOADNUMBERTYPE, PARENTNUMBER)
	-- Push into RelatedCase
	SELECT	RC.CASEID,  EC.EVENTNO, 
		CASE WHEN(EC.RECEIVINGCYCLEFLAG=1) THEN isnull(R.CYCLE,RC.CYCLE) ELSE RC.CYCLE END, 
		EC.CRITERIANO, isnull(TOA.ACTION,OA.ACTION), 
		T.COUNTRYCODE, 
		1, 
		COALESCE(TCE.NEWEVENTDATE,CE.EVENTDATE), 
		EC.ADJUSTMENT, RC.USERID, RC.IDENTITYID, EC.LOADNUMBERTYPE, O.OFFICIALNUMBER
	From #EVENTRELATEDCASES	RC
	join EVENTCONTROL EC	on (EC.UPDATEFROMEVENT	=RC.EVENTNO
				and EC.FROMRELATIONSHIP =RC.RELATIONSHIP)
	join EVENTS EV		on (EV.EVENTNO          =EC.UPDATEFROMEVENT)

	-----------------------------------------------------
	-- Action must exist for the Event that is determined
	-- from the related case event
	-----------------------------------------------------
	left join #TEMPOPENACTION TOA	
				on (TOA.CASEID		=RC.CASEID
				and TOA.NEWCRITERIANO	=EC.CRITERIANO)
	left join OPENACTION OA on (TOA.CASEID		is null
				and OA.CASEID		=RC.CASEID
				and OA.CRITERIANO	=EC.CRITERIANO)
	join ACTIONS A		on (A.ACTION		=isnull(TOA.ACTION, OA.ACTION))

	-----------------------------------------------------
	-- RFC 73065
	-- Determine the RelatedCase with the earliest date
	-- that is to be pushed into this Case
	-----------------------------------------------------
	join RELATEDCASE  R	on (R.CASEID      =RC.CASEID 
				and R.RELATIONSHIP=RC.RELATIONSHIP
				and R.RELATIONSHIPNO=(	select	convert(int,
								substring(
								min(
								    convert(nvarchar(8), coalesce(TC.NEWEVENTDATE,CE.EVENTDATE, R1.PRIORITYDATE,'20991231'), 112) -- Choose the EARLIEST date
								  + convert(nvarchar(11), R1.RELATIONSHIPNO)
								    ), 9,11))
							from RELATEDCASE R1
							left join CASEEVENT CE	on (CE.CASEID =R1.RELATEDCASEID
										and CE.EVENTNO=EC.UPDATEFROMEVENT
										and CE.CYCLE  =CASE WHEN(EV.NUMCYCLESALLOWED>1) THEN RC.CYCLE ELSE 1 END)
							left join #TEMPCASEEVENT TC	
										on (TC.CASEID =R1.RELATEDCASEID
										and TC.EVENTNO=EC.UPDATEFROMEVENT
										and TC.CYCLE  =CASE WHEN(EV.NUMCYCLESALLOWED>1) THEN RC.CYCLE ELSE 1 END)
							where R1.CASEID=R.CASEID
							and   R1.RELATIONSHIP=R.RELATIONSHIP)
							)

	-----------------------------------------------------
	-- Now get the date to be pushed into the child Case.
	--
	-- #TEMPCASEEVENT row may exist more than once so use
	-- the GROUP BY clause.
	-----------------------------------------------------
	left join CASEEVENT CE	on (CE.CASEID = R.RELATEDCASEID
				and CE.EVENTNO=EC.UPDATEFROMEVENT
				and CE.CYCLE  =CASE WHEN(EV.NUMCYCLESALLOWED>1) THEN RC.CYCLE ELSE 1 END)
				
	left join (	select min(NEWEVENTDATE) as NEWEVENTDATE, CASEID, EVENTNO, CYCLE
			from #TEMPCASEEVENT
			group by CASEID, EVENTNO, CYCLE) TCE
				on (TCE.CASEID = R.RELATEDCASEID
				and TCE.EVENTNO= EC.UPDATEFROMEVENT
				and TCE.CYCLE  = CASE WHEN(EV.NUMCYCLESALLOWED>1) THEN RC.CYCLE ELSE 1 END)

	-----------------------------------------------------
	-- Get the Case to be recalculate so we can check 
	-- its status
	-----------------------------------------------------
	left join #TEMPCASES T1	on (T1.CASEID		=RC.CASEID)
	left join CASES T	on (T1.CASEID		is null
				and T.CASEID		=RC.CASEID)
	left join STATUS S	on (S.STATUSCODE	=isnull(T1.STATUSCODE,T.STATUSCODE))
	
	-----------------------------------------------------
	-- Get the Date of the Case to be recalculated so we 
	-- can check if the date will change
	-----------------------------------------------------
	left join #TEMPCASEEVENT TC1
				on (TC1.CASEID		=RC.CASEID
				and TC1.EVENTNO		=EC.EVENTNO
				and TC1.CYCLE		=CASE WHEN(EC.RECEIVINGCYCLEFLAG=1) THEN isnull(R.CYCLE,RC.CYCLE) ELSE RC.CYCLE END)
	left join CASEEVENT CE1 on (TC1.CASEID		is null
				and CE1.CASEID		=RC.CASEID
				and CE1.EVENTNO		=EC.EVENTNO
				and CE1.CYCLE		=CASE WHEN(EC.RECEIVINGCYCLEFLAG=1) THEN isnull(R.CYCLE,RC.CYCLE) ELSE RC.CYCLE END)
	
	-----------------------------------------------------
	-- Get the official number of the related case whose 
	-- date is being pushed.
	-----------------------------------------------------
	left join OFFICIALNUMBERS O
				on (O.CASEID    =R.RELATEDCASEID
				and O.NUMBERTYPE=EC.LOADNUMBERTYPE
				and O.ISCURRENT =1)

	Where	((COALESCE(TCE.NEWEVENTDATE,CE.EVENTDATE,'')<>isnull(TC1.NEWEVENTDATE,'') and TC1.CASEID is not null) OR (COALESCE(TCE.NEWEVENTDATE,CE.EVENTDATE,'')<>isnull(CE1.EVENTDATE,'') and TC1.CASEID is null))  -- The date has actually changed
	and    (TOA.CASEID is not null or OA.CASEID is not null)
	and    ((A.ACTIONTYPEFLAG  =0 and S.POLICEOTHERACTIONS=1)
	 or     (A.ACTIONTYPEFLAG  =2 and S.POLICEEXAM        =1)
	 or     (A.ACTIONTYPEFLAG  =1 and S.POLICERENEWALS    =1)
	 or      S.STATUSCODE is null)
	UNION ALL
	-- Push into the Ancestor Case
	SELECT	C.CASEID,  EC.EVENTNO, TC.CYCLE, EC.CRITERIANO, isnull(TOA.ACTION,OA.ACTION), C.COUNTRYCODE, 1, 
		CASE WHEN(TC.[STATE]='D') THEN NULL ELSE TC.NEWEVENTDATE END, 
		EC.ADJUSTMENT, TC.USERID, TC.IDENTITYID, EC.LOADNUMBERTYPE, O.OFFICIALNUMBER
	From #TEMPCASEEVENT	TC
	join EVENTCONTROL EC	on (EC.UPDATEFROMEVENT	=TC.EVENTNO)
	join CASES C		on (C.PREDECESSORID	=TC.CASEID
				and C.CASEID           <>TC.CASEID)	--18633 do not allow case related to itself
	left join #TEMPCASES T1	on (T1.CASEID           =C.CASEID)
	left join #TEMPOPENACTION TOA	
				on (TOA.CASEID		=C.CASEID
				and TOA.NEWCRITERIANO	=EC.CRITERIANO)
	left join OPENACTION OA on (TOA.CASEID		is null
				and OA.CASEID		=C.CASEID
				and OA.CRITERIANO	=EC.CRITERIANO)
	join ACTIONS A		on (A.ACTION		=isnull(TOA.ACTION,OA.ACTION))
	left join #TEMPCASEEVENT TC1 
				on (TC1.CASEID		=C.CASEID
				and TC1.EVENTNO		=EC.EVENTNO
				and TC1.CYCLE		=TC.CYCLE)
	left join CASEEVENT CE1 on (TC1.CASEID		is null
				and CE1.CASEID		=C.CASEID
				and CE1.EVENTNO		=EC.EVENTNO
				and CE1.CYCLE		=TC.CYCLE)
	left join STATUS S	on (S.STATUSCODE	=isnull(T1.STATUSCODE,C.STATUSCODE))
	left join OFFICIALNUMBERS O
				on (O.CASEID    =TC.CASEID
				and O.NUMBERTYPE=EC.LOADNUMBERTYPE
				and O.ISCURRENT =1)
	Where	TC.[STATE] in ('I','D','R')
	and    ((isnull(TC.NEWEVENTDATE,'')<>isnull(TC1.NEWEVENTDATE,'') and TC1.CASEID is not null) OR (isnull(TC.NEWEVENTDATE,'')<>isnull(CE1.EVENTDATE,'') and TC1.CASEID is null))
	and	EC.FROMANCESTOR=1
	and	EC.FROMRELATIONSHIP is null
	and    (TOA.CASEID is not null or OA.CASEID is not null)	-- SQA11212
	and    ((A.ACTIONTYPEFLAG  =0 and S.POLICEOTHERACTIONS=1)
	 or     (A.ACTIONTYPEFLAG  =2 and S.POLICEEXAM        =1)
	 or     (A.ACTIONTYPEFLAG  =1 and S.POLICERENEWALS    =1)
	 or      S.STATUSCODE is null)
	UNION ALL
	-- Push into the same Case
	SELECT	TC.CASEID,  EC.EVENTNO, TC.CYCLE, EC.CRITERIANO, TOA.ACTION, TC.COUNTRYCODE, 1, 
		CASE WHEN(TC.[STATE]='D') THEN NULL ELSE TC.NEWEVENTDATE END, 
		EC.ADJUSTMENT, TC.USERID, TC.IDENTITYID, NULL, NULL
	From #TEMPCASEEVENT	TC
	join EVENTCONTROL EC	on (EC.UPDATEFROMEVENT	=TC.EVENTNO)
	join #TEMPOPENACTION TOA	
				on (TOA.CASEID		=TC.CASEID
				and TOA.NEWCRITERIANO	=EC.CRITERIANO)
	left join #TEMPCASEEVENT CE1 
				on (CE1.CASEID		=TC.CASEID
				and CE1.EVENTNO		=EC.EVENTNO
				and CE1.CYCLE		=TC.CYCLE)
	Where	TC.[STATE] in ('I','D','R')
	and     isnull(TC.NEWEVENTDATE,'')<>isnull(CE1.NEWEVENTDATE,'')
	and	isnull(EC.FROMANCESTOR,0)=0
	and	EC.FROMRELATIONSHIP is null"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount+@@Rowcount
End

-- Delete any rows that were inserted as a result of a change of Event that were also inserted 
-- due to a change in the Parent.

If @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString='
	Delete from #TEMPEVENTSTOCALCULATE
	where UPDATEFROMPARENT is null
	and exists
	(Select * from #TEMPEVENTSTOCALCULATE T
	 where T.CASEID	= #TEMPEVENTSTOCALCULATE.CASEID
	 and   T.EVENTNO= #TEMPEVENTSTOCALCULATE.EVENTNO
	 and   T.CYCLE	= #TEMPEVENTSTOCALCULATE.CYCLE
	 and   T.UPDATEFROMPARENT=1)'

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@Rowcount
End

-- Delete any recalculations where the EVENTNO and CYCLE of the Event to recalculate
-- is identical to the EVENTNO and CYCLE that triggered the calculation.  This will 
-- avoid an endless loop occurring.

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString='
	Delete from #TEMPEVENTSTOCALCULATE
	where EVENTNO=GOVERNINGEVENTNO
	and   CYCLE  =GOVERNINGCYCLE'

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@Rowcount
End

-- Check if any rows have just been inserted for a related Case then the Case and OpenAction
-- details for that Case will have to be loaded.

If  @ErrorCode=0
and @nRowCount>0
begin
	Set @sSQLString='
	select @nGetParentOUT=1
	from #TEMPEVENTSTOCALCULATE TC
	where not exists
	(select * from #TEMPCASES T
	 where T.CASEID=TC.CASEID)'
	
	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nGetParentOUT tinyint OUTPUT',
					  @nGetParentOUT=@nGetParent OUTPUT

End

If  @ErrorCode=0
and @nGetParent=1
Begin
	-- Load the #TEMPOPENACTIONS table
	Set @sSQLString="
	insert #TEMPOPENACTION
		(CASEID, ACTION, CYCLE, LASTEVENT, CRITERIANO, DATEFORACT, NEXTDUEDATE, POLICEEVENTS,
		 STATUSCODE, STATUSDESC, DATEENTERED, DATEUPDATED, CASETYPE, PROPERTYTYPE, COUNTRYCODE,
		 CASECATEGORY, SUBTYPE, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE, RENEWALTYPE,
		 CASEOFFICEID, NEWCRITERIANO, [STATE], USERID,IDENTITYID)
	select	distinct OA.CASEID,OA.ACTION,OA.CYCLE,OA.LASTEVENT,OA.CRITERIANO,OA.DATEFORACT,OA.NEXTDUEDATE,OA.POLICEEVENTS,
		OA.STATUSCODE,OA.STATUSDESC,OA.DATEENTERED,OA.DATEUPDATED,C.CASETYPE,C.PROPERTYTYPE,C.COUNTRYCODE,
		C.CASECATEGORY,C.SUBTYPE,P.BASIS,P.REGISTEREDUSERS,C.LOCALCLIENTFLAG,P.EXAMTYPE,P.RENEWALTYPE,
		C.OFFICEID,OA.CRITERIANO, 'C1', TC.USERID,TC.IDENTITYID
	from	#TEMPEVENTSTOCALCULATE TC
	join    OPENACTION OA  on (OA.CASEID    =TC.CASEID)
	join 	ACTIONS    A   on (A.ACTION     =OA.ACTION)
	join	CASES	   C   on (C.CASEID     =TC.CASEID)
	left join PROPERTY P   on (P.CASEID     =TC.CASEID)
	left join STATUS   S   on (S.STATUSCODE =C.STATUSCODE)
	left join STATUS   S1  on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join #TEMPCASES T on (T.CASEID     =TC.CASEID)
	where	T.CASEID is null  -- Only load TEMPOPENACTION if the Case is not in TEMPCASES
	and	OA.POLICEEVENTS=1
	and    ((A.ACTIONTYPEFLAG  =0 and (S.POLICEOTHERACTIONS=1 or S.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =2 and (S.POLICEEXAM        =1 or S.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =1 and (S.POLICERENEWALS    =1 or S.STATUSCODE  is null) 
	                              and (S1.POLICERENEWALS   =1 or S1.STATUSCODE is null)))"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount2=@@Rowcount

	-- Load the #TEMPCASES table

	If @ErrorCode=0
	and @nRowCount2>0
	Begin
		Set @sSQLString='
		insert #TEMPCASES (CASEID, STATUSCODE, RENEWALSTATUS, REPORTTOTHIRDPARTY, PREDECESSORID, ACTION,  
				   EVENTNO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
				   BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE,RENEWALTYPE, INSTRUCTIONSLOADED,
				   IPODELAY,APPLICANTDELAY,USERID,IDENTITYID,OFFICEID,CASELOGSTAMP,PROPERTYLOGSTAMP)

		select	distinct C.CASEID, C.STATUSCODE, P.RENEWALSTATUS, C.REPORTTOTHIRDPARTY,C.PREDECESSORID, null, 
				 null, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE,
				 P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, 0,isnull(C.IPODELAY,0),
				 isnull(C.APPLICANTDELAY,0), TC.USERID,TC.IDENTITYID,C.OFFICEID,C.LOGDATETIMESTAMP,P.LOGDATETIMESTAMP
		from #TEMPEVENTSTOCALCULATE TC
		join CASES C		on (C.CASEID=TC.CASEID)
		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
		left join PROPERTY P    on (P.CASEID=C.CASEID)
		left join #TEMPCASES T	on (T.CASEID=TC.CASEID)
		where T.CASEID is null'

		Exec @ErrorCode=sp_executesql @sSQLString

		Set @nRowCount2=@@Rowcount
	
		If  @ErrorCode=0
		and @nRowCount2>0
		Begin
			-- Get any Standing Instructions for Cases that have just been added.
			execute @ErrorCode = dbo.ip_PoliceGetStandingInstructions @pnDebugFlag

			-- Get any Events associated with the newly loaded Cases
			If @ErrorCode=0
				Execute @ErrorCode=ip_PoliceGetEventsForTempTable @pnDebugFlag
		End
	End

End

-- Now delete any #TEMPEVENTSTOCALCULATE rows where the Status of the Case is such that Policing
-- is not required.

If @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString='
	delete #TEMPEVENTSTOCALCULATE
	From		#TEMPEVENTSTOCALCULATE T
	join		#TEMPCASES C	on (C.CASEID=T.CASEID)
	join		ACTIONS A	on (A.ACTION=T.ACTION)
	left join	STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
	left join	STATUS SR	on (SR.STATUSCODE=C.RENEWALSTATUS)
	WHERE  ((A.ACTIONTYPEFLAG  =0 and  SC.POLICEOTHERACTIONS=0)
	 or     (A.ACTIONTYPEFLAG  =2 and  SC.POLICEEXAM        =0)
	 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =0 or SR.POLICERENEWALS=0)))'


	exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@Rowcount
End

If @ErrorCode=0
and @nRowCount>0
Begin
	-- delete any rows just inserted that require a particular standing instruction flag
	-- but do not have that flag

	Set @sSQLString='
	delete #TEMPEVENTSTOCALCULATE
	From #TEMPEVENTSTOCALCULATE T
	left join #TEMPCASEINSTRUCTIONS CI	on (CI.CASEID=T.CASEID
						and CI.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
	left join INSTRUCTIONFLAG F		on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE
						and F.FLAGNUMBER=T.FLAGNUMBER)
	WHERE T.INSTRUCTIONTYPE is not null
	and T.FLAGNUMBER      is not null
	and F.INSTRUCTIONCODE is null'

	exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@Rowcount
End


If @ErrorCode=0
and @nRowCount>0
Begin
	-- delete any rows just inserted where the Event is flagged
	-- to suppress calculation

	Set @sSQLString='
	delete T
	From #TEMPEVENTSTOCALCULATE T
	join EVENTCONTROL EC	on (EC.CRITERIANO=T.CRITERIANO
				and EC.EVENTNO   =T.EVENTNO)
	WHERE EC.SUPPRESSCALCULATION=1'

	exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@Rowcount
End 

-- If the #TEMPCASEEVENT table already has the CaseEvent that is eligible to be recalculated then
-- it is to be updated to have its STATE column set back to "C" so that it gets recalculated.
-- It is possible for the Case Event Cycle to appear in #TEMPCASEEVENT more than once if it resides  
-- under more than one Action.  If so then only change the STATE on the row for the Criteria to be calculated.

If @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	Update	#TEMPCASEEVENT
	set	[STATE]		=CASE WHEN(CALC.ACTION=isnull(T.ACTION,CALC.ACTION) OR T.[STATE] like 'D%')
					THEN 'C'		-- RFC12518 this code was replace  ----> CASE WHEN(T.DATEDUESAVED=1) THEN 'R' ELSE 'C' END
					ELSE T.[STATE]
				 END, 
		NEWEVENTDATE    =NULL,
		LOOPCOUNT	=T.LOOPCOUNT+1, 
		UPDATEFROMPARENT=CALC.UPDATEFROMPARENT, 
		PARENTEVENTDATE	=CALC.PARENTEVENTDATE, 
		ADJUSTMENT	=isnull(CALC.PARENTADJUSTMENT, T.ADJUSTMENT),
		LOADNUMBERTYPE  =CALC.LOADNUMBERTYPE,
		PARENTNUMBER    =CALC.PARENTNUMBER,
		OCCURREDFLAG    =CASE WHEN(CALC.ACTION=isnull(T.ACTION,CALC.ACTION) OR T.OCCURREDFLAG=9)	-- RFC11682 & RFC13246
					THEN 0
					ELSE T.OCCURREDFLAG
				 END, 
		DISPLAYSEQUENCE =E.DISPLAYSEQUENCE,
		IMPORTANCELEVEL =E.IMPORTANCELEVEL,
		WHICHDUEDATE    =E.WHICHDUEDATE,
		COMPAREBOOLEAN  =E.COMPAREBOOLEAN,
		CHECKCOUNTRYFLAG=E.CHECKCOUNTRYFLAG,
		SAVEDUEDATE     =E.SAVEDUEDATE,
		STATUSCODE      =E.STATUSCODE,
		RENEWALSTATUS	=E.RENEWALSTATUS,
		SPECIALFUNCTION =E.SPECIALFUNCTION,
		INITIALFEE      =E.INITIALFEE,
		PAYFEECODE      =E.PAYFEECODE,
		CREATEACTION    =E.CREATEACTION,
		STATUSDESC      =E.STATUSDESC,
		CLOSEACTION     =E.CLOSEACTION,
		RELATIVECYCLE   =E.RELATIVECYCLE,
		INSTRUCTIONTYPE =E.INSTRUCTIONTYPE,
		FLAGNUMBER      =E.FLAGNUMBER,
		SETTHIRDPARTYON =E.SETTHIRDPARTYON,
		ESTIMATEFLAG    =E.ESTIMATEFLAG,
		EXTENDPERIOD    =E.EXTENDPERIOD,
		EXTENDPERIODTYPE=E.EXTENDPERIODTYPE,
		INITIALFEE2     =E.INITIALFEE2,
		PAYFEECODE2     =E.PAYFEECODE2,
		ESTIMATEFLAG2   =E.ESTIMATEFLAG2,
		PTADELAY        =E.PTADELAY,
		SETTHIRDPARTYOFF=E.SETTHIRDPARTYOFF,
		CHANGENAMETYPE  =E.CHANGENAMETYPE,
		COPYFROMNAMETYPE=E.COPYFROMNAMETYPE,
		COPYTONAMETYPE  =E.COPYTONAMETYPE,
		DELCOPYFROMNAME =E.DELCOPYFROMNAME,
		DIRECTPAYFLAG   =E.DIRECTPAYFLAG,
		DIRECTPAYFLAG2  =E.DIRECTPAYFLAG2,
		CREATEDBYCRITERIA=CALC.CRITERIANO,
		CREATEDBYACTION  =CALC.ACTION,
		CRITERIANO       =CALC.CRITERIANO,
		--ACTION           =CALC.ACTION,		-- Commenting out because changing the ACTION causes the same row to be inserted in TEMPCASEEVENT if the Event exists for multiple Actions
		LIVEFLAG         =1
	From	#TEMPCASEEVENT  T
	join	#TEMPEVENTSTOCALCULATE  CALC	on (CALC.CASEID =T.CASEID
					   	and CALC.EVENTNO=T.EVENTNO
					   	and CALC.CYCLE  =T.CYCLE)
	join	EVENTCONTROL E	on (E.CRITERIANO=CALC.CRITERIANO
				and E.EVENTNO=CALC.EVENTNO)

		-- If the Event has been inserted then it does not 	
		-- have to be recalculated unless it is being changed
		-- by the parent case.		
	where 	(T.[STATE] not like ('I%') OR CALC.UPDATEFROMPARENT=1)
	and     (T.ACTION=CALC.ACTION OR T.ACTION is null OR T.[STATE] like 'D%')	-- RFC12128
	and    ((isnull(T.DATEDUESAVED,0)=0 and isnull(T.OCCURREDFLAG,0)=0) 
	     OR  T.OCCURREDFLAG=9 
	     OR  CALC.UPDATEFROMPARENT=1
	     OR (@pbRecalcEventDate=1 AND T.RECALCEVENTDATE=1 AND T.SAVEDUEDATE between 2 and 5) )"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pbRecalcEventDate	bit',
					  @pbRecalcEventDate=@pbRecalcEventDate

	Set @pnRowCount=@@Rowcount

	--=========================
	-- The #TEMPCASEEVENT table is to be loaded with Events that are eligible to be calculated if they do not 
	-- already exist on the #TEMPCASEEVENT table
	
	-- STATE = 'C' (calculate)
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPCASEEVENT 
				(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
					OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA, CRITERIANO, ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
					DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO, [STATE], ADJUSTMENT,
					IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
					SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
					INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, USERID, NEWEVENTDUEDATE,
					DATEREMIND,UPDATEFROMPARENT, PARENTEVENTDATE, ESTIMATEFLAG,
					EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
					CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2, LIVEFLAG,RESPNAMENO,RESPNAMETYPE, ACTION,
					LOADNUMBERTYPE,PARENTNUMBER)
		SELECT	DISTINCT CALC.CASEID,  E.DISPLAYSEQUENCE, CALC.EVENTNO, CALC.CYCLE,
			0, CE1.EVENTDATE, CE1.EVENTDUEDATE, isnull(CE1.DATEDUESAVED,0), 0, CALC.ACTION, E.CRITERIANO,E.CRITERIANO, CE1.ENTEREDDEADLINE, CE1.PERIODTYPE, 
			CE1.DOCUMENTNO, CE1.DOCSREQUIRED, CE1.DOCSRECEIVED, CE1.USEMESSAGE2FLAG, CE1.GOVERNINGEVENTNO, 'C', 
			CALC.PARENTADJUSTMENT, E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, 
			E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, 
			E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, 
			CS.COUNTRYCODE, CALC.USERID, CE1.EVENTDUEDATE,
			CE1.DATEREMIND, CALC.UPDATEFROMPARENT, CALC.PARENTEVENTDATE, E.ESTIMATEFLAG,
			E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,CALC.IDENTITYID,E.SETTHIRDPARTYOFF,
			E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,0,
			E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE, CALC.ACTION, CALC.LOADNUMBERTYPE,CALC.PARENTNUMBER
		From		#TEMPEVENTSTOCALCULATE	CALC
		join		EVENTCONTROL 	E   on ( E.CRITERIANO=CALC.CRITERIANO and E.EVENTNO=CALC.EVENTNO)
		join		#TEMPCASES	CS  on (CS.CASEID  =CALC.CASEID)	-- RFC12447
		left join	CASEEVENT 	CE1 on (CE1.CASEID =CALC.CASEID
						    and CE1.EVENTNO=CALC.EVENTNO
						    and CE1.CYCLE  =CALC.CYCLE)
		left join	#TEMPCASEEVENT	TC  on (TC.CASEID  =CALC.CASEID
						    and TC.EVENTNO =CALC.EVENTNO
						    and TC.CYCLE   =CALC.CYCLE
						    and TC.ACTION  =CALC.ACTION)	-- RFC40624
		Where E.NUMCYCLESALLOWED>=CALC.CYCLE		-- SQA 7344	
		and  TC.CASEID is null"
	
		Exec @ErrorCode=sp_executesql @sSQLString
		Set @pnRowCount=@pnRowCount+@@Rowcount
	End
End

If  @pnDebugFlag>0
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetEventsToCalculateFromEvents',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin	
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*, @pnRowCount as 'Row Count' 
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnRowCount	int',
						  @pnRowCount
	End
End

drop table #TEMPEVENTSTOCALCULATE
drop table #TEMPDUEDATECALC

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetEventsToCalculateFromEvents  to public
go
