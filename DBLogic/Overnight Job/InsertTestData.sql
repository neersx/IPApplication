/******************************************************************************************/
/***** Remove invalid data							      *****/
/******************************************************************************************/
If exists(select 1 from NAMETEXT WHERE unicode(right(cast(TEXT as nvarchar(4000)),1))=0)
Begin
	print '*****Removing invalid data'
	
	update NAMETEXT
	SET TEXT = left(cast(TEXT as nvarchar(4000)),len(cast(TEXT as nvarchar(4000)))-1)
	WHERE unicode(right(cast(TEXT as nvarchar(4000)),1))=0
End
Else Begin
	print '*****Invalid data already removed'
End

UPDATE REPORTS SET USERID='SYSADM' where USERID='sysadm'

Declare @nCurrentModule		int
Declare @sModuleTitle	nvarchar(512)
Declare @nInternalPortalKey	int
Declare @nExternalPortalKey	int

update REPORTS SET USERID='SYSADM' WHERE USERID='sysadm'


/******************************************************************************************/
/***** Creating an internal user						      *****/
/******************************************************************************************/

-- 1) Create a new role All Internal for internal use.  

If not exists (Select * from ROLE where ROLENAME = 'All Internal')
Begin
	print '*****Creating a new role All Internal for internal use'
	
	insert 	into ROLE
		(ROLENAME, 
		 DESCRIPTION, 		 
		 ISEXTERNAL)
	values	('All Internal',
		 'The role with permissions granted for all possible internal web parts, tasks and subjects.', 		
		 0)
End
Else Begin
	print '*****All Internal role already exists'
End

-- Grant all applicable permissions (except mandatory) to every 
-- internal web part.

If exists (Select  *
	from FEATUREMODULE FM
	join FEATURE F 		on (F.FEATUREID = FM.FEATUREID)
	WHERE F.ISINTERNAL = 1 
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'MODULE'
					and P.OBJECTINTEGERKEY = FM.MODULEID)
		where R.ROLENAME = 'All Internal')
	)
Begin
	print '*****Granting all applicable permissions (except mandatory) to every internal web part.'	

	insert into PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION)
	Select  DISTINCT
		'MODULE',
		FM.MODULEID,
		NULL,
		'ROLE', 
		R.ROLEID,	
		CASE WHEN PR.SelectPermission 	= 1 THEN 1 	ELSE 0 END |
		CASE WHEN PR.InsertPermission 	= 1 THEN 8  	ELSE 0 END |
		CASE WHEN PR.UpdatePermission	= 1 THEN 2	ELSE 0 END |
		CASE WHEN PR.DeletePermission	= 1 THEN 16 	ELSE 0 END |
		CASE WHEN PR.ExecutePermission  = 1 THEN 32 	ELSE 0 END,		
		0
	from FEATUREMODULE FM
	join FEATURE F 		on F.FEATUREID = FM.FEATUREID
	join dbo.fn_PermissionRule('MODULE', NULL, NULL) PR	
				on (PR.ObjectTable = 'MODULE')
	join ROLE R		on (R.ROLENAME = 'All Internal')
	WHERE F.ISINTERNAL = 1
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'MODULE'
					and P.OBJECTINTEGERKEY = FM.MODULEID)
		where R.ROLENAME = 'All Internal')
End
Else Begin
	print '*****All applicable permissions (except mandatory) are already granted to every internal web part.'	
End

-- Grant all applicable permissions (except mandatory) to every 
-- internal task.

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




-- Create a new portal configuration Internal Test. This should copy the Professional portal 
-- and then append a new tab for every internal web part that is not already present.

If not exists (Select * from PORTAL where NAME = 'Internal Test')
Begin
	print '*****Creating a new portal configuration Internal Test.'

	insert into PORTAL (NAME, DESCRIPTION, ISEXTERNAL)
	values( 'Internal Test',
		'Based on the Professional configuration, with all of the possible internal web parts attached.',
		0)

	-- Copy Professional portal tabs:
	
	If not exists (Select * from PORTALTAB PT, PORTAL P where P.PORTALID = PT.PORTALID and P.NAME = 'Internal Test')
	Begin
		print '*****Copying Professional portal tabs.'
	
		insert into PORTALTAB (TABNAME, IDENTITYID, TABSEQUENCE, PORTALID)
		Select  PT.TABNAME,
			NULL,
			PT.TABSEQUENCE,
			(Select PORTALID from PORTAL where NAME = 'Internal Test')
		from PORTALTAB PT
		join PORTAL P			on (P.PORTALID = PT.PORTALID)
		where P.NAME = 'Professional' 
		and PT.IDENTITYID is null
	End
	Else Begin
		print '*****Professional portal tabs have already been copied for Internal Test portal.'	
	End
	
	-- Copy Professional web parts:
	
	If not exists (	select * 
			from PORTALTAB PT
			join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
			join PORTAL P			on (P.PORTALID = PT.PORTALID)
			where P.NAME = 'Internal Test')
	Begin
		print '*****Copying Professional portal web parts.'
	
	
	
		insert 	into MODULECONFIGURATION
			(TABID, 
			 MODULEID, 		 
			 MODULESEQUENCE,
			 PANELLOCATION)
		Select  PT2.TABID,
			MC.MODULEID, 		--MD.NAME,
			MC.MODULESEQUENCE,
			MC.PANELLOCATION
		from PORTAL P			
		join PORTALTAB PT		on (PT.PORTALID = P.PORTALID and PT.IDENTITYID is null)
		join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID and MC.IDENTITYID is null)
		--join MODULEDEFINITION MD on ( MD.MODULEDEFID = MC.MODULEID)
		join PORTAL P2			on (P2.NAME = 'Internal Test')
		join PORTALTAB PT2		on (PT2.PORTALID = P2.PORTALID 
						and PT2.TABNAME = PT.TABNAME
						and PT2.TABSEQUENCE = PT.TABSEQUENCE)
		WHERE P.NAME = 'Professional'
	End
	Else Begin
		print '*****Professional portal web parts have already been copied for Internal Test portal.'	
	End
	
	
	
	-- Copy Professional settings:
	
	If not exists (	select * 
			from PORTALTAB PT
			join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
			join PORTAL P			on (P.PORTALID = PT.PORTALID)
			join PORTALSETTING PS		on (PS.MODULECONFIGID = MC.CONFIGURATIONID)
			where P.NAME = 'Internal Test')
	Begin
		print '*****Copying Professional portal settings.'
	
		insert into PORTALSETTING (MODULEID, MODULECONFIGID, IDENTITYID, SETTINGNAME, SETTINGVALUE)
		Select  PS.MODULEID,
			MC2.CONFIGURATIONID,
			PS.IDENTITYID,
			PS.SETTINGNAME,
			PS.SETTINGVALUE 
		from PORTAL P			
		join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
		join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
		join PORTALSETTING PS		on (PS.MODULECONFIGID = MC.CONFIGURATIONID)
		join PORTAL P2			on (P2.NAME = 'Internal Test')
		join PORTALTAB PT2		on (PT2.PORTALID = P2.PORTALID
						and PT2.TABSEQUENCE = PT.TABSEQUENCE)
		join MODULECONFIGURATION MC2 	on (MC2.TABID = PT2.TABID
						and MC2.MODULEID = MC.MODULEID)
		WHERE P.NAME = 'Professional'
	End
	Else Begin
		print '*****Professional portal settings have already been copied for Internal Test portal.'	
	End

End
Else Begin
	print '*****Internal Test portal configuration already exists.'	
End

-- Move My Case List to What's New
If exists (Select *
		from PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'Internal Test'
		and	MC.MODULEID =-23
		and	PT.TABSEQUENCE <> 3)
Begin

	-- Add the My Case List web part to the What's New tab
	insert into MODULECONFIGURATION
	(IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	select	NULL, PT.TABID, -23, 1, 'BottomPane', P.PORTALID
	from	PORTAL P
	join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	where 	P.NAME = 'Internal Test'
	and	PT.TABSEQUENCE = 3
	and	not exists(
		select *
		from	PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'Internal Test'
		and	PT.TABSEQUENCE = 3
		and	MC.PANELLOCATION = 'BottomPane')

	-- Remove the My Case List tab
	delete 	MODULECONFIGURATION
	from	PORTAL P
	join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	where 	P.NAME = 'Internal Test'
	and	PT.TABSEQUENCE <> 3
	AND	MODULECONFIGURATION.TABID = PT.TABID
	AND 	MODULECONFIGURATION.MODULEID = -23

	DELETE PORTALTAB
	FROM 	PORTAL P
	JOIN	PORTALTAB PT 	ON (PT.PORTALID=P.PORTALID)
	WHERE 	P.NAME = 'Internal Test'
	AND	PT.TABNAME = 'My Case List'

End

-- Implement What's Due List
If not exists (Select *
		from PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'Internal Test'
		and	MC.MODULEID =-24)
Begin

	-- Add the What's Due List web part to the bottom of the What's Due tab
	insert into MODULECONFIGURATION
	(IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	select	NULL, PT.TABID, -24, 1, 'BottomPane', P.PORTALID
	from	PORTAL P
	join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	where 	P.NAME = 'Internal Test'
	and	PT.TABSEQUENCE = 2
	and	not exists(
		select *
		from	PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'Internal Test'
		and	PT.TABSEQUENCE = 2
		and	MC.PANELLOCATION = 'BottomPane')

	-- Make List collapsed by default
	insert into PORTALSETTING
	(MODULECONFIGID, SETTINGNAME, SETTINGVALUE)
	Select  MC.CONFIGURATIONID,
		'IsWebPartCollapsed',
		'<Value>True</Value>' 
	from PORTAL P			
	join PORTALTAB PT		on (PT.PORTALID = P.PORTALID
					AND PT.TABSEQUENCE=2)
	join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID
					and MC.MODULEID=-24)
	WHERE P.NAME = 'Internal Test'
End


Select @nInternalPortalKey = PORTALID from PORTAL where NAME = 'Internal Test'
-- Add Case Reports tab
If not exists(Select * from PORTAL P 
                left join PORTALTAB PT  on (PT.PORTALID=P.PORTALID)
                where P.NAME = 'Internal Test'
                and PT.TABNAME = 'Case Reports')
Begin
    Set @nCurrentModule = -50
    
    exec dbo.ua_AddModuleToConfiguration					
		    @pnUserIdentityId	= 5,
		    @psCulture		= null,	
		    @pnIdentityKey		= null,
		    @pnPortalKey		= @nInternalPortalKey,
		    @pnModuleKey		= @nCurrentModule	
End

-- Add Name Simple Search tab
If not exists(Select * from PORTAL P 
                left join PORTALTAB PT  on (PT.PORTALID=P.PORTALID)
                where P.NAME = 'Internal Test'
                and PT.TABNAME = 'Name Simple Search')
Begin
    Set @nCurrentModule = -27
    
    exec dbo.ua_AddModuleToConfiguration					
		    @pnUserIdentityId	= 5,
		    @psCulture		= null,	
		    @pnIdentityKey		= null,
		    @pnPortalKey		= @nInternalPortalKey,
		    @pnModuleKey		= @nCurrentModule	
End
-- Add Name Reports to Name Simple Search tab
If not exists (Select *
		from PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'Internal Test'
		and	MC.MODULEID =-51
		and	PT.TABNAME = 'Name Simple Search')
Begin
	insert into MODULECONFIGURATION
	(IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	select	NULL, PT.TABID, -51, 1, 'BottomPane', P.PORTALID
	from	PORTAL P
	join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	where 	P.NAME = 'Internal Test'
	and	PT.TABNAME = 'Name Simple Search'
	and	not exists(
		select *
		from	PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'Internal Test'
		and	PT.TABNAME = 'Name Simple Search'
		and	MC.PANELLOCATION = 'BottomPane')
	-- Make List collapsed by default
	insert into PORTALSETTING
	(MODULECONFIGID, SETTINGNAME, SETTINGVALUE)
	Select  MC.CONFIGURATIONID,
		'IsWebPartCollapsed',
		'<Value>True</Value>' 
	from PORTAL P			
	join PORTALTAB PT		on (PT.PORTALID = P.PORTALID
					AND PT.TABNAME='Name Simple Search')
	join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID
					and MC.MODULEID=-51)
	WHERE P.NAME = 'Internal Test'
End

-- Add Reports tab.
If not exists(Select * from PORTAL P 
                left join PORTALTAB PT  on (PT.PORTALID=P.PORTALID)
                where P.NAME = 'Internal Test'
                and PT.TABNAME = 'Reports')
Begin
    Insert into PORTALTAB (TABNAME, IDENTITYID, TABSEQUENCE, PORTALID)
    Select  'Reports',NULL,1,(Select PORTALID from PORTAL where NAME = 'Internal Test')
End

If exists (Select * from PORTAL P 
                left join PORTALTAB PT  on (PT.PORTALID=P.PORTALID)
                where P.NAME = 'Internal Test'
                and PT.TABNAME = 'Reports')
Begin
    -- Add Case Fees Reports
    If not exists (Select *
		    from PORTAL P
		    join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		    join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		    where 	P.NAME = 'Internal Test'
		    and	MC.MODULEID =-52
		    and	PT.TABNAME = 'Reports')
    Begin
	    -- Add the Case Fees web part
	    insert into MODULECONFIGURATION
	    (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	    select	NULL, PT.TABID, -52, 1, 'BottomPane', P.PORTALID
	    from	PORTAL P
	    join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	    where 	P.NAME = 'Internal Test'
	    and	PT.TABNAME = 'Reports'
    End
     -- Add Activity Reports
    If not exists (Select *
		    from PORTAL P
		    join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		    join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		    where 	P.NAME = 'Internal Test'
		    and	MC.MODULEID =-54
		    and	PT.TABNAME = 'Reports')
    Begin
	    insert into MODULECONFIGURATION
	    (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	    select	NULL, PT.TABID, -54, 3, 'BottomPane', P.PORTALID
	    from	PORTAL P
	    join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	    where 	P.NAME = 'Internal Test'
	    and	PT.TABNAME = 'Reports'
    End
     -- Add WIP Overview Reports
    If not exists (Select *
		    from PORTAL P
		    join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		    join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		    where 	P.NAME = 'Internal Test'
		    and	MC.MODULEID =-55
		    and	PT.TABNAME = 'Reports')
    Begin
	    insert into MODULECONFIGURATION
	    (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	    select	NULL, PT.TABID, -55, 4, 'BottomPane', P.PORTALID
	    from	PORTAL P
	    join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	    where 	P.NAME = 'Internal Test'
	    and	PT.TABNAME = 'Reports'
    End
End

-- Add CRM Reports tab to Internal Test Portal
If not exists(Select * from PORTAL P 
                left join PORTALTAB PT  on (PT.PORTALID=P.PORTALID)
                where P.NAME = 'Internal Test'
                and PT.TABNAME = 'CRM Reports')
Begin
    Insert into PORTALTAB (TABNAME, IDENTITYID, TABSEQUENCE, PORTALID)
    Select  'CRM Reports',NULL,
    (Select MAX(TABSEQUENCE) + 1 from PORTALTAB where PORTALID in (Select PORTALID from PORTAL where NAME = 'Internal Test')),
    (Select PORTALID from PORTAL where NAME = 'Internal Test')
End

If exists (Select * from PORTAL P 
                left join PORTALTAB PT  on (PT.PORTALID=P.PORTALID)
                where P.NAME = 'Internal Test'
                and PT.TABNAME = 'CRM Reports')
Begin
    -- Add Leads Reports
    If not exists (Select *
		    from PORTAL P
		    join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		    join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		    where 	P.NAME = 'Internal Test'
		    and	MC.MODULEID =-57
		    and	PT.TABNAME = 'CRM Reports')
    Begin
	    insert into MODULECONFIGURATION
	    (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	    select	NULL, PT.TABID, -57, 1, 'BottomPane', P.PORTALID
	    from	PORTAL P
	    join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	    where 	P.NAME = 'Internal Test'
	    and	PT.TABNAME = 'CRM Reports'
    End
     -- Add Opportunity Reports
    If not exists (Select *
		    from PORTAL P
		    join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		    join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		    where 	P.NAME = 'Internal Test'
		    and	MC.MODULEID =-58
		    and	PT.TABNAME = 'CRM Reports')
    Begin
	    insert into MODULECONFIGURATION
	    (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	    select	NULL, PT.TABID, -58, 2, 'BottomPane', P.PORTALID
	    from	PORTAL P
	    join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	    where 	P.NAME = 'Internal Test'
	    and	PT.TABNAME = 'CRM Reports'
    End
     -- Add Campaign Reports
    If not exists (Select *
		    from PORTAL P
		    join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		    join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		    where 	P.NAME = 'Internal Test'
		    and	MC.MODULEID =-59
		    and	PT.TABNAME = 'CRM Reports')
    Begin
	    insert into MODULECONFIGURATION
	    (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	    select	NULL, PT.TABID, -59, 3, 'BottomPane', P.PORTALID
	    from	PORTAL P
	    join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	    where 	P.NAME = 'Internal Test'
	    and	PT.TABNAME = 'CRM Reports'
    End
     -- Add Marketing Event Reports
    If not exists (Select *
		    from PORTAL P
		    join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		    join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		    where 	P.NAME = 'Internal Test'
		    and	MC.MODULEID =-61
		    and	PT.TABNAME = 'CRM Reports')
    Begin
	    insert into MODULECONFIGURATION
	    (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	    select	NULL, PT.TABID, -61, 4, 'BottomPane', P.PORTALID
	    from	PORTAL P
	    join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	    where 	P.NAME = 'Internal Test'
	    and	PT.TABNAME = 'CRM Reports'
    End
     -- Add Reciprocity Reports
    If not exists (Select *
		    from PORTAL P
		    join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		    join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		    where 	P.NAME = 'Internal Test'
		    and	MC.MODULEID =-56
		    and	PT.TABNAME = 'CRM Reports')
    Begin
	    insert into MODULECONFIGURATION
	    (IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	    select	NULL, PT.TABID, -56, 5, 'BottomPane', P.PORTALID
	    from	PORTAL P
	    join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	    where 	P.NAME = 'Internal Test'
	    and	PT.TABNAME = 'CRM Reports'
    End
End

-- Append a new tab for every internal web part that is not already present,
-- and not allocated to system administrator:

-- Get the Key of the new Portal

Select @nInternalPortalKey = PORTALID
from PORTAL
where NAME = 'Internal Test'    

-- Extract first web part to be appended:
Select @nCurrentModule = min(FM.MODULEID) 
from FEATUREMODULE FM
join FEATURE F 		on F.FEATUREID = FM.FEATUREID
WHERE F.ISINTERNAL = 1 
and FM.MODULEID not between -37 and -28 /* CRM modules suppressed */
and not exists (Select * 
		from PORTAL P
		join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
		join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
		where P.NAME = 'Internal Test'
		and MC.MODULEID = FM.MODULEID)
and not exists (Select * 
		from PORTAL P
		join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
		join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
		where P.NAME = 'System Administrator'
		and MC.MODULEID = FM.MODULEID)

If @nCurrentModule is null
Begin
	print '*****All possible internal modules are already in the Internal Test portal.'
End

While @nCurrentModule is not null
Begin
	Select @sModuleTitle = TITLE from MODULE where MODULEID = @nCurrentModule
	print '*****Addiing ' + @sModuleTitle + '(' + cast(@nCurrentModule as varchar(10)) + ') ModuleKey as a new Tab to the Internal Test portal.'	

	exec dbo.ua_AddModuleToConfiguration					
					@pnUserIdentityId	= 5,
					@psCulture		= null,	
					@pnIdentityKey		= null,
					@pnPortalKey		= @nInternalPortalKey,
					@pnModuleKey		= @nCurrentModule	

	-- Extract the next web part to be appended:
	Select @nCurrentModule = min(FM.MODULEID) 
	from FEATUREMODULE FM
	join FEATURE F 		on F.FEATUREID = FM.FEATUREID
	WHERE F.ISINTERNAL = 1 
	and FM.MODULEID not between -37 and -28 /* CRM modules suppressed */
	and not exists (Select * 
			from PORTAL P
			join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
			join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
			where P.NAME = 'Internal Test'
			and MC.MODULEID = FM.MODULEID)
	and not exists (Select * 
			from PORTAL P
			join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
			join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
			where P.NAME = 'System Administrator'
			and MC.MODULEID = FM.MODULEID)
	and FM.MODULEID > @nCurrentModule
End

-- Create a new user 'internal' with the Internal Test portal and the All Internal role:

If not exists (select * from USERIDENTITY where LOGINID = 'internal')
Begin
	print '*****Create a new user - internal'	

	insert into USERIDENTITY(LOGINID, PASSWORD, NAMENO, ISEXTERNALUSER, ISADMINISTRATOR, ACCOUNTID, ISVALIDINPROSTART, ISVALIDWORKBENCH, DEFAULTPORTALID)
	values ('internal',0xD1EFAD72DC5B17DC66A46767C32FFF40, -487, 0, 0, -1, 1, 1, @nInternalPortalKey)
End
Else Begin
	print '*****internal user already exists.'	
End

If exists ( 	Select  UI.IDENTITYID,
			R.ROLEID
		from ROLE R, USERIDENTITY UI 
		where ROLENAME in ('Internal', 'User', 'All Internal')
		and UI.LOGINID = 'internal'
		and not exists
			(select * from IDENTITYROLES IR
			 where IR.IDENTITYID = UI.IDENTITYID
			 and IR.ROLEID = R.ROLEID))
Begin
	print '*****Assign the All Internal role to the user internal'	

	insert into IDENTITYROLES (IDENTITYID, ROLEID)
	Select  UI.IDENTITYID,
		R.ROLEID
	from ROLE R, USERIDENTITY UI 
	where ROLENAME in ('Internal', 'User', 'All Internal')
	and UI.LOGINID = 'internal'
	and not exists
		(select * from IDENTITYROLES IR
		 where IR.IDENTITYID = UI.IDENTITYID
		 and IR.ROLEID = R.ROLEID)
End
Else Begin
	print '*****The All Internal role has already been assigned to the user internal'	
End

/******************************************************************************************/
/***** Creating an external user						      *****/
/******************************************************************************************/

-- 1) Create a new role All External for external use

If not exists (Select * from ROLE where ROLENAME = 'All External')
Begin
	print '*****Creating a new role All External for external use'
	
	insert 	into ROLE
		(ROLENAME, 
		 DESCRIPTION, 		 
		 ISEXTERNAL)
	values	('All External',
		 'The role with permissions granted for all possible external web parts, tasks and subjects.', 		
		 1)
End
Else Begin
	print '*****All External role already exists'
End

-- Grant all applicable permissions (except mandatory) to every 
-- external web part.

If exists (Select  *
	from FEATUREMODULE FM
	join FEATURE F 		on (F.FEATUREID = FM.FEATUREID)
	WHERE F.ISEXTERNAL = 1 
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'MODULE'
					and P.OBJECTINTEGERKEY = FM.MODULEID)
		where R.ROLENAME = 'All External')
	)
Begin
	print '*****Granting all applicable permissions (except mandatory) to every external web part.'	

	insert into PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION)
	Select  DISTINCT
		'MODULE',
		FM.MODULEID,
		NULL,
		'ROLE', 
		R.ROLEID,	
		CASE WHEN PR.SelectPermission 	= 1 THEN 1 	ELSE 0 END |
		CASE WHEN PR.InsertPermission 	= 1 THEN 8  	ELSE 0 END |
		CASE WHEN PR.UpdatePermission	= 1 THEN 2	ELSE 0 END |
		CASE WHEN PR.DeletePermission	= 1 THEN 16 	ELSE 0 END |
		CASE WHEN PR.ExecutePermission  = 1 THEN 32 	ELSE 0 END,		
		0
	from FEATUREMODULE FM
	join FEATURE F 		on F.FEATUREID = FM.FEATUREID
	join dbo.fn_PermissionRule('MODULE', NULL, NULL) PR	
				on (PR.ObjectTable = 'MODULE')
	join ROLE R		on (R.ROLENAME = 'All External')
	WHERE F.ISEXTERNAL = 1
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'MODULE'
					and P.OBJECTINTEGERKEY = FM.MODULEID)
		where R.ROLENAME = 'All External')
End
Else Begin
	print '*****All applicable permissions (except mandatory) are already granted to every external web part.'	
End

-- Grant all applicable permissions (except mandatory) to every 
-- external task.

If exists (Select  *
	from FEATURETASK FT
	where exists (Select *
		    from FEATURE F
		    where F.FEATUREID = FT.FEATUREID  
		    and	  F.ISEXTERNAL = 1)
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'TASK'
					and P.OBJECTINTEGERKEY = FT.TASKID)
		where R.ROLENAME = 'All External')
	)
Begin
	print '*****Granting all applicable permissions (except mandatory) to every external task.'	

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
	join ROLE R		on (R.ROLENAME = 'All External')
	where exists (Select *
		    from FEATURE F
		    where F.FEATUREID = FT.FEATUREID  
		    and	  F.ISEXTERNAL = 1)
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'TASK'
					and P.OBJECTINTEGERKEY = FT.TASKID)
		where R.ROLENAME = 'All External')
End
Else Begin
	print '*****All applicable permissions (except mandatory) are already granted to every external task.'	
End

-- Grant all applicable permissions (except mandatory) to every 
-- external subject.

If exists (select *
	from DATATOPIC DT
	where DT.ISEXTERNAL = 1
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'DATATOPIC'
					and P.OBJECTINTEGERKEY = DT.TOPICID)
		where R.ROLENAME = 'All External')
	)
Begin
	print '*****Granting all applicable permissions (except mandatory) to every external subject.'

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
	join ROLE R		on (R.ROLENAME = 'All External')
	WHERE DT.ISEXTERNAL = 1
	and not exists(
		select *
		from ROLE R
		join PERMISSIONS P	on (P.LEVELKEY = R.ROLEID
					and P.OBJECTTABLE = 'DATATOPIC'
					and P.OBJECTINTEGERKEY = DT.TOPICID)
		where R.ROLENAME = 'All External')
End
Else Begin
	print '*****All applicable permissions (except mandatory) are already granted to every external subject.'	
End

-- Create a new portal configuration External Test. This should copy the Client portal 
-- and then append a new tab for every external web part that is not already present.

If not exists (Select * from PORTAL where NAME = 'External Test')
Begin
	print '*****Creating a new portal configuration External Test.'

	insert into PORTAL (NAME, DESCRIPTION, ISEXTERNAL)
	values( 'External Test',
		'Based on the Client configuration, with all of the possible external web parts attached.',
		1)

	-- Copy Client portal tabs:
	
	If not exists (Select * from PORTALTAB PT, PORTAL P where P.PORTALID = PT.PORTALID and P.NAME = 'External Test')
	Begin
		print '*****Copying Client portal tabs.'
	
		insert into PORTALTAB (TABNAME, IDENTITYID, TABSEQUENCE, PORTALID)
		Select  PT.TABNAME,
			NULL,
			PT.TABSEQUENCE,
			(Select PORTALID from PORTAL where NAME = 'External Test')
		from PORTALTAB PT
		join PORTAL P			on (P.PORTALID = PT.PORTALID)
		where P.NAME = 'Client'
		and PT.IDENTITYID is null 
	End
	Else Begin
		print '*****Client portal tabs have already been copied for Internal Test portal.'	
	End
	
	-- Copy Client web parts:
	
	If not exists (	select * 
			from PORTALTAB PT
			join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
			join PORTAL P			on (P.PORTALID = PT.PORTALID)
			where P.NAME = 'External Test')
	Begin
		print '*****Copying Client portal web parts.'
	
		insert 	into MODULECONFIGURATION
			(TABID, 
			 MODULEID, 		 
			 MODULESEQUENCE,
			 PANELLOCATION)
		Select  PT2.TABID,
			MC.MODULEID, 		
			MC.MODULESEQUENCE,
			MC.PANELLOCATION
		from PORTAL P			
		join PORTALTAB PT		on (PT.PORTALID = P.PORTALID and PT.IDENTITYID is null)
		join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID and MC.IDENTITYID is null)
		join PORTAL P2			on (P2.NAME = 'External Test')
		join PORTALTAB PT2		on (PT2.PORTALID = P2.PORTALID
						and PT2.TABNAME = PT.TABNAME
						and PT2.TABSEQUENCE = PT.TABSEQUENCE)
		WHERE P.NAME = 'Client'
	End
	Else Begin
		print '*****Client portal web parts have already been copied for External Test portal.'	
	End
	
	-- Copy Client settings:
	
	If not exists (	select * 
			from PORTALTAB PT
			join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
			join PORTAL P			on (P.PORTALID = PT.PORTALID)
			join PORTALSETTING PS		on (PS.MODULECONFIGID = MC.CONFIGURATIONID)
			where P.NAME = 'External Test')
	Begin
		print '*****Copying Client portal settings.'
	
		insert into PORTALSETTING (MODULEID, MODULECONFIGID, IDENTITYID, SETTINGNAME, SETTINGVALUE)
		Select  PS.MODULEID,
			MC2.CONFIGURATIONID,
			PS.IDENTITYID,
			PS.SETTINGNAME,
			PS.SETTINGVALUE 
		from PORTAL P			
		join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
		join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
		join PORTALSETTING PS		on (PS.MODULECONFIGID = MC.CONFIGURATIONID)
		join PORTAL P2			on (P2.NAME = 'External Test')
		join PORTALTAB PT2		on (PT2.PORTALID = P2.PORTALID
						and PT2.TABSEQUENCE = PT.TABSEQUENCE)
		join MODULECONFIGURATION MC2 	on (MC2.TABID = PT2.TABID
						and MC2.MODULEID = MC.MODULEID)
		WHERE P.NAME = 'Client'
	End
	Else Begin
		print '*****Client portal settings have already been copied for External Test portal.'	
	End

End
Else Begin
	print '*****External Test portal configuration already exists.'	
End

/*
-- Implement Quick Links and My Links
If not exists (Select *
		from PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'External Test'
		and	MC.MODULEID in (-19,-20))
Begin
	-- Move any web part from the TopPane to the ContentPane
	update	MODULECONFIGURATION
	set	PANELLOCATION = 'ContentPane'
	from	PORTAL P
	join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	join 	MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
	where 	P.NAME = 'External Test'
	and	PT.TABSEQUENCE = 1
	and	MC.PANELLOCATION = 'TopPane'
	and	CONFIGURATIONID = MC.CONFIGURATIONID
	and	not exists(
		select *
		from	PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'External Test'
		and	PT.TABSEQUENCE = 1
		and	MC.PANELLOCATION = 'ContentPane')

	-- Add the Quick Links web part
	insert into MODULECONFIGURATION
	(IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	select	NULL, PT.TABID, -19, 1, 'LeftPane', P.PORTALID
	from	PORTAL P
	join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	where 	P.NAME = 'External Test'
	and	PT.TABSEQUENCE = 1
	and	not exists(
		select *
		from	PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'External Test'
		and	PT.TABSEQUENCE = 1
		and	MC.PANELLOCATION = 'LeftPane')

	-- Add the My Links web part
	insert into MODULECONFIGURATION
	(IDENTITYID, TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
	select	NULL, PT.TABID, -20, 1, 'RightPane', P.PORTALID
	from	PORTAL P
	join 	PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
	where 	P.NAME = 'External Test'
	and	PT.TABSEQUENCE = 1
	and	not exists(
		select *
		from	PORTAL P
		join PORTALTAB PT		on (PT.PORTALID=P.PORTALID)
		join MODULECONFIGURATION MC	on (MC.TABID=PT.TABID)
		where 	P.NAME = 'External Test'
		and	PT.TABSEQUENCE = 1
		and	MC.PANELLOCATION = 'RightPane')

End
*/

-- Append a new tab for every external web part that is not already present:

-- Get the Key of the new Portal

Select @nExternalPortalKey = PORTALID
from PORTAL
where NAME = 'External Test'    

-- Reset the @nCurrentModule variable
Set @nCurrentModule = null

