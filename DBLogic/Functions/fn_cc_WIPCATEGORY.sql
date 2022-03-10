-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_WIPCATEGORY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_WIPCATEGORY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_WIPCATEGORY.'
	drop function dbo.fn_cc_WIPCATEGORY
	print '**** Creating function dbo.fn_cc_WIPCATEGORY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_WIPCATEGORY]') and xtype='U')
begin
	select * 
	into CCImport_WIPCATEGORY 
	from WIPCATEGORY
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_WIPCATEGORY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_WIPCATEGORY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the WIPCATEGORY table
-- CALLED BY :	ip_CopyConfigWIPCATEGORY
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
	 null as 'Imported Categorycode',
	 null as 'Imported Description',
	 null as 'Imported Categorysort',
	 null as 'Imported Historicalexchrate',
'D' as '-',
	 C.CATEGORYCODE as 'Categorycode',
	 C.DESCRIPTION as 'Description',
	 C.CATEGORYSORT as 'Categorysort',
	 C.HISTORICALEXCHRATE as 'Historicalexchrate'
from CCImport_WIPCATEGORY I 
	right join WIPCATEGORY C on( C.CATEGORYCODE=I.CATEGORYCODE)
where I.CATEGORYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CATEGORYCODE,
	 I.DESCRIPTION,
	 I.CATEGORYSORT,
	 I.HISTORICALEXCHRATE,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_WIPCATEGORY I 
	left join WIPCATEGORY C on( C.CATEGORYCODE=I.CATEGORYCODE)
where C.CATEGORYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CATEGORYCODE,
	 I.DESCRIPTION,
	 I.CATEGORYSORT,
	 I.HISTORICALEXCHRATE,
'U',
	 C.CATEGORYCODE,
	 C.DESCRIPTION,
	 C.CATEGORYSORT,
	 C.HISTORICALEXCHRATE
from CCImport_WIPCATEGORY I 
	join WIPCATEGORY C	on ( C.CATEGORYCODE=I.CATEGORYCODE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.CATEGORYSORT <>  C.CATEGORYSORT OR (I.CATEGORYSORT is null and C.CATEGORYSORT is not null) 
OR (I.CATEGORYSORT is not null and C.CATEGORYSORT is null))
	OR 	( I.HISTORICALEXCHRATE <>  C.HISTORICALEXCHRATE OR (I.HISTORICALEXCHRATE is null and C.HISTORICALEXCHRATE is not null) 
OR (I.HISTORICALEXCHRATE is not null and C.HISTORICALEXCHRATE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_WIPCATEGORY]') and xtype='U')
begin
	drop table CCImport_WIPCATEGORY 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_WIPCATEGORY  to public
go
