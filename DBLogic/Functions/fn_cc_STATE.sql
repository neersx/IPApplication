-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_STATE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_STATE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_STATE.'
	drop function dbo.fn_cc_STATE
	print '**** Creating function dbo.fn_cc_STATE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_STATE]') and xtype='U')
begin
	select * 
	into CCImport_STATE 
	from STATE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_STATE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_STATE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the STATE table
-- CALLED BY :	ip_CopyConfigSTATE
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
	 null as 'Imported State',
	 null as 'Imported Statename',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.STATE as 'State',
	 C.STATENAME as 'Statename'
from CCImport_STATE I 
	right join STATE C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.STATE=I.STATE)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.STATE,
	 I.STATENAME,
'I',
	 null ,
	 null ,
	 null
from CCImport_STATE I 
	left join STATE C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.STATE=I.STATE)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.STATE,
	 I.STATENAME,
'U',
	 C.COUNTRYCODE,
	 C.STATE,
	 C.STATENAME
from CCImport_STATE I 
	join STATE C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.STATE=I.STATE)
where 	( I.STATENAME <>  C.STATENAME OR (I.STATENAME is null and C.STATENAME is not null) 
OR (I.STATENAME is not null and C.STATENAME is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_STATE]') and xtype='U')
begin
	drop table CCImport_STATE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_STATE  to public
go
