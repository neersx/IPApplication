-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTOPICCONTROLFILTER
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTOPICCONTROLFILTER]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTOPICCONTROLFILTER.'
	drop function dbo.fn_ccnTOPICCONTROLFILTER
	print '**** Creating function dbo.fn_ccnTOPICCONTROLFILTER...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICCONTROLFILTER]') and xtype='U')
begin
	select * 
	into CCImport_TOPICCONTROLFILTER 
	from TOPICCONTROLFILTER
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTOPICCONTROLFILTER
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTOPICCONTROLFILTER
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICCONTROLFILTER table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 02 Oct 2014	MF	32711	1 	Procedure created
--
As 
Return
select	6 as TRIPNO, 'TOPICCONTROLFILTER' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TOPICCONTROLFILTER I 
	right join TOPICCONTROLFILTER C on( C.TOPICCONTROLFILTERNO=I.TOPICCONTROLFILTERNO)
where I.TOPICCONTROLFILTERNO is null
UNION ALL 
select	6, 'TOPICCONTROLFILTER', 0, count(*), 0, 0
from CCImport_TOPICCONTROLFILTER I 
	left join TOPICCONTROLFILTER C on( C.TOPICCONTROLFILTERNO=I.TOPICCONTROLFILTERNO)
where C.TOPICCONTROLFILTERNO is null
UNION ALL 
 select	6, 'TOPICCONTROLFILTER', 0, 0, count(*), 0
from CCImport_TOPICCONTROLFILTER I 
	join TOPICCONTROLFILTER C	on ( C.TOPICCONTROLFILTERNO=I.TOPICCONTROLFILTERNO)
where 	( I.TOPICCONTROLNO <>  C.TOPICCONTROLNO)
OR 	( I.FILTERNAME <>  C.FILTERNAME OR (I.FILTERNAME is null     and C.FILTERNAME is not null) 
					OR (I.FILTERNAME is not null and C.FILTERNAME is null))
OR 	(replace( I.FILTERVALUE,char(10),char(13)+char(10)) <>  C.FILTERVALUE OR (I.FILTERVALUE is null     and C.FILTERVALUE is not null) 
									      OR (I.FILTERVALUE is not null and C.FILTERVALUE is null))
UNION ALL 
 select	6, 'TOPICCONTROLFILTER', 0, 0, 0, count(*)
from CCImport_TOPICCONTROLFILTER I 
join TOPICCONTROLFILTER C	on( C.TOPICCONTROLFILTERNO=I.TOPICCONTROLFILTERNO)
where ( I.TOPICCONTROLNO =  C.TOPICCONTROLNO)
and ( I.FILTERNAME =  C.FILTERNAME OR (I.FILTERNAME is null and C.FILTERNAME is null))
and (replace( I.FILTERVALUE,char(10),char(13)+char(10)) =  C.FILTERVALUE OR (I.FILTERVALUE is null and C.FILTERVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICCONTROLFILTER]') and xtype='U')
begin
	drop table CCImport_TOPICCONTROLFILTER 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTOPICCONTROLFILTER  to public
go

