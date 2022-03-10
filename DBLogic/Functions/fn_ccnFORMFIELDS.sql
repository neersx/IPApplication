-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFORMFIELDS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFORMFIELDS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFORMFIELDS.'
	drop function dbo.fn_ccnFORMFIELDS
	print '**** Creating function dbo.fn_ccnFORMFIELDS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FORMFIELDS]') and xtype='U')
begin
	select * 
	into CCImport_FORMFIELDS 
	from FORMFIELDS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnFORMFIELDS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFORMFIELDS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FORMFIELDS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 21 Aug 2019	MF	DR-36783 1	Function created
--
As 
Return
select	10 as TRIPNO, 'FORMFIELDS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FORMFIELDS I 
	right join FORMFIELDS C on (C.DOCUMENTNO=I.DOCUMENTNO
				and C.FIELDNAME =I.FIELDNAME )
where I.DOCUMENTNO is null
UNION ALL 
select	10, 'FORMFIELDS', 0, count(*), 0, 0
from CCImport_FORMFIELDS I 
	left join FORMFIELDS C  on (C.DOCUMENTNO=I.DOCUMENTNO
				and C.FIELDNAME =I.FIELDNAME )
where C.DOCUMENTNO is null
UNION ALL 
 select	10, 'FORMFIELDS', 0, 0, count(*), 0
from CCImport_FORMFIELDS I 
	join FORMFIELDS C on (C.DOCUMENTNO=I.DOCUMENTNO
			  and C.FIELDNAME =I.FIELDNAME )
where 	 isnull(I.FIELDTYPE       ,'')<>isnull(C.FIELDTYPE       ,'')
OR 	 isnull(I.ITEM_ID         ,'')<>isnull(C.ITEM_ID         ,'')
OR 	 isnull(I.FIELDDESCRIPTION,'')<>isnull(C.FIELDDESCRIPTION,'')
OR 	 isnull(I.ITEMPARAMETER   ,'')<>isnull(C.ITEMPARAMETER   ,'')
OR 	 isnull(I.RESULTSEPARATOR ,'')<>isnull(C.RESULTSEPARATOR ,'')
UNION ALL 
 select	10, 'FORMFIELDS', 0, 0, 0, count(*)
from CCImport_FORMFIELDS I 
	join FORMFIELDS C on (C.DOCUMENTNO=I.DOCUMENTNO
			  and C.FIELDNAME =I.FIELDNAME )
where 	 isnull(I.FIELDTYPE       ,'')=isnull(C.FIELDTYPE       ,'')
AND 	 isnull(I.ITEM_ID         ,'')=isnull(C.ITEM_ID         ,'')
AND 	 isnull(I.FIELDDESCRIPTION,'')=isnull(C.FIELDDESCRIPTION,'')
AND 	 isnull(I.ITEMPARAMETER   ,'')=isnull(C.ITEMPARAMETER   ,'')
AND 	 isnull(I.RESULTSEPARATOR ,'')=isnull(C.RESULTSEPARATOR ,'')

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FORMFIELDS]') and xtype='U')
begin
	drop table CCImport_FORMFIELDS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFORMFIELDS  to public
go
