-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PROPERTYTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PROPERTYTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PROPERTYTYPE.'
	drop function dbo.fn_cc_PROPERTYTYPE
	print '**** Creating function dbo.fn_cc_PROPERTYTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROPERTYTYPE]') and xtype='U')
begin
	select * 
	into CCImport_PROPERTYTYPE 
	from PROPERTYTYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PROPERTYTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PROPERTYTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROPERTYTYPE table
-- CALLED BY :	ip_CopyConfigPROPERTYTYPE
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
	 null as 'Imported Propertytype',
	 null as 'Imported Propertyname',
	 null as 'Imported Allowsubclass',
	 null as 'Imported Crmonly',
'D' as '-',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.PROPERTYNAME as 'Propertyname',
	 C.ALLOWSUBCLASS as 'Allowsubclass',
	 C.CRMONLY as 'Crmonly'
from CCImport_PROPERTYTYPE I 
	right join PROPERTYTYPE C on( C.PROPERTYTYPE=I.PROPERTYTYPE)
where I.PROPERTYTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PROPERTYTYPE,
	 I.PROPERTYNAME,
	 I.ALLOWSUBCLASS,
	 I.CRMONLY,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_PROPERTYTYPE I 
	left join PROPERTYTYPE C on( C.PROPERTYTYPE=I.PROPERTYTYPE)
where C.PROPERTYTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.PROPERTYTYPE,
	 I.PROPERTYNAME,
	 I.ALLOWSUBCLASS,
	 I.CRMONLY,
'U',
	 C.PROPERTYTYPE,
	 C.PROPERTYNAME,
	 C.ALLOWSUBCLASS,
	 C.CRMONLY
from CCImport_PROPERTYTYPE I 
	join PROPERTYTYPE C	on ( C.PROPERTYTYPE=I.PROPERTYTYPE)
where 	( I.PROPERTYNAME <>  C.PROPERTYNAME OR (I.PROPERTYNAME is null and C.PROPERTYNAME is not null) 
OR (I.PROPERTYNAME is not null and C.PROPERTYNAME is null))
	OR 	( I.ALLOWSUBCLASS <>  C.ALLOWSUBCLASS)
	OR 	( I.CRMONLY <>  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is not null) 
OR (I.CRMONLY is not null and C.CRMONLY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROPERTYTYPE]') and xtype='U')
begin
	drop table CCImport_PROPERTYTYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PROPERTYTYPE  to public
go
