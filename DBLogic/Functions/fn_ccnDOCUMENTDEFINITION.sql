-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDOCUMENTDEFINITION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDOCUMENTDEFINITION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDOCUMENTDEFINITION.'
	drop function dbo.fn_ccnDOCUMENTDEFINITION
	print '**** Creating function dbo.fn_ccnDOCUMENTDEFINITION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENTDEFINITION]') and xtype='U')
begin
	select * 
	into CCImport_DOCUMENTDEFINITION 
	from DOCUMENTDEFINITION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDOCUMENTDEFINITION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDOCUMENTDEFINITION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DOCUMENTDEFINITION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'DOCUMENTDEFINITION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DOCUMENTDEFINITION I 
	right join DOCUMENTDEFINITION C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID)
where I.DOCUMENTDEFID is null
UNION ALL 
select	6, 'DOCUMENTDEFINITION', 0, count(*), 0, 0
from CCImport_DOCUMENTDEFINITION I 
	left join DOCUMENTDEFINITION C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID)
where C.DOCUMENTDEFID is null
UNION ALL 
 select	6, 'DOCUMENTDEFINITION', 0, 0, count(*), 0
from CCImport_DOCUMENTDEFINITION I 
	join DOCUMENTDEFINITION C	on ( C.DOCUMENTDEFID=I.DOCUMENTDEFID)
where 	( I.LETTERNO <>  C.LETTERNO)
	OR 	( I.NAME <>  C.NAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.CANFILTERCASES <>  C.CANFILTERCASES)
	OR 	( I.CANFILTEREVENTS <>  C.CANFILTEREVENTS)
	OR 	( I.SENDERREQUESTTYPE <>  C.SENDERREQUESTTYPE OR (I.SENDERREQUESTTYPE is null and C.SENDERREQUESTTYPE is not null) 
OR (I.SENDERREQUESTTYPE is not null and C.SENDERREQUESTTYPE is null))
UNION ALL 
 select	6, 'DOCUMENTDEFINITION', 0, 0, 0, count(*)
from CCImport_DOCUMENTDEFINITION I 
join DOCUMENTDEFINITION C	on( C.DOCUMENTDEFID=I.DOCUMENTDEFID)
where ( I.LETTERNO =  C.LETTERNO)
and ( I.NAME =  C.NAME)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.CANFILTERCASES =  C.CANFILTERCASES)
and ( I.CANFILTEREVENTS =  C.CANFILTEREVENTS)
and ( I.SENDERREQUESTTYPE =  C.SENDERREQUESTTYPE OR (I.SENDERREQUESTTYPE is null and C.SENDERREQUESTTYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENTDEFINITION]') and xtype='U')
begin
	drop table CCImport_DOCUMENTDEFINITION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDOCUMENTDEFINITION  to public
go
