if not exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = 'CreatedOn' and TABLE_NAME = 'MessageStore')
begin
	ALTER TABLE [MessageStore] ADD CreatedOn DATETIME2(7) NOT NULL DEFAULT GETUTCDATE()
	EXECUTE('UPDATE MessageStore SET CreatedOn = MessageTimestamp')
END


if exists (select * from (select lower(COLUMN_DEFAULT) as def from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = 'CreatedOn' and TABLE_NAME = 'MessageStore') t where t.def = '(getdate())')
begin
 declare @Exec nvarchar(max)= (select 'Alter Table MessageStore Drop Constraint [' + ( select d.name
     from 
         sys.tables t
         join sys.default_constraints d on d.parent_object_id = t.object_id
         join sys.columns c on c.object_id = t.object_id
                               and c.column_id = d.parent_column_id
     where 
         t.name = 'MessageStore'
         and c.name = 'CreatedOn') + ']'
		 )

 Execute (@exec);
 ALTER TABLE [dbo].[MessageStore] ADD  DEFAULT (getutcdate()) FOR [CreatedOn];

end