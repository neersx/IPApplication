-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceInsertReminders
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceInsertReminders]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceInsertReminders.'
	drop procedure dbo.ip_PoliceInsertReminders
end
print '**** Creating procedure dbo.ip_PoliceInsertReminders...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceInsertReminders 
			@pdtFromDate	datetime,
			@pdtUntilDate	datetime,
			@pnDebugFlag	tinyint,
			@nRowCount	int  OUTPUT

as

-- PROCEDURE :	ip_PoliceInsertReminders
-- VERSION :	39	
-- DESCRIPTION:	Inserts reminders into the EMPLOYEEREMINDER table
-- CALLED BY :	ipu_Policing
-- 
-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 27/04/2001	MF			Procedure created
-- 15/10/2001	MF	7120		When inserting reminders, check the Status prior to any updates caused in this
--					Policing run.
-- 23/10/2001	MF	7140		When Reminders are being generated, any reminder whose date falls within the 
--					date range and does not have another Reminder for the same name within its 
--					lead time are to be generated.  Currently only the reminder with the highest
--					reminder number within the date range is being generated.
-- 31/10/2001	MF	7161		When using the CREATEDBYCRITERIA to get the Reminders make sure that the
--					Action is Open for the Case.
-- 5/11/2001	MF	7146		Modify the algorithm that calculates the next reminder date.
-- 16/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 3/01/2002	MF	7314		When Policing is generating reminders ensure that the Case Event has not 
--					already occurred or been satisfied by another event.
-- 3/04/2002	MF	7535		Make sure that reminders are only generated against due dates.
-- 6/05/2002	MF	7609		When a new due date is calculated and a reminder should have already been sent 
--					for that due date then the EmployeeReminder row should be inserted with a 
--					Reminder Date that is less than or equal to the current system date
-- 10/05/2002	MF	7645		The wrong Message was being used on reminders where the Due Date was in the past.
-- 08/11/2002	MF	8171		Allow email reminders to be generated with Hyperlink.  Change to record the CRITERIANO.
-- 02/04/2003	MF	8606		The alternate reminder message should be used from the Due Date onwards if the 
--					rule has elected to generate reminders this way.
-- 28 Jul 2003	MF		10	Standardise version number
-- 08 Apr 2004	MF	9881	11	The next reminder date was incorrectly being used on the first reminder produced.
--					The system date can safely be used to represent the date the Reminder was actually
--					generated.
-- 06 Jun 2005	MF	10720	12	Allow different units of time for frequency and stop time for Reminders.
-- 24 Jan 2006	MF	12223	13	Events may belong to multiple Actions and Reminder calculations may exist
--					for a different Action to the one that had the due date calculation.
-- 11 Apr 2006	MF	12549	14	Allow for Critical reminders to be sent immediately as the first reminder
--					generated when an EventDueDate is first calculated
-- 07 Jun 2006	MF	12788	15	Reminders should not be sent to names that have expired against the Case.
-- 18 Apr 2007	MF	14201	16	Reminders may now be directed to a Name determined using the RELATIONSHIP
--					code associated with the Reminder rule.
-- 21 May 2007		14775	17	Incorrect Next Police (DateRemind) being calculated when Lead Time Period is
--					years and frequency is months.
-- 29 May 2007	MF	14812	18	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 16 Apr 2008	MF	16249	19	During revisit of 14812 found a performance problem which was resolved
--					by splitting one Insert into #TEMPEMPLOYEEREMINDERS into 3 separate
--					inserts.
-- 14 May 2008	MF	16417	20	Ensure the Due Date inserted into the Reminder was calculated by the main
--					calculating criteria.
-- 11 Dec 2008	MF	17136	21	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Mar 2009	MF	17520	22	Ensure the lowest level of locking is in place to avoid possibility of deadlocks.
-- 25 Mar 2009	MF	18088	23	The criteriano of the EventControl rule is to be compared against the CriteriaNo for the 
--					CaseEvent taking into consideration that the Event may exist under multiple Criteria.
-- 11 Jan 2010	MF	18145	24	Data extracted from the database is allowed to be formatted and embedded within the
--					generated reminder message.
-- 12 Jan 2010	MF	17731	24	Reminders are now allowed to be generated with a future date if the reminder does not
--					already exist. This will allows users of the Reminder program to look forward to see what
--					reminders will become available.
-- 22 Jan 2010	MF	18395	25	Reminders to go to a name relationship not handling multiple related names. The Reminder should be sent
--					to each name determined from the relationship.
-- 05 Feb 2010	MF	18395	26	Revisit to allow a reminder to go both to a Staff/Signatory as well as related Names.
-- 23 Apr 2010	MF	18641	27	Revisit of 17731. The future dated reminder should also be issued if the due date has changed even if 
--					the reminder date had been calculated previously.
-- 18 Oct 2011	MF	18798	28	Use OPTION(MAXDOP 1) to manually set the Maximum Degrees of Parallelism to a single processor. This will allow
--					the database to be set to use parallelism but those complex problem queries with this option will then
--					revert to no parallelism in order to get enhanced performance.
-- 12 Nov 2012	MF	R12882	29	An Event whose due date has been changed to a date in the past should still generate the next future reminder as
--					long as the reminder is within the lead time of when the first reminder should be sent.
-- 12 Nov 2012	DV	R12818  30      Add a new table #TEMPEXTRACTEDCASEREMINDER to store the REMINDERTEXT for corresponding EXTRACTDATA
-- 28 Jan 2013	ASH	R12907	31	Extended length of ALERTMESSAGE columns.
-- 05 Jun 2013  AT	R12907	32	Revert all changes from RFC12907 due to introduced bug with multiple reminders.
-- 05 Jul 2013	vql	R13629	33	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 05 Dec 2014	MF	R42124	34	EmployeeReminder is currently only generated if the Due Date has changed or previously there was no DATEREMIND
--					against the CaseEvent.  We should also consider a newly calculated reminder date that is earlier than a the 
--					previously existing date.
-- 06 Jan 2015	MF	R42807	35	If a future reminder falls on or before the Until Date for which Policing is being run then it should be allowed
--					to deliver the reminder via email if it has been configured that way.
-- 22 Apr 2015	MF	45629	36	Provide ability for multiple NameTypes to be defined as recipients of reminders. New EXTENDEDNAMETYPE column now
--					exists in REMINDERS table. This contains semicolon separated list of name types which need to be tokenised to
--					separate into separate NameTypes.
-- 18 Oct 2016	MF	69608	37	Reminder messages defined with text longer than 254 characters are being truncated.
-- 14 Nov 2018  AV	DR-45358 38	Date conversion errors when creating cases and opening names in Chinese DB
-- 10 Apr 2019	MF	DR-48142 39	When a reminder had a lead time configured as YEARS and a frequency in MONTHS the reminder is not always generated.

set nocount on

