-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_RATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_RATES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_RATES.'
	drop function dbo.fn_cc_RATES
	print '**** Creating function dbo.fn_cc_RATES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RATES]') and xtype='U')
begin
	select * 
	into CCImport_RATES 
	from RATES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_RATES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_RATES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RATES table
-- CALLED BY :	ip_CopyConfigRATES
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
	 null as 'Imported Rateno',
	 null as 'Imported Ratedesc',
	 null as 'Imported Ratetype',
	 null as 'Imported Usetypeofmark',
	 null as 'Imported Ratenosort',
	 null as 'Imported Calclabel1',
	 null as 'Imported Calclabel2',
	 null as 'Imported Action',
	 null as 'Imported Agentnametype',
'D' as '-',
	 C.RATENO as 'Rateno',
	 C.RATEDESC as 'Ratedesc',
	 C.RATETYPE as 'Ratetype',
	 C.USETYPEOFMARK as 'Usetypeofmark',
	 C.RATENOSORT as 'Ratenosort',
	 C.CALCLABEL1 as 'Calclabel1',
	 C.CALCLABEL2 as 'Calclabel2',
	 C.ACTION as 'Action',
	 C.AGENTNAMETYPE as 'Agentnametype'
from CCImport_RATES I 
	right join RATES C on( C.RATENO=I.RATENO)
where I.RATENO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.RATENO,
	 I.RATEDESC,
	 I.RATETYPE,
	 I.USETYPEOFMARK,
	 I.RATENOSORT,
	 I.CALCLABEL1,
	 I.CALCLABEL2,
	 I.ACTION,
	 I.AGENTNAMETYPE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_RATES I 
	left join RATES C on( C.RATENO=I.RATENO)
where C.RATENO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.RATENO,
	 I.RATEDESC,
	 I.RATETYPE,
	 I.USETYPEOFMARK,
	 I.RATENOSORT,
	 I.CALCLABEL1,
	 I.CALCLABEL2,
	 I.ACTION,
	 I.AGENTNAMETYPE,
'U',
	 C.RATENO,
	 C.RATEDESC,
	 C.RATETYPE,
	 C.USETYPEOFMARK,
	 C.RATENOSORT,
	 C.CALCLABEL1,
	 C.CALCLABEL2,
	 C.ACTION,
	 C.AGENTNAMETYPE
from CCImport_RATES I 
	join RATES C	on ( C.RATENO=I.RATENO)
where 	( I.RATEDESC <>  C.RATEDESC OR (I.RATEDESC is null and C.RATEDESC is not null) 
OR (I.RATEDESC is not null and C.RATEDESC is null))
	OR 	( I.RATETYPE <>  C.RATETYPE OR (I.RATETYPE is null and C.RATETYPE is not null) 
OR (I.RATETYPE is not null and C.RATETYPE is null))
	OR 	( I.USETYPEOFMARK <>  C.USETYPEOFMARK OR (I.USETYPEOFMARK is null and C.USETYPEOFMARK is not null) 
OR (I.USETYPEOFMARK is not null and C.USETYPEOFMARK is null))
	OR 	( I.RATENOSORT <>  C.RATENOSORT OR (I.RATENOSORT is null and C.RATENOSORT is not null) 
OR (I.RATENOSORT is not null and C.RATENOSORT is null))
	OR 	( I.CALCLABEL1 <>  C.CALCLABEL1 OR (I.CALCLABEL1 is null and C.CALCLABEL1 is not null) 
OR (I.CALCLABEL1 is not null and C.CALCLABEL1 is null))
	OR 	( I.CALCLABEL2 <>  C.CALCLABEL2 OR (I.CALCLABEL2 is null and C.CALCLABEL2 is not null) 
OR (I.CALCLABEL2 is not null and C.CALCLABEL2 is null))
	OR 	( I.ACTION <>  C.ACTION OR (I.ACTION is null and C.ACTION is not null) 
OR (I.ACTION is not null and C.ACTION is null))
	OR 	( I.AGENTNAMETYPE <>  C.AGENTNAMETYPE OR (I.AGENTNAMETYPE is null and C.AGENTNAMETYPE is not null) 
OR (I.AGENTNAMETYPE is not null and C.AGENTNAMETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RATES]') and xtype='U')
begin
	drop table CCImport_RATES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_RATES  to public
go

