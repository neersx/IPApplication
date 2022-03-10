-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFEETYPES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFEETYPES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFEETYPES.'
	drop function dbo.fn_ccnFEETYPES
	print '**** Creating function dbo.fn_ccnFEETYPES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnFEETYPES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFEETYPES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEETYPES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'FEETYPES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FEETYPES I 
	right join FEETYPES C on( C.FEETYPE=I.FEETYPE)
where I.FEETYPE is null
UNION ALL 
select	8, 'FEETYPES', 0, count(*), 0, 0
from CCImport_FEETYPES I 
	left join FEETYPES C on( C.FEETYPE=I.FEETYPE)
where C.FEETYPE is null
UNION ALL 
 select	8, 'FEETYPES', 0, 0, count(*), 0
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
UNION ALL 
 select	8, 'FEETYPES', 0, 0, 0, count(*)
from CCImport_FEETYPES I 
join FEETYPES C	on( C.FEETYPE=I.FEETYPE)
where ( I.FEENAME =  C.FEENAME OR (I.FEENAME is null and C.FEENAME is null))
and ( I.REPORTFORMAT =  C.REPORTFORMAT OR (I.REPORTFORMAT is null and C.REPORTFORMAT is null))
and ( I.RATENO =  C.RATENO OR (I.RATENO is null and C.RATENO is null))
and ( I.WIPCODE =  C.WIPCODE OR (I.WIPCODE is null and C.WIPCODE is null))
and ( I.ACCOUNTOWNER =  C.ACCOUNTOWNER OR (I.ACCOUNTOWNER is null and C.ACCOUNTOWNER is null))
and ( I.BANKNAMENO =  C.BANKNAMENO OR (I.BANKNAMENO is null and C.BANKNAMENO is null))
and ( I.ACCOUNTSEQUENCENO =  C.ACCOUNTSEQUENCENO OR (I.ACCOUNTSEQUENCENO is null and C.ACCOUNTSEQUENCENO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEETYPES]') and xtype='U')
begin
	drop table CCImport_FEETYPES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFEETYPES  to public
go
