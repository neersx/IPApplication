-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPROFILES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPROFILES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPROFILES.'
	drop function dbo.fn_ccnPROFILES
	print '**** Creating function dbo.fn_ccnPROFILES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILES]') and xtype='U')
begin
	select * 
	into CCImport_PROFILES 
	from PROFILES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPROFILES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPROFILES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFILES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'PROFILES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PROFILES I 
	right join PROFILES C on( C.PROFILEID=I.PROFILEID)
where I.PROFILEID is null
UNION ALL 
select	6, 'PROFILES', 0, count(*), 0, 0
from CCImport_PROFILES I 
	left join PROFILES C on( C.PROFILEID=I.PROFILEID)
where C.PROFILEID is null
UNION ALL 
 select	6, 'PROFILES', 0, 0, count(*), 0
from CCImport_PROFILES I 
	join PROFILES C	on ( C.PROFILEID=I.PROFILEID)
where 	( I.PROFILENAME <>  C.PROFILENAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
UNION ALL 
 select	6, 'PROFILES', 0, 0, 0, count(*)
from CCImport_PROFILES I 
join PROFILES C	on( C.PROFILEID=I.PROFILEID)
where ( I.PROFILENAME =  C.PROFILENAME)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILES]') and xtype='U')
begin
	drop table CCImport_PROFILES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPROFILES  to public
go
