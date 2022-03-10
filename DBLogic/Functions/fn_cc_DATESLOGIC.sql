-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DATESLOGIC
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DATESLOGIC]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DATESLOGIC.'
	drop function dbo.fn_cc_DATESLOGIC
	print '**** Creating function dbo.fn_cc_DATESLOGIC...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DATESLOGIC]') and xtype='U')
begin
	select * 
	into CCImport_DATESLOGIC 
	from DATESLOGIC
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DATESLOGIC
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DATESLOGIC
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DATESLOGIC table
-- CALLED BY :	ip_CopyConfigDATESLOGIC
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
	 null as 'Imported Eventno',
	 null as 'Imported Sequenceno',
	 null as 'Imported Datetype',
	 null as 'Imported Operator',
	 null as 'Imported Compareevent',
	 null as 'Imported Mustexist',
	 null as 'Imported Relativecycle',
	 null as 'Imported Comparedatetype',
	 null as 'Imported Caserelationship',
	 null as 'Imported Displayerrorflag',
	 null as 'Imported Errormessage',
	 null as 'Imported Inherited',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.EVENTNO as 'Eventno',
	 C.SEQUENCENO as 'Sequenceno',
	 C.DATETYPE as 'Datetype',
	 C.OPERATOR as 'Operator',
	 C.COMPAREEVENT as 'Compareevent',
	 C.MUSTEXIST as 'Mustexist',
	 C.RELATIVECYCLE as 'Relativecycle',
	 C.COMPAREDATETYPE as 'Comparedatetype',
	 C.CASERELATIONSHIP as 'Caserelationship',
	 C.DISPLAYERRORFLAG as 'Displayerrorflag',
	 C.ERRORMESSAGE as 'Errormessage',
	 C.INHERITED as 'Inherited'
from CCImport_DATESLOGIC I 
	right join DATESLOGIC C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCENO=I.SEQUENCENO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.SEQUENCENO,
	 I.DATETYPE,
	 I.OPERATOR,
	 I.COMPAREEVENT,
	 I.MUSTEXIST,
	 I.RELATIVECYCLE,
	 I.COMPAREDATETYPE,
	 I.CASERELATIONSHIP,
	 I.DISPLAYERRORFLAG,
	 I.ERRORMESSAGE,
	 I.INHERITED,
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
	 null
from CCImport_DATESLOGIC I 
	left join DATESLOGIC C on( C.CRITERIANO=I.CRITERIANO
and  C.EVENTNO=I.EVENTNO
and  C.SEQUENCENO=I.SEQUENCENO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.EVENTNO,
	 I.SEQUENCENO,
	 I.DATETYPE,
	 I.OPERATOR,
	 I.COMPAREEVENT,
	 I.MUSTEXIST,
	 I.RELATIVECYCLE,
	 I.COMPAREDATETYPE,
	 I.CASERELATIONSHIP,
	 I.DISPLAYERRORFLAG,
	 I.ERRORMESSAGE,
	 I.INHERITED,
'U',
	 C.CRITERIANO,
	 C.EVENTNO,
	 C.SEQUENCENO,
	 C.DATETYPE,
	 C.OPERATOR,
	 C.COMPAREEVENT,
	 C.MUSTEXIST,
	 C.RELATIVECYCLE,
	 C.COMPAREDATETYPE,
	 C.CASERELATIONSHIP,
	 C.DISPLAYERRORFLAG,
	 C.ERRORMESSAGE,
	 C.INHERITED
from CCImport_DATESLOGIC I 
	join DATESLOGIC C	on ( C.CRITERIANO=I.CRITERIANO
	and C.EVENTNO=I.EVENTNO
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.DATETYPE <>  C.DATETYPE)
	OR 	( I.OPERATOR <>  C.OPERATOR OR (I.OPERATOR is null and C.OPERATOR is not null) 
OR (I.OPERATOR is not null and C.OPERATOR is null))
	OR 	( I.COMPAREEVENT <>  C.COMPAREEVENT OR (I.COMPAREEVENT is null and C.COMPAREEVENT is not null) 
OR (I.COMPAREEVENT is not null and C.COMPAREEVENT is null))
	OR 	( I.MUSTEXIST <>  C.MUSTEXIST)
	OR 	( I.RELATIVECYCLE <>  C.RELATIVECYCLE OR (I.RELATIVECYCLE is null and C.RELATIVECYCLE is not null) 
OR (I.RELATIVECYCLE is not null and C.RELATIVECYCLE is null))
	OR 	( I.COMPAREDATETYPE <>  C.COMPAREDATETYPE)
	OR 	( I.CASERELATIONSHIP <>  C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is not null) 
OR (I.CASERELATIONSHIP is not null and C.CASERELATIONSHIP is null))
	OR 	( I.DISPLAYERRORFLAG <>  C.DISPLAYERRORFLAG OR (I.DISPLAYERRORFLAG is null and C.DISPLAYERRORFLAG is not null) 
OR (I.DISPLAYERRORFLAG is not null and C.DISPLAYERRORFLAG is null))
	OR 	(replace( I.ERRORMESSAGE,char(10),char(13)+char(10)) <>  C.ERRORMESSAGE OR (I.ERRORMESSAGE is null and C.ERRORMESSAGE is not null) 
OR (I.ERRORMESSAGE is not null and C.ERRORMESSAGE is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DATESLOGIC]') and xtype='U')
begin
	drop table CCImport_DATESLOGIC 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DATESLOGIC  to public
go
