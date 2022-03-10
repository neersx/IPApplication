-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceUpdateEvents
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceUpdateEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceUpdateEvents.'
	drop procedure dbo.ip_PoliceUpdateEvents
end
print '**** Creating procedure dbo.ip_PoliceUpdateEvents...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceUpdateEvents
				@pnCountStateC		int	OUTPUT,
				@pnCountStateI		int	OUTPUT,
				@pnCountStateR		int	OUTPUT,
				@pnCountStateD		int	OUTPUT,
				@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PoliceUpdateEvents
-- VERSION :	34
-- DESCRIPTION:	A procedure that identifies CASEEVENT rows to be updated as having occurred
--              as a result of another Event being updated.
-- CALLED BY :	ipu_Policing

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13/09/2000	MF			Procedure created
-- 17/10/2001	MF	7122		Use NEWCRITERIANO to get the EVENTCONTROL row for the event to be updated. 
-- 18/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 07/05/2002	MF	7615		ESTIMATEFLAG to be included in the GROUP BY clause.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 19/09/2002	MF	8009		Only trigger the updating of another Event if the Event being updated
--					does not already have the same Event Date.  This will avoid the possibility 
--					of an endless loop occurring where two Events are set up to update each other.
-- 06/03/2003	MF	8505		Need to allow for an Event to be updated from another Event even though the 
--					Event being updated does not currently belong to an Open Action.
-- 24 Jul 2003	MF	8260	10	Get PTADELAY from EventControl table for Patent Term Adjustment calculation.
-- 23 Oct 2003	MF	9375	11	Use CRITERIANO instead of CREATEDBYCRITERIA from the #TEMPCASEEVENT table
-- 12 Nov 2003	MF	9450	12	Set the CRITERIANO on the #TEMPCASEEVENT table when inserting rows.
-- 26 Feb 2004	MF	RFC709	13	Get IDENTITYID to identify workbench users
-- 24 Jun 2004	MF	9880	14	Increase the size of the ADJUSTMENT column in temporary table to nvarchar(4)
-- 06 Aug 2004	AB	8035	15	Add collate database_default to temp table definitions
-- 03 Nov 2004	MF	10385	16	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 19 Jan 2005	MF	10906	17	If multiple Events are updating the one Event then take the highest date.
-- 24 Jan 2005	MF	10915	18	Remove some row count restrictions to ensure all possible updates occur.
-- 15 May 2006	MF	12315	19	New EventControl collumns to update CASENAME when Event occurs.
-- 07 Jun 2006	MF	12417	20	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	21	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 29 May 2007	MF	14812	22	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	23	Reserve word [STATE]
-- 07 Jan 2008	MF	15586	24	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 16 Apr 2008	MF	16249	25	Revisit 14812 to better handle Events under multiple Actions.
-- 26 Aug 2008	MF	16868	26	Policing crashing when Update related event with Highest cycle is used and Case Event does not exist.
-- 27 Jul 2009	MF	17922	27	Ensure rows inserted into #TEMPCASEEVENT have the ACTION column initialised to the same as CREATEDBYACTION.
-- 06 Jun 2012	MF	S19025	28	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 25 Mar 2013	MF	S21299	29	Extend the ADJUSTMENT capability to allow user defined adjustment amounts by specified period type.
-- 06 Jun 2013	MF	S21404	30	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 15 Mar 2017	MF	70049	31	Allow Renewal Status to be separately specified to be updated by an Event.
-- 24 Jul 2017	MF	72034	32	If an Event is defined under multiple Actions, then the Action in which the Event is allowed to calculate (SUPPRESSCALCULATION=0)
--					is to take precedence over Action(s) where the calculation is suppressed (SUPPRESSCALCULATION=1).
-- 14 Nov 2018  AV	DR-45358 33	Date conversion errors when creating cases and opening names in Chinese DB
-- 29 Nov 2019	MF	DR-54681 34	Problems caused when an Event exists against multiple Actions. Each TEMPCASEEVENT records the ACTION the Event exists under.  This ACTION was being 
--					changed at times and as a result caused another TEMPCASEEVENT row to be inserted for that same ACTION resulting in exponential growth of TEMPCASEEVENT.
--					The ACTION should not have been changed.


set nocount on

-- An interim step is required to find the Events that are to be updated so that the 
-- TEMPCASEEVENT table can be updated.  Load these events into a new temporary table as
-- an update cannot be done directly because of an ambiguous error.

