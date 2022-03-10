-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CaseEventRuleDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_CaseEventRuleDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_CaseEventRuleDetails.'
	drop procedure dbo.cs_CaseEventRuleDetails
end
print '**** Creating procedure dbo.cs_CaseEventRuleDetails...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE procedure [dbo].[cs_CaseEventRuleDetails]	
		@pnUserIdentityId		int,			-- Mandatory
		@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed	
		@pnCaseId			int,			-- Key of Case 
		@pnEventNo			int,			-- Key of Event
		@pnCycle			int		= null,	-- Cycle of Case Event row
		@psAction			nvarchar(2)	= null	-- The Action under which the Event has been defined
		  
as
---PROCEDURE :	cs_CaseEventRuleDetails
-- VERSION :	15
-- DESCRIPTION:	This procedure returns details about the specific Case Event that has been passed to it.
--		Multiple result sets are returned for each of the details that describe the rules behind the Case Event.
--		The details that can be returned include :
--			EventControl Details (1 row)
--			IRN, CRITERIANO, EVENTNO, EVENTDATE, EVENTDUEDATE, DATEREMIND, EVENTDESCRIPTION, NUMCYCLESALLOWED, WHICHDUEDATE, COMPAREBOOLEAN, SAVEDUEDATE, UPDATEEVENTIMMEDIATELY, UPDATEWHENDUE, EXTENDPERIOD, EXTENDPERIODTYPE, RECALCEVENTDATE, IPOFFICEDELAY, APPLICANTDELAY, STATUS, CHARGEDESC, PAYFEECODE, CREATEACTION, CLOSEACTION, INSTRUCTIONTYPE, INSTRUCTIONFLAG, SETTHIRDPARTYON, SETTHIRDPARTYOFF, IMPORTANCELEVEL, EVENTTEXT, NOTES, LOGDATETIMESTAMP, LOGUSERID, LOGAPPLICATION
--
--			Related Case Details (1 row)
--			UPDATEFROMEVENT, FROMEVENTDESC, FROMRELATIONSHIP, ADJUSTMENT, FROMIRN, RELATEDCASEID, FROMEVENTDATE, FROMEVENTCYCLE, LOADNUMBERTYPE
--
--			Due Date Calculations (multiple rows)
--			CASEID, FROMEVENT, FROMDATE, FROMCYCLE, FROMEVENTDESC, RELATIVECYCLE, OPERATOR, DEADLINEPERIOD, PERIODTYPE, EVENTDATEFLAG, MUSTEXIST, WORKDAY, MESSAGE2FLAG, SUPPRESSREMINDERS, OVERRIDELETTER, ADJUSTMENT
--
--			Date Comparison (multiple rows)
--			CASEID, FROMEVENT, FROMDATE, FROMCYCLE, FROMEVENTDESC, RELATIVECYCLE, COMPARISON, COMPARISONIRN, COMPARARISONCASEID, COMPAREEVENT, COMPARISONDATE, COMPARISONCYCLENO, COMPAREEVENTDESC, COMPARECYCLE, COMPARERELATIONSHIP, COMPAREEVENTFLAG, COMPAREDATE, COMPARESYSTEMDATE
--
--			Related Events (multiple rows)
--			RELATEDEVENT, RELATEDEVENTDESC, UPDATEEVENT, SATISFYEVENT, CLEAREVENT, CLEARDUE, CLEAREVENTONDUECHANGE, CLEARDUEONDUECHANGE, RELATIVECYCLE, ADJUSTMENT, CASEID, RELATEDEVENTDATE, RELATEDEVENTCYCLE
--
--			Reminders (multiple rows)
--			LEADTIME, PERIODTYPE, FREQUENCY, FREQPERIODTYPE, STOPTIME, STOPTIMEPERIODTYPE, EMPLOYEENAMETYPE, SIGNATORYNAMETYPE, INSTRUCTORNAMETYPE, CRITICALFLAG, REMINDERNAME, NAMETYPE, RELATIONSHIP, SENDELECTRONICALLY, EMAILSUBJECT, USEBEFOREDUEDATE
--
--			Letters (multiple rows)
--			LEADTIME, PERIODTYPE, FREQUENCY, FREQPERIODTYPE, STOPTIME, STOPTIMEPERIODTYPE, MAXLETTERS, LETTERNO, LETTERNAME, CHECKOVERRIDE, UPDATEEVENT, LETTERFEE, PAYFEECODE, ESTIMATEFLAG, DIRECTPAYFLAG
--
--			Dates Logic (multiple rows)
--			DATETYPE, OPERATOR, COMPAREEVENT, COMPAREEVENTDESC, MUSTEXIST, RELATIVECYCLE, COMPARISONIRN, COMPARARISONCASEID, COMPARISONEVENTNO, COMPARISONCYCLENO, COMPARISONDATE, CASERELATIONSHIP, COMPARERELATIONSHIP, COMPAREDATETYPE, DISPLAYERRORFLAG, ERRORMESSAGE
--			
--------------------------------------------------------------------------------------------------------------
--	
-- MODIFICATION
-- Date		Who	No	Version	Description
-- ====         ===	=== 	=======	=====================================================================
-- 08 Mar 2011	MF	9319	1	Procedure created.
-- 21 Mar 2011	MF	9319	2	Ensure Action is correctly defaulted if not provided and also return the IRN of the Case.
-- 22 Mar 2011	MF	9319	3	Return the ACTION from where the rules have been determined.
-- 28 Mar 2011	SF	8532	4	Return action validation message in alert xml
-- 22 Jun 2011	SF	10886	5	Cater for translation EVENTDESCRIPTION, CHARGEDESC, NOTES
-- 05 Jul 2013	vql	R13629	6	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 09 Dec 2013	MF	R29407	7	View Rule Details should consider Related Events and Reminder in other actions.
-- 04 Nov 2015	KR	R53910	8	Adjust formatted names logic (DR-15543)
-- 21 Apr 2016	MF	R60711	9	Date comparison not being displayed on rule that only involves one event (e.g. Exists)
-- 27 Jul 2016	MF	62664	10	Reminders are now allowed to be delivered to multiple NameTypes specified in EXTENDEDNAMETYPE column.
-- 16 Dec 2016	MF	70134	11	Multiple EventControl rows being returned when both an Open Action and Close Action is included in rule.
-- 11 Jan 2017	MF	70368	12	If @pnCycle is passed with the value of 0 then change it to NULL.
-- 06 Jul 2017  MS	71121   13	Check OpenAction Cycle for relative events resultset to avoid duplicate records
-- 14 Nov 2018  AV	DR-45358 14	Date conversion errors when creating cases and opening names in Chinese DB
-- 22 Jan 2019	MF	DR-46611 15	Allow the Relative Cycle of All Cycles (5) to be used in the caculation of a due date.

		
set nocount on
set concat_null_yields_null off

 	
Declare	@ErrorCode		int
Declare	@nRowCount		int
Declare @nCriteriaNo		int
Declare @nDueDateCycle		int

