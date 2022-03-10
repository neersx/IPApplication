-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDATAVIEW
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDATAVIEW]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDATAVIEW.'
	drop function dbo.fn_ccnDATAVIEW
	print '**** Creating function dbo.fn_ccnDATAVIEW...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DATAVIEW]') and xtype='U')
begin
	select * 
	into CCImport_DATAVIEW 
	from DATAVIEW
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDATAVIEW
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDATAVIEW
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DATAVIEW table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'DATAVIEW' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DATAVIEW I 
	right join DATAVIEW C on( C.VIEWID=I.VIEWID)
where I.VIEWID is null
UNION ALL 
select	6, 'DATAVIEW', 0, count(*), 0, 0
from CCImport_DATAVIEW I 
	left join DATAVIEW C on( C.VIEWID=I.VIEWID)
where C.VIEWID is null
UNION ALL 
 select	6, 'DATAVIEW', 0, 0, count(*), 0
from CCImport_DATAVIEW I 
	join DATAVIEW C	on ( C.VIEWID=I.VIEWID)
where 	( I.CATEGORY <>  C.CATEGORY)
	OR 	( I.TITLE <>  C.TITLE)
	OR 	( replace(CAST(I.DESCRIPTION as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.DESCRIPTION as NVARCHAR(MAX)) OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null) 
OR (I.IDENTITYID is not null and C.IDENTITYID is null))
	OR 	( I.STYLE <>  C.STYLE)
	OR 	( I.SORTID <>  C.SORTID OR (I.SORTID is null and C.SORTID is not null) 
OR (I.SORTID is not null and C.SORTID is null))
	OR 	( I.FILTERID <>  C.FILTERID OR (I.FILTERID is null and C.FILTERID is not null) 
OR (I.FILTERID is not null and C.FILTERID is null))
	OR 	( I.FORMATID <>  C.FORMATID OR (I.FORMATID is null and C.FORMATID is not null) 
OR (I.FORMATID is not null and C.FORMATID is null))
UNION ALL 
 select	6, 'DATAVIEW', 0, 0, 0, count(*)
from CCImport_DATAVIEW I 
join DATAVIEW C	on( C.VIEWID=I.VIEWID)
where ( I.CATEGORY =  C.CATEGORY)
and ( I.TITLE =  C.TITLE)
and ( replace(CAST(I.DESCRIPTION as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.DESCRIPTION as NVARCHAR(MAX)) OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.IDENTITYID =  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is null))
and ( I.STYLE =  C.STYLE)
and ( I.SORTID =  C.SORTID OR (I.SORTID is null and C.SORTID is null))
and ( I.FILTERID =  C.FILTERID OR (I.FILTERID is null and C.FILTERID is null))
and ( I.FORMATID =  C.FORMATID OR (I.FORMATID is null and C.FORMATID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DATAVIEW]') and xtype='U')
begin
	drop table CCImport_DATAVIEW 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDATAVIEW  to public
go