CREATE TABLE #TEMPUPDATECASEEVENT (
        CASEID		int		NOT NULL,
        EVENTNO		int		NOT NULL,
        CYCLE		smallint	NOT NULL,
        NEWEVENTDATE	datetime	NOT NULL,
	ADJUSTMENT	nvarchar(4)	collate database_default NULL,
	COUNTRYCODE	nvarchar(3)	collate database_default NULL,
	USERID		nvarchar(255)	collate database_default NULL,
	IDENTITYID	int		NULL
	)

DECLARE		@ErrorCode	int,
		@nRowCount	int,
		@sSQLString	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

If  @ErrorCode=0
and @pnCountStateI>0
Begin
	Set @sSQLString="
	insert into #TEMPUPDATECASEEVENT(CASEID, EVENTNO, CYCLE, NEWEVENTDATE, ADJUSTMENT, COUNTRYCODE, USERID, IDENTITYID)
	select	distinct 
		T.CASEID, 
		RE.RELATEDEVENT, 
		CASE RE.RELATIVECYCLE	WHEN (0) THEN T.CYCLE
					WHEN (1) THEN T.CYCLE-1
					WHEN (2) THEN T.CYCLE+1
					WHEN (3) THEN 1
					WHEN (4) THEN isnull(
							(select max(CYCLE)
							from #TEMPCASEEVENT T1
							where T1.CASEID =T1.CASEID
							and   T1.EVENTNO=RE.RELATEDEVENT),1)
		END, 
		T.NEWEVENTDATE, 
		RE.ADJUSTMENT,
		T.COUNTRYCODE,
		T.USERID,
		T.IDENTITYID
	from	#TEMPCASEEVENT	T
	join	RELATEDEVENTS	RE on ( RE.CRITERIANO =T.CRITERIANO
				   and  RE.EVENTNO    =T.EVENTNO
				   and  RE.UPDATEEVENT=1)
	where	T.[STATE]='I'
	and	T.NEWEVENTDATE   is not null
	and	RE.RELATEDEVENT  is not null
	and	RE.RELATIVECYCLE between 0 and 4"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@@Rowcount
End

-- Update any of the Case Event rows that need adjusting. 

If @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	update	#TEMPUPDATECASEEVENT
	set NEWEVENTDATE = CASE	
				WHEN(A.PERIODTYPE='D') Then dateadd( day,   A.ADJUSTAMOUNT, NEWEVENTDATE )
				WHEN(A.PERIODTYPE='W') Then dateadd( week,  A.ADJUSTAMOUNT, NEWEVENTDATE )
				WHEN(A.PERIODTYPE='M') Then dateadd( month, A.ADJUSTAMOUNT, NEWEVENTDATE )
				WHEN(A.PERIODTYPE='Y') Then dateadd( year,  A.ADJUSTAMOUNT, NEWEVENTDATE )
				WHEN(A.ADJUSTMENT='E') Then dateadd( day, -1, cast(cast(MONTH (dateadd (month, 1, NEWEVENTDATE)) as nvarchar)+'/1/'+ cast(YEAR (dateadd (month, 1, NEWEVENTDATE))as nvarchar) as datetime))
						       Else cast(cast( isnull (A.ADJUSTMONTH, MONTH (NEWEVENTDATE)) as nvarchar)+'/'+cast( isnull (A.ADJUSTDAY, DAY (NEWEVENTDATE)) as nvarchar)+'/'+ cast( isnull (A.ADJUSTYEAR, YEAR (NEWEVENTDATE)) as nvarchar) as datetime)
			   END
	from 	#TEMPUPDATECASEEVENT T
	join	ADJUSTMENT A on A.ADJUSTMENT=T.ADJUSTMENT
	where 	T.NEWEVENTDATE is not null"

	Exec @ErrorCode=sp_executesql @sSQLString
End


