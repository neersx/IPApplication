-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_NAMEGROUPS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_NAMEGROUPS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_NAMEGROUPS.'
	drop function dbo.fn_cc_NAMEGROUPS
	print '**** Creating function dbo.fn_cc_NAMEGROUPS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NAMEGROUPS]') and xtype='U')
begin
	select * 
	into CCImport_NAMEGROUPS 
	from NAMEGROUPS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_NAMEGROUPS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_NAMEGROUPS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NAMEGROUPS table
-- CALLED BY :	ip_CopyConfigNAMEGROUPS
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
	 null as 'Imported Groupdescription',
'D' as '-',
	 C.NAMEGROUP as 'Namegroup',
	 C.GROUPDESCRIPTION as 'Groupdescription'
from CCImport_NAMEGROUPS I 
	right join NAMEGROUPS C on( C.NAMEGROUP=I.NAMEGROUP)
where I.NAMEGROUP is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NAMEGROUP,
	 I.GROUPDESCRIPTION,
'I',
	 null ,
	 null
from CCImport_NAMEGROUPS I 
	left join NAMEGROUPS C on( C.NAMEGROUP=I.NAMEGROUP)
where C.NAMEGROUP is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.NAMEGROUP,
	 I.GROUPDESCRIPTION,
'U',
	 C.NAMEGROUP,
	 C.GROUPDESCRIPTION
from CCImport_NAMEGROUPS I 
	join NAMEGROUPS C	on ( C.NAMEGROUP=I.NAMEGROUP)
where 	( I.GROUPDESCRIPTION <>  C.GROUPDESCRIPTION OR (I.GROUPDESCRIPTION is null and C.GROUPDESCRIPTION is not null) 
OR (I.GROUPDESCRIPTION is not null and C.GROUPDESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NAMEGROUPS]') and xtype='U')
begin
	drop table CCImport_NAMEGROUPS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_NAMEGROUPS  to public
go
