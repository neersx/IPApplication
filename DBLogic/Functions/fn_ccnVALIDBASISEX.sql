-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDBASISEX
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDBASISEX]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDBASISEX.'
	drop function dbo.fn_ccnVALIDBASISEX
	print '**** Creating function dbo.fn_ccnVALIDBASISEX...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDBASISEX]') and xtype='U')
begin
	select * 
	into CCImport_VALIDBASISEX 
	from VALIDBASISEX
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDBASISEX
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDBASISEX
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDBASISEX table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDBASISEX' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDBASISEX I 
	right join VALIDBASISEX C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASECATEGORY=I.CASECATEGORY
and  C.CASETYPE=I.CASETYPE
and  C.BASIS=I.BASIS)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDBASISEX', 0, count(*), 0, 0
from CCImport_VALIDBASISEX I 
	left join VALIDBASISEX C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASECATEGORY=I.CASECATEGORY
and  C.CASETYPE=I.CASETYPE
and  C.BASIS=I.BASIS)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDBASISEX', 0, 0, 0, count(*)
from CCImport_VALIDBASISEX I 
join VALIDBASISEX C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.CASECATEGORY=I.CASECATEGORY
and C.CASETYPE=I.CASETYPE
and C.BASIS=I.BASIS)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDBASISEX]') and xtype='U')
begin
	drop table CCImport_VALIDBASISEX 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDBASISEX  to public
go

