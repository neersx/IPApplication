-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCOPYPROFILE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCOPYPROFILE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCOPYPROFILE.'
	drop function dbo.fn_ccnCOPYPROFILE
	print '**** Creating function dbo.fn_ccnCOPYPROFILE...'
	print ''
end
go


SET NOCOUNT ON
go


-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_COPYPROFILE]') and xtype='U')
begin
	select * 
	into CCImport_COPYPROFILE 
	from COPYPROFILE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCOPYPROFILE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCOPYPROFILE
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the COPYPROFILE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 11 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	5 as TRIPNO, 'COPYPROFILE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_COPYPROFILE I 
	right join COPYPROFILE C on( C.PROFILENAME=I.PROFILENAME
and  C.SEQUENCENO=I.SEQUENCENO)
where I.PROFILENAME is null
UNION ALL 
select	5, 'COPYPROFILE', 0, count(*), 0, 0
from CCImport_COPYPROFILE I 
	left join COPYPROFILE C on( C.PROFILENAME=I.PROFILENAME
and  C.SEQUENCENO=I.SEQUENCENO)
where C.PROFILENAME is null
UNION ALL 
 select	5, 'COPYPROFILE', 0, 0, count(*), 0
from CCImport_COPYPROFILE I 
	join COPYPROFILE C	on ( C.PROFILENAME=I.PROFILENAME
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.COPYAREA <>  C.COPYAREA)
	OR 	( I.CHARACTERKEY <>  C.CHARACTERKEY OR (I.CHARACTERKEY is null and C.CHARACTERKEY is not null) 
OR (I.CHARACTERKEY is not null and C.CHARACTERKEY is null))
	OR 	( I.NUMERICKEY <>  C.NUMERICKEY OR (I.NUMERICKEY is null and C.NUMERICKEY is not null) 
OR (I.NUMERICKEY is not null and C.NUMERICKEY is null))
	OR 	(replace( I.REPLACEMENTDATA,char(10),char(13)+char(10)) <>  C.REPLACEMENTDATA OR (I.REPLACEMENTDATA is null and C.REPLACEMENTDATA is not null) 
OR (I.REPLACEMENTDATA is not null and C.REPLACEMENTDATA is null))
	OR 	( I.PROTECTCOPY <>  C.PROTECTCOPY OR (I.PROTECTCOPY is null and C.PROTECTCOPY is not null) 
OR (I.PROTECTCOPY is not null and C.PROTECTCOPY is null))
	OR 	( I.STOPCOPY <>  C.STOPCOPY OR (I.STOPCOPY is null and C.STOPCOPY is not null) 
OR (I.STOPCOPY is not null and C.STOPCOPY is null))
	OR 	( I.CRMONLY <>  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is not null )
 OR (I.CRMONLY is not null and C.CRMONLY is null))
UNION ALL 
 select	5, 'COPYPROFILE', 0, 0, 0, count(*)
from CCImport_COPYPROFILE I 
join COPYPROFILE C	on( C.PROFILENAME=I.PROFILENAME
and C.SEQUENCENO=I.SEQUENCENO)
where ( I.COPYAREA =  C.COPYAREA)
and ( I.CHARACTERKEY =  C.CHARACTERKEY OR (I.CHARACTERKEY is null and C.CHARACTERKEY is null))
and ( I.NUMERICKEY =  C.NUMERICKEY OR (I.NUMERICKEY is null and C.NUMERICKEY is null))
and (replace( I.REPLACEMENTDATA,char(10),char(13)+char(10)) =  C.REPLACEMENTDATA OR (I.REPLACEMENTDATA is null and C.REPLACEMENTDATA is null))
and ( I.PROTECTCOPY =  C.PROTECTCOPY OR (I.PROTECTCOPY is null and C.PROTECTCOPY is null))
and ( I.STOPCOPY =  C.STOPCOPY OR (I.STOPCOPY is null and C.STOPCOPY is null))
and ( I.CRMONLY =  C.CRMONLY OR (I.CRMONLY is null and C.CRMONLY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_COPYPROFILE]') and xtype='U')
begin
	drop table CCImport_COPYPROFILE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCOPYPROFILE  to public
go
