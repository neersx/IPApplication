-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PAYMENTMETHODS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PAYMENTMETHODS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PAYMENTMETHODS.'
	drop function dbo.fn_cc_PAYMENTMETHODS
	print '**** Creating function dbo.fn_cc_PAYMENTMETHODS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PAYMENTMETHODS]') and xtype='U')
begin
	select * 
	into CCImport_PAYMENTMETHODS 
	from PAYMENTMETHODS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PAYMENTMETHODS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PAYMENTMETHODS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PAYMENTMETHODS table
-- CALLED BY :	ip_CopyConfigPAYMENTMETHODS
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
	 null as 'Imported Paymentmethod',
	 null as 'Imported Paymentdescription',
	 null as 'Imported Presentphysically',
	 null as 'Imported Usedby',
'D' as '-',
	 C.PAYMENTMETHOD as 'Paymentmethod',
	 C.PAYMENTDESCRIPTION as 'Paymentdescription',
	 C.PRESENTPHYSICALLY as 'Presentphysically',
	 C.USEDBY as 'Usedby'
from CCImport_PAYMENTMETHODS I 
	right join PAYMENTMETHODS C on( C.PAYMENTMETHOD=I.PAYMENTMETHOD)
where I.PAYMENTMETHOD is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PAYMENTMETHOD,
	 I.PAYMENTDESCRIPTION,
	 I.PRESENTPHYSICALLY,
	 I.USEDBY,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_PAYMENTMETHODS I 
	left join PAYMENTMETHODS C on( C.PAYMENTMETHOD=I.PAYMENTMETHOD)
where C.PAYMENTMETHOD is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.PAYMENTMETHOD,
	 I.PAYMENTDESCRIPTION,
	 I.PRESENTPHYSICALLY,
	 I.USEDBY,
'U',
	 C.PAYMENTMETHOD,
	 C.PAYMENTDESCRIPTION,
	 C.PRESENTPHYSICALLY,
	 C.USEDBY
from CCImport_PAYMENTMETHODS I 
	join PAYMENTMETHODS C	on ( C.PAYMENTMETHOD=I.PAYMENTMETHOD)
where 	( I.PAYMENTDESCRIPTION <>  C.PAYMENTDESCRIPTION)
	OR 	( I.PRESENTPHYSICALLY <>  C.PRESENTPHYSICALLY)
	OR 	( I.USEDBY <>  C.USEDBY OR (I.USEDBY is null and C.USEDBY is not null) 
OR (I.USEDBY is not null and C.USEDBY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PAYMENTMETHODS]') and xtype='U')
begin
	drop table CCImport_PAYMENTMETHODS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PAYMENTMETHODS  to public
go
