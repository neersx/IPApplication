-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTOPICDATAITEMS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTOPICDATAITEMS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTOPICDATAITEMS.'
	drop function dbo.fn_ccnTOPICDATAITEMS
	print '**** Creating function dbo.fn_ccnTOPICDATAITEMS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICDATAITEMS]') and xtype='U')
begin
	select * 
	into CCImport_TOPICDATAITEMS 
	from TOPICDATAITEMS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTOPICDATAITEMS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTOPICDATAITEMS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICDATAITEMS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'TOPICDATAITEMS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TOPICDATAITEMS I 
	right join TOPICDATAITEMS C on( C.TOPICID=I.TOPICID
and  C.DATAITEMID=I.DATAITEMID)
where I.TOPICID is null
UNION ALL 
select	6, 'TOPICDATAITEMS', 0, count(*), 0, 0
from CCImport_TOPICDATAITEMS I 
	left join TOPICDATAITEMS C on( C.TOPICID=I.TOPICID
and  C.DATAITEMID=I.DATAITEMID)
where C.TOPICID is null
UNION ALL 
 select	6, 'TOPICDATAITEMS', 0, 0, 0, count(*)
from CCImport_TOPICDATAITEMS I 
join TOPICDATAITEMS C	on( C.TOPICID=I.TOPICID
and C.DATAITEMID=I.DATAITEMID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICDATAITEMS]') and xtype='U')
begin
	drop table CCImport_TOPICDATAITEMS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTOPICDATAITEMS  to public
go