Declare @sLookupCulture		nvarchar(10)
Declare @sCountryCode		nvarchar(3)
Declare @sActionName		nvarchar(50)
Declare @sErrorDescription	nvarchar(1000)
Declare @sSQLString		nvarchar(max)
------------------------------
--
-- I N I T I A L I S A T I O N
--
------------------------------
Set @ErrorCode = 0
Set @nRowCount = 0
Set @sLookupCulture  = dbo.fn_GetLookupCulture(@psCulture, null, 0)

If @pnCycle=0
	set @pnCycle=null

---------------------------------
-- If the Action is not specified
-- or is invalid for some reason
-- then determine it.
---------------------------------
If not exists (select 1 from ACTIONS where ACTION=@psAction)
Begin
	Select @psAction=substring(min(A.ACTION), 2,3)
	from (	select '1'+isnull(CE.CREATEDBYACTION,C.ACTION) as ACTION
		from CASEEVENT CE
		left join CRITERIA C	on (C.CRITERIANO=CE.CREATEDBYCRITERIA)
		where CE.CASEID=@pnCaseId
		and CE.EVENTNO =@pnEventNo
		and isnull(CE.CREATEDBYACTION,C.ACTION) is not null
		UNION ALL
		Select '2'+OA.ACTION
		from OPENACTION OA
		join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
					and EC.EVENTNO=@pnEventNo)
		join DUEDATECALC DD	on (DD.CRITERIANO=OA.CRITERIANO
					and DD.EVENTNO   =EC.EVENTNO)
		where OA.CASEID=@pnCaseId
		UNION ALL
		Select '3'+OA.ACTION
		from OPENACTION OA
		join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
					and EC.EVENTNO=@pnEventNo)
		left join DUEDATECALC DD on(DD.CRITERIANO=OA.CRITERIANO
					and DD.EVENTNO   =EC.EVENTNO)
		where OA.CASEID=@pnCaseId
		and DD.CRITERIANO is null) A

	Set @ErrorCode=@@Error
End

-----------------------------------
-- Validate that you have an Action
-----------------------------------
If @ErrorCode=0
and @psAction is null
Begin
	Set @sErrorDescription = dbo.fn_GetAlertXML('CS108', 'Action could not be determined for the Event',
   					null, null, null, null, null)
	RAISERROR(@sErrorDescription, 14, 1)
    Set @ErrorCode = @@ERROR
End

------------------------------------
-- Get the ACTIONNAME to be returned
------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sActionName=VA.ACTIONNAME
	from CASES C
	join VALIDACTION VA	on (VA.CASETYPE=C.CASETYPE
				and VA.PROPERTYTYPE=C.PROPERTYTYPE
				and VA.COUNTRYCODE=(	select min(VA1.COUNTRYCODE)
							from VALIDACTION VA1
							where VA1.CASETYPE    =VA.CASETYPE
							and   VA1.PROPERTYTYPE=VA.PROPERTYTYPE
							and   VA1.ACTION      =VA.ACTION
							and   VA1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)
							) )
	where C.CASEID=@pnCaseId
	and VA.ACTION=@psAction"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sActionName		nvarchar(50)	OUTPUT,
				  @pnCaseId		int,
				  @psAction		nvarchar(2)',
				  @sActionName=@sActionName		OUTPUT,
				  @pnCaseId   =@pnCaseId,
				  @psAction   =@psAction
	
End

---------------------------------
-- Get the CriteriaNo of the rule
---------------------------------
If @ErrorCode=0
Begin
	Set @nCriteriaNo=dbo.fn_GetCriteriaNo(@pnCaseId,'E',@psAction,getdate(), default)
End

