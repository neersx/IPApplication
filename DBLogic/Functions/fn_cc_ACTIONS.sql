-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ACTIONS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ACTIONS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ACTIONS.'
	drop function dbo.fn_cc_ACTIONS
	print '**** Creating function dbo.fn_cc_ACTIONS...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ACTIONS]') and xtype='U')
begin
	select * 
	into CCImport_ACTIONS 
	from ACTIONS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ACTIONS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ACTIONS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ACTIONS table
-- CALLED BY :	ip_CopyConfigACTIONS
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
	 null as 'Imported Action',
	 null as 'Imported Actionname',
	 null as 'Imported Numcyclesallowed',
	 null as 'Imported Actiontypeflag',
	 null as 'Imported Importancelevel',
'D' as '-',
	 C.ACTION as 'Action',
	 C.ACTIONNAME as 'Actionname',
	 C.NUMCYCLESALLOWED as 'Numcyclesallowed',
	 C.ACTIONTYPEFLAG as 'Actiontypeflag',
	 C.IMPORTANCELEVEL as 'Importancelevel'
from CCImport_ACTIONS I 
	right join ACTIONS C on( C.ACTION=I.ACTION)
where I.ACTION is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ACTION,
	 I.ACTIONNAME,
	 I.NUMCYCLESALLOWED,
	 I.ACTIONTYPEFLAG,
	 I.IMPORTANCELEVEL,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ACTIONS I 
	left join ACTIONS C on( C.ACTION=I.ACTION)
where C.ACTION is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ACTION,
	 I.ACTIONNAME,
	 I.NUMCYCLESALLOWED,
	 I.ACTIONTYPEFLAG,
	 I.IMPORTANCELEVEL,
'U',
	 C.ACTION,
	 C.ACTIONNAME,
	 C.NUMCYCLESALLOWED,
	 C.ACTIONTYPEFLAG,
	 C.IMPORTANCELEVEL
from CCImport_ACTIONS I 
	join ACTIONS C	on ( C.ACTION=I.ACTION)
where 	( I.ACTIONNAME <>  C.ACTIONNAME OR (I.ACTIONNAME is null and C.ACTIONNAME is not null) 
OR (I.ACTIONNAME is not null and C.ACTIONNAME is null))
	OR 	( I.NUMCYCLESALLOWED <>  C.NUMCYCLESALLOWED OR (I.NUMCYCLESALLOWED is null and C.NUMCYCLESALLOWED is not null) 
OR (I.NUMCYCLESALLOWED is not null and C.NUMCYCLESALLOWED is null))
	OR 	( I.ACTIONTYPEFLAG <>  C.ACTIONTYPEFLAG OR (I.ACTIONTYPEFLAG is null and C.ACTIONTYPEFLAG is not null) 
OR (I.ACTIONTYPEFLAG is not null and C.ACTIONTYPEFLAG is null))
	OR 	( I.IMPORTANCELEVEL <>  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is not null) 
OR (I.IMPORTANCELEVEL is not null and C.IMPORTANCELEVEL is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ACTIONS]') and xtype='U')
begin
	drop table CCImport_ACTIONS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ACTIONS  to public
go

