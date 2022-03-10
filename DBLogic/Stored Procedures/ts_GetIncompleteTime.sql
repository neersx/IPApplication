-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_GetIncompleteTime
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_GetIncompleteTime]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_GetIncompleteTime.'
	Drop procedure [dbo].[ts_GetIncompleteTime]
	Print '**** Creating Stored Procedure dbo.ts_GetIncompleteTime...'
	Print ''
End
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.ts_GetIncompleteTime
(
	@pnRowCount			int		= null	OUTPUT,
	@pnUserIdentityId		int	  	= null,
	@psCulture			nvarchar(10)	= null,
	@pnEmployeeNo			int		= null, 
	@pnFamilyNo			smallint	= null,
	@psProfitCentreCode		nvarchar(6)	= null,
	@pdtFromDate			datetime	= null,
	@pdtUntilDate			datetime	= null,
	@pnMinimumHours			decimal(7,3)	= null,
	@pnOrderBy			tinyint		= null	-- 1=Staff, Date; 2=Date, Staff; 3=Group, Staff, Date; 4=Profit Centre, Staff, Date
)

-- PROCEDURE :	ts_GetIncompleteTime
-- VERSION :	6
-- DESCRIPTION:	Returns a list of the Staff Members that have not posted time
--		totalling the standard hours during a particular date range.
-- NOTES:	

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 01 Sep 2003  MF		1	Procedure created
-- 04 Sep 2003	MF		2	Allow the Order By clause to be user defined.
-- 01 Oct 2003	MF	9319	3	If no FromDate passed as a parameter then set it to the first
--					of the current month if the current date is less than the 10th
--					otherwise set it to the first of the previous month.
-- 15 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Jul 2011	DL	RFC10830 5	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 02 Nov 2015	vql	R53910	6	Adjust formatted names logic (DR-15543).

AS

-- Settings

Set nocount on
Set concat_null_yields_null off

declare @tbWeekDays table (	Weekday		datetime	not null)

declare @tbResults  table (	Weekday		datetime	not null, 
				TotalHours	decimal(5,2)	not null, 
				StaffName	nvarchar(400)	collate database_default not null, 
				Entity		nvarchar(254)	collate database_default null, 
				NameGroup	nvarchar(50)	collate database_default null, 
				ProfitCentre	nvarchar(50)	collate database_default null
			)

Declare @ErrorCode 		int

Declare @sSQLString		nvarchar(4000)

Set @ErrorCode=0

-- Get the standard number of working hours.

If  @ErrorCode=0
and @pnMinimumHours is null
Begin
	Set @sSQLString="
	Select @pnMinimumHours=S.COLDECIMAL
	from SITECONTROL S
	where S.CONTROLID='Standard Daily Hours'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnMinimumHours	decimal(7,3)	OUTPUT',
				  @pnMinimumHours=@pnMinimumHours

	-- If there has been no definition of the Standard Hours
	-- then default to 8 hours.
	If @pnMinimumHours is null
		Set @pnMinimumHours=8
End


-- If no FromDate has been passed as a parameter then if the current Date of the month is less than the 10th
-- set the FromDate to the 1st day of the previous month otherwise set it to the 1st of the current month.
If  @ErrorCode=0
and @pdtFromDate is null
Begin
	If day(getdate())<10
		select @pdtFromDate=convert(varchar,month(dateadd(month,-1,getdate())))+'/01/'+convert(varchar,year(dateadd(month,-1,getdate())))
	Else
		select @pdtFromDate=convert(varchar,month(getdate()))+'/01/'+convert(varchar,year(getdate()))
End

-- If no UntilDate has been passed as a parameter then set it to the last date of the month used in the FromDate

If  @ErrorCode=0
and @pdtUntilDate is null
Begin
	select @pdtUntilDate=dateadd(day,-1,dateadd(month,1,@pdtFromDate))

	if @pdtUntilDate>getdate()
		select @pdtUntilDate=dateadd(day,-1,getdate())
End

-- Load the @tbWeekDays table variable with the valid
-- days of the week that have fallen within the period
-- to be tested

