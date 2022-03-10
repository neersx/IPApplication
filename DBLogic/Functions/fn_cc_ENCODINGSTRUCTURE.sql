-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ENCODINGSTRUCTURE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ENCODINGSTRUCTURE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ENCODINGSTRUCTURE.'
	drop function dbo.fn_cc_ENCODINGSTRUCTURE
	print '**** Creating function dbo.fn_cc_ENCODINGSTRUCTURE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODINGSTRUCTURE]') and xtype='U')
begin
	select * 
	into CCImport_ENCODINGSTRUCTURE 
	from ENCODINGSTRUCTURE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ENCODINGSTRUCTURE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ENCODINGSTRUCTURE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ENCODINGSTRUCTURE table
-- CALLED BY :	ip_CopyConfigENCODINGSTRUCTURE
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
	 null as 'Imported Schemeid',
	 null as 'Imported Structureid',
	 null as 'Imported Name',
	 null as 'Imported Description',
'D' as '-',
	 C.SCHEMEID as 'Schemeid',
	 C.STRUCTUREID as 'Structureid',
	 C.NAME as 'Name',
	 C.DESCRIPTION as 'Description'
from CCImport_ENCODINGSTRUCTURE I 
	right join ENCODINGSTRUCTURE C on( C.SCHEMEID=I.SCHEMEID
and  C.STRUCTUREID=I.STRUCTUREID)
where I.SCHEMEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SCHEMEID,
	 I.STRUCTUREID,
	 I.NAME,
	 I.DESCRIPTION,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ENCODINGSTRUCTURE I 
	left join ENCODINGSTRUCTURE C on( C.SCHEMEID=I.SCHEMEID
and  C.STRUCTUREID=I.STRUCTUREID)
where C.SCHEMEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SCHEMEID,
	 I.STRUCTUREID,
	 I.NAME,
	 I.DESCRIPTION,
'U',
	 C.SCHEMEID,
	 C.STRUCTUREID,
	 C.NAME,
	 C.DESCRIPTION
from CCImport_ENCODINGSTRUCTURE I 
	join ENCODINGSTRUCTURE C	on ( C.SCHEMEID=I.SCHEMEID
	and C.STRUCTUREID=I.STRUCTUREID)
where 	( I.NAME <>  C.NAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODINGSTRUCTURE]') and xtype='U')
begin
	drop table CCImport_ENCODINGSTRUCTURE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ENCODINGSTRUCTURE  to public
go
