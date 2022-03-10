-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DELIVERYMETHOD
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DELIVERYMETHOD]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DELIVERYMETHOD.'
	drop function dbo.fn_cc_DELIVERYMETHOD
	print '**** Creating function dbo.fn_cc_DELIVERYMETHOD...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DELIVERYMETHOD]') and xtype='U')
begin
	select * 
	into CCImport_DELIVERYMETHOD 
	from DELIVERYMETHOD
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DELIVERYMETHOD
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DELIVERYMETHOD
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DELIVERYMETHOD table
-- CALLED BY :	ip_CopyConfigDELIVERYMETHOD
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
	 null as 'Imported Deliveryid',
	 null as 'Imported Deliverytype',
	 null as 'Imported Description',
	 null as 'Imported Macro',
	 null as 'Imported Filedestination',
	 null as 'Imported Resourceno',
	 null as 'Imported Destinationsp',
	 null as 'Imported Digitalcertificate',
	 null as 'Imported Emailsp',
	 null as 'Imported Nametype',
'D' as '-',
	 C.DELIVERYID as 'Deliveryid',
	 C.DELIVERYTYPE as 'Deliverytype',
	 C.DESCRIPTION as 'Description',
	 C.MACRO as 'Macro',
	 C.FILEDESTINATION as 'Filedestination',
	 C.RESOURCENO as 'Resourceno',
	 C.DESTINATIONSP as 'Destinationsp',
	 CAST(C.DIGITALCERTIFICATE AS NVARCHAR(4000)) as 'Digitalcertificate',
	 C.EMAILSP as 'Emailsp',
	 C.NAMETYPE as 'Nametype'
from CCImport_DELIVERYMETHOD I 
	right join DELIVERYMETHOD C on( C.DELIVERYID=I.DELIVERYID)
where I.DELIVERYID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.DELIVERYID,
	 I.DELIVERYTYPE,
	 I.DESCRIPTION,
	 I.MACRO,
	 I.FILEDESTINATION,
	 I.RESOURCENO,
	 I.DESTINATIONSP,
	 CAST(I.DIGITALCERTIFICATE AS NVARCHAR(4000)),
	 I.EMAILSP,
	 I.NAMETYPE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_DELIVERYMETHOD I 
	left join DELIVERYMETHOD C on( C.DELIVERYID=I.DELIVERYID)
where C.DELIVERYID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.DELIVERYID,
	 I.DELIVERYTYPE,
	 I.DESCRIPTION,
	 I.MACRO,
	 I.FILEDESTINATION,
	 I.RESOURCENO,
	 I.DESTINATIONSP,
	 CAST(I.DIGITALCERTIFICATE AS NVARCHAR(4000)),
	 I.EMAILSP,
	 I.NAMETYPE,
'U',
	 C.DELIVERYID,
	 C.DELIVERYTYPE,
	 C.DESCRIPTION,
	 C.MACRO,
	 C.FILEDESTINATION,
	 C.RESOURCENO,
	 C.DESTINATIONSP,
	 CAST(C.DIGITALCERTIFICATE AS NVARCHAR(4000)),
	 C.EMAILSP,
	 C.NAMETYPE
from CCImport_DELIVERYMETHOD I 
	join DELIVERYMETHOD C	on ( C.DELIVERYID=I.DELIVERYID)
where 	( I.DELIVERYTYPE <>  C.DELIVERYTYPE OR (I.DELIVERYTYPE is null and C.DELIVERYTYPE is not null) 
OR (I.DELIVERYTYPE is not null and C.DELIVERYTYPE is null))
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	(replace( I.MACRO,char(10),char(13)+char(10)) <>  C.MACRO OR (I.MACRO is null and C.MACRO is not null) 
OR (I.MACRO is not null and C.MACRO is null))
	OR 	(replace( I.FILEDESTINATION,char(10),char(13)+char(10)) <>  C.FILEDESTINATION OR (I.FILEDESTINATION is null and C.FILEDESTINATION is not null) 
OR (I.FILEDESTINATION is not null and C.FILEDESTINATION is null))
	OR 	( I.RESOURCENO <>  C.RESOURCENO OR (I.RESOURCENO is null and C.RESOURCENO is not null) 
OR (I.RESOURCENO is not null and C.RESOURCENO is null))
	OR 	( I.DESTINATIONSP <>  C.DESTINATIONSP OR (I.DESTINATIONSP is null and C.DESTINATIONSP is not null) 
OR (I.DESTINATIONSP is not null and C.DESTINATIONSP is null))
	OR 	( replace(CAST(I.DIGITALCERTIFICATE as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.DIGITALCERTIFICATE as NVARCHAR(MAX)) OR (I.DIGITALCERTIFICATE is null and C.DIGITALCERTIFICATE is not null) 
OR (I.DIGITALCERTIFICATE is not null and C.DIGITALCERTIFICATE is null))
	OR 	( I.EMAILSP <>  C.EMAILSP OR (I.EMAILSP is null and C.EMAILSP is not null) 
OR (I.EMAILSP is not null and C.EMAILSP is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DELIVERYMETHOD]') and xtype='U')
begin
	drop table CCImport_DELIVERYMETHOD 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DELIVERYMETHOD  to public
go

