
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetEventsToCalculateFromAction
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetEventsToCalculateFromAction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetEventsToCalculateFromAction.'
	drop procedure dbo.ip_PoliceGetEventsToCalculateFromAction
end
print '**** Creating procedure dbo.ip_PoliceGetEventsToCalculateFromAction...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetEventsToCalculateFromAction
				@pnRowCount		int	OUTPUT,
				@pbRecalcEventDate	bit	= 0,	-- SQA19252 Indicates some Events may trigger to recalculate by changes to their governing event
				@pnDebugFlag		tinyint

as
-- PROCEDURE :	ip_PoliceGetEventsToCalculateFromAction
-- VERSION :	49
-- DESCRIPTION:	A procedure to get the Case Event rows that are to be calculated
--              as a result of recalculating an Action
-- CALLED BY :	ipu_PoliceRecalc

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 13/07/2000	MF			Procedure created
-- 07/09/2001	MF	7041		Remove the "Satisfied" events code and move it into its own 
--					stored procedure (ipu_PoliceRemoveSatisfiedEvents) so it can 
--					be called from other locations.
-- 12/09/2001	MF	7053		If a due date calculation uses a relative cycle of Earliest or latest
--					and the Event is cyclic and the Action is non cyclic then use the cycle
--					of the calculation.
-- 02/10/2001	MF	7094		Events that exist on the database but have been marked to be deleted
--					should also be returned if the Action is being recalculated.
-- 09/10/2001	MF	7109		If the DATEDUESAVED flag is set ON but there is no Due Date then set it off.
-- 15/10/2001	MF	7117		If an Event is being recalculated and the Due Date is manually entered 
--					then the Event still needs to be returned for recalculation in case the 
--					Event is now satisfied by another event
-- 18/10/2001	MF	7130		The OCCURREDFLAG is to be set to 0 if it does not exist.
-- 14/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 29/01/2001	MF	7380		Return rows CASEEVENT that have been marked with the OCCURREDFLAG=9 just in case these 
--					cases are no longer satisfied.
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 21/05/2002	MF	7673		Events with manually entered due dates are not having the ReminderDate calculated
--					when the Action is recalculated.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 24 Jul 2003	MF	8260	10	Get PTADELAY from EventControl table for Patent Term Adjustment
-- 12 Nov 2003	MF	9450	11	Set the CRITERIANO on the #TEMPCASEEVENT table when inserting rows.
-- 26 Nov 2003	MF	9495	12	Ensure that newly calculated CaseEvents in the temporary table take 
--					precedence over the CaseEvents already in the database.
--  4 Feb 2004	MF	9666	13	When returning a CaseEvent to be recalculated even though it does not have 
--					due date calculation, the NEWEVENTDUEDATE should be set to NULL and the
--					CREATEDBYCRITERIA should be set to the CRITERIANO of the OPENACTION.
-- 26 Feb 2004	MF	RFC708	14	Get the IDENTITYID to identify workbench users.
-- 03 Nov 2004	MF	10385	15	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 12 Nov 2004	MF	10385	16	Revist due to coding error.
-- 15 Mar 2005	MF	11159	17	When 2 cycles of the same Action are being opened and the triggering events
--					are split between the CASEEVENT and TEMPCASEEVENT tables then not all
--					events were calculating.
-- 24 Jun 2005	MF	11547	18	When removing Events to be calculated from TEMPCASEEVENT because an appropriate
--					standing instruction or status does not exist, do remove any where there is an
--					old EventDate as these may have been previously cleared out which has triggered
--					the calculation to occur.  We need this to proceed so that the CASEEVENT row
--					will eventually be removed.
-- 24 Jan 2006	MF	12223	19	Events may belong to more than one Action and Reminders are allowed to be 
--					defined against a different Action to the one that has the due date calculation.
-- 15 May 2006	MF	12315	20	New EventControl colums to update CASENAME when Event occurs.
-- 07 Jun 2006	MF	12417	21	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	22	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 26 Sep 2006	MF	13412	23	If the CaseEvent row was manually created and there is no CreatedByAction/Criteria
--					it still needs to be returned in case there is an Event that will satisfy it.
-- 19 Oct 2006	MF	13089	24	Revisit 13089.  Remove reference to DIRECTPAYFLAG from this release.
-- 28 Feb 2007	PY	14425 	25 	Reserved word [state]
-- 24 May 2007	MF	14812	26	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	27	Reserve word [STATE]
-- 30 Oct 2007	MF	15518	28	Performance improvements to SQL.
-- 10 Apr 2008	MF	16234	29	Only change the STATE on #TEMPCASEEVENT to 'C' if the row belongs to the 
--					action that is to be recalculated.
-- 16 Apr 2008	MF	16249	30	Revisit 14812 to better handle Events under multiple Actions.
-- 25 Jun 2008	MF	16600	31	Invalid Policing Error being raised  "Due date rule for this Event exists
--					for more than 1 Action and is being ignored."  Check that there actually are
--					Due Date Calculation rows against each criteria.
-- 09 Jul 2008	MF	16684	32	Revisit SQA16600. Checking to see if Event can be calculated by more than 1 
--					criteria has slowed Policing down.  Correction required.
-- 28 Oct 2008	MF	17073	33	Improve performance by loading DUEDATECALC rows into a temporary table.
-- 10 Nov 2008	DL		34	Fixed a merge issue that caused duplicate variable declaration.
-- 18 Dec 2008	MF	17231	35	Return CaseEvent to be recalculated for an Action even if that CaseEvent 
--					already exists for a different Action.
-- 25 Feb 2009	MF	17435	36	Direct Pay Flag not being set on charges generated from Event when Action recalculated.
-- 09 Apr 2009	MF	17590	36	Do not recalculate a CaseEvent if its Due Date has been flagges as saved (DATEDUESAVED=1).
-- 11 Nov 2010	MF	R9954	37	Revisit of SQ15586 to ensure when Action recalculated that Due Date responsible Name and NameType are considered
-- 18 Oct 2011	MF	18798	38	Use OPTION(MAXDOP 1) to manually set the Maximum Degrees of Parallelism to a single processor. This will allow
--					the database to be set to use parallelism but those complex problem queries with this option will then
--					revert to no parallelism in order to get enhanced performance.
-- 24 Oct 2011	MF	R11457	39	When an ACTION is opened it may reference events that have already been calculated by another Action. If these
--					events have a STATE of 'R1' indicating that they are due dates whose calculation is now completed then an 
--					additional #TEMPCASEEVENT row is required to be inserted for the new Action to be considered in relation to that Event.
--					Also when checking to see if there are duplicate #TEMPCASEEVENT rows flagged to calculate under different CriteriaNo,
--					consideration to the [STATE] of these rows needs to be given as it could be the original #TEMPCASEEVENT row is no longer
--					relevant after the recalculation of the CRITERIANO for the Action.
-- 27 Feb 2012	MF	S20363	40	When the Event is being inserted into #TEMPCASEEVENT make sure the OCCURREDFLAG value is also 
--					carried over.
-- 29 May 2012	MF	R12367	41	Event triggered to recalculate for an Action that exists for a different Action needs to return the existing due date.
-- 04 Jun 2012	MF	S19252	42	Provide an option to enable Events that may recalculate after they have occurred to be triggered as a result of changes to the
--					governing date.
-- 05 Jun 2013	MF	R13549	43	DateRemind was not being saved in new row inserted into #TEMPCASEEVENT. This then allowed the system to think that the
--					reminder has not be calcualated before and is causing a new future reminder to be inserted.
-- 06 Jun 2013	MF	S21404	44	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 04 Dec 2014	MF	R41729	45	An event flagged as RECALCEVENTDATE should also be marked for recalculation even if there are no governing events to trigger it.
-- 15 Mar 2017	MF	70049	46	Allow Renewal Status to be separately specified to be updated by an Event.
-- 17 Mar 2017	MF	70947	46	Rework of 70049.
-- 24 Jul 2017	MF	72034	47	If an Event is defined under multiple Actions, then the Action in which the Event is allowed to calculate (SUPPRESSCALCULATION=0)
--					is to take precedence over Action(s) where the calculation is suppressed (SUPPRESSCALCULATION=1).
-- 31 Oct 2017	MF	72737	48	Following on from 72034 there was a situation where an Event existed under multiple Actions where the SUPPRESSCALCULATION=1 was set under the 
--					specific Action being recalculated.  This resulted in the Event Due Date being removed and the CASEEVENT marked for deletion.
-- 14 Nov 2018  AV  75198/DR-45358	49   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on
		

