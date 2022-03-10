-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetEventToRecalculate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetEventToRecalculate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetEventToRecalculate.'
	drop procedure dbo.ip_PoliceGetEventToRecalculate
end
print '**** Creating procedure dbo.ip_PoliceGetEventToRecalculate...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetEventToRecalculate
			 @pnRowCount		int	OUTPUT,
			 @pnDebugFlag		tinyint,
			 @nEventNo		int,
			 @bRecalcEventDate	bit
as
-- PROCEDURE :	ip_PoliceGetEventToRecalculate
-- VERSION :	38
-- DESCRIPTION:	A procedure to get the Case Event rows that are to be recalculated as a result 
--              of a specific request from Policing Request
-- CALLED BY :	ipu_PoliceRecalc

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 10/07/2001	MF			Procedure created
-- 15/10/2001	MF	7117		If an Event is being recalculated and the Due Date is manually entered 
--					then the Event still needs to be returned for recalculation in case the 
--					Event is now satisfied by another event 
-- 16/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 24 Jul 2003	MF	8260	10	Get the PTADELAY from EventControl for Patent Term Adjustment calculation.
-- 12 Nov 2003	MF	9450	11	Set the CRITERIANO on the #TEMPCASEEVENT table when inserting rows.
-- 26 Feb 2004	MF	RFC709	12	Get IDENTITYID to identify workbench user
-- 03 Nov 2004	MF	10385	13	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 09 Jan 2006	MF	11971	14	Will cater for the new option where events that have occurred may be cleared
--					and recalculated if they are flagged as allowing the recalculation.
-- 13 Jan 2006	MF	11971	15	Rework. 
-- 17 Jan 2006	MF	11971	17	Rework.
-- 15 May 2006	MF	12315	18	New EventControl columns to update CASENAME when Event occurs.
-- 07 Jun 2006	MF	12417	19	Change order of columns returned in debug mode to make it easier to review
-- 19 Jun 2006	MF	12812	20	Related to 11971. Only return Recalcule Event for a CaseEvent if the rules
--					either have a due date calculation or a From Event Update rule defined.
-- 21 Aug 2006	MF	13089	21	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 31 May 2007	MF	14812	22	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	23	Reserve word [STATE],
-- 29 Oct 2007	MF	15518	24	Set the LIVEFLAG on #TEMPCASEEVENT
-- 07 Jan 2008	MF	15586	24	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 08 May 2008	MF	16385	25	Revisit of 11971. Clear out NEWEVENTDUEDATE so that cyclic Events set to auto
--					update do not do so until after the recalculation.
-- 27 Jul 2009	MF	17922	26	Ensure rows inserted into #TEMPCASEEVENT have the ACTION column initialised to the same as CREATEDBYACTION.
-- 28 Aug 2009	MF	17922	27	Revisit. Correction to SQL as ACTION referernced twice.
-- 23 Feb 2010	MF	18482	28	Events flagged to recalculate even if they have occurred (RECALCEVENTDATE) should
--					only be returned if the OpenAction is marked to recalculate (STATE='C') if there 
--					is a specific Action being recalculated.
-- 18 Apr 2011	MF	19544	29	Consider all of the Actions under which the candidate Events for recalculation reside.
--					By only considering the CreatedByCriteria against the CASEEVENT row we were excluding
--					the actual Action that contains the calculation if the Event was manually entered from
--					a different Action.
-- 20 Jun 2011	MF	10870	30	If DATEDUESAVED flag is on then the NewEventDueDate should be set to the current EVENTDUEDATE value.
-- 30 Nov 2011	MF	20142	31	An Event that is marked to Recalculate will now have any manually entered due date removed to ensure that
--					the previously occurred date is discarded and the previously entered due date is also ignored so the date
--					can calculate from scratch.
-- 06 Jun 2012	MF	S19025	32	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 11 Apr 2013	MF	R13395	33	CaseEvent rows that do not have any due date calculations defined should be returned to recalculate if a due date exists.
-- 06 Jun 2013	MF	S21404	34	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 18 Feb 2015	MF	45044	35	Events to be recalculated must belong to an OpenAction where POLICEEVENTS=1.
-- 15 Mar 2017	MF	70049	36	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV	DR-45358 37	Date conversion errors when creating cases and opening names in Chinese DB
-- 27 Jun 2019	MF	DR-33145 38	Revist of 521404.  Events flagged with SUPPRESSCALCULATION should not be recalculated. 

set nocount on

DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- The #TEMPCASEEVENT table is to be loaded with Events that are eligible to be calculated.  This will also include
-- rows that have been satisfied by another Event so that they will be deleted.

-- STATE = 'C' (calculate)

