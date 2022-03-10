-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCONFIGURATIONITEMGROUP
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCONFIGURATIONITEMGROUP]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCONFIGURATIONITEMGROUP.'
	drop function dbo.fn_ccnCONFIGURATIONITEMGROUP
	print '**** Creating function dbo.fn_ccnCONFIGURATIONITEMGROUP...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CONFIGURATIONITEMGROUP]') and xtype='U')
begin
	select * 
	into CCImport_CONFIGURATIONITEMGROUP 
	from CONFIGURATIONITEMGROUP
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCONFIGURATIONITEMGROUP
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCONFIGURATIONITEMGROUP
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CONFIGURATIONITEMGROUP table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 22 Aug 2019	MF	DR-51238	Function created
--
As 
Return
select	6 as TRIPNO, 'CONFIGURATIONITEMGROUP' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CONFIGURATIONITEMGROUP I 
	right join CONFIGURATIONITEMGROUP C on( C.ID=I.ID)
where I.ID is null
UNION ALL 
select	6, 'CONFIGURATIONITEMGROUP', 0, count(*), 0, 0
from CCImport_CONFIGURATIONITEMGROUP I 
	left join CONFIGURATIONITEMGROUP C on( C.ID=I.ID)
where C.ID is null
UNION ALL 
 select	6, 'CONFIGURATIONITEMGROUP', 0, 0, count(*), 0
from CCImport_CONFIGURATIONITEMGROUP I 
	join CONFIGURATIONITEMGROUP C	on ( C.ID=I.ID)
where 	(replace( I.TITLE,      char(10),char(13)+char(10)) <>  C.TITLE       OR (I.TITLE       is null and C.TITLE       is not null) OR (I.TITLE       is not null and C.TITLE       is null))
OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
OR 	( I.URL                                             <>  C.URL         OR (I.URL         is null and C.URL         is not null) OR (I.URL         is not null and C.URL         is null))
UNION ALL 
 select	6, 'CONFIGURATIONITEMGROUP', 0, 0, 0, count(*)
from CCImport_CONFIGURATIONITEMGROUP I 
join CONFIGURATIONITEMGROUP C	on( C.ID=I.ID)
where (replace( I.TITLE,      char(10),char(13)+char(10)) =  C.TITLE       OR (I.TITLE       is null and C.TITLE       is null))
and   (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and   ( I.URL                                             =  C.URL         OR (I.URL         is null and C.URL         is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CONFIGURATIONITEMGROUP]') and xtype='U')
begin
	drop table CCImport_CONFIGURATIONITEMGROUP 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCONFIGURATIONITEMGROUP  to public
go
