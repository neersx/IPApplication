-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_NAMETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_NAMETYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_NAMETYPE.'
	drop function dbo.fn_cc_NAMETYPE
	print '**** Creating function dbo.fn_cc_NAMETYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_NAMETYPE]') and xtype='U')
begin
	select * 
	into CCImport_NAMETYPE 
	from NAMETYPE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION [dbo].[fn_cc_NAMETYPE]
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_NAMETYPE
-- VERSION :	5
-- DESCRIPTION:	The SELECT to display of imported data for the NAMETYPE table
-- CALLED BY :	ip_CopyConfigNAMETYPE
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 03 Apr 2017	MF	71020	2	New columns added.
-- 29 Apr 2019	MF	DR-41987 3	New Columns.
-- 29 Apr 2019	MF	DR-41987 4	New Column. NAMETYPE.NATIONALITYFLAG
-- 19 Dec 2019	MF	DR-55248 5	Looks like a merge problem.  Reimplemented NAMETYPE.NATIONALITYFLAG.
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Nametype',
	 null as 'Imported Description',
	 null as 'Imported Pathnametype',
	 null as 'Imported Pathrelationship',
	 null as 'Imported Hierarchyflag',
	 null as 'Imported Mandatoryflag',
	 null as 'Imported Keepstreetflag',
	 null as 'Imported Columnflags',
	 null as 'Imported Maximumallowed',
	 null as 'Imported Picklistflags',
	 null as 'Imported Shownamecode',
	 null as 'Imported Defaultnameno',
	 null as 'Imported Namerestrictflag',
	 null as 'Imported Changeeventno',
	 null as 'Imported Futurenametype',
	 null as 'Imported Usehomenamerel',
	 null as 'Imported Updatefromparent',
	 null as 'Imported Oldnametype',
	 null as 'Imported Bulkentryflag',
	 null as 'Imported Kottexttype',
	 null as 'Imported Program',
	 null as 'Imported Ethicalwall',
	 null as 'Imported Priorityorder',
	 null as 'Imported Nationalityflag',
	'D' as '-',
	 C.NAMETYPE as 'Nametype',
	 C.DESCRIPTION as 'Description',
	 C.PATHNAMETYPE as 'Pathnametype',
	 C.PATHRELATIONSHIP as 'Pathrelationship',
	 C.HIERARCHYFLAG as 'Hierarchyflag',
	 C.MANDATORYFLAG as 'Mandatoryflag',
	 C.KEEPSTREETFLAG as 'Keepstreetflag',
	 C.COLUMNFLAGS as 'Columnflags',
	 C.MAXIMUMALLOWED as 'Maximumallowed',
	 C.PICKLISTFLAGS as 'Picklistflags',
	 C.SHOWNAMECODE as 'Shownamecode',
	 C.DEFAULTNAMENO as 'Defaultnameno',
	 C.NAMERESTRICTFLAG as 'Namerestrictflag',
	 C.CHANGEEVENTNO as 'Changeeventno',
	 C.FUTURENAMETYPE as 'Futurenametype',
	 C.USEHOMENAMEREL as 'Usehomenamerel',
	 C.UPDATEFROMPARENT as 'Updatefromparent',
	 C.OLDNAMETYPE as 'Oldnametype',
	 C.BULKENTRYFLAG as 'Bulkentryflag',
	 C.KOTTEXTTYPE as 'Kottexttype',
	 C.PROGRAM as 'Program',
	 C.ETHICALWALL as 'Ethicalwall',
	 C.PRIORITYORDER as 'Priorityorder',
	 C.NATIONALITYFLAG as 'Nationalityflag'
from CCImport_NAMETYPE I 
	right join NAMETYPE C on( C.NAMETYPE=I.NAMETYPE)
