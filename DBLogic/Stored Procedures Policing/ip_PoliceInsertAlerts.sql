-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceInsertAlerts
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceInsertAlerts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceInsertAlerts.'
	drop procedure dbo.ip_PoliceInsertAlerts
end
print '**** Creating procedure dbo.ip_PoliceInsertAlerts...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceInsertAlerts
			@pdtFromDate		datetime,
			@pdtUntilDate		datetime,
			@psIRN			nvarchar(30),
			@psOfficeId		nvarchar(254),
			@psPropertyType		char(1),
			@psCountryCode		nvarchar(3),
			@psNameType		nvarchar(3),
			@pnNameNo		int,
			@psCaseType		char(1),
			@psCaseCategory		nvarchar(2),
			@psSubtype		nvarchar(2),
			@pnExcludeProperty	decimal(1,0),
			@pnExcludeCountry	decimal(1,0),
			@pnUpdateFlag		decimal(1,0),
			@pnDebugFlag		tinyint,
			@nRowCount		int OUTPUT

as
-- PROCEDURE :	ip_PoliceInsertAlerts
-- VERSION :	43
-- DESCRIPTION:	Inserts adhoc reminders into the EMPLOYEEREMINDER table and
--		updates the ALERTS table
-- CALLED BY :	ipu_Policing

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 28/06/2001	MF			Procedure created
-- 5/11/2001	MF	7146		Modify the algorithm that calculates the next reminder date.
-- 19/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles 
-- 12/03/2002	MF	7485		Change the function USER to SYSTEM_USER
-- 13/05/2002	MF	7658		The next reminder date for Alerts is not being updated when there is
--					not a Stop Reminder Date specified.
-- 01/07/2002	MF	7773		A modification for .NET to allow Alerts to generate a LETTER as an 
--					alternative to a reminder.
-- 22/07/2002	MF	7750		Increase IRN to 30 characters
-- 06/09/2002	MF	7988		If no Alert Date exists then the Due Date should be inserted as the 
--					Reminder Date for the generated reminder.
-- 28 Jul 2003	MF		10	Standardise version number
-- 08 Jan 2004	MF	9173	11	Correction of problem.  Ensure the Daily Reminder is the next calculated
--					alert date if it falls before the next Monthly Reminder.
-- 08 Jan 2004	MF	9537	12	Only perform row level security if a Site Control is turned on.
-- 06 Feb 2004	MF	9673	13	If an Alert has a StopReminderDate then the reminder should only be sent
--					if the StopReminderDate is equal to or after the Until Date range that
--					Policing is being run for.
-- 18 Mar 2004	MF	9823	14	Row level security causing a GPF crash in SQLServer.  To get around this bug
--					in SQLServer the subselect used in the Row Level Security needed to be modified.
--					The solution implement changed the list of valid SECURITYFLAG from an "IN" clause
--					to a BETWEEN.  Another solution (not implemented) that was found was to remove 
--					SYSTEM_USER from the Select and actually embed the value into the code
-- 22 Jun 2004	MF	8673	15	If a single Office is stored against the Case rather than multiple offices
--					stored in TABLEATTRIBUTES then modify the row level security
-- 22 Jun 2004	MF	10195	15	Determine how to get the office associated with a Case by checking the 
--					Site Control "Row Security Uses Case Office"
-- 26 Aug 2004	MF	10414	16	Correction to calculation of next Alert Date. Problem where both Monthly and
--					Daily frequency reminders were defined.
-- 13 Sep 2004	MF	RFC1327	17	Allow Policing of specific ALERT row to be processed.
-- 29 Oct 2004	MF	10609	18	Daily reminders are being generated prematurely.  This is a revisit of 10414
--					to ensure the DailyFrequency is greater than 0
-- 03 Nov 2004	MF	10589	19	Modify the row level security code to improve performance where multiple
--					offices are allowed to exist for a Case.
-- 15 Nov 2004	MF	10659	20	Row Level Security is not returning the correct Cases to police when NT
--					security is in use.
-- 22 Nov 2004	MF	10692	21	Revisit of RFC1327.  Ensure that the processing of a specific ALERTDATE row
--					functions correctly even if the ALERTDATE is already known.
-- 07 Jul 2005	MF	11011	22	Increase CaseCategory column size to NVARCHAR(2)
-- 25 Aug 2005	MF	11788	23	Ad hoc reminders are to be delivered even if the REMINDERSALLOWED flag on the
--					Case Status is off.  This flag was only intended to stop Case Event reminders.
-- 01 Sep 2005	MF	11821	24	Change hardcoded date from English format to numeric format.
-- 06 Jan 2006	MF	12167	25	If the Stop Reminder date falls after the start of the Policing date range
--					then Alert reminders are allowed to be generated.
-- 31 May 2007	MF	14812	26	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 07 Nov 2007	MF	15187	26	Provide the ability filter by one or more offices.
-- 11 Dec 2008	MF	17136	27	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 12 May 2009	vql	17404	28	Allow recording of ad hoc reminders against names.
-- 20 Oct 2010	AT	RFC7272	29	Extended length of ALERTMESSAGE columns.
-- 29 Oct 2010	MF	18494	30	Allow Alerts to be directed to different users depending on the rules defined against the Alert 
--					and resolved to the specific Name at the time the alert is generated.
--					Also Alerts may now be triggered as a result of an Event that it is linked to having its 
--					EventDate updated. This will flow through to the AlertDate as its new DueDate.
-- 16 Dec 2010	MF	RFC10113 31	Ensure that the reminder being generated does not get created with a ReminderDate in the past.
-- 20 Apr 2011	MF	RFC10333 32	Reminders generated from an ALERT need to carry a reference to the EMPLOYEENO of the ALERT.
-- 12 Sep 2011	MF	19919	33	Record the key of the ALERT on the #TEMPEMPLOYEEREMINDER so the ALERTDATE can be reported
--					on any email reminder that is generated.
-- 10 Oct 2011	MF	11401	33	SQA11788 introduced a change whereby Alerts will still be sent for Cases even if the REMINDERSALLOWED flag
--					for the Status is turned off. A client moving from an old version does not want this functionality and 
--					so a site control will be introduced to allow the Status to be considered.
-- 24 Feb 2012	MF	R11985	34	Provide the ability for a unicode value to be used as the NameType.
--				
-- 14 Mar 2012	DV	R9946	35	Populate the EVENTNO and the CYCLE from the ALERT table if there are no rows in #TEMPCASEEVENT.
-- 26 Jun 2012	MF	R12201	36	Alerts that are directed to a recipient based on rules stored against the Alert are to actually generate
--					an Alert row for each recipient that can be determined. The audit log ALERT_iLOG will indicate if the Alert
--					has previously been deleted, in which case it will not be reinserted.
-- 05 Jul 2013	vql	R13629	37	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Aug 2013	vql	R13629	38	Revisit R13629 because length of dynamic SQL was causing truncation. Do not concate nvarchar(n) on big SQL string.
-- 05 Nov 2015	MF	R54617	39	AlertDate is being moved on even for ALERT rows that are marked as having occurred.
-- 17 Dec 2015	MF	R13501	40	Block spawning of Alerts for each recipient if sitecontrol set to TRUE.  This provides ability to turn off
--					functionality introduced with RFC12201.
-- 26 Oct 2017	MF	72047	41	Ethical Wall restrictions of Cases are to be applied.
-- 08 Nov 2018	AV	75198/DR-45358	42	Date conversion errors when creating cases and opening names in Chinese DB.
-- 03 Apr 2020	BS	DR-56861 43	Reminder should not generate if adhoc set to not repeat

set nocount on
set concat_null_yields_null off

DECLARE		@ErrorCode		int,
		@nAlertRows		int,
		@nUserIdentityId	int,
		@bCheckStatus		bit,
		@bBlockAlertSpawning	bit,
		@nReminders		int,
		@nCriticalStaff		int,
		@sInsertString		nvarchar(4000),
		@sWhereClause		nvarchar(2000),
		@sUser			nvarchar(255),
		@sCaseJoin		nvarchar(200),
		@sSQLString		nvarchar(max),
		@bRowLevelSecurity	bit,
		@bCaseOffice		bit,
		@bBlockCaseAccess	bit

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode	 = 0
Set @nAlertRows  = 0
Set @nReminders  = 0
Set @sWhereClause= null

