-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEVENTUPDATEPROFILE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEVENTUPDATEPROFILE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEVENTUPDATEPROFILE.'
	drop function dbo.fn_ccnEVENTUPDATEPROFILE
	print '**** Creating function dbo.fn_ccnEVENTUPDATEPROFILE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTUPDATEPROFILE]') and xtype='U')
begin
	select * 
	into CCImport_EVENTUPDATEPROFILE 
	from EVENTUPDATEPROFILE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEVENTUPDATEPROFILE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEVENTUPDATEPROFILE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTUPDATEPROFILE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'EVENTUPDATEPROFILE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EVENTUPDATEPROFILE I 
	right join EVENTUPDATEPROFILE C on( C.PROFILEREFNO=I.PROFILEREFNO)
where I.PROFILEREFNO is null
UNION ALL 
select	5, 'EVENTUPDATEPROFILE', 0, count(*), 0, 0
from CCImport_EVENTUPDATEPROFILE I 
	left join EVENTUPDATEPROFILE C on( C.PROFILEREFNO=I.PROFILEREFNO)
where C.PROFILEREFNO is null
UNION ALL 
 select	5, 'EVENTUPDATEPROFILE', 0, 0, count(*), 0
from CCImport_EVENTUPDATEPROFILE I 
	join EVENTUPDATEPROFILE C	on ( C.PROFILEREFNO=I.PROFILEREFNO)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.EVENT1NO <>  C.EVENT1NO)
	OR 	( I.EVENT1TEXT <>  C.EVENT1TEXT OR (I.EVENT1TEXT is null and C.EVENT1TEXT is not null) 
OR (I.EVENT1TEXT is not null and C.EVENT1TEXT is null))
	OR 	( I.EVENT2NO <>  C.EVENT2NO OR (I.EVENT2NO is null and C.EVENT2NO is not null) 
OR (I.EVENT2NO is not null and C.EVENT2NO is null))
	OR 	( I.EVENT2TEXT <>  C.EVENT2TEXT OR (I.EVENT2TEXT is null and C.EVENT2TEXT is not null) 
OR (I.EVENT2TEXT is not null and C.EVENT2TEXT is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
UNION ALL 
 select	5, 'EVENTUPDATEPROFILE', 0, 0, 0, count(*)
from CCImport_EVENTUPDATEPROFILE I 
join EVENTUPDATEPROFILE C	on( C.PROFILEREFNO=I.PROFILEREFNO)
where ( I.DESCRIPTION =  C.DESCRIPTION)
and ( I.EVENT1NO =  C.EVENT1NO)
and ( I.EVENT1TEXT =  C.EVENT1TEXT OR (I.EVENT1TEXT is null and C.EVENT1TEXT is null))
and ( I.EVENT2NO =  C.EVENT2NO OR (I.EVENT2NO is null and C.EVENT2NO is null))
and ( I.EVENT2TEXT =  C.EVENT2TEXT OR (I.EVENT2TEXT is null and C.EVENT2TEXT is null))
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTUPDATEPROFILE]') and xtype='U')
begin
	drop table CCImport_EVENTUPDATEPROFILE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEVENTUPDATEPROFILE  to public
go
