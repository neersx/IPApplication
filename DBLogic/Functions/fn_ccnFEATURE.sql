-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFEATURE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFEATURE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFEATURE.'
	drop function dbo.fn_ccnFEATURE
	print '**** Creating function dbo.fn_ccnFEATURE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEATURE]') and xtype='U')
begin
	select * 
	into CCImport_FEATURE 
	from FEATURE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnFEATURE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFEATURE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEATURE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'FEATURE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FEATURE I 
	right join FEATURE C on( C.FEATUREID=I.FEATUREID)
where I.FEATUREID is null
UNION ALL 
select	6, 'FEATURE', 0, count(*), 0, 0
from CCImport_FEATURE I 
	left join FEATURE C on( C.FEATUREID=I.FEATUREID)
where C.FEATUREID is null
UNION ALL 
 select	6, 'FEATURE', 0, 0, count(*), 0
from CCImport_FEATURE I 
	join FEATURE C	on ( C.FEATUREID=I.FEATUREID)
where 	( I.FEATURENAME <>  C.FEATURENAME)
	OR 	( I.CATEGORYID <>  C.CATEGORYID OR (I.CATEGORYID is null and C.CATEGORYID is not null) 
OR (I.CATEGORYID is not null and C.CATEGORYID is null))
	OR 	( I.ISEXTERNAL <>  C.ISEXTERNAL)
	OR 	( I.ISINTERNAL <>  C.ISINTERNAL)
UNION ALL 
 select	6, 'FEATURE', 0, 0, 0, count(*)
from CCImport_FEATURE I 
join FEATURE C	on( C.FEATUREID=I.FEATUREID)
where ( I.FEATURENAME =  C.FEATURENAME)
and ( I.CATEGORYID =  C.CATEGORYID OR (I.CATEGORYID is null and C.CATEGORYID is null))
and ( I.ISEXTERNAL =  C.ISEXTERNAL)
and ( I.ISINTERNAL =  C.ISINTERNAL)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEATURE]') and xtype='U')
begin
	drop table CCImport_FEATURE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFEATURE  to public
go
