-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSCREENS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSCREENS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSCREENS.'
	drop function dbo.fn_ccnSCREENS
	print '**** Creating function dbo.fn_ccnSCREENS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SCREENS]') and xtype='U')
begin
	select * 
	into CCImport_SCREENS 
	from SCREENS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSCREENS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSCREENS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SCREENS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'SCREENS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_SCREENS I 
	right join SCREENS C on( C.SCREENNAME=I.SCREENNAME)
where I.SCREENNAME is null
UNION ALL 
select	5, 'SCREENS', 0, count(*), 0, 0
from CCImport_SCREENS I 
	left join SCREENS C on( C.SCREENNAME=I.SCREENNAME)
where C.SCREENNAME is null
UNION ALL 
 select	5, 'SCREENS', 0, 0, count(*), 0
from CCImport_SCREENS I 
	join SCREENS C	on ( C.SCREENNAME=I.SCREENNAME)
where 	( I.SCREENTITLE <>  C.SCREENTITLE OR (I.SCREENTITLE is null and C.SCREENTITLE is not null) 
OR (I.SCREENTITLE is not null and C.SCREENTITLE is null))
	OR 	( I.SCREENTYPE <>  C.SCREENTYPE OR (I.SCREENTYPE is null and C.SCREENTYPE is not null) 
OR (I.SCREENTYPE is not null and C.SCREENTYPE is null))
	OR 	( replace(CAST(I.SCREENIMAGE as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.SCREENIMAGE as NVARCHAR(MAX)) OR (I.SCREENIMAGE is null and C.SCREENIMAGE is not null) 
OR (I.SCREENIMAGE is not null and C.SCREENIMAGE is null))
UNION ALL 
 select	5, 'SCREENS', 0, 0, 0, count(*)
from CCImport_SCREENS I 
join SCREENS C	on( C.SCREENNAME=I.SCREENNAME)
where ( I.SCREENTITLE =  C.SCREENTITLE OR (I.SCREENTITLE is null and C.SCREENTITLE is null))
and ( I.SCREENTYPE =  C.SCREENTYPE OR (I.SCREENTYPE is null and C.SCREENTYPE is null))
and ( replace(CAST(I.SCREENIMAGE as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.SCREENIMAGE as NVARCHAR(MAX)) OR (I.SCREENIMAGE is null and C.SCREENIMAGE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SCREENS]') and xtype='U')
begin
	drop table CCImport_SCREENS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSCREENS  to public
go
