-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_QUANTITYSOURCE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_QUANTITYSOURCE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_QUANTITYSOURCE.'
	drop function dbo.fn_cc_QUANTITYSOURCE
	print '**** Creating function dbo.fn_cc_QUANTITYSOURCE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_QUANTITYSOURCE]') and xtype='U')
begin
	select * 
	into CCImport_QUANTITYSOURCE 
	from QUANTITYSOURCE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_QUANTITYSOURCE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_QUANTITYSOURCE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the QUANTITYSOURCE table
-- CALLED BY :	ip_CopyConfigQUANTITYSOURCE
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
	 null as 'Imported Quantitysourceid',
	 null as 'Imported Source',
	 null as 'Imported Fromeventno',
	 null as 'Imported Untileventno',
	 null as 'Imported Periodtype',
'D' as '-',
	 C.QUANTITYSOURCEID as 'Quantitysourceid',
	 C.SOURCE as 'Source',
	 C.FROMEVENTNO as 'Fromeventno',
	 C.UNTILEVENTNO as 'Untileventno',
	 C.PERIODTYPE as 'Periodtype'
from CCImport_QUANTITYSOURCE I 
	right join QUANTITYSOURCE C on( C.QUANTITYSOURCEID=I.QUANTITYSOURCEID)
where I.QUANTITYSOURCEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.QUANTITYSOURCEID,
	 I.SOURCE,
	 I.FROMEVENTNO,
	 I.UNTILEVENTNO,
	 I.PERIODTYPE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_QUANTITYSOURCE I 
	left join QUANTITYSOURCE C on( C.QUANTITYSOURCEID=I.QUANTITYSOURCEID)
where C.QUANTITYSOURCEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.QUANTITYSOURCEID,
	 I.SOURCE,
	 I.FROMEVENTNO,
	 I.UNTILEVENTNO,
	 I.PERIODTYPE,
'U',
	 C.QUANTITYSOURCEID,
	 C.SOURCE,
	 C.FROMEVENTNO,
	 C.UNTILEVENTNO,
	 C.PERIODTYPE
from CCImport_QUANTITYSOURCE I 
	join QUANTITYSOURCE C	on ( C.QUANTITYSOURCEID=I.QUANTITYSOURCEID)
where 	( I.SOURCE <>  C.SOURCE)
	OR 	( I.FROMEVENTNO <>  C.FROMEVENTNO OR (I.FROMEVENTNO is null and C.FROMEVENTNO is not null) 
OR (I.FROMEVENTNO is not null and C.FROMEVENTNO is null))
	OR 	( I.UNTILEVENTNO <>  C.UNTILEVENTNO OR (I.UNTILEVENTNO is null and C.UNTILEVENTNO is not null) 
OR (I.UNTILEVENTNO is not null and C.UNTILEVENTNO is null))
	OR 	( I.PERIODTYPE <>  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) 
OR (I.PERIODTYPE is not null and C.PERIODTYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_QUANTITYSOURCE]') and xtype='U')
begin
	drop table CCImport_QUANTITYSOURCE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_QUANTITYSOURCE  to public
go
