-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_StaffPerformance
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_StaffPerformance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_StaffPerformance.'
	Drop procedure [dbo].[ts_StaffPerformance]
	Print '**** Creating Stored Procedure dbo.ts_StaffPerformance...'
	Print ''
End
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.ts_StaffPerformance
(
	@pnUserIdentityId		int	    = null,
	@psCulture			nvarchar(10) = null,
	@pnNameNo			int,	
	@psResponsibility		char(1)     = 'L',  	-- S(staff), P(partner), L(personal)
	@psTimeRange			char(1)     = 'P',  	-- P(period to date), W(week to date), Y(year to date)
	@pbPostDateFlag			bit         = 0,		-- Flag to indicate that Post Date to be used otherwise Trans Date.
	@pnRecordedSC			decimal(11,2) OUTPUT,	-- WIP Recorded (Time)
	@pnRecordedPD			decimal(11,2) OUTPUT,	-- WIP Recorded (Disbursement)
	@pnRecordedOR			decimal(11,2) OUTPUT,	-- WIP Recorded (Recoverables)
	@pnAdjustedSC			decimal(11,2) OUTPUT,	-- WIP Written Up/Down (Time)
	@pnAdjustedPD			decimal(11,2) OUTPUT,	-- WIP Written Up/Down (Disbursement)
	@pnAdjustedOR			decimal(11,2) OUTPUT,	-- WIP Written Up/Down (Recoverables)
	@pnBilledSC			decimal(11,2) OUTPUT,	-- Billed WIP (Time)
	@pnBilledPD			decimal(11,2) OUTPUT,	-- Billed WIP (Disbursement)
	@pnBilledOR			decimal(11,2) OUTPUT,	-- Billed WIP (Recoverables)
	@pnTimesheetSC			decimal(11,2) OUTPUT,	-- On Timesheet (Time)
	@pnTimesheetPD			decimal(11,2) OUTPUT,	-- On Timesheet (Disbursement)
	@pnTimesheetOR			decimal(11,2) OUTPUT,	-- On Timesheet (Recoverables)
	@pnProductivity			decimal(11,2) OUTPUT,	-- Productivity %
	@pnAgedWIP0			decimal(11,2) OUTPUT,	-- Aged WIP (Current Period)
	@pnAgedWIP1			decimal(11,2) OUTPUT,	-- Aged WIP (Period 1)
	@pnAgedWIP2			decimal(11,2) OUTPUT,	-- Aged WIP (Period 2)
	@pnAgedWIP3			decimal(11,2) OUTPUT,	-- Aged WIP (Period 3+)
	@pnAgedDebt0			decimal(11,2) OUTPUT,	-- Aged Debt (Current Period)
	@pnAgedDebt1			decimal(11,2) OUTPUT,	-- Aged Debt (Period 1)
	@pnAgedDebt2			decimal(11,2) OUTPUT,	-- Aged Debt (Period 2)
	@pnAgedDebt3			decimal(11,2) OUTPUT,	-- Aged Debt (Period 3+)
	@pnPrepayments			decimal(11,2) OUTPUT	-- Prepayments Total. 


)

-- PROCEDURE :	ts_StaffPerformance
-- VERSION :	8
-- DESCRIPTION:	Returns a summary of staff performance related information
-- NOTES:	
--
-- Date		Who	Change	Version	Description
-- ====		===	======  ======= =============
-- 21/02/2003	MF			Procedure created
-- 04/03/2003	MF	8072		If the firm is not using AR then suppress the display of aged AR	
-- 13/03/2003	MF	8072		Code correction found in testing.
-- 14/03/2003	MF	8072		Change the Billing figures so they are returned as a positive number.
-- 20/06/2005	TM	RFC1100		Exclude all timer rows from their processing of unposted time; i.e. AND ISTIMER=0.
-- 17/07/2008	KR	SQA16150 3	Made the ENDDATE in the Period to date to include time.
-- 18 Nov 2008	MF	SQA17136 4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 10 Jun 2009	Dw	SQA17760 5	Fixed bug where POSTDATE was being used instead of TRANSDATE (and vice versa) in 'Period to Date' queries.
-- 05 Apr 2011	Dw	SQA9377  6	Adjusted 'Week To Date' logic so that end date is current date.
-- 05 Jul 2013	vql	R13629	 7	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	8   Date conversion errors when creating cases and opening names in Chinese DB

AS

-- Settings

Set nocount on
Set concat_null_yields_null off

