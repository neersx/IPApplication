-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnWIPCATEGORY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnWIPCATEGORY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnWIPCATEGORY.'
	drop function dbo.fn_ccnWIPCATEGORY
	print '**** Creating function dbo.fn_ccnWIPCATEGORY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_WIPCATEGORY]') and xtype='U')
begin
	select * 
	into CCImport_WIPCATEGORY 
	from WIPCATEGORY
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnWIPCATEGORY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnWIPCATEGORY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the WIPCATEGORY table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'WIPCATEGORY' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_WIPCATEGORY I 
	right join WIPCATEGORY C on( C.CATEGORYCODE=I.CATEGORYCODE)
where I.CATEGORYCODE is null
UNION ALL 
select	8, 'WIPCATEGORY', 0, count(*), 0, 0
from CCImport_WIPCATEGORY I 
	left join WIPCATEGORY C on( C.CATEGORYCODE=I.CATEGORYCODE)
where C.CATEGORYCODE is null
UNION ALL 
 select	8, 'WIPCATEGORY', 0, 0, count(*), 0
from CCImport_WIPCATEGORY I 
	join WIPCATEGORY C	on ( C.CATEGORYCODE=I.CATEGORYCODE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.CATEGORYSORT <>  C.CATEGORYSORT OR (I.CATEGORYSORT is null and C.CATEGORYSORT is not null) 
OR (I.CATEGORYSORT is not null and C.CATEGORYSORT is null))
	OR 	( I.HISTORICALEXCHRATE <>  C.HISTORICALEXCHRATE OR (I.HISTORICALEXCHRATE is null and C.HISTORICALEXCHRATE is not null) 
OR (I.HISTORICALEXCHRATE is not null and C.HISTORICALEXCHRATE is null))
UNION ALL 
 select	8, 'WIPCATEGORY', 0, 0, 0, count(*)
from CCImport_WIPCATEGORY I 
join WIPCATEGORY C	on( C.CATEGORYCODE=I.CATEGORYCODE)
where ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.CATEGORYSORT =  C.CATEGORYSORT OR (I.CATEGORYSORT is null and C.CATEGORYSORT is null))
and ( I.HISTORICALEXCHRATE =  C.HISTORICALEXCHRATE OR (I.HISTORICALEXCHRATE is null and C.HISTORICALEXCHRATE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_WIPCATEGORY]') and xtype='U')
begin
	drop table CCImport_WIPCATEGORY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnWIPCATEGORY  to public
go
