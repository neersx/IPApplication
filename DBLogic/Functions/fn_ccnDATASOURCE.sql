-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDATASOURCE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDATASOURCE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDATASOURCE.'
	drop function dbo.fn_ccnDATASOURCE
	print '**** Creating function dbo.fn_ccnDATASOURCE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DATASOURCE]') and xtype='U')
begin
	select * 
	into CCImport_DATASOURCE 
	from DATASOURCE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDATASOURCE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDATASOURCE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DATASOURCE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'DATASOURCE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DATASOURCE I 
	right join DATASOURCE C on( C.DATASOURCEID=I.DATASOURCEID)
where I.DATASOURCEID is null
UNION ALL 
select	9, 'DATASOURCE', 0, count(*), 0, 0
from CCImport_DATASOURCE I 
	left join DATASOURCE C on( C.DATASOURCEID=I.DATASOURCEID)
where C.DATASOURCEID is null
UNION ALL 
 select	9, 'DATASOURCE', 0, 0, count(*), 0
from CCImport_DATASOURCE I 
	join DATASOURCE C	on ( C.DATASOURCEID=I.DATASOURCEID)
where 	( I.SYSTEMID <>  C.SYSTEMID)
	OR 	( I.SOURCENAMENO <>  C.SOURCENAMENO OR (I.SOURCENAMENO is null and C.SOURCENAMENO is not null) 
OR (I.SOURCENAMENO is not null and C.SOURCENAMENO is null))
	OR 	( I.ISPROTECTED <>  C.ISPROTECTED)
	OR 	( I.DATASOURCECODE <>  C.DATASOURCECODE OR (I.DATASOURCECODE is null and C.DATASOURCECODE is not null) 
OR (I.DATASOURCECODE is not null and C.DATASOURCECODE is null))
UNION ALL 
 select	9, 'DATASOURCE', 0, 0, 0, count(*)
from CCImport_DATASOURCE I 
join DATASOURCE C	on( C.DATASOURCEID=I.DATASOURCEID)
where ( I.SYSTEMID =  C.SYSTEMID)
and ( I.SOURCENAMENO =  C.SOURCENAMENO OR (I.SOURCENAMENO is null and C.SOURCENAMENO is null))
and ( I.ISPROTECTED =  C.ISPROTECTED)
and ( I.DATASOURCECODE =  C.DATASOURCECODE OR (I.DATASOURCECODE is null and C.DATASOURCECODE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DATASOURCE]') and xtype='U')
begin
	drop table CCImport_DATASOURCE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDATASOURCE  to public
go
