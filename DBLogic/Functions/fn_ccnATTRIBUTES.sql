-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnATTRIBUTES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnATTRIBUTES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnATTRIBUTES.'
	drop function dbo.fn_ccnATTRIBUTES
	print '**** Creating function dbo.fn_ccnATTRIBUTES...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ATTRIBUTES]') and xtype='U')
begin
	select * 
	into CCImport_ATTRIBUTES 
	from ATTRIBUTES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnATTRIBUTES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnATTRIBUTES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ATTRIBUTES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'ATTRIBUTES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ATTRIBUTES I 
	right join ATTRIBUTES C on( C.ATTRIBUTEID=I.ATTRIBUTEID)
where I.ATTRIBUTEID is null
UNION ALL 
select	6, 'ATTRIBUTES', 0, count(*), 0, 0
from CCImport_ATTRIBUTES I 
	left join ATTRIBUTES C on( C.ATTRIBUTEID=I.ATTRIBUTEID)
where C.ATTRIBUTEID is null
UNION ALL 
 select	6, 'ATTRIBUTES', 0, 0, count(*), 0
from CCImport_ATTRIBUTES I 
	join ATTRIBUTES C	on ( C.ATTRIBUTEID=I.ATTRIBUTEID)
where 	( I.ATTRIBUTENAME <>  C.ATTRIBUTENAME)
	OR 	( I.DATATYPE <>  C.DATATYPE)
	OR 	( I.TABLENAME <>  C.TABLENAME OR (I.TABLENAME is null and C.TABLENAME is not null) 
OR (I.TABLENAME is not null and C.TABLENAME is null))
	OR 	(replace( I.FILTERVALUE,char(10),char(13)+char(10)) <>  C.FILTERVALUE OR (I.FILTERVALUE is null and C.FILTERVALUE is not null) 
OR (I.FILTERVALUE is not null and C.FILTERVALUE is null))
UNION ALL 
 select	6, 'ATTRIBUTES', 0, 0, 0, count(*)
from CCImport_ATTRIBUTES I 
join ATTRIBUTES C	on( C.ATTRIBUTEID=I.ATTRIBUTEID)
where ( I.ATTRIBUTENAME =  C.ATTRIBUTENAME)
and ( I.DATATYPE =  C.DATATYPE)
and ( I.TABLENAME =  C.TABLENAME OR (I.TABLENAME is null and C.TABLENAME is null))
and (replace( I.FILTERVALUE,char(10),char(13)+char(10)) =  C.FILTERVALUE OR (I.FILTERVALUE is null and C.FILTERVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ATTRIBUTES]') and xtype='U')
begin
	drop table CCImport_ATTRIBUTES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnATTRIBUTES  to public
go

