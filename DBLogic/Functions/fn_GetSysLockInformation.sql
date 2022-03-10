-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetSysLockInformation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_GetSysLockInformation') and xtype='TF')
Begin
	print '**** Drop function dbo.fn_GetSysLockInformation.'
	drop function dbo.fn_GetSysLockInformation
	print '**** Creating function dbo.fn_GetSysLockInformation...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[fn_GetSysLockInformation]()
RETURNS @tblSysLockInformation TABLE
(
	resource_type	nvarchar(120)
	, resource_associated_entity_id	bigint
	, request_session_id	int
)
-- Function :	fn_GetSysLockInformation 
-- VERSION :	1
-- DESCRIPTION:	Returns information about currently active lock manager resources in SQL Server.
--				Each row represents a currently active request to the lock manager for a lock that has been granted or is waiting to be granted.
--				This is a wrapper function to prevent direct access to sys.dm_tran_locks and returns only the required columns
-- MODIFICATIONS :
-- Date			Who	Change		Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Jan 2020	BS	DR-44505	1		Function created
AS
BEGIN
	INSERT INTO @tblSysLockInformation
	SELECT 		
		resource_type, resource_associated_entity_id, request_session_id
	FROM sys.dm_tran_locks WITH(NOLOCK);

	RETURN
END


GO

Grant SELECT on dbo.fn_GetSysLockInformation to public
GO
