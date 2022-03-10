-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ForecastAdHocDates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ip_ForecastAdHocDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.ip_ForecastAdHocDates.'
	drop procedure dbo.ip_ForecastAdHocDates
End
print '**** Creating procedure dbo.ip_ForecastAdHocDates...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ip_ForecastAdHocDates
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pdtDueDate			datetime,		-- Mandatory. Due date of the Alert
	@pdtStopRemindersDate		datetime	= null,	-- the date reminders are to stop being produced
	@pnMonthsLead	 		smallint	= null,	-- no. of months before the @pdtDueDate that monthly reminders commence
	@pnMonthlyFrequency	 	smallint	= null,	-- no. of months between monthly reminders 
	@pnDaysLead			smallint	= null,	-- no. of days before the @pdtDueDate that daily reminders commence (and monthly reminders stop)
	@pnDailyFrequency 		smallint	= null	-- no. of days between daily reminders
)	
AS
-- PROCEDURE :	ip_ForecastAdHocDates
-- VERSION :	
-- DESCRIPTION:	Returns the projected dates that alert reminders will be generated for a
--		set of parameters.  A maximum of one years worth of reminders will be   
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 27 Aug 2004  MF		1	Procedure created 
-- 13 Sep 2004	MF		2	The @pnMonthsLead and @pnDaysLead parameters were incorrectly
--					being initialised to zero if they were NULL.
-- 22 Oct 2004	MF	1327	3	Procedure going into an endless loop for a particular set of data.
--					Issue arises where Due Date between 29th and 31st of month and their
--					is a monthly Frequency.  When the calculated reminder date falls on the
--					last day of the month which has a day (e.g. 28th) less than the day of the 
--					due date (e.g. 30th) then the newly calculate Reminder Date is not 
--					being advanced by the defined frequency.
-- 01 Sep 2006	LP	RFC4328 4	Add new RowKey column to result set
-- 05 Jul 2013	vql	R13629	5	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 08 Nov 2018	AV	75198/DR-45358	6	Date conversion errors when creating cases and opening names in Chinese DB.

-- Settings
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Variables
declare @ErrorCode	int
declare @dtReminderDate	datetime


declare @tbReminders table (REMINDERDATE	datetime,
			    ROWKEY		int		IDENTITY)

-- Initialise
set @ErrorCode=0
set @pnRowCount=1

-- Start the calculations from the current system date
set @dtReminderDate=convert(nvarchar, getdate(),112)

-- If a StopRemindersDate has not been set then artificially
-- set it to a maximum of 1 year from the current system date
-- to limit the size of the possible list of projected dates.
If @pdtStopRemindersDate is null
Begin
	If @pdtDueDate<getdate()
		Set @pdtStopRemindersDate=dateadd(year,1,getdate())
	else
		Set @pdtStopRemindersDate=dateadd(year,1,@pdtDueDate)
End

-- Now calculate the subsequent reminder dates up to a maximumn of
-- 1 year after the current date.

