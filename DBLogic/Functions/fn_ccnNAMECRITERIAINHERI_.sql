-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnNAMECRITERIAINHERI_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnNAMECRITERIAINHERI_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnNAMECRITERIAINHERI_.'
	drop function dbo.fn_ccnNAMECRITERIAINHERI_
	print '**** Creating function dbo.fn_ccnNAMECRITERIAINHERI_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NAMECRITERIAINHERITS]') and xtype='U')
begin
	select * 
	into CCImport_NAMECRITERIAINHERITS 
	from NAMECRITERIAINHERITS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnNAMECRITERIAINHERI_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnNAMECRITERIAINHERI_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NAMECRITERIAINHERITS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'NAMECRITERIAINHERITS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_NAMECRITERIAINHERITS I 
	right join NAMECRITERIAINHERITS C on( C.NAMECRITERIANO=I.NAMECRITERIANO
and  C.FROMNAMECRITERIANO=I.FROMNAMECRITERIANO)
where I.NAMECRITERIANO is null
UNION ALL 
select	5, 'NAMECRITERIAINHERITS', 0, count(*), 0, 0
from CCImport_NAMECRITERIAINHERITS I 
	left join NAMECRITERIAINHERITS C on( C.NAMECRITERIANO=I.NAMECRITERIANO
and  C.FROMNAMECRITERIANO=I.FROMNAMECRITERIANO)
where C.NAMECRITERIANO is null
UNION ALL 
 select	5, 'NAMECRITERIAINHERITS', 0, 0, 0, count(*)
from CCImport_NAMECRITERIAINHERITS I 
join NAMECRITERIAINHERITS C	on( C.NAMECRITERIANO=I.NAMECRITERIANO
and C.FROMNAMECRITERIANO=I.FROMNAMECRITERIANO)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NAMECRITERIAINHERITS]') and xtype='U')
begin
	drop table CCImport_NAMECRITERIAINHERITS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnNAMECRITERIAINHERI_  to public
go
