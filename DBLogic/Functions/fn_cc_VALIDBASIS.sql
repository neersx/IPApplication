-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDBASIS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDBASIS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDBASIS.'
	drop function dbo.fn_cc_VALIDBASIS
	print '**** Creating function dbo.fn_cc_VALIDBASIS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDBASIS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDBASIS 
	from VALIDBASIS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDBASIS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDBASIS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDBASIS table
-- CALLED BY :	ip_CopyConfigVALIDBASIS
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
	 null as 'Imported Basis',
	 null as 'Imported Basisdescription',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.BASIS as 'Basis',
	 C.BASISDESCRIPTION as 'Basisdescription'
from CCImport_VALIDBASIS I 
	right join VALIDBASIS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.BASIS=I.BASIS)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.BASIS,
	 I.BASISDESCRIPTION,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDBASIS I 
	left join VALIDBASIS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.BASIS=I.BASIS)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.BASIS,
	 I.BASISDESCRIPTION,
'U',
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.BASIS,
	 C.BASISDESCRIPTION
from CCImport_VALIDBASIS I 
	join VALIDBASIS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.BASIS=I.BASIS)
where 	( I.BASISDESCRIPTION <>  C.BASISDESCRIPTION OR (I.BASISDESCRIPTION is null and C.BASISDESCRIPTION is not null) 
OR (I.BASISDESCRIPTION is not null and C.BASISDESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDBASIS]') and xtype='U')
begin
	drop table CCImport_VALIDBASIS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDBASIS  to public
go
