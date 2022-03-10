-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnRECORDALELEMENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnRECORDALELEMENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnRECORDALELEMENT.'
	drop function dbo.fn_ccnRECORDALELEMENT
	print '**** Creating function dbo.fn_ccnRECORDALELEMENT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDALELEMENT]') and xtype='U')
begin
	select * 
	into CCImport_RECORDALELEMENT 
	from RECORDALELEMENT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnRECORDALELEMENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnRECORDALELEMENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RECORDALELEMENT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'RECORDALELEMENT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_RECORDALELEMENT I 
	right join RECORDALELEMENT C on( C.RECORDALELEMENTNO=I.RECORDALELEMENTNO)
where I.RECORDALELEMENTNO is null
UNION ALL 
select	5, 'RECORDALELEMENT', 0, count(*), 0, 0
from CCImport_RECORDALELEMENT I 
	left join RECORDALELEMENT C on( C.RECORDALELEMENTNO=I.RECORDALELEMENTNO)
where C.RECORDALELEMENTNO is null
UNION ALL 
 select	5, 'RECORDALELEMENT', 0, 0, count(*), 0
from CCImport_RECORDALELEMENT I 
	join RECORDALELEMENT C	on ( C.RECORDALELEMENTNO=I.RECORDALELEMENTNO)
where 	( I.RECORDALTYPENO <>  C.RECORDALTYPENO)
	OR 	( I.ELEMENTNO <>  C.ELEMENTNO)
	OR 	( I.ELEMENTLABEL <>  C.ELEMENTLABEL)
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.EDITATTRIBUTE <>  C.EDITATTRIBUTE)
UNION ALL 
 select	5, 'RECORDALELEMENT', 0, 0, 0, count(*)
from CCImport_RECORDALELEMENT I 
join RECORDALELEMENT C	on( C.RECORDALELEMENTNO=I.RECORDALELEMENTNO)
where ( I.RECORDALTYPENO =  C.RECORDALTYPENO)
and ( I.ELEMENTNO =  C.ELEMENTNO)
and ( I.ELEMENTLABEL =  C.ELEMENTLABEL)
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))
and ( I.EDITATTRIBUTE =  C.EDITATTRIBUTE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDALELEMENT]') and xtype='U')
begin
	drop table CCImport_RECORDALELEMENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnRECORDALELEMENT  to public
go
