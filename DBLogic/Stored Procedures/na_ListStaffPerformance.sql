-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListStaffPerformance
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListStaffPerformance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_ListStaffPerformance.'
	Drop procedure [dbo].[na_ListStaffPerformance]
	Print '**** Creating Stored Procedure dbo.na_ListStaffPerformance...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.na_ListStaffPerformance
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnNameKey		int		= null, 	-- The name the results are required for.  If left null, the results are extracted for the current UserIdentity.
	@psResultsRequired	nvarchar(100)   = null,  	-- A comma separated list of the result sets required.  Null will return all result sets.  Other values that may be requested are Hours, Receivable, WorkAnalysis, WorkInProgress, DueDates
	@psNameTypeKey		nvarchar(3) 	= null,		-- The Name Type relationship the NameKey has to the cases to be reported.  If null, personal data is reported.
	@pbPostDateFlag		bit         	= 0,		-- Flag to indicate that Post Date to be used otherwise Trans Date.
	@pnDueDateDays0		smallint	= 7,		-- The number of days if the Bracket0Count for Due Dates.
	@pnDueDateDays1		smallint	= 30,		-- The number of days if the Bracket1Count for Due Dates.
	@pnDueDateDays2		smallint	= 90,		-- The number of days if the Bracket2Count for Due Dates.
	@pbCalledFromCentura	bit		= 0

)
AS 
-- PROCEDURE:	na_ListStaffPerformance
-- VERSION:	33
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns the details for the professional with an overview of the status of work that is 
--		his/her responsibility.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 09 Feb 2004  TM	RFC834	1	Procedure created. 
-- 19-Feb-2004	TM	RFC976	2	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 24-Feb-2004	TM	RFC834	3	Implements Julie's feedback
-- 26-Feb-2004	TM	RFC834	4	Put Timesheet values into a separate result set. Implement Julie's feedback.
-- 27-Feb-2004	TM	RFC834	5	Retrieve the DaysSinceTimesheetPosted in the separate 'Select' statement.
--					Correct Start Date to be '>= Start Date' for WTD post date range and for the
--					TimesheetTotal calculation. Set results to null if the denominator is 0.
-- 01-Mar-2004	TM	RFC834	6	Return CategoryKey and CategoryDescription when there is no data in the WORKHISTORY. 
-- 16-Apr-2004	TM	RFC1317	7	Show Balance by Currency Totals in corresponding currency. Return Prepayment in
--					Accounts Receivable topic and Billed values in Work Analysis topic as positive 
--					values.
-- 16-Apr-2004	TM	RFC1332	8	Exclude Prepayment value from Accounts Receivable topic Total column.
-- 05-May-2004	TM	RFC1369	9	Correct the Days Beyond Terms calculation.
-- 13-May-2004	TM	RFC1431	10	Correct the ProductivityPercent column to be ProductivityPercentPTD.
-- 28-Jun-2004	TM	RFC1563	11	Correct the Due Date Counts calculation in the Due Date topic.
-- 18 Sep 2004	JEK	RFC886	12	Implement translation.
-- 29 Sep 2004	MF	RFC1846	13	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 14 Oct 2004	TM	RFC1699	14	Modify the logic that assembles all relevant WorkAnalysis date ranges to use 
--					'between' instead of 'like' to search on the WorkHistory.PostPeriod.
-- 20 Dec 2004	TM	RFC2121	15	Suppress the Hours and WorkAnalysis result sets if there are no Accounting 
--					Periods available.
-- 06 Jan 2005	TM	RFC2179	16	Multiply the WIP Recovery % by 100.
-- 07 Jan 2005	TM	RFC2185	17	Correct the outstanding days calculations in the WIP and Receivable result sets.
-- 24 Jan 2005	TM	RFC2223	18	WIP Recovery quotient is being incorrectly rounded to the nearest whole number 
--					before being multiplied by 100.
-- 15 May 2005	JEK	RFC2508	19	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 23 May 2005	TM	RFC2594	20	Modify to look up ReceivableItems and WIP subjects only once.
-- 20 Jun 2005	TM	RFC1100	21	Exclude all timer rows from their processing of unposted time; i.e. AND ISTIMER=0.
-- 25 Nov 2005	LP	RFC1017	22	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Name result set
-- 17 Jul 2006	SW	RFC3828	23	Pass getdate() to fn_Permission..
-- 06 Feb 2006	SF	RFC4918	24	Add RowKey for calling code compatibility
-- 11 Dec 2008	MF	17136	25	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 08 Jul 2010	MF	RFC6540	26	Correct counts returned for due date ranges to ensure each bracket does not include the counts from
--					the previous bracket.
-- 16 Jul 2010	MF	RFC6540	27	Also excluded Due Dates that exclusively belong to the Law Update Service Renewals action ~2.
-- 21 Jul 2010	MF	RFC6540	28	Revisit this to ensure the due date algorithm matches the algorithm used by the case query called from csw_ListCase.
-- 07 Jul 2011	DL	RFC10830 29	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 05 Jul 2013	vql	R13629	30	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910	31	Adjust formatted names logic (DR-15543).
-- 06 May 2016	LP	R61294	31	Fixed issue with WIP Category breakdown when filtering by cases that the user is responsible staff.
-- 12 May 2016	LP	R61405	32	Changed to multiply Billed totals by -1 to make it consistent with client-server
-- 14 Nov 2018  AV  75198/DR-45358	33   Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int

Declare @sSQLString			nvarchar(4000)

Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period

-- Variables used in Productivity % calculation
Declare @nDaysSinceTimesheetPosted	int
Declare @nProductivityWTD		int
Declare @nProductivityPTD		int 
Declare @nProductivityYTD		int 
Declare @nEffortPercentWTD		int
Declare @nEffortPercentPTD		int 
Declare @nEffortPercentYTD		int 
Declare @nWorkDaysWTD			int
Declare @nWorkDaysPTD			int
Declare @nWorkDaysYTD			int

-- Variables used in Date Range calculation for Productivity and for Work Analysis
Declare @sProductivityDateRangeWTD	nvarchar(100)
Declare @sProductivityDateRangePTD	nvarchar(100)
Declare @sProductivityDateRangeYTD	nvarchar(100)
Declare @sWorkAnalysisDateRangeWTD	nvarchar(100)
Declare @sWorkAnalysisDateRangePTD	nvarchar(100)
Declare @sWorkAnalysisDateRangeYTD	nvarchar(100)
Declare @nChargeableMinutesWTD		int
Declare @nChargeableMinutesPTD		int
Declare @nChargeableMinutesYTD		int
Declare @nMinutesWorkedWTD		int
Declare @nMinutesWorkedPTD		int
Declare @nMinutesWorkedYTD		int
Declare @dtWorkAnalysisEndDate		datetime
Declare @dtProductivityEndDate		datetime
Declare @dtStartDateWTD			datetime
Declare @dtStartDatePTD			datetime
Declare @dtStartDateYTD			datetime
Declare @nDailyHours			decimal(5,2)
Declare @nWorkHoursWTD			decimal(11,2)
Declare @nWorkHoursPTD			decimal(11,2)
Declare @nWorkHoursYTD			decimal(11,2)
Declare @nReceivableAverageValue	decimal(11,2)

Declare @bIsBillingAvailable		bit
Declare @bIsWIPAvailable		bit
Declare @bIsReceivableAvailable		bit
Declare @nWIPAverageValue		decimal(11,2)
Declare @nWIPDisbursemenAverageValue	decimal(11,2)

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint

-- Table variable used to hold the names of the Result Set that stored procedure needs to calculate and return.
Declare @tblResultsRequired table	(ResultSet	nvarchar(40) collate database_default) 

Declare @sLookupCulture		nvarchar(10)
Declare @dtToday		datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

-- Intialise Variables
Set     @nErrorCode = 0

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Use fn_Tokenise to extract the requested result sets into a @tblResultsRequired table variable 
If @nErrorCode = 0
and @psResultsRequired is not null
Begin
	Insert into @tblResultsRequired
	Select Parameter
	from fn_Tokenise (@psResultsRequired, ',')
End

