-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCaseDates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_ListCaseDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_ListCaseDates.'
	Drop procedure [dbo].[cs_ListCaseDates]
End
Print '**** Creating Stored Procedure dbo.cs_ListCaseDates...'
Print ''
go



CREATE  PROCEDURE dbo.cs_ListCaseDates
	@pnUserIdentityId	int,			-- included for use by .NET.
	@psCulture		nvarchar(10)	= null,	-- the language in which output is to be expressed.
	@pnCaseKey		int,			-- the caseid that dates will relate to.
	@pbDueDates		bit		= 0,	-- indicate due dates are to be returned.
	@pbRemindDates		bit		= 0,	-- indicate event remind dates are to be returned.
	@pbAhHocDates		bit		= 0,	-- indicate ad hoc dates are to be returned.
	@pdtFromDate		datetime	= null,	-- the from filter date.
	@pdtToDate		datetime	= null,	-- the to filter date.
	@pnImportanceLevel	int		= null	-- the event importance level.
	
AS

-- PROCEDURE:	cs_ListCaseDates
-- VERSION:	9
-- SCOPE:	User by Inpro on the frmCaseDates tab.
-- DESCRIPTION:	Returns information regarding case future, present and past Due Dates, Event Reminder Dates 
--		and Ad Hoc Reminder Dates that are already in the system.
-- CALLED BY:	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS:
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 05 Mar 2004	vql		1	Procedure created
-- 01 Dec 2005   dl		2	fix bug - ad hoc reminders are not retrieved correctly.
-- 18 Jan 2006	MF	12210	3	Return the EventDescription from EventControl in preference to the
--					the description in the Events table.
-- 11 Apr 2006	MF	12554	4	Events are only to be considered as Due if they have not occurred and
--					they are attached to an open Action.
-- 19 Sep 2006	Dev	13291	5	Changed the search conditions to refer to IMPORTANCELEVL in EVENTCONTROL
-- 16 Apr 2007	PY	12557	6	Sort order on Case Dates tab differs if Event Due Dates is only selection.
-- 17 Apr 2007	PY	12558	7	Case Dates Tab Showing Event Due Date Twice.
-- 07 Aug 2008	MF	16801	8	Ensure an Event only appears once in the result even if it belongs to
--					more than one Action by using the Event.ControllingAction in preference.
--					Also Reminder Dates should only be displayed if they are attached to an
--					open action.
-- 29 Jun 2015	Dw	47200	9	Adjusted filtering on Importance Level from = to >= 

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)
Declare @sSQLDueDates		nvarchar(4000)
Declare @sSQLRemindDates	nvarchar(4000)
Declare @sSQLAdHocDates		nvarchar(4000)
Declare @sSQLOrderBy		nvarchar(4000)

Set @nErrorCode = 0

-- First prepare the statements depending on the parameters passed.
-- These statements will then be joined using the UNION statement and executed.

