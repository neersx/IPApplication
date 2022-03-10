-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnELEMENTCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnELEMENTCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnELEMENTCONTROL.'
	drop function dbo.fn_ccnELEMENTCONTROL
	print '**** Creating function dbo.fn_ccnELEMENTCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnELEMENTCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnELEMENTCONTROL
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ELEMENTCONTROL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'ELEMENTCONTROL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ELEMENTCONTROL I 
	right join ELEMENTCONTROL C on( C.ELEMENTCONTROLNO=I.ELEMENTCONTROLNO)
where I.ELEMENTCONTROLNO is null
UNION ALL 
select	6, 'ELEMENTCONTROL', 0, count(*), 0, 0
from CCImport_ELEMENTCONTROL I 
	left join ELEMENTCONTROL C on( C.ELEMENTCONTROLNO=I.ELEMENTCONTROLNO)
where C.ELEMENTCONTROLNO is null
UNION ALL 
 select	6, 'ELEMENTCONTROL', 0, 0, count(*), 0
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
UNION ALL 
 select	6, 'ELEMENTCONTROL', 0, 0, 0, count(*)
from CCImport_ELEMENTCONTROL I 
join ELEMENTCONTROL C	on( C.ELEMENTCONTROLNO=I.ELEMENTCONTROLNO)
where ( I.TOPICCONTROLNO =  C.TOPICCONTROLNO)
and ( I.ELEMENTNAME =  C.ELEMENTNAME)
and (replace( I.SHORTLABEL,char(10),char(13)+char(10)) =  C.SHORTLABEL OR (I.SHORTLABEL is null and C.SHORTLABEL is null))
and (replace( I.FULLLABEL,char(10),char(13)+char(10)) =  C.FULLLABEL OR (I.FULLLABEL is null and C.FULLLABEL is null))
and (replace( I.BUTTON,char(10),char(13)+char(10)) =  C.BUTTON OR (I.BUTTON is null and C.BUTTON is null))
and (replace( I.TOOLTIP,char(10),char(13)+char(10)) =  C.TOOLTIP OR (I.TOOLTIP is null and C.TOOLTIP is null))
and (replace( I.LINK,char(10),char(13)+char(10)) =  C.LINK OR (I.LINK is null and C.LINK is null))
and (replace( I.LITERAL,char(10),char(13)+char(10)) =  C.LITERAL OR (I.LITERAL is null and C.LITERAL is null))
and (replace( I.DEFAULTVALUE,char(10),char(13)+char(10)) =  C.DEFAULTVALUE OR (I.DEFAULTVALUE is null and C.DEFAULTVALUE is null))
and ( I.ISHIDDEN =  C.ISHIDDEN)
and ( I.ISMANDATORY =  C.ISMANDATORY)
and ( I.ISREADONLY =  C.ISREADONLY)
and ( I.ISINHERITED =  C.ISINHERITED)
and ( I.FILTERNAME =  C.FILTERNAME OR (I.FILTERNAME is null and C.FILTERNAME is null))
and (replace( I.FILTERVALUE,char(10),char(13)+char(10)) =  C.FILTERVALUE OR (I.FILTERVALUE is null and C.FILTERVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ELEMENTCONTROL]') and xtype='U')
begin
	drop table CCImport_ELEMENTCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnELEMENTCONTROL  to public
go
