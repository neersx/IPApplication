-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_BUSINESSRULECONTRO_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_BUSINESSRULECONTRO_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_BUSINESSRULECONTRO_.'
	drop function dbo.fn_cc_BUSINESSRULECONTRO_
	print '**** Creating function dbo.fn_cc_BUSINESSRULECONTRO_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_BUSINESSRULECONTROL]') and xtype='U')
begin
	select * 
	into CCImport_BUSINESSRULECONTROL 
	from BUSINESSRULECONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_BUSINESSRULECONTRO_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_BUSINESSRULECONTRO_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the BUSINESSRULECONTROL table
-- CALLED BY :	ip_CopyConfigBUSINESSRULECONTRO_
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
	 null as 'Imported Topiccontrolno',
	 null as 'Imported Ruletype',
	 null as 'Imported Sequence',
	 null as 'Imported Value',
	 null as 'Imported Isinherited',
'D' as '-',
	 C.TOPICCONTROLNO as 'Topiccontrolno',
	 C.RULETYPE as 'Ruletype',
	 C.SEQUENCE as 'Sequence',
	 C.VALUE as 'Value',
	 C.ISINHERITED as 'Isinherited'
from CCImport_BUSINESSRULECONTROL I 
	right join BUSINESSRULECONTROL C on( C.BUSINESSRULENO=I.BUSINESSRULENO)
where I.BUSINESSRULENO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TOPICCONTROLNO,
	 I.RULETYPE,
	 I.SEQUENCE,
	 I.VALUE,
	 I.ISINHERITED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_BUSINESSRULECONTROL I 
	left join BUSINESSRULECONTROL C on( C.BUSINESSRULENO=I.BUSINESSRULENO)
where C.BUSINESSRULENO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TOPICCONTROLNO,
	 I.RULETYPE,
	 I.SEQUENCE,
	 I.VALUE,
	 I.ISINHERITED,
'U',
	 C.TOPICCONTROLNO,
	 C.RULETYPE,
	 C.SEQUENCE,
	 C.VALUE,
	 C.ISINHERITED
from CCImport_BUSINESSRULECONTROL I 
	join BUSINESSRULECONTROL C	on ( C.BUSINESSRULENO=I.BUSINESSRULENO)
where 	( I.TOPICCONTROLNO <>  C.TOPICCONTROLNO)
	OR 	( I.RULETYPE <>  C.RULETYPE)
	OR 	( I.SEQUENCE <>  C.SEQUENCE)
	OR 	(replace( I.VALUE,char(10),char(13)+char(10)) <>  C.VALUE OR (I.VALUE is null and C.VALUE is not null) 
OR (I.VALUE is not null and C.VALUE is null))
	OR 	( I.ISINHERITED <>  C.ISINHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_BUSINESSRULECONTROL]') and xtype='U')
begin
	drop table CCImport_BUSINESSRULECONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_BUSINESSRULECONTRO_  to public
go

