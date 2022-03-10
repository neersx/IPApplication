-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_PROTECTCODES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_PROTECTCODES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_PROTECTCODES.'
	drop function dbo.fn_cc_PROTECTCODES
	print '**** Creating function dbo.fn_cc_PROTECTCODES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROTECTCODES]') and xtype='U')
begin
	select * 
	into CCImport_PROTECTCODES 
	from PROTECTCODES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_PROTECTCODES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_PROTECTCODES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROTECTCODES table
-- CALLED BY :	ip_CopyConfigPROTECTCODES
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
	 null as 'Imported Protectkey',
	 null as 'Imported Tablecode',
	 null as 'Imported Tabletype',
	 null as 'Imported Eventno',
	 null as 'Imported Caserelationship',
	 null as 'Imported Namerelationship',
	 null as 'Imported Numbertype',
	 null as 'Imported Casetype',
	 null as 'Imported Nametype',
	 null as 'Imported Adjustment',
	 null as 'Imported Texttype',
	 null as 'Imported Family',
'D' as '-',
	 C.PROTECTKEY as 'Protectkey',
	 C.TABLECODE as 'Tablecode',
	 C.TABLETYPE as 'Tabletype',
	 C.EVENTNO as 'Eventno',
	 C.CASERELATIONSHIP as 'Caserelationship',
	 C.NAMERELATIONSHIP as 'Namerelationship',
	 C.NUMBERTYPE as 'Numbertype',
	 C.CASETYPE as 'Casetype',
	 C.NAMETYPE as 'Nametype',
	 C.ADJUSTMENT as 'Adjustment',
	 C.TEXTTYPE as 'Texttype',
	 C.FAMILY as 'Family'
from CCImport_PROTECTCODES I 
	right join PROTECTCODES C on( C.PROTECTKEY=I.PROTECTKEY)
where I.PROTECTKEY is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.PROTECTKEY,
	 I.TABLECODE,
	 I.TABLETYPE,
	 I.EVENTNO,
	 I.CASERELATIONSHIP,
	 I.NAMERELATIONSHIP,
	 I.NUMBERTYPE,
	 I.CASETYPE,
	 I.NAMETYPE,
	 I.ADJUSTMENT,
	 I.TEXTTYPE,
	 I.FAMILY,
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
	 null
from CCImport_PROTECTCODES I 
	left join PROTECTCODES C on( C.PROTECTKEY=I.PROTECTKEY)
where C.PROTECTKEY is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.PROTECTKEY,
	 I.TABLECODE,
	 I.TABLETYPE,
	 I.EVENTNO,
	 I.CASERELATIONSHIP,
	 I.NAMERELATIONSHIP,
	 I.NUMBERTYPE,
	 I.CASETYPE,
	 I.NAMETYPE,
	 I.ADJUSTMENT,
	 I.TEXTTYPE,
	 I.FAMILY,
'U',
	 C.PROTECTKEY,
	 C.TABLECODE,
	 C.TABLETYPE,
	 C.EVENTNO,
	 C.CASERELATIONSHIP,
	 C.NAMERELATIONSHIP,
	 C.NUMBERTYPE,
	 C.CASETYPE,
	 C.NAMETYPE,
	 C.ADJUSTMENT,
	 C.TEXTTYPE,
	 C.FAMILY
from CCImport_PROTECTCODES I 
	join PROTECTCODES C	on ( C.PROTECTKEY=I.PROTECTKEY)
where 	( I.TABLECODE <>  C.TABLECODE OR (I.TABLECODE is null and C.TABLECODE is not null) 
OR (I.TABLECODE is not null and C.TABLECODE is null))
	OR 	( I.TABLETYPE <>  C.TABLETYPE OR (I.TABLETYPE is null and C.TABLETYPE is not null) 
OR (I.TABLETYPE is not null and C.TABLETYPE is null))
	OR 	( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null) 
OR (I.EVENTNO is not null and C.EVENTNO is null))
	OR 	( I.CASERELATIONSHIP <>  C.CASERELATIONSHIP OR (I.CASERELATIONSHIP is null and C.CASERELATIONSHIP is not null) 
OR (I.CASERELATIONSHIP is not null and C.CASERELATIONSHIP is null))
	OR 	( I.NAMERELATIONSHIP <>  C.NAMERELATIONSHIP OR (I.NAMERELATIONSHIP is null and C.NAMERELATIONSHIP is not null) 
OR (I.NAMERELATIONSHIP is not null and C.NAMERELATIONSHIP is null))
	OR 	( I.NUMBERTYPE <>  C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is not null) 
OR (I.NUMBERTYPE is not null and C.NUMBERTYPE is null))
	OR 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.ADJUSTMENT <>  C.ADJUSTMENT OR (I.ADJUSTMENT is null and C.ADJUSTMENT is not null) 
OR (I.ADJUSTMENT is not null and C.ADJUSTMENT is null))
	OR 	( I.TEXTTYPE <>  C.TEXTTYPE OR (I.TEXTTYPE is null and C.TEXTTYPE is not null) 
OR (I.TEXTTYPE is not null and C.TEXTTYPE is null))
	OR 	( I.FAMILY <>  C.FAMILY OR (I.FAMILY is null and C.FAMILY is not null) 
OR (I.FAMILY is not null and C.FAMILY is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROTECTCODES]') and xtype='U')
begin
	drop table CCImport_PROTECTCODES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_PROTECTCODES  to public
go
