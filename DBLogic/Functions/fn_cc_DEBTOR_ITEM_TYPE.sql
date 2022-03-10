-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DEBTOR_ITEM_TYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DEBTOR_ITEM_TYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DEBTOR_ITEM_TYPE.'
	drop function dbo.fn_cc_DEBTOR_ITEM_TYPE
	print '**** Creating function dbo.fn_cc_DEBTOR_ITEM_TYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_DEBTOR_ITEM_TYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DEBTOR_ITEM_TYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DEBTOR_ITEM_TYPE table
-- CALLED BY :	ip_CopyConfigDEBTOR_ITEM_TYPE
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
	 null as 'Imported Item_type_id',
	 null as 'Imported Abbreviation',
	 null as 'Imported Description',
	 null as 'Imported Usedbybilling',
	 null as 'Imported Internal',
	 null as 'Imported Takeuponbill',
	 null as 'Imported Cashitemflag',
	 null as 'Imported Eventno',
'D' as '-',
	 C.ITEM_TYPE_ID as 'Item_type_id',
	 C.ABBREVIATION as 'Abbreviation',
	 C.DESCRIPTION as 'Description',
	 C.USEDBYBILLING as 'Usedbybilling',
	 C.INTERNAL as 'Internal',
	 C.TAKEUPONBILL as 'Takeuponbill',
	 C.CASHITEMFLAG as 'Cashitemflag',
	 C.EVENTNO as 'Eventno'
from CCImport_DEBTOR_ITEM_TYPE I 
	right join DEBTOR_ITEM_TYPE C on( C.ITEM_TYPE_ID=I.ITEM_TYPE_ID)
where I.ITEM_TYPE_ID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ITEM_TYPE_ID,
	 I.ABBREVIATION,
	 I.DESCRIPTION,
	 I.USEDBYBILLING,
	 I.INTERNAL,
	 I.TAKEUPONBILL,
	 I.CASHITEMFLAG,
	 I.EVENTNO,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_DEBTOR_ITEM_TYPE I 
	left join DEBTOR_ITEM_TYPE C on( C.ITEM_TYPE_ID=I.ITEM_TYPE_ID)
where C.ITEM_TYPE_ID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ITEM_TYPE_ID,
	 I.ABBREVIATION,
	 I.DESCRIPTION,
	 I.USEDBYBILLING,
	 I.INTERNAL,
	 I.TAKEUPONBILL,
	 I.CASHITEMFLAG,
	 I.EVENTNO,
'U',
	 C.ITEM_TYPE_ID,
	 C.ABBREVIATION,
	 C.DESCRIPTION,
	 C.USEDBYBILLING,
	 C.INTERNAL,
	 C.TAKEUPONBILL,
	 C.CASHITEMFLAG,
	 C.EVENTNO
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DEBTOR_ITEM_TYPE]') and xtype='U')
begin
	drop table CCImport_DEBTOR_ITEM_TYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DEBTOR_ITEM_TYPE  to public
go