If @nErrorCode = 0
Begin	

	-- Prepare get due dates statement.
	If @pbDueDates = 1
	Begin
		Set @sSQLDueDates = '
		Select 	DISTINCT CE.EVENTDUEDATE, 1 as TYPE, EC.EVENTDESCRIPTION as EVENTDESCRIPTION
		from	CASEEVENT CE
		join	OPENACTION OA	on (OA.CASEID=CE.CASEID
					and OA.POLICEEVENTS=1)
		join	ACTIONS A	on (A.ACTION=OA.ACTION)
		join	EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
					and EC.EVENTNO=CE.EVENTNO)
		join	EVENTS E	on (E.EVENTNO=CE.EVENTNO)
		where	CE.CASEID = @pnCaseKey
		and	CE.OCCURREDFLAG=0
		and	OA.ACTION=isnull(E.CONTROLLINGACTION,OA.ACTION)
		and	CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN OA.CYCLE ELSE CE.CYCLE END'

		If ( @pdtFromDate is not null )
			Set @sSQLDueDates = @sSQLDueDates + '
			and		CE.EVENTDUEDATE >= @pdtFromDate'
		If ( @pdtToDate is not null )
			Set @sSQLDueDates = @sSQLDueDates + '
			and		CE.EVENTDUEDATE <= @pdtToDate'
		If ( @pnImportanceLevel is not null )
			Set @sSQLDueDates = @sSQLDueDates + '
			and		EC.IMPORTANCELEVEL >= @pnImportanceLevel'
	End

	-- Prepare get event reminder dates statement.
	If @pbRemindDates = 1
	Begin
		Set @sSQLRemindDates = '
		Select 	DISTINCT CE.DATEREMIND, 2 as TYPE, EC.EVENTDESCRIPTION as EVENTDESCRIPTION
		from	CASEEVENT CE
		join	OPENACTION OA	on (OA.CASEID=CE.CASEID
					and OA.POLICEEVENTS=1)
		join	ACTIONS A	on (A.ACTION=OA.ACTION)
		join	EVENTCONTROL EC on (EC.CRITERIANO=OA.CRITERIANO
					and EC.EVENTNO=CE.EVENTNO)
		join	EVENTS E	on (E.EVENTNO=CE.EVENTNO)
		where	CE.CASEID = @pnCaseKey
		and	CE.DATEREMIND is not null
		and	CE.OCCURREDFLAG=0
		and	OA.ACTION=isnull(E.CONTROLLINGACTION,OA.ACTION)
		and	CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN OA.CYCLE ELSE CE.CYCLE END'

		If ( @pdtFromDate is not null )
			Set @sSQLRemindDates = @sSQLRemindDates + '
			and		CE.DATEREMIND >= @pdtFromDate'
		If ( @pdtToDate is not null )
			Set @sSQLRemindDates = @sSQLRemindDates + '
			and		CE.DATEREMIND <= @pdtToDate'
		If ( @pnImportanceLevel is not null )
			Set @sSQLRemindDates = @sSQLRemindDates + '
			and		EC.IMPORTANCELEVEL >= @pnImportanceLevel'
	End

	-- Prepare get ad hoc reminder dates statement.
	If @pbAhHocDates = 1
	Begin
		Set @sSQLAdHocDates = '
		Select		DISTINCT DUEDATE, 3 as TYPE, ALERTMESSAGE
		from		ALERT
		where		CASEID = @pnCaseKey
		and		DUEDATE is not null'

		If ( @pdtFromDate is not null )
			Set @sSQLAdHocDates = @sSQLAdHocDates + '
			and		DUEDATE >= @pdtFromDate'
		If ( @pdtToDate is not null )
			Set @sSQLAdHocDates = @sSQLAdHocDates + '
			and		DUEDATE <= @pdtToDate'
	End

	-- Create the order by clause.
	Set @sSQLOrderBy = '
	Order By 1'
End

-- Create the join statement.
If @nErrorCode = 0
Begin
	Set @sSQLString = null
	If ( @pbDueDates = 1 )
		Set @sSQLString = @sSQLDueDates
	If ( @pbRemindDates = 1 )
		Begin
			If ( @sSQLString is null )
				Set @sSQLString = @sSQLRemindDates
			Else
				Set @sSQLString = @sSQLString + ' UNION ' + @sSQLRemindDates
		End
	If ( @pbAhHocDates = 1 )
		Begin
			If ( @sSQLString is null )
				Set @sSQLString = @sSQLAdHocDates
			Else
				Set @sSQLString = @sSQLString + ' UNION ' + @sSQLAdHocDates
		End
	-- append order by
	Set @sSQLString = @sSQLString + ' ' + @sSQLOrderBy

	-- Execute statement.
	Exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @pdtFromDate		datetime,
					  @pdtToDate		datetime,
					  @pnImportanceLevel	int',
					  @pnCaseKey		=@pnCaseKey,
					  @pdtFromDate		=@pdtFromDate,
					  @pdtToDate		=@pdtToDate,
					  @pnImportanceLevel	=@pnImportanceLevel
End

Return @nErrorCode
GO

Grant execute on dbo.cs_ListCaseDates to public
GO
