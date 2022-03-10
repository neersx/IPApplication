-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCHARGETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCHARGETYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCHARGETYPE.'
	drop function dbo.fn_ccnCHARGETYPE
	print '**** Creating function dbo.fn_ccnCHARGETYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnCHARGETYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCHARGETYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CHARGETYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'CHARGETYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CHARGETYPE I 
	right join CHARGETYPE C on( C.CHARGETYPENO=I.CHARGETYPENO)
where I.CHARGETYPENO is null
UNION ALL 
select	8, 'CHARGETYPE', 0, count(*), 0, 0
from CCImport_CHARGETYPE I 
	left join CHARGETYPE C on( C.CHARGETYPENO=I.CHARGETYPENO)
where C.CHARGETYPENO is null
UNION ALL 
 select	8, 'CHARGETYPE', 0, 0, count(*), 0
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
UNION ALL 
 select	8, 'CHARGETYPE', 0, 0, 0, count(*)
from CCImport_CHARGETYPE I 
join CHARGETYPE C	on( C.CHARGETYPENO=I.CHARGETYPENO)
where ( I.CHARGEDESC =  C.CHARGEDESC)
and ( I.USEDASFLAG =  C.USEDASFLAG OR (I.USEDASFLAG is null and C.USEDASFLAG is null))
and ( I.CHARGEDUEEVENT =  C.CHARGEDUEEVENT OR (I.CHARGEDUEEVENT is null and C.CHARGEDUEEVENT is null))
and ( I.CHARGEINCURREDEVENT =  C.CHARGEINCURREDEVENT OR (I.CHARGEINCURREDEVENT is null and C.CHARGEINCURREDEVENT is null))
and ( I.PUBLICFLAG =  C.PUBLICFLAG OR (I.PUBLICFLAG is null and C.PUBLICFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CHARGETYPE]') and xtype='U')
begin
	drop table CCImport_CHARGETYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCHARGETYPE  to public
go
