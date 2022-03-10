-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEDERULECASENAME
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEDERULECASENAME]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEDERULECASENAME.'
	drop function dbo.fn_ccnEDERULECASENAME
	print '**** Creating function dbo.fn_ccnEDERULECASENAME...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASENAME]') and xtype='U')
begin
	select * 
	into CCImport_EDERULECASENAME 
	from EDERULECASENAME
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEDERULECASENAME
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEDERULECASENAME
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULECASENAME table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'EDERULECASENAME' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EDERULECASENAME I 
	right join EDERULECASENAME C on( C.CRITERIANO=I.CRITERIANO
and  C.NAMETYPE=I.NAMETYPE)
where I.CRITERIANO is null
UNION ALL 
select	9, 'EDERULECASENAME', 0, count(*), 0, 0
from CCImport_EDERULECASENAME I 
	left join EDERULECASENAME C on( C.CRITERIANO=I.CRITERIANO
and  C.NAMETYPE=I.NAMETYPE)
where C.CRITERIANO is null
UNION ALL 
 select	9, 'EDERULECASENAME', 0, 0, count(*), 0
from CCImport_EDERULECASENAME I 
	join EDERULECASENAME C	on ( C.CRITERIANO=I.CRITERIANO
	and C.NAMETYPE=I.NAMETYPE)
where 	( I.NAMENO <>  C.NAMENO OR (I.NAMENO is null and C.NAMENO is not null) 
OR (I.NAMENO is not null and C.NAMENO is null))
	OR 	( I.REFERENCENO <>  C.REFERENCENO OR (I.REFERENCENO is null and C.REFERENCENO is not null) 
OR (I.REFERENCENO is not null and C.REFERENCENO is null))
	OR 	( I.CORRESPONDNAME <>  C.CORRESPONDNAME OR (I.CORRESPONDNAME is null and C.CORRESPONDNAME is not null) 
OR (I.CORRESPONDNAME is not null and C.CORRESPONDNAME is null))
UNION ALL 
 select	9, 'EDERULECASENAME', 0, 0, 0, count(*)
from CCImport_EDERULECASENAME I 
join EDERULECASENAME C	on( C.CRITERIANO=I.CRITERIANO
and C.NAMETYPE=I.NAMETYPE)
where ( I.NAMENO =  C.NAMENO OR (I.NAMENO is null and C.NAMENO is null))
and ( I.REFERENCENO =  C.REFERENCENO OR (I.REFERENCENO is null and C.REFERENCENO is null))
and ( I.CORRESPONDNAME =  C.CORRESPONDNAME OR (I.CORRESPONDNAME is null and C.CORRESPONDNAME is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASENAME]') and xtype='U')
begin
	drop table CCImport_EDERULECASENAME 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEDERULECASENAME  to public
go