Create table #TEMPDUEDATECALC(
		CRITERIANO	int		NOT NULL,
		EVENTNO		int		NOT NULL,
		COUNTRYCODE	nvarchar(3)	collate database_default NOT NULL,
		CYCLENUMBER	smallint	NULL,
 		FROMEVENT	int		NULL,
 		RELATIVECYCLE	smallint	NULL,
 		EVENTDATEFLAG	smallint	NULL )

DECLARE		@ErrorCode	int,
		@nErrorCount	int,
		@nNewRows	int,
		@sSQLString	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- The #TEMPCASEEVENT table is to be loaded with Events that are eligible to be calculated

-- Load the events to be calculated.  This is done after the events to be deleted are loaded so that they are not 
-- reloaded.
-- STATE = 'C' (calculate)
If @ErrorCode=0
Begin
	Set @sSQLString=
	"Update #TEMPCASEEVENT
	Set [STATE]='C',
	NEWEVENTDUEDATE=CASE WHEN(@pbRecalcEventDate=1 and TC.RECALCEVENTDATE=1 and TC.OCCURREDFLAG between 1 and 8) 
				THEN NULL
				ELSE TC.NEWEVENTDUEDATE 
			END, 
	NEWEVENTDATE= 	CASE WHEN(@pbRecalcEventDate=1 and TC.RECALCEVENTDATE=1 and TC.OCCURREDFLAG between 1 and 8) 
				THEN NULL
				ELSE TC.NEWEVENTDATE 
			END, 
	OCCURREDFLAG=	CASE WHEN(@pbRecalcEventDate=1 and TC.RECALCEVENTDATE=1 and TC.OCCURREDFLAG between 1 and 8) 
				THEN 0
				ELSE TC.OCCURREDFLAG 
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
	CREATEDBYCRITERIA=T.NEWCRITERIANO,
	CREATEDBYACTION  =T.ACTION,
	ACTION           =T.ACTION,
	CRITERIANO       =T.NEWCRITERIANO,
	RESPNAMENO       =E.DUEDATERESPNAMENO,
	RESPNAMETYPE     =E.DUEDATERESPNAMETYPE,
	SUPPRESSCALCULATION=E.SUPPRESSCALCULATION,
	LIVEFLAG         =1
	from (	select T.CASEID, T.CYCLE, T.NEWCRITERIANO, T.ACTION, DD1.EVENTNO, max(isnull(DD1.COUNTRYCODE,'000')) as COUNTRY
		from #TEMPOPENACTION T
		join DUEDATECALC DD1	on (DD1.CRITERIANO=T.NEWCRITERIANO)
		where DD1.COMPARISON is null
		and (DD1.COUNTRYCODE=T.COUNTRYCODE or DD1.COUNTRYCODE is null)
		and T.[STATE] = 'C'
		group by T.CASEID, T.CYCLE, T.NEWCRITERIANO, T.ACTION, DD1.EVENTNO) T
	join DUEDATECALC DD
		on (DD.CRITERIANO=T.NEWCRITERIANO
		and DD.EVENTNO=T.EVENTNO
		and isnull(DD.COUNTRYCODE,'000')=T.COUNTRY)
	join EVENTCONTROL E
		on ( E.CRITERIANO=DD.CRITERIANO
		and  E.EVENTNO   =DD.EVENTNO)
	join ACTIONS A
		on (A.ACTION=T.ACTION)
		-- Look for the Events that might trigger other events to be calculated.
		-- Derived table required to avoid ambiguous table error
	join (	select * from #TEMPCASEEVENT
		where [STATE] not like 'D%') CE
		on (CE.CASEID=T.CASEID
		and CE.EVENTNO=DD.FROMEVENT)
		-- The TEMPCASEEVENT row to be updated
	join #TEMPCASEEVENT TC
		on  (TC.CASEID	=T.CASEID
		and  TC.EVENTNO=E.EVENTNO
		and  TC.CYCLE	=Case DD.RELATIVECYCLE
					WHEN (0) Then CE.CYCLE
					WHEN (1) Then CE.CYCLE+1
					WHEN (2) Then CE.CYCLE-1
					WHEN (3) Then CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
			 			 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
		     		 End
		and  isnull(TC.ACTION,T.ACTION)=T.ACTION)
	join #TEMPCASES C	on (C.CASEID=TC.CASEID)
	left join STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
	left join STATUS SR	on (SR.STATUSCODE=C.RENEWALSTATUS)
	left join #TEMPCASEINSTRUCTIONS CI
		on (CI.CASEID=TC.CASEID
		and CI.INSTRUCTIONTYPE=TC.INSTRUCTIONTYPE)
	left join INSTRUCTIONFLAG F
		on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE
		and F.FLAGNUMBER=TC.FLAGNUMBER)
		-- Actions to be calculated			
	WHERE	TC.[STATE]<>'C'
	and	isnull(E.SUPPRESSCALCULATION,0)=0	
		-- the CaseEvent row must not have occurred
		-- or it must be marked for deletion	
	and	(isnull(TC.OCCURREDFLAG,0) in (0,9) OR TC.[STATE] like 'D%' OR (@pbRecalcEventDate=1 AND TC.RECALCEVENTDATE=1 AND TC.SAVEDUEDATE between 2 and 5 and TC.[STATE]='X'))		
		-- Check Status
	and    ((isnull(A.ACTIONTYPEFLAG,0)=0 and isnull(SC.POLICEOTHERACTIONS,1)=1)
	 or     (	A.ACTIONTYPEFLAG   =2 and  isnull(SC.POLICEEXAM,1)        =1)
	 or     (	A.ACTIONTYPEFLAG   =1 and (isnull(SC.POLICERENEWALS,1)    =1 or SR.POLICERENEWALS=1)))
		-- Check Instruction
	and (TC.INSTRUCTIONTYPE is null OR F.INSTRUCTIONCODE is not null)
		-- Consider whether the EVENTDUEDATE or EVENDATE	
		-- is required in the calculation.
		-- RelativeCycle indicating the Next Cycle is required means	
		-- that the Cycle cannot be 1.	
	and ((CE.NEWEVENTDATE is not null and DD.EVENTDATEFLAG in (1,3)) or (CE.NEWEVENTDUEDATE is not null and DD.EVENTDATEFLAG in (2,3)))
	and ((CE.CYCLE >1 and DD.RELATIVECYCLE=2) or (DD.RELATIVECYCLE <>2))
		-- if the action is non cyclic then the Event can be any    
		-- cycle otherwise the cycle of the event must match the     
		-- cycle of the open action	
	and (A.NUMCYCLESALLOWED = 1
	 OR (A.NUMCYCLESALLOWED >1
	 AND T.CYCLE=Case DD.RELATIVECYCLE
			WHEN(0) Then CE.CYCLE
			WHEN(1) Then CE.CYCLE+1
			WHEN(2) Then CE.CYCLE-1
			WHEN(3) Then CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
				Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
		    End))
	and E.NUMCYCLESALLOWED >=
		Case DD.RELATIVECYCLE
			WHEN(0) Then CE.CYCLE	-- cycles allowed	
			WHEN(1) Then CE.CYCLE+1	-- must not be exceeded
			WHEN(2) Then CE.CYCLE-1
			WHEN(3) Then CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
				Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
		End"
		
	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pbRecalcEventDate	bit',
					  @pbRecalcEventDate=@pbRecalcEventDate

	Set @pnRowCount=@@Rowcount
