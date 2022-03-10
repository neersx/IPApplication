-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CULTURE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CULTURE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CULTURE.'
	drop function dbo.fn_cc_CULTURE
	print '**** Creating function dbo.fn_cc_CULTURE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CULTURE]') and xtype='U')
begin
	select * 
	into CCImport_CULTURE 
	from CULTURE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CULTURE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CULTURE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CULTURE table
-- CALLED BY :	ip_CopyConfigCULTURE
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
	 null as 'Imported Culture',
	 null as 'Imported Description',
	 null as 'Imported Istranslated',
'D' as '-',
	 C.CULTURE as 'Culture',
	 C.DESCRIPTION as 'Description',
	 C.ISTRANSLATED as 'Istranslated'
from CCImport_CULTURE I 
	right join CULTURE C on( C.CULTURE=I.CULTURE)
where I.CULTURE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CULTURE,
	 I.DESCRIPTION,
	 I.ISTRANSLATED,
'I',
	 null ,
	 null ,
	 null
from CCImport_CULTURE I 
	left join CULTURE C on( C.CULTURE=I.CULTURE)
where C.CULTURE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CULTURE,
	 I.DESCRIPTION,
	 I.ISTRANSLATED,
'U',
	 C.CULTURE,
	 C.DESCRIPTION,
	 C.ISTRANSLATED
from CCImport_CULTURE I 
	join CULTURE C	on ( C.CULTURE=I.CULTURE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.ISTRANSLATED <>  C.ISTRANSLATED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CULTURE]') and xtype='U')
begin
	drop table CCImport_CULTURE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CULTURE  to public
go

