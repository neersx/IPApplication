-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPROPERTYTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPROPERTYTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPROPERTYTYPE.'
	drop function dbo.fn_ccnPROPERTYTYPE
	print '**** Creating function dbo.fn_ccnPROPERTYTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROPERTYTYPE]') and xtype='U')
begin
	select * 
	into CCImport_PROPERTYTYPE 
	from PROPERTYTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPROPERTYTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPROPERTYTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROPERTYTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'PROPERTYTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PROPERTYTYPE I 
	right join PROPERTYTYPE C on( C.PROPERTYTYPE=I.PROPERTYTYPE)
where I.PROPERTYTYPE is null
UNION ALL 
select	2, 'PROPERTYTYPE', 0, count(*), 0, 0
from CCImport_PROPERTYTYPE I 
	left join PROPERTYTYPE C on( C.PROPERTYTYPE=I.PROPERTYTYPE)
where C.PROPERTYTYPE is null
UNION ALL 
 select	2, 'PROPERTYTYPE', 0, 0, count(*), 0
from CCImport_PROPERTYTYPE I 
	join PROPERTYTYPE C	on ( C.PROPERTYTYPE=I.PROPERTYTYPE)
where 	( I.PROPERTYNAME <>  C.PROPERTYNAME OR (I.PROPERTYNAME is null and C.PROPERTYNAME is not null) 
OR (I.PROPERTYNAME is not null and C.PROPERTYNAME is null))
	OR 	( I.ALLOWSUBCLASS <>  C.ALLOWSUBCLASS)
	OR 	( I.CRMONLY <>  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is not null) 
OR (I.CRMONLY is not null and C.CRMONLY is null))
UNION ALL 
 select	2, 'PROPERTYTYPE', 0, 0, 0, count(*)
from CCImport_PROPERTYTYPE I 
join PROPERTYTYPE C	on( C.PROPERTYTYPE=I.PROPERTYTYPE)
where ( I.PROPERTYNAME =  C.PROPERTYNAME OR (I.PROPERTYNAME is null and C.PROPERTYNAME is null))
and ( I.ALLOWSUBCLASS =  C.ALLOWSUBCLASS)
and ( I.CRMONLY =  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROPERTYTYPE]') and xtype='U')
begin
	drop table CCImport_PROPERTYTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPROPERTYTYPE  to public
go
