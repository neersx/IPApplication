-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetEventReminderToRecalculate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetEventReminderToRecalculate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetEventReminderToRecalculate.'
	drop procedure dbo.ip_PoliceGetEventReminderToRecalculate
end
print '**** Creating procedure dbo.ip_PoliceGetEventReminderToRecalculate...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetEventReminderToRecalculate
			 @pnRowCount	int	OUTPUT,
			 @pnDebugFlag	tinyint,
			 @nEventNo	int
as
-- PROCEDURE :	ip_PoliceGetEventReminderToRecalculate
-- VERSION :	27
-- DESCRIPTION:	A procedure to get the Case Event rows that are to have their DateRemind recalculated

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 19/09/2001	MF	7062		Procedure created
-- 18/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 11/02/2002	MF	7401		The SELECT that returns the CASEEVENT rows to police is joining on the OPENACTION table 
--					for rows that are marked for recalculation when it should just be processing rows that 
--					are currently available for Policing.
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 10/05/2002	MF	7646		Events that have had their due date saved should keep that flag on.  Currently
--					it is being reset.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 24 Jul 2003	MF	8260	10	Get PTADELAY flag from EventControl for Patent Term Adjustment calculation
-- 12 Nov 2003	MF	9450	11	Set the CRITERIANO on the #TEMPCASEEVENT table when inserting rows.
-- 26 Feb 2004	MF	RFC709	12	Get the IDENTITYID to identify workbench users
-- 03 Nov 2004	MF	10385	13	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 23 Jan 2006	MF	12223	14	Reminders are allowed to be calculated using the rules associated with any
--					open actions the Event is associated with.
-- 15 May 2006	MF	12315	15	New EventControl columns to set CASENAME when Event occurs.
-- 07 Jun 2006	MF	12417	16	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	17	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 31 May 2007	MF	14812	18	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	19	Reserve word [STATE]
-- 29 Oct 2007	MF	15518	20	Insert LIVEFLAG on #TEMPCASEEVENT
-- 07 Jan 2008	MF	15586	20	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 27 Jul 2009	MF	17922	21	Ensure rows inserted into #TEMPCASEEVENT have the ACTION column initialised to the same as CREATEDBYACTION.
-- 02 Aug 2011	MF	R11036	22	Recalculation of reminders only is not always picking up Events calculated by different Criteria.
-- 05 Jun 2012	MF	S19025	23	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 06 Jun 2013	MF	S21404	24	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 05 Dec 2014	MF	R42124	25	Events to have their Reminder Date recalculated are to have DATEREMIND set to NULL to force the EmployeeReminder
--					to be produced.  This will result in any existing EmployeeReminder having its ReminderDate updated.
-- 15 Mar 2017	MF	70049	26	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV  75198/DR-45358	27   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on

DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- The #TEMPCASEEVENT table is to be loaded with Events whose DateRemind is to be recalculated

-- STATE = 'R1' 