Create Table #TEMPEXTRACTEDSTRINGS	(
		EXTRACTDATA	varchar(30)	collate database_default not null PRIMARY KEY,
		RELATIVECYCLE	tinyint		null,
		EVENTNO		int		null )		

Create Table #TEMPEXTRACTEDCASEREMINDER( 
		EXTRACTDATA	varchar(30)	collate database_default not null,
		CASEID		int		not null,
		REMINDERTEXT	nvarchar(30)	collate database_default null)	

Create Table #TEMPREMINDERS (
		SEQUENCENO	int		identity(1,1),
		CRITERIANO	int		not null,
		EVENTNO		int		not null,
		REMINDERNO	int		not null, 
		EXTENDNAMETYPE	nvarchar(254)	collate database_default null)

Create Table #TEMPREMINDERNAMETYPES (
		CRITERIANO	int		not null,
		EVENTNO		int		not null,
		REMINDERNO	int		not null,
		NAMETYPE	nvarchar(3)	collate database_default not null )

Declare	@ErrorCode		int,
	@nCriticalStaff		int,
	@nUpdateCount		int,
	@nRowNumber		int,
	@nCriteriaNo		int,
	@nEventNo		int,
	@nReminderNo		int,
	@nExtractCount		smallint,
	@nDateFormat		tinyint,
	@sReminderMessage	nvarchar(max),
	@sExtendedNameType	nvarchar(254),
	@sSQLString		nvarchar(max)

-- Ensure the lowest level of locking is in place		
set transaction isolation level read uncommitted

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode     = 0
Set @nExtractCount = 0

-------------------------------------------------------
-- Load the list of possible reminders to be produced
-- so that any extended name types can be separated 
-- out.
-- Those reminders with a non null EXTENDEDNAMETYPE 
-- will be loaded first to make looping through these
-- rows more efficient.
-------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPREMINDERS(CRITERIANO, EVENTNO, REMINDERNO, EXTENDNAMETYPE)
	Select distinct R.CRITERIANO, R.EVENTNO, R.REMINDERNO, R.EXTENDEDNAMETYPE
	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO)
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	
	where  OA.POLICEEVENTS =1
	and   (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and   (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and   (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and  ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))
	
	and (  R.EMPLOYEEFLAG =1
	 OR    R.SIGNATORYFLAG=1
	 OR    R.NAMETYPE         is not null
	 OR    R.EXTENDEDNAMETYPE is not null)
	
	and (  T.DATEREMIND is null
	 OR    T.DATEREMIND between @pdtFromDate and @pdtUntilDate
	 OR    T.OLDEVENTDUEDATE<>T.NEWEVENTDUEDATE 
	 OR    T.DATEREMIND      >T.NEWDATEREMIND)
	       
	order by R.EXTENDEDNAMETYPE desc, R.CRITERIANO, R.EVENTNO, R.REMINDERNO"

	Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@pdtFromDate		datetime,
				  @pdtUntilDate		datetime',
				  @pdtFromDate =@pdtFromDate,
				  @pdtUntilDate=@pdtUntilDate
	
	Set @nRowCount=@@ROWCOUNT
End

-------------------------------------------------------
-- For each reminder definition to be sent, extract the
-- possible Name Types that will be recipients of that
-- reminder.
-------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPREMINDERNAMETYPES(CRITERIANO, EVENTNO, REMINDERNO, NAMETYPE)
	Select distinct R.CRITERIANO, R.EVENTNO, R.REMINDERNO, 'EMP'
	from #TEMPREMINDERS T
	join REMINDERS R on (R.CRITERIANO=T.CRITERIANO
			 and R.EVENTNO   =T.EVENTNO
			 and R.REMINDERNO=T.REMINDERNO)
	where R.EMPLOYEEFLAG=1
	UNION
	Select distinct R.CRITERIANO, R.EVENTNO, R.REMINDERNO, 'SIG'
	from #TEMPREMINDERS T
	join REMINDERS R on (R.CRITERIANO=T.CRITERIANO
			 and R.EVENTNO   =T.EVENTNO
			 and R.REMINDERNO=T.REMINDERNO)
	where R.SIGNATORYFLAG=1
	UNION
	Select distinct R.CRITERIANO, R.EVENTNO, R.REMINDERNO, R.NAMETYPE
	from #TEMPREMINDERS T
	join REMINDERS R on (R.CRITERIANO=T.CRITERIANO
			 and R.EVENTNO   =T.EVENTNO
			 and R.REMINDERNO=T.REMINDERNO)
	where R.NAMETYPE is not null"

	Exec @ErrorCode=sp_executesql @sSQLString
	
End

Set @nRowNumber=1

While @nRowNumber<=@nRowCount
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select	@sExtendedNameType=R.EXTENDEDNAMETYPE,
		@nCriteriaNo      =R.CRITERIANO,
		@nEventNo	  =R.EVENTNO,
		@nReminderNo	  =R.REMINDERNO
	from #TEMPREMINDERS T
	join REMINDERS R on (R.CRITERIANO=T.CRITERIANO
			 and R.EVENTNO   =T.EVENTNO
			 and R.REMINDERNO=T.REMINDERNO)
	where R.EXTENDEDNAMETYPE is not null
	and T.SEQUENCENO=@nRowNumber"

	Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@sExtendedNameType	nvarchar(254)		output,
				  @nCriteriaNo		int			output,
				  @nEventNo		int			output,
				  @nReminderNo		int			output,
				  @nRowNumber		int',
				  @sExtendedNameType	=@sExtendedNameType	output,
				  @nCriteriaNo		=@nCriteriaNo		output,
				  @nEventNo		=@nEventNo		output,
				  @nReminderNo		=@nReminderNo		output,
				  @nRowNumber		=@nRowNumber
				  
	If @sExtendedNameType is null
	Begin
		----------------------------
		-- Stop looping when no 
		-- ExtendedNameType is found
		----------------------------
		Set @nRowNumber=@nRowCount+1
	End
	Else Begin		
		Set @nRowNumber=@nRowNumber+1
		
		
		----------------------------
		-- Separate the extended 
		-- name types into separate
		-- name type rows.
		----------------------------
		
		Set @sSQLString="
		Insert into #TEMPREMINDERNAMETYPES(CRITERIANO, EVENTNO, REMINDERNO, NAMETYPE)
		Select distinct @nCriteriaNo, @nEventNo, @nReminderNo, NT.NAMETYPE
		from dbo.fn_Tokenise(@sExtendedNameType, ';') T
		join NAMETYPE NT on (NT.NAMETYPE=T.Parameter)
		left join #TEMPREMINDERNAMETYPES R on (R.CRITERIANO=@nCriteriaNo
						   and R.EVENTNO   =@nEventNo
						   and R.REMINDERNO=@nReminderNo
						   and R.NAMETYPE  =NT.NAMETYPE)
		where R.NAMETYPE is null"

		Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@sExtendedNameType	nvarchar(254),
				  @nCriteriaNo		int,
				  @nEventNo		int,
				  @nReminderNo		int',
				  @sExtendedNameType	=@sExtendedNameType,
				  @nCriteriaNo		=@nCriteriaNo,
				  @nEventNo		=@nEventNo,
				  @nReminderNo		=@nReminderNo
				  
		set @sExtendedNameType = NULL
	End 
