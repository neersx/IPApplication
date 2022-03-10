-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnENCODINGSCHEME
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnENCODINGSCHEME]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnENCODINGSCHEME.'
	drop function dbo.fn_ccnENCODINGSCHEME
	print '**** Creating function dbo.fn_ccnENCODINGSCHEME...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnENCODINGSCHEME
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnENCODINGSCHEME
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ENCODINGSCHEME table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'ENCODINGSCHEME' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ENCODINGSCHEME I 
	right join ENCODINGSCHEME C on( C.SCHEMEID=I.SCHEMEID)
where I.SCHEMEID is null
UNION ALL 
select	9, 'ENCODINGSCHEME', 0, count(*), 0, 0
from CCImport_ENCODINGSCHEME I 
	left join ENCODINGSCHEME C on( C.SCHEMEID=I.SCHEMEID)
where C.SCHEMEID is null
UNION ALL 
 select	9, 'ENCODINGSCHEME', 0, 0, count(*), 0
from CCImport_ENCODINGSCHEME I 
	join ENCODINGSCHEME C	on ( C.SCHEMEID=I.SCHEMEID)
where 	( I.SCHEMECODE <>  C.SCHEMECODE)
	OR 	( I.SCHEMENAME <>  C.SCHEMENAME)
	OR 	(replace( I.SCHEMEDESCRIPTION,char(10),char(13)+char(10)) <>  C.SCHEMEDESCRIPTION OR (I.SCHEMEDESCRIPTION is null and C.SCHEMEDESCRIPTION is not null) 
OR (I.SCHEMEDESCRIPTION is not null and C.SCHEMEDESCRIPTION is null))
	OR 	( I.ISPROTECTED <>  C.ISPROTECTED)
UNION ALL 
 select	9, 'ENCODINGSCHEME', 0, 0, 0, count(*)
from CCImport_ENCODINGSCHEME I 
join ENCODINGSCHEME C	on( C.SCHEMEID=I.SCHEMEID)
where ( I.SCHEMECODE =  C.SCHEMECODE)
and ( I.SCHEMENAME =  C.SCHEMENAME)
and (replace( I.SCHEMEDESCRIPTION,char(10),char(13)+char(10)) =  C.SCHEMEDESCRIPTION OR (I.SCHEMEDESCRIPTION is null and C.SCHEMEDESCRIPTION is null))
and ( I.ISPROTECTED =  C.ISPROTECTED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODINGSCHEME]') and xtype='U')
begin
	drop table CCImport_ENCODINGSCHEME 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnENCODINGSCHEME  to public
go