-- Extract first web part to be appended:
Select @nCurrentModule = min(FM.MODULEID) 
from FEATUREMODULE FM
join FEATURE F 		on F.FEATUREID = FM.FEATUREID
WHERE F.ISEXTERNAL = 1 
and FM.MODULEID not between -37 and -28 /* CRM modules suppressed */
and not exists (Select * 
		from PORTAL P
		join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
		join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
		where P.NAME = 'External Test'
		and MC.MODULEID = FM.MODULEID)

If @nCurrentModule is null
Begin
	print '*****All possible external modules are already in the External Test portal.'
End

While @nCurrentModule is not null
Begin
	Select @sModuleTitle = TITLE from MODULE where MODULEID = @nCurrentModule
	print '*****Addiing ' + @sModuleTitle + '(' + cast(@nCurrentModule as varchar(10)) + ') ModuleKey as a new Tab to the External Test portal.'	

	exec dbo.ua_AddModuleToConfiguration					
					@pnUserIdentityId	= 5,
					@psCulture		= null,	
					@pnIdentityKey		= null,
					@pnPortalKey		= @nExternalPortalKey,
					@pnModuleKey		= @nCurrentModule	

	-- Extract the next web part to be appended:
	Select @nCurrentModule = min(FM.MODULEID) 
	from FEATUREMODULE FM
	join FEATURE F 		on F.FEATUREID = FM.FEATUREID
	WHERE F.ISEXTERNAL = 1 
	and FM.MODULEID not between -37 and -28 /* CRM modules suppressed */	
	and not exists (Select * 
			from PORTAL P
			join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
			join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
			where P.NAME = 'External Test'
			and MC.MODULEID = FM.MODULEID)
End

-- Create a new user 'external' with the External Test portal and the All External role:

If not exists (select * from USERIDENTITY where LOGINID = 'external')
Begin
	print '*****Create a new user - external'	

	insert into USERIDENTITY(LOGINID, PASSWORD, NAMENO, ISEXTERNALUSER, ISADMINISTRATOR, ACCOUNTID, ISVALIDINPROSTART, ISVALIDWORKBENCH, DEFAULTPORTALID)
	values ('external',0x6A21B6995A068148BBB65C8F949B3FB2, 144, 1, 0, 2, 1, 1, @nExternalPortalKey)
End
Else Begin
	print '*****external user already exists.'	
End

If exists ( 	Select  UI.IDENTITYID,
			R.ROLEID
		from ROLE R, USERIDENTITY UI 
		where ROLENAME in ('External', 'User', 'All External')
		and UI.LOGINID = 'external'
		and not exists
			(select * from IDENTITYROLES IR
			 where IR.IDENTITYID = UI.IDENTITYID
			 and IR.ROLEID = R.ROLEID))
Begin
	print '*****Assign the All External role to the user internal'	

	insert into IDENTITYROLES (IDENTITYID, ROLEID)
	Select  UI.IDENTITYID,
		R.ROLEID
	from ROLE R, USERIDENTITY UI 
	where ROLENAME in ('External', 'User', 'All External')
	and UI.LOGINID = 'external'
	and not exists
		(select * from IDENTITYROLES IR
		 where IR.IDENTITYID = UI.IDENTITYID
		 and IR.ROLEID = R.ROLEID)
End
Else Begin
	print '*****The All External role has already been assigned to the user external'	
End

GO

If NOT exists(	Select * 
		from SETTINGVALUES 
		where IDENTITYID = (	Select IDENTITYID 
					from USERIDENTITY 
					where LOGINID = 'internal') 
		and SETTINGID = 2)
BEGIN
	 PRINT '**** RFC3142 Inserting data SETTINGVALUES for SETTINGID = 2 for internal user'
 Insert into SETTINGVALUES (SETTINGID, IDENTITYID, COLCHARACTER, COLINTEGER, COLDECIMAL, COLBOOLEAN)
 Select 2, IDENTITYID, NULL, NULL, NULL, 1
 from USERIDENTITY
 where LOGINID = 'internal'
 PRINT '**** RFC3142 Data successfully inserted into SETTINGVALUES table.'
 PRINT ''
	END
ELSE
	PRINT '**** RFC3142 SETTINGID = 2 for internal user already exists'
	PRINT ''
go

If NOT exists(	Select * 
	from SETTINGVALUES 
	where IDENTITYID = (Select IDENTITYID from USERIDENTITY where LOGINID = 'internal') 
	and SETTINGID = 3)
    BEGIN
        PRINT '**** RFC3142 Inserting data SETTINGVALUES for SETTINGID = 3 for internal user'
        Insert into SETTINGVALUES (SETTINGID, IDENTITYID, COLCHARACTER, COLINTEGER, COLDECIMAL, COLBOOLEAN)
        Select 3, IDENTITYID, N'ExchDevTest@dev.cpaglobal.net', NULL, NULL, NULL
        from USERIDENTITY
        where LOGINID = 'internal'
        PRINT '**** RFC3142 Data successfully inserted into SETTINGVALUES table.'
        PRINT ''
	END
    ELSE BEGIN
        IF EXISTS (SELECT * FROM SETTINGVALUES
                    WHERE SETTINGID = 3
                    AND COLCHARACTER = 'KYLEN'
                    AND IDENTITYID = (Select IDENTITYID 
				                        from USERIDENTITY 
				                        where LOGINID = 'internal'))
	    BEGIN
            PRINT '**** RFC5778 Updating data SETTINGVALUES for SETTINGID = 3 for internal user'
            UPDATE SETTINGVALUES
            SET COLCHARACTER = 'ExchDevTest@dev.cpaglobal.net'
            WHERE SETTINGID = 3
            AND COLCHARACTER = 'KYLEN'
            AND IDENTITYID = (Select IDENTITYID 
				    from USERIDENTITY 
				    where LOGINID = 'internal')
            PRINT '**** RFC5778 SETTINGID = 3 for crm user has been updated successfully.'
            PRINT ''
        END
        ELSE BEGIN
            PRINT '**** RFC5778 SETTINGID = 3 for crm user already exists/updated.'
            PRINT ''
        END
    END
go

If NOT exists(	Select * 
	from SETTINGVALUES 
	where IDENTITYID = (	Select IDENTITYID 
				from USERIDENTITY 
				where LOGINID = 'internal') 
	and SETTINGID = 4)
BEGIN
	 PRINT '**** RFC3142 Inserting data SETTINGVALUES for SETTINGID = 3 for internal user'
 Insert into SETTINGVALUES (SETTINGID, IDENTITYID, COLCHARACTER, COLINTEGER, COLDECIMAL, COLBOOLEAN)
 Select 4, IDENTITYID, NULL, NULL, NULL, 1
 from USERIDENTITY
 where LOGINID = 'internal'
 PRINT '**** RFC3142 Data successfully inserted into SETTINGVALUES table.'
 PRINT ''
	END
ELSE
	PRINT '**** RFC3142 SETTINGID = 4 for internal user already exists'
	PRINT ''
go

If NOT exists(	Select * 
	from SETTINGVALUES 
	where IDENTITYID = (	Select IDENTITYID 
				from USERIDENTITY 
				where LOGINID = 'internal') 
	and SETTINGID = 5)
BEGIN
	 PRINT '**** RFC3142 Inserting data SETTINGVALUES for SETTINGID = 5 for internal user'
 Insert into SETTINGVALUES (SETTINGID, IDENTITYID, COLCHARACTER, COLINTEGER, COLDECIMAL, COLBOOLEAN)
 Select 5, IDENTITYID, NULL, NULL, 10.50, NULL
 from USERIDENTITY
 where LOGINID = 'internal'
 PRINT '**** RFC3142 Data successfully inserted into SETTINGVALUES table.'
 PRINT ''
	END
ELSE
	PRINT '**** RFC3142 SETTINGID = 5 for internal user already exists'
	PRINT ''
go

PRINT '**** RFC3162 Create default mapping rules.'

exec dm_InsertExactMappings
	@pnUserIdentityId	= 5,
	@pbCalledFromCentura	= 0,
	@pnFromSchemeKey	= -1,
	@pnMapStructureKey	= 1
go

exec dm_InsertExactMappings
	@pnUserIdentityId	= 5,
	@pbCalledFromCentura	= 0,
	@pnFromSchemeKey	= -1,
	@pnMapStructureKey	= 2
go

exec dm_InsertExactMappings
	@pnUserIdentityId	= 5,
	@pbCalledFromCentura	= 0,
	@pnFromSchemeKey	= -1,
	@pnMapStructureKey	= 3
go

exec dm_InsertExactMappings
	@pnUserIdentityId	= 5,
	@pbCalledFromCentura	= 0,
	@pnFromSchemeKey	= -1,
	@pnMapStructureKey	= 4
go

exec dm_InsertExactMappings
	@pnUserIdentityId	= 5,
	@pbCalledFromCentura	= 0,
	@pnFromSchemeKey	= -1,
	@pnMapStructureKey	= 5
go


/******************************************************************************************/
/***** RFC3195 Ensure IRN generation rules produce unique IRN			      *****/
/******************************************************************************************/
-- Add default rule to generate a numeric stem for all cases
If not exists (Select * from INTERNALREFSTEM where CASETYPE is null and PROPERTYTYPE is null
		and CASEOFFICEID is null and COUNTRYCODE is null and CASECATEGORY is null)
Begin
	INSERT INTO INTERNALREFSTEM (STEMUNIQUENO, CASETYPE,PROPERTYTYPE,LEADINGZEROSFLAG,NUMBEROFDIGITS,NEXTAVAILABLESTEM)
	SELECT MAX(STEMUNIQUENO)+1, NULL,NULL,0,5,0
	FROM INTERNALREFSTEM
End
go
-- Update default rule to CountryCode+PropertyType+NewNumericStem
If not exists (Select * from IRFORMAT where CRITERIANO = -160538 and SEGMENT3CODE=1464)
Begin
	UPDATE IRFORMAT 
	SET SEGMENT1CODE=1451,
	SEGMENT2CODE=1450,
	SEGMENT3CODE=1464,
	SEGMENT4CODE=NULL,
	SEGMENT5CODE=NULL
	WHERE CRITERIANO = -160538
End
GO

/**********************************************************************************************************/
/*** RFC3515 Update data in the SITECONTROL table							***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = N'SMART POLICING' AND COLBOOLEAN NOT IN (1))
BEGIN
	 PRINT '**** RFC3515 Updating data in the SITECONTROL table for Smart Policing.'
 UPDATE SITECONTROL
 SET COLBOOLEAN = 1
 WHERE UPPER(CONTROLID) = N'SMART POLICING'
 PRINT '**** RFC3515 SITECONTROL table for Smart Policing has been updated successfully.'
 PRINT ''
	END
ELSE
	PRINT '**** RFC3515 SITECONTROL table for Smart Policing has already been updated.'
	PRINT ''
go

If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = N'SMART POLICING ONLY' AND COLBOOLEAN NOT IN (1))
BEGIN
	 PRINT '**** RFC3515 Updating data in the SITECONTROL table for Smart Policing Only.'
 UPDATE SITECONTROL
 SET COLBOOLEAN = 1
 WHERE UPPER(CONTROLID) = N'SMART POLICING ONLY'
 PRINT '**** RFC3515 SITECONTROL table for Smart Policing has been updated successfully.'
 PRINT ''
	END
ELSE
	PRINT '**** RFC3515 SITECONTROL table for Smart Policing has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC3644 Make an alias type available to external users						***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'CLIENT NAME ALIAS TYPES' AND COLCHARACTER is null)
BEGIN
	 PRINT '**** RFC3644 Updating data in the SITECONTROL table for Client Name Alias Types.'
	 UPDATE SITECONTROL
	 SET COLCHARACTER = N'AA'
	 WHERE UPPER(CONTROLID) = 'CLIENT NAME ALIAS TYPES' AND COLCHARACTER is null
	 PRINT '**** RFC3644 SITECONTROL table for Client Name Alias Types has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3644 SITECONTROL table for Client Name Alias Types has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC3644 Make all instruction types except Examination available to external users			***/
/**********************************************************************************************************/     
Declare @sInstructionTypes	nvarchar(4000)
Set @sInstructionTypes 		= ''

-- Extract all the instruction types at the current site:
Select @sInstructionTypes = @sInstructionTypes+','+INSTRUCTIONTYPE
from INSTRUCTIONTYPE
WHERE INSTRUCTIONTYPE<>'E'

-- Cut off the comma (',') from the beginning of the @sInstructionTypes string:
Set @sInstructionTypes = SUBSTRING(@sInstructionTypes, 2, 4000)


If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'CLIENT INSTRUCTION TYPES' AND COLCHARACTER <> @sInstructionTypes)
BEGIN
	 PRINT '**** RFC3644 Updating data in the SITECONTROL table for Client Instruction Types.'
	 UPDATE SITECONTROL
	 SET COLCHARACTER = @sInstructionTypes
	 WHERE UPPER(CONTROLID) = 'CLIENT INSTRUCTION TYPES'
	 PRINT '**** RFC3644 SITECONTROL table for Client Instruction Types has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3644 SITECONTROL table for Client Instruction Types has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC3214 Turn on time out for internal users.  Leave off for external						***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'TIME OUT INTERNAL USERS' AND COLBOOLEAN=0)
BEGIN
	 PRINT '**** RFC3214 Updating data in the SITECONTROL table for Time out internal users.'
	 UPDATE SITECONTROL
	 SET COLBOOLEAN = 1
	 WHERE UPPER(CONTROLID) = 'TIME OUT INTERNAL USERS' AND COLBOOLEAN=0
	 PRINT '**** RFC3214 SITECONTROL table for Time out internal users has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3214 SITECONTROL table for Time out internal users has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** Set address type for chinese tranlsations								***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'ADDRESS STYLE ZH-CHS' AND COLINTEGER is null)
BEGIN
	 PRINT '**** RFC3301 Updating data in the SITECONTROL table for Chinese Address Style.'
	 UPDATE SITECONTROL
	 SET COLINTEGER = 7208
	 WHERE UPPER(CONTROLID) = 'ADDRESS STYLE ZH-CHS' AND COLINTEGER is null
	 PRINT '**** RFC3301 SITECONTROL table for Chinese Address Style has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3301 SITECONTROL table for Chinese Address Style has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC2985 Define external activity categories							***/
/**********************************************************************************************************/     
If not exists (SELECT * FROM TABLECODES WHERE UPPER(DESCRIPTION) = 'GENERAL' AND TABLETYPE=59)
BEGIN
	 PRINT '**** RFC2985 Adding Activity Category=General for external use'
	 Declare @nTableCode int

	 update  LASTINTERNALCODE
	 Set	INTERNALSEQUENCE=INTERNALSEQUENCE+1,
		@nTableCode       =INTERNALSEQUENCE+1
	 where   TABLENAME='TABLECODES'

	 INSERT INTO TABLECODES (TABLECODE, TABLETYPE, DESCRIPTION)
	 VALUES (@nTableCode,59,'General')

	 UPDATE SITECONTROL
	 SET COLCHARACTER = COLCHARACTER+nullif(',',COLCHARACTER+',')+cast(@nTableCode as nvarchar(10))
	 WHERE UPPER(CONTROLID) = 'CLIENT ACTIVITY CATEGORIES' 
	 AND patindex('%'+','+cast(@nTableCode as nvarchar(50))+','+'%',',' + replace(COLCHARACTER, ' ', '') + ',')=0
	 PRINT '**** RFC2985 Activity Category=General for external use has been added successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 Activity Category=General for external use has already been added.'
	PRINT ''
go

If not exists (SELECT * FROM TABLECODES WHERE UPPER(DESCRIPTION) = 'INSTRUCTIONS' AND TABLETYPE=59)
BEGIN
	 PRINT '**** RFC2985 Adding Activity Category=Instructions for external use'
	 Declare @nTableCode int

	 update  LASTINTERNALCODE
	 Set	INTERNALSEQUENCE=INTERNALSEQUENCE+1,
		@nTableCode       =INTERNALSEQUENCE+1
	 where   TABLENAME='TABLECODES'

	 INSERT INTO TABLECODES (TABLECODE, TABLETYPE, DESCRIPTION)
	 VALUES (@nTableCode,59,'Instructions')

	 UPDATE SITECONTROL
	 SET COLCHARACTER = COLCHARACTER+nullif(',',COLCHARACTER+',')+cast(@nTableCode as nvarchar(10))
	 WHERE UPPER(CONTROLID) = 'CLIENT ACTIVITY CATEGORIES' 
	 AND patindex('%'+','+cast(@nTableCode as nvarchar(50))+','+'%',',' + replace(COLCHARACTER, ' ', '') + ',')=0
	 PRINT '**** RFC2985 Activity Category=Instructions for external use has been added successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 Activity Category=Instructions for external use has already been added.'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC2985 Set up Client Request doc item site controls							***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'CLIENT REQUEST CASE SUMMARY' AND COLCHARACTER is null)
BEGIN
	 PRINT '**** RFC2985 Updating data in the SITECONTROL table for Client Request Case Summary.'
	 UPDATE SITECONTROL
	 SET COLCHARACTER='EG_CLIENT_REQUEST_SUMMARY'
	 WHERE UPPER(CONTROLID) = 'CLIENT REQUEST CASE SUMMARY' AND COLCHARACTER is null
	 PRINT '**** RFC2985 SITECONTROL table for Client Request Case Summary has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 SITECONTROL table for Client Request Case Summary has already been updated.'
	PRINT ''
go

If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'CLIENT REQUEST EMAIL SUBJECT' AND COLCHARACTER is null)
BEGIN
	 PRINT '**** RFC2985 Updating data in the SITECONTROL table for Client Request Email Subject.'
	 UPDATE SITECONTROL
	 SET COLCHARACTER='EG_CLIENT_REQUEST_SUBJECT'
	 WHERE UPPER(CONTROLID) = 'CLIENT REQUEST EMAIL SUBJECT' AND COLCHARACTER is null
	 PRINT '**** RFC2985 SITECONTROL table for Client Request Email Subject has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 SITECONTROL table for Client Request Email Subject has already been updated.'
	PRINT ''
go

If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'CLIENT REQUEST EMAIL BODY' AND COLCHARACTER is null)
BEGIN
	 PRINT '**** RFC2985 Updating data in the SITECONTROL table for Client Request Email Body.'
	 UPDATE SITECONTROL
	 SET COLCHARACTER='EG_CLIENT_REQUEST_BODY'
	 WHERE UPPER(CONTROLID) = 'CLIENT REQUEST EMAIL BODY' AND COLCHARACTER is null
	 PRINT '**** RFC2985 SITECONTROL table for Client Request Email Body has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 SITECONTROL table for Client Request Email Body has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** Set up Additional Internal Staff site control							***/
/**********************************************************************************************************/     
If not exists (SELECT * FROM NAMETYPE WHERE NAMETYPE = 'PR')
BEGIN
	 PRINT '**** RFC2985 Adding Name Type = Alternate Staff'

	 INSERT INTO NAMETYPE (NAMETYPE, DESCRIPTION, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, PICKLISTFLAGS, MAXIMUMALLOWED)
	 VALUES ('PR','Paralegal', 0, 0, 0, 0,2,1)

	 UPDATE SITECONTROL
	 SET COLCHARACTER = 'PR'
	 WHERE UPPER(CONTROLID) = 'ADDITIONAL INTERNAL STAFF' 
	 AND COLCHARACTER IS NULL
	 PRINT '**** RFC2985 Name Type = Alternate Staff has been added successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 Name Type = Alternate Staff has already been added.'
	PRINT ''
go

/**********************************************************************************************************/
/*** Set up Agent Category site control									***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'AGENT CATEGORY' AND COLINTEGER is null)
BEGIN
	 PRINT '**** RFC2985 Updating data in the SITECONTROL table for Agent Category.'
	 UPDATE SITECONTROL
	 SET COLINTEGER=7
	 WHERE UPPER(CONTROLID) = 'AGENT CATEGORY' AND COLINTEGER is null
	 PRINT '**** RFC2985 SITECONTROL table for Agent Category has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 SITECONTROL table for Agent Category has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** Set up NationalityUsePostal									***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = N'NATIONALITYUSEPOSTAL' AND COLBOOLEAN NOT IN (1))
BEGIN
	 PRINT '**** Updating data in the SITECONTROL table for NationalityUsePostal.'
 UPDATE SITECONTROL
 SET COLBOOLEAN = 1
 WHERE UPPER(CONTROLID) = N'NATIONALITYUSEPOSTAL'
 PRINT '**** SITECONTROL table for NationalityUsePostal has been updated successfully.'
 PRINT ''
	END
ELSE
	PRINT '**** SITECONTROL table for NationalityUsePostal has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** Set up Duplicate Organisation Check									***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = N'DUPLICATE ORGANISATION CHECK' AND COLBOOLEAN NOT IN (1))
BEGIN
	 PRINT '**** Updating data in the SITECONTROL table for Duplicate Organisation Check.'
 UPDATE SITECONTROL
 SET COLBOOLEAN = 1
 WHERE UPPER(CONTROLID) = N'DUPLICATE ORGANISATION CHECK'
 PRINT '**** SITECONTROL table for Duplicate Organisation Check has been updated successfully.'
 PRINT ''
	END
ELSE
	PRINT '**** SITECONTROL table for Duplicate Organisation Check has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** Set up Duplicate Individual Check site control									***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'DUPLICATE INDIVIDUAL CHECK' AND COLINTEGER=0)
BEGIN
	 PRINT '**** RFC2985 Updating data in the SITECONTROL table for Duplicate Individual Check.'
	 UPDATE SITECONTROL
	 SET COLINTEGER=1
	 WHERE UPPER(CONTROLID) = 'DUPLICATE INDIVIDUAL CHECK' AND COLINTEGER=0
	 PRINT '**** RFC2985 SITECONTROL table for Duplicate Individual Check has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 SITECONTROL table for Duplicate Individual Check has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** Set up Generate Name Code site control									***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = 'GENERATENAMECODE' AND COLINTEGER=0)
BEGIN
	 PRINT '**** RFC2985 Updating data in the SITECONTROL table for Generate Name Code.'
	 UPDATE SITECONTROL
	 SET COLINTEGER=1
	 WHERE UPPER(CONTROLID) = 'GENERATENAMECODE' AND COLINTEGER=0
	 PRINT '**** RFC2985 SITECONTROL table for Generate Name Code has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 SITECONTROL table for Generate Name Code has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** Set up Name Variant									***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = N'NAME VARIANT' AND COLBOOLEAN NOT IN (1))
BEGIN
	 PRINT '**** Updating data in the SITECONTROL table for Name Variant.'
 UPDATE SITECONTROL
 SET COLBOOLEAN = 1
 WHERE UPPER(CONTROLID) = N'NAME VARIANT'
 PRINT '**** SITECONTROL table for Name Variant has been updated successfully.'
 PRINT ''
	END
ELSE
	PRINT '**** SITECONTROL table for Name Variant has already been updated.'
	PRINT ''
go

-- Turn on the Name Variant column for owners
If not exists (SELECT * FROM NAMETYPE WHERE NAMETYPE = 'O' AND COLUMNFLAGS&512=512)
BEGIN
	 PRINT '**** RFC2985 Updating Name Type = Owner'

	 UPDATE NAMETYPE
	 SET COLUMNFLAGS=COLUMNFLAGS|512
	 WHERE NAMETYPE='O'

	 PRINT '**** RFC2985 Name Type = Owner has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 Name Type = Owner has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** RFC3720 Set up change of responsibility testing							***/
/**********************************************************************************************************/     
-- Illustrate defaulting from HomeName
	-- Existing name relationship Renewal Agent (AGT)
	-- Create Renewal Agents by country & property type on Home Name No
	-- Create an overriding Renewal Agent against another name (42 Brimstone Holdings)
	-- Existing case name type Renewal Agent (&) - Set inherit from home name and Instructor

-- Renewal Agent associated names for home name no
--	US  Trademark 	-5908900	Robbins Berliner & Carson
--	US		-5710000		Ladas & Parry
--	    Design	-5546000	Hasse, Seaffe & Solly

If not exists (SELECT * FROM ASSOCIATEDNAME 
		JOIN SITECONTROL H ON (H.CONTROLID='HOMENAMENO')
		WHERE RELATIONSHIP = 'AGT'
		AND NAMENO=H.COLINTEGER
		AND RELATEDNAME=-5908900)
BEGIN
	 PRINT '**** RFC3720 Adding Renewal Agent - Robbins Berliner & Carson'

	 INSERT INTO ASSOCIATEDNAME (NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE, PROPERTYTYPE, COUNTRYCODE)
	 SELECT H.COLINTEGER, 'AGT', -5908900, 0, 'T', 'US'
	 FROM SITECONTROL H
	 WHERE H.CONTROLID='HOMENAMENO'

	 PRINT '**** RFC3720 Renewal Agent has been added successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3720 Renewal Agent - Robbins Berliner & Carson has already been added.'
	PRINT ''
go

If not exists (SELECT * FROM ASSOCIATEDNAME 
		JOIN SITECONTROL H ON (H.CONTROLID='HOMENAMENO')
		WHERE RELATIONSHIP = 'AGT'
		AND NAMENO=H.COLINTEGER
		AND RELATEDNAME=-5710000)
BEGIN
	 PRINT '**** RFC3720 Adding Renewal Agent - Ladas & Parry'

	 INSERT INTO ASSOCIATEDNAME (NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE, PROPERTYTYPE, COUNTRYCODE)
	 SELECT H.COLINTEGER, 'AGT', -5710000, 0, null, 'US'
	 FROM SITECONTROL H
	 WHERE H.CONTROLID='HOMENAMENO'

	 PRINT '**** RFC3720 Renewal Agent has been added successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3720 Renewal Agent - Ladas & Parry has already been added.'
	PRINT ''
go

If not exists (SELECT * FROM ASSOCIATEDNAME 
		JOIN SITECONTROL H ON (H.CONTROLID='HOMENAMENO')
		WHERE RELATIONSHIP = 'AGT'
		AND NAMENO=H.COLINTEGER
		AND RELATEDNAME=-5546000)
BEGIN
	 PRINT '**** RFC3720 Adding Renewal Agent - Hasse, Seaffe & Solly'

	 INSERT INTO ASSOCIATEDNAME (NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE, PROPERTYTYPE, COUNTRYCODE)
	 SELECT H.COLINTEGER, 'AGT', -5546000, 0, 'D', null
	 FROM SITECONTROL H
	 WHERE H.CONTROLID='HOMENAMENO'

	 PRINT '**** RFC3720 Renewal Agent has been added successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3720 Renewal Agent - Hasse, Seaffe & Solly has already been added.'
	PRINT ''
go

-- Renewal Agent associated names for Brimstone Holdings
--	-496	Origami & Beech

If not exists (SELECT * FROM ASSOCIATEDNAME 
		WHERE RELATIONSHIP = 'AGT'
		AND NAMENO=42
		AND RELATEDNAME=-496)
BEGIN
	 PRINT '**** RFC3720 Adding Renewal Agent - Origami & Beech'

	 INSERT INTO ASSOCIATEDNAME (NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE, PROPERTYTYPE, COUNTRYCODE)
	 VALUES(42, 'AGT', -496, 0, null, null)

	 PRINT '**** RFC3720 Renewal Agent has been added successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3720 Renewal Agent - Origami & Beech has already been added.'
	PRINT ''
go

-- Update Renewal Agent Name Type
If exists (Select * from NAMETYPE where NAMETYPE='&' and USEHOMENAMEREL<>1)
BEGIN
	 PRINT '**** RFC3093 Updating data in the NAMETYPE table for &.'

	 UPDATE NAMETYPE
	 SET USEHOMENAMEREL = 1, HIERARCHYFLAG=0, PATHNAMETYPE='I'
	 WHERE NAMETYPE = '&'

	 PRINT '**** RFC3720 NAMETYPE table for & has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3720 NAMETYPE table for & has already been updated.'
	PRINT ''
go

-- Illustrate Case Name Change Event
	-- Create change event Add/Update New Renewal Instructor
		-- Note: have not set up any events and entries rules.
	-- Create name type New Renewal Instructor (NRI) with change event and Commence Date
	-- Attach NRI to Renewal Names group so will appear in the UI
	-- Existing name type Renewal Instructor (R) - set New Name Type

If not exists (SELECT * FROM EVENTS WHERE UPPER(EVENTDESCRIPTION) = 'ADD/UPDATE NEW RENEWAL INSTRUCTOR')
BEGIN
	 PRINT '**** RFC3720 Adding Event=Add/Update New Renewal Instructor'
	 Declare @nEventKey int

	 update  LASTINTERNALCODE
	 Set	INTERNALSEQUENCE=(Select MAX(EVENTNO) FROM EVENTS)
	 where   TABLENAME='EVENTS'

	 update  LASTINTERNALCODE
	 Set	INTERNALSEQUENCE=INTERNALSEQUENCE+1,
		@nEventKey       =INTERNALSEQUENCE+1
	 where   TABLENAME='EVENTS'

	 INSERT INTO EVENTS (EVENTNO, EVENTCODE, EVENTDESCRIPTION, NUMCYCLESALLOWED, IMPORTANCELEVEL, CONTROLLINGACTION, DEFINITION, CLIENTIMPLEVEL, CATEGORYID, PROFILEREFNO, RECALCEVENTDATE)
	 VALUES (@nEventKey,null,'Add/Update New Renewal Instructor',1,'5',null,'A new Renewal Instructor has been added for the case.','5',null,null,null)

	 PRINT '**** RFC3720 Event=Add/Update New Renewal Instructor has been added successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3720 Event=Add/Update New Renewal Instructor has already been added.'
	PRINT ''
go

If not exists (SELECT * FROM NAMETYPE WHERE NAMETYPE = 'NRI')
BEGIN
	 PRINT '**** RFC2985 Adding Name Type = New Renewal Instructor'

	 INSERT INTO NAMETYPE (NAMETYPE, DESCRIPTION, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, PICKLISTFLAGS, MAXIMUMALLOWED,CHANGEEVENTNO)
	 SELECT 'NRI','New Renewal Instructor',0,0,KEEPSTREETFLAG,COLUMNFLAGS|16,PICKLISTFLAGS,MAXIMUMALLOWED,E.EVENTNO
	 FROM NAMETYPE
	 LEFT JOIN EVENTS E ON (UPPER(E.EVENTDESCRIPTION) = 'ADD/UPDATE NEW RENEWAL INSTRUCTOR')
	 WHERE NAMETYPE='R'

	 -- Add to Renewal Names group
	 INSERT INTO GROUPMEMBERS (NAMEGROUP,NAMETYPE)
	 VALUES (503,'NRI')

	 PRINT '**** RFC2985 Name Type = New Renewal Instructor has been added successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC2985 Name Type = New Renewal Instructor has already been added.'
	PRINT ''
go

If exists (Select * from NAMETYPE where NAMETYPE='R' and FUTURENAMETYPE IS NULL)
BEGIN
	 PRINT '**** RFC3093 Updating data in the NAMETYPE table for R.'

	 UPDATE NAMETYPE
	 SET FUTURENAMETYPE='NRI'
	 WHERE NAMETYPE = 'R'

	 PRINT '**** RFC3720 NAMETYPE table for R has been updated successfully.'
	 PRINT ''
	END
ELSE
	PRINT '**** RFC3720 NAMETYPE table for R has already been updated.'
	PRINT ''
go

/**********************************************************************************************************/
/*** Turn on US PTO Private Pair Enabled									***/
/**********************************************************************************************************/     
If exists (SELECT * FROM SITECONTROL WHERE UPPER(CONTROLID) = N'USPTO PRIVATE PAIR ENABLED' AND COLBOOLEAN NOT IN (1))
BEGIN
	 PRINT '**** Updating data in the SITECONTROL table for USPTO Private PAIR Enabled.'
 UPDATE SITECONTROL
 SET COLBOOLEAN = 1
 WHERE UPPER(CONTROLID) = N'USPTO PRIVATE PAIR ENABLED'
 PRINT '**** SITECONTROL table for USPTO Private PAIR Enabled has been updated successfully.'
 PRINT ''
	END
ELSE
	PRINT '**** SITECONTROL table for USPTO Private PAIR Enabled has already been updated.'
	PRINT ''
