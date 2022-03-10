-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EDERULEOFFICIALNUM_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EDERULEOFFICIALNUM_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EDERULEOFFICIALNUM_.'
	drop function dbo.fn_cc_EDERULEOFFICIALNUM_
	print '**** Creating function dbo.fn_cc_EDERULEOFFICIALNUM_...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULEOFFICIALNUMBER]') and xtype='U')
begin
	select * 
	into CCImport_EDERULEOFFICIALNUMBER 
	from EDERULEOFFICIALNUMBER
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EDERULEOFFICIALNUM_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EDERULEOFFICIALNUM_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULEOFFICIALNUMBER table
-- CALLED BY :	ip_CopyConfigEDERULEOFFICIALNUM_
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
	 null as 'Imported Numbertype',
	 null as 'Imported Officialnumber',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.NUMBERTYPE as 'Numbertype',
	 C.OFFICIALNUMBER as 'Officialnumber'
from CCImport_EDERULEOFFICIALNUMBER I 
	right join EDERULEOFFICIALNUMBER C on( C.CRITERIANO=I.CRITERIANO
and  C.NUMBERTYPE=I.NUMBERTYPE)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.NUMBERTYPE,
	 I.OFFICIALNUMBER,
'I',
	 null ,
	 null ,
	 null
from CCImport_EDERULEOFFICIALNUMBER I 
	left join EDERULEOFFICIALNUMBER C on( C.CRITERIANO=I.CRITERIANO
and  C.NUMBERTYPE=I.NUMBERTYPE)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.NUMBERTYPE,
	 I.OFFICIALNUMBER,
'U',
	 C.CRITERIANO,
	 C.NUMBERTYPE,
	 C.OFFICIALNUMBER
from CCImport_EDERULEOFFICIALNUMBER I 
	join EDERULEOFFICIALNUMBER C	on ( C.CRITERIANO=I.CRITERIANO
	and C.NUMBERTYPE=I.NUMBERTYPE)
where 	( I.OFFICIALNUMBER <>  C.OFFICIALNUMBER OR (I.OFFICIALNUMBER is null and C.OFFICIALNUMBER is not null) 
OR (I.OFFICIALNUMBER is not null and C.OFFICIALNUMBER is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULEOFFICIALNUMBER]') and xtype='U')
begin
	drop table CCImport_EDERULEOFFICIALNUMBER 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EDERULEOFFICIALNUM_  to public
go
