-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetEvents
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetEvents.'
	drop procedure dbo.ip_PoliceGetEvents
end
print '**** Creating procedure dbo.ip_PoliceGetEvents...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetEvents 
			@pnRowCount		int	OUTPUT,
			@pnDebugFlag		tinyint,
			@psIRN			nvarchar(30),
			@psOfficeId		nvarchar(254),
			@psPropertyType		char(1),
			@psCountryCode		nvarchar(3),
			@pdtDateOfAct		datetime,
			@psAction		nvarchar(2),
			@pnEventNo		int,
			@psNameType		nvarchar(3),
			@pnNameNo		int,
			@psCaseType		char(1),
			@psCaseCategory		nvarchar(2),
			@psSubtype		nvarchar(2),
			@pnExcludeProperty	decimal(1,0),
			@pnExcludeCountry	decimal(1,0),
			@pnExcludeAction	decimal(1,0),
			@pnCaseid		int,
			@pnTypeOfRequest	smallint,
			@pdtFromDate		datetime,
			@pdtUntilDate		datetime,
			@pnDueDateRange		smallint

as
-- PROCEDURE :	ip_PoliceGetEvents
-- VERSION :	41
-- DESCRIPTION:	A procedure to load the temporary tables #TEMPCASES & #TEMPOPENACTION with those rows to be be policed
-- CALLED BY :	ipu_PoliceRecalc

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 07/06/2001	MF			Procedure created
-- 13/10/2001	MF	7115		When Policing returns events to be processed it should also allow 
--					for the fact that the Event can belong to more than one Action 
-- 18/10/2001	MF	7130		The OCCURREDFLAG is to be set to 0 if it does not exist.
-- 18/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 01/03/2002	MF	7367 		Get ESTIMATEFLAG from the EventControl table for later charges raising.
-- 12/03/2002	MF	7485		Change the function USER to SYSTEM_USER
-- 22/07/2002	MF	7750		Increase IRN to 30 characters
-- 24/07/2002	MF	7864		Correction to 7484.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 24 Jul 2003	MF	8260	10	Get PTADELAY from the EventControl table for Patent Term Adjustment calculation
-- 28 Jul 2003	MF	8673	10	If a single Office is stored against the Case rather than multiple offices
--					stored in TABLEATTRIBUTES then modify the row level security
-- 08 Jan 2004	MF	9537	11	Only perform row level security if a Site Control is turned on.
-- 18 Mar 2004	MF	9823	12	Row level security causing a GPF crash in SQLServer.  To get around this bug
--					in SQLServer the subselect used in the Row Level Security needed to be modified.
--					The solution implement changed the list of valid SECURITYFLAG from an "IN" clause
--					to a BETWEEN.  Another solution (not implemented) that was found was to remove 
--					SYSTEM_USER from the Select and actually embed the value into the code
-- 19 Mar 2004	MF	9824	13	Return CaseEvent rows where the DueDate is within the date range and there are
--					reminder rules associated with the CaseEvent.  This is to ensure that CaseEvents
--					will be considered even if the DateRemind is not correct.
-- 10 May 2004	MF	10022	14	Recalculate CaseEvent rows that are missing both the EVENTDATE and EVENTDUEDATE.
-- 18 Jun 2004	MF	10195	15	Determine how to get the office associated with a Case by checking the 
--					Site Control "Row Security Uses Case Office"
-- 30 Jun 2004	MF	10239	16	Size of SQL is exceeding 4000 characters. Restructure.
-- 03 Nov 2004	MF	10589	17	Modify the row level security code to improve performance where multiple
--					offices are allowed to exist for a Case.
-- 03 Nov 2004	MF	10385	18	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 15 Nov 2004	MF	10659	19	Row Level Security is not returning the correct Cases to police when NT
--					security is in use.
-- 10 Feb 2005	MF	10995	20	Manually entered due dates should be marked for recalculation so as to 
--					check that no other event is now satisfying the due date.
-- 08 Mar 2005	MF	11122	21	Store the USERID and IDENTITYID against the #TEMPCASES rows.
-- 04 Apr 2005	MF	11233	22	Override the Due Date Range value if the date used in the FromDate 
--					is earlier.
-- 07 Jul 2005	MF	11011	23	Increase CaseCategory column size to NVARCHAR(2)
-- 15 May 2006	MF	12315	24	New EventControl columns to set CASENAME when Event occurs.
-- 06 Jun 2006	MF	12723	25	When inserting rows into #TEMPCASES ensure that NULLs are replaced with
--					zero for RECALCULATEPTA, IPODELAY and APPLICANTDELAY
-- 07 Jun 2006	MF	12417	26	Change order of columns returned in debug mode to make it easier to review
-- 21 Aug 2006	MF	13089	27	Get the DIRECTPAYFLAG from EventControl for later raising of charges.
-- 10 Aug 2007	MF	12548	28	Load #TEMPCASES.OFFICEID
-- 24 May 2007	MF	14812	29	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	30	Reserve word [STATE]
-- 24 Oct 2007	MF	15508	31	Only mark Events to be calculated if there is a missing EVENTDATE and EVENTDUEDATE.
--					Previously we recalculated every Event returned by this procedure however this 
--					is overkill as there is an explicit option available from Policing Request if
--					the due dates are to be recalculated. 
-- 29 Oct 2007	MF	15518	31	Insert LIVEFLAG on #TEMPCASEEVENT
-- 07 Nov 2007	MF	15187	31	Provide the ability filter by one or more offices.
-- 07 Jan 2008	MF	15586	32	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 11 Dec 2008	MF	17136	33	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 01 Jul 2011	MF	10929	34	Keep track of when the CASES and PROPERTY rows were last updated so that we can check that no changes
--					have been applied to the database when Policing attempts to update these.
-- 24 Feb 2012	MF	R11985	35	Provide the ability for a unicode value to be used as the NameType.
-- 05 Jun 2012	MF	S19025	36	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 06 Jun 2013	MF	S21404	37	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 14 Nov 2013	MF	S21776	38	SQL Error occuring where Row Level Security is in place. An introduced problem resulting from a code restructure.
-- 15 Mar 2017	MF	70049	39	Allow Renewal Status to be separately specified to be updated by an Event.
-- 26 Oct 2017	MF	72047	40	Ethical Wall restrictions of Cases are to be applied.
-- 14 Nov 2018  AV  75198/DR-45358	41   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on
set concat_null_yields_null off