go

	/**********************************************************************************************************/
	/*** RFC2984 Add due event to renewal charge		   	  					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from CHARGETYPE where CHARGETYPENO=99996 AND CHARGEDUEEVENT is not null)
		begin
		 PRINT '**** RFC2984 Updating due event for Renewals'
		 UPDATE CHARGETYPE SET CHARGEDUEEVENT=-100
		 WHERE CHARGETYPENO=99996 AND CHARGEDUEEVENT is null
		 PRINT '**** RFC2984 Data has been successfully updated to Charge Type for Renewals.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2984 Due event for Renewals already exists.'
		PRINT ''
 	go

	/**********************************************************************************************************/
	/*** RFC2984 Add incurred event to renewal charge		   	  					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from CHARGETYPE where CHARGETYPENO=99996 AND CHARGEINCURREDEVENT is not null)
		begin
		 PRINT '**** RFC2984 Updating incurred event for Renewals'
		 UPDATE CHARGETYPE SET CHARGEINCURREDEVENT=-111
		 WHERE CHARGETYPENO=99996 AND CHARGEINCURREDEVENT is null
		 PRINT '**** RFC2984 Data has been successfully updated to Charge Type for Renewals.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2984 Incurred event for Renewals already exists.'
		PRINT ''
 	go

	/**********************************************************************************************************/
	/*** RFC2984 Add renewal extension as second rate type for renewal charge		   	  					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from CHARGERATES where CHARGETYPENO=99996 AND RATENO=99998)
		begin
		 PRINT '**** RFC2984 Add renewal extension to Renewals charge type'
		 INSERT INTO CHARGERATES(CHARGETYPENO, RATENO)
		 VALUES (99996,99998)
		 PRINT '**** RFC2984 Data has been successfully updated to Charge Type for Renewals.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2984 Renewal Extension rate for Renewals already exists.'
		PRINT ''
 	go

	/**********************************************************************************************************/
	/*** RFC2984 Change renewal extension to calculate off the period bewteen two dates so that fine calculations are availble ***/
	/**********************************************************************************************************/
	UPDATE FEESCALCULATION
	SET  	PARAMETERSOURCE=CASE WHEN DISBWIPCODE IS NOT NULL THEN 18 ELSE PARAMETERSOURCE END ,
		PARAMETERSOURCE2=CASE WHEN SERVWIPCODE IS NOT NULL THEN 18 ELSE PARAMETERSOURCE2 END
	FROM CRITERIA C
	WHERE C.PURPOSECODE='F'
	AND C.RATENO=99998
	AND C.CRITERIANO=FEESCALCULATION.CRITERIANO
	and (isnull(PARAMETERSOURCE,18)<>18 or isnull(PARAMETERSOURCE2,18)<>18 or (PARAMETERSOURCE2 is null and SERVWIPCODE is not null ))

	/**********************************************************************************************************/
	/*** RFC2984 Add due event to filing charge		   	  					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from CHARGETYPE where CHARGETYPENO=100000 AND CHARGEDUEEVENT is not null)
		begin
		 PRINT '**** RFC2984 Updating due event for filings'

		declare @applicationConventionDeadlineEvent int
		Select @applicationConventionDeadlineEvent = E.EVENTNO
		from [EVENTS] E
		where E.EVENTDESCRIPTION = 'Application convention deadline'

		 UPDATE CHARGETYPE SET CHARGEDUEEVENT=@applicationConventionDeadlineEvent
		 WHERE CHARGETYPENO=100000 AND CHARGEDUEEVENT is null
		 PRINT '**** RFC2984 Data has been successfully updated to Charge Type for filing.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2984 Due event for filings already exists.'
		PRINT ''
 	go

	/**********************************************************************************************************/
	/*** RFC2984 Add incurred event to filing charge		   	  					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from CHARGETYPE where CHARGETYPENO=100000 AND CHARGEINCURREDEVENT is not null)
		begin
		 PRINT '**** RFC2984 Updating incurred event for filing'
		 UPDATE CHARGETYPE SET CHARGEINCURREDEVENT=-4
		 WHERE CHARGETYPENO=100000 AND CHARGEINCURREDEVENT is null
		 PRINT '**** RFC2984 Data has been successfully updated to Charge Type for filing.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2984 Incurred event for filing already exists.'
		PRINT ''
 	go

	/**********************************************************************************************************/
	/*** RFC3218 Make some charges public		   	  					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from CHARGETYPE where CHARGETYPENO in (100000,99996) AND PUBLICFLAG=1)
		begin
		 PRINT '**** RFC3218 Updating public flag on charge types'
		 UPDATE CHARGETYPE SET PUBLICFLAG=1
		 WHERE CHARGETYPENO in (100000,99996) AND isnull(PUBLICFLAG,0)=0
		 PRINT '**** RFC2984 Data has been successfully updated to Charge Type.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC3218 Public flags for charges types already updated.'
		PRINT ''
 	go

	/**********************************************************************************************************/
	/*** RFC2982 Add data Instruction Definition for Renewals		   	  					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from INSTRUCTIONDEFINITION where INSTRUCTIONNAME = 'Renewals')
		begin
		 PRINT '**** RFC2982 Inserting Instruction Definition for Renewals'
		 INSERT INTO INSTRUCTIONDEFINITION (INSTRUCTIONNAME, AVAILABILITYFLAGS, EXPLANATION, ACTION, USEMAXCYCLE, DUEEVENTNO, PREREQUISITEEVENTNO, INSTRUCTNAMETYPE, CHARGETYPENO)
		 VALUES ('Renewals', 7, 'A renewal fee needs to be paid to retain protection for this intellectual property', 'RN',1,-11,null,'R',99996)
		 PRINT '**** RFC2982 Data has been successfully added to Instruction Definition for Renewals.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2982 Instruction Definition for Renewals already exists.'
		PRINT ''
 	go

	IF NOT exists (select * from INSTRUCTIONRESPONSE R JOIN INSTRUCTIONDEFINITION D ON (D.INSTRUCTIONNAME = 'Renewals') WHERE R.LABEL='Pay')
		begin
		 PRINT '**** RFC2982 Inserting Instruction Response Pay'
		 INSERT INTO INSTRUCTIONRESPONSE (DEFINITIONID, SEQUENCENO, LABEL, FIREEVENTNO, EXPLANATION, DISPLAYEVENTNO, HIDEEVENTNO, NOTESPROMPT)
		 SELECT D.DEFINITIONID, 1, 'Pay', -111, 'Proceed with payment of renewal fee', -694, null, null
		 FROM INSTRUCTIONDEFINITION D
		 WHERE D.INSTRUCTIONNAME='Renewals'
		 PRINT '**** RFC2982 Data has been successfully added to Instruction Response Pay.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2982 Instruction Response Pay already exists.'
		PRINT ''
 	go

	IF NOT exists (select * from INSTRUCTIONRESPONSE R JOIN INSTRUCTIONDEFINITION D ON (D.INSTRUCTIONNAME = 'Renewals') WHERE R.LABEL='Abandon')
		begin
		 PRINT '**** RFC2982 Inserting Instruction Response Abandon'
		 INSERT INTO INSTRUCTIONRESPONSE (DEFINITIONID, SEQUENCENO, LABEL, FIREEVENTNO, EXPLANATION, DISPLAYEVENTNO, HIDEEVENTNO, NOTESPROMPT)
		 SELECT D.DEFINITIONID, 2, 'Abandon', -141, 'Protection for this intellectual property is no longer required', null, null, null
		 FROM INSTRUCTIONDEFINITION D
		 WHERE D.INSTRUCTIONNAME='Renewals'
		 PRINT '**** RFC2982 Data has been successfully added to Instruction Response Abandon.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2982 Instruction Response Abandon already exists.'
		PRINT ''
 	go

	IF NOT exists (select * from INSTRUCTIONRESPONSE R JOIN INSTRUCTIONDEFINITION D ON (D.INSTRUCTIONNAME = 'Renewals') WHERE R.LABEL='Other Channel')
		begin
		 PRINT '**** RFC2982 Inserting Instruction Response Other Channel'
		 INSERT INTO INSTRUCTIONRESPONSE (DEFINITIONID, SEQUENCENO, LABEL, FIREEVENTNO, EXPLANATION, DISPLAYEVENTNO, HIDEEVENTNO, NOTESPROMPT)
		 SELECT D.DEFINITIONID, 3, 'Other Channel', -183, 'Renewal of this property is being handled by another party', null, null, 'Please provide the name of the other party.'
		 FROM INSTRUCTIONDEFINITION D
		 WHERE D.INSTRUCTIONNAME='Renewals'
		 PRINT '**** RFC2982 Data has been successfully added to Instruction Response Other Channel.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2982 Instruction Response Other Channel already exists.'
		PRINT ''
 	go

	/**********************************************************************************************************/
	/*** RFC2982 Add data Instruction Definition for Official Action		   	  					***/
	/**********************************************************************************************************/
	IF NOT exists (select * from INSTRUCTIONDEFINITION where INSTRUCTIONNAME = 'Official Action')
		begin
		 PRINT '**** RFC2982 Inserting Instruction Definition for Official Action'
		 INSERT INTO INSTRUCTIONDEFINITION (INSTRUCTIONNAME, AVAILABILITYFLAGS, EXPLANATION, ACTION, USEMAXCYCLE, DUEEVENTNO, PREREQUISITEEVENTNO, INSTRUCTNAMETYPE, CHARGETYPENO)
		 VALUES ('Official Action', 1, 'A response is required to a query from an intellectual property office', null,0,null,-50,'I',null)
		 PRINT '**** RFC2982 Data has been successfully added to Instruction Definition for Official Action.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2982 Instruction Definition for Official Action already exists.'
		PRINT ''
 	go

	IF NOT exists (select * from INSTRUCTIONRESPONSE R JOIN INSTRUCTIONDEFINITION D ON (D.INSTRUCTIONNAME = 'Official Action') WHERE R.LABEL='Reply')
		begin
		 PRINT '**** RFC2982 Inserting Instruction Response Reply'
		 INSERT INTO INSTRUCTIONRESPONSE (DEFINITIONID, SEQUENCENO, LABEL, FIREEVENTNO, EXPLANATION, DISPLAYEVENTNO, HIDEEVENTNO, NOTESPROMPT)
		 SELECT D.DEFINITIONID, 1, 'Reply', -52, 'Notify your response has been provided', -52, null, 'Details of your response'
		 FROM INSTRUCTIONDEFINITION D
		 WHERE D.INSTRUCTIONNAME='Official Action'
		 PRINT '**** RFC2982 Data has been successfully added to Instruction Response Reply.'
		 PRINT ''	
		END
	ELSE
		PRINT '**** RFC2982 Instruction Response Reply already exists.'
		PRINT ''
 	go
 	
 	/**********************************************************************************************************/
    /*** RFC2982 Initialise/Refresh data for Provide Instructions		***/
	/**********************************************************************************************************/    
	If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_LoadCaseInstructAllowed]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	Begin 
		PRINT '**** RFC2982 Call ip_LoadCaseInstructAllowed'
		exec ip_LoadCaseInstructAllowed 
				@pbClearExisting=1		
		PRINT '**** RFC2982 CaseInstructAllowed loaded with test data'
	End
	go

	/**********************************************************************************************************/
    	/*** RFC3646 Initial Data for Document Request Maintenance		***/
	/**********************************************************************************************************/ 
	IF NOT exists (select * from TABLECODES where TABLECODE = 14201)
		begin
		 PRINT '**** RFC3646 Inserting Event Group - Prosecution Events'
		 Insert into TABLECODES(TABLECODE,TABLETYPE,DESCRIPTION)
		  Values(14201,142,'Prosecution Events')

		 PRINT '**** RFC3646 Event Group - Prosecution Events successfully added'
		 PRINT ''	
		END
	ELSE
		PRINT '**** **** RFC3646 Event Group - Prosecution Events already exists.'
		PRINT ''
		
	IF NOT exists (select * from TABLECODES where TABLECODE = 14202)
		begin
		 PRINT '**** RFC3646 Inserting Event Group - Filing Events'
		 Insert into TABLECODES(TABLECODE,TABLETYPE,DESCRIPTION)
		  Values(14202,142,'Filing Events')

		 PRINT '**** RFC3646 Event Group - Filing Events successfully added'
		 PRINT ''	
		END
	ELSE
		PRINT '**** **** RFC3646 Event Group - Filing Events already exists.'
		PRINT ''
	IF NOT exists (select * from TABLECODES where TABLECODE = 14203)
		begin
		 PRINT '**** RFC3646 Inserting Event Group - Renewal Events'
		 Insert into TABLECODES(TABLECODE,TABLETYPE,DESCRIPTION)
		  Values(14203,142,'Renewal Events')

		 PRINT '**** RFC3646 Event Group - Renewal Events successfully added'
		 PRINT ''	
		END
	ELSE
		PRINT '**** **** RFC3646 Event Group - Renewal Events already exists.'
		PRINT ''
 	go
/**********************************************************************************************************/
	/*** RFC4901 Set up Default Portal Configuration for Clerical ***/
/**********************************************************************************************************/
	Declare @TransactionCountStart 	int
	Declare @ErrorCode		int
	Declare	@RowCount		int

	If not exists (Select * from PORTALTAB where TABNAME = 'My Portal' and TABSEQUENCE = 6 and PORTALID = 4)
		Begin
			print '*****RFC4901 Creating a new My Portal tab for Clerical portal'
				insert into PORTALTAB(TABNAME, TABSEQUENCE,PORTALID)
				values('My Portal', 6, 4)			
		End
		Else Begin
			print '*****RFC4901 My Portal tab has already been inserted for Clerical portal.'	
		End
	
	Set @ErrorCode = 0
	-- Commence the transaction
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION	
	IF NOT exists(Select * from MODULECONFIGURATION where CONFIGURATIONID = 38 and PANELLOCATION = 'TopPane')
			BEGIN
			 PRINT '**** RFC4901 Updating data in MODULECONFIGURATION table for CONFIGURATIONID = 38'	
				update MODULECONFIGURATION
				set TABID = PT.TABID, PANELLOCATION = 'TopPane'
				from PORTALTAB PT
				where CONFIGURATIONID = 38
				and PT.TABSEQUENCE = 6
				and PT.PORTALID = 4
				and PT.TABNAME = 'My Portal'				

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in MODULECONFIGURATION table for CONFIGURATIONID = 38.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 MODULECONFIGURATION table for CONFIGURATIONID = 38 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** MODULECONFIGURATION table for CONFIGURATIONID = 38.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	
	GO
/**********************************************************************************************************/
	/*** RFC4901 Set up Default Portal Configuration for External Test ***/
/**********************************************************************************************************/
	Declare @TransactionCountStart 	int
	Declare @ErrorCode		int
	Declare	@RowCount		int

	If not exists (Select * from PORTALTAB where TABNAME = 'My Portal' and TABSEQUENCE = 8 and PORTALID = 3)
		Begin
			print '*****RFC4901 Creating a new My Portal tab for External Test portal'
				insert into PORTALTAB(TABNAME, TABSEQUENCE,PORTALID)
				values('My Portal', 8, 3)		
		End
		Else Begin
			print '*****RFC4901 My Portal tab has already been inserted for External Test portal.'	
		End

	Set @ErrorCode = 0
	-- Commence the transaction
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION	
	IF NOT exists(Select * from MODULECONFIGURATION where CONFIGURATIONID = 23 and PANELLOCATION = 'TopPane')
			BEGIN
			 PRINT '**** RFC4901 Updating data in MODULECONFIGURATION table for CONFIGURATIONID = 23'	
				update MODULECONFIGURATION
				set TABID = PT.TABID, PANELLOCATION = 'TopPane'
				from PORTALTAB PT
				where CONFIGURATIONID = 23
				and PT.TABSEQUENCE = 8
				and PT.PORTALID = 3
				and PT.TABNAME = 'My Portal'

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in MODULECONFIGURATION table for CONFIGURATIONID = 23.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 MODULECONFIGURATION table for CONFIGURATIONID = 23 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** MODULECONFIGURATION table for CONFIGURATIONID = 23.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	
	GO
/**********************************************************************************************************/
	/*** RFC4901 Set up Default Portal Configuration for Internal Test ***/
/**********************************************************************************************************/
	Declare @TransactionCountStart 	int
	Declare @ErrorCode		int
	Declare	@RowCount		int

	If not exists (Select * from PORTALTAB where TABNAME = 'My Portal' and TABSEQUENCE = 8 and PORTALID = 2)
		Begin
			print '*****RFC4901 Creating a new My Portal tab for Internal Test portal'
				insert into PORTALTAB(TABNAME, TABSEQUENCE,PORTALID)
				values('My Portal', 8, 2)		
		End
		Else Begin
			print '*****RFC4901 My Portal tab has already been inserted for Internal Test portal.'	
		End
	
	Set @ErrorCode = 0
	-- Commence the transaction
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION	
	IF NOT exists(Select * from MODULECONFIGURATION where CONFIGURATIONID = 13 and PANELLOCATION = 'TopPane')
			BEGIN
			 PRINT '**** RFC4901 Updating data in MODULECONFIGURATION table for CONFIGURATIONID = 13'	
				update MODULECONFIGURATION
				set TABID = PT.TABID, PANELLOCATION = 'TopPane'
				from PORTALTAB PT
				where CONFIGURATIONID = 13
				and PT.TABSEQUENCE = 8
				and PT.PORTALID = 2
				and PT.TABNAME = 'My Portal'

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in MODULECONFIGURATION table for CONFIGURATIONID = 13.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 MODULECONFIGURATION table for CONFIGURATIONID = 13 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** MODULECONFIGURATION table for CONFIGURATIONID = 23.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	

	IF NOT exists(Select * from MODULECONFIGURATION where CONFIGURATIONID = 40 and TABID = 5 and PANELLOCATION = 'TopPane')
			BEGIN
			 PRINT '**** RFC4901 Updating data in MODULECONFIGURATION table for CONFIGURATIONID = 40'	
				update MODULECONFIGURATION
				set TABID = 5, PANELLOCATION = 'TopPane', MODULESEQUENCE='2'
				where CONFIGURATIONID = 40

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in MODULECONFIGURATION table for CONFIGURATIONID = 40.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 MODULECONFIGURATION table for CONFIGURATIONID = 40 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** MODULECONFIGURATION table for CONFIGURATIONID = 40.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	
	GO
/**********************************************************************************************************/
	/*** RFC4901 Set up Default Portal Configuration for Client Activity ***/
/**********************************************************************************************************/
	Declare @TransactionCountStart 	int
	Declare @ErrorCode		int
	Declare	@RowCount		int

	If not exists (Select * from PORTALTAB where TABNAME = 'My Portal' and TABSEQUENCE = 2 and PORTALID = -5)
		Begin
			print '*****RFC4901 Creating a new My Portal tab for Client Activity portal'
				insert into PORTALTAB(TABNAME, TABSEQUENCE,PORTALID)
				values('My Portal', 2, -5)		
		End
		Else Begin
			print '*****RFC4901 My Portal tab has already been inserted for Client Activity portal.'	
		End
	
	Set @ErrorCode = 0
	-- Commence the transaction
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION	
	IF NOT exists(Select * from MODULECONFIGURATION where CONFIGURATIONID = 6 and PANELLOCATION = 'TopPane')
			BEGIN
			 PRINT '**** RFC4901 Updating data in MODULECONFIGURATION table for CONFIGURATIONID = 6'	
				update MODULECONFIGURATION
				set TABID = PT.TABID, PANELLOCATION = 'TopPane'
				from PORTALTAB PT
				where CONFIGURATIONID = 6
				and PT.TABSEQUENCE = 2
				and PT.PORTALID = -5
				and PT.TABNAME = 'My Portal'

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in MODULECONFIGURATION table for CONFIGURATIONID = 6.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 MODULECONFIGURATION table for CONFIGURATIONID = 6 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** MODULECONFIGURATION table for CONFIGURATIONID = 6.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	

	IF NOT exists(Select * from PORTALTAB where TABSEQUENCE = 3 and TABID = -19 and PORTALID = -5)
			BEGIN
			 PRINT '**** RFC4901 Updating data in PORTALTAB where TABSEQUENCE = 3 and TABID = -19 and PORTALID = -5'	
				update PORTALTAB
				set TABSEQUENCE = 3
				where TABID = -19
				and PORTALID = -5

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in PORTALTAB where TABSEQUENCE = 3 and TABID = -19 and PORTALID = -5.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 PORTALTAB where TABSEQUENCE = 3 and TABID = -19 and PORTALID = -5 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** PORTALTAB where TABSEQUENCE = 3 and TABID = -19 and PORTALID = -5.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	
	GO
/**********************************************************************************************************/
	/*** RFC4901 Set up Default Portal Configuration for Client Without Reminders ***/
/**********************************************************************************************************/
	Declare @TransactionCountStart 	int
	Declare @ErrorCode		int
	Declare	@RowCount		int

	If not exists (Select * from PORTALTAB where TABNAME = 'My Portal' and TABSEQUENCE = 3 and PORTALID = -4)
		Begin
			print '*****RFC4901 Creating a new My Portal tab for Client Without Reminders portal'
				insert into PORTALTAB(TABNAME, TABSEQUENCE,PORTALID)
				values('My Portal', 3, -4)		
		End
		Else Begin
			print '*****RFC4901 My Portal tab has already been inserted for Client Without Reminders portal.'	
		End
	
	Set @ErrorCode = 0
	-- Commence the transaction
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION	
	IF NOT exists(Select * from MODULECONFIGURATION where CONFIGURATIONID = 5 and PANELLOCATION = 'TopPane')
			BEGIN
			 PRINT '**** RFC4901 Updating data in MODULECONFIGURATION table for CONFIGURATIONID = 5'	
				update MODULECONFIGURATION
				set TABID = PT.TABID, PANELLOCATION = 'TopPane'
				from PORTALTAB PT
				where CONFIGURATIONID = 5
				and PT.TABSEQUENCE = 3
				and PT.PORTALID = -4
				and PT.TABNAME = 'My Portal'

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in MODULECONFIGURATION table for CONFIGURATIONID = 5.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 MODULECONFIGURATION table for CONFIGURATIONID = 5 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** MODULECONFIGURATION table for CONFIGURATIONID = 5.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	

	IF NOT exists(Select * from PORTALTAB where TABSEQUENCE = 4 and TABID = -17 and PORTALID = -4)
			BEGIN
			 PRINT '**** RFC4901 Updating data in PORTALTAB where TABSEQUENCE = 4 and TABID = -17 and PORTALID = -4'	
				update PORTALTAB
				set TABSEQUENCE = 4
				where TABID = -17
				and PORTALID = -4

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in PORTALTAB where TABSEQUENCE = 4 and TABID = -17 and PORTALID = -4.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 PORTALTAB where TABSEQUENCE = 4 and TABID = -17 and PORTALID = -4 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** PORTALTAB where TABSEQUENCE = 4 and TABID = -17 and PORTALID = -4.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	
	GO
/**********************************************************************************************************/
	/*** RFC4901 Set up Default Portal Configuration for Administrator ***/
/**********************************************************************************************************/
	Declare @TransactionCountStart 	int
	Declare @ErrorCode		int
	Declare	@RowCount		int

	If not exists (Select * from PORTALTAB where TABNAME = 'My Portal' and TABSEQUENCE = 5 and PORTALID = -1)
		Begin
			print '*****RFC4901 Creating a new My Portal tab for Administrator portal'
				insert into PORTALTAB(TABNAME, TABSEQUENCE,PORTALID)
				values('My Portal', 5, -1)		
		End
		Else Begin
			print '*****RFC4901 My Portal tab has already been inserted for Administrator portal.'	
		End
	
	Set @ErrorCode = 0
	-- Commence the transaction
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION	
	IF NOT exists(Select * from MODULECONFIGURATION where CONFIGURATIONID = 4 and PANELLOCATION = 'TopPane')
			BEGIN
			 PRINT '**** RFC4901 Updating data in MODULECONFIGURATION table for CONFIGURATIONID = 4'	
				update MODULECONFIGURATION
				set TABID = PT.TABID, PANELLOCATION = 'TopPane'
				from PORTALTAB PT
				where CONFIGURATIONID = 4
				and PT.TABSEQUENCE = 5
				and PT.PORTALID = -1
				and PT.TABNAME = 'My Portal'

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in MODULECONFIGURATION table for CONFIGURATIONID = 4.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 MODULECONFIGURATION table for CONFIGURATIONID = 4 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** MODULECONFIGURATION table for CONFIGURATIONID = 4.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	

	IF NOT exists(Select * from PORTALTAB where TABSEQUENCE = 6 and TABID = -7 and PORTALID = -1)
			BEGIN
			 PRINT '**** RFC4901 Updating data in PORTALTAB where TABSEQUENCE = 6 and TABID = -7 and PORTALID = -1'	
				update PORTALTAB
				set TABSEQUENCE = 6
				where TABID = -7
				and PORTALID = -1

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in PORTALTAB where TABSEQUENCE = 6 and TABID = -7 and PORTALID = -1.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 PORTALTAB where TABSEQUENCE = 6 and TABID = -7 and PORTALID = -1 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** PORTALTAB where TABSEQUENCE = 6 and TABID = -7 and PORTALID = -1.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	
	GO
/**********************************************************************************************************/
	/*** RFC4901 Set up Default Portal Configuration for Client ***/
/**********************************************************************************************************/
	Declare @TransactionCountStart 	int
	Declare @ErrorCode		int
	Declare	@RowCount		int

	If not exists (Select * from PORTALTAB where TABNAME = 'My Portal' and TABSEQUENCE = 4 and PORTALID = -2)
		Begin
			print '*****RFC4901 Creating a new My Portal tab for Client portal'
				insert into PORTALTAB(TABNAME, TABSEQUENCE,PORTALID)
				values('My Portal', 4, -2)	
		End
		Else Begin
			print '*****RFC4901 My Portal tab has already been inserted for Client portal.'	
		End
	
	Set @ErrorCode = 0
	-- Commence the transaction
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION	
	IF NOT exists(Select * from MODULECONFIGURATION where CONFIGURATIONID = 3 and PANELLOCATION = 'TopPane')
			BEGIN
			 PRINT '**** RFC4901 Updating data in MODULECONFIGURATION table for CONFIGURATIONID = 3'	
				update MODULECONFIGURATION
				set TABID = PT.TABID, PANELLOCATION = 'TopPane'
				from PORTALTAB PT
				where CONFIGURATIONID = 3
				and PT.TABSEQUENCE = 4
				and PT.PORTALID = -2
				and PT.TABNAME = 'My Portal'

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in MODULECONFIGURATION table for CONFIGURATIONID = 3.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 MODULECONFIGURATION table for CONFIGURATIONID = 3 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** MODULECONFIGURATION table for CONFIGURATIONID = 3.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	

	IF NOT exists(Select * from PORTALTAB where TABSEQUENCE = 5 and TABID = -6 and PORTALID = -2)
			BEGIN
			 PRINT '**** RFC4901 Updating data in PORTALTAB where TABSEQUENCE = 5 and TABID = -6 and PORTALID = -2'	
				update PORTALTAB
				set TABSEQUENCE = 5
				where TABID = -6
				and PORTALID = -2

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in PORTALTAB where TABSEQUENCE = 5 and TABID = -6 and PORTALID = -2.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 PORTALTAB where TABSEQUENCE = 5 and TABID = -6 and PORTALID = -2 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** PORTALTAB where TABSEQUENCE = 5 and TABID = -6 and PORTALID = -2.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	
	GO
/**********************************************************************************************************/
	/*** RFC4901 Set up Default Portal Configuration for Professional ***/
/**********************************************************************************************************/
	Declare @TransactionCountStart 	int
	Declare @ErrorCode		int
	Declare	@RowCount		int

	If not exists (Select * from PORTALTAB where TABNAME = 'My Portal' and TABSEQUENCE = 5 and PORTALID = -3)
		Begin
			print '*****RFC4901 Creating a new My Portal tab for Professional portal'
				insert into PORTALTAB(TABNAME, TABSEQUENCE,PORTALID)
				values('My Portal', 5, -3)	
		End
		Else Begin
			print '*****RFC4901 My Portal tab has already been inserted for Professional portal.'	
		End
	
	Set @ErrorCode = 0
	-- Commence the transaction
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION	
	IF NOT exists(Select * from MODULECONFIGURATION where CONFIGURATIONID = 2 and PANELLOCATION = 'TopPane')
			BEGIN
			 PRINT '**** RFC4901 Updating data in MODULECONFIGURATION table for CONFIGURATIONID = 3'	
				update MODULECONFIGURATION
				set TABID = PT.TABID, PANELLOCATION = 'TopPane'
				from PORTALTAB PT
				where CONFIGURATIONID = 2
				and PT.TABSEQUENCE = 5
				and PT.PORTALID = 3
				and PT.TABNAME = 'My Portal'

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in MODULECONFIGURATION table for CONFIGURATIONID = 2.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 MODULECONFIGURATION table for CONFIGURATIONID = 2 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** MODULECONFIGURATION table for CONFIGURATIONID = 2.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	

	IF NOT exists(Select * from PORTALTAB where TABSEQUENCE = 6 and TABID = -5 and PORTALID = -3)
			BEGIN
			 PRINT '**** RFC4901 Updating data in PORTALTAB where TABSEQUENCE = 5 and TABID = -5 and PORTALID = -3'	
				update PORTALTAB
				set TABSEQUENCE = 6
				where TABID = -5
				and PORTALID = -3

				Select	@ErrorCode=@@Error,
				@RowCount =@@RowCount		
			END

	If @@TranCount > @TransactionCountStart
	Begin		
		If @ErrorCode = 0
		Begin
			If @RowCount>0
				Begin
				 PRINT '**** RFC4901 Data has been successfully updated in PORTALTAB where TABSEQUENCE = 6 and TABID = -5 and PORTALID = -3.'
				 PRINT ''
				End
			Else
				Begin
	         		 PRINT '**** RFC4901 PORTALTAB where TABSEQUENCE = 6 and TABID = -5 and PORTALID = -3 has already been updated.'
	         		 PRINT ''
				End		
			COMMIT TRANSACTION
		End
		Else Begin
			PRINT '**** RFC4901 ****** FAIL ****** PORTALTAB where TABSEQUENCE = 6 and TABID = -5 and PORTALID = -3.'
			PRINT ''
			ROLLBACK TRANSACTION
		End
	End	
	GO

	/**********************************************************************************************************/
	/***  RFC5704 Insert IDENTITYROWACCESS.IDENTITYID = 26						***/
	/**********************************************************************************************************/
