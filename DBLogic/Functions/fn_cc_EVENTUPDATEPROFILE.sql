-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EVENTUPDATEPROFILE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EVENTUPDATEPROFILE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EVENTUPDATEPROFILE.'
	drop function dbo.fn_cc_EVENTUPDATEPROFILE
	print '**** Creating function dbo.fn_cc_EVENTUPDATEPROFILE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTUPDATEPROFILE]') and xtype='U')
begin
	select * 
	into CCImport_EVENTUPDATEPROFILE 
	from EVENTUPDATEPROFILE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EVENTUPDATEPROFILE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EVENTUPDATEPROFILE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTUPDATEPROFILE table
-- CALLED BY :	ip_CopyConfigEVENTUPDATEPROFILE
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
	 null as 'Imported Profilerefno',
	 null as 'Imported Description',
	 null as 'Imported Event1no',
	 null as 'Imported Event1text',
	 null as 'Imported Event2no',
	 null as 'Imported Event2text',
	 null as 'Imported Nametype',
'D' as '-',
	 C.PROFILEREFNO as 'Profilerefno',
	 C.DESCRIPTION as 'Description',
	 C.EVENT1NO as 'Event1no',
	 C.EVENT1TEXT as 'Event1text',
	 C.EVENT2NO as 'Event2no',
	 C.EVENT2TEXT as 'Event2text',
	 C.NAMETYPE as 'Nametype'
from CCImport_EVENTUPDATEPROFILE I 
	right join EVENTUPDATEPROFILE C on( C.PROFILEREFNO=I.PROFILEREFNO)
where I.PROFILEREFNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PROFILEREFNO,
	 I.DESCRIPTION,
	 I.EVENT1NO,
	 I.EVENT1TEXT,
	 I.EVENT2NO,
	 I.EVENT2TEXT,
	 I.NAMETYPE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EVENTUPDATEPROFILE I 
	left join EVENTUPDATEPROFILE C on( C.PROFILEREFNO=I.PROFILEREFNO)
where C.PROFILEREFNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.PROFILEREFNO,
	 I.DESCRIPTION,
	 I.EVENT1NO,
	 I.EVENT1TEXT,
	 I.EVENT2NO,
	 I.EVENT2TEXT,
	 I.NAMETYPE,
'U',
	 C.PROFILEREFNO,
	 C.DESCRIPTION,
	 C.EVENT1NO,
	 C.EVENT1TEXT,
	 C.EVENT2NO,
	 C.EVENT2TEXT,
	 C.NAMETYPE
from CCImport_EVENTUPDATEPROFILE I 
	join EVENTUPDATEPROFILE C	on ( C.PROFILEREFNO=I.PROFILEREFNO)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.EVENT1NO <>  C.EVENT1NO)
	OR 	( I.EVENT1TEXT <>  C.EVENT1TEXT OR (I.EVENT1TEXT is null and C.EVENT1TEXT is not null) 
OR (I.EVENT1TEXT is not null and C.EVENT1TEXT is null))
	OR 	( I.EVENT2NO <>  C.EVENT2NO OR (I.EVENT2NO is null and C.EVENT2NO is not null) 
OR (I.EVENT2NO is not null and C.EVENT2NO is null))
	OR 	( I.EVENT2TEXT <>  C.EVENT2TEXT OR (I.EVENT2TEXT is null and C.EVENT2TEXT is not null) 
OR (I.EVENT2TEXT is not null and C.EVENT2TEXT is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTUPDATEPROFILE]') and xtype='U')
begin
	drop table CCImport_EVENTUPDATEPROFILE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EVENTUPDATEPROFILE  to public
go
