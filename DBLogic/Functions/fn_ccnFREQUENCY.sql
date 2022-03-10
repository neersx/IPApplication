-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnFREQUENCY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnFREQUENCY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnFREQUENCY.'
	drop function dbo.fn_ccnFREQUENCY
	print '**** Creating function dbo.fn_ccnFREQUENCY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FREQUENCY]') and xtype='U')
begin
	select * 
	into CCImport_FREQUENCY 
	from FREQUENCY
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnFREQUENCY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnFREQUENCY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FREQUENCY table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'FREQUENCY' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_FREQUENCY I 
	right join FREQUENCY C on( C.FREQUENCYNO=I.FREQUENCYNO)
where I.FREQUENCYNO is null
UNION ALL 
select	2, 'FREQUENCY', 0, count(*), 0, 0
from CCImport_FREQUENCY I 
	left join FREQUENCY C on( C.FREQUENCYNO=I.FREQUENCYNO)
where C.FREQUENCYNO is null
UNION ALL 
 select	2, 'FREQUENCY', 0, 0, count(*), 0
from CCImport_FREQUENCY I 
	join FREQUENCY C	on ( C.FREQUENCYNO=I.FREQUENCYNO)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.FREQUENCY <>  C.FREQUENCY)
	OR 	( I.PERIODTYPE <>  C.PERIODTYPE)
	OR 	( I.FREQUENCYTYPE <>  C.FREQUENCYTYPE)
UNION ALL 
 select	2, 'FREQUENCY', 0, 0, 0, count(*)
from CCImport_FREQUENCY I 
join FREQUENCY C	on( C.FREQUENCYNO=I.FREQUENCYNO)
where ( I.DESCRIPTION =  C.DESCRIPTION)
and ( I.FREQUENCY =  C.FREQUENCY)
and ( I.PERIODTYPE =  C.PERIODTYPE)
and ( I.FREQUENCYTYPE =  C.FREQUENCYTYPE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FREQUENCY]') and xtype='U')
begin
	drop table CCImport_FREQUENCY 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnFREQUENCY  to public
go
