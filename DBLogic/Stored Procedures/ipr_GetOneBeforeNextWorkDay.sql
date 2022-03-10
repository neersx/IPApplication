-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_GetOneBeforeNextWorkDay
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_GetOneBeforeNextWorkDay]') 
				and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_GetOneBeforeNextWorkDay.'
	drop procedure dbo.ipr_GetOneBeforeNextWorkDay
end
print '**** Creating procedure dbo.ipr_GetOneBeforeNextWorkDay...'
print ''
go

Create proc dbo.ipr_GetOneBeforeNextWorkDay
	@pdtStartDate		datetime,
	@pbCalledFromCentura	bit		= 1,
	@pdtResultDate		datetime	= null output
	
as
-- AUTHOR:	Michael Fleming 
-- VERSION :	4
-- DESCRIPTION: Related to Reminders Mod 5861
--		Have a date range on Reminders window default to the system date in the To Date field
--		and one day after the previous working day in the From Date.
-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 08 Dec 2008	MF	17158	1	Procedure created. Copied from ipr_GetOneAfterPrevWorkDay
-- 07 Apr 2009	MF	17158	2	Revisit to cater for databases that do not have Sunday marked as the first day of week
-- 05 Jul 2013	vql	R13629	3	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	4   Date conversion errors when creating cases and opening names in Chinese DB
	
	---------------------------------------------
	-- Set the first day of week to be Sunday
	-- Required to determine what days have been
	-- flagged as working days for the home
	-- country.
	---------------------------------------------
	If @@DATEFIRST<>7
		Set DATEFIRST 7

	declare	@nWorkDay 	INT
 
	-- Strip out the time component of
	-- the datetime
	if @pdtStartDate is null
		set @pdtStartDate=convert(nvarchar,getdate(),112)
	Else
		set @pdtStartDate=convert(nvarchar,@pdtStartDate,112)

	set @nWorkDay=0

	while (@nWorkDay=0)
	begin
		set @pdtStartDate=dateadd(dd,+1,@pdtStartDate)

		select 	@nWorkDay=
		case when H.HOLIDAYDATE is not NULL 
			then 0
			else 	case (datepart(weekday,@pdtStartDate))
				when 7 	
					then 
						case when (isnull(WORKDAYFLAG,124)&1=1) 
						  then 1 
						  else 0 
						end 
					else 	case when (isnull(WORKDAYFLAG,124)&power(2,datepart(weekday,@pdtStartDate))=
								power(2,datepart(weekday,@pdtStartDate))) 
						  then 1 
						  else 0 
						end
				end 
		end
		from COUNTRY C
		join SITECONTROL S 
			on 	(upper(S.CONTROLID)='HOMECOUNTRY')
		left join HOLIDAYS H 
			on 	(	H.COUNTRYCODE=C.COUNTRYCODE 
				and 	datepart(year,  H.HOLIDAYDATE)= datepart(year, @pdtStartDate )
				and	datepart(month,  H.HOLIDAYDATE)= datepart(month, @pdtStartDate )
				and	datepart(day,  H.HOLIDAYDATE)= datepart(day, @pdtStartDate ))
		where C.COUNTRYCODE = S.COLCHARACTER
	end

	set @pdtStartDate = dateadd(day,-1,@pdtStartDate)
	
	If @pbCalledFromCentura = 1	
	Begin
		Select @pdtStartDate
	End
	Else If @pbCalledFromCentura = 0
	Begin
		Set @pdtResultDate = @pdtStartDate   
	End
go

grant execute on ipr_GetOneBeforeNextWorkDay to public
go
