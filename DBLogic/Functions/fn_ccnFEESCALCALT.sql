-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFEESCALCALT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFEESCALCALT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFEESCALCALT.'
	drop function dbo.fn_ccnFEESCALCALT
	print '**** Creating function dbo.fn_ccnFEESCALCALT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEESCALCALT]') and xtype='U')
begin
	select * 
	into CCImport_FEESCALCALT 
	from FEESCALCALT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnFEESCALCALT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFEESCALCALT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEESCALCALT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'FEESCALCALT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FEESCALCALT I 
	right join FEESCALCALT C on( C.CRITERIANO=I.CRITERIANO
and  C.UNIQUEID=I.UNIQUEID
and  C.COMPONENTTYPE=I.COMPONENTTYPE
and  C.SUPPLEMENTNO=I.SUPPLEMENTNO
and  C.PROCEDURENAME=I.PROCEDURENAME)
where I.CRITERIANO is null
UNION ALL 
select	5, 'FEESCALCALT', 0, count(*), 0, 0
from CCImport_FEESCALCALT I 
	left join FEESCALCALT C on( C.CRITERIANO=I.CRITERIANO
and  C.UNIQUEID=I.UNIQUEID
and  C.COMPONENTTYPE=I.COMPONENTTYPE
and  C.SUPPLEMENTNO=I.SUPPLEMENTNO
and  C.PROCEDURENAME=I.PROCEDURENAME)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'FEESCALCALT', 0, 0, count(*), 0
from CCImport_FEESCALCALT I 
	join FEESCALCALT C	on ( C.CRITERIANO=I.CRITERIANO
	and C.UNIQUEID=I.UNIQUEID
	and C.COMPONENTTYPE=I.COMPONENTTYPE
	and C.SUPPLEMENTNO=I.SUPPLEMENTNO
	and C.PROCEDURENAME=I.PROCEDURENAME)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.SUPPNUMERICVALUE <>  C.SUPPNUMERICVALUE OR (I.SUPPNUMERICVALUE is null and C.SUPPNUMERICVALUE is not null) 
OR (I.SUPPNUMERICVALUE is not null and C.SUPPNUMERICVALUE is null))
UNION ALL 
 select	5, 'FEESCALCALT', 0, 0, 0, count(*)
from CCImport_FEESCALCALT I 
join FEESCALCALT C	on( C.CRITERIANO=I.CRITERIANO
and C.UNIQUEID=I.UNIQUEID
and C.COMPONENTTYPE=I.COMPONENTTYPE
and C.SUPPLEMENTNO=I.SUPPLEMENTNO
and C.PROCEDURENAME=I.PROCEDURENAME)
where ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.SUPPNUMERICVALUE =  C.SUPPNUMERICVALUE OR (I.SUPPNUMERICVALUE is null and C.SUPPNUMERICVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEESCALCALT]') and xtype='U')
begin
	drop table CCImport_FEESCALCALT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFEESCALCALT  to public
go
