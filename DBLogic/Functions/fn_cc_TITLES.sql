-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TITLES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TITLES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TITLES.'
	drop function dbo.fn_cc_TITLES
	print '**** Creating function dbo.fn_cc_TITLES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TITLES]') and xtype='U')
begin
	select * 
	into CCImport_TITLES 
	from TITLES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TITLES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TITLES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TITLES table
-- CALLED BY :	ip_CopyConfigTITLES
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
	 null as 'Imported Title',
	 null as 'Imported Fulltitle',
	 null as 'Imported Genderflag',
	 null as 'Imported Defaultflag',
'D' as '-',
	 C.TITLE as 'Title',
	 C.FULLTITLE as 'Fulltitle',
	 C.GENDERFLAG as 'Genderflag',
	 C.DEFAULTFLAG as 'Defaultflag'
from CCImport_TITLES I 
	right join TITLES C on( C.TITLE=I.TITLE)
where I.TITLE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TITLE,
	 I.FULLTITLE,
	 I.GENDERFLAG,
	 I.DEFAULTFLAG,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_TITLES I 
	left join TITLES C on( C.TITLE=I.TITLE)
where C.TITLE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TITLE,
	 I.FULLTITLE,
	 I.GENDERFLAG,
	 I.DEFAULTFLAG,
'U',
	 C.TITLE,
	 C.FULLTITLE,
	 C.GENDERFLAG,
	 C.DEFAULTFLAG
from CCImport_TITLES I 
	join TITLES C	on ( C.TITLE=I.TITLE)
where 	( I.FULLTITLE <>  C.FULLTITLE OR (I.FULLTITLE is null and C.FULLTITLE is not null) 
OR (I.FULLTITLE is not null and C.FULLTITLE is null))
	OR 	( I.GENDERFLAG <>  C.GENDERFLAG OR (I.GENDERFLAG is null and C.GENDERFLAG is not null) 
OR (I.GENDERFLAG is not null and C.GENDERFLAG is null))
	OR 	( I.DEFAULTFLAG <>  C.DEFAULTFLAG OR (I.DEFAULTFLAG is null and C.DEFAULTFLAG is not null) 
OR (I.DEFAULTFLAG is not null and C.DEFAULTFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TITLES]') and xtype='U')
begin
	drop table CCImport_TITLES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TITLES  to public
go