--	If NOT exists(SELECT * FROM IDENTITYROWACCESS WHERE ACCESSNAME = 'Full Access' and IDENTITYID = 26)
--        	BEGIN
--         	 PRINT '**** RFC5704 Adding IDENTITYROWACCESS data IDENTITYID = 26'
--		 INSERT	IDENTITYROWACCESS (ACCESSNAME, IDENTITYID) 
--		 VALUES ('Full Access', 26)
--        	 PRINT '**** RFC5704 Data successfully added to IDENTITYROWACCESS table.'
--		 PRINT ''
--         	END
--    	ELSE
--         	BEGIN
--         	 PRINT '**** RFC5704 IDENTITYROWACCESS IDENTITYID = 26 already exists'
--		 PRINT ''
--         	END
--    	go
--	and exists (Select * from ROWACCESS)

	/**********************************************************************************************************/
	/***  RFC3210 Clean up corrupted data from RELATEDCASE							***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM RELATEDCASE WHERE RELATEDCASEID = -376 AND RELATIONSHIPNO = 5 and CASEID = -401)
        	BEGIN
			Update RELATEDCASE
			Set RELATEDCASEID = -376
			where CASEID = -401
			and RELATIONSHIPNO = 5

			Delete from RELATEDCASE
			where CASEID = -401
			and RELATIONSHIPNO = 73
         		PRINT '**** RFC3210 Cleaning up corrupted data from RELATEDCASE sucessfully.'
         	END
		ELSE
		BEGIN
			PRINT '**** RFC3210 corrupted data already removed.'
		END
    	go
	If NOT exists(SELECT * FROM RELATEDCASE WHERE RELATEDCASEID = -372 and RELATIONSHIPNO = 11 and CASEID = -401)
        	BEGIN
			Update RELATEDCASE
			Set RELATEDCASEID = -372
			where CASEID = -401
			and RELATIONSHIPNO = 11

			Delete from RELATEDCASE
			where CASEID = -401
			and RELATIONSHIPNO = 75
         		PRINT '**** RFC3210 Cleaning up corrupted data from RELATEDCASE sucessfully.'
         	END
		ELSE
		BEGIN
			PRINT '**** RFC3210 corrupted data already removed.'
		END
    	go
	If NOT exists(SELECT * FROM RELATEDCASE WHERE RELATEDCASEID = -375 and RELATIONSHIPNO = 45  and CASEID = -401)
        	BEGIN
			Update RELATEDCASE
			Set RELATEDCASEID = -375
			where CASEID = -401
			and RELATIONSHIPNO = 45

			Delete from RELATEDCASE
			where CASEID = -401
			and RELATIONSHIPNO = 74
         		PRINT '**** RFC3210 Cleaning up corrupted data from RELATEDCASE sucessfully.'
         	END
		ELSE
		BEGIN
			PRINT '**** RFC3210 corrupted data already removed.'
		END
    	go
	If NOT exists(SELECT * FROM RELATEDCASE WHERE RELATEDCASEID = -377 and RELATIONSHIPNO = 13 and CASEID = -401)
        	BEGIN
			Update RELATEDCASE
			Set RELATEDCASEID = -377
			where CASEID = -401
			and RELATIONSHIPNO = 13

			Delete from RELATEDCASE
			where CASEID = -401
			and RELATIONSHIPNO = 72
         		PRINT '**** RFC3210 Cleaning up corrupted data from RELATEDCASE sucessfully.'
         	END
		ELSE
		BEGIN
			PRINT '**** RFC3210 corrupted data already removed.'
		END
    	go
	If exists(SELECT * FROM RELATEDCASE WHERE CASEID = 14 and RELATIONSHIPNO = 39 and RELATIONSHIP = 'DC1')
        	BEGIN
			Delete from RELATEDCASE
			where RELATIONSHIP = 'DC1'
			and CASEID = 14
			and RELATIONSHIPNO = 39
         		PRINT '**** RFC3210 Cleaning up corrupted data from RELATEDCASE sucessfully.'
         	END
		ELSE
		BEGIN
			PRINT '**** RFC3210 corrupted data already removed.'
		END
    	go	
	/**********************************************************************************************************/
	/***  RFC6126 Clean up corrupted data from CASETEXT							***/
	/**********************************************************************************************************/
	If exists(select * from CASETEXT where datalength(TEXT) <= 508 and LONGFLAG = 1)
		BEGIN
			Update CASETEXT
			Set LONGFLAG = 0,
			SHORTTEXT = cast(TEXT as nvarchar(254))		
			where datalength(TEXT) <= 508 and LONGFLAG = 1
			PRINT '**** RFC6126 Clean up corrupted data from CASETEXT sucessfully.'
		END
		GO
	
	/**********************************************************************************************************/
	/***  RFC6420 Create CRM Test Data	--- limit licenses						***/
	/**********************************************************************************************************/
	
	if exists(select * from LICENSE WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        18%'))
	Begin
		print '***** -- Delete the existing unlimited case Professional WorkBench license.'
		delete 
		from LICENSE 
		WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        18%')
		print '***** -- Existing unlimited case Professional WorkBench license deleted.'
	End

	if exists(select * from LICENSE WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        19%'))
	Begin
		print '***** -- Delete the existing unlimited case Manager WorkBench license.'
		delete 
		from LICENSE 
		WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        19%')
		print '***** -- Existing unlimited case Manager WorkBench license deleted.'
	End

	if exists(select * from LICENSE WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        20%'))
	Begin
		print '***** -- Delete the existing unlimited case Marketing WorkBench license.'
		delete 
		from LICENSE 
		WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        20%')
		print '***** -- Existing unlimited case Marketing WorkBench license deleted.'
	End

	if exists(select * from LICENSE WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        21%'))
	Begin
		print '***** -- Delete the existing unlimited case Clerical WorkBench license.'
		delete 
		from LICENSE 
		WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        21%')
		print '***** -- Existing unlimited case Clerical WorkBench license deleted.'
	End
	
	if exists(select * from LICENSE WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        25%'))
	Begin
		print '***** -- Delete the existing unlimited case CRM WorkBench license.'
		delete 
		from LICENSE 
		WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        25%')
		print '***** -- Existing unlimited case CRM WorkBench license deleted.'
	End

	
	if exists(select * from LICENSE WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        27%'))
	Begin
		print '***** -- Delete the existing unlimited case Administrator WorkBench license.'
		delete 
		from LICENSE 
		WHERE dbo.fn_Decrypt(DATA, 0) like ('%-1        27%')
		print '***** -- Existing unlimited case Administrator WorkBench license deleted.'
	End

	-- Professional
	if not exists(select * 
			from LICENSE 
			WHERE DATA = '5V"S-OHgV6%T-&DPODCk(OTU:BOPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WXe:KVTU-')
	Begin
		print '***** -- Insert a new limited Professional WorkBench License (with 5 users)'
		INSERT INTO LICENSE (DATA) 
		VALUES ('5V"S-OHgV6%T-&DPODCk(OTU:BOPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WXe:KVTU-')
		print '***** -- New limited Professional WorkBench License (with 5 users) inserted successfully.'
	End

	-- Managers
	if not exists(select * 
			from LICENSE 
			WHERE DATA = '5V"S-OHgV6%T-&DPODCl(OTU=2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WWc:KVTU-')
	Begin
		print '***** -- Insert a new limited Professional WorkBench License (with 5 users)'
		INSERT INTO LICENSE (DATA) 
		VALUES ('5V"S-OHgV6%T-&DPODCl(OTU=2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WWc:KVTU-')
		print '***** -- New limited Professional WorkBench License (with 5 users) inserted successfully.'
	End

	-- Marketing
	if not exists(select * 
			from LICENSE 
			WHERE DATA = '5V"S-OHgV6%T-&DPODDc(OTU=2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WVe:KVTU-')
	Begin
		print '***** -- Insert a new limited Professional WorkBench License (with 5 users)'
		INSERT INTO LICENSE (DATA) 
		VALUES ('5V"S-OHgV6%T-&DPODDc(OTU=2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WVe:KVTU-')
		print '***** -- New limited Professional WorkBench License (with 5 users) inserted successfully.'
	End

	-- CRM
	if not exists(select * 
			from LICENSE 
			WHERE DATA = '5V"S-OHgV6%T-&DPODDh(OTU;2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WW^:KVTU-')
	Begin
		print '***** -- Insert a new limited CRM WorkBench License (with 3 users)'
		INSERT INTO LICENSE (DATA) 
		VALUES ('5V"S-OHgV6%T-&DPODDh(OTU;2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WW^:KVTU-')
		print '***** -- New limited CRM WorkBench License (with 3 users) inserted successfully.'
	End

	-- Clerical
	if not exists(select * 
			from LICENSE 
			WHERE DATA = '5V"S-OHgV6%T-&DPODDd(OTU=2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WVf:KVTU-')
	Begin
		print '***** -- Insert a new limited Clerical WorkBench License (with 3 users)'
		INSERT INTO LICENSE (DATA) 
		VALUES ('5V"S-OHgV6%T-&DPODDd(OTU=2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WVf:KVTU-')
		print '***** -- New limited Clerical WorkBench License (with 3 users) inserted successfully.'
	End
	
	-- Administrator
	if not exists(select * 
			from LICENSE 
			WHERE DATA = '5V"S-OHgV6%T-&DPODDj(OTU=2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WWb:KVTU-')
	Begin
		print '***** -- Insert a new limited Clerical WorkBench License (with 3 users)'
		INSERT INTO LICENSE (DATA) 
		VALUES ('5V"S-OHgV6%T-&DPODDj(OTU=2OPU-)OP)t$H{5Gk&H G*P5=m2g9/=n3BM)N2UIPE-)OMPH-DBO)ENBUI2NBU-GG2DU-W)E-UTTZOPOZN2DIBO-DS2U2SNTPGBSU-OUI2T2E-TD-QM-O2T"UI2ZEPOPUDBSSZUI2-S2W2SZEBZN2BO-OH#"N2UIPE1PSQSPD2EVS21.1GPSBDI-2W-OHTPN2E2T-S2ES2TVMU-TDBMM2E:2GG2DU-W2:PS:N2DIBO@WWb:KVTU-')
		print '***** -- New limited Clerical WorkBench License (with 3 users) inserted successfully.'
	End

	-- grant Demo Professional WB License
	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'Demo')
			where LU.MODULEID = 18)
	Begin
		print '***** Assign Demo Professional WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 18, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'Demo'
		print '***** Professional WorkBench license assigned to Demo.'
	End
	
	-- grant internal Professional WB License
	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'internal')
			where LU.MODULEID = 18)
	Begin
		print '***** Assign internal Professional WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 18, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'internal'
		print '***** Professional WorkBench license assigned to internal.'
	End

	-- grant internal Managers WB License
	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'internal')
			where LU.MODULEID = 19)
	Begin
		print '***** Assign internal Managers WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 19, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'internal'
		print '***** Managers WorkBench license assigned to internal.'
	End

	-- grant internal Marketing WB License
	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'internal')
			where LU.MODULEID = 20)
	Begin
		print '***** Assign internal Marketing WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 20, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'internal'
		print '***** Marketing WorkBench license assigned to internal.'
	End

	-- grant internal Clerical WB License
	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'internal')
			where LU.MODULEID = 21)
	Begin
		print '***** Assign internal Clerical WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 21, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'internal'
		print '***** Clerical WorkBench license assigned to internal.'
	End

	-- grant internal CRM WB License
	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'internal')
			where LU.MODULEID = 25)
	Begin
		print '***** Assign internal CRM WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 25, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'internal'
		print '***** CRM WorkBench license assigned to internal.'
	End

	-- grant Administrator Administrator WB License
	if not exists(select * 
			from LICENSEDUSER LU 			
			where LU.MODULEID = 27 and LU.USERIDENTITYID = -1)
	Begin
		print '***** Assign internal CRM WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		values (27, -1)		
		print '***** CRM WorkBench license assigned to internal.'
	End
	
	Go
	/******************************************************************************************/
	/***** Creating an internal CRM user						      *****/
	/******************************************************************************************/

	Declare @nCurrentCRMModule		int
	Declare @sCRMModuleTitle	nvarchar(512)
	Declare @nInternalCRMPortalKey	int

	-- Create a new portal configuration CRM Test. 
	-- Has a Home tab, My Details tab, CRM Reports tab
	-- and then append a new tab for every internal web part that is not already present.

	If not exists (Select * from PORTAL where NAME = 'CRM Test')
	Begin
		print '*****Creating a new portal configuration CRM Test.'

		insert into PORTAL (NAME, DESCRIPTION, ISEXTERNAL)
		values( 'CRM Test',
			'All CRM web parts attached.',
			0)

		
		Select @nInternalCRMPortalKey = P.PORTALID
		from PORTAL P
		where P.NAME = 'CRM Test'
		
		-- Copy Home portal tabs:
		If not exists (Select * from PORTALTAB PT, PORTAL P 
				where P.PORTALID = PT.PORTALID 
				and P.NAME = 'CRM Test'
				and PT.TABNAME = 'Home')
		Begin
			print '*****Copying Professional portal tabs.'
		
			insert into PORTALTAB (TABNAME, IDENTITYID, TABSEQUENCE, PORTALID)
			Select  PT.TABNAME,
				NULL,
				PT.TABSEQUENCE,
				(Select PORTALID from PORTAL where NAME = 'CRM Test')
			from PORTALTAB PT
			join PORTAL P			on (P.PORTALID = PT.PORTALID)
			where P.NAME = 'Professional' 
			and PT.TABNAME = 'Home'
		End
		Else Begin
			print '***** Home tab from Professional portal have already been copied for CRM Test.'	
		End
		
		If not exists(select * 
				from PORTALTAB P
				join MODULECONFIGURATION M on (M.TABID = P.TABID)
				where P.TABNAME = 'Home' 
				and M.MODULEID = -10
				and M.PORTALID = @nInternalCRMPortalKey)
		Begin
			print '*****Adding My Details to Home Tab for CRM Test.'
			
			Insert into MODULECONFIGURATION (TABID, MODULEID, MODULESEQUENCE, PANELLOCATION, PORTALID)
			Select TABID, 
				-10, 
				1, 
				'TopPane', 
				P.PORTALID 
			from PORTALTAB PT
			join PORTAL P on (P.NAME = 'CRM Test' and PT.PORTALID = P.PORTALID)
			where PT.TABNAME = 'Home'
			
			print '***** My Details added to Home Tab for CRM Test.'	
		End			
		Else Begin
			print '***** My Details already in Home Tab for CRM Test.'	
		End

	End

	/*  CRM Report Tabs to be implemented later
	-- Add CRM Reports tab. This will ensure that separate tabs are not created for the CRM Reports.
	If not exists(Select * from PORTALTAB where TABNAME = 'CRM Reports')
	Begin
		Declare @nTabSequence int
		Select  @nTabSequence = isnull(count(*),0)+1
		from PORTAL 
		where NAME = 'CRM Test'

	    Insert into PORTALTAB (TABNAME, IDENTITYID, TABSEQUENCE, PORTALID)
	    Select  'CRM Reports',
		    NULL,
			@nTabSequence,
			(Select PORTALID from PORTAL where NAME = 'CRM Test')

		print '***** CRM Reports tab added to CRM Test.'	
	End

	If not exists(select * 
			from PORTALTAB P
			join MODULECONFIGURATION M on (M.TABID = P.TABID)
			where P.TABNAME = 'CRM Reports' and M.MODULEID = -29)
	Begin
	    Insert into MODULECONFIGURATION (TABID, MODULEID, MODULESEQUENCE, PANELLOCATION)
	    Select  TABID, -29, 1, 'TopPane' from PORTALTAB where TABNAME = 'CRM Reports'
	End

	If not exists(select * 
			from PORTALTAB P
			join MODULECONFIGURATION M on (M.TABID = P.TABID)
			where P.TABNAME = 'CRM Reports' and M.MODULEID = -31)
	Begin
	    Insert into MODULECONFIGURATION (TABID, MODULEID, MODULESEQUENCE, PANELLOCATION)
	    Select  TABID, -31, 2, 'TopPane' from PORTALTAB where TABNAME = 'CRM Reports'
	End

	If not exists(select * 
			from PORTALTAB P
			join MODULECONFIGURATION M on (M.TABID = P.TABID)
			where P.TABNAME = 'CRM Reports' and M.MODULEID = -33)
	Begin
	    Insert into MODULECONFIGURATION (TABID, MODULEID, MODULESEQUENCE, PANELLOCATION)
	    Select  TABID, -33, 3, 'BottomPane' from PORTALTAB where TABNAME = 'CRM Reports'
	End

	If not exists(select * 
			from PORTALTAB P
			join MODULECONFIGURATION M on (M.TABID = P.TABID)
			where P.TABNAME = 'CRM Reports' and M.MODULEID = -35)
	Begin
	    Insert into MODULECONFIGURATION (TABID, MODULEID, MODULESEQUENCE, PANELLOCATION)
	    Select  TABID, -35, 4, 'BottomPane' from PORTALTAB where TABNAME = 'CRM Reports'
	End
	*/

	-- Get the Key of the new Portal

	Select @nInternalCRMPortalKey = PORTALID
	from PORTAL
	where NAME = 'CRM Test'    

	-- Extract first web part to be appended:
	Select @nCurrentCRMModule = min(FM.MODULEID) 
	from FEATUREMODULE FM
	join FEATURE F 		on F.FEATUREID = FM.FEATUREID
	WHERE F.ISINTERNAL = 1 
	and FM.MODULEID between -37 and -28 /* Obsolete CRM modules */
	and not exists (Select * 
			from PORTAL P
			join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
			join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
			where P.NAME = 'CRM Test'
			and MC.MODULEID = FM.MODULEID)
	and not exists (Select * 
			from PORTAL P
			join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
			join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
			where P.NAME = 'System Administrator'
			and MC.MODULEID = FM.MODULEID)

	If @nCurrentCRMModule is null
	Begin
		print '*****All possible CRM modules are already in the CRM Test.'
	End

	While @nCurrentCRMModule is not null
	Begin
		Select @sCRMModuleTitle = TITLE from MODULE where MODULEID = @nCurrentCRMModule
		print '*****Addiing ' + @sCRMModuleTitle + '(' + cast(@nCurrentCRMModule as varchar(10)) + ') ModuleKey as a new Tab to the CRM Test.'	

		exec dbo.ua_AddModuleToConfiguration					
						@pnUserIdentityId	= 5,
						@psCulture		= null,	
						@pnIdentityKey		= null,
						@pnPortalKey		= @nInternalCRMPortalKey,
						@pnModuleKey		= @nCurrentCRMModule	

		-- Extract the next web part to be appended:
		Select @nCurrentCRMModule = min(FM.MODULEID) 
		from FEATUREMODULE FM
		join FEATURE F 		on F.FEATUREID = FM.FEATUREID
		WHERE F.ISINTERNAL = 1 
		and FM.MODULEID between -37 and -28 /* Obsolete CRM modules */
		and not exists (Select * 
				from PORTAL P
				join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
				join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
				where P.NAME = 'CRM Test'
				and MC.MODULEID = FM.MODULEID)
		and not exists (Select * 
				from PORTAL P
				join PORTALTAB PT		on (PT.PORTALID = P.PORTALID)
				join MODULECONFIGURATION MC 	on (MC.TABID = PT.TABID)
				where P.NAME = 'System Administrator'
				and MC.MODULEID = FM.MODULEID)
		and FM.MODULEID > @nCurrentCRMModule
	End


	-- Create a new user 'crm' with the CRM Test and the All Internal role:
	If not exists (select * from USERIDENTITY where LOGINID = 'crm')
	Begin
		print '*****Create a new user - crm'	

		insert into USERIDENTITY(LOGINID, PASSWORD, NAMENO, ISEXTERNALUSER, ISADMINISTRATOR, ACCOUNTID, ISVALIDINPROSTART, ISVALIDWORKBENCH, DEFAULTPORTALID)
		values ('crm',0x1FECE0CB254F1F45891BC9EE9FED72A9, -487, 0, 0, -1, 1, 1, @nInternalCRMPortalKey)
	End
	Else Begin
		print '*****crm user already exists.'	
	End

	If exists ( 	Select  UI.IDENTITYID,
				R.ROLEID
			from ROLE R, USERIDENTITY UI 
			where ROLENAME in ('Internal', 'User', 'All Internal')
			and UI.LOGINID = 'crm'
			and not exists
				(select * from IDENTITYROLES IR
				 where IR.IDENTITYID = UI.IDENTITYID
				 and IR.ROLEID = R.ROLEID))
	Begin
		print '*****Assign the minimum role to the user crm'	

		insert into IDENTITYROLES (IDENTITYID, ROLEID)
		Select  UI.IDENTITYID,
			R.ROLEID
		from ROLE R, USERIDENTITY UI 
		where ROLENAME in ('Internal', 'User', 'All Internal')
		and UI.LOGINID = 'crm'
		and not exists
			(select * from IDENTITYROLES IR
			 where IR.IDENTITYID = UI.IDENTITYID
			 and IR.ROLEID = R.ROLEID)
	End
	Else Begin
		print '*****The crm user already has minumum role'	
	End

	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'crm')
			and LU.MODULEID = 25)
	Begin
		print '***** Assign internal CRM WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 25, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'crm'
		print '***** CRM WorkBench license assigned to internal.'
	End

	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'crm')
			and LU.MODULEID = 20)
	Begin
		print '***** Assign internal Marketing WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 20, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'crm'
		print '***** Marketing WorkBench license assigned to internal.'
	End
	
	If NOT exists(	Select * 
	from SETTINGVALUES 
	where IDENTITYID = (	Select IDENTITYID 
				from USERIDENTITY 
				where LOGINID = 'crm') 
	and SETTINGID = 3)
    BEGIN
	     PRINT '**** RFC3142 Inserting data SETTINGVALUES for SETTINGID = 3 for crm user'
         Insert into SETTINGVALUES (SETTINGID, IDENTITYID, COLCHARACTER, COLINTEGER, COLDECIMAL, COLBOOLEAN)
         Select 3, IDENTITYID, N'ExchDevTest@dev.cpaglobal.net', NULL, NULL, NULL
         from USERIDENTITY
         where LOGINID = 'crm'
         PRINT '**** RFC5778 Data successfully inserted into SETTINGVALUES table.'
         PRINT ''
    END
    ELSE BEGIN
        UPDATE SETTINGVALUES
        SET COLCHARACTER = 'ExchDevTest@dev.cpaglobal.net'
        WHERE SETTINGID = 3
        AND IDENTITYID = (Select IDENTITYID 
				from USERIDENTITY 
				where LOGINID = 'crm')
        PRINT '**** RFC5778 SETTINGID = 3 for crm user has been updated successfully.'
        PRINT ''
    END
	
	-- Create a new user 'crmonly' with the CRM Test and the All Internal role:
	If not exists (select * from USERIDENTITY where LOGINID = 'crmonly')
	Begin
		print '*****Create a new user - crmonly'	

		insert into USERIDENTITY(LOGINID, PASSWORD, NAMENO, ISEXTERNALUSER, ISADMINISTRATOR, ACCOUNTID, ISVALIDINPROSTART, ISVALIDWORKBENCH, DEFAULTPORTALID)
		values ('crmonly',0x7CB1D81E2B9B0930F56EFAC59F2E8323, -487, 0, 0, -1, 1, 1, @nInternalCRMPortalKey)
	End
	Else Begin
		print '*****crmonly user already exists.'	
	End

	If exists ( 	Select  UI.IDENTITYID,
				R.ROLEID
			from ROLE R, USERIDENTITY UI 
			where ROLENAME in ('Internal', 'User', 'All Internal')
			and UI.LOGINID = 'crmonly'
			and not exists
				(select * from IDENTITYROLES IR
				 where IR.IDENTITYID = UI.IDENTITYID
				 and IR.ROLEID = R.ROLEID))
	Begin
		print '*****Assign the minimum role to the user crmonly'	

		insert into IDENTITYROLES (IDENTITYID, ROLEID)
		Select  UI.IDENTITYID,
			R.ROLEID
		from ROLE R, USERIDENTITY UI 
		where ROLENAME in ('Internal', 'User', 'All Internal')
		and UI.LOGINID = 'crmonly'
		and not exists
			(select * from IDENTITYROLES IR
			 where IR.IDENTITYID = UI.IDENTITYID
			 and IR.ROLEID = R.ROLEID)
	End
	Else Begin
		print '*****The crmonly user already has minumum role'	
	End

	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'crmonly')
			and LU.MODULEID = 25)
	Begin
		print '***** Assign internal CRM WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 25, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'crmonly'
		print '***** CRM WorkBench license assigned to internal.'
	End
	
	If NOT exists(	Select * 
	from SETTINGVALUES 
	where IDENTITYID = (	Select IDENTITYID 
				from USERIDENTITY 
				where LOGINID = 'crmonly') 
	and SETTINGID = 3)
    BEGIN
	     PRINT '**** RFC3142 Inserting data SETTINGVALUES for SETTINGID = 3 for crmonly user'
         Insert into SETTINGVALUES (SETTINGID, IDENTITYID, COLCHARACTER, COLINTEGER, COLDECIMAL, COLBOOLEAN)
         Select 3, IDENTITYID, N'ExchDevTest@dev.cpaglobal.net', NULL, NULL, NULL
         from USERIDENTITY
         where LOGINID = 'crmonly'
         PRINT '**** RFC5778 Data successfully inserted into SETTINGVALUES table.'
         PRINT ''
	END
    ELSE BEGIN
        UPDATE SETTINGVALUES
        SET COLCHARACTER = 'ExchDevTest@dev.cpaglobal.net'
        WHERE SETTINGID = 3
        AND IDENTITYID = (Select IDENTITYID 
				from USERIDENTITY 
				where LOGINID = 'crmonly')
        PRINT '**** RFC5778 SETTINGID = 3 for crmonly user has been updated successfully.'
        PRINT ''
    END
GO

	/******************************************************************************************/
	/***** Creating an internal Clerical user						      *****/
	/******************************************************************************************/

	
	Declare @nInternalClericalPortalKey int
	Select @nInternalClericalPortalKey = PORTALID
	from PORTAL
	where NAME = 'Clerical'    


	-- Create a new user 'clerk' with the CRM Test and the All Internal role:
	If not exists (select * from USERIDENTITY where LOGINID = 'clerk')
	Begin
		print '*****Create a new user -clerk'	

		insert into USERIDENTITY(LOGINID, PASSWORD, NAMENO, ISEXTERNALUSER, ISADMINISTRATOR, ACCOUNTID, ISVALIDINPROSTART, ISVALIDWORKBENCH, DEFAULTPORTALID)
		values ('clerk',0x34776981FA47AA6CF3F2915D11BAE051, -487, 0, 0, -1, 1, 1, @nInternalClericalPortalKey)
	End
	Else Begin
		print '*****clerk user already exists.'	
	End

	If exists ( 	Select  UI.IDENTITYID,
				R.ROLEID
			from ROLE R, USERIDENTITY UI 
			where ROLENAME in ('Internal', 'User', 'Filing Clerk', 'All Internal')
			and UI.LOGINID = 'clerk'
			and not exists
				(select * from IDENTITYROLES IR
				 where IR.IDENTITYID = UI.IDENTITYID
				 and IR.ROLEID = R.ROLEID))
	Begin
		print '*****Assign the minimum role to the user clerk'	

		insert into IDENTITYROLES (IDENTITYID, ROLEID)
		Select  UI.IDENTITYID,
			R.ROLEID
		from ROLE R, USERIDENTITY UI 
		where ROLENAME in ('Internal', 'User', 'Filing Clerk', 'All Internal')
		and UI.LOGINID = 'clerk'
		and not exists
			(select * from IDENTITYROLES IR
			 where IR.IDENTITYID = UI.IDENTITYID
			 and IR.ROLEID = R.ROLEID)
	End
	Else Begin
		print '*****The clerk user already has minumum role'	
	End

	if not exists(select * 
			from LICENSEDUSER LU
			join USERIDENTITY UI on (UI.IDENTITYID = LU.USERIDENTITYID and UI.LOGINID = 'clerk')
			and LU.MODULEID = 21)
	Begin
		print '***** Assign internal Clerical WorkBench license.'
		Insert into LICENSEDUSER (MODULEID, USERIDENTITYID) 
		Select 21, IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'clerk'
		print '***** Clerical WorkBench license assigned to internal.'
	End

