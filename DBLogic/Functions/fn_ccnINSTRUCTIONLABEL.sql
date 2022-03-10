-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnINSTRUCTIONLABEL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnINSTRUCTIONLABEL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnINSTRUCTIONLABEL.'
	drop function dbo.fn_ccnINSTRUCTIONLABEL
	print '**** Creating function dbo.fn_ccnINSTRUCTIONLABEL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONLABEL]') and xtype='U')
begin
	select * 
	into CCImport_INSTRUCTIONLABEL 
	from INSTRUCTIONLABEL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnINSTRUCTIONLABEL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnINSTRUCTIONLABEL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INSTRUCTIONLABEL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'INSTRUCTIONLABEL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_INSTRUCTIONLABEL I 
	right join INSTRUCTIONLABEL C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where I.INSTRUCTIONTYPE is null
UNION ALL 
select	5, 'INSTRUCTIONLABEL', 0, count(*), 0, 0
from CCImport_INSTRUCTIONLABEL I 
	left join INSTRUCTIONLABEL C on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where C.INSTRUCTIONTYPE is null
UNION ALL 
 select	5, 'INSTRUCTIONLABEL', 0, 0, count(*), 0
from CCImport_INSTRUCTIONLABEL I 
	join INSTRUCTIONLABEL C	on ( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
	and C.FLAGNUMBER=I.FLAGNUMBER)
where 	( I.FLAGLITERAL <>  C.FLAGLITERAL OR (I.FLAGLITERAL is null and C.FLAGLITERAL is not null) 
OR (I.FLAGLITERAL is not null and C.FLAGLITERAL is null))
UNION ALL 
 select	5, 'INSTRUCTIONLABEL', 0, 0, 0, count(*)
from CCImport_INSTRUCTIONLABEL I 
join INSTRUCTIONLABEL C	on( C.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE
and C.FLAGNUMBER=I.FLAGNUMBER)
where ( I.FLAGLITERAL =  C.FLAGLITERAL OR (I.FLAGLITERAL is null and C.FLAGLITERAL is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONLABEL]') and xtype='U')
begin
	drop table CCImport_INSTRUCTIONLABEL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnINSTRUCTIONLABEL  to public
go
