-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEXTERNALSYSTEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEXTERNALSYSTEM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEXTERNALSYSTEM.'
	drop function dbo.fn_ccnEXTERNALSYSTEM
	print '**** Creating function dbo.fn_ccnEXTERNALSYSTEM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EXTERNALSYSTEM]') and xtype='U')
begin
	select * 
	into CCImport_EXTERNALSYSTEM 
	from EXTERNALSYSTEM
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEXTERNALSYSTEM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEXTERNALSYSTEM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EXTERNALSYSTEM table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'EXTERNALSYSTEM' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EXTERNALSYSTEM I 
	right join EXTERNALSYSTEM C on( C.SYSTEMID=I.SYSTEMID)
where I.SYSTEMID is null
UNION ALL 
select	9, 'EXTERNALSYSTEM', 0, count(*), 0, 0
from CCImport_EXTERNALSYSTEM I 
	left join EXTERNALSYSTEM C on( C.SYSTEMID=I.SYSTEMID)
where C.SYSTEMID is null
UNION ALL 
 select	9, 'EXTERNALSYSTEM', 0, 0, count(*), 0
from CCImport_EXTERNALSYSTEM I 
	join EXTERNALSYSTEM C	on ( C.SYSTEMID=I.SYSTEMID)
where 	( I.SYSTEMNAME <>  C.SYSTEMNAME)
	OR 	( I.SYSTEMCODE <>  C.SYSTEMCODE)
	OR 	( I.DATAEXTRACTID <>  C.DATAEXTRACTID OR (I.DATAEXTRACTID is null and C.DATAEXTRACTID is not null) 
OR (I.DATAEXTRACTID is not null and C.DATAEXTRACTID is null))
UNION ALL 
 select	9, 'EXTERNALSYSTEM', 0, 0, 0, count(*)
from CCImport_EXTERNALSYSTEM I 
join EXTERNALSYSTEM C	on( C.SYSTEMID=I.SYSTEMID)
where ( I.SYSTEMNAME =  C.SYSTEMNAME)
and ( I.SYSTEMCODE =  C.SYSTEMCODE)
and ( I.DATAEXTRACTID =  C.DATAEXTRACTID OR (I.DATAEXTRACTID is null and C.DATAEXTRACTID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EXTERNALSYSTEM]') and xtype='U')
begin
	drop table CCImport_EXTERNALSYSTEM 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEXTERNALSYSTEM  to public
go
