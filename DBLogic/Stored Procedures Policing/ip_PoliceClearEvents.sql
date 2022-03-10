-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceClearEvents 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceClearEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceClearEvents.'
	drop procedure dbo.ip_PoliceClearEvents
end
print '**** Creating procedure dbo.ip_PoliceClearEvents...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure [dbo].[ip_PoliceClearEvents]
				@pnCountStateC		int	OUTPUT,
				@pnCountStateI		int	OUTPUT,
				@pnCountStateR		int	OUTPUT,
				@pnCountStateD		int	OUTPUT,
				@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PoliceClearEvents
-- VERSION :	36
-- DESCRIPTION:	A procedure that identifies CASEEVENT rows to be cleared and recalculated
--              as a result of another Event being updated.

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 11/09/2000	MF			Procedure created
-- 16/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 24 JUL 2003	MF	8260	10	Get PTADELAY flag from EventControl for Patent Term Adjustment calculation
-- 23 OCT 2003	MF	9375	11	When an Event is cleared out it should not attempt to recalculate if there 
--					is no OpenAction
-- 12 Nov 2003	MF	9450	12	Set the CRITERIANO on the #TEMPCASEEVENT table when inserting rows.
-- 26 Feb 2004	MF	RFC709	13	Require IDENTITYID to identify workbench users
-- 29 Oct 2004	MF	10606	14	If the NEWEVENTDATE is not cleared out then do not reset the STATE to 'C'
-- 03 Nov 2004	MF	10385	15	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 15 May 2006	MF	12315	16	New EventControl columns to update CASENAME rows when Event occurs.
-- 07 Jun 2006	MF	12417	17	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	18	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 16 Jan 2006	MF	14145	19	Use the CriteriaNo from the associated open action rather than the original 
--					criteriano of the Case Event.  This is to cater for the situation where an
--					event that has occurred previously has since had a change of Criteria.
-- 31 May 2007	MF	14812	20	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	21	Reserve word [STATE]
-- 24 Jan 2007	MF	15868	22	@pnCountStateI incorrectly being decremented
-- 04 Apr 2008	MF	16208	23	Provide for new Relative Cycles as follows :
--						5 - Clear all cycles
--						6 - Clear all cycles less than triggering cycle
--						7 - Clear all cycles greater than triggering cycle 
-- 16 Apr 2008	MF	16249	24	Revisit 14812 to better handle Events under multiple Actions.
-- 08 Sep 2008	MF	16899	25	Allow events to be cleared when a due date is updated.
-- 12 Nov 2008	MF	17115	26	When determining if the cleared event is to be recalculated, do not use the
--					CREATEDBYACTION for checking if the OpenAction exists.
-- 07 Sep 2009	MF	18019	27	OpenAction must match on Cycle for cyclic Actions for recalc to be allowed.
-- 17 Mar 2010	MF	18553	28	Event that has been cleared out is not always recalculating. Need to consider Events that can be 
--					set from a related Case and not just those that have a due date calculation.
-- 26 Mar 2010	MF	18576	29	The due date of an Event is not being cleared if the Event is already on the queue to recalculate.
--					Remove the restriction that the Event to be cleared should not have a State of 'C'.
-- 20 Dec 2011	MF	R11727	30	When setting the CriteriaNo use the NEWCRITERIANO if it is available.
-- 30 Jan 2012	MF	R11851	31	Action was inadvertently being cleared out.
-- 05 Jun 2012	MF	S19025	32	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 11 Sep 2015	MF	R51626	33	Triggering of a due date to recalculate was ignoring the situation where the due date had been entered
--					manually. If there were no due date calculation rules the NEWEVENTDUEDATE column was being cleared and
--					the STATE incorrectly set to C1 instead of C. Even when there is a manually entered due date we need to
--					trigger calculation so as to consider Reminders.
-- 15 Mar 2017	MF	70049	34	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV	DR-45358 35	Date conversion errors when creating cases and opening names in Chinese DB
-- 29 Nov 2019	MF	DR-54681 36	Problems caused when an Event exists against multiple Actions. Each TEMPCASEEVENT records the ACTION the Event exists under.  This ACTION was being 
--					changed at times and as a result caused another TEMPCASEEVENT row to be inserted for that same ACTION resulting in exponential growth of TEMPCASEEVENT.
--					The ACTION should not have been changed.

set nocount on

DECLARE		@ErrorCode	int,
		@nRowCount	int,
		@sSQLString	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- Now update the TEMPCASEEVENT table to set the STATE, NEWEVENTDATE and NEWEVENTDUEDATE as required
