-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnWIPATTRIBUTE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnWIPATTRIBUTE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnWIPATTRIBUTE.'
	drop function dbo.fn_ccnWIPATTRIBUTE
	print '**** Creating function dbo.fn_ccnWIPATTRIBUTE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_WIPATTRIBUTE]') and xtype='U')
begin
	select * 
	into CCImport_WIPATTRIBUTE 
	from WIPATTRIBUTE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnWIPATTRIBUTE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnWIPATTRIBUTE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the WIPATTRIBUTE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	8 as TRIPNO, 'WIPATTRIBUTE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_WIPATTRIBUTE I 
	right join WIPATTRIBUTE C on( C.WIPATTRIBUTE=I.WIPATTRIBUTE)
where I.WIPATTRIBUTE is null
UNION ALL 
select	8, 'WIPATTRIBUTE', 0, count(*), 0, 0
from CCImport_WIPATTRIBUTE I 
	left join WIPATTRIBUTE C on( C.WIPATTRIBUTE=I.WIPATTRIBUTE)
where C.WIPATTRIBUTE is null
UNION ALL 
 select	8, 'WIPATTRIBUTE', 0, 0, count(*), 0
from CCImport_WIPATTRIBUTE I 
	join WIPATTRIBUTE C	on ( C.WIPATTRIBUTE=I.WIPATTRIBUTE)
where 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
UNION ALL 
 select	8, 'WIPATTRIBUTE', 0, 0, 0, count(*)
from CCImport_WIPATTRIBUTE I 
join WIPATTRIBUTE C	on( C.WIPATTRIBUTE=I.WIPATTRIBUTE)
where ( I.DESCRIPTION =  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_WIPATTRIBUTE]') and xtype='U')
begin
	drop table CCImport_WIPATTRIBUTE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnWIPATTRIBUTE  to public
go
