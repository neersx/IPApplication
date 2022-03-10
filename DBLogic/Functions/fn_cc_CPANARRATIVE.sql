-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CPANARRATIVE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CPANARRATIVE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CPANARRATIVE.'
	drop function dbo.fn_cc_CPANARRATIVE
	print '**** Creating function dbo.fn_cc_CPANARRATIVE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CPANARRATIVE]') and xtype='U')
begin
	select * 
	into CCImport_CPANARRATIVE 
	from CPANARRATIVE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CPANARRATIVE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CPANARRATIVE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CPANARRATIVE table
-- CALLED BY :	ip_CopyConfigCPANARRATIVE
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
	 null as 'Imported Cpanarrative',
	 null as 'Imported Caseeventno',
	 null as 'Imported Excludeflag',
	 null as 'Imported Narrativedesc',
'D' as '-',
	 C.CPANARRATIVE as 'Cpanarrative',
	 C.CASEEVENTNO as 'Caseeventno',
	 C.EXCLUDEFLAG as 'Excludeflag',
	 C.NARRATIVEDESC as 'Narrativedesc'
from CCImport_CPANARRATIVE I 
	right join CPANARRATIVE C on( C.CPANARRATIVE=I.CPANARRATIVE)
where I.CPANARRATIVE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CPANARRATIVE,
	 I.CASEEVENTNO,
	 I.EXCLUDEFLAG,
	 I.NARRATIVEDESC,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_CPANARRATIVE I 
	left join CPANARRATIVE C on( C.CPANARRATIVE=I.CPANARRATIVE)
where C.CPANARRATIVE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CPANARRATIVE,
	 I.CASEEVENTNO,
	 I.EXCLUDEFLAG,
	 I.NARRATIVEDESC,
'U',
	 C.CPANARRATIVE,
	 C.CASEEVENTNO,
	 C.EXCLUDEFLAG,
	 C.NARRATIVEDESC
from CCImport_CPANARRATIVE I 
	join CPANARRATIVE C	on ( C.CPANARRATIVE=I.CPANARRATIVE)
where 	( I.CASEEVENTNO <>  C.CASEEVENTNO OR (I.CASEEVENTNO is null and C.CASEEVENTNO is not null) 
OR (I.CASEEVENTNO is not null and C.CASEEVENTNO is null))
	OR 	( I.EXCLUDEFLAG <>  C.EXCLUDEFLAG)
	OR 	(replace( I.NARRATIVEDESC,char(10),char(13)+char(10)) <>  C.NARRATIVEDESC OR (I.NARRATIVEDESC is null and C.NARRATIVEDESC is not null) 
OR (I.NARRATIVEDESC is not null and C.NARRATIVEDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CPANARRATIVE]') and xtype='U')
begin
	drop table CCImport_CPANARRATIVE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CPANARRATIVE  to public
go
