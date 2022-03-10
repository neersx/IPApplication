-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnOFFICE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnOFFICE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnOFFICE.'
	drop function dbo.fn_ccnOFFICE
	print '**** Creating function dbo.fn_ccnOFFICE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_OFFICE]') and xtype='U')
begin
	select * 
	into CCImport_OFFICE 
	from OFFICE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnOFFICE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnOFFICE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the OFFICE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'OFFICE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_OFFICE I 
	right join OFFICE C on( C.OFFICEID=I.OFFICEID)
where I.OFFICEID is null
UNION ALL 
select	2, 'OFFICE', 0, count(*), 0, 0
from CCImport_OFFICE I 
	left join OFFICE C on( C.OFFICEID=I.OFFICEID)
where C.OFFICEID is null
UNION ALL 
 select	2, 'OFFICE', 0, 0, count(*), 0
from CCImport_OFFICE I 
	join OFFICE C	on ( C.OFFICEID=I.OFFICEID)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.USERCODE <>  C.USERCODE OR (I.USERCODE is null and C.USERCODE is not null) 
OR (I.USERCODE is not null and C.USERCODE is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.LANGUAGECODE <>  C.LANGUAGECODE OR (I.LANGUAGECODE is null and C.LANGUAGECODE is not null) 
OR (I.LANGUAGECODE is not null and C.LANGUAGECODE is null))
	OR 	( I.CPACODE <>  C.CPACODE OR (I.CPACODE is null and C.CPACODE is not null) 
OR (I.CPACODE is not null and C.CPACODE is null))
	OR 	( I.RESOURCENO <>  C.RESOURCENO OR (I.RESOURCENO is null and C.RESOURCENO is not null) 
OR (I.RESOURCENO is not null and C.RESOURCENO is null))
	OR 	( I.ITEMNOPREFIX <>  C.ITEMNOPREFIX OR (I.ITEMNOPREFIX is null and C.ITEMNOPREFIX is not null) 
OR (I.ITEMNOPREFIX is not null and C.ITEMNOPREFIX is null))
	OR 	( I.ITEMNOFROM <>  C.ITEMNOFROM OR (I.ITEMNOFROM is null and C.ITEMNOFROM is not null) 
OR (I.ITEMNOFROM is not null and C.ITEMNOFROM is null))
	OR 	( I.ITEMNOTO <>  C.ITEMNOTO OR (I.ITEMNOTO is null and C.ITEMNOTO is not null) 
OR (I.ITEMNOTO is not null and C.ITEMNOTO is null))
	OR 	( I.LASTITEMNO <>  C.LASTITEMNO OR (I.LASTITEMNO is null and C.LASTITEMNO is not null) 
OR (I.LASTITEMNO is not null and C.LASTITEMNO is null))
	OR 	( I.REGION <>  C.REGION OR (I.REGION is null and C.REGION is not null) 
OR (I.REGION is not null and C.REGION is null))
	OR 	( I.ORGNAMENO <>  C.ORGNAMENO OR (I.ORGNAMENO is null and C.ORGNAMENO is not null) 
OR (I.ORGNAMENO is not null and C.ORGNAMENO is null))
	OR 	( I.IRNCODE <>  C.IRNCODE OR (I.IRNCODE is null and C.IRNCODE is not null) 
OR (I.IRNCODE is not null and C.IRNCODE is null))
UNION ALL 
 select	2, 'OFFICE', 0, 0, 0, count(*)
from CCImport_OFFICE I 
join OFFICE C	on( C.OFFICEID=I.OFFICEID)
where ( I.DESCRIPTION =  C.DESCRIPTION)
and ( I.USERCODE =  C.USERCODE OR (I.USERCODE is null and C.USERCODE is null))
and ( I.COUNTRYCODE =  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is null))
and ( I.LANGUAGECODE =  C.LANGUAGECODE OR (I.LANGUAGECODE is null and C.LANGUAGECODE is null))
and ( I.CPACODE =  C.CPACODE OR (I.CPACODE is null and C.CPACODE is null))
and ( I.RESOURCENO =  C.RESOURCENO OR (I.RESOURCENO is null and C.RESOURCENO is null))
and ( I.ITEMNOPREFIX =  C.ITEMNOPREFIX OR (I.ITEMNOPREFIX is null and C.ITEMNOPREFIX is null))
and ( I.ITEMNOFROM =  C.ITEMNOFROM OR (I.ITEMNOFROM is null and C.ITEMNOFROM is null))
and ( I.ITEMNOTO =  C.ITEMNOTO OR (I.ITEMNOTO is null and C.ITEMNOTO is null))
and ( I.LASTITEMNO =  C.LASTITEMNO OR (I.LASTITEMNO is null and C.LASTITEMNO is null))
and ( I.REGION =  C.REGION OR (I.REGION is null and C.REGION is null))
and ( I.ORGNAMENO =  C.ORGNAMENO OR (I.ORGNAMENO is null and C.ORGNAMENO is null))
and ( I.IRNCODE =  C.IRNCODE OR (I.IRNCODE is null and C.IRNCODE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_OFFICE]') and xtype='U')
begin
	drop table CCImport_OFFICE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnOFFICE  to public
go
