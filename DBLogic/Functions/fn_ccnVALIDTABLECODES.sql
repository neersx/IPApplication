-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDTABLECODES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDTABLECODES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDTABLECODES.'
	drop function dbo.fn_ccnVALIDTABLECODES
	print '**** Creating function dbo.fn_ccnVALIDTABLECODES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDTABLECODES]') and xtype='U')
begin
	select * 
	into CCImport_VALIDTABLECODES 
	from VALIDTABLECODES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDTABLECODES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDTABLECODES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDTABLECODES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDTABLECODES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDTABLECODES I 
	right join VALIDTABLECODES C on( C.VALIDTABLECODEID=I.VALIDTABLECODEID)
where I.VALIDTABLECODEID is null
UNION ALL 
select	3, 'VALIDTABLECODES', 0, count(*), 0, 0
from CCImport_VALIDTABLECODES I 
	left join VALIDTABLECODES C on( C.VALIDTABLECODEID=I.VALIDTABLECODEID)
where C.VALIDTABLECODEID is null
UNION ALL 
 select	3, 'VALIDTABLECODES', 0, 0, count(*), 0
from CCImport_VALIDTABLECODES I 
	join VALIDTABLECODES C	on ( C.VALIDTABLECODEID=I.VALIDTABLECODEID)
where 	( I.TABLECODE <>  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is not null) 
OR (I.TABLECODE is not null and C.TABLECODE is null))
	OR 	( I.VALIDTABLECODE <>  C.VALIDTABLECODE OR (I.VALIDTABLECODE is null and C.VALIDTABLECODE is not null) 
OR (I.VALIDTABLECODE is not null and C.VALIDTABLECODE is null))
	OR 	( I.VALIDTABLETYPE <>  C.VALIDTABLETYPE OR (I.VALIDTABLETYPE is null and C.VALIDTABLETYPE is not null) 
OR (I.VALIDTABLETYPE is not null and C.VALIDTABLETYPE is null))
UNION ALL 
 select	3, 'VALIDTABLECODES', 0, 0, 0, count(*)
from CCImport_VALIDTABLECODES I 
join VALIDTABLECODES C	on( C.VALIDTABLECODEID=I.VALIDTABLECODEID)
where ( I.TABLECODE =  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is null))
and ( I.VALIDTABLECODE =  C.VALIDTABLECODE OR (I.VALIDTABLECODE is null and C.VALIDTABLECODE is null))
and ( I.VALIDTABLETYPE =  C.VALIDTABLETYPE OR (I.VALIDTABLETYPE is null and C.VALIDTABLETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDTABLECODES]') and xtype='U')
begin
	drop table CCImport_VALIDTABLECODES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDTABLECODES  to public
go
