-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EDERULERELATEDCASE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EDERULERELATEDCASE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EDERULERELATEDCASE.'
	drop function dbo.fn_cc_EDERULERELATEDCASE
	print '**** Creating function dbo.fn_cc_EDERULERELATEDCASE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULERELATEDCASE]') and xtype='U')
begin
	select * 
	into CCImport_EDERULERELATEDCASE 
	from EDERULERELATEDCASE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EDERULERELATEDCASE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EDERULERELATEDCASE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the EDERULERELATEDCASE table
-- CALLED BY :	ip_CopyConfigEDERULERELATEDCASE
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
	 null as 'Imported Relationship',
	 null as 'Imported Officialnumber',
	 null as 'Imported Prioritydate',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.RELATIONSHIP as 'Relationship',
	 C.OFFICIALNUMBER as 'Officialnumber',
	 C.PRIORITYDATE as 'Prioritydate'
from CCImport_EDERULERELATEDCASE I 
	right join EDERULERELATEDCASE C on( C.CRITERIANO=I.CRITERIANO
and  C.RELATIONSHIP=I.RELATIONSHIP)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.RELATIONSHIP,
	 I.OFFICIALNUMBER,
	 I.PRIORITYDATE,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EDERULERELATEDCASE I 
	left join EDERULERELATEDCASE C on( C.CRITERIANO=I.CRITERIANO
and  C.RELATIONSHIP=I.RELATIONSHIP)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.RELATIONSHIP,
	 I.OFFICIALNUMBER,
	 I.PRIORITYDATE,
'U',
	 C.CRITERIANO,
	 C.RELATIONSHIP,
	 C.OFFICIALNUMBER,
	 C.PRIORITYDATE
from CCImport_EDERULERELATEDCASE I 
	join EDERULERELATEDCASE C	on ( C.CRITERIANO=I.CRITERIANO
	and C.RELATIONSHIP=I.RELATIONSHIP)
where 	( I.OFFICIALNUMBER <>  C.OFFICIALNUMBER OR (I.OFFICIALNUMBER is null and C.OFFICIALNUMBER is not null) 
OR (I.OFFICIALNUMBER is not null and C.OFFICIALNUMBER is null))
	OR 	( I.PRIORITYDATE <>  C.PRIORITYDATE OR (I.PRIORITYDATE is null and C.PRIORITYDATE is not null) 
OR (I.PRIORITYDATE is not null and C.PRIORITYDATE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDERULERELATEDCASE]') and xtype='U')
begin
	drop table CCImport_EDERULERELATEDCASE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EDERULERELATEDCASE  to public
go
