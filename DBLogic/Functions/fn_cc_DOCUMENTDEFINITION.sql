-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DOCUMENTDEFINITION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DOCUMENTDEFINITION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DOCUMENTDEFINITION.'
	drop function dbo.fn_cc_DOCUMENTDEFINITION
	print '**** Creating function dbo.fn_cc_DOCUMENTDEFINITION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_DOCUMENTDEFINITION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DOCUMENTDEFINITION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DOCUMENTDEFINITION table
-- CALLED BY :	ip_CopyConfigDOCUMENTDEFINITION
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
	 null as 'Imported Letterno',
	 null as 'Imported Name',
	 null as 'Imported Description',
	 null as 'Imported Canfiltercases',
	 null as 'Imported Canfilterevents',
	 null as 'Imported Senderrequesttype',
'D' as '-',
	 C.LETTERNO as 'Letterno',
	 C.NAME as 'Name',
	 C.DESCRIPTION as 'Description',
	 C.CANFILTERCASES as 'Canfiltercases',
	 C.CANFILTEREVENTS as 'Canfilterevents',
	 C.SENDERREQUESTTYPE as 'Senderrequesttype'
from CCImport_DOCUMENTDEFINITION I 
	right join DOCUMENTDEFINITION C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID)
where I.DOCUMENTDEFID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.LETTERNO,
	 I.NAME,
	 I.DESCRIPTION,
	 I.CANFILTERCASES,
	 I.CANFILTEREVENTS,
	 I.SENDERREQUESTTYPE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_DOCUMENTDEFINITION I 
	left join DOCUMENTDEFINITION C on( C.DOCUMENTDEFID=I.DOCUMENTDEFID)
where C.DOCUMENTDEFID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.LETTERNO,
	 I.NAME,
	 I.DESCRIPTION,
	 I.CANFILTERCASES,
	 I.CANFILTEREVENTS,
	 I.SENDERREQUESTTYPE,
'U',
	 C.LETTERNO,
	 C.NAME,
	 C.DESCRIPTION,
	 C.CANFILTERCASES,
	 C.CANFILTEREVENTS,
	 C.SENDERREQUESTTYPE
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DOCUMENTDEFINITION]') and xtype='U')
begin
	drop table CCImport_DOCUMENTDEFINITION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DOCUMENTDEFINITION  to public
go

