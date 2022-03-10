-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetSysProcesses
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_GetSysProcesses') and xtype='TF')
Begin
	print '**** Drop function dbo.fn_GetSysProcesses.'
	drop function dbo.fn_GetSysProcesses
	print '**** Creating function dbo.fn_GetSysProcesses...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[fn_GetSysProcesses]()
RETURNS @tblSysProcesses TABLE
(
	spid	smallint
	, context_info	binary(128)
	, login_time	datetime
)
-- Function :	fn_GetSysProcesses 
-- VERSION :	1
-- DESCRIPTION:	Returns information about processes that are running on an instance of SQL Server. 
--				These processes can be client processes or system processes.
--				This is a wrapper function to prevent direct access to master.dbo.sysprocesses and returns only the required columns
-- MODIFICATIONS :
-- Date			Who	Change		Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Jan 2020	BS	DR-44505	1		Function created
AS
BEGIN
	INSERT INTO @tblSysProcesses
 	SELECT 
		spid, context_info, login_time
	FROM master.dbo.sysprocesses WITH(NOLOCK);

	RETURN
END


GO

Grant SELECT on dbo.fn_GetSysProcesses to public
GO
