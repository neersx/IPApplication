-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFIELDCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFIELDCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFIELDCONTROL.'
	drop function dbo.fn_ccnFIELDCONTROL
	print '**** Creating function dbo.fn_ccnFIELDCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FIELDCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_FIELDCONTROL 
	from FIELDCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnFIELDCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFIELDCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FIELDCONTROL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'FIELDCONTROL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FIELDCONTROL I 
	right join FIELDCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.SCREENNAME=I.SCREENNAME
and  C.SCREENID=I.SCREENID
and  C.FIELDNAME=I.FIELDNAME)
where I.CRITERIANO is null
UNION ALL 
select	5, 'FIELDCONTROL', 0, count(*), 0, 0
from CCImport_FIELDCONTROL I 
	left join FIELDCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.SCREENNAME=I.SCREENNAME
and  C.SCREENID=I.SCREENID
and  C.FIELDNAME=I.FIELDNAME)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'FIELDCONTROL', 0, 0, count(*), 0
from CCImport_FIELDCONTROL I 
	join FIELDCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
	and C.SCREENNAME=I.SCREENNAME
	and C.SCREENID=I.SCREENID
	and C.FIELDNAME=I.FIELDNAME)
where 	( I.ATTRIBUTES <>  C.ATTRIBUTES OR (I.ATTRIBUTES is null and C.ATTRIBUTES is not null) 
OR (I.ATTRIBUTES is not null and C.ATTRIBUTES is null))
	OR 	( I.FIELDLITERAL <>  C.FIELDLITERAL OR (I.FIELDLITERAL is null and C.FIELDLITERAL is not null) 
OR (I.FIELDLITERAL is not null and C.FIELDLITERAL is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
UNION ALL 
 select	5, 'FIELDCONTROL', 0, 0, 0, count(*)
from CCImport_FIELDCONTROL I 
join FIELDCONTROL C	on( C.CRITERIANO=I.CRITERIANO
and C.SCREENNAME=I.SCREENNAME
and C.SCREENID=I.SCREENID
and C.FIELDNAME=I.FIELDNAME)
where ( I.ATTRIBUTES =  C.ATTRIBUTES OR (I.ATTRIBUTES is null and C.ATTRIBUTES is null))
and ( I.FIELDLITERAL =  C.FIELDLITERAL OR (I.FIELDLITERAL is null and C.FIELDLITERAL is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FIELDCONTROL]') and xtype='U')
begin
	drop table CCImport_FIELDCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFIELDCONTROL  to public
go
