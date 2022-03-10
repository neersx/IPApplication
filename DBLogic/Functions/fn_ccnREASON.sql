-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnREASON
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnREASON]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnREASON.'
	drop function dbo.fn_ccnREASON
	print '**** Creating function dbo.fn_ccnREASON...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_REASON]') and xtype='U')
begin
	select * 
	into CCImport_REASON 
	from REASON
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnREASON
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnREASON
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the REASON table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'REASON' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_REASON I 
	right join REASON C on( C.REASONCODE=I.REASONCODE)
where I.REASONCODE is null
UNION ALL 
select	2, 'REASON', 0, count(*), 0, 0
from CCImport_REASON I 
	left join REASON C on( C.REASONCODE=I.REASONCODE)
where C.REASONCODE is null
UNION ALL 
 select	2, 'REASON', 0, 0, count(*), 0
from CCImport_REASON I 
	join REASON C	on ( C.REASONCODE=I.REASONCODE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.USED_BY <>  C.USED_BY OR (I.USED_BY is null and C.USED_BY is not null) 
OR (I.USED_BY is not null and C.USED_BY is null))
	OR 	( I.SHOWONDEBITNOTE <>  C.SHOWONDEBITNOTE OR (I.SHOWONDEBITNOTE is null and C.SHOWONDEBITNOTE is not null) 
OR (I.SHOWONDEBITNOTE is not null and C.SHOWONDEBITNOTE is null))
	OR 	( I.ISPROTECTED <>  C.ISPROTECTED OR (I.ISPROTECTED is null and C.ISPROTECTED is not null) 
OR (I.ISPROTECTED is not null and C.ISPROTECTED is null))
UNION ALL 
 select	2, 'REASON', 0, 0, 0, count(*)
from CCImport_REASON I 
join REASON C	on( C.REASONCODE=I.REASONCODE)
where ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.USED_BY =  C.USED_BY OR (I.USED_BY is null and C.USED_BY is null))
and ( I.SHOWONDEBITNOTE =  C.SHOWONDEBITNOTE OR (I.SHOWONDEBITNOTE is null and C.SHOWONDEBITNOTE is null))
and ( I.ISPROTECTED =  C.ISPROTECTED OR (I.ISPROTECTED is null and C.ISPROTECTED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_REASON]') and xtype='U')
begin
	drop table CCImport_REASON 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnREASON  to public
go