If @nRowCount is null
	Set @nRowCount=0
	
If @ErrorCode=0
Begin
	------------------------------------------------
	-- Check the site control to detemine if Alerts
	-- are to be blocked from spawning into separate
	-- rows for each recipient of the reminders.
	------------------------------------------------
	Set @sSQLString="
	Select @bBlockAlertSpawning=COLBOOLEAN
	from SITECONTROL
	where CONTROLID='Alert Spawning Blocked'"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@bBlockAlertSpawning	bit			OUTPUT',
				  @bBlockAlertSpawning=@bBlockAlertSpawning	OUTPUT
				  
	If @bBlockAlertSpawning is null
		Set @bBlockAlertSpawning=0
End

If @ErrorCode=0
Begin
	------------------------------------
	-- Attempt to get the UserIdentityId
	-- associated with the SPID
	------------------------------------
	select	@nUserIdentityId=CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4)  as int) END
	from master.dbo.sysprocesses
	where spid=@@SPID
	and(substring(context_info,1, 4)<>0x0000000)

	Set @ErrorCode=@@ERROR

	If isnull(@nUserIdentityId,'')=''
	and @ErrorCode=0
	Begin
		--------------------------------------
		-- If still no UserIdentityId then get
		-- the one linked to current login
		--------------------------------------
		Select @nUserIdentityId=min(IDENTITYID)
		from USERIDENTITY
		where LOGINID=substring(SYSTEM_USER,1,50)

		Set @ErrorCode=@@ERROR
	End
End


If  @ErrorCode=0
and @nUserIdentityId is not null
Begin
	---------------------------------------
	-- Check to see if the user is impacted
	-- by Row Level Security
	---------------------------------------
	Select @bRowLevelSecurity = 1
	from IDENTITYROWACCESS U 
	join ROWACCESSDETAIL R on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @nUserIdentityId

	Set @ErrorCode=@@ERROR
End

If @ErrorCode=0
Begin
	If @bRowLevelSecurity=1
	Begin
		---------------------------------------------
		-- If Row Level Security is in use for user,
		-- determine how/if Office is stored against 
		-- Cases.  It is possible to store the office
		-- directly in the CASES table or if a Case 
		-- is to have multiple offices then it is
		-- stored in TABLEATTRIBUTES.
		---------------------------------------------
		Select  @bCaseOffice = COLBOOLEAN
		from SITECONTROL
		where CONTROLID = 'Row Security Uses Case Office'

		Set @ErrorCode=@@ERROR
				
	
		---------------------------------------------
		-- Check to see if there are any Offices 
		-- held as TABLEATRRIBUTES of the Case. If
		-- not then treat as if Office is stored 
		-- directly in the CASES table.
		---------------------------------------------
		If(@bCaseOffice=0 or @bCaseOffice is null)
		and not exists (select 1 from TABLEATTRIBUTES where PARENTTABLE='CASES' and TABLETYPE=44)
			Set @bCaseOffice=1
	End
	Else Begin
		---------------------------------------------
		-- If Row Level Security is NOT in use for
		-- the current user, then check if any other 
		-- users are configured.  If they are, then 
		-- internal users that have no configuration 
		-- will be blocked from ALL cases.
		---------------------------------------------
		If @nUserIdentityId is null
		Begin
			-------------------------------
			-- Also do not block result if  
			-- @nUserIdentityID is unknown
			-------------------------------
			Set @bBlockCaseAccess=0
		End
		ELSE Begin
			Select @bBlockCaseAccess = 1
			from IDENTITYROWACCESS U
			join USERIDENTITY UI	on (U.IDENTITYID = UI.IDENTITYID) 
			join ROWACCESSDETAIL R	on (R.ACCESSNAME = U.ACCESSNAME) 
			where R.RECORDTYPE = 'C' 
			and isnull(UI.ISEXTERNALUSER,0) = 0

			Set @ErrorCode=@@ERROR
		End
	End
End

If exists (select * from sys.objects where name = 'fn_CasesEthicalWall')
and @nUserIdentityId is not null
Begin
	Set @sCaseJoin = '		left join dbo.fn_CasesEthicalWall('+cast(@nUserIdentityId as nvarchar)+') C on (C.CASEID=A.CASEID)'
End
Else
Begin
	Set @sCaseJoin = '		left join CASES C ON (C.CASEID=A.CASEID)'
End

-- Load #TEMPALERT with the details of any specific Alert rows to be processed.

If @ErrorCode=0
Begin
	------------------------------------------------
	-- Note that Ethical Walls and Row Level Access
	-- restrictions are not required here as this is
	-- for specific Alert processing.
	------------------------------------------------
	Set @sInsertString=
	"	insert #TEMPALERT (	
			EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE, ALERTDATE, DUEDATE, 
			DATEOCCURRED, OCCURREDFLAG, DELETEDATE, STOPREMINDERSDATE, MONTHLYFREQUENCY,
			MONTHSLEAD, DAILYFREQUENCY, DAYSLEAD, SEQUENCENO, SENDELECTRONICALLY, EMAILSUBJECT, NAMENO, EMPLOYEEFLAG, SIGNATORYFLAG,
			CRITICALFLAG, NAMETYPE, RELATIONSHIP, EVENTNO, CYCLE)
	
		select	DISTINCT A.EMPLOYEENO, A.ALERTSEQ, A.CASEID, A.ALERTMESSAGE, A.REFERENCE, 
			-- If the ALERTDATE is to be calculated then just calculate a temporary one for now to determine
			-- if a reminder is to be generated at this time.  The correct date will be calculated at the
			-- end of this procedure.
			CASE WHEN(A.ALERTDATE is NULL
			      and A.DUEDATE   is not NULL
			      and isnull(A.DATEOCCURRED     ,'30000131')>getdate()
			      and isnull(A.STOPREMINDERSDATE,'30000131')>@pdtFromDate
			      and isnull(A.DELETEDATE       ,'30000131')>@pdtFromDate )
			   THEN	CASE WHEN(dateadd(month,-1*A.MONTHSLEAD,A.DUEDATE) <= convert(nvarchar,@pdtUntilDate,112)
				       OR dateadd(day  ,-1*A.DAYSLEAD,  A.DUEDATE) <= convert(nvarchar,@pdtUntilDate,112))
					THEN convert(nvarchar,@pdtUntilDate,112)
				END
			     ---------------------------------------
			     -- SQA18494
			     -- Allow the Event Date of an Event to
			     -- be used as the Due Date on an Alert.
			     ---------------------------------------
			     WHEN(isnull(A.DUEDATE,'')<>CE.NEWEVENTDATE
			      and isnull(A.DATEOCCURRED     ,'30000131')>getdate()
			      and isnull(A.STOPREMINDERSDATE,'30000131')>@pdtFromDate
			      and isnull(A.DELETEDATE       ,'30000131')>@pdtFromDate )
			   THEN	CASE WHEN(dateadd(month,-1*A.MONTHSLEAD,CE.NEWEVENTDATE) <= convert(nvarchar,@pdtUntilDate,112)
				       OR dateadd(day  ,-1*A.DAYSLEAD,  CE.NEWEVENTDATE) <= convert(nvarchar,@pdtUntilDate,112))
					THEN convert(nvarchar,@pdtUntilDate,112)
				END

			   ELSE convert(nvarchar, A.ALERTDATE,112)
			END,
			CASE WHEN(CE.NEWEVENTDATE is not null) THEN convert(nvarchar, CE.NEWEVENTDATE, 112) ELSE convert(nvarchar, A.DUEDATE, 112) END,
			convert(nvarchar, A.DATEOCCURRED, 112), A.OCCURREDFLAG, convert(nvarchar, A.DELETEDATE,112),
			convert(nvarchar, A.STOPREMINDERSDATE,112), A.MONTHLYFREQUENCY,
			A.MONTHSLEAD, A.DAILYFREQUENCY, A.DAYSLEAD, A.SEQUENCENO, A.SENDELECTRONICALLY, A.EMAILSUBJECT, A.NAMENO, 
			A.EMPLOYEEFLAG, A.SIGNATORYFLAG, A.CRITICALFLAG, A.NAMETYPE, A.RELATIONSHIP, ISNULL(CE.EVENTNO,A.EVENTNO), ISNULL(CE.CYCLE,A.CYCLE)
		from #TEMPPOLICING T
		join ALERT A	on (A.EMPLOYEENO=T.ADHOCNAMENO
				and A.ALERTSEQ  =T.ADHOCDATECREATED)
		left join #TEMPCASEEVENT CE
				on (CE.CASEID=A.CASEID
				and CE.EVENTNO=A.TRIGGEREVENTNO
				and(CE.NEWEVENTDATE is not null and A.DUEDATE is null
				 OR CE.NEWEVENTDATE <> A.DUEDATE)
				and CE.[STATE]='I1')"
	
		exec @ErrorCode=sp_executesql @sInsertString,
						N'@pdtFromDate		datetime,
						  @pdtUntilDate		datetime',
						  @pdtFromDate=@pdtFromDate,
						  @pdtUntilDate=@pdtUntilDate
	
		Set @nAlertRows=@@Rowcount
