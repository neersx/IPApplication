-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceUpdateRelatedCaseEvent
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceUpdateRelatedCaseEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceUpdateRelatedCaseEvent.'
	drop procedure dbo.ip_PoliceUpdateRelatedCaseEvent
end
print '**** Creating procedure dbo.ip_PoliceUpdateRelatedCaseEvent...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceUpdateRelatedCaseEvent
				@pnRowCount	int	OUTPUT,
				@pnDebugFlag	tinyint
as
-- PROCEDURE :	ip_PoliceUpdateRelatedCaseEvent
-- VERSION :	21
-- DESCRIPTION:	A procedure that identifies CASEEVENT rows to be updated because a Related Case
--              is related by a Relationship that indicates the date for this Event is to be
--		copied to the Related Case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Feb 2006	MF	10983	1	Procedure created
-- 15 May 2006	MF	12315	2	New EventControl columns to update CASENAME when Event occurs.
-- 06 Jun 2006	MF	12723	3	When inserting rows into #TEMPCASES ensure that NULLs are replaced with
--					zero for RECALCULATEPTA, IPODELAY and APPLICANTDELAY
-- 07 Jun 2006	MF	12417	4	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	5	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 10 Aug 2007	MF	12548	6	Load #TEMPCASES.OFFICEID
-- 24 May 2007	MF	14812	7	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	8	Reserve word [STATE]
-- 07 Jan 2008	MF	15586	9	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 16 Apr 2008	MF	16249	10	Revisit 14812 to better handle Events under multiple Actions.
-- 27 Apr 2008	MF	16617	11	Error referencing NEWCRITERIANO.
-- 24 Jul 2009	MF	16548	12	The FROMEVENTNO will now identify the Event from a related Case that will be pushed
--					into the child Case.
-- 27 Jul 2009	MF	17922	13	Ensure rows inserted into #TEMPCASEEVENT have the ACTION column initialised to the same as CREATEDBYACTION.
-- 01 Jul 2011	MF	10929	14	Keep track of when the CASES and PROPERTY rows were last updated so that we can check that no changes
--					have been applied to the database when Policing attempts to update these.
-- 03 May 2012	MF	20554	15	This is a follow on from SQA16548.  If the FROMEVENTNO and the EVENTNO specified against the Relationship
--					are different then changes to the parent Case date were not being pushed down into the child case.
-- 06 Jun 2012	MF	S19025	16	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 06 Jun 2013	MF	S21404	17	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 17 Aug 2015	MF	51112	18	The EARLIESTDATEFLAG of the Relationship was not always being correctly considered.
-- 15 Mar 2017	MF	70049	19	Allow Renewal Status to be separately specified to be updated by an Event.
-- 24 Jul 2017	MF	72034	20	If an Event is defined under multiple Actions, then the Action in which the Event is allowed to calculate (SUPPRESSCALCULATION=0)
--					is to take precedence over Action(s) where the calculation is suppressed (SUPPRESSCALCULATION=1).
-- 14 Nov 2018  AV  75198/DR-45358	21   Date conversion errors when creating cases and opening names in Chinese DB


set nocount on

-- An interim step is required to find the Events that are to be updated so that the 
-- TEMPCASEEVENT table can be updated.  Load these events into a new temporary table 
-- to simplify the SQL.

CREATE TABLE #TEMPUPDATECASEEVENT (
        CASEID			int		NOT NULL,
        EVENTNO			int		NOT NULL,
        CYCLE			smallint	NOT NULL,
	RELATIONSHIP		nvarchar(3)	collate database_default NOT NULL,
	EARLIESTDATEFLAG	bit		NULL,
	USERID			nvarchar(255)	collate database_default NULL,
	IDENTITYID		int		NULL,
	FROMEVENTNO		int		NOT NULL
	)

DECLARE		@bGetParent	bit,
		@ErrorCode	int,
		@nRowCount	int,
		@nRowCount2	int,
		@sSQLString	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0
Set @pnRowCount= 0

-- Identify the Related Cases whose CaseEvent is to be updated as a result of 
-- a change to the current Event because there is a rule against the Relationship
-- Note that these rules only apply to Cycle 1
If  @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPUPDATECASEEVENT(CASEID, EVENTNO, CYCLE, RELATIONSHIP, EARLIESTDATEFLAG,USERID,IDENTITYID,FROMEVENTNO)
	select	distinct RC.CASEID, CR.EVENTNO, T.CYCLE, CR.RELATIONSHIP, CR.EARLIESTDATEFLAG,T.USERID,T.IDENTITYID,T.EVENTNO
	from	#TEMPCASEEVENT	T
	join	RELATEDCASE RC	on ( RC.RELATEDCASEID=T.CASEID)
	join 	CASERELATION CR	on ( CR.RELATIONSHIP=RC.RELATIONSHIP
				and  CR.FROMEVENTNO=T.EVENTNO)
	where T.[STATE] in ('I','R','D')
	and  T.CYCLE=1
	and isnull(CR.DISPLAYEVENTONLY,0)=0"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@@Rowcount
