-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_REQATTRIBUTES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_REQATTRIBUTES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_REQATTRIBUTES.'
	drop function dbo.fn_cc_REQATTRIBUTES
	print '**** Creating function dbo.fn_cc_REQATTRIBUTES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_REQATTRIBUTES]') and xtype='U')
begin
	select * 
	into CCImport_REQATTRIBUTES 
	from REQATTRIBUTES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_REQATTRIBUTES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_REQATTRIBUTES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the REQATTRIBUTES table
-- CALLED BY :	ip_CopyConfigREQATTRIBUTES
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
	 null as 'Imported Criteriano',
	 null as 'Imported Tabletype',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.TABLETYPE as 'Tabletype'
from CCImport_REQATTRIBUTES I 
	right join REQATTRIBUTES C on( C.CRITERIANO=I.CRITERIANO
and  C.TABLETYPE=I.TABLETYPE)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.TABLETYPE,
'I',
	 null ,
	 null
from CCImport_REQATTRIBUTES I 
	left join REQATTRIBUTES C on( C.CRITERIANO=I.CRITERIANO
and  C.TABLETYPE=I.TABLETYPE)
where C.CRITERIANO is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_REQATTRIBUTES]') and xtype='U')
begin
	drop table CCImport_REQATTRIBUTES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_REQATTRIBUTES  to public
go
