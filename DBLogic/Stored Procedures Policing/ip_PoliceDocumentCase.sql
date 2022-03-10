-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceDocumentCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceDocumentCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceDocumentCase.'
	drop procedure dbo.ip_PoliceDocumentCase
end
print '**** Creating procedure dbo.ip_PoliceDocumentCase...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceDocumentCase
			@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PoliceDocumentCase
-- VERSION :	7
-- DESCRIPTION:	When an Event on a document case occurs it may trigger
--		the occurrence of Events on other Cases.

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 29 May 2007	MF	15518	1	Procedure created
-- 25 Mar 2008	MF	16141	2	The triggering Case Event will now be treated as a separate
--					Policing "Type of Request". This is so that the query that finds
--					the Cases that are monitoring the occurrence of the Case Event does
--					not cause a bottleneck.  By splitting it into its own Policing request,
--					the Policing server will process the request without having a user wait.
-- 27 Jul 2009	MF	17922	3	Ensure rows inserted into #TEMPCASEEVENT have the ACTION column initialised to the same as CREATEDBYACTION.
-- 05 Jun 2012	MF	S19025	4	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 06 Jun 2013	MF	S21404	5	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 15 Mar 2017	MF	70049	6	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV  75198/DR-45358	7   Date conversion errors when creating cases and opening names in Chinese DB
--		

set nocount on

-- Create a temporary to hold Case Events details
-- that are candidates to automatically update.
-- This is the first stage in deterimining candidates
-- to improve database performance.
CREATE TABLE #TEMPSTEP1 (
	CASEID			int		NOT NULL,
	EVENTNO			int		NOT NULL,
	CYCLE			smallint	NOT NULL,
	SEQUENCENO		int		identity(0,1),
	DOCUMENTCASEID		int		NOT NULL,
	CRITERIANO		int		NOT NULL,
	IDENTITYID		int		NULL,
	USERID			nvarchar(255)	collate database_default NULL,
	BESTFIT			char(7) 	collate database_default NOT NULL,
	TRIGGERCASEID		int		NOT NULL
	)

-- Create a temporary to hold Case Events details
-- that are candidates to automatically update
CREATE TABLE #TEMPCANDIDATECASES (
	CASEID			int		NOT NULL,
	EVENTNO			int		NOT NULL,
	CYCLE			smallint	NOT NULL,
	SEQUENCENO		int		identity(0,1),
	DOCUMENTCASEID		int		NOT NULL,
	CRITERIANO		int		NOT NULL,
	IDENTITYID		int		NULL,
	USERID			nvarchar(255)	collate database_default NULL,
	BESTFIT			char(7) 	collate database_default NOT NULL
	)

CREATE CLUSTERED INDEX XPKTEMPCANDIDATECASES ON #TEMPCANDIDATECASES
	(
	CASEID,
	EVENTNO,
	CYCLE,
	SEQUENCENO
	)

Declare	@ErrorCode	int,
	@nRowCount	int,
	@sSQLString	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0


--	Note :	Locking level previously lowered
--		set transaction isolation level read uncommitted


