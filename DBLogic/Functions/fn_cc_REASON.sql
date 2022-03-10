-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_REASON
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_REASON]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_REASON.'
	drop function dbo.fn_cc_REASON
	print '**** Creating function dbo.fn_cc_REASON...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_REASON]') and xtype='U')
begin
	select * 
	into CCImport_REASON 
	from REASON
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_REASON
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_REASON
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the REASON table
-- CALLED BY :	ip_CopyConfigREASON
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
	 null as 'Imported Reasoncode',
	 null as 'Imported Description',
	 null as 'Imported Used_by',
	 null as 'Imported Showondebitnote',
	 null as 'Imported Isprotected',
'D' as '-',
	 C.REASONCODE as 'Reasoncode',
	 C.DESCRIPTION as 'Description',
	 C.USED_BY as 'Used_by',
	 C.SHOWONDEBITNOTE as 'Showondebitnote',
	 C.ISPROTECTED as 'Isprotected'
from CCImport_REASON I 
	right join REASON C on( C.REASONCODE=I.REASONCODE)
where I.REASONCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.REASONCODE,
	 I.DESCRIPTION,
	 I.USED_BY,
	 I.SHOWONDEBITNOTE,
	 I.ISPROTECTED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_REASON I 
	left join REASON C on( C.REASONCODE=I.REASONCODE)
where C.REASONCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.REASONCODE,
	 I.DESCRIPTION,
	 I.USED_BY,
	 I.SHOWONDEBITNOTE,
	 I.ISPROTECTED,
'U',
	 C.REASONCODE,
	 C.DESCRIPTION,
	 C.USED_BY,
	 C.SHOWONDEBITNOTE,
	 C.ISPROTECTED
from CCImport_REASON I 
	join REASON C	on ( C.REASONCODE=I.REASONCODE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.USED_BY <>  C.USED_BY OR (I.USED_BY is null and C.USED_BY is not null) 
OR (I.USED_BY is not null and C.USED_BY is null))
	OR 	( I.SHOWONDEBITNOTE <>  C.SHOWONDEBITNOTE OR (I.SHOWONDEBITNOTE is null and C.SHOWONDEBITNOTE is not null) 
OR (I.SHOWONDEBITNOTE is not null and C.SHOWONDEBITNOTE is null))
	OR 	( I.ISPROTECTED <>  C.ISPROTECTED OR (I.ISPROTECTED is null and C.ISPROTECTED is not null) 
OR (I.ISPROTECTED is not null and C.ISPROTECTED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_REASON]') and xtype='U')
begin
	drop table CCImport_REASON 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_REASON  to public
go
