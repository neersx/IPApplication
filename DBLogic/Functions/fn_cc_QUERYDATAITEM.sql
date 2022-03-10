-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_QUERYDATAITEM
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_QUERYDATAITEM]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_QUERYDATAITEM.'
	drop function dbo.fn_cc_QUERYDATAITEM
	print '**** Creating function dbo.fn_cc_QUERYDATAITEM...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_QUERYDATAITEM]') and xtype='U')
begin
	select * 
	into CCImport_QUERYDATAITEM 
	from QUERYDATAITEM
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_QUERYDATAITEM
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_QUERYDATAITEM
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the QUERYDATAITEM table
-- CALLED BY :	ip_CopyConfigQUERYDATAITEM
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Dataitemid',
	 null as 'Imported Procedurename',
	 null as 'Imported Procedureitemid',
	 null as 'Imported Qualifiertype',
	 null as 'Imported Sortdirection',
	 null as 'Imported Description',
	 null as 'Imported Ismultiresult',
	 null as 'Imported Dataformatid',
	 null as 'Imported Decimalplaces',
	 null as 'Imported Formatitemid',
	 null as 'Imported Filternodename',
	 null as 'Imported Isaggregate',
'D' as '-',
	 C.DATAITEMID as 'Dataitemid',
	 C.PROCEDURENAME as 'Procedurename',
	 C.PROCEDUREITEMID as 'Procedureitemid',
	 C.QUALIFIERTYPE as 'Qualifiertype',
	 C.SORTDIRECTION as 'Sortdirection',
	 C.DESCRIPTION as 'Description',
	 C.ISMULTIRESULT as 'Ismultiresult',
	 C.DATAFORMATID as 'Dataformatid',
	 C.DECIMALPLACES as 'Decimalplaces',
	 C.FORMATITEMID as 'Formatitemid',
	 C.FILTERNODENAME as 'Filternodename',
	 C.ISAGGREGATE as 'Isaggregate'
from CCImport_QUERYDATAITEM I 
	right join QUERYDATAITEM C on( C.DATAITEMID=I.DATAITEMID)
where I.DATAITEMID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.DATAITEMID,
	 I.PROCEDURENAME,
	 I.PROCEDUREITEMID,
	 I.QUALIFIERTYPE,
	 I.SORTDIRECTION,
	 I.DESCRIPTION,
	 I.ISMULTIRESULT,
	 I.DATAFORMATID,
	 I.DECIMALPLACES,
	 I.FORMATITEMID,
	 I.FILTERNODENAME,
	 I.ISAGGREGATE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_QUERYDATAITEM I 
	left join QUERYDATAITEM C on( C.DATAITEMID=I.DATAITEMID)
where C.DATAITEMID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.DATAITEMID,
	 I.PROCEDURENAME,
	 I.PROCEDUREITEMID,
	 I.QUALIFIERTYPE,
	 I.SORTDIRECTION,
	 I.DESCRIPTION,
	 I.ISMULTIRESULT,
	 I.DATAFORMATID,
	 I.DECIMALPLACES,
	 I.FORMATITEMID,
	 I.FILTERNODENAME,
	 I.ISAGGREGATE,
'U',
	 C.DATAITEMID,
	 C.PROCEDURENAME,
	 C.PROCEDUREITEMID,
	 C.QUALIFIERTYPE,
	 C.SORTDIRECTION,
	 C.DESCRIPTION,
	 C.ISMULTIRESULT,
	 C.DATAFORMATID,
	 C.DECIMALPLACES,
	 C.FORMATITEMID,
	 C.FILTERNODENAME,
	 C.ISAGGREGATE
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

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_QUERYDATAITEM]') and xtype='U')
begin
	drop table CCImport_QUERYDATAITEM 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_QUERYDATAITEM  to public
go
