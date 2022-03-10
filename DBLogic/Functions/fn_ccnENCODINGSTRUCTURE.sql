-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnENCODINGSTRUCTURE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnENCODINGSTRUCTURE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnENCODINGSTRUCTURE.'
	drop function dbo.fn_ccnENCODINGSTRUCTURE
	print '**** Creating function dbo.fn_ccnENCODINGSTRUCTURE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODINGSTRUCTURE]') and xtype='U')
begin
	select * 
	into CCImport_ENCODINGSTRUCTURE 
	from ENCODINGSTRUCTURE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnENCODINGSTRUCTURE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnENCODINGSTRUCTURE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ENCODINGSTRUCTURE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	9 as TRIPNO, 'ENCODINGSTRUCTURE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ENCODINGSTRUCTURE I 
	right join ENCODINGSTRUCTURE C on( C.SCHEMEID=I.SCHEMEID
and  C.STRUCTUREID=I.STRUCTUREID)
where I.SCHEMEID is null
UNION ALL 
select	9, 'ENCODINGSTRUCTURE', 0, count(*), 0, 0
from CCImport_ENCODINGSTRUCTURE I 
	left join ENCODINGSTRUCTURE C on( C.SCHEMEID=I.SCHEMEID
and  C.STRUCTUREID=I.STRUCTUREID)
where C.SCHEMEID is null
UNION ALL 
 select	9, 'ENCODINGSTRUCTURE', 0, 0, count(*), 0
from CCImport_ENCODINGSTRUCTURE I 
	join ENCODINGSTRUCTURE C	on ( C.SCHEMEID=I.SCHEMEID
	and C.STRUCTUREID=I.STRUCTUREID)
where 	( I.NAME <>  C.NAME)
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
UNION ALL 
 select	9, 'ENCODINGSTRUCTURE', 0, 0, 0, count(*)
from CCImport_ENCODINGSTRUCTURE I 
join ENCODINGSTRUCTURE C	on( C.SCHEMEID=I.SCHEMEID
and C.STRUCTUREID=I.STRUCTUREID)
where ( I.NAME =  C.NAME)
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ENCODINGSTRUCTURE]') and xtype='U')
begin
	drop table CCImport_ENCODINGSTRUCTURE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnENCODINGSTRUCTURE  to public
go
