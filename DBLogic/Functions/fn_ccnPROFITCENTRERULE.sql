-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPROFITCENTRERULE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPROFITCENTRERULE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPROFITCENTRERULE.'
	drop function dbo.fn_ccnPROFITCENTRERULE
	print '**** Creating function dbo.fn_ccnPROFITCENTRERULE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFITCENTRERULE]') and xtype='U')
begin
	select * 
	into CCImport_PROFITCENTRERULE 
	from PROFITCENTRERULE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPROFITCENTRERULE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPROFITCENTRERULE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFITCENTRERULE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'PROFITCENTRERULE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PROFITCENTRERULE I 
	right join PROFITCENTRERULE C on( C.ANALYSISCODE=I.ANALYSISCODE
and  C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where I.ANALYSISCODE is null
UNION ALL 
select	8, 'PROFITCENTRERULE', 0, count(*), 0, 0
from CCImport_PROFITCENTRERULE I 
	left join PROFITCENTRERULE C on( C.ANALYSISCODE=I.ANALYSISCODE
and  C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where C.ANALYSISCODE is null
UNION ALL 
 select	8, 'PROFITCENTRERULE', 0, 0, 0, count(*)
from CCImport_PROFITCENTRERULE I 
join PROFITCENTRERULE C	on( C.ANALYSISCODE=I.ANALYSISCODE
and C.PROFITCENTRECODE=I.PROFITCENTRECODE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFITCENTRERULE]') and xtype='U')
begin
	drop table CCImport_PROFITCENTRERULE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPROFITCENTRERULE  to public
go
