-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ROLESCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ROLESCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ROLESCONTROL.'
	drop function dbo.fn_cc_ROLESCONTROL
	print '**** Creating function dbo.fn_cc_ROLESCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ROLESCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_ROLESCONTROL 
	from ROLESCONTROL
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ROLESCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ROLESCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ROLESCONTROL table
-- CALLED BY :	ip_CopyConfigROLESCONTROL
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 01 May 2017	MF	71205	1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Criteriano',
	 null as 'Imported Entrynumber',
	 null as 'Imported Roleid',
	 null as 'Imported Inherited',
	'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.ENTRYNUMBER as 'Entrynumber',
	 C.ROLEID as 'Roleid',
	 C.INHERITED as 'Inherited'
from CCImport_ROLESCONTROL I 
	right join ROLESCONTROL C on( C.ROLEID=I.ROLEID
				  and C.CRITERIANO=I.CRITERIANO
				  and C.ENTRYNUMBER=I.ENTRYNUMBER)
where I.ROLEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.ENTRYNUMBER,
	 I.ROLEID,
	 I.INHERITED,
	'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ROLESCONTROL I 
	left join ROLESCONTROL C on( C.ROLEID=I.ROLEID
				 and C.CRITERIANO=I.CRITERIANO
				 and C.ENTRYNUMBER=I.ENTRYNUMBER)
where C.ROLEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.ENTRYNUMBER,
	 I.ROLEID,
	 I.INHERITED,
	'U',
	 C.CRITERIANO,
	 C.ENTRYNUMBER,
	 C.ROLEID,
	 C.INHERITED
from CCImport_ROLESCONTROL I 
	join ROLESCONTROL C	on ( C.ROLEID=I.ROLEID
				and  C.CRITERIANO=I.CRITERIANO
				and  C.ENTRYNUMBER=I.ENTRYNUMBER)
where 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ROLESCONTROL]') and xtype='U')
begin
	drop table CCImport_ROLESCONTROL 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ROLESCONTROL  to public
go
