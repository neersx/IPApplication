-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnINSTRUCTIONFLAG
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnINSTRUCTIONFLAG]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnINSTRUCTIONFLAG.'
	drop function dbo.fn_ccnINSTRUCTIONFLAG
	print '**** Creating function dbo.fn_ccnINSTRUCTIONFLAG...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONFLAG]') and xtype='U')
begin
	select * 
	into CCImport_INSTRUCTIONFLAG 
	from INSTRUCTIONFLAG
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnINSTRUCTIONFLAG
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnINSTRUCTIONFLAG
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the INSTRUCTIONFLAG table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'INSTRUCTIONFLAG' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_INSTRUCTIONFLAG I 
	right join INSTRUCTIONFLAG C on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where I.INSTRUCTIONCODE is null
UNION ALL 
select	5, 'INSTRUCTIONFLAG', 0, count(*), 0, 0
from CCImport_INSTRUCTIONFLAG I 
	left join INSTRUCTIONFLAG C on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where C.INSTRUCTIONCODE is null
UNION ALL 
 select	5, 'INSTRUCTIONFLAG', 0, 0, count(*), 0
from CCImport_INSTRUCTIONFLAG I 
	join INSTRUCTIONFLAG C	on ( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE
	and C.FLAGNUMBER=I.FLAGNUMBER)
where 	( I.INSTRUCTIONFLAG <>  C.INSTRUCTIONFLAG OR (I.INSTRUCTIONFLAG is null and C.INSTRUCTIONFLAG is not null) 
OR (I.INSTRUCTIONFLAG is not null and C.INSTRUCTIONFLAG is null))
UNION ALL 
 select	5, 'INSTRUCTIONFLAG', 0, 0, 0, count(*)
from CCImport_INSTRUCTIONFLAG I 
join INSTRUCTIONFLAG C	on( C.INSTRUCTIONCODE=I.INSTRUCTIONCODE
and C.FLAGNUMBER=I.FLAGNUMBER)
where ( I.INSTRUCTIONFLAG =  C.INSTRUCTIONFLAG OR (I.INSTRUCTIONFLAG is null and C.INSTRUCTIONFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_INSTRUCTIONFLAG]') and xtype='U')
begin
	drop table CCImport_INSTRUCTIONFLAG 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnINSTRUCTIONFLAG  to public
go
