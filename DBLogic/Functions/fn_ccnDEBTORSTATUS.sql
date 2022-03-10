-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDEBTORSTATUS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDEBTORSTATUS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDEBTORSTATUS.'
	drop function dbo.fn_ccnDEBTORSTATUS
	print '**** Creating function dbo.fn_ccnDEBTORSTATUS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DEBTORSTATUS]') and xtype='U')
begin
	select * 
	into CCImport_DEBTORSTATUS 
	from DEBTORSTATUS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDEBTORSTATUS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDEBTORSTATUS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DEBTORSTATUS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'DEBTORSTATUS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DEBTORSTATUS I 
	right join DEBTORSTATUS C on( C.BADDEBTOR=I.BADDEBTOR)
where I.BADDEBTOR is null
UNION ALL 
select	8, 'DEBTORSTATUS', 0, count(*), 0, 0
from CCImport_DEBTORSTATUS I 
	left join DEBTORSTATUS C on( C.BADDEBTOR=I.BADDEBTOR)
where C.BADDEBTOR is null
UNION ALL 
 select	8, 'DEBTORSTATUS', 0, 0, count(*), 0
from CCImport_DEBTORSTATUS I 
	join DEBTORSTATUS C	on ( C.BADDEBTOR=I.BADDEBTOR)
where 	( I.DEBTORSTATUS <>  C.DEBTORSTATUS OR (I.DEBTORSTATUS is null and C.DEBTORSTATUS is not null) 
OR (I.DEBTORSTATUS is not null and C.DEBTORSTATUS is null))
	OR 	( I.ACTIONFLAG <>  C.ACTIONFLAG OR (I.ACTIONFLAG is null and C.ACTIONFLAG is not null) 
OR (I.ACTIONFLAG is not null and C.ACTIONFLAG is null))
	OR 	( I.CLEARPASSWORD <>  C.CLEARPASSWORD OR (I.CLEARPASSWORD is null and C.CLEARPASSWORD is not null) 
OR (I.CLEARPASSWORD is not null and C.CLEARPASSWORD is null))
UNION ALL 
 select	8, 'DEBTORSTATUS', 0, 0, 0, count(*)
from CCImport_DEBTORSTATUS I 
join DEBTORSTATUS C	on( C.BADDEBTOR=I.BADDEBTOR)
where ( I.DEBTORSTATUS =  C.DEBTORSTATUS OR (I.DEBTORSTATUS is null and C.DEBTORSTATUS is null))
and ( I.ACTIONFLAG =  C.ACTIONFLAG OR (I.ACTIONFLAG is null and C.ACTIONFLAG is null))
and ( I.CLEARPASSWORD =  C.CLEARPASSWORD OR (I.CLEARPASSWORD is null and C.CLEARPASSWORD is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DEBTORSTATUS]') and xtype='U')
begin
	drop table CCImport_DEBTORSTATUS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDEBTORSTATUS  to public
go