If @nErrorCode = 0
and @pnNameKey is null
Begin
	Set @sSQLString = "
	Select @pnNameKey = UI.NAMENO
	from USERIDENTITY UI
	where UI.IDENTITYID = @pnUserIdentityId" 
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @pnNameKey 		int			OUTPUT',					 
					  @pnUserIdentityId     = @pnUserIdentityId,
					  @pnNameKey 		= @pnNameKey		OUTPUT
End

-- Name result set
If (exists(select * from @tblResultsRequired where ResultSet in ('Name'))
or @psResultsRequired is null)
and @nErrorCode = 0
Begin 
	Set @sSQLString = "
	Select  N.NAMENO 	as 'NameKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)	
			 	as 'Name',
		N.NAMECODE		as 'NameCode',
		@sLocalCurrencyCode 	as 'LocalCurrencyCode',
		@nLocalDecimalPlaces	as 'LocalDecimalPlaces'
		from NAME N	
		where N.NAMENO = @pnNameKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnNameKey 		int,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint',					 
					  @pnNameKey 		= @pnNameKey,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces

End

-- Check whether the if Time and Billing is implemented at the site
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select @bIsBillingAvailable = IsAvailable
	from	dbo.fn_GetTopicSecurity(null, 100, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @bIsBillingAvailable		bit			OUTPUT,
					  @dtToday			datetime',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @bIsBillingAvailable		= @bIsBillingAvailable	OUTPUT,
					  @dtToday			= @dtToday
End

-- Determine the date range to be used in the calculation of statistics
-- A parameter passed to the procedure will also determine whether TRANSDATE
-- or POSTDATE is to be used.

If (exists(select * from @tblResultsRequired where ResultSet in ('Hours', 'WorkAnalysisTotal','WorkAnalysisByCategory'))
or @psResultsRequired is null)
and @bIsBillingAvailable = 1
and @nErrorCode = 0
Begin 
	-- End date for Productivity % calculatiobs is always today minus 1 day
	Set @dtProductivityEndDate = DATEADD(dd ,-1,getdate())
	-- End date for Worl Analysis calculations is always today's date + 1 as we only use it 
	-- as the 'DIARY.STARTTIME < @dtWorkAnalysisEndDate'
	Set @dtWorkAnalysisEndDate = DATEADD(dd ,1,getdate()) 
 		
	-- Period to date
	-- Find the Start and End dates for the current period
	Set @sSQLString = 
	"Select @sProductivityDateRangePTD 	= '	W.TRANSDATE between '''" + char(10)+				     		
						 -- @sDateRangePTD is used to calculate Productivity % therefore use today minus 1 day as
						 -- an End Date.  
						 "+convert(nvarchar,P.STARTDATE,112) + "+"''' and '''"+" + convert(nvarchar,DATEADD(dd ,-1,getdate()) ,112) + "+"'''',"+char(10)+
		-- Start date is the same for both Productivity % and Work Analysis. 
		"@dtStartDatePTD 		= P.STARTDATE,"+char(10)+		
		"@sWorkAnalysisDateRangePTD 	= CASE WHEN(@pbPostDateFlag = 0)"+char(10)+ 
				     		  "THEN " + "'	W.TRANSDATE between '''" + char(10)+
						  -- @sWorkAnalysisDateRangePTD is used to calculate Work Analysis therefore use today as an End Date.						    
						  "+convert(nvarchar,P.STARTDATE,112) + "+"''' and '''"+" + convert(nvarchar,getdate(),112) + "+"''''"+char(10)+	
				     		  "ELSE " + "'	W.POSTPERIOD = '" + " + convert(varchar,P.PERIODID)" + char(10)+
			        		  "END" + char(10)+						 
	"from PERIOD P"+char(10)+
	"where P.STARTDATE = (select max(STARTDATE) from PERIOD where STARTDATE<getdate())"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@sProductivityDateRangePTD 	nvarchar(100)			OUTPUT,
					  @dtStartDatePTD		datetime			OUTPUT,
					  @sWorkAnalysisDateRangePTD	nvarchar(100)			OUTPUT,
					  @pbPostDateFlag		bit',					 
					  @sProductivityDateRangePTD 	= @sProductivityDateRangePTD	OUTPUT,
					  @dtStartDatePTD		= @dtStartDatePTD		OUTPUT,
					  @sWorkAnalysisDateRangePTD	= @sWorkAnalysisDateRangePTD	OUTPUT,
					  @pbPostDateFlag		= @pbPostDateFlag	

	If @nErrorCode = 0
	Begin
		-- Year to date
		-- Find the Start date of the first period of the financial year
		Set @sSQLString = 
		"Select @sProductivityDateRangeYTD 	= '	W.TRANSDATE between '''" + char(10)+			        		
							 -- @sProductivityDateRangeYTD is used to calculate Productivity % 
							 -- therefore use today minus 1 day as an End Date.  
							 "+convert(nvarchar,P.STARTDATE,112)  + "+"''' and '''"+" + convert(nvarchar,DATEADD(dd ,-1,getdate()) ,112) + "+"'''',"+char(10)+		
			-- Start date is the same for both Productivity % and Work Analysis. 
			"@dtStartDateYTD 		= P.STARTDATE," + char(10)+
			"@sWorkAnalysisDateRangeYTD  	= CASE WHEN(@pbPostDateFlag = 1)"+char(10)+ 
					     		      "THEN " + "'   W.POSTPERIOD between '''" + " + substring(convert(varchar,P.PERIODID),1,4) + '01'''+" +
									"'   and '''" + " + substring(convert(varchar,P.PERIODID),1,4) + '99'''" + char(10)+ 
					     		      "ELSE " + "'   W.TRANSDATE between '''" + char(10)+
							      "+convert(nvarchar,P.STARTDATE,112)  + "+"''' and '''"+" + convert(nvarchar,getdate() ,112) + "+"''''"+char(10)+		 	
				        		 "END" + char(10)+							   
		"from PERIOD P" + char(10)+ 
		"where P.PERIODID =(	select (P1.PERIODID/100)*100+01" + char(10)+
					"from PERIOD P1"+char(10)+
					"where P1.STARTDATE=(	select max(STARTDATE)" + char(10)+ 
								"from PERIOD where STARTDATE<getdate()))"

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@sProductivityDateRangeYTD 		nvarchar(100)			OUTPUT,
						  @dtStartDateYTD			datetime			OUTPUT,					 
						  @sWorkAnalysisDateRangeYTD		nvarchar(100)			OUTPUT,					  
						  @pbPostDateFlag			bit',					 
						  @sProductivityDateRangeYTD 		= @sProductivityDateRangeYTD	OUTPUT,
						  @dtStartDateYTD			= @dtStartDateYTD		OUTPUT,					 
						  @sWorkAnalysisDateRangeYTD		= @sWorkAnalysisDateRangeYTD	OUTPUT,					 
						  @pbPostDateFlag			= @pbPostDateFlag	
	End

	If @nErrorCode = 0
	Begin
		-- Week to date
		-- Find the Start and End date of the current week
		Set @sProductivityDateRangeWTD = "   W.TRANSDATE between '"			     		
				     		 +convert(nvarchar,DATEADD(day, -1*(DATEPART(weekday,getdate())-1), getdate()),112)+
		       		     		 -- @sDateRangeWTD is used to calculate Productivity % therefore use 'Today minus 1' day as
		       		     		 -- an End Date.  
	               		     		 "' and '"+convert(nvarchar,DATEADD(dd ,-1,getdate()) ,112)+"'" 
	
		Set @sWorkAnalysisDateRangeWTD = CASE WHEN(@pbPostDateFlag = 1) 						      
					  	      THEN "   W.POSTDATE  >= '"
						      +convert(nvarchar,DATEADD(day, -1*(DATEPART(weekday,getdate())-1), getdate()),112)+
						      -- W.POSTDATE is both Date and Time so use W.POSTDATE < today's date + 1
		       		     		      "' and W.POSTDATE < '"+convert(nvarchar,DATEADD(day,1,getdate()),112)+"'" 
					  	      ELSE "   W.TRANSDATE between '"
						      +convert(nvarchar,DATEADD(day, -1*(DATEPART(weekday,getdate())-1), getdate()),112)+
		       		     		      "' and '"+convert(nvarchar,getdate() ,112)+"'" 
				     		 END				     		
	
		-- Start date is the same for both Productivity % and Work Analysis. 
		Set @dtStartDateWTD = convert(nvarchar,DATEADD(day, -1*(DATEPART(weekday,getdate())-1), getdate()),112)		
	End
  	
	-- Now get the number of available hours in a standard day inorder to calculate
	-- the available hours for the date range.
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @nDailyHours = S.COLDECIMAL
		from SITECONTROL S
		where S.CONTROLID='Standard Daily Hours'"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nDailyHours	int		OUTPUT',
						  @nDailyHours	= @nDailyHours  OUTPUT
	End
End

-- Hours result set

If (exists(select * from @tblResultsRequired where ResultSet in ('Hours'))
or @psResultsRequired is null)
and @nErrorCode = 0
Begin 
	If @bIsBillingAvailable = 1
	and (@sProductivityDateRangePTD is not null 
	and  @sProductivityDateRangeYTD is not null)
	Begin
		Set @sSQLString =		
		"Select	@nChargeableMinutesPTD  	= SUM(CASE WHEN W.LOCALTRANSVALUE <> 0 and "+@sProductivityDateRangePTD+char(10)+ 
		"				           	   THEN isnull(DATEPART(HOUR,W.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0)"+char(10)+
		"				           	   ELSE 0"+char(10)+ 
		"				      	      END),"+char(10)+
		"	@nMinutesWorkedPTD 		= SUM(CASE WHEN "+@sProductivityDateRangePTD+char(10)+ 
		"					   	   THEN isnull(DATEPART(HOUR,W.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0)"+char(10)+ 
		"					   	   ELSE 0"+char(10)+
		"				      	      END),"+char(10)+  
		"	@nChargeableMinutesYTD  	= SUM(CASE WHEN W.LOCALTRANSVALUE <> 0 and "+@sProductivityDateRangeYTD+char(10)+ 
		"				           	   THEN isnull(DATEPART(HOUR,W.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0)"+char(10)+
		"				           	   ELSE 0"+char(10)+ 
		"				      	      END),"+char(10)+
		"	@nMinutesWorkedYTD 		= SUM(CASE WHEN "+@sProductivityDateRangeYTD+char(10)+ 
		"					           THEN isnull(DATEPART(HOUR,W.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0)"+char(10)+ 
		"					   	   ELSE 0"+char(10)+ 
		"				      	      END),"+char(10)+ 
		"	@nChargeableMinutesWTD  	= SUM(CASE WHEN W.LOCALTRANSVALUE <> 0 and "+@sProductivityDateRangeWTD+char(10)+ 
		"				           	   THEN isnull(DATEPART(HOUR,W.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0)"+char(10)+
		"				           	   ELSE 0"+char(10)+ 
		"				      	      END),"+char(10)+
		"	@nMinutesWorkedWTD 		= SUM(CASE WHEN "+@sProductivityDateRangeWTD+char(10)+ 
		"					   	   THEN isnull(DATEPART(HOUR,W.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0)"+char(10)+ 
		"					   	   ELSE 0"+char(10)+ 
		"				      	      END)"+char(10)+ 
		"from WORKHISTORY W"+char(10)+		
		"where W.EMPLOYEENO = @pnNameKey"+char(10)+	
		-- Looking only at 'Services' (where there is a TotalTime recorded).
		"and   W.TOTALTIME is not null"+char(10)+
		"and   W.STATUS <> 0"+char(10)+
		"and   W.MOVEMENTCLASS in (1,4,5)"+char(10)+	
		-- Start day of the week can be earlier that the start day of the year so we need Week to Date 
		-- or Year to Date range
		"and   (" + @sProductivityDateRangeWTD + char(10)+
		" or    " + @sProductivityDateRangeYTD +")"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nChargeableMinutesPTD	int			 	OUTPUT,
					     	  @nMinutesWorkedPTD		int			 	OUTPUT,
						  @nChargeableMinutesYTD	int 			 	OUTPUT,
						  @nMinutesWorkedYTD		int			 	OUTPUT,
						  @nChargeableMinutesWTD	int			 	OUTPUT,
						  @nMinutesWorkedWTD		int			 	OUTPUT,						 
						  @pnNameKey			int',
						  @nChargeableMinutesPTD	= @nChargeableMinutesPTD 	OUTPUT,
						  @nMinutesWorkedPTD		= @nMinutesWorkedPTD	 	OUTPUT,
						  @nChargeableMinutesYTD	= @nChargeableMinutesYTD 	OUTPUT,
						  @nMinutesWorkedYTD		= @nMinutesWorkedYTD	 	OUTPUT,
						  @nChargeableMinutesWTD	= @nChargeableMinutesWTD 	OUTPUT,
						  @nMinutesWorkedWTD		= @nMinutesWorkedWTD	 	OUTPUT,						  
						  @pnNameKey			= @pnNameKey

		If  @nErrorCode = 0
		Begin
			Set @sSQLString = "
			Select	@nDaysSinceTimesheetPosted	= datediff(dd,max(STARTTIME), getdate())
			from   DIARY D	 
			where  D.EMPLOYEENO = @pnNameKey
			and    D.TRANSNO is not null
			and    D.ISTIMER = 0"

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@nDaysSinceTimesheetPosted	int			 	OUTPUT,
					     	  @pnNameKey			int',
						  @nDaysSinceTimesheetPosted	= @nDaysSinceTimesheetPosted 	OUTPUT,
						  @pnNameKey			= @pnNameKey	 	
		End
	
		If  @nErrorCode = 0
		Begin
			-- 1)Calculate Period to Date (PTD) Productivity % and Effort Percent and store it in the @nProductivityPTD variable. 
		
			-- Get the number of working days for the calculated Productivity Date Range (Period to Date).	
			Set @nWorkDaysPTD = dbo.fn_GetWorkDays(@dtStartDatePTD,@dtProductivityEndDate)	
		
			-- Now Calculate the total number of hours for the date range
			Select @nWorkHoursPTD = @nWorkDaysPTD*isnull(@nDailyHours,8.0)
			
			-- Now calculate the Productivity percentage by dividing the number of Minutes of chargeable
			-- time by the total available number of minutes
			If @nWorkHoursPTD > 0
			Begin
				Set @nProductivityPTD =  convert(int,round((@nChargeableMinutesPTD*100)/(@nWorkHoursPTD*60),0))
		
				-- Now calculate the Effort percentage by dividing the number of Minutes of minutes worked
				-- by the total available number of minutes
		
				Set @nEffortPercentPTD = convert(int,round((@nMinutesWorkedPTD*100)/(@nWorkHoursPTD*60),0)) 
			End	 	
		
			-- 2)Calculate Year to Date (YTD) Productivity % and Effort Percent and store it in the @nProductivityYTD variable.
		
			-- Get the number of working days for the calculated Date Range (Year to Date). 
			Set @nWorkDaysYTD = dbo.fn_GetWorkDays(@dtStartDateYTD,@dtProductivityEndDate)		
		
			-- Now Calculate the total number of hours for the date range
			Select @nWorkHoursYTD=@nWorkDaysYTD*isnull(@nDailyHours,8.0)
		
			-- Now calculate the Productivity percentage by dividing the number of Minutes of chargeable
			-- time by the total available number of minutes
			If @nWorkHoursYTD>0
			Begin 
				Set @nProductivityYTD =  convert(int,round((@nChargeableMinutesYTD*100)/(@nWorkHoursYTD*60),0))
		
				-- Now calculate the Effort percentage by dividing the number of Minutes of minutes worked
				-- by the total available number of minutes
		
				Set @nEffortPercentYTD = convert(int,round((@nMinutesWorkedYTD*100)/(@nWorkHoursYTD*60),0)) 
			End	 
		
			-- 3)Calculate Week to Date (WTD) Productivity % and Effort Percent and store it in the @nProductivityYTD variable.
		
			-- Get the number of working days for the calculated Date Range (Week to Date). 
			Set @nWorkDaysWTD = dbo.fn_GetWorkDays(@dtStartDateWTD,@dtProductivityEndDate)		
		
			-- Now Calculate the total number of hours for the date range
			Select @nWorkHoursWTD=@nWorkDaysWTD*isnull(@nDailyHours,8.0)
		
			-- Now calculate the Productivity percentage by dividing the number of Minutes of chargeable
			-- time by the total available number of minutes
			If @nWorkHoursWTD>0
			Begin   
				Set @nProductivityWTD = convert(int,round((@nChargeableMinutesWTD*100)/(@nWorkHoursWTD*60.00),0))
		
				-- Now calculate the Effort percentage by dividing the number of Minutes of minutes worked
				-- by the total available number of minutes
		
				Set @nEffortPercentWTD = convert(int,round((@nMinutesWorkedWTD*100)/(@nWorkHoursWTD*60),0)) 
			End	 
		End	
	End
	
	-- Return the 'Hours' result set figures.	
	If @nErrorCode=0
	Begin		
		Select @nDaysSinceTimesheetPosted 
					  	as 'DaysSinceTimesheetPosted',	 
		        @nProductivityWTD 	as 'ProductivityPercentWTD',
		        @nProductivityPTD 	as 'ProductivityPercentPTD',
		        @nProductivityYTD 	as 'ProductivityPercentYTD',
		        @nEffortPercentWTD  	as 'EffortPercentWTD',
			@nEffortPercentPTD	as 'EffortPercentPTD',
			@nEffortPercentYTD  	as 'EffortPercentYTD',				
			@pnNameKey as 'NameKey',
			@pnNameKey as 'RowKey'
		where   @bIsBillingAvailable = 1
		and  (@nDaysSinceTimesheetPosted is not null
		 or   @nProductivityWTD  	 is not null
		 or   @nProductivityPTD  	 is not null
		 or   @nProductivityYTD  	 is not null
		 or   @nEffortPercentWTD 	 is not null
		 or   @nEffortPercentPTD 	 is not null
		 or   @nEffortPercentYTD 	 is not null)
	End	

