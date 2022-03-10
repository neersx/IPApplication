-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_RESOURCE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_RESOURCE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_RESOURCE.'
	drop function dbo.fn_cc_RESOURCE
	print '**** Creating function dbo.fn_cc_RESOURCE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RESOURCE]') and xtype='U')
begin
	select * 
	into CCImport_RESOURCE 
	from RESOURCE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_RESOURCE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_RESOURCE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RESOURCE table
-- CALLED BY :	ip_CopyConfigRESOURCE
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
	 null as 'Imported Resourceno',
	 null as 'Imported Type',
	 null as 'Imported Description',
	 null as 'Imported Resource',
	 null as 'Imported Driver',
	 null as 'Imported Port',
'D' as '-',
	 C.RESOURCENO as 'Resourceno',
	 C.TYPE as 'Type',
	 C.DESCRIPTION as 'Description',
	 C.RESOURCE as 'Resource',
	 C.DRIVER as 'Driver',
	 C.PORT as 'Port'
from CCImport_RESOURCE I 
	right join RESOURCE C on( C.RESOURCENO=I.RESOURCENO)
where I.RESOURCENO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.RESOURCENO,
	 I.TYPE,
	 I.DESCRIPTION,
	 I.RESOURCE,
	 I.DRIVER,
	 I.PORT,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_RESOURCE I 
	left join RESOURCE C on( C.RESOURCENO=I.RESOURCENO)
where C.RESOURCENO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.RESOURCENO,
	 I.TYPE,
	 I.DESCRIPTION,
	 I.RESOURCE,
	 I.DRIVER,
	 I.PORT,
'U',
	 C.RESOURCENO,
	 C.TYPE,
	 C.DESCRIPTION,
	 C.RESOURCE,
	 C.DRIVER,
	 C.PORT
from CCImport_RESOURCE I 
	join RESOURCE C	on ( C.RESOURCENO=I.RESOURCENO)
where 	( I.TYPE <>  C.TYPE)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	(replace( I.RESOURCE,char(10),char(13)+char(10)) <>  C.RESOURCE OR (I.RESOURCE is null and C.RESOURCE is not null) 
OR (I.RESOURCE is not null and C.RESOURCE is null))
	OR 	(replace( I.DRIVER,char(10),char(13)+char(10)) <>  C.DRIVER OR (I.DRIVER is null and C.DRIVER is not null) 
OR (I.DRIVER is not null and C.DRIVER is null))
	OR 	(replace( I.PORT,char(10),char(13)+char(10)) <>  C.PORT OR (I.PORT is null and C.PORT is not null) 
OR (I.PORT is not null and C.PORT is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RESOURCE]') and xtype='U')
begin
	drop table CCImport_RESOURCE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_RESOURCE  to public
go
