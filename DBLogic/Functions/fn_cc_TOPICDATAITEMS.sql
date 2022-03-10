-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TOPICDATAITEMS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TOPICDATAITEMS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TOPICDATAITEMS.'
	drop function dbo.fn_cc_TOPICDATAITEMS
	print '**** Creating function dbo.fn_cc_TOPICDATAITEMS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICDATAITEMS]') and xtype='U')
begin
	select * 
	into CCImport_TOPICDATAITEMS 
	from TOPICDATAITEMS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TOPICDATAITEMS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TOPICDATAITEMS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICDATAITEMS table
-- CALLED BY :	ip_CopyConfigTOPICDATAITEMS
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Topicid',
	 null as 'Imported Dataitemid',
'D' as '-',
	 C.TOPICID as 'Topicid',
	 C.DATAITEMID as 'Dataitemid'
from CCImport_TOPICDATAITEMS I 
	right join TOPICDATAITEMS C on( C.TOPICID=I.TOPICID
and  C.DATAITEMID=I.DATAITEMID)
where I.TOPICID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TOPICID,
	 I.DATAITEMID,
'I',
	 null ,
	 null
from CCImport_TOPICDATAITEMS I 
	left join TOPICDATAITEMS C on( C.TOPICID=I.TOPICID
and  C.DATAITEMID=I.DATAITEMID)
where C.TOPICID is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICDATAITEMS]') and xtype='U')
begin
	drop table CCImport_TOPICDATAITEMS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TOPICDATAITEMS  to public
go
