-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFILELOCATIONOFFICE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFILELOCATIONOFFICE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFILELOCATIONOFFICE.'
	drop function dbo.fn_ccnFILELOCATIONOFFICE
	print '**** Creating function dbo.fn_ccnFILELOCATIONOFFICE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FILELOCATIONOFFICE]') and xtype='U')
begin
	select * 
	into CCImport_FILELOCATIONOFFICE 
	from FILELOCATIONOFFICE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnFILELOCATIONOFFICE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFILELOCATIONOFFICE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FILELOCATIONOFFICE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'FILELOCATIONOFFICE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FILELOCATIONOFFICE I 
	right join FILELOCATIONOFFICE C on( C.FILELOCATIONID=I.FILELOCATIONID
and  C.OFFICEID=I.OFFICEID)
where I.FILELOCATIONID is null
UNION ALL 
select	2, 'FILELOCATIONOFFICE', 0, count(*), 0, 0
from CCImport_FILELOCATIONOFFICE I 
	left join FILELOCATIONOFFICE C on( C.FILELOCATIONID=I.FILELOCATIONID
and  C.OFFICEID=I.OFFICEID)
where C.FILELOCATIONID is null
UNION ALL 
 select	2, 'FILELOCATIONOFFICE', 0, 0, 0, count(*)
from CCImport_FILELOCATIONOFFICE I 
join FILELOCATIONOFFICE C	on( C.FILELOCATIONID=I.FILELOCATIONID
and C.OFFICEID=I.OFFICEID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FILELOCATIONOFFICE]') and xtype='U')
begin
	drop table CCImport_FILELOCATIONOFFICE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFILELOCATIONOFFICE  to public
go
