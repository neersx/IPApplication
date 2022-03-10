-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDTABLECODES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDTABLECODES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDTABLECODES.'
	drop function dbo.fn_cc_VALIDTABLECODES
	print '**** Creating function dbo.fn_cc_VALIDTABLECODES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDTABLECODES]') and xtype='U')
begin
	select * 
	into CCImport_VALIDTABLECODES 
	from VALIDTABLECODES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDTABLECODES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDTABLECODES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDTABLECODES table
-- CALLED BY :	ip_CopyConfigVALIDTABLECODES
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
	 null as 'Imported Tablecode',
	 null as 'Imported Validtablecode',
	 null as 'Imported Validtabletype',
'D' as '-',
	 C.TABLECODE as 'Tablecode',
	 C.VALIDTABLECODE as 'Validtablecode',
	 C.VALIDTABLETYPE as 'Validtabletype'
from CCImport_VALIDTABLECODES I 
	right join VALIDTABLECODES C on( C.VALIDTABLECODEID=I.VALIDTABLECODEID)
where I.VALIDTABLECODEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TABLECODE,
	 I.VALIDTABLECODE,
	 I.VALIDTABLETYPE,
'I',
	 null ,
	 null ,
	 null
from CCImport_VALIDTABLECODES I 
	left join VALIDTABLECODES C on( C.VALIDTABLECODEID=I.VALIDTABLECODEID)
where C.VALIDTABLECODEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TABLECODE,
	 I.VALIDTABLECODE,
	 I.VALIDTABLETYPE,
'U',
	 C.TABLECODE,
	 C.VALIDTABLECODE,
	 C.VALIDTABLETYPE
from CCImport_VALIDTABLECODES I 
	join VALIDTABLECODES C	on ( C.VALIDTABLECODEID=I.VALIDTABLECODEID)
where 	( I.TABLECODE <>  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is not null) 
OR (I.TABLECODE is not null and C.TABLECODE is null))
	OR 	( I.VALIDTABLECODE <>  C.VALIDTABLECODE OR (I.VALIDTABLECODE is null and C.VALIDTABLECODE is not null) 
OR (I.VALIDTABLECODE is not null and C.VALIDTABLECODE is null))
	OR 	( I.VALIDTABLETYPE <>  C.VALIDTABLETYPE OR (I.VALIDTABLETYPE is null and C.VALIDTABLETYPE is not null) 
OR (I.VALIDTABLETYPE is not null and C.VALIDTABLETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDTABLECODES]') and xtype='U')
begin
	drop table CCImport_VALIDTABLECODES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDTABLECODES  to public
go
