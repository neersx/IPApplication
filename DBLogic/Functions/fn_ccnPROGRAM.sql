-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnPROGRAM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnPROGRAM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnPROGRAM.'
	drop function dbo.fn_ccnPROGRAM
	print '**** Creating function dbo.fn_ccnPROGRAM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_PROGRAM]') and xtype='U')
begin
	select * 
	into CCImport_PROGRAM 
	from PROGRAM
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnPROGRAM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnPROGRAM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the PROGRAM table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 21 Aug 2019	MF	DR-42774 1	Function generated
--
As 
Return
select	2 as TRIPNO, 'PROGRAM' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_PROGRAM I 
	right join PROGRAM C on( C.PROGRAMID=I.PROGRAMID)
where I.PROGRAMID is null
UNION ALL 
select	2, 'PROGRAM', 0, count(*), 0, 0
from CCImport_PROGRAM I 
	left join PROGRAM C on( C.PROGRAMID=I.PROGRAMID)
where C.PROGRAMID is null
UNION ALL 
 select	2, 'PROGRAM', 0, 0, count(*), 0
from CCImport_PROGRAM I 
	join PROGRAM C	on ( C.PROGRAMID=I.PROGRAMID)
where 	( I.PROGRAMNAME   <>  C.PROGRAMNAME   OR (I.PROGRAMNAME   is null and C.PROGRAMNAME   is not null) OR (I.PROGRAMNAME   is not null and C.PROGRAMNAME   is null))
OR 	( I.PARENTPROGRAM <>  C.PARENTPROGRAM OR (I.PARENTPROGRAM is null and C.PARENTPROGRAM is not null) OR (I.PARENTPROGRAM is not null and C.PARENTPROGRAM is null))
OR 	( I.PROGRAMGROUP  <>  C.PROGRAMGROUP  OR (I.PROGRAMGROUP  is null and C.PROGRAMGROUP  is not null) OR (I.PROGRAMGROUP  is not null and C.PROGRAMGROUP  is null))
UNION ALL 
 select	2, 'PROGRAM', 0, 0, 0, count(*)
from CCImport_PROGRAM I 
join PROGRAM C	on( C.PROGRAMID=I.PROGRAMID)
where 	( I.PROGRAMNAME   =  C.PROGRAMNAME   OR I.PROGRAMNAME   is null and C.PROGRAMNAME   is  null)
AND 	( I.PARENTPROGRAM =  C.PARENTPROGRAM OR I.PARENTPROGRAM is null and C.PARENTPROGRAM is  null)
AND 	( I.PROGRAMGROUP  =  C.PROGRAMGROUP  OR I.PROGRAMGROUP  is null and C.PROGRAMGROUP  is  null)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_PROGRAM]') and xtype='U')
begin
	drop table CCImport_PROGRAM 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnPROGRAM  to public
go