If @ErrorCode=0
Begin
	If @bRecalcEventDate=0
	Begin
		-- Return Events that have not yet occurred and that match the EventNo passed 
		-- as a parameter.
		Set @sSQLString="
		insert into #TEMPCASEEVENT 
				(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
					OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA,ACTION,CRITERIANO,ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
					DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO,[STATE],ADJUSTMENT,
					IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
					SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
					INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, USERID, NEWEVENTDUEDATE,
					USEDINCALCULATION, DATEREMIND, ESTIMATEFLAG,EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
					CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE,RECALCEVENTDATE,
					SUPPRESSCALCULATION)
		SELECT	Distinct
			T.CASEID,  E.DISPLAYSEQUENCE, E.EVENTNO, isnull(CE.CYCLE, T.CYCLE),
			0, CE.EVENTDATE, CE.EVENTDUEDATE, CE.DATEDUESAVED, CE.OCCURREDFLAG, T.ACTION, E.CRITERIANO,T.ACTION,E.CRITERIANO, CE.ENTEREDDEADLINE, CE.PERIODTYPE, 
			CE.DOCUMENTNO, CE.DOCSREQUIRED, CE.DOCSRECEIVED, CE.USEMESSAGE2FLAG, CE.GOVERNINGEVENTNO, 'C', 
			NULL, E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, 
			E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, 
			E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, T.COUNTRYCODE, 
			T.USERID, CE.EVENTDUEDATE, NULL, CE.DATEREMIND, E.ESTIMATEFLAG,
			E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
			E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,convert(bit,isnull(CE.CASEID,0)),
			E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
		From		#TEMPOPENACTION T
		join		ACTIONS A	on (A.ACTION=T.ACTION)
		join		EVENTCONTROL E	on (E.CRITERIANO=T.CRITERIANO
						and E.EVENTNO   =@nEventNo)
		left join	CASEEVENT CE	on (CE.CASEID=T.CASEID
						and CE.EVENTNO=E.EVENTNO
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
		WHERE	(CE.CASEID 	 is null OR CE.OCCURREDFLAG=0 OR CE.OCCURREDFLAG is null)
		-- RFC45044
		-- The Action must allow Policing
		and	T.POLICEEVENTS=1
											-- Only calculate the row if the
											-- appropriate Status allows	
											-- the Action to be policed	
		and    ((A.ACTIONTYPEFLAG  =0 and (SC.POLICEOTHERACTIONS=1 or SC.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =2 and (SC.POLICEEXAM        =1 or SC.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =1 or SC.STATUSCODE  is null) 
		                              and (SR.POLICERENEWALS    =1 or SR.STATUSCODE is null)))"
	End
	Else Begin
		-- When the Recalc Event Date flag is used then Events may be returned even if they have already
		-- occurred as long as the EventControl for the Event is flagged to allow the Event Date to be 
		-- recalculated (RECALCEVENTDATE)
		Set @sSQLString="
		insert into #TEMPCASEEVENT 
				(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
					OCCURREDFLAG, CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
					DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO,[STATE],ADJUSTMENT,
					IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
					SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
					INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, USERID, NEWEVENTDUEDATE,
					USEDINCALCULATION, DATEREMIND, ESTIMATEFLAG,EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,IDENTITYID,SETTHIRDPARTYOFF,
					CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE,RECALCEVENTDATE,
					SUPPRESSCALCULATION)
		SELECT	Distinct
			T.CASEID,  E.DISPLAYSEQUENCE, E.EVENTNO, isnull(CE.CYCLE, T.CYCLE),
			0, CE.EVENTDATE, CE.EVENTDUEDATE,
			CASE WHEN(E.RECALCEVENTDATE=1 and CE.OCCURREDFLAG>0) 
				THEN 0
				ELSE CE.DATEDUESAVED 
			END, 
			0, T.ACTION, E.CRITERIANO,T.ACTION,E.CRITERIANO, CE.ENTEREDDEADLINE, CE.PERIODTYPE, 
			CE.DOCUMENTNO, CE.DOCSREQUIRED, CE.DOCSRECEIVED, CE.USEMESSAGE2FLAG, CE.GOVERNINGEVENTNO, 'C', 
			NULL, E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, 
			E.STATUSCODE, E.RENEWALSTATUS, E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, 
			E.CLOSEACTION, E.RELATIVECYCLE, E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, T.COUNTRYCODE, 
			T.USERID, 
			CASE WHEN(E.RECALCEVENTDATE=1 and CE.OCCURREDFLAG>0) 
				THEN NULL
				ELSE CE.EVENTDUEDATE 
			END, 
			NULL, CE.DATEREMIND, E.ESTIMATEFLAG,
			E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,T.IDENTITYID,E.SETTHIRDPARTYOFF,
			E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG, E.DIRECTPAYFLAG2,convert(bit,isnull(CE.CASEID,0)),
			E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
		From		#TEMPOPENACTION T
		join		ACTIONS A	on (A.ACTION=T.ACTION)
		join		EVENTCONTROL E	on (E.CRITERIANO=T.CRITERIANO)
		left join	CASEEVENT CE	on (CE.CASEID=T.CASEID
						and CE.EVENTNO=E.EVENTNO
											-- If the Action is cyclic then	
											-- use the cycle of the Open	
											-- Action row otherwise there is
											-- no restriction.		
						and CE.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED=1) THEN CE.CYCLE ELSE T.CYCLE END)
		join		#TEMPCASES C	on (C.CASEID=T.CASEID)
											-- Are there any Due Date Calculations
											-- for the Event?
		left join      (select distinct OA.CASEID, DD.EVENTNO
				from #TEMPOPENACTION OA
				join DUEDATECALC DD on (DD.CRITERIANO=OA.CRITERIANO)
				where DD.FROMEVENT is not null
				and   DD.OPERATOR  is not null) DC 
						on (DC.CASEID =T.CASEID
						and DC.EVENTNO=CE.EVENTNO)
				
		left join	STATUS SC	on (SC.STATUSCODE=C.STATUSCODE)
		left join	STATUS SR	on (SR.STATUSCODE=C.RENEWALSTATUS)
	
		-- Only calculate the row if the appropriate Status allows the Action to be policed	
		WHERE  ((A.ACTIONTYPEFLAG  =0 and (SC.POLICEOTHERACTIONS=1 or SC.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =2 and (SC.POLICEEXAM        =1 or SC.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =1 or SC.STATUSCODE  is null) 
		                              and (SR.POLICERENEWALS    =1 or SR.STATUSCODE is null)))
		-- RFC45044
		-- The Action must allow Policing
		and	T.POLICEEVENTS=1
		-- Only calculate the row if the due date has not been saved unless the Event has
		-- occurred and is marked as allowing recalculation.
		and (isnull(CE.DATEDUESAVED,0)=0 OR (E.RECALCEVENTDATE=1 and CE.OCCURREDFLAG>0))
		-- Only return the row if a Due Date rule exists or the event is loaded from another Event
		and 	(E.UPDATEFROMEVENT is not null
		 or	 exists
			 (select 1 from DUEDATECALC DD
			  where DD.CRITERIANO=E.CRITERIANO
			  and   DD.EVENTNO   =E.EVENTNO
			  and   DD.FROMEVENT is not null
			  and   DD.OPERATOR  is not null)
		-- OR You can return the row if the CaseEvent has not occurred and there are NO due date calculations
		 or	(CE.OCCURREDFLAG=0 and DC.CASEID is null and @nEventNo is not null)
			)"

		If @nEventNo is not null
		Begin
			-- If a specific EventNo has been specified then we are to recalculate 
			-- all of the CaseEvents for that EventNo if it has not already occurred
			-- or if the Event is flagged to allow the Event Date to recalculate then
			-- even those CaseEvents that have already occurred are to be flagged to
			-- be calculated.
			Set @sSQLString=@sSQLString+char(10)+
			"		and E.EVENTNO=@nEventNo"+char(10)+ 
			"		and (E.RECALCEVENTDATE=1 OR isnull(CE.OCCURREDFLAG,0)=0)"
		End
		Else Begin
			-- If no specific EventDate has been indicated then only return those Events
			-- that have occurred that are flagged as allowing recalculation of the
			-- Event date.
			Set @sSQLString=@sSQLString+char(10)+
			"		and E.RECALCEVENTDATE=1 and CE.OCCURREDFLAG between 1 and 8"

			-- SQA18482
			-- If an Action is being recalculated then restrict the Recalc Events
			-- to those Events that belong to the Action being recalculated.
			If exists(select 1 from #TEMPOPENACTION where [STATE]='C')
			Begin
				Set @sSQLString=@sSQLString+char(10)+
				"		and T.[STATE]='C'"
			End
		End
	End

	Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@nEventNo		int',
					@nEventNo

	-- SQA18482
	-- DO NOT SET ROWCOUNT
	-- this was blocking further processing when zero rows found.
	-- Set @pnRowCount=@@Rowcount

end

If  @ErrorCode=0
and @pnRowCount>0
Begin
	-----------------------------------------------------
	-- Any #TEMPCASEEVENT rows flagged to recalculate 'C'
	-- are to be changed to a STATE of 'X' so they are
	-- not recalculated if SUPPRESSCALCULATION=1
	-----------------------------------------------------
	Set @sSQLString="
	Update #TEMPCASEEVENT
	set [STATE]='X'
	from #TEMPCASEEVENT T
	where T.[STATE]='C'
	and T.SUPPRESSCALCULATION=1"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If  @ErrorCode=0
and @pnRowCount>0
Begin
	-----------------------------------------------------
	-- Remove any #TEMPCASEEVENT rows previously inserted
	-- with a STATE of 'X' which have now been inserted 
	-- a second time.
	-----------------------------------------------------
	Set @sSQLString="
	delete #TEMPCASEEVENT
	from #TEMPCASEEVENT T1
	where T1.[STATE]='X'
	and exists 
	(select 1 from #TEMPCASEEVENT T2
	 where T2.CASEID=T1.CASEID
	 and T2.EVENTNO=T1.EVENTNO
	 and T2.CYCLE=T1.CYCLE
	 and T2.[STATE]<>'X')"

	Exec @ErrorCode=sp_executesql @sSQLString
end

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetEventToRecalculate',0,1,@sTimeStamp ) with NOWAIT

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

grant execute on dbo.ip_PoliceGetEventToRecalculate  to public
go