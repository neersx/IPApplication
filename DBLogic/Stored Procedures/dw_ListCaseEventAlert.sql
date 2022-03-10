-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dw_ListCaseEventAlert
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[dw_ListCaseEventAlert]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.dw_ListCaseEventAlert.'
	drop procedure dbo.dw_ListCaseEventAlert
end
print '**** Creating procedure dbo.dw_ListCaseEventAlert...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create PROCEDURE dbo.dw_ListCaseEventAlert (
		@pnRowCount		int output,
		@pnUserIdentityId	int,		-- Mandatory
		@psCulture		nvarchar(10) 	= null,  
		@pnCaseId		int,
		@pbCalledByCentura	bit 		= 0)
AS

-- PROCEDURE :	dw_ListCaseEventAlert
-- VERSION :	19
-- SCOPE:	CPA Inprotech
-- DESCRIPTION:	Display data in the Docket Wizard table
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 12 Nov 04  	MB	10074	1	Procedure created
-- 23 Nov 04	MF	10074	1	Continuation
-- 29 Nov 04	MF	10074	1	Continuation.  Correct the Order By
-- 30 Nov 04	MF	10074	2	Continuation. Exclude EventNo's -13 & -14
-- 09 Dec 04	MF	10074	3	Continuation. Ensure Due Events are only returned if there is an open action.
-- 08 Nov 05	MF	12023	4	If a duplicate DisplayOrder has been set for an Alert or CaseEvent when it is
--					not a valid situation, then CaseEvent rows may fail to be returned.  Resolved 
--					by renumbering the DisplayOrder to ensure they are valid.
-- 13 Nov 07	MF	13793	5	Selected LONGFLAG, EVENTTEXT and EVENTLONGTEXT columns.
-- 20 Dec 07	SW	RFC5708	6	add translation support, security checking and new columns for workbenches
-- 16 JAN 08	SF	RFC5708	7	modify rowkey, and add IsNew, displayorder
-- 25 MAR 08	SF	RFC5790	8	translations not returned on some events
-- 26 MAR 08	SF	RFC6350	9	Suppress case events that have been "deleted" previously but has yet to be policed.
-- 02 Apr 09	Ash	RFC7351	10	comment the event text and correct the Order By.
-- 27 Apr 10	DL	18642	11	Make column aliases unique so that the order by clause do not need to prefix them with table alias.
--					Note: this change will ensure SQL Server Upgrade Advisor will not display warning message from this stored procedure
--					due to column aliases cannot be used with table alias.
-- 09 Aug 10	SF		12	Version 11 changed the name OccurredDate to T1T2_OccurredDate which caued the Web version Docketing Wizard to malfunction.
--					Note: Web version software requires the names to match.	
-- 01 May 12	MF	R12231	13	Event Description should be returned by looking at the Controlling Action if it is defined.				
-- 27 Feb 2014	DL	S21508	14	Change variables and temp table columns that reference namecode to 20 characters
-- 09 Apr 2014  MS      R31303  15      Added LogDateTimeStamp in resultset
-- 02 Nov 2015	vql	R53910	16	Adjust formatted names logic (DR-15543).
-- 26 Dec 2016	MS	R70131	17	Added StaffId in Rowkey in resultset
-- 08 Jan 2018	vql	R71716	18	SQL Error When Trying to Access the Docket Wizard (DR-34870).
-- 07 Sep 2018	AV	74738	19	Set isolation level to read uncommited.

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @ErrorCode	int
declare @nDisplayOrder	int
declare @nDueEventNo	int
declare @nSequenceNo	tinyint
declare @dtAlertSeq	datetime
Declare @sLookupCulture	nvarchar(10)
declare @bExternalUser	bit
declare @sSQLString	nvarchar(4000)

If @psCulture is not null
Begin
	Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 

-- Define a table variables to collect all of the potential rows to be displayed
-- This table variable will be used as a staging area for gathering the required
-- data from a variety of sources.
-- The final result set will combine any two rows that have the same DISPLAYORDER
-- into a single row.

