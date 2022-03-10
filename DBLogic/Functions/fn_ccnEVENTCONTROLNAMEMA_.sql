-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEVENTCONTROLNAMEMA_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEVENTCONTROLNAMEMA_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEVENTCONTROLNAMEMA_.'
	drop function dbo.fn_ccnEVENTCONTROLNAMEMA_
	print '**** Creating function dbo.fn_ccnEVENTCONTROLNAMEMA_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCONTROLNAMEMAP]') and xtype='U')
begin
	select * 
	into CCImport_EVENTCONTROLNAMEMAP 
	from EVENTCONTROLNAMEMAP
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEVENTCONTROLNAMEMA_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEVENTCONTROLNAMEMA_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTCONTROLNAMEMAP table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'EVENTCONTROLNAMEMAP' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EVENTCONTROLNAMEMAP I 
	right join EVENTCONTROLNAMEMAP C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCENO=I.SEQUENCENO)
where I.CRITERIANO is null
UNION ALL 
select	5, 'EVENTCONTROLNAMEMAP', 0, count(*), 0, 0
from CCImport_EVENTCONTROLNAMEMAP I 
	left join EVENTCONTROLNAMEMAP C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCENO=I.SEQUENCENO)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'EVENTCONTROLNAMEMAP', 0, 0, count(*), 0
from CCImport_EVENTCONTROLNAMEMAP I 
	join EVENTCONTROLNAMEMAP C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.APPLICABLENAMETYPE <>  C.APPLICABLENAMETYPE)
	OR 	( I.SUBSTITUTENAMETYPE <>  C.SUBSTITUTENAMETYPE)
	OR 	( I.MUSTEXIST <>  C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is not null) 
OR (I.MUSTEXIST is not null and C.MUSTEXIST is null))
	OR 	( I.INHERITED <>  C.INHERITED)
UNION ALL 
 select	5, 'EVENTCONTROLNAMEMAP', 0, 0, 0, count(*)
from CCImport_EVENTCONTROLNAMEMAP I 
join EVENTCONTROLNAMEMAP C	on( C.CRITERIANO=I.CRITERIANO
and C.EVENTNO=I.EVENTNO
and C.SEQUENCENO=I.SEQUENCENO)
where ( I.APPLICABLENAMETYPE =  C.APPLICABLENAMETYPE)
and ( I.SUBSTITUTENAMETYPE =  C.SUBSTITUTENAMETYPE)
and ( I.MUSTEXIST =  C.MUSTEXIST OR (I.MUSTEXIST is null and C.MUSTEXIST is null))
and ( I.INHERITED =  C.INHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTCONTROLNAMEMAP]') and xtype='U')
begin
	drop table CCImport_EVENTCONTROLNAMEMAP 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEVENTCONTROLNAMEMA_  to public
go

