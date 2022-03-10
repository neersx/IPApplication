-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ALIASTYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ALIASTYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ALIASTYPE.'
	drop function dbo.fn_cc_ALIASTYPE
	print '**** Creating function dbo.fn_cc_ALIASTYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ALIASTYPE]') and xtype='U')
begin
	select * 
	into CCImport_ALIASTYPE 
	from ALIASTYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ALIASTYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ALIASTYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ALIASTYPE table
-- CALLED BY :	ip_CopyConfigALIASTYPE
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
	 null as 'Imported Aliastype',
	 null as 'Imported Aliasdescription',
	 null as 'Imported Mustbeunique',
'D' as '-',
	 C.ALIASTYPE as 'Aliastype',
	 C.ALIASDESCRIPTION as 'Aliasdescription',
	 C.MUSTBEUNIQUE as 'Mustbeunique'
from CCImport_ALIASTYPE I 
	right join ALIASTYPE C on( C.ALIASTYPE=I.ALIASTYPE)
where I.ALIASTYPE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ALIASTYPE,
	 I.ALIASDESCRIPTION,
	 I.MUSTBEUNIQUE,
'I',
	 null ,
	 null ,
	 null
from CCImport_ALIASTYPE I 
	left join ALIASTYPE C on( C.ALIASTYPE=I.ALIASTYPE)
where C.ALIASTYPE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ALIASTYPE,
	 I.ALIASDESCRIPTION,
	 I.MUSTBEUNIQUE,
'U',
	 C.ALIASTYPE,
	 C.ALIASDESCRIPTION,
	 C.MUSTBEUNIQUE
from CCImport_ALIASTYPE I 
	join ALIASTYPE C	on ( C.ALIASTYPE=I.ALIASTYPE)
where 	( I.ALIASDESCRIPTION <>  C.ALIASDESCRIPTION OR (I.ALIASDESCRIPTION is null and C.ALIASDESCRIPTION is not null) 
OR (I.ALIASDESCRIPTION is not null and C.ALIASDESCRIPTION is null))
	OR 	( I.MUSTBEUNIQUE <>  C.MUSTBEUNIQUE OR (I.MUSTBEUNIQUE is null and C.MUSTBEUNIQUE is not null) 
OR (I.MUSTBEUNIQUE is not null and C.MUSTBEUNIQUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ALIASTYPE]') and xtype='U')
begin
	drop table CCImport_ALIASTYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ALIASTYPE  to public
go

