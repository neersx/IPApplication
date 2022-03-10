-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.csw_ListCaseEvents
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseEvents.'
	Drop procedure [dbo].[csw_ListCaseEvents]
	Print '**** Creating Stored Procedure dbo.csw_ListCaseEvents...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.csw_ListCaseEvents
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCriteriaKey		int,
	@pnCaseKey		int,
	@pnCycle		int,
	@pbIsAllEvents		bit		= 0,
	@pbIsActionCyclic	bit		= 0,
	@pbIsMostRecentCycle	bit		= 0,
	@pnImportanceLevelKey	int		= null,
	@pbIsDisplayAllEventDetails bit		= 0,
	@psActionKey		nvarchar(3)	= null
)
AS
-- PROCEDURE:	csw_ListCaseEvents
-- VERSION:	44
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inprotech WorkBench
-- DESCRIPTION:	Returns a list of case events for a paricular action criteria.

-- MODIFICATIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 17 Aug 2009  KR	R6950		1	Procedure created
-- 07 Sep 2009  KR	R6950		2	Added HasImportBatchKey
-- 16 Sep 2009	NG	R8102		3	Addded EventHasHistory column to identify if event has history
-- 24 Sep 2009	KR	R6950		4	fixed bug with defining @pnImportanceLevelKey
-- 25 Sep 2009	KR	R6950		5	fixed a bug
-- 08 Oct 2009	SF	R6950		6	Added EmployeeName, EmployeeCode, ResponsibleNameTypeDescription
-- 10 Nov 2009	KR	R100084		7	Added parameter @pbIsDisplayAllEventDetails, when set select EVENTDUEDATE and DATEREMIND only if EVENTDATE is null.
-- 11 Jan 2010	KR	R100084		8	Bug fix
-- 28 Jun 2010	LP	R9310		9	Call csw_ListCaseActionData if CriteriaKey is not provided.
-- 15 Oct 2010	LP	R9321		10	Fix logic when returning Most Recent Cycle events.
-- 14 Feb 2011	AT	R10034		11	Do not return Event Due Date / Reminder date if event occurred.
-- 04 Mar 2011  LP      R10222		12      Remove long comments from generated SQL. This was causing truncation of SQL.
-- 26 May 2011	JC	R9882		13	Add flag to check than an entry exists
-- 16 Sep 2011	LP	R10812		14	Return LastModifiedDate column for concurrency checking.
--						Return FromCaseKey column. Cast Cycle as integer, and return 1 if NULL (e.g. for unopened actions).
-- 20 Oct 2011	LP	R6896		15	Return HasAttachments column.
-- 24 Oct 2011	ASH	R11460		16	Cast integer columns as nvarchar(11) data type.
-- 26 Oct 2011	MF	R11470		17	CaseEvent row with no dates is being displayed even though @pbIsAllEvents=0. This is caused by R9321 where
--						logic for determining the most appropriate cycle is incorrect.
-- 01 Nov 2011	MF	R11458		18	Allow the creation of a hyperlink against an Action to be determined by a Site Control.
-- 01 Nov 2011  DV      R11417        	19      Fix ambiguous name CYCLE issue. 
-- 15 Nov 2011	LP	R11558		20	Allow checking of CASEEVENT_iLOG as both a table or view.
-- 19 Jan 2012	LP	R11771		21	Do not suppress CASEEVENTS with no event/due date if searching for ALL case events.
-- 13 Apr 2012	KR	R11882		22	When Due Date is not displayed, do not calculate due date in the past flag.
-- 24 May 2012	LP	R12346		23	Always return EVENTDUEDATE and DATEREMIND columns. Toggle will be handled by calling code.
-- 25 May 2012	LP	R11771		24	Use @pnCycle parameter if available to find matching Case Event History.
-- 21 Sep 2012	MF	R12703		25	External users are to check the sitecontrol "Client Due Dates: Overdue Days" and if a value exists then duedates are
--						displayed are to be restricted so that they are no older than the number of days specified.
-- 28 Sep 2012	SF	R12789		26	Reinstate linking to workflow entry functinoality
-- 15 Apr 2013	DV	R13270		27	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629		28	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Mar 2015	MS	R43203		29	Return Event Text from EVENTTEXT table
-- 02 Jun 2015	MF	R48140		30	Events on Action tab not considering the default sorting configured in Site Control
-- 03 Jun 2015	MF	R48140		31	Failed test.  Reworked.
-- 05 Oct 2015	DV	R49681		32	Added a new Period column.
-- 02 Nov 2015	vql	R53910		33	Adjust formatted names logic (DR-15543).
-- 11 Jul 2016	MF	63127		34	If the Event is cyclic within a non cyclic Action, ensure the cycle of CaseEvent is considered when determining
--						if audit log history exists. This is a rework of the change delivered for RFC11771.
-- 14 Oct 2016	MF	69013		35	Need to cater for the possibility that an Event could potentially have multiple Event Notes of the same Note Type. This can occur when
--						an Event that has its own notes as become a member of a NoteGroup where Notes existed for other Events in that NoteGroup. To decide which Note
--						to return, the system will give preference to a Note that has been shared followed by the latest note edited.
-- 27 Oct 2016	MF	64866		36	When returning the Event Text, the default preferred Event Text Type should be returned.
-- 05 Jan 2017	LP	70360		37	Fixed issue with incorrect variable name.
-- 05 Jun 2017  MS	71095		38	Fixed issue where Cycle is displayed as 0 rather than 1.
-- 03 Oct 2017	DV	72497		39	Fixed issue when events are not listed if LOGDATETIMESTAMP is null
-- 28 Nov 2017	MF	72968		40	Event Notes with no Event Note Type will be returned in preference.  If none exists then the user's preference will be shown or finally the most recently modified text.
-- 04 Jan 2018	MF	73214		41	Revisit 64866. We were previously returning Event Notes that were shared between Events, even though there was not a physical connection between the Event and the Note (no CASEEVENTTEXT row). This could
--						occur if the rules around how Events sharing have changed after notes had been entered.  This solution however only works well when looking at the details of a single Case, whereas a list of Cases such
--						as returned by the Due Date List (ipw_ListDueDate) would result in an unacceptable performance overhead. To ensure consistency of behaviour only notes directly linked to a CASEEVENT will be shown here.
-- 04 Jan 2018	MF	73220		42	Event Notes not being returned when the EVENTTEXT row is missing a LOGDATETIMESTAMP value. Resolved by defaulting to 1900-01-01.
-- 07 Sep 2018	AV	74738		43	Set isolation level to read uncommited.
-- 14 Nov 2018  AV  75198/DR-45358	44   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @nErrorCode 			int

