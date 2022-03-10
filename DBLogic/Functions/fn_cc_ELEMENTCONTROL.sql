-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ELEMENTCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ELEMENTCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ELEMENTCONTROL.'
	drop function dbo.fn_cc_ELEMENTCONTROL
	print '**** Creating function dbo.fn_cc_ELEMENTCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ELEMENTCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_ELEMENTCONTROL 
	from ELEMENTCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ELEMENTCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ELEMENTCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ELEMENTCONTROL table
-- CALLED BY :	ip_CopyConfigELEMENTCONTROL
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
	 null as 'Imported Topiccontrolno',
	 null as 'Imported Elementname',
	 null as 'Imported Shortlabel',
	 null as 'Imported Fulllabel',
	 null as 'Imported Button',
	 null as 'Imported Tooltip',
	 null as 'Imported Link',
	 null as 'Imported Literal',
	 null as 'Imported Defaultvalue',
	 null as 'Imported Ishidden',
	 null as 'Imported Ismandatory',
	 null as 'Imported Isreadonly',
	 null as 'Imported Isinherited',
	 null as 'Imported Filtername',
	 null as 'Imported Filtervalue',
'D' as '-',
	 C.TOPICCONTROLNO as 'Topiccontrolno',
	 C.ELEMENTNAME as 'Elementname',
	 C.SHORTLABEL as 'Shortlabel',
	 C.FULLLABEL as 'Fulllabel',
	 C.BUTTON as 'Button',
	 C.TOOLTIP as 'Tooltip',
	 C.LINK as 'Link',
	 C.LITERAL as 'Literal',
	 C.DEFAULTVALUE as 'Defaultvalue',
	 C.ISHIDDEN as 'Ishidden',
	 C.ISMANDATORY as 'Ismandatory',
	 C.ISREADONLY as 'Isreadonly',
	 C.ISINHERITED as 'Isinherited',
	 C.FILTERNAME as 'Filtername',
	 C.FILTERVALUE as 'Filtervalue'
from CCImport_ELEMENTCONTROL I 
	right join ELEMENTCONTROL C on( C.ELEMENTCONTROLNO=I.ELEMENTCONTROLNO)
where I.ELEMENTCONTROLNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TOPICCONTROLNO,
	 I.ELEMENTNAME,
	 I.SHORTLABEL,
	 I.FULLLABEL,
	 I.BUTTON,
	 I.TOOLTIP,
	 I.LINK,
	 I.LITERAL,
	 I.DEFAULTVALUE,
	 I.ISHIDDEN,
	 I.ISMANDATORY,
	 I.ISREADONLY,
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
	 null
from CCImport_ELEMENTCONTROL I 
	left join ELEMENTCONTROL C on( C.ELEMENTCONTROLNO=I.ELEMENTCONTROLNO)
where C.ELEMENTCONTROLNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TOPICCONTROLNO,
	 I.ELEMENTNAME,
	 I.SHORTLABEL,
	 I.FULLLABEL,
	 I.BUTTON,
	 I.TOOLTIP,
	 I.LINK,
	 I.LITERAL,
	 I.DEFAULTVALUE,
	 I.ISHIDDEN,
	 I.ISMANDATORY,
	 I.ISREADONLY,
	 I.ISINHERITED,
	 I.FILTERNAME,
	 I.FILTERVALUE,
'U',
	 C.TOPICCONTROLNO,
	 C.ELEMENTNAME,
	 C.SHORTLABEL,
	 C.FULLLABEL,
	 C.BUTTON,
	 C.TOOLTIP,
	 C.LINK,
	 C.LITERAL,
	 C.DEFAULTVALUE,
	 C.ISHIDDEN,
	 C.ISMANDATORY,
	 C.ISREADONLY,
	 C.ISINHERITED,
	 C.FILTERNAME,
	 C.FILTERVALUE
from CCImport_ELEMENTCONTROL I 
	join ELEMENTCONTROL C	on ( C.ELEMENTCONTROLNO=I.ELEMENTCONTROLNO)
where 	( I.TOPICCONTROLNO <>  C.TOPICCONTROLNO)
	OR 	( I.ELEMENTNAME <>  C.ELEMENTNAME)
	OR 	(replace( I.SHORTLABEL,char(10),char(13)+char(10)) <>  C.SHORTLABEL OR (I.SHORTLABEL is null and C.SHORTLABEL is not null) 
OR (I.SHORTLABEL is not null and C.SHORTLABEL is null))
	OR 	(replace( I.FULLLABEL,char(10),char(13)+char(10)) <>  C.FULLLABEL OR (I.FULLLABEL is null and C.FULLLABEL is not null) 
OR (I.FULLLABEL is not null and C.FULLLABEL is null))
	OR 	(replace( I.BUTTON,char(10),char(13)+char(10)) <>  C.BUTTON OR (I.BUTTON is null and C.BUTTON is not null) 
OR (I.BUTTON is not null and C.BUTTON is null))
	OR 	(replace( I.TOOLTIP,char(10),char(13)+char(10)) <>  C.TOOLTIP OR (I.TOOLTIP is null and C.TOOLTIP is not null) 
OR (I.TOOLTIP is not null and C.TOOLTIP is null))
	OR 	(replace( I.LINK,char(10),char(13)+char(10)) <>  C.LINK OR (I.LINK is null and C.LINK is not null) 
OR (I.LINK is not null and C.LINK is null))
	OR 	(replace( I.LITERAL,char(10),char(13)+char(10)) <>  C.LITERAL OR (I.LITERAL is null and C.LITERAL is not null) 
OR (I.LITERAL is not null and C.LITERAL is null))
	OR 	(replace( I.DEFAULTVALUE,char(10),char(13)+char(10)) <>  C.DEFAULTVALUE OR (I.DEFAULTVALUE is null and C.DEFAULTVALUE is not null) 
OR (I.DEFAULTVALUE is not null and C.DEFAULTVALUE is null))
	OR 	( I.ISHIDDEN <>  C.ISHIDDEN)
	OR 	( I.ISMANDATORY <>  C.ISMANDATORY)
	OR 	( I.ISREADONLY <>  C.ISREADONLY)
	OR 	( I.ISINHERITED <>  C.ISINHERITED)
	OR 	( I.FILTERNAME <>  C.FILTERNAME OR (I.FILTERNAME is null and C.FILTERNAME is not null) 
OR (I.FILTERNAME is not null and C.FILTERNAME is null))
	OR 	(replace( I.FILTERVALUE,char(10),char(13)+char(10)) <>  C.FILTERVALUE OR (I.FILTERVALUE is null and C.FILTERVALUE is not null) 
OR (I.FILTERVALUE is not null and C.FILTERVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ELEMENTCONTROL]') and xtype='U')
begin
	drop table CCImport_ELEMENTCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ELEMENTCONTROL  to public
go
