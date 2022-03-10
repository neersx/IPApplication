-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CHECKLISTLETTER
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CHECKLISTLETTER]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CHECKLISTLETTER.'
	drop function dbo.fn_cc_CHECKLISTLETTER
	print '**** Creating function dbo.fn_cc_CHECKLISTLETTER...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CHECKLISTLETTER]') and xtype='U')
begin
	select * 
	into CCImport_CHECKLISTLETTER 
	from CHECKLISTLETTER
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CHECKLISTLETTER
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CHECKLISTLETTER
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CHECKLISTLETTER table
-- CALLED BY :	ip_CopyConfigCHECKLISTLETTER
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
	 null as 'Imported Letterno',
	 null as 'Imported Questionno',
	 null as 'Imported Requiredanswer',
	 null as 'Imported Inherited',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.LETTERNO as 'Letterno',
	 C.QUESTIONNO as 'Questionno',
	 C.REQUIREDANSWER as 'Requiredanswer',
	 C.INHERITED as 'Inherited'
from CCImport_CHECKLISTLETTER I 
	right join CHECKLISTLETTER C on( C.CRITERIANO=I.CRITERIANO
and  C.LETTERNO=I.LETTERNO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.LETTERNO,
	 I.QUESTIONNO,
	 I.REQUIREDANSWER,
	 I.INHERITED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_CHECKLISTLETTER I 
	left join CHECKLISTLETTER C on( C.CRITERIANO=I.CRITERIANO
and  C.LETTERNO=I.LETTERNO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.LETTERNO,
	 I.QUESTIONNO,
	 I.REQUIREDANSWER,
	 I.INHERITED,
'U',
	 C.CRITERIANO,
	 C.LETTERNO,
	 C.QUESTIONNO,
	 C.REQUIREDANSWER,
	 C.INHERITED
from CCImport_CHECKLISTLETTER I 
	join CHECKLISTLETTER C	on ( C.CRITERIANO=I.CRITERIANO
	and C.LETTERNO=I.LETTERNO)
where 	( I.QUESTIONNO <>  C.QUESTIONNO OR (I.QUESTIONNO is null and C.QUESTIONNO is not null) 
OR (I.QUESTIONNO is not null and C.QUESTIONNO is null))
	OR 	( I.REQUIREDANSWER <>  C.REQUIREDANSWER OR (I.REQUIREDANSWER is null and C.REQUIREDANSWER is not null) 
OR (I.REQUIREDANSWER is not null and C.REQUIREDANSWER is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CHECKLISTLETTER]') and xtype='U')
begin
	drop table CCImport_CHECKLISTLETTER 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CHECKLISTLETTER  to public
go