where I.NAMETYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.NAMETYPE,
	 I.DESCRIPTION,
	 I.PATHNAMETYPE,
	 I.PATHRELATIONSHIP,
	 I.HIERARCHYFLAG,
	 I.MANDATORYFLAG,
	 I.KEEPSTREETFLAG,
	 I.COLUMNFLAGS,
	 I.MAXIMUMALLOWED,
	 I.PICKLISTFLAGS,
	 I.SHOWNAMECODE,
	 I.DEFAULTNAMENO,
	 I.NAMERESTRICTFLAG,
	 I.CHANGEEVENTNO,
	 I.FUTURENAMETYPE,
	 I.USEHOMENAMEREL,
	 I.UPDATEFROMPARENT,
	 I.OLDNAMETYPE,
	 I.BULKENTRYFLAG,
	 I.KOTTEXTTYPE,
	 I.PROGRAM,
	 I.ETHICALWALL,
	 I.PRIORITYORDER,
	 I.NATIONALITYFLAG,
	'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_NAMETYPE I 
	left join NAMETYPE C on( C.NAMETYPE=I.NAMETYPE)
where C.NAMETYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.NAMETYPE,
	 I.DESCRIPTION,
	 I.PATHNAMETYPE,
	 I.PATHRELATIONSHIP,
	 I.HIERARCHYFLAG,
	 I.MANDATORYFLAG,
	 I.KEEPSTREETFLAG,
	 I.COLUMNFLAGS,
	 I.MAXIMUMALLOWED,
	 I.PICKLISTFLAGS,
	 I.SHOWNAMECODE,
	 I.DEFAULTNAMENO,
	 I.NAMERESTRICTFLAG,
	 I.CHANGEEVENTNO,
	 I.FUTURENAMETYPE,
	 I.USEHOMENAMEREL,
	 I.UPDATEFROMPARENT,
	 I.OLDNAMETYPE,
	 I.BULKENTRYFLAG,
	 I.KOTTEXTTYPE,
	 I.PROGRAM,
	 I.ETHICALWALL,
	 I.PRIORITYORDER,
	 I.NATIONALITYFLAG,
	'U',
	 C.NAMETYPE,
	 C.DESCRIPTION,
	 C.PATHNAMETYPE,
	 C.PATHRELATIONSHIP,
	 C.HIERARCHYFLAG,
	 C.MANDATORYFLAG,
	 C.KEEPSTREETFLAG,
	 C.COLUMNFLAGS,
	 C.MAXIMUMALLOWED,
	 C.PICKLISTFLAGS,
	 C.SHOWNAMECODE,
	 C.DEFAULTNAMENO,
	 C.NAMERESTRICTFLAG,
	 C.CHANGEEVENTNO,
	 C.FUTURENAMETYPE,
	 C.USEHOMENAMEREL,
	 C.UPDATEFROMPARENT,
	 C.OLDNAMETYPE,
	 C.BULKENTRYFLAG,
	 C.KOTTEXTTYPE,
	 C.PROGRAM,
	 C.ETHICALWALL,
	 C.PRIORITYORDER,
	 C.NATIONALITYFLAG
