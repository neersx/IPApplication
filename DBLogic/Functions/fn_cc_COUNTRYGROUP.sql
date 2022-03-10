-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_COUNTRYGROUP
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_COUNTRYGROUP]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_COUNTRYGROUP.'
	drop function dbo.fn_cc_COUNTRYGROUP
	print '**** Creating function dbo.fn_cc_COUNTRYGROUP...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_COUNTRYGROUP
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_COUNTRYGROUP
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the COUNTRYGROUP table
-- CALLED BY :	ip_CopyConfigCOUNTRYGROUP
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
	 null as 'Imported Treatycode',
	 null as 'Imported Membercountry',
	 null as 'Imported Datecommenced',
	 null as 'Imported Dateceased',
	 null as 'Imported Associatemember',
	 null as 'Imported Defaultflag',
	 null as 'Imported Preventnatphase',
	 null as 'Imported Fullmemberdate',
	'D' as '-',
	 C.TREATYCODE as 'Treatycode',
	 C.MEMBERCOUNTRY as 'Membercountry',
	 C.DATECOMMENCED as 'Datecommenced',
	 C.DATECEASED as 'Dateceased',
	 C.ASSOCIATEMEMBER as 'Associatemember',
	 C.DEFAULTFLAG as 'Defaultflag',
	 C.PREVENTNATPHASE as 'Preventnatphase',
	 C.FULLMEMBERDATE as 'Fullmemberdate'
from CCImport_COUNTRYGROUP I 
	right join COUNTRYGROUP C on( C.TREATYCODE=I.TREATYCODE
and  C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
where I.TREATYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TREATYCODE,
	 I.MEMBERCOUNTRY,
	 I.DATECOMMENCED,
	 I.DATECEASED,
	 I.ASSOCIATEMEMBER,
	 I.DEFAULTFLAG,
	 I.PREVENTNATPHASE,
	 I.FULLMEMBERDATE,
	'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_COUNTRYGROUP I 
	left join COUNTRYGROUP C on( C.TREATYCODE=I.TREATYCODE
and  C.MEMBERCOUNTRY=I.MEMBERCOUNTRY)
where C.TREATYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TREATYCODE,
	 I.MEMBERCOUNTRY,
	 I.DATECOMMENCED,
	 I.DATECEASED,
	 I.ASSOCIATEMEMBER,
	 I.DEFAULTFLAG,
	 I.PREVENTNATPHASE,
	 I.FULLMEMBERDATE,
	'U',
	 C.TREATYCODE,
	 C.MEMBERCOUNTRY,
	 C.DATECOMMENCED,
	 C.DATECEASED,
	 C.ASSOCIATEMEMBER,
	 C.DEFAULTFLAG,
	 C.PREVENTNATPHASE,
	 C.FULLMEMBERDATE
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
	OR 	( I.FULLMEMBERDATE <>  C.FULLMEMBERDATE OR (I.FULLMEMBERDATE is null and C.FULLMEMBERDATE is not null) 
OR (I.FULLMEMBERDATE is not null and C.FULLMEMBERDATE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYGROUP]') and xtype='U')
begin
	drop table CCImport_COUNTRYGROUP 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_COUNTRYGROUP  to public
go
