-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_RECORDALTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_RECORDALTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_RECORDALTYPE.'
	drop function dbo.fn_cc_RECORDALTYPE
	print '**** Creating function dbo.fn_cc_RECORDALTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDALTYPE]') and xtype='U')
begin
	select * 
	into CCImport_RECORDALTYPE 
	from RECORDALTYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_RECORDALTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_RECORDALTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RECORDALTYPE table
-- CALLED BY :	ip_CopyConfigRECORDALTYPE
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
	 null as 'Imported Recordaltype',
	 null as 'Imported Requesteventno',
	 null as 'Imported Requestaction',
	 null as 'Imported Recordeventno',
	 null as 'Imported Recordaction',
'D' as '-',
	 C.RECORDALTYPE as 'Recordaltype',
	 C.REQUESTEVENTNO as 'Requesteventno',
	 C.REQUESTACTION as 'Requestaction',
	 C.RECORDEVENTNO as 'Recordeventno',
	 C.RECORDACTION as 'Recordaction'
from CCImport_RECORDALTYPE I 
	right join RECORDALTYPE C on( C.RECORDALTYPENO=I.RECORDALTYPENO)
where I.RECORDALTYPENO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.RECORDALTYPE,
	 I.REQUESTEVENTNO,
	 I.REQUESTACTION,
	 I.RECORDEVENTNO,
	 I.RECORDACTION,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_RECORDALTYPE I 
	left join RECORDALTYPE C on( C.RECORDALTYPENO=I.RECORDALTYPENO)
where C.RECORDALTYPENO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.RECORDALTYPE,
	 I.REQUESTEVENTNO,
	 I.REQUESTACTION,
	 I.RECORDEVENTNO,
	 I.RECORDACTION,
'U',
	 C.RECORDALTYPE,
	 C.REQUESTEVENTNO,
	 C.REQUESTACTION,
	 C.RECORDEVENTNO,
	 C.RECORDACTION
from CCImport_RECORDALTYPE I 
	join RECORDALTYPE C	on ( C.RECORDALTYPENO=I.RECORDALTYPENO)
where 	( I.RECORDALTYPE <>  C.RECORDALTYPE)
	OR 	( I.REQUESTEVENTNO <>  C.REQUESTEVENTNO OR (I.REQUESTEVENTNO is null and C.REQUESTEVENTNO is not null) 
OR (I.REQUESTEVENTNO is not null and C.REQUESTEVENTNO is null))
	OR 	( I.REQUESTACTION <>  C.REQUESTACTION OR (I.REQUESTACTION is null and C.REQUESTACTION is not null) 
OR (I.REQUESTACTION is not null and C.REQUESTACTION is null))
	OR 	( I.RECORDEVENTNO <>  C.RECORDEVENTNO OR (I.RECORDEVENTNO is null and C.RECORDEVENTNO is not null) 
OR (I.RECORDEVENTNO is not null and C.RECORDEVENTNO is null))
	OR 	( I.RECORDACTION <>  C.RECORDACTION OR (I.RECORDACTION is null and C.RECORDACTION is not null) 
OR (I.RECORDACTION is not null and C.RECORDACTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDALTYPE]') and xtype='U')
begin
	drop table CCImport_RECORDALTYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_RECORDALTYPE  to public
go
