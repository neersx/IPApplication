-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_COUNTRYFLAGS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_COUNTRYFLAGS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_COUNTRYFLAGS.'
	drop function dbo.fn_cc_COUNTRYFLAGS
	print '**** Creating function dbo.fn_cc_COUNTRYFLAGS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYFLAGS]') and xtype='U')
begin
	select * 
	into CCImport_COUNTRYFLAGS 
	from COUNTRYFLAGS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_COUNTRYFLAGS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_COUNTRYFLAGS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the COUNTRYFLAGS table
-- CALLED BY :	ip_CopyConfigCOUNTRYFLAGS
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
	 null as 'Imported Countrycode',
	 null as 'Imported Flagnumber',
	 null as 'Imported Flagname',
	 null as 'Imported Nationalallowed',
	 null as 'Imported Restrictremovalflg',
	 null as 'Imported Profilename',
	 null as 'Imported Status',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.FLAGNUMBER as 'Flagnumber',
	 C.FLAGNAME as 'Flagname',
	 C.NATIONALALLOWED as 'Nationalallowed',
	 C.RESTRICTREMOVALFLG as 'Restrictremovalflg',
	 C.PROFILENAME as 'Profilename',
	 C.STATUS as 'Status'
from CCImport_COUNTRYFLAGS I 
	right join COUNTRYFLAGS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.FLAGNUMBER,
	 I.FLAGNAME,
	 I.NATIONALALLOWED,
	 I.RESTRICTREMOVALFLG,
	 I.PROFILENAME,
	 I.STATUS,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_COUNTRYFLAGS I 
	left join COUNTRYFLAGS C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.FLAGNUMBER=I.FLAGNUMBER)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.FLAGNUMBER,
	 I.FLAGNAME,
	 I.NATIONALALLOWED,
	 I.RESTRICTREMOVALFLG,
	 I.PROFILENAME,
	 I.STATUS,
'U',
	 C.COUNTRYCODE,
	 C.FLAGNUMBER,
	 C.FLAGNAME,
	 C.NATIONALALLOWED,
	 C.RESTRICTREMOVALFLG,
	 C.PROFILENAME,
	 C.STATUS
from CCImport_COUNTRYFLAGS I 
	join COUNTRYFLAGS C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.FLAGNUMBER=I.FLAGNUMBER)
where 	( I.FLAGNAME <>  C.FLAGNAME OR (I.FLAGNAME is null and C.FLAGNAME is not null) 
OR (I.FLAGNAME is not null and C.FLAGNAME is null))
	OR 	( I.NATIONALALLOWED <>  C.NATIONALALLOWED OR (I.NATIONALALLOWED is null and C.NATIONALALLOWED is not null) 
OR (I.NATIONALALLOWED is not null and C.NATIONALALLOWED is null))
	OR 	( I.RESTRICTREMOVALFLG <>  C.RESTRICTREMOVALFLG OR (I.RESTRICTREMOVALFLG is null and C.RESTRICTREMOVALFLG is not null) 
OR (I.RESTRICTREMOVALFLG is not null and C.RESTRICTREMOVALFLG is null))
	OR 	( I.PROFILENAME <>  C.PROFILENAME OR (I.PROFILENAME is null and C.PROFILENAME is not null) 
OR (I.PROFILENAME is not null and C.PROFILENAME is null))
	OR 	( I.STATUS <>  C.STATUS)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_COUNTRYFLAGS]') and xtype='U')
begin
	drop table CCImport_COUNTRYFLAGS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_COUNTRYFLAGS  to public
go
