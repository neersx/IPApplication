-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnHOLIDAYS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnHOLIDAYS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnHOLIDAYS.'
	drop function dbo.fn_ccnHOLIDAYS
	print '**** Creating function dbo.fn_ccnHOLIDAYS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_HOLIDAYS]') and xtype='U')
begin
	select * 
	into CCImport_HOLIDAYS 
	from HOLIDAYS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnHOLIDAYS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnHOLIDAYS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the HOLIDAYS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'HOLIDAYS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_HOLIDAYS I 
	right join HOLIDAYS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.HOLIDAYDATE=I.HOLIDAYDATE)
where I.COUNTRYCODE is null
UNION ALL 
select	4, 'HOLIDAYS', 0, count(*), 0, 0
from CCImport_HOLIDAYS I 
	left join HOLIDAYS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.HOLIDAYDATE=I.HOLIDAYDATE)
where C.COUNTRYCODE is null
UNION ALL 
 select	4, 'HOLIDAYS', 0, 0, count(*), 0
from CCImport_HOLIDAYS I 
	join HOLIDAYS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.HOLIDAYDATE=I.HOLIDAYDATE)
where 	( I.HOLIDAYNAME <>  C.HOLIDAYNAME OR (I.HOLIDAYNAME is null and C.HOLIDAYNAME is not null) 
OR (I.HOLIDAYNAME is not null and C.HOLIDAYNAME is null))
UNION ALL 
 select	4, 'HOLIDAYS', 0, 0, 0, count(*)
from CCImport_HOLIDAYS I 
join HOLIDAYS C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.HOLIDAYDATE=I.HOLIDAYDATE)
where ( I.HOLIDAYNAME =  C.HOLIDAYNAME OR (I.HOLIDAYNAME is null and C.HOLIDAYNAME is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_HOLIDAYS]') and xtype='U')
begin
	drop table CCImport_HOLIDAYS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnHOLIDAYS  to public
go
