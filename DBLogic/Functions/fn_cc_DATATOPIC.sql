-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DATATOPIC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DATATOPIC]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DATATOPIC.'
	drop function dbo.fn_cc_DATATOPIC
	print '**** Creating function dbo.fn_cc_DATATOPIC...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DATATOPIC]') and xtype='U')
begin
	select * 
	into CCImport_DATATOPIC 
	from DATATOPIC
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DATATOPIC
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DATATOPIC
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DATATOPIC table
-- CALLED BY :	ip_CopyConfigDATATOPIC
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
	 null as 'Imported Topicid',
	 null as 'Imported Topicname',
	 null as 'Imported Description',
	 null as 'Imported Isexternal',
	 null as 'Imported Isinternal',
'D' as '-',
	 C.TOPICID as 'Topicid',
	 C.TOPICNAME as 'Topicname',
	 C.DESCRIPTION as 'Description',
	 C.ISEXTERNAL as 'Isexternal',
	 C.ISINTERNAL as 'Isinternal'
from CCImport_DATATOPIC I 
	right join DATATOPIC C on( C.TOPICID=I.TOPICID)
where I.TOPICID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TOPICID,
	 I.TOPICNAME,
	 I.DESCRIPTION,
	 I.ISEXTERNAL,
	 I.ISINTERNAL,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_DATATOPIC I 
	left join DATATOPIC C on( C.TOPICID=I.TOPICID)
where C.TOPICID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TOPICID,
	 I.TOPICNAME,
	 I.DESCRIPTION,
	 I.ISEXTERNAL,
	 I.ISINTERNAL,
'U',
	 C.TOPICID,
	 C.TOPICNAME,
	 C.DESCRIPTION,
	 C.ISEXTERNAL,
	 C.ISINTERNAL
from CCImport_DATATOPIC I 
	join DATATOPIC C	on ( C.TOPICID=I.TOPICID)
where 	( I.TOPICNAME <>  C.TOPICNAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.ISEXTERNAL <>  C.ISEXTERNAL)
	OR 	( I.ISINTERNAL <>  C.ISINTERNAL)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DATATOPIC]') and xtype='U')
begin
	drop table CCImport_DATATOPIC 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DATATOPIC  to public
go

