-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDEBTOR_ITEM_TYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDEBTOR_ITEM_TYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDEBTOR_ITEM_TYPE.'
	drop function dbo.fn_ccnDEBTOR_ITEM_TYPE
	print '**** Creating function dbo.fn_ccnDEBTOR_ITEM_TYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DEBTOR_ITEM_TYPE]') and xtype='U')
begin
	select * 
	into CCImport_DEBTOR_ITEM_TYPE 
	from DEBTOR_ITEM_TYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnDEBTOR_ITEM_TYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDEBTOR_ITEM_TYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DEBTOR_ITEM_TYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'DEBTOR_ITEM_TYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DEBTOR_ITEM_TYPE I 
	right join DEBTOR_ITEM_TYPE C on( C.ITEM_TYPE_ID=I.ITEM_TYPE_ID)
where I.ITEM_TYPE_ID is null
UNION ALL 
select	8, 'DEBTOR_ITEM_TYPE', 0, count(*), 0, 0
from CCImport_DEBTOR_ITEM_TYPE I 
	left join DEBTOR_ITEM_TYPE C on( C.ITEM_TYPE_ID=I.ITEM_TYPE_ID)
where C.ITEM_TYPE_ID is null
UNION ALL 
 select	8, 'DEBTOR_ITEM_TYPE', 0, 0, count(*), 0
from CCImport_DEBTOR_ITEM_TYPE I 
	join DEBTOR_ITEM_TYPE C	on ( C.ITEM_TYPE_ID=I.ITEM_TYPE_ID)
where 	( I.ABBREVIATION <>  C.ABBREVIATION)
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.USEDBYBILLING <>  C.USEDBYBILLING OR (I.USEDBYBILLING is null and C.USEDBYBILLING is not null) 
OR (I.USEDBYBILLING is not null and C.USEDBYBILLING is null))
	OR 	( I.INTERNAL <>  C.INTERNAL OR (I.INTERNAL is null and C.INTERNAL is not null) 
OR (I.INTERNAL is not null and C.INTERNAL is null))
	OR 	( I.TAKEUPONBILL <>  C.TAKEUPONBILL OR (I.TAKEUPONBILL is null and C.TAKEUPONBILL is not null) 
OR (I.TAKEUPONBILL is not null and C.TAKEUPONBILL is null))
	OR 	( I.CASHITEMFLAG <>  C.CASHITEMFLAG OR (I.CASHITEMFLAG is null and C.CASHITEMFLAG is not null) 
OR (I.CASHITEMFLAG is not null and C.CASHITEMFLAG is null))
	OR 	( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null) 
OR (I.EVENTNO is not null and C.EVENTNO is null))
UNION ALL 
 select	8, 'DEBTOR_ITEM_TYPE', 0, 0, 0, count(*)
from CCImport_DEBTOR_ITEM_TYPE I 
join DEBTOR_ITEM_TYPE C	on( C.ITEM_TYPE_ID=I.ITEM_TYPE_ID)
where ( I.ABBREVIATION =  C.ABBREVIATION)
and ( I.DESCRIPTION =  C.DESCRIPTION)
and ( I.USEDBYBILLING =  C.USEDBYBILLING OR (I.USEDBYBILLING is null and C.USEDBYBILLING is null))
and ( I.INTERNAL =  C.INTERNAL OR (I.INTERNAL is null and C.INTERNAL is null))
and ( I.TAKEUPONBILL =  C.TAKEUPONBILL OR (I.TAKEUPONBILL is null and C.TAKEUPONBILL is null))
and ( I.CASHITEMFLAG =  C.CASHITEMFLAG OR (I.CASHITEMFLAG is null and C.CASHITEMFLAG is null))
and ( I.EVENTNO =  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DEBTOR_ITEM_TYPE]') and xtype='U')
begin
	drop table CCImport_DEBTOR_ITEM_TYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDEBTOR_ITEM_TYPE  to public
go