-- Note that the next two SELECT statements were originally a single complex statement 
-- however for performance reasons it was better to split these apart even though it did
-- require a second temporary table.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPSTEP1(CASEID,EVENTNO,CYCLE,DOCUMENTCASEID,CRITERIANO,IDENTITYID,USERID,BESTFIT,TRIGGERCASEID)
	SELECT DISTINCT CE.CASEID, CE.EVENTNO, CE.CYCLE, T.CASEID, EC.CRITERIANO,POL.IDENTITYID,POL.SQLUSER,
		CASE WHEN (TC.OFFICEID     IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (RC.CASEID       IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (TC.PROPERTYTYPE ='~')	THEN '0' ELSE '1' END +
		CASE WHEN (TC.COUNTRYCODE  ='ZZZ')	THEN '0' ELSE '1' END +
		CASE WHEN (TC.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (TC.SUBTYPE      IS NULL)	THEN '0' ELSE '1' END +
		CASE WHEN (P1.BASIS        IS NULL)	THEN '0' ELSE '1' END,
		TC.CASEID
	From #TEMPPOLICING POL
	join CASES TC		on (TC.CASEID=POL.CASEID)
	left join PROPERTY P1	on (P1.CASEID=POL.CASEID)
	join CASEEVENT T	on (T.CASEID=POL.CASEID
				and T.EVENTNO=POL.EVENTNO
				and T.CYCLE=POL.CYCLE)
	join EVENTCONTROL EC	on (EC.CASETYPE=TC.CASETYPE
				and EC.SAVEDUEDATE between 2 and 5)
	join EVENTCONTROLREQEVENT  RE	on (RE.CRITERIANO=EC.CRITERIANO
					and RE.EVENTNO=EC.EVENTNO
					and RE.REQEVENTNO=T.EVENTNO)
	join OPENACTION OA	on (OA.CRITERIANO=EC.CRITERIANO and OA.POLICEEVENTS=1)
	join CASEEVENT CE	on (CE.CASEID=OA.CASEID
				and CE.EVENTNO=EC.EVENTNO
				and CE.OCCURREDFLAG=0
				and(CE.EVENTDUEDATE<=convert(varchar,getdate(),112) or EC.SAVEDUEDATE in (2,3)))
	join CASES C		on (C.CASEID=CE.CASEID)
	left join PROPERTY P	on (P.CASEID=CE.CASEID)
	left join RELATEDCASE RC	on (RC.CASEID=TC.CASEID
					and RC.RELATEDCASEID=C.CASEID)
	WHERE POL.TYPEOFREQUEST=8
	and   T.EVENTDATE is not null
	and  (TC.OFFICEID     = CASE WHEN(EC.OFFICEIDISTHISCASE=1)    THEN C.OFFICEID     ELSE EC.OFFICEID     END OR TC.OFFICEID     IS NULL)
	AND  (TC.PROPERTYTYPE = CASE WHEN(EC.PROPERTYTYPEISTHISCASE=1)THEN C.PROPERTYTYPE ELSE EC.PROPERTYTYPE END OR TC.PROPERTYTYPE ='~')
	AND  (TC.COUNTRYCODE  = CASE WHEN(EC.COUNTRYCODEISTHISCASE=1) THEN C.COUNTRYCODE  ELSE EC.COUNTRYCODE  END OR TC.COUNTRYCODE  ='ZZZ')
	AND  (TC.CASECATEGORY = CASE WHEN(EC.CATEGORYISTHISCASE=1)    THEN C.CASECATEGORY ELSE EC.CASECATEGORY END OR TC.CASECATEGORY IS NULL)
	AND  (TC.SUBTYPE      = CASE WHEN(EC.SUBTYPEISTHISCASE=1)     THEN C.SUBTYPE      ELSE EC.SUBTYPE      END OR TC.SUBTYPE      IS NULL)
	AND  (P1.BASIS        = CASE WHEN(EC.BASISISTHISCASE=1)       THEN P.BASIS        ELSE EC.BASIS        END OR P1.BASIS        IS NULL)
	AND  (RC.CASEID is not null
	 OR   not exists (Select 1 from RELATEDCASE R1
			  where R1.CASEID=TC.CASEID
			  and R1.RELATEDCASEID is not null) )"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @nRowCount=@@rowcount
End

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	insert into #TEMPCANDIDATECASES(CASEID,EVENTNO,CYCLE,DOCUMENTCASEID,CRITERIANO,IDENTITYID,USERID,BESTFIT)
	select DISTINCT T.CASEID,T.EVENTNO,T.CYCLE,T.DOCUMENTCASEID,T.CRITERIANO,T.IDENTITYID,T.USERID,T.BESTFIT	
	from #TEMPSTEP1 T
	join EVENTCONTROLNAMEMAP NM	on (NM.CRITERIANO=T.CRITERIANO
					and NM.EVENTNO=T.EVENTNO)
	join CASENAME CN1	on (CN1.CASEID=T.CASEID
				and CN1.NAMETYPE=isnull(NM.SUBSTITUTENAMETYPE,NM.APPLICABLENAMETYPE)
				and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>getdate()))

	left join CASENAME CN2	on (CN2.CASEID=T.TRIGGERCASEID
				and CN2.NAMETYPE=NM.APPLICABLENAMETYPE
				and(CN2.EXPIRYDATE is null or CN2.EXPIRYDATE>getdate())
				and CN2.NAMENO=CN1.NAMENO)
	left join (	select	RE.CRITERIANO, RE.EVENTNO, C.CASEID,
				count(*) as REQUIREDEVENTCOUNT,
				sum(CASE WHEN(CE.EVENTNO is null) THEN 0 ELSE 1 END) as OCCURREDEVENTCOUNT
			from EVENTCONTROLREQEVENT RE
			cross join #TEMPCASES C
			left join #TEMPCASEEVENT CE on (CE.CASEID=C.CASEID
						and CE.EVENTNO=RE.REQEVENTNO
						and CE.CYCLE=1
						and CE.OCCURREDFLAG=1)
			group by RE.CRITERIANO, RE.EVENTNO, C.CASEID) REQ
					on (REQ.CASEID=T.TRIGGERCASEID
					and REQ.CRITERIANO=T.CRITERIANO
					and REQ.EVENTNO=T.EVENTNO)
	WHERE isnull(REQ.OCCURREDEVENTCOUNT,0)>=isnull(REQ.REQUIREDEVENTCOUNT,0)
	AND  (CN2.NAMENO=CN1.NAMENO
	 OR  (isnull(NM.MUSTEXIST,0)=0
	  and not exists (Select 1 from CASENAME CN3
			  where CN3.CASEID=T.TRIGGERCASEID
			  and CN3.NAMETYPE=isnull(NM.SUBSTITUTENAMETYPE,NM.APPLICABLENAMETYPE)
			  and(CN3.EXPIRYDATE is null or CN3.EXPIRYDATE>getdate())
			  and CN3.NAMENO<>CN1.NAMENO) ))"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @nRowCount=@@rowcount
End

-- Delete any candidate Cases where all of the 
-- mandatory Name matches do not exist.
If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	Delete #TEMPCANDIDATECASES
	from #TEMPCANDIDATECASES T
	join EVENTCONTROLNAMEMAP NM	
				on (NM.CRITERIANO=T.CRITERIANO
				and NM.EVENTNO=T.EVENTNO)
	left join CASENAME CN1	on (CN1.CASEID=T.CASEID
				and CN1.NAMETYPE=isnull(NM.SUBSTITUTENAMETYPE,NM.APPLICABLENAMETYPE)
				and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE>getdate()))
	left join CASENAME CN2	on (CN2.CASEID=T.DOCUMENTCASEID
				and CN2.NAMETYPE=NM.APPLICABLENAMETYPE
				and(CN2.EXPIRYDATE is null or CN2.EXPIRYDATE>getdate())
				and CN2.NAMENO=CN1.NAMENO)
	--     Delete if a MustExist name is missing
	Where (NM.MUSTEXIST=1 and CN2.CASEID is null)
	--     Delete if an optional Name is missing but
	--     a non matching name exists for the name type
	OR    (isnull(NM.MUSTEXIST,0)=0 
	  and  CN2.CASEID is null
	  and  exists(  select * from CASENAME CN3
			where CN3.CASEID=T.DOCUMENTCASEID
			and CN3.NAMETYPE=NM.APPLICABLENAMETYPE
			and(CN3.EXPIRYDATE is null OR CN2.EXPIRYDATE>getdate())))"

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount-@@rowcount
End