GO

		/**********************************************************************************************************/
	/*** RFC6420 Set up Table Attributes for Product Interests ***/
	/**********************************************************************************************************/	
	If not exists (Select * from TABLECODES where TABLETYPE = 151)
		Begin
			print '*****RFC6420 Adding products into table codes'
			
			INSERT TABLECODES (TABLETYPE, TABLECODE, DESCRIPTION, USERCODE) 
			SELECT 151, (151*100)+MODULEID, MODULENAME, cast(MODULEID as nvarchar(3))
			FROM LICENSEMODULE
				
			print '*****RFC6420 products successfully added to table codes'
		End
		Else Begin
			print '*****RFC6420 products already exists'
		End

	/**********************************************************************************************************/
	/*** RFC6420 Insert New Leads																			***/
	/**********************************************************************************************************/
	If exists (
		Select	N.NAMENO,
			NT.NAMETYPE,
			CASE WHEN NT.NAMETYPE in ('~LD', '~CN') and NT.PICKLISTFLAGS & 32 = 32 THEN 1 ELSE 0 END
		from NAMETYPE NT
		left join NAME N on (N.NAMENO in (-495, 6001,6004,6009,6011)) 
		where NT.NAMETYPE not in (
			select NTC.NAMETYPE
			from NAMETYPECLASSIFICATION NTC
			where NTC.NAMENO = N.NAMENO
		)
		and (NT.PICKLISTFLAGS & 16 = 16 
			or NT.PICKLISTFLAGS & 32 = 32)
		)
	Begin
	PRINT '**** RFC6420 Adding NAMETYPECLASSIFICATION to NAMENO in (-495, 6001, 6004, 6009, 6011)'
		
		INSERT INTO NAMETYPECLASSIFICATION (NAMENO, NAMETYPE, ALLOW) 
		Select	N.NAMENO,
			NT.NAMETYPE,
			CASE WHEN NT.NAMETYPE in ('~LD', '~CN') and NT.PICKLISTFLAGS & 32 = 32 THEN 1 ELSE 0 END
		from NAMETYPE NT
		left join NAME N on (N.NAMENO in (-495, 6001,6004,6009,6011)) 
		where NT.NAMETYPE not in (
			select NTC.NAMETYPE
			from NAMETYPECLASSIFICATION NTC
			where NTC.NAMENO = N.NAMENO
		)
		and (NT.PICKLISTFLAGS & 16 = 16 
			or NT.PICKLISTFLAGS & 32 = 32)
		
		PRINT '**** RFC6420 Data successfully added to NAMETYPECLASSIFICATION table for NAMENO in (-495, 6001, 6004, 6009, 6011).'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 NAMETYPECLASSIFICATION for NAMENO = -495, 6001, 6004, 6009, 6011 already exists'

	PRINT ''
	go

	If not exists (Select * from NAMETYPECLASSIFICATION where NAMENO in (6009,6011) and NAMETYPE ='~~~' and ALLOW=0)
	Begin 
		PRINT '**** RFC6420 Setting NAMETYPECLASSIFICATION.NAMENO in( 6009,6011) to restricted names'

		Update NAMETYPECLASSIFICATION
			Set ALLOW = 0
		where NAMENO in (6009, 6011) 
		and NAMETYPE = '~~~'
		
		PRINT '**** RFC6420 Data successfully updated in NAMETYPECLASSIFICATION table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 NAMETYPECLASSIFICATION.NAMENO in (6009,6011) already updated'

	PRINT ''
	go

	If not exists (Select * from LEADDETAILS where NAMENO = -495)
	Begin 
		PRINT '**** RFC6420 Adding data LEADDETAILS.NAMENO = -495'

		INSERT LEADDETAILS (NAMENO, LEADSOURCE, ESTIMATEDREV, ESTREVCURRENCY, COMMENTS)
		VALUES (-495, -14301, 50000000, 'AUD', 'Calls on Mondays only')
		
		PRINT '**** RFC6420 Data successfully added to LEADDETAILS table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADDETAILS.NAMENO = -495 already exists'

	PRINT ''
	go

	If not exists(Select * from ASSOCIATEDNAME 
			where NAMENO = -496
			and RELATIONSHIP = 'LEA'
			and RELATEDNAME = -495
			and SEQUENCE = 0)
	Begin
		PRINT '**** RFC6420 Adding data ASSOCIATEDNAME.NAMENO = -496'

		INSERT ASSOCIATEDNAME (NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE)
		VALUES (-496, 'LEA', -495, 0)

		PRINT '**** RFC6420 Data successfully added to ASSOCIATEDNAME table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 ASSOCIATEDNAME.NAMENO = -496 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADDETAILS where NAMENO = 6001)
	Begin 
		PRINT '**** RFC6420 Adding data LEADDETAILS.NAMENO = 6001'

		INSERT LEADDETAILS (NAMENO, LEADSOURCE, ESTIMATEDREV, ESTREVCURRENCY, COMMENTS)
		VALUES (6001, -14301, 10000000, 'AUD', 'Calls on Wednesdays only')
		
		PRINT '**** RFC6420 Data successfully added to LEADDETAILS table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADDETAILS.NAMENO = 6001 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADDETAILS where NAMENO = 6004)
	Begin 
		PRINT '**** RFC6420 Adding data LEADDETAILS.NAMENO = 6004'

		INSERT LEADDETAILS (NAMENO, LEADSOURCE, ESTIMATEDREV, ESTREVCURRENCY, COMMENTS)
		VALUES (6004, -14302, 4500000, 'USD', 'Persuasion required.')
		
		PRINT '**** RFC6420 Data successfully added to LEADDETAILS table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADDETAILS.NAMENO = 6004 already exists'

	PRINT ''
	go


	If not exists (Select * from ASSOCIATEDNAME where RELATEDNAME = 6004 and RELATIONSHIP = 'LEA')
	Begin
		PRINT '**** RFC6420 Changing data ASSOCIATEDNAME.RELATEDNAME = 6004'

		UPDATE ASSOCIATEDNAME
			SET RELATIONSHIP = 'LEA'
		WHERE	RELATEDNAME = 6004
		and		RELATIONSHIP = 'EMP'
		and		SEQUENCE = 0
		
		UPDATE ASSOCIATEDNAME
			SET SEQUENCE = 0
		WHERE	RELATEDNAME = 6004
		and		RELATIONSHIP = 'EMP'		
		
		PRINT '**** RFC6420 Data successfully modified in ASSOCIATEDNAME table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 ASSOCIATEDNAME.RELATEDNAME = 6004 already modified'

	PRINT ''
	go	

	If not exists (Select * from LEADDETAILS where NAMENO = 6009)
	Begin 
		PRINT '**** RFC6420 Adding data LEADDETAILS.NAMENO = 6009'

		INSERT LEADDETAILS (NAMENO, LEADSOURCE, ESTIMATEDREV, ESTREVCURRENCY, COMMENTS)
		VALUES (6009, -14303, 13242300, 'GBP', 'Really good customer.... You can get him to buy anything!')
		
		PRINT '**** RFC6420 Data successfully added to LEADDETAILS table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADDETAILS.NAMENO = 6009 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADDETAILS where NAMENO = 6011)
	Begin 
		PRINT '**** RFC6420 Adding data LEADDETAILS.NAMENO = 6011'

		INSERT LEADDETAILS (NAMENO, LEADSOURCE, ESTIMATEDREV, ESTREVCURRENCY, COMMENTS)
		VALUES (6011, -14304, 5678900, 'AUD', NULL)
		
		PRINT '**** RFC6420 Data successfully added to LEADDETAILS table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADDETAILS.NAMENO = 6011 already exists'

	PRINT ''
	go

	If exists (Select  * 
				from NAME N
				where NAMENO in (6001, 6004, 6009, 6011, -495)
				and not exists (
					Select * 
					from ASSOCIATEDNAME AN 
					where	AN.RELATEDNAME = N.NAMENO
					and		AN.NAMENO in (-487, -499)
					and		AN.RELATIONSHIP = 'RES' 
					and		AN.SEQUENCE = 0
					))
	Begin 
		PRINT '**** RFC6420 Adding Lead Owners for Leads'

		INSERT ASSOCIATEDNAME (NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE)
		SELECT
			N.NAMENO, 'RES', CASE WHEN N.NAMENO = 6009 THEN -499 ELSE -487 END, 0
		from NAME N
		where NAMENO in (6001, 6004, 6009, 6011, -495)
		and not exists (
			Select * 
			from ASSOCIATEDNAME AN 
			where	AN.NAMENO  = N.NAMENO
			and		AN.RELATEDNAME in (-487, -499)
			and		AN.RELATIONSHIP = 'RES' 
			and		AN.SEQUENCE = 0
			)
		
		PRINT '**** RFC6420 Data successfully added to ASSOCIATEDNAME table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Lead Owners for Leads already exists'

	PRINT ''
	go

	If exists (Select  * 
				from NAME N
				where NAMENO in (6001, 6004, 6009, 6011, -495)
				and not exists (
					Select * 
					from ASSOCIATEDNAME AN 
					where	AN.RELATEDNAME = N.NAMENO					
					and		AN.RELATIONSHIP = 'REF' 
					and		AN.SEQUENCE = 0
					))
	Begin 
		PRINT '**** RFC6420 Adding Referred By for Leads'

		INSERT ASSOCIATEDNAME (NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE)
		SELECT
			N.NAMENO, 'REF', CASE 
								WHEN N.NAMENO = 6001 THEN -5710094
								WHEN N.NAMENO = 6004 THEN -6022195
								WHEN N.NAMENO = 6009 THEN -5951097
								WHEN N.NAMENO = 6011 THEN -5466093
								ELSE -196 END, 0
		from NAME N
		where NAMENO in (6001, 6004, 6009, 6011, -495)
		and not exists (
			Select * 
			from ASSOCIATEDNAME AN 
			where	AN.NAMENO  = N.NAMENO			
			and		AN.RELATIONSHIP = 'REF' 
			and		AN.SEQUENCE = 0
			)
		
		PRINT '**** RFC6420 Data successfully added to ASSOCIATEDNAME table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Referred By for Leads already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = -495 and LEADSTATUSID = -14405)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = -495'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (-495, -14405)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = -495 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = -495 and LEADSTATUSID = -14402)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = -495'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (-495, -14402)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6011 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = -495 and LEADSTATUSID = -14403)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = -495'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (-495, -14403)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6011 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = 6001 and LEADSTATUSID = -14405)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = 6001'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (6001, -14405)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6001 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = 6001 and LEADSTATUSID = -14402)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = 6001'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (6001, -14402)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6011 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = 6001 and LEADSTATUSID = -14403)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = 6001'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (6001, -14403)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6011 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = 6004 and LEADSTATUSID = -14405)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = 6004'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (6004, -14405)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6004 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = 6009 and LEADSTATUSID = -14405)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = 6009'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (6009, -14405)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6011 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = 6009 and LEADSTATUSID = -14402)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = 6009'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (6009, -14402)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6011 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = 6009 and LEADSTATUSID = -14401)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = 6009'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (6009, -14401)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6011 already exists'

	PRINT ''
	go

	If not exists (Select * from LEADSTATUSHISTORY where NAMENO = 6011 and LEADSTATUSID = -14405)
	Begin 
		PRINT '**** RFC6420 Adding data LEADSTATUSHISTORY.NAMENO = 6011'

		INSERT LEADSTATUSHISTORY(NAMENO, LEADSTATUS)
		VALUES (6011, -14405)	
		
		PRINT '**** RFC6420 Data successfully added to LEADSTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.NAMENO = 6011 already exists'

	PRINT ''
	go

	drop trigger tU_LEADSTATUSHISTORY_Audit
	go

	If (1=1)
	Begin 
		PRINT '**** RFC6420 Updating log identity id LEADSTATUSHISTORY.NAMENO in (-495,6001,6004,6009)'
		Update LEADSTATUSHISTORY 
			SET LOGIDENTITYID = IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'crm'
		and LEADSTATUSHISTORY.NAMENO in (-495,6001,6004,6009)
		and LEADSTATUSHISTORY.LOGIDENTITYID is null
		PRINT '**** RFC6420 Log identity id for LEADSTATUSHISTORY.NAMENO in (-495,6001,6004,6009) updated successfully'
	End
	
	If (1=1)
	Begin 
		PRINT '**** RFC6420 Updating log date time stamp for LEADSTATUSHISTORY.NAMENO = -495'
		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -56, LOGDATETIMESTAMP) 
		where NAMENO = -495
		and LEADSTATUS = -14405

		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -20, LOGDATETIMESTAMP) 
		where NAMENO = -495
		and LEADSTATUS = -14402

		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -1, LOGDATETIMESTAMP) 
		where NAMENO = -495
		and LEADSTATUS = -14403
		PRINT '**** RFC6420 LOGDATETIMESTAMP successfully updated to LEADSTATUSHISTORY table for NAMENO=-495.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.LOGDATETIMESTAMP = -495 already updated'

	go

	If (1=1)
	Begin 
		PRINT '**** RFC6420 Updating log date time stamp for LEADSTATUSHISTORY.NAMENO = 6001'
		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -60, LOGDATETIMESTAMP) 
		where NAMENO = 6001
		and LEADSTATUS = -14405
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -60, getdate()))!=0

		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -25, LOGDATETIMESTAMP) 
		where NAMENO = 6001
		and LEADSTATUS = -14402
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -25, getdate()))!=0

		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -5, LOGDATETIMESTAMP) 
		where NAMENO = 6001
		and LEADSTATUS = -14403
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -5, getdate()))!=0
		
		PRINT '**** RFC6420 LOGDATETIMESTAMP successfully updated to LEADSTATUSHISTORY table for NAMENO=6001.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.LOGDATETIMESTAMP = 6001 already updated'

	go
		
	If (1=1)
	Begin 
		PRINT '**** RFC6420 Updating log date time stamp for LEADSTATUSHISTORY.NAMENO = 6004'
		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -56, LOGDATETIMESTAMP) 
		where NAMENO = 6004
		and LEADSTATUS = -14405
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -56, getdate()))!=0
		
		PRINT '**** RFC6420 LOGDATETIMESTAMP successfully updated to LEADSTATUSHISTORY table for NAMENO=6004.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.LOGDATETIMESTAMP = 6004 already updated'

	go

	If (1=1)
	Begin 
		PRINT '**** RFC6420 Updating log date time stamp for LEADSTATUSHISTORY.NAMENO = 6009'
		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -123, LOGDATETIMESTAMP) 
		where NAMENO = 6001
		and LEADSTATUS = -14405
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -123, getdate()))!=0

		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -23, LOGDATETIMESTAMP) 
		where NAMENO = 6001
		and LEADSTATUS = -14402
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -23, getdate()))!=0

		Update LEADSTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -2, LOGDATETIMESTAMP) 
		where NAMENO = 6001
		and LEADSTATUS = -14401
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -2, getdate()))!=0
		
		PRINT '**** RFC6420 LOGDATETIMESTAMP successfully updated to LEADSTATUSHISTORY table for NAMENO=6009.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 LEADSTATUSHISTORY.LOGDATETIMESTAMP = 6009 already updated'

	go

	exec ipu_UtilGenerateAuditTriggers @psTable='LEADSTATUSHISTORY', @pbPrintLog=0
	go

	/**********************************************************************************************************/
	/*** RFC6420 Insert New Opportunities																	***/
	/**********************************************************************************************************/
	If not exists (Select * from CASES where CASEID = -500)
	Begin 
		PRINT '**** RFC6420 Inserting new Opportunity CASEID = -500'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, TITLE, LOCALCLIENTFLAG)
		values (-500, 'AU/ORIGAMI/01', 'O', 'A', 'AU', 'ORIGAMI/01', 1)
		
		PRINT '**** RFC6420 Data successfully added to Opportunity table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Opportunity CASE -500 already exists'

	PRINT ''
	go


	If not exists (Select * from CASES where CASEID = -501)
	Begin 
		PRINT '**** RFC6420 Inserting new Opportunity CASEID = -501'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, TITLE, LOCALCLIENTFLAG)
		values (-501, 'AU/XERO/PHIL/01', 'O', 'A', 'AU', 'Xero/Phil/01', 1)
		
		PRINT '**** RFC6420 Data successfully added to Opportunity table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Opportunity CASE -501 already exists'

	PRINT ''
	go

	If not exists (Select * from CASES where CASEID = -502)
	Begin 
		PRINT '**** RFC6420 Inserting new Opportunity CASEID = -502'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, TITLE, LOCALCLIENTFLAG)
		values (-502, 'UK/COWLEY/BRIAN/01', 'O', 'A', 'AU', 'Cowley/Brian/01', 1)
		
		PRINT '**** RFC6420 Data successfully added to Opportunity table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Opportunity CASE -501 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -500 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC6420 Inserting new Instructor for Opportunity CASEID = -500'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-500, 'I', -496, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Instructor for Opportunity CASE -500 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -500 and NAMETYPE = '~PR')
	Begin 
		PRINT '**** RFC6420 Inserting new Prospect for Opportunity CASEID = -500'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-500, '~PR', -496, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Prospect for Opportunity CASE -500 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -500 and NAMETYPE = '~LD' and NAMENO = -495)
	Begin 
		PRINT '**** RFC6420 Inserting new Lead for Opportunity CASEID = -500'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-500, '~LD', -495, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Lead for Opportunity CASE -500 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -500 and NAMETYPE = '~LD'  and NAMENO = 6004)
	Begin 
		PRINT '**** RFC6420 Inserting new Lead for Opportunity CASEID = -500'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-500, '~LD', 6004, 1)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Lead for Opportunity CASE -500 already exists'

	PRINT ''
	go	
	
	If not exists (Select * from CASENAME where CASEID = -500 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC6420 Inserting new Owner for Opportunity CASEID = -500'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-500, 'EMP', -487, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Owner for Opportunity CASE -500 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -501 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC6420 Inserting new Instructor for Opportunity CASEID = -501'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-501, 'I', 6001, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Instructor for Opportunity CASE -501 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -501 and NAMETYPE = '~PR')
	Begin 
		PRINT '**** RFC6420 Inserting new Prospect for Opportunity CASEID = -501'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-501, '~PR', 6001, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Prospect for Opportunity CASE -500 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -501 and NAMETYPE = '~LD')
	Begin 
		PRINT '**** RFC6420 Inserting new Lead for Opportunity CASEID = -501'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-501, '~LD', 6001, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Lead for Opportunity CASE -501 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -501 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC6420 Inserting new Owner for Opportunity CASEID = -501'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-501, 'EMP', -499, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Owner for Opportunity CASE -501 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -502 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC6420 Inserting new Instructor for Opportunity CASEID = -502'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-502, 'I', 6009, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Instructor for Opportunity CASE -502 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -502 and NAMETYPE = '~PR')
	Begin 
		PRINT '**** RFC6420 Inserting new Prospect for Opportunity CASEID = -502'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-502, '~PR', 6009, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Prospect for Opportunity CASE -502 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -502 and NAMETYPE = '~LD')
	Begin 
		PRINT '**** RFC6420 Inserting new Lead for Opportunity CASEID = -502'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-502, '~LD', 6009, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Lead for Opportunity CASE -502 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -502 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC6420 Inserting new Owner for Opportunity CASEID = -502'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE)
		values (-502, 'EMP', -487, 0)
		
		PRINT '**** RFC6420 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Owner for Opportunity CASE -502 already exists'

	PRINT ''
	go

	if exists (Select 1 from CASENAME WHERE DERIVEDCORRNAME = 0 AND CORRESPONDNAME IS NULL)
	Begin
		PRINT '**** RFC7245 Update DERIVEDCORRNAME flags where no CORRESPONDNAME name exists.'
		UPDATE CASENAME SET DERIVEDCORRNAME = 1 WHERE CORRESPONDNAME IS NULL and DERIVEDCORRNAME = 0
		PRINT '**** RFC7245 Data successfully added on Case Name table.'
		PRINT ''
	End
	Else
	Begin
		PRINT '**** RFC7245 DERIVEDCORRNAME flags do not require updating.'
		PRINT ''
	End
	go

	If not exists (Select * from OPPORTUNITY where CASEID = -500)
	Begin 
		PRINT '**** RFC6420 Inserting new Opportunity for CASEID = -500'

		INSERT INTO OPPORTUNITY (CASEID, POTENTIALVALUELOCAL, SOURCE, EXPCLOSEDATE, REMARKS, POTENTIALWIN, NEXTSTEP, POTENTIALVALCURRENCY,NUMBEROFSTAFF)
		VALUES (-500, 500000, -14301, DATEADD(month, 6, getdate()), 'Competition is closing in.', 75, 'Schedule a meeting soonish.', NULL, 5000)
	    
		PRINT '**** RFC6420 Data successfully added to Opportunity table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Opportunity for CASE -500 already exists'

	PRINT ''
	go

	If not exists (Select * from OPPORTUNITY where CASEID = -501)
	Begin 
		PRINT '**** RFC6420 Inserting new Opportunity for CASEID = -501'

		INSERT INTO OPPORTUNITY (CASEID, POTENTIALVALUELOCAL, SOURCE, EXPCLOSEDATE, REMARKS, POTENTIALWIN, NEXTSTEP, POTENTIALVALCURRENCY,NUMBEROFSTAFF)
		VALUES (-501, 100000, -14301, DATEADD(month, 8, getdate()), 'We can potentially make this bigger', 15, 'Send more brochers.  Find out why we lost the deal.', NULL, NULL)
	    
		PRINT '**** RFC6420 Data successfully added to Opportunity table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Opportunity for CASE -501 already exists'

	PRINT ''
	go

	If not exists (Select * from OPPORTUNITY where CASEID = -502)
	Begin 
		PRINT '**** RFC6420 Inserting new Opportunity for CASEID = -502'

		INSERT INTO OPPORTUNITY (CASEID, POTENTIALVALUE, POTENTIALVALUELOCAL, SOURCE, EXPCLOSEDATE, REMARKS, POTENTIALWIN, NEXTSTEP, POTENTIALVALCURRENCY,NUMBEROFSTAFF)
		VALUES (-502, 20594.29, 45462.00, -14303, DATEADD(month, 2, getdate()), NULL, 80, 'Show them the new product', 'GBP', NULL)
	    
		PRINT '**** RFC6420 Data successfully added to Opportunity table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Opportunity for CASE -502 already exists'

	PRINT ''
	go


	If not exists (Select * from CASEEVENT where CASEID = -500)
	BEGIN
		PRINT '**** RFC6420 Inserting date of entry and date of last change for Opportunity CASEID = -502'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-500, -13, DATEADD(day, -1, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-500, -14, DATEADD(day, -1, getdate()), 1, 1)
	    
		PRINT '**** RFC6420 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 date of entry and date of last change for Opportunity CASE -502 already exists'

	PRINT ''
	go

	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -500)
	BEGIN
		PRINT '**** RFC6420 Inserting CRMCASESTATUSHISTORY for Opportunity CASEID = -500'

		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-500, -14503)
		
		PRINT '**** RFC6420 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 CRMCASESTATUSHISTORY for Opportunity CASE -500 already exists'

	PRINT ''
	go


	If not exists (Select * from CASEEVENT where CASEID = -501)
	BEGIN
		PRINT '**** RFC6420 Inserting date of entry and date of last change for Opportunity CASEID = -501'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-501, -13, DATEADD(day, -25, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-501, -14, DATEADD(day, -5, getdate()), 1, 1)
	    
		PRINT '**** RFC6420 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 date of entry and date of last change for Opportunity CASE -501 already exists'

	PRINT ''
	go

	If not exists (Select * from TABLEATTRIBUTES where PARENTTABLE = 'CASES' and GENERICKEY = -500)
	BEGIN
		PRINT '**** RFC6420 Inserting product of interests (TABLEATTRIBUTES) for CASEID = -500'

		Insert TABLEATTRIBUTES (PARENTTABLE, GENERICKEY, TABLECODE, TABLETYPE)
		select 'CASES', -500, TABLECODE, 151
		from TABLECODES 
		join LICENSEMODULE LM on (LM.MODULEFLAG = 4 and (TABLECODES.TABLECODE = (15100)+LM.MODULEID))
	    
		PRINT '**** RFC6420 Data successfully added to TABLEATTRIBUTES table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Product of interests (TABLEATTRIBUTES) -500 already exists'

	PRINT ''
	go

	if not exists(Select	* 
					from	SELECTIONTYPES ST 
					where PARENTTABLE = 'CRM/OPPORTUNITY')
	Begin
		PRINT '**** RFC6420 Insert PRODUCT INTEREST data into Selection Types'

			INSERT SELECTIONTYPES (PARENTTABLE, TABLETYPE, MINIMUMALLOWED, MAXIMUMALLOWED)
			VALUES ('CRM/OPPORTUNITY', 151, 0, NULL)

			PRINT '**** RFC6420 PRODUCT INTEREST are inserted successfully data into Selection Types'
			PRINT ''
		END
		ELSE
			PRINT '**** RFC6420 PRODUCT INTEREST already exists in Selection Types'

		PRINT ''
	go

	If not exists (Select * from TABLEATTRIBUTES where PARENTTABLE = 'CASES' and GENERICKEY = -501)
	BEGIN
		PRINT '**** RFC6420 Inserting product of interests (TABLEATTRIBUTES) for CASEID = -501'

		Insert TABLEATTRIBUTES (PARENTTABLE, GENERICKEY, TABLECODE, TABLETYPE)
		values ('CASES', -501, 15106, 151)

		Insert TABLEATTRIBUTES (PARENTTABLE, GENERICKEY, TABLECODE, TABLETYPE)
		values ('CASES', -501, 15107, 151)
				
		PRINT '**** RFC6420 Data successfully added to TABLEATTRIBUTES table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 Product of interests (TABLEATTRIBUTES) -501 already exists'

	PRINT ''
	go

	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -501)
	BEGIN
		PRINT '**** RFC6420 Inserting CRMCASESTATUSHISTORY for Opportunity CASEID = -501'

		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-501, -14503)
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-501, -14502)
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-501, -14505)	
		
		PRINT '**** RFC6420 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 CRMCASESTATUSHISTORY for Opportunity CASE -501 already exists'

	PRINT ''
	go

	If not exists (Select * from CASEEVENT where CASEID = -502)
	BEGIN
		PRINT '**** RFC6420 Inserting date of entry and date of last change for Opportunity CASEID = -502'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-502, -13, DATEADD(day, -23, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-502, -14, DATEADD(day, -2, getdate()), 1, 1)
	    
		PRINT '**** RFC6420 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 date of entry and date of last change for Opportunity CASE -502 already exists'

	PRINT ''
	go

	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -502)
	BEGIN
		PRINT '**** RFC6420 Inserting CRMCASESTATUSHISTORY for Opportunity CASEID = -502'

		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-502, -14503)
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-502, -14502)
			
		PRINT '**** RFC6420 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 CRMCASESTATUSHISTORY for Opportunity CASE -502 already exists'

	PRINT ''
	go

	drop trigger tU_CRMCASESTATUSHISTORY_Audit
	go

	If (1=1)
	Begin 
		PRINT '**** RFC6420 Updating log identity id CRMCASESTATUSHISTORY.CASEID in (-500,-501,-502)'
		Update CRMCASESTATUSHISTORY 
			SET LOGIDENTITYID = IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'crm'
		and CRMCASESTATUSHISTORY.CASEID in (-500,-501,-502)
		and CRMCASESTATUSHISTORY.LOGIDENTITYID is null
		and CRMCASESTATUS is not null
		PRINT '**** RFC6420 Log identity id for CRMCASESTATUSHISTORY.CASEID in (-500,-501,-502) updated successfully'
	End

	If (1=1)
	Begin 
		PRINT '**** RFC6420 Updating log date time stamp for CRMCASESTATUSHISTORY.CASEID = -501'
		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -5, LOGDATETIMESTAMP) 
		where CASEID = -501
		and CRMCASESTATUS = -14503
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -5, getdate()))!=0

		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -3, LOGDATETIMESTAMP) 
		where CASEID = -501
		and CRMCASESTATUS = -14502
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -3, getdate()))!=0

		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -1, LOGDATETIMESTAMP) 
		where CASEID = -501
		and CRMCASESTATUS = -14505
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -1, getdate()))!=0

		PRINT '**** RFC6420 LOGDATETIMESTAMP successfully updated to CRMCASESTATUSHISTORY table for CASEID=-501.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 CRMCASESTATUSHISTORY.LOGDATETIMESTAMP = -501 already updated'

	go

	If (1=1)
	Begin 
		PRINT '**** RFC6420 Updating log date time stamp for CRMCASESTATUSHISTORY.CASEID = -502'
		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -1, LOGDATETIMESTAMP) 
		where CASEID = -502
		and CRMCASESTATUS = -14503
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -1, getdate()))!=0
		
		PRINT '**** RFC6420 LOGDATETIMESTAMP successfully updated to CRMCASESTATUSHISTORY table for CASEID=-502.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC6420 CRMCASESTATUSHISTORY.LOGDATETIMESTAMP = -502 already updated'

	go

	exec ipu_UtilGenerateAuditTriggers @psTable='CRMCASESTATUSHISTORY', @pbPrintLog=0
	go
	

	If not exists(Select * 
			from USERIDENTITY UI 
			join PORTAL P on (P.NAME = 'Customer Relationship Management')
			where UI.LOGINID = 'crmonly'
			and UI.DEFAULTPORTALID = P.PORTALID)
	Begin
		print '***** Updating crmonly user to use the default Customer Relationship Management portal.'
			
		Update USERIDENTITY
		Set DEFAULTPORTALID = PORTAL.PORTALID
		from USERIDENTITY 
		join PORTAL on (PORTAL.NAME = 'Customer Relationship Management')
		where LOGINID = 'crmonly'

		print '***** crmonly user configured to use the default Customer Relationship Management portal'
	End
	Else
		print '***** crmonly user already configured to use the default Customer Relationship Management portal'
	print ''
	go
	
	/**********************************************************************************************************/
	/*** RFC5760 Insert New Campaigns																	***/
	/**********************************************************************************************************/
	If not exists (Select * from CASES where CASEID = -600)
	Begin 
		PRINT '**** RFC5760 Inserting new Campaign CASEID = -600'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, TITLE, BUDGETAMOUNT, LOCALCLIENTFLAG)
		select -600, 'AU/CRM/01', 'M', PT.PROPERTYTYPE, 'AU', CC.CASECATEGORY, 'Australian CRM WorkBench Launch', 50000, 1
		from PROPERTYTYPE PT
		join SITECONTROL SC on (SC.CONTROLID = 'Property Type Campaign' and PT.PROPERTYTYPE = SC.COLCHARACTER)
		join CASECATEGORY CC on (CC.CASETYPE = 'M' and CC.CASECATEGORY = 'D')
		where 1=1
		
		PRINT '**** RFC5760 Data successfully added to Campaign table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Campaign CASE -600 already exists'

	PRINT ''
	go


	If not exists (Select * from CASES where CASEID = -601)
	Begin 
		PRINT '**** RFC5760 Inserting new Campaign CASEID = -601'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, TITLE, BUDGETAMOUNT, LOCALCLIENTFLAG)
		select -601,  'AU/WB50/01', 'M', PT.PROPERTYTYPE, 'AU', CC.CASECATEGORY, 'Australian WorkBench 5.0 Launch', 30000, 1
		from PROPERTYTYPE PT
		join SITECONTROL SC on (SC.CONTROLID = 'Property Type Campaign' and PT.PROPERTYTYPE = SC.COLCHARACTER)
		join CASECATEGORY CC on (CC.CASETYPE = 'M' and CC.CASECATEGORY = 'C')
		where 1=1
		
		PRINT '**** RFC5760 Data successfully added to Campaign table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Campaign CASE -601 already exists'

	PRINT ''
	go

	If not exists (Select * from CASES where CASEID = -602)
	Begin 
		PRINT '**** RFC5760 Inserting new Campaign CASEID = -602'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, TITLE, BUDGETAMOUNT, LOCALCLIENTFLAG)
		select -602, 'US/CWB/01', 'M', PT.PROPERTYTYPE, 'US', CC.CASECATEGORY, 'US Clerical WorkBench Launch', 90000, 0
		from PROPERTYTYPE PT
		join SITECONTROL SC on (SC.CONTROLID = 'Property Type Campaign' and PT.PROPERTYTYPE = SC.COLCHARACTER)
		join CASECATEGORY CC on (CC.CASETYPE = 'M' and CC.CASECATEGORY = 'G')
		where 1=1
		
		
		PRINT '**** RFC5760 Data successfully added to Campaign table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Campaign CASE -601 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -600 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC5760 Inserting new Instructor for Campaign CASEID = -600'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-600, 'I', 121, 0, 1)
		
		PRINT '**** RFC5760 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Instructor for Campaign CASE -600 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -600 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC5760 Inserting new Manager for Campaign CASEID = -600'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-600, 'EMP', 121, 0, 1)
		
		PRINT '**** RFC5760 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Manager for Campaign CASE -600 already exists'

	PRINT ''
	go

	IF not exists (SELECT * 
			FROM CASENAME CN
			WHERE	CN.NAMETYPE = '~CN' 
			AND		CN.CASEID = -600)
	Begin 
		PRINT '**** RFC5760 Inserting new Contacts for Campaign CASEID = -600'

		declare @tbCaseName table(
			SEQUENCE	int identity (1,1) not null,			
			CASEID		int		NOT NULL,
			NAMENO		int		NOT NULL,
			NAMETYPE	nvarchar(3)	collate database_default NOT NULL,			
			SENT		bit,
			RECEIVED	int
			)
			
		INSERT INTO @tbCaseName (CASEID,NAMETYPE,NAMENO,SENT, RECEIVED)
		SELECT
			-600, '~CN', N.NAMENO,			
			CASE WHEN N.NAMENO % 2 = 0 THEN 1 ELSE 0 END,
			CASE	WHEN N.NAMENO % 2 = 0 THEN
				CASE	WHEN N.NAMENO % 5 = 0  THEN -15302 --'No Response'
						WHEN N.NAMENO % 3 = 0  THEN -15301 --'Accepted'
						ELSE -15303 --'Declined'				 
				END
			END
		from NAME N		
		left join CASENAME CN  on (CN.NAMENO  = N.NAMENO			
							and		CN.NAMETYPE = '~CN' 
							and		CN.CASEID = -600)				
		where N.NAMENO in
		(-96727600,-96391500,-96386000,-96385200,-95172200,-94542800,-94535700,-91052200,-79878000,-79877200,-79876400,-77943300,-75513600,-6314099,-6314098,-6314097,-6278799,-6255098,-6255097,-6255096,-6207398,-6178399,-6178398,-6178397,-6178396,-6178395,-6146099,-6146098,-6146097,-6113999,-6113998,-6113997,-6113996,-6113995,-6062699,-6022199,-6022198,-6022197,-6022196,-6022195,-6022194,-6022192,-6022191,-6022190,-5974900,-5951098,-5951097,-5951094,-5951093,-5951092, 6000, 6009, 6011)
		and CN.NAMENO is null		

		INSERT INTO CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, CORRESPSENT, CORRESPRECEIVED, DERIVEDCORRNAME)	
		select	CASEID, NAMETYPE, NAMENO, SEQUENCE, SENT, RECEIVED, 1
		from	@tbCaseName		
		
		PRINT '**** RFC5760 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Contacts for Campaign CASE -600 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -601 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC5760 Inserting new Instructor for Campaign CASEID = -601'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-601, 'I', -499, 0, 1)
		
		PRINT '**** RFC5760 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Instructor for Campaign CASE -601 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -601 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC5760 Inserting new Manager for Campaign CASEID = -601'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-601, 'EMP', -499, 0, 1)
		
		PRINT '**** RFC5760 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Manager for Campaign CASE -601 already exists'

	PRINT ''
	go

	IF not exists (SELECT * 
			FROM CASENAME CN
			WHERE	CN.NAMETYPE = '~CN' 
			AND		CN.CASEID = -601)
	Begin 
		PRINT '**** RFC5760 Inserting new Contacts for Campaign CASEID = -600'

		declare @tbCaseName table(
			SEQUENCE	int identity (1,1) not null,			
			CASEID		int		NOT NULL,
			NAMENO		int		NOT NULL,
			NAMETYPE	nvarchar(3)	collate database_default NOT NULL,			
			SENT		bit,
			RECEIVED	int
			)
			
		INSERT INTO @tbCaseName (CASEID,NAMETYPE,NAMENO,SENT, RECEIVED)
		SELECT
			-601, '~CN', N.NAMENO,			
			CASE WHEN N.NAMENO % 2 = 0 THEN 1 ELSE 0 END,
			CASE	WHEN N.NAMENO % 2 = 0 THEN
				CASE	WHEN N.NAMENO % 5 = 0  THEN -15302 --'No Response'
						WHEN N.NAMENO % 3 = 0  THEN -15301 --'Accepted'
						ELSE -15303 --'Declined'				 
				END
			END
		from NAME N		
		left join CASENAME CN  on (CN.NAMENO  = N.NAMENO			
							and		CN.NAMETYPE = '~CN' 
							and		CN.CASEID = -601)
		where N.NAMENO in
		(-6022198,-6022197,-6022196,-6022195,-6022194,-6022192,-6022191,-6022190,-5974900,-5951098,-5951097,-5951094,-5951093,-5951092,-5951091,-5951090,-5951089,-5908999,-5892099,-5892098,-5892097,-5892096,-5892095,-5892094,-5892093,-5892092,-5892091,-5892090,-5892089,-5892088,-5727899,-5710098,-5710097,-5710096,-5710095,-5710094,-5710093,-5710092,-5710091,-5710090,-5710089,-5710086,-5710084,-5710083,-5710082,-5710081,-5710080,-5710078,-5710075,-5710074,-5710072,-5710071,-5710070,-5710069,-5710068,-5710067,-5710066,-5710065,-5710064,-5710062,-5710061,-5710060,-5710059,-5664799,-5664798,-5664797,-5655098,-5655097,-5655096,-5655095,-5655094,-5655093,-5655092,-5655091,-5634599,-5634598,-5634597,-5634596,-5634595,-5634593,-5634592,-5634591,-5555098,-5555097,-5555096,-5555095,-5555094,-5555093,-5555092,-5555091,-5555090,-5555089,-5555088,-5555087,-5555086,-5546099,-5546098,-5546097,-5546096,-5546095,-5546094,-5524399,-5524098,-5524097,-5524096,-5524095,-5524094,-5524093,-5524092,-5524091,-5524090,-5503099,-5503098,-5503097, 6000, 6004, 6009, -495)
		and CN.NAMENO is null		

		INSERT INTO CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, CORRESPSENT, CORRESPRECEIVED, DERIVEDCORRNAME)	
		select	CASEID, NAMETYPE, NAMENO, SEQUENCE, SENT, RECEIVED, 1
		from	@tbCaseName
		
		PRINT '**** RFC5760 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Contacts for Campaign CASE -601 already exists'

	PRINT ''
	go		
	
	If not exists (Select * from CASENAME where CASEID = -602 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC5760 Inserting new Instructor for Campaign CASEID = -602'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-602, 'I', -487, 0, 1)
		
		PRINT '**** RFC5760 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Instructor for Campaign CASE -602 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -602 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC5760 Inserting new Manager for Campaign CASEID = -602'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-602, 'EMP', -487, 0, 1)
		
		PRINT '**** RFC5760 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Manager for Campaign CASE -602 already exists'

	PRINT ''
	go

	IF not exists (SELECT * 
			FROM CASENAME CN
			WHERE	CN.NAMETYPE = '~CN' 
			AND		CN.CASEID = -602)
	Begin 
		PRINT '**** RFC5760 Inserting new Contacts for Campaign CASEID = -600'

		declare @tbCaseName table(
			SEQUENCE	int identity (1,1) not null,			
			CASEID		int		NOT NULL,
			NAMENO		int		NOT NULL,
			NAMETYPE	nvarchar(3)	collate database_default NOT NULL,			
			SENT		bit,
			RECEIVED	int
			)
			
		INSERT INTO @tbCaseName (CASEID,NAMETYPE,NAMENO,SENT, RECEIVED)
		SELECT
			-602, '~CN', N.NAMENO,			
			CASE WHEN N.NAMENO % 2 = 0 THEN 1 ELSE 0 END,
			CASE	WHEN N.NAMENO % 2 = 0 THEN
				CASE	WHEN N.NAMENO % 5 = 0  THEN -15302 --'No Response'
						WHEN N.NAMENO % 3 = 0  THEN -15301 --'Accepted'
						ELSE -15303 --'Declined'				 
				END
			END
		from NAME N		
		left join CASENAME CN  on (CN.NAMENO  = N.NAMENO			
							and		CN.NAMETYPE = '~CN' 
							and		CN.CASEID = -602)
		where N.NAMENO in
		(-75513600,-6314099,-6314098,-6314097,-6278799,-6255098,6255097,-6255096,-6207398,-6178399,-6178398,-6178397,-6178396,-6178395,-6146099,-6146098,-6146097,-6113999,-6113998,-6113997,-6113996,-6113995,-6062699,-6022199,-6022198,-6022197,-6022196,-6022195,-6022194,-6022192,-6022191,-6022190,-5974900,-5951098,-5951097,-5951094,-5951093,-5951092,-5951091,-5951090,-5951089,-5908999,-5892099,-5892098,-5892097,-5892096,-5892095,-5892094,-5892093,-5892092,-5892091,-5892090,-5892089,-5892088,-5727899,-5710098,-5710097,-5710096,-5710095,-5710094,-5710093,-5710092,-5710091,-5710090,-5710089,-5710086,-5710084,-5710083,-5710082,-5710081,-5710080,-5710078,-5710075,-5710074,-5710072,-5710071,-5710070,-5710069,-5710068, 6009, 6011)
		and CN.NAMENO is null		

		INSERT INTO CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, CORRESPSENT, CORRESPRECEIVED, DERIVEDCORRNAME)	
		select	CASEID, NAMETYPE, NAMENO, SEQUENCE, SENT, RECEIVED, 1
		from	@tbCaseName
		
		PRINT '**** RFC5760 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Contacts for Campaign CASE -602 already exists'

	PRINT ''
	go

	If exists (select NTC.ALLOW
		from 	NAME N
		join	CASENAME CN on (CN.NAMENO = N.NAMENO)
		join	MARKETING M on (M.CASEID = CN.CASEID)
		join	NAMETYPE NT on (CN.NAMETYPE = NT.NAMETYPE and NT.PICKLISTFLAGS & 32 = 32 and NT.NAMETYPE ='~CN')
		left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO and NTC.NAMETYPE = NT.NAMETYPE)
		where NTC.ALLOW is null or  NTC.ALLOW = 0)
	Begin 
		PRINT '**** RFC5760 Ensuring contacts in the Marketing Activities have ~CN set'
				
		UPDATE NAMETYPECLASSIFICATION SET ALLOW = 1	
		where NAMETYPE = '~CN' 
		and NAMENO in (Select N.NAMENO 	
		from 	NAME N
		join	CASENAME CN on (CN.NAMENO = N.NAMENO)
		join	MARKETING M on (M.CASEID = CN.CASEID)
		join	NAMETYPE NT on (CN.NAMETYPE = NT.NAMETYPE and NT.PICKLISTFLAGS & 32 = 32 and NT.NAMETYPE ='~CN')
		left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO and NTC.NAMETYPE = NT.NAMETYPE)
		where NTC.ALLOW is null or  NTC.ALLOW = 0)

		PRINT '**** RFC5760 Contacts in the Marketing Activities have been set successfully'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Contacts in the Marketing Activities already have ~CN set'

	PRINT ''
	go

	If not exists (Select * from MARKETING where CASEID = -600)
	Begin 
		PRINT '**** RFC5760 Inserting new MARKETING data for Campaign for CASEID = -600'

		INSERT INTO MARKETING (CASEID, ACTUALCOST, ACTUALCOSTCURRENCY, ACTUALCOSTLOCAL)
		VALUES (-600, null, null, 40560)
	    
		PRINT '**** RFC5760 Data successfully added to Campaign table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 MARKETING for CASE -600 already exists'

	PRINT ''
	go

	If not exists (Select * from MARKETING where CASEID = -601)
	Begin 
		PRINT '**** RFC5760 Inserting new MARKETING data for Campaign for CASEID = -601'

		INSERT INTO MARKETING (CASEID, ACTUALCOST, ACTUALCOSTCURRENCY, ACTUALCOSTLOCAL)
		VALUES (-601, null, null, 24396)
	    
		PRINT '**** RFC5760 Data successfully added to Campaign table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 MARKETING for CASE -601 already exists'

	PRINT ''
	go

	If not exists (Select * from MARKETING where CASEID = -602)
	Begin 
		PRINT '**** RFC5760 Inserting new MARKETING data for Campaign for CASEID = -602'

		INSERT INTO MARKETING (CASEID, ACTUALCOST, ACTUALCOSTCURRENCY, ACTUALCOSTLOCAL)
		VALUES (-602, 9489, 'USD', 92083)
	    
		PRINT '**** RFC5760 Data successfully added to Campaign table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 MARKETING for CASE -600 already exists'

	PRINT ''
	go

	If not exists (Select * from CASEEVENT where CASEID = -600)
	BEGIN
		PRINT '**** RFC5760 Inserting date of entry and date of last change for Campaign CASEID = -600'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-600, -13, DATEADD(day, -1, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-600, -14, DATEADD(day, -1, getdate()), 1, 1)
	    
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-600, -12210, DATEADD(day, 30, getdate()), 1, 1)
	    
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-600, -12211, DATEADD(day, 120, getdate()), 1, 1)
	    
		PRINT '**** RFC5760 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 date of entry and date of last change for Campaign CASE -600 already exists'

	PRINT ''
	go

	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -600)
	BEGIN
		PRINT '**** RFC5760 Inserting CRMCASESTATUSHISTORY for Campaign CASEID = -600'

		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-600, -15202)
		
		PRINT '**** RFC5760 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 CRMCASESTATUSHISTORY for Campaign CASE -600 already exists'

	PRINT ''
	go


	If not exists (Select * from CASEEVENT where CASEID = -601)
	BEGIN
		PRINT '**** RFC5760 Inserting date of entry and date of last change for Campaign CASEID = -601'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-601, -13, DATEADD(day, -25, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-601, -14, DATEADD(day, -5, getdate()), 1, 1)

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-601, -12210, DATEADD(day, -10, getdate()), 1, 1)
	    
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-601, -12211, DATEADD(day, 90, getdate()), 1, 1)
	    
		PRINT '**** RFC5760 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 date of entry and date of last change for Campaign CASE -601 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -601)
	BEGIN
		PRINT '**** RFC5760 Inserting CRMCASESTATUSHISTORY for Campaign CASEID = -601'
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-601, -15201)	
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-601, -15202)				
		
		PRINT '**** RFC5760 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 CRMCASESTATUSHISTORY for Campaign CASE -601 already exists'

	PRINT ''
	go

	If not exists (Select * from CASEEVENT where CASEID = -602)
	BEGIN
		PRINT '**** RFC5760 Inserting date of entry and date of last change for Campaign CASEID = -602'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-602, -13, DATEADD(day, -23, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-602, -14, DATEADD(day, -2, getdate()), 1, 1)

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-602, -12210, DATEADD(day, -90, getdate()), 1, 1)
	    
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-602, -12211, DATEADD(day, 7, getdate()), 1, 1)
	    
		PRINT '**** RFC5760 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 date of entry and date of last change for Campaign CASE -602 already exists'

	PRINT ''
	go

	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -602)
	BEGIN
		PRINT '**** RFC5760 Inserting CRMCASESTATUSHISTORY for Campaign CASEID = -602'

		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-602, -15201)
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-602, -15202)			
			
		PRINT '**** RFC5760 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 CRMCASESTATUSHISTORY for Campaign CASE -602 already exists'

	PRINT ''
	go

	drop trigger tU_CRMCASESTATUSHISTORY_Audit
	go

	If (1=1)
	Begin 
		PRINT '**** RFC5760 Updating log identity id CRMCASESTATUSHISTORY.CASEID in (-600,-601,-602)'
		Update CRMCASESTATUSHISTORY 
			SET LOGIDENTITYID = IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'crm'
		and CRMCASESTATUSHISTORY.CASEID in (-600,-601,-602)
		and CRMCASESTATUSHISTORY.LOGIDENTITYID is null
		and CRMCASESTATUS is not null
		PRINT '**** RFC5760 Log identity id for CRMCASESTATUSHISTORY.CASEID in (-600,-601,-602) updated successfully'
	End

	If (1=1)
	Begin 
		PRINT '**** RFC5760 Updating log date time stamp for CRMCASESTATUSHISTORY.CASEID = -601'
		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -5, LOGDATETIMESTAMP) 
		where CASEID = -601
		and CRMCASESTATUS = -15201
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -5, getdate()))!=0

		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -3, LOGDATETIMESTAMP) 
		where CASEID = -601
		and CRMCASESTATUS = -15202
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -3, getdate()))!=0

		PRINT '**** RFC5760 LOGDATETIMESTAMP successfully updated to CRMCASESTATUSHISTORY table for CASEID=-601.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 CRMCASESTATUSHISTORY.LOGDATETIMESTAMP = -601 already updated'

	go

	If (1=1)
	Begin 
		PRINT '**** RFC5760 Updating log date time stamp for CRMCASESTATUSHISTORY.CASEID = -602'
		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -1, LOGDATETIMESTAMP) 
		where CASEID = -602
		and CRMCASESTATUS = -15202
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -1, getdate()))!=0
		
		PRINT '**** RFC5760 LOGDATETIMESTAMP successfully updated to CRMCASESTATUSHISTORY table for CASEID=-602.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 CRMCASESTATUSHISTORY.LOGDATETIMESTAMP = -602 already updated'

	go

	exec ipu_UtilGenerateAuditTriggers @psTable='CRMCASESTATUSHISTORY', @pbPrintLog=0
	go
	
	If not exists (Select * from RELATEDCASE where CASEID = -600)
	Begin 
		PRINT '**** RFC5760 Inserting new related opportunity case for CASEID = -600'

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-600, 0, '~OP', -500)

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-600, 1, '~OP', -501)

		PRINT '**** RFC5760 Opportunity related case successfully added for CASEID = -600.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Opportunity related case for -600 already exists'

	PRINT ''
	go

	If not exists (Select * from RELATEDCASE where RELATEDCASEID = -600)
	Begin 
		PRINT '**** RFC5760 Inserting new reciprocal related opportunity case for CASEID = -600'

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-500, 0, '~MK', -600)

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-501, 0, '~MK', -600)

		PRINT '**** RFC5760 Reciprocal Opportunity related case successfully added for CASEID = -600.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Reciprocal Opportunity related case for -600 already exists'

	PRINT ''
	go

	If not exists (Select * from RELATEDCASE where CASEID = -601)
	Begin 
		PRINT '**** RFC5760 Inserting new related opportunity case for CASEID = -601'
		
		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-601, 0, '~OP', -502)

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-502, 0, '~MK', -601)

		PRINT '**** RFC5760 Opportunity related case successfully added for CASEID = -601.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5760 Opportunity related case for -601 already exists'

	PRINT ''
	go

	
	
	/**********************************************************************************************************/
	/*** RFC5761 Insert New Marketing Events																	***/
	/**********************************************************************************************************/
	If not exists (Select * from CASES where CASEID = -700)
	Begin 
		PRINT '**** RFC5761 Inserting new Marketing Event CASEID = -700'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, TITLE, BUDGETAMOUNT, LOCALCLIENTFLAG)
		values (-700, 'AU/TRADESHOW/2008', 'M', 'E', 'AU', 'D', 'Australian Tradeshow 2008', 15000, 1)
		
		PRINT '**** RFC5761 Data successfully added to Marketing Event table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Marketing Event CASE -700 already exists'

	PRINT ''
	go


	If not exists (Select * from CASES where CASEID = -701)
	Begin 
		PRINT '**** RFC5761 Inserting new Marketing Event CASEID = -701'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, TITLE, BUDGETAMOUNT, LOCALCLIENTFLAG)
		values (-701, 'AU/UG/2008', 'M', 'E', 'AU', 'B', 'Australian User Group Conference 2008', 10000, 1)
		
		PRINT '**** RFC5761 Data successfully added to Marketing Event table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Marketing Event CASE -701 already exists'

	PRINT ''
	go

	If not exists (Select * from CASES where CASEID = -702)
	Begin 
		PRINT '**** RFC5761 Inserting new Marketing Event CASEID = -702'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, TITLE, BUDGETAMOUNT, LOCALCLIENTFLAG)
		values (-702, 'US/SEMINAR/01', 'M', 'E', 'US', 'A', 'US WorkBench Seminar', 3000, 0)
		
		PRINT '**** RFC5761 Data successfully added to Marketing Event table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Marketing Event CASE -702 already exists'

	PRINT ''
	go

	If not exists (Select * from CASES where CASEID = -703)
	Begin 
		PRINT '**** RFC5761 Inserting new Marketing Event CASEID = -703'

		insert into CASES (CASEID, IRN, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, TITLE, BUDGETAMOUNT, LOCALCLIENTFLAG)
		values (-703, 'EU/UG/2008', 'M', 'E', 'GB', 'B', 'European User Group Conference 2008', 40000, 0)
		
		PRINT '**** RFC5761 Data successfully added to Marketing Event table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Marketing Event CASE -703 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -700 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC5761 Inserting new Instructor for Marketing Event CASEID = -700'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-700, 'I', -487, 0, 1)
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Instructor for Marketing Event CASE -700 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -700 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC5761 Inserting new Manager for Marketing Event CASEID = -700'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-700, 'EMP', -487, 0, 1)
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Manager for Marketing Event CASE -700 already exists'

	PRINT ''
	go

	IF not exists (SELECT * 
			FROM CASENAME CN
			WHERE	CN.NAMETYPE = '~CN' 
			AND		CN.CASEID = -700)
	Begin 
		PRINT '**** RFC5761 Inserting new Contacts for Marketing Event CASEID = -700'

		declare @tbCaseName table(
			SEQUENCE	int identity (1,1) not null,			
			CASEID		int		NOT NULL,
			NAMENO		int		NOT NULL,
			NAMETYPE	nvarchar(3)	collate database_default NOT NULL,			
			SENT		bit,
			RECEIVED	int
			)
			
		INSERT INTO @tbCaseName (CASEID,NAMETYPE,NAMENO,SENT, RECEIVED)
		SELECT
			-700, '~CN', N.NAMENO,			
			CASE WHEN N.NAMENO % 2 = 0 THEN 1 ELSE 0 END,
			CASE	WHEN N.NAMENO % 2 = 0 THEN
				CASE	WHEN N.NAMENO % 5 = 0  THEN -15302 --'No Response'
						WHEN N.NAMENO % 3 = 0  THEN -15301 --'Accepted'
						ELSE -15303 --'Declined'				 
				END
			END
		from NAME N		
		left join CASENAME CN  on (CN.NAMENO  = N.NAMENO			
							and		CN.NAMETYPE = '~CN' 
							and		CN.CASEID = -700)				
		where N.NAMENO in
		(-5001080, -5001079, -5001078, -5001077, -5001076, -5001075, -5001074, -5001073, -1681098, -1681097, -1681096, -1681095, -598500, -102899, -495, -491, -489, -486, -484, -481, -199, -197, -196, -195, -194, -193, -192, -191, -190, -9, -8, -7, -6, -5, -4, 9, 11, 14, 15, 22, 25, 29, 34, 43, 44, 50, 51, 53, 54, 56, 57, 58, 59, 60, 66, 68, 69, 70, 72, 73, 74, 75, 76, 78, 81, 84, 86, 93, 118, 119, 123, 124, 125, 126, 127, 129, 130, 133, 134, 135, 136, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 154, 6001, 6004, 6006, 6009, 6011, 10002, 10003, 10004, 10005, 10007, 10008, 10009, 10010, 10012, 10013, 10014, 10015, 10016, 10018, 10021, 10022, 10023, 10024, 6000, 6009, 6011)
		and CN.NAMENO is null		

		INSERT INTO CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, CORRESPSENT, CORRESPRECEIVED, DERIVEDCORRNAME)	
		select	CASEID, NAMETYPE, NAMENO, SEQUENCE, SENT, RECEIVED, 1
		from	@tbCaseName		
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Contacts for Marketing Event CASE -700 already exists'

	PRINT ''
	go

	If not exists (Select * from CASENAME where CASEID = -701 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC5761 Inserting new Instructor for Marketing Event CASEID = -701'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-701, 'I', -499, 0, 1)
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Instructor for Marketing Event CASE -701 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -701 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC5761 Inserting new Manager for Marketing Event CASEID = -701'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-701, 'EMP', -499, 0, 1)
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Manager for Marketing Event CASE -701 already exists'

	PRINT ''
	go

	IF not exists (SELECT * 
			FROM CASENAME CN
			WHERE	CN.NAMETYPE = '~CN' 
			AND		CN.CASEID = -701)
	Begin 
		PRINT '**** RFC5761 Inserting new Contacts for Marketing Event CASEID = -700'

		declare @tbCaseName table(
			SEQUENCE	int identity (1,1) not null,			
			CASEID		int		NOT NULL,
			NAMENO		int		NOT NULL,
			NAMETYPE	nvarchar(3)	collate database_default NOT NULL,			
			SENT		bit,
			RECEIVED	int
			)
			
		INSERT INTO @tbCaseName (CASEID,NAMETYPE,NAMENO,SENT, RECEIVED)
		SELECT
			-701, '~CN', N.NAMENO,			
			CASE WHEN N.NAMENO % 2 = 0 THEN 1 ELSE 0 END,
			CASE	WHEN N.NAMENO % 2 = 0 THEN
				CASE	WHEN N.NAMENO % 5 = 0  THEN -15302 --'No Response'
						WHEN N.NAMENO % 3 = 0  THEN -15301 --'Accepted'
						ELSE -15303 --'Declined'				 
				END
			END
		from NAME N		
		left join CASENAME CN  on (CN.NAMENO  = N.NAMENO			
							and		CN.NAMETYPE = '~CN' 
							and		CN.CASEID = -701)
		where N.NAMENO in
		(-5097299, -5097298, -5097297, -5097296, -5096099, -5096098, -5096097, -5096094, -5096093, -5096092, -5096091, -5096090, -5096089, -5096088, -5096087, -5096086, -5096085, -5096084, -5096083, -5096082, -5096081, -5096080, -5096079, -5096078, -5096077, -5087299, -5048599, -5048598, -5020899, -5006099, -5006098, -5001099, -5001098, -5001097, -5001096, -5001095, -5001094, -5001093, -5001092, -5001091, -5001090, -5001089, -5001088, -5001087, -5001086, -5001085, -5001084, -5001083, -5001082, -5001081, -5001080, -5001079, -5001078, -5001077, -5001076, -5001075, -5001074, -5001073, -1681098, -1681097, -1681096, -1681095, -598500, -102899, -495, -491, -489, -486, -484, -481, -199, -197, -196, -195, -194, -193, -192, -191, -190, -9, -8, -7, -6, -5, -4, 9, 11, 14, 15, 22, 25, 29, 34, 43, 44, 50, 51, 53, 54, 56, 57, 58, 59, 60, 66, 68, 69, 70, 72, 73, 74, 75, 76, 78, 81, 84, 86, 93, 118, 119, 123, 124, 125, 126, 127, 129, 130, 133, 134, 135, 136, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 154, 6001, 6004, 6006, 6009, -495)
		and CN.NAMENO is null		

		INSERT INTO CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, CORRESPSENT, CORRESPRECEIVED, DERIVEDCORRNAME)	
		select	CASEID, NAMETYPE, NAMENO, SEQUENCE, SENT, RECEIVED, 1
		from	@tbCaseName
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Contacts for Marketing Event CASE -701 already exists'

	PRINT ''
	go		
	
	If not exists (Select * from CASENAME where CASEID = -702 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC5761 Inserting new Instructor for Marketing Event CASEID = -702'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-702, 'I', -487, 0, 1)
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Instructor for Marketing Event CASE -702 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -702 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC5761 Inserting new Manager for Marketing Event CASEID = -702'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-702, 'EMP', -487, 0, 1)
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Manager for Marketing Event CASE -702 already exists'

	PRINT ''
	go

	IF not exists (SELECT * 
			FROM CASENAME CN
			WHERE	CN.NAMETYPE = '~CN' 
			AND		CN.CASEID = -702)
	Begin 
		PRINT '**** RFC5761 Inserting new Contacts for Marketing Event CASEID = -700'

		declare @tbCaseName table(
			SEQUENCE	int identity (1,1) not null,			
			CASEID		int		NOT NULL,
			NAMENO		int		NOT NULL,
			NAMETYPE	nvarchar(3)	collate database_default NOT NULL,			
			SENT		bit,
			RECEIVED	int
			)
			
		INSERT INTO @tbCaseName (CASEID,NAMETYPE,NAMENO,SENT, RECEIVED)
		SELECT
			-702, '~CN', N.NAMENO,			
			CASE WHEN N.NAMENO % 2 = 0 THEN 1 ELSE 0 END,
			CASE	WHEN N.NAMENO % 2 = 0 THEN
				CASE	WHEN N.NAMENO % 5 = 0  THEN -15302 --'No Response'
						WHEN N.NAMENO % 3 = 0  THEN -15301 --'Accepted'
						ELSE -15303 --'Declined'				 
				END
			END
		from NAME N		
		left join CASENAME CN  on (CN.NAMENO  = N.NAMENO			
							and		CN.NAMETYPE = '~CN' 
							and		CN.CASEID = -702)
		where N.NAMENO in
		(-6146098,-6146097,-6113999,-6113998,-6113997,-6113996,-6113995,-6062699,-7022199,-7022198,-7022197,-7022196,-7022195,-7022194,-7022192,-7022191,-7022190,-5974900,-5951098,-5951097,-5951094,-5951093,-5951092,-5951091,-5951090,-5951089,-5908999,-5892099,-5892098,-5892097,-5892096,-5892095,-5892094,-5892093,-5892092,-5892091,-5892090,-5892089,-5892088,-5727899,-5710098,-5710097,-5710096,-5710095,-5710094,-5710093,-5710092,-5710091,-5710090,-5710089,-5710086,-5710084,-5710083,-5710082,-5710081,-5710080,-5710078,-5710075,-5710074,-5710072,-5710071,-5710070,-5710069,-5710068, 6009, 6011)
		and CN.NAMENO is null		

		INSERT INTO CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, CORRESPSENT, CORRESPRECEIVED, DERIVEDCORRNAME)	
		select	CASEID, NAMETYPE, NAMENO, SEQUENCE, SENT, RECEIVED, 1
		from	@tbCaseName
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Contacts for Marketing Event CASE -702 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -703 and NAMETYPE = 'I')
	Begin 
		PRINT '**** RFC5761 Inserting new Instructor for Marketing Event CASEID = -703'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-703, 'I', -487, 0, 1)
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Instructor for Marketing Event CASE -703 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASENAME where CASEID = -703 and NAMETYPE = 'EMP')
	Begin 
		PRINT '**** RFC5761 Inserting new Manager for Marketing Event CASEID = -703'

		insert into CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, DERIVEDCORRNAME)
		values (-703, 'EMP', -487, 0, 1)
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Manager for Marketing Event CASE -703 already exists'

	PRINT ''
	go
	
	IF not exists (SELECT * 
			FROM CASENAME CN
			WHERE	CN.NAMETYPE = '~CN' 
			AND		CN.CASEID = -703)
	Begin 
		PRINT '**** RFC5761 Inserting new Contacts for Marketing Event CASEID = -703'

		declare @tbCaseName table(
			SEQUENCE	int identity (1,1) not null,			
			CASEID		int		NOT NULL,
			NAMENO		int		NOT NULL,
			NAMETYPE	nvarchar(3)	collate database_default NOT NULL,			
			SENT		bit,
			RECEIVED	int
			)
			
		INSERT INTO @tbCaseName (CASEID,NAMETYPE,NAMENO,SENT, RECEIVED)
		SELECT
			-703, '~CN', N.NAMENO,			
			CASE WHEN N.NAMENO % 2 = 0 THEN 1 ELSE 0 END,
			CASE	WHEN N.NAMENO % 2 = 0 THEN
				CASE	WHEN N.NAMENO % 5 = 0  THEN -15302 --'No Response'
						WHEN N.NAMENO % 3 = 0  THEN -15301 --'Accepted'
						ELSE -15303 --'Declined'				 
				END
			END
		from NAME N		
		left join CASENAME CN  on (CN.NAMENO  = N.NAMENO			
							and		CN.NAMETYPE = '~CN' 
							and		CN.CASEID = -703)
		where N.NAMENO in
		(-91052200, -79878000, -79877200, -79876400, -77943300, -75513600, -6314099, -6314098, -6314097, -6278799, -6255098, -6255097, -6255096, -6207398, -6178399, -6178398, -6178397, -6178396, -6178395, -6146099, -6146098, -6146097, -6113999, -6113998, -6113997, -6113996, -6113995, -6062699, -6022199, -6022198, -6022197, -6022196, -6022195, -6022194, -6022192, -6022191, -6022190, -5974900, -5951098, -5951097, -5951094, -5951093, -5951092, -5951091, -5951090, -5951089, -5908999, -5892099, -5892098, -5892097, -5892096, -5892095, -5892094, -5892093, -5892092, -5892091, -5892090, -5892089, -5892088, -5727899, -5710098, -5710097, -5710096, -5710095, -5710094, -5710093, -5710092, -5710091, -5710090, -5710089, -5710086, -5710084, -5710083, -5710082, -5710081, -5710080, -5710078, -5710075, -5710074, -5710072, -5710071, -5710070, -5710069, -5710068, -5710067, -5710066, -5710065, -5710064, -5710062, -5710061, -5710060, -5710059, -5664799, -5664798, -5664797, -5655098, -5655097, -5655096, -5655095, -5655094, -5655093, -5655092, -5655091, -5634599, -5634598, -5634597, -5634596, -5634595, -5634593, -5634592, -5634591, -5555098, -5555097, -5555096, -5555095, -5555094, -5555093, -5555092, -5555091, -5555090, -5555089, -5555088, -5555087, -5555086, -5546099, -5546098, -5546097, -5546096, -5546095, -5546094, -5524399, -5524098, -5524097, -5524096, -5524095, -5524094, -5524093, -5524092, -5524091, -5524090, -5503099, -5503098, -5503097, -5485099, -5485098, -5485097, -5485096, -5485095, -5485094, -5485093, -5485092, -5485091, -5485090, -5485089, -5466099, -5466098, -5466097, -5466096, -5466095, -5466094, -5466093, -5466092, -5466091, -5344899, -5335099, -5335098, -5323099, -5323098, -5323096, -5323094, -5323093, -5323092, -5323091, -5323090, -5323089, -5323088, -5323087, -5323086, -5269099, -5269098, -5269097, -5269096, -5269095, -5256599, -5241299, -5216099, -5216098, -5216097, -5216096, -5212099, -5212098, -5212097, -5212096, -5109099, -5109098, -5109097, -5109096, -5109095, -5109094, -5109093, -5097299, -5097298, -5097297, -5097296, -5096099, -5096098, -5096097, -5096094, -5096093, -5096092, -5096091, -5096090, -5096089, -5096088, -5096087, -5096086, -5096085, -5096084, -5096083, -5096082, -5096081, -5096080, -5096079, -5096078, -5096077, -5087299, -5048599, -5048598, -5020899, -5006099, -5006098, -5001099, -5001098, -5001097, -5001096, -5001095, -5001094, -5001093, -5001092, -5001091, -5001090, -5001089, -5001088, -5001087, -5001086, -5001085, -5001084, -5001083, -5001082, -5001081, -5001080, -5001079, -5001078, -5001077, -5001076, -5001075, -5001074, -5001073, -1681098, -1681097, -1681096, -1681095, -598500, -102899, -495, -491, -489, -486, -484, -481, 6009, 6011)
		and CN.NAMENO is null		

		INSERT INTO CASENAME (CASEID, NAMETYPE, NAMENO, SEQUENCE, CORRESPSENT, CORRESPRECEIVED, DERIVEDCORRNAME)	
		select	CASEID, NAMETYPE, NAMENO, SEQUENCE, SENT, RECEIVED, 1
		from	@tbCaseName
		
		PRINT '**** RFC5761 Data successfully added to Case Name table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Contacts for Marketing Event CASE -703 already exists'

	PRINT ''
	go

	If exists (select NTC.ALLOW
		from 	NAME N
		join	CASENAME CN on (CN.NAMENO = N.NAMENO)
		join	MARKETING M on (M.CASEID = CN.CASEID)
		join	NAMETYPE NT on (CN.NAMETYPE = NT.NAMETYPE and NT.PICKLISTFLAGS & 32 = 32 and NT.NAMETYPE ='~CN')
		left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO and NTC.NAMETYPE = NT.NAMETYPE)
		where NTC.ALLOW is null or  NTC.ALLOW = 0)
	Begin 
		PRINT '**** RFC5761 Ensuring contacts in the Marketing Activities have ~CN set'
				
		UPDATE NAMETYPECLASSIFICATION SET ALLOW = 1	
		where NAMETYPE = '~CN' 
		and NAMENO in (Select N.NAMENO 	
		from 	NAME N
		join	CASENAME CN on (CN.NAMENO = N.NAMENO)
		join	MARKETING M on (M.CASEID = CN.CASEID)
		join	NAMETYPE NT on (CN.NAMETYPE = NT.NAMETYPE and NT.PICKLISTFLAGS & 32 = 32 and NT.NAMETYPE ='~CN')
		left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO and NTC.NAMETYPE = NT.NAMETYPE)
		where NTC.ALLOW is null or  NTC.ALLOW = 0)

		PRINT '**** RFC5761 Contacts in the Marketing Activities have been set successfully'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Contacts in the Marketing Activities already have ~CN set'

	PRINT ''
	go

	If not exists (Select * from MARKETING where CASEID = -700)
	Begin 
		PRINT '**** RFC5761 Inserting new MARKETING data for Marketing Event for CASEID = -700'

		INSERT INTO MARKETING (CASEID, ACTUALCOST, ACTUALCOSTCURRENCY, ACTUALCOSTLOCAL)
		VALUES (-700, null, null, 14560)
	    
		PRINT '**** RFC5761 Data successfully added to Marketing Event table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 MARKETING for CASE -700 already exists'

	PRINT ''
	go

	If not exists (Select * from MARKETING where CASEID = -701)
	Begin 
		PRINT '**** RFC5761 Inserting new MARKETING data for Marketing Event for CASEID = -701'

		INSERT INTO MARKETING (CASEID, ACTUALCOST, ACTUALCOSTCURRENCY, ACTUALCOSTLOCAL)
		VALUES (-701, null, null, 8653)
	    
		PRINT '**** RFC5761 Data successfully added to Marketing Event table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 MARKETING for CASE -701 already exists'

	PRINT ''
	go

	If not exists (Select * from MARKETING where CASEID = -702)
	Begin 
		PRINT '**** RFC5761 Inserting new MARKETING data for Marketing Event for CASEID = -702'

		INSERT INTO MARKETING (CASEID, ACTUALCOST, ACTUALCOSTCURRENCY, ACTUALCOSTLOCAL)
		VALUES (-702, 4000, 'USD', 4321)
	    
		PRINT '**** RFC5761 Data successfully added to Marketing Event table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 MARKETING for CASE -700 already exists'

	PRINT ''
	go
	
	If not exists (Select * from MARKETING where CASEID = -703)
	Begin 
		PRINT '**** RFC5761 Inserting new MARKETING data for Marketing Event for CASEID = -703'

		INSERT INTO MARKETING (CASEID, ACTUALCOST, ACTUALCOSTCURRENCY, ACTUALCOSTLOCAL)
		VALUES (-703, 19563, 'EUR', 33934.08)
	    
		PRINT '**** RFC5761 Data successfully added to Marketing Event table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 MARKETING for CASE -703 already exists'

	PRINT ''
	go

	If not exists (Select * from CASEEVENT where CASEID = -700)
	BEGIN
		PRINT '**** RFC5761 Inserting date of entry and date of last change for Marketing Event CASEID = -700'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-700, -13, DATEADD(day, -43, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-700, -14, DATEADD(day, -1, getdate()), 1, 1)
	    
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-700, -12210, DATEADD(day, 43, getdate()), 1, 1)
	    
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-700, -12211, DATEADD(day, 20, getdate()), 1, 1)
	    
		PRINT '**** RFC5761 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 date of entry and date of last change for Marketing Event CASE -700 already exists'

	PRINT ''
	go

	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -700)
	BEGIN
		PRINT '**** RFC5761 Inserting CRMCASESTATUSHISTORY for Marketing Event CASEID = -700'

		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-700, -15202)
		
		PRINT '**** RFC5761 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 CRMCASESTATUSHISTORY for Marketing Event CASE -700 already exists'

	PRINT ''
	go


	If not exists (Select * from CASEEVENT where CASEID = -701)
	BEGIN
		PRINT '**** RFC5761 Inserting date of entry and date of last change for Marketing Event CASEID = -701'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-701, -13, DATEADD(day, -55, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-701, -14, DATEADD(day, -5, getdate()), 1, 1)

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-701, -12210, DATEADD(day, -55, getdate()), 1, 1)
	    
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-701, -12211, DATEADD(day, 190, getdate()), 1, 1)
	    
		PRINT '**** RFC5761 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 date of entry and date of last change for Marketing Event CASE -701 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -701)
	BEGIN
		PRINT '**** RFC5761 Inserting CRMCASESTATUSHISTORY for Marketing Event CASEID = -701'
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-701, -15201)	
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-701, -15202)				
		
		PRINT '**** RFC5761 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 CRMCASESTATUSHISTORY for Marketing Event CASE -701 already exists'

	PRINT ''
	go

	If not exists (Select * from CASEEVENT where CASEID = -702)
	BEGIN
		PRINT '**** RFC5761 Inserting date of entry and date of last change for Marketing Event CASEID = -702'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-702, -13, DATEADD(day, -23, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-702, -14, DATEADD(day, -2, getdate()), 1, 1)

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-702, -12210, DATEADD(day, -23, getdate()), 1, 1)
	    
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-702, -12211, DATEADD(day, 7, getdate()), 1, 1)
	    
		PRINT '**** RFC5761 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 date of entry and date of last change for Marketing Event CASE -702 already exists'

	PRINT ''
	go

	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -702)
	BEGIN
		PRINT '**** RFC5761 Inserting CRMCASESTATUSHISTORY for Marketing Event CASEID = -702'
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-702, -15201)	
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-702, -15202)				
		
		PRINT '**** RFC5761 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 CRMCASESTATUSHISTORY for Marketing Event CASE -702 already exists'

	PRINT ''
	go

	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -703)
	BEGIN
		PRINT '**** RFC5761 Inserting CRMCASESTATUSHISTORY for Marketing Event CASEID = -703'

		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-703, -15201)
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-703, -15202)			
			
		PRINT '**** RFC5761 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 CRMCASESTATUSHISTORY for Marketing Event CASE -703 already exists'

	PRINT ''
	go
	
	If not exists (Select * from CASEEVENT where CASEID = -703)
	BEGIN
		PRINT '**** RFC5761 Inserting date of entry and date of last change for Marketing Event CASEID = -703'

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-703, -13, DATEADD(day, -63, getdate()), 1, 1)
		
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-703, -14, DATEADD(day, -23, getdate()), 1, 1)

		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-703, -12210, DATEADD(day, -63, getdate()), 1, 1)
	    
		INSERT INTO CASEEVENT (CASEID, EVENTNO, EVENTDATE, CYCLE, OCCURREDFLAG)
		VALUES (-703, -12211, DATEADD(day, 7, getdate()), 1, 1)
	    
		PRINT '**** RFC5761 Data successfully added to CASEEVENT table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 date of entry and date of last change for Marketing Event CASE -703 already exists'

	PRINT ''
	go

	If not exists (Select * from CRMCASESTATUSHISTORY where CASEID = -703)
	BEGIN
		PRINT '**** RFC5761 Inserting CRMCASESTATUSHISTORY for Marketing Event CASEID = -703'

		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-703, -15201)
		
		INSERT INTO CRMCASESTATUSHISTORY (CASEID, CRMCASESTATUS)
		VALUES (-703, -15202)			
			
		PRINT '**** RFC5761 Data successfully added to CRMCASESTATUSHISTORY table.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 CRMCASESTATUSHISTORY for Marketing Event CASE -703 already exists'

	PRINT ''
	go

	drop trigger tU_CRMCASESTATUSHISTORY_Audit
	go

	If (1=1)
	Begin 
		PRINT '**** RFC5761 Updating log identity id CRMCASESTATUSHISTORY.CASEID in (-700,-701,-702)'
		Update CRMCASESTATUSHISTORY 
			SET LOGIDENTITYID = IDENTITYID
		from USERIDENTITY 
		where LOGINID = 'crm'
		and CRMCASESTATUSHISTORY.CASEID in (-700,-701,-702,-703)
		and CRMCASESTATUSHISTORY.LOGIDENTITYID is null
		and CRMCASESTATUS is not null
		PRINT '**** RFC5761 Log identity id for CRMCASESTATUSHISTORY.CASEID in (-700,-701,-702) updated successfully'
	End

	If (1=1)
	Begin 
		PRINT '**** RFC5761 Updating log date time stamp for CRMCASESTATUSHISTORY.CASEID = -701'
		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -43, LOGDATETIMESTAMP) 
		where CASEID = -700
		and CRMCASESTATUS = -15201
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -5, getdate()))!=0

		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -20, LOGDATETIMESTAMP) 
		where CASEID = -700
		and CRMCASESTATUS = -15202
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -3, getdate()))!=0

		PRINT '**** RFC5761 LOGDATETIMESTAMP successfully updated to CRMCASESTATUSHISTORY table for CASEID=-701.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 CRMCASESTATUSHISTORY.LOGDATETIMESTAMP = -701 already updated'

	go

	If (1=1)
	Begin 
		PRINT '**** RFC5761 Updating log date time stamp for CRMCASESTATUSHISTORY.CASEID = -701'
		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -5, LOGDATETIMESTAMP) 
		where CASEID = -701
		and CRMCASESTATUS = -15201
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -5, getdate()))!=0

		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -3, LOGDATETIMESTAMP) 
		where CASEID = -701
		and CRMCASESTATUS = -15202
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -3, getdate()))!=0

		PRINT '**** RFC5761 LOGDATETIMESTAMP successfully updated to CRMCASESTATUSHISTORY table for CASEID=-701.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 CRMCASESTATUSHISTORY.LOGDATETIMESTAMP = -701 already updated'

	go

	If (1=1)
	Begin 
		PRINT '**** RFC5761 Updating log date time stamp for CRMCASESTATUSHISTORY.CASEID = -702'
		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -1, LOGDATETIMESTAMP) 
		where CASEID = -702
		and CRMCASESTATUS = -15202
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -1, getdate()))!=0
		
		PRINT '**** RFC5761 LOGDATETIMESTAMP successfully updated to CRMCASESTATUSHISTORY table for CASEID=-702.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 CRMCASESTATUSHISTORY.LOGDATETIMESTAMP = -702 already updated'

	go

	If (1=1)
	Begin 
		PRINT '**** RFC5761 Updating log date time stamp for CRMCASESTATUSHISTORY.CASEID = -703'
		Update CRMCASESTATUSHISTORY 
			SET LOGDATETIMESTAMP = DATEADD(day, -1, LOGDATETIMESTAMP) 
		where CASEID = -703
		and CRMCASESTATUS = -15202
		and DATEDIFF(day, LOGDATETIMESTAMP, DATEADD(day, -1, getdate()))!=0
		
		PRINT '**** RFC5761 LOGDATETIMESTAMP successfully updated to CRMCASESTATUSHISTORY table for CASEID=-703.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 CRMCASESTATUSHISTORY.LOGDATETIMESTAMP = -703 already updated'

	go

	exec ipu_UtilGenerateAuditTriggers @psTable='CRMCASESTATUSHISTORY', @pbPrintLog=0
	go
	
	If not exists (Select * from RELATEDCASE where CASEID = -701)
	Begin 
		PRINT '**** RFC5761 Inserting new related opportunity case for CASEID = -701'

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-701, 0, '~OP', -500)

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-701, 1, '~OP', -501)

		PRINT '**** RFC5761 Opportunity related case successfully added for CASEID = -701.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Opportunity related case for -701 already exists'

	PRINT ''
	go

	If not exists (Select * from RELATEDCASE where RELATEDCASEID = -701)
	Begin 
		PRINT '**** RFC5761 Inserting new reciprocal related opportunity case for CASEID = -701'

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-500, 1, '~MK', -701)

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-501, 1, '~MK', -701)

		PRINT '**** RFC5761 Reciprocal Opportunity related case successfully added for CASEID = -701.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Reciprocal Opportunity related case for -701 already exists'

	PRINT ''
	go

	If not exists (Select * from RELATEDCASE where CASEID = -703)
	Begin 
		PRINT '**** RFC5761 Inserting new related opportunity case for CASEID = -703'
		
		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-703, 1, '~OP', -502)

		insert RELATEDCASE (CASEID, RELATIONSHIPNO, RELATIONSHIP, RELATEDCASEID)
		values (-502, 1, '~MK', -703)

		PRINT '**** RFC5761 Opportunity related case successfully added for CASEID = -703.'
		PRINT ''
	END
	ELSE
		PRINT '**** RFC5761 Opportunity related case for -703 already exists'

	PRINT ''
	go
	
	if not exists (select 1 from SELECTIONTYPES WHERE PARENTTABLE = 'MARKETING ACTIVITIES/MARKETING EVENT' AND TABLETYPE =-498)
	Begin
		PRINT '**** RFC5712 Insert -498 selection type for Marketing Event'
		INSERT INTO SELECTIONTYPES (PARENTTABLE, TABLETYPE, MINIMUMALLOWED,MAXIMUMALLOWED)
		VALUES('MARKETING ACTIVITIES/MARKETING EVENT', -498, 0, 1)
		PRINT '**** RFC5712 selection type successfully added'
		PRINT ''
	End
	
	if not exists (select 1 from SELECTIONTYPES WHERE PARENTTABLE = 'MARKETING ACTIVITIES/MARKETING EVENT' AND TABLETYPE = 143)
	Begin
		PRINT '**** RFC5712 Insert selection type for Marketing Event'
		INSERT INTO SELECTIONTYPES (PARENTTABLE, TABLETYPE, MINIMUMALLOWED,MAXIMUMALLOWED)
		VALUES('MARKETING ACTIVITIES/MARKETING EVENT', 143, 0, 5)
		PRINT '**** RFC5712 selection type successfully added'
		PRINT ''
	End
	ELSE
	PRINT '**** RFC5712 Selection type already exists'
	PRINT ''
	go

	if not exists (select 1 from SELECTIONTYPES WHERE PARENTTABLE = 'MARKETING ACTIVITIES/MARKETING EVENT' AND TABLETYPE = 151)
	Begin
		PRINT '**** RFC5712 Insert 151 selection type for Marketing Event'
		INSERT INTO SELECTIONTYPES (PARENTTABLE, TABLETYPE, MINIMUMALLOWED,MAXIMUMALLOWED)
		VALUES('MARKETING ACTIVITIES/MARKETING EVENT', 151, 0, NULL)
		PRINT '**** RFC5712 selection type successfully added'
		PRINT ''
	End
	ELSE
	PRINT '**** RFC5712 Selection type already exists'
	PRINT ''
	go

	if not exists (select 1 from SELECTIONTYPES WHERE PARENTTABLE = 'MARKETING ACTIVITIES/CAMPAIGN' AND TABLETYPE = -498)
	Begin
		PRINT '**** RFC5712 Insert -498 selection type for Campaign'
		INSERT INTO SELECTIONTYPES (PARENTTABLE, TABLETYPE, MINIMUMALLOWED,MAXIMUMALLOWED)
		VALUES('MARKETING ACTIVITIES/CAMPAIGN', -498, 0, 1)
		PRINT '**** RFC5712 selection type successfully added'
		PRINT ''
	End
	ELSE
	PRINT '**** RFC5712 Selection type already exists'
	PRINT ''
	go	

	if not exists (select 1 from SELECTIONTYPES WHERE PARENTTABLE = 'MARKETING ACTIVITIES/CAMPAIGN' AND TABLETYPE = 143)
	Begin
		PRINT '**** RFC5712 Insert 143 selection type for Campaign'
		INSERT INTO SELECTIONTYPES (PARENTTABLE, TABLETYPE, MINIMUMALLOWED,MAXIMUMALLOWED)
		VALUES('MARKETING ACTIVITIES/CAMPAIGN', 143, 0, 5)
		PRINT '**** RFC5712 selection type successfully added'
		PRINT ''
	End
	ELSE
	PRINT '**** RFC5712 Selection type already exists'
	PRINT ''
	go

	if not exists (select 1 from SELECTIONTYPES WHERE PARENTTABLE = 'MARKETING ACTIVITIES/CAMPAIGN' AND TABLETYPE = 151)
	Begin
		PRINT '**** RFC5712 Insert 151 selection type for Campaign'
		INSERT INTO SELECTIONTYPES (PARENTTABLE, TABLETYPE, MINIMUMALLOWED,MAXIMUMALLOWED)
		VALUES('MARKETING ACTIVITIES/CAMPAIGN', 151, 0, NULL)
		PRINT '**** RFC5712 selection type successfully added'
		PRINT ''
	End
	ELSE
	PRINT '**** RFC5712 Selection type already exists'
	PRINT ''
	go

