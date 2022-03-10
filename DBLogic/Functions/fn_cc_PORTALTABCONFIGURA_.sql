-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PORTALTABCONFIGURA_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PORTALTABCONFIGURA_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PORTALTABCONFIGURA_.'
	drop function dbo.fn_cc_PORTALTABCONFIGURA_
	print '**** Creating function dbo.fn_cc_PORTALTABCONFIGURA_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALTABCONFIGURATION]') and xtype='U')
begin
	select * 
	into CCImport_PORTALTABCONFIGURATION 
	from PORTALTABCONFIGURATION
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PORTALTABCONFIGURA_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PORTALTABCONFIGURA_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PORTALTABCONFIGURATION table
-- CALLED BY :	ip_CopyConfigPORTALTABCONFIGURA_
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
	 null as 'Imported Identityid',
	 null as 'Imported Tabid',
	 null as 'Imported Tabsequence',
	 null as 'Imported Portalid',
'D' as '-',
	 C.IDENTITYID as 'Identityid',
	 C.TABID as 'Tabid',
	 C.TABSEQUENCE as 'Tabsequence',
	 C.PORTALID as 'Portalid'
from CCImport_PORTALTABCONFIGURATION I 
	right join PORTALTABCONFIGURATION C on( C.CONFIGURATIONID=I.CONFIGURATIONID)
where I.CONFIGURATIONID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.IDENTITYID,
	 I.TABID,
	 I.TABSEQUENCE,
	 I.PORTALID,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_PORTALTABCONFIGURATION I 
	left join PORTALTABCONFIGURATION C on( C.CONFIGURATIONID=I.CONFIGURATIONID)
where C.CONFIGURATIONID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.IDENTITYID,
	 I.TABID,
	 I.TABSEQUENCE,
	 I.PORTALID,
'U',
	 C.IDENTITYID,
	 C.TABID,
	 C.TABSEQUENCE,
	 C.PORTALID
from CCImport_PORTALTABCONFIGURATION I 
	join PORTALTABCONFIGURATION C	on ( C.CONFIGURATIONID=I.CONFIGURATIONID)
where 	( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null) 
OR (I.IDENTITYID is not null and C.IDENTITYID is null))
	OR 	( I.TABID <>  C.TABID)
	OR 	( I.TABSEQUENCE <>  C.TABSEQUENCE)
	OR 	( I.PORTALID <>  C.PORTALID OR (I.PORTALID is null and C.PORTALID is not null) 
OR (I.PORTALID is not null and C.PORTALID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PORTALTABCONFIGURATION]') and xtype='U')
begin
	drop table CCImport_PORTALTABCONFIGURATION 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PORTALTABCONFIGURA_  to public
go
