-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPORTALMENU
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPORTALMENU]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPORTALMENU.'
	drop function dbo.fn_ccnPORTALMENU
	print '**** Creating function dbo.fn_ccnPORTALMENU...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALMENU]') and xtype='U')
begin
	select * 
	into CCImport_PORTALMENU 
	from PORTALMENU
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPORTALMENU
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPORTALMENU
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PORTALMENU table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'PORTALMENU' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PORTALMENU I 
	right join PORTALMENU C on( C.MENUID=I.MENUID)
where I.MENUID is null
UNION ALL 
select	6, 'PORTALMENU', 0, count(*), 0, 0
from CCImport_PORTALMENU I 
	left join PORTALMENU C on( C.MENUID=I.MENUID)
where C.MENUID is null
UNION ALL 
 select	6, 'PORTALMENU', 0, 0, count(*), 0
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
UNION ALL 
 select	6, 'PORTALMENU', 0, 0, 0, count(*)
from CCImport_PORTALMENU I 
join PORTALMENU C	on( C.MENUID=I.MENUID)
where ( I.ANONYMOUSUSER =  C.ANONYMOUSUSER)
and ( I.HEADER =  C.HEADER)
and ( I.PARENTID =  C.PARENTID OR (I.PARENTID is null and C.PARENTID is null))
and (replace( I.LABEL,char(10),char(13)+char(10)) =  C.LABEL OR (I.LABEL is null and C.LABEL is null))
and ( I.SEQUENCE =  C.SEQUENCE)
and ( I.IDENTITYID =  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is null))
and ( I.OVERRIDDEN =  C.OVERRIDDEN)
and ( I.TASKID =  C.TASKID OR (I.TASKID is null and C.TASKID is null))
and (replace( I.HREF,char(10),char(13)+char(10)) =  C.HREF OR (I.HREF is null and C.HREF is null))
and ( I.VIEWID =  C.VIEWID OR (I.VIEWID is null and C.VIEWID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALMENU]') and xtype='U')
begin
	drop table CCImport_PORTALMENU 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPORTALMENU  to public
go
