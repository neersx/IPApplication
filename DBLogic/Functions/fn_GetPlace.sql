-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetPlace
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetPlace') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetPlace'
	Drop function [dbo].[fn_GetPlace]
	Print '**** Creating Function dbo.fn_GetPlace...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetPlace
(
	@pnInput smallint
) 
RETURNS nvarchar(13)
AS
-- Function :	fn_GetPlace
-- VERSION :	1.0.0
-- DESCRIPTION:	Return dollar unit based on number enterred.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 12/05/2003	SFOO	SQA8183		Function created
-- 
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

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_GetPlace to public
go
