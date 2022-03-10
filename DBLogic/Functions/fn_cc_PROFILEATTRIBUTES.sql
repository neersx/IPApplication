-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PROFILEATTRIBUTES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PROFILEATTRIBUTES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PROFILEATTRIBUTES.'
	drop function dbo.fn_cc_PROFILEATTRIBUTES
	print '**** Creating function dbo.fn_cc_PROFILEATTRIBUTES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILEATTRIBUTES]') and xtype='U')
begin
	select * 
	into CCImport_PROFILEATTRIBUTES 
	from PROFILEATTRIBUTES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PROFILEATTRIBUTES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PROFILEATTRIBUTES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFILEATTRIBUTES table
-- CALLED BY :	ip_CopyConfigPROFILEATTRIBUTES
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
	 null as 'Imported Profileid',
	 null as 'Imported Attributeid',
	 null as 'Imported Attributevalue',
'D' as '-',
	 C.PROFILEID as 'Profileid',
	 C.ATTRIBUTEID as 'Attributeid',
	 C.ATTRIBUTEVALUE as 'Attributevalue'
from CCImport_PROFILEATTRIBUTES I 
	right join PROFILEATTRIBUTES C on( C.PROFILEID=I.PROFILEID
and  C.ATTRIBUTEID=I.ATTRIBUTEID)
where I.PROFILEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PROFILEID,
	 I.ATTRIBUTEID,
	 I.ATTRIBUTEVALUE,
'I',
	 null ,
	 null ,
	 null
from CCImport_PROFILEATTRIBUTES I 
	left join PROFILEATTRIBUTES C on( C.PROFILEID=I.PROFILEID
and  C.ATTRIBUTEID=I.ATTRIBUTEID)
where C.PROFILEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.PROFILEID,
	 I.ATTRIBUTEID,
	 I.ATTRIBUTEVALUE,
'U',
	 C.PROFILEID,
	 C.ATTRIBUTEID,
	 C.ATTRIBUTEVALUE
from CCImport_PROFILEATTRIBUTES I 
	join PROFILEATTRIBUTES C	on ( C.PROFILEID=I.PROFILEID
	and C.ATTRIBUTEID=I.ATTRIBUTEID)
where 	(replace( I.ATTRIBUTEVALUE,char(10),char(13)+char(10)) <>  C.ATTRIBUTEVALUE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFILEATTRIBUTES]') and xtype='U')
begin
	drop table CCImport_PROFILEATTRIBUTES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PROFILEATTRIBUTES  to public
go
