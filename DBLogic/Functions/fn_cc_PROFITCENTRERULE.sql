-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PROFITCENTRERULE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PROFITCENTRERULE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PROFITCENTRERULE.'
	drop function dbo.fn_cc_PROFITCENTRERULE
	print '**** Creating function dbo.fn_cc_PROFITCENTRERULE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROFITCENTRERULE]') and xtype='U')
begin
	select * 
	into CCImport_PROFITCENTRERULE 
	from PROFITCENTRERULE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PROFITCENTRERULE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PROFITCENTRERULE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROFITCENTRERULE table
-- CALLED BY :	ip_CopyConfigPROFITCENTRERULE
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
	 null as 'Imported Analysiscode',
	 null as 'Imported Profitcentrecode',
'D' as '-',
	 C.ANALYSISCODE as 'Analysiscode',
	 C.PROFITCENTRECODE as 'Profitcentrecode'
from CCImport_PROFITCENTRERULE I 
	right join PROFITCENTRERULE C on( C.ANALYSISCODE=I.ANALYSISCODE
and  C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where I.ANALYSISCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ANALYSISCODE,
	 I.PROFITCENTRECODE,
'I',
	 null ,
	 null
from CCImport_PROFITCENTRERULE I 
	left join PROFITCENTRERULE C on( C.ANALYSISCODE=I.ANALYSISCODE
and  C.PROFITCENTRECODE=I.PROFITCENTRECODE)
where C.ANALYSISCODE is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROFITCENTRERULE]') and xtype='U')
begin
	drop table CCImport_PROFITCENTRERULE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PROFITCENTRERULE  to public
go