------------------------
-- Return details of the 
-- central Event
------------------------
If @ErrorCode=0
Begin
	---------------------------------------
	-- Construct the SQL with consideration
	-- for columns to be translated
	---------------------------------------
	Set @sSQLString="
	Select	C.IRN,
		EC.CRITERIANO,
		@sActionName as ACTIONNAME,
		EC.EVENTNO,
		CE.EVENTDATE, 
		CE.EVENTDUEDATE,
		CE.DATEREMIND, 
		"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,default)+" as EVENTDESCRIPTION,
		EC.NUMCYCLESALLOWED,
		isnull(EC.WHICHDUEDATE, 'E') as WHICHDUEDATE,
		CASE WHEN(EC.COMPAREBOOLEAN= 1 ) THEN 'All' ELSE 'Any' END as COMPAREBOOLEAN,
		CASE WHEN(EC.SAVEDUEDATE&1 = 1 ) THEN 1 END as SAVEDUEDATE,
		CASE WHEN(EC.SAVEDUEDATE&2 = 2 ) THEN 1 END as UPDATEEVENTIMMEDIATELY,
		CASE WHEN(EC.SAVEDUEDATE&4 = 4 ) THEN 1 END as UPDATEWHENDUE,
		EC.EXTENDPERIOD,
		EC.EXTENDPERIODTYPE,
		EC.RECALCEVENTDATE,
		CASE WHEN(EC.PTADELAY=1) THEN 1 END as IPOFFICEDELAY,
		CASE WHEN(EC.PTADELAY=2) THEN 1 END as APPLICANTDELAY,
		"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'S',@sLookupCulture,default)+" as STATUS,
		"+dbo.fn_SqlTranslatedColumn('CHARGETYPE','CHARGEDESC',null,'CT',@sLookupCulture,default)+" as CHARGEDESC,
		EC.PAYFEECODE,
		"+dbo.fn_SqlTranslatedColumn('ACTION','ACTIONNAME',null,'A1',@sLookupCulture,default)+" as CREATEACTION,
		"+dbo.fn_SqlTranslatedColumn('ACTION','ACTIONNAME',null,'A2',@sLookupCulture,default)+" as CLOSEACTION,
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'I',@sLookupCulture,default)+" as INSTRUCTIONTYPE,
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONLABEL','FLAGLITERAL',null,'IL',@sLookupCulture,default)+" as INSTRUCTIONFLAG,
		EC.SETTHIRDPARTYON,
		EC.SETTHIRDPARTYOFF,
		"+dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'LV',@sLookupCulture,default)+" as IMPORTANCELEVEL,
		isnull(CE.EVENTLONGTEXT,CE.EVENTTEXT) as EVENTTEXT,
		"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','NOTES',null,'EC',@sLookupCulture,default)+" as NOTES,
		CE.LOGDATETIMESTAMP,
		isnull(U.LOGINID,CE.LOGUSERID) as LOGINID,
		CE.LOGAPPLICATION
	from EVENTCONTROL EC
	join CASES C		on (C.CASEID=@pnCaseId)
	left join CASEEVENT CE	on (CE.CASEID=@pnCaseId
				and CE.EVENTNO=EC.EVENTNO
				and CE.CYCLE  =isnull(@pnCycle,1))
	left join STATUS S	on (S.STATUSCODE=EC.STATUSCODE)
	left join CHARGETYPE CT	on (CT.CHARGETYPENO=EC.INITIALFEE)
	left join ACTIONS A1	on (A1.ACTION=EC.CREATEACTION)
	left join ACTIONS A2	on (A2.ACTION=EC.CLOSEACTION)
	left join INSTRUCTIONTYPE I
				on ( I.INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE)
	left join INSTRUCTIONLABEL IL
				on (IL.INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE
				and IL.FLAGNUMBER     =EC.FLAGNUMBER)
	left join IMPORTANCE LV	on (LV.IMPORTANCELEVEL=EC.IMPORTANCELEVEL)
	left join USERIDENTITY U
				on (U.IDENTITYID=EC.LOGIDENTITYID)
	Where EC.EVENTNO=@pnEventNo
	and   EC.CRITERIANO=@nCriteriaNo"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnEventNo		int,
				  @pnCycle		int,
				  @nCriteriaNo		int,
				  @sActionName		nvarchar(50)',
				  @pnCaseId   =@pnCaseId,
				  @pnEventNo  =@pnEventNo,
				  @pnCycle    =@pnCycle,
				  @nCriteriaNo=@nCriteriaNo,
				  @sActionName=@sActionName
End

