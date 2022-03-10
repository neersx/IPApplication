-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnINSTRUCTIONS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnINSTRUCTIONS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnINSTRUCTIONS.'
	drop function dbo.fn_ccnINSTRUCTIONS
	print '**** Creating function dbo.fn_ccnINSTRUCTIONS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONS]') and xtype='U')
begin
	select * 
	into CCImport_INSTRUCTIONS 
	from INSTRUCTIONS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnINSTRUCTIONS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnINSTRUCTIONS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INSTRUCTIONS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'INSTRUCTIONS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_INSTRUCTIONS I 
	right join INSTRUCTIONS C on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
where I.INSTRUCTIONCODE is null
UNION ALL 
select	5, 'INSTRUCTIONS', 0, count(*), 0, 0
from CCImport_INSTRUCTIONS I 
	left join INSTRUCTIONS C on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
where C.INSTRUCTIONCODE is null
UNION ALL 
 select	5, 'INSTRUCTIONS', 0, 0, count(*), 0
from CCImport_INSTRUCTIONS I 
	join INSTRUCTIONS C	on ( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
where 	( I.INSTRUCTIONTYPE <>  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is not null) 
OR (I.INSTRUCTIONTYPE is not null and C.INSTRUCTIONTYPE is null))
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
UNION ALL 
 select	5, 'INSTRUCTIONS', 0, 0, 0, count(*)
from CCImport_INSTRUCTIONS I 
join INSTRUCTIONS C	on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE)
where ( I.INSTRUCTIONTYPE =  C.INSTRUCTIONTYPE OR (I.INSTRUCTIONTYPE is null and C.INSTRUCTIONTYPE is null))
and ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONS]') and xtype='U')
begin
	drop table CCImport_INSTRUCTIONS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnINSTRUCTIONS  to public
go
