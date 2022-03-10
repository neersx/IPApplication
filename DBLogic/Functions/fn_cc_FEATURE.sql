-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FEATURE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FEATURE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FEATURE.'
	drop function dbo.fn_cc_FEATURE
	print '**** Creating function dbo.fn_cc_FEATURE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEATURE]') and xtype='U')
begin
	select * 
	into CCImport_FEATURE 
	from FEATURE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_FEATURE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FEATURE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEATURE table
-- CALLED BY :	ip_CopyConfigFEATURE
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
	 null as 'Imported Featureid',
	 null as 'Imported Featurename',
	 null as 'Imported Categoryid',
	 null as 'Imported Isexternal',
	 null as 'Imported Isinternal',
'D' as '-',
	 C.FEATUREID as 'Featureid',
	 C.FEATURENAME as 'Featurename',
	 C.CATEGORYID as 'Categoryid',
	 C.ISEXTERNAL as 'Isexternal',
	 C.ISINTERNAL as 'Isinternal'
from CCImport_FEATURE I 
	right join FEATURE C on( C.FEATUREID=I.FEATUREID)
where I.FEATUREID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.FEATUREID,
	 I.FEATURENAME,
	 I.CATEGORYID,
	 I.ISEXTERNAL,
	 I.ISINTERNAL,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_FEATURE I 
	left join FEATURE C on( C.FEATUREID=I.FEATUREID)
where C.FEATUREID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.FEATUREID,
	 I.FEATURENAME,
	 I.CATEGORYID,
	 I.ISEXTERNAL,
	 I.ISINTERNAL,
'U',
	 C.FEATUREID,
	 C.FEATURENAME,
	 C.CATEGORYID,
	 C.ISEXTERNAL,
	 C.ISINTERNAL
from CCImport_FEATURE I 
	join FEATURE C	on ( C.FEATUREID=I.FEATUREID)
where 	( I.FEATURENAME <>  C.FEATURENAME)
	OR 	( I.CATEGORYID <>  C.CATEGORYID OR (I.CATEGORYID is null and C.CATEGORYID is not null) 
OR (I.CATEGORYID is not null and C.CATEGORYID is null))
	OR 	( I.ISEXTERNAL <>  C.ISEXTERNAL)
	OR 	( I.ISINTERNAL <>  C.ISINTERNAL)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEATURE]') and xtype='U')
begin
	drop table CCImport_FEATURE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FEATURE  to public
go

