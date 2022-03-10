-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_GetQuantity
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_GetQuantity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	 print '**** Drop procedure dbo.pt_GetQuantity.'
	 drop procedure dbo.pt_GetQuantity
end
print '**** Creating procedure dbo.pt_GetQuantity...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create proc dbo.pt_GetQuantity 
			@pnParameterSource	smallint, 
			@pnARQuantity		int		=0, 
			@pnCaseId		int, 
			@pnNoInSeries		smallint	=0, 
			@pnNoOfClasses		smallint	=0,
			@pnCycle		smallint	=null, 
			@pnEventNo		int		=null, 
			@pdtFromDate		datetime	=null,
			@pdtUntilDate		datetime	=null,
			@prnQuantity		int 			output,
			@prsPeriodType		nchar(1)	=null	output,
			@prnPeriodCount		int		=0	output,
			@prnUnitCount		int		=0	output,
			@pbCalledFromCentura	tinyint  = 0			
as

-- PROCEDURE :	pt_GetQuantity
-- VERSION :	26
-- DESCRIPTION:	Gets the quantity from predefined locations for use in fee calculations
-- CALLED BY :	pt_DoCalculation
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26/02/2002	MF			Procedure Created
-- 28/02/2002	SS	7628		Added new Else If statement to retrieve Last Updated Renewal Cycle (6)
-- 13/12/2002	SS	7504		Added new Else If statements to retrieve no. of designated countries pending (7),
--					no. of designated countries registered (8) & no. of designated countries pending & registered (9).
-- 11/12/2005	AT	10442		Added new Else If statement to retrieve the number of International Classes for a case (10).
-- 08 Mar 2006	MF	11943	5	New Source of Quantity options have been provided
-- 07 Jul 2006	MF	12973	6	Syntax error correction when getting entered period of time for an event
-- 25 Jul 2006	MF	13076	7	Allow additional ParameterSource to calculate period between Event dates.
-- 28 Sep 2006	MF	13523	8	Where the source of quantity includes two different parameters (e.g. Months and
--					number of Classes) we need to multiply the parameters rather than add them as
--					this gives the desired result.
-- 03 Nov 2006	MF	13076	9	Revisit to allow additional source of quantities that calculate period between dates.
-- 09 Nov 2006	MF	13076	10	Remove debug code.
-- 01 Dec 2006	MF	12361	11	For simulated charge calculations allow the FromDate and UntilDate to be
--					passed for calculations requiring the period of time between two dates.
-- 15 May 2007	MF	14726	12	When calculating period between two dates use the @pdtUntilDate passed as a
--					parameter if no date is found for the second event.
-- 30 Jul 2007	MF	15081	13	Allow @pnARQuantity to process values greater than the smallint limit by
--					changing to an INT.
-- 10 Aug 2007	MF	15103	14	Simulated charge calculations will have an option to pass the value to be
--					used as a quantity when no Case is available.
-- 15 Dec 2008	MF	17136	15	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 23 Aug 2010	MF	R9707	16	Incorrect fee calculated where deadline date (FromDate) is later than Until Date.
-- 09 May 2012	MF	R12281	17	When calculating difference between dates take into consideration if the Event is cyclic or not and use
--					Cycle=1 for non cyclic Events.
-- 27 Aug 2012	MF	R12656	18	Further to RFC12281, if the quantity is being determined by the difference between 2 dates then do not allow the
--					the second date to be overridden by @pdtUntilDate if the EventNo is -11 (Next Renewal Date).  This is because in this
--					situation a simulated set of dates does not make logical sense.  This is not an ideal solution to have -11 hardcoded. A 
--					better solution for the future might be to allow a flag to indicates if simulated dates are allowed or not.
-- 12 Dec 2012	MF	S21097	19	Use Quantity from screen if there are no events for fee calculation. This will handle those fee calculations for 
--					a simulated Case rather than an actual Case.
-- 20 Dec 2012	MF	S21099	20	Add new Quantity Source for - International classes + Designated Countries pending/registered (value 26).
-- 08 Jan 2013	MF	S21099	21	Add new Quantity Source for - (International classes - 1) * Designated Countries pending/registered (value 27).
-- 15 Jan 2013	DL	S21160	22	Add param @pbCalledFromCentura to enable call from Centura
-- 27 Feb 2015	MF	R32785	23	Rework S21099, International classes-1 x Designated Countries pending/registered correction.
-- 05 Mar 2015	MF	R45354	24	When determining a count of designated countries, consider the actual status of the related case if it is available to
--					determine if it is registered/pending. If there is no related case then use status of the designated country.
-- 18 Mar 2016	MF	R59349	25	Add new Quantity Source for - Number of classes x Period between dates (value 28)
-- 27 Mar 2019	MF	DR-47445 26	When the quantity is supplied (@pnARQuantity<>0) and the Parameter Source does not require the supplied quantity to be
--					added to the calculated quantity, then use the supplied quantity instead of calculating it.

