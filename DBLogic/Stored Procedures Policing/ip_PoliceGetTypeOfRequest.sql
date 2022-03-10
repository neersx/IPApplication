-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetTypeOfRequest
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetTypeOfRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetTypeOfRequest.'
	drop procedure dbo.ip_PoliceGetTypeOfRequest
end
print '**** Creating procedure dbo.ip_PoliceGetTypeOfRequest...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure [dbo].[ip_PoliceGetTypeOfRequest] 
			@pnRowCount		int	OUTPUT,
			@pbPTARecalc		bit	OUTPUT,
			@pbRecalcEventDate	bit	= 0,
			@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PoliceGetTypeOfRequest
-- VERSION :	48
-- DESCRIPTION:	When Policing has been called either from the Policing Server or for a specific Case the details
--		of what Policing is to be performed are contained in details held on the POLICING table with
--		each row specifying a TYPEOFREQUEST.  The information contained in the POLICING row will be 
--		used to load the various temporary tables to allow Policing to be performed.
-- CALLED BY :	ipu_Policing

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 04/07/2001	MF			Procedure created
-- 15/08/2001	MF			Set the new TEMPCASEEVENT.EVENTUPDATEDMANUALLY column to flag those rows that
--					were updated prior to Policing being called.  If there is a Status update associated 
--					with these events then it will only be applied if the EventDate is greater than or equal
--					to the highest EventDate associated with the Case.
-- 16/08/2001	MF			Error when determining row count.  When I was testing the current row with an IF statement
--					this was resetting the rowcount to 0.  Need a new variable.
-- 05/09/2001	MF	7036		Events that cleared are to be marked so that they will trigger a 
--					recalculation and will be deleted if no calculation can be done.
-- 07/09/2001	MF	7040		Event updates sent to Policing are not always setting the Cycle number of the
--					the Event. If Cycle is null then change it to 1.
-- 20/09/2001	MF	7056		When an Event is updated then Policing should check for all of the EventControl
--					rules against OpenActions as well as the action in which the event was updated.	
-- 03/10/2001	MF	7101		When the Type Of Request is to recalculate the due date the Case Event row 
--					does not have to exist.
-- 09/10/2001	MF	7109		If the DATEDUESAVED flag is set ON but there is no Due Date then set it off.
-- 14/10/2001	MF	7117		If the Type of Request indicates that the due date has been changed then set
--					the Event Due Date to null.
-- 14/11/2001	MF	7189		If there is no CreatedByCriteria against a case but there is an Action make
--					sure that the CreatedByCriteria extracted matches the Action
-- 13/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 26/11/2001	MF	7237		If an Event is cleared out and the original CREATEDBYCRITERIA is not currently 
--					open against the case but another Action for the Event does exist then use the 
--					currently open Action.
-- 29/01/2002	MF	7380		When the due date of an Event is changed reset the OCCURREDFLAG to 0
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 12/06/2002	MF	7728		An Event should only be marked as Manually Entered if an actual date has been
--					entered.  Not when an EventDate is cleared out.
-- 20/06/2002	MF	7748		Before placing an event on the queue to be processed ensure that the cycle
--					number being requested is valid for the number of cycles allowed.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 30/07/2002	MF	7880		Where the Entered Deadline for an Event has been changed the Due Date is to be
--					calculated.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 25/09/2002	MF	8022		If an ACTION being opened by Smart Policing does not have the ActionType 
--					flag set then the OpenAction will be ignored.  Modify the procedure to cater 
--					for this situation as if the flag is set off.
-- 20/03/2003	MF	8549		Policing can go into an endless loop where it is processing a Batch and an error
--					is experienced thus leaving the POLICING row intact.  We need to keep previous
--					requests in #TEMPPOLICING to avoid this so we must flag these rows once
--					they have been processed.
-- 24 Jul 2003	MF	8260	10	Changes for the Patent Term Adjustment
-- 28 Jul 2003	MF	8673	10	Get the OFFICE associated with the Case so it can be used to determine the
--					best CriteriaNo for an Action.
-- 12 Nov 2003	MF	9450	11	Set the CRITERIANO on the #TEMPCASEEVENT table when inserting rows.
-- 25 Nov 2003	MF	9489	12	An Event that belongs to multiple Actions is returning multiple TEMPCASEEVENT
--					rows.  This later can result in the Event being recalculated even if it is 
--					satisfied by another event.
-- 26 Feb 2004	MF	RFC709	13	Get IDENTITYID to identify workbench users.
-- 28 Jul 2004	MF	10324	14	When an Event has been updated through Case Detail Entry with the Stop Police
--					checkbox this results in the OCCURREDFLAG being set to 1 and Policing being
--					entered with a Type of Request of 3.  This should treat the CaseEvent row
--					as if it has occurred however it is currently causing a recalculation because
--					the EventDate is empty.
-- 03 Nov 2004	MF	10385	15	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 25 Nov 2004	MF	10710	16	Allow Policing of a CaseEvent with a Cycle>1 even if the CaseEvent does not
--					specify the Criteriano to use.
-- 14 Jan 2005	MF	10863	17	If the Due Date has been manually changed then do not return the current DATEREMIND
--					date as we want to generate reminders as if none have been previously generated.
-- 10 Feb 2005	MF	10995	18	Manually entered Due Dates should also be flagged to calculate (State=C) so
--					that any satisfying events can be immediately considered.
-- 08 Mar 2005	MF	11122	19	Store the USERID and IDENTYID againt the #TEMPCASES row.
-- 15 May 2006	MF	12315	20	New EventControl columns to update CASENAME when Event occurs.
-- 06 Jun 2006	MF	12723	21	When inserting rows into #TEMPCASES ensure that NULLs are replaced with
--					zero for RECALCULATEPTA, IPODELAY and APPLICANTDELAY
-- 07 Jun 2006	MF	12417	22	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	23	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 10 Aug 2007	MF	12548	24	Load #TEMPCASES.OFFICEID
-- 24 May 2007	MF	14812	25	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	26	Reserve word [STATE]
-- 26 Oct 2007	MF	15518	27	Set LIVEFLAG on #TEMPCASEEVENT if CASEEVENT row already exists.
-- 11 Apr 2008	MF	16141	28	Introduce a new TYPEOFREQUEST value that will get the CaseEvent rows that
--					may now occur as a result of a Document Case Event having occurred.
-- 29 Oct 2007	MF	15438	24a	Return CREATEDBYACTION and CREATEDBYCRITERIA on TYPEOFREQUEST=2 (due date).
-- 07 Jan 2008	MF	15586	27	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 27 Mar 2009	MF	17526	29	CREATEDBYACTION column in CASEEVENT table being set to NULL when duedate is amended 
--					but the original Action no longer includes the EventNo.
-- 07 Apr 2009	MF	17573	30	Reminder not generating when CASEEVENT has CreatedByAction that does not match
--					the CreatedByCriteria. Correct data at point that Policing is triggered to process.
-- 20 Apr 2009	MF	17619	31	If Event has been updated from an Action that the Event does not have rules for then 
--					attempt to find the Action where rules do exist and use those rules.
-- 27 Jul 2009	MF	17922	32	Ensure rows inserted into #TEMPCASEEVENT have the ACTION column initialised to the same as CREATEDBYACTION.
-- 01 Jul 2011	MF	10929	33	Keep track of when the CASES and PROPERTY rows were last updated so that we can check that no changes
--					have been applied to the database when Policing attempts to update these.
-- 03 Aug 2011	MF	R11062	34	If TYPEOFREQUEST=6 then leave the DATEREMIND empty so that reminder will be resent.
-- 07 Mar 2012	MF	R12050	35	If TYPEOFREQUEST=6 then do not recalculate the due date if it already has a manually entered due date.
-- 06 Jun 2012	MF	S19025	36	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 06 Jun 2013	MF	S21404	37	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 27 Aug 2013	MF	R26121	38	Wrong CRITIERIANO for an Event is being returned where the Event was initially update by a checklist
-- 08 Jul 2014	MF	R121006	39	If TYPEOFREQUEST=6 and Event is cyclic in a non cyclic Action then force a recalculation of the open action. 
--					This is to ensure that all possible cycles for the CaseEvents to be triggered are considered.
-- 03 Oct 2014	MF	R40027	40	Rework RFC36785. Remove code to close Action.
-- 18 Oct 2014	MF	R40502	41	TypeOfRequest = 6 should also set the USEDINCALCULATION flag to Y to ensure any changes trigger other recalculations.
-- 23 Oct 2014	MF	R40843	42	Policing was only triggering the recalculation of a due date when the DesignatedCountry status was being set to a value that would cause
--					the due date to no longer calculate. Need to also handle the situation where the Event previously does not exist and the status is being
--					set for the first time against the designated country and we want this to trigger the calculation of the due date for the first time.
-- 09 Jan 2014	MF	R41513	43	Events triggered to recalculate the due date (Type of Request = 6) should also consider Events that are flagged with RECALCEVENTDATE=1
--					if the Site Control 'Policing Recalculates Event' is set to TRUE and passed as parameter @pbRecalcEventDate.
-- 10 Jun 2015	MF	R45361	44	Cater for requests to distribute Prior Art across the extended Case family determined from RelatedCases. The potential for large volumes of Cases
--					that can be impacted has required this to run as a separate asynchronous process from the triggering activity.
-- 09 Nov 2015	MF	R54876	45	A CaseEvent that has been cleared out that has exceeded the number of cycles allowed should be marked for deletion.
-- 15 Mar 2017	MF	70049	46	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV	DR-45358 47   Date conversion errors when creating cases and opening names in Chinese DB
-- 20 Jun 2019	MF	DR-49798 48	Revist of R121006.  The Recalculation of the entire action could possibly cause some problems when some CaseEvents are already marked to calculate. 
--					Change the approach so thate we get all the CaseEvents that could be calculated for an Action but then reset the Action so it does not recalculate
--					the criteria.
set nocount on

