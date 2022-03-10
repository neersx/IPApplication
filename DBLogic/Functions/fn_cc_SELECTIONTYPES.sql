-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_SELECTIONTYPES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_SELECTIONTYPES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_SELECTIONTYPES.'
	drop function dbo.fn_cc_SELECTIONTYPES
	print '**** Creating function dbo.fn_cc_SELECTIONTYPES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SELECTIONTYPES]') and xtype='U')
begin
	select * 
	into CCImport_SELECTIONTYPES 
	from SELECTIONTYPES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_SELECTIONTYPES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_SELECTIONTYPES
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the SELECTIONTYPES table
-- CALLED BY :	ip_CopyConfigSELECTIONTYPES
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 03 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Parenttable',
	 null as 'Imported Tabletype',
	 null as 'Imported Minimumallowed',
	 null as 'Imported Maximumallowed',
	 null as 'Imported Modifybyservice',
	'D' as '-',
	 C.PARENTTABLE as 'Parenttable',
	 C.TABLETYPE as 'Tabletype',
	 C.MINIMUMALLOWED as 'Minimumallowed',
	 C.MAXIMUMALLOWED as 'Maximumallowed',
	 C.MODIFYBYSERVICE as 'Modifybyservice'
from CCImport_SELECTIONTYPES I 
	right join SELECTIONTYPES C on( C.PARENTTABLE=I.PARENTTABLE
and  C.TABLETYPE=I.TABLETYPE)
where I.PARENTTABLE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PARENTTABLE,
	 I.TABLETYPE,
	 I.MINIMUMALLOWED,
	 I.MAXIMUMALLOWED,
	 I.MODIFYBYSERVICE,
	'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_SELECTIONTYPES I 
	left join SELECTIONTYPES C on( C.PARENTTABLE=I.PARENTTABLE
and  C.TABLETYPE=I.TABLETYPE)
where C.PARENTTABLE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.PARENTTABLE,
	 I.TABLETYPE,
	 I.MINIMUMALLOWED,
	 I.MAXIMUMALLOWED,
	 I.MODIFYBYSERVICE,
	'U',
	 C.PARENTTABLE,
	 C.TABLETYPE,
	 C.MINIMUMALLOWED,
	 C.MAXIMUMALLOWED,
	 C.MODIFYBYSERVICE
from CCImport_SELECTIONTYPES I 
	join SELECTIONTYPES C	on ( C.PARENTTABLE=I.PARENTTABLE
	and C.TABLETYPE=I.TABLETYPE)
where 	( I.MINIMUMALLOWED <>  C.MINIMUMALLOWED OR (I.MINIMUMALLOWED is null and C.MINIMUMALLOWED is not null) 
OR (I.MINIMUMALLOWED is not null and C.MINIMUMALLOWED is null))
	OR 	( I.MAXIMUMALLOWED <>  C.MAXIMUMALLOWED OR (I.MAXIMUMALLOWED is null and C.MAXIMUMALLOWED is not null) 
OR (I.MAXIMUMALLOWED is not null and C.MAXIMUMALLOWED is null))
	OR 	( I.MODIFYBYSERVICE <>  C.MODIFYBYSERVICE OR (I.MODIFYBYSERVICE is null and C.MODIFYBYSERVICE is not null) 
OR (I.MODIFYBYSERVICE is not null and C.MODIFYBYSERVICE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SELECTIONTYPES]') and xtype='U')
begin
	drop table CCImport_SELECTIONTYPES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_SELECTIONTYPES  to public
go
