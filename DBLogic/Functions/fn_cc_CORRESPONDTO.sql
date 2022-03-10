-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CORRESPONDTO
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CORRESPONDTO]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CORRESPONDTO.'
	drop function dbo.fn_cc_CORRESPONDTO
	print '**** Creating function dbo.fn_cc_CORRESPONDTO...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CORRESPONDTO]') and xtype='U')
begin
	select * 
	into CCImport_CORRESPONDTO 
	from CORRESPONDTO
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CORRESPONDTO
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CORRESPONDTO
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CORRESPONDTO table
-- CALLED BY :	ip_CopyConfigCORRESPONDTO
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
	 null as 'Imported Correspondtype',
	 null as 'Imported Description',
	 null as 'Imported Nametype',
	 null as 'Imported Copiesto',
'D' as '-',
	 C.CORRESPONDTYPE as 'Correspondtype',
	 C.DESCRIPTION as 'Description',
	 C.NAMETYPE as 'Nametype',
	 C.COPIESTO as 'Copiesto'
from CCImport_CORRESPONDTO I 
	right join CORRESPONDTO C on( C.CORRESPONDTYPE=I.CORRESPONDTYPE)
where I.CORRESPONDTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CORRESPONDTYPE,
	 I.DESCRIPTION,
	 I.NAMETYPE,
	 I.COPIESTO,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_CORRESPONDTO I 
	left join CORRESPONDTO C on( C.CORRESPONDTYPE=I.CORRESPONDTYPE)
where C.CORRESPONDTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CORRESPONDTYPE,
	 I.DESCRIPTION,
	 I.NAMETYPE,
	 I.COPIESTO,
'U',
	 C.CORRESPONDTYPE,
	 C.DESCRIPTION,
	 C.NAMETYPE,
	 C.COPIESTO
from CCImport_CORRESPONDTO I 
	join CORRESPONDTO C	on ( C.CORRESPONDTYPE=I.CORRESPONDTYPE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.COPIESTO <>  C.COPIESTO OR (I.COPIESTO is null and C.COPIESTO is not null) 
OR (I.COPIESTO is not null and C.COPIESTO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CORRESPONDTO]') and xtype='U')
begin
	drop table CCImport_CORRESPONDTO 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CORRESPONDTO  to public
go
