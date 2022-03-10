-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnB2BTASKEVENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnB2BTASKEVENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnB2BTASKEVENT.'
	drop function dbo.fn_ccnB2BTASKEVENT
	print '**** Creating function dbo.fn_ccnB2BTASKEVENT...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_B2BTASKEVENT]') and xtype='U')
begin
	select * 
	into CCImport_B2BTASKEVENT 
	from B2BTASKEVENT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnB2BTASKEVENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnB2BTASKEVENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the B2BTASKEVENT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'B2BTASKEVENT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_B2BTASKEVENT I 
	right join B2BTASKEVENT C on( C.PACKAGETYPE=I.PACKAGETYPE
and  C.TASKTYPE=I.TASKTYPE)
where I.PACKAGETYPE is null
UNION ALL 
select	9, 'B2BTASKEVENT', 0, count(*), 0, 0
from CCImport_B2BTASKEVENT I 
	left join B2BTASKEVENT C on( C.PACKAGETYPE=I.PACKAGETYPE
and  C.TASKTYPE=I.TASKTYPE)
where C.PACKAGETYPE is null
UNION ALL 
 select	9, 'B2BTASKEVENT', 0, 0, count(*), 0
from CCImport_B2BTASKEVENT I 
	join B2BTASKEVENT C	on ( C.PACKAGETYPE=I.PACKAGETYPE
	and C.TASKTYPE=I.TASKTYPE)
where 	( I.EVENTNO <>  C.EVENTNO)
	OR 	( I.TASKORDER <>  C.TASKORDER)
	OR 	( I.AUTOMATICFLAG <>  C.AUTOMATICFLAG OR (I.AUTOMATICFLAG is null and C.AUTOMATICFLAG is not null) 
OR (I.AUTOMATICFLAG is not null and C.AUTOMATICFLAG is null))
	OR 	( I.FINALFLAG <>  C.FINALFLAG OR (I.FINALFLAG is null and C.FINALFLAG is not null) 
OR (I.FINALFLAG is not null and C.FINALFLAG is null))
	OR 	( I.RETROEVENTNO <>  C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) 
OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null))
	OR 	(replace( I.PROMPT,char(10),char(13)+char(10)) <>  C.PROMPT OR (I.PROMPT is null and C.PROMPT is not null) 
OR (I.PROMPT is not null and C.PROMPT is null))
	OR 	(replace( I.COLLECTFILE,char(10),char(13)+char(10)) <>  C.COLLECTFILE OR (I.COLLECTFILE is null and C.COLLECTFILE is not null) 
OR (I.COLLECTFILE is not null and C.COLLECTFILE is null))
	OR 	( I.IMPORTMETHODNO <>  C.IMPORTMETHODNO OR (I.IMPORTMETHODNO is null and C.IMPORTMETHODNO is not null) 
OR (I.IMPORTMETHODNO is not null and C.IMPORTMETHODNO is null))
	OR 	(replace( I.XMLINSTRUCTION,char(10),char(13)+char(10)) <>  C.XMLINSTRUCTION OR (I.XMLINSTRUCTION is null and C.XMLINSTRUCTION is not null) 
OR (I.XMLINSTRUCTION is not null and C.XMLINSTRUCTION is null))
	OR 	( I.LETTERNO <>  C.LETTERNO OR (I.LETTERNO is null and C.LETTERNO is not null) 
OR (I.LETTERNO is not null and C.LETTERNO is null))
UNION ALL 
 select	9, 'B2BTASKEVENT', 0, 0, 0, count(*)
from CCImport_B2BTASKEVENT I 
join B2BTASKEVENT C	on( C.PACKAGETYPE=I.PACKAGETYPE
and C.TASKTYPE=I.TASKTYPE)
where ( I.EVENTNO =  C.EVENTNO)
and ( I.TASKORDER =  C.TASKORDER)
and ( I.AUTOMATICFLAG =  C.AUTOMATICFLAG OR (I.AUTOMATICFLAG is null and C.AUTOMATICFLAG is null))
and ( I.FINALFLAG =  C.FINALFLAG OR (I.FINALFLAG is null and C.FINALFLAG is null))
and ( I.RETROEVENTNO =  C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is null))
and (replace( I.PROMPT,char(10),char(13)+char(10)) =  C.PROMPT OR (I.PROMPT is null and C.PROMPT is null))
and (replace( I.COLLECTFILE,char(10),char(13)+char(10)) =  C.COLLECTFILE OR (I.COLLECTFILE is null and C.COLLECTFILE is null))
and ( I.IMPORTMETHODNO =  C.IMPORTMETHODNO OR (I.IMPORTMETHODNO is null and C.IMPORTMETHODNO is null))
and (replace( I.XMLINSTRUCTION,char(10),char(13)+char(10)) =  C.XMLINSTRUCTION OR (I.XMLINSTRUCTION is null and C.XMLINSTRUCTION is null))
and ( I.LETTERNO =  C.LETTERNO OR (I.LETTERNO is null and C.LETTERNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_B2BTASKEVENT]') and xtype='U')
begin
	drop table CCImport_B2BTASKEVENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnB2BTASKEVENT  to public
go

