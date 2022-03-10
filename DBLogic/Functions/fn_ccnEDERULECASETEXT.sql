-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEDERULECASETEXT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEDERULECASETEXT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEDERULECASETEXT.'
	drop function dbo.fn_ccnEDERULECASETEXT
	print '**** Creating function dbo.fn_ccnEDERULECASETEXT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASETEXT]') and xtype='U')
begin
	select * 
	into CCImport_EDERULECASETEXT 
	from EDERULECASETEXT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEDERULECASETEXT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEDERULECASETEXT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULECASETEXT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'EDERULECASETEXT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EDERULECASETEXT I 
	right join EDERULECASETEXT C on( C.CRITERIANO=I.CRITERIANO
and  C.TEXTTYPE=I.TEXTTYPE)
where I.CRITERIANO is null
UNION ALL 
select	9, 'EDERULECASETEXT', 0, count(*), 0, 0
from CCImport_EDERULECASETEXT I 
	left join EDERULECASETEXT C on( C.CRITERIANO=I.CRITERIANO
and  C.TEXTTYPE=I.TEXTTYPE)
where C.CRITERIANO is null
UNION ALL 
 select	9, 'EDERULECASETEXT', 0, 0, count(*), 0
from CCImport_EDERULECASETEXT I 
	join EDERULECASETEXT C	on ( C.CRITERIANO=I.CRITERIANO
	and C.TEXTTYPE=I.TEXTTYPE)
where 	( I.TEXT <>  C.TEXT OR (I.TEXT is null and C.TEXT is not null) 
OR (I.TEXT is not null and C.TEXT is null))
UNION ALL 
 select	9, 'EDERULECASETEXT', 0, 0, 0, count(*)
from CCImport_EDERULECASETEXT I 
join EDERULECASETEXT C	on( C.CRITERIANO=I.CRITERIANO
and C.TEXTTYPE=I.TEXTTYPE)
where ( I.TEXT =  C.TEXT OR (I.TEXT is null and C.TEXT is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASETEXT]') and xtype='U')
begin
	drop table CCImport_EDERULECASETEXT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEDERULECASETEXT  to public
go