End

If @ErrorCode=0
Begin
	-- Update the rows where the Reminder must be recalculated

	Set @sSQLString="
	Update #TEMPCASEEVENT
	Set [STATE]     ='R1',
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
	CREATEDBYCRITERIA=T.NEWCRITERIANO,
	CREATEDBYACTION  =T.ACTION,
	ACTION           =T.ACTION,
	CRITERIANO       =T.NEWCRITERIANO,
	RESPNAMENO       =E.DUEDATERESPNAMENO,
	RESPNAMETYPE     =E.DUEDATERESPNAMETYPE,
	LIVEFLAG         =1
	From #TEMPOPENACTION T
	join EVENTCONTROL E	on ( E.CRITERIANO=T.NEWCRITERIANO)		
	join #TEMPCASEEVENT TC	on  (TC.CASEID =T.CASEID
				and  TC.EVENTNO=E.EVENTNO
				and  isnull(TC.ACTION,T.ACTION)=T.ACTION)
	WHERE	T.[STATE]  = 'C'
	and	TC.[STATE] in ('X', 'R1') -- The event may have previously been calculated or not calculated
	and	TC.OCCURREDFLAG=0

	-- Either the due date has been manually entered or there is no
	-- due date rule.  The Reminder Date still must be calculated though.

	and    (TC.DATEDUESAVED=1
	 or not exists 
	       (select 1 from DUEDATECALC DD
		where DD.CRITERIANO=E.CRITERIANO
		and DD.EVENTNO=E.EVENTNO))

	-- A Reminder rule must exist

	and exists
	(select 1 from REMINDERS R
	 where R.CRITERIANO=E.CRITERIANO
	 and   R.EVENTNO   =E.EVENTNO)"

	exec @ErrorCode=sp_executesql @sSQLString

	set @pnRowCount=@pnRowCount+@@Rowcount
