-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCONFIGURATIONITEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCONFIGURATIONITEM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCONFIGURATIONITEM.'
	drop function dbo.fn_ccnCONFIGURATIONITEM
	print '**** Creating function dbo.fn_ccnCONFIGURATIONITEM...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnCONFIGURATIONITEM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCONFIGURATIONITEM
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the CONFIGURATIONITEM table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 11 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	6 as TRIPNO, 'CONFIGURATIONITEM' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CONFIGURATIONITEM I 
	right join CONFIGURATIONITEM C on( C.CONFIGITEMID=I.CONFIGITEMID)
where I.CONFIGITEMID is null
UNION ALL 
select	6, 'CONFIGURATIONITEM', 0, count(*), 0, 0
from CCImport_CONFIGURATIONITEM I 
	left join CONFIGURATIONITEM C on( C.CONFIGITEMID=I.CONFIGITEMID)
where C.CONFIGITEMID is null
UNION ALL 
 select	6, 'CONFIGURATIONITEM', 0, 0, count(*), 0
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
	OR	( I.GROUPID <>  C.GROUPID OR (I.GROUPID is null and C.GROUPID is not null )
OR (I.GROUPID is not null and C.GROUPID is null))
	OR	( I.URL <>  C.URL OR (I.URL is null and C.URL is not null )
OR (I.URL is not null and C.URL is null))
UNION ALL 
 select	6, 'CONFIGURATIONITEM', 0, 0, 0, count(*)
from CCImport_CONFIGURATIONITEM I 
join CONFIGURATIONITEM C	on( C.CONFIGITEMID=I.CONFIGITEMID)
where ( I.TASKID =  C.TASKID)
and ( I.CONTEXTID =  C.CONTEXTID OR (I.CONTEXTID is null and C.CONTEXTID is null))
and (replace( I.TITLE,char(10),char(13)+char(10)) =  C.TITLE OR (I.TITLE is null and C.TITLE is null))
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.GENERICPARAM =  C.GENERICPARAM OR (I.GENERICPARAM is null and C.GENERICPARAM is null))
and ( I.GROUPID =  C.GROUPID OR (I.GROUPID is null and C.GROUPID is null))
and ( I.URL =  C.URL OR (I.URL is null and C.URL is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CONFIGURATIONITEM]') and xtype='U')
begin
	drop table CCImport_CONFIGURATIONITEM 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCONFIGURATIONITEM  to public
go