End
		
If  @ErrorCode=0
and @nAlertRows>0
and @bBlockAlertSpawning=0
Begin
	-------------------------------------------------
	-- ALERTs that are defined to send reminders to 
	-- other names associated with the Case are to
	-- be copied to have their own ALERT row for each
	-- recipient name. This will allow
	-------------------------------------------------
	Set @sSQLString="
	insert #TEMPALERT (	
		EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE, ALERTDATE, DUEDATE, 
		DATEOCCURRED, OCCURREDFLAG, DELETEDATE, STOPREMINDERSDATE, MONTHLYFREQUENCY,
		MONTHSLEAD, DAILYFREQUENCY, DAYSLEAD, SEQUENCENO, SENDELECTRONICALLY, EMAILSUBJECT, NAMENO, EMPLOYEEFLAG, SIGNATORYFLAG,
		CRITICALFLAG, NAMETYPE, RELATIONSHIP, TRIGGEREVENTNO, EVENTNO, CYCLE, IMPORTANCELEVEL)
	select DISTINCT CN.NAMENO, T.ALERTSEQ, T.CASEID, T.ALERTMESSAGE, T.REFERENCE, T.ALERTDATE, T.DUEDATE, T.DATEOCCURRED, T.OCCURREDFLAG, 
			T.DELETEDATE, T.STOPREMINDERSDATE, T.MONTHLYFREQUENCY, T.MONTHSLEAD, T.DAILYFREQUENCY, T.DAYSLEAD, T.SEQUENCENO, 
			T.SENDELECTRONICALLY, T.EMAILSUBJECT, NULL, 0, 0, 0, NULL, T.RELATIONSHIP, A.TRIGGEREVENTNO, T.EVENTNO, T.CYCLE, A.IMPORTANCELEVEL
	from #TEMPALERT T
	     join ALERT A	on (A.EMPLOYEENO=T.EMPLOYEENO
				and A.ALERTSEQ  =T.ALERTSEQ)
	     join CASENAME CN	on ( CN.CASEID  =T.CASEID
				and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
				and((CN.NAMETYPE ='EMP' and T.EMPLOYEEFLAG=1)
				 or (CN.NAMETYPE ='SIG' and T.SIGNATORYFLAG=1)
				 or (CN.NAMETYPE =T.NAMETYPE)))
	left join #TEMPALERT T1	on (T1.EMPLOYEENO=CN.NAMENO
				and T1.ALERTSEQ  =T.ALERTSEQ)
	left join ALERT A1	on (A1.EMPLOYEENO=CN.NAMENO
				and A1.ALERTSEQ  =T.ALERTSEQ)			 
	where  A.LETTERNO   is null
	and   T1.EMPLOYEENO is null
	and   A1.EMPLOYEENO is null"
	
	------------------------------------------------------------
	-- If the ALERT table is being logged then check to see that 
	-- the ALERT to be spawned has not previously been generated
	-- and deleted.  This will avoid the regeneration of Alerts.
	------------------------------------------------------------
	
	If exists (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ALERT_iLOG')
	Begin
		Set @sSQLString=@sSQLString+CHAR(10)+
		"and not exists	(select 1 from ALERT_iLOG LOG"+CHAR(10)+
		"		 where LOG.EMPLOYEENO=CN.NAMENO"+CHAR(10)+
		"		 and   LOG.ALERTSEQ  =T.ALERTSEQ"+CHAR(10)+
		"		 and   LOG.LOGACTION ='D')"
	End		
	
	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Construct the SQL to load the #TEMPALERT table based on the parameters passed to this procedure
-- Return those rows whose ALERTDATE falls within the date range OR whose Delete Date is less than the
-- current date.
If  @ErrorCode=0
and @nAlertRows=0
Begin
	set @sInsertString = 
	"	insert #TEMPALERT (	
			EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE, ALERTDATE,DUEDATE, 
			DATEOCCURRED, OCCURREDFLAG, DELETEDATE, STOPREMINDERSDATE, MONTHLYFREQUENCY,
			MONTHSLEAD, DAILYFREQUENCY, DAYSLEAD, SEQUENCENO, SENDELECTRONICALLY, EMAILSUBJECT, NAMENO, 
			EMPLOYEEFLAG, SIGNATORYFLAG, CRITICALFLAG, NAMETYPE, RELATIONSHIP)
	
		select	A.EMPLOYEENO, A.ALERTSEQ, A.CASEID, A.ALERTMESSAGE, A.REFERENCE, 
			convert(nvarchar, A.ALERTDATE,112), 
			convert(nvarchar, A.DUEDATE, 112),
			convert(nvarchar, A.DATEOCCURRED,112), A.OCCURREDFLAG, 
			convert(nvarchar, A.DELETEDATE, 112),  
			convert(nvarchar, A.STOPREMINDERSDATE, 112), A.MONTHLYFREQUENCY,
			A.MONTHSLEAD, A.DAILYFREQUENCY, A.DAYSLEAD, A.SEQUENCENO, A.SENDELECTRONICALLY, A.EMAILSUBJECT, A.NAMENO, 
			A.EMPLOYEEFLAG, A.SIGNATORYFLAG, A.CRITICALFLAG, A.NAMETYPE, A.RELATIONSHIP
		from ALERT A" +CHAR(10)+
		
		@sCaseJoin + 
		
		CASE WHEN(@bRowLevelSecurity = 1 AND @bCaseOffice = 1)
			THEN char(10)+"		left join dbo.fn_CasesRowSecurity("+cast(@nUserIdentityId as nvarchar)+") RS on (RS.CASEID=A.CASEID AND RS.UPDATEALLOWED=1)"
		     WHEN(@bRowLevelSecurity = 1)
			THEN char(10)+"		left join dbo.fn_CasesRowSecurityMultiOffice("+cast(@nUserIdentityId as nvarchar)+") RS on (RS.CASEID=A.CASEID AND RS.UPDATEALLOWED=1)"
			ELSE ''
		END
	
	-- Build the WHERE clause based on the parameters passed to the procedure
	-- If IRN is passed then no additional parameters need to be looked at.
	
	set @sWhereClause="	where (isnull(A.OCCURREDFLAG,0)=0 AND(A.ALERTDATE between '"+convert(nvarchar,@pdtFromDate)+"' and '"+convert(nvarchar, @pdtUntilDate)+"' OR A.DUEDATE between '"+convert(nvarchar,@pdtFromDate)+"' and '"+convert(nvarchar, @pdtUntilDate)+"')"+CHAR(10)+
			  "	   OR  A.DELETEDATE<getdate() )"+CHAR(10)+
			  "	and (C.CASEID is not null OR A.CASEID is null)"

	if @bRowLevelSecurity = 1
	begin
		set @sWhereClause=@sWhereClause+char(10)+"	and (RS.CASEID is not null OR A.CASEID is null)"
	end

	if @bBlockCaseAccess=1
	begin
		Set @sWhereClause=@sWhereClause+char(10)+"	and 1=0"
	End

	
	if @psIRN is not null
	begin
		set @sWhereClause=@sWhereClause+char(10)+"	and C.IRN='"+@psIRN+"'"
	end
	else begin
		if @psOfficeId is not null
		begin
			set @sWhereClause=@sWhereClause+char(10)+"	and C.OFFICEID in ("+@psOfficeId+")"
		end

		if @psPropertyType is not null
		begin
			if @pnExcludeProperty=1
			begin
				set @sWhereClause=@sWhereClause+char(10)+"	and (C.PROPERTYTYPE is null OR C.PROPERTYTYPE<>'"+@psPropertyType+"')"
			End
			else begin
				set @sWhereClause=@sWhereClause+char(10)+"	and C.PROPERTYTYPE='"+@psPropertyType+"'"
			End
		end
		
		if @psCountryCode is not null
		begin
			if @pnExcludeCountry=1
			begin
				set @sWhereClause=@sWhereClause+char(10)+"	and (C.COUNTRYCODE is null OR C.COUNTRYCODE<>'"+@psCountryCode+"')"
			End
			else begin
				set @sWhereClause=@sWhereClause+char(10)+"	and C.COUNTRYCODE='"+@psCountryCode+"'"
			End
		end
	
		if @psCaseType is not null
		begin
			set @sWhereClause=@sWhereClause+char(10)+"	and C.CASETYPE='"+@psCaseType+"'"
		end
	
		if @psCaseCategory is not null
		begin
			set @sWhereClause=@sWhereClause+char(10)+"	and C.CASECATEGORY='"+@psCaseCategory+"'"
		end
		
		if @psSubtype is not null
		begin
			set @sWhereClause=@sWhereClause+char(10)+"	and C.SUBTYPE='"+@psSubtype+"'"
		end
		
		--  If the NAMENO is an Employee and no NAMETYPE is passed then filter for Alerts
		--  for that employee only.
	
		if  @psNameType is null
		and @pnNameNo   is not null
		and exists (select * from EMPLOYEE where EMPLOYEENO=@pnNameNo)
		begin
			set @sWhereClause=@sWhereClause+char(10)+"	and A.EMPLOYEENO="+convert(nvarchar,@pnNameNo)
		end
		--  If NAMENO or NAMETYPE are passed then a JOIN on the CASENAME table is required
	
		else if @pnNameNo   is not null
		     or @psNameType is not null
		begin
			set @sInsertString = @sInsertString+char(10)+"	     join CASENAME CN   on (CN.CASEID=C.CASEID"
		
			if @pnNameNo is not null
			begin
				set @sInsertString=@sInsertString+" and CN.NAMENO="+convert(nvarchar,@pnNameNo)
			end
		
			if @psNameType is not null
			begin
				set @sInsertString=@sInsertString+" and CN.NAMETYPE=N'"+@psNameType+"'"		-- RFC11985
			end
			
			set @sInsertString = @sInsertString+")"
		
		end
	end
	
	-- If Row Access security is in use then only return rows where the user has update rights to the Case.
	
	If exists (	SELECT *                    
			FROM ROWACCESSDETAIL R 
			join USERROWACCESS U on (U.ACCESSNAME = R.ACCESSNAME)
			join SITECONTROL S   on (S.CONTROLID='Policing Uses Row Security'
					     and S.COLBOOLEAN=1)
			WHERE R.RECORDTYPE = 'C')
	and isnull(@bRowLevelSecurity,0)=0		-- Row security for UserIdentityId has not been applied
	begin
		-- Get the current logged on user to determine what Row Level Security
		-- restrictions apply to that user.  Wrap the string in the appropriate quotes
		-- so it can be embedded into the SQL Statement.
	
		Set @sUser=dbo.fn_WrapQuotes(dbo.fn_SystemUser(),0,0)

		-- If multiple offices are allowed to be stored then get the Office from 
		-- the TABLEATTRIBUTES table otherwise get it from the CASES table
		If isnull(@bCaseOffice,0)=0
		begin
			set @sWhereClause=@sWhereClause	+char(10)+"and(C.CASEID is null"
							+char(10)+" OR Substring("
							+char(10)+"    (select MAX ("
							+char(10)+"     CASE WHEN OFFICE		IS NULL	THEN '0' ELSE '1' END +"
							+char(10)+"     CASE WHEN CASETYPE		IS NULL	THEN '0' ELSE '1' END +"
							+char(10)+"     CASE WHEN PROPERTYTYPE	IS NULL	THEN '0' ELSE '1' END +"
							+char(10)+"     CASE WHEN SECURITYFLAG < 10	THEN '0' END +"        -- pack a single digit flag with zero
							+char(10)+"     convert(nvarchar,SECURITYFLAG))"
							+char(10)+"     from USERROWACCESS UA"
							+char(10)+"     left join ROWACCESSDETAIL RAD	on (RAD.ACCESSNAME=UA.ACCESSNAME"
							+char(10)+"					and(RAD.OFFICE       in (select TA.TABLECODE from TABLEATTRIBUTES TA where TA.PARENTTABLE='CASES' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, C.CASEID))"   
							+char(10)+"					 or RAD.OFFICE       is NULL)"
							+char(10)+"					and(RAD.CASETYPE     = C.CASETYPE     or RAD.CASETYPE     is NULL)"
							+char(10)+"					and(RAD.PROPERTYTYPE = C.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL)"
							+char(10)+"					and RAD.RECORDTYPE = 'C')"
							+char(10)+"     where UA.USERID="+@sUser+"),4,2)"
							+char(10)+"     between '08' and '15' )"    -- list of SECURITYFLAG with SELECT set ON --SQA9823
		end
		else begin
			set @sWhereClause=@sWhereClause	+char(10)+"and(C.CASEID is null"
							+char(10)+" OR Substring("
							+char(10)+"    (select MAX ("
							+char(10)+"     CASE WHEN OFFICE		IS NULL	THEN '0' ELSE '1' END +"
							+char(10)+"     CASE WHEN CASETYPE		IS NULL	THEN '0' ELSE '1' END +"
							+char(10)+"     CASE WHEN PROPERTYTYPE	IS NULL	THEN '0' ELSE '1' END +"
							+char(10)+"     CASE WHEN SECURITYFLAG < 10	THEN '0' END +"        -- pack a single digit flag with zero
							+char(10)+"     convert(nvarchar,SECURITYFLAG))"
							+char(10)+"     from USERROWACCESS UA"
							+char(10)+"     left join ROWACCESSDETAIL RAD	on (RAD.ACCESSNAME=UA.ACCESSNAME"
							+char(10)+"					and(RAD.OFFICE       = C.OFFICEID     or RAD.OFFICE       is NULL)"
							+char(10)+"					and(RAD.CASETYPE     = C.CASETYPE     or RAD.CASETYPE     is NULL)"
							+char(10)+"					and(RAD.PROPERTYTYPE = C.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL)"
							+char(10)+"					and RAD.RECORDTYPE = 'C')"
							+char(10)+"     where UA.USERID="+@sUser+"),4,2)"
							+char(10)+"     between '08' and '15')"    -- list of SECURITYFLAG with SELECT set ON --SQA9823
		end
	end
	
	-- Append the WHERE clause to the rest of the INSERT statement.
	
	If @sWhereClause is not null
	begin
		set @sInsertString = @sInsertString + nchar(10)+ @sWhereClause
	end
	
	-- Now execute the dynamically created Insert to load #TEMPALERT.
	
	Execute @ErrorCode = sp_executesql @sInsertString
	Set @nAlertRows=@@Rowcount
