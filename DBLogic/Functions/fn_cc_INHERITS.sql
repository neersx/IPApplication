-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_INHERITS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_INHERITS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_INHERITS.'
	drop function dbo.fn_cc_INHERITS
	print '**** Creating function dbo.fn_cc_INHERITS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INHERITS]') and xtype='U')
begin
	select * 
	into CCImport_INHERITS 
	from INHERITS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_INHERITS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_INHERITS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INHERITS table
-- CALLED BY :	ip_CopyConfigINHERITS
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
	 null as 'Imported Fromcriteria',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.FROMCRITERIA as 'Fromcriteria'
from CCImport_INHERITS I
	right join INHERITS C on( C.CRITERIANO=I.CRITERIANO
and  C.FROMCRITERIA=I.FROMCRITERIA)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.FROMCRITERIA,
'I',
	 null ,
	 null
from CCImport_INHERITS I 
	left join INHERITS C on( C.CRITERIANO=I.CRITERIANO
and  C.FROMCRITERIA=I.FROMCRITERIA)
where C.CRITERIANO is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INHERITS]') and xtype='U')
begin
	drop table CCImport_INHERITS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_INHERITS  to public
go
