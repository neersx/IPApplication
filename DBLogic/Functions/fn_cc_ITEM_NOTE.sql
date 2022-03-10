-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ITEM_NOTE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ITEM_NOTE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ITEM_NOTE.'
	drop function dbo.fn_cc_ITEM_NOTE
	print '**** Creating function dbo.fn_cc_ITEM_NOTE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM_NOTE]') and xtype='U')
begin
	select * 
	into CCImport_ITEM_NOTE 
	from ITEM_NOTE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ITEM_NOTE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ITEM_NOTE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ITEM_NOTE table
-- CALLED BY :	ip_CopyConfigITEM_NOTE
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Item_id',
	 null as 'Imported Item_notes',
'D' as '-',
	 C.ITEM_ID as 'Item_id',
	 CAST(C.ITEM_NOTES AS NVARCHAR(4000)) as 'Item_notes'
from CCImport_ITEM_NOTE I 
	right join ITEM_NOTE C on( C.ITEM_ID=I.ITEM_ID)
where I.ITEM_ID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ITEM_ID,
	 CAST(I.ITEM_NOTES AS NVARCHAR(4000)),
'I',
	 null ,
	 null
from CCImport_ITEM_NOTE I 
	left join ITEM_NOTE C on( C.ITEM_ID=I.ITEM_ID)
where C.ITEM_ID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ITEM_ID,
	 CAST(I.ITEM_NOTES AS NVARCHAR(4000)),
'U',
	 C.ITEM_ID,
	 CAST(C.ITEM_NOTES AS NVARCHAR(4000))
from CCImport_ITEM_NOTE I 
	join ITEM_NOTE C	on ( C.ITEM_ID=I.ITEM_ID)
where 	( replace(CAST(I.ITEM_NOTES as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.ITEM_NOTES as NVARCHAR(MAX)) OR (I.ITEM_NOTES is null and C.ITEM_NOTES is not null) 
OR (I.ITEM_NOTES is not null and C.ITEM_NOTES is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM_NOTE]') and xtype='U')
begin
	drop table CCImport_ITEM_NOTE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ITEM_NOTE  to public
go
