-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPAYMENTMETHODS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPAYMENTMETHODS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPAYMENTMETHODS.'
	drop function dbo.fn_ccnPAYMENTMETHODS
	print '**** Creating function dbo.fn_ccnPAYMENTMETHODS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PAYMENTMETHODS]') and xtype='U')
begin
	select * 
	into CCImport_PAYMENTMETHODS 
	from PAYMENTMETHODS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPAYMENTMETHODS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPAYMENTMETHODS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PAYMENTMETHODS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'PAYMENTMETHODS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PAYMENTMETHODS I 
	right join PAYMENTMETHODS C on( C.PAYMENTMETHOD=I.PAYMENTMETHOD)
where I.PAYMENTMETHOD is null
UNION ALL 
select	8, 'PAYMENTMETHODS', 0, count(*), 0, 0
from CCImport_PAYMENTMETHODS I 
	left join PAYMENTMETHODS C on( C.PAYMENTMETHOD=I.PAYMENTMETHOD)
where C.PAYMENTMETHOD is null
UNION ALL 
 select	8, 'PAYMENTMETHODS', 0, 0, count(*), 0
from CCImport_PAYMENTMETHODS I 
	join PAYMENTMETHODS C	on ( C.PAYMENTMETHOD=I.PAYMENTMETHOD)
where 	( I.PAYMENTDESCRIPTION <>  C.PAYMENTDESCRIPTION)
	OR 	( I.PRESENTPHYSICALLY <>  C.PRESENTPHYSICALLY)
	OR 	( I.USEDBY <>  C.USEDBY OR (I.USEDBY is null and C.USEDBY is not null) 
OR (I.USEDBY is not null and C.USEDBY is null))
UNION ALL 
 select	8, 'PAYMENTMETHODS', 0, 0, 0, count(*)
from CCImport_PAYMENTMETHODS I 
join PAYMENTMETHODS C	on( C.PAYMENTMETHOD=I.PAYMENTMETHOD)
where ( I.PAYMENTDESCRIPTION =  C.PAYMENTDESCRIPTION)
and ( I.PRESENTPHYSICALLY =  C.PRESENTPHYSICALLY)
and ( I.USEDBY =  C.USEDBY OR (I.USEDBY is null and C.USEDBY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PAYMENTMETHODS]') and xtype='U')
begin
	drop table CCImport_PAYMENTMETHODS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPAYMENTMETHODS  to public
go
