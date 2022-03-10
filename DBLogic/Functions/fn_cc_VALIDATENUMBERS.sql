-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDATENUMBERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDATENUMBERS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDATENUMBERS.'
	drop function dbo.fn_cc_VALIDATENUMBERS
	print '**** Creating function dbo.fn_cc_VALIDATENUMBERS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDATENUMBERS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDATENUMBERS 
	from VALIDATENUMBERS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDATENUMBERS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDATENUMBERS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDATENUMBERS table
-- CALLED BY :	ip_CopyConfigVALIDATENUMBERS
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
	 null as 'Imported Validationid',
	 null as 'Imported Countrycode',
	 null as 'Imported Propertytype',
	 null as 'Imported Numbertype',
	 null as 'Imported Validfrom',
	 null as 'Imported Pattern',
	 null as 'Imported Warningflag',
	 null as 'Imported Errormessage',
	 null as 'Imported Validatingspid',
	 null as 'Imported Casetype',
	 null as 'Imported Casecategory',
	 null as 'Imported Subtype',
'D' as '-',
	 C.VALIDATIONID as 'Validationid',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.NUMBERTYPE as 'Numbertype',
	 C.VALIDFROM as 'Validfrom',
	 C.PATTERN as 'Pattern',
	 C.WARNINGFLAG as 'Warningflag',
	 C.ERRORMESSAGE as 'Errormessage',
	 C.VALIDATINGSPID as 'Validatingspid',
	 C.CASETYPE as 'Casetype',
	 C.CASECATEGORY as 'Casecategory',
	 C.SUBTYPE as 'Subtype'
from CCImport_VALIDATENUMBERS I 
	right join VALIDATENUMBERS C on( C.VALIDATIONID=I.VALIDATIONID)
where I.VALIDATIONID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.VALIDATIONID,
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.NUMBERTYPE,
	 I.VALIDFROM,
	 I.PATTERN,
	 I.WARNINGFLAG,
	 I.ERRORMESSAGE,
	 I.VALIDATINGSPID,
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.SUBTYPE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDATENUMBERS I 
	left join VALIDATENUMBERS C on( C.VALIDATIONID=I.VALIDATIONID)
where C.VALIDATIONID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.VALIDATIONID,
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.NUMBERTYPE,
	 I.VALIDFROM,
	 I.PATTERN,
	 I.WARNINGFLAG,
	 I.ERRORMESSAGE,
	 I.VALIDATINGSPID,
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.SUBTYPE,
'U',
	 C.VALIDATIONID,
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.NUMBERTYPE,
	 C.VALIDFROM,
	 C.PATTERN,
	 C.WARNINGFLAG,
	 C.ERRORMESSAGE,
	 C.VALIDATINGSPID,
	 C.CASETYPE,
	 C.CASECATEGORY,
	 C.SUBTYPE
from CCImport_VALIDATENUMBERS I 
	join VALIDATENUMBERS C	on ( C.VALIDATIONID=I.VALIDATIONID)
where 	( I.COUNTRYCODE <>  C.COUNTRYCODE)
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE)
	OR 	( I.NUMBERTYPE <>  C.NUMBERTYPE)
	OR 	( I.VALIDFROM <>  C.VALIDFROM OR (I.VALIDFROM is null and C.VALIDFROM is not null) 
OR (I.VALIDFROM is not null and C.VALIDFROM is null))
	OR 	(replace( I.PATTERN,char(10),char(13)+char(10)) <>  C.PATTERN)
	OR 	( I.WARNINGFLAG <>  C.WARNINGFLAG)
	OR 	(replace( I.ERRORMESSAGE,char(10),char(13)+char(10)) <>  C.ERRORMESSAGE)
	OR 	( I.VALIDATINGSPID <>  C.VALIDATINGSPID OR (I.VALIDATINGSPID is null and C.VALIDATINGSPID is not null) 
OR (I.VALIDATINGSPID is not null and C.VALIDATINGSPID is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDATENUMBERS]') and xtype='U')
begin
	drop table CCImport_VALIDATENUMBERS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDATENUMBERS  to public
go
