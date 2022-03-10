-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TOPICDEFAULTSETTIN_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TOPICDEFAULTSETTIN_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TOPICDEFAULTSETTIN_.'
	drop function dbo.fn_cc_TOPICDEFAULTSETTIN_
	print '**** Creating function dbo.fn_cc_TOPICDEFAULTSETTIN_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICDEFAULTSETTINGS]') and xtype='U')
begin
	select * 
	into CCImport_TOPICDEFAULTSETTINGS 
	from TOPICDEFAULTSETTINGS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TOPICDEFAULTSETTIN_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TOPICDEFAULTSETTIN_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICDEFAULTSETTINGS table
-- CALLED BY :	ip_CopyConfigTOPICDEFAULTSETTIN_
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
	 null as 'Imported Criteriano',
	 null as 'Imported Namecriteriano',
	 null as 'Imported Topicname',
	 null as 'Imported Filtername',
	 null as 'Imported Filtervalue',
	 null as 'Imported Isinherited',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.NAMECRITERIANO as 'Namecriteriano',
	 C.TOPICNAME as 'Topicname',
	 C.FILTERNAME as 'Filtername',
	 C.FILTERVALUE as 'Filtervalue',
	 C.ISINHERITED as 'Isinherited'
from CCImport_TOPICDEFAULTSETTINGS I 
	right join TOPICDEFAULTSETTINGS C on( C.DEFAULTSETTINGNO=I.DEFAULTSETTINGNO)
where I.DEFAULTSETTINGNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.NAMECRITERIANO,
	 I.TOPICNAME,
	 I.FILTERNAME,
	 I.FILTERVALUE,
	 I.ISINHERITED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_TOPICDEFAULTSETTINGS I 
	left join TOPICDEFAULTSETTINGS C on( C.DEFAULTSETTINGNO=I.DEFAULTSETTINGNO)
where C.DEFAULTSETTINGNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.NAMECRITERIANO,
	 I.TOPICNAME,
	 I.FILTERNAME,
	 I.FILTERVALUE,
	 I.ISINHERITED,
'U',
	 C.CRITERIANO,
	 C.NAMECRITERIANO,
	 C.TOPICNAME,
	 C.FILTERNAME,
	 C.FILTERVALUE,
	 C.ISINHERITED
from CCImport_TOPICDEFAULTSETTINGS I 
	join TOPICDEFAULTSETTINGS C	on ( C.DEFAULTSETTINGNO=I.DEFAULTSETTINGNO)
where 	( I.CRITERIANO <>  C.CRITERIANO OR (I.CRITERIANO is null and C.CRITERIANO is not null) 
OR (I.CRITERIANO is not null and C.CRITERIANO is null))
	OR 	( I.NAMECRITERIANO <>  C.NAMECRITERIANO OR (I.NAMECRITERIANO is null and C.NAMECRITERIANO is not null) 
OR (I.NAMECRITERIANO is not null and C.NAMECRITERIANO is null))
	OR 	( I.TOPICNAME <>  C.TOPICNAME)
	OR 	( I.FILTERNAME <>  C.FILTERNAME)
	OR 	(replace( I.FILTERVALUE,char(10),char(13)+char(10)) <>  C.FILTERVALUE)
	OR 	( I.ISINHERITED <>  C.ISINHERITED OR (I.ISINHERITED is null and C.ISINHERITED is not null) 
OR (I.ISINHERITED is not null and C.ISINHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICDEFAULTSETTINGS]') and xtype='U')
begin
	drop table CCImport_TOPICDEFAULTSETTINGS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TOPICDEFAULTSETTIN_  to public
go
