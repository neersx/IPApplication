-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnRATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnRATES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnRATES.'
	drop function dbo.fn_ccnRATES
	print '**** Creating function dbo.fn_ccnRATES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RATES]') and xtype='U')
begin
	select * 
	into CCImport_RATES 
	from RATES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnRATES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnRATES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RATES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'RATES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_RATES I 
	right join RATES C on( C.RATENO=I.RATENO)
where I.RATENO is null
UNION ALL 
select	5, 'RATES', 0, count(*), 0, 0
from CCImport_RATES I 
	left join RATES C on( C.RATENO=I.RATENO)
where C.RATENO is null
UNION ALL 
 select	5, 'RATES', 0, 0, count(*), 0
from CCImport_RATES I 
	join RATES C	on ( C.RATENO=I.RATENO)
where 	( I.RATEDESC <>  C.RATEDESC OR (I.RATEDESC is null and C.RATEDESC is not null) 
OR (I.RATEDESC is not null and C.RATEDESC is null))
	OR 	( I.RATETYPE <>  C.RATETYPE OR (I.RATETYPE is null and C.RATETYPE is not null) 
OR (I.RATETYPE is not null and C.RATETYPE is null))
	OR 	( I.USETYPEOFMARK <>  C.USETYPEOFMARK OR (I.USETYPEOFMARK is null and C.USETYPEOFMARK is not null) 
OR (I.USETYPEOFMARK is not null and C.USETYPEOFMARK is null))
	OR 	( I.RATENOSORT <>  C.RATENOSORT OR (I.RATENOSORT is null and C.RATENOSORT is not null) 
OR (I.RATENOSORT is not null and C.RATENOSORT is null))
	OR 	( I.CALCLABEL1 <>  C.CALCLABEL1 OR (I.CALCLABEL1 is null and C.CALCLABEL1 is not null) 
OR (I.CALCLABEL1 is not null and C.CALCLABEL1 is null))
	OR 	( I.CALCLABEL2 <>  C.CALCLABEL2 OR (I.CALCLABEL2 is null and C.CALCLABEL2 is not null) 
OR (I.CALCLABEL2 is not null and C.CALCLABEL2 is null))
	OR 	( I.ACTION <>  C.ACTION OR (I.ACTION is null and C.ACTION is not null) 
OR (I.ACTION is not null and C.ACTION is null))
	OR 	( I.AGENTNAMETYPE <>  C.AGENTNAMETYPE OR (I.AGENTNAMETYPE is null and C.AGENTNAMETYPE is not null) 
OR (I.AGENTNAMETYPE is not null and C.AGENTNAMETYPE is null))
UNION ALL 
 select	5, 'RATES', 0, 0, 0, count(*)
from CCImport_RATES I 
join RATES C	on( C.RATENO=I.RATENO)
where ( I.RATEDESC =  C.RATEDESC OR (I.RATEDESC is null and C.RATEDESC is null))
and ( I.RATETYPE =  C.RATETYPE OR (I.RATETYPE is null and C.RATETYPE is null))
and ( I.USETYPEOFMARK =  C.USETYPEOFMARK OR (I.USETYPEOFMARK is null and C.USETYPEOFMARK is null))
and ( I.RATENOSORT =  C.RATENOSORT OR (I.RATENOSORT is null and C.RATENOSORT is null))
and ( I.CALCLABEL1 =  C.CALCLABEL1 OR (I.CALCLABEL1 is null and C.CALCLABEL1 is null))
and ( I.CALCLABEL2 =  C.CALCLABEL2 OR (I.CALCLABEL2 is null and C.CALCLABEL2 is null))
and ( I.ACTION =  C.ACTION OR (I.ACTION is null and C.ACTION is null))
and ( I.AGENTNAMETYPE =  C.AGENTNAMETYPE OR (I.AGENTNAMETYPE is null and C.AGENTNAMETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RATES]') and xtype='U')
begin
	drop table CCImport_RATES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnRATES  to public
go