End

If @ErrorCode=0
Begin
	-- Flag the Events to recalculate even if there is no due date rule

	Set @sSQLString="
	Update #TEMPCASEEVENT 
	Set
	NEWEVENTDUEDATE=CASE WHEN(@pbRecalcEventDate=1 and TC.RECALCEVENTDATE=1 and TC.OCCURREDFLAG between 1 and 8) 
				THEN NULL
				ELSE TC.NEWEVENTDUEDATE 
			END, 
	NEWEVENTDATE= 	CASE WHEN(@pbRecalcEventDate=1 and TC.RECALCEVENTDATE=1 and TC.OCCURREDFLAG between 1 and 8) 
				THEN NULL
				ELSE TC.NEWEVENTDATE 
			END, 
	OCCURREDFLAG=	CASE WHEN(@pbRecalcEventDate=1 and TC.RECALCEVENTDATE=1 and TC.OCCURREDFLAG between 1 and 8) 
				THEN 0
	                     WHEN(TC.OCCURREDFLAG is null) 
				THEN 0
	                     WHEN(TC.OCCURREDFLAG = 9)
				THEN 0
				ELSE TC.OCCURREDFLAG 
			END, 
	
	DATEDUESAVED=   CASE WHEN(@pbRecalcEventDate=1 and TC.RECALCEVENTDATE=1 and TC.OCCURREDFLAG between 1 and 8) 
				THEN 0
				ELSE isnull(TC.DATEDUESAVED,0)
			END, 

	-- Set the STATE to 'R' if the due date has been previously calculated as this will stop it from being	
	-- recalculated however it will be available to automatically occur if this is appropriate.		
	[STATE]=CASE WHEN(@pbRecalcEventDate=1 and TC.RECALCEVENTDATE=1 and TC.OCCURREDFLAG between 1 and 8) THEN 'C'
	             WHEN (TC.DATEDUESAVED=1 AND TC.NEWEVENTDUEDATE is not NULL ) THEN 'R' 
		     WHEN (TC.[STATE]='R1') THEN 'R'
		     WHEN (TC.[STATE]='X')  THEN 'C'
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
	CREATEDBYCRITERIA=T.NEWCRITERIANO,
	CREATEDBYACTION  =T.ACTION,
	ACTION           =T.ACTION,
	CRITERIANO       =T.NEWCRITERIANO,
	RESPNAMENO       =E.DUEDATERESPNAMENO,
	RESPNAMETYPE     =E.DUEDATERESPNAMETYPE,
	SUPPRESSCALCULATION=E.SUPPRESSCALCULATION,
	LIVEFLAG         =1
	From	#TEMPOPENACTION T 
	join	ACTIONS A	on (A.ACTION=T.ACTION)
	join	EVENTCONTROL E	on (E.CRITERIANO=T.NEWCRITERIANO)

	-- Check now to see if the Event under consideration to	be calculated already exists 
	-- as it will not be required if a row exists already.
	join	#TEMPCASEEVENT TC	
				on (TC.CASEID	   	=T.CASEID 
				and TC.EVENTNO	   	=E.EVENTNO
				and isnull(TC.ACTION,T.ACTION)=T.ACTION
				and(TC.OCCURREDFLAG	in (0,9) OR (@pbRecalcEventDate=1 and TC.RECALCEVENTDATE=1))
				)

	-- Only process Actions that have been flagged to be calculated
	WHERE	T.[STATE] = 'C'
	and	isnull(E.SUPPRESSCALCULATION,0)=0
	 -- The event may have previously been calculated or not calculated yet
	and    TC.[STATE] in ('X', 'R1')
	-- the cycle of Event must match the cycle of the OpenAction if the Action is cyclic.	
	and    (A.NUMCYCLESALLOWED=1 OR T.CYCLE=TC.CYCLE)"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pbRecalcEventDate	bit',
					  @pbRecalcEventDate=@pbRecalcEventDate

	Set @pnRowCount=@pnRowCount+@@Rowcount
