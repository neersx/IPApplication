-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnTABLECODES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnTABLECODES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnTABLECODES.'
	drop function dbo.fn_ccnTABLECODES
	print '**** Creating function dbo.fn_ccnTABLECODES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TABLECODES]') and xtype='U')
begin
	select * 
	into CCImport_TABLECODES 
	from TABLECODES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnTABLECODES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnTABLECODES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TABLECODES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'TABLECODES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_TABLECODES I 
	right join TABLECODES C on( C.TABLECODE=I.TABLECODE)
where I.TABLECODE is null
UNION ALL 
select	2, 'TABLECODES', 0, count(*), 0, 0
from CCImport_TABLECODES I 
	left join TABLECODES C on( C.TABLECODE=I.TABLECODE)
where C.TABLECODE is null
UNION ALL 
 select	2, 'TABLECODES', 0, 0, count(*), 0
from CCImport_TABLECODES I 
	join TABLECODES C	on ( C.TABLECODE=I.TABLECODE)
where 	( I.TABLETYPE <>  C.TABLETYPE OR (I.TABLETYPE is null and C.TABLETYPE is not null) 
OR (I.TABLETYPE is not null and C.TABLETYPE is null))
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.USERCODE <>  C.USERCODE OR (I.USERCODE is null and C.USERCODE is not null) 
OR (I.USERCODE is not null and C.USERCODE is null))
	OR 	( I.BOOLEANFLAG <>  C.BOOLEANFLAG OR (I.BOOLEANFLAG is null and C.BOOLEANFLAG is not null) 
OR (I.BOOLEANFLAG is not null and C.BOOLEANFLAG is null))
UNION ALL 
 select	2, 'TABLECODES', 0, 0, 0, count(*)
from CCImport_TABLECODES I 
join TABLECODES C	on( C.TABLECODE=I.TABLECODE)
where ( I.TABLETYPE =  C.TABLETYPE OR (I.TABLETYPE is null and C.TABLETYPE is null))
and ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))
and ( I.USERCODE =  C.USERCODE OR (I.USERCODE is null and C.USERCODE is null))
and ( I.BOOLEANFLAG =  C.BOOLEANFLAG OR (I.BOOLEANFLAG is null and C.BOOLEANFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TABLECODES]') and xtype='U')
begin
	drop table CCImport_TABLECODES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnTABLECODES  to public
go
