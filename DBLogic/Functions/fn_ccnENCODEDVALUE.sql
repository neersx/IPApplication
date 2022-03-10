-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnENCODEDVALUE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnENCODEDVALUE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnENCODEDVALUE.'
	drop function dbo.fn_ccnENCODEDVALUE
	print '**** Creating function dbo.fn_ccnENCODEDVALUE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnENCODEDVALUE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnENCODEDVALUE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ENCODEDVALUE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'ENCODEDVALUE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ENCODEDVALUE I 
	right join ENCODEDVALUE C on( C.CODEID=I.CODEID)
where I.CODEID is null
UNION ALL 
select	9, 'ENCODEDVALUE', 0, count(*), 0, 0
from CCImport_ENCODEDVALUE I 
	left join ENCODEDVALUE C on( C.CODEID=I.CODEID)
where C.CODEID is null
UNION ALL 
 select	9, 'ENCODEDVALUE', 0, 0, count(*), 0
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
UNION ALL 
 select	9, 'ENCODEDVALUE', 0, 0, 0, count(*)
from CCImport_ENCODEDVALUE I 
join ENCODEDVALUE C	on( C.CODEID=I.CODEID)
where ( I.SCHEMEID =  C.SCHEMEID)
and ( I.STRUCTUREID =  C.STRUCTUREID)
and ( I.CODE =  C.CODE OR (I.CODE is null and C.CODE is null))
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.OUTBOUNDVALUE =  C.OUTBOUNDVALUE OR (I.OUTBOUNDVALUE is null and C.OUTBOUNDVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODEDVALUE]') and xtype='U')
begin
	drop table CCImport_ENCODEDVALUE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnENCODEDVALUE  to public
go