End
------------------------------------------------------
-- Get the SiteControl that will cause Alert generated 
-- reminders to be suppressed if the Status of the 
-- Case has the REMINDERSALLOWED flag turned off.
------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bCheckStatus=S.COLBOOLEAN
	from SITECONTROL S
	where S.CONTROLID='Alert Must Check Status'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@bCheckStatus		bit	OUTPUT',
				  @bCheckStatus	= @bCheckStatus	OUTPUT
End

-- Insert the EMPLOYEEREMINDER if it falls within the date range

if  @ErrorCode =0
and @nAlertRows>0
Begin
	set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO,  CASEID, REFERENCE, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE, SENDELECTRONICALLY, EMAILSUBJECT, ALERTNAMENO, RELATIONSHIP,
		    EVENTNO, CYCLENO, ALERTSEQ, FROMEMPLOYEENO )
	select	T.EMPLOYEENO, T.CASEID, 
		CASE WHEN (T.REFERENCE is not null) THEN T.REFERENCE
		     WHEN (T.CASEID is null and T.NAMENO is null)        
						    THEN replace(replace(convert(nvarchar,T.ALERTSEQ, 121),'-',''),' ','')
		END, 
		T.DUEDATE, 0, 1, T.SEQUENCENO, 
		CASE WHEN LEN(T.ALERTMESSAGE) <= 254 THEN T.ALERTMESSAGE ELSE NULL END,
		CASE WHEN LEN(T.ALERTMESSAGE) > 254 THEN T.ALERTMESSAGE ELSE NULL END,
		CASE WHEN(isnull(T.ALERTDATE,T.DUEDATE) > convert(varchar,getdate(),112))
			THEN isnull(T.ALERTDATE,T.DUEDATE)
			ELSE convert(varchar,getdate(),112)
		END,
		T.SENDELECTRONICALLY, T.EMAILSUBJECT, T.NAMENO, T.RELATIONSHIP,
		T.EVENTNO, T.CYCLE, T.ALERTSEQ, T.EMPLOYEENO
	from #TEMPALERT T"

	if @bCheckStatus=1
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	left join CASES C	on (C.CASEID=T.CASEID)"
					  +char(10)+"	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)"
	End

	set @sSQLString=@sSQLString+"
	where  (T.ALERTDATE between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"' 
	  OR   (T.DUEDATE   between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"' AND T.ALERTDATE is NULL))
	
	and    (T.OCCURREDFLAG = 0 OR T.OCCURREDFLAG is NULL)  
	and    (T.DATEOCCURRED     > getdate() OR T.DATEOCCURRED      is NULL ) 
	and    (T.STOPREMINDERSDATE> '"+convert(varchar,@pdtFromDate)+"' OR T.STOPREMINDERSDATE is NULL)
	and     T.ALERTMESSAGE is not null
	and not (cast(T.DUEDATE as date) < cast(getdate() as date) AND ISNULL(T.MONTHLYFREQUENCY,0)=0 and ISNULL(T.MONTHSLEAD,0)=0 and ISNULL(T.DAILYFREQUENCY,0)=0 and ISNULL(T.DAYSLEAD,0)=0)
	"

	if @bCheckStatus=1
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	and     isnull(S.LETTERSALLOWED,1)=1"
	End

	Exec(@sSQLString)

	Select	@ErrorCode=@@Error,
		@nReminders=@@Rowcount

	-- Get the NameNo used for delivering Critical Reminders

	If @ErrorCode=0
	and @nReminders>0
	Begin
		Set @sSQLString="
		Select @nCriticalStaff=S.COLINTEGER
		from SITECONTROL S
		where S.CONTROLID='Critical Reminder'"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nCriticalStaff	int		OUTPUT',
					  @nCriticalStaff=@nCriticalStaff	OUTPUT
	End

	If  @nReminders>0
	and @nCriticalStaff is not null
	and @ErrorCode=0
	Begin
		------------------------------------------
		-- The reminder recipient is the Name
		-- specified to receive Critical Reminders
		------------------------------------------
		set @sSQLString="
		insert into #TEMPEMPLOYEEREMINDER (NAMENO,  CASEID, REFERENCE, DUEDATE,  
			    READFLAG, SOURCE, SEQUENCENO, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE, SENDELECTRONICALLY, EMAILSUBJECT, ALERTNAMENO, RELATIONSHIP,
			    EVENTNO, CYCLENO, FROMEMPLOYEENO )
		select	@nCriticalStaff, T.CASEID, 
			CASE WHEN (T.REFERENCE is not null) THEN T.REFERENCE
			     WHEN (T.CASEID is null and T.NAMENO is null)        
							    THEN replace(replace(convert(nvarchar,T.ALERTSEQ, 121),'-',''),' ','')
			END, 
			T.DUEDATE, 0, 1, T.SEQUENCENO, 
			CASE WHEN LEN(T.ALERTMESSAGE) <= 254 THEN T.ALERTMESSAGE ELSE NULL END,
			CASE WHEN LEN(T.ALERTMESSAGE) > 254 THEN T.ALERTMESSAGE ELSE NULL END,
			CASE WHEN(isnull(T.ALERTDATE,T.DUEDATE) > convert(varchar,getdate(),112))
				THEN isnull(T.ALERTDATE,T.DUEDATE)
				ELSE convert(varchar,getdate(),112)
			END,
			T.SENDELECTRONICALLY, T.EMAILSUBJECT, T.NAMENO, T.RELATIONSHIP,
			T.EVENTNO, T.CYCLE, T.EMPLOYEENO
		from #TEMPALERT T
		     join NAME N	on (N.NAMENO=@nCriticalStaff)"

		if @bCheckStatus=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+"		left join CASES C	on (C.CASEID=T.CASEID)"
						   +char(10)+"		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)"
		End

		set @sSQLString=@sSQLString+"
		where  (T.ALERTDATE between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"' 
		  OR   (T.DUEDATE   between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"' AND T.ALERTDATE is NULL))
		
		and    (T.OCCURREDFLAG = 0 OR T.OCCURREDFLAG is NULL)  
		and    (T.DATEOCCURRED     > getdate() OR T.DATEOCCURRED      is NULL ) 
		and    (T.STOPREMINDERSDATE> '"+convert(varchar,@pdtFromDate)+"' OR T.STOPREMINDERSDATE is NULL)
		and	T.CRITICALFLAG=1
		and     T.ALERTMESSAGE is not null
		and not (cast(T.DUEDATE as date) < cast(getdate() as date) AND ISNULL(T.MONTHLYFREQUENCY,0)=0 and ISNULL(T.MONTHSLEAD,0)=0 and ISNULL(T.DAILYFREQUENCY,0)=0 and ISNULL(T.DAYSLEAD,0)=0)
		"

		if @bCheckStatus=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+"		and     isnull(S.LETTERSALLOWED,1)=1"
		End

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nCriticalStaff	int',
					  @nCriticalStaff=@nCriticalStaff

		Set @nReminders=@nReminders+@@Rowcount
	End

	-------------------------------------
	-- When Alerts have been blocked from
	-- spawning into separate Alert rows
	-- for each reminder recipient, then 
	-- generate the reminders from the 
	-- master Alert.
	-------------------------------------
	If  @nReminders>0
	and @ErrorCode=0
	and @bBlockAlertSpawning=1
	Begin
		------------------------------------------
		-- The reminder recipient is the Name
		-- specified to receive names associated
		-- the the Case by NameType
		------------------------------------------
		set @sSQLString="
		insert into #TEMPEMPLOYEEREMINDER (NAMENO,  CASEID, REFERENCE, DUEDATE,  
			    READFLAG, SOURCE, SEQUENCENO, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE, SENDELECTRONICALLY, EMAILSUBJECT, ALERTNAMENO, RELATIONSHIP,
			    EVENTNO, CYCLENO, FROMEMPLOYEENO )
		select	CN.NAMENO, T.CASEID, 
			CASE WHEN (T.REFERENCE is not null) THEN T.REFERENCE
			     WHEN (T.CASEID is null and T.NAMENO is null)        
							    THEN replace(replace(convert(nvarchar,T.ALERTSEQ, 121),'-',''),' ','')
			END, 
			T.DUEDATE, 0, 1, T.SEQUENCENO, 
			CASE WHEN LEN(T.ALERTMESSAGE) <= 254 THEN T.ALERTMESSAGE ELSE NULL END,
			CASE WHEN LEN(T.ALERTMESSAGE) > 254 THEN T.ALERTMESSAGE ELSE NULL END,
			CASE WHEN(isnull(T.ALERTDATE,T.DUEDATE) > convert(varchar,getdate(),112))
				THEN isnull(T.ALERTDATE,T.DUEDATE)
				ELSE convert(varchar,getdate(),112)
			END,
			T.SENDELECTRONICALLY, T.EMAILSUBJECT, T.NAMENO, T.RELATIONSHIP,
			T.EVENTNO, T.CYCLE, T.EMPLOYEENO
		from #TEMPALERT T
		     join ALERT A	on (A.EMPLOYEENO=T.EMPLOYEENO
					and A.ALERTSEQ  =T.ALERTSEQ)
		     join CASENAME CN	on ( CN.CASEID   =T.CASEID
					and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
					and((CN.NAMETYPE ='EMP' and T.EMPLOYEEFLAG=1)
					 or (CN.NAMETYPE ='SIG' and T.SIGNATORYFLAG=1)
					 or (CN.NAMETYPE =T.NAMETYPE)))"

		if @bCheckStatus=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+"		left join CASES C	on (C.CASEID=T.CASEID)"
						   +char(10)+"		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)"
		End

		set @sSQLString=@sSQLString+"
		where  (T.ALERTDATE between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"' 
		  OR   (T.DUEDATE   between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"' AND T.ALERTDATE is NULL))
		
		and    (T.OCCURREDFLAG = 0 OR T.OCCURREDFLAG is NULL)  
		and    (T.DATEOCCURRED     > getdate() OR T.DATEOCCURRED      is NULL ) 
		and    (T.STOPREMINDERSDATE> '"+convert(varchar,@pdtFromDate)+"' OR T.STOPREMINDERSDATE is NULL)
		and    (T.EMPLOYEEFLAG=1 OR T.SIGNATORYFLAG=1 OR T.NAMETYPE is not null)
		and     A.LETTERNO is null
		and not (cast(T.DUEDATE as date) < cast(getdate() as date) AND ISNULL(T.MONTHLYFREQUENCY,0)=0 and ISNULL(T.MONTHSLEAD,0)=0 and ISNULL(T.DAILYFREQUENCY,0)=0 and ISNULL(T.DAYSLEAD,0)=0)
		"


		if @bCheckStatus=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+"		and     isnull(S.LETTERSALLOWED,1)=1"
		End

		Exec @ErrorCode=sp_executesql @sSQLString

		Set @nReminders=@nReminders+@@Rowcount
	End
End

-- Generate any LETTERS required where the ALERTDATE falls within the date range
-- NOTE: The actual ACTIVITYREQUEST rows will be inserted in the procedure ipu_PoliceInsertLetters
--       after any other letters are inserted into the #TEMPACTIVITYREQUEST table

if  @ErrorCode =0
and @nAlertRows>0
Begin
	set @sSQLString="
	insert into #TEMPACTIVITYREQUEST (CASEID,  SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, 
					LETTERNO, COVERINGLETTERNO, HOLDFLAG, DELIVERYID, 
					ACTIVITYTYPE, ACTIVITYCODE, PROCESSED )
	Select	distinct T.CASEID, SYSTEM_USER, 'Pol-Proc', CE.CREATEDBYACTION, CE.EVENTNO, CE.CYCLE,
		L.LETTERNO, L.COVERINGLETTER, isnull(L.HOLDFLAG, 0), L.DELIVERYID, 32,
		CASE WHEN (MULTICASEFLAG=1) THEN 3206 ELSE 3204 END, 0
	from #TEMPALERT T
	join ALERT AL		on (AL.EMPLOYEENO=T.EMPLOYEENO
				and AL.ALERTSEQ  =T.ALERTSEQ)
	join CASEEVENT CE	on (CE.CASEID =AL.FROMCASEID
				and CE.EVENTNO=AL.EVENTNO
				and CE.CYCLE  =AL.CYCLE)
	join CASES C		on (C.CASEID=T.CASEID)
	join LETTER L		on (L.LETTERNO=AL.LETTERNO)"

	if @bCheckStatus=1
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)"
	End

	Set @sSQLString=@sSQLString+"
	where  (T.ALERTDATE between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"' 
	  OR   (T.DUEDATE   between '"+convert(varchar,@pdtFromDate)+"' and '"+convert(varchar,@pdtUntilDate)+"' AND T.ALERTDATE is NULL))
	and    (T.OCCURREDFLAG = 0 OR T.OCCURREDFLAG is NULL)  
	and    (T.DATEOCCURRED     < getdate() OR T.DATEOCCURRED      is NULL ) 
	and    (T.STOPREMINDERSDATE> getdate() OR T.STOPREMINDERSDATE is NULL)
	and not (cast(T.DUEDATE as date) < cast(getdate() as date) AND ISNULL(T.MONTHLYFREQUENCY,0)=0 and ISNULL(T.MONTHSLEAD,0)=0 and ISNULL(T.DAILYFREQUENCY,0)=0 and ISNULL(T.DAYSLEAD,0)=0)
	"

	if @bCheckStatus=1
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	and     isnull(S.LETTERSALLOWED,1)=1"
	End

	Exec(@sSQLString)
End

-- Update the ALERTDATE to the next date in the future

If  @ErrorCode	 =0
and @nAlertRows  >0
and @pnUpdateFlag=1
Begin
	Set @sSQLString="
	Update	#TEMPALERT
	Set ALERTDATE=
		-- If the DueDate less the Days lead time is earlier than the Until date
		-- then calculate the next ALERTDATE using the Days lead and frequency
	CASE 	WHEN( dateadd(day,  -1 * DAYSLEAD,   DUEDATE) <= convert(nvarchar,@pdtUntilDate,112))
			THEN CASE WHEN (DAILYFREQUENCY>0)
				THEN CASE WHEN((dateadd (day,  ((datediff (day,   dateadd (day,  -1 * DAYSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ DAILYFREQUENCY)   +1)*DAILYFREQUENCY-DAYSLEAD, DUEDATE))< STOPREMINDERSDATE) OR STOPREMINDERSDATE is NULL
					THEN    dateadd (day,  ((datediff (day,   dateadd (day,  -1 * DAYSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ DAILYFREQUENCY)   +1)*DAILYFREQUENCY-DAYSLEAD, DUEDATE)
					ELSE NULL
				     END
				ELSE NULL
			     END
		-- If the DueDate less the Months lead time is earlier than the Until date
		-- and the next Monthly Reminder is earlier than the next daily reminder
		-- then calculate the next ALERTDATE using the Months lead and frequency
		WHEN((dateadd(month,-1 * MONTHSLEAD,DUEDATE) <= convert(nvarchar,@pdtUntilDate,112))
		 and ((	CASE WHEN (MONTHLYFREQUENCY>0)
				THEN CASE WHEN((dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * MONTHSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ convert(decimal(5,1),MONTHLYFREQUENCY)))   +CASE WHEN(day  (DUEDATE) - day  (convert(nvarchar,@pdtUntilDate,112)) < 1) THEN 1 ELSE 0 END)*MONTHLYFREQUENCY-MONTHSLEAD, DUEDATE))< STOPREMINDERSDATE) OR STOPREMINDERSDATE is NULL
					THEN    dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * MONTHSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ convert(decimal(5,1),MONTHLYFREQUENCY)))   +CASE WHEN(day  (DUEDATE) - day  (convert(nvarchar,@pdtUntilDate,112)) < 1) THEN 1 ELSE 0 END)*MONTHLYFREQUENCY-MONTHSLEAD, DUEDATE)
					ELSE NULL
				     END
				ELSE NULL
			END) <  isnull(dateadd(day,  -1 * DAYSLEAD,   DUEDATE),'3000-12-31 00:00:00.000')))
			THEN CASE WHEN (MONTHLYFREQUENCY>0)
				THEN CASE WHEN((dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * MONTHSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ convert(decimal(5,1),MONTHLYFREQUENCY)))   +CASE WHEN(day  (DUEDATE) - day  (convert(nvarchar,@pdtUntilDate,112)) < 1) THEN 1 ELSE 0 END)*MONTHLYFREQUENCY-MONTHSLEAD, DUEDATE))< STOPREMINDERSDATE) OR STOPREMINDERSDATE is NULL
					THEN    dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * MONTHSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ convert(decimal(5,1),MONTHLYFREQUENCY)))   +CASE WHEN(day  (DUEDATE) - day  (convert(nvarchar,@pdtUntilDate,112)) < 1) THEN 1 ELSE 0 END)*MONTHLYFREQUENCY-MONTHSLEAD, DUEDATE)
					ELSE NULL
				     END
				ELSE NULL
			     END
		-- SQA10414
		-- If the DueDate less the Months lead time is earlier than the Until date
		-- and the next Monthly Reminder is on or after the first Daily reminder but before
		-- the second daily reminder then calculate the next ALERTDATE as the first Daily reminder
		WHEN((dateadd(month,-1 * MONTHSLEAD,DUEDATE)<= convert(nvarchar,@pdtUntilDate,112))
		 and  dateadd(day,  -1 * DAYSLEAD,  DUEDATE)< isnull(STOPREMINDERSDATE,'3000-12-31 00:00:00.000')
		 and (CASE WHEN (MONTHLYFREQUENCY>0)
				THEN CASE WHEN((dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * MONTHSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ convert(decimal(5,1),MONTHLYFREQUENCY)))   +CASE WHEN(day  (DUEDATE) - day  (convert(nvarchar,@pdtUntilDate,112)) < 1) THEN 1 ELSE 0 END)*MONTHLYFREQUENCY-MONTHSLEAD, DUEDATE))< STOPREMINDERSDATE) OR STOPREMINDERSDATE is NULL
					THEN    dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * MONTHSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ convert(decimal(5,1),MONTHLYFREQUENCY)))   +CASE WHEN(day  (DUEDATE) - day  (convert(nvarchar,@pdtUntilDate,112)) < 1) THEN 1 ELSE 0 END)*MONTHLYFREQUENCY-MONTHSLEAD, DUEDATE)
					ELSE NULL
				     END
				ELSE NULL
			END
			>= isnull(dateadd(day,  -1 * DAYSLEAD,   DUEDATE),'3000-12-31 00:00:00.000')))
			THEN dateadd(day,  -1 * DAYSLEAD,   DUEDATE)
		-- If the DueDate less the Months lead time is earlier than the Until date
		-- and the next Monthly Reminder is not earlier than the first Daily reminder
		-- then calculate the next ALERTDATE using the Days lead and frequency
		WHEN((dateadd(month,-1 * MONTHSLEAD,DUEDATE) <= convert(nvarchar,@pdtUntilDate,112))
		 and ((	CASE WHEN (MONTHLYFREQUENCY>0)
				THEN CASE WHEN((dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * MONTHSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ convert(decimal(5,1),MONTHLYFREQUENCY)))   +CASE WHEN(day  (DUEDATE) - day  (convert(nvarchar,@pdtUntilDate,112)) < 1) THEN 1 ELSE 0 END)*MONTHLYFREQUENCY-isnull(MONTHSLEAD,0), DUEDATE))< STOPREMINDERSDATE) OR STOPREMINDERSDATE is NULL
					THEN    dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * MONTHSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ convert(decimal(5,1),MONTHLYFREQUENCY)))   +CASE WHEN(day  (DUEDATE) - day  (convert(nvarchar,@pdtUntilDate,112)) < 1) THEN 1 ELSE 0 END)*MONTHLYFREQUENCY-isnull(MONTHSLEAD,0), DUEDATE)
					ELSE NULL
				     END
				ELSE NULL
			END) >= isnull(dateadd(day,  -1 * DAYSLEAD,   DUEDATE),'3000-12-31 00:00:00.000')))
			THEN CASE WHEN(DAILYFREQUENCY>0)
				THEN CASE WHEN((dateadd (day,  ((datediff (day,   dateadd (day,  -1 * DAYSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ DAILYFREQUENCY)   +1)*DAILYFREQUENCY-isnull(DAYSLEAD,0), DUEDATE))< STOPREMINDERSDATE) OR STOPREMINDERSDATE is NULL
					THEN    dateadd (day,  ((datediff (day,   dateadd (day,  -1 * DAYSLEAD, DUEDATE), convert(nvarchar,@pdtUntilDate,112))/ DAILYFREQUENCY)   +1)*DAILYFREQUENCY-isnull(DAYSLEAD,0), DUEDATE)
					ELSE NULL
				     END
			     END
		-- If the DueDate less the Months lead time is before the DueDate less the 
		-- Days lead time or there is no Days lead time then the ALERTDATE will be
		-- set to the DueDate less the Months lead time if it is in the future
		WHEN(  dateadd(month,-1 * MONTHSLEAD,DUEDATE) < isnull(dateadd(day,  -1 * DAYSLEAD,   DUEDATE),'3000-12-31 00:00:00.000')
		   and dateadd(month,-1 * MONTHSLEAD,DUEDATE)> convert(nvarchar,@pdtUntilDate,112))
		   and dateadd(month,-1 * MONTHSLEAD,DUEDATE)< isnull(STOPREMINDERSDATE,'3000-12-31 00:00:00.000')
			THEN dateadd(month,-1 * MONTHSLEAD,DUEDATE)
		-- If the DueDate less the Days lead time is in the future then the ALERTDATE will be
		-- set to the DueDate less the Days lead time
		WHEN( isnull(dateadd(day,  -1 * DAYSLEAD,   DUEDATE),'01-JAN-1900')> convert(nvarchar,@pdtUntilDate,112)
		   and dateadd(day,  -1 * DAYSLEAD,DUEDATE)< isnull(STOPREMINDERSDATE,'3000-12-31 00:00:00.000'))
			THEN dateadd(day,  -1 * DAYSLEAD,   DUEDATE)
	END
	where	isnull(DAYSLEAD,0)   is not null
	or	isnull(MONTHSLEAD,0) is not null"
	
	exec @ErrorCode=sp_executesql @sSQLString,
                                N'@pdtUntilDate   datetime',
                                  @pdtUntilDate = @pdtUntilDate	  
End

------------------------------------------------------
-- Insert the EMPLOYEEREMINDER for the Alert with a 
-- future date if a row has not already been inserted.
-- Note that these reminders will not be emailed.
------------------------------------------------------
if  @ErrorCode =0
and @nAlertRows  >0
and @pnUpdateFlag=1
Begin
	set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO,  CASEID, REFERENCE, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE, SENDELECTRONICALLY, EMAILSUBJECT, ALERTNAMENO, RELATIONSHIP,
		    EVENTNO, CYCLENO, ALERTSEQ, FROMEMPLOYEENO )
	select	T.EMPLOYEENO, T.CASEID, 
		CASE WHEN (T.REFERENCE is not null) THEN T.REFERENCE
		     WHEN (T.CASEID is null and T.NAMENO is null)        
						    THEN replace(replace(convert(nvarchar,T.ALERTSEQ, 121),'-',''),' ','')
		END, 
		T.DUEDATE, 0, 1, T.SEQUENCENO, 
		CASE WHEN LEN(T.ALERTMESSAGE) <= 254 THEN T.ALERTMESSAGE ELSE NULL END,
		CASE WHEN LEN(T.ALERTMESSAGE) > 254 THEN T.ALERTMESSAGE ELSE NULL END,
			CASE WHEN(isnull(T.ALERTDATE,T.DUEDATE) > convert(varchar,getdate(),112))
				THEN isnull(T.ALERTDATE,T.DUEDATE)
				ELSE convert(varchar,getdate(),112)
			END,
		NULL, NULL, T.NAMENO, T.RELATIONSHIP,
		T.EVENTNO, T.CYCLE, T.ALERTSEQ, T.EMPLOYEENO
	from #TEMPALERT T
	left join #TEMPEMPLOYEEREMINDER E
				on ( E.NAMENO=T.EMPLOYEENO
				and  E.SEQUENCENO=T.SEQUENCENO
				and (E.CASEID=T.CASEID
				 or  E.ALERTNAMENO=T.NAMENO
				 or  E.REFERENCE=T.REFERENCE
				 or  E.REFERENCE=replace(replace(convert(nvarchar,T.ALERTSEQ, 121),'-',''),' ','') ) )"

	if @bCheckStatus=1
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	left join CASES C	on (C.CASEID=T.CASEID)"
					  +char(10)+"	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)"
	End
	
	Set @sSQLString=@sSQLString+"
	where   E.NAMENO is null
	and    (T.ALERTDATE is not null OR T.DUEDATE is not null)
	and    (T.OCCURREDFLAG = 0 OR T.OCCURREDFLAG is NULL)  
	and    (T.DATEOCCURRED     > isnull(T.ALERTDATE,T.DUEDATE) OR T.DATEOCCURRED      is NULL) 
	and    (T.STOPREMINDERSDATE> isnull(T.ALERTDATE,T.DUEDATE) OR T.STOPREMINDERSDATE is NULL)
	and     T.ALERTMESSAGE is not null
	and not (cast(T.DUEDATE as date) < cast(getdate() as date) AND ISNULL(T.MONTHLYFREQUENCY,0)=0 and ISNULL(T.MONTHSLEAD,0)=0 and ISNULL(T.DAILYFREQUENCY,0)=0 and ISNULL(T.DAYSLEAD,0)=0)
	"


	if @bCheckStatus=1
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	and     isnull(S.REMINDERSALLOWED,1)=1"
	End
	

	Exec(@sSQLString)

	Select	@ErrorCode=@@Error,
		@nReminders=@nReminders+@@Rowcount

	If  @nReminders>0
	and @nCriticalStaff is not null
	and @ErrorCode=0
	Begin
		------------------------------------------
		-- The reminder recipient is the Name
		-- specified to receive Critical Reminders
		------------------------------------------
		set @sSQLString="
		insert into #TEMPEMPLOYEEREMINDER (NAMENO,  CASEID, REFERENCE, DUEDATE,  
			    READFLAG, SOURCE, SEQUENCENO, SHORTMESSAGE, LONGMESSAGE, REMINDERDATE, SENDELECTRONICALLY, EMAILSUBJECT, ALERTNAMENO, RELATIONSHIP,
			    EVENTNO, CYCLENO, FROMEMPLOYEENO )
		select	@nCriticalStaff, T.CASEID, 
			CASE WHEN (T.REFERENCE is not null) THEN T.REFERENCE
			     WHEN (T.CASEID is null and T.NAMENO is null)        
							    THEN replace(replace(convert(nvarchar,T.ALERTSEQ, 121),'-',''),' ','')
			END, 
			T.DUEDATE, 0, 1, T.SEQUENCENO, 
			CASE WHEN LEN(T.ALERTMESSAGE) <= 254 THEN T.ALERTMESSAGE ELSE NULL END,
			CASE WHEN LEN(T.ALERTMESSAGE) > 254 THEN T.ALERTMESSAGE ELSE NULL END,
			CASE WHEN(isnull(T.ALERTDATE,T.DUEDATE) > convert(varchar,getdate(),112))
				THEN isnull(T.ALERTDATE,T.DUEDATE)
				ELSE convert(varchar,getdate(),112)
			END,
			T.SENDELECTRONICALLY, T.EMAILSUBJECT, T.NAMENO, T.RELATIONSHIP,
			T.EVENTNO, T.CYCLE, T.EMPLOYEENO
		from #TEMPALERT T
		     join NAME N	on (N.NAMENO=@nCriticalStaff)
		left join #TEMPEMPLOYEEREMINDER E
					on ( E.NAMENO=T.EMPLOYEENO
					and  E.SEQUENCENO=T.SEQUENCENO
					and (E.CASEID=T.CASEID
					 or  E.ALERTNAMENO=T.NAMENO
					 or  E.REFERENCE=T.REFERENCE))"

		if @bCheckStatus=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+"		left join CASES C	on (C.CASEID=T.CASEID)"
						   +char(10)+"		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)"
		End

		set @sSQLString=@sSQLString+"
		where   E.NAMENO is null
		and    (T.ALERTDATE is not null OR T.DUEDATE is not null)
		and    (T.OCCURREDFLAG = 0 OR T.OCCURREDFLAG is NULL)  
		and    (T.DATEOCCURRED     > isnull(T.ALERTDATE,T.DUEDATE) OR T.DATEOCCURRED      is NULL) 
		and    (T.STOPREMINDERSDATE> isnull(T.ALERTDATE,T.DUEDATE) OR T.STOPREMINDERSDATE is NULL)
		and	T.CRITICALFLAG=1
		and	T.ALERTMESSAGE is not null
		and not (cast(T.DUEDATE as date) < cast(getdate() as date) AND ISNULL(T.MONTHLYFREQUENCY,0)=0 and ISNULL(T.MONTHSLEAD,0)=0 and ISNULL(T.DAILYFREQUENCY,0)=0 and ISNULL(T.DAYSLEAD,0)=0)
		"


		if @bCheckStatus=1
		Begin
			Set @sSQLString=@sSQLString+char(10)+"		and     isnull(S.REMINDERSALLOWED,1)=1"
		End

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nCriticalStaff	int',
					  @nCriticalStaff=@nCriticalStaff

		Set @nReminders=@nReminders+@@Rowcount
	End