DECLARE		@ErrorCode		int,
		@nOpenActionCount	int,
		@nUserIdentityId	int,
		@sInsertString		nvarchar(max),
		@sWhereClause		nvarchar(max),
		@sUser			nvarchar(255),
		@sCaseJoin		nvarchar(200),
		@dtStartDueDate		datetime,
		@bRowLevelSecurity	bit,
		@bCaseOffice		bit,
		@bBlockCaseAccess	bit

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode       = 0
Set @nOpenActionCount=0

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
	Set @sCaseJoin = 'join dbo.fn_CasesEthicalWall('+cast(@nUserIdentityId as nvarchar)+') C on (C.CASEID=CE.CASEID)'
End
Else
Begin
	Set @sCaseJoin = 'join CASES C ON C.CASEID=CE.CASEID'
End

-- Calculate the starting date used for checking the EVENTDUEDATE

If @pnDueDateRange is null
Begin
	Set @dtStartDueDate=Null
End
Else Begin
	Set @dtStartDueDate = convert(nvarchar,getdate(),112)
	Set @dtStartDueDate = dateadd(day, @pnDueDateRange*-1, @dtStartDueDate)

	--SQA11233
	If @pdtFromDate<@dtStartDueDate
	Begin
		Set @dtStartDueDate=@pdtFromDate
	End
End

-- Adjust the End Date so that its time is the last second of the day
set @pdtUntilDate = dateadd(s, 86399, @pdtUntilDate)

-- Load #TEMPCASES with the details of the Cases to be recalculated. 

-- Construct the SQL to load the TEMPCASES table based on the parameters passed to this procedure

