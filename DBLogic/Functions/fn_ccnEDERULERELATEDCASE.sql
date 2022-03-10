-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEDERULERELATEDCASE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEDERULERELATEDCASE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEDERULERELATEDCASE.'
	drop function dbo.fn_ccnEDERULERELATEDCASE
	print '**** Creating function dbo.fn_ccnEDERULERELATEDCASE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULERELATEDCASE]') and xtype='U')
begin
	select * 
	into CCImport_EDERULERELATEDCASE 
	from EDERULERELATEDCASE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEDERULERELATEDCASE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEDERULERELATEDCASE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULERELATEDCASE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'EDERULERELATEDCASE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EDERULERELATEDCASE I 
	right join EDERULERELATEDCASE C on( C.CRITERIANO=I.CRITERIANO
and  C.RELATIONSHIP=I.RELATIONSHIP)
where I.CRITERIANO is null
UNION ALL 
select	9, 'EDERULERELATEDCASE', 0, count(*), 0, 0
from CCImport_EDERULERELATEDCASE I 
	left join EDERULERELATEDCASE C on( C.CRITERIANO=I.CRITERIANO
and  C.RELATIONSHIP=I.RELATIONSHIP)
where C.CRITERIANO is null
UNION ALL 
 select	9, 'EDERULERELATEDCASE', 0, 0, count(*), 0
from CCImport_EDERULERELATEDCASE I 
	join EDERULERELATEDCASE C	on ( C.CRITERIANO=I.CRITERIANO
	and C.RELATIONSHIP=I.RELATIONSHIP)
where 	( I.OFFICIALNUMBER <>  C.OFFICIALNUMBER OR (I.OFFICIALNUMBER is null and C.OFFICIALNUMBER is not null) 
OR (I.OFFICIALNUMBER is not null and C.OFFICIALNUMBER is null))
	OR 	( I.PRIORITYDATE <>  C.PRIORITYDATE OR (I.PRIORITYDATE is null and C.PRIORITYDATE is not null) 
OR (I.PRIORITYDATE is not null and C.PRIORITYDATE is null))
UNION ALL 
 select	9, 'EDERULERELATEDCASE', 0, 0, 0, count(*)
from CCImport_EDERULERELATEDCASE I 
join EDERULERELATEDCASE C	on( C.CRITERIANO=I.CRITERIANO
and C.RELATIONSHIP=I.RELATIONSHIP)
where ( I.OFFICIALNUMBER =  C.OFFICIALNUMBER OR (I.OFFICIALNUMBER is null and C.OFFICIALNUMBER is null))
and ( I.PRIORITYDATE =  C.PRIORITYDATE OR (I.PRIORITYDATE is null and C.PRIORITYDATE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULERELATEDCASE]') and xtype='U')
begin
	drop table CCImport_EDERULERELATEDCASE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEDERULERELATEDCASE  to public
go
