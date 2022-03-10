-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnMODULECONFIGURATIO_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnMODULECONFIGURATIO_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnMODULECONFIGURATIO_.'
	drop function dbo.fn_ccnMODULECONFIGURATIO_
	print '**** Creating function dbo.fn_ccnMODULECONFIGURATIO_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_MODULECONFIGURATION]') and xtype='U')
begin
	select * 
	into CCImport_MODULECONFIGURATION 
	from MODULECONFIGURATION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnMODULECONFIGURATIO_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnMODULECONFIGURATIO_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the MODULECONFIGURATION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'MODULECONFIGURATION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_MODULECONFIGURATION I 
	right join MODULECONFIGURATION C on( C.CONFIGURATIONID=I.CONFIGURATIONID)
where I.CONFIGURATIONID is null
UNION ALL 
select	6, 'MODULECONFIGURATION', 0, count(*), 0, 0
from CCImport_MODULECONFIGURATION I 
	left join MODULECONFIGURATION C on( C.CONFIGURATIONID=I.CONFIGURATIONID)
where C.CONFIGURATIONID is null
UNION ALL 
 select	6, 'MODULECONFIGURATION', 0, 0, count(*), 0
from CCImport_MODULECONFIGURATION I 
	join MODULECONFIGURATION C	on ( C.CONFIGURATIONID=I.CONFIGURATIONID)
where 	( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null) 
OR (I.IDENTITYID is not null and C.IDENTITYID is null))
	OR 	( I.TABID <>  C.TABID)
	OR 	( I.MODULEID <>  C.MODULEID)
	OR 	( I.MODULESEQUENCE <>  C.MODULESEQUENCE)
	OR 	( I.PANELLOCATION <>  C.PANELLOCATION)
	OR 	( I.PORTALID <>  C.PORTALID OR (I.PORTALID is null and C.PORTALID is not null) 
OR (I.PORTALID is not null and C.PORTALID is null))
UNION ALL 
 select	6, 'MODULECONFIGURATION', 0, 0, 0, count(*)
from CCImport_MODULECONFIGURATION I 
join MODULECONFIGURATION C	on( C.CONFIGURATIONID=I.CONFIGURATIONID)
where ( I.IDENTITYID =  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is null))
and ( I.TABID =  C.TABID)
and ( I.MODULEID =  C.MODULEID)
and ( I.MODULESEQUENCE =  C.MODULESEQUENCE)
and ( I.PANELLOCATION =  C.PANELLOCATION)
and ( I.PORTALID =  C.PORTALID OR (I.PORTALID is null and C.PORTALID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_MODULECONFIGURATION]') and xtype='U')
begin
	drop table CCImport_MODULECONFIGURATION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnMODULECONFIGURATIO_  to public
go
