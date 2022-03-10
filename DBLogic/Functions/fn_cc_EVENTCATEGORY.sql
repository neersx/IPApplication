-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EVENTCATEGORY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EVENTCATEGORY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EVENTCATEGORY.'
	drop function dbo.fn_cc_EVENTCATEGORY
	print '**** Creating function dbo.fn_cc_EVENTCATEGORY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCATEGORY]') and xtype='U')
begin
	select * 
	into CCImport_EVENTCATEGORY 
	from EVENTCATEGORY
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EVENTCATEGORY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EVENTCATEGORY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTCATEGORY table
-- CALLED BY :	ip_CopyConfigEVENTCATEGORY
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
	 null as 'Imported Categoryid',
	 null as 'Imported Categoryname',
	 null as 'Imported Description',
	 null as 'Imported Iconimageid',
'D' as '-',
	 C.CATEGORYID as 'Categoryid',
	 C.CATEGORYNAME as 'Categoryname',
	 C.DESCRIPTION as 'Description',
	 C.ICONIMAGEID as 'Iconimageid'
from CCImport_EVENTCATEGORY I 
	right join EVENTCATEGORY C on( C.CATEGORYID=I.CATEGORYID)
where I.CATEGORYID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CATEGORYID,
	 I.CATEGORYNAME,
	 I.DESCRIPTION,
	 I.ICONIMAGEID,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EVENTCATEGORY I 
	left join EVENTCATEGORY C on( C.CATEGORYID=I.CATEGORYID)
where C.CATEGORYID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CATEGORYID,
	 I.CATEGORYNAME,
	 I.DESCRIPTION,
	 I.ICONIMAGEID,
'U',
	 C.CATEGORYID,
	 C.CATEGORYNAME,
	 C.DESCRIPTION,
	 C.ICONIMAGEID
from CCImport_EVENTCATEGORY I 
	join EVENTCATEGORY C	on ( C.CATEGORYID=I.CATEGORYID)
where 	( I.CATEGORYNAME <>  C.CATEGORYNAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.ICONIMAGEID <>  C.ICONIMAGEID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCATEGORY]') and xtype='U')
begin
	drop table CCImport_EVENTCATEGORY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EVENTCATEGORY  to public
go
