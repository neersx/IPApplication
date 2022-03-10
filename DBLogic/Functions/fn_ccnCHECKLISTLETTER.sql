-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCHECKLISTLETTER
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCHECKLISTLETTER]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCHECKLISTLETTER.'
	drop function dbo.fn_ccnCHECKLISTLETTER
	print '**** Creating function dbo.fn_ccnCHECKLISTLETTER...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CHECKLISTLETTER]') and xtype='U')
begin
	select * 
	into CCImport_CHECKLISTLETTER 
	from CHECKLISTLETTER
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCHECKLISTLETTER
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCHECKLISTLETTER
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CHECKLISTLETTER table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'CHECKLISTLETTER' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CHECKLISTLETTER I 
	right join CHECKLISTLETTER C on( C.CRITERIANO=I.CRITERIANO
and  C.LETTERNO=I.LETTERNO)
where I.CRITERIANO is null
UNION ALL 
select	5, 'CHECKLISTLETTER', 0, count(*), 0, 0
from CCImport_CHECKLISTLETTER I 
	left join CHECKLISTLETTER C on( C.CRITERIANO=I.CRITERIANO
and  C.LETTERNO=I.LETTERNO)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'CHECKLISTLETTER', 0, 0, count(*), 0
from CCImport_CHECKLISTLETTER I 
	join CHECKLISTLETTER C	on ( C.CRITERIANO=I.CRITERIANO
	and C.LETTERNO=I.LETTERNO)
where 	( I.QUESTIONNO <>  C.QUESTIONNO OR (I.QUESTIONNO is null and C.QUESTIONNO is not null) 
OR (I.QUESTIONNO is not null and C.QUESTIONNO is null))
	OR 	( I.REQUIREDANSWER <>  C.REQUIREDANSWER OR (I.REQUIREDANSWER is null and C.REQUIREDANSWER is not null) 
OR (I.REQUIREDANSWER is not null and C.REQUIREDANSWER is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
UNION ALL 
 select	5, 'CHECKLISTLETTER', 0, 0, 0, count(*)
from CCImport_CHECKLISTLETTER I 
join CHECKLISTLETTER C	on( C.CRITERIANO=I.CRITERIANO
and C.LETTERNO=I.LETTERNO)
where ( I.QUESTIONNO =  C.QUESTIONNO OR (I.QUESTIONNO is null and C.QUESTIONNO is null))
and ( I.REQUIREDANSWER =  C.REQUIREDANSWER OR (I.REQUIREDANSWER is null and C.REQUIREDANSWER is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CHECKLISTLETTER]') and xtype='U')
begin
	drop table CCImport_CHECKLISTLETTER 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCHECKLISTLETTER  to public
go
