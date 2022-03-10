-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPROFITCENTRE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPROFITCENTRE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPROFITCENTRE.'
	drop function dbo.fn_ccnPROFITCENTRE
	print '**** Creating function dbo.fn_ccnPROFITCENTRE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFITCENTRE]') and xtype='U')
begin
	select * 
	into CCImport_PROFITCENTRE 
	from PROFITCENTRE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPROFITCENTRE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPROFITCENTRE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFITCENTRE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'PROFITCENTRE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PROFITCENTRE I 
	right join PROFITCENTRE C on( C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where I.PROFITCENTRECODE is null
UNION ALL 
select	8, 'PROFITCENTRE', 0, count(*), 0, 0
from CCImport_PROFITCENTRE I 
	left join PROFITCENTRE C on( C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where C.PROFITCENTRECODE is null
UNION ALL 
 select	8, 'PROFITCENTRE', 0, 0, count(*), 0
from CCImport_PROFITCENTRE I 
	join PROFITCENTRE C	on ( C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where 	( I.ENTITYNO <>  C.ENTITYNO)
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.INCLUDEONLYWIP <>  C.INCLUDEONLYWIP OR (I.INCLUDEONLYWIP is null and C.INCLUDEONLYWIP is not null) 
OR (I.INCLUDEONLYWIP is not null and C.INCLUDEONLYWIP is null))
UNION ALL 
 select	8, 'PROFITCENTRE', 0, 0, 0, count(*)
from CCImport_PROFITCENTRE I 
join PROFITCENTRE C	on( C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where ( I.ENTITYNO =  C.ENTITYNO)
and ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.INCLUDEONLYWIP =  C.INCLUDEONLYWIP OR (I.INCLUDEONLYWIP is null and C.INCLUDEONLYWIP is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFITCENTRE]') and xtype='U')
begin
	drop table CCImport_PROFITCENTRE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPROFITCENTRE  to public
go
