-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceCalculateReminderDate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceCalculateReminderDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceCalculateReminderDate.'
	drop procedure dbo.ip_PoliceCalculateReminderDate
end
print '**** Creating procedure dbo.ip_PoliceCalculateReminderDate...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create  procedure dbo.ip_PoliceCalculateReminderDate 
			@pdtRunDate	datetime,
			@pnDebugFlag	tinyint
as
-- PROCEDURE :	ip_PoliceCalculateReminderDate
-- VERSION :	24
-- DESCRIPTION:	Calculate the next Reminder date greater than the current date for each Event that has not occurred
-- CALLED BY :	ipu_PoliceRecalc
-- PARAMETERS:	@pdtRunDate

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 9/01/2001	MF			Procedure created	 
-- 20/08/2001	MF			When calculating which Reminder to send the calculated reminder date should be less than or
--					equal to the Reminder Date policing is being run for.
-- 18/09/2001	MF	7060		The calculation of the next reminder date using the letters for the Event is
--					not always accurate.
-- 5/11/2001	MF	7146		Modify the algorithm that calculates the next reminder date.
-- 31/10/2001	MF	7161		When using the CREATEDBYCRITERIA to get the Reminders make sure that the
--					Action is Open for the Case.
-- 15/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles 
-- 3/01/2002	MF	7316		When determining the REMINDERTOSEND also consider the Stop Time.
-- 01/07/2002	MF	7773		If an ALERT has been defined for the CASEID, EVENTNO and CYCLE with the 
--					OVERRIDERULE flag set on then do not consider the Letter rules when 
--					calculating the next reminder date.
-- 29/04/2003	MF	8714		Where an Event has multiple reminders defined and only the last reminder 
--					has a Stop After Due Date the earlier reminders are incorrectly continuing 
--					to be sent even though the Stop After Due Date has been exceeded.
-- 02/05/2003	MF	8714		Revisit.  New code was allowing a Zero Divide error.
-- 28 Jul 2003	MF		10	Standardise version number
-- 01 Oct 2003	MF	9311	11	Only attempt to calculate reminder date if the EventDueDate exists.
-- 04 Nov 2004	MF	10619	12	When determining which RemindersToSend we need to exclude reminder rules
--					that have been stopped by a subsequent reminder.
-- 05 Jun 2005	MF	10720	13	Allow different units of time for frequency and stop time for Reminders.
-- 23 Jan 2006	MF	12223	14	Reminders are to be allowed to be calculated from any Action that the Event
--					is attached to and not restricted to the Criteria that had the due date
--					calculation.
-- 23 Feb 2006	MF	12316	15	If the Frequency of the Reminder is zero and the run date is after the
--					date that the reminder should have been generated then force a reminder
--					to be sent only if the EventDueDate has just changed.  This is to solve the 
--					problem where  Reminders continued to repeat indefinitely when
--					the Frequency was zero.
-- 07 Jun 2006	MF	12417	16	Change order of columns returned in debug mode to make it easier to review
-- 27 Jul 2006	MF	12747	17	SQLServer 2005 SQL Error - divide by zero.  Issue occurring because SQLServer
--					2005 appears to have resolved a bug that we were inadvertently exploiting. 
--					Cannot assume that a restriction in a JOIN (e.g. AND FREQUENCY>0) will 
--					stop other conditions within the same JOIN from being executed.
-- 21 May 2007		14775	18	Incorrect Next Police (DateRemind) being calculated when Lead Time Period is
--					years and frequency is months.
-- 29 May 2007	MF	14812	19	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	20	Reserve word [STATE]
-- 05 Jun 2012	MF	S19025	21	Dump out all columns in #TEMPCASEEVENT in debug mode. Also cater for RECALCEVENTDATE on #TEMPCASEEVENT.
-- 05 Jul 2013	vql	R13629	22	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 15 Mar 2017	MF	70049	23	Allow Renewal Status to be separately specified to be updated by an Event.
-- 14 Nov 2018  AV  75198/DR-45358	24   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on

