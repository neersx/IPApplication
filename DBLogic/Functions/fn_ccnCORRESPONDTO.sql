-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCORRESPONDTO
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCORRESPONDTO]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCORRESPONDTO.'
	drop function dbo.fn_ccnCORRESPONDTO
	print '**** Creating function dbo.fn_ccnCORRESPONDTO...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CORRESPONDTO]') and xtype='U')
begin
	select * 
	into CCImport_CORRESPONDTO 
	from CORRESPONDTO
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCORRESPONDTO
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCORRESPONDTO
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CORRESPONDTO table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'CORRESPONDTO' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CORRESPONDTO I 
	right join CORRESPONDTO C on( C.CORRESPONDTYPE=I.CORRESPONDTYPE)
where I.CORRESPONDTYPE is null
UNION ALL 
select	2, 'CORRESPONDTO', 0, count(*), 0, 0
from CCImport_CORRESPONDTO I 
	left join CORRESPONDTO C on( C.CORRESPONDTYPE=I.CORRESPONDTYPE)
where C.CORRESPONDTYPE is null
UNION ALL 
 select	2, 'CORRESPONDTO', 0, 0, count(*), 0
from CCImport_CORRESPONDTO I 
	join CORRESPONDTO C	on ( C.CORRESPONDTYPE=I.CORRESPONDTYPE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.COPIESTO <>  C.COPIESTO OR (I.COPIESTO is null and C.COPIESTO is not null) 
OR (I.COPIESTO is not null and C.COPIESTO is null))
UNION ALL 
 select	2, 'CORRESPONDTO', 0, 0, 0, count(*)
from CCImport_CORRESPONDTO I 
join CORRESPONDTO C	on( C.CORRESPONDTYPE=I.CORRESPONDTYPE)
where ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))
and ( I.COPIESTO =  C.COPIESTO OR (I.COPIESTO is null and C.COPIESTO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CORRESPONDTO]') and xtype='U')
begin
	drop table CCImport_CORRESPONDTO 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCORRESPONDTO  to public
go
