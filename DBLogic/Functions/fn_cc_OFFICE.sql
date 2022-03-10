-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_OFFICE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_OFFICE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_OFFICE.'
	drop function dbo.fn_cc_OFFICE
	print '**** Creating function dbo.fn_cc_OFFICE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_OFFICE]') and xtype='U')
begin
	select * 
	into CCImport_OFFICE 
	from OFFICE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_OFFICE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_OFFICE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the OFFICE table
-- CALLED BY :	ip_CopyConfigOFFICE
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
	 null as 'Imported Officeid',
	 null as 'Imported Description',
	 null as 'Imported Usercode',
	 null as 'Imported Countrycode',
	 null as 'Imported Languagecode',
	 null as 'Imported Cpacode',
	 null as 'Imported Resourceno',
	 null as 'Imported Itemnoprefix',
	 null as 'Imported Itemnofrom',
	 null as 'Imported Itemnoto',
	 null as 'Imported Lastitemno',
	 null as 'Imported Region',
	 null as 'Imported Orgnameno',
	 null as 'Imported Irncode',
'D' as '-',
	 C.OFFICEID as 'Officeid',
	 C.DESCRIPTION as 'Description',
	 C.USERCODE as 'Usercode',
	 C.COUNTRYCODE as 'Countrycode',
	 C.LANGUAGECODE as 'Languagecode',
	 C.CPACODE as 'Cpacode',
	 C.RESOURCENO as 'Resourceno',
	 C.ITEMNOPREFIX as 'Itemnoprefix',
	 C.ITEMNOFROM as 'Itemnofrom',
	 C.ITEMNOTO as 'Itemnoto',
	 C.LASTITEMNO as 'Lastitemno',
	 C.REGION as 'Region',
	 C.ORGNAMENO as 'Orgnameno',
	 C.IRNCODE as 'Irncode'
from CCImport_OFFICE I 
	right join OFFICE C on( C.OFFICEID=I.OFFICEID)
where I.OFFICEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.OFFICEID,
	 I.DESCRIPTION,
	 I.USERCODE,
	 I.COUNTRYCODE,
	 I.LANGUAGECODE,
	 I.CPACODE,
	 I.RESOURCENO,
	 I.ITEMNOPREFIX,
	 I.ITEMNOFROM,
	 I.ITEMNOTO,
	 I.LASTITEMNO,
	 I.REGION,
	 I.ORGNAMENO,
	 I.IRNCODE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_OFFICE I 
	left join OFFICE C on( C.OFFICEID=I.OFFICEID)
where C.OFFICEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.OFFICEID,
	 I.DESCRIPTION,
	 I.USERCODE,
	 I.COUNTRYCODE,
	 I.LANGUAGECODE,
	 I.CPACODE,
	 I.RESOURCENO,
	 I.ITEMNOPREFIX,
	 I.ITEMNOFROM,
	 I.ITEMNOTO,
	 I.LASTITEMNO,
	 I.REGION,
	 I.ORGNAMENO,
	 I.IRNCODE,
'U',
	 C.OFFICEID,
	 C.DESCRIPTION,
	 C.USERCODE,
	 C.COUNTRYCODE,
	 C.LANGUAGECODE,
	 C.CPACODE,
	 C.RESOURCENO,
	 C.ITEMNOPREFIX,
	 C.ITEMNOFROM,
	 C.ITEMNOTO,
	 C.LASTITEMNO,
	 C.REGION,
	 C.ORGNAMENO,
	 C.IRNCODE
from CCImport_OFFICE I 
	join OFFICE C	on ( C.OFFICEID=I.OFFICEID)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.USERCODE <>  C.USERCODE OR (I.USERCODE is null and C.USERCODE is not null) 
OR (I.USERCODE is not null and C.USERCODE is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.LANGUAGECODE <>  C.LANGUAGECODE OR (I.LANGUAGECODE is null and C.LANGUAGECODE is not null) 
OR (I.LANGUAGECODE is not null and C.LANGUAGECODE is null))
	OR 	( I.CPACODE <>  C.CPACODE OR (I.CPACODE is null and C.CPACODE is not null) 
OR (I.CPACODE is not null and C.CPACODE is null))
	OR 	( I.RESOURCENO <>  C.RESOURCENO OR (I.RESOURCENO is null and C.RESOURCENO is not null) 
OR (I.RESOURCENO is not null and C.RESOURCENO is null))
	OR 	( I.ITEMNOPREFIX <>  C.ITEMNOPREFIX OR (I.ITEMNOPREFIX is null and C.ITEMNOPREFIX is not null) 
OR (I.ITEMNOPREFIX is not null and C.ITEMNOPREFIX is null))
	OR 	( I.ITEMNOFROM <>  C.ITEMNOFROM OR (I.ITEMNOFROM is null and C.ITEMNOFROM is not null) 
OR (I.ITEMNOFROM is not null and C.ITEMNOFROM is null))
	OR 	( I.ITEMNOTO <>  C.ITEMNOTO OR (I.ITEMNOTO is null and C.ITEMNOTO is not null) 
OR (I.ITEMNOTO is not null and C.ITEMNOTO is null))
	OR 	( I.LASTITEMNO <>  C.LASTITEMNO OR (I.LASTITEMNO is null and C.LASTITEMNO is not null) 
OR (I.LASTITEMNO is not null and C.LASTITEMNO is null))
	OR 	( I.REGION <>  C.REGION OR (I.REGION is null and C.REGION is not null) 
OR (I.REGION is not null and C.REGION is null))
	OR 	( I.ORGNAMENO <>  C.ORGNAMENO OR (I.ORGNAMENO is null and C.ORGNAMENO is not null) 
OR (I.ORGNAMENO is not null and C.ORGNAMENO is null))
	OR 	( I.IRNCODE <>  C.IRNCODE OR (I.IRNCODE is null and C.IRNCODE is not null) 
OR (I.IRNCODE is not null and C.IRNCODE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_OFFICE]') and xtype='U')
begin
	drop table CCImport_OFFICE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_OFFICE  to public
go
