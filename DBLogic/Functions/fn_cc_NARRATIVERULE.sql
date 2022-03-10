-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_NARRATIVERULE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_NARRATIVERULE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_NARRATIVERULE.'
	drop function dbo.fn_cc_NARRATIVERULE
	print '**** Creating function dbo.fn_cc_NARRATIVERULE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NARRATIVERULE]') and xtype='U')
begin
	select * 
	into CCImport_NARRATIVERULE 
	from NARRATIVERULE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_NARRATIVERULE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_NARRATIVERULE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NARRATIVERULE table
-- CALLED BY :	ip_CopyConfigNARRATIVERULE
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
	 null as 'Imported Narrativeruleno',
	 null as 'Imported Narrativeno',
	 null as 'Imported Wipcode',
	 null as 'Imported Employeeno',
	 null as 'Imported Casetype',
	 null as 'Imported Propertytype',
	 null as 'Imported Casecategory',
	 null as 'Imported Subtype',
	 null as 'Imported Typeofmark',
	 null as 'Imported Countrycode',
	 null as 'Imported Localcountryflag',
	 null as 'Imported Foreigncountryflag',
	 null as 'Imported Debtorno',
'D' as '-',
	 C.NARRATIVERULENO as 'Narrativeruleno',
	 C.NARRATIVENO as 'Narrativeno',
	 C.WIPCODE as 'Wipcode',
	 C.EMPLOYEENO as 'Employeeno',
	 C.CASETYPE as 'Casetype',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.CASECATEGORY as 'Casecategory',
	 C.SUBTYPE as 'Subtype',
	 C.TYPEOFMARK as 'Typeofmark',
	 C.COUNTRYCODE as 'Countrycode',
	 C.LOCALCOUNTRYFLAG as 'Localcountryflag',
	 C.FOREIGNCOUNTRYFLAG as 'Foreigncountryflag',
	 C.DEBTORNO as 'Debtorno'
from CCImport_NARRATIVERULE I 
	right join NARRATIVERULE C on( C.NARRATIVERULENO=I.NARRATIVERULENO)
where I.NARRATIVERULENO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NARRATIVERULENO,
	 I.NARRATIVENO,
	 I.WIPCODE,
	 I.EMPLOYEENO,
	 I.CASETYPE,
	 I.PROPERTYTYPE,
	 I.CASECATEGORY,
	 I.SUBTYPE,
	 I.TYPEOFMARK,
	 I.COUNTRYCODE,
	 I.LOCALCOUNTRYFLAG,
	 I.FOREIGNCOUNTRYFLAG,
	 I.DEBTORNO,
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
	 null ,
	 null
from CCImport_NARRATIVERULE I 
	left join NARRATIVERULE C on( C.NARRATIVERULENO=I.NARRATIVERULENO)
where C.NARRATIVERULENO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.NARRATIVERULENO,
	 I.NARRATIVENO,
	 I.WIPCODE,
	 I.EMPLOYEENO,
	 I.CASETYPE,
	 I.PROPERTYTYPE,
	 I.CASECATEGORY,
	 I.SUBTYPE,
	 I.TYPEOFMARK,
	 I.COUNTRYCODE,
	 I.LOCALCOUNTRYFLAG,
	 I.FOREIGNCOUNTRYFLAG,
	 I.DEBTORNO,
'U',
	 C.NARRATIVERULENO,
	 C.NARRATIVENO,
	 C.WIPCODE,
	 C.EMPLOYEENO,
	 C.CASETYPE,
	 C.PROPERTYTYPE,
	 C.CASECATEGORY,
	 C.SUBTYPE,
	 C.TYPEOFMARK,
	 C.COUNTRYCODE,
	 C.LOCALCOUNTRYFLAG,
	 C.FOREIGNCOUNTRYFLAG,
	 C.DEBTORNO
from CCImport_NARRATIVERULE I 
	join NARRATIVERULE C	on ( C.NARRATIVERULENO=I.NARRATIVERULENO)
where 	( I.NARRATIVENO <>  C.NARRATIVENO)
	OR 	( I.WIPCODE <>  C.WIPCODE)
	OR 	( I.EMPLOYEENO <>  C.EMPLOYEENO OR (I.EMPLOYEENO is null and C.EMPLOYEENO is not null) 
OR (I.EMPLOYEENO is not null and C.EMPLOYEENO is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.CASECATEGORY <>  C.CASECATEGORY OR (I.CASECATEGORY is null and C.CASECATEGORY is not null) 
OR (I.CASECATEGORY is not null and C.CASECATEGORY is null))
	OR 	( I.SUBTYPE <>  C.SUBTYPE OR (I.SUBTYPE is null and C.SUBTYPE is not null) 
OR (I.SUBTYPE is not null and C.SUBTYPE is null))
	OR 	( I.TYPEOFMARK <>  C.TYPEOFMARK OR (I.TYPEOFMARK is null and C.TYPEOFMARK is not null) 
OR (I.TYPEOFMARK is not null and C.TYPEOFMARK is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.LOCALCOUNTRYFLAG <>  C.LOCALCOUNTRYFLAG OR (I.LOCALCOUNTRYFLAG is null and C.LOCALCOUNTRYFLAG is not null) 
OR (I.LOCALCOUNTRYFLAG is not null and C.LOCALCOUNTRYFLAG is null))
	OR 	( I.FOREIGNCOUNTRYFLAG <>  C.FOREIGNCOUNTRYFLAG OR (I.FOREIGNCOUNTRYFLAG is null and C.FOREIGNCOUNTRYFLAG is not null) 
OR (I.FOREIGNCOUNTRYFLAG is not null and C.FOREIGNCOUNTRYFLAG is null))
	OR 	( I.DEBTORNO <>  C.DEBTORNO OR (I.DEBTORNO is null and C.DEBTORNO is not null) 
OR (I.DEBTORNO is not null and C.DEBTORNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NARRATIVERULE]') and xtype='U')
begin
	drop table CCImport_NARRATIVERULE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_NARRATIVERULE  to public
go
