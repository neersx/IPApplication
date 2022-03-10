-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetWorkDays
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetWorkDays') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetWorkDays'
	Drop function [dbo].[fn_GetWorkDays]
End
Print '**** Creating Function dbo.fn_GetWorkDays...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetWorkDays
(
	@pdtFromDate	datetime, 
	@pdtToDate	datetime
) 
RETURNS nvarchar(13)
AS
-- Function :	fn_GetWorkDays
-- VERSION :	1
-- DESCRIPTION:	Returns the number of working days for the calculated Date Range.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Feb 2004	TM	RFC834	1	Function created

Begin
	Declare @nTotalDays	int
	Declare @nWorkDays	int
	Declare @nWeeks		smallint
	Declare	@nExcessDays	tinyint
	Declare @nFirstDay	tinyint
	Declare	@nLastDay	tinyint


	Select	@nTotalDays=datediff(day,@pdtFromDate, @pdtToDate)+1,
		@nFirstDay=	CASE datename(weekday, @pdtFromDate)
					WHEN('Monday')    THEN 6
					WHEN('Tuesday')   THEN 5
					WHEN('Wednesday') THEN 4
					WHEN('Thursday')  THEN 3
					WHEN('Friday')    THEN 2
					WHEN('Saturday')  THEN 1
					WHEN('Sunday')    THEN 0
				END,
		@nLastDay=	CASE datename(weekday, @pdtToDate)
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
		
	RETURN @nWorkDays
End
GO

grant execute on dbo.fn_GetWorkDays to public
go
