-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCASECATEGORY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCASECATEGORY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCASECATEGORY.'
	drop function dbo.fn_ccnCASECATEGORY
	print '**** Creating function dbo.fn_ccnCASECATEGORY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnCASECATEGORY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCASECATEGORY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CASECATEGORY table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'CASECATEGORY' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CASECATEGORY I 
	right join CASECATEGORY C on( C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY)
where I.CASETYPE is null
UNION ALL 
select	2, 'CASECATEGORY', 0, count(*), 0, 0
from CCImport_CASECATEGORY I 
	left join CASECATEGORY C on( C.CASETYPE=I.CASETYPE
and  C.CASECATEGORY=I.CASECATEGORY)
where C.CASETYPE is null
UNION ALL 
 select	2, 'CASECATEGORY', 0, 0, count(*), 0
from CCImport_CASECATEGORY I 
	join CASECATEGORY C	on ( C.CASETYPE=I.CASETYPE
	and C.CASECATEGORY=I.CASECATEGORY)
where 	( I.CASECATEGORYDESC <>  C.CASECATEGORYDESC OR (I.CASECATEGORYDESC is null and C.CASECATEGORYDESC is not null) 
OR (I.CASECATEGORYDESC is not null and C.CASECATEGORYDESC is null))
	OR 	( I.CONVENTIONLITERAL <>  C.CONVENTIONLITERAL OR (I.CONVENTIONLITERAL is null and C.CONVENTIONLITERAL is not null) 
OR (I.CONVENTIONLITERAL is not null and C.CONVENTIONLITERAL is null))
UNION ALL 
 select	2, 'CASECATEGORY', 0, 0, 0, count(*)
from CCImport_CASECATEGORY I 
join CASECATEGORY C	on( C.CASETYPE=I.CASETYPE
and C.CASECATEGORY=I.CASECATEGORY)
where ( I.CASECATEGORYDESC =  C.CASECATEGORYDESC OR (I.CASECATEGORYDESC is null and C.CASECATEGORYDESC is null))
and ( I.CONVENTIONLITERAL =  C.CONVENTIONLITERAL OR (I.CONVENTIONLITERAL is null and C.CONVENTIONLITERAL is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CASECATEGORY]') and xtype='U')
begin
	drop table CCImport_CASECATEGORY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCASECATEGORY  to public
go
