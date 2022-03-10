-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCOUNTRYFLAGS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCOUNTRYFLAGS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCOUNTRYFLAGS.'
	drop function dbo.fn_ccnCOUNTRYFLAGS
	print '**** Creating function dbo.fn_ccnCOUNTRYFLAGS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYFLAGS]') and xtype='U')
begin
	select * 
	into CCImport_COUNTRYFLAGS 
	from COUNTRYFLAGS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCOUNTRYFLAGS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCOUNTRYFLAGS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the COUNTRYFLAGS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	4 as TRIPNO, 'COUNTRYFLAGS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_COUNTRYFLAGS I 
	right join COUNTRYFLAGS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where I.COUNTRYCODE is null
UNION ALL 
select	4, 'COUNTRYFLAGS', 0, count(*), 0, 0
from CCImport_COUNTRYFLAGS I 
	left join COUNTRYFLAGS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where C.COUNTRYCODE is null
UNION ALL 
 select	4, 'COUNTRYFLAGS', 0, 0, count(*), 0
from CCImport_COUNTRYFLAGS I 
	join COUNTRYFLAGS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.FLAGNUMBER=I.FLAGNUMBER)
where 	( I.FLAGNAME <>  C.FLAGNAME OR (I.FLAGNAME is null and C.FLAGNAME is not null) 
OR (I.FLAGNAME is not null and C.FLAGNAME is null))
	OR 	( I.NATIONALALLOWED <>  C.NATIONALALLOWED OR (I.NATIONALALLOWED is null and C.NATIONALALLOWED is not null) 
OR (I.NATIONALALLOWED is not null and C.NATIONALALLOWED is null))
	OR 	( I.RESTRICTREMOVALFLG <>  C.RESTRICTREMOVALFLG OR (I.RESTRICTREMOVALFLG is null and C.RESTRICTREMOVALFLG is not null) 
OR (I.RESTRICTREMOVALFLG is not null and C.RESTRICTREMOVALFLG is null))
	OR 	( I.PROFILENAME <>  C.PROFILENAME OR (I.PROFILENAME is null and C.PROFILENAME is not null) 
OR (I.PROFILENAME is not null and C.PROFILENAME is null))
	OR 	( I.STATUS <>  C.STATUS)
UNION ALL 
 select	4, 'COUNTRYFLAGS', 0, 0, 0, count(*)
from CCImport_COUNTRYFLAGS I 
join COUNTRYFLAGS C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.FLAGNUMBER=I.FLAGNUMBER)
where ( I.FLAGNAME =  C.FLAGNAME OR (I.FLAGNAME is null and C.FLAGNAME is null))
and ( I.NATIONALALLOWED =  C.NATIONALALLOWED OR (I.NATIONALALLOWED is null and C.NATIONALALLOWED is null))
and ( I.RESTRICTREMOVALFLG =  C.RESTRICTREMOVALFLG OR (I.RESTRICTREMOVALFLG is null and C.RESTRICTREMOVALFLG is null))
and ( I.PROFILENAME =  C.PROFILENAME OR (I.PROFILENAME is null and C.PROFILENAME is null))
and ( I.STATUS =  C.STATUS)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYFLAGS]') and xtype='U')
begin
	drop table CCImport_COUNTRYFLAGS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCOUNTRYFLAGS  to public
go
