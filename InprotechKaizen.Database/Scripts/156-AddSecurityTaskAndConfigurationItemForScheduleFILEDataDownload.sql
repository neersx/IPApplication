/**********************************************************************************************************/
/*** DR-33347 Task Security for scheduling FILE integration - Task						***/
/**********************************************************************************************************/
if not exists (select *
               from   TASK
               where  TASKID = 271)
begin
    print '**** DR-33347 Adding data TASK.TASKID = 271'

    insert into TASK
                (TASKID,TASKNAME,DESCRIPTION)
    values      (271,N'Schedule FILE Data Download',N'Schedule tasks to download data from FILE for use with case data comparison')

    print '**** DR-33347 Data successfully added to TASK table.'

    print ''
end
else
  print '**** DR-33347 TASK.TASKID = 271 already exists'

print ''

GO

/**********************************************************************************************************/
/*** DR-33347 Task Security for scheduling FILE integration - FeatureTask						***/
/**********************************************************************************************************/
if not exists (select *
               from   FEATURETASK
               where  FEATUREID = 32
                      and TASKID = 271)
begin
    print '**** DR-33347 Inserting FEATURETASK.FEATUREID = 32, TASKID = 271'

    insert into FEATURETASK
                (FEATUREID,TASKID)
    values      (32,271)

    print '**** DR-33347 Data has been successfully added to FEATURETASK table.'

    print ''
end
else
  print '**** DR-33347 FEATURETASK.FEATUREID = 32, TASKID = 271 already exists.'

print ''

GO

/**********************************************************************************************************/
/*** DR-33347 Task Security for scheduling FILE integration - Permission Definition						***/
/**********************************************************************************************************/
if not exists(select *
              from   PERMISSIONS
              where  OBJECTTABLE = 'TASK'
                     and OBJECTINTEGERKEY = 271
                     and LEVELTABLE is null
                     and LEVELKEY is null)
begin
    print '**** DR-33347 Adding TASK definition data PERMISSIONS.OBJECTKEY = 271'

    insert PERMISSIONS
           (OBJECTTABLE,OBJECTINTEGERKEY,OBJECTSTRINGKEY,LEVELTABLE,LEVELKEY,GRANTPERMISSION,DENYPERMISSION)
    values ('TASK',271,null,null,null,32,0)

    print '**** DR-33347 Data successfully added to PERMISSIONS table.'

    print ''
end
else
begin
    print '**** DR-33347 TASK definition data PERMISSIONS.OBJECTKEY = 271 already exists'

    print ''
end

GO

/**********************************************************************************************************/
/*** DR-33347 - ValidObject								***/
/**********************************************************************************************************/
if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72 811')
begin
    print '**** DR-33347 Adding data VALIDOBJECT.OBJECTDATA = 72 811'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72 811')

    print '**** DR-33347 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** DR-33347 VALIDOBJECT.OBJECTDATA = 72 811 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72 112')
begin
    print '**** DR-33347 Adding data VALIDOBJECT.OBJECTDATA = 72 112'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72 112')

    print '**** DR-33347 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** DR-33347 VALIDOBJECT.OBJECTDATA = 72 112 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72 712')
begin
    print '**** DR-33347 Adding data VALIDOBJECT.OBJECTDATA = 72 712'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72 712')

    print '**** DR-33347 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** DR-33347 VALIDOBJECT.OBJECTDATA = 72 712 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72 812')
begin
    print '**** DR-33347 Adding data VALIDOBJECT.OBJECTDATA = 72 812'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72 812')

    print '**** DR-33347 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** DR-33347 VALIDOBJECT.OBJECTDATA = 72 812 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72  12')
begin
    print '**** DR-33347 Adding data VALIDOBJECT.OBJECTDATA = 72  12'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72  12')

    print '**** DR-33347 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** DR-33347 VALIDOBJECT.OBJECTDATA = 72  12 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72 912')
begin
    print '**** DR-33347 Adding data VALIDOBJECT.OBJECTDATA = 72 912'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72 912')

    print '**** DR-33347 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** DR-33347 VALIDOBJECT.OBJECTDATA = 72 912 already exists'

print ''

GO 


/**********************************************************************************************************/
/*** DR-33347  Schedule Innography Data Download - ConfigurationItem						                            ***/
/**********************************************************************************************************/
if not exists (select * from CONFIGURATIONITEM where TASKID = 271 and TITLE = 'Schedule FILE Data Download')
begin
    print '**** DR-33347  Inserting CONFIGURATIONITEM WHERE TASKID=266 and TITLE = "Schedule FILE Data Download"'

    insert into CONFIGURATIONITEM (TASKID,TITLE,DESCRIPTION,URL)
    values     (271,'Schedule FILE Data Download','	Schedule tasks to automatically download selected case data from the FILE.','/i/integration/ptoaccess/#/schedules')

    print '**** DR-33347  Data successfully inserted in CONFIGURATIONITEM table.'

    print ''
end
else
begin
    print '**** DR-33347 CONFIGURATIONITEM WHERE TASKID=271 and TITLE ="Schedule FILE Data Download" already exists'

    print ''
end 
go


if exists (select * from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'CONFIGURATIONITEM' and COLUMN_NAME = 'GROUPID')
begin
    declare @bExists BIT
    set @bExists = 0

    exec sp_executesql
      N'select @bExists = 1 FROM CONFIGURATIONITEM WHERE TASKID in (216, 232, 227, 266, 271) and GROUPID IS NULL',
      N'@bExists bit output',
      @bExists = @bExists OUTPUT

    if ( @bExists = 1 )
    begin
        print '**** DR-33347  Updating CONFIGURATIONITEM for Schedule Innography Data Download'

        exec sp_executesql
          N'UPDATE CONFIGURATIONITEM 
				SET GROUPID = 1
				WHERE TASKID in (216, 232, 227, 266, 271)'

        print '**** DR-33347 Data successfully updated on CONFIGURATIONITEM table.'
        print ''
    end
    else
    begin
        print '**** DR-33347 CONFIGURATIONITEM Schedule Data Download already up to date.'
        print ''
    end
end

GO 
