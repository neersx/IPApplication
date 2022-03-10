-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ENCODEDVALUE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ENCODEDVALUE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ENCODEDVALUE.'
	drop function dbo.fn_cc_ENCODEDVALUE
	print '**** Creating function dbo.fn_cc_ENCODEDVALUE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODEDVALUE]') and xtype='U')
begin
	select * 
	into CCImport_ENCODEDVALUE 
	from ENCODEDVALUE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ENCODEDVALUE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ENCODEDVALUE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ENCODEDVALUE table
-- CALLED BY :	ip_CopyConfigENCODEDVALUE
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
	 null as 'Imported Schemeid',
	 null as 'Imported Structureid',
	 null as 'Imported Code',
	 null as 'Imported Description',
	 null as 'Imported Outboundvalue',
'D' as '-',
	 C.SCHEMEID as 'Schemeid',
	 C.STRUCTUREID as 'Structureid',
	 C.CODE as 'Code',
	 C.DESCRIPTION as 'Description',
	 C.OUTBOUNDVALUE as 'Outboundvalue'
from CCImport_ENCODEDVALUE I 
	right join ENCODEDVALUE C on( C.CODEID=I.CODEID)
where I.CODEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SCHEMEID,
	 I.STRUCTUREID,
	 I.CODE,
	 I.DESCRIPTION,
	 I.OUTBOUNDVALUE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ENCODEDVALUE I 
	left join ENCODEDVALUE C on( C.CODEID=I.CODEID)
where C.CODEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SCHEMEID,
	 I.STRUCTUREID,
	 I.CODE,
	 I.DESCRIPTION,
	 I.OUTBOUNDVALUE,
'U',
	 C.SCHEMEID,
	 C.STRUCTUREID,
	 C.CODE,
	 C.DESCRIPTION,
	 C.OUTBOUNDVALUE
from CCImport_ENCODEDVALUE I 
	join ENCODEDVALUE C	on ( C.CODEID=I.CODEID)
where 	( I.SCHEMEID <>  C.SCHEMEID)
	OR 	( I.STRUCTUREID <>  C.STRUCTUREID)
	OR 	( I.CODE <>  C.CODE OR (I.CODE is null and C.CODE is not null) 
OR (I.CODE is not null and C.CODE is null))
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.OUTBOUNDVALUE <>  C.OUTBOUNDVALUE OR (I.OUTBOUNDVALUE is null and C.OUTBOUNDVALUE is not null) 
OR (I.OUTBOUNDVALUE is not null and C.OUTBOUNDVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODEDVALUE]') and xtype='U')
begin
	drop table CCImport_ENCODEDVALUE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ENCODEDVALUE  to public
go
