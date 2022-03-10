-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsAuditSchemaConsistent
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsAuditSchemaConsistent') and xtype='FN')
begin
	print '**** Drop function dbo.fn_IsAuditSchemaConsistent.'
	drop function dbo.fn_IsAuditSchemaConsistent
end
print '**** Creating function dbo.fn_IsAuditSchemaConsistent...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_IsAuditSchemaConsistent
			(
				@psTable	nvarchar(128)
			)
RETURNS bit
AS 
-- FUNCTION :	fn_IsAuditSchemaConsistent
-- VERSION :	2
-- DESCRIPTION:	This function accepts to determine if audit trigger need  to be recreated
-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- ------------	-------	-------		------	----------------------------------------- 
-- 29/11/2021	AK						1	Function created
-- 07/12/2021	AK						2	allowed standard triggers to be regenrated
Begin		
	
	Declare @sLogTable nvarchar(128)
	Declare @bReturnValue bit = 1

	set @sLogTable = @psTable + '_iLog'		
	if exists (select 1 from AUDITLOGTABLES where LOGFLAG = 1 AND TABLENAME = @psTable)
	begin
		if exists(select *
				FROM sys.dm_exec_describe_first_result_set (N'SELECT * FROM ' + @psTable, NULL, 0) live
				FULL OUTER JOIN sys.dm_exec_describe_first_result_set (N'SELECT * FROM ' + @sLogTable, NULL, 0) log
				ON live.name = log.name
				and live.system_type_name = log.system_type_name
				and live.max_length = log.max_length
				and live.precision = log.precision
				and live.scale = log.scale
				where log.name is null 
						and live.system_type_name not in ('ntext','text','image','sysname'))
		begin
			set @bReturnValue = 0
		end
	end
	else	
	begin				
		set @bReturnValue = 0
	end		

	RETURN @bReturnValue
End
GO

Grant execute on dbo.fn_IsAuditSchemaConsistent to public
GO
