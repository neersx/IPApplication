-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTOPICCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTOPICCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTOPICCONTROL.'
	drop function dbo.fn_ccnTOPICCONTROL
	print '**** Creating function dbo.fn_ccnTOPICCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_TOPICCONTROL 
	from TOPICCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTOPICCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTOPICCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICCONTROL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'TOPICCONTROL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TOPICCONTROL I 
	right join TOPICCONTROL C on( C.TOPICCONTROLNO=I.TOPICCONTROLNO)
where I.TOPICCONTROLNO is null
UNION ALL 
select	6, 'TOPICCONTROL', 0, count(*), 0, 0
from CCImport_TOPICCONTROL I 
	left join TOPICCONTROL C on( C.TOPICCONTROLNO=I.TOPICCONTROLNO)
where C.TOPICCONTROLNO is null
UNION ALL 
 select	6, 'TOPICCONTROL', 0, 0, count(*), 0
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
UNION ALL 
 select	6, 'TOPICCONTROL', 0, 0, 0, count(*)
from CCImport_TOPICCONTROL I 
join TOPICCONTROL C	on( C.TOPICCONTROLNO=I.TOPICCONTROLNO)
where ( I.WINDOWCONTROLNO =  C.WINDOWCONTROLNO)
and ( I.TOPICNAME =  C.TOPICNAME)
and ( I.TOPICSUFFIX =  C.TOPICSUFFIX OR (I.TOPICSUFFIX is null and C.TOPICSUFFIX is null))
and ( I.ROWPOSITION =  C.ROWPOSITION)
and ( I.COLPOSITION =  C.COLPOSITION)
and ( I.TABCONTROLNO =  C.TABCONTROLNO OR (I.TABCONTROLNO is null and C.TABCONTROLNO is null))
and (replace( I.TOPICTITLE,char(10),char(13)+char(10)) =  C.TOPICTITLE OR (I.TOPICTITLE is null and C.TOPICTITLE is null))
and (replace( I.TOPICSHORTTITLE,char(10),char(13)+char(10)) =  C.TOPICSHORTTITLE OR (I.TOPICSHORTTITLE is null and C.TOPICSHORTTITLE is null))
and (replace( I.TOPICDESCRIPTION,char(10),char(13)+char(10)) =  C.TOPICDESCRIPTION OR (I.TOPICDESCRIPTION is null and C.TOPICDESCRIPTION is null))
and ( I.DISPLAYDESCRIPTION =  C.DISPLAYDESCRIPTION)
and (replace( I.SCREENTIP,char(10),char(13)+char(10)) =  C.SCREENTIP OR (I.SCREENTIP is null and C.SCREENTIP is null))
and ( I.ISHIDDEN =  C.ISHIDDEN)
and ( I.ISMANDATORY =  C.ISMANDATORY)
and ( I.ISINHERITED =  C.ISINHERITED)
and ( I.FILTERNAME =  C.FILTERNAME OR (I.FILTERNAME is null and C.FILTERNAME is null))
and (replace( I.FILTERVALUE,char(10),char(13)+char(10)) =  C.FILTERVALUE OR (I.FILTERVALUE is null and C.FILTERVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICCONTROL]') and xtype='U')
begin
	drop table CCImport_TOPICCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTOPICCONTROL  to public
go

