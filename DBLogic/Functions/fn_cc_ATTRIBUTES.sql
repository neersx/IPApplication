-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ATTRIBUTES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ATTRIBUTES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ATTRIBUTES.'
	drop function dbo.fn_cc_ATTRIBUTES
	print '**** Creating function dbo.fn_cc_ATTRIBUTES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ATTRIBUTES]') and xtype='U')
begin
	select * 
	into CCImport_ATTRIBUTES 
	from ATTRIBUTES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ATTRIBUTES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ATTRIBUTES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ATTRIBUTES table
-- CALLED BY :	ip_CopyConfigATTRIBUTES
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
	 null as 'Imported Attributename',
	 null as 'Imported Datatype',
	 null as 'Imported Tablename',
	 null as 'Imported Filtervalue',
'D' as '-',
	 C.ATTRIBUTENAME as 'Attributename',
	 C.DATATYPE as 'Datatype',
	 C.TABLENAME as 'Tablename',
	 C.FILTERVALUE as 'Filtervalue'
from CCImport_ATTRIBUTES I 
	right join ATTRIBUTES C on( C.ATTRIBUTEID=I.ATTRIBUTEID)
where I.ATTRIBUTEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ATTRIBUTENAME,
	 I.DATATYPE,
	 I.TABLENAME,
	 I.FILTERVALUE,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ATTRIBUTES I 
	left join ATTRIBUTES C on( C.ATTRIBUTEID=I.ATTRIBUTEID)
where C.ATTRIBUTEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ATTRIBUTENAME,
	 I.DATATYPE,
	 I.TABLENAME,
	 I.FILTERVALUE,
'U',
	 C.ATTRIBUTENAME,
	 C.DATATYPE,
	 C.TABLENAME,
	 C.FILTERVALUE
from CCImport_ATTRIBUTES I 
	join ATTRIBUTES C	on ( C.ATTRIBUTEID=I.ATTRIBUTEID)
where 	( I.ATTRIBUTENAME <>  C.ATTRIBUTENAME)
	OR 	( I.DATATYPE <>  C.DATATYPE)
	OR 	( I.TABLENAME <>  C.TABLENAME OR (I.TABLENAME is null and C.TABLENAME is not null) 
OR (I.TABLENAME is not null and C.TABLENAME is null))
	OR 	(replace( I.FILTERVALUE,char(10),char(13)+char(10)) <>  C.FILTERVALUE OR (I.FILTERVALUE is null and C.FILTERVALUE is not null) 
OR (I.FILTERVALUE is not null and C.FILTERVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ATTRIBUTES]') and xtype='U')
begin
	drop table CCImport_ATTRIBUTES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ATTRIBUTES  to public
go
