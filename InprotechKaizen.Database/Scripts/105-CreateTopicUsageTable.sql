/** R69865 Available topic pick list for entry control **/
if not exists (select * from TRANSLATIONSOURCE where TABLENAME = 'TOPICUSAGE' and TIDCOLUMN = 'TOPICTITLE_TID')
begin
	print '**** R69865 Inserting data into TRANSLATIONSOURCE.TABLENAME = TOPICUSAGE'
    
	insert into TRANSLATIONSOURCE (TABLENAME, SHORTCOLUMN , LONGCOLUMN, TIDCOLUMN, INUSE)
    values ('TOPICUSAGE', 'TOPICTITLE', NULL, 'TOPICTITLE_TID', 0)
	
	print '**** R69865 Data has been successfully added to TRANSLATIONSOURCE table.'
	print ''   
end
else
begin
	print '**** R69865 TRANSLATIONSOURCE.TOPICTITLE already exists.'
end
PRINT ''
go


if not exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TOPICUSAGE')
begin
	print '**** R69865  Adding table TOPICUSAGE.' 
    
	create table dbo.TOPICUSAGE
    (
 		ID                   int  NOT NULL  IDENTITY ( 1,1 )  NOT FOR REPLICATION,
 		TOPICNAME            nvarchar(250)  NOT NULL ,
 		TOPICTITLE           nvarchar(254)  NOT NULL ,
 		TOPICTITLE_TID       int  NULL ,
 		[TYPE]               nchar(2)  NOT NULL ,
 		LOGUSERID            nvarchar(50)  NULL ,
 		LOGIDENTITYID        int  NULL ,
 		LOGTRANSACTIONNO     int  NULL ,
 		LOGDATETIMESTAMP     datetime  NULL ,
 		LOGAPPLICATION       nvarchar(128)  NULL ,
 		LOGOFFICEID          int  NULL 
    )
	                
    exec sc_AssignTableSecurity 'TOPICUSAGE'

	print '**** R69865 TOPICUSAGE table has been added.'
    print ''
end
else
begin
	print '**** R69865 TOPICUSAGE already exists'
end
print ''
go 

if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'TOPICUSAGE' and CONSTRAINT_NAME = 'XPKTOPICUSAGE')
begin
	print 'Dropping primary key constraint TOPICUSAGE.XPKTOPICUSAGE...'
	alter table TOPICUSAGE drop constraint XPKTOPICUSAGE
end
go

print 'Adding primary key constraint TOPICUSAGE.XPKTOPICUSAGE...'
alter table dbo.TOPICUSAGE
	 with nocheck add constraint XPKTOPICUSAGE primary key  clustered (ID asc)
go

if exists (select * from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = 'TOPICUSAGE' and CONSTRAINT_NAME = 'R_81887')
begin
	print 'Dropping foreign key constraint TOPICUSAGE.R_81887...'
	alter table TOPICUSAGE drop constraint R_81887
end
go

print 'Adding foreign key constraint TOPICUSAGE.R_81887......'
alter table dbo.TOPICUSAGE
	 with nocheck add constraint R_81887 foreign key (TOPICTITLE_TID) references dbo.TRANSLATEDITEMS(TID)
	 not for replication
go

if exists (select * from sysindexes where name = 'XAK1TOPICUSAGE')
begin
	 print 'Dropping index TOPICUSAGE.XAK1TOPICUSAGE ...'
	 drop index XAK1TOPICUSAGE on TOPICUSAGE
end
go

print 'Adding index XAK1TOPICUSAGE.XAK1EVENTTEXTTYPE ...'
create unique nonclustered index XAK1TOPICUSAGE on TOPICUSAGE
( 
	TOPICNAME   asc
)
go    

IF dbo.fn_IsAuditSchemaConsistent('TOPICUSAGE') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'TOPICUSAGE'
END
GO