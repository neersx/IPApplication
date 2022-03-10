-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetEventsToUpdate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetEventsToUpdate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetEventsToUpdate.'
	drop procedure dbo.ip_PoliceGetEventsToUpdate
end
print '**** Creating procedure dbo.ip_PoliceGetEventsToUpdate...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetEventsToUpdate 
			 @pnDebugFlag	tinyint
as
-- PROCEDURE :	ip_PoliceGetEventsToUpdate
-- VERSION :	36
-- DESCRIPTION:	A procedure to get the Case Event rows that are to be updated from another Event
--              as a result of recalculating an Action
-- CALLED BY :	ipu_Policing

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 13/07/2000	MF			Procedure created	 
-- 19/09/2001	MF	7063		When getting details of Case Event rows to update from a related case
--					the program must take into consideration that more than one relationship
--					may exist against the case.  When this happens use the Relationship with
--					the lowest relationship number.
-- 14/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 06/11/2002	MF	8162		A SQL Error is being returned where an Event is being updated from another 
--					Event and the from Event has also been Policed and is reference by more than 
--					one Criteria.  This is because a subselect was returning multiple rows.
-- 24 Jul 2003	MF	8260	10	Get PTADELAY from EventControl table for Patent Term Adjustment calculation
-- 12 Nov 2003	MF	9450	11	Set the CRITERIANO on the #TEMPCASEEVENT table when inserting rows.
-- 26 Feb 2004	MF	RFC709	12	Get IDENTITYID to identify workbench user
-- 03 Nov 2004	MF	10385	13	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 27 Jan 2005	MF	10928	14	A specific Cycle may now be defined within the RelateCase row to indicate
--					what Cycle of a CaseEvent is to be updated from the related case.
-- 18 Jan 2006	MF	11971	15	If the CaseEvent row is being recalculated after having its EventDate cleared
--					out then do not reset the EventDate from itself if no related Case is found.
-- 15 May 2006	MF	12315	16	New EventControl columns to update CASENAME when Event occurs.
-- 23 May 2006	MF	12315	17	Revisit. SQL variable exceeded 4000 characters
-- 07 Jun 2006	MF	12417	18	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	19	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 05 Sep 2006	MF	13378	20	If a cyclic Event is to be updated from a Related Case and that Event is
--					also cyclic then the calculation should default to using the same Cycle as
--					the Event trying to be calculated.  If the Related Case event is not cyclic
--					then Cycle 1 may be used.
-- 24 May 2007	MF	14812	21	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	22	Reserve word [STATE]
-- 16 Apr 2008	MF	16249	24	Revisit 14812 to better handle Events under multiple Actions.
-- 23 Jun 2009	MF	17808	25	Use cycle of Related Case event when getting Event from Related Case.
-- 27 Jul 2009	MF	17922	26	Ensure rows inserted into #TEMPCASEEVENT have the ACTION column initialised to the same as CREATEDBYACTION.
-- 15 Oct 2009	MF	17773	27	An Event that may gets its date from a related Case is also now able to get an official number from the
--					same Case.
-- 20 Sep 2011	MF	R11320	28	Coding error where T.ACTION=T.ACTION should have been A.ACTION=T.ACTION.
-- 06 Jun 2012	MF	S19025	29	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 18 Dec 2012	MF	R11320	30	Coding error where T.ACTION=T.ACTION should have been A.ACTION=T.ACTION.
-- 25 Feb 2013	MF	R13259	31	When inserting a #TEMPCASEEVENT row the CREATEDBYACTION and CREATEDBYCRITERIA is not always being initialised.
-- 25 Mar 2013	MF	S21299	32	Extend the ADJUSTMENT capability to allow user defined adjustment amounts by specified period type.
-- 06 Jun 2013	MF	S21404	33	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 30 Aug 2016	MF	66054	34	When getting a date from a related case using the FROMRELATIONSHIP, it is possible for more than one related
--					case to exist.  Currently the system take the related case with the lowest relationship no. This will be changed
--					to take the related case with earliest date.
-- 15 Mar 2017	MF	70049	158	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV  75198/DR-45358	159   Date conversion errors when creating cases and opening names in Chinese DB


