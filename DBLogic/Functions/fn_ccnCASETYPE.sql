-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCASETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCASETYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCASETYPE.'
	drop function dbo.fn_ccnCASETYPE
	print '**** Creating function dbo.fn_ccnCASETYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CASETYPE]') and xtype='U')
begin
	select * 
	into CCImport_CASETYPE 
	from CASETYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCASETYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCASETYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CASETYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'CASETYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CASETYPE I 
	right join CASETYPE C on( C.CASETYPE=I.CASETYPE)
where I.CASETYPE is null
UNION ALL 
select	2, 'CASETYPE', 0, count(*), 0, 0
from CCImport_CASETYPE I 
	left join CASETYPE C on( C.CASETYPE=I.CASETYPE)
where C.CASETYPE is null
UNION ALL 
 select	2, 'CASETYPE', 0, 0, count(*), 0
from CCImport_CASETYPE I 
	join CASETYPE C	on ( C.CASETYPE=I.CASETYPE)
where 	( I.CASETYPEDESC <>  C.CASETYPEDESC OR (I.CASETYPEDESC is null and C.CASETYPEDESC is not null) 
OR (I.CASETYPEDESC is not null and C.CASETYPEDESC is null))
	OR 	( I.ACTUALCASETYPE <>  C.ACTUALCASETYPE OR (I.ACTUALCASETYPE is null and C.ACTUALCASETYPE is not null) 
OR (I.ACTUALCASETYPE is not null and C.ACTUALCASETYPE is null))
	OR 	( I.CRMONLY <>  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is not null) 
OR (I.CRMONLY is not null and C.CRMONLY is null))
	OR 	( I.KOTTEXTTYPE <>  C.KOTTEXTTYPE OR (I.KOTTEXTTYPE is null and C.KOTTEXTTYPE is not null) 
OR (I.KOTTEXTTYPE is not null and C.KOTTEXTTYPE is null))
	OR 	( I.PROGRAM <>  C.PROGRAM OR (I.PROGRAM is null and C.PROGRAM is not null) 
OR (I.PROGRAM is not null and C.PROGRAM is null))
UNION ALL 
 select	2, 'CASETYPE', 0, 0, 0, count(*)
from CCImport_CASETYPE I 
join CASETYPE C	on( C.CASETYPE=I.CASETYPE)
where ( I.CASETYPEDESC =  C.CASETYPEDESC OR (I.CASETYPEDESC is null and C.CASETYPEDESC is null))
and ( I.ACTUALCASETYPE =  C.ACTUALCASETYPE OR (I.ACTUALCASETYPE is null and C.ACTUALCASETYPE is null))
and ( I.CRMONLY =  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is null))
and ( I.KOTTEXTTYPE =  C.KOTTEXTTYPE OR (I.KOTTEXTTYPE is null and C.KOTTEXTTYPE is null))
and ( I.PROGRAM =  C.PROGRAM OR (I.PROGRAM is null and C.PROGRAM is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CASETYPE]') and xtype='U')
begin
	drop table CCImport_CASETYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCASETYPE  to public
go