-- Create a table into which a row for each CASEEVENT can be inserted with the calculate DATEREMIND
-- A separate table is required for this process because you cannot use an aggregate function in 
-- an UPDATE statement.

create table #TEMPREMINDERS 
		(	CASEID		int 	 not null,
			EVENTNO		int 	 not null,
			CYCLE		smallint not null,
			CALCDATEREMIND	datetime null
		)

DECLARE		@ErrorCode	int,
		@sSQLString	nvarchar(4000),
		@sSQLString1	nvarchar(4000),
		@sSQLString2	nvarchar(4000),	
		@sSQLString3	nvarchar(4000),	
		@sSQLString4	nvarchar(4000),	
		@sSQLString5	nvarchar(4000),	
		@sSQLString6	nvarchar(4000),	
		@sSQLString7	nvarchar(4000),	
		@sSQLString8	nvarchar(4000),	
		@sSQLString9	nvarchar(4000),	
		@sSQLString10	nvarchar(4000),	
		@sSQLString11	nvarchar(4000),	
		@sSQLString12	nvarchar(4000),	
		@sSQLString13	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- Find the appropriate REMINDER row for the Event to use in the following way :
-- 1)	Calculate the next Reminder date for each Reminder and choose the lowest date
-- 2) 	The next Reminder date is calculated as:
--	a) The Lead Time date if it is in the future; otherwise
-- 	b) Calculate the number of periods (days, months, weeks years) from the Lead Time Date until the current date.
-- 	c) Divide this number of periods by the FREQUENCY to get an integer result and increment the result by 1 under
--	   certain circumstances.
--  	d) Now multiply the FREQUENCY by the result from b) and add this to the Lead Time Date.
-- 	Note that if the calculated REMINDER date must not exceed the calculate Stop Time Date

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPREMINDERS (CASEID, EVENTNO, CYCLE, CALCDATEREMIND)
	select T.CASEID, T.EVENTNO, T.CYCLE,
	min(
	CASE WHEN (	CASE isnull(R.PERIODTYPE,'D')
				WHEN 'D' THEN dateadd (day,  -1 * isnull(R.LEADTIME,0), T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * isnull(R.LEADTIME,0), T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * isnull(R.LEADTIME,0), T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * isnull(R.LEADTIME,0), T.NEWEVENTDUEDATE)
		   	END ) > '"+convert(nvarchar,@pdtRunDate,112)+"'
									-- If the Lead Time date is in the 
									-- future then use it as the Reminder
									-- date
		THEN 	CASE isnull(R.PERIODTYPE,'D')
				WHEN 'D' THEN dateadd (day,  -1 * isnull(R.LEADTIME,0), T.NEWEVENTDUEDATE)
				WHEN 'W' THEN dateadd (week, -1 * isnull(R.LEADTIME,0), T.NEWEVENTDUEDATE)
				WHEN 'M' THEN dateadd (month,-1 * isnull(R.LEADTIME,0), T.NEWEVENTDUEDATE)
				WHEN 'Y' THEN dateadd (year, -1 * isnull(R.LEADTIME,0), T.NEWEVENTDUEDATE)
		   	END
			-- If the Lead Time is not in the future then the Reminder date will be
			-- calculated from the Lead Time date by using the Frequency to get a future date
		ELSE	CASE
			  ---------------------------------------------------
			  -- Lead Time in DAYS
			  ---------------------------------------------------
			  WHEN(R.PERIODTYPE='D' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='D')
			    THEN dateadd (day,  ((datediff (day,   dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R.FREQUENCY)   +1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)

			  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='W')
			    THEN dateadd (week, ((datediff (day,   dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))

			  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='M')
			    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
					THEN	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					ELSE	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
				 END

			  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='Y')
			    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
					THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
				 END"

	Set @sSQLString1="
			  ---------------------------------------------------
			  -- Lead Time in WEEKS
			  ---------------------------------------------------
			  -- Note that the DATEDIFF function is calculated in Days when the Period
		   	  -- Type is WEEK and then divided by an additional factor of 7 to bring it
			  -- back to a number of weeks.  This is to avoid the problems caused by the
			  -- way DATEDIFF considers a week as being a change from Saturday to
			  -- Sunday rather than a 7 day period.
			  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='D')
			    THEN dateadd (day,  ((datediff (day,   dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))

			  WHEN(R.PERIODTYPE='W' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='W')
			    THEN dateadd (week, ((datediff (day,   dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R.FREQUENCY*7))+1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)

			  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='M')
			    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
					THEN	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					ELSE	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
				 END

			  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='Y')
			    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
					THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
				 END"

	Set @sSQLString2="
			  ---------------------------------------------------
			  -- Lead Time in MONTHS
			  ---------------------------------------------------
			  -- When calculating the reminder date by incrementing in months or years we need
		  	  -- to check to see if the calculated date is in the future.  If not then increment it
			  -- by a further value of the Frequency
			  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='D')
			    THEN dateadd (day,  ((datediff (day,   dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))

			  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='W')
			    THEN dateadd (week, ((datediff (day,   dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))

			  WHEN(R.PERIODTYPE='M' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='M')
			    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >'"+convert(nvarchar,@pdtRunDate,112)+"'
					THEN	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
					ELSE	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
				 END

			  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='Y')
			    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
					THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
				 END"

	Set @sSQLString3="
			  ---------------------------------------------------
			  -- Lead Time in YEARS
			  ---------------------------------------------------
			  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='D')
			    THEN dateadd (day,  ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))

			  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='W')
			    THEN dateadd (week, ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))

			  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='M')
			    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
					THEN	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
					ELSE	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
				 END

			  WHEN(R.PERIODTYPE='Y' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='Y')
			    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >'"+convert(nvarchar,@pdtRunDate,112)+"'
					THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
					ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
				 END
			END
	END)"

	Set @sSQLString4="
	from	#TEMPOPENACTION OA
	join	EVENTCONTROL EC		on (EC.CRITERIANO=OA.NEWCRITERIANO)
	join	#TEMPCASEEVENT T	on (T.CASEID=OA.CASEID
					and T.EVENTNO=EC.EVENTNO)
	join 	REMINDERS R 
		on (R.CRITERIANO=OA.NEWCRITERIANO
		and R.EVENTNO   =T.EVENTNO
		and R.REMINDERNO in (	select R1.REMINDERNO
					from   REMINDERS R1
					where  R1.CRITERIANO=R.CRITERIANO
					and    R1.EVENTNO   =R.EVENTNO
					and   (R1.LETTERNO is NULL
					 or not exists (select * from ALERT A where A.CASEID=T.CASEID and A.EVENTNO=T.EVENTNO and A.CYCLE=T.CYCLE and A.OVERRIDERULE=1))
									-- the lead time must either be in the
									-- future or there must be a repeating
									-- frequency that the Stop time has
									-- not exceeded
					and    ('"+convert(nvarchar,@pdtRunDate)+"'  <CASE isnull(R1.PERIODTYPE,'D')
										WHEN 'D' THEN dateadd (day,  -1 * isnull(R1.LEADTIME,0), T.NEWEVENTDUEDATE)
										WHEN 'W' THEN dateadd (week, -1 * isnull(R1.LEADTIME,0), T.NEWEVENTDUEDATE)
										WHEN 'M' THEN dateadd (month,-1 * isnull(R1.LEADTIME,0), T.NEWEVENTDUEDATE)
										WHEN 'Y' THEN dateadd (year, -1 * isnull(R1.LEADTIME,0), T.NEWEVENTDUEDATE)
							     END"

	Set @sSQLString5="
						-- the Frequency must be > 0 and there must either be no stop time or the
						-- calculated stop time must be greater than or equal to the calculated date
					OR    (R1.FREQUENCY>0
					and    (R1.STOPTIME is NULL
					or	CASE isnull(R1.STOPTIMEPERIODTYPE,R1.PERIODTYPE	)
							WHEN 'D' THEN dateadd (day,  R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN 'W' THEN dateadd (week, R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN 'M' THEN dateadd (month,R1.STOPTIME, T.NEWEVENTDUEDATE)
							WHEN 'Y' THEN dateadd (year, R1.STOPTIME, T.NEWEVENTDUEDATE)
						END 
						>=
						CASE WHEN(R1.FREQUENCY>0) THEN
						 CASE
						  ---------------------------------------------------
						  -- Lead Time in DAYS
						  ---------------------------------------------------
						  WHEN(R1.PERIODTYPE='D' and isnull(R1.FREQPERIODTYPE,R1.PERIODTYPE)='D')
						    THEN dateadd (day,  ((datediff (day,   dateadd (day,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R1.FREQUENCY)   +1)*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
			
						  WHEN(R1.PERIODTYPE='D' and R1.FREQPERIODTYPE='W')
						    THEN dateadd (week, ((datediff (day,   dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R1.FREQUENCY*7))+1)*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R1.PERIODTYPE='D' and R1.FREQPERIODTYPE='M')
						    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							 END
			
						  WHEN(R1.PERIODTYPE='D' and R1.FREQPERIODTYPE='Y')
						    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (day, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							 END"

	Set @sSQLString6="
						  ---------------------------------------------------
						  -- Lead Time in WEEKS
						  ---------------------------------------------------
						  -- Note that the DATEDIFF function is calculated in Days when the Period
					   	  -- Type is WEEK and then divided by an additional factor of 7 to bring it
						  -- back to a number of weeks.  This is to avoid the problems caused by the
						  -- way DATEDIFF considers a week as being a change from Saturday to
						  -- Sunday rather than a 7 day period.
						  WHEN(R1.PERIODTYPE='W' and R1.FREQPERIODTYPE='D')
						    THEN dateadd (day,  ((datediff (day,   dateadd (week,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R1.FREQUENCY)   +1)*R1.FREQUENCY, dateadd (week,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R1.PERIODTYPE='W' and isnull(R1.FREQPERIODTYPE,R1.PERIODTYPE)='W')
						    THEN dateadd (week, ((datediff (day,   dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R1.FREQUENCY*7))+1)*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
			
						  WHEN(R1.PERIODTYPE='W' and R1.FREQPERIODTYPE='M')
						    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (week,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							 END
			
						  WHEN(R1.PERIODTYPE='W' and R1.FREQPERIODTYPE='Y')
						    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (week, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							 END"

	Set @sSQLString7="
						  ---------------------------------------------------
						  -- Lead Time in MONTHS
						  ---------------------------------------------------
						  -- When calculating the reminder date by incrementing in months or years we need
					  	  -- to check to see if the calculated date is in the future.  If not then increment it
						  -- by a further value of the Frequency
						  WHEN(R1.PERIODTYPE='M' and R1.FREQPERIODTYPE='D')
						    THEN dateadd (day,  ((datediff (day,   dateadd (month,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R1.FREQUENCY)   +1)*R1.FREQUENCY, dateadd (month,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R1.PERIODTYPE='M' and R1.FREQPERIODTYPE='W')
						    THEN dateadd (week, ((datediff (day,   dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R1.FREQUENCY*7))+1)*R1.FREQUENCY, dateadd (month,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R1.PERIODTYPE='M' and isnull(R1.FREQPERIODTYPE,R1.PERIODTYPE)='M')
						    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
								ELSE	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
							 END
			
						  WHEN(R1.PERIODTYPE='M' and R1.FREQPERIODTYPE='Y')
						    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (month, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							 END"

	Set @sSQLString8="
						  ---------------------------------------------------
						  -- Lead Time in YEARS
						  ---------------------------------------------------
						  WHEN(R1.PERIODTYPE='Y' and R1.FREQPERIODTYPE='D')
						    THEN dateadd (day,  ((datediff (day,   dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R1.FREQUENCY)   +1)*R1.FREQUENCY, dateadd (year,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R1.PERIODTYPE='Y' and R1.FREQPERIODTYPE='W')
						    THEN dateadd (week, ((datediff (day,   dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R1.FREQUENCY*7))+1)*R1.FREQUENCY, dateadd (year,  -1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R1.PERIODTYPE='Y' and R1.FREQPERIODTYPE='M')
						    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY, dateadd (year,-1 * R1.LEADTIME, T.NEWEVENTDUEDATE))
							 END
			
						  WHEN(R1.PERIODTYPE='Y' and isnull(R1.FREQPERIODTYPE,R1.PERIODTYPE)='Y')
						    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))   )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
								ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R1.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R1.FREQUENCY)))+1 )*R1.FREQUENCY-R1.LEADTIME, T.NEWEVENTDUEDATE)
							 END
						 END
						END)))))"

	Set @sSQLString9="
	-- SQA 8714 ensure there are no later Reminders that have already passed the Stop Time.
	left join REMINDERS R2	on (R2.CRITERIANO=R.CRITERIANO
				and R2.EVENTNO   =T.EVENTNO
				and R2.REMINDERNO>R.REMINDERNO
				and R2.STOPTIME is not null
				and R.FREQUENCY>0 -- Stoptime is only valid if the reminder is repeating.  This will avoid a zero divide error
				and CASE isnull(R2.STOPTIMEPERIODTYPE,R2.PERIODTYPE)
					WHEN 'D' THEN dateadd (day,  R2.STOPTIME, T.NEWEVENTDUEDATE)
					WHEN 'W' THEN dateadd (week, R2.STOPTIME, T.NEWEVENTDUEDATE)
					WHEN 'M' THEN dateadd (month,R2.STOPTIME, T.NEWEVENTDUEDATE)
					WHEN 'Y' THEN dateadd (year, R2.STOPTIME, T.NEWEVENTDUEDATE)
				    END  
					<
					CASE WHEN(R.FREQUENCY>0) THEN
					   CASE"

	Set @sSQLString10="
						  ---------------------------------------------------
						  -- Lead Time in DAYS
						  ---------------------------------------------------
						  WHEN(R.PERIODTYPE='D' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='D')
						    THEN dateadd (day,  ((datediff (day,   dateadd (day,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R.FREQUENCY)   +1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
			
						  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='W')
						    THEN dateadd (week, ((datediff (day,   dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='M')
						    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
							 END
			
						  WHEN(R.PERIODTYPE='D' and R.FREQPERIODTYPE='Y')
						    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (day, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
							 END"

	Set @sSQLString11="
						  ---------------------------------------------------
						  -- Lead Time in WEEKS
						  ---------------------------------------------------
						  -- Note that the DATEDIFF function is calculated in Days when the Period
					   	  -- Type is WEEK and then divided by an additional factor of 7 to bring it
						  -- back to a number of weeks.  This is to avoid the problems caused by the
						  -- way DATEDIFF considers a week as being a change from Saturday to
						  -- Sunday rather than a 7 day period.
						  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='D')
						    THEN dateadd (day,  ((datediff (day,   dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (week,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R.PERIODTYPE='W' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='W')
						    THEN dateadd (week, ((datediff (day,   dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R.FREQUENCY*7))+1)*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
			
						  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='M')
						    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
							 END
			
						  WHEN(R.PERIODTYPE='W' and R.FREQPERIODTYPE='Y')
						    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (week, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
							 END"

	Set @sSQLString12="
						  ---------------------------------------------------
						  -- Lead Time in MONTHS
						  ---------------------------------------------------
						  -- When calculating the reminder date by incrementing in months or years we need
					  	  -- to check to see if the calculated date is in the future.  If not then increment it
						  -- by a further value of the Frequency
						  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='D')
						    THEN dateadd (day,  ((datediff (day,   dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='W')
						    THEN dateadd (week, ((datediff (day,   dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (month,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R.PERIODTYPE='M' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='M')
						    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
								ELSE	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
							 END
			
						  WHEN(R.PERIODTYPE='M' and R.FREQPERIODTYPE='Y')
						    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (month, -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
							 END"

	Set @sSQLString13="
						  ---------------------------------------------------
						  -- Lead Time in YEARS
						  ---------------------------------------------------
						  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='D')
						    THEN dateadd (day,  ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R.FREQUENCY)   +1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='W')
						    THEN dateadd (week, ((datediff (day,   dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R.FREQUENCY*7))+1)*R.FREQUENCY, dateadd (year,  -1 * R.LEADTIME, T.NEWEVENTDUEDATE))
			
						  WHEN(R.PERIODTYPE='Y' and R.FREQPERIODTYPE='M')
						    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
								ELSE	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY, dateadd (year,-1 * R.LEADTIME, T.NEWEVENTDUEDATE))
							 END
			
						  WHEN(R.PERIODTYPE='Y' and isnull(R.FREQPERIODTYPE,R.PERIODTYPE)='Y')
						    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)) >'"+convert(nvarchar,@pdtRunDate,112)+"'
								THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))   )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
								ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R.FREQUENCY)))+1 )*R.FREQUENCY-R.LEADTIME, T.NEWEVENTDUEDATE)
							 END
					   END
					END)
	Where OA.POLICEEVENTS =1
	and T.[STATE]='R1'
	and T.NEWEVENTDUEDATE is not null 	-- 9311
	and R2.CRITERIANO is null 		-- 8714
	group by T.CASEID, T.EVENTNO, T.CYCLE"

	Exec (	@sSQLString + @sSQLString1 + @sSQLString2 + @sSQLString3 + @sSQLString4 + 
		@sSQLString5+ @sSQLString6 + @sSQLString7 + @sSQLString8 + @sSQLString9 + 
		@sSQLString10+@sSQLString11+ @sSQLString12+ @sSQLString13)
	
	Select @ErrorCode=@@Error
End

-- Update the TEMPCASEEVENT rows with the calculated next Reminder Date and also for rows that have not
-- had a previous reminder calculated what the last reminder that should have been sent is so that it can
-- be sent immediately.

If @ErrorCode=0
Begin
	Set @sSQLString="
	update	#TEMPCASEEVENT
	set
	NEWDATEREMIND=TR.CALCDATEREMIND,"+char(10)+
	-- If no reminders have been calculated previously for this CaseEvent then
	-- determine the reminder to generate
	"
	REMINDERTOSEND
	=	CASE WHEN(T.DATEREMIND is not null)
		THEN NULL
 		ELSE   (select max(R3.REMINDERNO)
			from   REMINDERS R3
			join	#TEMPOPENACTION OA
						on (OA.CASEID       =T.CASEID
						and(OA.CRITERIANO   =R3.CRITERIANO
						or  OA.NEWCRITERIANO=R3.CRITERIANO)
						and OA.POLICEEVENTS =1)
			left join REMINDERS R4	on (R4.CRITERIANO=R3.CRITERIANO
						and R4.EVENTNO   =R3.EVENTNO
						and R4.REMINDERNO>R3.REMINDERNO
						and R4.LETTERNO is null)
			where  R3.EVENTNO   =T.EVENTNO
			and    R3.LETTERNO  is null
			and   (R4.REMINDERNO is null
			 or    '"+convert(nvarchar,@pdtRunDate,112)+"' < CASE R4.PERIODTYPE
						  WHEN 'D' THEN dateadd (day,  -1 * R4.LEADTIME, T.NEWEVENTDUEDATE)
						  WHEN 'W' THEN dateadd (week, -1 * R4.LEADTIME, T.NEWEVENTDUEDATE)
						  WHEN 'M' THEN dateadd (month,-1 * R4.LEADTIME, T.NEWEVENTDUEDATE)
						  WHEN 'Y' THEN dateadd (year, -1 * R4.LEADTIME, T.NEWEVENTDUEDATE)
						END)
			and    '"+convert(nvarchar,@pdtRunDate,112)+"' >= CASE R3.PERIODTYPE
						  WHEN 'D' THEN dateadd (day,  -1 * R3.LEADTIME, T.NEWEVENTDUEDATE)
						  WHEN 'W' THEN dateadd (week, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE)
						  WHEN 'M' THEN dateadd (month,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE)
						  WHEN 'Y' THEN dateadd (year, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE)
						END"

	Set @sSQLString1="
			and  ((isnull(R3.FREQUENCY,0)=0 AND (T.NEWEVENTDUEDATE<>T.OLDEVENTDUEDATE OR T.OLDEVENTDUEDATE is null))
			-- the Frequency must be > 0 and there must either be no stop time
			-- or the calculated stop time must be greater than or equal to the calculated date
			 OR   (R3.FREQUENCY>0
			and    (R3.STOPTIME is NULL
			or	CASE isnull(R3.STOPTIMEPERIODTYPE, R3.PERIODTYPE)
					WHEN 'D' THEN dateadd (day,  R3.STOPTIME, T.NEWEVENTDUEDATE)
					WHEN 'W' THEN dateadd (week, R3.STOPTIME, T.NEWEVENTDUEDATE)
					WHEN 'M' THEN dateadd (month,R3.STOPTIME, T.NEWEVENTDUEDATE)
					WHEN 'Y' THEN dateadd (year, R3.STOPTIME, T.NEWEVENTDUEDATE)
				END
				>=
				CASE WHEN(R3.FREQUENCY>0) THEN
				 CASE
				  ---------------------------------------------------
				  -- Lead Time in DAYS
				  ---------------------------------------------------
				  WHEN(R3.PERIODTYPE='D' and isnull(R3.FREQPERIODTYPE,R3.PERIODTYPE)='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (day,  -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R3.FREQUENCY)   +1)*R3.FREQUENCY-R3.LEADTIME, T.NEWEVENTDUEDATE)
	
				  WHEN(R3.PERIODTYPE='D' and R3.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R3.FREQUENCY*7))+1)*R3.FREQUENCY, dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R3.PERIODTYPE='D' and R3.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (day,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))+1 )*R3.FREQUENCY, dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R3.PERIODTYPE='D' and R3.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))+1 )*R3.FREQUENCY, dateadd (day, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
					 END"

	Set @sSQLString2="
				  ---------------------------------------------------
				  -- Lead Time in WEEKS
				  ---------------------------------------------------
				  WHEN(R3.PERIODTYPE='W' and R3.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (week,  -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R3.FREQUENCY)   +1)*R3.FREQUENCY, dateadd (week,  -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R3.PERIODTYPE='W' and isnull(R3.FREQPERIODTYPE,R3.PERIODTYPE)='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (week, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R3.FREQUENCY*7))+1)*R3.FREQUENCY-R3.LEADTIME, T.NEWEVENTDUEDATE)
	
				  WHEN(R3.PERIODTYPE='W' and R3.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (week,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (week,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (week,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))+1 )*R3.FREQUENCY, dateadd (week,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R3.PERIODTYPE='W' and R3.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (week, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (week, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (week, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))+1 )*R3.FREQUENCY, dateadd (week, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
					 END"

	Set @sSQLString3="
				  ---------------------------------------------------
				  -- Lead Time in MONTHS
				  ---------------------------------------------------
				  WHEN(R3.PERIODTYPE='M' and R3.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (month,  -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R3.FREQUENCY)   +1)*R3.FREQUENCY, dateadd (month,  -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R3.PERIODTYPE='M' and R3.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (month, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R3.FREQUENCY*7))+1)*R3.FREQUENCY, dateadd (month,  -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R3.PERIODTYPE='M' and isnull(R3.FREQPERIODTYPE,R3.PERIODTYPE)='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY-R3.LEADTIME, T.NEWEVENTDUEDATE)) >'"+convert(nvarchar,@pdtRunDate,112)+"'
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY-R3.LEADTIME, T.NEWEVENTDUEDATE)
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (month,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))+1 )*R3.FREQUENCY-R3.LEADTIME, T.NEWEVENTDUEDATE)
					 END
	
				  WHEN(R3.PERIODTYPE='M' and R3.FREQPERIODTYPE='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (month, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (month, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (month, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))+1 )*R3.FREQUENCY, dateadd (month, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
					 END"

	Set @sSQLString4="
				  ---------------------------------------------------
				  -- Lead Time in YEARS
				  ---------------------------------------------------
				  WHEN(R3.PERIODTYPE='Y' and R3.FREQPERIODTYPE='D')
				    THEN dateadd (day,  ((datediff (day,   dateadd (year,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ R3.FREQUENCY)   +1)*R3.FREQUENCY, dateadd (year,  -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R3.PERIODTYPE='Y' and R3.FREQPERIODTYPE='W')
				    THEN dateadd (week, ((datediff (day,   dateadd (year,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/(R3.FREQUENCY*7))+1)*R3.FREQUENCY, dateadd (year,  -1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
	
				  WHEN(R3.PERIODTYPE='Y' and R3.FREQPERIODTYPE='M')
				    THEN CASE WHEN (	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (year,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE))) >'"+convert(nvarchar,@pdtRunDate,112)+"'
						THEN	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY, dateadd (year,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
						ELSE	dateadd (month,((ceiling(datediff (month, dateadd (year,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))+1 )*R3.FREQUENCY, dateadd (year,-1 * R3.LEADTIME, T.NEWEVENTDUEDATE))
					 END
	
				  WHEN(R3.PERIODTYPE='Y' and isnull(R3.FREQPERIODTYPE,R3.PERIODTYPE)='Y')
				    THEN CASE WHEN (	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY-R3.LEADTIME, T.NEWEVENTDUEDATE)) >'"+convert(nvarchar,@pdtRunDate,112)+"'
						THEN	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))   )*R3.FREQUENCY-R3.LEADTIME, T.NEWEVENTDUEDATE)
						ELSE	dateadd (year, ((ceiling(datediff (year,  dateadd (year, -1 * R3.LEADTIME, T.NEWEVENTDUEDATE),'"+convert(nvarchar,@pdtRunDate,112)+"')/ convert(decimal(5,1),R3.FREQUENCY)))+1 )*R3.FREQUENCY-R3.LEADTIME, T.NEWEVENTDUEDATE)
					 END
				 END
				END))))
		END
	from #TEMPCASEEVENT T
	left join #TEMPREMINDERS TR on (TR.CASEID =T.CASEID
				and TR.EVENTNO=T.EVENTNO
				and TR.CYCLE  =T.CYCLE)
	Where T.[STATE]='R1'"

	Exec (@sSQLString + @sSQLString1 + @sSQLString2 + @sSQLString3 + @sSQLString4)
End


If  @pnDebugFlag>0
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceCalculateReminderDate',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*
		from	#TEMPCASEEVENT T
		where	T.[STATE]<>'X'
		order by 4,1,2,3"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
End

drop table #TEMPREMINDERS

return @ErrorCode
go

grant execute on dbo.ip_PoliceCalculateReminderDate to public
go
