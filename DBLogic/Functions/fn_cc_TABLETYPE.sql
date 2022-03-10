-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TABLETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TABLETYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TABLETYPE.'
	drop function dbo.fn_cc_TABLETYPE
	print '**** Creating function dbo.fn_cc_TABLETYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TABLETYPE]') and xtype='U')
begin
	select * 
	into CCImport_TABLETYPE 
	from TABLETYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TABLETYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TABLETYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TABLETYPE table
-- CALLED BY :	ip_CopyConfigTABLETYPE
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
	 null as 'Imported Tabletype',
	 null as 'Imported Tablename',
	 null as 'Imported Modifiable',
	 null as 'Imported Activityflag',
	 null as 'Imported Databasetable',
'D' as '-',
	 C.TABLETYPE as 'Tabletype',
	 C.TABLENAME as 'Tablename',
	 C.MODIFIABLE as 'Modifiable',
	 C.ACTIVITYFLAG as 'Activityflag',
	 C.DATABASETABLE as 'Databasetable'
from CCImport_TABLETYPE I 
	right join TABLETYPE C on( C.TABLETYPE=I.TABLETYPE)
where I.TABLETYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TABLETYPE,
	 I.TABLENAME,
	 I.MODIFIABLE,
	 I.ACTIVITYFLAG,
	 I.DATABASETABLE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_TABLETYPE I 
	left join TABLETYPE C on( C.TABLETYPE=I.TABLETYPE)
where C.TABLETYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TABLETYPE,
	 I.TABLENAME,
	 I.MODIFIABLE,
	 I.ACTIVITYFLAG,
	 I.DATABASETABLE,
'U',
	 C.TABLETYPE,
	 C.TABLENAME,
	 C.MODIFIABLE,
	 C.ACTIVITYFLAG,
	 C.DATABASETABLE
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TABLETYPE]') and xtype='U')
begin
	drop table CCImport_TABLETYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TABLETYPE  to public
go
