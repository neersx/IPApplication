-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPROFILEATTRIBUTES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPROFILEATTRIBUTES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPROFILEATTRIBUTES.'
	drop function dbo.fn_ccnPROFILEATTRIBUTES
	print '**** Creating function dbo.fn_ccnPROFILEATTRIBUTES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILEATTRIBUTES]') and xtype='U')
begin
	select * 
	into CCImport_PROFILEATTRIBUTES 
	from PROFILEATTRIBUTES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPROFILEATTRIBUTES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPROFILEATTRIBUTES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFILEATTRIBUTES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'PROFILEATTRIBUTES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PROFILEATTRIBUTES I 
	right join PROFILEATTRIBUTES C on( C.PROFILEID=I.PROFILEID
and  C.ATTRIBUTEID=I.ATTRIBUTEID)
where I.PROFILEID is null
UNION ALL 
select	6, 'PROFILEATTRIBUTES', 0, count(*), 0, 0
from CCImport_PROFILEATTRIBUTES I 
	left join PROFILEATTRIBUTES C on( C.PROFILEID=I.PROFILEID
and  C.ATTRIBUTEID=I.ATTRIBUTEID)
where C.PROFILEID is null
UNION ALL 
 select	6, 'PROFILEATTRIBUTES', 0, 0, count(*), 0
from CCImport_PROFILEATTRIBUTES I 
	join PROFILEATTRIBUTES C	on ( C.PROFILEID=I.PROFILEID
	and C.ATTRIBUTEID=I.ATTRIBUTEID)
where 	(replace( I.ATTRIBUTEVALUE,char(10),char(13)+char(10)) <>  C.ATTRIBUTEVALUE)
UNION ALL 
 select	6, 'PROFILEATTRIBUTES', 0, 0, 0, count(*)
from CCImport_PROFILEATTRIBUTES I 
join PROFILEATTRIBUTES C	on( C.PROFILEID=I.PROFILEID
and C.ATTRIBUTEID=I.ATTRIBUTEID)
where (replace( I.ATTRIBUTEVALUE,char(10),char(13)+char(10)) =  C.ATTRIBUTEVALUE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILEATTRIBUTES]') and xtype='U')
begin
	drop table CCImport_PROFILEATTRIBUTES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPROFILEATTRIBUTES  to public
go
