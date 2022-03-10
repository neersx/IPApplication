-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CONFIGURATIONITEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CONFIGURATIONITEM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CONFIGURATIONITEM.'
	drop function dbo.fn_cc_CONFIGURATIONITEM
	print '**** Creating function dbo.fn_cc_CONFIGURATIONITEM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CONFIGURATIONITEM]') and xtype='U')
begin
	select * 
	into CCImport_CONFIGURATIONITEM 
	from CONFIGURATIONITEM
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CONFIGURATIONITEM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CONFIGURATIONITEM
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the CONFIGURATIONITEM table
-- CALLED BY :	ip_CopyConfigCONFIGURATIONITEM
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 03 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Taskid',
	 null as 'Imported Contextid',
	 null as 'Imported Title',
	 null as 'Imported Description',
	 null as 'Imported Genericparam',
	 null as 'Imported Groupid',
	 null as 'Imported Url',
	'D' as '-',
	 C.TASKID as 'Taskid',
	 C.CONTEXTID as 'Contextid',
	 C.TITLE as 'Title',
	 C.DESCRIPTION as 'Description',
	 C.GENERICPARAM as 'Genericparam',
	 C.GROUPID as 'Groupid',
	 C.URL as 'URL'
from CCImport_CONFIGURATIONITEM I 
	right join CONFIGURATIONITEM C on( C.CONFIGITEMID=I.CONFIGITEMID)
where I.CONFIGITEMID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TASKID,
	 I.CONTEXTID,
	 I.TITLE,
	 I.DESCRIPTION,
	 I.GENERICPARAM,
	 I.GROUPID,
	 I.URL,
	'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_CONFIGURATIONITEM I 
	left join CONFIGURATIONITEM C on( C.CONFIGITEMID=I.CONFIGITEMID)
where C.CONFIGITEMID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TASKID,
	 I.CONTEXTID,
	 I.TITLE,
	 I.DESCRIPTION,
	 I.GENERICPARAM,
	 I.GROUPID,
	 I.URL,
	'U',
	 C.TASKID,
	 C.CONTEXTID,
	 C.TITLE,
	 C.DESCRIPTION,
	 C.GENERICPARAM,
	 C.GROUPID,
	 C.URL
from CCImport_CONFIGURATIONITEM I 
	join CONFIGURATIONITEM C	on ( C.CONFIGITEMID=I.CONFIGITEMID)
where 	( I.TASKID <>  C.TASKID)
	OR 	( I.CONTEXTID <>  C.CONTEXTID OR (I.CONTEXTID is null and C.CONTEXTID is not null) 
OR (I.CONTEXTID is not null and C.CONTEXTID is null))
	OR 	(replace( I.TITLE,char(10),char(13)+char(10)) <>  C.TITLE OR (I.TITLE is null and C.TITLE is not null) 
OR (I.TITLE is not null and C.TITLE is null))
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.GENERICPARAM <>  C.GENERICPARAM OR (I.GENERICPARAM is null and C.GENERICPARAM is not null) 
OR (I.GENERICPARAM is not null and C.GENERICPARAM is null))
	OR 	( I.GROUPID <>  C.GROUPID OR (I.GROUPID is null and C.GROUPID is not null) 
OR (I.GROUPID is not null and C.GROUPID is null))
	OR 	( I.URL <>  C.URL OR (I.URL is null and C.URL is not null) 
OR (I.URL is not null and C.URL is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CONFIGURATIONITEM]') and xtype='U')
begin
	drop table CCImport_CONFIGURATIONITEM 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CONFIGURATIONITEM  to public
go
