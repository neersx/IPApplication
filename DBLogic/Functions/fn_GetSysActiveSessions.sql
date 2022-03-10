-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetSysActiveSessions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_GetSysActiveSessions') and xtype='TF')
Begin
	print '**** Drop function dbo.fn_GetSysActiveSessions.'
	drop function dbo.fn_GetSysActiveSessions
	print '**** Creating function dbo.fn_GetSysActiveSessions...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[fn_GetSysActiveSessions]()
RETURNS @tblSysActiveSessions TABLE
(
	session_id smallint
	, last_request_start_time	datetime
)
-- Function :	fn_GetSysActiveSessions 
-- VERSION :	1
-- DESCRIPTION:	Returns the session id and time at which the last request on the session began. This includes the currently executing request.
--				sys.dm_exec_sessions is a server-scope view that shows information about all active user connections and internal tasks. 
--				This function is a wrapper function to prevent direct access to sys.dm_exec_sessions.

-- MODIFICATIONS :
-- Date			Who	Change		Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 May 2020	BS	DR-53425	1		Function created
AS
BEGIN
	INSERT INTO @tblSysActiveSessions
	SELECT 		
		session_id, last_request_start_time
	FROM sys.dm_exec_sessions WITH(NOLOCK);

	RETURN
END


GO

Grant SELECT on dbo.fn_GetSysActiveSessions to public
GO