--------------------------------
-- Event pulled from Related Case
--------------------------------
If @ErrorCode=0
Begin
	---------------------------------------
	-- Construct the SQL with consideration
	-- for columns to be translated
	---------------------------------------

	Set @sSQLString="
	Select	EC.UPDATEFROMEVENT,
		"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,default)+" as FROMEVENTDESC,
		"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'CR',@sLookupCulture,default)+" as FROMRELATIONSHIP,
		"+dbo.fn_SqlTranslatedColumn('ADJUSTMENT','ADJUSTMENTDESC',null,'A',@sLookupCulture,default)+" as ADJUSTMENT,
		CS.IRN as FROMIRN,
		R.RELATEDCASEID,
		CE.EVENTDATE as FROMEVENTDATE,
		CE.CYCLE as FROMEVENTCYCLE,
		"+dbo.fn_SqlTranslatedColumn('NUMBERTYPES','DESCRIPTION',null,'N',@sLookupCulture,default)+" as LOADNUMBERTYPE
	from EVENTCONTROL EC
	join CASERELATION CR	on (CR.RELATIONSHIP=EC.FROMRELATIONSHIP)
	join EVENTS E		on (E.EVENTNO=EC.UPDATEFROMEVENT)
	left join ADJUSTMENT A	on (A.ADJUSTMENT=EC.ADJUSTMENT)
	left join RELATEDCASE R	on (R.CASEID=@pnCaseId
				and R.RELATIONSHIP=EC.FROMRELATIONSHIP)
	left join CASES CS	on (CS.CASEID=R.RELATEDCASEID)
	left join CASEEVENT CE	on (CE.CASEID=R.RELATEDCASEID
				and CE.EVENTNO=EC.UPDATEFROMEVENT
				and CE.CYCLE  =CASE WHEN(EC.NUMCYCLESALLOWED>1) THEN @pnCycle ELSE 1 END)
	left join NUMBERTYPES N	on (N.NUMBERTYPE=EC.LOADNUMBERTYPE)
	Where EC.EVENTNO=@pnEventNo
	and   EC.CRITERIANO=@nCriteriaNo"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnEventNo		int,
				  @pnCycle		int,
				  @nCriteriaNo		int',
				  @pnCaseId   =@pnCaseId,
				  @pnEventNo  =@pnEventNo,
				  @pnCycle    =@pnCycle,
				  @nCriteriaNo=@nCriteriaNo
End

-------------------------------
-- Due date calculation details
-------------------------------
If @ErrorCode=0
Begin
	------------------------------
	-- Get the CountryCode used in
	-- due date calculations for
	-- the case.
	------------------------------
	Select @sCountryCode=max(DD.COUNTRYCODE)
	from CASES C
	join DUEDATECALC DD
			on (DD.CRITERIANO=@nCriteriaNo
			and DD.EVENTNO   =@pnEventNo
			and DD.COUNTRYCODE=C.COUNTRYCODE
			and DD.COMPARISON is null)
	where C.CASEID=@pnCaseId
	
	Set @ErrorCode=@@Error

	------------------------------
	-- Get the Cycle used in
	-- due date calculations for
	-- the case.
	------------------------------
	If @ErrorCode=0
	Begin
		select @nDueDateCycle=max(CYCLENUMBER) 
		from DUEDATECALC
		where CRITERIANO=@nCriteriaNo
		and EVENTNO=@pnEventNo 
		and COMPARISON is null 
		and(COUNTRYCODE=@sCountryCode or (COUNTRYCODE is null and @sCountryCode is null))
		and CYCLENUMBER<=isnull(@pnCycle,1)

		Set @ErrorCode=@@Error
	End

	---------------------------------------
	-- Construct the SQL with consideration
	-- for columns to be translated
	---------------------------------------
	Set @sSQLString="
	Select	CE.CASEID,
		DD.FROMEVENT,
		CASE(DD.EVENTDATEFLAG)
		  WHEN(1) THEN CE.EVENTDATE
		  WHEN(2) THEN CE.EVENTDUEDATE
		  WHEN(3) THEN isnull(CE.EVENTDATE,CE.EVENTDUEDATE)
		END      as FROMDATE,
		CE.CYCLE as FROMCYCLE,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,default)+","+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,default)+") as FROMEVENTDESC,
		DD.RELATIVECYCLE,
		DD.OPERATOR,
		DD.DEADLINEPERIOD,
		DD.PERIODTYPE,
		DD.EVENTDATEFLAG,
		DD.MUSTEXIST,
		DD.WORKDAY,
		DD.MESSAGE2FLAG,
		DD.SUPPRESSREMINDERS,
		DD.OVERRIDELETTER,
		"+dbo.fn_SqlTranslatedColumn('ADJUSTMENT','ADJUSTMENTDESC',null,'A',@sLookupCulture,default)+" as ADJUSTMENT
	from DUEDATECALC DD
	left join EVENTCONTROL EC
				on (EC.CRITERIANO=DD.CRITERIANO
				and EC.EVENTNO   =DD.FROMEVENT)
	join EVENTS E		on ( E.EVENTNO   =DD.FROMEVENT) 
	left join ADJUSTMENT A	on (A.ADJUSTMENT =DD.ADJUSTMENT)
	left join CASEEVENT CE	on (CE.CASEID=@pnCaseId
				and CE.EVENTNO=DD.FROMEVENT
				and isnull(CE.OCCURREDFLAG,0)<9
				and((CE.EVENTDATE is not null and DD.EVENTDATEFLAG=1) OR (CE.EVENTDATE is null and CE.EVENTDUEDATE is not null and DD.EVENTDATEFLAG=2) OR (isnull(CE.EVENTDATE, CE.EVENTDUEDATE) is not null and DD.EVENTDATEFLAG = 3))
				and CE.CYCLE=	CASE DD.RELATIVECYCLE
							WHEN(0)	THEN @pnCycle
							WHEN(1) THEN @pnCycle-1
							WHEN(2) THEN @pnCycle+1
							WHEN(3) THEN 1
							WHEN(5)	THEN CE.CYCLE		-- DR-46611 Relative Cycle of 5 means consider all Cycles
								ELSE (	select max(CE2.CYCLE) 
								      	from  CASEEVENT CE2
							 		where CE2.CASEID=CE.CASEID 
									and   CE2.EVENTNO=CE.EVENTNO
									and  isnull(CE2.OCCURREDFLAG,0)<9
									and ((DD.EVENTDATEFLAG=1 and  CE2.EVENTDATE is not null)
									 or  (DD.EVENTDATEFLAG=2 and  CE2.EVENTDUEDATE is not null)
									 or  (DD.EVENTDATEFLAG=3 and (CE2.EVENTDUEDATE is not null or CE2.EVENTDATE is not null))))
						END)
	Where DD.EVENTNO=@pnEventNo
	and   DD.CRITERIANO=@nCriteriaNo
	and   DD.COMPARISON is null
	and  (DD.COUNTRYCODE=@sCountryCode  or (DD.COUNTRYCODE is null and @sCountryCode  is null))
	and  (DD.CYCLENUMBER=@nDueDateCycle or (DD.CYCLENUMBER is null and @nDueDateCycle is null))
	ORDER BY DD.SEQUENCE"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnEventNo		int,
				  @pnCycle		int,
				  @nCriteriaNo		int,
				  @nDueDateCycle	int,
				  @sCountryCode		nvarchar(3)',
				  @pnCaseId     =@pnCaseId,
				  @pnEventNo    =@pnEventNo,
				  @pnCycle      =@pnCycle,
				  @nCriteriaNo  =@nCriteriaNo,
				  @nDueDateCycle=@nDueDateCycle,
				  @sCountryCode =@sCountryCode
