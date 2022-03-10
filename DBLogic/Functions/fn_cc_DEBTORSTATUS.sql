-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DEBTORSTATUS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DEBTORSTATUS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DEBTORSTATUS.'
	drop function dbo.fn_cc_DEBTORSTATUS
	print '**** Creating function dbo.fn_cc_DEBTORSTATUS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DEBTORSTATUS]') and xtype='U')
begin
	select * 
	into CCImport_DEBTORSTATUS 
	from DEBTORSTATUS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DEBTORSTATUS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DEBTORSTATUS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DEBTORSTATUS table
-- CALLED BY :	ip_CopyConfigDEBTORSTATUS
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
	 null as 'Imported Baddebtor',
	 null as 'Imported Debtorstatus',
	 null as 'Imported Actionflag',
	 null as 'Imported Clearpassword',
'D' as '-',
	 C.BADDEBTOR as 'Baddebtor',
	 C.DEBTORSTATUS as 'Debtorstatus',
	 C.ACTIONFLAG as 'Actionflag',
	 C.CLEARPASSWORD as 'Clearpassword'
from CCImport_DEBTORSTATUS I 
	right join DEBTORSTATUS C on( C.BADDEBTOR=I.BADDEBTOR)
where I.BADDEBTOR is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.BADDEBTOR,
	 I.DEBTORSTATUS,
	 I.ACTIONFLAG,
	 I.CLEARPASSWORD,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_DEBTORSTATUS I 
	left join DEBTORSTATUS C on( C.BADDEBTOR=I.BADDEBTOR)
where C.BADDEBTOR is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.BADDEBTOR,
	 I.DEBTORSTATUS,
	 I.ACTIONFLAG,
	 I.CLEARPASSWORD,
'U',
	 C.BADDEBTOR,
	 C.DEBTORSTATUS,
	 C.ACTIONFLAG,
	 C.CLEARPASSWORD
from CCImport_DEBTORSTATUS I 
	join DEBTORSTATUS C	on ( C.BADDEBTOR=I.BADDEBTOR)
where 	( I.DEBTORSTATUS <>  C.DEBTORSTATUS OR (I.DEBTORSTATUS is null and C.DEBTORSTATUS is not null) 
OR (I.DEBTORSTATUS is not null and C.DEBTORSTATUS is null))
	OR 	( I.ACTIONFLAG <>  C.ACTIONFLAG OR (I.ACTIONFLAG is null and C.ACTIONFLAG is not null) 
OR (I.ACTIONFLAG is not null and C.ACTIONFLAG is null))
	OR 	( I.CLEARPASSWORD <>  C.CLEARPASSWORD OR (I.CLEARPASSWORD is null and C.CLEARPASSWORD is not null) 
OR (I.CLEARPASSWORD is not null and C.CLEARPASSWORD is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DEBTORSTATUS]') and xtype='U')
begin
	drop table CCImport_DEBTORSTATUS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DEBTORSTATUS  to public
go
