-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDELIVERYMETHOD
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDELIVERYMETHOD]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDELIVERYMETHOD.'
	drop function dbo.fn_ccnDELIVERYMETHOD
	print '**** Creating function dbo.fn_ccnDELIVERYMETHOD...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnDELIVERYMETHOD
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDELIVERYMETHOD
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DELIVERYMETHOD table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'DELIVERYMETHOD' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DELIVERYMETHOD I 
	right join DELIVERYMETHOD C on( C.DELIVERYID=I.DELIVERYID)
where I.DELIVERYID is null
UNION ALL 
select	2, 'DELIVERYMETHOD', 0, count(*), 0, 0
from CCImport_DELIVERYMETHOD I 
	left join DELIVERYMETHOD C on( C.DELIVERYID=I.DELIVERYID)
where C.DELIVERYID is null
UNION ALL 
 select	2, 'DELIVERYMETHOD', 0, 0, count(*), 0
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
UNION ALL 
 select	2, 'DELIVERYMETHOD', 0, 0, 0, count(*)
from CCImport_DELIVERYMETHOD I 
join DELIVERYMETHOD C	on( C.DELIVERYID=I.DELIVERYID)
where ( I.DELIVERYTYPE =  C.DELIVERYTYPE OR (I.DELIVERYTYPE is null and C.DELIVERYTYPE is null))
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and (replace( I.MACRO,char(10),char(13)+char(10)) =  C.MACRO OR (I.MACRO is null and C.MACRO is null))
and (replace( I.FILEDESTINATION,char(10),char(13)+char(10)) =  C.FILEDESTINATION OR (I.FILEDESTINATION is null and C.FILEDESTINATION is null))
and ( I.RESOURCENO =  C.RESOURCENO OR (I.RESOURCENO is null and C.RESOURCENO is null))
and ( I.DESTINATIONSP =  C.DESTINATIONSP OR (I.DESTINATIONSP is null and C.DESTINATIONSP is null))
and ( replace(CAST(I.DIGITALCERTIFICATE as NVARCHAR(MAX)),char(10),char(13)+char(10)) =  CAST(C.DIGITALCERTIFICATE as NVARCHAR(MAX)) OR (I.DIGITALCERTIFICATE is null and C.DIGITALCERTIFICATE is null))
and ( I.EMAILSP =  C.EMAILSP OR (I.EMAILSP is null and C.EMAILSP is null))
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DELIVERYMETHOD]') and xtype='U')
begin
	drop table CCImport_DELIVERYMETHOD 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDELIVERYMETHOD  to public
go

