-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CHECKLISTITEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CHECKLISTITEM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CHECKLISTITEM.'
	drop function dbo.fn_cc_CHECKLISTITEM
	print '**** Creating function dbo.fn_cc_CHECKLISTITEM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CHECKLISTITEM]') and xtype='U')
begin
	select * 
	into CCImport_CHECKLISTITEM 
	from CHECKLISTITEM
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_CHECKLISTITEM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CHECKLISTITEM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CHECKLISTITEM table
-- CALLED BY :	ip_CopyConfigCHECKLISTITEM
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
	 null as 'Imported Questionno',
	 null as 'Imported Sequenceno',
	 null as 'Imported Question',
	 null as 'Imported Yesnorequired',
	 null as 'Imported Countrequired',
	 null as 'Imported Periodtyperequired',
	 null as 'Imported Amountrequired',
	 null as 'Imported Daterequired',
	 null as 'Imported Employeerequired',
	 null as 'Imported Textrequired',
	 null as 'Imported Payfeecode',
	 null as 'Imported Updateeventno',
	 null as 'Imported Duedateflag',
	 null as 'Imported Yesrateno',
	 null as 'Imported Norateno',
	 null as 'Imported Yeschecklisttype',
	 null as 'Imported Nochecklisttype',
	 null as 'Imported Inherited',
	 null as 'Imported Noduedateflag',
	 null as 'Imported Noeventno',
	 null as 'Imported Estimateflag',
	 null as 'Imported Directpayflag',
	 null as 'Imported Sourcequestion',
	 null as 'Imported Answersourceyes',
	 null as 'Imported Answersourceno',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.QUESTIONNO as 'Questionno',
	 C.SEQUENCENO as 'Sequenceno',
	 C.QUESTION as 'Question',
	 C.YESNOREQUIRED as 'Yesnorequired',
	 C.COUNTREQUIRED as 'Countrequired',
	 C.PERIODTYPEREQUIRED as 'Periodtyperequired',
	 C.AMOUNTREQUIRED as 'Amountrequired',
	 C.DATEREQUIRED as 'Daterequired',
	 C.EMPLOYEEREQUIRED as 'Employeerequired',
	 C.TEXTREQUIRED as 'Textrequired',
	 C.PAYFEECODE as 'Payfeecode',
	 C.UPDATEEVENTNO as 'Updateeventno',
	 C.DUEDATEFLAG as 'Duedateflag',
	 C.YESRATENO as 'Yesrateno',
	 C.NORATENO as 'Norateno',
	 C.YESCHECKLISTTYPE as 'Yeschecklisttype',
	 C.NOCHECKLISTTYPE as 'Nochecklisttype',
	 C.INHERITED as 'Inherited',
	 C.NODUEDATEFLAG as 'Noduedateflag',
	 C.NOEVENTNO as 'Noeventno',
	 C.ESTIMATEFLAG as 'Estimateflag',
	 C.DIRECTPAYFLAG as 'Directpayflag',
	 C.SOURCEQUESTION as 'Sourcequestion',
	 C.ANSWERSOURCEYES as 'Answersourceyes',
	 C.ANSWERSOURCENO as 'Answersourceno'
