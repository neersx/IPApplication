-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetActiveLoginSessions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetActiveLoginSessions') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetActiveLoginSessions'
	Drop function [dbo].[fn_GetActiveLoginSessions]
End
Print '**** Creating Function dbo.fn_GetActiveLoginSessions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetActiveLoginSessions
(
	@pnIdentityId int
) 
RETURNS NVARCHAR(4000)
AS
-- Function :	fn_GetActiveLoginSessions
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return dollar unit based on number enterred.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 NOV 2017	HM		1	Function created

Begin
	IF OBJECT_ID('fn_appsGetActiveLoginSessions') IS NOT NULL    
	    BEGIN        
                 RETURN dbo.fn_appsGetActiveLoginSessions(@pnIdentityId);
         END                   
              RETURN NULL;		
End
GO

grant execute on dbo.fn_GetActiveLoginSessions to public
go
