-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TOPICS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TOPICS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TOPICS.'
	drop function dbo.fn_cc_TOPICS
	print '**** Creating function dbo.fn_cc_TOPICS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICS]') and xtype='U')
begin
	select * 
	into CCImport_TOPICS 
	from TOPICS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TOPICS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TOPICS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICS table
-- CALLED BY :	ip_CopyConfigTOPICS
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
	 null as 'Imported Topicname',
	 null as 'Imported Topictype',
'D' as '-',
	 C.TOPICNAME as 'Topicname',
	 C.TOPICTYPE as 'Topictype'
from CCImport_TOPICS I 
	right join TOPICS C on( C.TOPICNAME=I.TOPICNAME
and  C.TOPICTYPE=I.TOPICTYPE)
where I.TOPICNAME is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TOPICNAME,
	 I.TOPICTYPE,
'I',
	 null ,
	 null
from CCImport_TOPICS I 
	left join TOPICS C on( C.TOPICNAME=I.TOPICNAME
and  C.TOPICTYPE=I.TOPICTYPE)
where C.TOPICNAME is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICS]') and xtype='U')
begin
	drop table CCImport_TOPICS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TOPICS  to public
go