End


-- Check if any rows have just been inserted for a related Case then the Case and OpenAction
-- details for that Case will have to be loaded.

If  @ErrorCode=0
and @nRowCount>0
begin
	Set @sSQLString="
	select @bGetParent=1
	from #TEMPUPDATECASEEVENT UC
	where not exists
	(select * from #TEMPCASES T
	 where T.CASEID=UC.CASEID)"
	
	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@bGetParent 	bit	 	OUTPUT',
					  @bGetParent=@bGetParent 	OUTPUT
End

If  @ErrorCode=0
and @bGetParent=1
Begin
	-- Load the #TEMPOPENACTIONS table
	Set @sSQLString="
	insert #TEMPOPENACTION
		(CASEID, ACTION, CYCLE, LASTEVENT, CRITERIANO, DATEFORACT, NEXTDUEDATE, POLICEEVENTS,
		 STATUSCODE, STATUSDESC, DATEENTERED, DATEUPDATED, CASETYPE, PROPERTYTYPE, COUNTRYCODE,
		 CASECATEGORY, SUBTYPE, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE, RENEWALTYPE,
		 CASEOFFICEID, NEWCRITERIANO,[STATE],USERID,IDENTITYID)
	select	distinct OA.CASEID,OA.ACTION,OA.CYCLE,OA.LASTEVENT,OA.CRITERIANO,OA.DATEFORACT,OA.NEXTDUEDATE,OA.POLICEEVENTS,
		OA.STATUSCODE,OA.STATUSDESC,OA.DATEENTERED,OA.DATEUPDATED,C.CASETYPE,C.PROPERTYTYPE,C.COUNTRYCODE,
		C.CASECATEGORY,C.SUBTYPE,P.BASIS,P.REGISTEREDUSERS,C.LOCALCLIENTFLAG,P.EXAMTYPE,P.RENEWALTYPE,
		C.OFFICEID,OA.CRITERIANO, 'C1', TC.USERID,TC.IDENTITYID
	from	#TEMPUPDATECASEEVENT TC
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
		Set @sSQLString="
		insert #TEMPCASES (CASEID, STATUSCODE, RENEWALSTATUS, REPORTTOTHIRDPARTY, PREDECESSORID, ACTION,  
				   EVENTNO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
				   BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE,RENEWALTYPE, INSTRUCTIONSLOADED,
				   IPODELAY,APPLICANTDELAY,USERID,IDENTITYID,OFFICEID,CASELOGSTAMP,PROPERTYLOGSTAMP)

		select	distinct C.CASEID, C.STATUSCODE, P.RENEWALSTATUS, C.REPORTTOTHIRDPARTY,C.PREDECESSORID, null, 
				 null, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE,
				 P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, 0,isnull(C.IPODELAY,0),
				 isnull(C.APPLICANTDELAY,0), TC.USERID,TC.IDENTITYID,C.OFFICEID,C.LOGDATETIMESTAMP,P.LOGDATETIMESTAMP
		from #TEMPUPDATECASEEVENT TC
		join CASES C		on (C.CASEID=TC.CASEID)
		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
		left join PROPERTY P    on (P.CASEID=C.CASEID)
		left join #TEMPCASES T	on (T.CASEID=TC.CASEID)
		where T.CASEID is null"

		Exec @ErrorCode=sp_executesql @sSQLString

		Set @nRowCount2=@@Rowcount
	
		If @nRowCount2>0
		Begin
			-- Get any Standing Instructions for Cases that have just been added.
			If  @ErrorCode=0
			Begin
				execute @ErrorCode = dbo.ip_PoliceGetStandingInstructions @pnDebugFlag
			End

			-- Load all CaseEvents into temporary table for the Cases added
			If  @ErrorCode=0
			Begin
				Execute @ErrorCode=ip_PoliceGetEventsForTempTable @pnDebugFlag
			End
		End
	End
End

-- Now update the TEMPCASEEVENT table to set the STATE, and NEWEVENTDATE.
-- Note that the STATE will be set to 'IX' so as to not confuse it with the original "I" rows which will be
-- updated to "I1" to indicate they have been processed.