set nocount on

declare	@ErrorCode	int
declare @nDayCount	int
declare	@nFromEventNo		int
declare	@nUntilEventNo		int
declare	@nFromCyclesAllowed	smallint	
declare	@nUntilCyclesAllowed	smallint
declare	@nYears		smallint
declare	@nMonths	tinyint
declare	@nDays		tinyint

declare	@sFromControlAction	nvarchar(2)
declare	@sUntilControlAction	nvarchar(2)
declare @sDateDiff	varchar(24)
declare @sIntClasses	nvarchar(254)
declare @sSQLString	nvarchar(4000)

Set	@ErrorCode=0

--  1 - Quantity from Checklist
If (@pnParameterSource is null) OR (@pnParameterSource = 0) OR (@pnParameterSource = 1) 
OR (@pnParameterSource not in (11,12,13,14,15,16,17) and @pnARQuantity<>0)
	Set @prnQuantity = coalesce(@pnARQuantity,0)
--  2 - Number in Series for the Case
Else If (@pnParameterSource in (2, 17, 25))
	Set @prnQuantity = coalesce(@pnNoInSeries,@pnARQuantity,0)
--  3 - Number of local Classes
Else If (@pnParameterSource in (3, 11, 19, 28))
	Set @prnQuantity = coalesce(@pnNoOfClasses,@pnARQuantity,0)
--  4 - Number of Claims
Else If (@pnParameterSource in (4, 13, 21))
	Begin
		If @pnCaseId is null
			set @prnQuantity=@pnARQuantity
		Else
			Set @sSQLString="
			SELECT @prnQuantity=coalesce(NOOFCLAIMS,0)
			FROM PROPERTY
			WHERE CASEID = @pnCaseId"
	End
--  5 - Entered period of time for a particular Event
Else If (@pnParameterSource = 5) AND (@pnEventNo is not null) AND (@pnCycle is not null)
	Begin
		If @pnCaseId is null
			set @prnQuantity=@pnARQuantity
		Else
			Set @sSQLString="
			SELECT @prnQuantity=coalesce(ENTEREDDEADLINE,0)
			FROM CASEEVENT
			WHERE CASEID = @pnCaseId
			AND EVENTNO = @pnEventNo
			AND CYCLE = @pnCycle"
	End
--  6 - Highest Renewal Cycle where Renewal Date has occurred
Else If (@pnParameterSource = 6)
	Begin
		If @pnCaseId is null
			set @prnQuantity=@pnARQuantity
		Else
			Set @sSQLString="
			SELECT @prnQuantity=coalesce(MAX(CYCLE),0)
			FROM CASEEVENT
			WHERE CASEID = @pnCaseId
			AND EVENTNO = -11
			AND EVENTDATE IS NOT NULL"
	End