from CCImport_CHECKLISTITEM I 
	right join CHECKLISTITEM C on( C.CRITERIANO=I.CRITERIANO
and  C.QUESTIONNO=I.QUESTIONNO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.QUESTIONNO,
	 I.SEQUENCENO,
	 I.QUESTION,
	 I.YESNOREQUIRED,
	 I.COUNTREQUIRED,
	 I.PERIODTYPEREQUIRED,
	 I.AMOUNTREQUIRED,
	 I.DATEREQUIRED,
	 I.EMPLOYEEREQUIRED,
	 I.TEXTREQUIRED,
	 I.PAYFEECODE,
	 I.UPDATEEVENTNO,
	 I.DUEDATEFLAG,
	 I.YESRATENO,
	 I.NORATENO,
	 I.YESCHECKLISTTYPE,
	 I.NOCHECKLISTTYPE,
	 I.INHERITED,
	 I.NODUEDATEFLAG,
	 I.NOEVENTNO,
	 I.ESTIMATEFLAG,
	 I.DIRECTPAYFLAG,
	 I.SOURCEQUESTION,
	 I.ANSWERSOURCEYES,
	 I.ANSWERSOURCENO,
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
from CCImport_CHECKLISTITEM I 
	left join CHECKLISTITEM C on( C.CRITERIANO=I.CRITERIANO
and  C.QUESTIONNO=I.QUESTIONNO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.QUESTIONNO,
	 I.SEQUENCENO,
	 I.QUESTION,
	 I.YESNOREQUIRED,
	 I.COUNTREQUIRED,
	 I.PERIODTYPEREQUIRED,
	 I.AMOUNTREQUIRED,
	 I.DATEREQUIRED,
	 I.EMPLOYEEREQUIRED,
	 I.TEXTREQUIRED,
	 I.PAYFEECODE,
	 I.UPDATEEVENTNO,
	 I.DUEDATEFLAG,
	 I.YESRATENO,
	 I.NORATENO,
	 I.YESCHECKLISTTYPE,
	 I.NOCHECKLISTTYPE,
	 I.INHERITED,
	 I.NODUEDATEFLAG,
	 I.NOEVENTNO,
	 I.ESTIMATEFLAG,
	 I.DIRECTPAYFLAG,
	 I.SOURCEQUESTION,
	 I.ANSWERSOURCEYES,
	 I.ANSWERSOURCENO,
'U',
	 C.CRITERIANO,
	 C.QUESTIONNO,
	 C.SEQUENCENO,
	 C.QUESTION,
	 C.YESNOREQUIRED,
	 C.COUNTREQUIRED,
	 C.PERIODTYPEREQUIRED,
	 C.AMOUNTREQUIRED,
	 C.DATEREQUIRED,
	 C.EMPLOYEEREQUIRED,
	 C.TEXTREQUIRED,
	 C.PAYFEECODE,
	 C.UPDATEEVENTNO,
	 C.DUEDATEFLAG,
	 C.YESRATENO,
	 C.NORATENO,
	 C.YESCHECKLISTTYPE,
	 C.NOCHECKLISTTYPE,
	 C.INHERITED,
	 C.NODUEDATEFLAG,
	 C.NOEVENTNO,
	 C.ESTIMATEFLAG,
	 C.DIRECTPAYFLAG,
	 C.SOURCEQUESTION,
	 C.ANSWERSOURCEYES,
	 C.ANSWERSOURCENO
from CCImport_CHECKLISTITEM I 
	join CHECKLISTITEM C	on ( C.CRITERIANO=I.CRITERIANO
	and C.QUESTIONNO=I.QUESTIONNO)
where 	( I.SEQUENCENO <>  C.SEQUENCENO OR (I.SEQUENCENO is null and C.SEQUENCENO is not null) 
OR (I.SEQUENCENO is not null and C.SEQUENCENO is null))
	OR 	( I.QUESTION <>  C.QUESTION OR (I.QUESTION is null and C.QUESTION is not null) 
OR (I.QUESTION is not null and C.QUESTION is null))
	OR 	( I.YESNOREQUIRED <>  C.YESNOREQUIRED OR (I.YESNOREQUIRED is null and C.YESNOREQUIRED is not null) 
OR (I.YESNOREQUIRED is not null and C.YESNOREQUIRED is null))
	OR 	( I.COUNTREQUIRED <>  C.COUNTREQUIRED OR (I.COUNTREQUIRED is null and C.COUNTREQUIRED is not null) 
OR (I.COUNTREQUIRED is not null and C.COUNTREQUIRED is null))
	OR 	( I.PERIODTYPEREQUIRED <>  C.PERIODTYPEREQUIRED OR (I.PERIODTYPEREQUIRED is null and C.PERIODTYPEREQUIRED is not null) 
OR (I.PERIODTYPEREQUIRED is not null and C.PERIODTYPEREQUIRED is null))
	OR 	( I.AMOUNTREQUIRED <>  C.AMOUNTREQUIRED OR (I.AMOUNTREQUIRED is null and C.AMOUNTREQUIRED is not null) 
OR (I.AMOUNTREQUIRED is not null and C.AMOUNTREQUIRED is null))
	OR 	( I.DATEREQUIRED <>  C.DATEREQUIRED OR (I.DATEREQUIRED is null and C.DATEREQUIRED is not null) 
OR (I.DATEREQUIRED is not null and C.DATEREQUIRED is null))
	OR 	( I.EMPLOYEEREQUIRED <>  C.EMPLOYEEREQUIRED OR (I.EMPLOYEEREQUIRED is null and C.EMPLOYEEREQUIRED is not null) 
OR (I.EMPLOYEEREQUIRED is not null and C.EMPLOYEEREQUIRED is null))
	OR 	( I.TEXTREQUIRED <>  C.TEXTREQUIRED OR (I.TEXTREQUIRED is null and C.TEXTREQUIRED is not null) 
OR (I.TEXTREQUIRED is not null and C.TEXTREQUIRED is null))
	OR 	( I.PAYFEECODE <>  C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is not null) 
OR (I.PAYFEECODE is not null and C.PAYFEECODE is null))
	OR 	( I.UPDATEEVENTNO <>  C.UPDATEEVENTNO OR (I.UPDATEEVENTNO is null and C.UPDATEEVENTNO is not null) 
OR (I.UPDATEEVENTNO is not null and C.UPDATEEVENTNO is null))
	OR 	( I.DUEDATEFLAG <>  C.DUEDATEFLAG OR (I.DUEDATEFLAG is null and C.DUEDATEFLAG is not null) 
OR (I.DUEDATEFLAG is not null and C.DUEDATEFLAG is null))
	OR 	( I.YESRATENO <>  C.YESRATENO OR (I.YESRATENO is null and C.YESRATENO is not null) 
OR (I.YESRATENO is not null and C.YESRATENO is null))
	OR 	( I.NORATENO <>  C.NORATENO OR (I.NORATENO is null and C.NORATENO is not null) 
OR (I.NORATENO is not null and C.NORATENO is null))
	OR 	( I.YESCHECKLISTTYPE <>  C.YESCHECKLISTTYPE OR (I.YESCHECKLISTTYPE is null and C.YESCHECKLISTTYPE is not null) 
OR (I.YESCHECKLISTTYPE is not null and C.YESCHECKLISTTYPE is null))
	OR 	( I.NOCHECKLISTTYPE <>  C.NOCHECKLISTTYPE OR (I.NOCHECKLISTTYPE is null and C.NOCHECKLISTTYPE is not null) 
OR (I.NOCHECKLISTTYPE is not null and C.NOCHECKLISTTYPE is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
	OR 	( I.NODUEDATEFLAG <>  C.NODUEDATEFLAG OR (I.NODUEDATEFLAG is null and C.NODUEDATEFLAG is not null) 
OR (I.NODUEDATEFLAG is not null and C.NODUEDATEFLAG is null))
	OR 	( I.NOEVENTNO <>  C.NOEVENTNO OR (I.NOEVENTNO is null and C.NOEVENTNO is not null) 
OR (I.NOEVENTNO is not null and C.NOEVENTNO is null))
	OR 	( I.ESTIMATEFLAG <>  C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is not null) 
OR (I.ESTIMATEFLAG is not null and C.ESTIMATEFLAG is null))
	OR 	( I.DIRECTPAYFLAG <>  C.DIRECTPAYFLAG OR (I.DIRECTPAYFLAG is null and C.DIRECTPAYFLAG is not null) 
OR (I.DIRECTPAYFLAG is not null and C.DIRECTPAYFLAG is null))
	OR 	( I.SOURCEQUESTION <>  C.SOURCEQUESTION OR (I.SOURCEQUESTION is null and C.SOURCEQUESTION is not null) 
OR (I.SOURCEQUESTION is not null and C.SOURCEQUESTION is null))
	OR 	( I.ANSWERSOURCEYES <>  C.ANSWERSOURCEYES OR (I.ANSWERSOURCEYES is null and C.ANSWERSOURCEYES is not null) 
OR (I.ANSWERSOURCEYES is not null and C.ANSWERSOURCEYES is null))
	OR 	( I.ANSWERSOURCENO <>  C.ANSWERSOURCENO OR (I.ANSWERSOURCENO is null and C.ANSWERSOURCENO is not null) 
OR (I.ANSWERSOURCENO is not null and C.ANSWERSOURCENO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CHECKLISTITEM]') and xtype='U')
begin
	drop table CCImport_CHECKLISTITEM 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CHECKLISTITEM  to public
go