Declare @sSQLString			nvarchar(max)
Declare @sLookupCulture			nvarchar(10)
Declare @nProfileKey			int
declare @nDefaultEventNoteType		int
Declare @sSQLWhereImportanceLevel	nvarchar(500)
Declare	@sOrder				nvarchar(100)
Declare	@sOrderType			nvarchar(5)

Declare @bEventLogTableExists		bit
Declare @bEntryFlag			bit
Declare	@bIsExternalUser		bit
Declare	@nOverdueDays			int

Declare	@dtOverdueRangeFrom		datetime	-- external users restricted from seeing overdue dates

Set @sLookupCulture        = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nDefaultEventNoteType = dbo.fn_GetDefaultEventNoteType(@pnUserIdentityId)
Set @nErrorCode = 0
Set @pnRowCount	= 0

-------------------------
-- Check if External User
-------------------------
If @nErrorCode = 0
Begin
        Select	@bIsExternalUser = ISEXTERNALUSER
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
        Set @nErrorCode = @@ERROR
End

--------------------------------------
-- Determine if Events should display
-- a hyperlink to their Workflow Entry
-- ALSO
-- Set the columns to be used in the
-- Order By clause.
--------------------------------------
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  @bEntryFlag=isnull(S.COLBOOLEAN,0),
		@sOrderType=SC.COLCHARACTER,
		@sOrder = 
		CASE(SC.COLCHARACTER)
			WHEN('ES') THEN 'E.DISPLAYSEQUENCE, Cycle'
			WHEN('ED') THEN 'EventDate, Cycle, E.DISPLAYSEQUENCE'
			WHEN('DD') THEN 'EventDueDate, Cycle, E.DISPLAYSEQUENCE'
			WHEN('NR') THEN 'ReminderDate, Cycle, E.DISPLAYSEQUENCE'
			WHEN('IL') THEN 'isnull(E.IMPORTANCELEVEL, EV.IMPORTANCELEVEL), Cycle, E.DISPLAYSEQUENCE'
			WHEN('CD') THEN 'Cycle, ISNULL(EventDate,EventDueDate), E.DISPLAYSEQUENCE'
				   ELSE 'E.DISPLAYSEQUENCE, Cycle'
		END				
	from SITECONTROL S
	left join SITECONTROL SC on (SC.CONTROLID = 'Case Event Default Sorting')
	where  S.CONTROLID='Event Link to Workflow Allowed'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bEntryFlag	bit		output,
					  @sOrder	nvarchar(100)	output,
					  @sOrderType	nvarchar(5)	output',
					  @bEntryFlag	= @bEntryFlag	output,
					  @sOrder	= @sOrder	output,
					  @sOrderType	= @sOrderType	output
End

If  @nErrorCode=0
and @bIsExternalUser=1
Begin
	Select	@nOverdueDays  =S1.COLINTEGER
	from SITECONTROL S1
	where S1.CONTROLID='Client Due Dates: Overdue Days'

	Set @nErrorCode=@@Error

	----------------------------------------------
	-- Determine the date from which due dates are
	-- allowed to be displayed by subtracting the 
	-- OverdueDays from todays
	----------------------------------------------
	If  @nErrorCode = 0
	and @nOverdueDays is not null
	begin
		Set @dtOverdueRangeFrom = convert(nvarchar,dateadd(Day, @nOverdueDays*-1, getdate()),112)
	end
End

-- Attempt to retrieve criteria key based on 
If @pnCaseKey is not null
and @psActionKey is not null
and @pnCriteriaKey is null
Begin
	Select 
	@pbIsActionCyclic = CASE WHEN A.NUMCYCLESALLOWED > 1 THEN cast(1 as bit) ELSE cast(0 as bit) END,
	@pnCriteriaKey = dbo.fn_GetCriteriaNo(@pnCaseKey,'E',@psActionKey, getdate(), @nProfileKey)                                                       
	from  ACTIONS A
	where A.ACTION = @psActionKey
End


if @pnImportanceLevelKey is null
	Set @sSQLWhereImportanceLevel = ""
else
	Set @sSQLWhereImportanceLevel = "and E.IMPORTANCELEVEL >= @pnImportanceLevelKey"

-- Check if Event Log table exists
If @nErrorCode = 0
Begin
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[CASEEVENT_iLOG]') and (OBJECTPROPERTY(id, N'IsTable') = 1 or OBJECTPROPERTY(id, N'IsView') = 1))
		Set @bEventLogTableExists = 1
	else
		Set @bEventLogTableExists = 0
End