WHILE @ErrorCode=0
and   @pnRowCount >0
begin
	-- Use the previously inserted @dtReminder to get the last reminder
	-- date so that the next date is greater than it.

	select	@dtReminderDate=
		-- If the @pdtDueDate less the Days lead time is earlier than the last date
		-- then calculate the next ALERTDATE using the Days lead and frequency
	CASE 	WHEN( dateadd(day,  -1 * @pnDaysLead,   @pdtDueDate) <= @dtReminderDate)
			THEN CASE WHEN (@pnDailyFrequency>0)
				THEN CASE WHEN((dateadd (day,  ((datediff (day,   dateadd (day,  -1 * @pnDaysLead, @pdtDueDate), @dtReminderDate)/ @pnDailyFrequency)   +1)*@pnDailyFrequency-@pnDaysLead, @pdtDueDate))< isnull(@pdtStopRemindersDate,'30001231'))  -- '31-DEC-3000'
					THEN    dateadd (day,  ((datediff (day,   dateadd (day,  -1 * @pnDaysLead, @pdtDueDate), @dtReminderDate)/ @pnDailyFrequency)   +1)*@pnDailyFrequency-@pnDaysLead, @pdtDueDate)
					ELSE NULL
				     END
				ELSE NULL
			     END
		-- If the @pdtDueDate less the Months lead time is earlier than the previous date
		-- and the next Monthly Reminder is earlier than the first daily reminder
		-- then calculate the next ALERTDATE using the Months lead and frequency
		WHEN((dateadd(month,-1 * @pnMonthsLead,@pdtDueDate) <= @dtReminderDate)
		 and ((	CASE WHEN (@pnMonthlyFrequency>0)
				THEN CASE WHEN((dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * @pnMonthsLead, @pdtDueDate), @dtReminderDate)/ convert(decimal(5,1),@pnMonthlyFrequency)))   +CASE WHEN(day  (@pdtDueDate) - day  (@dtReminderDate) < 1) THEN 1 WHEN(day(@dtReminderDate+1)=1) THEN 1 ELSE 0 END)*@pnMonthlyFrequency-@pnMonthsLead, @pdtDueDate))< isnull(@pdtStopRemindersDate,'30001231')) -- '31-DEC-3000'
					THEN    dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * @pnMonthsLead, @pdtDueDate), @dtReminderDate)/ convert(decimal(5,1),@pnMonthlyFrequency)))   +CASE WHEN(day  (@pdtDueDate) - day  (@dtReminderDate) < 1) THEN 1 WHEN(day(@dtReminderDate+1)=1) THEN 1 ELSE 0 END)*@pnMonthlyFrequency-@pnMonthsLead, @pdtDueDate)
					ELSE NULL
				     END
				ELSE NULL
			END) < isnull(dateadd(day,  -1 * @pnDaysLead,   @pdtDueDate),'30001231') )) -- '31-DEC-3000'
			THEN CASE WHEN (@pnMonthlyFrequency>0)
				THEN CASE WHEN((dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * @pnMonthsLead, @pdtDueDate), @dtReminderDate)/ convert(decimal(5,1),@pnMonthlyFrequency)))   +CASE WHEN(day  (@pdtDueDate) - day  (@dtReminderDate) < 1) THEN 1 WHEN(day(@dtReminderDate+1)=1) THEN 1 ELSE 0 END)*@pnMonthlyFrequency-@pnMonthsLead, @pdtDueDate))< isnull(@pdtStopRemindersDate,'30001231')) -- '31-DEC-3000'
					THEN    dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * @pnMonthsLead, @pdtDueDate), @dtReminderDate)/ convert(decimal(5,1),@pnMonthlyFrequency)))   +CASE WHEN(day  (@pdtDueDate) - day  (@dtReminderDate) < 1) THEN 1 WHEN(day(@dtReminderDate+1)=1) THEN 1 ELSE 0 END)*@pnMonthlyFrequency-@pnMonthsLead, @pdtDueDate)
					ELSE NULL
				     END
				ELSE NULL
			     END
		-- If the @pdtDueDate less the Months lead time is earlier than the previous date
		-- and the next monthly reminder is after the first Daily reminder then use the first Daily reminder
		WHEN((dateadd(month,-1 * @pnMonthsLead,@pdtDueDate)<= @dtReminderDate)
		 and  dateadd(day,  -1 * @pnDaysLead,  @pdtDueDate)<  isnull(@pdtStopRemindersDate,'30001231') -- '31-DEC-3000'
		 and (CASE WHEN (@pnMonthlyFrequency>0)
				THEN CASE WHEN((dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * @pnMonthsLead, @pdtDueDate), @dtReminderDate)/ convert(decimal(5,1),@pnMonthlyFrequency)))   +CASE WHEN(day  (@pdtDueDate) - day  (@dtReminderDate) < 1) THEN 1 WHEN(day(@dtReminderDate+1)=1) THEN 1 ELSE 0 END)*@pnMonthlyFrequency-@pnMonthsLead, @pdtDueDate))< isnull(@pdtStopRemindersDate,'30001231')) --'31-DEC-3000'
					THEN    dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * @pnMonthsLead, @pdtDueDate), @dtReminderDate)/ convert(decimal(5,1),@pnMonthlyFrequency)))   +CASE WHEN(day  (@pdtDueDate) - day  (@dtReminderDate) < 1) THEN 1 WHEN(day(@dtReminderDate+1)=1) THEN 1 ELSE 0 END)*@pnMonthlyFrequency-@pnMonthsLead, @pdtDueDate)
					ELSE NULL
				     END
				ELSE NULL
			END
			>= isnull(dateadd(day,  -1 * @pnDaysLead,   @pdtDueDate),'30001231') ))  -- '31-DEC-3000'
			THEN dateadd(day,  -1 * @pnDaysLead,   @pdtDueDate)
		-- If the @pdtDueDate less the Months lead time is earlier than the previous date
		-- and the next Monthly Reminder is not earlier than the next Daily reminder
		-- then calculate the next ALERTDATE using the Daily lead and frequency
		WHEN((dateadd(month,-1 * @pnMonthsLead,@pdtDueDate) <= @dtReminderDate)
		 and ((	CASE WHEN (@pnMonthlyFrequency>0)
				THEN CASE WHEN((dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * @pnMonthsLead, @pdtDueDate), @dtReminderDate)/ convert(decimal(5,1),@pnMonthlyFrequency)))   +CASE WHEN(day  (@pdtDueDate) - day  (@dtReminderDate) < 1) THEN 1 WHEN(day(@dtReminderDate+1)=1) THEN 1 ELSE 0 END)*@pnMonthlyFrequency-@pnMonthsLead, @pdtDueDate))< isnull(@pdtStopRemindersDate,'30001231')) --'31-DEC-3000'
					THEN    dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * @pnMonthsLead, @pdtDueDate), @dtReminderDate)/ convert(decimal(5,1),@pnMonthlyFrequency)))   +CASE WHEN(day  (@pdtDueDate) - day  (@dtReminderDate) < 1) THEN 1 WHEN(day(@dtReminderDate+1)=1) THEN 1 ELSE 0 END)*@pnMonthlyFrequency-@pnMonthsLead, @pdtDueDate)
					ELSE NULL
				     END
				ELSE NULL
			END) >= isnull(dateadd(day,  -1 * @pnDaysLead,   @pdtDueDate),'30001231'))) -- '31-DEC-3000'
			THEN CASE WHEN((dateadd (day,  ((datediff (day,   dateadd (day,  -1 * @pnDaysLead, @pdtDueDate), @dtReminderDate)/ @pnDailyFrequency)   +1)*@pnDailyFrequency-@pnDaysLead, @pdtDueDate))< isnull(@pdtStopRemindersDate,'30001231')) --'31-DEC-3000'
				THEN    dateadd (day,  ((datediff (day,   dateadd (day,  -1 * @pnDaysLead, @pdtDueDate), @dtReminderDate)/ @pnDailyFrequency)   +1)*@pnDailyFrequency-@pnDaysLead, @pdtDueDate)
				ELSE NULL
			     END
		-- If the @pdtDueDate less the Months lead time is before the @pdtDueDate less the 
		-- Days lead time or there is no Days lead time then the ALERTDATE will be
		-- set to the @pdtDueDate less the Months lead time if it is in the future
		WHEN(  dateadd(month,-1 * @pnMonthsLead,@pdtDueDate) < isnull(dateadd(day,  -1 * @pnDaysLead,   @pdtDueDate),'30001231') -- '31-DEC-3000'
		   and dateadd(month,-1 * @pnMonthsLead,@pdtDueDate)> @dtReminderDate)
		   and dateadd(month,-1 * @pnMonthsLead,@pdtDueDate)< isnull(@pdtStopRemindersDate,'30001231') -- '31-DEC-3000'
			THEN dateadd(month,-1 * @pnMonthsLead,@pdtDueDate)
		-- If the @pdtDueDate less the Days lead time is in the future then the ALERTDATE will be
		-- set to the @pdtDueDate less the Days lead time
		WHEN( isnull(dateadd(day,  -1 * @pnDaysLead,   @pdtDueDate),'19000101')> @dtReminderDate		-- '01-JAN-1900'
		   and dateadd(day,  -1 * @pnDaysLead,@pdtDueDate)< isnull(@pdtStopRemindersDate,'30001231')) -- '31-DEC-3000'
			THEN dateadd(day,  -1 * @pnDaysLead,   @pdtDueDate)
	END
	
	-- Now load the calculated date into a table variable

	insert into @tbReminders(REMINDERDATE)
	select @dtReminderDate
	where  @dtReminderDate is not null
	
	Select	@pnRowCount=@@RowCount,
		@ErrorCode =@@Error

End -- While loop

-- Return the result set from the table variable

If @ErrorCode=0
Begin
	Select  REMINDERDATE,
		CONVERT(nvarchar(10),ROWKEY) 	as ROWKEY
	from @tbReminders
	order by REMINDERDATE
		
	Select	@pnRowCount=@@RowCount,
		@ErrorCode =@@Error
End


RETURN @ErrorCode
GO

Grant execute on dbo.ip_ForecastAdHocDates  to public
GO

