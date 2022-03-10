-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_appsFilterEligibleCasesForComparison
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_appsGetActiveLoginSessions') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_appsGetActiveLoginSessions'
	Drop function [dbo].fn_appsGetActiveLoginSessions
End
Print '**** Creating Function dbo.fn_appsGetActiveLoginSessions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_appsGetActiveLoginSessions
(
	@pnIdentityId INT
) 
RETURNS NVARCHAR(4000)
AS
-- Function :	fn_appsGetActiveLoginSessions
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return critical mapped events given the data source required.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 NOV 2017	HM		1	Function created
-- 27 OCT 2020	SF		2	Function created

 BEGIN	
         DECLARE @openIds NVARCHAR(MAX);
         SET @openIds = '';
         SELECT @openIds = @openIds+CAST(LOGID AS NVARCHAR(MAX))+','
         FROM
         (
             SELECT TOP 20 u.LOGID
             FROM dbo.USERIDENTITYACCESSLOG u
             WHERE u.IDENTITYID = @pnIdentityId
                   AND u.LOGOUTTIME IS NULL
                   and [provider] <> 'Centura'
             ORDER BY u.LOGID DESC
         ) A;
         return @openIds;
     END;

GO

grant execute on dbo.fn_appsGetActiveLoginSessions to public
go
