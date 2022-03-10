-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDPROPERTY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDPROPERTY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDPROPERTY.'
	drop function dbo.fn_ccnVALIDPROPERTY
	print '**** Creating function dbo.fn_ccnVALIDPROPERTY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDPROPERTY]') and xtype='U')
begin
	select * 
	into CCImport_VALIDPROPERTY 
	from VALIDPROPERTY
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDPROPERTY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDPROPERTY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDPROPERTY table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDPROPERTY' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDPROPERTY I 
	right join VALIDPROPERTY C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDPROPERTY', 0, count(*), 0, 0
from CCImport_VALIDPROPERTY I 
	left join VALIDPROPERTY C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDPROPERTY', 0, 0, count(*), 0
from CCImport_VALIDPROPERTY I 
	join VALIDPROPERTY C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE)
where 	( I.PROPERTYNAME <>  C.PROPERTYNAME OR (I.PROPERTYNAME is null and C.PROPERTYNAME is not null) 
OR (I.PROPERTYNAME is not null and C.PROPERTYNAME is null))
	OR 	( I.OFFSET <>  C.OFFSET OR (I.OFFSET is null and C.OFFSET is not null) 
OR (I.OFFSET is not null and C.OFFSET is null))
	OR 	( I.CYCLEOFFSET <>  C.CYCLEOFFSET OR (I.CYCLEOFFSET is null and C.CYCLEOFFSET is not null) 
OR (I.CYCLEOFFSET is not null and C.CYCLEOFFSET is null))
	OR 	( I.ANNUITYTYPE <>  C.ANNUITYTYPE OR (I.ANNUITYTYPE is null and C.ANNUITYTYPE is not null) 
OR (I.ANNUITYTYPE is not null and C.ANNUITYTYPE is null))
UNION ALL 
 select	3, 'VALIDPROPERTY', 0, 0, 0, count(*)
from CCImport_VALIDPROPERTY I 
join VALIDPROPERTY C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE)
where ( I.PROPERTYNAME =  C.PROPERTYNAME OR (I.PROPERTYNAME is null and C.PROPERTYNAME is null))
and ( I.OFFSET =  C.OFFSET OR (I.OFFSET is null and C.OFFSET is null))
and ( I.CYCLEOFFSET =  C.CYCLEOFFSET OR (I.CYCLEOFFSET is null and C.CYCLEOFFSET is null))
and ( I.ANNUITYTYPE =  C.ANNUITYTYPE OR (I.ANNUITYTYPE is null and C.ANNUITYTYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDPROPERTY]') and xtype='U')
begin
	drop table CCImport_VALIDPROPERTY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDPROPERTY  to public
go
