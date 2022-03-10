-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_RECORDALELEMENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_RECORDALELEMENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_RECORDALELEMENT.'
	drop function dbo.fn_cc_RECORDALELEMENT
	print '**** Creating function dbo.fn_cc_RECORDALELEMENT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDALELEMENT]') and xtype='U')
begin
	select * 
	into CCImport_RECORDALELEMENT 
	from RECORDALELEMENT
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_RECORDALELEMENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_RECORDALELEMENT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the RECORDALELEMENT table
-- CALLED BY :	ip_CopyConfigRECORDALELEMENT
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
	 null as 'Imported Recordaltypeno',
	 null as 'Imported Elementno',
	 null as 'Imported Elementlabel',
	 null as 'Imported Nametype',
	 null as 'Imported Editattribute',
'D' as '-',
	 C.RECORDALTYPENO as 'Recordaltypeno',
	 C.ELEMENTNO as 'Elementno',
	 C.ELEMENTLABEL as 'Elementlabel',
	 C.NAMETYPE as 'Nametype',
	 C.EDITATTRIBUTE as 'Editattribute'
from CCImport_RECORDALELEMENT I 
	right join RECORDALELEMENT C on( C.RECORDALELEMENTNO=I.RECORDALELEMENTNO)
where I.RECORDALELEMENTNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.RECORDALTYPENO,
	 I.ELEMENTNO,
	 I.ELEMENTLABEL,
	 I.NAMETYPE,
	 I.EDITATTRIBUTE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_RECORDALELEMENT I 
	left join RECORDALELEMENT C on( C.RECORDALELEMENTNO=I.RECORDALELEMENTNO)
where C.RECORDALELEMENTNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.RECORDALTYPENO,
	 I.ELEMENTNO,
	 I.ELEMENTLABEL,
	 I.NAMETYPE,
	 I.EDITATTRIBUTE,
'U',
	 C.RECORDALTYPENO,
	 C.ELEMENTNO,
	 C.ELEMENTLABEL,
	 C.NAMETYPE,
	 C.EDITATTRIBUTE
from CCImport_RECORDALELEMENT I 
	join RECORDALELEMENT C	on ( C.RECORDALELEMENTNO=I.RECORDALELEMENTNO)
where 	( I.RECORDALTYPENO <>  C.RECORDALTYPENO)
	OR 	( I.ELEMENTNO <>  C.ELEMENTNO)
	OR 	( I.ELEMENTLABEL <>  C.ELEMENTLABEL)
	OR 	( I.NAMETYPE <>  C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) 
OR (I.NAMETYPE is not null and C.NAMETYPE is null))
	OR 	( I.EDITATTRIBUTE <>  C.EDITATTRIBUTE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_RECORDALELEMENT]') and xtype='U')
begin
	drop table CCImport_RECORDALELEMENT 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_RECORDALELEMENT  to public
go
