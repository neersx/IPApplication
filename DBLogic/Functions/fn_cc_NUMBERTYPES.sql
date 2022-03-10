-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_NUMBERTYPES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_NUMBERTYPES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_NUMBERTYPES.'
	drop function dbo.fn_cc_NUMBERTYPES
	print '**** Creating function dbo.fn_cc_NUMBERTYPES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NUMBERTYPES]') and xtype='U')
begin
	select * 
	into CCImport_NUMBERTYPES 
	from NUMBERTYPES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_NUMBERTYPES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_NUMBERTYPES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NUMBERTYPES table
-- CALLED BY :	ip_CopyConfigNUMBERTYPES
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
	 null as 'Imported Numbertype',
	 null as 'Imported Description',
	 null as 'Imported Relatedeventno',
	 null as 'Imported Issuedbyipoffice',
	 null as 'Imported Displaypriority',
'D' as '-',
	 C.NUMBERTYPE as 'Numbertype',
	 C.DESCRIPTION as 'Description',
	 C.RELATEDEVENTNO as 'Relatedeventno',
	 C.ISSUEDBYIPOFFICE as 'Issuedbyipoffice',
	 C.DISPLAYPRIORITY as 'Displaypriority'
from CCImport_NUMBERTYPES I 
	right join NUMBERTYPES C on( C.NUMBERTYPE=I.NUMBERTYPE)
where I.NUMBERTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NUMBERTYPE,
	 I.DESCRIPTION,
	 I.RELATEDEVENTNO,
	 I.ISSUEDBYIPOFFICE,
	 I.DISPLAYPRIORITY,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_NUMBERTYPES I 
	left join NUMBERTYPES C on( C.NUMBERTYPE=I.NUMBERTYPE)
where C.NUMBERTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.NUMBERTYPE,
	 I.DESCRIPTION,
	 I.RELATEDEVENTNO,
	 I.ISSUEDBYIPOFFICE,
	 I.DISPLAYPRIORITY,
'U',
	 C.NUMBERTYPE,
	 C.DESCRIPTION,
	 C.RELATEDEVENTNO,
	 C.ISSUEDBYIPOFFICE,
	 C.DISPLAYPRIORITY
from CCImport_NUMBERTYPES I 
	join NUMBERTYPES C	on ( C.NUMBERTYPE=I.NUMBERTYPE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.RELATEDEVENTNO <>  C.RELATEDEVENTNO OR (I.RELATEDEVENTNO is null and C.RELATEDEVENTNO is not null) 
OR (I.RELATEDEVENTNO is not null and C.RELATEDEVENTNO is null))
	OR 	( I.ISSUEDBYIPOFFICE <>  C.ISSUEDBYIPOFFICE OR (I.ISSUEDBYIPOFFICE is null and C.ISSUEDBYIPOFFICE is not null) 
OR (I.ISSUEDBYIPOFFICE is not null and C.ISSUEDBYIPOFFICE is null))
	OR 	( I.DISPLAYPRIORITY <>  C.DISPLAYPRIORITY OR (I.DISPLAYPRIORITY is null and C.DISPLAYPRIORITY is not null) 
OR (I.DISPLAYPRIORITY is not null and C.DISPLAYPRIORITY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NUMBERTYPES]') and xtype='U')
begin
	drop table CCImport_NUMBERTYPES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_NUMBERTYPES  to public
go