End

-- Get the NameNo used for delivering Critical Reminders

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @nCriticalStaff=S.COLINTEGER
	from SITECONTROL S
	where S.CONTROLID='Critical Reminder'"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCriticalStaff	int		OUTPUT',
				  @nCriticalStaff=@nCriticalStaff	OUTPUT
End
---------------------------------------------
-- Insert the EMPLOYEEREMINDER using the last
-- reminder that would have been generated
---------------------------------------------
if @ErrorCode=0
Begin
	----------------------------------------
	-- The reminder recipient is determined
	-- from a name type associated with Case
	----------------------------------------
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO,  CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION, SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE)
	select  distinct CN.NAMENO, T.CASEID, T.EVENTNO, T.CYCLE, R.CRITERIANO, T.NEWEVENTDUEDATE,  
		0, 0, 0, getdate(), EC.EVENTDESCRIPTION, R.SENDELECTRONICALLY, R.EMAILSUBJECT, OA.ACTION, 
		OA.PROPERTYTYPE, OA.COUNTRYCODE, 
		CASE WHEN(CN.NAMETYPE in ('EMP','SIG')) THEN NULL 
			ELSE R.RELATIONSHIP 
		END,
		-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if the DUE DATE is still in the
		-- future and use the second Reminder message if the DUE DATE has already occurred.
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))>254 OR LEN(cast(R.MESSAGE2 as nvarchar(max)))>254) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Handle messages that exceed 254 characters
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))<255 AND LEN(cast(R.MESSAGE2 as nvarchar(max)))<255) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		convert(nvarchar, getdate(),112)

	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO
				and R.REMINDERNO=T.REMINDERTOSEND)
	left join CASENAME CN	on ( CN.CASEID   =T.CASEID
				and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
				and((CN.NAMETYPE ='EMP' and R.EMPLOYEEFLAG=1)
				 or (CN.NAMETYPE ='SIG' and R.SIGNATORYFLAG=1)
				 or (CN.NAMETYPE =R.NAMETYPE)))
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	where  OA.POLICEEVENTS =1
	and    CN.NAMENO is not null
	and    T.DATEREMIND is null
	and   (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and   (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and   (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and  ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))"

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @nRowCount=@@Rowcount
End

if @ErrorCode=0
Begin
	----------------------------------------
	-- The reminder recipient is specific
	-- Name on the reminder rule
	----------------------------------------
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO,  CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION, SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE,  REMINDERDATE)
	select  R.REMINDEMPLOYEE, T.CASEID, T.EVENTNO, T.CYCLE, R.CRITERIANO, T.NEWEVENTDUEDATE,  
		0, 0, 0, getdate(), EC.EVENTDESCRIPTION, R.SENDELECTRONICALLY, R.EMAILSUBJECT, OA.ACTION, 
		OA.PROPERTYTYPE, OA.COUNTRYCODE,R.RELATIONSHIP,
		-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if the DUE DATE is still in the
		-- future and use the second Reminder message if the DUE DATE has already occurred.
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))>254 OR LEN(cast(R.MESSAGE2 as nvarchar(max)))>254) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Handle messages that exceed 254 characters
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))<255 AND LEN(cast(R.MESSAGE2 as nvarchar(max)))<255) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		convert(nvarchar, getdate(),112)

	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO
				and R.REMINDERNO=T.REMINDERTOSEND)
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join #TEMPEMPLOYEEREMINDER TR
				on (TR.NAMENO=R.REMINDEMPLOYEE
				and TR.CASEID=T.CASEID
				and TR.EVENTNO=T.EVENTNO
				and TR.CYCLENO=T.CYCLE
				and TR.REFERENCE is null
				and TR.SEQUENCENO=0)
	where  OA.POLICEEVENTS =1
	and    R.REMINDEMPLOYEE is not null
	and    TR.NAMENO is null
	and    T.DATEREMIND is null
	and   (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and   (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and   (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and  ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))"

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @nRowCount=@nRowCount+@@Rowcount
End

if @ErrorCode=0
and @nCriticalStaff is not null
Begin
	------------------------------------------
	-- The reminder recipient is the Name
	-- specified to receive Critical Reminders
	------------------------------------------
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO,  CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION, SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE)
	select @nCriticalStaff, T.CASEID, T.EVENTNO, T.CYCLE, R.CRITERIANO, T.NEWEVENTDUEDATE,  
		0, 0, 0, getdate(), EC.EVENTDESCRIPTION, R.SENDELECTRONICALLY, R.EMAILSUBJECT, OA.ACTION, 
		OA.PROPERTYTYPE, OA.COUNTRYCODE, NULL,

		-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if the DUE DATE is still in the
		-- future and use the second Reminder message if the DUE DATE has already occurred.
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))>254 OR LEN(cast(R.MESSAGE2 as nvarchar(max)))>254) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Handle messages that exceed 254 characters
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))<255 AND LEN(cast(R.MESSAGE2 as nvarchar(max)))<255) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		convert(nvarchar, getdate(),112)

	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO
				and R.REMINDERNO=T.REMINDERTOSEND)
	     join NAME N	on (N.NAMENO=@nCriticalStaff)
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join #TEMPEMPLOYEEREMINDER TR
				on (TR.NAMENO=@nCriticalStaff
				and TR.CASEID=T.CASEID
				and TR.EVENTNO=T.EVENTNO
				and TR.CYCLENO=T.CYCLE
				and TR.REFERENCE is null
				and TR.SEQUENCENO=0)
	where  OA.POLICEEVENTS=1
	and    R.CRITICALFLAG =1
	and    TR.NAMENO is null
	and    T.DATEREMIND is null
	and   (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and   (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and   (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and  ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCriticalStaff	int',
				  @nCriticalStaff=@nCriticalStaff

	Set @nRowCount=@nRowCount+@@Rowcount
End

-- If the original DATEREMIND falls within the date range for which Policing is being run then determine
-- what Reminders would fall within the date range and insert them into EMPLOYEEREMINDER
-- This has been split into 3 separate INSERT statements because of a performance problem
-- and because UNION cannot be used as the MESSAGE columns are ntext.

if @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO, CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION,  SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE)
	select distinct CN.NAMENO,  T.CASEID, T.EVENTNO, T.CYCLE, R.CRITERIANO, T.NEWEVENTDUEDATE, 
		0, 0, 0, getdate(), EC.EVENTDESCRIPTION, R.SENDELECTRONICALLY, R.EMAILSUBJECT, OA.ACTION, 
		OA.PROPERTYTYPE, OA.COUNTRYCODE,
		CASE WHEN(CN.NAMETYPE in ('EMP','SIG')) THEN NULL ELSE R.RELATIONSHIP END,
		-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if the DUE DATE is still in the
		-- future and use the second Reminder message if the DUE DATE has already occurred.
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))>254 OR LEN(cast(R.MESSAGE2 as nvarchar(max)))>254) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Handle messages that exceed 254 characters
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))<255 AND LEN(cast(R.MESSAGE2 as nvarchar(max)))<255) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Calculate the date that this reminder was supposed to be sent
		CASE WHEN(CASE R.PERIODTYPE	
				WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
		   	 END ) >= T.DATEREMIND
									-- If the Lead Time date matches the	
									-- next reminder date then use it as the
									-- Reminder date			
		THEN 	CASE R.PERIODTYPE	
				WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
		   	END
									-- If the Lead Time is not in the 	
									-- future then the Reminder date will be
									-- calculated from the Lead Time date by
									-- using the Frequency to get a future  
									-- date.				
		ELSE	CASE WHEN (R.FREQUENCY=0 OR R.FREQUENCY is NULL)
			     THEN NULL
			     ELSE
				CASE
				  ---------------------------------------------------
				  -- Lead Time in DAYS
				  ---------------------------------------------------
				  WHEN(R.PERIODTYPE='D' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
	
				  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
				  ---------------------------------------------------
				  -- Lead Time in WEEKS
				  ---------------------------------------------------
				  -- Note that the DATEDIFF function is calculated in Days when the Period
			   	  -- Type is WEEK and then divided by an additional factor of 7 to bring it
				  -- back to a number of weeks.  This is to avoid the problems caused by the
				  -- way DATEDIFF considers a week as being a change from Saturday to
				  -- Sunday rather than a 7 day period.
				  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='W' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
	
				  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
				  ---------------------------------------------------
				  -- Lead Time in MONTHS
				  ---------------------------------------------------
				  -- When calculating the reminder date by incrementing in months or years we need
			  	  -- to check to see if the calculated date is in the future.  If not then increment it
				  -- by a further value of the Frequency
				  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='M' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
					 END
	
				  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
				  ---------------------------------------------------
				  -- Lead Time in YEARS
				  ---------------------------------------------------
				  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R.PERIODTYPE='Y' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
					 END
				END
			END
		END
	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO)
	     join #TEMPREMINDERNAMETYPES NT
				on (NT.CRITERIANO=R.CRITERIANO
				and NT.EVENTNO   =R.EVENTNO
				and NT.REMINDERNO=R.REMINDERNO)
	     join CASENAME CN	on ( CN.CASEID   =T.CASEID
				and  CN.NAMETYPE =NT.NAMETYPE
				and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	where  OA.POLICEEVENTS =1
	and   (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and   (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and   T.DATEREMIND between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"'
	and  (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))

									-- Return all of the available reminders
	and R.REMINDERNO in
	(select R1.REMINDERNO
	 from REMINDERS R1
	 where R1.CRITERIANO=R.CRITERIANO
	 and   R1.EVENTNO   =R.EVENTNO
	 and   R1.LETTERNO is null
									-- Ensure that a later reminder does not
									-- exist that is already on or past its	
									-- lead time and would generate 	
									-- reminders for at least some of the 	
									-- same recipients.				
	 and not exists 
	      (	select * from REMINDERS R2
		where R2.CRITERIANO=R1.CRITERIANO
		and   R2.EVENTNO   =R1.EVENTNO
		and   R2.LETTERNO is null
		and   R2.REMINDERNO>R1.REMINDERNO
		and ((R2.EMPLOYEEFLAG=1 and R1.EMPLOYEEFLAG=1) OR (R2.SIGNATORYFLAG=1 and R2.SIGNATORYFLAG=1) OR (R2.NAMETYPE=R1.NAMETYPE))
		and   CASE R2.PERIODTYPE
				WHEN 'D' THEN dateadd (day,  -1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
		      END  <= T.DATEREMIND )

									-- Only return reminders that are eligible 
									-- to be produced within the date range
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
		END) between T.DATEREMIND and '"+convert(varchar,@pdtUntilDate)+"') OPTION (MAXDOP 1)"

	Exec(@sSQLString)

	Select	@ErrorCode=@@Error,
		@nRowCount=CASE WHEN(@nRowCount=0) Then @@Rowcount Else @nRowCount End
End

if @ErrorCode=0
and @nCriticalStaff is not null
Begin
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO, CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION,  SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE)
	select distinct N.NAMENO, T.CASEID, T.EVENTNO, T.CYCLE, R.CRITERIANO, T.NEWEVENTDUEDATE, 
	       	0, 0, 0, getdate(), EC.EVENTDESCRIPTION, R.SENDELECTRONICALLY, R.EMAILSUBJECT, OA.ACTION, 
		OA.PROPERTYTYPE, OA.COUNTRYCODE, NULL,

		-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if the DUE DATE is still in the
		-- future and use the second Reminder message if the DUE DATE has already occurred.
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))>254 OR LEN(cast(R.MESSAGE2 as nvarchar(max)))>254) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Handle messages that exceed 254 characters
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))<255 AND LEN(cast(R.MESSAGE2 as nvarchar(max)))<255) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Calculate the date that this reminder was supposed to be sent
		CASE WHEN(CASE R.PERIODTYPE	
				WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
		   	 END ) >= T.DATEREMIND
									-- If the Lead Time date matches the	
									-- next reminder date then use it as the
									-- Reminder date			
		THEN 	CASE R.PERIODTYPE	
				WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
		   	END
									-- If the Lead Time is not in the 	
									-- future then the Reminder date will be
									-- calculated from the Lead Time date by
									-- using the Frequency to get a future  
									-- date.				
		ELSE	CASE WHEN (R.FREQUENCY=0 OR R.FREQUENCY is NULL)
			     THEN NULL
			     ELSE
				CASE
				  ---------------------------------------------------
				  -- Lead Time in DAYS
				  ---------------------------------------------------
				  WHEN(R.PERIODTYPE='D' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
	
				  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
				  ---------------------------------------------------
				  -- Lead Time in WEEKS
				  ---------------------------------------------------
				  -- Note that the DATEDIFF function is calculated in Days when the Period
			   	  -- Type is WEEK and then divided by an additional factor of 7 to bring it
				  -- back to a number of weeks.  This is to avoid the problems caused by the
				  -- way DATEDIFF considers a week as being a change from Saturday to
				  -- Sunday rather than a 7 day period.
				  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='W' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
	
				  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
				  ---------------------------------------------------
				  -- Lead Time in MONTHS
				  ---------------------------------------------------
				  -- When calculating the reminder date by incrementing in months or years we need
			  	  -- to check to see if the calculated date is in the future.  If not then increment it
				  -- by a further value of the Frequency
				  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='M' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
					 END
	
				  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
				  ---------------------------------------------------
				  -- Lead Time in YEARS
				  ---------------------------------------------------
				  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R.PERIODTYPE='Y' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
					 END
				END
			END
		END
	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO)
	     join NAME N	on (N.NAMENO ="+convert(varchar,@nCriticalStaff)+")
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	
	where OA.POLICEEVENTS=1
	and   R.CRITICALFLAG=1
	and  (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and  (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and   T.DATEREMIND between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"'
	and  (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))

									-- Return all of the eligible reminders
	and R.REMINDERNO in
	(select R1.REMINDERNO
	 from REMINDERS R1
	 where R1.CRITERIANO=R.CRITERIANO
	 and   R1.EVENTNO   =R.EVENTNO
	 and   R1.LETTERNO is null
	 and   R1.CRITICALFLAG=1
									-- Ensure that a later reminder does not
									-- exist that is already on or past its	
									-- lead time and would generate 	
									-- reminders for at least some of the 	
									-- same recipients.				
	 and not exists 
	      (	select * from REMINDERS R2
		where R2.CRITERIANO=R1.CRITERIANO
		and   R2.EVENTNO   =R1.EVENTNO
		and   R2.LETTERNO is null
		and   R2.CRITICALFLAG=1
		and   R2.REMINDERNO>R1.REMINDERNO
		and   CASE R2.PERIODTYPE
				WHEN 'D' THEN dateadd (day,  -1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
		      END  <= T.DATEREMIND )

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
		END) between T.DATEREMIND and '"+convert(varchar,@pdtUntilDate)+"') OPTION (MAXDOP 1)"

	Exec(@sSQLString)

	Select	@ErrorCode=@@Error,
		@nRowCount=CASE WHEN(@nRowCount=0) Then @@Rowcount Else @nRowCount End
End

if @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO, CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION,  SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE)
	select distinct R.REMINDEMPLOYEE,  T.CASEID, T.EVENTNO, T.CYCLE, R.CRITERIANO, T.NEWEVENTDUEDATE, 
		0, 0, 0, getdate(), EC.EVENTDESCRIPTION, R.SENDELECTRONICALLY, R.EMAILSUBJECT, OA.ACTION, 
		OA.PROPERTYTYPE, OA.COUNTRYCODE, R.RELATIONSHIP,

		-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if the DUE DATE is still in the
		-- future and use the second Reminder message if the DUE DATE has already occurred.
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))>254 OR LEN(cast(R.MESSAGE2 as nvarchar(max)))>254) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Handle messages that exceed 254 characters
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))<255 AND LEN(cast(R.MESSAGE2 as nvarchar(max)))<255) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=convert(nvarchar,getdate(),112))
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Calculate the date that this reminder was supposed to be sent
		CASE WHEN(CASE R.PERIODTYPE	
				WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
		   	 END ) >= T.DATEREMIND
									-- If the Lead Time date matches the	
									-- next reminder date then use it as the
									-- Reminder date			
		THEN 	CASE R.PERIODTYPE	
				WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
		   	END
									-- If the Lead Time is not in the 	
									-- future then the Reminder date will be
									-- calculated from the Lead Time date by
									-- using the Frequency to get a future  
									-- date.				
		ELSE	CASE WHEN (R.FREQUENCY=0 OR R.FREQUENCY is NULL)
			     THEN NULL
			     ELSE
				CASE
				  ---------------------------------------------------
				  -- Lead Time in DAYS
				  ---------------------------------------------------
				  WHEN(R.PERIODTYPE='D' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
	
				  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
				  ---------------------------------------------------
				  -- Lead Time in WEEKS
				  ---------------------------------------------------
				  -- Note that the DATEDIFF function is calculated in Days when the Period
			   	  -- Type is WEEK and then divided by an additional factor of 7 to bring it
				  -- back to a number of weeks.  This is to avoid the problems caused by the
				  -- way DATEDIFF considers a week as being a change from Saturday to
				  -- Sunday rather than a 7 day period.
				  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='W' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
	
				  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
				  ---------------------------------------------------
				  -- Lead Time in MONTHS
				  ---------------------------------------------------
				  -- When calculating the reminder date by incrementing in months or years we need
			  	  -- to check to see if the calculated date is in the future.  If not then increment it
				  -- by a further value of the Frequency
				  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='M' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
					 END
	
				  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
				  ---------------------------------------------------
				  -- Lead Time in YEARS
				  ---------------------------------------------------
				  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >=T.DATEREMIND
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R.PERIODTYPE='Y' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >=T.DATEREMIND
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),dateadd(day,-1,T.DATEREMIND))/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
					 END
				END
			END
		END
	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO)
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	
	where OA.POLICEEVENTS=1
	and   R.REMINDEMPLOYEE is not null
	and  (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and  (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and   T.DATEREMIND between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"'
	and  (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))

									-- Return all of the available reminders
	and R.REMINDERNO in
	(select R1.REMINDERNO
	 from REMINDERS R1
	 where R1.CRITERIANO=R.CRITERIANO
	 and   R1.EVENTNO   =R.EVENTNO
	 and   R1.LETTERNO is null
	 and   R1.REMINDEMPLOYEE is not null
									-- Ensure that a later reminder does not
									-- exist that is already on or past its	
									-- lead time and would generate 	
									-- reminders for at least some of the 	
									-- same recipients.				
	 and not exists 
	      (	select * from REMINDERS R2
		where R2.CRITERIANO=R1.CRITERIANO
		and   R2.EVENTNO   =R1.EVENTNO
		and   R2.LETTERNO is null
		and   R2.REMINDERNO>R1.REMINDERNO
		and   R2.REMINDEMPLOYEE=R1.REMINDEMPLOYEE
		and   CASE R2.PERIODTYPE
				WHEN 'D' THEN dateadd (day,  -1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R2.LEADTIME, T.NEWEVENTDUEDATE)
		      END <= T.DATEREMIND )

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
		END) between T.DATEREMIND and '"+convert(varchar,@pdtUntilDate)+"') OPTION (MAXDOP 1)"

	Exec(@sSQLString)

	Select	@ErrorCode=@@Error,
		@nRowCount=CASE WHEN(@nRowCount=0) Then @@Rowcount Else @nRowCount End
