-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnITEM_NOTE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnITEM_NOTE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnITEM_NOTE.'
	drop function dbo.fn_ccnITEM_NOTE
	print '**** Creating function dbo.fn_ccnITEM_NOTE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM_NOTE]') and xtype='U')
begin
	select * 
	into CCImport_ITEM_NOTE 
	from ITEM_NOTE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnITEM_NOTE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnITEM_NOTE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ITEM_NOTE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	10 as TRIPNO, 'ITEM_NOTE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ITEM_NOTE I 
	right join ITEM_NOTE C on( C.ITEM_ID=I.ITEM_ID)
where I.ITEM_ID is null
UNION ALL 
select	10, 'ITEM_NOTE', 0, count(*), 0, 0
from CCImport_ITEM_NOTE I 
	left join ITEM_NOTE C on( C.ITEM_ID=I.ITEM_ID)
where C.ITEM_ID is null
UNION ALL 
 select	10, 'ITEM_NOTE', 0, 0, count(*), 0
from CCImport_ITEM_NOTE I 
	join ITEM_NOTE C	on ( C.ITEM_ID=I.ITEM_ID)
where 	( replace(CAST(I.ITEM_NOTES as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.ITEM_NOTES as NVARCHAR(MAX)) OR (I.ITEM_NOTES is null and C.ITEM_NOTES is not null) 
OR (I.ITEM_NOTES is not null and C.ITEM_NOTES is null))
UNION ALL 
 select	10, 'ITEM_NOTE', 0, 0, 0, count(*)
from CCImport_ITEM_NOTE I 
join ITEM_NOTE C	on( C.ITEM_ID=I.ITEM_ID)
where ( replace(CAST(I.ITEM_NOTES as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.ITEM_NOTES as NVARCHAR(MAX)) OR (I.ITEM_NOTES is null and C.ITEM_NOTES is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM_NOTE]') and xtype='U')
begin
	drop table CCImport_ITEM_NOTE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnITEM_NOTE  to public
go
