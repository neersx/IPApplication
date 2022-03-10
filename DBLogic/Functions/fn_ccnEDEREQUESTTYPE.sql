-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnEDEREQUESTTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnEDEREQUESTTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnEDEREQUESTTYPE.'
	drop function dbo.fn_ccnEDEREQUESTTYPE
	print '**** Creating function dbo.fn_ccnEDEREQUESTTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnEDEREQUESTTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnEDEREQUESTTYPE
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the EDEREQUESTTYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 11 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	9 as TRIPNO, 'EDEREQUESTTYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_EDEREQUESTTYPE I 
	right join EDEREQUESTTYPE C on( C.REQUESTTYPECODE=I.REQUESTTYPECODE)
where I.REQUESTTYPECODE is null
UNION ALL 
select	9, 'EDEREQUESTTYPE', 0, count(*), 0, 0
from CCImport_EDEREQUESTTYPE I 
	left join EDEREQUESTTYPE C on( C.REQUESTTYPECODE=I.REQUESTTYPECODE)
where C.REQUESTTYPECODE is null
UNION ALL 
 select	9, 'EDEREQUESTTYPE', 0, 0, count(*), 0
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
	OR	( I.OUTPUTNOTREQUIRED   <>  C.OUTPUTNOTREQUIRED)
UNION ALL 
 select	9, 'EDEREQUESTTYPE', 0, 0, 0, count(*)
from CCImport_EDEREQUESTTYPE I 
join EDEREQUESTTYPE C	on( C.REQUESTTYPECODE=I.REQUESTTYPECODE)
where (replace( I.REQUESTTYPENAME,char(10),char(13)+char(10)) =  C.REQUESTTYPENAME)
and ( I.REQUESTORNAMETYPE =  C.REQUESTORNAMETYPE OR (I.REQUESTORNAMETYPE is null and C.REQUESTORNAMETYPE is null))
and ( I.TRANSACTIONREASONNO =  C.TRANSACTIONREASONNO OR (I.TRANSACTIONREASONNO is null and C.TRANSACTIONREASONNO is null))
and ( I.UPDATEEVENTNO =  C.UPDATEEVENTNO OR (I.UPDATEEVENTNO is null and C.UPDATEEVENTNO is null))
and ( I.POLICINGNOTREQUIRED =  C.POLICINGNOTREQUIRED)
and ( I.OUTPUTNOTREQUIRED   =  C.OUTPUTNOTREQUIRED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_EDEREQUESTTYPE]') and xtype='U')
begin
	drop table CCImport_EDEREQUESTTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnEDEREQUESTTYPE  to public
go