set @sInsertString = "
		insert into #TEMPCASEEVENT
		(CASEID,DISPLAYSEQUENCE,EVENTNO,CYCLE,LOOPCOUNT,OLDEVENTDATE,OLDEVENTDUEDATE,DATEDUESAVED,
		OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ENTEREDDEADLINE,PERIODTYPE,DOCUMENTNO,
		DOCSREQUIRED,DOCSRECEIVED,USEMESSAGE2FLAG,GOVERNINGEVENTNO,[STATE],ADJUSTMENT,
		IMPORTANCELEVEL,WHICHDUEDATE,COMPAREBOOLEAN,CHECKCOUNTRYFLAG,SAVEDUEDATE,STATUSCODE,RENEWALSTATUS,
		SPECIALFUNCTION,INITIALFEE,PAYFEECODE,CREATEACTION,STATUSDESC,CLOSEACTION,RELATIVECYCLE,
		INSTRUCTIONTYPE,FLAGNUMBER,SETTHIRDPARTYON,COUNTRYCODE,USERID,NEWEVENTDUEDATE,
		USEDINCALCULATION,DATEREMIND,CRITERIANO,ACTION,ESTIMATEFLAG,
		EXTENDPERIOD,EXTENDPERIODTYPE,INITIALFEE2,PAYFEECODE2,ESTIMATEFLAG2,PTADELAY,SETTHIRDPARTYOFF,
		CHANGENAMETYPE,COPYFROMNAMETYPE,COPYTONAMETYPE,DELCOPYFROMNAME,DIRECTPAYFLAG,DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE,RECALCEVENTDATE,SUPPRESSCALCULATION)
		
		SELECT CE.CASEID,E.DISPLAYSEQUENCE,CE.EVENTNO,CE.CYCLE,
		0,CE.EVENTDATE,CE.EVENTDUEDATE,isnull(CE.DATEDUESAVED,0),isnull(CE.OCCURREDFLAG,0),CE.CREATEDBYACTION,CE.CREATEDBYCRITERIA,
		CE.ENTEREDDEADLINE,CE.PERIODTYPE,CE.DOCUMENTNO,CE.DOCSREQUIRED,CE.DOCSRECEIVED,CE.USEMESSAGE2FLAG,
		CE.GOVERNINGEVENTNO,
		CASE WHEN(CE.EVENTDATE is NULL AND CE.EVENTDUEDATE is NULL) THEN 'C' ELSE CASE WHEN(E.SAVEDUEDATE in (4,5) and E.CASETYPE is not NULL) THEN 'R1' ELSE CASE WHEN(E.SAVEDUEDATE=8) THEN 'C' ELSE 'R' END END END,
		NULL,E.IMPORTANCELEVEL,E.WHICHDUEDATE,E.COMPAREBOOLEAN,E.CHECKCOUNTRYFLAG,
		E.SAVEDUEDATE,E.STATUSCODE,E.RENEWALSTATUS,E.SPECIALFUNCTION,E.INITIALFEE,E.PAYFEECODE,E.CREATEACTION,E.STATUSDESC,
		E.CLOSEACTION,E.RELATIVECYCLE,E.INSTRUCTIONTYPE,E.FLAGNUMBER,E.SETTHIRDPARTYON,C.COUNTRYCODE,SYSTEM_USER,
		CE.EVENTDUEDATE,
		CASE WHEN(CE.EVENTDATE is NULL and CE.EVENTDUEDATE is NULL) THEN 'Y' END,
		CE.DATEREMIND,OA.CRITERIANO,OA.ACTION,E.ESTIMATEFLAG,
		E.EXTENDPERIOD,E.EXTENDPERIODTYPE,E.INITIALFEE2,E.PAYFEECODE2,E.ESTIMATEFLAG2,E.PTADELAY,E.SETTHIRDPARTYOFF,
		E.CHANGENAMETYPE,E.COPYFROMNAMETYPE,E.COPYTONAMETYPE,E.DELCOPYFROMNAME,E.DIRECTPAYFLAG,E.DIRECTPAYFLAG2,1,
		E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE,E.RECALCEVENTDATE,E.SUPPRESSCALCULATION
		from CASEEVENT CE" +CHAR(10)+
		
		@sCaseJoin + 
		
		CASE WHEN(@bRowLevelSecurity = 1 AND @bCaseOffice = 1)
			THEN char(10)+"		join dbo.fn_CasesRowSecurity("+cast(@nUserIdentityId as nvarchar)+") RS on (RS.CASEID=CE.CASEID AND RS.UPDATEALLOWED=1)"
		     WHEN(@bRowLevelSecurity = 1)
			THEN char(10)+"		join dbo.fn_CasesRowSecurityMultiOffice("+cast(@nUserIdentityId as nvarchar)+") RS on (RS.CASEID=CE.CASEID AND RS.UPDATEALLOWED=1)"
			ELSE ''
		END + "

		join OPENACTION OA	on (OA.CASEID=CE.CASEID
					and OA.POLICEEVENTS=1)
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		join EVENTCONTROL E	on (E.CRITERIANO=OA.CRITERIANO
					and E.EVENTNO	=CE.EVENTNO)
		left join (	select CRITERIANO, EVENTNO
				from REMINDERS
				group by CRITERIANO, EVENTNO) R
					on (R.CRITERIANO=E.CRITERIANO
					and R.EVENTNO   =E.EVENTNO)
		left join PROPERTY P    on (P.CASEID=C.CASEID)
		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
		left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)"

