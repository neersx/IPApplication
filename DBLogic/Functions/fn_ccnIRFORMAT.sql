-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnIRFORMAT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnIRFORMAT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnIRFORMAT.'
	drop function dbo.fn_ccnIRFORMAT
	print '**** Creating function dbo.fn_ccnIRFORMAT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_IRFORMAT]') and xtype='U')
begin
	select * 
	into CCImport_IRFORMAT 
	from IRFORMAT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnIRFORMAT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnIRFORMAT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the IRFORMAT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'IRFORMAT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_IRFORMAT I 
	right join IRFORMAT C on( C.CRITERIANO=I.CRITERIANO)
where I.CRITERIANO is null
UNION ALL 
select	5, 'IRFORMAT', 0, count(*), 0, 0
from CCImport_IRFORMAT I 
	left join IRFORMAT C on( C.CRITERIANO=I.CRITERIANO)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'IRFORMAT', 0, 0, count(*), 0
from CCImport_IRFORMAT I 
	join IRFORMAT C	on ( C.CRITERIANO=I.CRITERIANO)
where 	( I.SEGMENT1 <>  C.SEGMENT1 OR (I.SEGMENT1 is null and C.SEGMENT1 is not null) 
OR (I.SEGMENT1 is not null and C.SEGMENT1 is null))
	OR 	( I.SEGMENT2 <>  C.SEGMENT2 OR (I.SEGMENT2 is null and C.SEGMENT2 is not null) 
OR (I.SEGMENT2 is not null and C.SEGMENT2 is null))
	OR 	( I.SEGMENT3 <>  C.SEGMENT3 OR (I.SEGMENT3 is null and C.SEGMENT3 is not null) 
OR (I.SEGMENT3 is not null and C.SEGMENT3 is null))
	OR 	( I.SEGMENT4 <>  C.SEGMENT4 OR (I.SEGMENT4 is null and C.SEGMENT4 is not null) 
OR (I.SEGMENT4 is not null and C.SEGMENT4 is null))
	OR 	( I.SEGMENT5 <>  C.SEGMENT5 OR (I.SEGMENT5 is null and C.SEGMENT5 is not null) 
OR (I.SEGMENT5 is not null and C.SEGMENT5 is null))
	OR 	( I.INSTRUCTORFLAG <>  C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is not null) 
OR (I.INSTRUCTORFLAG is not null and C.INSTRUCTORFLAG is null))
	OR 	( I.OWNERFLAG <>  C.OWNERFLAG OR (I.OWNERFLAG is null and C.OWNERFLAG is not null) 
OR (I.OWNERFLAG is not null and C.OWNERFLAG is null))
	OR 	( I.STAFFFLAG <>  C.STAFFFLAG OR (I.STAFFFLAG is null and C.STAFFFLAG is not null) 
OR (I.STAFFFLAG is not null and C.STAFFFLAG is null))
	OR 	( I.FAMILYFLAG <>  C.FAMILYFLAG OR (I.FAMILYFLAG is null and C.FAMILYFLAG is not null) 
OR (I.FAMILYFLAG is not null and C.FAMILYFLAG is null))
	OR 	( I.SEGMENT6 <>  C.SEGMENT6 OR (I.SEGMENT6 is null and C.SEGMENT6 is not null) 
OR (I.SEGMENT6 is not null and C.SEGMENT6 is null))
	OR 	( I.SEGMENT7 <>  C.SEGMENT7 OR (I.SEGMENT7 is null and C.SEGMENT7 is not null) 
OR (I.SEGMENT7 is not null and C.SEGMENT7 is null))
	OR 	( I.SEGMENT8 <>  C.SEGMENT8 OR (I.SEGMENT8 is null and C.SEGMENT8 is not null) 
OR (I.SEGMENT8 is not null and C.SEGMENT8 is null))
	OR 	( I.SEGMENT9 <>  C.SEGMENT9 OR (I.SEGMENT9 is null and C.SEGMENT9 is not null) 
OR (I.SEGMENT9 is not null and C.SEGMENT9 is null))
	OR 	( I.SEGMENT1CODE <>  C.SEGMENT1CODE OR (I.SEGMENT1CODE is null and C.SEGMENT1CODE is not null) 
OR (I.SEGMENT1CODE is not null and C.SEGMENT1CODE is null))
	OR 	( I.SEGMENT2CODE <>  C.SEGMENT2CODE OR (I.SEGMENT2CODE is null and C.SEGMENT2CODE is not null) 
OR (I.SEGMENT2CODE is not null and C.SEGMENT2CODE is null))
	OR 	( I.SEGMENT3CODE <>  C.SEGMENT3CODE OR (I.SEGMENT3CODE is null and C.SEGMENT3CODE is not null) 
OR (I.SEGMENT3CODE is not null and C.SEGMENT3CODE is null))
	OR 	( I.SEGMENT4CODE <>  C.SEGMENT4CODE OR (I.SEGMENT4CODE is null and C.SEGMENT4CODE is not null) 
OR (I.SEGMENT4CODE is not null and C.SEGMENT4CODE is null))
	OR 	( I.SEGMENT5CODE <>  C.SEGMENT5CODE OR (I.SEGMENT5CODE is null and C.SEGMENT5CODE is not null) 
OR (I.SEGMENT5CODE is not null and C.SEGMENT5CODE is null))
	OR 	( I.SEGMENT6CODE <>  C.SEGMENT6CODE OR (I.SEGMENT6CODE is null and C.SEGMENT6CODE is not null) 
OR (I.SEGMENT6CODE is not null and C.SEGMENT6CODE is null))
	OR 	( I.SEGMENT7CODE <>  C.SEGMENT7CODE OR (I.SEGMENT7CODE is null and C.SEGMENT7CODE is not null) 
OR (I.SEGMENT7CODE is not null and C.SEGMENT7CODE is null))
	OR 	( I.SEGMENT8CODE <>  C.SEGMENT8CODE OR (I.SEGMENT8CODE is null and C.SEGMENT8CODE is not null) 
OR (I.SEGMENT8CODE is not null and C.SEGMENT8CODE is null))
	OR 	( I.SEGMENT9CODE <>  C.SEGMENT9CODE OR (I.SEGMENT9CODE is null and C.SEGMENT9CODE is not null) 
OR (I.SEGMENT9CODE is not null and C.SEGMENT9CODE is null))
UNION ALL 
 select	5, 'IRFORMAT', 0, 0, 0, count(*)
