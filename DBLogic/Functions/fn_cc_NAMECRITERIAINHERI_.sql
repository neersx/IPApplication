-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_NAMECRITERIAINHERI_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_NAMECRITERIAINHERI_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_NAMECRITERIAINHERI_.'
	drop function dbo.fn_cc_NAMECRITERIAINHERI_
	print '**** Creating function dbo.fn_cc_NAMECRITERIAINHERI_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NAMECRITERIAINHERITS]') and xtype='U')
begin
	select * 
	into CCImport_NAMECRITERIAINHERITS 
	from NAMECRITERIAINHERITS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_NAMECRITERIAINHERI_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_NAMECRITERIAINHERI_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NAMECRITERIAINHERITS table
-- CALLED BY :	ip_CopyConfigNAMECRITERIAINHERI_
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
	 null as 'Imported Namecriteriano',
	 null as 'Imported Fromnamecriteriano',
'D' as '-',
	 C.NAMECRITERIANO as 'Namecriteriano',
	 C.FROMNAMECRITERIANO as 'Fromnamecriteriano'
from CCImport_NAMECRITERIAINHERITS I 
	right join NAMECRITERIAINHERITS C on( C.NAMECRITERIANO=I.NAMECRITERIANO
and  C.FROMNAMECRITERIANO=I.FROMNAMECRITERIANO)
where I.NAMECRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NAMECRITERIANO,
	 I.FROMNAMECRITERIANO,
'I',
	 null ,
	 null
from CCImport_NAMECRITERIAINHERITS I 
	left join NAMECRITERIAINHERITS C on( C.NAMECRITERIANO=I.NAMECRITERIANO
and  C.FROMNAMECRITERIANO=I.FROMNAMECRITERIANO)
where C.NAMECRITERIANO is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NAMECRITERIAINHERITS]') and xtype='U')
begin
	drop table CCImport_NAMECRITERIAINHERITS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_NAMECRITERIAINHERI_  to public
go
