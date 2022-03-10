/* **** DR-52550 Ability to enter cases screen designer ****/
if not exists (select 1 from CONFIGURATIONITEMGROUP where ID = 4)
begin
	PRINT '*** DR-52550 Begin Inserting Screen Designer - Cases Configuration Item Group ***'

		insert CONFIGURATIONITEMGROUP (ID, TITLE, [DESCRIPTION], URL)
		values (4, 'Screen Designer - Cases', 'Maintain rules governing how case pages are displayed in the New Portal.', '/apps/#/configuration/rules/screen-designer/cases')
	
	PRINT '*** DR-52550 End Inserting Screen Designer - Cases Configuration Item Group ***'
end
else if exists(select 1 from CONFIGURATIONITEMGROUP where ID=4 and DESCRIPTION='Maintain protected and firm-specific Case window rules via Screen Designer.')
begin
	update CONFIGURATIONITEMGROUP set DESCRIPTION='Maintain rules governing how case pages are displayed in the New Portal.' where ID=4
end
go

PRINT '*** DR-52550 Begin inserting configuration items for the case windows under configuration item group ***'
	insert CONFIGURATIONITEM (TASKID, TITLE, [DESCRIPTION], GENERICPARAM, GROUPID, URL)
	select T.TASKID, CIG.TITLE, CIG.[DESCRIPTION], 'CaseWindows', CIG.ID, CIG.URL 
	from CONFIGURATIONITEMGROUP CIG 
	JOIN TASK T on T.TASKID in (130, 131)
	left join CONFIGURATIONITEM CI on CI.GROUPID = CIG.ID and CI.TASKID = T.TASKID
	where CIG.ID = 4
	and CI.CONFIGITEMID is null
	go
PRINT '*** DR-52550 End inserting configuration items for the case windows under configuration item group ***'

PRINT '*** DR-52550 Begin inserting components for screen designer under configuration item ***'
insert CONFIGURATIONITEMCOMPONENTS(CONFIGITEMID, COMPONENTID)
select CI.CONFIGITEMID, C.COMPONENTID
from CONFIGURATIONITEM CI
left join COMPONENTS C on C.COMPONENTNAME in ('Case', 'Screen Designer')
left join CONFIGURATIONITEMCOMPONENTS CIC on CIC.CONFIGITEMID = CI.CONFIGITEMID and CIC.COMPONENTID = C.COMPONENTID
where CI.GROUPID = 4
and CIC.COMPONENTID is null
go
PRINT '*** DR-52550 End inserting components for screen designer under configuration item ***'

