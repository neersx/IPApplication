-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnB2BELEMENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnB2BELEMENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnB2BELEMENT.'
	drop function dbo.fn_ccnB2BELEMENT
	print '**** Creating function dbo.fn_ccnB2BELEMENT...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_B2BELEMENT]') and xtype='U')
begin
	select * 
	into CCImport_B2BELEMENT 
	from B2BELEMENT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnB2BELEMENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnB2BELEMENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the B2BELEMENT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'B2BELEMENT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_B2BELEMENT I 
	right join B2BELEMENT C on( C.ELEMENTID=I.ELEMENTID)
where I.ELEMENTID is null
UNION ALL 
select	9, 'B2BELEMENT', 0, count(*), 0, 0
from CCImport_B2BELEMENT I 
	left join B2BELEMENT C on( C.ELEMENTID=I.ELEMENTID)
where C.ELEMENTID is null
UNION ALL 
 select	9, 'B2BELEMENT', 0, 0, count(*), 0
from CCImport_B2BELEMENT I 
	join B2BELEMENT C	on ( C.ELEMENTID=I.ELEMENTID)
where 	( I.COUNTRY <>  C.COUNTRY OR (I.COUNTRY is null and C.COUNTRY is not null) 
OR (I.COUNTRY is not null and C.COUNTRY is null))
	OR 	( I.SETTINGID <>  C.SETTINGID OR (I.SETTINGID is null and C.SETTINGID is not null) 
OR (I.SETTINGID is not null and C.SETTINGID is null))
	OR 	( I.ELEMENTNAME <>  C.ELEMENTNAME OR (I.ELEMENTNAME is null and C.ELEMENTNAME is not null) 
OR (I.ELEMENTNAME is not null and C.ELEMENTNAME is null))
	OR 	( I.VALUE <>  C.VALUE OR (I.VALUE is null and C.VALUE is not null) 
OR (I.VALUE is not null and C.VALUE is null))
	OR 	( I.INUSE <>  C.INUSE)
	OR 	( replace(CAST(I.DESCRIPTION as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.DESCRIPTION as NVARCHAR(MAX)) OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
UNION ALL 
 select	9, 'B2BELEMENT', 0, 0, 0, count(*)
from CCImport_B2BELEMENT I 
join B2BELEMENT C	on( C.ELEMENTID=I.ELEMENTID)
where ( I.COUNTRY =  C.COUNTRY OR (I.COUNTRY is null and C.COUNTRY is null))
and ( I.SETTINGID =  C.SETTINGID OR (I.SETTINGID is null and C.SETTINGID is null))
and ( I.ELEMENTNAME =  C.ELEMENTNAME OR (I.ELEMENTNAME is null and C.ELEMENTNAME is null))
and ( I.VALUE =  C.VALUE OR (I.VALUE is null and C.VALUE is null))
and ( I.INUSE =  C.INUSE)
and ( replace(CAST(I.DESCRIPTION as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.DESCRIPTION as NVARCHAR(MAX)) OR (I.DESCRIPTION is null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_B2BELEMENT]') and xtype='U')
begin
	drop table CCImport_B2BELEMENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnB2BELEMENT  to public
go