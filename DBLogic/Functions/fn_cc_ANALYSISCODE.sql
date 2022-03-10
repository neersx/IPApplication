-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ANALYSISCODE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ANALYSISCODE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ANALYSISCODE.'
	drop function dbo.fn_cc_ANALYSISCODE
	print '**** Creating function dbo.fn_cc_ANALYSISCODE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_ANALYSISCODE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ANALYSISCODE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the ANALYSISCODE table
-- CALLED BY :	ip_CopyConfigANALYSISCODE
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
	 null as 'Imported Codeid',
	 null as 'Imported Code',
	 null as 'Imported Description',
	 null as 'Imported Typeid',
'D' as '-',
	 C.CODEID as 'Codeid',
	 C.CODE as 'Code',
	 C.DESCRIPTION as 'Description',
	 C.TYPEID as 'Typeid'
from CCImport_ANALYSISCODE I 
	right join ANALYSISCODE C on( C.CODEID=I.CODEID)
where I.CODEID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CODEID,
	 I.CODE,
	 I.DESCRIPTION,
	 I.TYPEID,
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ANALYSISCODE I 
	left join ANALYSISCODE C on( C.CODEID=I.CODEID)
where C.CODEID is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CODEID,
	 I.CODE,
	 I.DESCRIPTION,
	 I.TYPEID,
'U',
	 C.CODEID,
	 C.CODE,
	 C.DESCRIPTION,
	 C.TYPEID
from CCImport_ANALYSISCODE I 
	join ANALYSISCODE C	on ( C.CODEID=I.CODEID)
where 	( I.CODE <>  C.CODE)
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION)
	OR 	( I.TYPEID <>  C.TYPEID)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ANALYSISCODE]') and xtype='U')
begin
	drop table CCImport_ANALYSISCODE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ANALYSISCODE  to public
go