-- Do this Update for each different STATE so that we can keep the various counts up to date.

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	update	#TEMPCASEEVENT
	set 	[STATE]	        =CASE WHEN(TU.NEWEVENTDATE is null) THEN 'C' ELSE 'IX' END,
		OCCURREDFLAG    =CASE WHEN(TU.NEWEVENTDATE is null) THEN 0   ELSE 1    END,
		NEWEVENTDATE    =TU.NEWEVENTDATE,
		LOOPCOUNT       =isnull(LOOPCOUNT,0)+1,
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
		CREATEDBYCRITERIA=isnull(T.CREATEDBYCRITERIA,CR.CRITERIANO),
		CREATEDBYACTION  =isnull(T.CREATEDBYACTION,CR.ACTION),
		CRITERIANO       =CR.CRITERIANO,
		ACTION           =CR.ACTION,
		RECALCEVENTDATE    =CASE WHEN(T.RECALCEVENTDATE    =1)	THEN 1 ELSE isnull(E.RECALCEVENTDATE,    0) END,
		SUPPRESSCALCULATION=CASE WHEN(T.SUPPRESSCALCULATION=1 OR DD.CRITERIANO is not null) 
									THEN T.SUPPRESSCALCULATION ELSE isnull(E.SUPPRESSCALCULATION,0) END,
		LIVEFLAG         =1
	from 	#TEMPCASEEVENT T
	join	(select UC.CASEID, UC.EVENTNO, UC.CYCLE, 
		  CASE WHEN(UC.EARLIESTDATEFLAG=1)
			THEN min(coalesce(TC.NEWEVENTDATE,CE.EVENTDATE,RC.PRIORITYDATE))
			ELSE max(coalesce(TC.NEWEVENTDATE,CE.EVENTDATE,RC.PRIORITYDATE))
		  END as NEWEVENTDATE
		 from #TEMPUPDATECASEEVENT UC
		 join RELATEDCASE RC		on (RC.CASEID=UC.CASEID
						and RC.RELATIONSHIP=UC.RELATIONSHIP)
		 left join #TEMPCASEEVENT TC	on (TC.CASEID=RC.RELATEDCASEID
						and TC.EVENTNO=UC.FROMEVENTNO
						and TC.CYCLE=1)
		 left join CASEEVENT CE		on (CE.CASEID=RC.RELATEDCASEID
						and CE.EVENTNO=UC.FROMEVENTNO
						and CE.CYCLE=1
						and CE.EVENTDATE is not null
						-- only use CASEEVENT if no #TEMPCASEEVENT row
						and TC.CASEID is null)
		 where coalesce(TC.NEWEVENTDATE,CE.EVENTDATE,RC.PRIORITYDATE) is not null
		 group by UC.CASEID, UC.EVENTNO, UC.CYCLE, UC.EARLIESTDATEFLAG) TU 
					on (TU.CASEID = T.CASEID
				        and TU.EVENTNO= T.EVENTNO
				        and TU.CYCLE  = T.CYCLE)
		-- Get the EVENTCONTROL by using
		-- the Criteriano of the Open Action
	left join EVENTCONTROL	E  on (E.CRITERIANO=(	select max(TA.NEWCRITERIANO)
							from #TEMPOPENACTION TA
							join EVENTCONTROL E1	on (E1.CRITERIANO=TA.NEWCRITERIANO
										and E1.EVENTNO=T.EVENTNO)
							where TA.CASEID=T.CASEID
							and   TA.POLICEEVENTS=1)
				   and E.EVENTNO   =T.EVENTNO)
	left join CRITERIA CR	   on (CR.CRITERIANO=E.CRITERIANO)
	left join (select distinct CRITERIANO, EVENTNO
		   from DUEDATECALC
		   where OPERATOR is not null) DD
					on (DD.CRITERIANO=T.CREATEDBYCRITERIA
					and DD.EVENTNO=T.EVENTNO)
	where (T.NEWEVENTDATE<>TU.NEWEVENTDATE 
	   OR (T.NEWEVENTDATE is null     and TU.NEWEVENTDATE is not null)
	   OR (T.NEWEVENTDATE is not null and TU.NEWEVENTDATE is null))"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @pnRowCount=@pnRowCount+@@RowCount
End

--==============================
-- Load the #TEMPCASEEVENT table with Events that are to be updated if they do not already exist on the
-- #TEMPCASEEVENT table

