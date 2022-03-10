-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEDERULEOFFICIALNUM_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEDERULEOFFICIALNUM_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEDERULEOFFICIALNUM_.'
	drop function dbo.fn_ccnEDERULEOFFICIALNUM_
	print '**** Creating function dbo.fn_ccnEDERULEOFFICIALNUM_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULEOFFICIALNUMBER]') and xtype='U')
begin
	select * 
	into CCImport_EDERULEOFFICIALNUMBER 
	from EDERULEOFFICIALNUMBER
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEDERULEOFFICIALNUM_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEDERULEOFFICIALNUM_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULEOFFICIALNUMBER table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'EDERULEOFFICIALNUMBER' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EDERULEOFFICIALNUMBER I 
	right join EDERULEOFFICIALNUMBER C on( C.CRITERIANO=I.CRITERIANO
and  C.NUMBERTYPE=I.NUMBERTYPE)
where I.CRITERIANO is null
UNION ALL 
select	9, 'EDERULEOFFICIALNUMBER', 0, count(*), 0, 0
from CCImport_EDERULEOFFICIALNUMBER I 
	left join EDERULEOFFICIALNUMBER C on( C.CRITERIANO=I.CRITERIANO
and  C.NUMBERTYPE=I.NUMBERTYPE)
where C.CRITERIANO is null
UNION ALL 
 select	9, 'EDERULEOFFICIALNUMBER', 0, 0, count(*), 0
from CCImport_EDERULEOFFICIALNUMBER I 
	join EDERULEOFFICIALNUMBER C	on ( C.CRITERIANO=I.CRITERIANO
	and C.NUMBERTYPE=I.NUMBERTYPE)
where 	( I.OFFICIALNUMBER <>  C.OFFICIALNUMBER OR (I.OFFICIALNUMBER is null and C.OFFICIALNUMBER is not null) 
OR (I.OFFICIALNUMBER is not null and C.OFFICIALNUMBER is null))
UNION ALL 
 select	9, 'EDERULEOFFICIALNUMBER', 0, 0, 0, count(*)
from CCImport_EDERULEOFFICIALNUMBER I 
join EDERULEOFFICIALNUMBER C	on( C.CRITERIANO=I.CRITERIANO
and C.NUMBERTYPE=I.NUMBERTYPE)
where ( I.OFFICIALNUMBER =  C.OFFICIALNUMBER OR (I.OFFICIALNUMBER is null and C.OFFICIALNUMBER is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULEOFFICIALNUMBER]') and xtype='U')
begin
	drop table CCImport_EDERULEOFFICIALNUMBER 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEDERULEOFFICIALNUM_  to public
go
