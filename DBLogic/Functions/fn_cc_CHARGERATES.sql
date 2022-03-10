-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CHARGERATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CHARGERATES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CHARGERATES.'
	drop function dbo.fn_cc_CHARGERATES
	print '**** Creating function dbo.fn_cc_CHARGERATES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CHARGERATES]') and xtype='U')
begin
	select * 
	into CCImport_CHARGERATES 
	from CHARGERATES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CHARGERATES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CHARGERATES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CHARGERATES table
-- CALLED BY :	ip_CopyConfigCHARGERATES
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
	 null as 'Imported Chargetypeno',
	 null as 'Imported Rateno',
	 null as 'Imported Casetype',
	 null as 'Imported Casecategory',
	 null as 'Imported Propertytype',
	 null as 'Imported Countrycode',
	 null as 'Imported Subtype',
	 null as 'Imported Instructiontype',
	 null as 'Imported Flagnumber',
'D' as '-',
	 C.CHARGETYPENO as 'Chargetypeno',
	 C.RATENO as 'Rateno',
	 C.CASETYPE as 'Casetype',
	 C.CASECATEGORY as 'Casecategory',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.COUNTRYCODE as 'Countrycode',
	 C.SUBTYPE as 'Subtype',
	 C.INSTRUCTIONTYPE as 'Instructiontype',
	 C.FLAGNUMBER as 'Flagnumber'
from CCImport_CHARGERATES I 
	right join CHARGERATES C on( C.CHARGETYPENO=I.CHARGETYPENO
and  C.RATENO=I.RATENO
and  C.SEQUENCENO=I.SEQUENCENO)
where I.CHARGETYPENO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CHARGETYPENO,
	 I.RATENO,
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.PROPERTYTYPE,
	 I.COUNTRYCODE,
	 I.SUBTYPE,
	 I.INSTRUCTIONTYPE,
	 I.FLAGNUMBER,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_CHARGERATES I 
	left join CHARGERATES C on( C.CHARGETYPENO=I.CHARGETYPENO
and  C.RATENO=I.RATENO
and  C.SEQUENCENO=I.SEQUENCENO)
where C.CHARGETYPENO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CHARGETYPENO,
	 I.RATENO,
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.PROPERTYTYPE,
	 I.COUNTRYCODE,
	 I.SUBTYPE,
	 I.INSTRUCTIONTYPE,
	 I.FLAGNUMBER,
'U',
	 C.CHARGETYPENO,
	 C.RATENO,
	 C.CASETYPE,
	 C.CASECATEGORY,
	 C.PROPERTYTYPE,
	 C.COUNTRYCODE,
	 C.SUBTYPE,
	 C.INSTRUCTIONTYPE,
	 C.FLAGNUMBER
from CCImport_CHARGERATES I 
	join CHARGERATES C	on ( C.CHARGETYPENO=I.CHARGETYPENO
	and C.RATENO=I.RATENO
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))
	OR 	( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null) 
OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
	OR 	( I.FLAGNUMBER <>  C.FLAGNUMBER OR (I.FLAGNUMBER is null and C.FLAGNUMBER is not null) 
OR (I.FLAGNUMBER is not null and C.FLAGNUMBER is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CHARGERATES]') and xtype='U')
begin
	drop table CCImport_CHARGERATES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CHARGERATES  to public
go