-- when the Event Date has occurred or changed

If  @ErrorCode=0
Begin
	Set @sSQLString="
	update	#TEMPCASEEVENT
	Set
	@pnCountStateI = @pnCountStateI - CASE WHEN(T.[STATE]='I') THEN CASE WHEN(isnull(TC.CLEAREVENT,0)=0 and T.NEWEVENTDATE is not null) THEN 0 ELSE 1 END ELSE 0 END,
	@pnCountStateR = @pnCountStateR - CASE	WHEN(T.[STATE]='R') THEN 1 ELSE 0 END,
	@pnCountStateC = @pnCountStateC+ 
			CASE	WHEN(T.[STATE] like 'C%') THEN 0
			      	WHEN(T.[STATE]='I') THEN CASE WHEN(isnull(TC.CLEAREVENT,0)=0 and T.NEWEVENTDATE is not null) THEN 0 ELSE 1 END
				ELSE 1
			END,
	[STATE]=	CASE WHEN(T.[STATE]='I')
				THEN CASE WHEN(isnull(TC.CLEAREVENT,0)=0 and T.NEWEVENTDATE is not null) THEN 'I'
					ELSE CASE WHEN(OA.NEWCRITERIANO is not null OR T.DATEDUESAVED=1) THEN 'C' ELSE 'C1' END
				     END
				ELSE CASE WHEN(OA.NEWCRITERIANO is not null OR T.DATEDUESAVED=1) THEN 'C' ELSE 'C1' END
			END,
	CREATEDBYCRITERIA=isnull(OA.NEWCRITERIANO,T.CREATEDBYCRITERIA),
	NEWEVENTDATE   =CASE TC.CLEAREVENT WHEN(1) THEN NULL
				ELSE T.NEWEVENTDATE
			END,
	NEWEVENTDUEDATE=CASE WHEN(TC.CLEARDUE=1) THEN NULL
			      WHEN(OA.NEWCRITERIANO is NULL and isnull(T.DATEDUESAVED,0)=0) THEN NULL
				ELSE T.NEWEVENTDUEDATE
			END,
	DATEDUESAVED   =CASE TC.CLEARDUE WHEN(1) THEN NULL
				ELSE T.DATEDUESAVED
			END,
	OCCURREDFLAG   =CASE TC.CLEAREVENT WHEN(1) THEN 0
				ELSE T.OCCURREDFLAG
			END,
	-- Only increment loop count if the State is being changed
	LOOPCOUNT=LOOPCOUNT+
		CASE	WHEN(T.[STATE]='I') THEN CASE WHEN(isnull(TC.CLEAREVENT,0)=0 and T.NEWEVENTDATE is not null) THEN 0 ELSE 1 END
			WHEN(T.[STATE]='C') THEN 0 ELSE 1
		END,
	DISPLAYSEQUENCE=E.DISPLAYSEQUENCE,
	IMPORTANCELEVEL=E.IMPORTANCELEVEL,
	WHICHDUEDATE=E.WHICHDUEDATE,
	COMPAREBOOLEAN=E.COMPAREBOOLEAN,
	CHECKCOUNTRYFLAG=E.CHECKCOUNTRYFLAG,
	SAVEDUEDATE=E.SAVEDUEDATE,
	STATUSCODE=E.STATUSCODE,
	RENEWALSTATUS=E.RENEWALSTATUS,
	SPECIALFUNCTION=E.SPECIALFUNCTION,
	INITIALFEE=E.INITIALFEE,
	PAYFEECODE=E.PAYFEECODE,
	CREATEACTION=E.CREATEACTION,
	STATUSDESC=E.STATUSDESC,
	CLOSEACTION=E.CLOSEACTION,
	RELATIVECYCLE=E.RELATIVECYCLE,
	INSTRUCTIONTYPE=E.INSTRUCTIONTYPE,
	FLAGNUMBER=E.FLAGNUMBER,
	SETTHIRDPARTYON=E.SETTHIRDPARTYON,
	ESTIMATEFLAG=E.ESTIMATEFLAG,
	EXTENDPERIOD=E.EXTENDPERIOD,
	EXTENDPERIODTYPE=E.EXTENDPERIODTYPE,
	INITIALFEE2=E.INITIALFEE2,
	PAYFEECODE2=E.PAYFEECODE2,
	ESTIMATEFLAG2=E.ESTIMATEFLAG2,
	PTADELAY=E.PTADELAY,
	SETTHIRDPARTYOFF=E.SETTHIRDPARTYOFF,
	CHANGENAMETYPE=E.CHANGENAMETYPE,
	COPYFROMNAMETYPE=E.COPYFROMNAMETYPE,
	COPYTONAMETYPE=E.COPYTONAMETYPE,
	DELCOPYFROMNAME=E.DELCOPYFROMNAME,
	DIRECTPAYFLAG=E.DIRECTPAYFLAG,
	DIRECTPAYFLAG2=E.DIRECTPAYFLAG2,
	RESPNAMENO=isnull(T.RESPNAMENO,E.DUEDATERESPNAMENO),
	RESPNAMETYPE=isnull(T.RESPNAMETYPE,E.DUEDATERESPNAMETYPE),
	CREATEDBYACTION=isnull(OA.ACTION,T.CREATEDBYACTION),
	CRITERIANO=isnull(OA.NEWCRITERIANO,T.CRITERIANO),
	-- ACTION=isnull(OA.ACTION,T.ACTION),		-- Commented out because this is changing the Action and results in the same row being reinserted into #TEMPCASEEVENT
	LIVEFLAG=OA.POLICEEVENTS
	from 	#TEMPCASEEVENT T
	join
	(select distinct T1.CASEID, T1.EVENTNO, T1.CYCLE, RE.CLEAREVENT, RE.CLEARDUE
	from #TEMPCASEEVENT T
	join RELATEDEVENTS RE	on ( RE.CRITERIANO=T.CRITERIANO
		and  RE.EVENTNO=T.EVENTNO
		and (RE.CLEAREVENT = 1 OR RE.CLEARDUE =1))
	join #TEMPCASEEVENT T1	on ( T1.CASEID =T.CASEID
		and  T1.EVENTNO=RE.RELATEDEVENT
		and((T1.CYCLE  < T.CYCLE and RE.RELATIVECYCLE=6)
		 OR (T1.CYCLE  > T.CYCLE and RE.RELATIVECYCLE=7)
		 OR  T1.CYCLE  =CASE RE.RELATIVECYCLE
				WHEN (0) THEN T.CYCLE
				WHEN (1) THEN T.CYCLE-1
				WHEN (2) THEN T.CYCLE+1
				WHEN (3) THEN 1
				WHEN (4) THEN (	select max(CYCLE)
						from #TEMPCASEEVENT T2
						where T2.CASEID =T1.CASEID
						and   T2.EVENTNO=T1.EVENTNO)
				WHEN (5) THEN T1.CYCLE
			END))
	where T.[STATE]='I') TC on (TC.CASEID = T.CASEID
			and TC.EVENTNO= T.EVENTNO
			and TC.CYCLE  = T.CYCLE)
	left join
	(select distinct A.CASEID,A.ACTION,A.CYCLE,A.NEWCRITERIANO,A.CRITERIANO,A.POLICEEVENTS,EC.EVENTNO,AC.NUMCYCLESALLOWED
	 from #TEMPOPENACTION A
	 join EVENTCONTROL EC     on (EC.CRITERIANO=A.NEWCRITERIANO)
	 left join DUEDATECALC DD on (DD.CRITERIANO=A.NEWCRITERIANO
				   and DD.EVENTNO=EC.EVENTNO)
	 join ACTIONS AC	   on (AC.ACTION=A.ACTION)
	 where A.POLICEEVENTS=1
	 and (DD.CRITERIANO is not null OR EC.UPDATEFROMEVENT is not null)) OA
		on (OA.CASEID=T.CASEID
		and OA.EVENTNO=T.EVENTNO
		and(OA.CYCLE=T.CYCLE OR OA.NUMCYCLESALLOWED=1))
	left join EVENTCONTROL E
		on (E.CRITERIANO=OA.NEWCRITERIANO
		and E.EVENTNO=T.EVENTNO)
	where T.[STATE] not like 'D%'
	and((T.NEWEVENTDATE is not null and TC.CLEAREVENT=1)
	 or (T.NEWEVENTDATE is null and TC.CLEARDUE=1))"

	Exec @ErrorCode = sp_executesql @sSQLString,
						N'@pnCountStateC	int	OUTPUT,
						  @pnCountStateI	int	OUTPUT,
						  @pnCountStateR	int	OUTPUT',
						  @pnCountStateC		OUTPUT,
						  @pnCountStateI		OUTPUT,
						  @pnCountStateR		OUTPUT
