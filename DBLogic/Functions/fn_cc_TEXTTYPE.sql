-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TEXTTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TEXTTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TEXTTYPE.'
	drop function dbo.fn_cc_TEXTTYPE
	print '**** Creating function dbo.fn_cc_TEXTTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TEXTTYPE]') and xtype='U')
begin
	select * 
	into CCImport_TEXTTYPE 
	from TEXTTYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TEXTTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TEXTTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TEXTTYPE table
-- CALLED BY :	ip_CopyConfigTEXTTYPE
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
	 null as 'Imported Texttype',
	 null as 'Imported Textdescription',
	 null as 'Imported Usedbyflag',
'D' as '-',
	 C.TEXTTYPE as 'Texttype',
	 C.TEXTDESCRIPTION as 'Textdescription',
	 C.USEDBYFLAG as 'Usedbyflag'
from CCImport_TEXTTYPE I 
	right join TEXTTYPE C on( C.TEXTTYPE=I.TEXTTYPE)
where I.TEXTTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TEXTTYPE,
	 I.TEXTDESCRIPTION,
	 I.USEDBYFLAG,
'I',
	 null ,
	 null ,
	 null
from CCImport_TEXTTYPE I 
	left join TEXTTYPE C on( C.TEXTTYPE=I.TEXTTYPE)
where C.TEXTTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TEXTTYPE,
	 I.TEXTDESCRIPTION,
	 I.USEDBYFLAG,
'U',
	 C.TEXTTYPE,
	 C.TEXTDESCRIPTION,
	 C.USEDBYFLAG
from CCImport_TEXTTYPE I 
	join TEXTTYPE C	on ( C.TEXTTYPE=I.TEXTTYPE)
where 	( I.TEXTDESCRIPTION <>  C.TEXTDESCRIPTION OR (I.TEXTDESCRIPTION is null and C.TEXTDESCRIPTION is not null) 
OR (I.TEXTDESCRIPTION is not null and C.TEXTDESCRIPTION is null))
	OR 	( I.USEDBYFLAG <>  C.USEDBYFLAG OR (I.USEDBYFLAG is null and C.USEDBYFLAG is not null) 
OR (I.USEDBYFLAG is not null and C.USEDBYFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TEXTTYPE]') and xtype='U')
begin
	drop table CCImport_TEXTTYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TEXTTYPE  to public
go