set @sWhereClause="
		where (CE.OCCURREDFLAG=0 OR CE.OCCURREDFLAG is null)
		and   (S.STATUSCODE  is null or	(S.POLICERENEWALS=1     and A.ACTIONTYPEFLAG=1)
				     or	(S.POLICEEXAM=1         and A.ACTIONTYPEFLAG=2)
				     or	(S.POLICEOTHERACTIONS=1 and A.ACTIONTYPEFLAG=0)
				     or	(S.POLICERENEWALS+S.POLICEEXAM+S.POLICERENEWALS >1 and A.ACTIONTYPEFLAG is null))
		and   (S1.STATUSCODE is null or (S1.POLICERENEWALS=1    and A.ACTIONTYPEFLAG=1)
				     or (A.ACTIONTYPEFLAG <>1	or  A.ACTIONTYPEFLAG is null))
		and  ((CE.CYCLE>=OA.CYCLE and A.NUMCYCLESALLOWED=1) OR (CE.CYCLE=OA.CYCLE AND  A.NUMCYCLESALLOWED>1))"

if @bBlockCaseAccess=1
begin
	Set @sWhereClause=@sWhereClause+char(10)+"and 1=0"
End

if @pdtFromDate is not null
begin
	set @sWhereClause=@sWhereClause+char(10)+"and ((CE.DATEREMIND between '"+convert(nvarchar,@pdtFromDate)+"' and '"+convert(nvarchar,@pdtUntilDate)+"')"
end
else begin
	set @sWhereClause=@sWhereClause+char(10)+"and ((CE.DATEREMIND <= '"+convert(nvarchar,@pdtUntilDate)+"')"
end

if @dtStartDueDate is not null
begin
	set @sWhereClause=@sWhereClause+"OR (CE.EVENTDUEDATE between '"+convert(nvarchar,@dtStartDueDate)+"' and '"+convert(nvarchar,@pdtUntilDate)+"' AND (E.SAVEDUEDATE in (4,5,8) OR (R.CRITERIANO is not null AND CE.DATEREMIND is null))) OR (CE.EVENTDATE is NULL AND CE.EVENTDUEDATE is NULL))"
end
else begin
	set @sWhereClause=@sWhereClause+"OR (CE.EVENTDUEDATE <= '"+convert(nvarchar,@pdtUntilDate)+"' AND (E.SAVEDUEDATE in (4,5,8) OR (R.CRITERIANO is not null AND CE.DATEREMIND is null))) OR (CE.EVENTDATE is NULL AND CE.EVENTDUEDATE is NULL))"
end

-- Continue building the WHERE clause based on the parameters passed to the procedure
-- If IRN or CASEID is passed then no additional parameters need to be looked at.

if @psIRN is not null
begin
	set @sWhereClause=@sWhereClause+char(10)+"and C.IRN='"+@psIRN+"'"
end
else if @pnCaseid is not null
begin
	set @sWhereClause=@sWhereClause+char(10)+"and C.CASEID="+convert(nvarchar,@pnCaseid)
