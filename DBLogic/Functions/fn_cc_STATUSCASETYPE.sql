-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_STATUSCASETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_STATUSCASETYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_STATUSCASETYPE.'
	drop function dbo.fn_cc_STATUSCASETYPE
	print '**** Creating function dbo.fn_cc_STATUSCASETYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_STATUSCASETYPE]') and xtype='U')
begin
	select * 
	into CCImport_STATUSCASETYPE 
	from STATUSCASETYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_STATUSCASETYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_STATUSCASETYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the STATUSCASETYPE table
-- CALLED BY :	ip_CopyConfigSTATUSCASETYPE
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
	 null as 'Imported Casetype',
	 null as 'Imported Statuscode',
'D' as '-',
	 C.CASETYPE as 'Casetype',
	 C.STATUSCODE as 'Statuscode'
from CCImport_STATUSCASETYPE I 
	right join STATUSCASETYPE C on( C.CASETYPE=I.CASETYPE
and  C.STATUSCODE=I.STATUSCODE)
where I.CASETYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CASETYPE,
	 I.STATUSCODE,
'I',
	 null ,
	 null
from CCImport_STATUSCASETYPE I 
	left join STATUSCASETYPE C on( C.CASETYPE=I.CASETYPE
and  C.STATUSCODE=I.STATUSCODE)
where C.CASETYPE is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_STATUSCASETYPE]') and xtype='U')
begin
	drop table CCImport_STATUSCASETYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_STATUSCASETYPE  to public
go
