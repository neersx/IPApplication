
if not exists (select * from APPSLINK where NAME = 'AccessNewPortal')
begin
	insert APPSLINK (NAME, TITLE, DESCRIPTION, URL, ISINTERNAL, ISEXTERNAL, TASKID, CHECKEXECUTE)
	values ('AccessNewPortal', 'Try New Portal', 'Click here to access the New Portal', '/#/home', 1, 1, null, 0)
end


if not exists (select * 
				from ACCESSPOINT AP 
				join APPSLINK AL on (AL.NAME = 'AccessNewPortal' and AP.APPSLINKID = AL.ID)
				where AP.NAME = 'PortalSideBar')
begin
	insert ACCESSPOINT (NAME, APPSLINKID)
	select 'PortalSideBar', AL.ID
	from APPSLINK AL
	where AL.NAME = 'AccessNewPortal'
end