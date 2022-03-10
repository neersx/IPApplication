-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FEETYPES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FEETYPES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FEETYPES.'
	drop function dbo.fn_cc_FEETYPES
	print '**** Creating function dbo.fn_cc_FEETYPES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEETYPES]') and xtype='U')
begin
	select * 
	into CCImport_FEETYPES 
	from FEETYPES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_FEETYPES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FEETYPES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEETYPES table
-- CALLED BY :	ip_CopyConfigFEETYPES
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
	 null as 'Imported Feetype',
	 null as 'Imported Feename',
	 null as 'Imported Reportformat',
	 null as 'Imported Rateno',
	 null as 'Imported Wipcode',
	 null as 'Imported Accountowner',
	 null as 'Imported Banknameno',
	 null as 'Imported Accountsequenceno',
'D' as '-',
	 C.FEETYPE as 'Feetype',
	 C.FEENAME as 'Feename',
	 C.REPORTFORMAT as 'Reportformat',
	 C.RATENO as 'Rateno',
	 C.WIPCODE as 'Wipcode',
	 C.ACCOUNTOWNER as 'Accountowner',
	 C.BANKNAMENO as 'Banknameno',
	 C.ACCOUNTSEQUENCENO as 'Accountsequenceno'
from CCImport_FEETYPES I 
	right join FEETYPES C on( C.FEETYPE=I.FEETYPE)
where I.FEETYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.FEETYPE,
	 I.FEENAME,
	 I.REPORTFORMAT,
	 I.RATENO,
	 I.WIPCODE,
	 I.ACCOUNTOWNER,
	 I.BANKNAMENO,
	 I.ACCOUNTSEQUENCENO,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_FEETYPES I 
	left join FEETYPES C on( C.FEETYPE=I.FEETYPE)
where C.FEETYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.FEETYPE,
	 I.FEENAME,
	 I.REPORTFORMAT,
	 I.RATENO,
	 I.WIPCODE,
	 I.ACCOUNTOWNER,
	 I.BANKNAMENO,
	 I.ACCOUNTSEQUENCENO,
'U',
	 C.FEETYPE,
	 C.FEENAME,
	 C.REPORTFORMAT,
	 C.RATENO,
	 C.WIPCODE,
	 C.ACCOUNTOWNER,
	 C.BANKNAMENO,
	 C.ACCOUNTSEQUENCENO
from CCImport_FEETYPES I 
	join FEETYPES C	on ( C.FEETYPE=I.FEETYPE)
where 	( I.FEENAME <>  C.FEENAME OR (I.FEENAME is null and C.FEENAME is not null) 
OR (I.FEENAME is not null and C.FEENAME is null))
	OR 	( I.REPORTFORMAT <>  C.REPORTFORMAT OR (I.REPORTFORMAT is null and C.REPORTFORMAT is not null) 
OR (I.REPORTFORMAT is not null and C.REPORTFORMAT is null))
	OR 	( I.RATENO <>  C.RATENO OR (I.RATENO is null and C.RATENO is not null) 
OR (I.RATENO is not null and C.RATENO is null))
	OR 	( I.WIPCODE <>  C.WIPCODE OR (I.WIPCODE is null and C.WIPCODE is not null) 
OR (I.WIPCODE is not null and C.WIPCODE is null))
	OR 	( I.ACCOUNTOWNER <>  C.ACCOUNTOWNER OR (I.ACCOUNTOWNER is null and C.ACCOUNTOWNER is not null) 
OR (I.ACCOUNTOWNER is not null and C.ACCOUNTOWNER is null))
	OR 	( I.BANKNAMENO <>  C.BANKNAMENO OR (I.BANKNAMENO is null and C.BANKNAMENO is not null) 
OR (I.BANKNAMENO is not null and C.BANKNAMENO is null))
	OR 	( I.ACCOUNTSEQUENCENO <>  C.ACCOUNTSEQUENCENO OR (I.ACCOUNTSEQUENCENO is null and C.ACCOUNTSEQUENCENO is not null) 
OR (I.ACCOUNTSEQUENCENO is not null and C.ACCOUNTSEQUENCENO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEETYPES]') and xtype='U')
begin
	drop table CCImport_FEETYPES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FEETYPES  to public
go