from CCImport_NAMETYPE I 
	join NAMETYPE C	on ( C.NAMETYPE=I.NAMETYPE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.PATHNAMETYPE <>  C.PATHNAMETYPE OR (I.PATHNAMETYPE is null and C.PATHNAMETYPE is not null) 
OR (I.PATHNAMETYPE is not null and C.PATHNAMETYPE is null))
	OR 	( I.PATHRELATIONSHIP <>  C.PATHRELATIONSHIP OR (I.PATHRELATIONSHIP is null and C.PATHRELATIONSHIP is not null) 
OR (I.PATHRELATIONSHIP is not null and C.PATHRELATIONSHIP is null))
	OR 	( I.HIERARCHYFLAG <>  C.HIERARCHYFLAG OR (I.HIERARCHYFLAG is null and C.HIERARCHYFLAG is not null) 
OR (I.HIERARCHYFLAG is not null and C.HIERARCHYFLAG is null))
	OR 	( I.MANDATORYFLAG <>  C.MANDATORYFLAG OR (I.MANDATORYFLAG is null and C.MANDATORYFLAG is not null) 
OR (I.MANDATORYFLAG is not null and C.MANDATORYFLAG is null))
	OR 	( I.KEEPSTREETFLAG <>  C.KEEPSTREETFLAG OR (I.KEEPSTREETFLAG is null and C.KEEPSTREETFLAG is not null) 
OR (I.KEEPSTREETFLAG is not null and C.KEEPSTREETFLAG is null))
	OR 	( I.COLUMNFLAGS <>  C.COLUMNFLAGS OR (I.COLUMNFLAGS is null and C.COLUMNFLAGS is not null) 
OR (I.COLUMNFLAGS is not null and C.COLUMNFLAGS is null))
	OR 	( I.MAXIMUMALLOWED <>  C.MAXIMUMALLOWED OR (I.MAXIMUMALLOWED is null and C.MAXIMUMALLOWED is not null) 
OR (I.MAXIMUMALLOWED is not null and C.MAXIMUMALLOWED is null))
	OR 	( I.PICKLISTFLAGS <>  C.PICKLISTFLAGS OR (I.PICKLISTFLAGS is null and C.PICKLISTFLAGS is not null) 
OR (I.PICKLISTFLAGS is not null and C.PICKLISTFLAGS is null))
	OR 	( I.SHOWNAMECODE <>  C.SHOWNAMECODE OR (I.SHOWNAMECODE is null and C.SHOWNAMECODE is not null) 
OR (I.SHOWNAMECODE is not null and C.SHOWNAMECODE is null))
	OR 	( I.DEFAULTNAMENO <>  C.DEFAULTNAMENO OR (I.DEFAULTNAMENO is null and C.DEFAULTNAMENO is not null) 
OR (I.DEFAULTNAMENO is not null and C.DEFAULTNAMENO is null))
	OR 	( I.NAMERESTRICTFLAG <>  C.NAMERESTRICTFLAG OR (I.NAMERESTRICTFLAG is null and C.NAMERESTRICTFLAG is not null) 
OR (I.NAMERESTRICTFLAG is not null and C.NAMERESTRICTFLAG is null))
	OR 	( I.CHANGEEVENTNO <>  C.CHANGEEVENTNO OR (I.CHANGEEVENTNO is null and C.CHANGEEVENTNO is not null) 
OR (I.CHANGEEVENTNO is not null and C.CHANGEEVENTNO is null))
	OR 	( I.FUTURENAMETYPE <>  C.FUTURENAMETYPE OR (I.FUTURENAMETYPE is null and C.FUTURENAMETYPE is not null) 
OR (I.FUTURENAMETYPE is not null and C.FUTURENAMETYPE is null))
	OR 	( I.USEHOMENAMEREL <>  C.USEHOMENAMEREL)
	OR 	( I.UPDATEFROMPARENT <>  C.UPDATEFROMPARENT)
	OR 	( I.OLDNAMETYPE <>  C.OLDNAMETYPE OR (I.OLDNAMETYPE is null and C.OLDNAMETYPE is not null) 
OR (I.OLDNAMETYPE is not null and C.OLDNAMETYPE is null))
	OR 	( I.BULKENTRYFLAG <>  C.BULKENTRYFLAG OR (I.BULKENTRYFLAG is null and C.BULKENTRYFLAG is not null) 
OR (I.BULKENTRYFLAG is not null and C.BULKENTRYFLAG is null))
	OR 	( I.KOTTEXTTYPE <>  C.KOTTEXTTYPE OR (I.KOTTEXTTYPE is null and C.KOTTEXTTYPE is not null) 
OR (I.KOTTEXTTYPE is not null and C.KOTTEXTTYPE is null))
	OR 	( I.PROGRAM <>  C.PROGRAM OR (I.PROGRAM is null and C.PROGRAM is not null) 
OR (I.PROGRAM is not null and C.PROGRAM is null))
	OR 	( I.ETHICALWALL <>  C.ETHICALWALL OR (I.ETHICALWALL is null and C.ETHICALWALL is not null) 
OR (I.ETHICALWALL is not null and C.ETHICALWALL is null))
	OR 	( I.PRIORITYORDER <>  C.PRIORITYORDER OR (I.PRIORITYORDER is null and C.PRIORITYORDER is not null) 
OR (I.PRIORITYORDER is not null and C.PRIORITYORDER is null))
	OR 	( I.NATIONALITYFLAG <>  C.NATIONALITYFLAG OR (I.NATIONALITYFLAG is null and C.NATIONALITYFLAG is not null) 
OR (I.NATIONALITYFLAG is not null and C.NATIONALITYFLAG is null))



go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_NAMETYPE]') and xtype='U')
begin
	drop table CCImport_NAMETYPE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_NAMETYPE  to public
go
