-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCPANARRATIVE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCPANARRATIVE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCPANARRATIVE.'
	drop function dbo.fn_ccnCPANARRATIVE
	print '**** Creating function dbo.fn_ccnCPANARRATIVE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CPANARRATIVE]') and xtype='U')
begin
	select * 
	into CCImport_CPANARRATIVE 
	from CPANARRATIVE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCPANARRATIVE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCPANARRATIVE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CPANARRATIVE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	7 as TRIPNO, 'CPANARRATIVE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CPANARRATIVE I 
	right join CPANARRATIVE C on( C.CPANARRATIVE=I.CPANARRATIVE)
where I.CPANARRATIVE is null
UNION ALL 
select	7, 'CPANARRATIVE', 0, count(*), 0, 0
from CCImport_CPANARRATIVE I 
	left join CPANARRATIVE C on( C.CPANARRATIVE=I.CPANARRATIVE)
where C.CPANARRATIVE is null
UNION ALL 
 select	7, 'CPANARRATIVE', 0, 0, count(*), 0
from CCImport_CPANARRATIVE I 
	join CPANARRATIVE C	on ( C.CPANARRATIVE=I.CPANARRATIVE)
where 	( I.CASEEVENTNO <>  C.CASEEVENTNO OR (I.CASEEVENTNO is null and C.CASEEVENTNO is not null) 
OR (I.CASEEVENTNO is not null and C.CASEEVENTNO is null))
	OR 	( I.EXCLUDEFLAG <>  C.EXCLUDEFLAG)
	OR 	(replace( I.NARRATIVEDESC,char(10),char(13)+char(10)) <>  C.NARRATIVEDESC OR (I.NARRATIVEDESC is null and C.NARRATIVEDESC is not null) 
OR (I.NARRATIVEDESC is not null and C.NARRATIVEDESC is null))
UNION ALL 
 select	7, 'CPANARRATIVE', 0, 0, 0, count(*)
from CCImport_CPANARRATIVE I 
join CPANARRATIVE C	on( C.CPANARRATIVE=I.CPANARRATIVE)
where ( I.CASEEVENTNO =  C.CASEEVENTNO OR (I.CASEEVENTNO is null and C.CASEEVENTNO is null))
and ( I.EXCLUDEFLAG =  C.EXCLUDEFLAG)
and (replace( I.NARRATIVEDESC,char(10),char(13)+char(10)) =  C.NARRATIVEDESC OR (I.NARRATIVEDESC is null and C.NARRATIVEDESC is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CPANARRATIVE]') and xtype='U')
begin
	drop table CCImport_CPANARRATIVE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCPANARRATIVE  to public
go
