------------------------------
SET NOCOUNT ON
go
-----------------------------------------------------------------------------------------------
-- Creation of fn_ccnELEMENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnELEMENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnELEMENT.'
	drop function dbo.fn_ccnELEMENT
	print '**** Creating function dbo.fn_ccnELEMENT...'
	print ''
end
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnELEMENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnELEMENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ELEMENT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'ELEMENT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ELEMENT I 
	right join ELEMENT C on( C.ELEMENTNO=I.ELEMENTNO)
where I.ELEMENTNO is null
UNION ALL 
select	6, 'ELEMENT', 0, count(*), 0, 0
from CCImport_ELEMENT I 
	left join ELEMENT C on( C.ELEMENTNO=I.ELEMENTNO)
where C.ELEMENTNO is null
UNION ALL 
 select	6, 'ELEMENT', 0, 0, count(*), 0
from CCImport_ELEMENT I 
	join ELEMENT C	on ( C.ELEMENTNO=I.ELEMENTNO)
where 	( I.ELEMENT <>  C.ELEMENT)
	OR 	( I.ELEMENTCODE <>  C.ELEMENTCODE)
	OR 	( I.EDITATTRIBUTE <>  C.EDITATTRIBUTE OR (I.EDITATTRIBUTE is null and C.EDITATTRIBUTE is not null) 
OR (I.EDITATTRIBUTE is not null and C.EDITATTRIBUTE is null))
UNION ALL 
 select	6, 'ELEMENT', 0, 0, 0, count(*)
from CCImport_ELEMENT I 
join ELEMENT C	on( C.ELEMENTNO=I.ELEMENTNO)
where ( I.ELEMENT =  C.ELEMENT)
and ( I.ELEMENTCODE =  C.ELEMENTCODE)
and ( I.EDITATTRIBUTE =  C.EDITATTRIBUTE OR (I.EDITATTRIBUTE is null and C.EDITATTRIBUTE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ELEMENT]') and xtype='U')
begin
	drop table CCImport_ELEMENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnELEMENT  to public
go
