-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_MAPPING
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_MAPPING]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_MAPPING.'
	drop function dbo.fn_cc_MAPPING
	print '**** Creating function dbo.fn_cc_MAPPING...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MAPPING]') and xtype='U')
begin
	select * 
	into CCImport_MAPPING 
	from MAPPING
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_MAPPING
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_MAPPING
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MAPPING table
-- CALLED BY :	ip_CopyConfigMAPPING
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
	 null as 'Imported Structureid',
	 null as 'Imported Datasourceid',
	 null as 'Imported Inputcode',
	 null as 'Imported Inputdescription',
	 null as 'Imported Inputcodeid',
	 null as 'Imported Outputcodeid',
	 null as 'Imported Outputvalue',
	 null as 'Imported Isnotapplicable',
'D' as '-',
	 C.STRUCTUREID as 'Structureid',
	 C.DATASOURCEID as 'Datasourceid',
	 C.INPUTCODE as 'Inputcode',
	 C.INPUTDESCRIPTION as 'Inputdescription',
	 C.INPUTCODEID as 'Inputcodeid',
	 C.OUTPUTCODEID as 'Outputcodeid',
	 C.OUTPUTVALUE as 'Outputvalue',
	 C.ISNOTAPPLICABLE as 'Isnotapplicable'
from CCImport_MAPPING I 
	right join MAPPING C on( C.ENTRYID=I.ENTRYID)
where I.ENTRYID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.STRUCTUREID,
	 I.DATASOURCEID,
	 I.INPUTCODE,
	 I.INPUTDESCRIPTION,
	 I.INPUTCODEID,
	 I.OUTPUTCODEID,
	 I.OUTPUTVALUE,
	 I.ISNOTAPPLICABLE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_MAPPING I 
	left join MAPPING C on( C.ENTRYID=I.ENTRYID)
where C.ENTRYID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.STRUCTUREID,
	 I.DATASOURCEID,
	 I.INPUTCODE,
	 I.INPUTDESCRIPTION,
	 I.INPUTCODEID,
	 I.OUTPUTCODEID,
	 I.OUTPUTVALUE,
	 I.ISNOTAPPLICABLE,
'U',
	 C.STRUCTUREID,
	 C.DATASOURCEID,
	 C.INPUTCODE,
	 C.INPUTDESCRIPTION,
	 C.INPUTCODEID,
	 C.OUTPUTCODEID,
	 C.OUTPUTVALUE,
	 C.ISNOTAPPLICABLE
from CCImport_MAPPING I 
	join MAPPING C	on ( C.ENTRYID=I.ENTRYID)
where 	( I.STRUCTUREID <>  C.STRUCTUREID)
	OR 	( I.DATASOURCEID <>  C.DATASOURCEID OR (I.DATASOURCEID is null and C.DATASOURCEID is not null) 
OR (I.DATASOURCEID is not null and C.DATASOURCEID is null))
	OR 	( I.INPUTCODE <>  C.INPUTCODE OR (I.INPUTCODE is null and C.INPUTCODE is not null) 
OR (I.INPUTCODE is not null and C.INPUTCODE is null))
	OR 	(replace( I.INPUTDESCRIPTION,char(10),char(13)+char(10)) <>  C.INPUTDESCRIPTION OR (I.INPUTDESCRIPTION is null and C.INPUTDESCRIPTION is not null) 
OR (I.INPUTDESCRIPTION is not null and C.INPUTDESCRIPTION is null))
	OR 	( I.INPUTCODEID <>  C.INPUTCODEID OR (I.INPUTCODEID is null and C.INPUTCODEID is not null) 
OR (I.INPUTCODEID is not null and C.INPUTCODEID is null))
	OR 	( I.OUTPUTCODEID <>  C.OUTPUTCODEID OR (I.OUTPUTCODEID is null and C.OUTPUTCODEID is not null) 
OR (I.OUTPUTCODEID is not null and C.OUTPUTCODEID is null))
	OR 	( I.OUTPUTVALUE <>  C.OUTPUTVALUE OR (I.OUTPUTVALUE is null and C.OUTPUTVALUE is not null) 
OR (I.OUTPUTVALUE is not null and C.OUTPUTVALUE is null))
	OR 	( I.ISNOTAPPLICABLE <>  C.ISNOTAPPLICABLE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MAPPING]') and xtype='U')
begin
	drop table CCImport_MAPPING 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_MAPPING  to public
go