--  7 - Number of Designated Countries that are Pending
Else If (@pnParameterSource in (7, 14, 22))
	Begin
		If @pnCaseId is null
			set @prnQuantity=@pnARQuantity
		Else
			Set @sSQLString="
			SELECT @prnQuantity=coalesce(COUNT(DISTINCT R.COUNTRYCODE),0)
			FROM CASES C
			JOIN RELATEDCASE R	on (R.CASEID=C.CASEID
						and R.RELATIONSHIP='DC1')
			JOIN COUNTRYFLAGS CF 	on (CF.COUNTRYCODE = C.COUNTRYCODE
						and CF.FLAGNUMBER  = R.CURRENTSTATUS)
			LEFT JOIN CASES C1	on (C1.CASEID=R.RELATEDCASEID)
			LEFT JOIN STATUS S	on (S.STATUSCODE=C1.STATUSCODE)
			WHERE C.CASEID = @pnCaseId
			and((S.LIVEFLAG=1 and S.REGISTEREDFLAG=0) OR (C1.CASEID is NULL and CF.STATUS=1))"
	End
--  8 - Number of Designated Countries that are Registered
Else If (@pnParameterSource in (8, 15, 23))
	Begin
		If @pnCaseId is null
			set @prnQuantity=@pnARQuantity
		Else
			Set @sSQLString="
			SELECT @prnQuantity=coalesce(COUNT(DISTINCT R.COUNTRYCODE),0)
			FROM CASES C
			JOIN RELATEDCASE R	on (R.CASEID=C.CASEID
						and R.RELATIONSHIP='DC1')
			JOIN COUNTRYFLAGS CF 	on (CF.COUNTRYCODE = C.COUNTRYCODE
						and CF.FLAGNUMBER  = R.CURRENTSTATUS)
			LEFT JOIN CASES C1	on (C1.CASEID=R.RELATEDCASEID)
			LEFT JOIN STATUS S	on (S.STATUSCODE=C1.STATUSCODE)
			WHERE C.CASEID = @pnCaseId
			and((S.LIVEFLAG=1 and S.REGISTEREDFLAG=1) OR (C1.CASEID is NULL and CF.STATUS=2))"
	End
--  9 - Number of Designated Countries that are either Registered or Pending
Else If (@pnParameterSource in (9, 16, 24))
	Begin
		If @pnCaseId is null
			set @prnQuantity=@pnARQuantity
		Else
			Set @sSQLString="
			SELECT @prnQuantity=coalesce(COUNT(DISTINCT R.COUNTRYCODE),0)
			FROM CASES C
			JOIN RELATEDCASE R	on (R.CASEID=C.CASEID
						and R.RELATIONSHIP='DC1')
			JOIN COUNTRYFLAGS CF 	on (CF.COUNTRYCODE = C.COUNTRYCODE
						and CF.FLAGNUMBER  = R.CURRENTSTATUS)
			LEFT JOIN CASES C1	on (C1.CASEID=R.RELATEDCASEID)
			LEFT JOIN STATUS S	on (S.STATUSCODE=C1.STATUSCODE)
			WHERE C.CASEID = @pnCaseId
			and(S.LIVEFLAG=1 OR (C1.CASEID is NULL and CF.STATUS in (1,2)))"
	End
-- 10 - Number of International Classes for a Case
Else If (@pnParameterSource in (10,12,20))
	Begin
		If @pnCaseId is null
			set @prnQuantity=@pnARQuantity
		Else Begin
			Set @sSQLString="
			Declare @sIntClasses 	nvarchar(254)
			Select @sIntClasses=INTCLASSES from CASES where CASEID = @pnCaseId
			Select @prnQuantity=count(*) from dbo.fn_Tokenise(@sIntClasses, ',')"
		End
	End
