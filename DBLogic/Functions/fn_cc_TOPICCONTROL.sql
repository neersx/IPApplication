-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TOPICCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TOPICCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TOPICCONTROL.'
	drop function dbo.fn_cc_TOPICCONTROL
	print '**** Creating function dbo.fn_cc_TOPICCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_TOPICCONTROL 
	from TOPICCONTROL
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TOPICCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TOPICCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICCONTROL table
-- CALLED BY :	ip_CopyConfigTOPICCONTROL
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
	 null as 'Imported Windowcontrolno',
	 null as 'Imported Topicname',
	 null as 'Imported Topicsuffix',
	 null as 'Imported Rowposition',
	 null as 'Imported Colposition',
	 null as 'Imported Tabcontrolno',
	 null as 'Imported Topictitle',
	 null as 'Imported Topicshorttitle',
	 null as 'Imported Topicdescription',
	 null as 'Imported Displaydescription',
	 null as 'Imported Screentip',
	 null as 'Imported Ishidden',
	 null as 'Imported Ismandatory',
	 null as 'Imported Isinherited',
	 null as 'Imported Filtername',
	 null as 'Imported Filtervalue',
'D' as '-',
	 C.WINDOWCONTROLNO as 'Windowcontrolno',
	 C.TOPICNAME as 'Topicname',
	 C.TOPICSUFFIX as 'Topicsuffix',
	 C.ROWPOSITION as 'Rowposition',
	 C.COLPOSITION as 'Colposition',
	 C.TABCONTROLNO as 'Tabcontrolno',
	 C.TOPICTITLE as 'Topictitle',
	 C.TOPICSHORTTITLE as 'Topicshorttitle',
	 C.TOPICDESCRIPTION as 'Topicdescription',
	 C.DISPLAYDESCRIPTION as 'Displaydescription',
	 C.SCREENTIP as 'Screentip',
	 C.ISHIDDEN as 'Ishidden',
	 C.ISMANDATORY as 'Ismandatory',
	 C.ISINHERITED as 'Isinherited',
	 C.FILTERNAME as 'Filtername',
	 C.FILTERVALUE as 'Filtervalue'
from CCImport_TOPICCONTROL I 
	right join TOPICCONTROL C on( C.TOPICCONTROLNO=I.TOPICCONTROLNO)
where I.TOPICCONTROLNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.WINDOWCONTROLNO,
	 I.TOPICNAME,
	 I.TOPICSUFFIX,
	 I.ROWPOSITION,
	 I.COLPOSITION,
	 I.TABCONTROLNO,
	 I.TOPICTITLE,
	 I.TOPICSHORTTITLE,
	 I.TOPICDESCRIPTION,
	 I.DISPLAYDESCRIPTION,
	 I.SCREENTIP,
	 I.ISHIDDEN,
	 I.ISMANDATORY,
	 I.ISINHERITED,
	 I.FILTERNAME,
	 I.FILTERVALUE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_TOPICCONTROL I 
	left join TOPICCONTROL C on( C.TOPICCONTROLNO=I.TOPICCONTROLNO)
where C.TOPICCONTROLNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.WINDOWCONTROLNO,
	 I.TOPICNAME,
	 I.TOPICSUFFIX,
	 I.ROWPOSITION,
	 I.COLPOSITION,
	 I.TABCONTROLNO,
	 I.TOPICTITLE,
	 I.TOPICSHORTTITLE,
	 I.TOPICDESCRIPTION,
	 I.DISPLAYDESCRIPTION,
	 I.SCREENTIP,
	 I.ISHIDDEN,
	 I.ISMANDATORY,
	 I.ISINHERITED,
	 I.FILTERNAME,
	 I.FILTERVALUE,
'U',
	 C.WINDOWCONTROLNO,
	 C.TOPICNAME,
	 C.TOPICSUFFIX,
	 C.ROWPOSITION,
	 C.COLPOSITION,
	 C.TABCONTROLNO,
	 C.TOPICTITLE,
	 C.TOPICSHORTTITLE,
	 C.TOPICDESCRIPTION,
	 C.DISPLAYDESCRIPTION,
	 C.SCREENTIP,
	 C.ISHIDDEN,
	 C.ISMANDATORY,
	 C.ISINHERITED,
	 C.FILTERNAME,
	 C.FILTERVALUE
from CCImport_TOPICCONTROL I 
	join TOPICCONTROL C	on ( C.TOPICCONTROLNO=I.TOPICCONTROLNO)
where 	( I.WINDOWCONTROLNO <>  C.WINDOWCONTROLNO)
	OR 	( I.TOPICNAME <>  C.TOPICNAME)
	OR 	( I.TOPICSUFFIX <>  C.TOPICSUFFIX OR (I.TOPICSUFFIX is null and C.TOPICSUFFIX is not null) 
OR (I.TOPICSUFFIX is not null and C.TOPICSUFFIX is null))
	OR 	( I.ROWPOSITION <>  C.ROWPOSITION)
	OR 	( I.COLPOSITION <>  C.COLPOSITION)
	OR 	( I.TABCONTROLNO <>  C.TABCONTROLNO OR (I.TABCONTROLNO is null and C.TABCONTROLNO is not null) 
OR (I.TABCONTROLNO is not null and C.TABCONTROLNO is null))
	OR 	(replace( I.TOPICTITLE,char(10),char(13)+char(10)) <>  C.TOPICTITLE OR (I.TOPICTITLE is null and C.TOPICTITLE is not null) 
OR (I.TOPICTITLE is not null and C.TOPICTITLE is null))
	OR 	(replace( I.TOPICSHORTTITLE,char(10),char(13)+char(10)) <>  C.TOPICSHORTTITLE OR (I.TOPICSHORTTITLE is null and C.TOPICSHORTTITLE is not null) 
OR (I.TOPICSHORTTITLE is not null and C.TOPICSHORTTITLE is null))
	OR 	(replace( I.TOPICDESCRIPTION,char(10),char(13)+char(10)) <>  C.TOPICDESCRIPTION OR (I.TOPICDESCRIPTION is null and C.TOPICDESCRIPTION is not null) 
OR (I.TOPICDESCRIPTION is not null and C.TOPICDESCRIPTION is null))
	OR 	( I.DISPLAYDESCRIPTION <>  C.DISPLAYDESCRIPTION)
	OR 	(replace( I.SCREENTIP,char(10),char(13)+char(10)) <>  C.SCREENTIP OR (I.SCREENTIP is null and C.SCREENTIP is not null) 
OR (I.SCREENTIP is not null and C.SCREENTIP is null))
	OR 	( I.ISHIDDEN <>  C.ISHIDDEN)
	OR 	( I.ISMANDATORY <>  C.ISMANDATORY)
	OR 	( I.ISINHERITED <>  C.ISINHERITED)
	OR 	( I.FILTERNAME <>  C.FILTERNAME OR (I.FILTERNAME is null and C.FILTERNAME is not null) 
OR (I.FILTERNAME is not null and C.FILTERNAME is null))
	OR 	(replace( I.FILTERVALUE,char(10),char(13)+char(10)) <>  C.FILTERVALUE OR (I.FILTERVALUE is null and C.FILTERVALUE is not null) 
OR (I.FILTERVALUE is not null and C.FILTERVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICCONTROL]') and xtype='U')
begin
	drop table CCImport_TOPICCONTROL 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TOPICCONTROL  to public
go
