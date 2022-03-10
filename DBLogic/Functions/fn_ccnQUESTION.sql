-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnQUESTION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnQUESTION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnQUESTION.'
	drop function dbo.fn_ccnQUESTION
	print '**** Creating function dbo.fn_ccnQUESTION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_QUESTION]') and xtype='U')
begin
	select * 
	into CCImport_QUESTION 
	from QUESTION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnQUESTION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnQUESTION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the QUESTION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'QUESTION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_QUESTION I 
	right join QUESTION C on( C.QUESTIONNO=I.QUESTIONNO)
where I.QUESTIONNO is null
UNION ALL 
select	2, 'QUESTION', 0, count(*), 0, 0
from CCImport_QUESTION I 
	left join QUESTION C on( C.QUESTIONNO=I.QUESTIONNO)
where C.QUESTIONNO is null
UNION ALL 
 select	2, 'QUESTION', 0, 0, count(*), 0
from CCImport_QUESTION I 
	join QUESTION C	on ( C.QUESTIONNO=I.QUESTIONNO)
where 	( I.IMPORTANCELEVEL <>  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is not null) 
OR (I.IMPORTANCELEVEL is not null and C.IMPORTANCELEVEL is null))
	OR 	( I.QUESTIONCODE <>  C.QUESTIONCODE OR (I.QUESTIONCODE is null and C.QUESTIONCODE is not null) 
OR (I.QUESTIONCODE is not null and C.QUESTIONCODE is null))
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
	OR 	( I.EMPLOYEEREQUIRED <>  C.EMPLOYEEREQUIRED OR (I.EMPLOYEEREQUIRED is null and C.EMPLOYEEREQUIRED is not null) 
OR (I.EMPLOYEEREQUIRED is not null and C.EMPLOYEEREQUIRED is null))
	OR 	( I.TEXTREQUIRED <>  C.TEXTREQUIRED OR (I.TEXTREQUIRED is null and C.TEXTREQUIRED is not null) 
OR (I.TEXTREQUIRED is not null and C.TEXTREQUIRED is null))
	OR 	( I.TABLETYPE <>  C.TABLETYPE OR (I.TABLETYPE is null and C.TABLETYPE is not null) 
OR (I.TABLETYPE is not null and C.TABLETYPE is null))
UNION ALL 
 select	2, 'QUESTION', 0, 0, 0, count(*)
from CCImport_QUESTION I 
join QUESTION C	on( C.QUESTIONNO=I.QUESTIONNO)
where ( I.IMPORTANCELEVEL =  C.IMPORTANCELEVEL OR (I.IMPORTANCELEVEL is null and C.IMPORTANCELEVEL is null))
and ( I.QUESTIONCODE =  C.QUESTIONCODE OR (I.QUESTIONCODE is null and C.QUESTIONCODE is null))
and ( I.QUESTION =  C.QUESTION OR (I.QUESTION is null and C.QUESTION is null))
and ( I.YESNOREQUIRED =  C.YESNOREQUIRED OR (I.YESNOREQUIRED is null and C.YESNOREQUIRED is null))
and ( I.COUNTREQUIRED =  C.COUNTREQUIRED OR (I.COUNTREQUIRED is null and C.COUNTREQUIRED is null))
and ( I.PERIODTYPEREQUIRED =  C.PERIODTYPEREQUIRED OR (I.PERIODTYPEREQUIRED is null and C.PERIODTYPEREQUIRED is null))
and ( I.AMOUNTREQUIRED =  C.AMOUNTREQUIRED OR (I.AMOUNTREQUIRED is null and C.AMOUNTREQUIRED is null))
and ( I.EMPLOYEEREQUIRED =  C.EMPLOYEEREQUIRED OR (I.EMPLOYEEREQUIRED is null and C.EMPLOYEEREQUIRED is null))
and ( I.TEXTREQUIRED =  C.TEXTREQUIRED OR (I.TEXTREQUIRED is null and C.TEXTREQUIRED is null))
and ( I.TABLETYPE =  C.TABLETYPE OR (I.TABLETYPE is null and C.TABLETYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_QUESTION]') and xtype='U')
begin
	drop table CCImport_QUESTION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnQUESTION  to public
go
