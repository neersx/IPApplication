-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PORTAL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PORTAL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PORTAL.'
	drop function dbo.fn_cc_PORTAL
	print '**** Creating function dbo.fn_cc_PORTAL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PORTAL]') and xtype='U')
begin
	select * 
	into CCImport_PORTAL 
	from PORTAL
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PORTAL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PORTAL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PORTAL table
-- CALLED BY :	ip_CopyConfigPORTAL
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
	 null as 'Imported Name',
	 null as 'Imported Description',
	 null as 'Imported Isexternal',
'D' as '-',
	 C.NAME as 'Name',
	 C.DESCRIPTION as 'Description',
	 C.ISEXTERNAL as 'Isexternal'
from CCImport_PORTAL I 
	right join PORTAL C on( C.PORTALID=I.PORTALID)
where I.PORTALID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NAME,
	 I.DESCRIPTION,
	 I.ISEXTERNAL,
'I',
	 null ,
	 null ,
	 null
from CCImport_PORTAL I 
	left join PORTAL C on( C.PORTALID=I.PORTALID)
where C.PORTALID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.NAME,
	 I.DESCRIPTION,
	 I.ISEXTERNAL,
'U',
	 C.NAME,
	 C.DESCRIPTION,
	 C.ISEXTERNAL
from CCImport_PORTAL I 
	join PORTAL C	on ( C.PORTALID=I.PORTALID)
where 	( I.NAME <>  C.NAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.ISEXTERNAL <>  C.ISEXTERNAL)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PORTAL]') and xtype='U')
begin
	drop table CCImport_PORTAL 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PORTAL  to public
go
