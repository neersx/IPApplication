-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FREQUENCY
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FREQUENCY]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FREQUENCY.'
	drop function dbo.fn_cc_FREQUENCY
	print '**** Creating function dbo.fn_cc_FREQUENCY...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FREQUENCY]') and xtype='U')
begin
	select * 
	into CCImport_FREQUENCY 
	from FREQUENCY
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_FREQUENCY
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FREQUENCY
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FREQUENCY table
-- CALLED BY :	ip_CopyConfigFREQUENCY
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
	 null as 'Imported Frequencyno',
	 null as 'Imported Description',
	 null as 'Imported Frequency',
	 null as 'Imported Periodtype',
	 null as 'Imported Frequencytype',
'D' as '-',
	 C.FREQUENCYNO as 'Frequencyno',
	 C.DESCRIPTION as 'Description',
	 C.FREQUENCY as 'Frequency',
	 C.PERIODTYPE as 'Periodtype',
	 C.FREQUENCYTYPE as 'Frequencytype'
from CCImport_FREQUENCY I 
	right join FREQUENCY C on( C.FREQUENCYNO=I.FREQUENCYNO)
where I.FREQUENCYNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.FREQUENCYNO,
	 I.DESCRIPTION,
	 I.FREQUENCY,
	 I.PERIODTYPE,
	 I.FREQUENCYTYPE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_FREQUENCY I 
	left join FREQUENCY C on( C.FREQUENCYNO=I.FREQUENCYNO)
where C.FREQUENCYNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.FREQUENCYNO,
	 I.DESCRIPTION,
	 I.FREQUENCY,
	 I.PERIODTYPE,
	 I.FREQUENCYTYPE,
'U',
	 C.FREQUENCYNO,
	 C.DESCRIPTION,
	 C.FREQUENCY,
	 C.PERIODTYPE,
	 C.FREQUENCYTYPE
from CCImport_FREQUENCY I 
	join FREQUENCY C	on ( C.FREQUENCYNO=I.FREQUENCYNO)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.FREQUENCY <>  C.FREQUENCY)
	OR 	( I.PERIODTYPE <>  C.PERIODTYPE)
	OR 	( I.FREQUENCYTYPE <>  C.FREQUENCYTYPE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FREQUENCY]') and xtype='U')
begin
	drop table CCImport_FREQUENCY 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FREQUENCY  to public
go
