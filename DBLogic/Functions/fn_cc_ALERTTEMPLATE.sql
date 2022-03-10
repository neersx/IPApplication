-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ALERTTEMPLATE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ALERTTEMPLATE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ALERTTEMPLATE.'
	drop function dbo.fn_cc_ALERTTEMPLATE
	print '**** Creating function dbo.fn_cc_ALERTTEMPLATE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ALERTTEMPLATE]') and xtype='U')
begin
	select * 
	into CCImport_ALERTTEMPLATE 
	from ALERTTEMPLATE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ALERTTEMPLATE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ALERTTEMPLATE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ALERTTEMPLATE table
-- CALLED BY :	ip_CopyConfigALERTTEMPLATE
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
	 null as 'Imported Alerttemplatecode',
	 null as 'Imported Alertmessage',
	 null as 'Imported Emailsubject',
	 null as 'Imported Sendelectronically',
	 null as 'Imported Importancelevel',
	 null as 'Imported Dayslead',
	 null as 'Imported Dailyfrequency',
	 null as 'Imported Monthslead',
	 null as 'Imported Monthlyfrequency',
	 null as 'Imported Stopalert',
	 null as 'Imported Deletealert',
	 null as 'Imported Employeeflag',
	 null as 'Imported Criticalflag',
	 null as 'Imported Signatoryflag',
	 null as 'Imported Nametype',
	 null as 'Imported Relationship',
	 null as 'Imported Employeeno',
'D' as '-',
	 C.ALERTTEMPLATECODE as 'Alerttemplatecode',
	 C.ALERTMESSAGE as 'Alertmessage',
	 C.EMAILSUBJECT as 'Emailsubject',
	 C.SENDELECTRONICALLY as 'Sendelectronically',
	 C.IMPORTANCELEVEL as 'Importancelevel',
	 C.DAYSLEAD as 'Dayslead',
	 C.DAILYFREQUENCY as 'Dailyfrequency',
	 C.MONTHSLEAD as 'Monthslead',
	 C.MONTHLYFREQUENCY as 'Monthlyfrequency',
	 C.STOPALERT as 'Stopalert',
	 C.DELETEALERT as 'Deletealert',
	 C.EMPLOYEEFLAG as 'Employeeflag',
	 C.CRITICALFLAG as 'Criticalflag',
	 C.SIGNATORYFLAG as 'Signatoryflag',
	 C.NAMETYPE as 'Nametype',
	 C.RELATIONSHIP as 'Relationship',
	 C.EMPLOYEENO as 'Employeeno'
from CCImport_ALERTTEMPLATE I 
	right join ALERTTEMPLATE C on( C.ALERTTEMPLATECODE=I.ALERTTEMPLATECODE)
where I.ALERTTEMPLATECODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ALERTTEMPLATECODE,
	 I.ALERTMESSAGE,
	 I.EMAILSUBJECT,
	 I.SENDELECTRONICALLY,
	 I.IMPORTANCELEVEL,
	 I.DAYSLEAD,
	 I.DAILYFREQUENCY,
	 I.MONTHSLEAD,
	 I.MONTHLYFREQUENCY,
	 I.STOPALERT,
	 I.DELETEALERT,
	 I.EMPLOYEEFLAG,
	 I.CRITICALFLAG,
	 I.SIGNATORYFLAG,
	 I.NAMETYPE,
	 I.RELATIONSHIP,
	 I.EMPLOYEENO,
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
	 null ,
	 null
from CCImport_ALERTTEMPLATE I 
	left join ALERTTEMPLATE C on( C.ALERTTEMPLATECODE=I.ALERTTEMPLATECODE)
where C.ALERTTEMPLATECODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ALERTTEMPLATECODE,
	 I.ALERTMESSAGE,
	 I.EMAILSUBJECT,
	 I.SENDELECTRONICALLY,
	 I.IMPORTANCELEVEL,
	 I.DAYSLEAD,
	 I.DAILYFREQUENCY,
	 I.MONTHSLEAD,
	 I.MONTHLYFREQUENCY,
	 I.STOPALERT,
	 I.DELETEALERT,
	 I.EMPLOYEEFLAG,
	 I.CRITICALFLAG,
	 I.SIGNATORYFLAG,
	 I.NAMETYPE,
	 I.RELATIONSHIP,
	 I.EMPLOYEENO,
