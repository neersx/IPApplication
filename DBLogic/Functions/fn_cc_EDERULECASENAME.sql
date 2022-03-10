-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EDERULECASENAME
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EDERULECASENAME]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EDERULECASENAME.'
	drop function dbo.fn_cc_EDERULECASENAME
	print '**** Creating function dbo.fn_cc_EDERULECASENAME...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASENAME]') and xtype='U')
begin
	select * 
	into CCImport_EDERULECASENAME 
	from EDERULECASENAME
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EDERULECASENAME
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EDERULECASENAME
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULECASENAME table
-- CALLED BY :	ip_CopyConfigEDERULECASENAME
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
	 null as 'Imported Criteriano',
	 null as 'Imported Nametype',
	 null as 'Imported Nameno',
	 null as 'Imported Referenceno',
	 null as 'Imported Correspondname',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.NAMETYPE as 'Nametype',
	 C.NAMENO as 'Nameno',
	 C.REFERENCENO as 'Referenceno',
	 C.CORRESPONDNAME as 'Correspondname'
from CCImport_EDERULECASENAME I 
	right join EDERULECASENAME C on( C.CRITERIANO=I.CRITERIANO
and  C.NAMETYPE=I.NAMETYPE)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.NAMETYPE,
	 I.NAMENO,
	 I.REFERENCENO,
	 I.CORRESPONDNAME,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EDERULECASENAME I 
	left join EDERULECASENAME C on( C.CRITERIANO=I.CRITERIANO
and  C.NAMETYPE=I.NAMETYPE)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.NAMETYPE,
	 I.NAMENO,
	 I.REFERENCENO,
	 I.CORRESPONDNAME,
'U',
	 C.CRITERIANO,
	 C.NAMETYPE,
	 C.NAMENO,
	 C.REFERENCENO,
	 C.CORRESPONDNAME
from CCImport_EDERULECASENAME I 
	join EDERULECASENAME C	on ( C.CRITERIANO=I.CRITERIANO
	and C.NAMETYPE=I.NAMETYPE)
where 	( I.NAMENO <>  C.NAMENO OR (I.NAMENO is null and C.NAMENO is not null) 
OR (I.NAMENO is not null and C.NAMENO is null))
	OR 	( I.REFERENCENO <>  C.REFERENCENO OR (I.REFERENCENO is null and C.REFERENCENO is not null) 
OR (I.REFERENCENO is not null and C.REFERENCENO is null))
	OR 	( I.CORRESPONDNAME <>  C.CORRESPONDNAME OR (I.CORRESPONDNAME is null and C.CORRESPONDNAME is not null) 
OR (I.CORRESPONDNAME is not null and C.CORRESPONDNAME is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASENAME]') and xtype='U')
begin
	drop table CCImport_EDERULECASENAME 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EDERULECASENAME  to public
go
