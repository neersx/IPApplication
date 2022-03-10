-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceInsertLetters
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceInsertLetters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceInsertLetters.'
	drop procedure dbo.ip_PoliceInsertLetters
end
print '**** Creating procedure dbo.ip_PoliceInsertLetters...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceInsertLetters 
			@pdtFromDate		datetime,
			@pdtUntilDate		datetime,
			@pdtLetterDate		datetime,
			@pnCountStateI1		int,
			@pnCountStateR1		int,
			@pnDebugFlag		tinyint,
			@pnUserIdentityId	int	=null,
			@pbUniqueTimeRequired	bit	=0

as
-- PROCEDURE :	ip_PoliceInsertLetters
-- VERSION :	28
-- DESCRIPTION:	Inserts letters into the ACTIVITYREQUEST table
-- CALLED BY :	ipu_Policing
--		ipu_PoliceUpdateDatabase

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 27/04/2001	MF			Procedure created
-- 18/09/2001	MF	7060 		The letter to be sent is not always correctly being determined because of a
--					coding error.
-- 03/10/2001	MF	7095		When the due date of an Event is calculated then the last letter that should
--					have been produced up to now is to be produced.
-- 14/10/2001	MF	7117		Correction to SQA 7095.
-- 15/10/2001	MF	7120		When inserting letters, check the Status prior to any updates caused in this
--					Policing run.
-- 22/10/2001	MF	7137		Policing should produce all eligible letters that fall within the Policing date 
--					range and not just the last letter in the list.
-- 31/10/2001	MF	7161		When using the CREATEDBYCRITERIA to get the Reminders make sure that the
--					Action is Open for the Case.
-- 5/11/2001	MF	7146		Modify the algorithm that calculates the next reminder date.
-- 15/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 6/12/2001	MF	7273		Avoid duplicate letters being produced by using a DISTINCT clause.  Duplicates
--					can occur if a letter has been defined multiple times with the update option.
-- 04/02/2002	MF	7377		Letters that the MULTICASEFLAG set on are to have an ACTIVITYREQUEST row with an 
--					ACTIVITITYCODE Of 3206 to indicate the letter is available for bulk processing.
-- 12/03/2002	MF	7485		Change the function USER to SYSTEM_USER
-- 16/03/2002	MF	7506		Change the processing so that Events that have updated during processing will 
--					trigger letters to be sent even if the Action is no longer opened against the Case.
-- 01/07/2002	MF	7773		A modification for .NET to allow Alerts to generate a LETTER which results in
--					any letter rules for this CASEID, EVENTNO and CYCLE being suppressed.
-- 18/07/2002	MF	7839		Letters that are flagged to update the Event when they are sent should not be
--					generated if the Event has been manually modified.
-- 17/02/2003	MF	8429		Only insert letters for Cases that have not been marked as being in error.
-- 24/02/2003	MF	8429		Revisit.  Problem with change found in testing.
-- 26/05/2003	MF			Do not perform any updates if TEMPCASES is marked as having an error.
-- 28 Jul 2003	MF		10	Standardise version number
-- 26 Feb 2004	MF	RFC709	11	To identify workbench users add the parameter @pnUserIdentityId
-- 08 Jun 2004	MF	10151	12	Insert a separate Letter request row into ACTIVITYREQUEST for each Name that
--					is associated with the Case for the specified NameType.
-- 07 Dec 2004	MF	10593	13	Ensure that rows written to the ACITIVITYHISTORY have a different datetime
--					stamp to those written to ACTIVITYREQUEST.  This ensures that when the 
--					ACTIVITREQUEST row is eventually processed and moved to ACTIVITYHISTORY that
--					a duplicate key error is avoided.
-- 06 Jan 2005	MF	9914	14	Where letters are flagged as only being required for Prime Cases then check
--					to see if the Case is on a CaseList.  If it is then only generate the letter
--					of the Case is flagged as the prime case.
-- 07 Jun 2005	MF	10720	15	Allow different units of time for frequency and stop time for Letters.
-- 09 Jun 2005	MF	11480	16	Duplicate error on ActivityRequest when client PC time is in advance of server.
-- 23 Jan 2006	MF	12223	17	Letters may be defined for the Event against an Action that is not the same
--					as the Action with the due date calculation for the Event.
-- 31 May 2007	MF	14812	18	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	19	Reserve word [STATE]
-- 10 Mar 2008	MF	16070	20	The ACTIVITYREQUEST table now have a system assigned unique
--					identity column as the unique primary key. As a result the WHENREQUESTED datetime
--					stamp is no longer required to be unique so we can simplify the code used to 
--					ensure rows written were always unique.  This will create a performance improvement.
-- 11 Jul 2008	MF	16690	21	If rows inserted into the ACTIVITYREQUEST table are required to have a unique
--					WHENREQUESTED datetime then an additional processing will enforce this.
-- 13 Apr 2009	MF	17601	22	Load rows from #TEMPACTIVITYREQUEST that were generated by Alert.
-- 18 Oct 2011	MF	18798	23	Use OPTION(MAXDOP 1) to manually set the Maximum Degrees of Parallelism to a single processor. This will allow
--					the database to be set to use parallelism but those complex problem queries with this option will then
--					revert to no parallelism in order to get enhanced performance.
-- 05 Jul 2013	vql	R13629	24	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 31 Jul 2013	MF	R13629	25	Revisit R13629 because length of dynamic SQL was causing truncation. Change @sSQLString to nvarchar(max).
-- 04 Sep 2013	MF	R13743	26	When @pnIdentityId is null a sql error was occurring as a result of changes made to extend @sSQLString to nvarchar(max).
-- 14 Nov 2018  AV	DR-45358 27	Date conversion errors when creating cases and opening names in Chinese DB
-- 10 Apr 2019	MF	DR-48142 28	When a letter had a lead time configured as YEARS and a frequency in MONTHS the letter is not always generated.
--
set nocount on

