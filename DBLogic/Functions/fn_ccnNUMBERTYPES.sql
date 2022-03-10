-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnNUMBERTYPES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnNUMBERTYPES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnNUMBERTYPES.'
	drop function dbo.fn_ccnNUMBERTYPES
	print '**** Creating function dbo.fn_ccnNUMBERTYPES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NUMBERTYPES]') and xtype='U')
begin
	select * 
	into CCImport_NUMBERTYPES 
	from NUMBERTYPES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnNUMBERTYPES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnNUMBERTYPES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NUMBERTYPES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'NUMBERTYPES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_NUMBERTYPES I 
	right join NUMBERTYPES C on( C.NUMBERTYPE=I.NUMBERTYPE)
where I.NUMBERTYPE is null
UNION ALL 
select	2, 'NUMBERTYPES', 0, count(*), 0, 0
from CCImport_NUMBERTYPES I 
	left join NUMBERTYPES C on( C.NUMBERTYPE=I.NUMBERTYPE)
where C.NUMBERTYPE is null
UNION ALL 
 select	2, 'NUMBERTYPES', 0, 0, count(*), 0
from CCImport_NUMBERTYPES I 
	join NUMBERTYPES C	on ( C.NUMBERTYPE=I.NUMBERTYPE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.RELATEDEVENTNO <>  C.RELATEDEVENTNO OR (I.RELATEDEVENTNO is null and C.RELATEDEVENTNO is not null) 
OR (I.RELATEDEVENTNO is not null and C.RELATEDEVENTNO is null))
	OR 	( I.ISSUEDBYIPOFFICE <>  C.ISSUEDBYIPOFFICE OR (I.ISSUEDBYIPOFFICE is null and C.ISSUEDBYIPOFFICE is not null) 
OR (I.ISSUEDBYIPOFFICE is not null and C.ISSUEDBYIPOFFICE is null))
	OR 	( I.DISPLAYPRIORITY <>  C.DISPLAYPRIORITY OR (I.DISPLAYPRIORITY is null and C.DISPLAYPRIORITY is not null) 
OR (I.DISPLAYPRIORITY is not null and C.DISPLAYPRIORITY is null))
UNION ALL 
 select	2, 'NUMBERTYPES', 0, 0, 0, count(*)
from CCImport_NUMBERTYPES I 
join NUMBERTYPES C	on( C.NUMBERTYPE=I.NUMBERTYPE)
where ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.RELATEDEVENTNO =  C.RELATEDEVENTNO OR (I.RELATEDEVENTNO is null and C.RELATEDEVENTNO is null))
and ( I.ISSUEDBYIPOFFICE =  C.ISSUEDBYIPOFFICE OR (I.ISSUEDBYIPOFFICE is null and C.ISSUEDBYIPOFFICE is null))
and ( I.DISPLAYPRIORITY =  C.DISPLAYPRIORITY OR (I.DISPLAYPRIORITY is null and C.DISPLAYPRIORITY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NUMBERTYPES]') and xtype='U')
begin
	drop table CCImport_NUMBERTYPES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnNUMBERTYPES  to public
go
