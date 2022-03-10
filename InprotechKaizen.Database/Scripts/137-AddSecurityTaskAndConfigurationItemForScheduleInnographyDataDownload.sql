/**********************************************************************************************************/
/*** DR-28342 DR-28342 Task Security for scheduling Innography integration - Task						***/
/**********************************************************************************************************/
if not exists (select * from   TASK where  TASKID = 266)
begin
    print '**** DR-28342 Adding data TASK.TASKID = 266'

    insert into TASK(TASKID,TASKNAME,DESCRIPTION)
    values      (266,N'Schedule Innography Data Download',N'Schedule tasks to download data from Innography for use with case data comparison')

    print '**** DR-28342 Data successfully added to TASK table.'
    print ''
end
else
  print '**** DR-28342 TASK.TASKID = 266 already exists'

print ''

GO

/**********************************************************************************************************/
/*** DR-28342 DR-28342 Task Security for scheduling Innography integration - FeatureTask						***/
/**********************************************************************************************************/
if not exists (select * from   FEATURETASK where  FEATUREID = 32 and TASKID = 266)
begin
    print '**** DR-28342 Inserting FEATURETASK.FEATUREID = 32, TASKID = 266'
    insert into FEATURETASK(FEATUREID,TASKID) values      (32,266)

    print '**** DR-28342 Data has been successfully added to FEATURETASK table.'
    print ''
end
else
  print '**** DR-28342 FEATURETASK.FEATUREID = 32, TASKID = 266 already exists.'

print ''

GO

/**********************************************************************************************************/
/*** DR-28342 DR-28342 Task Security for scheduling Innography integration - Permission Definition						***/
/**********************************************************************************************************/
if not exists(select *
              from   PERMISSIONS
              where  OBJECTTABLE = 'TASK'
                     and OBJECTINTEGERKEY = 266
                     and LEVELTABLE is null
                     and LEVELKEY is null)
begin
    print '**** DR-28342 Adding TASK definition data PERMISSIONS.OBJECTKEY = 266'

    insert PERMISSIONS (OBJECTTABLE,OBJECTINTEGERKEY,OBJECTSTRINGKEY,LEVELTABLE,LEVELKEY,GRANTPERMISSION,DENYPERMISSION)
    values ('TASK',266,null,null,null,32,0)

    print '**** DR-28342 Data successfully added to PERMISSIONS table.'
    print ''
end
else
begin
    print '**** DR-28342 TASK definition data PERMISSIONS.OBJECTKEY = 266 already exists'

    print ''
end

GO

/**********************************************************************************************************/
/*** DR-28342 - ValidObject								***/
/**********************************************************************************************************/
if not exists (select * from   VALIDOBJECT where  TYPE = 20 and OBJECTDATA = '62 861')
begin
    print '**** DR-28342 Adding data VALIDOBJECT.OBJECTDATA = 62 861'

    declare @validObject INT
    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT (OBJECTID,TYPE,OBJECTDATA) values (@validObject,20,'62 861')

    print '**** DR-28342 Data successfully added to VALIDOBJECT table.'
    print ''
end
else
  print '**** DR-28342 VALIDOBJECT.OBJECTDATA = 62 861 already exists'

print ''

GO

if not exists (select * from   VALIDOBJECT where  TYPE = 20 and OBJECTDATA = '62 162')
begin
    print '**** DR-28342 Adding data VALIDOBJECT.OBJECTDATA = 62 162'

    declare @validObject INT
    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT (OBJECTID,TYPE,OBJECTDATA) values (@validObject,20,'62 162')

    print '**** DR-28342 Data successfully added to VALIDOBJECT table.'
    print ''
end
else
  print '**** DR-28342 VALIDOBJECT.OBJECTDATA = 62 162 already exists'

print ''

GO

