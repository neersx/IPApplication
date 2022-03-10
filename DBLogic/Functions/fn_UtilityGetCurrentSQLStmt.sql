-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_UtilityGetCurrentSQLStmt
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_UtilityGetCurrentSQLStmt]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_UtilityGetCurrentSQLStmt.'
	drop function [dbo].[fn_UtilityGetCurrentSQLStmt]
	print '**** Creating Function dbo.fn_UtilityGetCurrentSQLStmt...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_UtilityGetCurrentSQLStmt
	(	
		@nSQLHandle		binary,
		@nStart			int,
		@nEnd			int
	)
Returns varchar(8000)

-- FUNCTION :	fn_UtilityGetCurrentSQLStmt
-- VERSION :	1
-- DESCRIPTION:	Retrieve the currently executing statement.  This is useful
--		for finding code that is blocking other code.
-- ------------------------------------------------------------------------------------
-- EXAMPLE USE:
--		select p.spid,p.blocked,p.waittype,
--			p.waittime, p.lastwaittype,p.waitresource,
--			dbo.fn_UtilityGetCurrentSQLStmt(sql_handle,
--							stmt_start,
--							stmt_end) as sql_text,
--			p.cmd,p.status,p.cpu,p.physical_io,p.memusage,
--			p.login_time,p.last_batch,p.program_name
--		from master.dbo.sysprocesses as p
--		where p.spid>51
--		and p.dbid=db_id()
-- ------------------------------------------------------------------------------------
-- MODIFICTIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 9 Mar 2007	MF		1	Function created
as
Begin
	Return (
		Select coalesce(quotename(object_name(s.objectid)) + ':', '')
			+ cast(substring(s.text,
				(@nStart/2)+1,
				(((CASE WHEN(@nEnd=-1) THEN datalength(s.text) ELSE @nEnd END)	
					- @nStart)/2)+1) as varchar(8000))
		from  ::fn_get_sql(@nSQLHandle) as s )

End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_UtilityGetCurrentSQLStmt to public
GO
