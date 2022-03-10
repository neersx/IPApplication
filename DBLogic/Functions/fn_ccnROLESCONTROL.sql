-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnROLESCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnROLESCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnROLESCONTROL.'
	drop function dbo.fn_ccnROLESCONTROL
	print '**** Creating function dbo.fn_ccnROLESCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ROLESCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_ROLESCONTROL 
	from ROLESCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnROLESCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnROLESCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ROLESCONTROL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 01 May 2017	MF	71205	1	Function generated
--
As 
Return
select	6 as TRIPNO, 'ROLESCONTROL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ROLESCONTROL I 
	right join ROLESCONTROL C on( C.ROLEID=I.ROLEID
				  and C.CRITERIANO=I.CRITERIANO
				  and C.ENTRYNUMBER=I.ENTRYNUMBER)
where I.ROLEID is null
UNION ALL 
select	6, 'ROLESCONTROL', 0, count(*), 0, 0
from CCImport_ROLESCONTROL I 
	left join ROLESCONTROL C on( C.ROLEID=I.ROLEID
				 and C.CRITERIANO=I.CRITERIANO
				 and C.ENTRYNUMBER=I.ENTRYNUMBER)
where C.ROLEID is null
UNION ALL 
 select	6, 'ROLESCONTROL', 0, 0, count(*), 0
from CCImport_ROLESCONTROL I 
	join ROLESCONTROL C	on ( C.ROLEID=I.ROLEID
				and  C.CRITERIANO=I.CRITERIANO
				and  C.ENTRYNUMBER=I.ENTRYNUMBER)
where 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
UNION ALL 
 select	6, 'ROLESCONTROL', 0, 0, 0, count(*)
from CCImport_ROLESCONTROL I 
join ROLESCONTROL C	on( C.ROLEID=I.ROLEID
			and C.CRITERIANO=I.CRITERIANO
			and C.ENTRYNUMBER=I.ENTRYNUMBER)
where ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ROLESCONTROL]') and xtype='U')
begin
	drop table CCImport_ROLESCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnROLESCONTROL  to public
go
