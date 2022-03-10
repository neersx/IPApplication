-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_EDEREQUESTTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_EDEREQUESTTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_EDEREQUESTTYPE.'
	drop function dbo.fn_cc_EDEREQUESTTYPE
	print '**** Creating function dbo.fn_cc_EDEREQUESTTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_EDEREQUESTTYPE]') and xtype='U')
begin
	select * 
	into CCImport_EDEREQUESTTYPE 
	from EDEREQUESTTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_EDEREQUESTTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_EDEREQUESTTYPE
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the EDEREQUESTTYPE table
-- CALLED BY :	ip_CopyConfigEDEREQUESTTYPE
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 03 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Requesttypecode',
	 null as 'Imported Requesttypename',
	 null as 'Imported Requestornametype',
	 null as 'Imported Transactionreasonno',
	 null as 'Imported Updateeventno',
	 null as 'Imported Policingnotrequired',
	 null as 'Imported Outputnotrequired',
	'D' as '-',
	 C.REQUESTTYPECODE as 'Requesttypecode',
	 C.REQUESTTYPENAME as 'Requesttypename',
	 C.REQUESTORNAMETYPE as 'Requestornametype',
	 C.TRANSACTIONREASONNO as 'Transactionreasonno',
	 C.UPDATEEVENTNO as 'Updateeventno',
	 C.POLICINGNOTREQUIRED as 'Policingnotrequired',
	 C.OUTPUTNOTREQUIRED as 'Outputnotrequired'
from CCImport_EDEREQUESTTYPE I 
	right join EDEREQUESTTYPE C on( C.REQUESTTYPECODE=I.REQUESTTYPECODE)
where I.REQUESTTYPECODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.REQUESTTYPECODE,
	 I.REQUESTTYPENAME,
	 I.REQUESTORNAMETYPE,
	 I.TRANSACTIONREASONNO,
	 I.UPDATEEVENTNO,
	 I.POLICINGNOTREQUIRED,
	 I.OUTPUTNOTREQUIRED,
	'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_EDEREQUESTTYPE I 
	left join EDEREQUESTTYPE C on( C.REQUESTTYPECODE=I.REQUESTTYPECODE)
where C.REQUESTTYPECODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.REQUESTTYPECODE,
	 I.REQUESTTYPENAME,
	 I.REQUESTORNAMETYPE,
	 I.TRANSACTIONREASONNO,
	 I.UPDATEEVENTNO,
	 I.POLICINGNOTREQUIRED,
	 I.OUTPUTNOTREQUIRED,
	'U',
	 C.REQUESTTYPECODE,
	 C.REQUESTTYPENAME,
	 C.REQUESTORNAMETYPE,
	 C.TRANSACTIONREASONNO,
	 C.UPDATEEVENTNO,
	 C.POLICINGNOTREQUIRED,
	 C.OUTPUTNOTREQUIRED
from CCImport_EDEREQUESTTYPE I 
	join EDEREQUESTTYPE C	on ( C.REQUESTTYPECODE=I.REQUESTTYPECODE)
where 	(replace( I.REQUESTTYPENAME,char(10),char(13)+char(10)) <>  C.REQUESTTYPENAME)
	OR 	( I.REQUESTORNAMETYPE <>  C.REQUESTORNAMETYPE OR (I.REQUESTORNAMETYPE is null and C.REQUESTORNAMETYPE is not null) 
OR (I.REQUESTORNAMETYPE is not null and C.REQUESTORNAMETYPE is null))
	OR 	( I.TRANSACTIONREASONNO <>  C.TRANSACTIONREASONNO OR (I.TRANSACTIONREASONNO is null and C.TRANSACTIONREASONNO is not null) 
OR (I.TRANSACTIONREASONNO is not null and C.TRANSACTIONREASONNO is null))
	OR 	( I.UPDATEEVENTNO <>  C.UPDATEEVENTNO OR (I.UPDATEEVENTNO is null and C.UPDATEEVENTNO is not null) 
OR (I.UPDATEEVENTNO is not null and C.UPDATEEVENTNO is null))
	OR 	( I.POLICINGNOTREQUIRED <>  C.POLICINGNOTREQUIRED)
	OR 	( I.OUTPUTNOTREQUIRED   <>  C.OUTPUTNOTREQUIRED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDEREQUESTTYPE]') and xtype='U')
begin
	drop table CCImport_EDEREQUESTTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_EDEREQUESTTYPE  to public
go
