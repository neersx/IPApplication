-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_NAMERELATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_NAMERELATION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_NAMERELATION.'
	drop function dbo.fn_cc_NAMERELATION
	print '**** Creating function dbo.fn_cc_NAMERELATION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NAMERELATION]') and xtype='U')
begin
	select * 
	into CCImport_NAMERELATION 
	from NAMERELATION
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_NAMERELATION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_NAMERELATION
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the NAMERELATION table
-- CALLED BY :	ip_CopyConfigNAMERELATION
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 03 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Relationship',
	 null as 'Imported Relationdescr',
	 null as 'Imported Reversedescr',
	 null as 'Imported Showflag',
	 null as 'Imported Usedbynametype',
	 null as 'Imported Crmonly',
	 null as 'Imported Ethicalwall',
	'D' as '-',
	 C.RELATIONSHIP as 'Relationship',
	 C.RELATIONDESCR as 'Relationdescr',
	 C.REVERSEDESCR as 'Reversedescr',
	 C.SHOWFLAG as 'Showflag',
	 C.USEDBYNAMETYPE as 'Usedbynametype',
	 C.CRMONLY as 'Crmonly',
	 C.ETHICALWALL as 'Ethicalwall'
from CCImport_NAMERELATION I 
	right join NAMERELATION C on( C.RELATIONSHIP=I.RELATIONSHIP)
where I.RELATIONSHIP is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.RELATIONSHIP,
	 I.RELATIONDESCR,
	 I.REVERSEDESCR,
	 I.SHOWFLAG,
	 I.USEDBYNAMETYPE,
	 I.CRMONLY,
	 I.ETHICALWALL,
	'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_NAMERELATION I 
	left join NAMERELATION C on( C.RELATIONSHIP=I.RELATIONSHIP)
where C.RELATIONSHIP is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.RELATIONSHIP,
	 I.RELATIONDESCR,
	 I.REVERSEDESCR,
	 I.SHOWFLAG,
	 I.USEDBYNAMETYPE,
	 I.CRMONLY,
	 I.ETHICALWALL,
	'U',
	 C.RELATIONSHIP,
	 C.RELATIONDESCR,
	 C.REVERSEDESCR,
	 C.SHOWFLAG,
	 C.USEDBYNAMETYPE,
	 C.CRMONLY,
	 C.ETHICALWALL
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
	OR 	( I.ETHICALWALL <>  C.ETHICALWALL OR (I.ETHICALWALL is null and C.ETHICALWALL is not null) 
OR (I.ETHICALWALL is not null and C.ETHICALWALL is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NAMERELATION]') and xtype='U')
begin
	drop table CCImport_NAMERELATION 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_NAMERELATION  to public
go