declare @tbDueDates table (
		DueEventNo		int		NULL,
		DueCycleNo		smallint	NULL,
		EventDue		nvarchar(1000)	collate database_default NULL,
		EventDueTid		int		NULL,
		DueDate			datetime	NULL,
		StaffId			int		NULL,
		StaffNameCode		nvarchar(20)	collate database_default NULL,
		StaffMember		nvarchar(500)	collate database_default NULL,
		OccurredEventNo		int		NULL,
		OccurredCycleNo		smallint	NULL,
		OccurredEvent		nvarchar(1000)	collate database_default NULL,
		OccurredEventTid	int		NULL,
		DateOccurred		datetime	NULL,
		SendMethodId		int		NULL,
		SendMethod		nvarchar(80)	collate database_default NULL,
		SendMethodTid		int		NULL,
		SentDate		datetime	NULL,
		ReceiptDate		datetime	NULL,
		Reference		nvarchar(50)	collate database_default NULL,
		AlertSeq		datetime	NULL,
		DisplayOrder		smallint	NULL,
		SortDate		datetime	NULL,
		OccurredFlag		tinyint		NULL,
		LastModifiedDate        datetime        NULL,
		RowId			smallint	identity(1,1)
	)

Set @ErrorCode = 0

-- Determine if the user is internal or external
If @ErrorCode = 0
Begin		
	Set @sSQLString = "
	Select	@bExternalUser = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId"

	Exec  @ErrorCode = sp_executesql @sSQLString,
				N'@bExternalUser	bit			OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser	= @bExternalUser	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId
End

