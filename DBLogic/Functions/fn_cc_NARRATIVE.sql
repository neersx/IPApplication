-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_NARRATIVE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_NARRATIVE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_NARRATIVE.'
	drop function dbo.fn_cc_NARRATIVE
	print '**** Creating function dbo.fn_cc_NARRATIVE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NARRATIVE]') and xtype='U')
begin
	select * 
	into CCImport_NARRATIVE 
	from NARRATIVE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_NARRATIVE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_NARRATIVE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the NARRATIVE table
-- CALLED BY :	ip_CopyConfigNARRATIVE
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
	 null as 'Imported Narrativeno',
	 null as 'Imported Narrativecode',
	 null as 'Imported Narrativetitle',
	 null as 'Imported Narrativetext',
'D' as '-',
	 C.NARRATIVENO as 'Narrativeno',
	 C.NARRATIVECODE as 'Narrativecode',
	 C.NARRATIVETITLE as 'Narrativetitle',
	 CAST(C.NARRATIVETEXT AS NVARCHAR(4000)) as 'Narrativetext'
from CCImport_NARRATIVE I 
	right join NARRATIVE C on( C.NARRATIVENO=I.NARRATIVENO)
where I.NARRATIVENO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NARRATIVENO,
	 I.NARRATIVECODE,
	 I.NARRATIVETITLE,
	 CAST(I.NARRATIVETEXT AS NVARCHAR(4000)),
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_NARRATIVE I 
	left join NARRATIVE C on( C.NARRATIVENO=I.NARRATIVENO)
where C.NARRATIVENO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.NARRATIVENO,
	 I.NARRATIVECODE,
	 I.NARRATIVETITLE,
	 CAST(I.NARRATIVETEXT AS NVARCHAR(4000)),
'U',
	 C.NARRATIVENO,
	 C.NARRATIVECODE,
	 C.NARRATIVETITLE,
	 CAST(C.NARRATIVETEXT AS NVARCHAR(4000))
from CCImport_NARRATIVE I 
	join NARRATIVE C	on ( C.NARRATIVENO=I.NARRATIVENO)
where 	( I.NARRATIVECODE <>  C.NARRATIVECODE OR (I.NARRATIVECODE is null and C.NARRATIVECODE is not null) 
OR (I.NARRATIVECODE is not null and C.NARRATIVECODE is null))
	OR 	( I.NARRATIVETITLE <>  C.NARRATIVETITLE OR (I.NARRATIVETITLE is null and C.NARRATIVETITLE is not null) 
OR (I.NARRATIVETITLE is not null and C.NARRATIVETITLE is null))
	OR 	( replace(CAST(I.NARRATIVETEXT as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.NARRATIVETEXT as NVARCHAR(MAX)) OR (I.NARRATIVETEXT is null and C.NARRATIVETEXT is not null) 
OR (I.NARRATIVETEXT is not null and C.NARRATIVETEXT is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NARRATIVE]') and xtype='U')
begin
	drop table CCImport_NARRATIVE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_NARRATIVE  to public
go
