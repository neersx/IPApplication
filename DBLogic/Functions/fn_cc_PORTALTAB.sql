-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PORTALTAB
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PORTALTAB]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PORTALTAB.'
	drop function dbo.fn_cc_PORTALTAB
	print '**** Creating function dbo.fn_cc_PORTALTAB...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALTAB]') and xtype='U')
begin
	select * 
	into CCImport_PORTALTAB 
	from PORTALTAB
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PORTALTAB
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PORTALTAB
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PORTALTAB table
-- CALLED BY :	ip_CopyConfigPORTALTAB
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
	 null as 'Imported Tabname',
	 null as 'Imported Identityid',
	 null as 'Imported Tabsequence',
	 null as 'Imported Portalid',
	 null as 'Imported Cssclassname',
	 null as 'Imported Canrename',
	 null as 'Imported Candelete',
	 null as 'Imported Parenttabid',
'D' as '-',
	 C.TABNAME as 'Tabname',
	 C.IDENTITYID as 'Identityid',
	 C.TABSEQUENCE as 'Tabsequence',
	 C.PORTALID as 'Portalid',
	 C.CSSCLASSNAME as 'Cssclassname',
	 C.CANRENAME as 'Canrename',
	 C.CANDELETE as 'Candelete',
	 C.PARENTTABID as 'Parenttabid'
from CCImport_PORTALTAB I 
	right join PORTALTAB C on( C.TABID=I.TABID)
where I.TABID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TABNAME,
	 I.IDENTITYID,
	 I.TABSEQUENCE,
	 I.PORTALID,
	 I.CSSCLASSNAME,
	 I.CANRENAME,
	 I.CANDELETE,
	 I.PARENTTABID,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_PORTALTAB I 
	left join PORTALTAB C on( C.TABID=I.TABID)
where C.TABID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TABNAME,
	 I.IDENTITYID,
	 I.TABSEQUENCE,
	 I.PORTALID,
	 I.CSSCLASSNAME,
	 I.CANRENAME,
	 I.CANDELETE,
	 I.PARENTTABID,
'U',
	 C.TABNAME,
	 C.IDENTITYID,
	 C.TABSEQUENCE,
	 C.PORTALID,
	 C.CSSCLASSNAME,
	 C.CANRENAME,
	 C.CANDELETE,
	 C.PARENTTABID
from CCImport_PORTALTAB I 
	join PORTALTAB C	on ( C.TABID=I.TABID)
where 	( I.TABNAME <>  C.TABNAME)
	OR 	( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null) 
OR (I.IDENTITYID is not null and C.IDENTITYID is null))
	OR 	( I.TABSEQUENCE <>  C.TABSEQUENCE)
	OR 	( I.PORTALID <>  C.PORTALID OR (I.PORTALID is null and C.PORTALID is not null) 
OR (I.PORTALID is not null and C.PORTALID is null))
	OR 	( I.CSSCLASSNAME <>  C.CSSCLASSNAME OR (I.CSSCLASSNAME is null and C.CSSCLASSNAME is not null) 
OR (I.CSSCLASSNAME is not null and C.CSSCLASSNAME is null))
	OR 	( I.CANRENAME <>  C.CANRENAME)
	OR 	( I.CANDELETE <>  C.CANDELETE)
	OR 	( I.PARENTTABID <>  C.PARENTTABID OR (I.PARENTTABID is null and C.PARENTTABID is not null) 
OR (I.PARENTTABID is not null and C.PARENTTABID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALTAB]') and xtype='U')
begin
	drop table CCImport_PORTALTAB 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PORTALTAB  to public
go
