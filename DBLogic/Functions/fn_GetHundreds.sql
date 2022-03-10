-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetHundreds
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetHundreds') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetHundreds'
	Drop function [dbo].[fn_GetHundreds]
	Print '**** Creating Function dbo.fn_GetHundreds...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetHundreds
(
	@psMyNumber nvarchar(3)
) 
RETURNS nvarchar(27)
AS
-- Function :	fn_GetHundreds
-- VERSION :	1.0.0
-- DESCRIPTION:	Convert the hundredth digit to the corresponding English word.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 12/05/2003	SFOO	SQA8183		Function created
-- 
Begin
	declare @sResult nvarchar(27)
	set @sResult = N''
	
	if CAST(@psMyNumber As smallint) = 0
		return N''

	set @psMyNumber = RIGHT(N'000' + @psMyNumber, 3)
	if SUBSTRING(@psMyNumber, 1, 1) != N'0'
		set @sResult = dbo.fn_GetDigit(SUBSTRING(@psMyNumber, 1, 1)) + N' Hundred '

 	if SUBSTRING(@psMyNumber, 2, 1) != N'0'
		set @sResult = @sResult + dbo.fn_GetTens(SUBSTRING(@psMyNumber, 2, 2))
	else
		set @sResult = @sResult + dbo.fn_GetDigit(SUBSTRING(@psMyNumber, 3, 1))
	
	return @sResult
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Grant execute on dbo.fn_GetHundreds to public 
go