End

-- Now update the TEMPCASEEVENT table to set the STATE, NEWEVENTDATE and NEWEVENTDUEDATE as required
-- when the Event Due Date has changed

If  @ErrorCode=0
Begin
	Set @sSQLString="
	update	#TEMPCASEEVENT
	Set
	@pnCountStateI = @pnCountStateI - CASE WHEN(T.[STATE]='I') THEN CASE WHEN(isnull(TC.CLEAREVENTONDUECHANGE,0)=0 and T.NEWEVENTDATE is not null) THEN 0 ELSE 1 END ELSE 0 END,
	@pnCountStateR = @pnCountStateR - CASE	WHEN(T.[STATE]='R') THEN 1 ELSE 0 END,
	@pnCountStateC = @pnCountStateC +
			CASE	WHEN(T.[STATE] like 'C%') THEN 0
				WHEN(T.[STATE]='I') THEN CASE WHEN(isnull(TC.CLEAREVENTONDUECHANGE,0)=0 and T.NEWEVENTDATE is not null) THEN 0 ELSE 1 END ELSE 1
			END,
	[STATE]=CASE WHEN(T.[STATE]='I')
			THEN CASE WHEN(isnull(TC.CLEAREVENTONDUECHANGE,0)=0 and T.NEWEVENTDATE is not null) THEN 'I'
				ELSE CASE WHEN(OA.NEWCRITERIANO is not null OR T.DATEDUESAVED=1) THEN 'C' ELSE 'C1' END
			     END
			ELSE CASE WHEN(OA.NEWCRITERIANO is not null OR T.DATEDUESAVED=1) THEN 'C' ELSE 'C1' END
		END,
	CREATEDBYCRITERIA=isnull(OA.NEWCRITERIANO,T.CREATEDBYCRITERIA),
	NEWEVENTDATE   =CASE TC.CLEAREVENTONDUECHANGE WHEN(1) THEN NULL
				ELSE T.NEWEVENTDATE
			END,
	NEWEVENTDUEDATE=CASE WHEN(TC.CLEARDUEONDUECHANGE=1) THEN NULL
			     WHEN(OA.NEWCRITERIANO is NULL AND isnull(T.DATEDUESAVED,0)=0) THEN NULL
				ELSE T.NEWEVENTDUEDATE
			END,
	DATEDUESAVED   =CASE TC.CLEARDUEONDUECHANGE WHEN(1) THEN NULL
				ELSE T.DATEDUESAVED
			END,
	OCCURREDFLAG   =CASE TC.CLEAREVENTONDUECHANGE WHEN(1) THEN 0
				ELSE T.OCCURREDFLAG
			END,
	-- Only increment loop count if the State is being changed
	LOOPCOUNT=LOOPCOUNT+
		CASE	WHEN(T.[STATE]='I') THEN CASE WHEN(isnull(TC.CLEAREVENTONDUECHANGE,0)=0 and T.NEWEVENTDATE is not null) THEN 0 ELSE 1 END
			WHEN(T.[STATE]='C') THEN 0 ELSE 1
		END,
	DISPLAYSEQUENCE=E.DISPLAYSEQUENCE,
	IMPORTANCELEVEL=E.IMPORTANCELEVEL,
	WHICHDUEDATE=E.WHICHDUEDATE,
	COMPAREBOOLEAN=E.COMPAREBOOLEAN,
	CHECKCOUNTRYFLAG=E.CHECKCOUNTRYFLAG,
	SAVEDUEDATE=E.SAVEDUEDATE,
	STATUSCODE=E.STATUSCODE,
	RENEWALSTATUS=E.RENEWALSTATUS,
	SPECIALFUNCTION=E.SPECIALFUNCTION,
	INITIALFEE=E.INITIALFEE,
	PAYFEECODE=E.PAYFEECODE,
	CREATEACTION=E.CREATEACTION,
	STATUSDESC=E.STATUSDESC,
	CLOSEACTION=E.CLOSEACTION,
	RELATIVECYCLE=E.RELATIVECYCLE,
	INSTRUCTIONTYPE=E.INSTRUCTIONTYPE,
	FLAGNUMBER=E.FLAGNUMBER,
	SETTHIRDPARTYON=E.SETTHIRDPARTYON,
	ESTIMATEFLAG=E.ESTIMATEFLAG,
	EXTENDPERIOD=E.EXTENDPERIOD,
	EXTENDPERIODTYPE=E.EXTENDPERIODTYPE,
	INITIALFEE2=E.INITIALFEE2,
	PAYFEECODE2=E.PAYFEECODE2,
	ESTIMATEFLAG2=E.ESTIMATEFLAG2,
	PTADELAY=E.PTADELAY,
	SETTHIRDPARTYOFF=E.SETTHIRDPARTYOFF,
	CHANGENAMETYPE=E.CHANGENAMETYPE,
	COPYFROMNAMETYPE=E.COPYFROMNAMETYPE,
	COPYTONAMETYPE=E.COPYTONAMETYPE,
	DELCOPYFROMNAME=E.DELCOPYFROMNAME,
	DIRECTPAYFLAG=E.DIRECTPAYFLAG,
	DIRECTPAYFLAG2=E.DIRECTPAYFLAG2,
	CREATEDBYACTION=isnull(OA.ACTION,T.CREATEDBYACTION),
	CRITERIANO=isnull(OA.NEWCRITERIANO,T.CRITERIANO),
	-- ACTION=isnull(OA.ACTION,T.ACTION),		-- Commented out because this is changing the Action and results in the same row being reinserted into #TEMPCASEEVENT
	LIVEFLAG=OA.POLICEEVENTS
	from #TEMPCASEEVENT T
	join
	(select distinct T1.CASEID, T1.EVENTNO, T1.CYCLE, RE.CLEAREVENTONDUECHANGE, RE.CLEARDUEONDUECHANGE
	from #TEMPCASEEVENT T
	join RELATEDEVENTS RE	on ( RE.CRITERIANO=T.CRITERIANO
	and  RE.EVENTNO=T.EVENTNO
	and (RE.CLEAREVENTONDUECHANGE = 1 OR RE.CLEARDUEONDUECHANGE =1))
	join #TEMPCASEEVENT T1	on ( T1.CASEID =T.CASEID
				and  T1.EVENTNO=RE.RELATEDEVENT
				and((T1.CYCLE  < T.CYCLE and RE.RELATIVECYCLE=6)
	 OR (T1.CYCLE  > T.CYCLE and RE.RELATIVECYCLE=7)
	 OR  T1.CYCLE  =CASE RE.RELATIVECYCLE
			WHEN (0) THEN T.CYCLE
			WHEN (1) THEN T.CYCLE-1
			WHEN (2) THEN T.CYCLE+1
			WHEN (3) THEN 1
			WHEN (4) THEN (	select max(CYCLE)
					from #TEMPCASEEVENT T2
					where T2.CASEID =T1.CASEID
					and   T2.EVENTNO=T1.EVENTNO)
			WHEN (5) THEN T1.CYCLE
		END))
	Where T.[STATE] in ('R','D')
	and isnull(T.OLDEVENTDUEDATE,'')<>isnull(T.NEWEVENTDUEDATE,'')) TC
		on (TC.CASEID = T.CASEID
		and TC.EVENTNO= T.EVENTNO
		and TC.CYCLE  = T.CYCLE)
	left join
	(select distinct A.CASEID,A.ACTION,A.CYCLE,A.NEWCRITERIANO,A.CRITERIANO,A.POLICEEVENTS,DD.EVENTNO,AC.NUMCYCLESALLOWED
	from #TEMPOPENACTION A
	join DUEDATECALC DD	on (DD.CRITERIANO=A.NEWCRITERIANO)
	join ACTIONS AC	on (AC.ACTION=A.ACTION)
	where A.POLICEEVENTS=1) OA
		on (OA.CASEID=T.CASEID
		and OA.EVENTNO=T.EVENTNO
		and(OA.CYCLE=T.CYCLE OR OA.NUMCYCLESALLOWED=1))
	left join EVENTCONTROL E
		on (E.CRITERIANO=OA.NEWCRITERIANO
		and E.EVENTNO=T.EVENTNO)
	where T.[STATE] not in ('D','D1')
	and((T.NEWEVENTDATE is not null and TC.CLEAREVENTONDUECHANGE=1)
	 or (T.NEWEVENTDATE is null and TC.CLEARDUEONDUECHANGE=1))"

	Exec @ErrorCode = sp_executesql @sSQLString,
						N'@pnCountStateC	int	OUTPUT,
						  @pnCountStateI	int	OUTPUT,
						  @pnCountStateR	int	OUTPUT',
						  @pnCountStateC		OUTPUT,
						  @pnCountStateI		OUTPUT,
						  @pnCountStateR		OUTPUT
End


If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceClearEvents',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*, @pnCountStateC as 'CountStateC', @pnCountStateI as 'CountStateI', @pnCountStateR as 'CountStateR', @pnCountStateD as 'CountStateD' 
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

return @ErrorCode
go

grant execute on dbo.ip_PoliceClearEvents  to public
go