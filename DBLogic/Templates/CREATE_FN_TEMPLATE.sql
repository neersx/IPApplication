-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_MyFunc
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_MyFunc') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_MyFunc'
	Drop function [dbo].[fn_MyFunc]
End
Print '**** Creating Function dbo.fn_MyFunc...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_MyFunc
(
	@pnInput	smallint
) 
RETURNS nvarchar(13)
AS
-- Function :	fn_MyFunc
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return dollar unit based on number enterred.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- dd MMM YYYY	AP	####	1	Function created

Begin
	declare @sResult nvarchar(13)
	set @sResult = N''

	if @pnInput = 2
		set @sResult = N' Thousand '
	else if @pnInput = 3
		set @sResult = N' Million '
	else if @pnInput = 4
		set @sResult = N' Billion '
	else if @pnInput = 5
		set @sResult = N' Trillion '
	else if @pnInput = 6
		set @sResult = N' Quadrillion '
		
	return @sResult
End
GO

grant execute on dbo.fn_MyFunc to public
go
