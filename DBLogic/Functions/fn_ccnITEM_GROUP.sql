-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnITEM_GROUP
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnITEM_GROUP]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnITEM_GROUP.'
	drop function dbo.fn_ccnITEM_GROUP
	print '**** Creating function dbo.fn_ccnITEM_GROUP...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM_GROUP]') and xtype='U')
begin
	select * 
	into CCImport_ITEM_GROUP 
	from ITEM_GROUP
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnITEM_GROUP
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnITEM_GROUP
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ITEM_GROUP table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	10 as TRIPNO, 'ITEM_GROUP' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ITEM_GROUP I 
	right join ITEM_GROUP C on( C.GROUP_CODE=I.GROUP_CODE
and  C.ITEM_ID=I.ITEM_ID)
where I.GROUP_CODE is null
UNION ALL 
select	10, 'ITEM_GROUP', 0, count(*), 0, 0
from CCImport_ITEM_GROUP I 
	left join ITEM_GROUP C on( C.GROUP_CODE=I.GROUP_CODE
and  C.ITEM_ID=I.ITEM_ID)
where C.GROUP_CODE is null
UNION ALL 
 select	10, 'ITEM_GROUP', 0, 0, 0, count(*)
from CCImport_ITEM_GROUP I 
join ITEM_GROUP C	on( C.GROUP_CODE=I.GROUP_CODE
and C.ITEM_ID=I.ITEM_ID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM_GROUP]') and xtype='U')
begin
	drop table CCImport_ITEM_GROUP 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnITEM_GROUP  to public
go
