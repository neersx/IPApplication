-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPROTECTCODES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPROTECTCODES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPROTECTCODES.'
	drop function dbo.fn_ccnPROTECTCODES
	print '**** Creating function dbo.fn_ccnPROTECTCODES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROTECTCODES]') and xtype='U')
begin
	select * 
	into CCImport_PROTECTCODES 
	from PROTECTCODES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPROTECTCODES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPROTECTCODES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROTECTCODES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'PROTECTCODES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PROTECTCODES I 
	right join PROTECTCODES C on( C.PROTECTKEY=I.PROTECTKEY)
where I.PROTECTKEY is null
UNION ALL 
select	5, 'PROTECTCODES', 0, count(*), 0, 0
from CCImport_PROTECTCODES I 
	left join PROTECTCODES C on( C.PROTECTKEY=I.PROTECTKEY)
where C.PROTECTKEY is null
UNION ALL 
 select	5, 'PROTECTCODES', 0, 0, count(*), 0
from CCImport_PROTECTCODES I 
	join PROTECTCODES C	on ( C.PROTECTKEY=I.PROTECTKEY)
where 	( I.TABLECODE <>  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is not null) 
OR (I.TABLECODE is not null and C.TABLECODE is null))
	OR 	( I.TABLETYPE <>  C.TABLETYPE OR (I.TABLETYPE is null and C.TABLETYPE is not null) 
OR (I.TABLETYPE is not null and C.TABLETYPE is null))
	OR 	( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null) 
OR (I.EVENTNO is not null and C.EVENTNO is null))
	OR 	( I.CASERELATIONSHIP <>  C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is not null) 
OR (I.CASERELATIONSHIP is not null and C.CASERELATIONSHIP is null))
	OR 	( I.NAMERELATIONSHIP <>  C.NAMERELATIONSHIP OR (I.NAMERELATIONSHIP is null and C.NAMERELATIONSHIP is not null) 
OR (I.NAMERELATIONSHIP is not null and C.NAMERELATIONSHIP is null))
	OR 	( I.NUMBERTYPE <>  C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is not null) 
OR (I.NUMBERTYPE is not null and C.NUMBERTYPE is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.ADJUSTMENT <>  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) 
OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null))
	OR 	( I.TEXTTYPE <>  C.TEXTTYPE OR (I.TEXTTYPE is null and C.TEXTTYPE is not null) 
OR (I.TEXTTYPE is not null and C.TEXTTYPE is null))
	OR 	( I.FAMILY <>  C.FAMILY OR (I.FAMILY is null and C.FAMILY is not null) 
OR (I.FAMILY is not null and C.FAMILY is null))
UNION ALL 
 select	5, 'PROTECTCODES', 0, 0, 0, count(*)
from CCImport_PROTECTCODES I 
join PROTECTCODES C	on( C.PROTECTKEY=I.PROTECTKEY)
where ( I.TABLECODE =  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is null))
and ( I.TABLETYPE =  C.TABLETYPE OR (I.TABLETYPE is null and C.TABLETYPE is null))
and ( I.EVENTNO =  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is null))
and ( I.CASERELATIONSHIP =  C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is null))
and ( I.NAMERELATIONSHIP =  C.NAMERELATIONSHIP OR (I.NAMERELATIONSHIP is null and C.NAMERELATIONSHIP is null))
and ( I.NUMBERTYPE =  C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is null))
and ( I.CASETYPE =  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is null))
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))
and ( I.ADJUSTMENT =  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is null))
and ( I.TEXTTYPE =  C.TEXTTYPE OR (I.TEXTTYPE is null and C.TEXTTYPE is null))
and ( I.FAMILY =  C.FAMILY OR (I.FAMILY is null and C.FAMILY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROTECTCODES]') and xtype='U')
begin
	drop table CCImport_PROTECTCODES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPROTECTCODES  to public
go
