-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTRANSACTIONREASON
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTRANSACTIONREASON]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTRANSACTIONREASON.'
	drop function dbo.fn_ccnTRANSACTIONREASON
	print '**** Creating function dbo.fn_ccnTRANSACTIONREASON...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TRANSACTIONREASON]') and xtype='U')
begin
	select * 
	into CCImport_TRANSACTIONREASON 
	from TRANSACTIONREASON
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTRANSACTIONREASON
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTRANSACTIONREASON
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TRANSACTIONREASON table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'TRANSACTIONREASON' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TRANSACTIONREASON I 
	right join TRANSACTIONREASON C on( C.TRANSACTIONREASONNO=I.TRANSACTIONREASONNO)
where I.TRANSACTIONREASONNO is null
UNION ALL 
select	2, 'TRANSACTIONREASON', 0, count(*), 0, 0
from CCImport_TRANSACTIONREASON I 
	left join TRANSACTIONREASON C on( C.TRANSACTIONREASONNO=I.TRANSACTIONREASONNO)
where C.TRANSACTIONREASONNO is null
UNION ALL 
 select	2, 'TRANSACTIONREASON', 0, 0, count(*), 0
from CCImport_TRANSACTIONREASON I 
	join TRANSACTIONREASON C	on ( C.TRANSACTIONREASONNO=I.TRANSACTIONREASONNO)
where 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.INTERNALFLAG <>  C.INTERNALFLAG OR (I.INTERNALFLAG is null and C.INTERNALFLAG is not null) 
OR (I.INTERNALFLAG is not null and C.INTERNALFLAG is null))
UNION ALL 
 select	2, 'TRANSACTIONREASON', 0, 0, 0, count(*)
from CCImport_TRANSACTIONREASON I 
join TRANSACTIONREASON C	on( C.TRANSACTIONREASONNO=I.TRANSACTIONREASONNO)
where (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.INTERNALFLAG =  C.INTERNALFLAG OR (I.INTERNALFLAG is null and C.INTERNALFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TRANSACTIONREASON]') and xtype='U')
begin
	drop table CCImport_TRANSACTIONREASON 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTRANSACTIONREASON  to public
go