-- Delete any candidate Cases where there is a
-- Document Case with higher best fit match
If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	Delete #TEMPCANDIDATECASES
	from #TEMPCANDIDATECASES T
	join (select * from #TEMPCANDIDATECASES) T1
			on (T1.CASEID=T.CASEID
			and T1.EVENTNO=T.EVENTNO
			and T1.CYCLE=T.CYCLE
			and T1.BESTFIT>T.BESTFIT)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Delete any candidate Cases where there is a
-- Document Case with lower sequence number. 
-- This is to just remove any duplicate candidate
-- Case Events.
If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	Delete #TEMPCANDIDATECASES
	from #TEMPCANDIDATECASES T
	join (select * from #TEMPCANDIDATECASES) T1
			on (T1.CASEID=T.CASEID
			and T1.EVENTNO=T.EVENTNO
			and T1.CYCLE=T.CYCLE
			and T1.SEQUENCENO>T.SEQUENCENO)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
and @nRowCount>0
Begin
	-- Update any existing #TEMPCASEEVENT rows for the candidate
	-- cases that can now occur.
	-- NOTE: State is set to I1 so that it does not trigger any
	--	 other events at this time.  A Policing request will
	-- 	 be raised separately to process this event occurring.
	Set @sSQLString="
	Update #TEMPCASEEVENT
	Set	NEWEVENTDATE=CASE WHEN(EC.SAVEDUEDATE in (2,3)) THEN T.NEWEVENTDUEDATE ELSE convert(varchar,getdate(),112) END,
		OCCURREDFLAG=1,
		FROMCASEID  =C.DOCUMENTCASEID,
		[STATE]	    ='I1'
	From #TEMPCASEEVENT T
	join #TEMPCANDIDATECASES C on (C.CASEID =T.CASEID
				   and C.EVENTNO=T.EVENTNO
				   and C.CYCLE  =T.CYCLE)
	join EVENTCONTROL EC	   on (EC.CRITERIANO=T.CRITERIANO
				   and EC.EVENTNO=T.EVENTNO)
	Where T.NEWEVENTDATE is null
	and   T.NEWEVENTDUEDATE is not null
	and   T.[STATE] not like 'D%'"

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @nRowCount=@@rowcount

	If @ErrorCode=0
	Begin
		-- Load the #TEMPECASEEVENT table with the Candidate case 
		-- details that have occurred.
		Set @sSQLString="
		Insert into #TEMPCASEEVENT(CASEID, EVENTNO, CYCLE, OCCURREDFLAG, OLDEVENTDATE,NEWEVENTDATE, OLDEVENTDUEDATE,
					   NEWEVENTDUEDATE, NEWDATEREMIND, DATEDUESAVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO,
					   [STATE], CREATEDBYACTION, CREATEDBYCRITERIA, FROMCASEID, USERID, IDENTITYID, ACTION,CRITERIANO,
					   RECALCEVENTDATE,SUPPRESSCALCULATION)
		Select 	DISTINCT CE.CASEID, CE.EVENTNO, CE.CYCLE, 1, CE.EVENTDATE,
			CASE WHEN(EC.SAVEDUEDATE in (2,3)) THEN CE.EVENTDUEDATE ELSE convert(varchar,getdate(),112) END,
			CE.EVENTDUEDATE, CE.EVENTDUEDATE, NULL, CE.DATEDUESAVED, CE.USEMESSAGE2FLAG, CE.GOVERNINGEVENTNO,
			'I1', CE.CREATEDBYACTION, CE.CREATEDBYCRITERIA, T.DOCUMENTCASEID,T.USERID, T.IDENTITYID, CE.CREATEDBYACTION, CE.CREATEDBYCRITERIA,
			EC.RECALCEVENTDATE,EC.SUPPRESSCALCULATION
		from #TEMPCANDIDATECASES T
		join CASEEVENT CE	on (CE.CASEID =T.CASEID
					and CE.EVENTNO=T.EVENTNO
					and CE.CYCLE  =T.CYCLE)
		join EVENTCONTROL EC	on (EC.CRITERIANO=T.CRITERIANO
					and EC.EVENTNO=T.EVENTNO)
		Where CE.EVENTDATE is null"
	
		Exec @ErrorCode=sp_executesql @sSQLString

		Set @nRowCount=@nRowCount+@@rowcount
	End

	If @ErrorCode=0
	and @nRowCount>0
	Begin
		-- If CaseEvents have just been marked as having occurred
		-- then raise a separate Policing request.  These will be 
		-- processed in a different Policing thread so as not to
		-- delay processing of the current Policing thread.
		Set @sSQLString="
		insert into #TEMPPOLICINGREQUEST (CASEID,EVENTNO,CYCLE,TYPEOFREQUEST,CRITERIANO,SQLUSER,IDENTITYID)
		select	distinct CE.CASEID,CE.EVENTNO,CE.CYCLE,3,CE.CREATEDBYCRITERIA,T.USERID,T.IDENTITYID
		from #TEMPCANDIDATECASES T
		join #TEMPCASEEVENT CE	on (CE.CASEID =T.CASEID
					and CE.EVENTNO=T.EVENTNO
					and CE.CYCLE  =T.CYCLE)
		where CE.[STATE]='I1'"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceDocumentCase',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
End

drop table #TEMPCANDIDATECASES
drop table #TEMPSTEP1

return @ErrorCode
go

grant execute on dbo.ip_PoliceDocumentCase  to public
go
