-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnMAPPING
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnMAPPING]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnMAPPING.'
	drop function dbo.fn_ccnMAPPING
	print '**** Creating function dbo.fn_ccnMAPPING...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MAPPING]') and xtype='U')
begin
	select * 
	into CCImport_MAPPING 
	from MAPPING
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnMAPPING
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnMAPPING
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MAPPING table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'MAPPING' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_MAPPING I 
	right join MAPPING C on( C.ENTRYID=I.ENTRYID)
where I.ENTRYID is null
UNION ALL 
select	9, 'MAPPING', 0, count(*), 0, 0
from CCImport_MAPPING I 
	left join MAPPING C on( C.ENTRYID=I.ENTRYID)
where C.ENTRYID is null
UNION ALL 
 select	9, 'MAPPING', 0, 0, count(*), 0
from CCImport_MAPPING I 
	join MAPPING C	on ( C.ENTRYID=I.ENTRYID)
where 	( I.STRUCTUREID <>  C.STRUCTUREID)
	OR 	( I.DATASOURCEID <>  C.DATASOURCEID OR (I.DATASOURCEID is null and C.DATASOURCEID is not null) 
OR (I.DATASOURCEID is not null and C.DATASOURCEID is null))
	OR 	( I.INPUTCODE <>  C.INPUTCODE OR (I.INPUTCODE is null and C.INPUTCODE is not null) 
OR (I.INPUTCODE is not null and C.INPUTCODE is null))
	OR 	(replace( I.INPUTDESCRIPTION,char(10),char(13)+char(10)) <>  C.INPUTDESCRIPTION OR (I.INPUTDESCRIPTION is null and C.INPUTDESCRIPTION is not null) 
OR (I.INPUTDESCRIPTION is not null and C.INPUTDESCRIPTION is null))
	OR 	( I.INPUTCODEID <>  C.INPUTCODEID OR (I.INPUTCODEID is null and C.INPUTCODEID is not null) 
OR (I.INPUTCODEID is not null and C.INPUTCODEID is null))
	OR 	( I.OUTPUTCODEID <>  C.OUTPUTCODEID OR (I.OUTPUTCODEID is null and C.OUTPUTCODEID is not null) 
OR (I.OUTPUTCODEID is not null and C.OUTPUTCODEID is null))
	OR 	( I.OUTPUTVALUE <>  C.OUTPUTVALUE OR (I.OUTPUTVALUE is null and C.OUTPUTVALUE is not null) 
OR (I.OUTPUTVALUE is not null and C.OUTPUTVALUE is null))
	OR 	( I.ISNOTAPPLICABLE <>  C.ISNOTAPPLICABLE)
UNION ALL 
 select	9, 'MAPPING', 0, 0, 0, count(*)
from CCImport_MAPPING I 
join MAPPING C	on( C.ENTRYID=I.ENTRYID)
where ( I.STRUCTUREID =  C.STRUCTUREID)
and ( I.DATASOURCEID =  C.DATASOURCEID OR (I.DATASOURCEID is null and C.DATASOURCEID is null))
and ( I.INPUTCODE =  C.INPUTCODE OR (I.INPUTCODE is null and C.INPUTCODE is null))
and (replace( I.INPUTDESCRIPTION,char(10),char(13)+char(10)) =  C.INPUTDESCRIPTION OR (I.INPUTDESCRIPTION is null and C.INPUTDESCRIPTION is null))
and ( I.INPUTCODEID =  C.INPUTCODEID OR (I.INPUTCODEID is null and C.INPUTCODEID is null))
and ( I.OUTPUTCODEID =  C.OUTPUTCODEID OR (I.OUTPUTCODEID is null and C.OUTPUTCODEID is null))
and ( I.OUTPUTVALUE =  C.OUTPUTVALUE OR (I.OUTPUTVALUE is null and C.OUTPUTVALUE is null))
and ( I.ISNOTAPPLICABLE =  C.ISNOTAPPLICABLE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MAPPING]') and xtype='U')
begin
	drop table CCImport_MAPPING 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnMAPPING  to public
go
