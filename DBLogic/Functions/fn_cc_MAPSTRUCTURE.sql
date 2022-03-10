-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_MAPSTRUCTURE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_MAPSTRUCTURE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_MAPSTRUCTURE.'
	drop function dbo.fn_cc_MAPSTRUCTURE
	print '**** Creating function dbo.fn_cc_MAPSTRUCTURE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MAPSTRUCTURE]') and xtype='U')
begin
	select * 
	into CCImport_MAPSTRUCTURE 
	from MAPSTRUCTURE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_MAPSTRUCTURE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_MAPSTRUCTURE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MAPSTRUCTURE table
-- CALLED BY :	ip_CopyConfigMAPSTRUCTURE
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
	 null as 'Imported Structureid',
	 null as 'Imported Structurename',
	 null as 'Imported Tablename',
	 null as 'Imported Keycolumname',
	 null as 'Imported Codecolumnname',
	 null as 'Imported Desccolumnname',
	 null as 'Imported Searchcontextid',
'D' as '-',
	 C.STRUCTUREID as 'Structureid',
	 C.STRUCTURENAME as 'Structurename',
	 C.TABLENAME as 'Tablename',
	 C.KEYCOLUMNAME as 'Keycolumname',
	 C.CODECOLUMNNAME as 'Codecolumnname',
	 C.DESCCOLUMNNAME as 'Desccolumnname',
	 C.SEARCHCONTEXTID as 'Searchcontextid'
from CCImport_MAPSTRUCTURE I 
	right join MAPSTRUCTURE C on( C.STRUCTUREID=I.STRUCTUREID)
where I.STRUCTUREID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.STRUCTUREID,
	 I.STRUCTURENAME,
	 I.TABLENAME,
	 I.KEYCOLUMNAME,
	 I.CODECOLUMNNAME,
	 I.DESCCOLUMNNAME,
	 I.SEARCHCONTEXTID,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_MAPSTRUCTURE I 
	left join MAPSTRUCTURE C on( C.STRUCTUREID=I.STRUCTUREID)
where C.STRUCTUREID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.STRUCTUREID,
	 I.STRUCTURENAME,
	 I.TABLENAME,
	 I.KEYCOLUMNAME,
	 I.CODECOLUMNNAME,
	 I.DESCCOLUMNNAME,
	 I.SEARCHCONTEXTID,
'U',
	 C.STRUCTUREID,
	 C.STRUCTURENAME,
	 C.TABLENAME,
	 C.KEYCOLUMNAME,
	 C.CODECOLUMNNAME,
	 C.DESCCOLUMNNAME,
	 C.SEARCHCONTEXTID
from CCImport_MAPSTRUCTURE I 
	join MAPSTRUCTURE C	on ( C.STRUCTUREID=I.STRUCTUREID)
where 	( I.STRUCTURENAME <>  C.STRUCTURENAME)
	OR 	( I.TABLENAME <>  C.TABLENAME)
	OR 	( I.KEYCOLUMNAME <>  C.KEYCOLUMNAME)
	OR 	( I.CODECOLUMNNAME <>  C.CODECOLUMNNAME OR (I.CODECOLUMNNAME is null and C.CODECOLUMNNAME is not null) 
OR (I.CODECOLUMNNAME is not null and C.CODECOLUMNNAME is null))
	OR 	( I.DESCCOLUMNNAME <>  C.DESCCOLUMNNAME OR (I.DESCCOLUMNNAME is null and C.DESCCOLUMNNAME is not null) 
OR (I.DESCCOLUMNNAME is not null and C.DESCCOLUMNNAME is null))
	OR 	( I.SEARCHCONTEXTID <>  C.SEARCHCONTEXTID OR (I.SEARCHCONTEXTID is null and C.SEARCHCONTEXTID is not null) 
OR (I.SEARCHCONTEXTID is not null and C.SEARCHCONTEXTID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MAPSTRUCTURE]') and xtype='U')
begin
	drop table CCImport_MAPSTRUCTURE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_MAPSTRUCTURE  to public
go
