-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnALERTTEMPLATE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnALERTTEMPLATE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnALERTTEMPLATE.'
	drop function dbo.fn_ccnALERTTEMPLATE
	print '**** Creating function dbo.fn_ccnALERTTEMPLATE...'
	print ''
end
go

SET NOCOUNT ON
GO

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ALERTTEMPLATE]') and xtype='U')
begin
	select * 
	into CCImport_ALERTTEMPLATE 
	from ALERTTEMPLATE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnALERTTEMPLATE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnALERTTEMPLATE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ALERTTEMPLATE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'ALERTTEMPLATE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ALERTTEMPLATE I 
	right join ALERTTEMPLATE C on( C.ALERTTEMPLATECODE=I.ALERTTEMPLATECODE)
where I.ALERTTEMPLATECODE is null
UNION ALL 
select	2, 'ALERTTEMPLATE', 0, count(*), 0, 0
from CCImport_ALERTTEMPLATE I 
	left join ALERTTEMPLATE C on( C.ALERTTEMPLATECODE=I.ALERTTEMPLATECODE)
where C.ALERTTEMPLATECODE is null
UNION ALL 
 select	2, 'ALERTTEMPLATE', 0, 0, count(*), 0
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
UNION ALL 
 select	2, 'ALERTTEMPLATE', 0, 0, 0, count(*)
from CCImport_ALERTTEMPLATE I 
join ALERTTEMPLATE C	on( C.ALERTTEMPLATECODE=I.ALERTTEMPLATECODE)
where (replace( I.ALERTMESSAGE,char(10),char(13)+char(10)) =  C.ALERTMESSAGE)
and ( I.EMAILSUBJECT =  C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is null))
and ( I.SENDELECTRONICALLY =  C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is null))
and ( I.IMPORTANCELEVEL =  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is null))
and ( I.DAYSLEAD =  C.DAYSLEAD OR (I.DAYSLEAD is null and C.DAYSLEAD is null))
and ( I.DAILYFREQUENCY =  C.DAILYFREQUENCY OR (I.DAILYFREQUENCY is null and C.DAILYFREQUENCY is null))
and ( I.MONTHSLEAD =  C.MONTHSLEAD OR (I.MONTHSLEAD is null and C.MONTHSLEAD is null))
and ( I.MONTHLYFREQUENCY =  C.MONTHLYFREQUENCY OR (I.MONTHLYFREQUENCY is null and C.MONTHLYFREQUENCY is null))
and ( I.STOPALERT =  C.STOPALERT OR (I.STOPALERT is null and C.STOPALERT is null))
and ( I.DELETEALERT =  C.DELETEALERT OR (I.DELETEALERT is null and C.DELETEALERT is null))
and ( I.EMPLOYEEFLAG =  C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is null))
and ( I.CRITICALFLAG =  C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is null))
and ( I.SIGNATORYFLAG =  C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is null))
and ( I.NAMETYPE =  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))
and ( I.RELATIONSHIP =  C.RELATIONSHIP OR (I.RELATIONSHIP is null and C.RELATIONSHIP is null))
and ( I.EMPLOYEENO =  C.EMPLOYEENO OR (I.EMPLOYEENO is null and C.EMPLOYEENO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ALERTTEMPLATE]') and xtype='U')
begin
	drop table CCImport_ALERTTEMPLATE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnALERTTEMPLATE  to public
go
