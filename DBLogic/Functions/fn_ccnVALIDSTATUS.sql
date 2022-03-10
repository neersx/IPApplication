-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDSTATUS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDSTATUS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDSTATUS.'
	drop function dbo.fn_ccnVALIDSTATUS
	print '**** Creating function dbo.fn_ccnVALIDSTATUS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDSTATUS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDSTATUS 
	from VALIDSTATUS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDSTATUS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDSTATUS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDSTATUS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDSTATUS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDSTATUS I 
	right join VALIDSTATUS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.STATUSCODE=I.STATUSCODE)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDSTATUS', 0, count(*), 0, 0
from CCImport_VALIDSTATUS I 
	left join VALIDSTATUS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.STATUSCODE=I.STATUSCODE)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDSTATUS', 0, 0, 0, count(*)
from CCImport_VALIDSTATUS I 
join VALIDSTATUS C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.CASETYPE=I.CASETYPE
and C.STATUSCODE=I.STATUSCODE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDSTATUS]') and xtype='U')
begin
	drop table CCImport_VALIDSTATUS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDSTATUS  to public
go
