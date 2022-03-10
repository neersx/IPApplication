-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ENCODINGSCHEME
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ENCODINGSCHEME]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ENCODINGSCHEME.'
	drop function dbo.fn_cc_ENCODINGSCHEME
	print '**** Creating function dbo.fn_cc_ENCODINGSCHEME...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODINGSCHEME]') and xtype='U')
begin
	select * 
	into CCImport_ENCODINGSCHEME 
	from ENCODINGSCHEME
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ENCODINGSCHEME
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ENCODINGSCHEME
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ENCODINGSCHEME table
-- CALLED BY :	ip_CopyConfigENCODINGSCHEME
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
	 null as 'Imported Schemecode',
	 null as 'Imported Schemename',
	 null as 'Imported Schemedescription',
	 null as 'Imported Isprotected',
'D' as '-',
	 C.SCHEMEID as 'Schemeid',
	 C.SCHEMECODE as 'Schemecode',
	 C.SCHEMENAME as 'Schemename',
	 C.SCHEMEDESCRIPTION as 'Schemedescription',
	 C.ISPROTECTED as 'Isprotected'
from CCImport_ENCODINGSCHEME I 
	right join ENCODINGSCHEME C on( C.SCHEMEID=I.SCHEMEID)
where I.SCHEMEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SCHEMEID,
	 I.SCHEMECODE,
	 I.SCHEMENAME,
	 I.SCHEMEDESCRIPTION,
	 I.ISPROTECTED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ENCODINGSCHEME I 
	left join ENCODINGSCHEME C on( C.SCHEMEID=I.SCHEMEID)
where C.SCHEMEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SCHEMEID,
	 I.SCHEMECODE,
	 I.SCHEMENAME,
	 I.SCHEMEDESCRIPTION,
	 I.ISPROTECTED,
'U',
	 C.SCHEMEID,
	 C.SCHEMECODE,
	 C.SCHEMENAME,
	 C.SCHEMEDESCRIPTION,
	 C.ISPROTECTED
from CCImport_ENCODINGSCHEME I 
	join ENCODINGSCHEME C	on ( C.SCHEMEID=I.SCHEMEID)
where 	( I.SCHEMECODE <>  C.SCHEMECODE)
	OR 	( I.SCHEMENAME <>  C.SCHEMENAME)
	OR 	(replace( I.SCHEMEDESCRIPTION,char(10),char(13)+char(10)) <>  C.SCHEMEDESCRIPTION OR (I.SCHEMEDESCRIPTION is null and C.SCHEMEDESCRIPTION is not null) 
OR (I.SCHEMEDESCRIPTION is not null and C.SCHEMEDESCRIPTION is null))
	OR 	( I.ISPROTECTED <>  C.ISPROTECTED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODINGSCHEME]') and xtype='U')
begin
	drop table CCImport_ENCODINGSCHEME 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ENCODINGSCHEME  to public
go