-- STATE = 'IX' (inserted) if there is a NEWEVENTDATE value otherwise 'C'

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	insert into #TEMPCASEEVENT 
			(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
				OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA,CRITERIANO, ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
				DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO,[STATE],ADJUSTMENT,
				IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
				SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
				INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, USERID,
				NEWEVENTDUEDATE,NEWEVENTDATE,ESTIMATEFLAG, EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
				CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,RESPNAMENO,RESPNAMETYPE,ACTION, RECALCEVENTDATE,
				SUPPRESSCALCULATION)
	SELECT	TU.CASEID,  E.DISPLAYSEQUENCE, TU.EVENTNO, 1,
		0, CE1.EVENTDATE, CE1.EVENTDUEDATE, 
		CE1.DATEDUESAVED, 
		CASE WHEN(TU.NEWEVENTDATE is null) THEN 0 ELSE 1 END, 
		CE1.CREATEDBYACTION, CE1.CREATEDBYCRITERIA, CE1.CREATEDBYCRITERIA, CE1.ENTEREDDEADLINE, CE1.PERIODTYPE, CE1.DOCUMENTNO, 
		CE1.DOCSREQUIRED, CE1.DOCSRECEIVED, CE1.USEMESSAGE2FLAG, CE1.GOVERNINGEVENTNO, 
		CASE WHEN(TU.NEWEVENTDATE is null) THEN 'C' ELSE 'IX' END, 
		NULL,E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, E.STATUSCODE, E.RENEWALSTATUS,
		E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, E.CLOSEACTION, E.RELATIVECYCLE,
		E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, T.COUNTRYCODE, TU.USERID,
		CE1.EVENTDUEDATE, TU.NEWEVENTDATE, E.ESTIMATEFLAG, E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,TU.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,
		E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,CE1.CREATEDBYACTION, E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
	from	(select UC.CASEID, UC.EVENTNO, UC.CYCLE, UC.USERID, UC.IDENTITYID,
		  CASE WHEN(UC.EARLIESTDATEFLAG=1)
			THEN min(coalesce(TC.NEWEVENTDATE,CE.EVENTDATE,RC.PRIORITYDATE))
			ELSE max(coalesce(TC.NEWEVENTDATE,CE.EVENTDATE,RC.PRIORITYDATE))
		  END as NEWEVENTDATE
		 from #TEMPUPDATECASEEVENT UC
		 join RELATEDCASE RC		on (RC.CASEID=UC.CASEID
						and RC.RELATIONSHIP=UC.RELATIONSHIP)
		 left join #TEMPCASEEVENT TC	on (TC.CASEID=RC.RELATEDCASEID
						and TC.EVENTNO=UC.FROMEVENTNO
						and TC.CYCLE=1)
		 left join CASEEVENT CE		on (CE.CASEID=RC.RELATEDCASEID
						and CE.EVENTNO=UC.FROMEVENTNO
						and CE.CYCLE=1
						and CE.EVENTDATE is not null
						-- only use CASEEVENT if no #TEMPCASEEVENT row
						and TC.CASEID is null)
		 where coalesce(TC.NEWEVENTDATE,CE.EVENTDATE,RC.PRIORITYDATE) is not null
		 group by UC.CASEID, UC.EVENTNO, UC.CYCLE, UC.EARLIESTDATEFLAG,UC.USERID, UC.IDENTITYID) TU 
	     join #TEMPCASES	T   on (T.CASEID=TU.CASEID)
	left join CASEEVENT	CE1 on (CE1.CASEID =TU.CASEID
				   and  CE1.EVENTNO=TU.EVENTNO
				   and  CE1.CYCLE  =1)
										-- Get the EVENTCONTROL either	
										-- by using the CreatedbyCriteria
										-- if it exists or use the	
										-- Criteriano of the Open Action
	left join EVENTCONTROL	E  on (E.CRITERIANO=isnull(CE1.CREATEDBYCRITERIA, (select max(TA.NEWCRITERIANO)
										   from #TEMPOPENACTION TA
										   join EVENTCONTROL E1 on (E1.CRITERIANO=TA.NEWCRITERIANO
													and E1.EVENTNO=TU.EVENTNO)
										   where TA.CASEID=TU.CASEID
										   and   TA.POLICEEVENTS=1))
				   and E.EVENTNO   =TU.EVENTNO)
	left join #TEMPCASEEVENT T3 on(T3.CASEID =TU.CASEID
				   and T3.EVENTNO=TU.EVENTNO
				   and T3.CYCLE  =1)
	where T3.CASEID is null -- Event being inserted must not exist
	and (CE1.EVENTDATE<>TU.NEWEVENTDATE 
	 OR (CE1.EVENTDATE is null     and TU.NEWEVENTDATE is not null)
	 OR (CE1.EVENTDATE is not null and TU.NEWEVENTDATE is null))"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @pnRowCount=@pnRowCount+@@RowCount
End

If  @pnDebugFlag>0
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceUpdateRelatedCaseEvent',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		Exec @ErrorCode = sp_executesql @sSQLString
	End
End

drop table #TEMPUPDATECASEEVENT

return @ErrorCode
go

grant execute on dbo.ip_PoliceUpdateRelatedCaseEvent  to public
go