Declare @ErrorCode 		int
Declare @sSQLSelect		nvarchar(4000)
Declare @sSQLString		nvarchar(4000)
Declare @sDateRange		nvarchar(100)
Declare @nChargeableMinutes	int
Declare	@nAge0			smallint
Declare	@nAge1			smallint
Declare	@nAge2			smallint
Declare @dtStartDate		datetime
Declare @dtEndDate		datetime
Declare @nDailyHours		decimal(5,2)
Declare @nWorkHours		decimal(11,2)

-- Variables required for the calculation of the number of working days

Declare @nTotalDays	int
Declare @nWorkDays	int
Declare @nWeeks		smallint
Declare	@nExcessDays	tinyint
Declare @nFirstDay	tinyint
Declare	@nLastDay	tinyint

Set @ErrorCode=0

-- Determine the ageing periods to be used for the WIP and Debtor ageing
-- Selects the period where today is between the start and end dates (Period 0)
-- Sets the AgeBaseDate to the end date of Period 0
-- Sets the Bracket 0 days (current) to AgeBaseDate - start date of Period 0 + 1
-- Selects the previous period by descending PeriodId (Period 1)
-- Sets the Bracket 0-1 days to AgeBaseDate - start date of Period 1 + 1 
-- Selects the previous period by descending PeriodId (Period 2)
-- Sets the Bracket 0-2 days to AgeBaseDate - start date of Period 2 + 1 

If @ErrorCode=0
Begin
	Set @sSQLString="
	select 	@nAge0=datediff(day, P0.STARTDATE, P0.ENDDATE)+1,
		@nAge1=datediff(day, P1.STARTDATE, P0.ENDDATE)+1,
		@nAge2=datediff(day, P2.STARTDATE, P0.ENDDATE)+1
	from PERIOD P0
	left join PERIOD P1	on (P1.PERIODID=(select max(P1X.PERIODID)
						 from PERIOD P1X
						 where P1X.PERIODID<P0.PERIODID))
	left join PERIOD P2	on (P2.PERIODID=(select max(P2X.PERIODID)
						 from PERIOD P2X
						 where P2X.PERIODID<P1.PERIODID))
	where getdate() between P0.STARTDATE and P0.ENDDATE"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nAge0	smallint	OUTPUT,
					  @nAge1	smallint	OUTPUT,
					  @nAge2	smallint	OUTPUT',
					  @nAge0=@nAge0			OUTPUT,
					  @nAge1=@nAge1			OUTPUT,
					  @nAge2=@nAge2			OUTPUT

	-- if there aren't enough ageing periods set (e.g. the client has just started using the system 
	-- and only has the current period defined, the approximate the missing ageing brackets by assuming 
	-- that they will have the same number of days as in the last defined bracket; i.e.

	Select @nAge0=isnull(@nAge0,30)
	Select @nAge1=isnull(@nAge1, @nAge0*2)
	Select @nAge2=isnull(@nAge2, @nAge1+@nAge1-@nAge0)
End

-- Determine the date range to be used in the calculation of statistics
-- A parameter passed to the procedure will also determine whether TRANSDATE
-- or POSTDATE is to be used.

If @psTimeRange='P'
Begin
	-- Period to date
	-- Find the Start and End dates for the current period
	select @sDateRange=CASE WHEN(@pbPostDateFlag=1) 
				THEN "and   W.POSTDATE between '"
				ELSE "and   W.TRANSDATE  between '"
			   END
			+convert(nvarchar,P.STARTDATE,112)+"' and '"+convert(varchar,dateadd(ms,-2,dateadd(day,1,P.ENDDATE)),126)+"'",
		@dtStartDate=P.STARTDATE,
		@dtEndDate  =P.ENDDATE
	from PERIOD P
	where P.STARTDATE=(select max(STARTDATE) from PERIOD where STARTDATE<getdate())
End
Else If @psTimeRange='Y'
Begin
	-- Year to date
	-- Find the Start date of the first period of the financial year
	select @sDateRange=CASE WHEN(@pbPostDateFlag=1) 
				THEN "and   W.POSTDATE >= '"
				ELSE "and   W.TRANSDATE>= '"
			   END
			+convert(nvarchar,P.STARTDATE,112)+"'",
		@dtStartDate=P.STARTDATE,
		@dtEndDate  =getdate()
	from PERIOD P
	where P.PERIODID =(	select (P1.PERIODID/100)*100+01
				from PERIOD P1
				where P1.STARTDATE=(	select max(STARTDATE) 
							from PERIOD where STARTDATE<getdate()))
