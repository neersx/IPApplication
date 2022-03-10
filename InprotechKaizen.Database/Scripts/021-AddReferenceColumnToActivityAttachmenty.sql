if not exists(select * from information_schema.columns where table_name = 'ACTIVITYATTACHMENT' and column_name = 'REFERENCE')
begin		 
	alter table ACTIVITYATTACHMENT add [REFERENCE] [uniqueidentifier] NULL	
end
GO
exec ipu_UtilGenerateAuditTriggers 'ACTIVITYATTACHMENT'
GO