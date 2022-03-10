-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCPAEVENTCODE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCPAEVENTCODE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCPAEVENTCODE.'
	drop function dbo.fn_ccnCPAEVENTCODE
	print '**** Creating function dbo.fn_ccnCPAEVENTCODE...'
	print ''
end
go


SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CPAEVENTCODE]') and xtype='U')
begin
	select * 
	into CCImport_CPAEVENTCODE 
	from CPAEVENTCODE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCPAEVENTCODE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCPAEVENTCODE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CPAEVENTCODE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	7 as TRIPNO, 'CPAEVENTCODE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CPAEVENTCODE I 
	right join CPAEVENTCODE C on( C.CPAEVENTCODE=I.CPAEVENTCODE)
where I.CPAEVENTCODE is null
UNION ALL 
select	7, 'CPAEVENTCODE', 0, count(*), 0, 0
from CCImport_CPAEVENTCODE I 
	left join CPAEVENTCODE C on( C.CPAEVENTCODE=I.CPAEVENTCODE)
where C.CPAEVENTCODE is null
UNION ALL 
 select	7, 'CPAEVENTCODE', 0, 0, count(*), 0
from CCImport_CPAEVENTCODE I 
	join CPAEVENTCODE C	on ( C.CPAEVENTCODE=I.CPAEVENTCODE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.CASEEVENTNO <>  C.CASEEVENTNO OR (I.CASEEVENTNO is null and C.CASEEVENTNO is not null) 
OR (I.CASEEVENTNO is not null and C.CASEEVENTNO is null))
UNION ALL 
 select	7, 'CPAEVENTCODE', 0, 0, 0, count(*)
from CCImport_CPAEVENTCODE I 
join CPAEVENTCODE C	on( C.CPAEVENTCODE=I.CPAEVENTCODE)
where ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.CASEEVENTNO =  C.CASEEVENTNO OR (I.CASEEVENTNO is null and C.CASEEVENTNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CPAEVENTCODE]') and xtype='U')
begin
	drop table CCImport_CPAEVENTCODE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCPAEVENTCODE  to public
go
