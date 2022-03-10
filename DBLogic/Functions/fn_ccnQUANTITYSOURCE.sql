-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnQUANTITYSOURCE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnQUANTITYSOURCE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnQUANTITYSOURCE.'
	drop function dbo.fn_ccnQUANTITYSOURCE
	print '**** Creating function dbo.fn_ccnQUANTITYSOURCE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_QUANTITYSOURCE]') and xtype='U')
begin
	select * 
	into CCImport_QUANTITYSOURCE 
	from QUANTITYSOURCE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnQUANTITYSOURCE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnQUANTITYSOURCE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the QUANTITYSOURCE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'QUANTITYSOURCE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_QUANTITYSOURCE I 
	right join QUANTITYSOURCE C on( C.QUANTITYSOURCEID=I.QUANTITYSOURCEID)
where I.QUANTITYSOURCEID is null
UNION ALL 
select	2, 'QUANTITYSOURCE', 0, count(*), 0, 0
from CCImport_QUANTITYSOURCE I 
	left join QUANTITYSOURCE C on( C.QUANTITYSOURCEID=I.QUANTITYSOURCEID)
where C.QUANTITYSOURCEID is null
UNION ALL 
 select	2, 'QUANTITYSOURCE', 0, 0, count(*), 0
from CCImport_QUANTITYSOURCE I 
	join QUANTITYSOURCE C	on ( C.QUANTITYSOURCEID=I.QUANTITYSOURCEID)
where 	( I.SOURCE <>  C.SOURCE)
	OR 	( I.FROMEVENTNO <>  C.FROMEVENTNO OR (I.FROMEVENTNO is null and C.FROMEVENTNO is not null) 
OR (I.FROMEVENTNO is not null and C.FROMEVENTNO is null))
	OR 	( I.UNTILEVENTNO <>  C.UNTILEVENTNO OR (I.UNTILEVENTNO is null and C.UNTILEVENTNO is not null) 
OR (I.UNTILEVENTNO is not null and C.UNTILEVENTNO is null))
	OR 	( I.PERIODTYPE <>  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) 
OR (I.PERIODTYPE is not null and C.PERIODTYPE is null))
UNION ALL 
 select	2, 'QUANTITYSOURCE', 0, 0, 0, count(*)
from CCImport_QUANTITYSOURCE I 
join QUANTITYSOURCE C	on( C.QUANTITYSOURCEID=I.QUANTITYSOURCEID)
where ( I.SOURCE =  C.SOURCE)
and ( I.FROMEVENTNO =  C.FROMEVENTNO OR (I.FROMEVENTNO is null and C.FROMEVENTNO is null))
and ( I.UNTILEVENTNO =  C.UNTILEVENTNO OR (I.UNTILEVENTNO is null and C.UNTILEVENTNO is null))
and ( I.PERIODTYPE =  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_QUANTITYSOURCE]') and xtype='U')
begin
	drop table CCImport_QUANTITYSOURCE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnQUANTITYSOURCE  to public
go
