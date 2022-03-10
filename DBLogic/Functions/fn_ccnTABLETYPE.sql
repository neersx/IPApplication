-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTABLETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTABLETYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTABLETYPE.'
	drop function dbo.fn_ccnTABLETYPE
	print '**** Creating function dbo.fn_ccnTABLETYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TABLETYPE]') and xtype='U')
begin
	select * 
	into CCImport_TABLETYPE 
	from TABLETYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTABLETYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTABLETYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TABLETYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'TABLETYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TABLETYPE I 
	right join TABLETYPE C on( C.TABLETYPE=I.TABLETYPE)
where I.TABLETYPE is null
UNION ALL 
select	2, 'TABLETYPE', 0, count(*), 0, 0
from CCImport_TABLETYPE I 
	left join TABLETYPE C on( C.TABLETYPE=I.TABLETYPE)
where C.TABLETYPE is null
UNION ALL 
 select	2, 'TABLETYPE', 0, 0, count(*), 0
from CCImport_TABLETYPE I 
	join TABLETYPE C	on ( C.TABLETYPE=I.TABLETYPE)
where 	( I.TABLENAME <>  C.TABLENAME OR (I.TABLENAME is null and C.TABLENAME is not null) 
OR (I.TABLENAME is not null and C.TABLENAME is null))
	OR 	( I.MODIFIABLE <>  C.MODIFIABLE OR (I.MODIFIABLE is null and C.MODIFIABLE is not null) 
OR (I.MODIFIABLE is not null and C.MODIFIABLE is null))
	OR 	( I.ACTIVITYFLAG <>  C.ACTIVITYFLAG OR (I.ACTIVITYFLAG is null and C.ACTIVITYFLAG is not null) 
OR (I.ACTIVITYFLAG is not null and C.ACTIVITYFLAG is null))
	OR 	( I.DATABASETABLE <>  C.DATABASETABLE OR (I.DATABASETABLE is null and C.DATABASETABLE is not null) 
OR (I.DATABASETABLE is not null and C.DATABASETABLE is null))
UNION ALL 
 select	2, 'TABLETYPE', 0, 0, 0, count(*)
from CCImport_TABLETYPE I 
join TABLETYPE C	on( C.TABLETYPE=I.TABLETYPE)
where ( I.TABLENAME =  C.TABLENAME OR (I.TABLENAME is null and C.TABLENAME is null))
and ( I.MODIFIABLE =  C.MODIFIABLE OR (I.MODIFIABLE is null and C.MODIFIABLE is null))
and ( I.ACTIVITYFLAG =  C.ACTIVITYFLAG OR (I.ACTIVITYFLAG is null and C.ACTIVITYFLAG is null))
and ( I.DATABASETABLE =  C.DATABASETABLE OR (I.DATABASETABLE is null and C.DATABASETABLE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TABLETYPE]') and xtype='U')
begin
	drop table CCImport_TABLETYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTABLETYPE  to public
go
