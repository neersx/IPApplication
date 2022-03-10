-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TRANSACTIONREASON
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TRANSACTIONREASON]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TRANSACTIONREASON.'
	drop function dbo.fn_cc_TRANSACTIONREASON
	print '**** Creating function dbo.fn_cc_TRANSACTIONREASON...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TRANSACTIONREASON]') and xtype='U')
begin
	select * 
	into CCImport_TRANSACTIONREASON 
	from TRANSACTIONREASON
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TRANSACTIONREASON
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TRANSACTIONREASON
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TRANSACTIONREASON table
-- CALLED BY :	ip_CopyConfigTRANSACTIONREASON
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
	 null as 'Imported Description',
	 null as 'Imported Internalflag',
'D' as '-',
	 C.DESCRIPTION as 'Description',
	 C.INTERNALFLAG as 'Internalflag'
from CCImport_TRANSACTIONREASON I 
	right join TRANSACTIONREASON C on( C.TRANSACTIONREASONNO=I.TRANSACTIONREASONNO)
where I.TRANSACTIONREASONNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.DESCRIPTION,
	 I.INTERNALFLAG,
'I',
	 null ,
	 null
from CCImport_TRANSACTIONREASON I 
	left join TRANSACTIONREASON C on( C.TRANSACTIONREASONNO=I.TRANSACTIONREASONNO)
where C.TRANSACTIONREASONNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.DESCRIPTION,
	 I.INTERNALFLAG,
'U',
	 C.DESCRIPTION,
	 C.INTERNALFLAG
from CCImport_TRANSACTIONREASON I 
	join TRANSACTIONREASON C	on ( C.TRANSACTIONREASONNO=I.TRANSACTIONREASONNO)
where 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.INTERNALFLAG <>  C.INTERNALFLAG OR (I.INTERNALFLAG is null and C.INTERNALFLAG is not null) 
OR (I.INTERNALFLAG is not null and C.INTERNALFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TRANSACTIONREASON]') and xtype='U')
begin
	drop table CCImport_TRANSACTIONREASON 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TRANSACTIONREASON  to public
go
