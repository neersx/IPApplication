-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_WIPATTRIBUTE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_WIPATTRIBUTE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_WIPATTRIBUTE.'
	drop function dbo.fn_cc_WIPATTRIBUTE
	print '**** Creating function dbo.fn_cc_WIPATTRIBUTE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_WIPATTRIBUTE]') and xtype='U')
begin
	select * 
	into CCImport_WIPATTRIBUTE 
	from WIPATTRIBUTE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_WIPATTRIBUTE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_WIPATTRIBUTE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the WIPATTRIBUTE table
-- CALLED BY :	ip_CopyConfigWIPATTRIBUTE
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
	 null as 'Imported Wipattribute',
	 null as 'Imported Description',
'D' as '-',
	 C.WIPATTRIBUTE as 'Wipattribute',
	 C.DESCRIPTION as 'Description'
from CCImport_WIPATTRIBUTE I 
	right join WIPATTRIBUTE C on( C.WIPATTRIBUTE=I.WIPATTRIBUTE)
where I.WIPATTRIBUTE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.WIPATTRIBUTE,
	 I.DESCRIPTION,
'I',
	 null ,
	 null
from CCImport_WIPATTRIBUTE I 
	left join WIPATTRIBUTE C on( C.WIPATTRIBUTE=I.WIPATTRIBUTE)
where C.WIPATTRIBUTE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.WIPATTRIBUTE,
	 I.DESCRIPTION,
'U',
	 C.WIPATTRIBUTE,
	 C.DESCRIPTION
from CCImport_WIPATTRIBUTE I 
	join WIPATTRIBUTE C	on ( C.WIPATTRIBUTE=I.WIPATTRIBUTE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_WIPATTRIBUTE]') and xtype='U')
begin
	drop table CCImport_WIPATTRIBUTE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_WIPATTRIBUTE  to public
go
