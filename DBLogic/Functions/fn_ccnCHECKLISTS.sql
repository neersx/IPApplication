-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCHECKLISTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCHECKLISTS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCHECKLISTS.'
	drop function dbo.fn_ccnCHECKLISTS
	print '**** Creating function dbo.fn_ccnCHECKLISTS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnCHECKLISTS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCHECKLISTS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CHECKLISTS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'CHECKLISTS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CHECKLISTS I 
	right join CHECKLISTS C on( C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where I.CHECKLISTTYPE is null
UNION ALL 
select	5, 'CHECKLISTS', 0, count(*), 0, 0
from CCImport_CHECKLISTS I 
	left join CHECKLISTS C on( C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where C.CHECKLISTTYPE is null
UNION ALL 
 select	5, 'CHECKLISTS', 0, 0, count(*), 0
from CCImport_CHECKLISTS I 
	join CHECKLISTS C	on ( C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where 	( I.CHECKLISTDESC <>  C.CHECKLISTDESC OR (I.CHECKLISTDESC is null and C.CHECKLISTDESC is not null) 
OR (I.CHECKLISTDESC is not null and C.CHECKLISTDESC is null))
	OR 	( I.CHECKLISTTYPEFLAG <>  C.CHECKLISTTYPEFLAG OR (I.CHECKLISTTYPEFLAG is null and C.CHECKLISTTYPEFLAG is not null) 
OR (I.CHECKLISTTYPEFLAG is not null and C.CHECKLISTTYPEFLAG is null))
UNION ALL 
 select	5, 'CHECKLISTS', 0, 0, 0, count(*)
from CCImport_CHECKLISTS I 
join CHECKLISTS C	on( C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where ( I.CHECKLISTDESC =  C.CHECKLISTDESC OR (I.CHECKLISTDESC is null and C.CHECKLISTDESC is null))
and ( I.CHECKLISTTYPEFLAG =  C.CHECKLISTTYPEFLAG OR (I.CHECKLISTTYPEFLAG is null and C.CHECKLISTTYPEFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CHECKLISTS]') and xtype='U')
begin
	drop table CCImport_CHECKLISTS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCHECKLISTS  to public
go
