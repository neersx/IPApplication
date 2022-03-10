-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetTens
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetTens') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetTens'
	Drop function [dbo].[fn_GetTens]
	Print '**** Creating Function dbo.fn_GetTens...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetTens
(
	@psTensText nvarchar(2)
) 
RETURNS nvarchar(13)

As
-- Function :	fn_GetTens
-- VERSION :	1.0.0
-- DESCRIPTION:	Convert the tenth digit to the corresponding English word.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 12/05/2003	SFOO	SQA8183		Function created
-- 13/06/2003	CR	SQA8183		Changed wording a bit e.g. TEN to Ten
-- 
Begin
	declare @sResult nvarchar(20),
	        @sTempString char(1)
	set @sResult = N''	-- Initialise string variables b4 use
	set @sTempString = N''

	if LEFT(@psTensText, 1) = N'1'
	    begin
		if @psTensText = N'10'
			set @sResult = N'Ten'
		else if @psTensText = N'11'
			set @sResult = N'Eleven'
		else if @psTensText = N'12'
			set @sResult = N'Twelve'
		else if @psTensText = N'13'
			set @sResult = N'Thirteen'
		else if @psTensText = N'14'
			set @sResult = N'Fourteen'
		else if @psTensText = N'15'
			set @sResult = N'Fifteen'
		else if @psTensText = N'16'
			set @sResult = N'Sixteen'
		else if @psTensText = N'17'
			set @sResult = N'Seventeen'
		else if @psTensText = N'18'
			set @sResult = N'Eighteen'
		else if @psTensText = N'19'
			set @sResult = N'Nineteen'
	    end
	else
	    begin
		set @sTempString = LEFT(@psTensText, 1)
		if @sTempString = N'2'
			set @sResult = N'Twenty '
		if @sTempString = N'3'
			set @sResult = N'Thirty '
		if @sTempString = N'4'
			set @sResult = N'Forty '
		if @sTempString = N'5'
			set @sResult = N'Fifty '
		if @sTempString = N'6'
			set @sResult = N'Sixty '
		if @sTempString = N'7'
			set @sResult = N'Seventy '
		if @sTempString = N'8'
			set @sResult = N'Eighty '
		if @sTempString = N'9'
			set @sResult = N'Ninety '
		set @sResult = @sResult + dbo.fn_GetDigit(RIGHT(@psTensText, 1))
	    end	

	return @sResult
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_GetTens to public
go
