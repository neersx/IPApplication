-----------------------------------------------------------------------------------------------------------------------------
--  This script depends on fn_IsAvailableInLicense which is now available as part of standard upgrade                      --
-----------------------------------------------------------------------------------------------------------------------------

declare @sSQLString nvarchar(4000)
-----------------------------------------------------------------------------------------------------------------------------
--  List Web Parts Feature chart --
-----------------------------------------------------------------------------------------------------------------------------

set @sSQLString = 'Select coalesce(MD.[NAME], M.TITLE) as [Web Part], M.DESCRIPTION, '
select @sSQLString = @sSQLString + 'dbo.fn_IsAvailableInLicense(M.MODULEID, 10,' + cast(L.MODULEID as nvarchar(2)) + ') as [' + L.MODULENAME + '], '
from LICENSEMODULE L
where L.MODULEFLAG = 4 
set @sSQLString = SUBSTRING(@sSQLString, 0, LEN(@sSQLString)) + char(13) + char(10) + 'from MODULE M 
left join MODULEDEFINITION MD on (M.MODULEDEFID = MD.MODULEDEFID)
order by 1'

exec sp_executesql @sSQLString


-----------------------------------------------------------------------------------------------------------------------------
--  List Tasks Feature chart --
-----------------------------------------------------------------------------------------------------------------------------

set @sSQLString = 'Select T.TASKNAME, T.DESCRIPTION, '
select @sSQLString = @sSQLString + 'dbo.fn_IsAvailableInLicense(T.TASKID, 20,' + cast(L.MODULEID as nvarchar(2)) + ') as [' + L.MODULENAME + '], '
from LICENSEMODULE L
where L.MODULEFLAG = 4 
set @sSQLString = SUBSTRING(@sSQLString, 0, LEN(@sSQLString)) + char(13) + char(10) + 'from TASK T
order by 1'

exec sp_executesql @sSQLString

-----------------------------------------------------------------------------------------------------------------------------
--  List Data Topic Feature chart --
-----------------------------------------------------------------------------------------------------------------------------

set @sSQLString = 'Select DT.TOPICNAME, DT.DESCRIPTION, '
select @sSQLString = @sSQLString + 'dbo.fn_IsAvailableInLicense(DT.TOPICID, 30,' + cast(L.MODULEID as nvarchar(2)) + ') as [' + L.MODULENAME + '], '
from LICENSEMODULE L
where L.MODULEFLAG = 4 
set @sSQLString = SUBSTRING(@sSQLString, 0, LEN(@sSQLString)) + char(13) + char(10) + 'from DATATOPIC DT
order by 1'

exec sp_executesql @sSQLString


-----------------------------------------------------------------------------------------------------------------------------
--  List Data Topic Implied Feature chart --
-----------------------------------------------------------------------------------------------------------------------------

set @sSQLString = 'Select DT.TOPICNAME, DT.DESCRIPTION, '
select @sSQLString = @sSQLString + 'dbo.fn_IsAvailableInLicense(DT.TOPICID, 35,' + cast(L.MODULEID as nvarchar(2)) + ') as [' + L.MODULENAME + '], '
from LICENSEMODULE L
--where L.MODULEFLAG = 4 
set @sSQLString = SUBSTRING(@sSQLString, 0, LEN(@sSQLString)) + char(13) + char(10) + 'from DATATOPIC DT
order by 1'

exec sp_executesql @sSQLString

