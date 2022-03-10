-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSTATE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSTATE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSTATE.'
	drop function dbo.fn_ccnSTATE
	print '**** Creating function dbo.fn_ccnSTATE...'
	print ''
end
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_STATE]') and xtype='U')
begin
	select * 
	into CCImport_STATE 
	from STATE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSTATE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSTATE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the STATE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'STATE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_STATE I 
	right join STATE C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.STATE=I.STATE)
where I.COUNTRYCODE is null
UNION ALL 
select	4, 'STATE', 0, count(*), 0, 0
from CCImport_STATE I 
	left join STATE C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.STATE=I.STATE)
where C.COUNTRYCODE is null
UNION ALL 
 select	4, 'STATE', 0, 0, count(*), 0
from CCImport_STATE I 
	join STATE C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.STATE=I.STATE)
where 	( I.STATENAME <>  C.STATENAME OR (I.STATENAME is null and C.STATENAME is not null) 
OR (I.STATENAME is not null and C.STATENAME is null))
UNION ALL 
 select	4, 'STATE', 0, 0, 0, count(*)
from CCImport_STATE I 
join STATE C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.STATE=I.STATE)
where ( I.STATENAME =  C.STATENAME OR (I.STATENAME is null and C.STATENAME is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_STATE]') and xtype='U')
begin
	drop table CCImport_STATE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSTATE  to public
go