-- Load a table variable with the data to be returned from both the CASEEVENT
-- and ALERT tables.  
-- The table variable is being used because the final result set may combine 2 events
-- with the same DisplayOrder to appear in the one row.
If @ErrorCode = 0
Begin
	Insert into @tbDueDates(DueEventNo, DueCycleNo, EventDue, EventDueTid, DueDate, StaffId, StaffMember, StaffNameCode,
				OccurredEventNo, OccurredCycleNo, OccurredEvent, OccurredEventTid, DateOccurred,
				SendMethodId, SendMethod, SendMethodTid, SentDate, ReceiptDate, Reference,
				AlertSeq, DisplayOrder, SortDate, OccurredFlag, LastModifiedDate)
	Select
	CASE WHEN(CE.EVENTDUEDATE is not null) THEN CE.EVENTNO END,
	CASE WHEN(CE.EVENTDUEDATE is not null) THEN CE.CYCLE END,
	CASE WHEN(CE.EVENTDUEDATE is not null) THEN isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION) END,
	CASE WHEN(CE.EVENTDUEDATE is not null) THEN isnull(EC.EVENTDESCRIPTION_TID, E.EVENTDESCRIPTION_TID) END,
	CE.EVENTDUEDATE,
	CE.EMPLOYEENO,  
	dbo.fn_FormatNameUsingNameNo(N.NAMENO,DEFAULT),
	N.NAMECODE,
	CASE WHEN(CE.EVENTDATE is not null) THEN CE.EVENTNO END,
	CASE WHEN(CE.EVENTDATE is not null) THEN CE.CYCLE END,
	CASE WHEN(CE.EVENTDATE is not null) THEN isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION) END,
	CASE WHEN(CE.EVENTDATE is not null) THEN isnull(EC.EVENTDESCRIPTION_TID, E.EVENTDESCRIPTION_TID) END,
	CE.EVENTDATE,

	CE.SENDMETHOD,
	TC.DESCRIPTION,
	TC.DESCRIPTION_TID,
	CE.SENTDATE,
	CE.RECEIPTDATE,
	CE.RECEIPTREFERENCE,
	NULL,
	CE.DISPLAYORDER*10,
	CASE WHEN(CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0) 
		THEN CE.EVENTDUEDATE 
		ELSE '31-DEC-3000' 
	END,
	CE.OCCURREDFLAG,
	CE.LOGDATETIMESTAMP
	from CASEEVENT CE
	left join OPENACTION OA		on (OA.CASEID=CE.CASEID)
	     join EVENTS E 		on ( E.EVENTNO=CE.EVENTNO)
	left join EVENTCONTROL EC	on (EC.EVENTNO=CE.EVENTNO
					and EC.CRITERIANO=isnull((select max(EC1.CRITERIANO)
								from OPENACTION OA1
								join EVENTCONTROL EC1 on (EC1.CRITERIANO=OA1.CRITERIANO
										      and EC1.EVENTNO=CE.EVENTNO)
								where OA1.CASEID=CE.CASEID
								and (OA1.ACTION=E.CONTROLLINGACTION OR (E.CONTROLLINGACTION is NULL and OA1.POLICEEVENTS=1))
								), CE.CREATEDBYCRITERIA))
	left join ACTIONS A		on ( A.ACTION =OA.ACTION)
	left join NAME N 		on ( N.NAMENO =CE.EMPLOYEENO)
	left join TABLECODES TC 	on (TC.TABLECODE=CE.SENDMETHOD)
	where CE.CASEID = @pnCaseId
	and CE.EVENTNO not in (-13,-14)
	-- A due event will only be returned if it is attached to an Open Action
	-- with the appropriate Cycle
	and (CE.OCCURREDFLAG between 1 and 8
	 OR (CE.OCCURREDFLAG=0 and
	     EC.CRITERIANO=OA.CRITERIANO and
	     OA.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED=1) THEN 1 ELSE CE.CYCLE END and
	     OA.POLICEEVENTS=1))
	-- Some events have been 'deleted' but hasn't been policed
	-- Return those with at least one date present
	and (CE.EVENTDATE is not null OR CE.EVENTDUEDATE is not null)
	
	union
	
	Select
		NULL,
		NULL,
		CASE WHEN(A.DUEDATE is not null) THEN A.ALERTMESSAGE END,
		NULL,
		A.DUEDATE,
		A.EMPLOYEENO,  
		dbo.fn_FormatNameUsingNameNo(N.NAMENO,DEFAULT),
		N.NAMECODE,
		NULL,
		NULL,
		CASE WHEN(A.DATEOCCURRED is not null) THEN A.ALERTMESSAGE END,
		NULL,
		A.DATEOCCURRED,
		A.SENDMETHOD,
		TC.DESCRIPTION,
		TC.DESCRIPTION_TID,
		A.SENTDATE,
		A.RECEIPTDATE,
		A.RECEIPTREFERENCE,
		A.ALERTSEQ,
		A.DISPLAYORDER*10,
		CASE WHEN(A.DUEDATE is not null and A.DATEOCCURRED is null and isnull(A.OCCURREDFLAG,0)=0) 
			THEN A.DUEDATE 
			ELSE '31-DEC-3000' 
		END,
		A.OCCURREDFLAG,
		A.LOGDATETIMESTAMP
	from ALERT A  
	left join NAME N	on (N.NAMENO=A.EMPLOYEENO)
	left join TABLECODES TC on (TC.TABLECODE=A.SENDMETHOD)
	where A.CASEID = @pnCaseId
	order by 20,22

	set @ErrorCode=@@Error
end

-- SQA12023
-- Need to safeguard against multiple rows having the same DISPLAYORDER value.
If @ErrorCode=0
Begin
	Set @nDisplayOrder = null
	Set @nDueEventNo   = null

	-- The DISPLAYORDER should be different to previous rows unless it is an EventDate
	-- following a DueDate.

	Update @tbDueDates
	Set 	@nSequenceNo = 
		Case When (@nDisplayOrder=DisplayOrder)
			Then Case When(@nDueEventNo is not null and OccurredEventNo is not null) 
					Then 0
					Else @nSequenceNo+1
			     End
			Else 0
		End,
		DisplayOrder  =DisplayOrder + @nSequenceNo,
		@nDisplayOrder=DisplayOrder,
		@nDueEventNo  =DueEventNo

	Set @ErrorCode=@@Error
End