While @pdtFromDate<=@pdtUntilDate
and   @ErrorCode=0
Begin
	-- Only load the table variable if the day is a weekday
	If datepart(dw, @pdtFromDate) between 2 and 6
	Begin
		insert into @tbWeekDays(Weekday)
		select @pdtFromDate
	End

	-- Increment the date

	-- If the current day is Friday then increment by 3 days
	If datepart(dw, @pdtFromDate)=6	
		Select @pdtFromDate=dateadd(day, 3, @pdtFromDate)
	Else
	-- If the current day is Saturday then increment by 2 days
	If datepart(dw, @pdtFromDate)=7
		Select @pdtFromDate=dateadd(day, 2, @pdtFromDate)
	-- Otherwise increment by 1 day
	Else
		Select @pdtFromDate=dateadd(day, 1, @pdtFromDate)
	
End

If @ErrorCode=0
Begin
	-- Load the results into a table variable as an interim step because we need to dyamically
	-- control the ORDER BY and we cannot use dynamic SQL because of the @tbWeekDays table variable
	Insert into @tbResults(Weekday, TotalHours, StaffName, Entity, NameGroup, ProfitCentre)
	select 	WD.Weekday, 
		(select cast(isnull(sum(DATEPART(HOUR,isnull(D.TOTALTIME,0) )*60 
			              + DATEPART(MINUTE, isnull(D.TOTALTIME,0))
				      +DATEPART(HOUR,isnull(D.TIMECARRIEDFORWARD,0) )*60 
				      + DATEPART(MINUTE, isnull(D.TIMECARRIEDFORWARD,0))),0)/60.0 as decimal(5,2))
		 from DIARY D
		 where D.EMPLOYEENO=E.EMPLOYEENO
		 and D.TRANSNO is not null
		 and D.STARTTIME between WD.Weekday and dateadd(day,1,WD.Weekday)),
		dbo.fn_FormatNameUsingNameNo(N.NAMENO,NULL),
		EN.NAME,
		NF.FAMILYTITLE,
		P.DESCRIPTION
	from EMPLOYEE E
	cross join  @tbWeekDays WD
	      join NAME N		on (N.NAMENO=E.EMPLOYEENO)
	left  join NAMEFAMILY NF	on (NF.FAMILYNO=N.FAMILYNO)
	left  join PROFITCENTRE P	on (P.PROFITCENTRECODE=E.PROFITCENTRECODE)
	left  join NAME EN		on (EN.NAMENO=P.ENTITYNO)
	where E.STARTDATE<=@pdtUntilDate
	and isnull(E.ENDDATE,@pdtUntilDate)>=@pdtUntilDate
	and (E.EMPLOYEENO      =@pnEmployeeNo       OR @pnEmployeeNo       is null)
	and (E.PROFITCENTRECODE=@psProfitCentreCode OR @psProfitCentreCode is null)
	and (N.FAMILYNO        =@pnFamilyNo         OR @pnFamilyNo         is null)
	and (@pnMinimumHours*60)>
	(select isnull(sum(DATEPART(HOUR,isnull(D.TOTALTIME,0))*60          + DATEPART(MINUTE, isnull(D.TOTALTIME,0))
		          +DATEPART(HOUR,isnull(D.TIMECARRIEDFORWARD,0))*60 + DATEPART(MINUTE, isnull(D.TIMECARRIEDFORWARD,0))),0)
	 from DIARY D
	 where D.EMPLOYEENO=E.EMPLOYEENO
	 and D.TRANSNO   is not null
	 and D.STARTTIME between WD.Weekday and dateadd(day,1,WD.Weekday))

	Set @ErrorCode=@@Error
end

-- Return the result set with the sort dependant on the input parameter

If @ErrorCode=0
Begin
	If @pnOrderBy=2
		Select Weekday, TotalHours, StaffName, Entity, NameGroup, ProfitCentre
		from @tbResults
		order by Entity, Weekday, StaffName
	Else
	If @pnOrderBy=3
		Select Weekday, TotalHours, StaffName, Entity, NameGroup, ProfitCentre
		from @tbResults
		order by Entity, NameGroup, StaffName, Weekday
	Else
	If @pnOrderBy=4
		Select Weekday, TotalHours, StaffName, Entity, NameGroup, ProfitCentre
		from @tbResults
		order by Entity, ProfitCentre, StaffName, Weekday
	Else
		Select Weekday, TotalHours, StaffName, Entity, NameGroup, ProfitCentre
		from @tbResults
		order by Entity, StaffName, Weekday

	Select 	@ErrorCode=@@Error,
		@pnRowCount=@@Rowcount
End
	

Return @ErrorCode
go

grant execute on dbo.ts_GetIncompleteTime to public
go
