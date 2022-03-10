-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CHARGETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CHARGETYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CHARGETYPE.'
	drop function dbo.fn_cc_CHARGETYPE
	print '**** Creating function dbo.fn_cc_CHARGETYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CHARGETYPE]') and xtype='U')
begin
	select * 
	into CCImport_CHARGETYPE 
	from CHARGETYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CHARGETYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CHARGETYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CHARGETYPE table
-- CALLED BY :	ip_CopyConfigCHARGETYPE
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
	 null as 'Imported Chargedesc',
	 null as 'Imported Usedasflag',
	 null as 'Imported Chargedueevent',
	 null as 'Imported Chargeincurredevent',
	 null as 'Imported Publicflag',
'D' as '-',
	 C.CHARGEDESC as 'Chargedesc',
	 C.USEDASFLAG as 'Usedasflag',
	 C.CHARGEDUEEVENT as 'Chargedueevent',
	 C.CHARGEINCURREDEVENT as 'Chargeincurredevent',
	 C.PUBLICFLAG as 'Publicflag'
from CCImport_CHARGETYPE I 
	right join CHARGETYPE C on( C.CHARGETYPENO=I.CHARGETYPENO)
where I.CHARGETYPENO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CHARGEDESC,
	 I.USEDASFLAG,
	 I.CHARGEDUEEVENT,
	 I.CHARGEINCURREDEVENT,
	 I.PUBLICFLAG,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_CHARGETYPE I 
	left join CHARGETYPE C on( C.CHARGETYPENO=I.CHARGETYPENO)
where C.CHARGETYPENO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CHARGEDESC,
	 I.USEDASFLAG,
	 I.CHARGEDUEEVENT,
	 I.CHARGEINCURREDEVENT,
	 I.PUBLICFLAG,
'U',
	 C.CHARGEDESC,
	 C.USEDASFLAG,
	 C.CHARGEDUEEVENT,
	 C.CHARGEINCURREDEVENT,
	 C.PUBLICFLAG
from CCImport_CHARGETYPE I 
	join CHARGETYPE C	on ( C.CHARGETYPENO=I.CHARGETYPENO)
where 	( I.CHARGEDESC <>  C.CHARGEDESC)
	OR 	( I.USEDASFLAG <>  C.USEDASFLAG OR (I.USEDASFLAG is null and C.USEDASFLAG is not null) 
OR (I.USEDASFLAG is not null and C.USEDASFLAG is null))
	OR 	( I.CHARGEDUEEVENT <>  C.CHARGEDUEEVENT OR (I.CHARGEDUEEVENT is null and C.CHARGEDUEEVENT is not null) 
OR (I.CHARGEDUEEVENT is not null and C.CHARGEDUEEVENT is null))
	OR 	( I.CHARGEINCURREDEVENT <>  C.CHARGEINCURREDEVENT OR (I.CHARGEINCURREDEVENT is null and C.CHARGEINCURREDEVENT is not null) 
OR (I.CHARGEINCURREDEVENT is not null and C.CHARGEINCURREDEVENT is null))
	OR 	( I.PUBLICFLAG <>  C.PUBLICFLAG OR (I.PUBLICFLAG is null and C.PUBLICFLAG is not null) 
OR (I.PUBLICFLAG is not null and C.PUBLICFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CHARGETYPE]') and xtype='U')
begin
	drop table CCImport_CHARGETYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CHARGETYPE  to public
go

