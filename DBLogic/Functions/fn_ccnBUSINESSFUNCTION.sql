-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnBUSINESSFUNCTION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnBUSINESSFUNCTION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnBUSINESSFUNCTION.'
	drop function dbo.fn_ccnBUSINESSFUNCTION
	print '**** Creating function dbo.fn_ccnBUSINESSFUNCTION...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_BUSINESSFUNCTION]') and xtype='U')
begin
	select * 
	into CCImport_BUSINESSFUNCTION 
	from BUSINESSFUNCTION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnBUSINESSFUNCTION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnBUSINESSFUNCTION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the BUSINESSFUNCTION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'BUSINESSFUNCTION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_BUSINESSFUNCTION I 
	right join BUSINESSFUNCTION C on( C.FUNCTIONTYPE=I.FUNCTIONTYPE)
where I.FUNCTIONTYPE is null
UNION ALL 
select	6, 'BUSINESSFUNCTION', 0, count(*), 0, 0
from CCImport_BUSINESSFUNCTION I 
	left join BUSINESSFUNCTION C on( C.FUNCTIONTYPE=I.FUNCTIONTYPE)
where C.FUNCTIONTYPE is null
UNION ALL 
 select	6, 'BUSINESSFUNCTION', 0, 0, count(*), 0
from CCImport_BUSINESSFUNCTION I 
	join BUSINESSFUNCTION C	on ( C.FUNCTIONTYPE=I.FUNCTIONTYPE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.OWNERALLOWED <>  C.OWNERALLOWED)
	OR 	( I.PRIVILEGESALLOWED <>  C.PRIVILEGESALLOWED)
UNION ALL 
 select	6, 'BUSINESSFUNCTION', 0, 0, 0, count(*)
from CCImport_BUSINESSFUNCTION I 
join BUSINESSFUNCTION C	on( C.FUNCTIONTYPE=I.FUNCTIONTYPE)
where ( I.DESCRIPTION =  C.DESCRIPTION)
and ( I.OWNERALLOWED =  C.OWNERALLOWED)
and ( I.PRIVILEGESALLOWED =  C.PRIVILEGESALLOWED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_BUSINESSFUNCTION]') and xtype='U')
begin
	drop table CCImport_BUSINESSFUNCTION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnBUSINESSFUNCTION  to public
go
