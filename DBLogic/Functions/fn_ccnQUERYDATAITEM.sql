-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnQUERYDATAITEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnQUERYDATAITEM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnQUERYDATAITEM.'
	drop function dbo.fn_ccnQUERYDATAITEM
	print '**** Creating function dbo.fn_ccnQUERYDATAITEM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_QUERYDATAITEM]') and xtype='U')
begin
	select * 
	into CCImport_QUERYDATAITEM 
	from QUERYDATAITEM
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnQUERYDATAITEM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnQUERYDATAITEM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the QUERYDATAITEM table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'QUERYDATAITEM' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_QUERYDATAITEM I 
	right join QUERYDATAITEM C on( C.DATAITEMID=I.DATAITEMID)
where I.DATAITEMID is null
UNION ALL 
select	6, 'QUERYDATAITEM', 0, count(*), 0, 0
from CCImport_QUERYDATAITEM I 
	left join QUERYDATAITEM C on( C.DATAITEMID=I.DATAITEMID)
where C.DATAITEMID is null
UNION ALL 
 select	6, 'QUERYDATAITEM', 0, 0, count(*), 0
from CCImport_QUERYDATAITEM I 
	join QUERYDATAITEM C	on ( C.DATAITEMID=I.DATAITEMID)
where 	( I.PROCEDURENAME <>  C.PROCEDURENAME)
	OR 	( I.PROCEDUREITEMID <>  C.PROCEDUREITEMID)
	OR 	( I.QUALIFIERTYPE <>  C.QUALIFIERTYPE OR (I.QUALIFIERTYPE is null and C.QUALIFIERTYPE is not null) 
OR (I.QUALIFIERTYPE is not null and C.QUALIFIERTYPE is null))
	OR 	( I.SORTDIRECTION <>  C.SORTDIRECTION OR (I.SORTDIRECTION is null and C.SORTDIRECTION is not null) 
OR (I.SORTDIRECTION is not null and C.SORTDIRECTION is null))
	OR 	(replace( I.DESCRIPTION,char(10),char(13)+char(10)) <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.ISMULTIRESULT <>  C.ISMULTIRESULT)
	OR 	( I.DATAFORMATID <>  C.DATAFORMATID)
	OR 	( I.DECIMALPLACES <>  C.DECIMALPLACES OR (I.DECIMALPLACES is null and C.DECIMALPLACES is not null) 
OR (I.DECIMALPLACES is not null and C.DECIMALPLACES is null))
	OR 	( I.FORMATITEMID <>  C.FORMATITEMID OR (I.FORMATITEMID is null and C.FORMATITEMID is not null) 
OR (I.FORMATITEMID is not null and C.FORMATITEMID is null))
	OR 	( I.FILTERNODENAME <>  C.FILTERNODENAME OR (I.FILTERNODENAME is null and C.FILTERNODENAME is not null) 
OR (I.FILTERNODENAME is not null and C.FILTERNODENAME is null))
	OR 	( I.ISAGGREGATE <>  C.ISAGGREGATE)
UNION ALL 
 select	6, 'QUERYDATAITEM', 0, 0, 0, count(*)
from CCImport_QUERYDATAITEM I 
join QUERYDATAITEM C	on( C.DATAITEMID=I.DATAITEMID)
where ( I.PROCEDURENAME =  C.PROCEDURENAME)
and ( I.PROCEDUREITEMID =  C.PROCEDUREITEMID)
and ( I.QUALIFIERTYPE =  C.QUALIFIERTYPE OR (I.QUALIFIERTYPE is null and C.QUALIFIERTYPE is null))
and ( I.SORTDIRECTION =  C.SORTDIRECTION OR (I.SORTDIRECTION is null and C.SORTDIRECTION is null))
and (replace( I.DESCRIPTION,char(10),char(13)+char(10)) =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.ISMULTIRESULT =  C.ISMULTIRESULT)
and ( I.DATAFORMATID =  C.DATAFORMATID)
and ( I.DECIMALPLACES =  C.DECIMALPLACES OR (I.DECIMALPLACES is null and C.DECIMALPLACES is null))
and ( I.FORMATITEMID =  C.FORMATITEMID OR (I.FORMATITEMID is null and C.FORMATITEMID is null))
and ( I.FILTERNODENAME =  C.FILTERNODENAME OR (I.FILTERNODENAME is null and C.FILTERNODENAME is null))
and ( I.ISAGGREGATE =  C.ISAGGREGATE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_QUERYDATAITEM]') and xtype='U')
begin
	drop table CCImport_QUERYDATAITEM 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnQUERYDATAITEM  to public
go
