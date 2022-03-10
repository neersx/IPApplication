
if not exists (select * from APPSLINK where NAME = 'AccessPolicingDashboard')
begin
	insert APPSLINK (NAME, TITLE, DESCRIPTION, URL, ISINTERNAL, TASKID, CHECKEXECUTE)
	values ('AccessPolicingDashboard', 'Policing Dashboard', 'Click here to access the Policing Dashboard', '/#/policing-dashboard', 1, 256, 1)
end


if not exists (select * 
				from ACCESSPOINT AP 
				join APPSLINK AL on (AL.NAME = 'AccessPolicingDashboard' and AP.APPSLINKID = AL.ID)
				where AP.NAME = 'PortalSideBar')
begin
	insert ACCESSPOINT (NAME, APPSLINKID)
	select 'PortalSideBar', AL.ID
	from APPSLINK AL
	where AL.NAME = 'AccessPolicingDashboard'
end