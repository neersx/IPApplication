-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PORTALMENU
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PORTALMENU]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PORTALMENU.'
	drop function dbo.fn_cc_PORTALMENU
	print '**** Creating function dbo.fn_cc_PORTALMENU...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALMENU]') and xtype='U')
begin
	select * 
	into CCImport_PORTALMENU 
	from PORTALMENU
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PORTALMENU
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PORTALMENU
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PORTALMENU table
-- CALLED BY :	ip_CopyConfigPORTALMENU
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
	 null as 'Imported Anonymoususer',
	 null as 'Imported Header',
	 null as 'Imported Parentid',
	 null as 'Imported Label',
	 null as 'Imported Sequence',
	 null as 'Imported Identityid',
	 null as 'Imported Overridden',
	 null as 'Imported Taskid',
	 null as 'Imported Href',
	 null as 'Imported Viewid',
'D' as '-',
	 C.ANONYMOUSUSER as 'Anonymoususer',
	 C.HEADER as 'Header',
	 C.PARENTID as 'Parentid',
	 C.LABEL as 'Label',
	 C.SEQUENCE as 'Sequence',
	 C.IDENTITYID as 'Identityid',
	 C.OVERRIDDEN as 'Overridden',
	 C.TASKID as 'Taskid',
	 C.HREF as 'Href',
	 C.VIEWID as 'Viewid'
from CCImport_PORTALMENU I 
	right join PORTALMENU C on( C.MENUID=I.MENUID)
where I.MENUID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ANONYMOUSUSER,
	 I.HEADER,
	 I.PARENTID,
	 I.LABEL,
	 I.SEQUENCE,
	 I.IDENTITYID,
	 I.OVERRIDDEN,
	 I.TASKID,
	 I.HREF,
	 I.VIEWID,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_PORTALMENU I 
	left join PORTALMENU C on( C.MENUID=I.MENUID)
where C.MENUID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ANONYMOUSUSER,
	 I.HEADER,
	 I.PARENTID,
	 I.LABEL,
	 I.SEQUENCE,
	 I.IDENTITYID,
	 I.OVERRIDDEN,
	 I.TASKID,
	 I.HREF,
	 I.VIEWID,
'U',
	 C.ANONYMOUSUSER,
	 C.HEADER,
	 C.PARENTID,
	 C.LABEL,
	 C.SEQUENCE,
	 C.IDENTITYID,
	 C.OVERRIDDEN,
	 C.TASKID,
	 C.HREF,
	 C.VIEWID
from CCImport_PORTALMENU I 
	join PORTALMENU C	on ( C.MENUID=I.MENUID)
where 	( I.ANONYMOUSUSER <>  C.ANONYMOUSUSER)
	OR 	( I.HEADER <>  C.HEADER)
	OR 	( I.PARENTID <>  C.PARENTID OR (I.PARENTID is null and C.PARENTID is not null) 
OR (I.PARENTID is not null and C.PARENTID is null))
	OR 	(replace( I.LABEL,char(10),char(13)+char(10)) <>  C.LABEL OR (I.LABEL is null and C.LABEL is not null) 
OR (I.LABEL is not null and C.LABEL is null))
	OR 	( I.SEQUENCE <>  C.SEQUENCE)
	OR 	( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null) 
OR (I.IDENTITYID is not null and C.IDENTITYID is null))
	OR 	( I.OVERRIDDEN <>  C.OVERRIDDEN)
	OR 	( I.TASKID <>  C.TASKID OR (I.TASKID is null and C.TASKID is not null) 
OR (I.TASKID is not null and C.TASKID is null))
	OR 	(replace( I.HREF,char(10),char(13)+char(10)) <>  C.HREF OR (I.HREF is null and C.HREF is not null) 
OR (I.HREF is not null and C.HREF is null))
	OR 	( I.VIEWID <>  C.VIEWID OR (I.VIEWID is null and C.VIEWID is not null) 
OR (I.VIEWID is not null and C.VIEWID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALMENU]') and xtype='U')
begin
	drop table CCImport_PORTALMENU 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PORTALMENU  to public
go
