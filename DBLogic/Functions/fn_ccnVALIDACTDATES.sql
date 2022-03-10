-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDACTDATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDACTDATES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDACTDATES.'
	drop function dbo.fn_ccnVALIDACTDATES
	print '**** Creating function dbo.fn_ccnVALIDACTDATES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDACTDATES]') and xtype='U')
begin
	select * 
	into CCImport_VALIDACTDATES 
	from VALIDACTDATES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDACTDATES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDACTDATES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDACTDATES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDACTDATES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDACTDATES I 
	right join VALIDACTDATES C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.DATEOFACT=I.DATEOFACT
and  C.SEQUENCENO=I.SEQUENCENO)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDACTDATES', 0, count(*), 0, 0
from CCImport_VALIDACTDATES I 
	left join VALIDACTDATES C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.DATEOFACT=I.DATEOFACT
and  C.SEQUENCENO=I.SEQUENCENO)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDACTDATES', 0, 0, count(*), 0
from CCImport_VALIDACTDATES I 
	join VALIDACTDATES C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.DATEOFACT=I.DATEOFACT
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.RETROSPECTIVEACTIO <>  C.RETROSPECTIVEACTIO OR (I.RETROSPECTIVEACTIO is null and C.RETROSPECTIVEACTIO is not null) 
OR (I.RETROSPECTIVEACTIO is not null and C.RETROSPECTIVEACTIO is null))
	OR 	( I.ACTEVENTNO <>  C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is not null) 
OR (I.ACTEVENTNO is not null and C.ACTEVENTNO is null))
	OR 	( I.RETROEVENTNO <>  C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) 
OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null))
UNION ALL 
 select	3, 'VALIDACTDATES', 0, 0, 0, count(*)
from CCImport_VALIDACTDATES I 
join VALIDACTDATES C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.DATEOFACT=I.DATEOFACT
and C.SEQUENCENO=I.SEQUENCENO)
where ( I.RETROSPECTIVEACTIO =  C.RETROSPECTIVEACTIO OR (I.RETROSPECTIVEACTIO is null and C.RETROSPECTIVEACTIO is null))
and ( I.ACTEVENTNO =  C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is null))
and ( I.RETROEVENTNO =  C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDACTDATES]') and xtype='U')
begin
	drop table CCImport_VALIDACTDATES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDACTDATES  to public
go