If @pbCalledByCentura = 1
Begin

	-- Now return the result set 
	If @ErrorCode=0
	Begin
		Select	T1.DueEventNo, 
			T1.DueCycleNo, 
			T1.EventDue, 
			T1.DueDate, 
			T1.StaffId, 
			T1.StaffMember,
			isnull(T2.OccurredEventNo, T1.OccurredEventNo),
			isnull(T2.OccurredCycleNo, T1.OccurredCycleNo),
			isnull(T2.OccurredEvent, T1.OccurredEvent),
			isnull(T2.DateOccurred, T1.DateOccurred),
			isnull(T2.SendMethodId, T1.SendMethodId),
			isnull(T2.SendMethod, T1.SendMethod),
			isnull(T2.SentDate, T1.SentDate),
			isnull(T2.ReceiptDate, T1.ReceiptDate),
			isnull(T2.Reference, T1.Reference),
			isnull(T2.AlertSeq, T1.AlertSeq),
			CASE WHEN(isnull(T2.OccurredEvent, T1.OccurredEvent) is not null) THEN C2.LONGFLAG      ELSE C1.LONGFLAG      END,
			CASE WHEN(isnull(T2.OccurredEvent, T1.OccurredEvent) is not null) THEN C2.EVENTTEXT     ELSE C1.EVENTTEXT     END,
			CASE WHEN(isnull(T2.OccurredEvent, T1.OccurredEvent) is not null) THEN C2.EVENTLONGTEXT ELSE C1.EVENTLONGTEXT END
		From @tbDueDates T1
		left join CASEEVENT C1	 on (C1.CASEID =@pnCaseId
					 and C1.EVENTNO=T1.DueEventNo
					 and C1.CYCLE  =T1.DueCycleNo)
		left join @tbDueDates T2 on (T2.DisplayOrder=T1.DisplayOrder
					 and T2.RowId>T1.RowId)
		left join CASEEVENT C2	 on (C2.CASEID =@pnCaseId
					 and C2.EVENTNO=isnull(T2.OccurredEventNo, T1.OccurredEventNo)
					 and C2.CYCLE  =isnull(T2.OccurredCycleNo, T1.OccurredCycleNo))
		where not exists
		(select * from @tbDueDates T3
		 where T3.DisplayOrder=T1.DisplayOrder
		 and T3.RowId<T1.RowId)
		order by isnull(T1.DisplayOrder,9999) ASC, T1.SortDate ASC, T1.DateOccurred DESC

		Select 	@ErrorCode=@@Error,
			@pnRowCount=@@Rowcount
	End
End
Else -- @pbCalledByCentura = 0
Begin
-- Now return the result set 
	If @ErrorCode=0
	Begin
		Select	Cast(T1.DueEventNo as nvarchar(10)) + '^' 
			+ Cast(T1.DueCycleNo as nvarchar(10)) + '^' 
			+ Cast(isnull(T2.OccurredEventNo, T1.OccurredEventNo) as nvarchar(10)) + '^'
			+ Cast(isnull(T2.OccurredCycleNo, T1.OccurredCycleNo) as nvarchar(10)) + '^'
			+ Convert(nvarchar(25), isnull(T2.AlertSeq, T1.AlertSeq), 126) + '^' 
			+ Cast(T1.StaffId as nvarchar(10))
									as RowKey,
			T1.DueEventNo					as DueEventKey, 
			T1.DueCycleNo					as DueCycle, 
			dbo.fn_GetTranslation(T1.EventDue,null,T1.EventDueTid,@sLookupCulture)	
									as EventDueDescription, 
			T1.DueDate					as DueDate, 
			T1.StaffId					as StaffKey,
			T1.StaffNameCode				as StaffCode,
			T1.StaffMember					as StaffMember,
			isnull(T2.OccurredEventNo, T1.OccurredEventNo)	as OccurredEventKey,
			isnull(T2.OccurredCycleNo, T1.OccurredCycleNo)	as OccurredCycle,
			isnull( dbo.fn_GetTranslation(T2.OccurredEvent,null,T2.OccurredEventTid,@sLookupCulture), 
				dbo.fn_GetTranslation(T1.OccurredEvent,null,T1.OccurredEventTid,@sLookupCulture))
									as OccurredEventDescription,
