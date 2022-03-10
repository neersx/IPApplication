-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetDigit
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetDigit') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetDigit'
	Drop function [dbo].[fn_GetDigit]
	Print '**** Creating Function dbo.fn_GetDigit...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetDigit
(
	@psDigit char(1)
) 
RETURNS nvarchar(5)
AS
-- Function :	fn_GetDigit
-- VERSION :	1.0.0
-- DESCRIPTION:	Convert a digit to its corresponding English word.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 12/05/2003	SFOO	SQA8183		Function created
-- 
Begin
	Declare @sResult nvarchar(5)
	set @sResult = N''
	
	if @psDigit = '1'
		set @sResult = N'One'
	else if @psDigit = '2'
		set @sResult = N'Two'
	else if @psDigit = '3'
		set @sResult = N'Three'
	else if @psDigit = '4'
		set @sResult = N'Four'
	else if @psDigit = '5'
		set @sResult = N'Five'
	else if @psDigit = '6'
		set @sResult = N'Six'
	else if @psDigit = '7'
		set @sResult = N'Seven'
	else if @psDigit = '8'
		set @sResult = N'Eight'
	else if @psDigit = '9'
		set @sResult = N'Nine'
		
	return @sResult
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Grant execute on dbo.fn_GetDigit to public 
go
