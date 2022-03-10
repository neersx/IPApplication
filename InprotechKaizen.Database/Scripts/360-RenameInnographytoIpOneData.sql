if exists(select 1 from TASK where TASKID = 266 and TASKNAME = N'Schedule Innography Data Download')
begin
	update TASK set TASKNAME = 'Schedule IP One Data Download', DESCRIPTION = 'Schedule tasks to download data from IP One Data (Innography) for use with case data comparison'
	where TASKID = 266 and TASKNAME = N'Schedule Innography Data Download'
end

GO

if exists(select 1 from CONFIGURATIONITEM where TASKID = 239 and TITLE = N'Data Mapping for Innography')
begin
	update CONFIGURATIONITEM set TITLE = 'Data Mapping for IP One Data', DESCRIPTION = 'Maintain data mapping for IP One Data.', URL = '/apps/#/configuration/general/ede/datamapping/IpOneData'
	where TASKID = 239 and TITLE = N'Data Mapping for Innography'
end

GO

if exists(select 1 from EXTERNALSYSTEM where SYSTEMID = -5 and SYSTEMNAME = N'Innography')
begin
	update EXTERNALSYSTEM set SYSTEMNAME = 'IPONE', SYSTEMCODE = 'IPOneData'
	where SYSTEMID = -5 and SYSTEMNAME = N'Innography'
end

if exists(select 1 from DATASOURCE where DATASOURCEID = -5 and SYSTEMID = -5 and DATASOURCECODE = N'Innography')
begin
	update DATASOURCE set DATASOURCECODE = 'IPOneData'
	where DATASOURCEID = -5 and SYSTEMID = -5
end

GO

if exists(select 1 from DATAEXTRACTMODULE where SYSTEMID = -5 and EXTRACTNAME = N'Innography')
begin
	update DATAEXTRACTMODULE set EXTRACTNAME = 'IPOneData'
	where SYSTEMID = -5 and EXTRACTNAME = N'Innography'
end

GO

if exists(select 1 from QUERY where QUERYNAME = N'Innography Ongoing Verification - Sample')
begin
	update query set QUERYNAME = 'IP One Data Ongoing Verification - Sample'
	where QUERYNAME = N'Innography Ongoing Verification - Sample'
end

GO

if exists(select 1 from QUERY where QUERYNAME = N'Innography Initial Matching - Sample')
begin
	update query set QUERYNAME = 'IP One Data Initial Matching - Sample'
	where QUERYNAME = N'Innography Initial Matching - Sample'
end

GO

if exists (select 1 from TABLETYPE where TABLETYPE = -516 and TABLENAME = N'Innography Type')
begin
	update TABLETYPE set TABLENAME = 'IP One Data Type'
	where TABLETYPE = -516 and TABLENAME = N'Innography Type'
end

GO