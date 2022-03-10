-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TOPICUSAGECCImport_TOPICUSAGE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TOPICUSAGE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TOPICUSAGE.'
	drop function dbo.fn_cc_TOPICUSAGE
	print '**** Creating function dbo.fn_cc_TOPICUSAGE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICUSAGE]') and xtype='U')
begin
	select * 
	into CCImport_TOPICUSAGE 
	from TOPICUSAGE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TOPICUSAGE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TOPICUSAGE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICUSAGE table
-- CALLED BY :	ip_CopyConfigTOPICUSAGE
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 03 Apr 2017	MF	71020	1	Function created.
--
As 
Return
select	1     as 'Switch',
	'X'   as 'Match',
	'D'   as 'Imported -',
	 null as 'Imported Topicname',
	 null as 'Imported Topictitle',
	 null as 'Imported Type',
	'D' as '-',
	 C.TOPICNAME  as 'Topicname',
	 C.TOPICTITLE as 'Topictitle',
	 C.TYPE       as 'Type'
from CCImport_TOPICUSAGE I 
	right join TOPICUSAGE C on ( C.TOPICNAME=I.TOPICNAME)
where I.TOPICNAME is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TOPICNAME,
	 I.TOPICTITLE,
	 I.TYPE,
	'I',
	 null ,
	 null ,
	 null
from CCImport_TOPICUSAGE I 
	left join TOPICUSAGE C on ( C.TOPICNAME=I.TOPICNAME)
where C.TOPICNAME is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TOPICNAME,
	 I.TOPICTITLE,
	 I.TYPE,
	'U',
	 C.TOPICNAME,
	 C.TOPICTITLE,
	 C.TYPE
from CCImport_TOPICUSAGE I 
	join TOPICUSAGE C	on ( C.TOPICNAME=I.TOPICNAME)
where 	( I.TOPICTITLE <>  C.TOPICTITLE OR (I.TOPICTITLE is null and C.TOPICTITLE is not null) 
OR (I.TOPICTITLE is not null and C.TOPICTITLE is null))
	OR 	( I.TYPE <>  C.TYPE OR (I.TYPE is null and C.TYPE is not null) 
OR (I.TYPE is not null and C.TYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICUSAGE]') and xtype='U')
begin
	drop table CCImport_TOPICUSAGE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TOPICUSAGE  to public
go
