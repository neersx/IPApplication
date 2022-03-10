-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnALIASTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnALIASTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnALIASTYPE.'
	drop function dbo.fn_ccnALIASTYPE
	print '**** Creating function dbo.fn_ccnALIASTYPE...'
	print ''
end
go

SET NOCOUNT ON
GO

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ALIASTYPE]') and xtype='U')
begin
	select * 
	into CCImport_ALIASTYPE 
	from ALIASTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnALIASTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnALIASTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ALIASTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'ALIASTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ALIASTYPE I 
	right join ALIASTYPE C on( C.ALIASTYPE=I.ALIASTYPE)
where I.ALIASTYPE is null
UNION ALL 
select	2, 'ALIASTYPE', 0, count(*), 0, 0
from CCImport_ALIASTYPE I 
	left join ALIASTYPE C on( C.ALIASTYPE=I.ALIASTYPE)
where C.ALIASTYPE is null
UNION ALL 
 select	2, 'ALIASTYPE', 0, 0, count(*), 0
from CCImport_ALIASTYPE I 
	join ALIASTYPE C	on ( C.ALIASTYPE=I.ALIASTYPE)
where 	( I.ALIASDESCRIPTION <>  C.ALIASDESCRIPTION OR (I.ALIASDESCRIPTION is null and C.ALIASDESCRIPTION is not null) 
OR (I.ALIASDESCRIPTION is not null and C.ALIASDESCRIPTION is null))
	OR 	( I.MUSTBEUNIQUE <>  C.MUSTBEUNIQUE OR (I.MUSTBEUNIQUE is null and C.MUSTBEUNIQUE is not null) 
OR (I.MUSTBEUNIQUE is not null and C.MUSTBEUNIQUE is null))
UNION ALL 
 select	2, 'ALIASTYPE', 0, 0, 0, count(*)
from CCImport_ALIASTYPE I 
join ALIASTYPE C	on( C.ALIASTYPE=I.ALIASTYPE)
where ( I.ALIASDESCRIPTION =  C.ALIASDESCRIPTION OR (I.ALIASDESCRIPTION is null and C.ALIASDESCRIPTION is null))
and ( I.MUSTBEUNIQUE =  C.MUSTBEUNIQUE OR (I.MUSTBEUNIQUE is null and C.MUSTBEUNIQUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ALIASTYPE]') and xtype='U')
begin
	drop table CCImport_ALIASTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnALIASTYPE  to public
go