-- Remove this duplicate row
if ((select count(*) FROM ASSOCIATEDNAME where NAMENO = 45 AND RELATIONSHIP = 'EMP' AND RELATEDNAME = 125) > 1)
Begin
	PRINT '**** RFC7301 Remove duplicate Employee row against Brimstone'
	Delete from ASSOCIATEDNAME 
	WHERE NAMENO = 45 
	AND RELATIONSHIP = 'EMP' 
	AND RELATEDNAME = 125
	AND SEQUENCE = 1
	PRINT '**** RFC7301  Removed duplicate Employee row against Brimstone'
	PRINT ''
END
Else
Begin
	PRINT '**** RFC5712 duplicate Employee row against Brimstone does not exist'
	PRINT ''
End
go

-- turn off annoying timeout thing
if exists(select 1 from SITECONTROL WHERE CONTROLID = 'Time out internal users' AND COLBOOLEAN = 1)
Begin
	PRINT '*** Disabling timeout ***'
	UPDATE SITECONTROL SET COLBOOLEAN = 0 WHERE CONTROLID = 'Time out internal users'
	PRINT '*** Timeout disabled ***'
End
go

if exists(select 1 from SELECTIONTYPES WHERE MAXIMUMALLOWED = 0)
Begin
	print '*** setting appropriate maximum allowed for SELECTIONTYPES with 0 max allowed ***'
	update SELECTIONTYPES
	SET MAXIMUMALLOWED = NULL
	WHERE MAXIMUMALLOWED = 0
	print '*** SELECTIONTYPES with 0 max allowed updated ***'