End

--------------------------
-- Date Comparison details
--------------------------
If @ErrorCode=0
Begin
	------------------------------
	-- Get the CountryCode used in
	-- date comparison rules.
	------------------------------
	Select @sCountryCode=max(DD.COUNTRYCODE)
	from CASES C
	join DUEDATECALC DD
			on (DD.CRITERIANO=@nCriteriaNo
			and DD.EVENTNO   =@pnEventNo
			and DD.COUNTRYCODE=C.COUNTRYCODE
			and DD.COMPARISON is NOT null)
	where C.CASEID=@pnCaseId
	
	Set @ErrorCode=@@Error

	------------------------
	-- Get the Cycle used in
	-- date comparison rules
	------------------------
	If @ErrorCode=0
	Begin
		select @nDueDateCycle=max(CYCLENUMBER) 
		from DUEDATECALC
		where CRITERIANO=@nCriteriaNo
		and EVENTNO=@pnEventNo 
		and COMPARISON is NOT null 
		and(COUNTRYCODE=@sCountryCode or (COUNTRYCODE is null and @sCountryCode is null))
		and CYCLENUMBER<=isnull(@pnCycle,1)

		Set @ErrorCode=@@Error
	End

	---------------------------------------
	-- Construct the SQL with consideration
	-- for columns to be translated
	---------------------------------------
	Set @sSQLString="
	Select	CE.CASEID,
		DD.FROMEVENT,
		CASE(DD.EVENTDATEFLAG)
		  WHEN(1) THEN CE.EVENTDATE
		  WHEN(2) THEN CE.EVENTDUEDATE
			  ELSE isnull(CE.EVENTDATE,CE.EVENTDUEDATE)
		END      as FROMDATE,
		CE.CYCLE as FROMCYCLE,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,default)+","+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,default)+") as FROMEVENTDESC,
		DD.RELATIVECYCLE,
		DD.EVENTDATEFLAG,
		DD.COMPARISON,

		CS.IRN     as COMPARISONIRN,
		CE1.CASEID as COMPARARISONCASEID,
		DD.COMPAREEVENT,
		CASE WHEN(DD.COMPAREDATE is not null) THEN DD.COMPAREDATE
		     WHEN(DD.COMPARESYSTEMDATE=1)     THEN convert(nvarchar, getdate(),112)
		  ELSE CASE(DD.COMPAREEVENTFLAG)
			  WHEN(1) THEN CE1.EVENTDATE
			  WHEN(2) THEN CE1.EVENTDUEDATE
				  ELSE isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE)
		       END      
		END as COMPARISONDATE,
		CE1.CYCLE as COMPARISONCYCLENO,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC1',@sLookupCulture,default)+","+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E1',@sLookupCulture,default)+") as COMPAREEVENTDESC,
		DD.COMPARECYCLE,
		"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'CR',@sLookupCulture,default)+" as COMPARERELATIONSHIP,
		DD.COMPAREEVENTFLAG,
		DD.COMPAREDATE,
		DD.COMPARESYSTEMDATE
	from DUEDATECALC DD
	left join EVENTCONTROL EC
				on (EC.CRITERIANO=DD.CRITERIANO
				and EC.EVENTNO   =DD.FROMEVENT)
	join EVENTS E		on ( E.EVENTNO   =DD.FROMEVENT) 
	left join CASEEVENT CE	on (CE.CASEID=@pnCaseId
				and CE.EVENTNO=DD.FROMEVENT
				and isnull(CE.OCCURREDFLAG,0)<9
				and CE.CYCLE=	CASE DD.RELATIVECYCLE
							WHEN(0)	THEN @pnCycle
							WHEN(1) THEN @pnCycle-1
							WHEN(2) THEN @pnCycle+1
							WHEN(3) THEN 1
								ELSE (	select max(CE2.CYCLE) 
								      	from  CASEEVENT CE2
							 		where CE2.CASEID=CE.CASEID 
									and   CE2.EVENTNO=CE.EVENTNO
									and  isnull(CE2.OCCURREDFLAG,0)<9
									and ((DD.EVENTDATEFLAG=1 and  CE2.EVENTDATE is not null)
									 or  (DD.EVENTDATEFLAG=2 and  CE2.EVENTDUEDATE is not null)
									 or  (DD.EVENTDATEFLAG=3 and (CE2.EVENTDUEDATE is not null or CE2.EVENTDATE is not null))))
						END)

	left join EVENTCONTROL EC1
				on (EC1.CRITERIANO=DD.CRITERIANO
				and EC1.EVENTNO   =DD.COMPAREEVENT)
	left join EVENTS E1	on ( E1.EVENTNO   =DD.COMPAREEVENT) 


	left join CASERELATION CR	
				on (CR.RELATIONSHIP=DD.COMPARERELATIONSHIP)
	left join RELATEDCASE R	on (R.CASEID=@pnCaseId
				and R.RELATIONSHIP=DD.COMPARERELATIONSHIP)
	left join CASES CS	on (CS.CASEID=R.RELATEDCASEID)

	left join CASEEVENT CE1	on (CE1.CASEID =isnull(R.RELATEDCASEID, @pnCaseId)
				and CE1.EVENTNO=DD.COMPAREEVENT
				and isnull(CE1.OCCURREDFLAG,0)<9
				and CE1.CYCLE=	CASE DD.COMPARECYCLE
							WHEN(0)	THEN @pnCycle
							WHEN(1) THEN @pnCycle-1
							WHEN(2) THEN @pnCycle+1
							WHEN(3) THEN 1
								ELSE (	select max(CE2.CYCLE) 
								      	from  CASEEVENT CE2
							 		where CE2.CASEID=CE1.CASEID 
									and   CE2.EVENTNO=CE1.EVENTNO
									and  isnull(CE2.OCCURREDFLAG,0)<9
									and ((DD.COMPAREEVENTFLAG=1 and  CE2.EVENTDATE is not null)
									 or  (DD.COMPAREEVENTFLAG=2 and  CE2.EVENTDUEDATE is not null)
									 or  (DD.COMPAREEVENTFLAG=3 and (CE2.EVENTDUEDATE is not null or CE2.EVENTDATE is not null))))
						END)

	Where DD.EVENTNO=@pnEventNo
	and   DD.CRITERIANO=@nCriteriaNo
	and   DD.COMPARISON is NOT null
	and  (DD.COUNTRYCODE=@sCountryCode  or (DD.COUNTRYCODE is null and @sCountryCode  is null))
	and  (DD.CYCLENUMBER=@nDueDateCycle or (DD.CYCLENUMBER is null and @nDueDateCycle is null))
	ORDER BY DD.SEQUENCE"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnEventNo		int,
				  @pnCycle		int,
				  @nCriteriaNo		int,
				  @nDueDateCycle	int,
				  @sCountryCode		nvarchar(3)',
				  @pnCaseId     =@pnCaseId,
				  @pnEventNo    =@pnEventNo,
				  @pnCycle      =@pnCycle,
				  @nCriteriaNo  =@nCriteriaNo,
				  @nDueDateCycle=@nDueDateCycle,
				  @sCountryCode =@sCountryCode
