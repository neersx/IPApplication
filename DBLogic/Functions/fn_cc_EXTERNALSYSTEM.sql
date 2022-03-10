-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EXTERNALSYSTEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EXTERNALSYSTEM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EXTERNALSYSTEM.'
	drop function dbo.fn_cc_EXTERNALSYSTEM
	print '**** Creating function dbo.fn_cc_EXTERNALSYSTEM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EXTERNALSYSTEM]') and xtype='U')
begin
	select * 
	into CCImport_EXTERNALSYSTEM 
	from EXTERNALSYSTEM
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EXTERNALSYSTEM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EXTERNALSYSTEM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EXTERNALSYSTEM table
-- CALLED BY :	ip_CopyConfigEXTERNALSYSTEM
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
	 null as 'Imported Systemid',
	 null as 'Imported Systemname',
	 null as 'Imported Systemcode',
	 null as 'Imported Dataextractid',
'D' as '-',
	 C.SYSTEMID as 'Systemid',
	 C.SYSTEMNAME as 'Systemname',
	 C.SYSTEMCODE as 'Systemcode',
	 C.DATAEXTRACTID as 'Dataextractid'
from CCImport_EXTERNALSYSTEM I 
	right join EXTERNALSYSTEM C on( C.SYSTEMID=I.SYSTEMID)
where I.SYSTEMID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SYSTEMID,
	 I.SYSTEMNAME,
	 I.SYSTEMCODE,
	 I.DATAEXTRACTID,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EXTERNALSYSTEM I 
	left join EXTERNALSYSTEM C on( C.SYSTEMID=I.SYSTEMID)
where C.SYSTEMID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SYSTEMID,
	 I.SYSTEMNAME,
	 I.SYSTEMCODE,
	 I.DATAEXTRACTID,
'U',
	 C.SYSTEMID,
	 C.SYSTEMNAME,
	 C.SYSTEMCODE,
	 C.DATAEXTRACTID
from CCImport_EXTERNALSYSTEM I 
	join EXTERNALSYSTEM C	on ( C.SYSTEMID=I.SYSTEMID)
where 	( I.SYSTEMNAME <>  C.SYSTEMNAME)
	OR 	( I.SYSTEMCODE <>  C.SYSTEMCODE)
	OR 	( I.DATAEXTRACTID <>  C.DATAEXTRACTID OR (I.DATAEXTRACTID is null and C.DATAEXTRACTID is not null) 
OR (I.DATAEXTRACTID is not null and C.DATAEXTRACTID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EXTERNALSYSTEM]') and xtype='U')
begin
	drop table CCImport_EXTERNALSYSTEM 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EXTERNALSYSTEM  to public
go

