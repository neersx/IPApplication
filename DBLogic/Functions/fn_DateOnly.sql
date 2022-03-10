-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_DateOnly
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_DateOnly]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_DateOnly.'
	drop function [dbo].[fn_DateOnly]
	print '**** Creating Function dbo.fn_DateOnly...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_DateOnly
	(	
		@pdDateToConvert	datetime
	)
Returns datetime

-- FUNCTION :	fn_DateOnly
-- VERSION :	6
-- DESCRIPTION:	Returns the date without any time stamp (i.e. 0:00.000)

-- Date		MODIFICTION HISTORY
-- ====         ===================
--13/07/2002	JB	Function created

as
Begin
	Declare @sDate nvarchar(30)
	Declare @dDateOnly datetime
	Set @sDate = convert(nvarchar(30), @pdDateToConvert, 101)
	Set @dDateOnly = convert(datetime, @sDate, 101)

	Return @dDateOnly
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_DateOnly to public
GO
