
declare @sDefaultConstraintName nvarchar(128)

-- get the constraint name
select @sDefaultConstraintName = dc.name from sys.default_constraints dc
join sys.syscolumns sc on sc.cdefault = dc.object_id
join sys.sysobjects so on so.id = sc.id
						  and so.id = dc.parent_object_id
where so.name = 'LETTER'
and sc.name = 'FORPRIMECASESONLY'
AND dc.type = 'D'
AND dc.definition like '%NULL%'

if (@sDefaultConstraintName is not null and @sDefaultConstraintName != '')
	BEGIN
		declare @sSQLString nvarchar(1000)
		set @sSQLString = 'ALTER TABLE [LETTER] DROP CONSTRAINT ' + @sDefaultConstraintName
		exec (@sSQLString)
	END
go

if exists(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'LETTER' 
					AND COLUMN_NAME = 'FORPRIMECASESONLY' 
					AND COLUMN_DEFAULT is null)
	BEGIN
		ALTER TABLE [LETTER] ADD DEFAULT 0 FOR FORPRIMECASESONLY
	END
go