End

If @ErrorCode=0
Begin
	-- R11457
	-- Where the newly opened Action references an Event that already
	-- exists as a due date but does not have any due date calculation 
	-- rules itself then add a new row so that other aspects of the 
	-- rule are considered.
	Set @sSQLString="
	insert into #TEMPCASEEVENT 
			(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, OLDEVENTDUEDATE,NEWEVENTDUEDATE, DATEREMIND, LOOPCOUNT, OCCURREDFLAG, DATEDUESAVED, 
				CREATEDBYACTION, CREATEDBYCRITERIA, ACTION, CRITERIANO,
				[STATE], 
				IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
				SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
				INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, USERID, 
				ESTIMATEFLAG, EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
				CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME,DIRECTPAYFLAG,DIRECTPAYFLAG2,RESPNAMENO,RESPNAMETYPE,RECALCEVENTDATE,SUPPRESSCALCULATION)
	SELECT	Distinct
		TC.CASEID,  E.DISPLAYSEQUENCE, TC.EVENTNO, TC.CYCLE, TC.OLDEVENTDUEDATE, TC.NEWEVENTDUEDATE, TC.DATEREMIND, 0, TC.OCCURREDFLAG, TC.DATEDUESAVED,
		TC.ACTION, TC.CRITERIANO, T.ACTION, E.CRITERIANO, 
		'R', 
		E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, 
		E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION,E.INITIALFEE,E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, 
		E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE,E.FLAGNUMBER,E.SETTHIRDPARTYON,TC.COUNTRYCODE,TC.USERID,
		E.ESTIMATEFLAG,
		E.EXTENDPERIOD, E.EXTENDPERIODTYPE,E.INITIALFEE2,E.PAYFEECODE2,E.ESTIMATEFLAG2,E.PTADELAY,TC.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME,E.DIRECTPAYFLAG,E.DIRECTPAYFLAG,E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,
		CASE WHEN(TC.RECALCEVENTDATE    =1) THEN 1 ELSE isnull(E.RECALCEVENTDATE,    0) END,
		CASE WHEN(TC.SUPPRESSCALCULATION=1) THEN 1 ELSE isnull(E.SUPPRESSCALCULATION,0) END
	From	#TEMPOPENACTION T 
	join	ACTIONS A	on (A.ACTION=T.ACTION)
	join	EVENTCONTROL E	on (E.CRITERIANO=T.NEWCRITERIANO)

	-- The Event under consideration must already exist as a due date
	-- for a different Action to the one being calculated.
	join	#TEMPCASEEVENT TC	
				on (TC.CASEID	   	=T.CASEID 
				and TC.EVENTNO	   	=E.EVENTNO
				and isnull(TC.ACTION,T.ACTION)<>T.ACTION
				and TC.OCCURREDFLAG	in (0,9))

	-- The Event under consideration must already exist as a due date
	-- for a different Action to the one being calculated.
	left join #TEMPCASEEVENT TC1	
				on (TC1.CASEID =TC.CASEID 
				and TC1.EVENTNO=TC.EVENTNO
				and TC1.CYCLE  =TC.CYCLE
				and TC1.ACTION =T.ACTION)

	-- No due date calculations exist for this Event and Action
	left join (select distinct CRITERIANO, EVENTNO
		   from DUEDATECALC) DD
				on (DD.CRITERIANO=E.CRITERIANO
				and DD.EVENTNO   =E.EVENTNO)

	-- Only process Actions that have been flagged to be calculated
	WHERE	T.[STATE] = 'C'
	 -- The event may have previously been calculated or not calculated yet
	and    TC.[STATE] in ('X', 'R1')
	 -- The event may not already exist against for this Action
	and    TC1.CASEID is null
	-- the cycle of Event must match the cycle of the OpenAction if the Action is cyclic.	
	and    (A.NUMCYCLESALLOWED=1 OR T.CYCLE=TC.CYCLE)
	-- No due date calculations exist for this Event and Action
	and DD.CRITERIANO is null"

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @pnRowCount=@pnRowCount+@@Rowcount
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into  #TEMPDUEDATECALC(CRITERIANO,EVENTNO,CYCLENUMBER,COUNTRYCODE,FROMEVENT,RELATIVECYCLE,EVENTDATEFLAG)
	select distinct DD.CRITERIANO,DD.EVENTNO,DD.CYCLENUMBER,isnull(DD.COUNTRYCODE,'000'),DD.FROMEVENT,DD.RELATIVECYCLE,DD.EVENTDATEFLAG
	from #TEMPOPENACTION T
	join DUEDATECALC DD	on (DD.CRITERIANO=T.NEWCRITERIANO)
	where DD.COMPARISON is null
	and (DD.COUNTRYCODE=T.COUNTRYCODE or DD.COUNTRYCODE is null)
	and T.[STATE] = 'C'
	
	CREATE INDEX XIE1TEMPDUEDATECALC ON #TEMPDUEDATECALC
	(
		CRITERIANO	ASC,
		EVENTNO		ASC,
		COUNTRYCODE	ASC
	)"
	
	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	-- It is possible for new #TEMPCASEEVENT rows to be created if the 
	-- relative cycle results in a new cycle being triggered
	Exec ("
	insert into #TEMPCASEEVENT 
			(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OCCURREDFLAG, DATEDUESAVED,
				CREATEDBYACTION, CREATEDBYCRITERIA, ACTION, CRITERIANO,
				[STATE], OLDEVENTDUEDATE,
				IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
				SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
				INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, USERID, 
				ESTIMATEFLAG, EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
				CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME,DIRECTPAYFLAG,DIRECTPAYFLAG2,RESPNAMENO,RESPNAMETYPE,RECALCEVENTDATE,
				SUPPRESSCALCULATION)
	SELECT	Distinct
		T.CASEID,  E.DISPLAYSEQUENCE, DD.EVENTNO,
		Case DD.RELATIVECYCLE	WHEN (0) Then CE.CYCLE
					WHEN (1) Then CE.CYCLE+1
					WHEN (2) Then CE.CYCLE-1
					WHEN (3) Then CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
						 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
		End, 0, 0, 0,
		T.ACTION, E.CRITERIANO, T.ACTION, E.CRITERIANO, 
		'C', TC.OLDEVENTDUEDATE,	-- RFC12367
		E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, 
		E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION,E.INITIALFEE,E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, 
		E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE,E.FLAGNUMBER,E.SETTHIRDPARTYON,T.COUNTRYCODE,T.USERID,
		E.ESTIMATEFLAG,
		E.EXTENDPERIOD, E.EXTENDPERIODTYPE,E.INITIALFEE2,E.PAYFEECODE2,E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME,E.DIRECTPAYFLAG,E.DIRECTPAYFLAG,E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,
		E.RECALCEVENTDATE, E.SUPPRESSCALCULATION
										-- the due date rule must either match
										-- the Country of the Case or be NULL.
										-- Substituting '000' for NULL to avoid
										-- getting the Warning for an aggregate
										-- statement removing a NULL.
	From (	select T.CASEID, T.USERID,T.IDENTITYID, T.CYCLE, T.NEWCRITERIANO, T.ACTION, DD1.EVENTNO, max(DD1.COUNTRYCODE) as COUNTRYCODE
		from #TEMPOPENACTION T
		join #TEMPDUEDATECALC DD1	on (DD1.CRITERIANO=T.NEWCRITERIANO)
		where T.[STATE]='C'
		and (DD1.COUNTRYCODE=T.COUNTRYCODE or DD1.COUNTRYCODE='000')
		group by T.CASEID,T.USERID,T.IDENTITYID, T.CYCLE, T.NEWCRITERIANO, T.ACTION, DD1.EVENTNO) T
	join		#TEMPDUEDATECALC DD
					on (DD.CRITERIANO=T.NEWCRITERIANO
					and DD.EVENTNO=T.EVENTNO
					and DD.COUNTRYCODE=T.COUNTRYCODE)
	join		EVENTCONTROL E	on ( E.CRITERIANO=DD.CRITERIANO
					and  E.EVENTNO   =DD.EVENTNO)
	join		ACTIONS	A	on ( A.ACTION	 =T.ACTION)
										
			-- Look for the Events that might trigger other
			-- events to be calculated.

	join 		#TEMPCASEEVENT CE	on (CE.CASEID=T.CASEID
						and CE.EVENTNO=DD.FROMEVENT)
			-- Check now to see if the Event under consideration to	
			-- be calculated already exists (for the same Action) as
			-- it will not be required if a row exists already or the
			-- event has already occurred.	
	left join	#TEMPCASEEVENT TC
					on  (TC.CASEID	=T.CASEID 
					and  TC.EVENTNO =E.EVENTNO
					and  TC.CYCLE	=Case DD.RELATIVECYCLE
								WHEN (0) Then CE.CYCLE
								WHEN (1) Then CE.CYCLE+1
								WHEN (2) Then CE.CYCLE-1
								WHEN (3) Then CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
						 			 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
					     		 End)
	join #TEMPCASES C	on (C.CASEID=T.CASEID)
	left join STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
	left join STATUS SR	on (SR.STATUSCODE=C.RENEWALSTATUS)
	left join #TEMPCASEINSTRUCTIONS CI	
					on (CI.CASEID=T.CASEID
					and CI.INSTRUCTIONTYPE=E.INSTRUCTIONTYPE)
	left join INSTRUCTIONFLAG F	on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE
					and F.FLAGNUMBER=E.FLAGNUMBER)

		-- If a TEMPCASEEVENT row exists then it must not be flagged for deletion.	
	WHERE   CE.[STATE] not like 'D%'
	and	isnull(E.SUPPRESSCALCULATION,0)=0	-- RFC72737

		-- the TEMPCASEEVENT row of the	event to be calculated may not already exist for the same Action
	and	(TC.CASEID is null OR (TC.ACTION<>T.ACTION AND isnull(TC.DATEDUESAVED,0)=0 AND TC.NEWEVENTDATE is null))-- SQA17590 & RFC12367

		-- Check Status
	and    ((isnull(A.ACTIONTYPEFLAG,0)=0 and  isnull(SC.POLICEOTHERACTIONS,1)=1)
	 or     (	A.ACTIONTYPEFLAG   =2 and  isnull(SC.POLICEEXAM,1)        =1)
	 or     (	A.ACTIONTYPEFLAG   =1 and (isnull(SC.POLICERENEWALS,1)    =1 or SR.POLICERENEWALS=1)))

		-- Check Instruction
	and (E.INSTRUCTIONTYPE is null OR F.INSTRUCTIONCODE is not null)

		-- The cycle of the due date rule 
		-- must <= the cycle of the Event
		-- to be calculated	
	and	 DD.CYCLENUMBER<=CASE DD.RELATIVECYCLE	WHEN (0) Then CE.CYCLE
							WHEN (1) Then CE.CYCLE+1
							WHEN (2) Then CE.CYCLE-1
							WHEN (3) Then CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
								 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
				 END
		-- Take into consideration whether the EVENTDUEDATE or
		-- the EVENTDATE is required in the calculation. Also the	
		-- RelativeCycle indicating the	Next Cycle is required means	
		-- that the Cycle cannot be 1.	
	and     ((CE.NEWEVENTDATE is not null and DD.EVENTDATEFLAG in (1,3)) or (CE.NEWEVENTDUEDATE is not null and DD.EVENTDATEFLAG in (2,3)))  
	and 	((CE.CYCLE >1 and DD.RELATIVECYCLE=2) or (DD.RELATIVECYCLE <>2))

										-- if the action is non cyclic	
										-- then the Event can be any    
										-- cycle otherwise the cycle of 
										-- the event must match the     
										-- cycle of the open action	
	and	(A.NUMCYCLESALLOWED = 1 OR 
		(A.NUMCYCLESALLOWED >1 AND T.CYCLE=Case DD.RELATIVECYCLE WHEN(0) Then CE.CYCLE
									 WHEN(1) Then CE.CYCLE+1
									 WHEN(2) Then CE.CYCLE-1
									 WHEN(3) Then CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
										 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
						    End))

	and	E.NUMCYCLESALLOWED >=	   Case DD.RELATIVECYCLE WHEN(0) Then CE.CYCLE	-- the number of cycles allowed	
								 WHEN(1) Then CE.CYCLE+1	-- for the Event must not be	
								 WHEN(2) Then CE.CYCLE-1	-- exceeded			
								 WHEN(3) Then CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
									 Else CASE WHEN (A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE isnull(DD.CYCLENUMBER,1) END 	-- SQA 7053
					    End
	OPTION (MAXDOP 1)")

	Select	@ErrorCode=@@Error,
		@nNewRows=@@RowCount,
		@pnRowCount=@pnRowCount+@@RowCount
End

-- Check the #TEMPCASEEVENT table for any duplicates and report these as errors
-- and then remove them to allow processing to continue

If  @ErrorCode=0
and @nNewRows>0 -- Only need to do this if we have just inserted #TEMPCASEEVENT rows
Begin
	-------------------------------------------------
	-- If dupicate #TEMPCASEEVENT rows exist, delete
	-- those that have SUPPRESSCALCULATION=1 if there
	-- are other rows where SUPPRESSCALCULATION=0
	-------------------------------------------------
	If  @ErrorCode=0
	Begin
		Set @sSQLString="
		Delete #TEMPCASEEVENT
		from #TEMPCASEEVENT T
		join (	select distinct CRITERIANO, EVENTNO
			from DUEDATECALC
			where OPERATOR is not null) DD
					on (DD.CRITERIANO=T.CREATEDBYCRITERIA
					and DD.EVENTNO=T.EVENTNO)
		where T.[STATE]='C' 
		and T.SUPPRESSCALCULATION=1
		and exists
		(select * from #TEMPCASEEVENT T1
		 join DUEDATECALC DD1 on (DD1.CRITERIANO=T1.CREATEDBYCRITERIA
				      and DD1.EVENTNO=T1.EVENTNO)
		 where T1.CASEID	   = T.CASEID
		 and   T1.EVENTNO	   = T.EVENTNO
		 and   T1.CYCLE		   = T.CYCLE
		 and   T1.[STATE]          ='C'
		 and   isnull(T1.SUPPRESSCALCULATION,0)=0
		 and   DD1.OPERATOR is not null)"
		
		Exec @ErrorCode=sp_executesql @sSQLString
		Set @pnRowCount=@pnRowCount-@@Rowcount
	
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPPOLICINGERRORS (CASEID, EVENTNO, CYCLENO, CRITERIANO, MESSAGE)
		select T.CASEID, T.EVENTNO, T.CYCLE, T.CREATEDBYCRITERIA, 
		      'Due date rule for this Event exists for more than 1 Action and is being ignored.  Action '
		      +T1.CREATEDBYACTION+' & Criteriano '+convert(nvarchar,T1.CREATEDBYCRITERIA)+' are being used.'
		from #TEMPCASEEVENT T
		join (	select distinct CRITERIANO, EVENTNO
			from DUEDATECALC
			where OPERATOR is not null) DD
					on (DD.CRITERIANO=T.CREATEDBYCRITERIA
					and DD.EVENTNO=T.EVENTNO)
		join #TEMPCASEEVENT T1	on (T1.CASEID		=T.CASEID
					and T1.EVENTNO		=T.EVENTNO
					and T1.CYCLE		=T.CYCLE
					and T1.CREATEDBYCRITERIA<T.CREATEDBYCRITERIA
					and T1.[STATE]          ='C')
		join (	select distinct CRITERIANO, EVENTNO
			from DUEDATECALC
			where OPERATOR is not null) DD1
					on (DD1.CRITERIANO=T1.CREATEDBYCRITERIA
					and DD1.EVENTNO=T1.EVENTNO)
		where T.[STATE] = 'C'"

		Exec @ErrorCode=sp_executesql @sSQLString
		Set @nErrorCount=@@Rowcount
	End

	If  @ErrorCode=0
	and @nErrorCount>0
	Begin
		Set @sSQLString="
		Delete #TEMPCASEEVENT
		from #TEMPCASEEVENT T
		join (	select distinct CRITERIANO, EVENTNO
			from DUEDATECALC
			where OPERATOR is not null) DD
					on (DD.CRITERIANO=T.CREATEDBYCRITERIA
					and DD.EVENTNO=T.EVENTNO)
		where [STATE]='C' 
		and exists
		(select * from #TEMPCASEEVENT T1
		 join DUEDATECALC DD1 on (DD1.CRITERIANO=T1.CREATEDBYCRITERIA
				      and DD1.EVENTNO=T1.EVENTNO)
		 where T1.CASEID	   = T.CASEID
		 and   T1.EVENTNO	   = T.EVENTNO
		 and   T1.CYCLE		   = T.CYCLE
		 and   T1.CREATEDBYCRITERIA< T.CREATEDBYCRITERIA
		 and   T1.[STATE]          ='C'
		 and   DD1.OPERATOR is not null)"
		
		Exec @ErrorCode=sp_executesql @sSQLString
		Set @pnRowCount=@pnRowCount-@@Rowcount
	
	End
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetEventsToCalculateFromAction',0,1,@sTimeStamp ) with NOWAIT

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

drop table #TEMPDUEDATECALC

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetEventsToCalculateFromAction  to public
go