DECLARE		@ErrorCode	int,
		@nRowCount	int,
		@dtTimeStamp	datetime,
		@dtTimeStamp1	datetime,
		@sSQLString	nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0
Set @nRowCount = 0

-- Get the highest datetimestamp in ACTIVITYHISTORY used as a starting point for new rows to be inserted into
-- the ACTIVITYREQUEST table
If @ErrorCode=0
Begin
	If @pbUniqueTimeRequired=1
	Begin
		Set @sSQLString="
		Select @dtTimeStamp=max(A.WHENREQUESTED)
		from #TEMPCASEEVENT T
		join ACTIVITYHISTORY A	on (A.CASEID=T.CASEID)
		where A.WHENREQUESTED>getdate()"
		
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@dtTimeStamp	datetime	OUTPUT',
						  @dtTimeStamp=@dtTimeStamp	OUTPUT
	End
	Else Begin
		Set @dtTimeStamp=getdate()
	End
End

-- Need to see if there is any higher datetimestamp used on the ACTIVITYREQUEST table
If @ErrorCode=0
and @pbUniqueTimeRequired=1
Begin
	Set @dtTimeStamp1=@dtTimeStamp

	Set @sSQLString="
	Select @dtTimeStamp=max(A.WHENREQUESTED)
	from #TEMPCASEEVENT T
	join ACTIVITYREQUEST A	on (A.CASEID=T.CASEID)
	where A.WHENREQUESTED>isnull(@dtTimeStamp1,getdate())"
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@dtTimeStamp	datetime	OUTPUT,
					  @dtTimeStamp1	datetime',
					  @dtTimeStamp=@dtTimeStamp	OUTPUT,
					  @dtTimeStamp1=@dtTimeStamp1

	If @ErrorCode=0
	Begin
		Set @dtTimeStamp=dateadd(ms,3, ( CASE WHEN(@dtTimeStamp1>@dtTimeStamp)
							THEN @dtTimeStamp1
							ELSE coalesce(@dtTimeStamp, @dtTimeStamp1, getdate())
						 END))
	End
									