-- 11 - Number of Designated Countries that are either Registered or Pending
--    + Number of International Classes for a Case
Else If (@pnParameterSource in (26))
	Begin
		If @pnCaseId is null
			set @prnQuantity=@pnARQuantity
		Else
			Set @sSQLString="
			Declare @sIntClasses 	nvarchar(254)
			Select @sIntClasses=INTCLASSES from CASES where CASEID = @pnCaseId
			Select @prnQuantity=count(*) from dbo.fn_Tokenise(@sIntClasses, ',')
			
			SELECT @prnQuantity=@prnQuantity + coalesce(COUNT(DISTINCT R.COUNTRYCODE),0)
			FROM CASES C
			JOIN RELATEDCASE R	on (R.CASEID=C.CASEID
						and R.RELATIONSHIP='DC1')
			JOIN COUNTRYFLAGS CF 	on (CF.COUNTRYCODE = C.COUNTRYCODE
						and CF.FLAGNUMBER  = R.CURRENTSTATUS
					     	and CF.STATUS in (1,2))
			WHERE C.CASEID = @pnCaseId"
	End
		
-- 12 - (Number of Intl Classes for a Case - 1) * Number of Designated Countries
Else If (@pnParameterSource in (27))
	Begin
		If @pnCaseId is null
			set @prnQuantity=@pnARQuantity
		Else
			Set @sSQLString="
			Declare @sIntClasses 	nvarchar(254)
			Select @sIntClasses=INTCLASSES from CASES where CASEID = @pnCaseId
			Select @prnQuantity=count(*) from dbo.fn_Tokenise(@sIntClasses, ',')
			
			IF @prnQuantity > 0
				Set @prnQuantity=@prnQuantity-1
			
			SELECT @prnQuantity=@prnQuantity * coalesce(COUNT(DISTINCT R.COUNTRYCODE),0)
			FROM CASES C
			JOIN RELATEDCASE R	on (R.CASEID=C.CASEID
						and R.RELATIONSHIP='DC1')
			JOIN COUNTRYFLAGS CF 	on (CF.COUNTRYCODE = C.COUNTRYCODE
						and CF.FLAGNUMBER  = R.CURRENTSTATUS
					     	and CF.STATUS in (1,2))
			WHERE C.CASEID = @pnCaseId"
	End	
		
-- Now execute the constructed SQL
If @sSQLString is not null
begin
	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@prnQuantity		int	output,
				  @pnCaseId		int,
				  @pnEventNo		int,
				  @pnCycle		int',
				  @prnQuantity=@prnQuantity	output,
				  @pnCaseId   =@pnCaseId,
				  @pnEventNo  =@pnEventNo,
				  @pnCycle    =@pnCycle
End

-- Check to see if the ParameterSource requires the period of time
-- between two events to be calculated.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	@prsPeriodType =PERIODTYPE
	From QUANTITYSOURCE
	Where QUANTITYSOURCEID=@pnParameterSource"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@prsPeriodType		nchar(1)	OUTPUT,
				  @pnParameterSource	smallint',
				  @prsPeriodType		=@prsPeriodType	OUTPUT,
				  @pnParameterSource	=@pnParameterSource
End

