-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSELECTIONTYPES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSELECTIONTYPES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSELECTIONTYPES.'
	drop function dbo.fn_ccnSELECTIONTYPES
	print '**** Creating function dbo.fn_ccnSELECTIONTYPES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SELECTIONTYPES]') and xtype='U')
begin
	select * 
	into CCImport_SELECTIONTYPES 
	from SELECTIONTYPES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSELECTIONTYPES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSELECTIONTYPES
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the SELECTIONTYPES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 11 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	2 as TRIPNO, 'SELECTIONTYPES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_SELECTIONTYPES I 
	right join SELECTIONTYPES C on( C.PARENTTABLE=I.PARENTTABLE
				    and C.TABLETYPE  =I.TABLETYPE)
where I.PARENTTABLE is null
UNION ALL 
select	2, 'SELECTIONTYPES', 0, count(*), 0, 0
from CCImport_SELECTIONTYPES I 
	left join SELECTIONTYPES C on( C.PARENTTABLE=I.PARENTTABLE
				   and C.TABLETYPE  =I.TABLETYPE)
where C.PARENTTABLE is null
UNION ALL 
 select	2, 'SELECTIONTYPES', 0, 0, count(*), 0
from CCImport_SELECTIONTYPES I 
	join SELECTIONTYPES C	on ( C.PARENTTABLE=I.PARENTTABLE
				and  C.TABLETYPE  =I.TABLETYPE)
where 	( I.MINIMUMALLOWED <>  C.MINIMUMALLOWED OR (I.MINIMUMALLOWED is null and C.MINIMUMALLOWED is not null) 
     OR ( I.MINIMUMALLOWED is not null and C.MINIMUMALLOWED is null))
     OR	( I.MAXIMUMALLOWED <>  C.MAXIMUMALLOWED OR (I.MAXIMUMALLOWED is null and C.MAXIMUMALLOWED is not null) 
     OR ( I.MAXIMUMALLOWED is not null and C.MAXIMUMALLOWED is null))
     OR	( I.MODIFYBYSERVICE <>  C.MODIFYBYSERVICE OR (I.MODIFYBYSERVICE is null and C.MODIFYBYSERVICE is not null )
     OR ( I.MODIFYBYSERVICE is not null and C.MODIFYBYSERVICE is null))
UNION ALL 
 select	2, 'SELECTIONTYPES', 0, 0, 0, count(*)
from CCImport_SELECTIONTYPES I 
join SELECTIONTYPES C	on( C.PARENTTABLE=I.PARENTTABLE
			and C.TABLETYPE  =I.TABLETYPE)
where ( I.MINIMUMALLOWED =  C.MINIMUMALLOWED  OR (I.MINIMUMALLOWED  is null and C.MINIMUMALLOWED  is null))
and   ( I.MAXIMUMALLOWED =  C.MAXIMUMALLOWED  OR (I.MAXIMUMALLOWED  is null and C.MAXIMUMALLOWED  is null))
and   ( I.MODIFYBYSERVICE=  C.MODIFYBYSERVICE OR (I.MODIFYBYSERVICE is null and C.MODIFYBYSERVICE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SELECTIONTYPES]') and xtype='U')
begin
	drop table CCImport_SELECTIONTYPES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSELECTIONTYPES  to public
go

