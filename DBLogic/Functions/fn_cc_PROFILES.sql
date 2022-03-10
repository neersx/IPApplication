-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PROFILES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PROFILES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PROFILES.'
	drop function dbo.fn_cc_PROFILES
	print '**** Creating function dbo.fn_cc_PROFILES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILES]') and xtype='U')
begin
	select * 
	into CCImport_PROFILES 
	from PROFILES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PROFILES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PROFILES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFILES table
-- CALLED BY :	ip_CopyConfigPROFILES
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
	 null as 'Imported Profilename',
	 null as 'Imported Description',
'D' as '-',
	 C.PROFILENAME as 'Profilename',
	 C.DESCRIPTION as 'Description'
from CCImport_PROFILES I 
	right join PROFILES C on( C.PROFILEID=I.PROFILEID)
where I.PROFILEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PROFILENAME,
	 I.DESCRIPTION,
'I',
	 null ,
	 null
from CCImport_PROFILES I 
	left join PROFILES C on( C.PROFILEID=I.PROFILEID)
where C.PROFILEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.PROFILENAME,
	 I.DESCRIPTION,
'U',
	 C.PROFILENAME,
	 C.DESCRIPTION
from CCImport_PROFILES I 
	join PROFILES C	on ( C.PROFILEID=I.PROFILEID)
where 	( I.PROFILENAME <>  C.PROFILENAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILES]') and xtype='U')
begin
	drop table CCImport_PROFILES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PROFILES  to public
go
