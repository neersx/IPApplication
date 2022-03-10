-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FORMFIELDS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FORMFIELDS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FORMFIELDS.'
	drop function dbo.fn_cc_FORMFIELDS
	print '**** Creating function dbo.fn_cc_FORMFIELDS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FORMFIELDS]') and xtype='U')
begin
	select * 
	into CCImport_FORMFIELDS 
	from FORMFIELDS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_FORMFIELDS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FORMFIELDS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FORMFIELDS table
-- CALLED BY :	ip_CopyConfigFORMFIELDS
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 21 Aug 2019	MF	DR-36783 1	Function created
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Documentno',
	 null as 'Imported Fieldname',
	 null as 'Imported Fieldtype',
	 null as 'Imported Item_id',
	 null as 'Imported Fielddescription',
	 null as 'Imported Itemparameter',
	 null as 'Imported Resultseparator',
	'D' as '-',
	 C.DOCUMENTNO       as 'Documentno',
	 C.FIELDNAME        as 'Fieldname',
	 C.FIELDTYPE        as 'Fieldtype',
	 C.ITEM_ID          as 'Item_id',
	 C.FIELDDESCRIPTION as 'Fielddescription',
	 C.ITEMPARAMETER    as 'Itemparameter',
	 C.RESULTSEPARATOR  as 'Resultseparator'
from CCImport_FORMFIELDS I 
	right join FORMFIELDS C on( C.DOCUMENTNO=I.DOCUMENTNO
				and C.FIELDNAME =I.FIELDNAME )
where I.DOCUMENTNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.DOCUMENTNO,
	 I.FIELDNAME,
	 I.FIELDTYPE,
	 I.ITEM_ID,
	 I.FIELDDESCRIPTION,
	 I.ITEMPARAMETER,
	 I.RESULTSEPARATOR,
	'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_FORMFIELDS I 
	left join FORMFIELDS C	on ( C.DOCUMENTNO=I.DOCUMENTNO
				and  C.FIELDNAME =I.FIELDNAME)
where C.DOCUMENTNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.DOCUMENTNO,
	 I.FIELDNAME,
	 I.FIELDTYPE,
	 I.ITEM_ID,
	 I.FIELDDESCRIPTION,
	 I.ITEMPARAMETER,
	 I.RESULTSEPARATOR,
	'U',
	 C.DOCUMENTNO,
	 C.FIELDNAME,
	 C.FIELDTYPE,
	 C.ITEM_ID,
	 C.FIELDDESCRIPTION,
	 C.ITEMPARAMETER,
	 C.RESULTSEPARATOR
from CCImport_FORMFIELDS I 
	join FORMFIELDS C on ( C.DOCUMENTNO=I.DOCUMENTNO
			  and  C.FIELDNAME =I.FIELDNAME)
where 	 isnull(I.FIELDTYPE       ,'')<>isnull(C.FIELDTYPE       ,'')
OR 	 isnull(I.ITEM_ID         ,'')<>isnull(C.ITEM_ID         ,'')
OR 	 isnull(I.FIELDDESCRIPTION,'')<>isnull(C.FIELDDESCRIPTION,'')
OR 	 isnull(I.ITEMPARAMETER   ,'')<>isnull(C.ITEMPARAMETER   ,'')
OR 	 isnull(I.RESULTSEPARATOR ,'')<>isnull(C.RESULTSEPARATOR ,'')

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FORMFIELDS]') and xtype='U')
begin
	drop table CCImport_FORMFIELDS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FORMFIELDS  to public
go
