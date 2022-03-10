-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ELEMENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ELEMENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ELEMENT.'
	drop function dbo.fn_cc_ELEMENT
	print '**** Creating function dbo.fn_cc_ELEMENT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ELEMENT]') and xtype='U')
begin
	select * 
	into CCImport_ELEMENT 
	from ELEMENT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ELEMENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ELEMENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ELEMENT table
-- CALLED BY :	ip_CopyConfigELEMENT
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
	 null as 'Imported Element',
	 null as 'Imported Elementcode',
	 null as 'Imported Editattribute',
'D' as '-',
	 C.ELEMENT as 'Element',
	 C.ELEMENTCODE as 'Elementcode',
	 C.EDITATTRIBUTE as 'Editattribute'
from CCImport_ELEMENT I 
	right join ELEMENT C on( C.ELEMENTNO=I.ELEMENTNO)
where I.ELEMENTNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ELEMENT,
	 I.ELEMENTCODE,
	 I.EDITATTRIBUTE,
'I',
	 null ,
	 null ,
	 null
from CCImport_ELEMENT I 
	left join ELEMENT C on( C.ELEMENTNO=I.ELEMENTNO)
where C.ELEMENTNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ELEMENT,
	 I.ELEMENTCODE,
	 I.EDITATTRIBUTE,
'U',
	 C.ELEMENT,
	 C.ELEMENTCODE,
	 C.EDITATTRIBUTE
from CCImport_ELEMENT I 
	join ELEMENT C	on ( C.ELEMENTNO=I.ELEMENTNO)
where 	( I.ELEMENT <>  C.ELEMENT)
	OR 	( I.ELEMENTCODE <>  C.ELEMENTCODE)
	OR 	( I.EDITATTRIBUTE <>  C.EDITATTRIBUTE OR (I.EDITATTRIBUTE is null and C.EDITATTRIBUTE is not null) 
OR (I.EDITATTRIBUTE is not null and C.EDITATTRIBUTE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ELEMENT]') and xtype='U')
begin
	drop table CCImport_ELEMENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ELEMENT  to public
go
