-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDETAILLETTERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDETAILLETTERS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDETAILLETTERS.'
	drop function dbo.fn_ccnDETAILLETTERS
	print '**** Creating function dbo.fn_ccnDETAILLETTERS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DETAILLETTERS]') and xtype='U')
begin
	select * 
	into CCImport_DETAILLETTERS 
	from DETAILLETTERS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDETAILLETTERS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDETAILLETTERS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DETAILLETTERS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'DETAILLETTERS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DETAILLETTERS I 
	right join DETAILLETTERS C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER
and  C.LETTERNO=I.LETTERNO)
where I.CRITERIANO is null
UNION ALL 
select	5, 'DETAILLETTERS', 0, count(*), 0, 0
from CCImport_DETAILLETTERS I 
	left join DETAILLETTERS C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER
and  C.LETTERNO=I.LETTERNO)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'DETAILLETTERS', 0, 0, count(*), 0
from CCImport_DETAILLETTERS I 
	join DETAILLETTERS C	on ( C.CRITERIANO=I.CRITERIANO
	and C.ENTRYNUMBER=I.ENTRYNUMBER
	and C.LETTERNO=I.LETTERNO)
where 	( I.MANDATORYFLAG <>  C.MANDATORYFLAG OR (I.MANDATORYFLAG is null and C.MANDATORYFLAG is not null) 
OR (I.MANDATORYFLAG is not null and C.MANDATORYFLAG is null))
	OR 	( I.DELIVERYMETHODFLAG <>  C.DELIVERYMETHODFLAG OR (I.DELIVERYMETHODFLAG is null and C.DELIVERYMETHODFLAG is not null) 
OR (I.DELIVERYMETHODFLAG is not null and C.DELIVERYMETHODFLAG is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
UNION ALL 
 select	5, 'DETAILLETTERS', 0, 0, 0, count(*)
from CCImport_DETAILLETTERS I 
join DETAILLETTERS C	on( C.CRITERIANO=I.CRITERIANO
and C.ENTRYNUMBER=I.ENTRYNUMBER
and C.LETTERNO=I.LETTERNO)
where ( I.MANDATORYFLAG =  C.MANDATORYFLAG OR (I.MANDATORYFLAG is null and C.MANDATORYFLAG is null))
and ( I.DELIVERYMETHODFLAG =  C.DELIVERYMETHODFLAG OR (I.DELIVERYMETHODFLAG is null and C.DELIVERYMETHODFLAG is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DETAILLETTERS]') and xtype='U')
begin
	drop table CCImport_DETAILLETTERS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDETAILLETTERS  to public
go
