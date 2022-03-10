-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetNextGenerateDate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_GetNextGenerateDate]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_GetNextGenerateDate.'
	drop function [dbo].[fn_GetNextGenerateDate]
	print '**** Creating Function dbo.fn_GetNextGenerateDate...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetNextGenerateDate
	(	
		@pdDateToConvert	datetime,
		@pnDayOfMonth		int,
		@pnFrequency		tinyint
	)
Returns datetime

-- FUNCTION :	fn_GetNextGenerateDate
-- VERSION :	2
-- DESCRIPTION:	Calcuate the next generate date for document request based on the repeat frequency and start day
--
-- MODIFICATIONS :
-- Date		Who	SQA#		Version	Change
-- ------------	-------	--------	-------	----------------------------------------------- 
-- 13/08/2009	DL	SQA17939	1	Procedure created
-- 30/06/2010	DL	SQA17957	2	Fixed bug - Monthly frequency for document requests not working correctly if DAYOFMONTH is empty


as
Begin
	Declare @dNewDate		datetime,
		@nNewDay		int,
		@nLastDayOfMonth	int

	if @pnDayOfMonth is null or @pnDayOfMonth = 0
		set @pnDayOfMonth = day(@pdDateToConvert)

	Set @dNewDate = dateadd( month, isnull(@pnFrequency, 1), @pdDateToConvert)
	Set @nNewDay = Day(@dNewDate)
	set @nLastDayOfMonth = day(DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@dNewDate)+1,0)))

	if @pnDayOfMonth > @nLastDayOfMonth
		set @pnDayOfMonth = @nLastDayOfMonth

	-- Adjust the day to the match the @pnDayOfMonth but only if it is valid (<= last day of the month)
	Set @dNewDate = dateadd( day, @pnDayOfMonth - @nNewDay, @dNewDate)

	Return @dNewDate
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_GetNextGenerateDate to public
GO
