-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDCHECKLISTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDCHECKLISTS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDCHECKLISTS.'
	drop function dbo.fn_ccnVALIDCHECKLISTS
	print '**** Creating function dbo.fn_ccnVALIDCHECKLISTS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDCHECKLISTS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDCHECKLISTS 
	from VALIDCHECKLISTS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDCHECKLISTS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDCHECKLISTS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDCHECKLISTS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDCHECKLISTS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDCHECKLISTS I 
	right join VALIDCHECKLISTS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDCHECKLISTS', 0, count(*), 0, 0
from CCImport_VALIDCHECKLISTS I 
	left join VALIDCHECKLISTS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDCHECKLISTS', 0, 0, count(*), 0
from CCImport_VALIDCHECKLISTS I 
	join VALIDCHECKLISTS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.CASETYPE=I.CASETYPE
	and C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where 	( I.CHECKLISTDESC <>  C.CHECKLISTDESC OR (I.CHECKLISTDESC is null and C.CHECKLISTDESC is not null) 
OR (I.CHECKLISTDESC is not null and C.CHECKLISTDESC is null))
UNION ALL 
 select	3, 'VALIDCHECKLISTS', 0, 0, 0, count(*)
from CCImport_VALIDCHECKLISTS I 
join VALIDCHECKLISTS C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.CASETYPE=I.CASETYPE
and C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where ( I.CHECKLISTDESC =  C.CHECKLISTDESC OR (I.CHECKLISTDESC is null and C.CHECKLISTDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDCHECKLISTS]') and xtype='U')
begin
	drop table CCImport_VALIDCHECKLISTS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDCHECKLISTS  to public
go
