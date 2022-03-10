-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ACCT_TRANS_TYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ACCT_TRANS_TYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ACCT_TRANS_TYPE.'
	drop function dbo.fn_cc_ACCT_TRANS_TYPE
	print '**** Creating function dbo.fn_cc_ACCT_TRANS_TYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_ACCT_TRANS_TYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ACCT_TRANS_TYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ACCT_TRANS_TYPE table
-- CALLED BY :	ip_CopyConfigACCT_TRANS_TYPE
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
	 null as 'Imported Trans_type_id',
	 null as 'Imported Description',
	 null as 'Imported Used_by',
	 null as 'Imported Reverse_trans_type',
'D' as '-',
	 C.TRANS_TYPE_ID as 'Trans_type_id',
	 C.DESCRIPTION as 'Description',
	 C.USED_BY as 'Used_by',
	 C.REVERSE_TRANS_TYPE as 'Reverse_trans_type'
from CCImport_ACCT_TRANS_TYPE I 
	right join ACCT_TRANS_TYPE C on( C.TRANS_TYPE_ID=I.TRANS_TYPE_ID)
where I.TRANS_TYPE_ID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TRANS_TYPE_ID,
	 I.DESCRIPTION,
	 I.USED_BY,
	 I.REVERSE_TRANS_TYPE,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ACCT_TRANS_TYPE I 
	left join ACCT_TRANS_TYPE C on( C.TRANS_TYPE_ID=I.TRANS_TYPE_ID)
where C.TRANS_TYPE_ID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TRANS_TYPE_ID,
	 I.DESCRIPTION,
	 I.USED_BY,
	 I.REVERSE_TRANS_TYPE,
'U',
	 C.TRANS_TYPE_ID,
	 C.DESCRIPTION,
	 C.USED_BY,
	 C.REVERSE_TRANS_TYPE
from CCImport_ACCT_TRANS_TYPE I 
	join ACCT_TRANS_TYPE C	on ( C.TRANS_TYPE_ID=I.TRANS_TYPE_ID)
where 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.USED_BY <>  C.USED_BY)
	OR 	( I.REVERSE_TRANS_TYPE <>  C.REVERSE_TRANS_TYPE OR (I.REVERSE_TRANS_TYPE is null and C.REVERSE_TRANS_TYPE is not null) 
OR (I.REVERSE_TRANS_TYPE is not null and C.REVERSE_TRANS_TYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ACCT_TRANS_TYPE]') and xtype='U')
begin
	drop table CCImport_ACCT_TRANS_TYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ACCT_TRANS_TYPE  to public
go
