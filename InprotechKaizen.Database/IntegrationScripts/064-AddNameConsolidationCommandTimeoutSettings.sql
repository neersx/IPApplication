if not exists (select *
				from ConfigurationSettings 
				where [Key] = 'NameConsolidation.CommandTimeout')
begin
	-- default command timeout is 30 minutes
	insert ConfigurationSettings ([Key], [Value]) values ('NameConsolidation.CommandTimeout',  1800)
end
go