-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_GROUPMEMBERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_GROUPMEMBERS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_GROUPMEMBERS.'
	drop function dbo.fn_cc_GROUPMEMBERS
	print '**** Creating function dbo.fn_cc_GROUPMEMBERS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_GROUPMEMBERS]') and xtype='U')
begin
	select * 
	into CCImport_GROUPMEMBERS 
	from GROUPMEMBERS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_GROUPMEMBERS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_GROUPMEMBERS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the GROUPMEMBERS table
-- CALLED BY :	ip_CopyConfigGROUPMEMBERS
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
	 null as 'Imported Namegroup',
	 null as 'Imported Nametype',
'D' as '-',
	 C.NAMEGROUP as 'Namegroup',
	 C.NAMETYPE as 'Nametype'
from CCImport_GROUPMEMBERS I 
	right join GROUPMEMBERS C on( C.NAMEGROUP=I.NAMEGROUP
and  C.NAMETYPE=I.NAMETYPE)
where I.NAMEGROUP is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NAMEGROUP,
	 I.NAMETYPE,
'I',
	 null ,
	 null
from CCImport_GROUPMEMBERS I 
	left join GROUPMEMBERS C on( C.NAMEGROUP=I.NAMEGROUP
and  C.NAMETYPE=I.NAMETYPE)
where C.NAMEGROUP is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_GROUPMEMBERS]') and xtype='U')
begin
	drop table CCImport_GROUPMEMBERS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_GROUPMEMBERS  to public
go