End

--------------------------------------------
-- SQA17731
-- Where the first reminder to be sent is as
-- at a future date, a Reminder row will now
-- be inserted with that future date.
-- This will allow users to look at what 
-- reminders are coming up into the future.
-- NOTE : These reminders will not be marked
--        to generate as emailed reminders
--	  unless the reminder date falls on
--	  or before the Until Date for which
--	  Policing is being run.
--------------------------------------------
if @ErrorCode=0
Begin
	----------------------------------------
	-- The reminder recipient is determined
	-- from a name type associated with Case
	----------------------------------------
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO, CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION,  SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE)
	select distinct CN.NAMENO,  T.CASEID, T.EVENTNO, T.CYCLE, R.CRITERIANO, T.NEWEVENTDUEDATE, 
		0, 0, 0, getdate(), EC.EVENTDESCRIPTION, 
		CASE WHEN(T.NEWDATEREMIND<=@pdtUntilDate) THEN R.SENDELECTRONICALLY ELSE NULL END, 
		CASE WHEN(T.NEWDATEREMIND<=@pdtUntilDate) THEN R.EMAILSUBJECT       ELSE NULL END,
		OA.ACTION, 
		OA.PROPERTYTYPE, OA.COUNTRYCODE, 
		CASE WHEN(CN.NAMETYPE in ('EMP','SIG')) THEN NULL ELSE R.RELATIONSHIP END,
		-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if the DUE DATE is still in the
		-- future and use the second Reminder message if the DUE DATE has already occurred.
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))>254 OR LEN(cast(R.MESSAGE2 as nvarchar(max)))>254) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=T.NEWDATEREMIND)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Handle messages that exceed 254 characters
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))<255 AND LEN(cast(R.MESSAGE2 as nvarchar(max)))<255) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=T.NEWDATEREMIND)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Use the previously calculated future reminder date
		T.NEWDATEREMIND
	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO)
	     join #TEMPREMINDERNAMETYPES NT
				on (NT.CRITERIANO=R.CRITERIANO
				and NT.EVENTNO   =R.EVENTNO
				and NT.REMINDERNO=R.REMINDERNO)
	     join CASENAME CN	on ( CN.CASEID   =T.CASEID
				and  CN.NAMETYPE =NT.NAMETYPE
				and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	where  OA.POLICEEVENTS =1
	and   (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and   (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and  (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))
	and  (T.DATEREMIND is null or (T.OLDEVENTDUEDATE<>T.NEWEVENTDUEDATE) or T.DATEREMIND>T.NEWDATEREMIND) -- SQA18641 first reminder or due date has changed
	and T.REMINDERTOSEND is null
	and T.NEWDATEREMIND between @pdtUntilDate and dateadd(year, 10, @pdtUntilDate)
	and T.NEWDATEREMIND>=CASE R.PERIODTYPE					-- RFC12882 changed the = into >=
				WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
			    END"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pdtUntilDate		datetime',
				  @pdtUntilDate=@pdtUntilDate

	Set @nRowCount=CASE WHEN(@nRowCount=0) Then @@Rowcount Else @nRowCount End
End

if @ErrorCode=0
Begin
	----------------------------------------
	-- The reminder recipient is specific
	-- Name on the reminder rule
	----------------------------------------
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO, CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION,  SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE,  REMINDERDATE)
	select distinct R.REMINDEMPLOYEE,  T.CASEID, T.EVENTNO, T.CYCLE, R.CRITERIANO, T.NEWEVENTDUEDATE, 
		0, 0, 0, getdate(), EC.EVENTDESCRIPTION, 
		CASE WHEN(T.NEWDATEREMIND<=@pdtUntilDate) THEN R.SENDELECTRONICALLY ELSE NULL END, 
		CASE WHEN(T.NEWDATEREMIND<=@pdtUntilDate) THEN R.EMAILSUBJECT       ELSE NULL END,
		OA.ACTION, 
		OA.PROPERTYTYPE, OA.COUNTRYCODE, R.RELATIONSHIP,

		-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if the DUE DATE is still in the
		-- future and use the second Reminder message if the DUE DATE has already occurred.
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))>254 OR LEN(cast(R.MESSAGE2 as nvarchar(max)))>254) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=T.NEWDATEREMIND)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Handle messages that exceed 254 characters
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))<255 AND LEN(cast(R.MESSAGE2 as nvarchar(max)))<255) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=T.NEWDATEREMIND)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Use the previously calculated future reminder date
		T.NEWDATEREMIND
	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO)
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join #TEMPEMPLOYEEREMINDER TR
				on (TR.NAMENO=R.REMINDEMPLOYEE
				and TR.CASEID=T.CASEID
				and TR.EVENTNO=T.EVENTNO
				and TR.CYCLENO=T.CYCLE
				and TR.REFERENCE is null
				and TR.SEQUENCENO=0)
	where  OA.POLICEEVENTS =1
	and    R.REMINDEMPLOYEE is not null
	and    TR.NAMENO is null
	and   (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and   (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and  (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))
	and  (T.DATEREMIND is null or (T.OLDEVENTDUEDATE<>T.NEWEVENTDUEDATE) or T.DATEREMIND>T.NEWDATEREMIND) -- SQA18641 first reminder or due date has changed
	and T.REMINDERTOSEND is null
	and T.NEWDATEREMIND between @pdtUntilDate and dateadd(year, 10, @pdtUntilDate)
	and T.NEWDATEREMIND>=CASE R.PERIODTYPE					-- RFC12882 changed the = into >=	
				WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
			    END"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pdtUntilDate		datetime',
				  @pdtUntilDate=@pdtUntilDate

	Set @nRowCount=CASE WHEN(@nRowCount=0) Then @@Rowcount Else @nRowCount End
End

if @ErrorCode=0
and @nCriticalStaff is not null
Begin
	------------------------------------------
	-- The reminder recipient is the Name
	-- specified to receive Critical Reminders
	------------------------------------------
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO, CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION,  SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE)
	select  @nCriticalStaff,  T.CASEID, T.EVENTNO, T.CYCLE, R.CRITERIANO, T.NEWEVENTDUEDATE, 
		0, 0, 0, getdate(), EC.EVENTDESCRIPTION, 
		CASE WHEN(T.NEWDATEREMIND<=@pdtUntilDate) THEN R.SENDELECTRONICALLY ELSE NULL END, 
		CASE WHEN(T.NEWDATEREMIND<=@pdtUntilDate) THEN R.EMAILSUBJECT       ELSE NULL END,
		OA.ACTION, 
		OA.PROPERTYTYPE, OA.COUNTRYCODE, NULL,

		-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if the DUE DATE is still in the
		-- future and use the second Reminder message if the DUE DATE has already occurred.
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))>254 OR LEN(cast(R.MESSAGE2 as nvarchar(max)))>254) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=T.NEWDATEREMIND)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(254),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(254),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Handle messages that exceed 254 characters
		CASE WHEN(LEN(cast(R.MESSAGE1 as nvarchar(max)))<255 AND LEN(cast(R.MESSAGE2 as nvarchar(max)))<255) THEN NULL
		     WHEN(R.USEMESSAGE1=1)
			-- If the USEMESSAGE1 is set to 1 then use the first Reminder message if 
			-- the DUE DATE is still in the future and use the second Reminder message 
			-- if the DUE DATE has already occurred.
			THEN CASE WHEN (T.NEWEVENTDUEDATE<=T.NEWDATEREMIND)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
			-- If the USEMESSAGE2 is set to 1 then use the second Reminder message.   
			-- This is determined by the Event used in the due date calculation.
			ELSE CASE WHEN (T.USEMESSAGE2FLAG=1)
					THEN isnull(convert(nvarchar(max),R.MESSAGE2),'** Reminder message not defined - report to system administrator ***')
					ELSE isnull(convert(nvarchar(max),R.MESSAGE1),'** Reminder message not defined - report to system administrator ***')
			     END
		END,
		-- Use the previously calculated future reminder date
		T.NEWDATEREMIND
	from #TEMPOPENACTION OA
	     join EVENTCONTROL EC
				on (EC.CRITERIANO=OA.NEWCRITERIANO)
	     join #TEMPCASEEVENT T
				on (T.CASEID=OA.CASEID
				and T.EVENTNO=EC.EVENTNO
				and EC.CRITERIANO=isnull(T.CRITERIANO,T.CREATEDBYCRITERIA))
	     join REMINDERS R 	on (R.CRITERIANO=OA.NEWCRITERIANO
				and R.EVENTNO   =T.EVENTNO)
	     join CASES TC	on (TC.CASEID=T.CASEID)
	left join PROPERTY P	on (P.CASEID =T.CASEID)
	     join ACTIONS A	on (A.ACTION =OA.ACTION)
	left join STATUS S	on (S.STATUSCODE=TC.STATUSCODE)
	left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join #TEMPEMPLOYEEREMINDER TR
				on (TR.NAMENO=@nCriticalStaff
				and TR.CASEID=T.CASEID
				and TR.EVENTNO=T.EVENTNO
				and TR.CYCLENO=T.CYCLE
				and TR.REFERENCE is null
				and TR.SEQUENCENO=0)
	where  OA.POLICEEVENTS =1
	and     R.CRITICALFLAG =1
	and    TR.NAMENO is null
	and   (T.SUPPRESSREMINDERS=0 or T.SUPPRESSREMINDERS is null)
	and   (T.OCCURREDFLAG = 0    or T.OCCURREDFLAG      is null)
	and  (S.REMINDERSALLOWED=1 OR S.REMINDERSALLOWED is null)
	and ((A.ACTIONTYPEFLAG=1  and (S1.REMINDERSALLOWED is null OR S1.REMINDERSALLOWED =1)) OR (A.ACTIONTYPEFLAG<>1 or A.ACTIONTYPEFLAG is null))
	and  (T.DATEREMIND is null or (T.OLDEVENTDUEDATE<>T.NEWEVENTDUEDATE) or T.DATEREMIND>T.NEWDATEREMIND) -- SQA18641 first reminder or due date has changed
	and T.REMINDERTOSEND is null
	and T.NEWDATEREMIND between @pdtUntilDate and dateadd(year, 10, @pdtUntilDate)
	and T.NEWDATEREMIND>=CASE R.PERIODTYPE					-- RFC12882 changed the = into >=	
				WHEN 'D' THEN dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE)
			    END"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pdtUntilDate		datetime,
				  @nCriticalStaff	int',
				  @pdtUntilDate  =@pdtUntilDate,
				  @nCriticalStaff=@nCriticalStaff

	Set @nRowCount=CASE WHEN(@nRowCount=0) Then @@Rowcount Else @nRowCount End
