-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FIELDCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FIELDCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FIELDCONTROL.'
	drop function dbo.fn_cc_FIELDCONTROL
	print '**** Creating function dbo.fn_cc_FIELDCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FIELDCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_FIELDCONTROL 
	from FIELDCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_FIELDCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FIELDCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FIELDCONTROL table
-- CALLED BY :	ip_CopyConfigFIELDCONTROL
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
	 null as 'Imported Screenname',
	 null as 'Imported Screenid',
	 null as 'Imported Fieldname',
	 null as 'Imported Attributes',
	 null as 'Imported Fieldliteral',
	 null as 'Imported Inherited',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.SCREENNAME as 'Screenname',
	 C.SCREENID as 'Screenid',
	 C.FIELDNAME as 'Fieldname',
	 C.ATTRIBUTES as 'Attributes',
	 C.FIELDLITERAL as 'Fieldliteral',
	 C.INHERITED as 'Inherited'
from CCImport_FIELDCONTROL I 
	right join FIELDCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.SCREENNAME=I.SCREENNAME
and  C.SCREENID=I.SCREENID
and  C.FIELDNAME=I.FIELDNAME)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.SCREENNAME,
	 I.SCREENID,
	 I.FIELDNAME,
	 I.ATTRIBUTES,
	 I.FIELDLITERAL,
	 I.INHERITED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_FIELDCONTROL I 
	left join FIELDCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.SCREENNAME=I.SCREENNAME
and  C.SCREENID=I.SCREENID
and  C.FIELDNAME=I.FIELDNAME)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.SCREENNAME,
	 I.SCREENID,
	 I.FIELDNAME,
	 I.ATTRIBUTES,
	 I.FIELDLITERAL,
	 I.INHERITED,
'U',
	 C.CRITERIANO,
	 C.SCREENNAME,
	 C.SCREENID,
	 C.FIELDNAME,
	 C.ATTRIBUTES,
	 C.FIELDLITERAL,
	 C.INHERITED
from CCImport_FIELDCONTROL I 
	join FIELDCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
	and C.SCREENNAME=I.SCREENNAME
	and C.SCREENID=I.SCREENID
	and C.FIELDNAME=I.FIELDNAME)
where 	( I.ATTRIBUTES <>  C.ATTRIBUTES OR (I.ATTRIBUTES is null and C.ATTRIBUTES is not null) 
OR (I.ATTRIBUTES is not null and C.ATTRIBUTES is null))
	OR 	( I.FIELDLITERAL <>  C.FIELDLITERAL OR (I.FIELDLITERAL is null and C.FIELDLITERAL is not null) 
OR (I.FIELDLITERAL is not null and C.FIELDLITERAL is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FIELDCONTROL]') and xtype='U')
begin
	drop table CCImport_FIELDCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FIELDCONTROL  to public
go
