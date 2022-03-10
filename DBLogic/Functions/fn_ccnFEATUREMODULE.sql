-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFEATUREMODULE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFEATUREMODULE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFEATUREMODULE.'
	drop function dbo.fn_ccnFEATUREMODULE
	print '**** Creating function dbo.fn_ccnFEATUREMODULE...'
	print ''
end
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEATUREMODULE]') and xtype='U')
begin
	select * 
	into CCImport_FEATUREMODULE 
	from FEATUREMODULE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnFEATUREMODULE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFEATUREMODULE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEATUREMODULE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'FEATUREMODULE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FEATUREMODULE I 
	right join FEATUREMODULE C on( C.FEATUREID=I.FEATUREID
and  C.MODULEID=I.MODULEID)
where I.FEATUREID is null
UNION ALL 
select	6, 'FEATUREMODULE', 0, count(*), 0, 0
from CCImport_FEATUREMODULE I 
	left join FEATUREMODULE C on( C.FEATUREID=I.FEATUREID
and  C.MODULEID=I.MODULEID)
where C.FEATUREID is null
UNION ALL 
 select	6, 'FEATUREMODULE', 0, 0, 0, count(*)
from CCImport_FEATUREMODULE I 
join FEATUREMODULE C	on( C.FEATUREID=I.FEATUREID
and C.MODULEID=I.MODULEID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEATUREMODULE]') and xtype='U')
begin
	drop table CCImport_FEATUREMODULE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFEATUREMODULE  to public
go