set nocount on

DECLARE		@ErrorCode	int,
		@nRowCount	int,
		@sSQLString	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0
Set @nRowCount = 0

-- The #TEMPCASEEVENT table is to be loaded with Events that can be loaded directly from another Event

-- If a row already exists in TEMPCASEEVENT with a STATE other than 'I' then the row is to be updated to indicate
-- that the CaseEvent is to be updated from another Event.
-- STATE = 'I' (insert)



If @ErrorCode=0
Begin
	set @sSQLString="
	update	TC1			
	set	[STATE]	= 'I',
	-- Update the event with the Event from TEMPCASEEVENT if it has occurred.		
	NEWEVENTDATE	= isnull(TC.NEWEVENTDATE,CE.EVENTDATE), 
	LOOPCOUNT	= LOOPCOUNT + 1,
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
	CREATEDBYCRITERIA=isnull(TC1.CREATEDBYCRITERIA,T.NEWCRITERIANO),
	CREATEDBYACTION  =isnull(TC1.CREATEDBYACTION,T.ACTION),
	CRITERIANO       =T.NEWCRITERIANO,
	ACTION           =T.ACTION,
	LIVEFLAG         =1,
	LOADNUMBERTYPE   =E.LOADNUMBERTYPE,
	PARENTNUMBER     =O.OFFICIALNUMBER,
	RECALCEVENTDATE  =E.RECALCEVENTDATE
	from		#TEMPCASEEVENT TC1
	join 		#TEMPOPENACTION T
					on (T.CASEID=TC1.CASEID)
	join		CASES C 	on (C.CASEID=TC1.CASEID)
	join		EVENTCONTROL E	on (E.CRITERIANO=T.NEWCRITERIANO 
					and E.EVENTNO=TC1.EVENTNO)
	left join 	EVENTS EV	on (EV.EVENTNO=UPDATEFROMEVENT)
	left join	RELATEDCASE  R	on (R.CASEID=T.CASEID 
					and R.RELATIONSHIP=E.FROMRELATIONSHIP
					and R.RELATEDCASEID is not null
					and R.RELATIONSHIPNO=(	select	convert(int,
									substring(
									min(
									    convert(nvarchar(8), coalesce(TC.NEWEVENTDATE,CE.EVENTDATE), 112) -- Choose the EARLIEST date
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
								and   R1.RELATEDCASEID is not null
								and   coalesce(TC.NEWEVENTDATE, CE.EVENTDATE) is not null)
								)
	left join	OFFICIALNUMBERS O
					on (O.NUMBERTYPE=E.LOADNUMBERTYPE
					and O.ISCURRENT=1
					and O.CASEID= 	CASE WHEN (E.FROMANCESTOR=1) 		   THEN C.PREDECESSORID
							     WHEN (E.FROMRELATIONSHIP is not null) THEN R.RELATEDCASEID
							END)
	left join	CASEEVENT CE	on (CE.EVENTNO=E.UPDATEFROMEVENT
					and CE.CYCLE  =CASE WHEN(EV.NUMCYCLESALLOWED>1) THEN TC1.CYCLE ELSE 1 END
					and CE.CASEID =CASE WHEN (E.FROMANCESTOR=1) 		THEN C.PREDECESSORID
							     WHEN (R.RELATEDCASEID is not null)	THEN R.RELATEDCASEID
							END)
	left join      (select min(NEWEVENTDATE) as NEWEVENTDATE, CASEID, EVENTNO, CYCLE 
			from #TEMPCASEEVENT
			where NEWEVENTDATE is not null
			group by CASEID, EVENTNO, CYCLE
			having min(NEWEVENTDATE) is not null) TC
					on (TC.EVENTNO=E.UPDATEFROMEVENT
					and TC.CYCLE =CASE WHEN(EV.NUMCYCLESALLOWED>1)       THEN TC1.CYCLE ELSE 1 END
					and TC.CASEID=CASE WHEN(E.FROMANCESTOR=1) 	     THEN C.PREDECESSORID
							   WHEN(R.RELATEDCASEID is not null) THEN R.RELATEDCASEID
						       END)
	left join	#TEMPCASEINSTRUCTIONS CI
					on (CI.CASEID=T.CASEID and CI.INSTRUCTIONTYPE=E.INSTRUCTIONTYPE)
	left join	INSTRUCTIONFLAG F
					on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE and F.FLAGNUMBER=E.FLAGNUMBER)

	-- Only process rows that are not already marked as having occurred.			
	Where	T.[STATE] = 'C'
	and	TC1.[STATE] not like 'I%'
	and	TC1.NEWEVENTDATE is null
	and	E.UPDATEFROMEVENT is not null
	and    (TC.NEWEVENTDATE is not NULL OR CE.EVENTDATE is not NULL)
	-- if the EventControl is flagged to use the ReceivingCycle then the Cycle of CaseEvent
	-- must match the Cycle on the RelatedCase row.
	and   ((E.RECEIVINGCYCLEFLAG=1 and TC1.CYCLE=R.CYCLE) OR isnull(E.RECEIVINGCYCLEFLAG,0)=0)

	-- if there is a FLAGNUMBER then it must match the Flagnumber of the standing instruction against the Case.            
	and	(E.FLAGNUMBER IS NULL OR E.FLAGNUMBER=F.FLAGNUMBER)"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@@Rowcount
End

If @ErrorCode=0
Begin
	set @sSQLString="
	insert into #TEMPCASEEVENT
	(	CASEID,DISPLAYSEQUENCE,EVENTNO,CYCLE,LOOPCOUNT,OLDEVENTDATE,OLDEVENTDUEDATE,DATEDUESAVED,
		OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,CRITERIANO,ENTEREDDEADLINE,PERIODTYPE,DOCUMENTNO,
		DOCSREQUIRED,DOCSRECEIVED,USEMESSAGE2FLAG,GOVERNINGEVENTNO,[STATE],ADJUSTMENT,
		STATUSCODE,RENEWALSTATUS,SPECIALFUNCTION,INITIALFEE,PAYFEECODE,CREATEACTION,
		STATUSDESC,CLOSEACTION,RELATIVECYCLE,USERID,
		INSTRUCTIONTYPE,FLAGNUMBER,SETTHIRDPARTYON,NEWEVENTDATE,NEWEVENTDUEDATE,ESTIMATEFLAG,
		EXTENDPERIOD,EXTENDPERIODTYPE,INITIALFEE2,PAYFEECODE2,ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
		CHANGENAMETYPE,COPYFROMNAMETYPE,COPYTONAMETYPE,DELCOPYFROMNAME,DIRECTPAYFLAG,DIRECTPAYFLAG2,ACTION,
		LOADNUMBERTYPE,PARENTNUMBER,RECALCEVENTDATE,SUPPRESSCALCULATION)
	-- Find the Events that are to be updated from another Event either of the Current Case, Parent Case or Related Case
	-- STATE = 'I' (insert)
	select	Distinct T.CASEID,E.DISPLAYSEQUENCE,E.EVENTNO,
		isnull(TC.CYCLE,CE.CYCLE),0,CE1.EVENTDATE,CE1.EVENTDUEDATE,CE1.DATEDUESAVED,1,
		isnull(CE1.CREATEDBYACTION,T.ACTION),isnull(CE1.CREATEDBYCRITERIA,T.NEWCRITERIANO),isnull(CE1.CREATEDBYCRITERIA,T.NEWCRITERIANO),CE1.ENTEREDDEADLINE,CE1.PERIODTYPE,CE1.DOCUMENTNO,
		CE1.DOCSREQUIRED,CE1.DOCSRECEIVED,CE1.USEMESSAGE2FLAG,CE1.GOVERNINGEVENTNO,'I',E.ADJUSTMENT,
		E.STATUSCODE,E.RENEWALSTATUS,E.SPECIALFUNCTION,E.INITIALFEE,E.PAYFEECODE,E.CREATEACTION,E.STATUSDESC,
		E.CLOSEACTION,E.RELATIVECYCLE,T.USERID,E.INSTRUCTIONTYPE,E.FLAGNUMBER,E.SETTHIRDPARTYON,
	        isnull(TC.NEWEVENTDATE,CE.EVENTDATE),	CE1.EVENTDUEDATE,E.ESTIMATEFLAG,
		E.EXTENDPERIOD,E.EXTENDPERIODTYPE,E.INITIALFEE2,E.PAYFEECODE2,E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE,E.COPYFROMNAMETYPE,E.COPYTONAMETYPE,E.DELCOPYFROMNAME,E.DIRECTPAYFLAG,E.DIRECTPAYFLAG2,isnull(CE1.CREATEDBYACTION,T.ACTION),
		E.LOADNUMBERTYPE,O.OFFICIALNUMBER,E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
	from 		#TEMPOPENACTION T
	join		ACTIONS A	on (A.ACTION=T.ACTION)	-- RFC11320 
	join		CASES C 	on (C.CASEID=T.CASEID)
	join		EVENTCONTROL E	on (E.CRITERIANO=T.NEWCRITERIANO)
	left join	EVENTS EV	on (EV.EVENTNO=E.UPDATEFROMEVENT)
	left join	RELATEDCASE  R	on (R.CASEID=T.CASEID 
					and R.RELATIONSHIP=E.FROMRELATIONSHIP
					and R.RELATIONSHIPNO=(	select	convert(int,
									substring(
									min(
									    convert(nvarchar(8), coalesce(TC.NEWEVENTDATE,CE.EVENTDATE), 112) -- Choose the EARLIEST date
									  + convert(nvarchar(11), R1.RELATIONSHIPNO)
									    ), 9,11))
								from RELATEDCASE R1
								left join CASEEVENT CE	on (CE.CASEID =R1.RELATEDCASEID
											and CE.EVENTNO=E.UPDATEFROMEVENT)
								left join #TEMPCASEEVENT TC	
											on (TC.CASEID =R1.RELATEDCASEID
											and TC.EVENTNO=E.UPDATEFROMEVENT)
								where R1.CASEID=R.CASEID
								and   R1.RELATIONSHIP=R.RELATIONSHIP
								and   R1.RELATEDCASEID is not null
								and   coalesce(TC.NEWEVENTDATE, CE.EVENTDATE) is not null)
								)
	left join	OFFICIALNUMBERS O
					on (O.NUMBERTYPE=E.LOADNUMBERTYPE
					and O.ISCURRENT=1
					and O.CASEID= 	CASE WHEN (E.FROMANCESTOR=1) 		   THEN C.PREDECESSORID
							     WHEN (E.FROMRELATIONSHIP is not null) THEN R.RELATEDCASEID
							END)
	left join	CASEEVENT CE	on (CE.EVENTNO=E.UPDATEFROMEVENT
					and CE.CYCLE =CASE WHEN(A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE CASE WHEN(EV.NUMCYCLESALLOWED>1 AND E.NUMCYCLESALLOWED>1) THEN CE.CYCLE ELSE 1 END END --SQA17808
					and CE.CASEID=CASE WHEN (E.FROMANCESTOR=1) 		   THEN C.PREDECESSORID
							   WHEN (E.FROMRELATIONSHIP is not null) THEN R.RELATEDCASEID
											--	   ELSE T.CASEID   --SQA11971
						       END)
	left join	#TEMPCASEEVENT TC
					on (TC.EVENTNO=E.UPDATEFROMEVENT 
					and TC.NEWEVENTDATE is not null
					and TC.CYCLE =CASE WHEN(A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE CASE WHEN(EV.NUMCYCLESALLOWED>1 AND E.NUMCYCLESALLOWED>1) THEN TC.CYCLE ELSE 1 END END --SQA17808
					and TC.CASEID=CASE WHEN (E.FROMANCESTOR=1) 		   THEN C.PREDECESSORID
							   WHEN (E.FROMRELATIONSHIP is not null) THEN R.RELATEDCASEID
											--	   ELSE T.CASEID  --SQA11971
						      END)
	left join	CASEEVENT CE1	on (CE1.CASEID=T.CASEID 
					and CE1.EVENTNO=E.EVENTNO
					and CE1.CYCLE=isnull(TC.CYCLE,CE.CYCLE))
	left join	#TEMPCASEEVENT TC1
					on (TC1.CASEID=T.CASEID 
					and TC1.EVENTNO=E.EVENTNO 
					and TC1.CYCLE=isnull(TC.CYCLE,CE.CYCLE))
	left join	#TEMPCASEINSTRUCTIONS CI
					on (CI.CASEID=T.CASEID 
					and CI.INSTRUCTIONTYPE=E.INSTRUCTIONTYPE)
	left join	INSTRUCTIONFLAG F
					on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE 
					and F.FLAGNUMBER=E.FLAGNUMBER)
	Where	T.[STATE]='C'
	-- CASEEVENT may not already exists
	and    (CE1.CASEID is null OR CE1.EVENTDATE is null)
	and	TC1.CASEID is null
	-- use the TEMPCASEEVENT in preference to CASEEVENT
	and    (TC.NEWEVENTDATE is not null OR CE.EVENTDATE is not null)
	-- if the EventControl is flagged to use the ReceivingCycle then the Cycle of CaseEvent
	-- must match the Cycle on the RelatedCase row.
	and   ((E.RECEIVINGCYCLEFLAG=1 and T.CYCLE=R.CYCLE) OR isnull(E.RECEIVINGCYCLEFLAG,0)=0)
	-- FLAGNUMBER must match  Flagnumber of the standing instruction against the Case.
	and    (E.FLAGNUMBER IS NULL OR E.FLAGNUMBER=F.FLAGNUMBER)
	OPTION (MAXDOP 1)"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount+@@Rowcount
End

-- Update any of the Case Event rows that need adjusting. 

If  @ErrorCode=0
and @nRowCount>0
Begin
	set @sSQLString="
	update	#TEMPCASEEVENT
	set ADJUSTMENT= null, 
	    NEWEVENTDATE = CASE	
				WHEN(A.PERIODTYPE='D') Then dateadd( day,   A.ADJUSTAMOUNT, NEWEVENTDATE )
				WHEN(A.PERIODTYPE='W') Then dateadd( week,  A.ADJUSTAMOUNT, NEWEVENTDATE )
				WHEN(A.PERIODTYPE='M') Then dateadd( month, A.ADJUSTAMOUNT, NEWEVENTDATE )
				WHEN(A.PERIODTYPE='Y') Then dateadd( year,  A.ADJUSTAMOUNT, NEWEVENTDATE )
				WHEN(A.ADJUSTMENT='E') Then dateadd( day, -1, cast(cast(MONTH (dateadd (month, 1, NEWEVENTDATE)) as nvarchar)+'/1/'+ cast(YEAR (dateadd (month, 1, NEWEVENTDATE))as nvarchar) as datetime))
					  Else	cast(cast( isnull (A.ADJUSTMONTH, MONTH (NEWEVENTDATE)) as nvarchar)+'/'+cast( isnull (A.ADJUSTDAY, DAY (NEWEVENTDATE)) as nvarchar)+'/'+ cast( isnull (A.ADJUSTYEAR, YEAR (NEWEVENTDATE)) as nvarchar) as datetime)
			   END
	from 	#TEMPCASEEVENT T
	join	ADJUSTMENT A on A.ADJUSTMENT=T.ADJUSTMENT
	where 	T.NEWEVENTDATE is not null
	and	T.[STATE]='I'"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetEventsToUpdate',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	begin
		set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetEventsToUpdate  to public
go