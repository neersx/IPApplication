-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DATASOURCE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DATASOURCE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DATASOURCE.'
	drop function dbo.fn_cc_DATASOURCE
	print '**** Creating function dbo.fn_cc_DATASOURCE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DATASOURCE]') and xtype='U')
begin
	select * 
	into CCImport_DATASOURCE 
	from DATASOURCE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DATASOURCE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DATASOURCE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DATASOURCE table
-- CALLED BY :	ip_CopyConfigDATASOURCE
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
	 null as 'Imported Systemid',
	 null as 'Imported Sourcenameno',
	 null as 'Imported Isprotected',
	 null as 'Imported Datasourcecode',
'D' as '-',
	 C.SYSTEMID as 'Systemid',
	 C.SOURCENAMENO as 'Sourcenameno',
	 C.ISPROTECTED as 'Isprotected',
	 C.DATASOURCECODE as 'Datasourcecode'
from CCImport_DATASOURCE I 
	right join DATASOURCE C on( C.DATASOURCEID=I.DATASOURCEID)
where I.DATASOURCEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SYSTEMID,
	 I.SOURCENAMENO,
	 I.ISPROTECTED,
	 I.DATASOURCECODE,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_DATASOURCE I 
	left join DATASOURCE C on( C.DATASOURCEID=I.DATASOURCEID)
where C.DATASOURCEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SYSTEMID,
	 I.SOURCENAMENO,
	 I.ISPROTECTED,
	 I.DATASOURCECODE,
'U',
	 C.SYSTEMID,
	 C.SOURCENAMENO,
	 C.ISPROTECTED,
	 C.DATASOURCECODE
from CCImport_DATASOURCE I 
	join DATASOURCE C	on ( C.DATASOURCEID=I.DATASOURCEID)
where 	( I.SYSTEMID <>  C.SYSTEMID)
	OR 	( I.SOURCENAMENO <>  C.SOURCENAMENO OR (I.SOURCENAMENO is null and C.SOURCENAMENO is not null) 
OR (I.SOURCENAMENO is not null and C.SOURCENAMENO is null))
	OR 	( I.ISPROTECTED <>  C.ISPROTECTED)
	OR 	( I.DATASOURCECODE <>  C.DATASOURCECODE OR (I.DATASOURCECODE is null and C.DATASOURCECODE is not null) 
OR (I.DATASOURCECODE is not null and C.DATASOURCECODE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DATASOURCE]') and xtype='U')
begin
	drop table CCImport_DATASOURCE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DATASOURCE  to public
go

