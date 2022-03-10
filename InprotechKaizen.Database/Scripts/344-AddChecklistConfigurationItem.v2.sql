if not exists (select 1 from CONFIGURATIONITEMGROUP where ID = 5)
begin
	PRINT '*** DR-74416 Begin Inserting Rules - Checklists Configuration Item Group ***'

		insert CONFIGURATIONITEMGROUP (ID, TITLE, [DESCRIPTION], URL)
		values (5, 'Rules - Checklist Configuration (Apps)', 'Maintain checklist rules and questions', '/apps/#/configuration/rules/checklist-configuration')	
	
	PRINT '*** DR-74416 End Inserting Rules - Checklists Configuration Item Group ***'
end
go

PRINT '*** DR-74416 Begin inserting configuration items for Checklists under configuration item group ***'
	insert CONFIGURATIONITEM (TASKID, TITLE, [DESCRIPTION], GENERICPARAM, GROUPID, URL)
	select T.TASKID, CIG.TITLE, CIG.[DESCRIPTION], 'ChecklistApps', CIG.ID, CIG.URL 
	from CONFIGURATIONITEMGROUP CIG 
	JOIN TASK T on T.TASKID in (130,131)
	left join CONFIGURATIONITEM CI on CI.GROUPID = CIG.ID and CI.TASKID = T.TASKID
	where CIG.ID = 5
	and CI.CONFIGITEMID is null
	go
PRINT '*** DR-74416 End inserting configuration items for the Checklists under configuration item group ***'

PRINT '*** DR-74416 Begin inserting components for Checklists under configuration item ***'
insert CONFIGURATIONITEMCOMPONENTS(CONFIGITEMID, COMPONENTID)
select CI.CONFIGITEMID, C.COMPONENTID
from CONFIGURATIONITEM CI
left join COMPONENTS C on C.COMPONENTNAME in ('Checklist', 'Case')
left join CONFIGURATIONITEMCOMPONENTS CIC on CIC.CONFIGITEMID = CI.CONFIGITEMID and CIC.COMPONENTID = C.COMPONENTID
where CI.GROUPID = 5
and CIC.COMPONENTID is null
go
PRINT '*** DR-74416 End inserting components for Checklists under configuration item ***'