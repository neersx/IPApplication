-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnRELATEDEVENTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnRELATEDEVENTS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnRELATEDEVENTS.'
	drop function dbo.fn_ccnRELATEDEVENTS
	print '**** Creating function dbo.fn_ccnRELATEDEVENTS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RELATEDEVENTS]') and xtype='U')
begin
	select * 
	into CCImport_RELATEDEVENTS 
	from RELATEDEVENTS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnRELATEDEVENTS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnRELATEDEVENTS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RELATEDEVENTS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'RELATEDEVENTS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_RELATEDEVENTS I 
	right join RELATEDEVENTS C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.RELATEDNO=I.RELATEDNO)
where I.CRITERIANO is null
UNION ALL 
select	5, 'RELATEDEVENTS', 0, count(*), 0, 0
from CCImport_RELATEDEVENTS I 
	left join RELATEDEVENTS C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.RELATEDNO=I.RELATEDNO)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'RELATEDEVENTS', 0, 0, count(*), 0
from CCImport_RELATEDEVENTS I 
	join RELATEDEVENTS C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO
	and C.RELATEDNO=I.RELATEDNO)
where 	( I.RELATEDEVENT <>  C.RELATEDEVENT OR (I.RELATEDEVENT is null and C.RELATEDEVENT is not null) 
OR (I.RELATEDEVENT is not null and C.RELATEDEVENT is null))
	OR 	( I.CLEAREVENT <>  C.CLEAREVENT OR (I.CLEAREVENT is null and C.CLEAREVENT is not null) 
OR (I.CLEAREVENT is not null and C.CLEAREVENT is null))
	OR 	( I.CLEARDUE <>  C.CLEARDUE OR (I.CLEARDUE is null and C.CLEARDUE is not null) 
OR (I.CLEARDUE is not null and C.CLEARDUE is null))
	OR 	( I.SATISFYEVENT <>  C.SATISFYEVENT OR (I.SATISFYEVENT is null and C.SATISFYEVENT is not null) 
OR (I.SATISFYEVENT is not null and C.SATISFYEVENT is null))
	OR 	( I.UPDATEEVENT <>  C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null) 
OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null))
	OR 	( I.CREATENEXTCYCLE <>  C.CREATENEXTCYCLE OR (I.CREATENEXTCYCLE is null and C.CREATENEXTCYCLE is not null) 
OR (I.CREATENEXTCYCLE is not null and C.CREATENEXTCYCLE is null))
	OR 	( I.ADJUSTMENT <>  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) 
OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
	OR 	( I.RELATIVECYCLE <>  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) 
OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null))
	OR 	( I.CLEAREVENTONDUECHANGE <>  C.CLEAREVENTONDUECHANGE OR (I.CLEAREVENTONDUECHANGE is null and C.CLEAREVENTONDUECHANGE is not null) 
OR (I.CLEAREVENTONDUECHANGE is not null and C.CLEAREVENTONDUECHANGE is null))
	OR 	( I.CLEARDUEONDUECHANGE <>  C.CLEARDUEONDUECHANGE OR (I.CLEARDUEONDUECHANGE is null and C.CLEARDUEONDUECHANGE is not null) 
OR (I.CLEARDUEONDUECHANGE is not null and C.CLEARDUEONDUECHANGE is null))
UNION ALL 
 select	5, 'RELATEDEVENTS', 0, 0, 0, count(*)
from CCImport_RELATEDEVENTS I 
join RELATEDEVENTS C	on( C.CRITERIANO=I.CRITERIANO
and C.EVENTNO=I.EVENTNO
and C.RELATEDNO=I.RELATEDNO)
where ( I.RELATEDEVENT =  C.RELATEDEVENT OR (I.RELATEDEVENT is null and C.RELATEDEVENT is null))
and ( I.CLEAREVENT =  C.CLEAREVENT OR (I.CLEAREVENT is null and C.CLEAREVENT is null))
and ( I.CLEARDUE =  C.CLEARDUE OR (I.CLEARDUE is null and C.CLEARDUE is null))
and ( I.SATISFYEVENT =  C.SATISFYEVENT OR (I.SATISFYEVENT is null and C.SATISFYEVENT is null))
and ( I.UPDATEEVENT =  C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is null))
and ( I.CREATENEXTCYCLE =  C.CREATENEXTCYCLE OR (I.CREATENEXTCYCLE is null and C.CREATENEXTCYCLE is null))
and ( I.ADJUSTMENT =  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))
and ( I.RELATIVECYCLE =  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is null))
and ( I.CLEAREVENTONDUECHANGE =  C.CLEAREVENTONDUECHANGE OR (I.CLEAREVENTONDUECHANGE is null and C.CLEAREVENTONDUECHANGE is null))
and ( I.CLEARDUEONDUECHANGE =  C.CLEARDUEONDUECHANGE OR (I.CLEARDUEONDUECHANGE is null and C.CLEARDUEONDUECHANGE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RELATEDEVENTS]') and xtype='U')
begin
	drop table CCImport_RELATEDEVENTS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnRELATEDEVENTS  to public
go