If @ErrorCode=0
Begin
	-- Add the Checklist Quantity to the quantity already extracted
	-- for the following ParameterSource values
	If (@pnParameterSource in (11, 12, 13, 14, 15, 16, 17))
	Begin
		Set @prnQuantity=coalesce(@prnQuantity,0)+coalesce(@pnARQuantity,0)
	End

	-- The period of time between two dates is to be calculated
	Else If @prsPeriodType is not null
	Begin
		Set @sSQLString="
		select  @nFromEventNo       =E1.EVENTNO,
			@nUntilEventNo      =E2.EVENTNO,
			@nFromCyclesAllowed =E1.NUMCYCLESALLOWED,
			@nUntilCyclesAllowed=E2.NUMCYCLESALLOWED,
			@sFromControlAction =E1.CONTROLLINGACTION,
			@sUntilControlAction=E2.CONTROLLINGACTION
		from QUANTITYSOURCE Q
		join EVENTS E1 on (E1.EVENTNO=Q.FROMEVENTNO)
		join EVENTS E2 on (E2.EVENTNO=Q.UNTILEVENTNO)
		where Q.QUANTITYSOURCEID=@pnParameterSource"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nFromEventNo		int			OUTPUT,
					  @nUntilEventNo	int			OUTPUT,
					  @nFromCyclesAllowed	smallint		OUTPUT,
					  @nUntilCyclesAllowed	smallint		OUTPUT,
					  @sFromControlAction	nvarchar(2)		OUTPUT,
					  @sUntilControlAction	nvarchar(2)		OUTPUT,
					  @pnParameterSource	smallint',
					  @nFromEventNo		=@nFromEventNo		OUTPUT,
					  @nUntilEventNo	=@nUntilEventNo		OUTPUT,
					  @nFromCyclesAllowed	=@nFromCyclesAllowed	OUTPUT,
					  @nUntilCyclesAllowed	=@nUntilCyclesAllowed	OUTPUT,
					  @sFromControlAction	=@sFromControlAction	OUTPUT,
					  @sUntilControlAction	=@sUntilControlAction	OUTPUT,
					  @pnParameterSource	=@pnParameterSource

		If @ErrorCode=0
		Begin
		If @pdtFromDate >= @pdtUntilDate	--RFC9707 Greater Than or Equal To replaced Equal
			and @nUntilEventNo<>-11
		Begin
			Set @sDateDiff='+0000-00-00 00:00:00.000'
			Set @nDayCount=0
		End
		Else If @pdtFromDate < @pdtUntilDate
			     and @nUntilEventNo<>-11
		Begin
			Set @sDateDiff=dbo.fn_DateDiff(@pdtFromDate,@pdtUntilDate)
			Set @nDayCount=DATEDIFF(Day,@pdtFromDate,@pdtUntilDate)
		End
			Else If @pnCaseId is not null
			Begin

			Set @sSQLString="
			Select	@sDateDiff=dbo.fn_DateDiff(coalesce(CE1.EVENTDATE, CE1.EVENTDUEDATE),coalesce(CE2.EVENTDATE, CE2.EVENTDUEDATE,@pdtUntilDate)),
				@nDayCount=   DATEDIFF(Day,coalesce(CE1.EVENTDATE, CE1.EVENTDUEDATE),coalesce(CE2.EVENTDATE, CE2.EVENTDUEDATE,@pdtUntilDate))
			from QUANTITYSOURCE Q
			left join SITECONTROL S	on (S.CONTROLID='Main Renewal Action') -- Renewal action is used as default if no controlling action
			-- get the lowest open action cycle associated with the FromEvent
			left join OPENACTION OA1 on OA1.CASEID=@pnCaseId
							and OA1.ACTION=isnull(@sFromControlAction,S.COLCHARACTER)
						and OA1.CYCLE=(	select min(OA3.CYCLE)
								from OPENACTION OA3
								where OA3.CASEID=OA1.CASEID
								and OA3.ACTION=OA1.ACTION
								and OA3.POLICEEVENTS=1)
			-- get the lowest open action cycle associated with the UntilEvent
			left join OPENACTION OA2 on OA2.CASEID=@pnCaseId
							and OA2.ACTION=isnull(@sUntilControlAction,S.COLCHARACTER)
						and OA2.CYCLE=(	select min(OA4.CYCLE)
								from OPENACTION OA4
								where OA4.CASEID=OA2.CASEID
								and OA4.ACTION=OA2.ACTION
								and OA4.POLICEEVENTS=1)
			join CASEEVENT CE1	on (CE1.CASEID=@pnCaseId
							and CE1.EVENTNO=@nFromEventNo
							and CE1.CYCLE=CASE WHEN(@nFromCyclesAllowed=1) THEN 1 ELSE coalesce(@pnCycle, OA1.CYCLE) END)
			left join CASEEVENT CE2	on (CE2.CASEID=@pnCaseId
							and CE2.EVENTNO=@nUntilEventNo
							and CE2.CYCLE=CASE WHEN(@nUntilCyclesAllowed=1) THEN 1 ELSE coalesce(@pnCycle, OA2.CYCLE) END)
			where Q.QUANTITYSOURCEID=@pnParameterSource
			and coalesce(CE1.EVENTDATE, CE1.EVENTDUEDATE)<coalesce(CE2.EVENTDATE, CE2.EVENTDUEDATE,@pdtUntilDate)"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sDateDiff		varchar(24)	OUTPUT,
						  @nDayCount		int		OUTPUT,
						  @pnParameterSource	smallint,
						  @pnCaseId		int,
						  @pnCycle		smallint,
							  @pdtUntilDate		datetime,
							  @nFromEventNo		int,
							  @nUntilEventNo	int,
							  @nFromCyclesAllowed	smallint,
							  @nUntilCyclesAllowed	smallint,
							  @sFromControlAction	nvarchar(2),
							  @sUntilControlAction	nvarchar(2)',
						  @sDateDiff		=@sDateDiff	OUTPUT,
						  @nDayCount		=@nDayCount	OUTPUT,
						  @pnParameterSource	=@pnParameterSource,
						  @pnCaseId		=@pnCaseId,
						  @pnCycle		=@pnCycle,
							  @pdtUntilDate		=@pdtUntilDate,
							  @nFromEventNo		=@nFromEventNo,
							  @nUntilEventNo	=@nUntilEventNo,
							  @nFromCyclesAllowed	=@nFromCyclesAllowed,
							  @nUntilCyclesAllowed	=@nUntilCyclesAllowed,
							  @sFromControlAction	=@sFromControlAction,
							  @sUntilControlAction	=@sUntilControlAction
			End
		End

		-- Split up the returned DateDiff value into its components
		If  @ErrorCode=0
		and @sDateDiff   is not null
		and @prsPeriodType is not null
		Begin
			Set @nYears =convert(smallint, substring(@sDateDiff,2,4))
			Set @nMonths=convert(tinyint,  substring(@sDateDiff,7,2))
			Set @nDays  =convert(tinyint,  substring(@sDateDiff,10,2))

			If @prsPeriodType='Y'
			Begin
				Set @prnPeriodCount=@nYears
				-- A partial year should increment the year count by 1
				If @nMonths>0
				or @nDays  >0
					Set @prnPeriodCount=@prnPeriodCount+1
			End
			Else If @prsPeriodType='M'
			Begin
				Set @prnPeriodCount=(@nYears*12)+@nMonths
				-- A partial month should increment the month count by 1
				If @nDays  >0
					Set @prnPeriodCount=@prnPeriodCount+1
			End
			Else If @prsPeriodType='D'
			Begin
				Set @prnPeriodCount=@nDayCount
			End
		End

		-- This is used as a multiplying factor so it needs to default
		-- to 1 to ensure it has no impact if there is no actual value.
		Set @prnUnitCount=1

		-- Combination of Period with another quantity
		If @pnParameterSource in (19,20,21,22,23,24,25,28)
		Begin
			-- When the quantity is null or zero then set it to 1 so as not to corrupt
			-- the period of time calculated.
			Set @prnUnitCount=CASE WHEN(coalesce(@prnQuantity,0)=0) THEN 1 ELSE @prnQuantity END
			Set @prnQuantity =@prnUnitCount*coalesce(@prnPeriodCount,0)
		End
		Else Begin
			-- Allow for simulated situations where there is 
			-- no Case.  Just use the passed in quantity.
			If @pnCaseId is null
				Set @prnQuantity=@pnARQuantity
			Else
			Set @prnQuantity=coalesce(@prnPeriodCount,0)
		End

	End
End

-- If called from Centurea select this parameter to make it available to Centura calls
if @pbCalledFromCentura = 1
	Select @prnQuantity

Return @ErrorCode
go

grant execute on dbo.pt_GetQuantity to public
go
