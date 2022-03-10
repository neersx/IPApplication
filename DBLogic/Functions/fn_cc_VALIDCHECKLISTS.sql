-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDCHECKLISTS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDCHECKLISTS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDCHECKLISTS.'
	drop function dbo.fn_cc_VALIDCHECKLISTS
	print '**** Creating function dbo.fn_cc_VALIDCHECKLISTS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDCHECKLISTS]') and xtype='U')
begin
	select * 
	into CCImport_VALIDCHECKLISTS 
	from VALIDCHECKLISTS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDCHECKLISTS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDCHECKLISTS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDCHECKLISTS table
-- CALLED BY :	ip_CopyConfigVALIDCHECKLISTS
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Countrycode',
	 null as 'Imported Propertytype',
	 null as 'Imported Casetype',
	 null as 'Imported Checklisttype',
	 null as 'Imported Checklistdesc',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.CASETYPE as 'Casetype',
	 C.CHECKLISTTYPE as 'Checklisttype',
	 C.CHECKLISTDESC as 'Checklistdesc'
from CCImport_VALIDCHECKLISTS I 
	right join VALIDCHECKLISTS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASETYPE,
	 I.CHECKLISTTYPE,
	 I.CHECKLISTDESC,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDCHECKLISTS I 
	left join VALIDCHECKLISTS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASETYPE,
	 I.CHECKLISTTYPE,
	 I.CHECKLISTDESC,
'U',
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.CASETYPE,
	 C.CHECKLISTTYPE,
	 C.CHECKLISTDESC
from CCImport_VALIDCHECKLISTS I 
	join VALIDCHECKLISTS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.CASETYPE=I.CASETYPE
	and C.CHECKLISTTYPE=I.CHECKLISTTYPE)
where 	( I.CHECKLISTDESC <>  C.CHECKLISTDESC OR (I.CHECKLISTDESC is null and C.CHECKLISTDESC is not null) 
OR (I.CHECKLISTDESC is not null and C.CHECKLISTDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDCHECKLISTS]') and xtype='U')
begin
	drop table CCImport_VALIDCHECKLISTS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDCHECKLISTS  to public
go