End
Else Begin
	-- Week to date
	-- Find the Start date of the current week
	select @sDateRange=CASE WHEN(@pbPostDateFlag=1) 
				THEN "and   W.POSTDATE  between '"
				ELSE "and   W.TRANSDATE between '"
			   END
			+convert(nvarchar,DATEADD(day, -1*(DATEPART(weekday,getdate())-1), getdate()),112)+
               "' and '"+convert(nvarchar,DATEADD(day, (7-DATEPART(weekday,getdate())),    getdate()),112)+"'" ,
		@dtStartDate=convert(nvarchar,DATEADD(day, -1*(DATEPART(weekday,getdate())-1), getdate()),112),
		--@dtEndDate  =convert(varchar,DATEADD(day, (7-DATEPART(weekday,getdate())),    getdate()),106)
		-- SQA9377
		@dtEndDate  =getdate()
End

-- Start extracting the performance statistics depending on the type of relationship
-- the staff member entered has

If  @ErrorCode=0
and @psResponsibility in ('S','P')
Begin
	Set @sSQLString="
	select	
	@pnSC  =SUM(	CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END),
	@pnPD  =SUM(	CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END),
	@pnOR  =SUM(	CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END)
	from WORKHISTORY W
	join WIPTEMPLATE WIP	on (WIP.WIPCODE=W.WIPCODE)
	join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)
	join CASES C		on (C.CASEID=W.CASEID		-- Exclude internal Cases
				and C.CASETYPE<>'Y')
	join CASENAME CN	on (CN.CASEID=W.CASEID
				and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
	
	where CN.NAMENO=@pnNameNo
	and   CN.NAMETYPE=CASE WHEN(@psResponsibility='S') THEN 'EMP' ELSE 'SIG' END
	AND   W.STATUS <> 0
	and   W.MOVEMENTCLASS in (1,4,5)
	"+@sDateRange

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnSC			decimal(11,2)	OUTPUT,
					  @pnPD			decimal(11,2)	OUTPUT,
					  @pnOR			decimal(11,2)	OUTPUT,
					  @pnNameNo		int,
					  @psResponsibility	char(1)',
					  @pnSC=@pnRecordedSC	OUTPUT,
					  @pnPD=@pnRecordedPD	OUTPUT,
					  @pnOR=@pnRecordedOR	OUTPUT,
					  @pnNameNo=@pnNameNo,
					  @psResponsibility=@psResponsibility

	-- Now get the Billed values
	-- This is the exact same SQL but with different MovementClass value

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select	
		@pnSC  =SUM(	CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END)*-1,
		@pnPD  =SUM(	CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END)*-1,
		@pnOR  =SUM(	CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END)*-1
		from WORKHISTORY W
		join WIPTEMPLATE WIP	on (WIP.WIPCODE=W.WIPCODE)
		join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)
		join CASES C		on (C.CASEID=W.CASEID		-- Exclude internal Cases
					and C.CASETYPE<>'Y')
		join CASENAME CN	on (CN.CASEID=W.CASEID
					and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
		where CN.NAMENO=@pnNameNo
		and   CN.NAMETYPE=CASE WHEN(@psResponsibility='S') THEN 'EMP' ELSE 'SIG' END
		AND   W.STATUS <> 0
		and   W.MOVEMENTCLASS=2
		"+@sDateRange

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnSC			decimal(11,2)	OUTPUT,
						  @pnPD			decimal(11,2)	OUTPUT,
						  @pnOR			decimal(11,2)	OUTPUT,
						  @pnNameNo		int,
						  @psResponsibility	char(1)',
						  @pnSC=@pnBilledSC	OUTPUT,
						  @pnPD=@pnBilledPD	OUTPUT,
						  @pnOR=@pnBilledOR	OUTPUT,
						  @pnNameNo=@pnNameNo,
						  @psResponsibility=@psResponsibility
	End

	-- Now get the Write On and OFF figures
	-- This is the exact same SQL but with different MovementClass value

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select	
		@pnSC  =SUM(	CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END),
		@pnPD  =SUM(	CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END),
		@pnOR  =SUM(	CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END)
		from WORKHISTORY W
		join WIPTEMPLATE WIP	on (WIP.WIPCODE=W.WIPCODE)
		join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)
		join CASES C		on (C.CASEID=W.CASEID		-- Exclude internal Cases
					and C.CASETYPE<>'Y')
		join CASENAME CN	on (CN.CASEID=W.CASEID
					and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
		where CN.NAMENO=@pnNameNo
		and   CN.NAMETYPE=CASE WHEN(@psResponsibility='S') THEN 'EMP' ELSE 'SIG' END
		AND   W.STATUS <> 0
		and   W.MOVEMENTCLASS in (3,9)
		"+@sDateRange

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnSC			decimal(11,2)	OUTPUT,
						  @pnPD			decimal(11,2)	OUTPUT,
						  @pnOR			decimal(11,2)	OUTPUT,
						  @pnNameNo		int,
						  @psResponsibility	char(1)',
						  @pnSC=@pnAdjustedSC	OUTPUT,
						  @pnPD=@pnAdjustedPD	OUTPUT,
						  @pnOR=@pnAdjustedOR	OUTPUT,
						  @pnNameNo=@pnNameNo,
						  @psResponsibility=@psResponsibility
	End

	-- Now get the value of time on the Timesheet but not yet posted

	If @ErrorCode=0
	Begin

		Set @sSQLString="
		select	
		@pnSC=SUM(CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(D.TIMEVALUE,0) ELSE 0 END),
		@pnPD=SUM(CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(D.TIMEVALUE,0) ELSE 0 END),
		@pnOR=SUM(CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(D.TIMEVALUE,0) ELSE 0 END)
		from DIARY D
		join WIPTEMPLATE WIP	on (WIP.WIPCODE=D.ACTIVITY)
		join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)
		join CASENAME CN	on (CN.CASEID=D.CASEID
					and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
		
		where CN.NAMENO=@pnNameNo
		and   CN.NAMETYPE=CASE WHEN(@psResponsibility='S') THEN 'EMP' ELSE 'SIG' END
		and   D.TRANSNO is null
		and   D.ISTIMER = 0
		"+replace(replace(@sDateRange,'W.TRANSDATE','D.STARTTIME'),'W.POSTDATE','D.STARTTIME')

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnSC			decimal(11,2)	OUTPUT,
						  @pnPD			decimal(11,2)	OUTPUT,
						  @pnOR			decimal(11,2)	OUTPUT,
						  @pnNameNo		int,
						  @psResponsibility	char(1)',
						  @pnSC=@pnTimesheetSC	OUTPUT,
						  @pnPD=@pnTimesheetPD	OUTPUT,
						  @pnOR=@pnTimesheetOR	OUTPUT,
						  @pnNameNo=@pnNameNo,
						  @psResponsibility=@psResponsibility

	End

	-- Get the aged WIP values
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select 
		@pnAgedWIP0=sum(CASE WHEN(datediff(dd,CASE WHEN(@pbPostDateFlag=1) THEN W.POSTDATE ELSE W.TRANSDATE END,getdate()) <  @nAge0)                   THEN W.BALANCE ELSE 0 END),
		@pnAgedWIP1=sum(CASE WHEN(datediff(dd,CASE WHEN(@pbPostDateFlag=1) THEN W.POSTDATE ELSE W.TRANSDATE END,getdate()) between @nAge0 and @nAge1-1) THEN W.BALANCE ELSE 0 END),
		@pnAgedWIP2=sum(CASE WHEN(datediff(dd,CASE WHEN(@pbPostDateFlag=1) THEN W.POSTDATE ELSE W.TRANSDATE END,getdate()) between @nAge1 and @nAge2-1) THEN W.BALANCE ELSE 0 END),
		@pnAgedWIP3=sum(CASE WHEN(datediff(dd,CASE WHEN(@pbPostDateFlag=1) THEN W.POSTDATE ELSE W.TRANSDATE END,getdate())>=  @nAge2)                   THEN W.BALANCE ELSE 0 END)
		from WORKINPROGRESS W
		join CASES C		on (C.CASEID=W.CASEID		-- Exclude internal Cases
					and C.CASETYPE<>'Y')
		join CASENAME CN	on (CN.CASEID=W.CASEID
					and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
		
		where CN.NAMENO=@pnNameNo
		and   CN.NAMETYPE=CASE WHEN(@psResponsibility='S') THEN 'EMP' ELSE 'SIG' END  
		and   W.BALANCE<>0"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnAgedWIP0		decimal(11,2)	OUTPUT,
						  @pnAgedWIP1		decimal(11,2)	OUTPUT,
						  @pnAgedWIP2		decimal(11,2)	OUTPUT,
						  @pnAgedWIP3		decimal(11,2)	OUTPUT,
						  @pbPostDateFlag	bit,
						  @pnNameNo		int,
						  @psResponsibility	char(1),
						  @nAge0		smallint,
						  @nAge1		smallint,
						  @nAge2		smallint',
						  @pnAgedWIP0=@pnAgedWIP0	OUTPUT,
						  @pnAgedWIP1=@pnAgedWIP1	OUTPUT,
						  @pnAgedWIP2=@pnAgedWIP2	OUTPUT,
						  @pnAgedWIP3=@pnAgedWIP3	OUTPUT,
						  @pbPostDateFlag=@pbPostDateFlag,
						  @pnNameNo=@pnNameNo,
						  @psResponsibility=@psResponsibility,
						  @nAge0=@nAge0,
						  @nAge1=@nAge1,
						  @nAge2=@nAge2
	End

End
Else If  @ErrorCode=0
     and @psResponsibility in ('L')
Begin
	Set @sSQLString="
	select	
	@pnSC=SUM(CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END),
	@pnPD=SUM(CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END),
	@pnOR=SUM(CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END),
	@pnTime=SUM(	CASE WHEN(WT.CATEGORYCODE='SC' AND W.LOCALTRANSVALUE<>0) 
				THEN isnull(DATEPART(HOUR,W.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0)
				ELSE 0 
			END)
	from WORKHISTORY W
	join WIPTEMPLATE WIP	on (WIP.WIPCODE=W.WIPCODE)
	join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)
	left join CASES C	on (C.CASEID=W.CASEID)
	where W.EMPLOYEENO=@pnNameNo
	AND  (W.CASEID is null OR C.CASETYPE<>'Y') -- exclude internal Cases
	AND   W.STATUS <> 0
	and   W.MOVEMENTCLASS in (1,4,5)
	"+@sDateRange

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnSC			decimal(11,2)	OUTPUT,
					  @pnPD			decimal(11,2)	OUTPUT,
					  @pnOR			decimal(11,2)	OUTPUT,
					  @pnTime		int		OUTPUT,
					  @pnNameNo		int',
					  @pnSC=@pnRecordedSC	OUTPUT,
					  @pnPD=@pnRecordedPD	OUTPUT,
					  @pnOR=@pnRecordedOR	OUTPUT,
					  @pnTime=@nChargeableMinutes	OUTPUT,
					  @pnNameNo=@pnNameNo

	-- Now get the Billed values
	-- This is the exact same SQL but with different MovementClass value

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select	
		@pnSC=SUM(CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END)*-1,
		@pnPD=SUM(CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END)*-1,
		@pnOR=SUM(CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END)*-1
		from WORKHISTORY W
		join WIPTEMPLATE WIP	on (WIP.WIPCODE=W.WIPCODE)
		join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)
		left join CASES C	on (C.CASEID=W.CASEID)
		where W.EMPLOYEENO=@pnNameNo
		AND  (W.CASEID is null OR C.CASETYPE<>'Y') -- exclude internal Cases
		AND   W.STATUS <> 0
		and   W.MOVEMENTCLASS=2
		"+@sDateRange

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnSC			decimal(11,2)	OUTPUT,
						  @pnPD			decimal(11,2)	OUTPUT,
						  @pnOR			decimal(11,2)	OUTPUT,
						  @pnNameNo		int',
						  @pnSC=@pnBilledSC	OUTPUT,
						  @pnPD=@pnBilledPD	OUTPUT,
						  @pnOR=@pnBilledOR	OUTPUT,
						  @pnNameNo=@pnNameNo
	End

	-- Now get the Write On and Off values
	-- This is the exact same SQL but with different MovementClass value

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select	
		@pnSC=SUM(CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END),
		@pnPD=SUM(CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END),
		@pnOR=SUM(CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(W.LOCALTRANSVALUE,0) ELSE 0 END)
		from WORKHISTORY W
		join WIPTEMPLATE WIP	on (WIP.WIPCODE=W.WIPCODE)
		join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)
		left join CASES C	on (C.CASEID=W.CASEID)
		where W.EMPLOYEENO=@pnNameNo
		AND  (W.CASEID is null OR C.CASETYPE<>'Y') -- exclude internal Cases
		AND   W.STATUS <> 0
		and   W.MOVEMENTCLASS in (3,9)
		"+@sDateRange

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnSC			decimal(11,2)	OUTPUT,
						  @pnPD			decimal(11,2)	OUTPUT,
						  @pnOR			decimal(11,2)	OUTPUT,
						  @pnNameNo		int',
						  @pnSC=@pnAdjustedSC	OUTPUT,
						  @pnPD=@pnAdjustedPD	OUTPUT,
						  @pnOR=@pnAdjustedOR	OUTPUT,
						  @pnNameNo=@pnNameNo
	End

	-- Now get the value of time on the Timesheet but not yet posted

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select	
		@pnSC=SUM(CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(D.TIMEVALUE,0) ELSE 0 END),
		@pnPD=SUM(CASE WHEN(WT.CATEGORYCODE='PD') THEN isnull(D.TIMEVALUE,0) ELSE 0 END),
		@pnOR=SUM(CASE WHEN(WT.CATEGORYCODE='OR') THEN isnull(D.TIMEVALUE,0) ELSE 0 END)
		from DIARY D
		join WIPTEMPLATE WIP	on (WIP.WIPCODE=D.ACTIVITY)
		join WIPTYPE WT		on (WT.WIPTYPEID=WIP.WIPTYPEID)
		left join CASES C	on (C.CASEID=D.CASEID)
		where D.EMPLOYEENO=@pnNameNo
		AND  (D.CASEID is null OR C.CASETYPE<>'Y') -- exclude internal Cases
		and   D.TRANSNO is null
		and   D.ISTIMER = 0
		"+replace(replace(@sDateRange,'W.TRANSDATE','D.STARTTIME'),'W.POSTDATE','D.STARTTIME')

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnSC			decimal(11,2)	OUTPUT,
						  @pnPD			decimal(11,2)	OUTPUT,
						  @pnOR			decimal(11,2)	OUTPUT,
						  @pnNameNo		int',
						  @pnSC=@pnTimesheetSC	OUTPUT,
						  @pnPD=@pnTimesheetPD	OUTPUT,
						  @pnOR=@pnTimesheetOR	OUTPUT,
						  @pnNameNo=@pnNameNo
	End

	-- Get the aged WIP values
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select 
		@pnAgedWIP0=sum(CASE WHEN(datediff(dd,CASE WHEN(@pbPostDateFlag=1) THEN W.POSTDATE ELSE W.TRANSDATE END,getdate()) <  @nAge0)                   THEN W.BALANCE ELSE 0 END),
		@pnAgedWIP1=sum(CASE WHEN(datediff(dd,CASE WHEN(@pbPostDateFlag=1) THEN W.POSTDATE ELSE W.TRANSDATE END,getdate()) between @nAge0 and @nAge1-1) THEN W.BALANCE ELSE 0 END),
		@pnAgedWIP2=sum(CASE WHEN(datediff(dd,CASE WHEN(@pbPostDateFlag=1) THEN W.POSTDATE ELSE W.TRANSDATE END,getdate()) between @nAge1 and @nAge2-1) THEN W.BALANCE ELSE 0 END),
		@pnAgedWIP3=sum(CASE WHEN(datediff(dd,CASE WHEN(@pbPostDateFlag=1) THEN W.POSTDATE ELSE W.TRANSDATE END,getdate())>=  @nAge2)                   THEN W.BALANCE ELSE 0 END)
		from WORKINPROGRESS W
		left join CASES C on (C.CASEID=W.CASEID)
		where W.EMPLOYEENO=@pnNameNo
		AND  (W.CASEID is null OR C.CASETYPE<>'Y') -- exclude internal Cases  
		and   W.STATUS<>0
		and   getdate()>=CASE WHEN(@pbPostDateFlag=1) THEN W.POSTDATE ELSE W.TRANSDATE END"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnAgedWIP0		decimal(11,2)	OUTPUT,
						  @pnAgedWIP1		decimal(11,2)	OUTPUT,
						  @pnAgedWIP2		decimal(11,2)	OUTPUT,
						  @pnAgedWIP3		decimal(11,2)	OUTPUT,
						  @pbPostDateFlag	bit,
						  @pnNameNo		int,
						  @nAge0		smallint,
						  @nAge1		smallint,
						  @nAge2		smallint',
						  @pnAgedWIP0=@pnAgedWIP0	OUTPUT,
						  @pnAgedWIP1=@pnAgedWIP1	OUTPUT,
						  @pnAgedWIP2=@pnAgedWIP2	OUTPUT,
						  @pnAgedWIP3=@pnAgedWIP3	OUTPUT,
						  @pbPostDateFlag=@pbPostDateFlag,
						  @pnNameNo=@pnNameNo,
						  @nAge0=@nAge0,
						  @nAge1=@nAge1,
						  @nAge2=@nAge2
	End