if not exists (select * from   VALIDOBJECT where  TYPE = 20 and OBJECTDATA = '62 762')
begin
    print '**** DR-28342 Adding data VALIDOBJECT.OBJECTDATA = 62 762'

    declare @validObject INT
    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT (OBJECTID,TYPE,OBJECTDATA) values (@validObject,20,'62 762')

    print '**** DR-28342 Data successfully added to VALIDOBJECT table.'
    print ''
end
else
  print '**** DR-28342 VALIDOBJECT.OBJECTDATA = 62 762 already exists'

print ''

GO

if not exists (select * from   VALIDOBJECT where  TYPE = 20 and OBJECTDATA = '62 862')
begin
    print '**** DR-28342 Adding data VALIDOBJECT.OBJECTDATA = 62 862'

    declare @validObject INT
    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT (OBJECTID,TYPE,OBJECTDATA) values (@validObject,20,'62 862')

    print '**** DR-28342 Data successfully added to VALIDOBJECT table.'
    print ''
end
else
  print '**** DR-28342 VALIDOBJECT.OBJECTDATA = 62 862 already exists'

print ''

GO

if not exists (select * from   VALIDOBJECT where  TYPE = 20 and OBJECTDATA = '62 962')
begin
    print '**** DR-28342 Adding data VALIDOBJECT.OBJECTDATA = 62 962'

    declare @validObject INT
    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT (OBJECTID,TYPE,OBJECTDATA) values (@validObject,20,'62 962')

    print '**** DR-28342 Data successfully added to VALIDOBJECT table.'
    print ''
end
else
  print '**** DR-28342 VALIDOBJECT.OBJECTDATA = 62 962 already exists'

print ''

GO 

If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = 20 and OBJECTDATA = '62  62')
BEGIN

	PRINT '**** DR-28342 Adding data VALIDOBJECT.OBJECTDATA = 62  62'
	declare @validObject int
	Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT
    
	INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA) VALUES (@validObject, 20, '62  62')
	PRINT '**** DR-28342 Data successfully added to VALIDOBJECT table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-28342 VALIDOBJECT.OBJECTDATA = 62  62 already exists'

PRINT ''

go


/**********************************************************************************************************/
/*** DR-28342 Schedule Innography Data Download - ConfigurationItem						                            ***/
/**********************************************************************************************************/
if not exists (select * from CONFIGURATIONITEM where TASKID = 266 and TITLE = 'Schedule Innography Data Download')
begin
    print '**** DR-28342 Inserting CONFIGURATIONITEM WHERE TASKID=266 and TITLE = "Schedule Innography Data Download"'

    insert into CONFIGURATIONITEM (TASKID,TITLE,DESCRIPTION,URL)
    values     (266,'Schedule Innography Data Download','	Schedule tasks to automatically download selected case data from the Innography.','/i/integration/ptoaccess/#/schedules')

    print '**** DR-28342 Data successfully inserted in CONFIGURATIONITEM table.'

    print ''
end
else
begin
    print '**** DR-28342 CONFIGURATIONITEM WHERE TASKID=266 and TITLE ="Schedule Innography Data Download" already exists'

    print ''
end 
go


if exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'CONFIGURATIONITEM' and COLUMN_NAME = 'GROUPID')
begin
    declare @bExists BIT
    set @bExists = 0

    exec sp_executesql
      N'select @bExists = 1 FROM CONFIGURATIONITEM WHERE TASKID in (216, 232, 227, 266) and GROUPID IS NULL',
      N'@bExists bit output',
      @bExists = @bExists OUTPUT

    if ( @bExists = 1 )
    begin
        print '**** DR-28342 Updating CONFIGURATIONITEM for Schedule Innography Data Download'

        exec sp_executesql
          N'UPDATE CONFIGURATIONITEM 
				SET GROUPID = 1
				WHERE TASKID in (216, 232, 227, 266)'

        print '**** DR-28342 Data successfully updated on CONFIGURATIONITEM table.'
        print ''
    end
    else
    begin
        print '**** DR-28342 CONFIGURATIONITEM Schedule Data Download already up to date.'
        print ''
    end
end

GO 
