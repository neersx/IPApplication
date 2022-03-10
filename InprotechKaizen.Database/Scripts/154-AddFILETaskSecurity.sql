/**********************************************************************************************************/
/*** RFC72066 Create PCT National Phase in FILE from Inprotech - Feature						***/
/**********************************************************************************************************/
if not exists (select *
               from   FEATURE
               where  FEATUREID = 78)
begin
    print '**** RFC72066 Inserting FEATURE.FEATUREID = 78'

    insert into FEATURE
                (FEATUREID,FEATURENAME,CATEGORYID,ISEXTERNAL,ISINTERNAL)
    values      (78,N'The IP Platform FILE App',9801,0,1)

    print '**** RFC72066 Data has been successfully added to FEATURE table.'

    print ''
end
else
  print '**** RFC72066 FEATURE.FEATUREID = 78 already exists.'

print ''

GO

/**********************************************************************************************************/
/*** RFC72066 Create PCT National Phase in FILE from Inprotech - Task						***/
/**********************************************************************************************************/
if not exists (select *
               from   TASK
               where  TASKID = 269)
begin
    print '**** RFC72066 Adding data TASK.TASKID = 269'

    insert into TASK
                (TASKID,TASKNAME,DESCRIPTION)
    values      (269,N'View FILE Case',N'View FILE cases from Inprotech cases, without needing the ability to create cases in FILE')

    print '**** RFC72066 Data successfully added to TASK table.'

    print ''
end
else
  print '**** RFC72066 TASK.TASKID = 269 already exists'

print ''

GO

/**********************************************************************************************************/
/*** RFC72066 Create PCT National Phase in FILE from Inprotech - FeatureTask						***/
/**********************************************************************************************************/
if not exists (select *
               from   FEATURETASK
               where  FEATUREID = 78
                      and TASKID = 269)
begin
    print '**** RFC72066 Inserting FEATURETASK.FEATUREID = 78, TASKID = 269'

    insert into FEATURETASK
                (FEATUREID,TASKID)
    values      (78,269)

    print '**** RFC72066 Data has been successfully added to FEATURETASK table.'

    print ''
end
else
  print '**** RFC72066 FEATURETASK.FEATUREID = 78, TASKID = 269 already exists.'

print ''

GO

/**********************************************************************************************************/
/*** RFC72066 Create PCT National Phase in FILE from Inprotech - Permission Definition						***/
/**********************************************************************************************************/
if not exists(select *
              from   PERMISSIONS
              where  OBJECTTABLE = 'TASK'
                     and OBJECTINTEGERKEY = 269
                     and LEVELTABLE is null
                     and LEVELKEY is null)
begin
    print '**** RFC72066 Adding TASK definition data PERMISSIONS.OBJECTKEY = 269'

    insert PERMISSIONS
           (OBJECTTABLE,OBJECTINTEGERKEY,OBJECTSTRINGKEY,LEVELTABLE,LEVELKEY,GRANTPERMISSION,DENYPERMISSION)
    values ('TASK',269,null,null,null,32,0)

    print '**** RFC72066 Data successfully added to PERMISSIONS table.'

    print ''
end
else
begin
    print '**** RFC72066 TASK definition data PERMISSIONS.OBJECTKEY = 269 already exists'

    print ''
end

GO

/**********************************************************************************************************/
/*** RFC72066 - ValidObject								***/
/**********************************************************************************************************/
if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '62 891')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 62 891'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'62 891')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 62 891 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '62 192')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 62 192'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'62 192')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 62 192 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '62  92')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 62  92'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'62  92')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 62  92 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '62 892')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 62 892'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'62 892')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 62 892 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '62 992')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 62 992'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'62 992')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 62 992 already exists'

print ''

GO

if not exists (select *
               from   TASK
               where  TASKID = 270)
begin
    print '**** RFC72066 Adding data TASK.TASKID = 270'

    insert into TASK
                (TASKID,TASKNAME,DESCRIPTION)
    values      (270,N'Create FILE Case',N'Create FILE cases from Inprotech cases')

    print '**** RFC72066 Data successfully added to TASK table.'

    print ''
end
else
  print '**** RFC72066 TASK.TASKID = 270 already exists'

print ''

GO

/**********************************************************************************************************/
/*** RFC72066 Create PCT National Phase in FILE from Inprotech - FeatureTask						***/
/**********************************************************************************************************/
if not exists (select *
               from   FEATURETASK
               where  FEATUREID = 78
                      and TASKID = 270)
begin
    print '**** RFC72066 Inserting FEATURETASK.FEATUREID = 78, TASKID = 270'

    insert into FEATURETASK
                (FEATUREID,TASKID)
    values      (78,270)

    print '**** RFC72066 Data has been successfully added to FEATURETASK table.'

    print ''
end
else
  print '**** RFC72066 FEATURETASK.FEATUREID = 78, TASKID = 270 already exists.'

print ''

GO

/**********************************************************************************************************/
/*** RFC72066 Create PCT National Phase in FILE from Inprotech - Permission Definition						***/
/**********************************************************************************************************/
if not exists(select *
              from   PERMISSIONS
              where  OBJECTTABLE = 'TASK'
                     and OBJECTINTEGERKEY = 270
                     and LEVELTABLE is null
                     and LEVELKEY is null)
begin
    print '**** RFC72066 Adding TASK definition data PERMISSIONS.OBJECTKEY = 270'

    insert PERMISSIONS
           (OBJECTTABLE,OBJECTINTEGERKEY,OBJECTSTRINGKEY,LEVELTABLE,LEVELKEY,GRANTPERMISSION,DENYPERMISSION)
    values ('TASK',270,null,null,null,32,0)

    print '**** RFC72066 Data successfully added to PERMISSIONS table.'

    print ''
end
else
begin
    print '**** RFC72066 TASK definition data PERMISSIONS.OBJECTKEY = 270 already exists'

    print ''
end

GO

/**********************************************************************************************************/
/*** RFC72066 - ValidObject								***/
/**********************************************************************************************************/
if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72 801')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 72 801'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72 801')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 72 801 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72 102')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 72 102'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72 102')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 72 102 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72  02')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 72  02'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72  02')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 72  02 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72 802')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 72 802'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72 802')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 72 802 already exists'

print ''

GO

if not exists (select *
               from   VALIDOBJECT
               where  TYPE = 20
                      and OBJECTDATA = '72 902')
begin
    print '**** RFC72066 Adding data VALIDOBJECT.OBJECTDATA = 72 902'

    declare @validObject INT

    select @validObject = ( max(OBJECTID) + 1 )
    from   VALIDOBJECT

    insert into VALIDOBJECT
                (OBJECTID,TYPE,OBJECTDATA)
    values      (@validObject,20,'72 902')

    print '**** RFC72066 Data successfully added to VALIDOBJECT table.'

    print ''
end
else
  print '**** RFC72066 VALIDOBJECT.OBJECTDATA = 72 902 already exists'

print ''

GO 
