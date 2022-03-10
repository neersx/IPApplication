-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CHECKLISTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CHECKLISTS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CHECKLISTS.'
	drop function dbo.fn_cc_CHECKLISTS
	print '**** Creating function dbo.fn_cc_CHECKLISTS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CHECKLISTS]') and xtype='U')
begin
	select * 
	into CCImport_CHECKLISTS 
	from CHECKLISTS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CHECKLISTS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CHECKLISTS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CHECKLISTS table
-- CALLED BY :	ip_CopyConfigCHECKLISTS
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
	 null as 'Imported Checklisttype',
	 null as 'Imported Checklistdesc',
	 null as 'Imported Checklisttypeflag',
'D' as '-',
	 C.CHECKLISTTYPE as 'Checklisttype',
	 C.CHECKLISTDESC as 'Checklistdesc',
	 C.CHECKLISTTYPEFLAG as 'Checklisttypeflag'
from CCImport_CHECKLISTS I 
	right join CHECKLISTS C on( C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where I.CHECKLISTTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CHECKLISTTYPE,
	 I.CHECKLISTDESC,
	 I.CHECKLISTTYPEFLAG,
'I',
	 null ,
	 null ,
	 null
from CCImport_CHECKLISTS I 
	left join CHECKLISTS C on( C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where C.CHECKLISTTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CHECKLISTTYPE,
	 I.CHECKLISTDESC,
	 I.CHECKLISTTYPEFLAG,
'U',
	 C.CHECKLISTTYPE,
	 C.CHECKLISTDESC,
	 C.CHECKLISTTYPEFLAG
from CCImport_CHECKLISTS I 
	join CHECKLISTS C	on ( C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where 	( I.CHECKLISTDESC <>  C.CHECKLISTDESC OR (I.CHECKLISTDESC is null and C.CHECKLISTDESC is not null) 
OR (I.CHECKLISTDESC is not null and C.CHECKLISTDESC is null))
	OR 	( I.CHECKLISTTYPEFLAG <>  C.CHECKLISTTYPEFLAG OR (I.CHECKLISTTYPEFLAG is null and C.CHECKLISTTYPEFLAG is not null) 
OR (I.CHECKLISTTYPEFLAG is not null and C.CHECKLISTTYPEFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CHECKLISTS]') and xtype='U')
begin
	drop table CCImport_CHECKLISTS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CHECKLISTS  to public
go