-- Now update the TEMPCASEEVENT table to set the STATE, and NEWEVENTDATE.
-- Note that the STATE will be set to 'IX' so as to not confuse it with the original "I" rows which will be
-- updated to "I1" to indicate they have been processed.

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	update	#TEMPCASEEVENT
	set 	@pnCountStateC=@pnCountStateC-CASE WHEN(T.[STATE] like 'C%') THEN 1 ELSE 0 END,
		@pnCountStateI=@pnCountStateI-CASE WHEN(T.[STATE] =    'I' ) THEN 1 ELSE 0 END,
		@pnCountStateR=@pnCountStateR-CASE WHEN(T.[STATE] =    'R' ) THEN 1 ELSE 0 END,
		@pnCountStateD=@pnCountStateD-CASE WHEN(T.[STATE] =    'D' ) THEN 1 ELSE 0 END,
		[STATE]	        ='IX',
		NEWEVENTDATE    =TU.NEWEVENTDATE,
		OCCURREDFLAG    =1,
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
		RESPNAMENO      =isnull(T.RESPNAMENO,E.DUEDATERESPNAMENO),
		RESPNAMETYPE    =isnull(T.RESPNAMETYPE,E.DUEDATERESPNAMETYPE),
		CREATEDBYCRITERIA=isnull(T.CREATEDBYCRITERIA,CR.CRITERIANO),
		CREATEDBYACTION  =isnull(T.CREATEDBYACTION,CR.ACTION),
	--	CRITERIANO       =CR.CRITERIANO,
	--	ACTION           =CR.ACTION,
		RECALCEVENTDATE    =CASE WHEN(T.RECALCEVENTDATE    =1)	THEN 1 ELSE isnull(E.RECALCEVENTDATE,    0) END,
		SUPPRESSCALCULATION=CASE WHEN(T.SUPPRESSCALCULATION=1 OR DD.CRITERIANO is not null) 
									THEN 1 ELSE isnull(E.SUPPRESSCALCULATION,0) END,
		LIVEFLAG         =1
	from 	#TEMPCASEEVENT T
	join	(select CASEID, EVENTNO, CYCLE, max(NEWEVENTDATE) as NEWEVENTDATE
		 from #TEMPUPDATECASEEVENT
		 group by CASEID, EVENTNO, CYCLE) TU 
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
	where T.[STATE] <> 'IX'
	and (T.NEWEVENTDATE<>TU.NEWEVENTDATE OR T.NEWEVENTDATE is null)"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCountStateC	int	OUTPUT,
					  @pnCountStateI	int	OUTPUT,
					  @pnCountStateR	int	OUTPUT,
					  @pnCountStateD	int	OUTPUT',
					  @pnCountStateC		OUTPUT,
					  @pnCountStateI		OUTPUT,
					  @pnCountStateR		OUTPUT,
					  @pnCountStateD		OUTPUT
End

--==============================
-- Load the #TEMPCASEEVENT table with Events that are to be updated if they do not already exist on the
-- #TEMPCASEEVENT table

-- STATE = 'IX' (inserted)

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	insert into #TEMPCASEEVENT 
			(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, 
				OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA,CRITERIANO,
				[STATE],
				IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
				SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
				INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, USERID,
				NEWEVENTDATE,ESTIMATEFLAG, EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
				CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,RESPNAMENO,RESPNAMETYPE,ACTION,RECALCEVENTDATE,
				SUPPRESSCALCULATION)
	SELECT	T.CASEID,  E.DISPLAYSEQUENCE, T.EVENTNO, T.CYCLE, 0,
		1, CR.ACTION, E.CRITERIANO, E.CRITERIANO,
		'IX',
		E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, E.STATUSCODE, E.RENEWALSTATUS,
		E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, E.CLOSEACTION, E.RELATIVECYCLE,
		E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, T.COUNTRYCODE, T.USERID,
		max(T.NEWEVENTDATE), E.ESTIMATEFLAG, E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,
		E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE, CR.ACTION, E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
	from	#TEMPUPDATECASEEVENT T
	left join #TEMPCASEEVENT TC on (TC.CASEID =T.CASEID
				   and  TC.EVENTNO=T.EVENTNO
				   and  TC.CYCLE  =T.CYCLE)
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
	where TC.CASEID is null
	group by T.CASEID,  E.DISPLAYSEQUENCE, T.EVENTNO, T.CYCLE,
		CR.ACTION, E.CRITERIANO, E.CRITERIANO,
		E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, E.STATUSCODE, E.RENEWALSTATUS,
		E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, E.CLOSEACTION, E.RELATIVECYCLE,
		E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, T.COUNTRYCODE, T.USERID,
		E.ESTIMATEFLAG, E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,
		E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE, CR.ACTION, E.RECALCEVENTDATE, E.SUPPRESSCALCULATION"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @pnDebugFlag>0
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceUpdateEvents',0,1,@sTimeStamp ) with NOWAIT

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

drop table #TEMPUPDATECASEEVENT

return @ErrorCode
go

grant execute on dbo.ip_PoliceUpdateEvents  to public
go