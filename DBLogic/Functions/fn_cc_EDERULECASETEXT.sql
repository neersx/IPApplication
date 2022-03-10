-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EDERULECASETEXT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EDERULECASETEXT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EDERULECASETEXT.'
	drop function dbo.fn_cc_EDERULECASETEXT
	print '**** Creating function dbo.fn_cc_EDERULECASETEXT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASETEXT]') and xtype='U')
begin
	select * 
	into CCImport_EDERULECASETEXT 
	from EDERULECASETEXT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EDERULECASETEXT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EDERULECASETEXT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULECASETEXT table
-- CALLED BY :	ip_CopyConfigEDERULECASETEXT
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
	 null as 'Imported Texttype',
	 null as 'Imported Text',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.TEXTTYPE as 'Texttype',
	 C.TEXT as 'Text'
from CCImport_EDERULECASETEXT I 
	right join EDERULECASETEXT C on( C.CRITERIANO=I.CRITERIANO
and  C.TEXTTYPE=I.TEXTTYPE)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.TEXTTYPE,
	 I.TEXT,
'I',
	 null ,
	 null ,
	 null
from CCImport_EDERULECASETEXT I 
	left join EDERULECASETEXT C on( C.CRITERIANO=I.CRITERIANO
and  C.TEXTTYPE=I.TEXTTYPE)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.TEXTTYPE,
	 I.TEXT,
'U',
	 C.CRITERIANO,
	 C.TEXTTYPE,
	 C.TEXT
from CCImport_EDERULECASETEXT I 
	join EDERULECASETEXT C	on ( C.CRITERIANO=I.CRITERIANO
	and C.TEXTTYPE=I.TEXTTYPE)
where 	( I.TEXT <>  C.TEXT OR (I.TEXT is null and C.TEXT is not null) 
OR (I.TEXT is not null and C.TEXT is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULECASETEXT]') and xtype='U')
begin
	drop table CCImport_EDERULECASETEXT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EDERULECASETEXT  to public
go
