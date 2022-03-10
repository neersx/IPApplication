-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FEESCALCALT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FEESCALCALT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FEESCALCALT.'
	drop function dbo.fn_cc_FEESCALCALT
	print '**** Creating function dbo.fn_cc_FEESCALCALT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEESCALCALT]') and xtype='U')
begin
	select * 
	into CCImport_FEESCALCALT 
	from FEESCALCALT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_FEESCALCALT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FEESCALCALT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEESCALCALT table
-- CALLED BY :	ip_CopyConfigFEESCALCALT
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
	 null as 'Imported Criteriano',
	 null as 'Imported Uniqueid',
	 null as 'Imported Componenttype',
	 null as 'Imported Supplementno',
	 null as 'Imported Procedurename',
	 null as 'Imported Description',
	 null as 'Imported Countrycode',
	 null as 'Imported Suppnumericvalue',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.UNIQUEID as 'Uniqueid',
	 C.COMPONENTTYPE as 'Componenttype',
	 C.SUPPLEMENTNO as 'Supplementno',
	 C.PROCEDURENAME as 'Procedurename',
	 C.DESCRIPTION as 'Description',
	 C.COUNTRYCODE as 'Countrycode',
	 C.SUPPNUMERICVALUE as 'Suppnumericvalue'
from CCImport_FEESCALCALT I 
	right join FEESCALCALT C on( C.CRITERIANO=I.CRITERIANO
and  C.UNIQUEID=I.UNIQUEID
and  C.COMPONENTTYPE=I.COMPONENTTYPE
and  C.SUPPLEMENTNO=I.SUPPLEMENTNO
and  C.PROCEDURENAME=I.PROCEDURENAME)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.UNIQUEID,
	 I.COMPONENTTYPE,
	 I.SUPPLEMENTNO,
	 I.PROCEDURENAME,
	 I.DESCRIPTION,
	 I.COUNTRYCODE,
	 I.SUPPNUMERICVALUE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_FEESCALCALT I 
	left join FEESCALCALT C on( C.CRITERIANO=I.CRITERIANO
and  C.UNIQUEID=I.UNIQUEID
and  C.COMPONENTTYPE=I.COMPONENTTYPE
and  C.SUPPLEMENTNO=I.SUPPLEMENTNO
and  C.PROCEDURENAME=I.PROCEDURENAME)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.UNIQUEID,
	 I.COMPONENTTYPE,
	 I.SUPPLEMENTNO,
	 I.PROCEDURENAME,
	 I.DESCRIPTION,
	 I.COUNTRYCODE,
	 I.SUPPNUMERICVALUE,
'U',
	 C.CRITERIANO,
	 C.UNIQUEID,
	 C.COMPONENTTYPE,
	 C.SUPPLEMENTNO,
	 C.PROCEDURENAME,
	 C.DESCRIPTION,
	 C.COUNTRYCODE,
	 C.SUPPNUMERICVALUE
from CCImport_FEESCALCALT I 
	join FEESCALCALT C	on ( C.CRITERIANO=I.CRITERIANO
	and C.UNIQUEID=I.UNIQUEID
	and C.COMPONENTTYPE=I.COMPONENTTYPE
	and C.SUPPLEMENTNO=I.SUPPLEMENTNO
	and C.PROCEDURENAME=I.PROCEDURENAME)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.SUPPNUMERICVALUE <>  C.SUPPNUMERICVALUE OR (I.SUPPNUMERICVALUE is null and C.SUPPNUMERICVALUE is not null) 
OR (I.SUPPNUMERICVALUE is not null and C.SUPPNUMERICVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEESCALCALT]') and xtype='U')
begin
	drop table CCImport_FEESCALCALT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FEESCALCALT  to public
go

