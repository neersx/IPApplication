-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_MODULE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_MODULE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_MODULE.'
	drop function dbo.fn_cc_MODULE
	print '**** Creating function dbo.fn_cc_MODULE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MODULE]') and xtype='U')
begin
	select * 
	into CCImport_MODULE 
	from MODULE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_MODULE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_MODULE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MODULE table
-- CALLED BY :	ip_CopyConfigMODULE
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
	 null as 'Imported Moduledefid',
	 null as 'Imported Title',
	 null as 'Imported Cachetime',
	 null as 'Imported Description',
'D' as '-',
	 C.MODULEDEFID as 'Moduledefid',
	 C.TITLE as 'Title',
	 C.CACHETIME as 'Cachetime',
	 C.DESCRIPTION as 'Description'
from CCImport_MODULE I 
	right join MODULE C on( C.MODULEID=I.MODULEID)
where I.MODULEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.MODULEDEFID,
	 I.TITLE,
	 I.CACHETIME,
	 I.DESCRIPTION,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_MODULE I 
	left join MODULE C on( C.MODULEID=I.MODULEID)
where C.MODULEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.MODULEDEFID,
	 I.TITLE,
	 I.CACHETIME,
	 I.DESCRIPTION,
'U',
	 C.MODULEDEFID,
	 C.TITLE,
	 C.CACHETIME,
	 C.DESCRIPTION
from CCImport_MODULE I 
	join MODULE C	on ( C.MODULEID=I.MODULEID)
where 	( I.MODULEDEFID <>  C.MODULEDEFID)
	OR 	(replace( I.TITLE,char(10),char(13)+char(10)) <>  C.TITLE OR (I.TITLE is null and C.TITLE is not null) 
OR (I.TITLE is not null and C.TITLE is null))
	OR 	( I.CACHETIME <>  C.CACHETIME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MODULE]') and xtype='U')
begin
	drop table CCImport_MODULE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_MODULE  to public
go