End

-- WorkAnalysis result set.

--If (exists(select * from @tblResultsRequired where ResultSet in ('WorkAnalysis'))

If (exists(select * from @tblResultsRequired where ResultSet in ('TimesheetTotal','WorkAnalysisTotal','WorkAnalysisByCategory'))
or @psResultsRequired is null
and @nErrorCode = 0)
Begin		
	If @bIsBillingAvailable = 1
	and (@dtStartDatePTD is not null
	and  @dtStartDateYTD is not null 
	and  @sWorkAnalysisDateRangeYTD is not null 
	and  @sWorkAnalysisDateRangePTD is not null)
	Begin 
		If (exists(select * from @tblResultsRequired where ResultSet in ('TimesheetTotal'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin		
			-- TimesheetTotal result set
			Set @sSQLString = 
			"Select"+char(10)+							
			"SUM(CASE WHEN(D.STARTTIME >= '" + convert(nvarchar,@dtStartDateWTD,112) +
				  "' and D.STARTTIME <'"  + convert(nvarchar,@dtWorkAnalysisEndDate,112) + "')"+char(10)+ 
			"	  THEN isnull(D.TIMEVALUE,0) - ISNULL(D.DISCOUNTVALUE,0)"+char(10)+
			"         ELSE 0"+char(10)+
			"    END) as TimesheetValueWTD,"+char(10)+
			"SUM(CASE WHEN(D.STARTTIME >= '" + convert(nvarchar,@dtStartDatePTD,112) + 
				  "' and D.STARTTIME < '"  + convert(nvarchar,@dtWorkAnalysisEndDate,112) + "')"+char(10)+ 
			"	  THEN isnull(D.TIMEVALUE,0) - ISNULL(D.DISCOUNTVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END) as TimesheetValuePTD,"+char(10)+
			"SUM(CASE WHEN(D.STARTTIME >= '" + convert(nvarchar,@dtStartDateYTD,112) + 
				  "' and D.STARTTIME < '"  + convert(nvarchar,@dtWorkAnalysisEndDate,112) + "')"+char(10)+ 
			"	  THEN isnull(D.TIMEVALUE,0) - ISNULL(D.DISCOUNTVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END) as TimesheetValueYTD,"+char(10)+
			"	@pnNameKey as NameKey,"+char(10)+
			"	@pnNameKey as RowKey"
			
			If @psNameTypeKey is null
			Begin
				Set @sSQLString = @sSQLString + char(10)+
				"from DIARY D"+char(10)+				
				"where D.EMPLOYEENO = @pnNameKey"+char(10)+		
				"and   D.TRANSNO is null"+char(10)+
				"and   D.ISTIMER = 0"
			End
			Else
			Begin
				Set @sSQLString = @sSQLString + char(10)+
				"from DIARY D"+char(10)+	
				"join CASENAME CN	on (CN.CASEID=D.CASEID"+char(10)+	
				"			and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"+char(10)+		
				"where CN.NAMENO = @pnNameKey"+char(10)+	
				"and   CN.NAMETYPE = @psNameTypeKey"+char(10)+	
				"and   D.TRANSNO is null"+char(10)+
				"and   D.ISTIMER = 0"	
			End
		
			Set @sSQLString = @sSQLString + char(10)+ 		
			-- Start day of the week can be earlier that the start day of the year so we need Week to Date 
			-- or Year to Date range
			"and (D.STARTTIME >= '" + convert(nvarchar,@dtStartDateWTD,112) +
			"' and D.STARTTIME < '"  + convert(nvarchar,@dtWorkAnalysisEndDate,112) + "'" + char(10)+ 
			" or D.STARTTIME >= '"  + convert(nvarchar,@dtStartDateYTD,112) + 
			"' and D.STARTTIME < '"  + convert(nvarchar,@dtWorkAnalysisEndDate,112) + "')"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameKey		int,
							  @psNameTypeKey	nvarchar(3)',
							  @pnNameKey   		= @pnNameKey,
							  @psNameTypeKey	= @psNameTypeKey

		End

		-- WorkAnalysisTotal result set
		If (exists(select * from @tblResultsRequired where ResultSet in ('WorkAnalysisTotal'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin
			Set @sSQLString=
			"select"+char(10)+	
			-- WIPRecoveryPercent is to be calculated over the YTD date range. It is equal to 
			-- WIPBilledYTD/ WIP billed and written up/down year to date.  
			"convert(int,round("+char(10)+			
			"CASE WHEN SUM(CASE WHEN(" + @sWorkAnalysisDateRangeYTD + " and W.MOVEMENTCLASS in (2,3,9))"+char(10)+
			"	  	    THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  	    ELSE 0"+char(10)+
			"    	       END) = 0"+char(10)+ 
				       -- Avoid 'divide by zero' exception and set WIPRecoveryPercent to null.
			"     THEN null"+char(10)+ 
			"     ELSE SUM(CASE WHEN(" + @sWorkAnalysisDateRangeYTD + " and W.MOVEMENTCLASS = 2)"+char(10)+
			"	            THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	            ELSE 0"+char(10)+
			"              END)"+char(10)+
			"	   /"+char(10)+
			" 	   SUM(CASE WHEN(" + @sWorkAnalysisDateRangeYTD + " and W.MOVEMENTCLASS in (2,3,9))"+char(10)+
			"	   	    THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	   	    ELSE 0"+char(10)+
			"     	       END)"+char(10)+
			"END*100,0)) 		as WIPRecoveryPercent,"+char(10)+				
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangeWTD + " and W.MOVEMENTCLASS in (1,4,5))"+char(10)+ 	
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPRecordedWTD,"+char(10)+
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangePTD + " and W.MOVEMENTCLASS in (1,4,5))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"         ELSE 0"+char(10)+
			"    END)		as WIPRecordedPTD,"+char(10)+		
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangeYTD + " and W.MOVEMENTCLASS in (1,4,5))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPRecordedYTD,"+char(10)+
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangeWTD + " and W.MOVEMENTCLASS in (3,9))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPVarianceWTD,"+char(10)+
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangePTD + " and W.MOVEMENTCLASS in (3,9))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPVariancePTD,"+char(10)+
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangeYTD + " and W.MOVEMENTCLASS in (3,9))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPVarianceYTD,"+char(10)+
			"(SUM(CASE WHEN(" + @sWorkAnalysisDateRangeWTD + " and W.MOVEMENTCLASS = 2)"+char(10)+
			"             THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	      ELSE 0"+char(10)+
			"        END)*-1)		as WIPBilledWTD,"+char(10)+
			"(SUM(CASE WHEN(" + @sWorkAnalysisDateRangePTD + " and W.MOVEMENTCLASS = 2)"+char(10)+
			"	      THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	      ELSE 0"+char(10)+
			"        END)*-1)		as WIPBilledPTD,"+char(10)+
			"(SUM(CASE WHEN(" + @sWorkAnalysisDateRangeYTD + " and W.MOVEMENTCLASS = 2)"+char(10)+
			"	      THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	      ELSE 0"+char(10)+
			"        END)*-1)		as WIPBilledYTD,"+char(10)+
			"@pnNameKey as NameKey,"+char(10)+
			"@pnNameKey as RowKey"
			
			If @psNameTypeKey is null
			Begin
				Set @sSQLString = @sSQLString + char(10)+
				"from WORKHISTORY W					
				where W.EMPLOYEENO = @pnNameKey
				and   W.STATUS <> 0"		
			End
			Else
			Begin	
				Set @sSQLString = @sSQLString + char(10)+
				"from WORKHISTORY W
				join CASENAME CN	on (CN.CASEID = W.CASEID
							and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))	
				where CN.NAMENO = @pnNameKey
				and   CN.NAMETYPE = @psNameTypeKey
				and   W.STATUS <> 0"
			End
	
			-- This topic is only visible if Time and Billing is implemented as the site.
			Set @sSQLString = @sSQLString + char(10)+ 
			-- Start day of the week can be earlier that the start day of the year so we need Week to Date 
			-- or Year to Date range
			"and   (" + @sWorkAnalysisDateRangeWTD + char(10)+
			" or    " + @sWorkAnalysisDateRangeYTD +")" + char(10)+
			"and @bIsBillingAvailable = 1"	

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameKey			int,
							  @psNameTypeKey		nvarchar(3),
							  @bIsBillingAvailable		bit',
							  @pnNameKey			= @pnNameKey,
							  @psNameTypeKey		= @psNameTypeKey,
							  @bIsBillingAvailable		= @bIsBillingAvailable			
		End
		
		-- WorkAnalysisByCategory result set
		If (exists(select * from @tblResultsRequired where ResultSet in ('WorkAnalysisByCategory'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin
			Set @sSQLString =  
			"Select"+char(10)+
			"WC.CATEGORYCODE as CategoryKey,"+char(10)+	
			dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)
				+ " as CategoryDescription,"+char(10)+	
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangeWTD + " and W.MOVEMENTCLASS in (1,4,5))"+char(10)+ 	
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPRecordedWTD,"+char(10)+
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangePTD + " and W.MOVEMENTCLASS in (1,4,5))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"         ELSE 0"+char(10)+
			"    END)		as WIPRecordedPTD,"+char(10)+		
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangeYTD + " and W.MOVEMENTCLASS in (1,4,5))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPRecordedYTD,"+char(10)+
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangeWTD + " and W.MOVEMENTCLASS in (3,9))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPVarianceWTD,"+char(10)+
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangePTD + " and W.MOVEMENTCLASS in (3,9))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPVariancePTD,"+char(10)+
			"SUM(CASE WHEN(" + @sWorkAnalysisDateRangeYTD + " and W.MOVEMENTCLASS in (3,9))"+char(10)+
			"	  THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	  ELSE 0"+char(10)+
			"    END)		as WIPVarianceYTD,"+char(10)+
			"(SUM(CASE WHEN(" + @sWorkAnalysisDateRangeWTD + " and W.MOVEMENTCLASS = 2)"+char(10)+
			"             THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	      ELSE 0"+char(10)+
			"        END)*-1)		as WIPBilledWTD,"+char(10)+
			"(SUM(CASE WHEN(" + @sWorkAnalysisDateRangePTD + " and W.MOVEMENTCLASS = 2)"+char(10)+
			"	      THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	      ELSE 0"+char(10)+
			"        END)*-1)		as WIPBilledPTD,"+char(10)+
			"(SUM(CASE WHEN(" + @sWorkAnalysisDateRangeYTD + " and W.MOVEMENTCLASS = 2)"+char(10)+
			"	      THEN isnull(W.LOCALTRANSVALUE,0)"+char(10)+
			"	      ELSE 0"+char(10)+
			"        END)*-1)		as WIPBilledYTD,"+char(10)+
			"@pnNameKey as NameKey,"+char(10)+
			"WC.CATEGORYCODE as RowKey"
			
			If @psNameTypeKey is null
			Begin
				Set @sSQLString = @sSQLString + char(10)+
				"from WIPCATEGORY WC"+char(10)+
				"left join WIPTYPE WT 	 	on (WT.CATEGORYCODE = WC.CATEGORYCODE)"+char(10)+  
				"left join WIPTEMPLATE WIP 	on (WIP.WIPTYPEID = WT.WIPTYPEID)"+char(10)+
				"left join WORKHISTORY W 	on (W.WIPCODE = WIP.WIPCODE"+char(10)+
				"				and W.EMPLOYEENO = @pnNameKey"+char(10)+
				"				and   W.STATUS <> 0"+char(10)+			
				-- Start day of the week can be earlier that the start day of the year so we need Week to Date 
				-- or Year to Date range
				"				and   (" + @sWorkAnalysisDateRangeWTD + char(10)+
				" 				or    " + @sWorkAnalysisDateRangeYTD +"))"
				
			End
			Else
			Begin	
				Set @sSQLString = @sSQLString + char(10)+
				"from WIPCATEGORY WC"+char(10)+
				"left join WIPTYPE WT 		on (WT.CATEGORYCODE = WC.CATEGORYCODE)"+char(10)+  
				"left join WIPTEMPLATE WIP	on (WIP.WIPTYPEID = WT.WIPTYPEID)"+char(10)+
				"left join WORKHISTORY W 	on (W.WIPCODE = WIP.WIPCODE"+char(10)+				
				"				and W.STATUS<>0"+char(10)+			
								-- Start day of the week can be earlier that the start day 
								-- of the year so we need Week to Date  or Year to Date range
				"				and (" + @sWorkAnalysisDateRangeWTD + char(10)+
				"				or " + @sWorkAnalysisDateRangeYTD +"))"+char(10)+
				"join CASENAME CN 		on (CN.CASEID = W.CASEID"+char(10)+
				"				and CN.NAMENO=@pnNameKey"+char(10)+
				"				and CN.NAMETYPE=@psNameTypeKey"+char(10)+
				"				and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"				
			End		
	
			Set @sSQLString = @sSQLString + char(10)+						
			"group by WC.CATEGORYCODE, "+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)+char(10)+  
			"order by CASE WC.CATEGORYCODE WHEN 'SC' THEN 0"+char(10)+	-- Services
			"   			       WHEN 'PD' THEN 1"+char(10)+	-- Disbursements
			"			       WHEN 'OR' THEN 2"+char(10)+	-- Overheads
			"         END"	

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameKey			int,
							  @psNameTypeKey		nvarchar(3)',
							  @pnNameKey			= @pnNameKey,
							  @psNameTypeKey		= @psNameTypeKey		
		End
	End
	Else 
	Begin
		-- Return an empty TimesheetTotal result set
		If (exists(select * from @tblResultsRequired where ResultSet in ('TimesheetTotal'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin
			Select	null 	as TimesheetValueWTD,
				null 	as TimesheetValuePTD,
				null	as TimesheetValueYTD,
				null 	as NameKey,
				null	as RowKey
			where @bIsBillingAvailable = 1
		End
		
		-- Return an empty WorkAnalysisTotal result set
		If (exists(select * from @tblResultsRequired where ResultSet in ('WorkAnalysisTotal'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin
			Select	null 	as WIPRecoveryPercent,
				null  	as WIPRecordedWTD,
				null	as WIPRecordedPTD,
				null	as WIPRecordedYTD,
				null 	as WIPVarianceWTD,
				null	as WIPVariancePTD,
				null	as WIPVarianceYTD,
				null	as WIPBilledWTD,
				null	as WIPBilledPTD,
				null	as WIPBilledYTD,
				null 	as NameKey,
				null	as RowKey
			where @bIsBillingAvailable = 1
		End

		-- Return an empty WorkAnalysisByCategory result set	
		If (exists(select * from @tblResultsRequired where ResultSet in ('WorkAnalysisByCategory'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin
			Select	null 	as CategoryKey,
				null 	as CategoryDescription,
				null  	as WIPRecordedWTD,
				null	as WIPRecordedPTD,
				null	as WIPRecordedYTD,
				null 	as WIPVarianceWTD,
				null	as WIPVariancePTD,
				null	as WIPVarianceYTD,
				null	as WIPBilledWTD,
				null	as WIPBilledPTD,
				null	as WIPBilledYTD,
				null 	as NameKey,
				null 	as RowKey
			where @bIsBillingAvailable = 1			
		End
	End
End

-- Determine the ageing periods to be used for the aged balance calculations
If (exists(select * from @tblResultsRequired where ResultSet in ('ReceivableTotal','ReceivableByCurrency','WIPTotal','WIPByCurrency'))
or @psResultsRequired is null)
and @nErrorCode = 0
Begin
	exec @nErrorCode = ac_GetAgeingBrackets @pdtBaseDate	  = @dtBaseDate		OUTPUT,
						@pnBracket0Days   = @nAge0		OUTPUT,
						@pnBracket1Days   = @nAge1 		OUTPUT,
						@pnBracket2Days   = @nAge2		OUTPUT,
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture	  = @psCulture
End

If (exists(select * from @tblResultsRequired where ResultSet in ('ReceivableTotal','ReceivableByCurrency'))
or @psResultsRequired is null)
and @nErrorCode = 0
Begin
	-- Check whether the Receivable Items information is available:
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		select @bIsReceivableAvailable = IsAvailable
		from	dbo.fn_GetTopicSecurity(null, 200, default, @dtToday)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId		int,
						  @bIsReceivableAvailable	bit			  OUTPUT,
						  @dtToday			datetime',
						  @pnUserIdentityId		= @pnUserIdentityId,
						  @bIsReceivableAvailable	= @bIsReceivableAvailable OUTPUT,
						  @dtToday			= @dtToday
	End

	-- These result sets should be empty unless Receivable Items information security is implemented at the site.
	If @bIsReceivableAvailable = 1
	Begin
		If @nErrorCode=0
		Begin
			-- Average value added to receivables per day. This average is to be calculated across DEBTORHISTORYs 
			-- for the staff member involved posted	in the past year as sum(LOCALVALUE)/days in last year.
		
			Set @sSQLString = "
			Select @nReceivableAverageValue = sum(isnull(DH.LOCALVALUE,0))/datediff(dd,dateadd(yy,-1,getdate()),getdate())
			from ASSOCIATEDNAME AN
			join DEBTORHISTORY DH	on (DH.ACCTDEBTORNO=AN.NAMENO)
			where AN.RELATEDNAME = @pnNameKey
			and   AN.RELATIONSHIP = 'RES'
			and   DH.MOVEMENTCLASS = 1
			and   DH.POSTDATE between  dateadd(yy,-1,getdate()) and getdate()"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nReceivableAverageValue	decimal(11,2)	 		OUTPUT,
							  @pnNameKey			int',
							  @nReceivableAverageValue	= @nReceivableAverageValue 	OUTPUT,
							  @pnNameKey			= @pnNameKey
		End
		
		-- Populating ReceivableTotal Result Set
		If (exists(select * from @tblResultsRequired where ResultSet in ('ReceivableTotal'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin
			Set @sSQLString = "
			-- DaysOutstanding - calculated as the current outstanding balance (sum(LOCALBALANCE)) divided by the average value 
		 	-- added to receivables per day. This average is to be calculated across all OPENITEMs posted 
			-- in the past year as sum(LOCALVALUE)/days in last year.
			Select
			@pnNameKey	as 'NameKey', 
			-- it is unlikely Trading Tems will be set to -999999.  This is used as a row key.
			ISNULL(SC.COLINTEGER, -999999) as 'RowKey',	
			convert(int,	       
			CASE WHEN @nReceivableAverageValue = 0 
			     -- Avoid 'divide by zero' exception and set DaysOutstanding to null.
			     THEN null
			     ELSE (sum(isnull(O.LOCALBALANCE,0)))/@nReceivableAverageValue
			END)		as 'DaysOutstanding',
			-- DaysBeyondTerms is calculated as sum(ReceivableBalance x Days OverDue)/Total Receivable Balance. 
			-- It should return null if the Trading Terms site control is set to null.
			CASE WHEN SC.COLINTEGER is null
			     THEN null
			     ELSE convert(int,			  
				  CASE WHEN sum(CASE WHEN O.LOCALBALANCE > 0 THEN O.LOCALBALANCE ELSE 0 END) = 0
				       -- Avoid 'divide by zero' exception and set DaysBeyondTerms to null.
				       THEN null 
			     	       ELSE sum(CASE WHEN O.LOCALBALANCE > 0 
						     THEN (O.LOCALBALANCE* CASE WHEN (datediff(dd,isnull(O.ITEMDUEDATE, dateadd(dd,SC.COLINTEGER,O.ITEMDATE)), getdate())) < 0 
						 				THEN 0
						 				ELSE isnull((datediff(dd,isnull(O.ITEMDUEDATE, dateadd(dd,SC.COLINTEGER,O.ITEMDATE)), getdate())),0)
					    				   END)
						     ELSE 0
			    	      		END)/sum(CASE WHEN O.LOCALBALANCE > 0 THEN O.LOCALBALANCE ELSE 0 END) 	
				  END) 			  	
			END		as 'DaysBeyondTerms', 
			sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) <  @nAge0 and O.ITEMTYPE <> 523) 		      THEN O.LOCALBALANCE ELSE 0 END) 
					as 'Bracket0Total',
			sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1 and O.ITEMTYPE <> 523) THEN O.LOCALBALANCE ELSE 0 END) 
					as 'Bracket1Total',
			sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1 and O.ITEMTYPE <> 523) THEN O.LOCALBALANCE ELSE 0 END) 
					as 'Bracket2Total',
			sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) >= @nAge2 and O.ITEMTYPE <> 523) 		      THEN O.LOCALBALANCE ELSE 0 END) 
					as 'Bracket3Total',
			sum(CASE WHEN(O.ITEMTYPE <> 523) THEN O.LOCALBALANCE ELSE 0 END)						
					as 'Total',
			abs(sum(CASE WHEN(O.ITEMTYPE = 523) THEN O.LOCALBALANCE ELSE 0 END))
					as 'Prepayments'	
			from ASSOCIATEDNAME AN
			join OPENITEM O			on (O.ACCTDEBTORNO=AN.NAMENO)
			left join SITECONTROL SC	on (SC.CONTROLID = 'Trading Terms') 	
			where AN.RELATEDNAME = @pnNameKey
			and AN.RELATIONSHIP = 'RES'
			and O.STATUS<>0
			and O.ITEMDATE<=getdate()
			and O.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112)
			group by SC.COLINTEGER"	
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameKey			int,
							  @pnUserIdentityId		int,
							  @nAge0			smallint,
							  @nAge1			smallint,
							  @nAge2			smallint,
							  @dtBaseDate			datetime,
							  @nReceivableAverageValue	decimal(11,2)',
							  @pnNameKey			= @pnNameKey,
							  @pnUserIdentityId		= @pnUserIdentityId,
							  @nAge0         		= @nAge0,
							  @nAge1         		= @nAge1,
							  @nAge2         		= @nAge2,
							  @dtBaseDate			= @dtBaseDate,
							  @nReceivableAverageValue	= @nReceivableAverageValue
		End	
		
		-- ReceivableByCurrency result set
		If (exists(select * from @tblResultsRequired where ResultSet in ('ReceivableByCurrency'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin		
			Set @sSQLString = "
			Select
			@pnNameKey	as 'NameKey', 
			ISNULL(O.CURRENCY, @sLocalCurrencyCode)
					as 'RowKey',	
			ISNULL(O.CURRENCY, @sLocalCurrencyCode)
					as 'CurrencyCode',
			sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) <  @nAge0 and O.ITEMTYPE <> 523) 		      THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END) 
					as 'Bracket0Total',
			sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge0 and @nAge1-1 and O.ITEMTYPE <> 523) THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END) 
					as 'Bracket1Total',
			sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) between @nAge1 and @nAge2-1 and O.ITEMTYPE <> 523) THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END) 
					as 'Bracket2Total',
			sum(CASE WHEN(datediff(day,O.ITEMDATE,@dtBaseDate) >= @nAge2 and O.ITEMTYPE <> 523) 		      THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END) 
					as 'Bracket3Total',		
			sum(CASE WHEN(O.ITEMTYPE <> 523) THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE 0 END)	
					as 'Total',
			abs(sum(CASE WHEN(O.ITEMTYPE = 523) THEN coalesce(O.FOREIGNBALANCE, O.LOCALBALANCE,0) ELSE 0 END))
					as 'Prepayments'
			from ASSOCIATEDNAME AN
			join OPENITEM O	on (O.ACCTDEBTORNO=AN.NAMENO)
			where AN.RELATEDNAME = @pnNameKey
			and AN.RELATIONSHIP = 'RES'
			and O.STATUS<>0
			and O.ITEMDATE<=getdate()
			and O.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112)
			group by ISNULL(O.CURRENCY, @sLocalCurrencyCode)"	
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameKey		int,
							  @pnUserIdentityId	int,
							  @nAge0		smallint,
							  @nAge1		smallint,
							  @nAge2		smallint,
							  @dtBaseDate		datetime,
							  @sLocalCurrencyCode	nvarchar(3)',
							  @pnNameKey		= @pnNameKey,
							  @pnUserIdentityId	= @pnUserIdentityId,
							  @nAge0         	= @nAge0,
							  @nAge1         	= @nAge1,
							  @nAge2         	= @nAge2,
							  @dtBaseDate		= @dtBaseDate,
							  @sLocalCurrencyCode	= @sLocalCurrencyCode
		End	
	End
	-- If Receivable Items topic is not available then return empty result set:
	Else If @nErrorCode=0
	Begin
		-- Populating ReceivableTotal Result Set
		If (exists(select * from @tblResultsRequired where ResultSet in ('ReceivableTotal'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin	
			Select
			null 	as 'RowKey',
			null	as 'NameKey',
			null	as 'DaysOutstanding',
			null	as 'DaysBeyondTerms', 
			null	as 'Bracket0Total',
			null	as 'Bracket1Total',
			null	as 'Bracket2Total',
			null	as 'Bracket3Total',
			null	as 'Total',
			null	as 'Prepayments'	
			where 1=2		
		End	
			
		-- ReceivableByCurrency result set
		If (exists(select * from @tblResultsRequired where ResultSet in ('ReceivableByCurrency'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin	
			Select
			null 	as 'RowKey',
			null	as 'NameKey',
			null	as 'CurrencyCode',
			null	as 'Bracket0Total',
			null	as 'Bracket1Total',
			null	as 'Bracket2Total',
			null	as 'Bracket3Total',		
			null	as 'Total',
			null	as 'Prepayments'
			where 1=2
		End
	End
End

-- WIPTotal result set
If (exists(select * from @tblResultsRequired where ResultSet in ('WIPTotal','WIPByCurrency'))
or @psResultsRequired is null)
and @nErrorCode = 0
Begin
	-- Check whether the WIP Items information is available:
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		select @bIsWIPAvailable = IsAvailable
		from	dbo.fn_GetTopicSecurity(null, 120, default, @dtToday)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int,
						  @bIsWIPAvailable	bit			OUTPUT,
						  @dtToday		datetime',
						  @pnUserIdentityId	= @pnUserIdentityId,
						  @bIsWIPAvailable	= @bIsWIPAvailable 	OUTPUT,
						  @dtToday		= @dtToday
	End

	-- The result set should only be published if the Work In Progress Items information security topic (120) 
	-- is available.
	If @nErrorCode=0
	and @bIsWIPAvailable = 1
	Begin	
		-- Average value added to WIP per day is to be calculated for WIP of the Name posted over 
		-- the last year)/days in last year.
		Set @sSQLString = "
		Select @nWIPAverageValue	    = SUM(ISNULL(WH.LOCALTRANSVALUE,0))/datediff(dd,dateadd(yy,-1,getdate()),getdate()),
		       @nWIPDisbursemenAverageValue = SUM(CASE WHEN WT.CATEGORYCODE = 'PD' 
							       THEN ISNULL(WH.LOCALTRANSVALUE,0)
							       ELSE 0
							  END)/datediff(dd,dateadd(yy,-1,getdate()),getdate())		       		
		from WORKHISTORY WH	
		join WIPTEMPLATE WIP	on (WIP.WIPCODE = WH.WIPCODE)	
		join WIPTYPE WT	on (WT.WIPTYPEID = WIP.WIPTYPEID)" 					
		
		If @psNameTypeKey is null
		Begin
			Set @sSQLString = @sSQLString   + char(10) + "where WH.EMPLOYEENO = @pnNameKey"
									
		End
		Else
		Begin
			Set @sSQLString = @sSQLString   + char(10) + "join CASENAME CN	on (CN.CASEID = WH.CASEID"
							+ char(10) + "and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"
							+ char(10) + "where CN.NAMENO = @pnNameKey"
							+ char(10) + "and   CN.NAMETYPE = @psNameTypeKey"
		End
	
		Set @sSQLString = @sSQLString   + char(10) + "and  WH.MOVEMENTCLASS = 1"
						+ char(10) + "and   WH.STATUS <> 0"	
						+ char(10) + "and   WH.POSTDATE between  dateadd(yy,-1,getdate()) and getdate()" 	
	
		
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nWIPAverageValue		decimal(11,2)			OUTPUT,
						  @nWIPDisbursemenAverageValue	decimal(11,2)			OUTPUT,
						  @pnNameKey			int,
						  @psNameTypeKey		nvarchar(3)',
						  @nWIPAverageValue		= @nWIPAverageValue		OUTPUT,
						  @nWIPDisbursemenAverageValue	= @nWIPDisbursemenAverageValue	OUTPUT,
						  @pnNameKey			= @pnNameKey,
						  @psNameTypeKey		= @psNameTypeKey
		
		If (exists(select * from @tblResultsRequired where ResultSet in ('WIPTotal'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin	
			Set @sSQLString = "
			Select
			@pnNameKey as NameKey,
			@sLocalCurrencyCode as RowKey,
			CASE WHEN @nWIPAverageValue = 0 
			     -- Avoid 'divide by zero' exception and set DaysWIPOutstanding
			     -- to null.
			     THEN null 
			     ELSE convert(int,SUM(ISNULL(W.BALANCE,0))/@nWIPAverageValue)
			END		as 'DaysWIPOutstanding',
			convert(int, CASE WHEN @nWIPDisbursemenAverageValue = 0 
			     	          -- Avoid 'divide by zero' exception and set @nWIPDisbursemenAverageValue to null.
			     		  THEN null
			     		  ELSE SUM(CASE WHEN WT.CATEGORYCODE = 'PD' 
							THEN ISNULL(W.BALANCE,0) 
							ELSE 0 
						   END)/@nWIPDisbursemenAverageValue
				     END)
					as 'DaysDisbursementOutstanding',	
			SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) <  @nAge0) 		         THEN ISNULL(W.BALANCE,0) ELSE 0 END)
					as Bracket0Total,
			SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN ISNULL(W.BALANCE,0) ELSE 0 END)
					as Bracket1Total,
			SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN ISNULL(W.BALANCE,0) ELSE 0 END)
					as Bracket2Total,
			SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) >= @nAge2) 		         THEN ISNULL(W.BALANCE,0) ELSE 0 END)
					as Bracket3Total,
			SUM(ISNULL(W.BALANCE,0))
				 	as Total						
			from WORKINPROGRESS W
			join WIPTEMPLATE WIP	on (WIP.WIPCODE = W.WIPCODE)
			join WIPTYPE WT		on (WT.WIPTYPEID = WIP.WIPTYPEID)" 	
			
			If @psNameTypeKey is null
			Begin
				Set @sSQLString = @sSQLString   + char(10) + "where W.EMPLOYEENO = @pnNameKey"
										
			End
			Else
			Begin
				Set @sSQLString = @sSQLString   + char(10) + "join CASENAME CN	on (CN.CASEID = W.CASEID"
								+ char(10) + "and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"
								+ char(10) + "where CN.NAMENO = @pnNameKey"
								+ char(10) + "and   CN.NAMETYPE = @psNameTypeKey"
			End
		
			Set @sSQLString = @sSQLString + char(10) + 	
			"and W.STATUS <> 0
			and  W.TRANSDATE <= getdate()"		
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameKey			int,
							  @pnUserIdentityId		int,
							  @psNameTypeKey		nvarchar(3),
							  @dtBaseDate			datetime,
							  @nAge0			smallint,
							  @nAge1			smallint,
							  @nAge2			smallint,
							  @nWIPAverageValue		decimal(11,2),
							  @nWIPDisbursemenAverageValue	decimal(11,2),	
							 @sLocalCurrencyCode	nvarchar(3)',
							  @pnNameKey			= @pnNameKey,
							  @pnUserIdentityId		= @pnUserIdentityId,
							  @psNameTypeKey		= @psNameTypeKey,
						          @dtBaseDate			= @dtBaseDate,
							  @nAge0			= @nAge0,
							  @nAge1			= @nAge1,
							  @nAge2			= @nAge2,
							  @nWIPAverageValue		= @nWIPAverageValue,
							  @nWIPDisbursemenAverageValue	= @nWIPDisbursemenAverageValue,
							@sLocalCurrencyCode	= @sLocalCurrencyCode
		End
	
	
		-- WIPByCurrency result set
		If (exists(select * from @tblResultsRequired where ResultSet in ('WIPByCurrency'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin	
			Set @sSQLString = "
			Select
			@pnNameKey as NameKey,
			ISNULL(W.FOREIGNCURRENCY, @sLocalCurrencyCode)	
					as RowKey,
			ISNULL(W.FOREIGNCURRENCY, @sLocalCurrencyCode)	
					as CurrencyCode,
			SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) <  @nAge0) 		         THEN coalesce(W.FOREIGNBALANCE, W.BALANCE,0) ELSE 0 END)
					as Bracket0Total,
			SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN coalesce(W.FOREIGNBALANCE, W.BALANCE,0) ELSE 0 END)
					as Bracket1Total,
			SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN coalesce(W.FOREIGNBALANCE, W.BALANCE,0) ELSE 0 END)
					as Bracket2Total,
			SUM(CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) >= @nAge2) 		         THEN coalesce(W.FOREIGNBALANCE, W.BALANCE,0) ELSE 0 END)
					as Bracket3Total,
			SUM(coalesce(W.FOREIGNBALANCE, W.BALANCE,0))
				 	as Total						
			from WORKINPROGRESS W"
			
			If @psNameTypeKey is null
			Begin
				Set @sSQLString = @sSQLString + char(10) + "where W.EMPLOYEENO = @pnNameKey"		
			End
			Else
			Begin
				Set @sSQLString = @sSQLString + char(10) + 
				"join CASENAME CN	on (CN.CASEID = W.CASEID
							and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
				where CN.NAMENO = @pnNameKey
				and   CN.NAMETYPE = @psNameTypeKey"
			End
		
			Set @sSQLString = @sSQLString + char(10) + "		
			and W.STATUS <> 0
			and W.TRANSDATE <= getdate()
			group by ISNULL(W.FOREIGNCURRENCY, @sLocalCurrencyCode)"		
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameKey		int,
							  @pnUserIdentityId	int,
							  @psNameTypeKey	nvarchar(3),
							  @dtBaseDate		datetime,
							  @nAge0		smallint,
							  @nAge1		smallint,
							  @nAge2		smallint,
							  @sLocalCurrencyCode	nvarchar(3)',
							  @pnNameKey		= @pnNameKey,
							  @pnUserIdentityId	= @pnUserIdentityId,
							  @psNameTypeKey	= @psNameTypeKey,
						          @dtBaseDate		= @dtBaseDate,
							  @nAge0		= @nAge0,
							  @nAge1		= @nAge1,
							  @nAge2		= @nAge2,
							  @sLocalCurrencyCode	= @sLocalCurrencyCode
		End	
	End
	Else If @nErrorCode = 0
	Begin
		If (exists(select * from @tblResultsRequired where ResultSet in ('WIPTotal'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin	
			Select
			null	as 'RowKey',
			null 	as 'NameKey',
			null	as 'DaysWIPOutstanding',
			null	as 'DaysDisbursementOutstanding',	
			null	as 'Bracket0Total',
			null	as 'Bracket1Total',
			null	as 'Bracket2Total',
			null	as 'Bracket3Total',
			null 	as 'Total'						
			where 1=2	
		End
	
		-- WIPByCurrency result set
		If (exists(select * from @tblResultsRequired where ResultSet in ('WIPByCurrency'))
		or @psResultsRequired is null
		and @nErrorCode = 0)
		Begin	
			Select
			null 	as 'RowKey',
			null	as 'NameKey',
			null	as 'CurrencyCode',
			null	as 'Bracket0Total',
			null	as 'Bracket1Total',
			null	as 'Bracket2Total',
			null 	as 'Total'						
			where 1=2		
		End
	End
End

If (exists(select * from @tblResultsRequired where ResultSet in ('DueDates'))
or @psResultsRequired is null)
and @nErrorCode = 0
Begin
	Set @sSQLString="
	Select
		@pnNameKey as NameKey,
		  I.IMPORTANCELEVEL	as 'RowKey', 
		  I.IMPORTANCELEVEL	as 'ImportanceLevelKey', 
		"+dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ImportanceLevelDescription',
		SUM(CASE WHEN CE.EVENTDUEDATE <= getdate() THEN 1 ELSE 0 END)
					as 'OverdueCount',
		SUM(CASE WHEN CE.EVENTDUEDATE between getdate()                                 and dateadd(dd, @pnDueDateDays0, getdate()) THEN 1 ELSE 0 END)
					as 'Bracket0Count',
		SUM(CASE WHEN CE.EVENTDUEDATE between dateadd(dd, @pnDueDateDays0+1, getdate()) and dateadd(dd, @pnDueDateDays1, getdate()) THEN 1 ELSE 0 END)
					as 'Bracket1Count',
		SUM(CASE WHEN CE.EVENTDUEDATE between dateadd(dd, @pnDueDateDays1+1, getdate()) and dateadd(dd, @pnDueDateDays2, getdate()) THEN 1 ELSE 0 END)
					as 'Bracket2Count'
	from CASENAME CN
	join CASEEVENT CE	on (CE.CASEID = CN.CASEID
				and CE.OCCURREDFLAG = 0)
	left join EVENTCONTROL EC	
				on (EC.EVENTNO   =CE.EVENTNO
				and EC.CRITERIANO=CE.CREATEDBYCRITERIA)
	join EVENTS E		on (E.EVENTNO    =CE.EVENTNO)
	join IMPORTANCE I	on (I.IMPORTANCELEVEL = isnull(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL))
	left join SITECONTROL SC on (SC.CONTROLID='Main Renewal Action')

	where CN.NAMENO = @pnNameKey
	and   CN.NAMETYPE = @psNameTypeKey
	and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())	
	
	and exists
	(select 1 from OPENACTION OA
	 join EVENTCONTROL ECX on (ECX.CRITERIANO=OA.CRITERIANO
			       and ECX.EVENTNO   =CE.EVENTNO)
	 join ACTIONS A        on (A.ACTION=OA.ACTION)
	 where OA.CASEID=CN.CASEID
	 and   OA.POLICEEVENTS=1 
	 and   OA.ACTION<>'~2'
	 and ((OA.ACTION=SC.COLCHARACTER AND EC.EVENTNO=-11) OR EC.EVENTNO<>-11 OR SC.COLCHARACTER is null)
	 and   OA.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN CE.CYCLE ELSE 1 END)

	group by "+dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)+", I.IMPORTANCELEVEL
	order by I.IMPORTANCELEVEL desc"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @psNameTypeKey	nvarchar(3),
					  @pnDueDateDays0	smallint,
					  @pnDueDateDays1	smallint,
					  @pnDueDateDays2	smallint',
					  @pnNameKey		= @pnNameKey,
					  @psNameTypeKey	= @psNameTypeKey,
					  @pnDueDateDays0	= @pnDueDateDays0,
					  @pnDueDateDays1	= @pnDueDateDays1,
					  @pnDueDateDays2	= @pnDueDateDays2
End

Return @nErrorCode
GO

Grant execute on dbo.na_ListStaffPerformance to public
GO
