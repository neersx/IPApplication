-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnANALYSISCODE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnANALYSISCODE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnANALYSISCODE.'
	drop function dbo.fn_ccnANALYSISCODE
	print '**** Creating function dbo.fn_ccnANALYSISCODE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ANALYSISCODE]') and xtype='U')
begin
	select * 
	into CCImport_ANALYSISCODE 
	from ANALYSISCODE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnANALYSISCODE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnANALYSISCODE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ANALYSISCODE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'ANALYSISCODE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ANALYSISCODE I 
	right join ANALYSISCODE C on( C.CODEID=I.CODEID)
where I.CODEID is null
UNION ALL 
select	8, 'ANALYSISCODE', 0, count(*), 0, 0
from CCImport_ANALYSISCODE I 
	left join ANALYSISCODE C on( C.CODEID=I.CODEID)
where C.CODEID is null
UNION ALL 
 select	8, 'ANALYSISCODE', 0, 0, count(*), 0
from CCImport_ANALYSISCODE I 
	join ANALYSISCODE C	on ( C.CODEID=I.CODEID)
where 	( I.CODE <>  C.CODE)
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.TYPEID <>  C.TYPEID)
UNION ALL 
 select	8, 'ANALYSISCODE', 0, 0, 0, count(*)
from CCImport_ANALYSISCODE I 
join ANALYSISCODE C	on( C.CODEID=I.CODEID)
where ( I.CODE =  C.CODE)
and ( I.DESCRIPTION =  C.DESCRIPTION)
and ( I.TYPEID =  C.TYPEID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ANALYSISCODE]') and xtype='U')
begin
	drop table CCImport_ANALYSISCODE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnANALYSISCODE  to public
go