If  @ErrorCode=0
and @nEventNo is not null
Begin
	Set @sSQLString="
	insert into #TEMPCASEEVENT 
			(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
				OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA,CRITERIANO, ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
				DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO, [STATE], ADJUSTMENT,
				IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
				SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
				INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, USERID, NEWEVENTDUEDATE,
				USEDINCALCULATION, DATEREMIND, ESTIMATEFLAG,EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2, PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
				CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE,ACTION,RECALCEVENTDATE,
				SUPPRESSCALCULATION)
	SELECT	T.CASEID,  E.DISPLAYSEQUENCE, E.EVENTNO, isnull(CE.CYCLE, T.CYCLE),
		0, CE.EVENTDATE, CE.EVENTDUEDATE, CE.DATEDUESAVED, 0, CE.CREATEDBYACTION, CE.CREATEDBYCRITERIA,E.CRITERIANO, CE.ENTEREDDEADLINE, CE.PERIODTYPE, 
		CE.DOCUMENTNO, CE.DOCSREQUIRED, CE.DOCSRECEIVED, CE.USEMESSAGE2FLAG, CE.GOVERNINGEVENTNO, 'R1', 
		NULL, E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, 
		E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, 
		E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, T.COUNTRYCODE, T.USERID,
		CE.EVENTDUEDATE, NULL, NULL, E.ESTIMATEFLAG,E.EXTENDPERIOD,E.EXTENDPERIODTYPE,E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,1,
		E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,T.ACTION,E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
	From		#TEMPOPENACTION T
	join		ACTIONS A	on (A.ACTION=T.ACTION)
	join		EVENTCONTROL E	on (E.CRITERIANO=T.CRITERIANO
					and E.EVENTNO   =@nEventNo)
	join		CASEEVENT CE	on (CE.CASEID=T.CASEID
					and CE.EVENTNO=E.EVENTNO
					and CE.OCCURREDFLAG=0
										-- If the Action is cyclic then	
										-- use the cycle of the Open	
										-- Action row otherwise there is
										-- no restriction.		
					and CE.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED=1) THEN CE.CYCLE ELSE T.CYCLE END)
	join		#TEMPCASES C	on (C.CASEID=T.CASEID)
	left join	STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
	left join	STATUS SR	on (SR.STATUSCODE=C.RENEWALSTATUS)
	
	WHERE	T.POLICEEVENTS=1
										-- Only calculate the row if the
										-- appropriate Status allows	
										-- the Action to be policed	
	and    ((A.ACTIONTYPEFLAG  =0 and (SC.POLICEOTHERACTIONS=1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =2 and (SC.POLICEEXAM        =1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =1 or SC.STATUSCODE  is null) 
	                              and (SR.POLICERENEWALS    =1 or SR.STATUSCODE is null)))
	and exists
	(select * from REMINDERS R
	 where R.CRITERIANO=E.CRITERIANO
	 and   R.EVENTNO   =E.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nEventNo int',
				@nEventNo

	Set @pnRowCount=@@Rowcount

end

Else If  @ErrorCode=0
     and @nEventNo is null
Begin
	Set @sSQLString="
	insert into #TEMPCASEEVENT 
			(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
				OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA, CRITERIANO, ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
				DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO, [STATE], ADJUSTMENT,
				IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
				SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
				INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, USERID, NEWEVENTDUEDATE,
				USEDINCALCULATION, DATEREMIND, ESTIMATEFLAG,EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
				CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE,ACTION,RECALCEVENTDATE,
				SUPPRESSCALCULATION)
	SELECT	T.CASEID,  E.DISPLAYSEQUENCE, E.EVENTNO, isnull(CE.CYCLE, T.CYCLE),
		0, CE.EVENTDATE, CE.EVENTDUEDATE, CE.DATEDUESAVED, 0, CE.CREATEDBYACTION, CE.CREATEDBYCRITERIA, E.CRITERIANO, CE.ENTEREDDEADLINE, CE.PERIODTYPE, 
		CE.DOCUMENTNO, CE.DOCSREQUIRED, CE.DOCSRECEIVED, CE.USEMESSAGE2FLAG, CE.GOVERNINGEVENTNO, 'R1', 
		NULL, E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, 
		E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC,
		E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, T.COUNTRYCODE, T.USERID,
		CE.EVENTDUEDATE, NULL, NULL, E.ESTIMATEFLAG,E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,1,
		E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,T.ACTION,E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
	From		#TEMPOPENACTION T
	join		ACTIONS A	on (A.ACTION=T.ACTION)
	join		EVENTCONTROL E	on (E.CRITERIANO=T.CRITERIANO)
	join		CASEEVENT CE	on (CE.CASEID=T.CASEID
					and CE.EVENTNO=E.EVENTNO
					and CE.OCCURREDFLAG=0
										-- If the Action is cyclic then	
										-- use the cycle of the Open	
										-- Action row otherwise there is
										-- no restriction.		
					and CE.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED=1) THEN CE.CYCLE ELSE T.CYCLE END)
	join		#TEMPCASES C	on (C.CASEID=T.CASEID)
	left join	STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
	left join	STATUS SR	on (SR.STATUSCODE=C.RENEWALSTATUS)

										-- the CaseEvent row must not	
										-- exist or be a due date only	
	WHERE	T.[STATE]='C'
										-- Only calculate the row if the
										-- appropriate Status allows	
										-- the Action to be policed	
	and    ((A.ACTIONTYPEFLAG  =0 and (SC.POLICEOTHERACTIONS=1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =2 and (SC.POLICEEXAM        =1 or SC.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =1 or SC.STATUSCODE  is null) 
	                              and (SR.POLICERENEWALS    =1 or SR.STATUSCODE is null)))
	and exists
	(select * from REMINDERS R
	 where R.CRITERIANO=E.CRITERIANO
	 and   R.EVENTNO   =E.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @pnRowCount=@@Rowcount

end

-- Now set the state of the OPENACTION table to C1 so that it will not be recalculated.  It was originally
-- set to "C" only to indicate which Action's Events are to be recalculated.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update 	#TEMPOPENACTION
	set 	[STATE]='C1'
	where	[STATE]='C'"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetEventReminderToRecalculate',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*, @pnRowCount as 'Row Count' 
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		exec @ErrorCode= sp_executesql @sSQLString,
						N'@pnRowCount	int',
						  @pnRowCount
	End
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetEventReminderToRecalculate  to public
go
