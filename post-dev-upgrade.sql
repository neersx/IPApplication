If not exists(select * from CONFIGURATIONSETTINGS where SETTINGKEY = 'InprotechServer.AppSettings.AuthenticationMode')
begin
	insert CONFIGURATIONSETTINGS (SETTINGKEY, SETTINGVALUE)
	values ('InprotechServer.AppSettings.AuthenticationMode', 'Forms,Windows,Sso')
end

If not exists(select * from CONFIGURATIONSETTINGS where SETTINGKEY = 'InprotechServer.AppSettings.cpa.sso.clientId')
begin
	insert CONFIGURATIONSETTINGS (SETTINGKEY, SETTINGVALUE)
	values ('InprotechServer.AppSettings.cpa.sso.clientId', 'HUf/zB1Op5XPhhhc7LbpkA==')
end

If not exists(select * from CONFIGURATIONSETTINGS where SETTINGKEY = 'InprotechServer.AppSettings.cpa.sso.clientSecret')
begin
	insert CONFIGURATIONSETTINGS (SETTINGKEY, SETTINGVALUE)
	values ('InprotechServer.AppSettings.cpa.sso.clientSecret', '3kgWwmYywhlr+u4FeieGoNsMBROx8KHfwgVuWCAHZyX0DXoFW3N8AF9fKJ8ixUpHTJ3LyYujVvzzVMxVAuWjJTjwV35u+capFfg4l1vduMc=')
end	

If not exists(select * from CONFIGURATIONSETTINGS where SETTINGKEY = 'Inprotech.Ede.SqlBulkLoadProvider')
begin
	insert CONFIGURATIONSETTINGS (SETTINGKEY, SETTINGVALUE)
	values ('Inprotech.Ede.SqlBulkLoadProvider', 'SQLOLEDB')
end	

declare @bExists bit
exec sp_executesql N'select @bExists = 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = ''CONFIGURATIONSETTINGS'' AND COLUMN_NAME = ''CreatedByE2E''', N'@bExists bit output', @bExists = @bExists output

If not exists(select * from CONFIGURATIONSETTINGS where SETTINGKEY = 'Inprotech.Server.Instances')
begin
	insert CONFIGURATIONSETTINGS (SETTINGKEY, SETTINGVALUE)
	values ('Inprotech.Server.Instances', '[]')
end	
else if (@bExists = 1)
begin
	exec sp_executesql N'update CONFIGURATIONSETTINGS set CreatedByE2E = 0 where SETTINGKEY = ''Inprotech.Server.Instances'''	
end

If not exists(select * from CONFIGURATIONSETTINGS where SETTINGKEY = 'Inprotech.IntegrationServer.Instances')
begin
	insert CONFIGURATIONSETTINGS (SETTINGKEY, SETTINGVALUE)
	values ('Inprotech.IntegrationServer.Instances', '[]')
end	
else if (@bExists = 1)
begin
	exec sp_executesql N'update CONFIGURATIONSETTINGS set CreatedByE2E = 0 where SETTINGKEY = ''Inprotech.IntegrationServer.Instances'''	
end
	
If exists (Select  *
	from FEATURETASK FT
	where exists (Select *
		    from FEATURE F
		    where F.FEATUREID = FT.FEATUREID  
		    and	  F.ISINTERNAL = 1)
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'TASK'
					and P.OBJECTINTEGERKEY = FT.TASKID)
		where R.ROLENAME = 'All Internal')
	)
Begin
	print '*****Granting all applicable permissions (except mandatory) to every internal task.'	

	insert into PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION)
	Select  DISTINCT
		'TASK',
		FT.TASKID,
		NULL,
		'ROLE',
		R.ROLEID,
		CASE WHEN PR.SelectPermission 	= 1 THEN 1 	ELSE 0 END |
		CASE WHEN PR.InsertPermission 	= 1 THEN 8  	ELSE 0 END |
		CASE WHEN PR.UpdatePermission	= 1 THEN 2	ELSE 0 END |
		CASE WHEN PR.DeletePermission	= 1 THEN 16 	ELSE 0 END |
		CASE WHEN PR.ExecutePermission  = 1 THEN 32 	ELSE 0 END,		
		0
	from FEATURETASK FT
	join TASK T		on (T.TASKID = FT.TASKID)
	join dbo.fn_PermissionRule('TASK', NULL, NULL) PR
				on (PR.ObjectIntegerKey = T.TASKID)
	join ROLE R		on (R.ROLENAME = 'All Internal')
	where exists (Select *
		    from FEATURE F
		    where F.FEATUREID = FT.FEATUREID  
		    and	  F.ISINTERNAL = 1)
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'TASK'
					and P.OBJECTINTEGERKEY = FT.TASKID)
		where R.ROLENAME = 'All Internal')
End
Else Begin
	print '*****All applicable permissions (except mandatory) are already granted to every internal task.'	
End

-- Grant all applicable permissions (except mandatory) to every 
-- internal subject.

If exists (select *
	from DATATOPIC DT
	where DT.ISINTERNAL = 1
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'DATATOPIC'
					and P.OBJECTINTEGERKEY = DT.TOPICID)
		where R.ROLENAME = 'All Internal')
	)
Begin
	print '*****Granting all applicable permissions (except mandatory) to every internal subject.'

	insert into PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION)
	Select  'DATATOPIC',
		DT.TOPICID,
		NULL,
		'ROLE',
		R.ROLEID,
		CASE WHEN PR.SelectPermission 	= 1 THEN 1 	ELSE 0 END |
		CASE WHEN PR.InsertPermission 	= 1 THEN 8  	ELSE 0 END |
		CASE WHEN PR.UpdatePermission	= 1 THEN 2	ELSE 0 END |
		CASE WHEN PR.DeletePermission	= 1 THEN 16 	ELSE 0 END |
		CASE WHEN PR.ExecutePermission  = 1 THEN 32 	ELSE 0 END,		
		0
	From DATATOPIC DT
	join dbo.fn_PermissionRule('DATATOPIC', NULL, NULL) PR
				on (PR.ObjectTable = 'DATATOPIC')
	join ROLE R		on (R.ROLENAME = 'All Internal')
	WHERE DT.ISINTERNAL = 1
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'DATATOPIC'
					and P.OBJECTINTEGERKEY = DT.TOPICID)
		where R.ROLENAME = 'All Internal')
End
Else Begin
	print '*****All applicable permissions (except mandatory) are already granted to every internal subject.'	
End

