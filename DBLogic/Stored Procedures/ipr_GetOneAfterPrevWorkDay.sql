-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_GetOneAfterPrevWorkDay
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_GetOneAfterPrevWorkDay]') 
				and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_GetOneAfterPrevWorkDay.'
	drop procedure dbo.ipr_GetOneAfterPrevWorkDay
end
print '**** Creating procedure dbo.ipr_GetOneAfterPrevWorkDay...'
print ''
go

Create proc dbo.ipr_GetOneAfterPrevWorkDay
	@pdtStartDate		datetime,
	@pbCalledFromCentura	bit		= 1,
	@pdtResultDate		datetime	= null output
	
as
-- AUTHOR:	Michael Fleming 
-- VERSION :	7
-- DESCRIPTION: Related to Reminders Mod 5861
--		Have a date range on Reminders window default to the system date in the To Date field
--		and one day after the previous working day in the From Date.
-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07/10/2003	AB		1	Add user dbo. to create procedure	
-- 11/08/2004	TM	1320	2	Add @pbCalledFromCentura and @pdtResultDate optional parameters.
--					If @pbCalledFromCentura is set to 0 then do not select @pdtStartDate
--					and set @pdtResultDate. 
-- 08 Dec 2008	MF	17158	3	Strip out time component from @pdtStartDate.
-- 11 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Apr 2009	MF	17158	5	Revisit to cater for databases that do not have Sunday marked as the first day of week
-- 05 Jul 2013	vql	R13629	6	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	7   Date conversion errors when creating cases and opening names in Chinese DB
	
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
		set @pdtStartDate=dateadd(dd,-1,@pdtStartDate)

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
			on 	(S.CONTROLID='HOMECOUNTRY')
		left join HOLIDAYS H 
			on 	(	H.COUNTRYCODE=C.COUNTRYCODE 
				and 	datepart(year,  H.HOLIDAYDATE)= datepart(year, @pdtStartDate )
				and	datepart(month,  H.HOLIDAYDATE)= datepart(month, @pdtStartDate )
				and	datepart(day,  H.HOLIDAYDATE)= datepart(day, @pdtStartDate ))
		where C.COUNTRYCODE = S.COLCHARACTER
	end
	select @pdtStartDate = dateadd(day,1,@pdtStartDate)
	
	If @pbCalledFromCentura = 1	
	Begin
		Select @pdtStartDate
	End
	Else If @pbCalledFromCentura = 0
	Begin
		Set @pdtResultDate = @pdtStartDate   
	End
go

grant execute on ipr_GetOneAfterPrevWorkDay to public
go