-- SQA18642 Change Alias OccurredDate to unique name T2T1_OccurredDate 
			isnull(T2.DateOccurred, T1.DateOccurred)	as OccurredDate,
			isnull(T2.SendMethodId, T1.SendMethodId)	as SendMethodKey,		
			isnull( dbo.fn_GetTranslation(T2.SendMethod,null,T2.SendMethodTid,@sLookupCulture), 
				dbo.fn_GetTranslation(T1.SendMethod,null,T1.SendMethodTid,@sLookupCulture))
									as SendMethod,
			isnull(T2.SentDate, T1.SentDate)		as SendDate,
			isnull(T2.ReceiptDate, T1.ReceiptDate)		as ReceiptDate,
			isnull(T2.Reference, T1.Reference)		as Reference,
			isnull(T2.AlertSeq, T1.AlertSeq)		as AlertSequence,
--  Event text is not being used in Docketing Wizard.
--			CASE WHEN(isnull(T2.OccurredEvent, T1.OccurredEvent) is not null) THEN C2.LONGFLAG      ELSE C1.LONGFLAG      END
--									as IsLongEventText,
--			CASE WHEN(isnull(T2.OccurredEvent, T1.OccurredEvent) is not null) 
--				THEN dbo.fn_GetTranslation(C2.EVENTTEXT,null,C2.EVENTTEXT_TID,@sLookupCulture)	
--				ELSE dbo.fn_GetTranslation(C1.EVENTTEXT,null,C1.EVENTTEXT_TID,@sLookupCulture)
--			END						as OccurredEventText,
--			CASE WHEN(isnull(T2.OccurredEvent, T1.OccurredEvent) is not null) 
--				THEN dbo.fn_GetTranslation(null,C2.EVENTLONGTEXT,C2.EVENTTEXT_TID,@sLookupCulture)
--				ELSE dbo.fn_GetTranslation(null,C1.EVENTLONGTEXT,C1.EVENTTEXT_TID,@sLookupCulture)
--			END						as OccurredEventLongText,
			CASE WHEN(isnull(T2.AlertSeq, T1.AlertSeq) is not null) THEN 1 ELSE 0 END as IsAdHocDate,
			@pnCaseId					as CaseKey,
			0 as IsNew,
-- SQA18642 Change Alias DisplayOrder to unique name T1_DisplayOrder so that order by does not require table prefix.
			isnull(T1.DisplayOrder, 9999)	as T1_DisplayOrder,
			T1.LastModifiedDate     as LastModifiedDate
		From @tbDueDates T1
		left join CASEEVENT C1	 on (C1.CASEID =@pnCaseId
					 and C1.EVENTNO=T1.DueEventNo
					 and C1.CYCLE  =T1.DueCycleNo)
		left join @tbDueDates T2 on (T2.DisplayOrder=T1.DisplayOrder
					 and T2.RowId>T1.RowId)
		left join CASEEVENT C2	 on (C2.CASEID =@pnCaseId
					 and C2.EVENTNO=isnull(T2.OccurredEventNo, T1.OccurredEventNo)
					 and C2.CYCLE  =isnull(T2.OccurredCycleNo, T1.OccurredCycleNo))
		where @bExternalUser = 0
		and not exists
		(select * from @tbDueDates T3
		 where T3.DisplayOrder=T1.DisplayOrder
		 and T3.RowId<T1.RowId)
-- SQA18642 remove table alias from column aliases
--		order by isnull(T1.DisplayOrder,9999) ASC, T1.SortDate ASC, T1.OccurredDate DESC
		order by T1_DisplayOrder ASC, T1.SortDate ASC, T1.DateOccurred DESC

		Select 	@ErrorCode=@@Error,
			@pnRowCount=@@Rowcount
	End
End

RETURN @ErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.dw_ListCaseEventAlert to public
go
