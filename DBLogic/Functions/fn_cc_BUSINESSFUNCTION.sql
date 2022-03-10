-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_BUSINESSFUNCTION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_BUSINESSFUNCTION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_BUSINESSFUNCTION.'
	drop function dbo.fn_cc_BUSINESSFUNCTION
	print '**** Creating function dbo.fn_cc_BUSINESSFUNCTION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_BUSINESSFUNCTION]') and xtype='U')
begin
	select * 
	into CCImport_BUSINESSFUNCTION 
	from BUSINESSFUNCTION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_BUSINESSFUNCTION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_BUSINESSFUNCTION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the BUSINESSFUNCTION table
-- CALLED BY :	ip_CopyConfigBUSINESSFUNCTION
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
	 null as 'Imported Functiontype',
	 null as 'Imported Description',
	 null as 'Imported Ownerallowed',
	 null as 'Imported Privilegesallowed',
'D' as '-',
	 C.FUNCTIONTYPE as 'Functiontype',
	 C.DESCRIPTION as 'Description',
	 C.OWNERALLOWED as 'Ownerallowed',
	 C.PRIVILEGESALLOWED as 'Privilegesallowed'
from CCImport_BUSINESSFUNCTION I 
	right join BUSINESSFUNCTION C on( C.FUNCTIONTYPE=I.FUNCTIONTYPE)
where I.FUNCTIONTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.FUNCTIONTYPE,
	 I.DESCRIPTION,
	 I.OWNERALLOWED,
	 I.PRIVILEGESALLOWED,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_BUSINESSFUNCTION I 
	left join BUSINESSFUNCTION C on( C.FUNCTIONTYPE=I.FUNCTIONTYPE)
where C.FUNCTIONTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.FUNCTIONTYPE,
	 I.DESCRIPTION,
	 I.OWNERALLOWED,
	 I.PRIVILEGESALLOWED,
'U',
	 C.FUNCTIONTYPE,
	 C.DESCRIPTION,
	 C.OWNERALLOWED,
	 C.PRIVILEGESALLOWED
from CCImport_BUSINESSFUNCTION I 
	join BUSINESSFUNCTION C	on ( C.FUNCTIONTYPE=I.FUNCTIONTYPE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.OWNERALLOWED <>  C.OWNERALLOWED)
	OR 	( I.PRIVILEGESALLOWED <>  C.PRIVILEGESALLOWED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_BUSINESSFUNCTION]') and xtype='U')
begin
	drop table CCImport_BUSINESSFUNCTION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_BUSINESSFUNCTION  to public
go