End

------------------------
-- Related Event details
--   Clear Events
--   Clear Due
--   Satisfied By
--   Update other event
------------------------
If @ErrorCode=0
Begin
	---------------------------------------
	-- Construct the SQL with consideration
	-- for columns to be translated
	---------------------------------------

	Set @sSQLString="
	Select	RE.RELATEDEVENT,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,default)+","+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,default)+") as RELATEDEVENTDESC,
		RE.UPDATEEVENT, 
		RE.SATISFYEVENT,
		RE.CLEAREVENT,
		RE.CLEARDUE,
		RE.CLEAREVENTONDUECHANGE,
		RE.CLEARDUEONDUECHANGE,
		RE.RELATIVECYCLE,
		"+dbo.fn_SqlTranslatedColumn('ADJUSTMENT','ADJUSTMENTDESC',null,'A',@sLookupCulture,default)+" as ADJUSTMENT,
		CE.CASEID,
		CE.EVENTDATE as RELATEDEVENTDATE,
		CE.CYCLE as RELATEDEVENTCYCLE
	from OPENACTION OA		
	join RELATEDEVENTS RE	on (RE.CRITERIANO=OA.CRITERIANO)
	left join EVENTCONTROL EC
				on (EC.CRITERIANO=RE.CRITERIANO
				and EC.EVENTNO   =RE.RELATEDEVENT)
	join EVENTS E		on (E.EVENTNO    =RE.RELATEDEVENT)
	left join ADJUSTMENT A	on (A.ADJUSTMENT =RE.ADJUSTMENT)
	left join CASEEVENT CE	on (CE.CASEID =@pnCaseId
				and CE.EVENTNO=RE.RELATEDEVENT
				and(RE.SATISFYEVENT=1 OR RE.UPDATEEVENT=1) -- only return CaseEvent for Satisfied or Updated rules
				and CE.CYCLE  =	CASE RE.RELATIVECYCLE
							WHEN(0)	THEN @pnCycle
							WHEN(1) THEN @pnCycle-1
							WHEN(2) THEN @pnCycle+1
							WHEN(3) THEN 1
								ELSE (	select max(CE2.CYCLE) 
								      	from  CASEEVENT CE2
							 		where CE2.CASEID=CE.CASEID 
									and   CE2.EVENTNO=CE.EVENTNO)
						END)
	Where OA.CASEID =@pnCaseId
        and OA.CYCLE = ISNULL(@pnCycle, 1)
	--------------------------------------------------------------
	-- RFC29407
	-- Related Events do not have to belong to the Criteria that
	-- calculated the Event due date. Satisfying Events will also
	-- be considered even if the Action where they are defined
	-- is closed.
	--------------------------------------------------------------
	and ((OA.POLICEEVENTS=1 and 1 in (RE.UPDATEEVENT,RE.CLEAREVENT,RE.CLEARDUE,RE.CLEAREVENTONDUECHANGE,RE.CLEARDUEONDUECHANGE)) OR RE.SATISFYEVENT=1)
	and   RE.EVENTNO=@pnEventNo
	ORDER BY RE.UPDATEEVENT DESC, RE.SATISFYEVENT DESC, RE.RELATEDNO"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnEventNo		int,
				  @pnCycle		int,
				  @nCriteriaNo		int',
				  @pnCaseId   =@pnCaseId,
				  @pnEventNo  =@pnEventNo,
				  @pnCycle    =@pnCycle,
				  @nCriteriaNo=@nCriteriaNo
