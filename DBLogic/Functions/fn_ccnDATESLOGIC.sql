-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDATESLOGIC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDATESLOGIC]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDATESLOGIC.'
	drop function dbo.fn_ccnDATESLOGIC
	print '**** Creating function dbo.fn_ccnDATESLOGIC...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DATESLOGIC]') and xtype='U')
begin
	select * 
	into CCImport_DATESLOGIC 
	from DATESLOGIC
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDATESLOGIC
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDATESLOGIC
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DATESLOGIC table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'DATESLOGIC' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DATESLOGIC I 
	right join DATESLOGIC C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCENO=I.SEQUENCENO)
where I.CRITERIANO is null
UNION ALL 
select	5, 'DATESLOGIC', 0, count(*), 0, 0
from CCImport_DATESLOGIC I 
	left join DATESLOGIC C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCENO=I.SEQUENCENO)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'DATESLOGIC', 0, 0, count(*), 0
from CCImport_DATESLOGIC I 
	join DATESLOGIC C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.DATETYPE <>  C.DATETYPE)
	OR 	( I.OPERATOR <>  C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null) 
OR (I.OPERATOR is not null and C.OPERATOR is null))
	OR 	( I.COMPAREEVENT <>  C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null) 
OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null))
	OR 	( I.MUSTEXIST <>  C.MUSTEXIST)
	OR 	( I.RELATIVECYCLE <>  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) 
OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null))
	OR 	( I.COMPAREDATETYPE <>  C.COMPAREDATETYPE)
	OR 	( I.CASERELATIONSHIP <>  C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is not null) 
OR (I.CASERELATIONSHIP is not null and C.CASERELATIONSHIP is null))
	OR 	( I.DISPLAYERRORFLAG <>  C.DISPLAYERRORFLAG OR (I.DISPLAYERRORFLAG is null and C.DISPLAYERRORFLAG is not null) 
OR (I.DISPLAYERRORFLAG is not null and C.DISPLAYERRORFLAG is null))
	OR 	(replace( I.ERRORMESSAGE,char(10),char(13)+char(10)) <>  C.ERRORMESSAGE OR (I.ERRORMESSAGE is null and C.ERRORMESSAGE is not null) 
OR (I.ERRORMESSAGE is not null and C.ERRORMESSAGE is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
UNION ALL 
 select	5, 'DATESLOGIC', 0, 0, 0, count(*)
from CCImport_DATESLOGIC I 
join DATESLOGIC C	on( C.CRITERIANO=I.CRITERIANO
and C.EVENTNO=I.EVENTNO
and C.SEQUENCENO=I.SEQUENCENO)
where ( I.DATETYPE =  C.DATETYPE)
and ( I.OPERATOR =  C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is null))
and ( I.COMPAREEVENT =  C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is null))
and ( I.MUSTEXIST =  C.MUSTEXIST)
and ( I.RELATIVECYCLE =  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is null))
and ( I.COMPAREDATETYPE =  C.COMPAREDATETYPE)
and ( I.CASERELATIONSHIP =  C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is null))
and ( I.DISPLAYERRORFLAG =  C.DISPLAYERRORFLAG OR (I.DISPLAYERRORFLAG is null and C.DISPLAYERRORFLAG is null))
and (replace( I.ERRORMESSAGE,char(10),char(13)+char(10)) =  C.ERRORMESSAGE OR (I.ERRORMESSAGE is null and C.ERRORMESSAGE is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DATESLOGIC]') and xtype='U')
begin
	drop table CCImport_DATESLOGIC 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDATESLOGIC  to public
go