If @nErrorCode = 0
Begin
	if @pbIsAllEvents = 1
	Begin
		if @pbIsActionCyclic = 1
		Begin
			---------------------------------
			-- All Events for a Cyclic Action
			---------------------------------
			Set @sSQLString = "
			With	CTE_EventText (EVENTNO, CYCLE, EVENTTEXTID, LASTENTERED, DEFAULTTEXTTYPE)
					as (	select  CT.EVENTNO, CT.CYCLE, ET.EVENTTEXTID, isnull(ET.LOGDATETIMESTAMP,'1900-01-01'),
							CASE WHEN(ET.EVENTTEXTTYPEID is null)
								THEN '2'
								WHEN(ET.EVENTTEXTTYPEID=@nDefaultEventNoteType)
								THEN '1'
								ELSE '0'
							END
						from CASEEVENTTEXT CT
						join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
						Where CT.CASEID=@pnCaseKey
					)
			SELECT	
			CAST(isnull(C.CASEID, @pnCaseKey) as nvarchar(11))+'^'+ 
				CAST(E.EVENTNO as varchar(11)) +'^'+ CAST(isnull(C.CYCLE, @pnCycle) as nvarchar(5)) +'^'+
			CAST(case when (C.CASEID is null)then 1 else 0  end as nvarchar(5)) as 'RowKey',
			isnull(C.CASEID,@pnCaseKey) as 'CaseKey',
			E.EVENTNO as 'EventKey',
			COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+",
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EV',@sLookupCulture,@pbCalledFromCentura)+")
			as 'EventDescription',
			"+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ETF',@sLookupCulture,@pbCalledFromCentura)+"				
											as EventText,
			EVENTDATE as 'EventDate',  
			EVENTDUEDATE as 'EventDueDate',  				
			DATEREMIND as 'ReminderDate',   
			cast(coalesce(C.CYCLE,@pnCycle,1) as int) as 'Cycle', 
			cast(ISNULL(C.DATEDUESAVED,0) as bit) as 'DueDateSaved', 
			C.OCCURREDFLAG as 'OccuredFlag', 
			C.CREATEDBYACTION as 'CreatedByAction', 
			C.CREATEDBYCRITERIA as 'CreatedByCriteria', 
			C.IMPORTBATCHNO as 'ImportBatchKey', 
			CA.IRN as 'FromCaseReference',
			C.EMPLOYEENO as 'EmployeeKey', 
			N.NAMECODE as 'EmployeeCode',
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'EmployeeName',
			C.DUEDATERESPNAMETYPE as 'ResponsibleNameType',
			NT.DESCRIPTION		as 'ResponsibleNameTypeDescription',
			isnull( EVENTDATE, EVENTDUEDATE ) as 'AllDates',
			E.IMPORTANCELEVEL as 'ImportanceLevel',
			cast(case when (C.CASEID is null)then 1 else 0  end as bit) as 'IsNew',
			cast(case when (C.IMPORTBATCHNO is null)then 0 else 1  end as bit) as 'HasImportBatchKey',
			cast(case when (EVENTDUEDATE < getdate()) then 1 else 0 end as bit) as 'IsDueDatePast',
			cast(case when (DATEREMIND < getdate()) then 1 else 0 end as bit) as 'IsReminderDatePast',
			cast(case when (EVENTDUEDATE > getdate()and DATEDUESAVED = 1 ) then 1 else 0 end as bit) as 'IsDueDateFuture'," +char(10)+
			CASE WHEN @bEventLogTableExists = 1
					THEN "cast(case when exists (select 1 from CASEEVENT_iLOG where CASEID = @pnCaseKey and EVENTNO = E.EVENTNO and CYCLE = ISNULL(C.CYCLE,@pnCycle)) then 1 else 0 end as bit)"
				ELSE "cast(0 as bit)"
			END +char(10)+
			"as 'EventHasHistory',"

			If @bEntryFlag=1
			Begin
				Set @sSQLString=@sSQLString+char(10)+"dbo.fn_DoesEntryExistForCaseEvent(@pnUserIdentityId,C.CASEID,C.EVENTNO,C.CYCLE) as 'DoesEntryExistForCaseEvent',"
			End
			Else Begin
				Set @sSQLString=@sSQLString+char(10)+"					cast(0 as bit) as 'DoesEntryExistForCaseEvent',"
			End
			
			Set @sSQLString=@sSQLString+"
				C.FROMCASEID as FromCaseKey,
				cast(C.ENTEREDDEADLINE as nvarchar(20)) + ' ' + cast(TC.DESCRIPTION as nvarchar(20)) as Period,
				cast (case when exists (select 1 from DATESLOGIC DL where DL.EVENTNO = E.EVENTNO and DL.CRITERIANO = E.CRITERIANO) then 1 else 0 end as bit) as 'HasDatesLogic',
				cast (case when exists (select 1 from ACTIVITY A where A.EVENTNO = C.EVENTNO and A.CYCLE = C.CYCLE and A.CASEID = @pnCaseKey) then 1 else 0 end as bit) as 'HasAttachments',
				C.LOGDATETIMESTAMP as LastModifiedDate
			FROM EVENTCONTROL  E
			left join CASEEVENT C	on (E.EVENTNO=C.EVENTNO 
						and C.CASEID  =@pnCaseKey 
						and C.CYCLE   = @pnCycle 
						and C.OCCURREDFLAG < 9)
			left join CASES CA	on (CA.CASEID = C.FROMCASEID)
			left join EVENTS EV	on (EV.EVENTNO = E.EVENTNO )
			left join NAME N	on (N.NAMENO = C.EMPLOYEENO)
			left join NAMETYPE NT	on (NT.NAMETYPE = C.DUEDATERESPNAMETYPE)
			left join TABLECODES TC	on (TC.TABLETYPE = 127 and TC.USERCODE = C.PERIODTYPE)

			-------------------------------------------
			-- The Event Note to return is based on the
			-- following hierarchy:
			-- 1 - No TextType
			-- 2 - Users default Text Type
			-- 3 - Most recently modified text
			-------------------------------------------
			left join CTE_EventText CTE	on (CTE.EVENTNO  =C.EVENTNO
							and CTE.CYCLE    =C.CYCLE
							and CTE.EVENTTEXTID = Cast
								     (substring
								      ((select max(CTE1.DEFAULTTEXTTYPE + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
									from CTE_EventText CTE1
									where CTE1.EVENTNO  =CTE.EVENTNO
									and   CTE1.CYCLE    =CTE.CYCLE ),25,11) as int)
								)
			left join EVENTTEXT ETF		on (ETF.EVENTTEXTID = CTE.EVENTTEXTID)		
			WHERE	 
			E.CRITERIANO = @pnCriteriaKey 
			" + @sSQLWhereImportanceLevel + " 
				and (C.EVENTDUEDATE>=@dtOverdueRangeFrom OR C.EVENTDUEDATE is null OR @dtOverdueRangeFrom is null OR C.OCCURREDFLAG>0)
				ORDER BY "+@sOrder
					
			exec @nErrorCode = sp_executesql @sSQLString,
								N'@pnUserIdentityId		int,
								  @pnCriteriaKey		int,
								  @pnCaseKey			int,
								  @pnCycle			int,
								  @pnImportanceLevelKey		int,
								  @nDefaultEventNoteType	int,
								  @bEventLogTableExists		bit,
								  @pbIsDisplayAllEventDetails	bit,
								  @dtOverdueRangeFrom		datetime',
								  @pnUserIdentityId		= @pnUserIdentityId,
								  @pnCriteriaKey		= @pnCriteriaKey,
								  @pnCaseKey			= @pnCaseKey,
								  @pnCycle			= @pnCycle,
								  @pnImportanceLevelKey		= @pnImportanceLevelKey,
								  @nDefaultEventNoteType	= @nDefaultEventNoteType,
								  @bEventLogTableExists		= @bEventLogTableExists,
								  @pbIsDisplayAllEventDetails	= @pbIsDisplayAllEventDetails,
								  @dtOverdueRangeFrom		= @dtOverdueRangeFrom
							  
		End
		Else Begin
			-------------------------------------
			-- All Events for a Non Cyclic Action
			-------------------------------------
			Set @sSQLString = "
			With	CTE_EventText (EVENTNO, CYCLE, EVENTTEXTID, LASTENTERED, DEFAULTTEXTTYPE)
					as (	select  CT.EVENTNO, CT.CYCLE, ET.EVENTTEXTID, isnull(ET.LOGDATETIMESTAMP,'1900-01-01'),
							CASE WHEN(ET.EVENTTEXTTYPEID is null)
								THEN '2'
								WHEN(ET.EVENTTEXTTYPEID=@nDefaultEventNoteType)
								THEN '1'
								ELSE '0'
							END
						from CASEEVENTTEXT CT
						join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
						Where CT.CASEID=@pnCaseKey
					)
			SELECT	
			CAST(isnull(C.CASEID, @pnCaseKey) as nvarchar(11))+'^'+ 
			CAST(E.EVENTNO as varchar(11)) +'^'+ CAST(isnull(C.CYCLE, 1) as nvarchar(5)) +'^'+
			CAST(case when (C.CASEID is null)then 1 else 0  end as nvarchar(5)) as 'RowKey',
			isnull(C.CASEID,@pnCaseKey) as 'CaseKey',
			E.EVENTNO as 'EventKey',
			COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+",
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EV',@sLookupCulture,@pbCalledFromCentura)+")
			as 'EventDescription',
			"+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ETF',@sLookupCulture,@pbCalledFromCentura)+"				
				as EventText,
			EVENTDATE as 'EventDate',  
			EVENTDUEDATE as 'EventDueDate',  				
			DATEREMIND as 'ReminderDate',  
			cast(isnull(C.CYCLE,1) as int) as 'Cycle', 
			cast(ISNULL(C.DATEDUESAVED,0) as bit) as 'DueDateSaved', 
			C.OCCURREDFLAG as 'OccuredFlag', 
			C.CREATEDBYACTION as 'CreatedByAction', 
			C.CREATEDBYCRITERIA as 'CreatedByCriteria', 
			C.IMPORTBATCHNO as 'ImportBatchKey', 
			CA.IRN as 'FromCaseReference',
			C.EMPLOYEENO as 'EmployeeKey', 
			N.NAMECODE as 'EmployeeCode',
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'EmployeeName',
			C.DUEDATERESPNAMETYPE as 'ResponsibleNameType',
			NT.DESCRIPTION		as 'ResponsibleNameTypeDescription',
			isnull( EVENTDATE, EVENTDUEDATE ) as 'AllDates',
			E.IMPORTANCELEVEL as 'ImportanceLevel',
			cast(case when (C.CASEID is null)then 1 else 0  end as bit) as 'IsNew',
			cast(case when (C.IMPORTBATCHNO is null)then 0 else 1  end as bit) as 'HasImportBatchKey',
			cast(case when (EVENTDUEDATE < getdate()) then 1 else 0 end as bit) as 'IsDueDatePast',
			cast(case when (DATEREMIND < getdate()) then 1 else 0 end as bit) as 'IsReminderDatePast',
			cast(case when (EVENTDUEDATE > getdate()and DATEDUESAVED = 1 ) then 1 else 0 end as bit) as 'IsDueDateFuture'," +char(10)+
			CASE WHEN @bEventLogTableExists = 1
					THEN "cast(case when exists (select 1 from CASEEVENT_iLOG L where L.CASEID = @pnCaseKey and L.EVENTNO = E.EVENTNO and L.CYCLE = ISNULL(C.CYCLE, L.CYCLE)) then 1 else 0 end as bit)"
				ELSE "cast(0 as bit)"
			END +char(10)+
				"as 'EventHasHistory',"

				If @bEntryFlag=1
				Begin
					Set @sSQLString=@sSQLString+char(10)+"dbo.fn_DoesEntryExistForCaseEvent(@pnUserIdentityId,C.CASEID,C.EVENTNO,C.CYCLE) as 'DoesEntryExistForCaseEvent',"
				End
				Else Begin
					Set @sSQLString=@sSQLString+char(10)+"					cast(0 as bit) as 'DoesEntryExistForCaseEvent',"
				End
				
				Set @sSQLString=@sSQLString+"
				C.FROMCASEID as FromCaseKey,
				cast(C.ENTEREDDEADLINE as nvarchar(20)) + ' ' + cast(TC.DESCRIPTION as nvarchar(20)) as Period,
				cast (case when exists (select 1 from DATESLOGIC DL where DL.EVENTNO = E.EVENTNO and DL.CRITERIANO = E.CRITERIANO) then 1 else 0 end as bit) as 'HasDatesLogic',
				cast (case when exists (select 1 from ACTIVITY A where A.EVENTNO = C.EVENTNO and A.CYCLE = C.CYCLE and A.CASEID = @pnCaseKey) then 1 else 0 end as bit) as 'HasAttachments',
				C.LOGDATETIMESTAMP as LastModifiedDate
			FROM EVENTCONTROL  E
			left join CASEEVENT C	ON (C.EVENTNO = E.EVENTNO 
						AND C.CASEID =  @pnCaseKey 
						AND C.OCCURREDFLAG < 9)
			left join CASES CA	on (CA.CASEID = C.FROMCASEID)
			left join EVENTS EV	on (EV.EVENTNO = E.EVENTNO )
			left join NAME N	on (N.NAMENO = C.EMPLOYEENO)
			left join NAMETYPE NT	on (NT.NAMETYPE = C.DUEDATERESPNAMETYPE)
			left join TABLECODES TC on (TC.TABLETYPE = 127 and TC.USERCODE = C.PERIODTYPE)

			-------------------------------------------
			-- The Event Note to return is based on the
			-- following hierarchy:
			-- 1 - No TextType
			-- 2 - Users default Text Type
			-- 3 - Most recently modified text
			-------------------------------------------
			left join CTE_EventText CTE	on (CTE.EVENTNO  =C.EVENTNO
							and CTE.CYCLE    =C.CYCLE
							and CTE.EVENTTEXTID = Cast
								     (substring
								      ((select max(CTE1.DEFAULTTEXTTYPE + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
									from CTE_EventText CTE1
									where CTE1.EVENTNO  =CTE.EVENTNO
									and   CTE1.CYCLE    =CTE.CYCLE ),25,11) as int)
								)
			left join EVENTTEXT ETF		on (ETF.EVENTTEXTID = CTE.EVENTTEXTID)
			WHERE	 
			E.CRITERIANO = @pnCriteriaKey
			 " + @sSQLWhereImportanceLevel + "
				and (C.EVENTDUEDATE>=@dtOverdueRangeFrom OR C.EVENTDUEDATE is null OR @dtOverdueRangeFrom is null OR C.OCCURREDFLAG>0)
				ORDER BY "+@sOrder

			exec @nErrorCode = sp_executesql @sSQLString,
								N'@pnUserIdentityId		int,
								  @pnCriteriaKey		int,
								  @pnCaseKey			int,
								  @pnImportanceLevelKey		int,
								  @nDefaultEventNoteType	int,
								  @bEventLogTableExists		bit,
								  @pbIsDisplayAllEventDetails	bit,
								  @dtOverdueRangeFrom		datetime,
								  @pnCycle			int',								  
								  @pnUserIdentityId		= @pnUserIdentityId,
								  @pnCriteriaKey		= @pnCriteriaKey,
								  @pnCaseKey			= @pnCaseKey,
								  @pnImportanceLevelKey		= @pnImportanceLevelKey,
								  @nDefaultEventNoteType	= @nDefaultEventNoteType,
								  @bEventLogTableExists		= @bEventLogTableExists,
								  @pbIsDisplayAllEventDetails	= @pbIsDisplayAllEventDetails,
								  @dtOverdueRangeFrom		= @dtOverdueRangeFrom,
								  @pnCycle			= @pnCycle
		End

	End
	Else
	Begin
		if @pbIsActionCyclic = 1
		Begin
			-----------------------------
			-- Events for a Cyclic Action
			-----------------------------
			Set @sSQLString = "
			With	CTE_EventText (EVENTNO, CYCLE, EVENTTEXTID, LASTENTERED, DEFAULTTEXTTYPE)
					as (	select  CT.EVENTNO, CT.CYCLE, ET.EVENTTEXTID, isnull(ET.LOGDATETIMESTAMP,'1900-01-01'),
							CASE WHEN(ET.EVENTTEXTTYPEID is null)
								THEN '2'
								WHEN(ET.EVENTTEXTTYPEID=@nDefaultEventNoteType)
								THEN '1'
								ELSE '0'
							END
						from CASEEVENTTEXT CT
						join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
						Where CT.CASEID=@pnCaseKey
					)
			SELECT	
			CAST(C.CASEID as nvarchar(11))+'^'+ 
				CAST(E.EVENTNO as varchar(11)) +'^'+ CAST(C.CYCLE as nvarchar(5))+'^'+
			CAST(case when (C.CASEID is null)then 1 else 0  end as nvarchar(5)) as 'RowKey',
			C.CASEID as 'CaseKey',
			E.EVENTNO as 'EventKey',
			COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+",
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EV',@sLookupCulture,@pbCalledFromCentura)+")
			as 'EventDescription',
			"+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ETF',@sLookupCulture,@pbCalledFromCentura)+"				
								as EventText,
			EVENTDATE as 'EventDate',  
				EVENTDUEDATE as 'EventDueDate',  
				DATEREMIND as 'ReminderDate',  											
			C.CYCLE as 'Cycle', 
			cast(ISNULL(C.DATEDUESAVED,0) as bit) as 'DueDateSaved', 
			C.OCCURREDFLAG as 'OccuredFlag', 
			C.CREATEDBYACTION as 'CreatedByAction', 
			C.CREATEDBYCRITERIA as 'CreatedByCriteria', 
			C.IMPORTBATCHNO as 'ImportBatchKey', 
			CA.IRN as 'FromCaseReference',
			C.EMPLOYEENO as 'EmployeeKey', 
			N.NAMECODE as 'EmployeeCode',
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'EmployeeName',
			C.DUEDATERESPNAMETYPE as 'ResponsibleNameType',
			NT.DESCRIPTION		as 'ResponsibleNameTypeDescription',
			isnull( EVENTDATE, EVENTDUEDATE ) as 'AllDates',
			E.IMPORTANCELEVEL as 'ImportanceLevel',
			cast(0 as bit) as 'IsNew',
			cast(case when (C.IMPORTBATCHNO is null)then 0 else 1  end as bit) as 'HasImportBatchKey',
			cast(case when (EVENTDUEDATE < getdate()) then 1 else 0 end as bit) as 'IsDueDatePast',
			cast(case when (DATEREMIND < getdate()) then 1 else 0 end as bit) as 'IsReminderDatePast',
			cast(case when (EVENTDUEDATE > getdate()and DATEDUESAVED = 1 ) then 1 else 0 end as bit) as 'IsDueDateFuture'," +char(10)+
			CASE WHEN @bEventLogTableExists = 1
					THEN "cast(case when exists (select 1 from CASEEVENT_iLOG where CASEID = @pnCaseKey and EVENTNO = E.EVENTNO and CYCLE = C.CYCLE) then 1 else 0 end as bit)"
				ELSE "cast(0 as bit)"
			END +char(10)+
				"as 'EventHasHistory',"

			If @bEntryFlag=1
			Begin
				Set @sSQLString=@sSQLString+char(10)+"dbo.fn_DoesEntryExistForCaseEvent(@pnUserIdentityId,C.CASEID,C.EVENTNO,C.CYCLE) as 'DoesEntryExistForCaseEvent',"
			End
			Else Begin
				Set @sSQLString=@sSQLString+char(10)+"					cast(0 as bit) as 'DoesEntryExistForCaseEvent',"
			End
			
			Set @sSQLString=@sSQLString+"
				C.FROMCASEID as FromCaseKey,
				cast(C.ENTEREDDEADLINE as nvarchar(20)) + ' ' + cast(TC.DESCRIPTION as nvarchar(20)) as Period,
				cast (case when exists (select 1 from DATESLOGIC DL where DL.EVENTNO = E.EVENTNO and DL.CRITERIANO = E.CRITERIANO) then 1 else 0 end as bit) as 'HasDatesLogic',
				cast (case when exists (select 1 from ACTIVITY A where A.EVENTNO = C.EVENTNO and A.CYCLE = C.CYCLE and A.CASEID = @pnCaseKey) then 1 else 0 end as bit) as 'HasAttachments',
				C.LOGDATETIMESTAMP as LastModifiedDate
			FROM CASEEVENT C
			join EVENTCONTROL E	ON ( E.EVENTNO = C.EVENTNO  " + @sSQLWhereImportanceLevel + " )
			left join CASES CA	on (CA.CASEID = C.FROMCASEID)
			left join EVENTS EV	on (EV.EVENTNO = E.EVENTNO )
			left join NAME N	on (N.NAMENO = C.EMPLOYEENO)
			left join NAMETYPE NT	on (NT.NAMETYPE = C.DUEDATERESPNAMETYPE)				
			left join TABLECODES TC	on (TC.TABLETYPE = 127 and TC.USERCODE = C.PERIODTYPE)

			-------------------------------------------
			-- The Event Note to return is based on the
			-- following hierarchy:
			-- 1 - No TextType
			-- 2 - Users default Text Type
			-- 3 - Most recently modified text
			-------------------------------------------
			left join CTE_EventText CTE	on (CTE.EVENTNO  =C.EVENTNO
							and CTE.CYCLE    =C.CYCLE
							and CTE.EVENTTEXTID = Cast
								     (substring
								      ((select max(CTE1.DEFAULTTEXTTYPE + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
									from CTE_EventText CTE1
									where CTE1.EVENTNO  =CTE.EVENTNO
									and   CTE1.CYCLE    =CTE.CYCLE ),25,11) as int)
								)
			left join EVENTTEXT ETF		on (ETF.EVENTTEXTID = CTE.EVENTTEXTID)
			WHERE	C.CASEID =  @pnCaseKey
			AND	C.OCCURREDFLAG < 9 
			AND	C.CYCLE = @pnCycle
			AND 	NOT (EVENTDATE IS NULL
			AND	     EVENTDUEDATE IS NULL
			AND	     DATEREMIND IS NULL)  
			AND	E.CRITERIANO = @pnCriteriaKey 
			and    (C.EVENTDUEDATE>=@dtOverdueRangeFrom OR @dtOverdueRangeFrom is null OR C.OCCURREDFLAG>0)
			ORDER BY "+@sOrder

			exec @nErrorCode = sp_executesql @sSQLString,
								N'@pnUserIdentityId		int,
								  @pnCriteriaKey		int,
								  @pnCaseKey			int,
								  @pnCycle			int,
								  @pnImportanceLevelKey		int,
								  @nDefaultEventNoteType	int,
								  @bEventLogTableExists		bit,
								  @pbIsDisplayAllEventDetails	bit,
								  @dtOverdueRangeFrom		datetime',
								  @pnUserIdentityId		= @pnUserIdentityId,
								  @pnCriteriaKey		= @pnCriteriaKey,
								  @pnCaseKey			= @pnCaseKey,
								  @pnCycle			= @pnCycle,
								  @pnImportanceLevelKey		= @pnImportanceLevelKey,
								  @nDefaultEventNoteType	= @nDefaultEventNoteType,
								  @bEventLogTableExists		= @bEventLogTableExists,
								  @pbIsDisplayAllEventDetails	= @pbIsDisplayAllEventDetails,
								  @dtOverdueRangeFrom		= @dtOverdueRangeFrom
		End
		Else If (@pbIsActionCyclic = 0)
		Begin
			If  @pbIsMostRecentCycle = 1
			and isnull(@sOrderType,'')<>'CD'	-- If sorting by Cycle then return all cycles.	
			Begin

				---------------------------------
				-- Events for a Non Cyclic Action
				-- showing the most recent Event
				-- cycle.
				---------------------------------
				Set @sSQLString = "
				With	CTE_EventText (EVENTNO, CYCLE, EVENTTEXTID, LASTENTERED, DEFAULTTEXTTYPE)
						as (	select  CT.EVENTNO, CT.CYCLE, ET.EVENTTEXTID, isnull(ET.LOGDATETIMESTAMP,'1900-01-01'),
								CASE WHEN(ET.EVENTTEXTTYPEID is null)
									THEN '2'
									WHEN(ET.EVENTTEXTTYPEID=@nDefaultEventNoteType)
									THEN '1'
									ELSE '0'
								END
							from CASEEVENTTEXT CT
							join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
							Where CT.CASEID=@pnCaseKey
						)
				SELECT	
				CAST(C.CASEID as nvarchar(11))+'^'+ 
							CAST(E.EVENTNO as varchar(11)) +'^'+ CAST(C.CYCLE as nvarchar(5))+'^'+
				CAST(case when (C.CASEID is null)then 1 else 0  end as nvarchar(5)) as 'RowKey',
				C.CASEID as 'CaseKey',
				E.EVENTNO as 'EventKey',
				COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+",
				"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EV',@sLookupCulture,@pbCalledFromCentura)+")
				as 'EventDescription',
				"+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ETF',@sLookupCulture,@pbCalledFromCentura)+"				
											as EventText,
				EVENTDATE as 'EventDate',
				EVENTDUEDATE as 'EventDueDate',  
				DATEREMIND as 'ReminderDate',  
				cast(isnull(C.CYCLE,1) as int) as 'Cycle', 
				cast(ISNULL(C.DATEDUESAVED,0) as bit) as 'DueDateSaved', 
				C.OCCURREDFLAG as 'OccuredFlag', 
				C.CREATEDBYACTION as 'CreatedByAction', 
				C.CREATEDBYCRITERIA as 'CreatedByCriteria', 
				C.IMPORTBATCHNO as 'ImportBatchKey', 
				CA.IRN as 'FromCaseReference',
				C.EMPLOYEENO as 'EmployeeKey', 
				N.NAMECODE as 'EmployeeCode',
				dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'EmployeeName',
				C.DUEDATERESPNAMETYPE as 'ResponsibleNameType',
				NT.DESCRIPTION		as 'ResponsibleNameTypeDescription',
				isnull( EVENTDATE, EVENTDUEDATE ) as 'AllDates',
				E.IMPORTANCELEVEL as 'ImportanceLevel',
				cast(case when (C.CASEID is null)then 1 else 0  end as bit) as 'IsNew',
				cast(case when (C.IMPORTBATCHNO is null)then 0 else 1  end as bit) as 'HasImportBatchKey',
				cast(case when (EVENTDUEDATE < getdate()) then 1 else 0 end as bit) as 'IsDueDatePast',
				cast(case when (DATEREMIND < getdate()) then 1 else 0 end as bit) as 'IsReminderDatePast',
				cast(case when (EVENTDUEDATE > getdate()and DATEDUESAVED = 1 ) then 1 else 0 end as bit) as 'IsDueDateFuture'," +char(10)+
				CASE WHEN @bEventLogTableExists = 1
					THEN "cast(case when exists (select 1 from CASEEVENT_iLOG where CASEID = @pnCaseKey and EVENTNO = E.EVENTNO and CYCLE = C.CYCLE) then 1 else 0 end as bit)"
					ELSE "cast(0 as bit)"
				END +char(10)+
				"as 'EventHasHistory',"

				If @bEntryFlag=1
				Begin
					Set @sSQLString=@sSQLString+char(10)+"dbo.fn_DoesEntryExistForCaseEvent(@pnUserIdentityId,C.CASEID,C.EVENTNO,C.CYCLE) as 'DoesEntryExistForCaseEvent',"
				End
				Else Begin
					Set @sSQLString=@sSQLString+char(10)+"					cast(0 as bit) as 'DoesEntryExistForCaseEvent',"
				End
				
				Set @sSQLString=@sSQLString+"
				C.FROMCASEID as FromCaseKey,
				cast(C.ENTEREDDEADLINE as nvarchar(20)) + ' ' + cast(TC.DESCRIPTION as nvarchar(20)) as Period,
				cast (case when exists (select 1 from DATESLOGIC DL where DL.EVENTNO = E.EVENTNO and DL.CRITERIANO = E.CRITERIANO) then 1 else 0 end as bit) as 'HasDatesLogic',
				cast (case when exists (select 1 from ACTIVITY A where A.EVENTNO = C.EVENTNO and A.CYCLE = C.CYCLE and A.CASEID = @pnCaseKey) then 1 else 0 end as bit) as 'HasAttachments',
				C.LOGDATETIMESTAMP as LastModifiedDate
				FROM CASEEVENT C
				join EVENTCONTROL E	ON ( E.EVENTNO = C.EVENTNO  " + @sSQLWhereImportanceLevel + " )
				left join CASES CA	on (CA.CASEID = C.FROMCASEID)
				left join EVENTS EV	on (EV.EVENTNO = E.EVENTNO )
				left join NAME N	on (N.NAMENO = C.EMPLOYEENO)
				left join NAMETYPE NT	on (NT.NAMETYPE = C.DUEDATERESPNAMETYPE)					
				left join TABLECODES TC on (TC.TABLETYPE = 127 and TC.USERCODE = C.PERIODTYPE)"
				-- get the lowest cycle for a due date
				+CHAR(10)+
				"left join (select CASEID, EVENTNO, min(CYCLE) as CYCLE
					   from CASEEVENT
					   where OCCURREDFLAG=0
					   and EVENTDUEDATE is not null
					   group by CASEID, EVENTNO) CE1
							on (CE1.CASEID=C.CASEID
							and CE1.EVENTNO=C.EVENTNO)"
				-- get the highest cycle for an occurred date
				+CHAR(10)+
				"left join (select CASEID, EVENTNO, max(CYCLE) as CYCLE
					   from CASEEVENT
					   where OCCURREDFLAG between 1 and 8
					   and EVENTDATE is not null
					   group by CASEID, EVENTNO) CE2
							on (CE2.CASEID=C.CASEID
							and CE2.EVENTNO=C.EVENTNO)

				-------------------------------------------
				-- The Event Note to return is based on the
				-- following hierarchy:
				-- 1 - No TextType
				-- 2 - Users default Text Type
				-- 3 - Most recently modified text
				-------------------------------------------
				left join CTE_EventText CTE	on (CTE.EVENTNO  =C.EVENTNO
								and CTE.CYCLE    =C.CYCLE
								and CTE.EVENTTEXTID = Cast
									     (substring
									      ((select max(CTE1.DEFAULTTEXTTYPE + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
										from CTE_EventText CTE1
										where CTE1.EVENTNO  =CTE.EVENTNO
										and   CTE1.CYCLE    =CTE.CYCLE ),25,11) as int)
									)
				left join EVENTTEXT ETF		on (ETF.EVENTTEXTID = CTE.EVENTTEXTID)	
				WHERE	C.CASEID =  @pnCaseKey
				AND	C.OCCURREDFLAG < 9 "
				-- Display the first due date in preference to the last occurred date
				+CHAR(10)+
				"AND	C.CYCLE=isnull(CE1.CYCLE, CE2.CYCLE)
				AND E.CRITERIANO = @pnCriteriaKey 
				ORDER BY "+@sOrder

				exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnUserIdentityId	int,
							  @pnCriteriaKey	int,
							  @pnCaseKey		int,
							  @pnImportanceLevelKey int,
							  @nDefaultEventNoteType int,
							  @bEventLogTableExists	bit,
							  @pnCycle		int,
							  @pbIsActionCyclic	bit',
							  @pnUserIdentityId	= @pnUserIdentityId,
							  @pnCriteriaKey	= @pnCriteriaKey,
							  @pnCaseKey		= @pnCaseKey,
							  @pnImportanceLevelKey = @pnImportanceLevelKey,
							  @nDefaultEventNoteType= @nDefaultEventNoteType,
							  @bEventLogTableExists = @bEventLogTableExists,
							  @pnCycle		= @pnCycle,
							  @pbIsActionCyclic	= @pbIsActionCyclic
			End
			Else Begin
				---------------------------------
				-- Events for a Non Cyclic Action
				-- showing the all Event cycles.
				---------------------------------
				Set @sSQLString = "
				With	CTE_EventText (EVENTNO, CYCLE, EVENTTEXTID, LASTENTERED, DEFAULTTEXTTYPE)
						as (	select  CT.EVENTNO, CT.CYCLE, ET.EVENTTEXTID, isnull(ET.LOGDATETIMESTAMP,'1900-01-01'),
								CASE WHEN(ET.EVENTTEXTTYPEID is null)
									THEN '2'
									WHEN(ET.EVENTTEXTTYPEID=@nDefaultEventNoteType)
									THEN '1'
									ELSE '0'
								END
							from CASEEVENTTEXT CT
							join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
							Where CT.CASEID=@pnCaseKey
						)
				SELECT	CAST(C.CASEID as nvarchar(11))+'^'+ 
				CAST(E.EVENTNO as varchar(11)) +'^'+ CAST(C.CYCLE as nvarchar(5))+'^'+
				CAST(case when (C.CASEID is null)then 1 else 0  end as nvarchar(5)) as 'RowKey',
				C.CASEID as 'CaseKey',
				E.EVENTNO as 'EventKey',
				COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+",
				"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EV',@sLookupCulture,@pbCalledFromCentura)+")
				as 'EventDescription',
				"+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ETF',@sLookupCulture,@pbCalledFromCentura)+"				
								as EventText,
				EVENTDATE as 'EventDate',  
				EVENTDUEDATE as 'EventDueDate',  				
				DATEREMIND as 'ReminderDate',
				C.CYCLE as 'Cycle', 
				cast(ISNULL(C.DATEDUESAVED,0) as bit) as 'DueDateSaved', 
				C.OCCURREDFLAG as 'OccuredFlag', 
				C.CREATEDBYACTION as 'CreatedByAction', 
				C.CREATEDBYCRITERIA as 'CreatedByCriteria', 
				C.IMPORTBATCHNO as 'ImportBatchKey', 
				CA.IRN as 'FromCaseReference',
				C.EMPLOYEENO as 'EmployeeKey', 
				N.NAMECODE as 'EmployeeCode',
				dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'EmployeeName',
				C.DUEDATERESPNAMETYPE as 'ResponsibleNameType',
				NT.DESCRIPTION		as 'ResponsibleNameTypeDescription',
				isnull( EVENTDATE, EVENTDUEDATE ) as 'AllDates',
				E.IMPORTANCELEVEL as 'ImportanceLevel',
				cast(0 as bit) as 'IsNew',
				cast(case when (C.IMPORTBATCHNO is null)then 0 else 1  end as bit) as 'HasImportBatchKey',
				cast(case when (EVENTDUEDATE < getdate()) then 1 else 0 end as bit) as 'IsDueDatePast',
				cast(case when (DATEREMIND < getdate()) then 1 else 0 end as bit) as 'IsReminderDatePast',
				cast(case when (EVENTDUEDATE > getdate()and DATEDUESAVED = 1 ) then 1 else 0 end as bit) as 'IsDueDateFuture'," +char(10)+
				CASE WHEN @bEventLogTableExists = 1
					THEN "cast(case when exists (select 1 from CASEEVENT_iLOG where CASEID = @pnCaseKey and EVENTNO = E.EVENTNO and CYCLE = C.CYCLE) then 1 else 0 end as bit)"
					ELSE "cast(0 as bit)"
				END +char(10)+
				"as 'EventHasHistory',"

				If @bEntryFlag=1
				Begin
					Set @sSQLString=@sSQLString+char(10)+"dbo.fn_DoesEntryExistForCaseEvent(@pnUserIdentityId,C.CASEID,C.EVENTNO,C.CYCLE) as 'DoesEntryExistForCaseEvent',"
				End
				Else Begin
					Set @sSQLString=@sSQLString+char(10)+"					cast(0 as bit) as 'DoesEntryExistForCaseEvent',"
				End
				
				Set @sSQLString=@sSQLString+"
				C.FROMCASEID as FromCaseKey,
				cast(C.ENTEREDDEADLINE as nvarchar(20)) + ' ' + cast(TC.DESCRIPTION as nvarchar(20)) as Period,
				cast (case when exists (select 1 from DATESLOGIC DL where DL.EVENTNO = E.EVENTNO and DL.CRITERIANO = E.CRITERIANO) then 1 else 0 end as bit) as 'HasDatesLogic',
				cast (case when exists (select 1 from ACTIVITY A where A.EVENTNO = C.EVENTNO and A.CYCLE = C.CYCLE and A.CASEID = @pnCaseKey) then 1 else 0 end as bit) as 'HasAttachments',
				C.LOGDATETIMESTAMP as LastModifiedDate
				FROM CASEEVENT  C
				join EVENTCONTROL E	ON ( E.EVENTNO = C.EVENTNO  " + @sSQLWhereImportanceLevel + " )
				left join CASES CA	on (CA.CASEID = C.FROMCASEID)
				left join EVENTS EV	on (EV.EVENTNO = E.EVENTNO )
				left join NAME N	on (N.NAMENO = C.EMPLOYEENO)
				left join NAMETYPE NT	on (NT.NAMETYPE = C.DUEDATERESPNAMETYPE)					
				left join TABLECODES TC on (TC.TABLETYPE = 127 and TC.USERCODE = C.PERIODTYPE)

				-------------------------------------------
				-- The Event Note to return is based on the
				-- following hierarchy:
				-- 1 - No TextType
				-- 2 - Users default Text Type
				-- 3 - Most recently modified text
				-------------------------------------------
				left join CTE_EventText CTE	on (CTE.EVENTNO  =C.EVENTNO
								and CTE.CYCLE    =C.CYCLE
								and CTE.EVENTTEXTID = Cast
									     (substring
									      ((select max(CTE1.DEFAULTTEXTTYPE + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
										from CTE_EventText CTE1
										where CTE1.EVENTNO  =CTE.EVENTNO
										and   CTE1.CYCLE    =CTE.CYCLE ),25,11) as int)
									)
				left join EVENTTEXT ETF		on (ETF.EVENTTEXTID = CTE.EVENTTEXTID)
				WHERE	C.CASEID =  @pnCaseKey
				AND	C.OCCURREDFLAG < 9 
				AND 	NOT (EVENTDATE    IS NULL
				AND	     EVENTDUEDATE IS NULL
				AND	     DATEREMIND   IS NULL)  
				AND     E.CRITERIANO = @pnCriteriaKey 
				ORDER BY "+@sOrder

				exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnUserIdentityId	int,
							  @pnCriteriaKey	int,
							  @pnCaseKey		int,
							  @pnImportanceLevelKey int,
							  @nDefaultEventNoteType int,
							  @bEventLogTableExists	bit,
							  @dtOverdueRangeFrom	datetime,
							  @pnCycle		int,
							  @pbIsActionCyclic	bit',
							  @pnUserIdentityId	= @pnUserIdentityId,
							  @pnCriteriaKey	= @pnCriteriaKey,
							  @pnCaseKey		= @pnCaseKey,
							  @pnImportanceLevelKey = @pnImportanceLevelKey,
							  @nDefaultEventNoteType= @nDefaultEventNoteType,
							  @bEventLogTableExists = @bEventLogTableExists,
							  @dtOverdueRangeFrom	= @dtOverdueRangeFrom,
							  @pnCycle		= @pnCycle,
							  @pbIsActionCyclic	= @pbIsActionCyclic
			End
		End
	End
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseEvents to public
GO
