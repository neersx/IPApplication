-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnBUSINESSRULECONTRO_
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnBUSINESSRULECONTRO_]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnBUSINESSRULECONTRO_.'
	drop function dbo.fn_ccnBUSINESSRULECONTRO_
	print '**** Creating function dbo.fn_ccnBUSINESSRULECONTRO_...'
	print ''
end
go

SET NOCOUNT ON
go


-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_BUSINESSRULECONTROL]') and xtype='U')
begin
	select * 
	into CCImport_BUSINESSRULECONTROL 
	from BUSINESSRULECONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnBUSINESSRULECONTRO_
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnBUSINESSRULECONTRO_
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the BUSINESSRULECONTROL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	6 as TRIPNO, 'BUSINESSRULECONTROL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_BUSINESSRULECONTROL I 
	right join BUSINESSRULECONTROL C on( C.BUSINESSRULENO=I.BUSINESSRULENO)
where I.BUSINESSRULENO is null
UNION ALL 
select	6, 'BUSINESSRULECONTROL', 0, count(*), 0, 0
from CCImport_BUSINESSRULECONTROL I 
	left join BUSINESSRULECONTROL C on( C.BUSINESSRULENO=I.BUSINESSRULENO)
where C.BUSINESSRULENO is null
UNION ALL 
 select	6, 'BUSINESSRULECONTROL', 0, 0, count(*), 0
from CCImport_BUSINESSRULECONTROL I 
	join BUSINESSRULECONTROL C	on ( C.BUSINESSRULENO=I.BUSINESSRULENO)
where 	( I.TOPICCONTROLNO <>  C.TOPICCONTROLNO)
	OR 	( I.RULETYPE <>  C.RULETYPE)
	OR 	( I.SEQUENCE <>  C.SEQUENCE)
	OR 	(replace( I.VALUE,char(10),char(13)+char(10)) <>  C.VALUE OR (I.VALUE is null and C.VALUE is not null) 
OR (I.VALUE is not null and C.VALUE is null))
	OR 	( I.ISINHERITED <>  C.ISINHERITED)
UNION ALL 
 select	6, 'BUSINESSRULECONTROL', 0, 0, 0, count(*)
from CCImport_BUSINESSRULECONTROL I 
join BUSINESSRULECONTROL C	on( C.BUSINESSRULENO=I.BUSINESSRULENO)
where ( I.TOPICCONTROLNO =  C.TOPICCONTROLNO)
and ( I.RULETYPE =  C.RULETYPE)
and ( I.SEQUENCE =  C.SEQUENCE)
and (replace( I.VALUE,char(10),char(13)+char(10)) =  C.VALUE OR (I.VALUE is null and C.VALUE is null))
and ( I.ISINHERITED =  C.ISINHERITED)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_BUSINESSRULECONTROL]') and xtype='U')
begin
	drop table CCImport_BUSINESSRULECONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnBUSINESSRULECONTRO_  to public
go
