-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDSUBTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDSUBTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDSUBTYPE.'
	drop function dbo.fn_cc_VALIDSUBTYPE
	print '**** Creating function dbo.fn_cc_VALIDSUBTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDSUBTYPE]') and xtype='U')
begin
	select * 
	into CCImport_VALIDSUBTYPE 
	from VALIDSUBTYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDSUBTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDSUBTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDSUBTYPE table
-- CALLED BY :	ip_CopyConfigVALIDSUBTYPE
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
	 null as 'Imported Casecategory',
	 null as 'Imported Subtype',
	 null as 'Imported Subtypedesc',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.CASETYPE as 'Casetype',
	 C.CASECATEGORY as 'Casecategory',
	 C.SUBTYPE as 'Subtype',
	 C.SUBTYPEDESC as 'Subtypedesc'
from CCImport_VALIDSUBTYPE I 
	right join VALIDSUBTYPE C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY
and  C.SUBTYPE=I.SUBTYPE)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.SUBTYPE,
	 I.SUBTYPEDESC,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDSUBTYPE I 
	left join VALIDSUBTYPE C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY
and  C.SUBTYPE=I.SUBTYPE)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.SUBTYPE,
	 I.SUBTYPEDESC,
'U',
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.CASETYPE,
	 C.CASECATEGORY,
	 C.SUBTYPE,
	 C.SUBTYPEDESC
from CCImport_VALIDSUBTYPE I 
	join VALIDSUBTYPE C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.CASETYPE=I.CASETYPE
	and C.CASECATEGORY=I.CASECATEGORY
	and C.SUBTYPE=I.SUBTYPE)
where 	( I.SUBTYPEDESC <>  C.SUBTYPEDESC OR (I.SUBTYPEDESC is null and C.SUBTYPEDESC is not null) 
OR (I.SUBTYPEDESC is not null and C.SUBTYPEDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDSUBTYPE]') and xtype='U')
begin
	drop table CCImport_VALIDSUBTYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDSUBTYPE  to public
go
