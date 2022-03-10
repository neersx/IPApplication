-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FILELOCATIONOFFICE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FILELOCATIONOFFICE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FILELOCATIONOFFICE.'
	drop function dbo.fn_cc_FILELOCATIONOFFICE
	print '**** Creating function dbo.fn_cc_FILELOCATIONOFFICE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_FILELOCATIONOFFICE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FILELOCATIONOFFICE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FILELOCATIONOFFICE table
-- CALLED BY :	ip_CopyConfigFILELOCATIONOFFICE
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Filelocationid',
	 null as 'Imported Officeid',
'D' as '-',
	 C.FILELOCATIONID as 'Filelocationid',
	 C.OFFICEID as 'Officeid'
from CCImport_FILELOCATIONOFFICE I 
	right join FILELOCATIONOFFICE C on( C.FILELOCATIONID=I.FILELOCATIONID
and  C.OFFICEID=I.OFFICEID)
where I.FILELOCATIONID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.FILELOCATIONID,
	 I.OFFICEID,
'I',
	 null ,
	 null
from CCImport_FILELOCATIONOFFICE I 
	left join FILELOCATIONOFFICE C on( C.FILELOCATIONID=I.FILELOCATIONID
and  C.OFFICEID=I.OFFICEID)
where C.FILELOCATIONID is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FILELOCATIONOFFICE]') and xtype='U')
begin
	drop table CCImport_FILELOCATIONOFFICE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FILELOCATIONOFFICE  to public
go
