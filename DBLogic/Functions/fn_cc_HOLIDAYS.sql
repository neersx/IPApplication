-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_HOLIDAYS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_HOLIDAYS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_HOLIDAYS.'
	drop function dbo.fn_cc_HOLIDAYS
	print '**** Creating function dbo.fn_cc_HOLIDAYS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_HOLIDAYS]') and xtype='U')
begin
	select * 
	into CCImport_HOLIDAYS 
	from HOLIDAYS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_HOLIDAYS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_HOLIDAYS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the HOLIDAYS table
-- CALLED BY :	ip_CopyConfigHOLIDAYS
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Countrycode',
	 null as 'Imported Holidaydate',
	 null as 'Imported Holidayname',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.HOLIDAYDATE as 'Holidaydate',
	 C.HOLIDAYNAME as 'Holidayname'
from CCImport_HOLIDAYS I 
	right join HOLIDAYS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.HOLIDAYDATE=I.HOLIDAYDATE)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.HOLIDAYDATE,
	 I.HOLIDAYNAME,
'I',
	 null ,
	 null ,
	 null
from CCImport_HOLIDAYS I 
	left join HOLIDAYS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.HOLIDAYDATE=I.HOLIDAYDATE)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.HOLIDAYDATE,
	 I.HOLIDAYNAME,
'U',
	 C.COUNTRYCODE,
	 C.HOLIDAYDATE,
	 C.HOLIDAYNAME
from CCImport_HOLIDAYS I 
	join HOLIDAYS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.HOLIDAYDATE=I.HOLIDAYDATE)
where 	( I.HOLIDAYNAME <>  C.HOLIDAYNAME OR (I.HOLIDAYNAME is null and C.HOLIDAYNAME is not null) 
OR (I.HOLIDAYNAME is not null and C.HOLIDAYNAME is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_HOLIDAYS]') and xtype='U')
begin
	drop table CCImport_HOLIDAYS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_HOLIDAYS  to public
go
