-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnINSTRUCTIONTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnINSTRUCTIONTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnINSTRUCTIONTYPE.'
	drop function dbo.fn_ccnINSTRUCTIONTYPE
	print '**** Creating function dbo.fn_ccnINSTRUCTIONTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONTYPE]') and xtype='U')
begin
	select * 
	into CCImport_INSTRUCTIONTYPE 
	from INSTRUCTIONTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnINSTRUCTIONTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnINSTRUCTIONTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INSTRUCTIONTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'INSTRUCTIONTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_INSTRUCTIONTYPE I 
	right join INSTRUCTIONTYPE C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
where I.INSTRUCTIONTYPE is null
UNION ALL 
select	5, 'INSTRUCTIONTYPE', 0, count(*), 0, 0
from CCImport_INSTRUCTIONTYPE I 
	left join INSTRUCTIONTYPE C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
where C.INSTRUCTIONTYPE is null
UNION ALL 
 select	5, 'INSTRUCTIONTYPE', 0, 0, count(*), 0
from CCImport_INSTRUCTIONTYPE I 
	join INSTRUCTIONTYPE C	on ( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
where 	( I.NAMETYPE <>  C.NAMETYPE)
	OR 	( I.INSTRTYPEDESC <>  C.INSTRTYPEDESC OR (I.INSTRTYPEDESC is null and C.INSTRTYPEDESC is not null) 
OR (I.INSTRTYPEDESC is not null and C.INSTRTYPEDESC is null))
	OR 	( I.RESTRICTEDBYTYPE <>  C.RESTRICTEDBYTYPE OR (I.RESTRICTEDBYTYPE is null and C.RESTRICTEDBYTYPE is not null) 
OR (I.RESTRICTEDBYTYPE is not null and C.RESTRICTEDBYTYPE is null))
UNION ALL 
 select	5, 'INSTRUCTIONTYPE', 0, 0, 0, count(*)
from CCImport_INSTRUCTIONTYPE I 
join INSTRUCTIONTYPE C	on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
where ( I.NAMETYPE =  C.NAMETYPE)
and ( I.INSTRTYPEDESC =  C.INSTRTYPEDESC OR (I.INSTRTYPEDESC is null and C.INSTRTYPEDESC is null))
and ( I.RESTRICTEDBYTYPE =  C.RESTRICTEDBYTYPE OR (I.RESTRICTEDBYTYPE is null and C.RESTRICTEDBYTYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONTYPE]') and xtype='U')
begin
	drop table CCImport_INSTRUCTIONTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnINSTRUCTIONTYPE  to public
go
