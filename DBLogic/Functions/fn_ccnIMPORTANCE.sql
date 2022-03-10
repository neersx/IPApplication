-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnIMPORTANCE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnIMPORTANCE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnIMPORTANCE.'
	drop function dbo.fn_ccnIMPORTANCE
	print '**** Creating function dbo.fn_ccnIMPORTANCE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_IMPORTANCE]') and xtype='U')
begin
	select * 
	into CCImport_IMPORTANCE 
	from IMPORTANCE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnIMPORTANCE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnIMPORTANCE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the IMPORTANCE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'IMPORTANCE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_IMPORTANCE I 
	right join IMPORTANCE C on( C.IMPORTANCELEVEL=I.IMPORTANCELEVEL)
where I.IMPORTANCELEVEL is null
UNION ALL 
select	2, 'IMPORTANCE', 0, count(*), 0, 0
from CCImport_IMPORTANCE I 
	left join IMPORTANCE C on( C.IMPORTANCELEVEL=I.IMPORTANCELEVEL)
where C.IMPORTANCELEVEL is null
UNION ALL 
 select	2, 'IMPORTANCE', 0, 0, count(*), 0
from CCImport_IMPORTANCE I 
	join IMPORTANCE C	on ( C.IMPORTANCELEVEL=I.IMPORTANCELEVEL)
where 	( I.IMPORTANCEDESC <>  C.IMPORTANCEDESC OR (I.IMPORTANCEDESC is null and C.IMPORTANCEDESC is not null) 
OR (I.IMPORTANCEDESC is not null and C.IMPORTANCEDESC is null))
UNION ALL 
 select	2, 'IMPORTANCE', 0, 0, 0, count(*)
from CCImport_IMPORTANCE I 
join IMPORTANCE C	on( C.IMPORTANCELEVEL=I.IMPORTANCELEVEL)
where ( I.IMPORTANCEDESC =  C.IMPORTANCEDESC OR (I.IMPORTANCEDESC is null and C.IMPORTANCEDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_IMPORTANCE]') and xtype='U')
begin
	drop table CCImport_IMPORTANCE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnIMPORTANCE  to public
go
