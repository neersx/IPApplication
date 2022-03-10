-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTEXTTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTEXTTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTEXTTYPE.'
	drop function dbo.fn_ccnTEXTTYPE
	print '**** Creating function dbo.fn_ccnTEXTTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TEXTTYPE]') and xtype='U')
begin
	select * 
	into CCImport_TEXTTYPE 
	from TEXTTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTEXTTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTEXTTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TEXTTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'TEXTTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TEXTTYPE I 
	right join TEXTTYPE C on( C.TEXTTYPE=I.TEXTTYPE)
where I.TEXTTYPE is null
UNION ALL 
select	2, 'TEXTTYPE', 0, count(*), 0, 0
from CCImport_TEXTTYPE I 
	left join TEXTTYPE C on( C.TEXTTYPE=I.TEXTTYPE)
where C.TEXTTYPE is null
UNION ALL 
 select	2, 'TEXTTYPE', 0, 0, count(*), 0
from CCImport_TEXTTYPE I 
	join TEXTTYPE C	on ( C.TEXTTYPE=I.TEXTTYPE)
where 	( I.TEXTDESCRIPTION <>  C.TEXTDESCRIPTION OR (I.TEXTDESCRIPTION is null and C.TEXTDESCRIPTION is not null) 
OR (I.TEXTDESCRIPTION is not null and C.TEXTDESCRIPTION is null))
	OR 	( I.USEDBYFLAG <>  C.USEDBYFLAG OR (I.USEDBYFLAG is null and C.USEDBYFLAG is not null) 
OR (I.USEDBYFLAG is not null and C.USEDBYFLAG is null))
UNION ALL 
 select	2, 'TEXTTYPE', 0, 0, 0, count(*)
from CCImport_TEXTTYPE I 
join TEXTTYPE C	on( C.TEXTTYPE=I.TEXTTYPE)
where ( I.TEXTDESCRIPTION =  C.TEXTDESCRIPTION OR (I.TEXTDESCRIPTION is null and C.TEXTDESCRIPTION is null))
and ( I.USEDBYFLAG =  C.USEDBYFLAG OR (I.USEDBYFLAG is null and C.USEDBYFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TEXTTYPE]') and xtype='U')
begin
	drop table CCImport_TEXTTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTEXTTYPE  to public
go