'U',
	 C.ALERTTEMPLATECODE,
	 C.ALERTMESSAGE,
	 C.EMAILSUBJECT,
	 C.SENDELECTRONICALLY,
	 C.IMPORTANCELEVEL,
	 C.DAYSLEAD,
	 C.DAILYFREQUENCY,
	 C.MONTHSLEAD,
	 C.MONTHLYFREQUENCY,
	 C.STOPALERT,
	 C.DELETEALERT,
	 C.EMPLOYEEFLAG,
	 C.CRITICALFLAG,
	 C.SIGNATORYFLAG,
	 C.NAMETYPE,
	 C.RELATIONSHIP,
	 C.EMPLOYEENO
from CCImport_ALERTTEMPLATE I 
	join ALERTTEMPLATE C	on ( C.ALERTTEMPLATECODE=I.ALERTTEMPLATECODE)
where 	(replace( I.ALERTMESSAGE,char(10),char(13)+char(10)) <>  C.ALERTMESSAGE)
	OR 	( I.EMAILSUBJECT <>  C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is not null) 
OR (I.EMAILSUBJECT is not null and C.EMAILSUBJECT is null))
	OR 	( I.SENDELECTRONICALLY <>  C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is not null) 
OR (I.SENDELECTRONICALLY is not null and C.SENDELECTRONICALLY is null))
	OR 	( I.IMPORTANCELEVEL <>  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is not null) 
OR (I.IMPORTANCELEVEL is not null and C.IMPORTANCELEVEL is null))
	OR 	( I.DAYSLEAD <>  C.DAYSLEAD OR (I.DAYSLEAD is null and C.DAYSLEAD is not null) 
OR (I.DAYSLEAD is not null and C.DAYSLEAD is null))
	OR 	( I.DAILYFREQUENCY <>  C.DAILYFREQUENCY OR (I.DAILYFREQUENCY is null and C.DAILYFREQUENCY is not null) 
OR (I.DAILYFREQUENCY is not null and C.DAILYFREQUENCY is null))
	OR 	( I.MONTHSLEAD <>  C.MONTHSLEAD OR (I.MONTHSLEAD is null and C.MONTHSLEAD is not null) 
OR (I.MONTHSLEAD is not null and C.MONTHSLEAD is null))
	OR 	( I.MONTHLYFREQUENCY <>  C.MONTHLYFREQUENCY OR (I.MONTHLYFREQUENCY is null and C.MONTHLYFREQUENCY is not null) 
OR (I.MONTHLYFREQUENCY is not null and C.MONTHLYFREQUENCY is null))
	OR 	( I.STOPALERT <>  C.STOPALERT OR (I.STOPALERT is null and C.STOPALERT is not null) 
OR (I.STOPALERT is not null and C.STOPALERT is null))
	OR 	( I.DELETEALERT <>  C.DELETEALERT OR (I.DELETEALERT is null and C.DELETEALERT is not null) 
OR (I.DELETEALERT is not null and C.DELETEALERT is null))
	OR 	( I.EMPLOYEEFLAG <>  C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is not null) 
OR (I.EMPLOYEEFLAG is not null and C.EMPLOYEEFLAG is null))
	OR 	( I.CRITICALFLAG <>  C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is not null) 
OR (I.CRITICALFLAG is not null and C.CRITICALFLAG is null))
	OR 	( I.SIGNATORYFLAG <>  C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is not null) 
OR (I.SIGNATORYFLAG is not null and C.SIGNATORYFLAG is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.RELATIONSHIP <>  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is not null) 
OR (I.RELATIONSHIP is not null and C.RELATIONSHIP is null))
	OR 	( I.EMPLOYEENO <>  C.EMPLOYEENO OR (I.EMPLOYEENO is null and C.EMPLOYEENO is not null) 
OR (I.EMPLOYEENO is not null and C.EMPLOYEENO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ALERTTEMPLATE]') and xtype='U')
begin
	drop table CCImport_ALERTTEMPLATE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ALERTTEMPLATE  to public
go