end
else begin
	if @psOfficeId is not null
	begin
		set @sWhereClause=@sWhereClause+char(10)+"and C.OFFICEID in ("+@psOfficeId+")"
	end
	
	if @psPropertyType is not null
	begin
		if @pnExcludeProperty=1
		begin
			set @sWhereClause=@sWhereClause+char(10)+"and (C.PROPERTYTYPE is null OR C.PROPERTYTYPE<>'"+@psPropertyType+"')"
		End
		else begin
			set @sWhereClause=@sWhereClause+char(10)+"and C.PROPERTYTYPE='"+@psPropertyType+"'"
		End
	end
	
	if @psCountryCode is not null
	begin
		if @pnExcludeCountry=1
		begin
			set @sWhereClause=@sWhereClause+char(10)+"and (C.COUNTRYCODE is null OR C.COUNTRYCODE<>'"+@psCountryCode+"')"
		End
		else begin
			set @sWhereClause=@sWhereClause+char(10)+"and C.COUNTRYCODE='"+@psCountryCode+"'"
		End
	end

	if @psCaseType is not null
	begin
		set @sWhereClause=@sWhereClause+char(10)+"and C.CASETYPE='"+@psCaseType+"'"
	end

	if @psCaseCategory is not null
	begin
		set @sWhereClause=@sWhereClause+char(10)+"and C.CASECATEGORY='"+@psCaseCategory+"'"
	end
	
	if @psSubtype is not null
	begin
		set @sWhereClause=@sWhereClause+char(10)+"and C.SUBTYPE='"+@psSubtype+"'"
	end
	
	--  If NAMENO or NAMETYPE are passed then a JOIN on the CASENAME table is required

	if @pnNameNo   is not null
	or @psNameType is not null
	begin
		set @sInsertString = @sInsertString+char(10)+"join CASENAME CN   on (CN.CASEID=C.CASEID"
	
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

-- Filter on the Action if it was passed as a parameter

if @psAction is not null
begin
	if @pnExcludeAction=1
	begin
		set @sWhereClause=@sWhereClause+char(10)+"and OA.ACTION<>'"+@psAction+"'"
	End
	else begin
		set @sWhereClause=@sWhereClause+char(10)+"and OA.ACTION='"+@psAction+"'"
	End

	if @pdtDateOfAct is not null
	begin
		set @sWhereClause=@sWhereClause+char(10)+"and OA.DATEFORACT='"+convert(nvarchar,@pdtDateOfAct,112)+"'"
	end
end

-- Filter on the EVENTNO if it was passed as a parameter

if @pnEventNo is not null
begin
	set @sWhereClause=@sWhereClause+char(10)+"and CE.EVENTNO="+convert(nvarchar,@pnEventNo)
end

-- If Row Access security is in use then only return rows where the user has update rights to the Case.

If exists (	SELECT *                    
		FROM ROWACCESSDETAIL R 
		join USERROWACCESS U on (U.ACCESSNAME = R.ACCESSNAME)
		join SITECONTROL S   on (S.CONTROLID='Policing Uses Row Security'
				     and S.COLBOOLEAN=1)
		WHERE R.RECORDTYPE = 'C')