End

-- Now get the Aged Debt for the Debtors that the name has a "responsibility" relationship
-- Only get the Aged Debt if the existence of an entry in the CONTROLTOTAL indicates that AR is in use

If @ErrorCode=0
and exists (select * from CONTROLTOTAL where TYPE = 520)
Begin
	Set @sSQLString="
	select 
	@pnAgedDebt0  =sum(CASE WHEN(O.ITEMTYPE<> 523 AND datediff(dd,O.ITEMDATE,getdate()) <  @nAge0)                   THEN O.LOCALBALANCE ELSE 0 END),
	@pnAgedDebt1  =sum(CASE WHEN(O.ITEMTYPE<> 523 AND datediff(dd,O.ITEMDATE,getdate()) between @nAge0 and @nAge1-1) THEN O.LOCALBALANCE ELSE 0 END),
	@pnAgedDebt2  =sum(CASE WHEN(O.ITEMTYPE<> 523 AND datediff(dd,O.ITEMDATE,getdate()) between @nAge1 and @nAge2-1) THEN O.LOCALBALANCE ELSE 0 END),
	@pnAgedDebt3  =sum(CASE WHEN(O.ITEMTYPE<> 523 AND datediff(dd,O.ITEMDATE,getdate()) >= @nAge2)                   THEN O.LOCALBALANCE ELSE 0 END),
	@pnPrepayments=sum(CASE WHEN(O.ITEMTYPE = 523) THEN O.LOCALBALANCE ELSE 0 END)
	from ASSOCIATEDNAME AN
	join OPENITEM O	on (O.ACCTDEBTORNO=AN.NAMENO)
	where AN.RELATEDNAME = @pnNameNo
	and AN.RELATIONSHIP = 'RES'
	and O.STATUS<>0
	and O.ITEMDATE<=getdate()
	and O.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112)"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnAgedDebt0		decimal(11,2)	OUTPUT,
					  @pnAgedDebt1		decimal(11,2)	OUTPUT,
					  @pnAgedDebt2		decimal(11,2)	OUTPUT,
					  @pnAgedDebt3		decimal(11,2)	OUTPUT,
					  @pnPrepayments	decimal(11,2)	OUTPUT,
					  @pnNameNo		int,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint',
					  @pnAgedDebt0   =@pnAgedDebt0		OUTPUT,
					  @pnAgedDebt1   =@pnAgedDebt1		OUTPUT,
					  @pnAgedDebt2   =@pnAgedDebt2		OUTPUT,
					  @pnAgedDebt3   =@pnAgedDebt3		OUTPUT,
					  @pnPrepayments =@pnPrepayments	OUTPUT,
					  @pnNameNo      =@pnNameNo,
					  @nAge0         =@nAge0,
					  @nAge1         =@nAge1,
					  @nAge2         =@nAge2
