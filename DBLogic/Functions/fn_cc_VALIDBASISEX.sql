-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDBASISEX
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDBASISEX]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDBASISEX.'
	drop function dbo.fn_cc_VALIDBASISEX
	print '**** Creating function dbo.fn_cc_VALIDBASISEX...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDBASISEX]') and xtype='U')
begin
	select * 
	into CCImport_VALIDBASISEX 
	from VALIDBASISEX
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDBASISEX
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDBASISEX
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDBASISEX table
-- CALLED BY :	ip_CopyConfigVALIDBASISEX
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
	 null as 'Imported Casecategory',
	 null as 'Imported Casetype',
	 null as 'Imported Basis',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.CASECATEGORY as 'Casecategory',
	 C.CASETYPE as 'Casetype',
	 C.BASIS as 'Basis'
from CCImport_VALIDBASISEX I 
	right join VALIDBASISEX C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASECATEGORY=I.CASECATEGORY
and  C.CASETYPE=I.CASETYPE
and  C.BASIS=I.BASIS)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASECATEGORY,
	 I.CASETYPE,
	 I.BASIS,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDBASISEX I 
	left join VALIDBASISEX C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASECATEGORY=I.CASECATEGORY
and  C.CASETYPE=I.CASETYPE
and  C.BASIS=I.BASIS)
where C.COUNTRYCODE is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDBASISEX]') and xtype='U')
begin
	drop table CCImport_VALIDBASISEX 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDBASISEX  to public
go