End
------------------------------------------------------
-- Enable data to be extracted and embedded within the
-- generated reminder message.
------------------------------------------------------
If @ErrorCode=0
Begin
	---------------------------------------------------
	-- Get the first Reminder Message that includes the 
	-- delimiter that indicates data is to be extracted 
	-- and embedded within the Reminder Message.
	-- The delimiter is the tilde character "~"
	---------------------------------------------------
	Set @sSQLString="
	Select @sReminderMessage=min(coalesce(LONGMESSAGE,SHORTMESSAGE))
	from #TEMPEMPLOYEEREMINDER
	where coalesce(LONGMESSAGE,SHORTMESSAGE) like '%~%~%'"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sReminderMessage	nvarchar(max)	OUTPUT',
				  @sReminderMessage=@sReminderMessage	OUTPUT
End

While @sReminderMessage is not null
and @ErrorCode=0
Begin
	-------------------------------------------
	-- For each unique Reminder Message extract
	-- all of the delimited character strings
	-- and save into a temporary table.
	-------------------------------------------
	Set @sSQLString="
	Insert into #TEMPEXTRACTEDSTRINGS(EXTRACTDATA,RELATIVECYCLE,EVENTNO)
	select	distinct
		DS.CharacterString,
		CASE WHEN(left(DS.CharacterString,2) in ('DD','EV')
		      and substring(DS.CharacterString,3,1)='\'
		      and isnumeric(substring(DS.CharacterString,4,1))=1)
			THEN convert(tinyint,substring(DS.CharacterString,4,1))
			ELSE NULL
		END,
		CASE WHEN(left(DS.CharacterString,2) in ('DD','EV')
		      and substring(DS.CharacterString,5,1)='\'
		      and isnumeric(substring(DS.CharacterString,6,20))=1)
			THEN convert(int,substring(DS.CharacterString,6,20))
			ELSE NULL
		END
	from dbo.fn_GetDelimitedStrings(@sReminderMessage, '~') DS
	left join #TEMPEXTRACTEDSTRINGS T on (T.EXTRACTDATA=DS.CharacterString)
	where T.EXTRACTDATA is null"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sReminderMessage	nvarchar(max)',
				  @sReminderMessage=@sReminderMessage

	Set @nExtractCount=@nExtractCount+@@rowcount
				  
	If @ErrorCode=0
	Begin
		---------------------------------------------------
		-- Get the next Reminder Message that includes the 
		-- delimiter.
		---------------------------------------------------
		Set @sSQLString="
		Select @sReminderMessage=min(coalesce(LONGMESSAGE,SHORTMESSAGE))
		from #TEMPEMPLOYEEREMINDER
		where coalesce(LONGMESSAGE,SHORTMESSAGE) like '%~%~%'
		and coalesce(LONGMESSAGE,SHORTMESSAGE)>@sReminderMessage"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sReminderMessage	nvarchar(max)	OUTPUT',
					  @sReminderMessage=@sReminderMessage	OUTPUT
	End
