-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnRESOURCE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnRESOURCE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnRESOURCE.'
	drop function dbo.fn_ccnRESOURCE
	print '**** Creating function dbo.fn_ccnRESOURCE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RESOURCE]') and xtype='U')
begin
	select * 
	into CCImport_RESOURCE 
	from RESOURCE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnRESOURCE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnRESOURCE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RESOURCE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'RESOURCE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_RESOURCE I 
	right join RESOURCE C on( C.RESOURCENO=I.RESOURCENO)
where I.RESOURCENO is null
UNION ALL 
select	2, 'RESOURCE', 0, count(*), 0, 0
from CCImport_RESOURCE I 
	left join RESOURCE C on( C.RESOURCENO=I.RESOURCENO)
where C.RESOURCENO is null
UNION ALL 
 select	2, 'RESOURCE', 0, 0, count(*), 0
from CCImport_RESOURCE I 
	join RESOURCE C	on ( C.RESOURCENO=I.RESOURCENO)
where 	( I.TYPE <>  C.TYPE)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	(replace( I.RESOURCE,char(10),char(13)+char(10)) <>  C.RESOURCE OR (I.RESOURCE is null and C.RESOURCE is not null) 
OR (I.RESOURCE is not null and C.RESOURCE is null))
	OR 	(replace( I.DRIVER,char(10),char(13)+char(10)) <>  C.DRIVER OR (I.DRIVER is null and C.DRIVER is not null) 
OR (I.DRIVER is not null and C.DRIVER is null))
	OR 	(replace( I.PORT,char(10),char(13)+char(10)) <>  C.PORT OR (I.PORT is null and C.PORT is not null) 
OR (I.PORT is not null and C.PORT is null))
UNION ALL 
 select	2, 'RESOURCE', 0, 0, 0, count(*)
from CCImport_RESOURCE I 
join RESOURCE C	on( C.RESOURCENO=I.RESOURCENO)
where ( I.TYPE =  C.TYPE)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and (replace( I.RESOURCE,char(10),char(13)+char(10)) =  C.RESOURCE OR (I.RESOURCE is null and C.RESOURCE is null))
and (replace( I.DRIVER,char(10),char(13)+char(10)) =  C.DRIVER OR (I.DRIVER is null and C.DRIVER is null))
and (replace( I.PORT,char(10),char(13)+char(10)) =  C.PORT OR (I.PORT is null and C.PORT is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RESOURCE]') and xtype='U')
begin
	drop table CCImport_RESOURCE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnRESOURCE  to public
go
