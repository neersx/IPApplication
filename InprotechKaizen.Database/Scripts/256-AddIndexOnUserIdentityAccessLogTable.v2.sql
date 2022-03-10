/****************************************************************************/
/*** DR-57464 Adding Index USERIDENTITYACCESSLOG.XIE1USERIDENTITYACCESSLOG **/
/****************************************************************************/
if exists (select * from sysindexes where name = 'XAK2USERIDENTITYACCESSLOG')
	 DROP INDEX XAK2USERIDENTITYACCESSLOG ON USERIDENTITYACCESSLOG
go


if exists (select * from sysindexes where name = 'XIE1USERIDENTITYACCESSLOG')
begin
	 PRINT 'Dropping index USERIDENTITYACCESSLOG.XIE1USERIDENTITYACCESSLOG ...'
	 DROP INDEX XIE1USERIDENTITYACCESSLOG ON USERIDENTITYACCESSLOG
end
go

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'USERIDENTITYACCESSLOG'AND COLUMN_NAME = 'SOURCE')
	BEGIN
	ALTER TABLE USERIDENTITYACCESSLOG ADD SOURCE nvarchar(100) null
END
GO

if not exists (select * from sysindexes where name = 'XIE1USERIDENTITYACCESSLOG')
begin
	 PRINT 'Adding index USERIDENTITYACCESSLOG.XIE1USERIDENTITYACCESSLOG ...'
	 CREATE NONCLUSTERED INDEX XIE1USERIDENTITYACCESSLOG ON USERIDENTITYACCESSLOG
( 
	IDENTITYID            ASC,
	LOGOUTTIME            ASC
)
include ([PROVIDER], LOGID)
end
go

if exists (select * from sysobjects where type='TR' and name = 'InsertUserIdentityAccessLog_ModuleUsage')
begin
	PRINT 'InsertUserIdentityAccessLog_ModuleUsage...'
	DROP TRIGGER InsertUserIdentityAccessLog_ModuleUsage
end
go

Create trigger InsertUserIdentityAccessLog_ModuleUsage on MODULEUSAGE for INSERT NOT FOR REPLICATION as
Begin
	--------------------------------------------------------------------------
	-- Include USERIDENTITYACCESSLOG when MODULEUSAGE is being inserted into . 
	--------------------------------------------------------------------------
	insert into USERIDENTITYACCESSLOG (IDENTITYID, [PROVIDER], LOGINTIME, [SOURCE])

	select i.IDENTITYID, 'Centura', i.USAGETIME, i.COMPUTERIDENTIFIER
	from inserted i
End
go

