-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEVENTCATEGORY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEVENTCATEGORY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEVENTCATEGORY.'
	drop function dbo.fn_ccnEVENTCATEGORY
	print '**** Creating function dbo.fn_ccnEVENTCATEGORY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCATEGORY]') and xtype='U')
begin
	select * 
	into CCImport_EVENTCATEGORY 
	from EVENTCATEGORY
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEVENTCATEGORY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEVENTCATEGORY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTCATEGORY table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'EVENTCATEGORY' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EVENTCATEGORY I 
	right join EVENTCATEGORY C on( C.CATEGORYID=I.CATEGORYID)
where I.CATEGORYID is null
UNION ALL 
select	2, 'EVENTCATEGORY', 0, count(*), 0, 0
from CCImport_EVENTCATEGORY I 
	left join EVENTCATEGORY C on( C.CATEGORYID=I.CATEGORYID)
where C.CATEGORYID is null
UNION ALL 
 select	2, 'EVENTCATEGORY', 0, 0, count(*), 0
from CCImport_EVENTCATEGORY I 
	join EVENTCATEGORY C	on ( C.CATEGORYID=I.CATEGORYID)
where 	( I.CATEGORYNAME <>  C.CATEGORYNAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.ICONIMAGEID <>  C.ICONIMAGEID)
UNION ALL 
 select	2, 'EVENTCATEGORY', 0, 0, 0, count(*)
from CCImport_EVENTCATEGORY I 
join EVENTCATEGORY C	on( C.CATEGORYID=I.CATEGORYID)
where ( I.CATEGORYNAME =  C.CATEGORYNAME)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.ICONIMAGEID =  C.ICONIMAGEID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCATEGORY]') and xtype='U')
begin
	drop table CCImport_EVENTCATEGORY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEVENTCATEGORY  to public
go
