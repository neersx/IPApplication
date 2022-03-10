-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_B2BTASKEVENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_B2BTASKEVENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_B2BTASKEVENT.'
	drop function dbo.fn_cc_B2BTASKEVENT
	print '**** Creating function dbo.fn_cc_B2BTASKEVENT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_B2BTASKEVENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_B2BTASKEVENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the B2BTASKEVENT table
-- CALLED BY :	ip_CopyConfigB2BTASKEVENT
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
	 null as 'Imported Packagetype',
	 null as 'Imported Tasktype',
	 null as 'Imported Eventno',
	 null as 'Imported Taskorder',
	 null as 'Imported Automaticflag',
	 null as 'Imported Finalflag',
	 null as 'Imported Retroeventno',
	 null as 'Imported Prompt',
	 null as 'Imported Collectfile',
	 null as 'Imported Importmethodno',
	 null as 'Imported Xmlinstruction',
	 null as 'Imported Letterno',
'D' as '-',
	 C.PACKAGETYPE as 'Packagetype',
	 C.TASKTYPE as 'Tasktype',
	 C.EVENTNO as 'Eventno',
	 C.TASKORDER as 'Taskorder',
	 C.AUTOMATICFLAG as 'Automaticflag',
	 C.FINALFLAG as 'Finalflag',
	 C.RETROEVENTNO as 'Retroeventno',
	 C.PROMPT as 'Prompt',
	 C.COLLECTFILE as 'Collectfile',
	 C.IMPORTMETHODNO as 'Importmethodno',
	 C.XMLINSTRUCTION as 'Xmlinstruction',
	 C.LETTERNO as 'Letterno'
from CCImport_B2BTASKEVENT I 
	right join B2BTASKEVENT C on( C.PACKAGETYPE=I.PACKAGETYPE
and  C.TASKTYPE=I.TASKTYPE)
where I.PACKAGETYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PACKAGETYPE,
	 I.TASKTYPE,
	 I.EVENTNO,
	 I.TASKORDER,
	 I.AUTOMATICFLAG,
	 I.FINALFLAG,
	 I.RETROEVENTNO,
	 I.PROMPT,
	 I.COLLECTFILE,
	 I.IMPORTMETHODNO,
	 I.XMLINSTRUCTION,
	 I.LETTERNO,
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
	 null
from CCImport_B2BTASKEVENT I 
	left join B2BTASKEVENT C on( C.PACKAGETYPE=I.PACKAGETYPE
and  C.TASKTYPE=I.TASKTYPE)
where C.PACKAGETYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.PACKAGETYPE,
	 I.TASKTYPE,
	 I.EVENTNO,
	 I.TASKORDER,
	 I.AUTOMATICFLAG,
	 I.FINALFLAG,
	 I.RETROEVENTNO,
	 I.PROMPT,
	 I.COLLECTFILE,
	 I.IMPORTMETHODNO,
	 I.XMLINSTRUCTION,
	 I.LETTERNO,
'U',
	 C.PACKAGETYPE,
	 C.TASKTYPE,
	 C.EVENTNO,
	 C.TASKORDER,
	 C.AUTOMATICFLAG,
	 C.FINALFLAG,
	 C.RETROEVENTNO,
	 C.PROMPT,
	 C.COLLECTFILE,
	 C.IMPORTMETHODNO,
	 C.XMLINSTRUCTION,
	 C.LETTERNO
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_B2BTASKEVENT]') and xtype='U')
begin
	drop table CCImport_B2BTASKEVENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_B2BTASKEVENT  to public
go

