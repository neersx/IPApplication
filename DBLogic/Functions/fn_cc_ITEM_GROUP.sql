-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ITEM_GROUP
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ITEM_GROUP]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ITEM_GROUP.'
	drop function dbo.fn_cc_ITEM_GROUP
	print '**** Creating function dbo.fn_cc_ITEM_GROUP...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM_GROUP]') and xtype='U')
begin
	select * 
	into CCImport_ITEM_GROUP 
	from ITEM_GROUP
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ITEM_GROUP
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ITEM_GROUP
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ITEM_GROUP table
-- CALLED BY :	ip_CopyConfigITEM_GROUP
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
	 null as 'Imported Group_code',
	 null as 'Imported Item_id',
'D' as '-',
	 C.GROUP_CODE as 'Group_code',
	 C.ITEM_ID as 'Item_id'
from CCImport_ITEM_GROUP I 
	right join ITEM_GROUP C on( C.GROUP_CODE=I.GROUP_CODE
and  C.ITEM_ID=I.ITEM_ID)
where I.GROUP_CODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.GROUP_CODE,
	 I.ITEM_ID,
'I',
	 null ,
	 null
from CCImport_ITEM_GROUP I 
	left join ITEM_GROUP C on( C.GROUP_CODE=I.GROUP_CODE
and  C.ITEM_ID=I.ITEM_ID)
where C.GROUP_CODE is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ITEM_GROUP]') and xtype='U')
begin
	drop table CCImport_ITEM_GROUP 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ITEM_GROUP  to public
go
