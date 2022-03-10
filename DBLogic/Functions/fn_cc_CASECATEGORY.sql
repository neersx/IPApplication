-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CASECATEGORY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CASECATEGORY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CASECATEGORY.'
	drop function dbo.fn_cc_CASECATEGORY
	print '**** Creating function dbo.fn_cc_CASECATEGORY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CASECATEGORY]') and xtype='U')
begin
	select * 
	into CCImport_CASECATEGORY 
	from CASECATEGORY
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CASECATEGORY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CASECATEGORY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CASECATEGORY table
-- CALLED BY :	ip_CopyConfigCASECATEGORY
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
	 null as 'Imported Casetype',
	 null as 'Imported Casecategory',
	 null as 'Imported Casecategorydesc',
	 null as 'Imported Conventionliteral',
'D' as '-',
	 C.CASETYPE as 'Casetype',
	 C.CASECATEGORY as 'Casecategory',
	 C.CASECATEGORYDESC as 'Casecategorydesc',
	 C.CONVENTIONLITERAL as 'Conventionliteral'
from CCImport_CASECATEGORY I 
	right join CASECATEGORY C on( C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY)
where I.CASETYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.CASECATEGORYDESC,
	 I.CONVENTIONLITERAL,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_CASECATEGORY I 
	left join CASECATEGORY C on( C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY)
where C.CASETYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CASETYPE,
	 I.CASECATEGORY,
	 I.CASECATEGORYDESC,
	 I.CONVENTIONLITERAL,
'U',
	 C.CASETYPE,
	 C.CASECATEGORY,
	 C.CASECATEGORYDESC,
	 C.CONVENTIONLITERAL
from CCImport_CASECATEGORY I 
	join CASECATEGORY C	on ( C.CASETYPE=I.CASETYPE
	and C.CASECATEGORY=I.CASECATEGORY)
where 	( I.CASECATEGORYDESC <>  C.CASECATEGORYDESC OR (I.CASECATEGORYDESC is null and C.CASECATEGORYDESC is not null) 
OR (I.CASECATEGORYDESC is not null and C.CASECATEGORYDESC is null))
	OR 	( I.CONVENTIONLITERAL <>  C.CONVENTIONLITERAL OR (I.CONVENTIONLITERAL is null and C.CONVENTIONLITERAL is not null) 
OR (I.CONVENTIONLITERAL is not null and C.CONVENTIONLITERAL is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CASECATEGORY]') and xtype='U')
begin
	drop table CCImport_CASECATEGORY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CASECATEGORY  to public
go