DECLARE		@ErrorCode		int,
		@nActionRowCount	int,
		@nCasesRowCount		int,
		@sSQLString		nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode       = 0


-- For each POLICING row being processed load the appropriate temporary tables depending on the TYPEOFREQUEST
--	 Type of Request
-- 		1	Open an Action
--		2	Due Date has changed
--		3	Event Occurred
--		4	Recalculate an Action
--		5	Recalculate Due Date when Designated Country Status changes
--		6	Recalculate Due Date
--		7	Recalculate the Patent Term Adjustment totals for the Case
--		8	Find Case Events Triggered From Document Case Event occurring.
--		9	Trigger the distribution of prior art across all directly and indirectly related Cases.
If @ErrorCode=0
Begin
	-- TYPEOFREQUEST	6
	-- =============	=
	-- When Events are explicitly being triggered to calculate the due date it is normally as a result of a
	-- change in Standing Instruction.  This works very efficiently for non cyclic Events however where the 
	-- Event can be cyclic in a non cyclic Action then it is possible that explicit cycles that may be able 
	-- to calculate are not considered.  To address this situation generate a row to recalculate the entire
	-- OpenAction which will then consider all of the cycles for the CaseEvents.
	set @sSQLString="
	insert #TEMPOPENACTION (CASEID, ACTION, POLICEEVENTS, DATEENTERED, DATEUPDATED, CASETYPE, PROPERTYTYPE, COUNTRYCODE,
		CASECATEGORY, SUBTYPE, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE, RENEWALTYPE, CASEOFFICEID,[STATE],
		CYCLE, USERID,IDENTITYID)
	select	distinct	
		T.CASEID, OA.ACTION, 
		OA.POLICEEVENTS,
		getdate(), getdate(), C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY,
		C.SUBTYPE, P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, C.OFFICEID,

		-- Recalculate the OpenAction if it is already open.
		CASE WHEN (OA.POLICEEVENTS=1) THEN 'C' ELSE 'C1' END,
		isnull(OA.CYCLE,1), T.SQLUSER,T.IDENTITYID
	from	  #TEMPPOLICING T
	join	  OPENACTION OA	 on (OA.CASEID=T.CASEID
				 and OA.POLICEEVENTS=1)
	join	  EVENTCONTROL E on (E.CRITERIANO=OA.CRITERIANO
				 and E.EVENTNO   =T.EVENTNO
				 and E.NUMCYCLESALLOWED>1)
	join	  DUEDATECALC D	 on (D.CRITERIANO=OA.CRITERIANO
				 and D.EVENTNO   =E.EVENTNO)				
	join	  ACTIONS A	 on (A.ACTION=OA.ACTION
				 and A.NUMCYCLESALLOWED=1)
	join	  CASES	C	 on (C.CASEID=T.CASEID)
	left join PROPERTY P	 on (P.CASEID=T.CASEID)
	left join STATUS SC	 on (SC.STATUSCODE=C.STATUSCODE)
	left join STATUS SR	 on (SR.STATUSCODE=P.RENEWALSTATUS)
											-- Get the Validaction. 	
	join VALIDACTION V	on (V.CASETYPE    =C.CASETYPE
				and V.PROPERTYTYPE=C.PROPERTYTYPE
				and V.ACTION      =OA.ACTION
				and V.COUNTRYCODE = (select min(COUNTRYCODE)
							from  VALIDACTION V1
							where V1.CASETYPE    =V.CASETYPE
							and   V1.PROPERTYTYPE=V.PROPERTYTYPE
							and   V1.ACTION      =V.ACTION
							and   V1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	where T.TYPEOFREQUEST=6
	and   T.PROCESSED is null
											-- Only calculate the row if the
											-- appropriate Status allows	
											-- the Action to be policed	
	and   (((A.ACTIONTYPEFLAG  =0 OR A.ACTIONTYPEFLAG is null) and (SC.POLICEOTHERACTIONS=1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =2 and (SC.POLICEEXAM        =1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =1 or SC.STATUSCODE  is null) 
        	                      and (SR.POLICERENEWALS    =1 or SR.STATUSCODE is null)))"
	
	exec @ErrorCode= sp_executesql @sSQLString
	Set  @pnRowCount=@pnRowCount+@@Rowcount

	If @pnRowCount>0
	and @ErrorCode=0
	Begin
		------------------------------------------------------------
		-- This will get all of the possible Events to recalculation 
		-- for the #TEMPOPENACTION rows where STATE='C'
		------------------------------------------------------------
		execute @ErrorCode = dbo.ip_PoliceGetEventsToCalculateFromAction 
							@pnRowCount	OUTPUT,
							@pbRecalcEventDate,
							@pnDebugFlag

		If @ErrorCode=0
		Begin
			--------------------------------------------------
			-- Now reset the STATE on #TEMPOPENACTION to avoid 
			-- recalculating the criteria.
			--------------------------------------------------
			Set @sSQLString="
			Update #TEMPOPENACTION
			set	[STATE]	= 'C1'
			where	[STATE]	= 'C'"

			exec @ErrorCode=sp_executesql @sSQLString
		End
	End
	
End

If @ErrorCode=0
Begin
	-- TYPEOFREQUEST	2, 3, 6
	-- =============	========
	-- Load details of the Events from Policing rows.
	-- The CriteriaNo and Action that created the Event is not always known so try and determine this by looking
	-- at the current OpenActions with a preference where the POLICEVENTS flag is ON.

	set @sSQLString="
	insert into #TEMPCASEEVENT
	(CASEID,DISPLAYSEQUENCE,EVENTNO,CYCLE,LOOPCOUNT,OLDEVENTDATE,OLDEVENTDUEDATE,DATEDUESAVED,
	OCCURREDFLAG,CREATEDBYACTION,
	CREATEDBYCRITERIA,
	ENTEREDDEADLINE,PERIODTYPE,DOCUMENTNO,
	DOCSREQUIRED,DOCSRECEIVED,USEMESSAGE2FLAG,GOVERNINGEVENTNO,[STATE],ADJUSTMENT,
	IMPORTANCELEVEL,WHICHDUEDATE,COMPAREBOOLEAN,CHECKCOUNTRYFLAG,SAVEDUEDATE,STATUSCODE,RENEWALSTATUS,
	SPECIALFUNCTION,INITIALFEE,PAYFEECODE,CREATEACTION,STATUSDESC,CLOSEACTION,RELATIVECYCLE,
	INSTRUCTIONTYPE,FLAGNUMBER,SETTHIRDPARTYON,COUNTRYCODE,NEWEVENTDATE,NEWEVENTDUEDATE,
	USEDINCALCULATION,DATEREMIND,USERID,CRITERIANO,ACTION,EVENTUPDATEDMANUALLY,ESTIMATEFLAG,
	EXTENDPERIOD,EXTENDPERIODTYPE,INITIALFEE2,PAYFEECODE2,ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
	CHANGENAMETYPE,COPYFROMNAMETYPE,COPYTONAMETYPE,DELCOPYFROMNAME,DIRECTPAYFLAG,DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE,RECALCEVENTDATE,SUPPRESSCALCULATION)
	SELECT	distinct T.CASEID,  E.DISPLAYSEQUENCE, T.EVENTNO, isnull(T.CYCLE,1), 
		0, 
		CASE WHEN (@pbRecalcEventDate=1 and T.TYPEOFREQUEST=6)   THEN NULL ELSE CE.EVENTDATE END, 
		-- If type of request indicates the due date has changed then set OldEventDueDate to null
		CASE WHEN (T.TYPEOFREQUEST=2) THEN NULL ELSE CE.EVENTDUEDATE END, 
		-- If the Due Date has been cleared out then reset the DateDueSaved flag
		CASE WHEN (CE.EVENTDUEDATE is NULL) THEN 0 ELSE isnull(CE.DATEDUESAVED,0) END, 
		
		CASE WHEN (CE.OCCURREDFLAG is NULL OR CE.OCCURREDFLAG=9) THEN 0 
		     WHEN (@pbRecalcEventDate=1 and T.TYPEOFREQUEST=6)   THEN 0
									 ELSE CE.OCCURREDFLAG 
		END,
		
		-- If the Event is being cleared then reset the CreatedByAction
		CASE WHEN (CE.EVENTDATE is null) THEN CR.ACTION ELSE isnull(CE.CREATEDBYACTION, CR.ACTION) END,
		-- If the Event is being cleared then reset the CreatedByCriteria
		CASE WHEN (CE.EVENTDATE is null)
			THEN CR.CRITERIANO
			ELSE isnull(CE.CREATEDBYCRITERIA,
				CASE WHEN(CE.CREATEDBYACTION=CR.ACTION or CE.CREATEDBYACTION is null)
					THEN CR.CRITERIANO
				     	ELSE NULL
				END)
		END,
		CE.ENTEREDDEADLINE, CE.PERIODTYPE, CE.DOCUMENTNO, CE.DOCSREQUIRED,
		CE.DOCSRECEIVED, CE.USEMESSAGE2FLAG, CE.GOVERNINGEVENTNO, 
		CASE WHEN (T.TYPEOFREQUEST=3 and (CE.EVENTDATE is not null or CE.OCCURREDFLAG between 1 and 8)) 
			 THEN 'I'-- Event has occurred or been updated
		     WHEN (T.TYPEOFREQUEST=6 and CE.EVENTDUEDATE is not null and CE.DATEDUESAVED=1)		-- RFC12050
			 THEN 'R1' -- Only want reminders to be recalculated for manually entered due date	-- RFC12050
		     WHEN (coalesce(E.NUMCYCLESALLOWED,V.NUMCYCLESALLOWED,1) < isnull(T.CYCLE,1) and CE.EVENTDATE is null and CE.EVENTDUEDATE is null)	-- RFC54876
		         THEN 'D'  -- Mark the row for deletion
	 		 ELSE 'C'  -- Recalculate the due date
		END,
		NULL, E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, 
		E.SAVEDUEDATE, E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, 
		E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, C.COUNTRYCODE, 
		
		CASE WHEN (T.TYPEOFREQUEST=6) THEN NULL ELSE CE.EVENTDATE END,
		
		CASE WHEN (T.TYPEOFREQUEST=6 and isnull(CE.DATEDUESAVED,0)=0) THEN NULL ELSE CE.EVENTDUEDATE END, 
		
		CASE WHEN (T.TYPEOFREQUEST=3 and CE.EVENTDATE is NULL) 	THEN 'Y'	-- Mark events that are cleared with USEDINCALCULATION flag 
		     WHEN (T.TYPEOFREQUEST in (2,6))			THEN 'Y'	-- Mark events whose due date is changed with the USEDINCALCULATION flag	
									ELSE NULL END,
		CASE WHEN (T.TYPEOFREQUEST in (2,6)) THEN NULL ELSE CE.DATEREMIND END, 
		T.SQLUSER, E.CRITERIANO, CR.ACTION, 
		CASE	WHEN (T.TYPEOFREQUEST=3 and CE.EVENTDATE is not null) THEN 1 ELSE 0 END, 
		E.ESTIMATEFLAG, E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,convert(bit,CE.CASEID),E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,
		E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
	from #TEMPPOLICING T
	left join CASEEVENT CE	on (CE.CASEID =T.CASEID
				and CE.EVENTNO=T.EVENTNO
				and CE.CYCLE  =isnull(T.CYCLE,1))
	join CASES C		on (C.CASEID  =T.CASEID)
	left join (select distinct CASEID, ACTION, CRITERIANO
		   from OPENACTION) O	
				on (O.CASEID=T.CASEID
				and O.ACTION=CE.CREATEDBYACTION)
	left join EVENTCONTROL E1	
				on (E1.EVENTNO   =T.EVENTNO
				and E1.CRITERIANO=isnull(O.CRITERIANO,T.CRITERIANO))
	-- RFC26121 Ensure the Criteria is valid for this Case
	left join OPENACTION O1	on (O1.CASEID=T.CASEID
				and O1.CRITERIANO=E1.CRITERIANO)
	left join (	select O.CASEID, EC.EVENTNO, min(EC.CRITERIANO) as CRITERIANO
			from OPENACTION O
			join EVENTCONTROL EC on (EC.CRITERIANO=O.CRITERIANO)
			where O.POLICEEVENTS=1
			group by O.CASEID, EC.EVENTNO) OA
				on (T.TYPEOFREQUEST in (2,3)
				and O1.CRITERIANO is null
				and OA.CASEID=C.CASEID
				and OA.EVENTNO=T.EVENTNO)
	left join EVENTS V	on (V.EVENTNO=T.EVENTNO)
	left join CRITERIA CR	on (CR.CRITERIANO=isnull(O1.CRITERIANO,OA.CRITERIANO))
	left join EVENTCONTROL E	
				on (E.CRITERIANO=CR.CRITERIANO
				and E.EVENTNO   =T.EVENTNO)
	left join PROPERTY P    on (P.CASEID=C.CASEID)
	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join ACTIONS A	on (A.ACTION=isnull(T.ACTION, CR.ACTION))
	left join #TEMPCASEEVENT TC
				on (TC.CASEID =T.CASEID
				and TC.EVENTNO=T.EVENTNO
				and TC.CYCLE  =isnull(T.CYCLE, 1))
	where T.TYPEOFREQUEST in (2,3,6)
	and   T.PROCESSED is null
	and  TC.CASEID    is null
	and  (CE.CASEID is not null OR T.TYPEOFREQUEST=6)	
	and  (T.TYPEOFREQUEST <>6 or (T.TYPEOFREQUEST=6 and (isnull(CE.OCCURREDFLAG,0)=0 OR (@pbRecalcEventDate=1 and E.RECALCEVENTDATE=1 and E.SAVEDUEDATE between 2 and 5))))
	--and   coalesce(E.NUMCYCLESALLOWED,V.NUMCYCLESALLOWED,1) >= isnull(T.CYCLE,1)
	and   (S.STATUSCODE  is null or	(S.POLICERENEWALS=1     and A.ACTIONTYPEFLAG=1)
				     or	(S.POLICEEXAM=1         and A.ACTIONTYPEFLAG=2)
				     or	(S.POLICEOTHERACTIONS=1 and A.ACTIONTYPEFLAG=0)
				     or	(S.POLICERENEWALS+S.POLICEEXAM+S.POLICERENEWALS >1 and A.ACTIONTYPEFLAG is null)
				     or  T.TYPEOFREQUEST in (2,3))
	and   (S1.STATUSCODE is null or (S1.POLICERENEWALS=1    and A.ACTIONTYPEFLAG=1)
				     or (A.ACTIONTYPEFLAG <>1	or  A.ACTIONTYPEFLAG is null)
				     or  T.TYPEOFREQUEST in (2,3))"
	
	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pbRecalcEventDate	bit',
					  @pbRecalcEventDate=@pbRecalcEventDate
	set @pnRowCount=@pnRowCount+@@RowCount
End

-- SQA 7237	Delete from #TEMPCASEEVENT any rows that have been entered more than once
-- 		where the row to be deleted does not have an open action against the Case.

If  @ErrorCode=0
Begin
	set @sSQLString="
	delete from #TEMPCASEEVENT
	where (CRITERIANO is null
	OR 	not exists
		(select * from OPENACTION OA
		 where OA.CASEID=#TEMPCASEEVENT.CASEID
		 and   OA.CRITERIANO=#TEMPCASEEVENT.CRITERIANO
		 and   OA.POLICEEVENTS=1) )
	AND	exists
		(select * from #TEMPCASEEVENT T
		 where T.CASEID =#TEMPCASEEVENT.CASEID
		 and   T.EVENTNO=#TEMPCASEEVENT.EVENTNO
		 and   T.CYCLE  =#TEMPCASEEVENT.CYCLE
		 and  (T.CRITERIANO<>#TEMPCASEEVENT.CRITERIANO OR (T.CRITERIANO is not null and #TEMPCASEEVENT.CRITERIANO is null)))"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set  @pnRowCount=@pnRowCount-@@Rowcount
End

-- Load #TEMPOPENACTION with the details of the Cases and Actions to be recalculated. 

If @ErrorCode=0
Begin
	-- TYPEOFREQUEST	1, 4
	-- =============	====
	-- Load details of the Action to be opened or recalculated from the POLICING table.
	-- The CriteriaNo and Action that created the Event is not always known so try and determine this by looking
	-- at the current OpenActions with a preference where the POLICEVENTS flag is ON.
	set @sSQLString="
	insert #TEMPOPENACTION (CASEID, ACTION, POLICEEVENTS, DATEENTERED, DATEUPDATED, CASETYPE, PROPERTYTYPE, COUNTRYCODE,
		CASECATEGORY, SUBTYPE, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE, RENEWALTYPE, CASEOFFICEID,[STATE],
		CYCLE, USERID,IDENTITYID)
	select	distinct	
		T.CASEID, T.ACTION, 

		-- If ValidAction row exists then set POLICEVENTS to 1 otherwise close it by setting to 0
		CASE WHEN (V.ACTION is not null) THEN 1 ELSE 0 END,
		getdate(), getdate(), C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY,
		C.SUBTYPE, P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, C.OFFICEID,

		-- If ValidAction row exists then recalculate the OpenAction otherwise do not.
		CASE WHEN (V.ACTION is not null) THEN 'C' ELSE 'C1' END,
		isnull(T.CYCLE,1), T.SQLUSER,T.IDENTITYID
	from	  #TEMPPOLICING T
	join	  ACTIONS A	on (A.ACTION=T.ACTION)
	join	  CASES	C	on (C.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID=T.CASEID)
	left join STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
	left join STATUS SR	on (SR.STATUSCODE=P.RENEWALSTATUS)
											-- Get the Validaction.  If it	
											-- does not exist then the 	
											-- OpenAction will be closed.	
	left join VALIDACTION V	on (V.CASETYPE    =C.CASETYPE
				and V.PROPERTYTYPE=C.PROPERTYTYPE
				and V.ACTION      =T.ACTION
				and V.COUNTRYCODE = (select min(COUNTRYCODE)
							from  VALIDACTION V1
							where V1.CASETYPE    =V.CASETYPE
							and   V1.PROPERTYTYPE=V.PROPERTYTYPE
							and   V1.ACTION      =V.ACTION
							and   V1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	where T.TYPEOFREQUEST in (1,4)
	and   T.PROCESSED is null
											-- Only calculate the row if the
											-- appropriate Status allows	
											-- the Action to be policed	
	and   (((A.ACTIONTYPEFLAG  =0 OR A.ACTIONTYPEFLAG is null) and (SC.POLICEOTHERACTIONS=1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =2 and (SC.POLICEEXAM        =1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =1 or SC.STATUSCODE  is null) 
        	                      and (SR.POLICERENEWALS    =1 or SR.STATUSCODE is null)))"
	
	exec @ErrorCode= sp_executesql @sSQLString
	Set  @pnRowCount=@pnRowCount+@@Rowcount
End

If @ErrorCode=0
Begin
	-- TYPEOFREQUEST	5
	-- =============	=
	-- Load details of the Events from Policing rows when Designated Country status changes.  This will potentially
	-- load multiple CaseEvent rows for each POLICING row.
	-- The CriteriaNo and Action that created the Event is not always known so try and determine this by looking
	-- at the current OpenActions with a preference where the POLICEVENTS flag is ON.
	set @sSQLString="
	insert into #TEMPCASEEVENT 
	(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
		OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA, CRITERIANO,ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
		DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO,[STATE],ADJUSTMENT,
		IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
		SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
		INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, NEWEVENTDATE, NEWEVENTDUEDATE,
		USEDINCALCULATION, DATEREMIND, USERID, ESTIMATEFLAG,EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
		CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2, LIVEFLAG,RESPNAMENO,RESPNAMETYPE,ACTION,RECALCEVENTDATE,
		SUPPRESSCALCULATION)
	SELECT	distinct C.CASEID,  E.DISPLAYSEQUENCE, E.EVENTNO, isnull(CE.CYCLE,1), 
		0, CE.EVENTDATE, CE.EVENTDUEDATE, CE.DATEDUESAVED, CE.OCCURREDFLAG, isnull(CE.CREATEDBYACTION, OA.ACTION), 
		isnull(CE.CREATEDBYCRITERIA, E.CRITERIANO),isnull(CE.CREATEDBYCRITERIA, E.CRITERIANO), CE.ENTEREDDEADLINE, CE.PERIODTYPE, CE.DOCUMENTNO, CE.DOCSREQUIRED,
		CE.DOCSRECEIVED, CE.USEMESSAGE2FLAG, CE.GOVERNINGEVENTNO, 
		'C',	-- Due date is to be recalculated
		NULL, E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, 
		E.SAVEDUEDATE, E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, 
		E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, C.COUNTRYCODE, 
		CE.EVENTDATE, NULL, NULL, CE.DATEREMIND, T.SQLUSER, E.ESTIMATEFLAG,
		E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,convert(bit,CE.CASEID),
		E.DUEDATERESPNAMENO, E.DUEDATERESPNAMETYPE,isnull(CE.CREATEDBYACTION, OA.ACTION),E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
	from #TEMPPOLICING T
	join OPENACTION OA	on (OA.CASEID		=T.CASEID
				and OA.POLICEEVENTS	=1)
	join EVENTCONTROL E	on (E.CRITERIANO	=OA.CRITERIANO
				and E.CHECKCOUNTRYFLAG  is not null)	-- RFC40843 Rule has CheckCountryFlag
	join DUEDATECALC DD	on (DD.CRITERIANO	=E.CRITERIANO
				and DD.EVENTNO   	=E.EVENTNO
				and DD.FROMEVENT  	is null
				and DD.COUNTRYCODE 	is not null)
	left join CASEEVENT CE	on (CE.CASEID		=T.CASEID
				and CE.EVENTNO		=E.EVENTNO)
	join CASES C		on (C.CASEID		=T.CASEID)
	left join PROPERTY P    on (P.CASEID		=C.CASEID)
	left join STATUS S	on (S.STATUSCODE	=C.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE	=P.RENEWALSTATUS)
	left join ACTIONS A	on (A.ACTION		=OA.ACTION)
	where T.TYPEOFREQUEST = 5
	and   T.PROCESSED is null
	and   isnull(CE.OCCURREDFLAG,0)=0	-- RFC40843 Only calculate the event if it has not occurred.
	and   (S.STATUSCODE  is null or	(S.POLICERENEWALS=1     and A.ACTIONTYPEFLAG=1)
				     or	(S.POLICEEXAM=1         and A.ACTIONTYPEFLAG=2)
				     or	(S.POLICEOTHERACTIONS=1 and A.ACTIONTYPEFLAG=0)
				     or	(S.POLICERENEWALS+S.POLICEEXAM+S.POLICERENEWALS >1 and A.ACTIONTYPEFLAG is null))
	and   (S1.STATUSCODE is null or (S1.POLICERENEWALS=1    and A.ACTIONTYPEFLAG=1)
				     or (A.ACTIONTYPEFLAG <>1	or  A.ACTIONTYPEFLAG is null))"
	
	exec @ErrorCode= sp_executesql @sSQLString
	Set  @pnRowCount=@pnRowCount+@@Rowcount
End

If @ErrorCode=0
Begin
	-- TYPEOFREQUEST	7
	-- =============	=
	-- Load details of CASES that have been flagged to recalculate the Patent Term Adjustment figures
	
	set @sSQLString="
	insert #TEMPCASES (CASEID, STATUSCODE, RENEWALSTATUS, REPORTTOTHIRDPARTY, PREDECESSORID, ACTION,  
			   EVENTNO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
			   BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE,RENEWALTYPE, INSTRUCTIONSLOADED,RECALCULATEPTA,
			   IPODELAY,APPLICANTDELAY,USERID,IDENTITYID,OFFICEID,CASELOGSTAMP,PROPERTYLOGSTAMP)
	select	C.CASEID, C.STATUSCODE, P.RENEWALSTATUS, C.REPORTTOTHIRDPARTY,C.PREDECESSORID, null, 
		null, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE,
		P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, 0,1,isnull(C.IPODELAY,0),
		isnull(C.APPLICANTDELAY,0),T.SQLUSER,T.IDENTITYID,C.OFFICEID,C.LOGDATETIMESTAMP,P.LOGDATETIMESTAMP
	from #TEMPPOLICING T
	join CASES C		on (C.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID=C.CASEID)
	where T.TYPEOFREQUEST=7"

	exec @ErrorCode= sp_executesql @sSQLString

	Set @nCasesRowCount=@@Rowcount

	If @nCasesRowCount>0
		Set @pbPTARecalc=1
End

-- Load #TEMPCASES with the details of the Cases being processed.

If  @ErrorCode=0
and @pnRowCount>0
Begin
	set @sSQLString="
	insert #TEMPCASES (CASEID, STATUSCODE, RENEWALSTATUS, REPORTTOTHIRDPARTY, PREDECESSORID, ACTION,  
			   EVENTNO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
			   BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE,RENEWALTYPE, INSTRUCTIONSLOADED,IPODELAY,
			   APPLICANTDELAY,USERID,IDENTITYID,OFFICEID,CASELOGSTAMP,PROPERTYLOGSTAMP)
	select	C.CASEID, C.STATUSCODE, P.RENEWALSTATUS, C.REPORTTOTHIRDPARTY,C.PREDECESSORID, null, 
		null, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE,
		P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, 0,isnull(C.IPODELAY,0),
		isnull(C.APPLICANTDELAY,0),T.USERID,T.IDENTITYID,C.OFFICEID,C.LOGDATETIMESTAMP,P.LOGDATETIMESTAMP
	from CASES C
	join #TEMPCASEEVENT T	on (T.CASEID=C.CASEID)
	left join PROPERTY P	on (P.CASEID=C.CASEID)
	left join #TEMPCASES TC	on (TC.CASEID=C.CASEID)
	where TC.CASEID is null
	union
	select	C.CASEID, C.STATUSCODE, P.RENEWALSTATUS, C.REPORTTOTHIRDPARTY,C.PREDECESSORID, null, 
		null, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE,
		P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, 0,isnull(C.IPODELAY,0),
		isnull(C.APPLICANTDELAY,0),T.USERID,T.IDENTITYID,C.OFFICEID,C.LOGDATETIMESTAMP,P.LOGDATETIMESTAMP
	from CASES C
	join #TEMPOPENACTION T	on (T.CASEID=C.CASEID)
	left join PROPERTY P	on (P.CASEID=C.CASEID)
	left join #TEMPCASES TC	on (TC.CASEID=C.CASEID)
	where TC.CASEID is null"

	exec @ErrorCode= sp_executesql @sSQLString

	Set @nCasesRowCount=@@Rowcount
End

If @ErrorCode=0
and @nCasesRowCount>0
Begin
	-- Load all of the Events into a temporary table for
	-- the Cases loaded.
	Execute @ErrorCode=ip_PoliceGetEventsForTempTable @pnDebugFlag
End

If @ErrorCode=0
and exists (select 1 from #TEMPPOLICING where  TYPEOFREQUEST=8)
Begin
	-- TYPEOFREQUEST	8
	-- =============	=
	-- These are Case Events that have occurred against a Case that we know that other
	-- Cases are monitoring.  Examples of this are Document Cases which are required to 
	-- have had an event occur before allowing an Event on a Property Case to occur.

	-- Finding these Cases can be slow due to the reverse best fit algorithm required
	-- to be used.  These requests will only be picked up if no other requests are 
	-- able to be processed.
	
	exec @ErrorCode= dbo.ip_PoliceDocumentCase
				@pnDebugFlag
End

If @ErrorCode=0
and exists (select 1 from #TEMPPOLICING where TYPEOFREQUEST=9)
and exists (select 1 from CASESEARCHRESULT)
Begin
	-- TYPEOFREQUEST	9
	-- =============	=
	-- Cases can be triggered to determine if cited Prior Art is to be distributed
	-- to other Cases that are either directly or indirectly related to each other.
	-- It is possible for these "families" of Cases to become quite large resulting 
	-- in a significant volume of Prior Art being referenced.  
	
	-- Triggering activities can include :
	-- 1) Changes in relationships between Cases
	-- 2) Changes in the Status of a Case

	-- To avoid significant performance problems during one of these activities the
	-- process has been moved into Policing so it can take place asynchronously as 
	-- a separate database transaction.
	
	exec @ErrorCode= dbo.ip_PolicePriorArtDistributions
				@pnDebugFlag
End

-- Flag the #TEMPPOLICING rows as having been processed.

If @ErrorCode=0
Begin
	Set @sSQLString="
	update #TEMPPOLICING
	set PROCESSED=1
	where PROCESSED is null"

	exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetTypeOfRequest',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*, @pnRowCount as 'Row Count' 
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		exec @ErrorCode= sp_executesql @sSQLString,
						N'@pnRowCount	int',
						  @pnRowCount
	End
End

-- Load #TEMPOPENACTION with the details of the Actions to be processed. 

If  @ErrorCode=0
and @pnRowCount>0
Begin
	execute @ErrorCode = dbo.ip_PoliceGetActions
					@nActionRowCount	OUTPUT,
					@pnDebugFlag
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetTypeOfRequest  to public
go