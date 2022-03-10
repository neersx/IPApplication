-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnRECORDALTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnRECORDALTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnRECORDALTYPE.'
	drop function dbo.fn_ccnRECORDALTYPE
	print '**** Creating function dbo.fn_ccnRECORDALTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDALTYPE]') and xtype='U')
begin
	select * 
	into CCImport_RECORDALTYPE 
	from RECORDALTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnRECORDALTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnRECORDALTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RECORDALTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'RECORDALTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_RECORDALTYPE I 
	right join RECORDALTYPE C on( C.RECORDALTYPENO=I.RECORDALTYPENO)
where I.RECORDALTYPENO is null
UNION ALL 
select	5, 'RECORDALTYPE', 0, count(*), 0, 0
from CCImport_RECORDALTYPE I 
	left join RECORDALTYPE C on( C.RECORDALTYPENO=I.RECORDALTYPENO)
where C.RECORDALTYPENO is null
UNION ALL 
 select	5, 'RECORDALTYPE', 0, 0, count(*), 0
from CCImport_RECORDALTYPE I 
	join RECORDALTYPE C	on ( C.RECORDALTYPENO=I.RECORDALTYPENO)
where 	( I.RECORDALTYPE <>  C.RECORDALTYPE)
	OR 	( I.REQUESTEVENTNO <>  C.REQUESTEVENTNO OR (I.REQUESTEVENTNO is null and C.REQUESTEVENTNO is not null) 
OR (I.REQUESTEVENTNO is not null and C.REQUESTEVENTNO is null))
	OR 	( I.REQUESTACTION <>  C.REQUESTACTION OR (I.REQUESTACTION is null and C.REQUESTACTION is not null) 
OR (I.REQUESTACTION is not null and C.REQUESTACTION is null))
	OR 	( I.RECORDEVENTNO <>  C.RECORDEVENTNO OR (I.RECORDEVENTNO is null and C.RECORDEVENTNO is not null) 
OR (I.RECORDEVENTNO is not null and C.RECORDEVENTNO is null))
	OR 	( I.RECORDACTION <>  C.RECORDACTION OR (I.RECORDACTION is null and C.RECORDACTION is not null) 
OR (I.RECORDACTION is not null and C.RECORDACTION is null))
UNION ALL 
 select	5, 'RECORDALTYPE', 0, 0, 0, count(*)
from CCImport_RECORDALTYPE I 
join RECORDALTYPE C	on( C.RECORDALTYPENO=I.RECORDALTYPENO)
where ( I.RECORDALTYPE =  C.RECORDALTYPE)
and ( I.REQUESTEVENTNO =  C.REQUESTEVENTNO OR (I.REQUESTEVENTNO is null and C.REQUESTEVENTNO is null))
and ( I.REQUESTACTION =  C.REQUESTACTION OR (I.REQUESTACTION is null and C.REQUESTACTION is null))
and ( I.RECORDEVENTNO =  C.RECORDEVENTNO OR (I.RECORDEVENTNO is null and C.RECORDEVENTNO is null))
and ( I.RECORDACTION =  C.RECORDACTION OR (I.RECORDACTION is null and C.RECORDACTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDALTYPE]') and xtype='U')
begin
	drop table CCImport_RECORDALTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnRECORDALTYPE  to public
go
