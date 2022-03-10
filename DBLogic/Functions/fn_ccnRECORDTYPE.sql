-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnRECORDTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnRECORDTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnRECORDTYPE.'
	drop function dbo.fn_ccnRECORDTYPE
	print '**** Creating function dbo.fn_ccnRECORDTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDTYPE]') and xtype='U')
begin
	select * 
	into CCImport_RECORDTYPE 
	from RECORDTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnRECORDTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnRECORDTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RECORDTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'RECORDTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_RECORDTYPE I 
	right join RECORDTYPE C on( C.RECORDTYPE=I.RECORDTYPE)
where I.RECORDTYPE is null
UNION ALL 
select	2, 'RECORDTYPE', 0, count(*), 0, 0
from CCImport_RECORDTYPE I 
	left join RECORDTYPE C on( C.RECORDTYPE=I.RECORDTYPE)
where C.RECORDTYPE is null
UNION ALL 
 select	2, 'RECORDTYPE', 0, 0, count(*), 0
from CCImport_RECORDTYPE I 
	join RECORDTYPE C	on ( C.RECORDTYPE=I.RECORDTYPE)
where 	( I.RECORDTYPEDESC <>  C.RECORDTYPEDESC)
UNION ALL 
 select	2, 'RECORDTYPE', 0, 0, 0, count(*)
from CCImport_RECORDTYPE I 
join RECORDTYPE C	on( C.RECORDTYPE=I.RECORDTYPE)
where ( I.RECORDTYPEDESC =  C.RECORDTYPEDESC)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDTYPE]') and xtype='U')
begin
	drop table CCImport_RECORDTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnRECORDTYPE  to public
go
