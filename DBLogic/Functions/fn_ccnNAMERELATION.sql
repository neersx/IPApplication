-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnNAMERELATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnNAMERELATION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnNAMERELATION.'
	drop function dbo.fn_ccnNAMERELATION
	print '**** Creating function dbo.fn_ccnNAMERELATION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NAMERELATION]') and xtype='U')
begin
	select * 
	into CCImport_NAMERELATION 
	from NAMERELATION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnNAMERELATION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnNAMERELATION
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the NAMERELATION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 11 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	2 as TRIPNO, 'NAMERELATION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_NAMERELATION I 
	right join NAMERELATION C on( C.RELATIONSHIP=I.RELATIONSHIP)
where I.RELATIONSHIP is null
UNION ALL 
select	2, 'NAMERELATION', 0, count(*), 0, 0
from CCImport_NAMERELATION I 
	left join NAMERELATION C on( C.RELATIONSHIP=I.RELATIONSHIP)
where C.RELATIONSHIP is null
UNION ALL 
 select	2, 'NAMERELATION', 0, 0, count(*), 0
from CCImport_NAMERELATION I 
	join NAMERELATION C	on ( C.RELATIONSHIP=I.RELATIONSHIP)
where 	( I.RELATIONDESCR <>  C.RELATIONDESCR OR (I.RELATIONDESCR is null and C.RELATIONDESCR is not null) 
OR (I.RELATIONDESCR is not null and C.RELATIONDESCR is null))
	OR 	( I.REVERSEDESCR <>  C.REVERSEDESCR OR (I.REVERSEDESCR is null and C.REVERSEDESCR is not null) 
OR (I.REVERSEDESCR is not null and C.REVERSEDESCR is null))
	OR 	( I.SHOWFLAG <>  C.SHOWFLAG OR (I.SHOWFLAG is null and C.SHOWFLAG is not null) 
OR (I.SHOWFLAG is not null and C.SHOWFLAG is null))
	OR 	( I.USEDBYNAMETYPE <>  C.USEDBYNAMETYPE OR (I.USEDBYNAMETYPE is null and C.USEDBYNAMETYPE is not null) 
OR (I.USEDBYNAMETYPE is not null and C.USEDBYNAMETYPE is null))
	OR 	( I.CRMONLY <>  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is not null) 
OR (I.CRMONLY is not null and C.CRMONLY is null))
	OR 	( I.ETHICALWALL <>  C.ETHICALWALL OR (I.ETHICALWALL is null and C.ETHICALWALL is not null )
OR (I.ETHICALWALL is not null and C.ETHICALWALL is null))
UNION ALL 
 select	2, 'NAMERELATION', 0, 0, 0, count(*)
from CCImport_NAMERELATION I 
join NAMERELATION C	on( C.RELATIONSHIP=I.RELATIONSHIP)
where ( I.RELATIONDESCR =  C.RELATIONDESCR OR (I.RELATIONDESCR is null and C.RELATIONDESCR is null))
and ( I.REVERSEDESCR =  C.REVERSEDESCR OR (I.REVERSEDESCR is null and C.REVERSEDESCR is null))
and ( I.SHOWFLAG =  C.SHOWFLAG OR (I.SHOWFLAG is null and C.SHOWFLAG is null))
and ( I.USEDBYNAMETYPE =  C.USEDBYNAMETYPE OR (I.USEDBYNAMETYPE is null and C.USEDBYNAMETYPE is null))
and ( I.CRMONLY =  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is null))
and ( I.ETHICALWALL = C.ETHICALWALL OR (I.ETHICALWALL is null and C.ETHICALWALL is  null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NAMERELATION]') and xtype='U')
begin
	drop table CCImport_NAMERELATION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnNAMERELATION  to public
go
