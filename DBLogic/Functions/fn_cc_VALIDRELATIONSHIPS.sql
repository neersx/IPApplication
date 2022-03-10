-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDRELATIONSHIPS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDRELATIONSHIPS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDRELATIONSHIPS.'
	drop function dbo.fn_cc_VALIDRELATIONSHIPS
	print '**** Creating function dbo.fn_cc_VALIDRELATIONSHIPS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDRELATIONSHIPS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDRELATIONSHIPS 
	from VALIDRELATIONSHIPS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDRELATIONSHIPS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDRELATIONSHIPS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDRELATIONSHIPS table
-- CALLED BY :	ip_CopyConfigVALIDRELATIONSHIPS
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
	 null as 'Imported Relationship',
	 null as 'Imported Reciprelationship',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.RELATIONSHIP as 'Relationship',
	 C.RECIPRELATIONSHIP as 'Reciprelationship'
from CCImport_VALIDRELATIONSHIPS I 
	right join VALIDRELATIONSHIPS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.RELATIONSHIP=I.RELATIONSHIP)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.RELATIONSHIP,
	 I.RECIPRELATIONSHIP,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDRELATIONSHIPS I 
	left join VALIDRELATIONSHIPS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.RELATIONSHIP=I.RELATIONSHIP)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.RELATIONSHIP,
	 I.RECIPRELATIONSHIP,
'U',
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.RELATIONSHIP,
	 C.RECIPRELATIONSHIP
from CCImport_VALIDRELATIONSHIPS I 
	join VALIDRELATIONSHIPS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.RELATIONSHIP=I.RELATIONSHIP)
where 	( I.RECIPRELATIONSHIP <>  C.RECIPRELATIONSHIP OR (I.RECIPRELATIONSHIP is null and C.RECIPRELATIONSHIP is not null) 
OR (I.RECIPRELATIONSHIP is not null and C.RECIPRELATIONSHIP is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDRELATIONSHIPS]') and xtype='U')
begin
	drop table CCImport_VALIDRELATIONSHIPS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDRELATIONSHIPS  to public
go
