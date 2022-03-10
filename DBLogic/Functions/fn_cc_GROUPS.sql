-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_GROUPS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_GROUPS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_GROUPS.'
	drop function dbo.fn_cc_GROUPS
	print '**** Creating function dbo.fn_cc_GROUPS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_GROUPS]') and xtype='U')
begin
	select * 
	into CCImport_GROUPS 
	from GROUPS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_GROUPS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_GROUPS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the GROUPS table
-- CALLED BY :	ip_CopyConfigGROUPS
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
	 null as 'Imported Group_name',
'D' as '-',
	 C.GROUP_CODE as 'Group_code',
	 C.GROUP_NAME as 'Group_name'
from CCImport_GROUPS I 
	right join GROUPS C on( C.GROUP_CODE=I.GROUP_CODE)
where I.GROUP_CODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.GROUP_CODE,
	 I.GROUP_NAME,
'I',
	 null ,
	 null
from CCImport_GROUPS I 
	left join GROUPS C on( C.GROUP_CODE=I.GROUP_CODE)
where C.GROUP_CODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.GROUP_CODE,
	 I.GROUP_NAME,
'U',
	 C.GROUP_CODE,
	 C.GROUP_NAME
from CCImport_GROUPS I 
	join GROUPS C	on ( C.GROUP_CODE=I.GROUP_CODE)
where 	( I.GROUP_NAME <>  C.GROUP_NAME)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_GROUPS]') and xtype='U')
begin
	drop table CCImport_GROUPS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_GROUPS  to public
go