and isnull(@bRowLevelSecurity,0)=0		-- Row security for UserIdentityId has not been applied
Begin
	-- Get the current logged on user to determine what Row Level Security
	-- restrictions apply to that user.  Wrap the string in the appriate quotes
	-- so it can be embedded into the SQL Statement.

	Set @sUser=dbo.fn_WrapQuotes(dbo.fn_SystemUser(),0,0)

	-- If multiple offices are allowed to be stored then get the Office from 
	-- the TABLEATTRIBUTES table otherwise get it from the CASES table
	If not exists(	SELECT 1 		--SQA10195
			FROM SITECONTROL
			WHERE CONTROLID='Row Security Uses Case Office'
			AND COLBOOLEAN=1)
	begin
		set @sWhereClause=@sWhereClause	+"
					and Substring(
					(select MAX (
					 CASE WHEN OFFICE	 IS NULL THEN '0' ELSE '1' END+
					 CASE WHEN CASETYPE	 IS NULL THEN '0' ELSE '1' END+
					 CASE WHEN PROPERTYTYPE IS NULL THEN '0' ELSE '1' END+
					 CASE WHEN SECURITYFLAG < 10	THEN '0' END+        -- pack a single digit flag with zero
					 convert(nvarchar,SECURITYFLAG))
					 from USERROWACCESS UA
					 left join ROWACCESSDETAIL RAD on (RAD.ACCESSNAME=UA.ACCESSNAME
					 				and(RAD.OFFICE       in (select TA.TABLECODE from TABLEATTRIBUTES TA where TA.PARENTTABLE='CASES' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, C.CASEID))   
									 or RAD.OFFICE       is NULL)
					 				and(RAD.CASETYPE     = C.CASETYPE     or RAD.CASETYPE     is NULL)
					  				and(RAD.PROPERTYTYPE = C.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL)
					  				and RAD.RECORDTYPE = 'C')
					 where UA.USERID="+@sUser+"),4,2) -- end of Substring
					 between '08' and '15'"         -- list of SECURITYFLAG with UPDATE set ON 	-- SQA9823
	end
	else begin
		set @sWhereClause=@sWhereClause	+"
					and Substring(
					(select MAX (
					 CASE WHEN OFFICE	   IS NULL THEN '0' ELSE '1' END+
					 CASE WHEN CASETYPE	   IS NULL THEN '0' ELSE '1' END+
					 CASE WHEN PROPERTYTYPE IS NULL THEN '0' ELSE '1' END+
					 CASE WHEN SECURITYFLAG < 10	THEN '0' END+        -- pack a single digit flag with zero
					 convert(nvarchar,SECURITYFLAG))
					 from USERROWACCESS UA
					 left join ROWACCESSDETAIL RAD on(RAD.ACCESSNAME=UA.ACCESSNAME
									 and(RAD.OFFICE       = C.OFFICEID     or RAD.OFFICE       is NULL)
									 and(RAD.CASETYPE     = C.CASETYPE     or RAD.CASETYPE     is NULL)
									 and(RAD.PROPERTYTYPE = C.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL)
									 and RAD.RECORDTYPE = 'C')
					 where UA.USERID="+@sUser+"),4,2)
					 between '08' and '15'"        -- list of SECURITYFLAG with UPDATE set ON 	-- SQA9823
	end
End

-- Now execute the dynamically created Insert.
exec (@sInsertString+@sWhereClause)

Select 	@ErrorCode=@@Error,
	@pnRowCount=@@Rowcount

-- Load #TEMPCASES with the details of the Cases being processed.

If  @ErrorCode=0
and @pnRowCount>0
Begin
	Set @sInsertString="
	insert #TEMPCASES (CASEID, STATUSCODE, RENEWALSTATUS, REPORTTOTHIRDPARTY, PREDECESSORID, ACTION,  
			   EVENTNO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
			   BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE,RENEWALTYPE, INSTRUCTIONSLOADED,IPODELAY,
			   APPLICANTDELAY,USERID,IDENTITYID,OFFICEID,CASELOGSTAMP,PROPERTYLOGSTAMP)

	select	distinct C.CASEID, C.STATUSCODE, P.RENEWALSTATUS, C.REPORTTOTHIRDPARTY,C.PREDECESSORID, null, 
			 null, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE,
			 P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, 0,isnull(C.IPODELAY,0),
			 isnull(C.APPLICANTDELAY,0),T.USERID,T.IDENTITYID,C.OFFICEID,C.LOGDATETIMESTAMP,P.LOGDATETIMESTAMP
	from CASES C
	join #TEMPCASEEVENT T	on (T.CASEID=C.CASEID)
	left join PROPERTY P	on (P.CASEID=C.CASEID)"

	Execute @ErrorCode=sp_executesql @sInsertString

	Set @pnRowCount=@@Rowcount
End

-- If new Cases were loaded then load the associated CaseEvents

If @ErrorCode=0
and @pnRowCount>0
Begin
	Execute @ErrorCode=ip_PoliceGetEventsForTempTable @pnDebugFlag
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetEvents',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sInsertString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*, @pnRowCount as 'Row Count' 
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		exec @ErrorCode= sp_executesql @sInsertString,
						N'@pnRowCount	int',
						  @pnRowCount
	End
End

-- Load #TEMPOPENACTION with the details of the Actions to be processed. 

If  @ErrorCode=0
and @pnRowCount>0
Begin
	execute @ErrorCode = dbo.ip_PoliceGetActions @nOpenActionCount	OUTPUT,
						     @pnDebugFlag	

End

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetEvents  to public
go
