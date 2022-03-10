-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnREQATTRIBUTES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnREQATTRIBUTES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnREQATTRIBUTES.'
	drop function dbo.fn_ccnREQATTRIBUTES
	print '**** Creating function dbo.fn_ccnREQATTRIBUTES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_REQATTRIBUTES]') and xtype='U')
begin
	select * 
	into CCImport_REQATTRIBUTES 
	from REQATTRIBUTES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnREQATTRIBUTES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnREQATTRIBUTES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the REQATTRIBUTES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'REQATTRIBUTES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_REQATTRIBUTES I 
	right join REQATTRIBUTES C on( C.CRITERIANO=I.CRITERIANO
and  C.TABLETYPE=I.TABLETYPE)
where I.CRITERIANO is null
UNION ALL 
select	5, 'REQATTRIBUTES', 0, count(*), 0, 0
from CCImport_REQATTRIBUTES I 
	left join REQATTRIBUTES C on( C.CRITERIANO=I.CRITERIANO
and  C.TABLETYPE=I.TABLETYPE)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'REQATTRIBUTES', 0, 0, 0, count(*)
from CCImport_REQATTRIBUTES I 
join REQATTRIBUTES C	on( C.CRITERIANO=I.CRITERIANO
and C.TABLETYPE=I.TABLETYPE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_REQATTRIBUTES]') and xtype='U')
begin
	drop table CCImport_REQATTRIBUTES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnREQATTRIBUTES  to public
go
