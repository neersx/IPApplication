-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetUser
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetUser') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetUser'
	Drop function [dbo].[fn_GetUser]
End
Print '**** Creating Function dbo.fn_GetUser...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetUser()
RETURNS nvarchar(30)
AS
-- Function :	fn_GetUser
-- VERSION :	1
-- DESCRIPTION:	Returns the USERID of the current user

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 NOV 2003	CR	8816	1.00	Function created

Begin
	declare @sResult nvarchar(30)
	SELECT @sResult = SUBSTRING (SYSTEM_USER, CHARINDEX ( N'\' , SYSTEM_USER ) + 1,30)
		
	return @sResult
End
GO

grant execute on dbo.fn_GetUser to public
go