End

-- Insert Letters when the Event has just been updated and the Letter is flagged to either
-- update when the Event occurs or the Event is updated when the letter is sent.

-- A temporary table is used to generate a unique number which is later used to increment the
-- datetime stamp used to make the rows unique.

If  @ErrorCode=0
and @pnCountStateI1>0
Begin
	Set @sSQLString="
	insert into ACTIVITYREQUEST (	CASEID,  WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, 
				  	LETTERNO, COVERINGLETTERNO, HOLDFLAG, LETTERDATE, DELIVERYID, 
					ACTIVITYTYPE, ACTIVITYCODE, PROCESSED, IDENTITYID, INSTRUCTOR, BILLPERCENTAGE )
	Select	distinct T.CASEID, @dtTimeStamp, isnull(T.USERID,SYSTEM_USER), 'Pol-Proc', T.CREATEDBYACTION, T.EVENTNO, T.CYCLE,
		L.LETTERNO, L.COVERINGLETTER, isnull(L.HOLDFLAG, 0), @pdtLetterDate, L.DELIVERYID, 32,
		CASE WHEN (MULTICASEFLAG=1) THEN 3206 ELSE 3204 END, 0, isnull(T.IDENTITYID,@pnUserIdentityId),
		CN.NAMENO, CN.BILLPERCENTAGE
	from	#TEMPCASEEVENT T
	join	#TEMPCASES TC	on (TC.CASEID=T.CASEID
				and TC.ERRORFOUND is null)
	join	#TEMPOPENACTION OA
				on (OA.CASEID       =T.CASEID
				and(OA.CRITERIANO   =isnull(T.CRITERIANO, T.CREATEDBYCRITERIA)
				 or OA.NEWCRITERIANO=isnull(T.CRITERIANO, T.CREATEDBYCRITERIA)) )	-- Note the Action does not need to be open
	join	REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO	=T.EVENTNO)
	join	LETTER L	on (L.LETTERNO	=CASE WHEN (R.CHECKOVERRIDE=1)	THEN isnull(T.OVERRIDELETTER,R.LETTERNO) 
										ELSE R.LETTERNO
						 END)
	join	CASES C		on (C.CASEID=T.CASEID)
	join 	ACTIONS A	on (A.ACTION =OA.ACTION)
	left join CASELISTMEMBER LM on (LM.CASEID=T.CASEID)
	left join CORRESPONDTO CT on (CT.CORRESPONDTYPE=L.CORRESPONDTYPE)
	left join CASENAME CN	on (CN.CASEID=T.CASEID
				and CN.NAMETYPE=CT.NAMETYPE
				and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join ALERT AL	on (AL.CASEID =T.CASEID
				and AL.EVENTNO=T.EVENTNO
				and AL.CYCLE  =T.CYCLE
				and AL.OVERRIDERULE=1)
	Where	T.[STATE] like 'I%'
	and   ((L.FORPRIMECASESONLY=1 and LM.PRIMECASE=1) OR isnull(L.FORPRIMECASESONLY,0)=0 OR LM.CASEID is null)
	and    (OA.CYCLE=T.CYCLE OR A.NUMCYCLESALLOWED=1)
	and    (S.LETTERSALLOWED=1 OR S.LETTERSALLOWED is null)
	and   ((A.ACTIONTYPEFLAG=1  and (S1.LETTERSALLOWED is null OR S1.LETTERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))
	and    (R.UPDATEEVENT =2 OR (R.UPDATEEVENT=1 AND (T.EVENTUPDATEDMANUALLY=0 OR T.EVENTUPDATEDMANUALLY is null)))	-- SQA 7839
	and    (R.MAXLETTERS  is null
	 OR	R.MAXLETTERS  > (select count(distinct convert(varchar,AH.WHENREQUESTED,100)) 
				 from ACTIVITYHISTORY AH
				 where AH.CASEID  =T.CASEID
				 and   AH.EVENTNO =T.EVENTNO
				 and   AH.CYCLE   =T.CYCLE
				 and   AH.LETTERNO=L.LETTERNO))
	and  AL.CASEID is null
	OPTION (MAXDOP 1)"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pdtLetterDate	datetime,
					  @dtTimeStamp		datetime,
					  @pnUserIdentityId	int',
					  @pdtLetterDate,
					  @dtTimeStamp,
					  @pnUserIdentityId

	Set @nRowCount=@@Rowcount
End

-- Insert Letters when the letters to be produced fall within the date range that Policing is being run for.
-- This includes letters that have not yet occurred or those that have just occurred

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into ACTIVITYREQUEST (	CASEID,  WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, 
				  	LETTERNO, COVERINGLETTERNO, HOLDFLAG, LETTERDATE, DELIVERYID, 
					ACTIVITYTYPE, ACTIVITYCODE, PROCESSED, IDENTITYID, INSTRUCTOR, BILLPERCENTAGE )
	Select	distinct T.CASEID, convert(varchar,@dtTimeStamp,121),isnull(T.USERID,SYSTEM_USER), 'Pol-Proc', T.CREATEDBYACTION, T.EVENTNO, T.CYCLE,
		L.LETTERNO, L.COVERINGLETTER, isnull(L.HOLDFLAG, 0), convert(nvarchar,@pdtLetterDate,112), L.DELIVERYID, 32,
		CASE WHEN (MULTICASEFLAG=1) THEN 3206 ELSE 3204 END, 0,isnull(T.IDENTITYID,@pnUserIdentityId),
		CN.NAMENO, CN.BILLPERCENTAGE
	from	#TEMPOPENACTION OA
	join	EVENTCONTROL EC	on (EC.CRITERIANO=OA.NEWCRITERIANO)
	join	#TEMPCASEEVENT T on(T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO)
	join	#TEMPCASES TC	on (TC.CASEID=T.CASEID
				and TC.ERRORFOUND is null)
	join	REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO	=T.EVENTNO)
	join	LETTER L	on (L.LETTERNO	=CASE WHEN (R.CHECKOVERRIDE=1)	THEN isnull(T.OVERRIDELETTER,R.LETTERNO) 
										ELSE R.LETTERNO
						 END)
	join	CASES C		on (C.CASEID=T.CASEID)
	join 	ACTIONS A	on (A.ACTION =OA.ACTION)
	left join CASELISTMEMBER LM on (LM.CASEID=T.CASEID)
	left join CORRESPONDTO CT on (CT.CORRESPONDTYPE=L.CORRESPONDTYPE)
	left join CASENAME CN	on (CN.CASEID=T.CASEID
				and CN.NAMETYPE=CT.NAMETYPE
				and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join ALERT AL	on (AL.CASEID =T.CASEID
				and AL.EVENTNO=T.EVENTNO
				and AL.CYCLE  =T.CYCLE
				and AL.OVERRIDERULE=1)
	Where   OA.POLICEEVENTS=1
	and    (T.[STATE] like 'R%' OR T.[STATE] like 'I%')
	and   ((L.FORPRIMECASESONLY=1 and LM.PRIMECASE=1) OR isnull(L.FORPRIMECASESONLY,0)=0 OR LM.CASEID is null)
	and     T.DATEREMIND between @pdtFromDate and @pdtUntilDate
	and     T.OLDEVENTDUEDATE=T.NEWEVENTDUEDATE			-- SQA7095 The duedate has not just been calculated
	and    (OA.CYCLE=T.CYCLE   OR A.NUMCYCLESALLOWED=1)
	and    (S.LETTERSALLOWED=1 OR S.LETTERSALLOWED is null)
	and   ((A.ACTIONTYPEFLAG=1  and (S1.LETTERSALLOWED is null OR S1.LETTERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))
	and    (R.UPDATEEVENT is null or R.UPDATEEVENT=0)
									-- Check that the maximum of number of	
									-- letters have not been exceeded.	
	and    (R.MAXLETTERS  is null
	 OR	R.MAXLETTERS  > (select count(distinct convert(varchar,A.WHENREQUESTED,100)) 
				 from ACTIVITYHISTORY A
				 where A.CASEID  =T.CASEID
				 and   A.EVENTNO =T.EVENTNO
				 and   A.CYCLE   =T.CYCLE
				 and   A.LETTERNO=L.LETTERNO)
			       +(select count(distinct convert(varchar,A.WHENREQUESTED,100)) 
				 from ACTIVITYREQUEST A
				 where A.CASEID  =T.CASEID
				 and   A.EVENTNO =T.EVENTNO
				 and   A.CYCLE   =T.CYCLE
				 and   A.LETTERNO=L.LETTERNO))
	-- Find all of the letters in the list of available reminders where the	
	-- reminder date falls between the next	reminder date for the Event and the	
	-- final date in the date range for which Policing is being run.		
	and R.REMINDERNO in
	(select R1.REMINDERNO
	 from REMINDERS R1
	 where R1.CRITERIANO=R.CRITERIANO
	 and   R1.EVENTNO   =R.EVENTNO
	 and   R1.LETTERNO is not null
	 and  (CASE WHEN(CASE R1.PERIODTYPE	
				WHEN 'D' THEN dateadd (day,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE)
		   	 END ) >= T.DATEREMIND
			-- If the Lead Time date matches the	
			-- next reminder date then use it as the
			-- Reminder date			
		THEN 	CASE R1.PERIODTYPE	
				WHEN 'D' THEN dateadd (day,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE)
		   	END
			-- If the Lead Time is not in the 	
			-- future then the Reminder date will be
			-- calculated from the Lead Time date by
			-- using the Frequency to get a future  
			-- date.				
		ELSE	CASE WHEN (R1.FREQUENCY=0 OR R1.FREQUENCY is NULL)
			     THEN NULL
			     ELSE
				CASE
				  ---------------------------------------------------
				  -- Lead Time in DAYS
				  ---------------------------------------------------
				  WHEN(R1.PERIODTYPE='D' and isnull(R1.FREQPERIODTYPE,R1.PERIODTYPE)='D')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and dateadd (day,  ((datediff (day,   dateadd (day,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R1.FREQUENCY)   +1)*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE) 
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						    END
						THEN NULL
						ELSE dateadd (day,  ((datediff (day,   dateadd (day,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R1.FREQUENCY)   +1)*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
					 END
	
				  WHEN(R1.PERIODTYPE='D' and R1.FREQPERIODTYPE='W')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and dateadd (week, ((datediff (day,   dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R1.FREQUENCY*7))+1)*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE dateadd (week, ((datediff (day,   dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R1.FREQUENCY*7))+1)*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R1.PERIODTYPE='D' and R1.FREQPERIODTYPE='M')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						   END
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE CASE WHEN (dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						     END
					 END
	
				  WHEN(R1.PERIODTYPE='D' and R1.FREQPERIODTYPE='Y')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						   END
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE CASE WHEN (dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						     END
					 END
				  ---------------------------------------------------
				  -- Lead Time in WEEKS
				  ---------------------------------------------------
				  WHEN(R1.PERIODTYPE='W' and R1.FREQPERIODTYPE='D')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and dateadd (day,  ((datediff (day,   dateadd (week,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R1.FREQUENCY)   +1)*R1.FREQUENCY, dateadd (week,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE)) 
						>= CASE R1.STOPTIMEPERIODTYPE 
							  WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							  WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							  WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							  WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						    END
						THEN NULL
						ELSE dateadd (day,  ((datediff (day,   dateadd (week,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R1.FREQUENCY)   +1)*R1.FREQUENCY, dateadd (week,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
					 END

				  WHEN(R1.PERIODTYPE='W' and isnull(R1.FREQPERIODTYPE,R1.PERIODTYPE)='W')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and dateadd (week, ((datediff (day,   dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R1.FREQUENCY*7))+1)*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE) 
						>=  CASE R1.STOPTIMEPERIODTYPE 
							  WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							  WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							  WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							  WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						     END
						THEN NULL
						ELSE dateadd (week, ((datediff (day,   dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R1.FREQUENCY*7))+1)*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
					 END

				  WHEN(R1.PERIODTYPE='W' and R1.FREQPERIODTYPE='M')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						   END
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE CASE WHEN (dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						     END
					 END
	
				  WHEN(R1.PERIODTYPE='W' and R1.FREQPERIODTYPE='Y')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						   END
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE CASE WHEN (dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						     END
					 END
				  ---------------------------------------------------
				  -- Lead Time in MONTHS
				  ---------------------------------------------------
				  WHEN(R1.PERIODTYPE='M' and R1.FREQPERIODTYPE='D')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and dateadd (day,  ((datediff (day,   dateadd (month,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R1.FREQUENCY)   +1)*R1.FREQUENCY, dateadd (month,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE dateadd (day,  ((datediff (day,   dateadd (month,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R1.FREQUENCY)   +1)*R1.FREQUENCY, dateadd (month,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
					 END

				  WHEN(R1.PERIODTYPE='M' and R1.FREQPERIODTYPE='W')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and dateadd (week, ((datediff (day,   dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R1.FREQUENCY*7))+1)*R1.FREQUENCY, dateadd (month,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE dateadd (week, ((datediff (day,   dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R1.FREQUENCY*7))+1)*R1.FREQUENCY, dateadd (month,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
					 END

				  WHEN(R1.PERIODTYPE='M' and isnull(R1.FREQPERIODTYPE,R1.PERIODTYPE)='M')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
							THEN	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
							ELSE	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
						   END
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE CASE WHEN (dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
							THEN	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
							ELSE	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
						     END
					 END
	
				  WHEN(R1.PERIODTYPE='M' and R1.FREQPERIODTYPE='Y')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						   END
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE CASE WHEN (dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						     END
					 END
				  ---------------------------------------------------
				  -- Lead Time in YEARS
				  ---------------------------------------------------
				  WHEN(R1.PERIODTYPE='Y' and R1.FREQPERIODTYPE='D')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and dateadd (day,  ((datediff (day,   dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R1.FREQUENCY)   +1)*R1.FREQUENCY, dateadd (year,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE dateadd (day,  ((datediff (day,   dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R1.FREQUENCY)   +1)*R1.FREQUENCY, dateadd (year,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
					 END

				  WHEN(R1.PERIODTYPE='Y' and R1.FREQPERIODTYPE='W')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and dateadd (week, ((datediff (day,   dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R1.FREQUENCY*7))+1)*R1.FREQUENCY, dateadd (year,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE dateadd (week, ((datediff (day,   dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R1.FREQUENCY*7))+1)*R1.FREQUENCY, dateadd (year,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
					 END

				  WHEN(R1.PERIODTYPE='Y' and R1.FREQPERIODTYPE='M')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						   END
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE CASE WHEN (dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
							THEN	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							ELSE	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
						     END
					 END
	
				  WHEN(R1.PERIODTYPE='Y' and isnull(R1.FREQPERIODTYPE,R1.PERIODTYPE)='Y')
				    THEN CASE WHEN R1.STOPTIME is not null
					       and CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
							THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
							ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
						   END
						>= CASE R1.STOPTIMEPERIODTYPE 
							WHEN('D') THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('W') THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('M') THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN('Y') THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						   END
						THEN NULL
						ELSE CASE WHEN (dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
							THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
							ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
						     END
					 END
				END
			END
		END) between T.DATEREMIND and @pdtUntilDate)
	and AL.CASEID is null
	OPTION (MAXDOP 1)"
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@dtTimeStamp		datetime,
					  @pdtLetterDate	datetime,
					  @pdtFromDate		datetime,
					  @pdtUntilDate		datetime,
					  @pnUserIdentityId	int',
					  @dtTimeStamp		= @dtTimeStamp,
					  @pdtLetterDate	= @pdtLetterDate,
					  @pdtFromDate		= @pdtFromDate,
					  @pdtUntilDate		= @pdtUntilDate,
					  @pnUserIdentityId	= @pnUserIdentityId
	
	Set @nRowCount=@nRowCount+@@Rowcount
End

-- SQA 7095
-- If the due date has just been changed or calculated then output all letters where the duedate less the leadtime
-- is on or earlier than the date that Policing is being run.

If  @ErrorCode=0
and @pnCountStateR1>0
Begin
	Select @sSQLString="
	insert into ACTIVITYREQUEST (	CASEID,  WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, 
				  	LETTERNO, COVERINGLETTERNO, HOLDFLAG, LETTERDATE, DELIVERYID, 
					ACTIVITYTYPE, ACTIVITYCODE, PROCESSED, IDENTITYID, INSTRUCTOR, BILLPERCENTAGE )
	Select	distinct T.CASEID, @dtTimeStamp, isnull(T.USERID,SYSTEM_USER), 'Pol-Proc', T.CREATEDBYACTION, T.EVENTNO, T.CYCLE,
		L.LETTERNO, L.COVERINGLETTER, isnull(L.HOLDFLAG, 0), @pdtLetterDate, L.DELIVERYID, 32,
		CASE WHEN (MULTICASEFLAG=1) THEN 3206 ELSE 3204 END, 0,isnull(T.IDENTITYID,@pnUserIdentityId),
		CN.NAMENO, CN.BILLPERCENTAGE
	from	#TEMPOPENACTION OA
	join	EVENTCONTROL EC	on (EC.CRITERIANO=OA.NEWCRITERIANO)
	join	#TEMPCASEEVENT T on(T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO)
	join	#TEMPCASES TC	on (TC.CASEID=T.CASEID
				and TC.ERRORFOUND is null)
	join	REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO	=T.EVENTNO)
	join	LETTER L	on (L.LETTERNO	=CASE WHEN (R.CHECKOVERRIDE=1)	THEN isnull(T.OVERRIDELETTER,R.LETTERNO) 
										ELSE R.LETTERNO
						 END)
	join	CASES C		on (C.CASEID=T.CASEID)
	join 	ACTIONS A	on (A.ACTION=OA.ACTION)
	left join CASELISTMEMBER LM on (LM.CASEID=T.CASEID)
	left join CORRESPONDTO CT on (CT.CORRESPONDTYPE=L.CORRESPONDTYPE)
	left join CASENAME CN	on (CN.CASEID=T.CASEID
				and CN.NAMETYPE=CT.NAMETYPE
				and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
	left join PROPERTY P	on (P.CASEID=T.CASEID)
	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join ALERT AL	on (AL.CASEID=T.CASEID
				and AL.EVENTNO=T.EVENTNO
				and AL.CYCLE=T.CYCLE
				and AL.OVERRIDERULE=1)
	Where	OA.POLICEEVENTS=1
	and	T.[STATE] like 'R%'
	and   ((L.FORPRIMECASESONLY=1 and LM.PRIMECASE=1) OR isnull(L.FORPRIMECASESONLY,0)=0 OR LM.CASEID is null)
	and    (T.OLDEVENTDUEDATE<>T.NEWEVENTDUEDATE or (T.OLDEVENTDUEDATE is null and T.NEWEVENTDUEDATE is not null))
	and    (OA.CYCLE=T.CYCLE   OR A.NUMCYCLESALLOWED=1)
	and    (S.LETTERSALLOWED=1 OR S.LETTERSALLOWED is null)
	and   ((A.ACTIONTYPEFLAG=1  and (S1.LETTERSALLOWED is null OR S1.LETTERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))
	and    (R.UPDATEEVENT is null or R.UPDATEEVENT=0)
									-- If the due date less the lead time	
									-- is on or earlier than the date	
									-- policing is being run for then the	
									-- letter is eligble to produced if it	
									-- has not already been created.	

	and    (CASE R.PERIODTYPE	
			WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
			WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
			WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
			WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
		END ) <= @pdtUntilDate
									-- Check that the letter has not already
									-- been created				
	and    (1  >    (select count(distinct convert(varchar,A.WHENREQUESTED,100)) 
			 from ACTIVITYHISTORY A
			 where A.CASEID  =T.CASEID
			 and   A.EVENTNO =T.EVENTNO
			 and   A.CYCLE   =T.CYCLE
			 and   A.LETTERNO=L.LETTERNO)
		       +(select count(distinct convert(varchar,A.WHENREQUESTED,100)) 
			 from ACTIVITYREQUEST A
			 where A.CASEID  =T.CASEID
			 and   A.EVENTNO =T.EVENTNO
			 and   A.CYCLE   =T.CYCLE
			 and   A.LETTERNO=L.LETTERNO))
	and AL.CASEID is null"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pdtLetterDate datetime,
					  @pdtUntilDate  datetime,
					  @dtTimeStamp	 datetime,
					  @pnUserIdentityId int',
					  @pdtLetterDate,
					  @pdtUntilDate,
					  @dtTimeStamp,
					  @pnUserIdentityId
	Set @nRowCount=@nRowCount+@@Rowcount
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into ACTIVITYREQUEST (	CASEID,  WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, 
				  	LETTERNO, COVERINGLETTERNO, HOLDFLAG, LETTERDATE, DELIVERYID, 
					ACTIVITYTYPE, ACTIVITYCODE, PROCESSED, IDENTITYID, INSTRUCTOR, BILLPERCENTAGE )
	select  T.CASEID,  @dtTimeStamp, isnull(T.SQLUSER,SYSTEM_USER), T.PROGRAMID, T.ACTION, T.EVENTNO, T.CYCLE, 
		T.LETTERNO, T.COVERINGLETTERNO, T.HOLDFLAG, isnull(T.LETTERDATE,@pdtLetterDate), T.DELIVERYID, 
		T.ACTIVITYTYPE, T.ACTIVITYCODE, T.PROCESSED,T.IDENTITYID, T.WRITETONAME, T.BILLPERCENTAGE
	from #TEMPACTIVITYREQUEST T
	join #TEMPCASES TC	on (TC.CASEID=T.CASEID
				and TC.ERRORFOUND is null)"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pdtLetterDate	datetime,
					  @dtTimeStamp		datetime',
					  @pdtLetterDate,
					  @dtTimeStamp
	Set @nRowCount=@nRowCount+@@Rowcount
End

--------------------------------------------------------------------
-- The ACTIVITYREQUEST rows have now all been inserted with the
-- same WHENREQUESTED datetime stamp.  This will cause problems
-- for firms that have not changed their letter templates to use
-- ACTIVITYID as the unique identifier of the ACTIVITYREQUEST table.
-- To maintain backward compatibility the ACTIVITYREQUEST rows will
-- now be updated to make the WHENREQUESTED value unique.
--------------------------------------------------------------------
If  @ErrorCode=0
and @nRowCount>0
and @pbUniqueTimeRequired=1
Begin
	-- The Update will use the generated sequential ACTIVITYID offset back
	-- to a starting point of zero. Each different value will then be 
	-- multiplied by 3 ms which is the minimum unique
	set @sSQLString="
	update ACTIVITYREQUEST
	set WHENREQUESTED=dateadd(millisecond,3*(A.ACTIVITYID-A1.MINACTIVITYID),A.WHENREQUESTED)
	from ACTIVITYREQUEST A
	cross join (	select min(A.ACTIVITYID) as MINACTIVITYID
			from ACTIVITYREQUEST A
			where A.WHENREQUESTED=@dtTimeStamp) A1
	where WHENREQUESTED=@dtTimeStamp"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@dtTimeStamp		datetime',
					  @dtTimeStamp
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceInsertLetters',0,1,@sTimeStamp ) with NOWAIT
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceInsertLetters  to public
go
