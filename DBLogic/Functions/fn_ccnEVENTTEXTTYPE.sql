-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEVENTTEXTTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEVENTTEXTTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEVENTTEXTTYPE.'
	drop function dbo.fn_ccnEVENTTEXTTYPE
	print '**** Creating function dbo.fn_ccnEVENTTEXTTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTTEXTTYPE]') and xtype='U')
begin
	select * 
	into CCImport_EVENTTEXTTYPE 
	from EVENTTEXTTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnEVENTTEXTTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEVENTTEXTTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTTEXTTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 06 Dec 2019	MF	DR-28833 1	Function created
--
As 
Return
select	2 as TRIPNO, 'EVENTTEXTTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EVENTTEXTTYPE I 
	right join EVENTTEXTTYPE C on (C.EVENTTEXTTYPEID=I.EVENTTEXTTYPEID)
where I.EVENTTEXTTYPEID is null
UNION ALL 
select	2, 'EVENTTEXTTYPE', 0, count(*), 0, 0
from CCImport_EVENTTEXTTYPE I 
	left join EVENTTEXTTYPE C  on (C.EVENTTEXTTYPEID=I.EVENTTEXTTYPEID )
where C.EVENTTEXTTYPEID is null
UNION ALL 
 select	2, 'EVENTTEXTTYPE', 0, 0, count(*), 0
from CCImport_EVENTTEXTTYPE I 
	join EVENTTEXTTYPE C on (C.EVENTTEXTTYPEID=I.EVENTTEXTTYPEID )
where 	 isnull(I.DESCRIPTION   ,'')<>isnull(C.DESCRIPTION   ,'')
OR 	 isnull(I.ISEXTERNAL    ,'')<>isnull(C.ISEXTERNAL    ,'')
OR 	 isnull(I.SHARINGALLOWED,'')<>isnull(C.SHARINGALLOWED,'')
UNION ALL 
 select	2, 'EVENTTEXTTYPE', 0, 0, 0, count(*)
from CCImport_EVENTTEXTTYPE I 
	join EVENTTEXTTYPE C on (C.EVENTTEXTTYPEID=I.EVENTTEXTTYPEID )
where 	 isnull(I.DESCRIPTION   ,'')=isnull(C.DESCRIPTION   ,'')
AND 	 isnull(I.ISEXTERNAL    ,'')=isnull(C.ISEXTERNAL    ,'')
AND 	 isnull(I.SHARINGALLOWED,'')=isnull(C.SHARINGALLOWED,'')

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTTEXTTYPE]') and xtype='U')
begin
	drop table CCImport_EVENTTEXTTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEVENTTEXTTYPE  to public
go
