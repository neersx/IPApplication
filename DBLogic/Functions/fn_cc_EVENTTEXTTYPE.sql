-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EVENTTEXTTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EVENTTEXTTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EVENTTEXTTYPE.'
	drop function dbo.fn_cc_EVENTTEXTTYPE
	print '**** Creating function dbo.fn_cc_EVENTTEXTTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTTEXTTYPE]') and xtype='U')
begin
	select * 
	into CCImport_EVENTTEXTTYPE 
	from EVENTTEXTTYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EVENTTEXTTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EVENTTEXTTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EVENTTEXTTYPE table
-- CALLED BY :	ip_CopyConfigEVENTTEXTTYPE
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 06 Dec 2019	MF	DR-28833 1	Function created
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Eventtexttypeid',
	 null as 'Imported Description',
	 null as 'Imported Isexternal',
	 null as 'Imported Sharingallowed',
	'D' as '-',
	 C.EVENTTEXTTYPEID  as 'Eventtexttypeid',
	 C.DESCRIPTION      as 'Description',
	 C.ISEXTERNAL       as 'Isexternal',
	 C.SHARINGALLOWED   as 'Sharingallowed'
from CCImport_EVENTTEXTTYPE I 
	right join EVENTTEXTTYPE C on( C.EVENTTEXTTYPEID=I.EVENTTEXTTYPEID )
where I.EVENTTEXTTYPEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.EVENTTEXTTYPEID,
	 I.DESCRIPTION,
	 I.ISEXTERNAL,
	 I.SHARINGALLOWED,
	'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EVENTTEXTTYPE I 
	left join EVENTTEXTTYPE C	on ( C.EVENTTEXTTYPEID=I.EVENTTEXTTYPEID)
where C.EVENTTEXTTYPEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.EVENTTEXTTYPEID,
	 I.DESCRIPTION,
	 I.ISEXTERNAL,
	 I.SHARINGALLOWED,
	'U',
	 C.EVENTTEXTTYPEID,
	 C.DESCRIPTION,
	 C.ISEXTERNAL,
	 C.SHARINGALLOWED
from CCImport_EVENTTEXTTYPE I 
	join EVENTTEXTTYPE C on ( C.EVENTTEXTTYPEID=I.EVENTTEXTTYPEID)
where 	 isnull(I.DESCRIPTION   ,'')<>isnull(C.DESCRIPTION   ,'')
OR 	 isnull(I.ISEXTERNAL    ,'')<>isnull(C.ISEXTERNAL    ,'')
OR 	 isnull(I.SHARINGALLOWED,'')<>isnull(C.SHARINGALLOWED,'')

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EVENTTEXTTYPE]') and xtype='U')
begin
	drop table CCImport_EVENTTEXTTYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EVENTTEXTTYPE  to public
go
