-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPORTALSETTING
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPORTALSETTING]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPORTALSETTING.'
	drop function dbo.fn_ccnPORTALSETTING
	print '**** Creating function dbo.fn_ccnPORTALSETTING...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALSETTING]') and xtype='U')
begin
	select * 
	into CCImport_PORTALSETTING 
	from PORTALSETTING
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPORTALSETTING
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPORTALSETTING
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PORTALSETTING table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'PORTALSETTING' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PORTALSETTING I 
	right join PORTALSETTING C on( C.SETTINGID=I.SETTINGID)
where I.SETTINGID is null
UNION ALL 
select	6, 'PORTALSETTING', 0, count(*), 0, 0
from CCImport_PORTALSETTING I 
	left join PORTALSETTING C on( C.SETTINGID=I.SETTINGID)
where C.SETTINGID is null
UNION ALL 
 select	6, 'PORTALSETTING', 0, 0, count(*), 0
from CCImport_PORTALSETTING I 
	join PORTALSETTING C	on ( C.SETTINGID=I.SETTINGID)
where 	( I.MODULEID <>  C.MODULEID OR (I.MODULEID is null and C.MODULEID is not null) 
OR (I.MODULEID is not null and C.MODULEID is null))
	OR 	( I.MODULECONFIGID <>  C.MODULECONFIGID OR (I.MODULECONFIGID is null and C.MODULECONFIGID is not null) 
OR (I.MODULECONFIGID is not null and C.MODULECONFIGID is null))
	OR 	( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null) 
OR (I.IDENTITYID is not null and C.IDENTITYID is null))
	OR 	( I.SETTINGNAME <>  C.SETTINGNAME)
	OR 	( replace(CAST(I.SETTINGVALUE as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.SETTINGVALUE as NVARCHAR(MAX)) OR (I.SETTINGVALUE is null and C.SETTINGVALUE is not null) 
OR (I.SETTINGVALUE is not null and C.SETTINGVALUE is null))
UNION ALL 
 select	6, 'PORTALSETTING', 0, 0, 0, count(*)
from CCImport_PORTALSETTING I 
join PORTALSETTING C	on( C.SETTINGID=I.SETTINGID)
where ( I.MODULEID =  C.MODULEID OR (I.MODULEID is null and C.MODULEID is null))
and ( I.MODULECONFIGID =  C.MODULECONFIGID OR (I.MODULECONFIGID is null and C.MODULECONFIGID is null))
and ( I.IDENTITYID =  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is null))
and ( I.SETTINGNAME =  C.SETTINGNAME)
and ( replace(CAST(I.SETTINGVALUE as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.SETTINGVALUE as NVARCHAR(MAX)) OR (I.SETTINGVALUE is null and C.SETTINGVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALSETTING]') and xtype='U')
begin
	drop table CCImport_PORTALSETTING 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPORTALSETTING  to public
go
