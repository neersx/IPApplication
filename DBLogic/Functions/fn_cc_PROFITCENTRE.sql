-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PROFITCENTRE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PROFITCENTRE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PROFITCENTRE.'
	drop function dbo.fn_cc_PROFITCENTRE
	print '**** Creating function dbo.fn_cc_PROFITCENTRE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFITCENTRE]') and xtype='U')
begin
	select * 
	into CCImport_PROFITCENTRE 
	from PROFITCENTRE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PROFITCENTRE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PROFITCENTRE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFITCENTRE table
-- CALLED BY :	ip_CopyConfigPROFITCENTRE
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
	 null as 'Imported Profitcentrecode',
	 null as 'Imported Entityno',
	 null as 'Imported Description',
	 null as 'Imported Includeonlywip',
'D' as '-',
	 C.PROFITCENTRECODE as 'Profitcentrecode',
	 C.ENTITYNO as 'Entityno',
	 C.DESCRIPTION as 'Description',
	 C.INCLUDEONLYWIP as 'Includeonlywip'
from CCImport_PROFITCENTRE I 
	right join PROFITCENTRE C on( C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where I.PROFITCENTRECODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PROFITCENTRECODE,
	 I.ENTITYNO,
	 I.DESCRIPTION,
	 I.INCLUDEONLYWIP,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_PROFITCENTRE I 
	left join PROFITCENTRE C on( C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where C.PROFITCENTRECODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.PROFITCENTRECODE,
	 I.ENTITYNO,
	 I.DESCRIPTION,
	 I.INCLUDEONLYWIP,
'U',
	 C.PROFITCENTRECODE,
	 C.ENTITYNO,
	 C.DESCRIPTION,
	 C.INCLUDEONLYWIP
from CCImport_PROFITCENTRE I 
	join PROFITCENTRE C	on ( C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where 	( I.ENTITYNO <>  C.ENTITYNO)
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.INCLUDEONLYWIP <>  C.INCLUDEONLYWIP OR (I.INCLUDEONLYWIP is null and C.INCLUDEONLYWIP is not null) 
OR (I.INCLUDEONLYWIP is not null and C.INCLUDEONLYWIP is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFITCENTRE]') and xtype='U')
begin
	drop table CCImport_PROFITCENTRE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PROFITCENTRE  to public
go
