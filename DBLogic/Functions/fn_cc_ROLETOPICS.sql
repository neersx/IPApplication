-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ROLETOPICS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ROLETOPICS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ROLETOPICS.'
	drop function dbo.fn_cc_ROLETOPICS
	print '**** Creating function dbo.fn_cc_ROLETOPICS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ROLETOPICS]') and xtype='U')
begin
	select * 
	into CCImport_ROLETOPICS 
	from ROLETOPICS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ROLETOPICS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ROLETOPICS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ROLETOPICS table
-- CALLED BY :	ip_CopyConfigROLETOPICS
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
	 null as 'Imported Roleid',
	 null as 'Imported Topicid',
'D' as '-',
	 C.ROLEID as 'Roleid',
	 C.TOPICID as 'Topicid'
from CCImport_ROLETOPICS I 
	right join ROLETOPICS C on( C.ROLEID=I.ROLEID
and  C.TOPICID=I.TOPICID)
where I.ROLEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ROLEID,
	 I.TOPICID,
'I',
	 null ,
	 null
from CCImport_ROLETOPICS I 
	left join ROLETOPICS C on( C.ROLEID=I.ROLEID
and  C.TOPICID=I.TOPICID)
where C.ROLEID is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ROLETOPICS]') and xtype='U')
begin
	drop table CCImport_ROLETOPICS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ROLETOPICS  to public
go
