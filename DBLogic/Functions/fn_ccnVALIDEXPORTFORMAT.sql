-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDEXPORTFORMAT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDEXPORTFORMAT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDEXPORTFORMAT.'
	drop function dbo.fn_ccnVALIDEXPORTFORMAT
	print '**** Creating function dbo.fn_ccnVALIDEXPORTFORMAT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDEXPORTFORMAT]') and xtype='U')
begin
	select * 
	into CCImport_VALIDEXPORTFORMAT 
	from VALIDEXPORTFORMAT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDEXPORTFORMAT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDEXPORTFORMAT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDEXPORTFORMAT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDEXPORTFORMAT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDEXPORTFORMAT I 
	right join VALIDEXPORTFORMAT C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and  C.FORMATID=I.FORMATID)
where I.DOCUMENTDEFID is null
UNION ALL 
select	3, 'VALIDEXPORTFORMAT', 0, count(*), 0, 0
from CCImport_VALIDEXPORTFORMAT I 
	left join VALIDEXPORTFORMAT C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and  C.FORMATID=I.FORMATID)
where C.DOCUMENTDEFID is null
UNION ALL 
 select	3, 'VALIDEXPORTFORMAT', 0, 0, count(*), 0
from CCImport_VALIDEXPORTFORMAT I 
	join VALIDEXPORTFORMAT C	on ( C.DOCUMENTDEFID=I.DOCUMENTDEFID
	and C.FORMATID=I.FORMATID)
where 	( I.ISDEFAULT <>  C.ISDEFAULT)
UNION ALL 
 select	3, 'VALIDEXPORTFORMAT', 0, 0, 0, count(*)
from CCImport_VALIDEXPORTFORMAT I 
join VALIDEXPORTFORMAT C	on( C.DOCUMENTDEFID=I.DOCUMENTDEFID
and C.FORMATID=I.FORMATID)
where ( I.ISDEFAULT =  C.ISDEFAULT)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDEXPORTFORMAT]') and xtype='U')
begin
	drop table CCImport_VALIDEXPORTFORMAT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDEXPORTFORMAT  to public
go
