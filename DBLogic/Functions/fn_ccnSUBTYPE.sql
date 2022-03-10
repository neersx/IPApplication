-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSUBTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSUBTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSUBTYPE.'
	drop function dbo.fn_ccnSUBTYPE
	print '**** Creating function dbo.fn_ccnSUBTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SUBTYPE]') and xtype='U')
begin
	select * 
	into CCImport_SUBTYPE 
	from SUBTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSUBTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSUBTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SUBTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'SUBTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_SUBTYPE I 
	right join SUBTYPE C on( C.SUBTYPE=I.SUBTYPE)
where I.SUBTYPE is null
UNION ALL 
select	2, 'SUBTYPE', 0, count(*), 0, 0
from CCImport_SUBTYPE I 
	left join SUBTYPE C on( C.SUBTYPE=I.SUBTYPE)
where C.SUBTYPE is null
UNION ALL 
 select	2, 'SUBTYPE', 0, 0, count(*), 0
from CCImport_SUBTYPE I 
	join SUBTYPE C	on ( C.SUBTYPE=I.SUBTYPE)
where 	( I.SUBTYPEDESC <>  C.SUBTYPEDESC OR (I.SUBTYPEDESC is null and C.SUBTYPEDESC is not null) 
OR (I.SUBTYPEDESC is not null and C.SUBTYPEDESC is null))
UNION ALL 
 select	2, 'SUBTYPE', 0, 0, 0, count(*)
from CCImport_SUBTYPE I 
join SUBTYPE C	on( C.SUBTYPE=I.SUBTYPE)
where ( I.SUBTYPEDESC =  C.SUBTYPEDESC OR (I.SUBTYPEDESC is null and C.SUBTYPEDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SUBTYPE]') and xtype='U')
begin
	drop table CCImport_SUBTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSUBTYPE  to public
go
