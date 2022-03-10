-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCRITERIACHANGES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCRITERIACHANGES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCRITERIACHANGES.'
	drop function dbo.fn_ccnCRITERIACHANGES
	print '**** Creating function dbo.fn_ccnCRITERIACHANGES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CRITERIACHANGES]') and xtype='U')
begin
	select * 
	into CCImport_CRITERIACHANGES 
	from CRITERIACHANGES
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCRITERIACHANGES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCRITERIACHANGES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CRITERIACHANGES table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'CRITERIACHANGES' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CRITERIACHANGES I 
	right join CRITERIACHANGES C on( C.WHENREQUESTED=I.WHENREQUESTED
and  C.SQLUSER=I.SQLUSER)
where I.WHENREQUESTED is null
UNION ALL 
select	5, 'CRITERIACHANGES', 0, count(*), 0, 0
from CCImport_CRITERIACHANGES I 
	left join CRITERIACHANGES C on( C.WHENREQUESTED=I.WHENREQUESTED
and  C.SQLUSER=I.SQLUSER)
where C.WHENREQUESTED is null
UNION ALL 
 select	5, 'CRITERIACHANGES', 0, 0, count(*), 0
from CCImport_CRITERIACHANGES I 
	join CRITERIACHANGES C	on ( C.WHENREQUESTED=I.WHENREQUESTED
	and C.SQLUSER=I.SQLUSER)
where 	( I.CRITERIANO <>  C.CRITERIANO OR (I.CRITERIANO is null and C.CRITERIANO is not null) 
OR (I.CRITERIANO is not null and C.CRITERIANO is null))
	OR 	( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null) 
OR (I.EVENTNO is not null and C.EVENTNO is null))
	OR 	( I.OLDCRITERIANO <>  C.OLDCRITERIANO OR (I.OLDCRITERIANO is null and C.OLDCRITERIANO is not null) 
OR (I.OLDCRITERIANO is not null and C.OLDCRITERIANO is null))
	OR 	( I.NEWCRITERIANO <>  C.NEWCRITERIANO OR (I.NEWCRITERIANO is null and C.NEWCRITERIANO is not null) 
OR (I.NEWCRITERIANO is not null and C.NEWCRITERIANO is null))
	OR 	( I.PROCESSED <>  C.PROCESSED OR (I.PROCESSED is null and C.PROCESSED is not null) 
OR (I.PROCESSED is not null and C.PROCESSED is null))
	OR 	( I.WHENOCCURRED <>  C.WHENOCCURRED OR (I.WHENOCCURRED is null and C.WHENOCCURRED is not null) 
OR (I.WHENOCCURRED is not null and C.WHENOCCURRED is null))
	OR 	( I.IDENTITYID <>  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is not null) 
OR (I.IDENTITYID is not null and C.IDENTITYID is null))
UNION ALL 
 select	5, 'CRITERIACHANGES', 0, 0, 0, count(*)
from CCImport_CRITERIACHANGES I 
join CRITERIACHANGES C	on( C.WHENREQUESTED=I.WHENREQUESTED
and C.SQLUSER=I.SQLUSER)
where ( I.CRITERIANO =  C.CRITERIANO OR (I.CRITERIANO is null and C.CRITERIANO is null))
and ( I.EVENTNO =  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is null))
and ( I.OLDCRITERIANO =  C.OLDCRITERIANO OR (I.OLDCRITERIANO is null and C.OLDCRITERIANO is null))
and ( I.NEWCRITERIANO =  C.NEWCRITERIANO OR (I.NEWCRITERIANO is null and C.NEWCRITERIANO is null))
and ( I.PROCESSED =  C.PROCESSED OR (I.PROCESSED is null and C.PROCESSED is null))
and ( I.WHENOCCURRED =  C.WHENOCCURRED OR (I.WHENOCCURRED is null and C.WHENOCCURRED is null))
and ( I.IDENTITYID =  C.IDENTITYID OR (I.IDENTITYID is null and C.IDENTITYID is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CRITERIACHANGES]') and xtype='U')
begin
	drop table CCImport_CRITERIACHANGES 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCRITERIACHANGES  to public
go
