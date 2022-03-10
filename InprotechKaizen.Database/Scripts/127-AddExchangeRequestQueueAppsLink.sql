
if not exists (select * from APPSLINK where NAME = 'AdministerExchangeIntegration')
begin
	insert APPSLINK (NAME, TITLE, DESCRIPTION, URL, ISINTERNAL, TASKID, CHECKEXECUTE)
	values ('AdministerExchangeIntegration', 'Exchange Integration', 'Click here to administer Exchange Integration requests', '/#/exchange-requests', 1, 264, 1)
end


if not exists (select * 
				from ACCESSPOINT AP 
				join APPSLINK AL on (AL.NAME = 'AdministerExchangeIntegration' and AP.APPSLINKID = AL.ID)
				where AP.NAME = 'PortalSideBar')
begin
	insert ACCESSPOINT (NAME, APPSLINKID)
	select 'PortalSideBar', AL.ID
	from APPSLINK AL
	where AL.NAME = 'AdministerExchangeIntegration'
end