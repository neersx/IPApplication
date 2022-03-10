-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTOPICUSAGE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTOPICUSAGE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTOPICUSAGE.'
	drop function dbo.fn_ccnTOPICUSAGE
	print '**** Creating function dbo.fn_ccnTOPICUSAGE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICUSAGE]') and xtype='U')
begin
	select * 
	into CCImport_TOPICUSAGE 
	from TOPICUSAGE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTOPICUSAGE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTOPICUSAGE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICUSAGE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 10 Apr 2017	MF	71020	1	Function generated
--
As 
Return
select	6 as TRIPNO, 'TOPICUSAGE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TOPICUSAGE I 
	right join TOPICUSAGE C on( C.TOPICNAME=I.TOPICNAME)
where I.TOPICNAME is null
UNION ALL 
select	6, 'TOPICUSAGE', 0, count(*), 0, 0
from CCImport_TOPICUSAGE I 
	left join TOPICUSAGE C on( C.TOPICNAME=I.TOPICNAME)
where C.TOPICNAME is null
UNION ALL 
 select	6, 'TOPICUSAGE', 0, 0, count(*), 0
from CCImport_TOPICUSAGE I 
	join TOPICUSAGE C	on ( C.TOPICNAME=I.TOPICNAME)
where 	( I.TOPICTITLE <>  C.TOPICTITLE OR (I.TOPICTITLE is null and C.TOPICTITLE is not null) 
OR (I.TOPICTITLE is not null and C.TOPICTITLE is null))
	OR 	( I.TYPE <>  C.TYPE OR (I.TYPE is null and C.TYPE is not null) 
OR (I.TYPE is not null and C.TYPE is null))
UNION ALL 
 select	6, 'TOPICUSAGE', 0, 0, 0, count(*)
from CCImport_TOPICUSAGE I 
join TOPICUSAGE C	on( C.TOPICNAME=I.TOPICNAME)
where ( I.TOPICTITLE =  C.TOPICTITLE OR (I.TOPICTITLE is null and C.TOPICTITLE is null))
and   ( I.TYPE       =  C.TYPE       OR (I.TYPE       is null and C.TYPE       is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICUSAGE]') and xtype='U')
begin
	drop table CCImport_TOPICUSAGE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTOPICUSAGE  to public
go