End

-------------------------------------------------------------
-- The Alert rule may specify a RELATIONSHIP to be used 
-- to determine the recipient of the reminder. It is possible 
-- for multiple Names to be found.
-------------------------------------------------------------
If  @ErrorCode=0
and @nReminders>0
Begin
	Set @sSQLString="
	insert into #TEMPEMPLOYEEREMINDER (NAMENO, CASEID, EVENTNO, CYCLENO, CRITERIANO, DUEDATE,  
		    READFLAG, SOURCE, SEQUENCENO, DATEUPDATED, EVENTDESCRIPTION,  SENDELECTRONICALLY, EMAILSUBJECT,
		    RELATIONSHIP, SHORTMESSAGE,  REMINDERDATE, FROMEMPLOYEENO)
	select	A.RELATEDNAME, T.CASEID, T.EVENTNO, T.CYCLENO, T.CRITERIANO, T.DUEDATE,  
		    T.READFLAG, T.SOURCE, T.SEQUENCENO, T.DATEUPDATED, T.EVENTDESCRIPTION,  T.SENDELECTRONICALLY, T.EMAILSUBJECT,
		    NULL, T.SHORTMESSAGE, T.REMINDERDATE, T.FROMEMPLOYEENO
	from #TEMPEMPLOYEEREMINDER T
	join ASSOCIATEDNAME A	on (A.NAMENO=T.NAMENO
				and A.RELATIONSHIP=T.RELATIONSHIP)
	join CASES C		on (C.CASEID=T.CASEID)
	left join #TEMPEMPLOYEEREMINDER T1
				on (T1.NAMENO=A.RELATEDNAME
				and T1.CASEID=T.CASEID
				and T1.SEQUENCENO=T.SEQUENCENO)"

	if @bCheckStatus=1
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)"
	End

	set @sSQLString=@sSQLString+"
	where T1.NAMENO is null
	and T.SOURCE=1
	and checksum(A.PROPERTYTYPE,A.COUNTRYCODE)
		=(	select 
			convert(int,
			substring(
			min (
			CASE WHEN (A1.PROPERTYTYPE IS NULL) THEN '1' ELSE '0' END +			
			CASE WHEN (A1.COUNTRYCODE  IS NULL) THEN '1' ELSE '0' END +
			convert(char(11),checksum(A1.PROPERTYTYPE,A1.COUNTRYCODE)) ), 3,11))
			from ASSOCIATEDNAME A1
			where A1.NAMENO=T.NAMENO
			and   A1.RELATIONSHIP=T.RELATIONSHIP
			and (A1.PROPERTYTYPE=C.PROPERTYTYPE or A1.PROPERTYTYPE is null)
			and (A1.COUNTRYCODE =C.COUNTRYCODE  or A1.COUNTRYCODE  is null)
			and (A1.ACTION      is null) )"

	if @bCheckStatus=1
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	and     isnull(S.REMINDERSALLOWED,1)=1"
	End

	exec @ErrorCode=sp_executesql @sSQLString

	set @nRowCount=@nRowCount+@@rowcount
End

-- Note we are trying to keep track if any Reminders at all are being inserted so the 
-- @nRowCount was previously loaded if reminders were loaded in the ipu_PoliceInsertReminders procedure.

If  @ErrorCode=0
and @nReminders>0
	Set @nRowCount=@nRowCount+@nReminders

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceInsertAlerts',0,1,@sTimeStamp ) with NOWAIT
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceInsertAlerts  to public
go
