-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnACCT_TRANS_TYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnACCT_TRANS_TYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnACCT_TRANS_TYPE.'
	drop function dbo.fn_ccnACCT_TRANS_TYPE
	print '**** Creating function dbo.fn_ccnACCT_TRANS_TYPE...'
	print ''
end
go

SET NOCOUNT ON
GO

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ACCT_TRANS_TYPE]') and xtype='U')
begin
	select * 
	into CCImport_ACCT_TRANS_TYPE 
	from ACCT_TRANS_TYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnACCT_TRANS_TYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnACCT_TRANS_TYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ACCT_TRANS_TYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'ACCT_TRANS_TYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ACCT_TRANS_TYPE I 
	right join ACCT_TRANS_TYPE C on( C.TRANS_TYPE_ID=I.TRANS_TYPE_ID)
where I.TRANS_TYPE_ID is null
UNION ALL 
select	8, 'ACCT_TRANS_TYPE', 0, count(*), 0, 0
from CCImport_ACCT_TRANS_TYPE I 
	left join ACCT_TRANS_TYPE C on( C.TRANS_TYPE_ID=I.TRANS_TYPE_ID)
where C.TRANS_TYPE_ID is null
UNION ALL 
 select	8, 'ACCT_TRANS_TYPE', 0, 0, count(*), 0
from CCImport_ACCT_TRANS_TYPE I 
	join ACCT_TRANS_TYPE C	on ( C.TRANS_TYPE_ID=I.TRANS_TYPE_ID)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.USED_BY <>  C.USED_BY)
	OR 	( I.REVERSE_TRANS_TYPE <>  C.REVERSE_TRANS_TYPE OR (I.REVERSE_TRANS_TYPE is null and C.REVERSE_TRANS_TYPE is not null) 
OR (I.REVERSE_TRANS_TYPE is not null and C.REVERSE_TRANS_TYPE is null))
UNION ALL 
 select	8, 'ACCT_TRANS_TYPE', 0, 0, 0, count(*)
from CCImport_ACCT_TRANS_TYPE I 
join ACCT_TRANS_TYPE C	on( C.TRANS_TYPE_ID=I.TRANS_TYPE_ID)
where ( I.DESCRIPTION =  C.DESCRIPTION)
and ( I.USED_BY =  C.USED_BY)
and ( I.REVERSE_TRANS_TYPE =  C.REVERSE_TRANS_TYPE OR (I.REVERSE_TRANS_TYPE is null and C.REVERSE_TRANS_TYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ACCT_TRANS_TYPE]') and xtype='U')
begin
	drop table CCImport_ACCT_TRANS_TYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnACCT_TRANS_TYPE  to public
go