End
go

/*********************************************************************************
	Insert some document request test data
**********************************************************************************/
IF NOT EXISTS (SELECT * FROM TABLECODES WHERE TABLECODE = 3802)
Begin
	print '**** SQA12330 inserting CEF EDE output type'
	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	VALUES(3802, 138, 'CEF')
	print '**** SQA12330 CEF output type inserted'
End
else
Begin
	print '**** SQA12330 CEF Output type already exists'
	print ''
End
go

IF NOT EXISTS (Select * from  DELIVERYMETHOD where DESCRIPTION = 'Save CEF')
Begin
	PRINT '**** SQA12330 Adding delivery method [Save CEF]'
	Declare @nDeliveryMethod int
	
	update LASTINTERNALCODE
	Set	INTERNALSEQUENCE=INTERNALSEQUENCE+1,
	@nDeliveryMethod=INTERNALSEQUENCE+1
	where  TABLENAME='DELIVERYMETHOD'
	
	insert into DELIVERYMETHOD (DELIVERYID, DELIVERYTYPE, DESCRIPTION,  DESTINATIONSP, FILEDESTINATION) 
	values (@nDeliveryMethod, 5302, 'Save CEF', null, null)
	
	PRINT '**** SQA12330 Delivery method [Save CEF] added to the DELIVERYMETHOD table'
	PRINT ''
End
Else 
	Begin
	 PRINT '**** SQA12330 Delivery method [Save CEF] already exists'
	 PRINT ''
	End
go

IF NOT EXISTS (Select * from LETTER WHERE LETTERNAME='Composite Events File' )
BEGIN
	PRINT '**** SQA12330 Inserting letter template Composite Events File (CEF).'
	declare @nLetterNo	int
	declare @nDeliveryMethod int
	
	
	update LASTINTERNALCODE
	Set	INTERNALSEQUENCE=INTERNALSEQUENCE+1,
	@nLetterNo    =INTERNALSEQUENCE+1
	where  TABLENAME = 'LETTER'
	
	Select @nDeliveryMethod = DELIVERYID from  DELIVERYMETHOD where DESCRIPTION = 'Save CEF'
	
	Insert into LETTER (LETTERNO, DELIVERYID, DOCUMENTTYPE, HOLDFLAG, DOCUMENTCODE, LETTERNAME, MACRO)
	values ( @nLetterNo, @nDeliveryMethod, 3, 0, 'CEF', 'Composite Events File', 'sqlt_EDE_CEF.xml')
	
	INSERT INTO DOCUMENTDEFINITION(LETTERNO, NAME, DESCRIPTION, CANFILTERCASES, CANFILTEREVENTS, SENDERREQUESTTYPE)
	VALUES( @nLetterNo, 'CEF', 'Composite Events File', 1, 1, 'Data Input')

	PRINT '**** SQA12330 letter template EDE CEF inserted in LETTER table.'
	PRINT ''
END
ELSE
Begin
	PRINT '**** SQA12330 letter template EDE CEF already inserted.'
	PRINT ''
End
go

If not exists (SELECT * FROM DOCUMENTDEFINITION)
Begin
	print '**** RFC7970 Adding test data to DOCUMENTDEFINITION table.'
INSERT INTO DOCUMENTDEFINITION(LETTERNO, NAME, DESCRIPTION, CANFILTERCASES, CANFILTEREVENTS, SENDERREQUESTTYPE)
SELECT TOP 1 LETTERNO,'CEF','Composite Events File',1,1,'Data Input'
FROM LETTER
	PRINT '**** RFC7970 data successfully added to DOCUMENTDEFINITION table.'
	PRINT ''
End
Else
Begin
	PRINT '**** RFC7970 DOCUMENTDEFINITION already inserted.'
	PRINT ''
End
go

If not exists (select * from DOCUMENTREQUEST)
Begin
	print '**** RFC7970 Adding test data to DOCUMENTREQUEST table.'
	INSERT INTO DOCUMENTREQUEST(RECIPIENT, DESCRIPTION, DOCUMENTDEFID, FREQUENCY, PERIODTYPE, OUTPUTFORMATID, NEXTGENERATE, STOPON, LASTGENERATED, BELONGINGTOCODE, CASEFILTERID, EVENTSTART, SUPPRESSWHENEMPTY)
	SELECT TOP 1 -493,'Asparagus CEF',DOCUMENTDEFID,1,'W',3700,getdate()+7,'2020-12-31 00:00:00',getdate()-7,'R',null,'1956-01-01 00:00:00',0
	FROM DOCUMENTDEFINITION
	PRINT '**** RFC7970 data successfully added to DOCUMENTREQUEST table.'
	PRINT ''
End
Else
Begin
	PRINT '**** RFC7970 Document Request already inserted.'
	PRINT ''
End
go

if not exists (Select * from VALIDEXPORTFORMAT)
Begin
	print '**** RFC7970 Adding test data to VALIDEXPORTFORMAT table.'
	insert into VALIDEXPORTFORMAT (DOCUMENTDEFID, FORMATID, ISDEFAULT)
	SELECT DOCUMENTDEFID, TABLECODE, 0
	FROM TABLECODES, DOCUMENTDEFINITION
	WHERE TABLETYPE = 137
	PRINT '**** RFC7970 data successfully added to VALIDEXPORTFORMAT table.'
	PRINT ''
End
Else
Begin
	PRINT '**** RFC7970 VALIDEXPORTFORMAT already inserted.'
	PRINT ''
End
go

IF NOT EXISTS (SELECT * FROM DOCUMENTDEFINITIONACTINGAS)
Begin
	print '**** RFC7970 Adding test data to DOCUMENTDEFINITIONACTINGAS table.'
	INSERT INTO DOCUMENTDEFINITIONACTINGAS(DOCUMENTDEFID, NAMETYPE)
	SELECT DOCUMENTDEFID, 'I'
	FROM DOCUMENTDEFINITION

	INSERT INTO DOCUMENTDEFINITIONACTINGAS(DOCUMENTDEFID, NAMETYPE)
	SELECT DOCUMENTDEFID, 'O'
	FROM DOCUMENTDEFINITION
	PRINT '**** RFC7970 data successfully added to DOCUMENTDEFINITIONACTINGAS table.'
	PRINT ''
End
Else
Begin
	PRINT '**** RFC7970 DOCUMENTDEFINITIONACTINGAS already inserted.'
	PRINT ''
End
go

--Insert Office Region codes
if not exists (select * from TABLECODES WHERE TABLETYPE = 139)
Begin

	print ' **** RFC7440 Inserting test data for Region TableCode.'
	DECLARE @nNextTC int
	
	select @nNextTC = INTERNALSEQUENCE + 1 FROM LASTINTERNALCODE WHERE TABLENAME = 'TABLECODES'
	
	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 139, 'North')
	
	set @nNextTC = @nNextTC + 1
	
	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 139, 'South')
	
	set @nNextTC = @nNextTC + 1
	
	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 139, 'East')
	
	set @nNextTC = @nNextTC + 1
	
	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 139, 'West')
	
	update LASTINTERNALCODE
	SET INTERNALSEQUENCE = @nNextTC
	WHERE TABLENAME = 'TABLECODES'

	print ' **** RFC7440 Data successfully added for Region TableCode.'
	print ''
End
Else
Begin
	print ' **** RFC7440 Data already exists for Region TableCode.'
	print ''
End
go

-- Insert Period types
if not exists (select * from TABLECODES WHERE TABLETYPE = 75)
Begin

	print ' **** RFC7440 Inserting test data for Periodicity TableCode.'
	DECLARE @nNextTC int
	
	select @nNextTC = INTERNALSEQUENCE + 1 FROM LASTINTERNALCODE WHERE TABLENAME = 'TABLECODES'

	set @nNextTC = @nNextTC + 1

	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 75, 'Daily')

	set @nNextTC = @nNextTC + 1

	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 75, 'Weekly')
	
	set @nNextTC = @nNextTC + 1

	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 75, 'Monthly')	
	
	set @nNextTC = @nNextTC + 1

	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 75, 'Quarterly')

	set @nNextTC = @nNextTC + 1

	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 75, 'Half Yearly')

	set @nNextTC = @nNextTC + 1

	INSERT INTO TABLECODES(TABLECODE, TABLETYPE, DESCRIPTION)
	values(@nNextTC, 75, 'Yearly')

	update LASTINTERNALCODE
	SET INTERNALSEQUENCE = @nNextTC
	WHERE TABLENAME = 'TABLECODES'

	print ' **** RFC7440 Data successfully added for Periodicity TableCode.'
	print ''
End
Else
Begin
	print ' **** RFC7440 Data already exists for Periodicity TableCode.'
	print ''
End
go

-- insert an alert which will produce a reminder for today, update its comments and forward to cork colleen.
If not exists (Select * from ALERT where ALERTMESSAGE = 'Contact Brimstone for high-level talk tomorrow')
Begin
	declare @dtAlertSeq datetime
	Set @dtAlertSeq = getdate()
	
	INSERT ALERT(EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE, 
		ALERTDATE, DUEDATE,
		OCCURREDFLAG,DAILYFREQUENCY,
		DAYSLEAD,
		SEQUENCENO, 
		SENDELECTRONICALLY)
	VALUES (-487, @dtAlertSeq, 14, 'Contact Brimstone for high-level talk tomorrow', NULL,
		getdate(), convert(char(10), dateadd(DAY, 1, getdate()),121),
		0,1,0,0,0)

	declare @nNextBatchNo int
	Select @nNextBatchNo = max(INTERNALSEQUENCE)+1
	from LASTINTERNALCODE 
	where TABLENAME = 'POLICING'

	UPDATE LASTINTERNALCODE
		SET INTERNALSEQUENCE = @nNextBatchNo
	where TABLENAME = 'POLICING'

	exec dbo.ipw_InsertPolicing
		@pnUserIdentityId	= 26,
		@pnTypeOfRequest	= 2,
		@pnPolicingBatchNo	= @nNextBatchNo,
		@pnAdHocNameNo		= -487,
		@pdtAdHocDateCreated	= @dtAlertSeq

	exec dbo.ipu_Policing
		@pnUserIdentityId	= 26,
		@pnBatchNo=@nNextBatchNo

	UPDATE EMPLOYEEREMINDER
		set	COMMENTS = 'How about Tetsuya?'
	where EMPLOYEENO = -487
	and SHORTMESSAGE = 'Contact Brimstone for high-level talk tomorrow'

	INSERT into EMPLOYEEREMINDER 
		(EMPLOYEENO, MESSAGESEQ, CASEID,  COMMENTS, DATEUPDATED, 
		DUEDATE, READFLAG, REFERENCE,  REMINDERDATE, SEQUENCENO, SHORTMESSAGE,  SOURCE) 
	Select 3, getdate(), ER.CASEID, 'Excellent Idea!', ER.DATEUPDATED, ER.DUEDATE, 0, ER.REFERENCE, ER.REMINDERDATE, 0, ER.SHORTMESSAGE, 1
	from EMPLOYEEREMINDER ER
	where ER.EMPLOYEENO = -487 and SHORTMESSAGE = 'Contact Brimstone for high-level talk tomorrow'
End
go


If not exists(select	* 
	from	TELECOMMUNICATION T
	join	NAMETELECOM NT on (T.TELECODE = NT.TELECODE)
	join	NAME N on (N.NAMENO = NT.NAMENO and N.MAINEMAIL = NT.TELECODE)
	where	N.NAMENO = -487
	and		T.TELECOMNUMBER = 'webdevtest@cpass.com')
Begin
	print ' **** Update email address of main user.'
	
	update	TELECOMMUNICATION 
	set		TELECOMNUMBER = 'webdevtest@cpass.com'
	where	TELECOMMUNICATION.TELECODE = (
		select	T.TELECODE 
		from	TELECOMMUNICATION T
		join	NAMETELECOM NT on (T.TELECODE = NT.TELECODE)
		join	NAME N on (N.NAMENO = NT.NAMENO and N.MAINEMAIL = NT.TELECODE)
		where	N.NAMENO = -487)
		
	print ' **** Email address of the main user updated.'

End
go


If exists (select * from SITECONTROL where CONTROLID = 'Database Email Profile' and COLCHARACTER is null)
Begin

	print ' **** Set up email profile to be used with policing.'

	update SITECONTROL set COLCHARACTER = 'CPASS Exchange'
	where CONTROLID = 'Database Email Profile'
	
	print ' **** Email profile now configured.'
End
go

if exists (select * 
			from USERIDENTITY UI
			where UI.ISEXTERNALUSER = 1
			and	not exists (
				select * 
				from	ASSOCIATEDNAME AN 
				left	join ACCESSACCOUNTNAMES AAN on (AAN.ACCOUNTID = UI.ACCOUNTID)
				where	AN.RELATEDNAME = UI.NAMENO and AN.RELATIONSHIP = 'EMP'
				and		AN.NAMENO = AAN.NAMENO))
begin
	insert ASSOCIATEDNAME (NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE)
	select OrgNameNo, 'EMP', UI.NAMENO, MaxSequence
	from USERIDENTITY UI
	left join (
		select AAN1.ACCOUNTID, min(AAN1.NAMENO) as OrgNameNo
		from ACCESSACCOUNTNAMES AAN1
		group by AAN1.ACCOUNTID) AAN2 on (AAN2.ACCOUNTID = UI.ACCOUNTID)
	left join (
		select NAMENO, Max(SEQUENCE) as MaxSequence
		from ASSOCIATEDNAME AN1
		where RELATIONSHIP = 'EMP'
		group by NAMENO) AN2 on (AN2.NAMENO = OrgNameNo)
	where UI.ISEXTERNALUSER = 1
	and	not exists (
				select * 
				from	ASSOCIATEDNAME AN 
				left	join ACCESSACCOUNTNAMES AAN on (AAN.ACCOUNTID = UI.ACCOUNTID)
				where	AN.RELATEDNAME = UI.NAMENO and AN.RELATIONSHIP = 'EMP'
				and		AN.NAMENO = AAN.NAMENO)
	
end
go

/**********************************************************************************************************/
/*** RFC8916 - Remove corrupt  Data from Lead "Xero Phil"							***/
/**********************************************************************************************************/
If exists (SELECT * FROM LEADDETAILS WHERE ESTREVCURRENCY IS NULL AND ESTIMATEDREV IS NOT NULL)
  BEGIN
  PRINT '**** RFC8916 Updating data LEADDETAILS.ESTREVCURRENCY = NULL'
	UPDATE LEADDETAILS 
	SET ESTREVCURRENCY='AUD'
	WHERE ESTREVCURRENCY IS NULL AND ESTIMATEDREV IS NOT NULL
  PRINT '**** RFC8916 Data successfully updated in the LEADDETAILS table.'
  PRINT ''