End
-- If AR is not in fully in use but the Prepayment component is then get the Prepayment total
Else If @ErrorCode=0
     and exists(select * from SITECONTROL where CONTROLID='AR for Prepayments' and COLBOOLEAN=1)
Begin
	Set @sSQLString="
	select 
	@pnPrepayments=sum(O.LOCALBALANCE)
	from ASSOCIATEDNAME AN
	join OPENITEM O	on (O.ACCTDEBTORNO=AN.NAMENO)
	where AN.RELATEDNAME = @pnNameNo
	and AN.RELATIONSHIP = 'RES'
	and O.ITEMTYPE = 523
	and O.STATUS<>0
	and O.ITEMDATE<=getdate()
	and O.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112)"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnPrepayments	decimal(11,2)	OUTPUT,
					  @pnNameNo		int',
					  @pnPrepayments =@pnPrepayments	OUTPUT,
					  @pnNameNo      =@pnNameNo
End


-- Calculate the number of working days for the calculated Date Range.  To be used in the 
-- calculation of Productivity percentage.
-- NOTE : This should be changed to a FUNCTION when we move to SQLServer 2000

If @ErrorCode=0
Begin
	select	@nTotalDays=datediff(day,@dtStartDate, @dtEndDate)+1,
		@nFirstDay=	CASE datename(weekday, @dtStartDate)
					WHEN('Monday')    THEN 6
					WHEN('Tuesday')   THEN 5
					WHEN('Wednesday') THEN 4
					WHEN('Thursday')  THEN 3
					WHEN('Friday')    THEN 2
					WHEN('Saturday')  THEN 1
					WHEN('Sunday')    THEN 0
				END,
		@nLastDay=	CASE datename(weekday, @dtEndDate)
					WHEN('Monday')    THEN 6
					WHEN('Tuesday')   THEN 5
					WHEN('Wednesday') THEN 4
					WHEN('Thursday')  THEN 3
					WHEN('Friday')    THEN 2
					WHEN('Saturday')  THEN 1
					WHEN('Sunday')    THEN 0
				END
	
	Select @nWeeks=@nTotalDays/7		-- Calculates the total number of complete weeks
	Select @nExcessDays=@nTotalDays%7	-- Calculates the days in excess of a complete week
	
	-- Now we know the first day in excess of a full week is the same week day as the
	-- Start Date then we can determine how many weekday make up the excess component
	
	If @nExcessDays>0
	Begin
		Select @nExcessDays=	
				CASE WHEN(@nFirstDay=0)				-- If started on a Sunday then subtract 1 non working day because we know it didn't finish on a Saturday
					THEN @nExcessDays-1
				     WHEN(@nFirstDay=1 AND @nExcessDays>1)	-- If started Saturday and ends after Sunday then subtract 2 non working days
					THEN @nExcessDays-2
				     WHEN(@nFirstDay=1 and @nExcessDays=1)	-- If started Saturday and ends on Saturday then there are no excess days
					THEN 0
				     WHEN(@nLastDay=1)				-- If finished on a Saturday then subtract 1 non working day because we know it did not start on a Sunday
					THEN @nExcessDays-1
				     WHEN(@nLastDay=0 and @nExcessDays>1)	-- If finised on a Sunday and there are more than 1 excess days then subtract 2 non working days
					THEN @nExcessDays-2
				     WHEN(@nFirstDay<@nLastDay)			-- If started on a weekday later in the week than the weekday that it finished on then subtract 2 non working days.
					THEN @nExcessDays-2
					ELSE @nExcessDays
				END
	End
			
	Select @nWorkDays=@nWeeks*5+@nExcessDays

	-- Now get the number of available hours in a standard day inorder to calculate
	-- the available hours for the date range.

	Select @nDailyHours=S.COLDECIMAL
	from SITECONTROL S
	where S.CONTROLID='Standard Daily Hours'

	-- Now Calculate the total number of hours for the date range

	Select @nWorkHours=@nWorkDays*isnull(@nDailyHours,8.0)

	-- Now calculate the Productivity percentage by dividing the number of Minutes of chargeable
	-- time by the total available number of minutes

	If @nWorkHours>0
	Begin
		Select @pnProductivity=(@nChargeableMinutes*100)/(@nWorkHours*60)
	End

