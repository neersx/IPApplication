-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PORTALSETTING
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PORTALSETTING]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PORTALSETTING.'
	drop function dbo.fn_cc_PORTALSETTING
	print '**** Creating function dbo.fn_cc_PORTALSETTING...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALSETTING]') and xtype='U')
begin
	select * 
	into CCImport_PORTALSETTING 
	from PORTALSETTING
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PORTALSETTING
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PORTALSETTING
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PORTALSETTING table
-- CALLED BY :	ip_CopyConfigPORTALSETTING
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Moduleid',
	 null as 'Imported Moduleconfigid',
	 null as 'Imported Identityid',
	 null as 'Imported Settingname',
	 null as 'Imported Settingvalue',
'D' as '-',
	 C.MODULEID as 'Moduleid',
	 C.MODULECONFIGID as 'Moduleconfigid',
	 C.IDENTITYID as 'Identityid',
	 C.SETTINGNAME as 'Settingname',
	 CAST(C.SETTINGVALUE AS NVARCHAR(4000)) as 'Settingvalue'
from CCImport_PORTALSETTING I 
	right join PORTALSETTING C on( C.SETTINGID=I.SETTINGID)
where I.SETTINGID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.MODULEID,
	 I.MODULECONFIGID,
	 I.IDENTITYID,
	 I.SETTINGNAME,
	 CAST(I.SETTINGVALUE AS NVARCHAR(4000)),
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_PORTALSETTING I 
	left join PORTALSETTING C on( C.SETTINGID=I.SETTINGID)
where C.SETTINGID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.MODULEID,
	 I.MODULECONFIGID,
	 I.IDENTITYID,
	 I.SETTINGNAME,
	 CAST(I.SETTINGVALUE AS NVARCHAR(4000)),
'U',
	 C.MODULEID,
	 C.MODULECONFIGID,
	 C.IDENTITYID,
	 C.SETTINGNAME,
	 CAST(C.SETTINGVALUE AS NVARCHAR(4000))
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALSETTING]') and xtype='U')
begin
	drop table CCImport_PORTALSETTING 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PORTALSETTING  to public
go
