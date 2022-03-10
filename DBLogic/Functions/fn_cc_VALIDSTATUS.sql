-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDSTATUS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDSTATUS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDSTATUS.'
	drop function dbo.fn_cc_VALIDSTATUS
	print '**** Creating function dbo.fn_cc_VALIDSTATUS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDSTATUS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDSTATUS 
	from VALIDSTATUS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDSTATUS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDSTATUS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDSTATUS table
-- CALLED BY :	ip_CopyConfigVALIDSTATUS
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
	 null as 'Imported Propertytype',
	 null as 'Imported Casetype',
	 null as 'Imported Statuscode',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.CASETYPE as 'Casetype',
	 C.STATUSCODE as 'Statuscode'
from CCImport_VALIDSTATUS I 
	right join VALIDSTATUS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.STATUSCODE=I.STATUSCODE)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASETYPE,
	 I.STATUSCODE,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDSTATUS I 
	left join VALIDSTATUS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.STATUSCODE=I.STATUSCODE)
where C.COUNTRYCODE is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDSTATUS]') and xtype='U')
begin
	drop table CCImport_VALIDSTATUS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDSTATUS  to public
go