End

If @ErrorCode=0
Begin
	Select 	@pnRecordedSC		as RecordedSC,		-- WIP Recorded (Time)
		@pnRecordedPD		as RecordedPD,		-- WIP Recorded (Disbursement)
		@pnRecordedOR		as RecordedOR,		-- WIP Recorded (Recoverables)
		@pnAdjustedSC		as AdjustedSC,		-- WIP Written Up/Down (Time)
		@pnAdjustedPD		as AdjustedPD,		-- WIP Written Up/Down (Disbursement)
		@pnAdjustedOR		as AdjustedOR,		-- WIP Written Up/Down (Recoverables)
		@pnBilledSC		as BilledSC,		-- Billed WIP (Time)
		@pnBilledPD		as BilledPD,		-- Billed WIP (Disbursement)
		@pnBilledOR		as BilledOR,		-- Billed WIP (Recoverables)
		@pnTimesheetSC		as TimesheetSC,		-- On Timesheet (Time)
		@pnTimesheetPD		as TimesheetPD,		-- On Timesheet (Disbursement)
		@pnTimesheetOR		as TimesheetOR,		-- On Timesheet (Recoverables)
		@pnProductivity		as Productivity,	-- Productivty
		@pnAgedWIP0		as AgedWIP0,		-- Aged WIP (Current Period)
		@pnAgedWIP1		as AgedWIP1,		-- Aged WIP (Period 1)
		@pnAgedWIP2		as AgedWIP2,		-- Aged WIP (Period 2)
		@pnAgedWIP3		as AgedWIP3,		-- Aged WIP (Period 3)
		@pnAgedDebt0		as AgedDebt0,		-- Aged Debt (Current Period)
		@pnAgedDebt1		as AgedDebt1,		-- Aged Debt (Period 1)
		@pnAgedDebt2		as AgedDebt2,		-- Aged Debt (Period 2)
		@pnAgedDebt3		as AgedDebt3,		-- Aged Debt (Period 3)
		@pnPrepayments		as Prepayments		-- Prepayments
End
Else Begin
	Select @ErrorCode
End

Return @ErrorCode
go

grant execute on dbo.ts_StaffPerformance to public
go
