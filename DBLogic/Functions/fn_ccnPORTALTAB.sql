-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPORTALTAB
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPORTALTAB]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPORTALTAB.'
	drop function dbo.fn_ccnPORTALTAB
	print '**** Creating function dbo.fn_ccnPORTALTAB...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALTAB]') and xtype='U')
begin
	select * 
	into CCImport_PORTALTAB 
	from PORTALTAB
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPORTALTAB
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPORTALTAB
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PORTALTAB table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'PORTALTAB' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PORTALTAB I 
	right join PORTALTAB C on( C.TABID=I.TABID)
where I.TABID is null
UNION ALL 
select	6, 'PORTALTAB', 0, count(*), 0, 0
from CCImport_PORTALTAB I 
	left join PORTALTAB C on( C.TABID=I.TABID)
where C.TABID is null
UNION ALL 
 select	6, 'PORTALTAB', 0, 0, count(*), 0
from CCImport_PORTALTAB I 
	join PORTALTAB C	on ( C.TABID=I.TABID)
where 	( I.TABNAME <>  C.TABNAME)
	OR 	( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null) 
OR (I.IDENTITYID is not null and C.IDENTITYID is null))
	OR 	( I.TABSEQUENCE <>  C.TABSEQUENCE)
	OR 	( I.PORTALID <>  C.PORTALID OR (I.PORTALID is null and C.PORTALID is not null) 
OR (I.PORTALID is not null and C.PORTALID is null))
	OR 	( I.CSSCLASSNAME <>  C.CSSCLASSNAME OR (I.CSSCLASSNAME is null and C.CSSCLASSNAME is not null) 
OR (I.CSSCLASSNAME is not null and C.CSSCLASSNAME is null))
	OR 	( I.CANRENAME <>  C.CANRENAME)
	OR 	( I.CANDELETE <>  C.CANDELETE)
	OR 	( I.PARENTTABID <>  C.PARENTTABID OR (I.PARENTTABID is null and C.PARENTTABID is not null) 
OR (I.PARENTTABID is not null and C.PARENTTABID is null))
UNION ALL 
 select	6, 'PORTALTAB', 0, 0, 0, count(*)
from CCImport_PORTALTAB I 
join PORTALTAB C	on( C.TABID=I.TABID)
where ( I.TABNAME =  C.TABNAME)
and ( I.IDENTITYID =  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is null))
and ( I.TABSEQUENCE =  C.TABSEQUENCE)
and ( I.PORTALID =  C.PORTALID OR (I.PORTALID is null and C.PORTALID is null))
and ( I.CSSCLASSNAME =  C.CSSCLASSNAME OR (I.CSSCLASSNAME is null and C.CSSCLASSNAME is null))
and ( I.CANRENAME =  C.CANRENAME)
and ( I.CANDELETE =  C.CANDELETE)
and ( I.PARENTTABID =  C.PARENTTABID OR (I.PARENTTABID is null and C.PARENTTABID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALTAB]') and xtype='U')
begin
	drop table CCImport_PORTALTAB 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPORTALTAB  to public
go