End

-------------------------------------------------
-- If data is to be extracted from the database
-- and embedded within the Reminder Message then
-- construct an update statement to update the
-- reminder message held in #TEMPEMPLOYEEREMINDER
-------------------------------------------------
If @nExtractCount>0
and @ErrorCode=0
Begin
	------------------------------------------------
	-- Get the default Date Style from SiteControl 
	-- and then translate it to the SQLServer Style.
	------------------------------------------------
	Set @sSQLString="
	Select @nDateFormat=S.COLINTEGER
	From SITECONTROL S
	Where S.CONTROLID='Date Style'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nDateFormat	tinyint		Output',
				  @nDateFormat=@nDateFormat	Output

	Set @nDateFormat=CASE @nDateFormat
				WHEN(1)	THEN 106
				WHEN(2) THEN 100
				WHEN(3)	THEN 111
				WHEN(4)	THEN 101
					ELSE 103
			 END
	------------------------------------------------
	-- As there may be multiple embedded data fields
	-- within any one reminder message, a loop will
	-- be required to ensure all occurrences have 
	-- been replaced.
	------------------------------------------------
	Set @sSQLString="
	insert into #TEMPEXTRACTEDCASEREMINDER (EXTRACTDATA,CASEID,REMINDERTEXT)	
	select  E.EXTRACTDATA,
	        T.CASEID,	        
	        CASE(left(E.EXTRACTDATA,2))
		   WHEN('EV') THEN
			CASE WHEN(CE.NEWEVENTDATE is not null)
				THEN convert(nvarchar(12),CE.NEWEVENTDATE,@nDateFormat)
				ELSE '**No Date**'
			END
		   WHEN('DD') THEN
			CASE WHEN(CE.NEWEVENTDUEDATE is not null)
				THEN convert(nvarchar(12), CE.NEWEVENTDUEDATE, @nDateFormat)
				ELSE '**No Date**'
			END
		   ELSE
			'*** ERROR ***'
		END	
	from #TEMPEXTRACTEDSTRINGS E
	join #TEMPEMPLOYEEREMINDER T 
				on (coalesce(T.LONGMESSAGE,T.SHORTMESSAGE) like '%~'+EXTRACTDATA+'~%')
	left join #TEMPCASEEVENT CE	
				on (CE.CASEID =T.CASEID
				and CE.EVENTNO=E.EVENTNO
				and CE.CYCLE=CASE(E.RELATIVECYCLE)
						WHEN(0) THEN T.CYCLENO
						WHEN(1) THEN T.CYCLENO-1
						WHEN(2) THEN T.CYCLENO+1
						WHEN(3) THEN 1
						WHEN(4) THEN (	select max(CE1.CYCLE)
								from #TEMPCASEEVENT CE1
								WHERE CE1.CASEID=CE.CASEID
								and CE1.EVENTNO=CE.EVENTNO)
					     END
				and CE.[STATE] not like 'D%')"
					
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nDateFormat		tinyint',
					  @nDateFormat=@nDateFormat
	While @nExtractCount>0
	and   @ErrorCode=0
	Begin
		Set @sSQLString="Update T
		Set SHORTMESSAGE= CASE WHEN(T.SHORTMESSAGE IS NOT NULL) THEN replace(T.SHORTMESSAGE,'~'+E.EXTRACTDATA+'~',convert(nvarchar(12), E.REMINDERTEXT)) END,	
		    LONGMESSAGE = CASE WHEN(T.LONGMESSAGE  IS NOT NULL) THEN replace(T.LONGMESSAGE, '~'+E.EXTRACTDATA+'~',convert(nvarchar(12), E.REMINDERTEXT)) END			
		from #TEMPEXTRACTEDCASEREMINDER E
		join #TEMPEMPLOYEEREMINDER T on (T.CASEID = E.CASEID 
					     and coalesce(T.LONGMESSAGE,T.SHORTMESSAGE) like '%~'+EXTRACTDATA+'~%')"
					
		exec @ErrorCode=sp_executesql @sSQLString
		
		set @nExtractCount=@@Rowcount
	End
