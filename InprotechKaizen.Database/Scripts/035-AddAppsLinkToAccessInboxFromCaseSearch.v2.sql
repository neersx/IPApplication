if not exists (select * from APPSLINK where ISMULTIARG = 1 and TASKID = 55 and NAME = 'Data Comparison')
begin
	insert APPSLINK (NAME, URL, ISINTERNAL, TASKID, CHECKEXECUTE, ISMULTIARG, TITLE, DESCRIPTION)
	values ('Data Comparison', '/#/casecomparison/inbox?caselist={caseIds}',
			1, 55, 1, 1, 
			'Case Data Comparison', 
			'Compare case data with data downloaded from other sources such as IP Offices.')
end
else
begin
	update APPSLINK set URL = '/#/casecomparison/inbox?caselist={caseIds}'
	where ISMULTIARG = 1 and TASKID = 55 and NAME = 'Data Comparison'
end

if not exists(select * from ACCESSPOINT where NAME = 'CaseSearch')
begin
	insert ACCESSPOINT(NAME, APPSLINKID)
	select 'CaseSearch', A.ID
	from APPSLINK A
	where A.NAME = 'Data Comparison' 
	and ISMULTIARG = 1
end