End

------------------------
-- Reminder details
------------------------
If @ErrorCode=0
Begin
	---------------------------------------
	-- Construct the SQL with consideration
	-- for columns to be translated.
	--
	-- RFC62664
	-- Add the CTE ExtendedNameTypes to 
	-- concatenate any extended name types
	-- together.
	---------------------------------------

	Set @sSQLString="
	with ExtendedNameTypes
	as (	Select  distinct R.CRITERIANO, R.EVENTNO, R.REMINDERNO,
		SUBSTRING( (select distinct ', '+"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,default)+" as [text()]
			    from dbo.fn_Tokenise(R.EXTENDEDNAMETYPE, ';') T
			    join NAMETYPE NT on (NT.NAMETYPE=T.Parameter)
			    Where T.Parameter<>ISNULL(R.NAMETYPE,'')
			    For XML PATH ('') ),
			    2, 1000) [Description]
		from OPENACTION OA
		join REMINDERS R on (R.CRITERIANO=OA.CRITERIANO)
		)
	Select	R.LEADTIME,
		CASE WHEN(R.LEADTIME<>0) THEN R.PERIODTYPE ELSE NULL END as PERIODTYPE,
		R.FREQUENCY,
		CASE WHEN(R.FREQUENCY<>0) THEN isnull(R.FREQPERIODTYPE,R.PERIODTYPE) ELSE NULL END as FREQPERIODTYPE,
		R.STOPTIME,
		CASE WHEN(R.STOPTIME is not null) THEN isnull(R.STOPTIMEPERIODTYPE,R.PERIODTYPE) ELSE NULL END as STOPTIMEPERIODTYPE,
		"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT1',@sLookupCulture,default)+"    as EMPLOYEENAMETYPE,
		"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT2',@sLookupCulture,default)+"    as SIGNATORYNAMETYPE,
		"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT3',@sLookupCulture,default)+"    as INSTRUCTORNAMETYPE,
		R.CRITICALFLAG,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO,N.NAMESTYLE) as REMINDERNAME,
		isnull("+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT4',@sLookupCulture,default)+",'') +
			CASE WHEN(NT4.DESCRIPTION is not null and ENT.Description is not null) THEN ', ' ELSE '' END +
			isnull(ltrim(ENT.DESCRIPTION),'') as NAMETYPE,
		"+dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,'NR',@sLookupCulture,default)+" as RELATIONSHIP,
		R.SENDELECTRONICALLY,
		R.EMAILSUBJECT,
		R.USEMESSAGE1 as USEBEFOREDUEDATE,
		cast(R.MESSAGE1 as nvarchar(max)) as MESSAGE1,
		cast(R.MESSAGE2 as nvarchar(max)) as MESSAGE2
	--------------------------------------------------
	-- RFC29407
	-- Reminders do not have to belong to the Criteria
	-- that calculated the Event due date.
	--------------------------------------------------
	from OPENACTION OA		
	join REMINDERS R	on (R.CRITERIANO=OA.CRITERIANO)
	left join ExtendedNameTypes ENT
				on (ENT.CRITERIANO=R.CRITERIANO
				and ENT.EVENTNO   =R.EVENTNO
				and ENT.REMINDERNO=R.REMINDERNO)
	left join NAME N	on (N.NAMENO=R.REMINDEMPLOYEE)
	left join NAMETYPE NT1	on (NT1.NAMETYPE='EMP'
				and R.EMPLOYEEFLAG=1)
	left join NAMETYPE NT2	on (NT2.NAMETYPE='SIG'
				and R.SIGNATORYFLAG=1)
	left join NAMETYPE NT3	on (NT3.NAMETYPE='I'
				and R.INSTRUCTORFLAG=1)
	left join NAMETYPE NT4	on (NT4.NAMETYPE=R.NAMETYPE)
	left join NAMERELATION NR
				on (NR.RELATIONSHIP=R.RELATIONSHIP)
	Where OA.CASEID=@pnCaseId
	and   R.EVENTNO=@pnEventNo
	and   R.LETTERNO is null
	ORDER BY R.REMINDERNO"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnEventNo		int,
				  @nCriteriaNo		int',
				  @pnCaseId   =@pnCaseId, 
				  @pnEventNo  =@pnEventNo,
				  @nCriteriaNo=@nCriteriaNo
End