End

-------------------------------------------------------------
-- SQA14201 & SQA18395
-- The Reminder rule may specify a RELATIONSHIP to be used 
-- to determine the recipient of the reminder. It is possible 
-- for multiple Names to be found.
-------------------------------------------------------------
If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO, CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION,  SENDELECTRONICALLY, EMAILSUBJECT,
		    ACTION, PROPERTYTYPE, COUNTRYCODE, RELATIONSHIP, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE)
	select	A.RELATEDNAME, T.CASEID, T.EVENTNO, T.CYCLENO, T.CRITERIANO, T.DUEDATE,  
		    T.READFLAG, T.SOURCE, T.SEQUENCENO, T.DATEUPDATED, T.EVENTDESCRIPTION,  T.SENDELECTRONICALLY, T.EMAILSUBJECT,
		    T.ACTION, T.PROPERTYTYPE, T.COUNTRYCODE, NULL, T.SHORTMESSAGE, T.LONGMESSAGE, T.REMINDERDATE
	from #TEMPEMPLOYEEREMINDER T
	join ASSOCIATEDNAME A	on (A.NAMENO=T.NAMENO
				and A.RELATIONSHIP=T.RELATIONSHIP)
	left join #TEMPEMPLOYEEREMINDER T1
				on (T1.NAMENO=A.RELATEDNAME
				and T1.CASEID=T.CASEID
				and T1.EVENTNO=T.EVENTNO
				and T1.CYCLENO=T.CYCLENO
				and T1.REFERENCE is null
				and T1.SEQUENCENO=T.SEQUENCENO)
	where T1.NAMENO is null
	and checksum(A.PROPERTYTYPE,A.ACTION,A.COUNTRYCODE)
		=(	select 
			convert(int,
			substring(
			min (
			CASE WHEN (A1.PROPERTYTYPE IS NULL) THEN '1' ELSE '0' END +
			CASE WHEN (A1.ACTION       IS NULL) THEN '1' ELSE '0' END +   			
			CASE WHEN (A1.COUNTRYCODE  IS NULL) THEN '1' ELSE '0' END +
			convert(char(11),checksum(A1.PROPERTYTYPE,A1.ACTION,A1.COUNTRYCODE)) ), 4,11))
			from ASSOCIATEDNAME A1
			where A1.NAMENO=T.NAMENO
			and   A1.RELATIONSHIP=T.RELATIONSHIP
			and (A1.PROPERTYTYPE=T.PROPERTYTYPE or A1.PROPERTYTYPE is null)
			and (A1.COUNTRYCODE =T.COUNTRYCODE  or A1.COUNTRYCODE  is null)
			and (A1.ACTION      =T.ACTION       or A1.ACTION       is null) )"

	exec @ErrorCode=sp_executesql @sSQLString

	set @nRowCount=@nRowCount+@@rowcount
End
------------------------------------------------------
-- After inserting the reminders for the related names
-- remove the reminder with the NameNo that was used
-- to determine the related names.
------------------------------------------------------
If @ErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	Delete from #TEMPEMPLOYEEREMINDER
	where RELATIONSHIP is not null"

	exec @ErrorCode=sp_executesql @sSQLString
	
	set @nRowCount=@nRowCount-@@rowcount
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceInsertReminders',0,1,@sTimeStamp ) with NOWAIT
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceInsertReminders  to public
go
