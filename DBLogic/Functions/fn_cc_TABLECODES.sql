-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TABLECODES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TABLECODES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TABLECODES.'
	drop function dbo.fn_cc_TABLECODES
	print '**** Creating function dbo.fn_cc_TABLECODES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TABLECODES]') and xtype='U')
begin
	select * 
	into CCImport_TABLECODES 
	from TABLECODES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TABLECODES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TABLECODES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TABLECODES table
-- CALLED BY :	ip_CopyConfigTABLECODES
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
	 null as 'Imported Tabletype',
	 null as 'Imported Description',
	 null as 'Imported Usercode',
	 null as 'Imported Booleanflag',
'D' as '-',
	 C.TABLECODE as 'Tablecode',
	 C.TABLETYPE as 'Tabletype',
	 C.DESCRIPTION as 'Description',
	 C.USERCODE as 'Usercode',
	 C.BOOLEANFLAG as 'Booleanflag'
from CCImport_TABLECODES I 
	right join TABLECODES C on( C.TABLECODE=I.TABLECODE)
where I.TABLECODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TABLECODE,
	 I.TABLETYPE,
	 I.DESCRIPTION,
	 I.USERCODE,
	 I.BOOLEANFLAG,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_TABLECODES I 
	left join TABLECODES C on( C.TABLECODE=I.TABLECODE)
where C.TABLECODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TABLECODE,
	 I.TABLETYPE,
	 I.DESCRIPTION,
	 I.USERCODE,
	 I.BOOLEANFLAG,
'U',
	 C.TABLECODE,
	 C.TABLETYPE,
	 C.DESCRIPTION,
	 C.USERCODE,
	 C.BOOLEANFLAG
from CCImport_TABLECODES I 
	join TABLECODES C	on ( C.TABLECODE=I.TABLECODE)
where 	( I.TABLETYPE <>  C.TABLETYPE OR (I.TABLETYPE is null and C.TABLETYPE is not null) 
OR (I.TABLETYPE is not null and C.TABLETYPE is null))
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.USERCODE <>  C.USERCODE OR (I.USERCODE is null and C.USERCODE is not null) 
OR (I.USERCODE is not null and C.USERCODE is null))
	OR 	( I.BOOLEANFLAG <>  C.BOOLEANFLAG OR (I.BOOLEANFLAG is null and C.BOOLEANFLAG is not null) 
OR (I.BOOLEANFLAG is not null and C.BOOLEANFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TABLECODES]') and xtype='U')
begin
	drop table CCImport_TABLECODES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TABLECODES  to public
go