------------------------
-- Letter details
------------------------
If @ErrorCode=0
Begin
	---------------------------------------
	-- Construct the SQL with consideration
	-- for columns to be translated
	---------------------------------------

	Set @sSQLString="
	Select	R.LEADTIME,
		CASE WHEN(R.LEADTIME<>0) THEN R.PERIODTYPE ELSE NULL END as PERIODTYPE,
		R.FREQUENCY,
		CASE WHEN(R.FREQUENCY<>0) THEN isnull(R.FREQPERIODTYPE,R.PERIODTYPE) ELSE NULL END as FREQPERIODTYPE,
		R.STOPTIME,
		CASE WHEN(R.STOPTIME is not null) THEN isnull(R.STOPTIMEPERIODTYPE,R.PERIODTYPE) ELSE NULL END as STOPTIMEPERIODTYPE,
		R.MAXLETTERS,
		R.LETTERNO,
		"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'L',@sLookupCulture,default)+" as LETTERNAME,
		R.CHECKOVERRIDE,
		R.UPDATEEVENT,
		"+dbo.fn_SqlTranslatedColumn('CHARGETYPE','CHARGEDESC',null,'CT',@sLookupCulture,default)+" as LETTERFEE,
		R.PAYFEECODE,
		R.ESTIMATEFLAG,
		R.DIRECTPAYFLAG
	--------------------------------------------------
	-- RFC29407
	-- Letters do not have to belong to the Criteria
	-- that calculated the Event due date.
	--------------------------------------------------
	from OPENACTION OA		
	join REMINDERS R	on (R.CRITERIANO=OA.CRITERIANO)
	join LETTER L		on (L.LETTERNO=R.LETTERNO)
	left join CHARGETYPE CT	on (CT.CHARGETYPENO=R.LETTERFEE)
	Where OA.CASEID=@pnCaseId
	and   R.EVENTNO=@pnEventNo
	ORDER BY R.REMINDERNO"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnEventNo		int,
				  @nCriteriaNo		int',
				  @pnCaseId   =@pnCaseId, 
				  @pnEventNo  =@pnEventNo,
				  @nCriteriaNo=@nCriteriaNo
End

---------------------
-- Date Logic details
---------------------
If @ErrorCode=0
Begin
	---------------------------------------
	-- Construct the SQL with consideration
	-- for columns to be translated
	---------------------------------------
	Set @sSQLString="
	Select	DL.DATETYPE,
		DL.OPERATOR,
		DL.COMPAREEVENT,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,default)+","+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,default)+") as COMPAREEVENTDESC,
		cast(DL.MUSTEXIST as bit) as MUSTEXIST,
		DL.RELATIVECYCLE,

		CS.IRN     as COMPARISONIRN,
		CE.CASEID  as COMPARARISONCASEID,
		CE.EVENTNO as COMPARISONEVENTNO,
		CE.CYCLE   as COMPARISONCYCLENO,
		CASE(DL.COMPAREDATETYPE)
			WHEN(1) THEN CE.EVENTDATE
				ELSE CE.EVENTDUEDATE
		END as COMPARISONDATE,
		DL.CASERELATIONSHIP,
		"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'CR',@sLookupCulture,default)+" as COMPARERELATIONSHIP,
		DL.COMPAREDATETYPE,
		DL.DISPLAYERRORFLAG,
		"+dbo.fn_SqlTranslatedColumn('DATESLOGIC','ERRORMESSAGE',null,'DL',@sLookupCulture,default)+" as ERRORMESSAGE
		
	from DATESLOGIC DL
	left join EVENTCONTROL EC
				on (EC.CRITERIANO=DL.CRITERIANO
				and EC.EVENTNO   =DL.COMPAREEVENT)
	join EVENTS E		on ( E.EVENTNO   =DL.COMPAREEVENT)

	left join CASERELATION CR	
				on (CR.RELATIONSHIP=DL.CASERELATIONSHIP)
	left join RELATEDCASE R	on (R.CASEID=@pnCaseId
				and R.RELATIONSHIP=DL.CASERELATIONSHIP)
	left join CASES CS	on (CS.CASEID=R.RELATEDCASEID)
	left join CASEEVENT CE	on (CE.CASEID =isnull(R.RELATEDCASEID, @pnCaseId)
				and CE.EVENTNO=DL.COMPAREEVENT
				and isnull(CE.OCCURREDFLAG,0)<9
				and CE.CYCLE=	CASE DL.RELATIVECYCLE
							WHEN(0)	THEN @pnCycle
							WHEN(1) THEN @pnCycle-1
							WHEN(2) THEN @pnCycle+1
							WHEN(3) THEN 1
								ELSE (	select max(CE2.CYCLE) 
								      	from  CASEEVENT CE2
							 		where CE2.CASEID =CE.CASEID 
									and   CE2.EVENTNO=CE.EVENTNO
									and  isnull(CE2.OCCURREDFLAG,0)<9
									and ((DL.COMPAREDATETYPE=1 and  CE2.EVENTDATE is not null)
									 or  (DL.COMPAREDATETYPE=2 and  CE2.EVENTDUEDATE is not null)))
						END)

	Where DL.EVENTNO=@pnEventNo
	and   DL.CRITERIANO=@nCriteriaNo
	ORDER BY DL.SEQUENCENO"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnEventNo		int,
				  @pnCycle		int,
				  @nCriteriaNo		int',
				  @pnCaseId     =@pnCaseId,
				  @pnEventNo    =@pnEventNo,
				  @pnCycle      =@pnCycle,
				  @nCriteriaNo  =@nCriteriaNo
End

RETURN @ErrorCode
go

grant execute on dbo.cs_CaseEventRuleDetails  to public
go

