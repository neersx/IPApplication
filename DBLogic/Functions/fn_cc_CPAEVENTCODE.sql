-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CPAEVENTCODE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CPAEVENTCODE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CPAEVENTCODE.'
	drop function dbo.fn_cc_CPAEVENTCODE
	print '**** Creating function dbo.fn_cc_CPAEVENTCODE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CPAEVENTCODE]') and xtype='U')
begin
	select * 
	into CCImport_CPAEVENTCODE 
	from CPAEVENTCODE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CPAEVENTCODE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CPAEVENTCODE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CPAEVENTCODE table
-- CALLED BY :	ip_CopyConfigCPAEVENTCODE
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
	 null as 'Imported Cpaeventcode',
	 null as 'Imported Description',
	 null as 'Imported Caseeventno',
'D' as '-',
	 C.CPAEVENTCODE as 'Cpaeventcode',
	 C.DESCRIPTION as 'Description',
	 C.CASEEVENTNO as 'Caseeventno'
from CCImport_CPAEVENTCODE I 
	right join CPAEVENTCODE C on( C.CPAEVENTCODE=I.CPAEVENTCODE)
where I.CPAEVENTCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CPAEVENTCODE,
	 I.DESCRIPTION,
	 I.CASEEVENTNO,
'I',
	 null ,
	 null ,
	 null
from CCImport_CPAEVENTCODE I 
	left join CPAEVENTCODE C on( C.CPAEVENTCODE=I.CPAEVENTCODE)
where C.CPAEVENTCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CPAEVENTCODE,
	 I.DESCRIPTION,
	 I.CASEEVENTNO,
'U',
	 C.CPAEVENTCODE,
	 C.DESCRIPTION,
	 C.CASEEVENTNO
from CCImport_CPAEVENTCODE I 
	join CPAEVENTCODE C	on ( C.CPAEVENTCODE=I.CPAEVENTCODE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.CASEEVENTNO <>  C.CASEEVENTNO OR (I.CASEEVENTNO is null and C.CASEEVENTNO is not null) 
OR (I.CASEEVENTNO is not null and C.CASEEVENTNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CPAEVENTCODE]') and xtype='U')
begin
	drop table CCImport_CPAEVENTCODE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CPAEVENTCODE  to public
go