END
ELSE
Begin
   PRINT '**** RFC8916 LEADDETAILS.ESTREVCURRENCY = NULL does not exist'
   PRINT ''
End
go

If exists (SELECT * FROM TELECOMMUNICATION WHERE TELECOMNUMBER is NULL and TELECOMTYPE in ('1901','1902'))
  BEGIN
  PRINT '**** RFC8916 Updating data TELECOMMUNICATION.TELECOMNUMBER = NULL'
	UPDATE TELECOMMUNICATION 
	SET TELECOMNUMBER= 4122026
	WHERE TELECOMNUMBER is NULL and TELECOMTYPE in ('1901','1902')
  PRINT '**** RFC8916 Data successfully updated in the TELECOMMUNICATION table.'
  PRINT ''
END
ELSE
Begin
   PRINT '**** RFC8916 TELECOMMUNICATION.TELECOMNUMBER = NULL does not exist'
   PRINT ''
End
go

If exists (SELECT * FROM TELECOMMUNICATION WHERE TELECOMNUMBER is NULL and TELECOMTYPE in ('1903'))
  BEGIN
  PRINT '**** RFC8916 Updating data TELECOMMUNICATION.TELECOMNUMBER = NULL for TELECOMTYPE FAX'
	UPDATE TELECOMMUNICATION 
	SET TELECOMNUMBER='webdevtest@cpass.com'
	WHERE TELECOMNUMBER is NULL and TELECOMTYPE in ('1903')
  PRINT '**** RFC8916 Data successfully updated in the TELECOMMUNICATION table.'
  PRINT ''
END
ELSE
Begin
   PRINT '**** RFC8916 TELECOMMUNICATION.TELECOMNUMBER = NULL for TELECOMTYPE FAX does not exist'
   PRINT ''
End
go

/**********************************************************************************************************/
/*** RFC8203 - Insert test Format Profiles if there aren't any					        ***/
/**********************************************************************************************************/
If not exists (SELECT 1 from FORMATPROFILE)
BEGIN
        Print '**** RFC8203 Inserting test Bill Format Profiles ****'
        insert into FORMATPROFILE (FORMATDESC)
        values (N'Default Bill Format')

        insert into FORMATPROFILE (FORMATDESC)
        values (N'Standard Invoice Format')

        insert into FORMATPROFILE (FORMATDESC)
        values (N'Standard LEDES Format')
        Print '**** Bill Format Profiles inserted successfully. ****'
END        
ELSE
BEGIN
        Print '**** Bill Format Profiles already exist. ****'
END

/*********************************************************************************
	RFC100219 - Delete TOPICCONTROL with TOPICNAME starting with newTab_
**********************************************************************************/
IF EXISTS (select * from TOPICCONTROL where TOPICNAME like 'newTab_%')
Begin
	print '**** RFC100219 Delete TOPICCONTROL with TOPICNAME starting with newTab_'
	Delete from TOPICCONTROL
	where TOPICNAME like 'newTab_%'
	print '**** Delete TOPICCONTROL with TOPICNAME starting with newTab_'
End
else
Begin
	print '**** RFC100219 TOPICCONTROL with TOPICNAME starting with newTab_ does not exist'
	print ''
End
go
If not exists(select * 
					from TOPICCONTROL TC
					join WINDOWCONTROL WC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO)
					join CRITERIA C on (C.CRITERIANO = WC.CRITERIANO)
					where C.CASETYPE = 'A' 
					and C.PURPOSECODE = 'W' 
					and C.PROPERTYUNKNOWN = 1 
					and C.COUNTRYUNKNOWN = 1
					and C.CATEGORYUNKNOWN = 1
					and C.SUBTYPEUNKNOWN = 1)
Begin
	PRINT '**** RFC6547 Ensuring staff, instructor and owner are mandatory in the default screen control rule'

	Declare @nTopicControlNo int
	
	Insert TOPICCONTROL (WINDOWCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, DISPLAYDESCRIPTION, ISHIDDEN, ISINHERITED)
	Select WC.WINDOWCONTROLNO, N'Case_NamesTopic', 3, 0, 0, 0, 0
	from WINDOWCONTROL WC 
	join CRITERIA C on (C.CRITERIANO = WC.CRITERIANO)
	where C.CASETYPE = 'A' 
	and C.PURPOSECODE = 'W' 
	and C.PROPERTYUNKNOWN = 1 
	and C.COUNTRYUNKNOWN = 1
	and C.CATEGORYUNKNOWN = 1
	and C.SUBTYPEUNKNOWN = 1
	
	
	Set @nTopicControlNo = SCOPE_IDENTITY()
	
IF exists (select 1 from TOPICCONTROL where TOPICCONTROLNO = @nTopicControlNo) 
	BEGIN		
	Insert ELEMENTCONTROL (TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	values (@nTopicControlNo, N'pkInstructorName', 0, 1, 0, 0) 					
	
	Insert ELEMENTCONTROL (TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	values (@nTopicControlNo, N'pkOwnerName', 0, 1, 0, 0) 					
	
	Insert ELEMENTCONTROL (TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	values (@nTopicControlNo, N'pkStaffName', 0, 1, 0, 0) 	
	End	
End	
go
/*********************************************************************************
	RFC9038 - Delete Invalid License
**********************************************************************************/
if exists (SELECT * 
		FROM LICENSEDUSER LU 
		join USERIDENTITY UI on (LU.USERIDENTITYID = UI.IDENTITYID)
		where UI.LOGINID = 'Attorney' 
		and UI.IDENTITYID = 6)
Begin
	print '**** RFC9038 Delete LicensedUser for USERIDENTITYID = 6'
	delete from LICENSEDUSER where USERIDENTITYID = 6
	print '**** RFC9038 LicensedUser for USERIDENTITYID = 6 Deleted'
End
else
Begin
	print '**** RFC100219 LicensedUser for USERIDENTITYID = 6 not found'
	print ''
End
Go

if exists (SELECT * 
		FROM LICENSEDUSER LU 
		join USERIDENTITY UI on (LU.USERIDENTITYID = UI.IDENTITYID)
		where UI.LOGINID = 'bern' 
		and UI.IDENTITYID = 41)
Begin
	print '**** RFC9038 Delete LicensedUser for USERIDENTITYID = 41'
	delete from LICENSEDUSER where USERIDENTITYID = 41
	print '**** RFC9038 LicensedUser for USERIDENTITYID = 41 Deleted'
End
else
Begin
	print '**** RFC100219 LicensedUser for USERIDENTITYID = 41 not found'
	print ''
End
Go


/**********************************************************************************************************/
/***  RFC9212 Restore Same Name Type flag if no CRM License						***/
/**********************************************************************************************************/     
-- Turn the same name type checkbox back on for CRM Names
IF exists (SELECT * FROM NAMETYPE WHERE PICKLISTFLAGS & 32 = 32
			and PICKLISTFLAGS & 16 = 0)
Begin
	Print 'Restore same name type flag for CRM Names'
	UPDATE NAMETYPE SET PICKLISTFLAGS = PICKLISTFLAGS + 16
	WHERE PICKLISTFLAGS & 32 = 32
	and PICKLISTFLAGS & 16 = 0
	Print 'Restored same name type flag for CRM Names'
End
Else
Begin
	PRINT 'CRM Name types do not need to be updated.'
	PRINT ''
End
Go

IF EXISTS (SELECT * FROM OPENITEM WHERE LOCALVALUE = 0)
Begin
	print ' *** Deleting zero value open items *** '
	DELETE BI
	FROM BILLEDITEM BI
	JOIN OPENITEM OI ON OI.ITEMTRANSNO = BI.ITEMTRANSNO
			AND OI.ITEMENTITYNO = BI.ITEMENTITYNO
	WHERE OI.LOCALVALUE = 0

	DELETE BL 
	FROM BILLLINE BL 
	JOIN OPENITEM OI ON OI.ITEMTRANSNO = BL.ITEMTRANSNO
			AND OI.ITEMENTITYNO = BL.ITEMENTITYNO
	WHERE OI.LOCALVALUE = 0

	DELETE W 
	FROM WORKHISTORY W
	JOIN OPENITEM OI ON OI.ITEMTRANSNO = W.REFTRANSNO
			AND OI.ITEMENTITYNO = W.REFENTITYNO
	WHERE OI.LOCALVALUE = 0

	DELETE D
	FROM DEBTORHISTORY D
	JOIN OPENITEM OI ON OI.ITEMTRANSNO = D.REFTRANSNO
			AND OI.ITEMENTITYNO = D.REFENTITYNO
	WHERE OI.LOCALVALUE = 0

	DELETE T 
	FROM TAXHISTORY T
	JOIN OPENITEM OI ON OI.ITEMTRANSNO = T.REFTRANSNO
			AND OI.ITEMENTITYNO = T.REFENTITYNO
	WHERE OI.LOCALVALUE = 0

	DELETE from OPENITEM WHERE LOCALVALUE = 0

	DELETE TH
	FROM TRANSACTIONHEADER TH
	WHERE TH.TRANSTYPE IN (510,516,514)
	AND NOT EXISTS (SELECT * FROM OPENITEM WHERE ITEMTRANSNO = TH.TRANSNO
						AND ITEMENTITYNO = TH.ENTITYNO)
	AND NOT EXISTS (SELECT * FROM BILLEDITEM WHERE ITEMTRANSNO = TH.TRANSNO)
	print ' *** Deleted zero value open items *** '
End
Go

IF exists (SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 990
			and PROCEDUREITEMID = 'EventDescription' and SEQUENCENO = 6)
Begin
	UPDATE QUERYIMPLIEDITEM 
		SET PROCEDUREITEMID = 'CaseReference',
			USAGE = 'CaseReference',
			PROCEDURENAME = 'csw_ListCase'
	where	IMPLIEDDATAID = 990
	and		PROCEDUREITEMID = 'EventDescription' 
	and SEQUENCENO = 6
End
Go

IF exists (SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 990
			and PROCEDUREITEMID = 'CaseReference' and SEQUENCENO = 7)
Begin
	UPDATE QUERYIMPLIEDITEM 
		SET PROCEDUREITEMID = 'CurrentOfficialNumber',
			USAGE = 'CurrentOfficialNumber'
	where	IMPLIEDDATAID = 990
	and		PROCEDUREITEMID = 'CaseReference' 
	and SEQUENCENO = 7
End
Go

IF exists (SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 990
				and SEQUENCENO >= 8)
Begin
	DELETE QUERYIMPLIEDITEM 
	where	IMPLIEDDATAID = 990
	and		SEQUENCENO >= 8
End
Go

/**********************************************************************************************************/
/***  RFC8412 Stamp Fees                                						***/
/**********************************************************************************************************/
If not exists(SELECT 1 from WIPTEMPLATE where WIPCODE = 'STAMP')
Begin
        insert into WIPTEMPLATE(WIPCODE, DESCRIPTION, TAXCODE, USEDBY)
        values('STAMP','Stamp Duty Fee', '0', 7)
End

update TAXRATES
set WIPCODE = 'STAMP', MAXFREEAMOUNT = 1000.00, FEEPERCENTAGE = 10, HIDEFEEINDRAFT = 1
where TAXCODE = 'T1'
Go

-- Fix incomplete data originally added in 8412
IF EXISTS(SELECT * FROM WIPTEMPLATE WHERE WIPCODE = 'STAMP' AND WIPTYPEID IS NULL)
BEGIN
	UPDATE WIPTEMPLATE SET WIPTYPEID = 'OFEELC',
	CONSOLIDATE =0,
	ENTERCREDITWIP = 0
	WHERE WIPCODE = 'STAMP'
END
go

Declare @nInternalPortalKey int
Declare @nCurrentModule int
Select @nInternalPortalKey = PORTALID from PORTAL where NAME = 'Internal Test'
-- Add Configuration Web Part tab to internal test portal
If not exists(Select * from PORTAL P 
                left join PORTALTAB PT  on (PT.PORTALID=P.PORTALID)
                where P.NAME = 'Internal Test'
                and PT.TABNAME = 'Configuration')
Begin
    Set @nCurrentModule = -60
    
    exec dbo.ua_AddModuleToConfiguration					
		    @pnUserIdentityId	= 5,
		    @psCulture		= null,	
		    @pnIdentityKey		= null,
		    @pnPortalKey		= @nInternalPortalKey,
		    @pnModuleKey		= @nCurrentModule	
End
go 


Declare @nExternalPortalKey int
Declare @nCurrentModule int
Select @nExternalPortalKey = PORTALID from PORTAL where NAME = 'External Test'
-- Add Configuration Web Part tab to external test portal
If not exists(Select * from PORTAL P 
                left join PORTALTAB PT  on (PT.PORTALID=P.PORTALID)
                where P.NAME = 'External Test'
                and PT.TABNAME = 'Configuration')
Begin
    Set @nCurrentModule = -60
    
    exec dbo.ua_AddModuleToConfiguration					
		    @pnUserIdentityId	= 5,
		    @psCulture		= null,	
		    @pnIdentityKey		= null,
		    @pnPortalKey		= @nExternalPortalKey,
		    @pnModuleKey		= @nCurrentModule	
End
go 
/**********************************************************************************************************/
/***  RFC100620 WIP Overview Reports web part return an error					***/
/**********************************************************************************************************/    
IF exists (SELECT MC2.CONFIGURATIONID from MODULECONFIGURATION MC2 JOIN PORTALTAB PT2 on(PT2.TABID= MC2.TABID) where
  MC2.PORTALID is null and exists (SELECT * FROM MODULECONFIGURATION MC1
WHERE MC1.MODULEID = MC2.MODULEID and MC1.PORTALID = PT2.PORTALID))
Begin
	PRINT '**** RFC100620 Remove invalid module from MODULECONFIGURATION table'
	Delete MODULECONFIGURATION Where CONFIGURATIONID in(
	SELECT MC.CONFIGURATIONID from MODULECONFIGURATION MC JOIN PORTALTAB PT on(PT.TABID= MC.TABID) where
	MC.PORTALID is null and exists (SELECT * FROM MODULECONFIGURATION MC1
	WHERE MC1.MODULEID = MC.MODULEID and MC1.PORTALID = PT.PORTALID))
	
	PRINT '**** RFC100620  Removed invalid module from MODULECONFIGURATION table'
	PRINT ''
END
Else
Begin
	PRINT '**** RFC100620 There is no invalid module exists in MODULECONFIGURATION table'
	PRINT ''
End
go

/**********************************************************************************************************/
/*** Insert Default bill formats									***/
/**********************************************************************************************************/
Declare @nHomeNameNo int
Select @nHomeNameNo = COLINTEGER FROM SITECONTROL WHERE CONTROLID = 'HOMENAMENO'

if not exists (select * from BILLFORMAT WHERE FORMATNAME = 'Default Format' and ENTITYNO = @nHomeNameNo and BILLFORMATREPORT = 'billing.rdl')
Begin
	insert into BILLFORMAT(BILLFORMATID, FORMATNAME, NAMENO, ENTITYNO, BILLFORMATDESC, BILLFORMATREPORT,
	SORTDATE, SORTCASE, SORTWIPCATEGORY, CONSOLIDATESC, CONSOLIDATEPD, CONSOLIDATEOR, DETAILSREQUIRED, CONSOLIDATEDISC, 
	CONSOLIDATECHTYP, SORTCASETITLE, SORTCASEDEBTORREF, FORMATPROFILEID, DEBITNOTE)
	SELECT LC.INTERNALSEQUENCE + 1, 'Default Format', null, @nHomeNameNo, 'Default Format', 'billing.rdl', 
	3, 2, 1, 0, 0, 0, 31, 0, 
	0, 4, 5, null, null
	FROM LASTINTERNALCODE LC WHERE LC.TABLENAME = 'BILLFORMAT'
	
	UPDATE LASTINTERNALCODE SET INTERNALSEQUENCE = INTERNALSEQUENCE + 1 WHERE TABLENAME = 'BILLFORMAT'
End

-- Insert e-bill fields
If not exists (select * from TABLECODES WHERE TABLETYPE = -500)
Begin
	Declare @nInternalCode int

	Select @nInternalCode = INTERNALSEQUENCE
	FROM LASTINTERNALCODE
	WHERE TABLENAME = 'TABLECODES'

	INSERT INTO TABLECODES (TABLECODE, TABLETYPE, DESCRIPTION)
	SELECT @nInternalCode + 1, -500, 'FIELD0'

	INSERT INTO TABLECODES (TABLECODE, TABLETYPE, DESCRIPTION)
	SELECT @nInternalCode + 2, -500, 'FIELD1'

	INSERT INTO TABLECODES (TABLECODE, TABLETYPE, DESCRIPTION)
	SELECT @nInternalCode + 3, -500, 'FIELD2'
	
	UPDATE LASTINTERNALCODE SET INTERNALSEQUENCE = @nInternalCode + 3 WHERE TABLENAME = 'TABLECODES'
END

-- Insert e-bill format
If not exists (select * from QUERYPRESENTATION WHERE CONTEXTID = 460 AND ISDEFAULT = 0)
Begin
	Declare @nPresentationId int
	Declare @nFormatId int
	Declare @nLetterNo int
	Declare @nBillMapProfileId int

	INSERT INTO QUERYPRESENTATION(CONTEXTID, ISDEFAULT)
	VALUES(460, 0)

	Select @nPresentationId = SCOPE_IDENTITY()

	-- SELECT * FROM QUERYCONTENT WHERE PRESENTATIONID = 34
	INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, CONTEXTID)
	SELECT @nPresentationId, COLUMNID, 460
	FROM QUERYCOLUMN
	WHERE DATAITEMID = 1091

	INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, CONTEXTID)
	SELECT @nPresentationId, COLUMNID, 460
	FROM QUERYCONTENT WHERE PRESENTATIONID = 34

	INSERT INTO FORMATPROFILE (PRESENTATIONID, CONSOLIDATIONFLAG, FORMATDESC)
	VALUES(@nPresentationId, 0, 'EBill Format')

	Select @nFormatId = SCOPE_IDENTITY()

	select @nLetterNo = LETTERNO from LETTER where UPPER(LETTERNAME) LIKE 'ELECTRONIC%' and DELIVERYID = 4

	If (@nLetterNo is null)
	Begin
		UPDATE LASTINTERNALCODE 
		SET @nLetterNo = INTERNALSEQUENCE + 1,
		INTERNALSEQUENCE = INTERNALSEQUENCE + 1 
		WHERE TABLENAME = 'LETTER'

		Print '**** RFCxxxx Adding data into LETTER'
		INSERT INTO LETTER(LETTERNO, LETTERNAME, DOCUMENTCODE, CORRESPONDTYPE, COPIESALLOWEDFLAG, COVERINGLETTER, EXTRACOPIES, MULTICASEFLAG, MACRO, SINGLECASELETTERNO, INSTRUCTIONTYPE, ENVELOPE, COUNTRYCODE, DELIVERYID, PROPERTYTYPE, HOLDFLAG, NOTES, DOCUMENTTYPE, USEDBY, FORPRIMECASESONLY, GENERATEASANSI, ADDATTACHMENTFLAG, ACTIVITYTYPE, ACTIVITYCATEGORY, ENTRYPOINTTYPE, SOURCEFILE, EXTERNALUSAGE)
		VALUES(@nLetterNo,'Electronic Bill','EBILL',null,0,null,null,0,'N:\Apps\Inpro50\SQLT_DebitNoteLEDES_Micron.xml',null,null,null,null,4,null,0,null,3,1,0,0,0,null,null,null,null,0)
		Print '**** RFCxxxx Data successfully added to LETTER table.'
		Print ''
	End

	if not exists (select * from BILLFORMAT WHERE FORMATNAME = 'EBill Format' and ENTITYNO = @nHomeNameNo and BILLFORMATREPORT = 'billing.rdl')
	Begin
		insert into BILLFORMAT(BILLFORMATID, FORMATNAME, NAMENO, ENTITYNO, BILLFORMATDESC, BILLFORMATREPORT,
		SORTDATE, SORTCASE, SORTWIPCATEGORY, CONSOLIDATESC, CONSOLIDATEPD, CONSOLIDATEOR, DETAILSREQUIRED, CONSOLIDATEDISC, 
		CONSOLIDATECHTYP, SORTCASETITLE, SORTCASEDEBTORREF, FORMATPROFILEID, DEBITNOTE)
		SELECT LC.INTERNALSEQUENCE + 1, 'EBill Format', null, null, 'EBill Format', 'billing.rdl',
		3, 2, 1, 11, 13, 13, 30, 0, 
		0, 4, 5, @nFormatId, @nLetterNo
		FROM LASTINTERNALCODE LC WHERE LC.TABLENAME = 'BILLFORMAT'
		
		UPDATE LASTINTERNALCODE SET INTERNALSEQUENCE = INTERNALSEQUENCE + 1 WHERE TABLENAME = 'BILLFORMAT'
	End

	if not exists (SELECT * FROM BILLMAPPROFILE WHERE BILLMAPDESC = 'BILLMAP')
	Begin
		INSERT INTO BILLMAPPROFILE (BILLMAPDESC)
		VALUES ('BILLMAP')

		Select @nBillMapProfileId = SCOPE_IDENTITY()

		declare @nCode int

		Select @nCode = TABLECODE FROM TABLECODES WHERE DESCRIPTION = 'FIELD0' AND TABLETYPE = -500
		INSERT INTO BILLMAPRULES (BILLMAPPROFILEID, FIELDCODE, WIPCODE, MAPPEDVALUE)
		VALUES (@nBillMapProfileId, @nCode, 'HEAR', 'HEARCODE1')

		Select @nCode = TABLECODE FROM TABLECODES WHERE DESCRIPTION = 'FIELD1' AND TABLETYPE = -500
		INSERT INTO BILLMAPRULES (BILLMAPPROFILEID, FIELDCODE, WIPCODE, MAPPEDVALUE)
		VALUES (@nBillMapProfileId, @nCode, 'HEAR', 'HEARCODE2')
		INSERT INTO BILLMAPRULES (BILLMAPPROFILEID, FIELDCODE, WIPCODE, MAPPEDVALUE)
		VALUES (@nBillMapProfileId, @nCode, 'SEARCH', 'SEACHCODE')

		Select @nCode = TABLECODE FROM TABLECODES WHERE DESCRIPTION = 'FIELD2' AND TABLETYPE = -500
		INSERT INTO BILLMAPRULES (BILLMAPPROFILEID, FIELDCODE, WIPCODE, MAPPEDVALUE)
		VALUES (@nBillMapProfileId, @nCode, NULL, 'FIELD2VALUE')

		update IPNAME 
		SET BILLMAPPROFILEID = @nBillMapProfileId
		WHERE BILLMAPPROFILEID IS NULL
	End
End
go



        /**********************************************************************************************************/
    	/*** RFC100503 RESOURCE table for Devices                                  			        ***/
	/**********************************************************************************************************/     
        If not exists (Select * from RESOURCE where RESOURCENO=1)
        Begin
                PRINT '**** RFC100503 Adding data RESOURCE.RESOURCENO = 1'
                Insert into RESOURCE(RESOURCENO, TYPE, DESCRIPTION)
                VALUES(1,1,'RFID Scanner 01')                
                PRINT '**** RFC100503 Data successfully added to RESOURCE table.'
		PRINT ''
        End
        ELSE        
         	 PRINT '**** RFC100503 RESOURCE.RESOURCENO = 1 already exists'
		 PRINT ''
        go
        

        If not exists (Select * from RESOURCE where RESOURCENO=2)
        Begin
                PRINT '**** RFC100503 Adding data RESOURCE.RESOURCENO = 2'
                Insert into RESOURCE(RESOURCENO, TYPE, DESCRIPTION)
                VALUES(2,1,'RFID Scanner 02')                
                PRINT '**** RFC100503 Data successfully added to RESOURCE table.'
		PRINT ''
        End
        ELSE
        
         	 PRINT '**** RFC100503 RESOURCE.RESOURCENO = 2 already exists'
		 PRINT ''
        go
        
        /**********************************************************************************************************/
    	/*** RFC12673 Edit Renewal tab in Case Details							        ***/
	/**********************************************************************************************************/   
        If exists (SELECT * FROM SITECONTROL WHERE CONTROLID = N'CPA Date-Start' AND (COLINTEGER <> -11858 or COLINTEGER is null))
        BEGIN
	         PRINT '**** RFC12673 Updating data in the SITECONTROL table for CPA Date-Start.'
                 UPDATE SITECONTROL
                 SET COLINTEGER = -11858
                 WHERE CONTROLID = N'CPA Date-Start'
                 PRINT '**** RFC12673 SITECONTROL table for CPA Date-Start has been updated successfully.'
                 PRINT ''
	END
        ELSE
	        PRINT '**** RFC12673 SITECONTROL table for CPA Date-Start has already been updated.'
	        PRINT ''
        go
        If exists (SELECT * FROM SITECONTROL WHERE CONTROLID = N'CPA Date-Stop' AND (COLINTEGER <> -11859 or COLINTEGER is null))
        BEGIN
	         PRINT '**** RFC12673 Updating data in the SITECONTROL table for CPA Date-Stop.'
                 UPDATE SITECONTROL
                 SET COLINTEGER = -11859
                 WHERE CONTROLID = N'CPA Date-Stop'
                 PRINT '**** RFC12673 SITECONTROL table for CPA Date-Stop has been updated successfully.'
                 PRINT ''
	END
        ELSE
	        PRINT '**** RFC12673 SITECONTROL table for CPA Date-Stop has already been updated.'
	        PRINT ''
        go

/*** RFC29307 Update Statement text doc item for wip split multi debtor ***/      
If exists (SELECT * FROM ITEM WHERE ITEM_ID = 332 AND ITEM_NAME = 'STATEMENT' AND DATE_UPDATED < '20131219')
BEGIN
	PRINT '**** RFC29307 Update Statement Doc Item to cater for split debtor bills.'
	update ITEM SET SQL_QUERY = 'select ''Our Ref: '' + C.IRN + 
CASE WHEN CN.REFERENCENO IS NOT NULL 
THEN ''  Your Ref: '' + CN.REFERENCENO END
FROM CASES C  
JOIN CASENAME CN ON (C.CASEID = CN.CASEID)
LEFT JOIN SITECONTROL WSMDSC ON (WSMDSC.CONTROLID = ''WIP Split Multi Debtor'')
WHERE IRN = :gstrEntryPoint
AND CN.NAMETYPE = isnull(CAST(nullif(:p2,'''') AS NVARCHAR(2)),''D'')
AND CN.NAMENO = case when WSMDSC.COLBOOLEAN = 1
				THEN isnull(CAST(nullif(:p3,'''') AS INT), CN.NAMENO)
				ELSE CN.NAMENO
				END',
	DATE_UPDATED = '20131219'
	WHERE ITEM_ID = 332
	and ITEM_NAME = 'STATEMENT'
	PRINT '**** RFC29307 STATEMENT doc item updated successfully.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC29307 STATEMENT doc item already up to date.'
	PRINT ''
END
go


/*** RFC37920 Add EDE alias to Maxim Yarrow & Coleman for e2e tests in apps ***/
If NOT exists (select * from NAMEALIAS WHERE NAMENO = -283575757 AND ALIASTYPE = '_E')
BEGIN
	PRINT '**** RFC37920 Add EDE alias to Maxim Yarrow & Coleman for e2e tests in apps.'
	INSERT INTO NAMEALIAS (NAMENO, ALIAS, ALIASTYPE)
	VALUES (-283575757, 'MYAC', '_E')
	PRINT '**** RFC37920 NAMEALIAS for MYAC updated successfully.'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC29307 NAMEALIAS for MYAC already inserted.'
	PRINT ''
END
go        

/******************************************************************************************/
/***	ADD ACCOUNTING PERIODS 24 months out from today.				***/
/******************************************************************************************/

/********* Make sure there is at least one period ***************/
if not exists (select * from PERIOD)
Begin
	insert into PERIOD (PERIODID, LABEL, STARTDATE, ENDDATE, POSTINGCOMMENCED)
	values ('199901', 'July 1998', '1998-07-01', '1998-07-31', getdate())
End
go

/********* Calculate the number of periods to add ***************/

declare @nNumberOfPeriodsFromToday int
Set @nNumberOfPeriodsFromToday = 24

declare @dtLastEndDate datetime
Select @dtLastEndDate = MAX(ENDDATE) from PERIOD

declare @dToday datetime
Set @dToday = GETDATE()

declare @nPeriodsToAdd int
Set @nPeriodsToAdd = datediff(MONTH, @dtLastEndDate, @dToday) + @nNumberOfPeriodsFromToday

if (@nPeriodsToAdd > 0)
Begin
	print 'Adding ' + cast(@nPeriodsToAdd as nvarchar) + ' periods.' + char(10)
	
	Declare @nMaxPeriod int
	Declare @nMaxMonth int
	Declare @nMaxYear int

	Declare @nStartFinancialYear int
	Declare @dtStartDate datetime
	Declare @nIndex int
	Declare @nMonthIndex int
	Declare @dtPeriodStart datetime
	Declare @dtPeriodFinish datetime

	Declare @sPeriodId nvarchar(14)
	Declare @nStartPeriod int

	Select @nMaxPeriod = max(PERIODID) from PERIOD
	Set @nMaxMonth = cast(right(@nMaxPeriod,2) as int)
	Set @nMaxYear = cast(left(@nMaxPeriod,4) as int)

	If @nMaxMonth = 12
	Begin
		Set @nStartPeriod = 1
		Set @nStartFinancialYear = @nMaxYear+1
	End
	Else
	Begin
		Set @nStartPeriod = @nMaxMonth+1
		Set @nStartFinancialYear = @nMaxYear
	End
		
	select @dtStartDate = MAX(ENDDATE)+1 FROM PERIOD

	Set @nIndex = 0
	Set @nMonthIndex = @nStartPeriod

	while (@nIndex < @nPeriodsToAdd)
	Begin
		Set @sPeriodId = cast(@nStartFinancialYear as nvarchar(4)) + RIGHT('0' + RTRIM(@nMonthIndex), 2)
		if not exists (select * from PERIOD WHERE PERIODID = @sPeriodId)
		Begin
			Set @dtPeriodStart = dateadd(month, @nIndex, @dtStartDate)
			Set @dtPeriodFinish = DATEADD(day, -1, dateadd(MONTH,1,@dtPeriodStart))
			Print '*** Inserting period, ' + @sPeriodId + '...'
			INSERT INTO PERIOD (PERIODID, LABEL, STARTDATE, ENDDATE, POSTINGCOMMENCED, YEARENDROLLOVERFL, LEDGERPERIODOPENFL, CLOSEDFOR)
			VALUES (
				@sPeriodId, 
				DATENAME(MONTH,@dtPeriodStart) + ' ' + cast(YEAR(@dtPeriodStart) as nvarchar(4)),
				@dtPeriodStart, 
				@dtPeriodFinish, NULL, 0, 1, NULL
			)
		Print char(10)+'*** Period successfully inserted.'+char(10)
		End
		Else
		Begin
			Print '*** Period ' + @sPeriodId + ' already exists.'
		End
		Set @nIndex = @nIndex + 1
		If @nMonthIndex < 12
		Begin
			Set @nMonthIndex = @nMonthIndex + 1
		End
		Else
		Begin
			Set @nMonthIndex = 1
			Set @nStartFinancialYear = @nStartFinancialYear + 1
		End
	End
End
else
Begin
	print 'PERIODs already at least ' + cast(@nNumberOfPeriodsFromToday as nvarchar) + ' months ahead of today.'
End
go

-- Remove Keep On Top Notes
update NAMETYPE
set KOTTEXTTYPE = NULL
where KOTTEXTTYPE IS NOT NULL
go

-- Turn off Stamp Fees
UPDATE TAXRATES SET WIPCODE = NULL, WIPCATEGORY = NULL, NARRATIVENO = NULL, CURRENCYCODE = NULL, MAXFREEAMOUNT = NULL, FEEAMOUNT=NULL, FEEPERCENTAGE=NULL, HIDEFEEINDRAFT=NULL
go

-- Turn off Case Budget WIP Warnings
DELETE from CASEBUDGET
UPDATE CASES SET BUDGETAMOUNT = NULL WHERE BUDGETAMOUNT IS NOT NULL
go