from CCImport_IRFORMAT I 
join IRFORMAT C	on( C.CRITERIANO=I.CRITERIANO)
where ( I.SEGMENT1 =  C.SEGMENT1 OR (I.SEGMENT1 is null and C.SEGMENT1 is null))
and ( I.SEGMENT2 =  C.SEGMENT2 OR (I.SEGMENT2 is null and C.SEGMENT2 is null))
and ( I.SEGMENT3 =  C.SEGMENT3 OR (I.SEGMENT3 is null and C.SEGMENT3 is null))
and ( I.SEGMENT4 =  C.SEGMENT4 OR (I.SEGMENT4 is null and C.SEGMENT4 is null))
and ( I.SEGMENT5 =  C.SEGMENT5 OR (I.SEGMENT5 is null and C.SEGMENT5 is null))
and ( I.INSTRUCTORFLAG =  C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is null))
and ( I.OWNERFLAG =  C.OWNERFLAG OR (I.OWNERFLAG is null and C.OWNERFLAG is null))
and ( I.STAFFFLAG =  C.STAFFFLAG OR (I.STAFFFLAG is null and C.STAFFFLAG is null))
and ( I.FAMILYFLAG =  C.FAMILYFLAG OR (I.FAMILYFLAG is null and C.FAMILYFLAG is null))
and ( I.SEGMENT6 =  C.SEGMENT6 OR (I.SEGMENT6 is null and C.SEGMENT6 is null))
and ( I.SEGMENT7 =  C.SEGMENT7 OR (I.SEGMENT7 is null and C.SEGMENT7 is null))
and ( I.SEGMENT8 =  C.SEGMENT8 OR (I.SEGMENT8 is null and C.SEGMENT8 is null))
and ( I.SEGMENT9 =  C.SEGMENT9 OR (I.SEGMENT9 is null and C.SEGMENT9 is null))
and ( I.SEGMENT1CODE =  C.SEGMENT1CODE OR (I.SEGMENT1CODE is null and C.SEGMENT1CODE is null))
and ( I.SEGMENT2CODE =  C.SEGMENT2CODE OR (I.SEGMENT2CODE is null and C.SEGMENT2CODE is null))
and ( I.SEGMENT3CODE =  C.SEGMENT3CODE OR (I.SEGMENT3CODE is null and C.SEGMENT3CODE is null))
and ( I.SEGMENT4CODE =  C.SEGMENT4CODE OR (I.SEGMENT4CODE is null and C.SEGMENT4CODE is null))
and ( I.SEGMENT5CODE =  C.SEGMENT5CODE OR (I.SEGMENT5CODE is null and C.SEGMENT5CODE is null))
and ( I.SEGMENT6CODE =  C.SEGMENT6CODE OR (I.SEGMENT6CODE is null and C.SEGMENT6CODE is null))
and ( I.SEGMENT7CODE =  C.SEGMENT7CODE OR (I.SEGMENT7CODE is null and C.SEGMENT7CODE is null))
and ( I.SEGMENT8CODE =  C.SEGMENT8CODE OR (I.SEGMENT8CODE is null and C.SEGMENT8CODE is null))
and ( I.SEGMENT9CODE =  C.SEGMENT9CODE OR (I.SEGMENT9CODE is null and C.SEGMENT9CODE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_IRFORMAT]') and xtype='U')
begin
	drop table CCImport_IRFORMAT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnIRFORMAT  to public
go
