-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCOUNTRYGROUP
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCOUNTRYGROUP]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCOUNTRYGROUP.'
	drop function dbo.fn_ccnCOUNTRYGROUP
	print '**** Creating function dbo.fn_ccnCOUNTRYGROUP...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYGROUP]') and xtype='U')
begin
	select * 
	into CCImport_COUNTRYGROUP 
	from COUNTRYGROUP
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCOUNTRYGROUP
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCOUNTRYGROUP
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the COUNTRYGROUP table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 11 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	4 as TRIPNO, 'COUNTRYGROUP' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_COUNTRYGROUP I 
	right join COUNTRYGROUP C on( C.TREATYCODE=I.TREATYCODE
and  C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
where I.TREATYCODE is null
UNION ALL 
select	4, 'COUNTRYGROUP', 0, count(*), 0, 0
from CCImport_COUNTRYGROUP I 
	left join COUNTRYGROUP C on( C.TREATYCODE=I.TREATYCODE
and  C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
where C.TREATYCODE is null
UNION ALL 
 select	4, 'COUNTRYGROUP', 0, 0, count(*), 0
from CCImport_COUNTRYGROUP I 
	join COUNTRYGROUP C	on ( C.TREATYCODE=I.TREATYCODE
	and C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
where 	( I.DATECOMMENCED <>  C.DATECOMMENCED OR (I.DATECOMMENCED is null and C.DATECOMMENCED is not null) 
OR (I.DATECOMMENCED is not null and C.DATECOMMENCED is null))
	OR 	( I.DATECEASED <>  C.DATECEASED OR (I.DATECEASED is null and C.DATECEASED is not null) 
OR (I.DATECEASED is not null and C.DATECEASED is null))
	OR 	( I.ASSOCIATEMEMBER <>  C.ASSOCIATEMEMBER OR (I.ASSOCIATEMEMBER is null and C.ASSOCIATEMEMBER is not null) 
OR (I.ASSOCIATEMEMBER is not null and C.ASSOCIATEMEMBER is null))
	OR 	( I.DEFAULTFLAG <>  C.DEFAULTFLAG OR (I.DEFAULTFLAG is null and C.DEFAULTFLAG is not null) 
OR (I.DEFAULTFLAG is not null and C.DEFAULTFLAG is null))
	OR 	( I.PREVENTNATPHASE <>  C.PREVENTNATPHASE OR (I.PREVENTNATPHASE is null and C.PREVENTNATPHASE is not null) 
OR (I.PREVENTNATPHASE is not null and C.PREVENTNATPHASE is null))
	OR	( I.FULLMEMBERDATE <>  C.FULLMEMBERDATE OR (I.FULLMEMBERDATE is null and C.FULLMEMBERDATE is not null )
 OR (I.FULLMEMBERDATE is not null and C.FULLMEMBERDATE is null))
UNION ALL 
 select	4, 'COUNTRYGROUP', 0, 0, 0, count(*)
from CCImport_COUNTRYGROUP I 
join COUNTRYGROUP C	on( C.TREATYCODE=I.TREATYCODE
and C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
where ( I.DATECOMMENCED =  C.DATECOMMENCED OR (I.DATECOMMENCED is null and C.DATECOMMENCED is null))
and ( I.DATECEASED =  C.DATECEASED OR (I.DATECEASED is null and C.DATECEASED is null))
and ( I.ASSOCIATEMEMBER =  C.ASSOCIATEMEMBER OR (I.ASSOCIATEMEMBER is null and C.ASSOCIATEMEMBER is null))
and ( I.DEFAULTFLAG =  C.DEFAULTFLAG OR (I.DEFAULTFLAG is null and C.DEFAULTFLAG is null))
and ( I.PREVENTNATPHASE =  C.PREVENTNATPHASE OR (I.PREVENTNATPHASE is null and C.PREVENTNATPHASE is null))
and ( I.FULLMEMBERDATE =  C.FULLMEMBERDATE OR (I.FULLMEMBERDATE is null and C.FULLMEMBERDATE is  null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYGROUP]') and xtype='U')
begin
	drop table CCImport_COUNTRYGROUP 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCOUNTRYGROUP  to public
go
