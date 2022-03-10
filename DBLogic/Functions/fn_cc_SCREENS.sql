-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_SCREENS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_SCREENS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_SCREENS.'
	drop function dbo.fn_cc_SCREENS
	print '**** Creating function dbo.fn_cc_SCREENS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_SCREENS]') and xtype='U')
begin
	select * 
	into CCImport_SCREENS 
	from SCREENS
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_SCREENS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_SCREENS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the SCREENS table
-- CALLED BY :	ip_CopyConfigSCREENS
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
	 null as 'Imported Screenname',
	 null as 'Imported Screentitle',
	 null as 'Imported Screentype',
	 null as 'Imported Screenimage',
'D' as '-',
	 C.SCREENNAME as 'Screenname',
	 C.SCREENTITLE as 'Screentitle',
	 C.SCREENTYPE as 'Screentype',
	 CAST(C.SCREENIMAGE AS NVARCHAR(4000)) as 'Screenimage'
from CCImport_SCREENS I 
	right join SCREENS C on( C.SCREENNAME=I.SCREENNAME)
where I.SCREENNAME is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.SCREENNAME,
	 I.SCREENTITLE,
	 I.SCREENTYPE,
	 CAST(I.SCREENIMAGE AS NVARCHAR(4000)),
'I',
	 null ,
	 null ,
	 null ,
	 null
from CCImport_SCREENS I 
	left join SCREENS C on( C.SCREENNAME=I.SCREENNAME)
where C.SCREENNAME is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.SCREENNAME,
	 I.SCREENTITLE,
	 I.SCREENTYPE,
	 CAST(I.SCREENIMAGE AS NVARCHAR(4000)),
'U',
	 C.SCREENNAME,
	 C.SCREENTITLE,
	 C.SCREENTYPE,
	 CAST(C.SCREENIMAGE AS NVARCHAR(4000))
from CCImport_SCREENS I 
	join SCREENS C	on ( C.SCREENNAME=I.SCREENNAME)
where 	( I.SCREENTITLE <>  C.SCREENTITLE OR (I.SCREENTITLE is null and C.SCREENTITLE is not null) 
OR (I.SCREENTITLE is not null and C.SCREENTITLE is null))
	OR 	( I.SCREENTYPE <>  C.SCREENTYPE OR (I.SCREENTYPE is null and C.SCREENTYPE is not null) 
OR (I.SCREENTYPE is not null and C.SCREENTYPE is null))
	OR 	( replace(CAST(I.SCREENIMAGE as NVARCHAR(MAX)),char(10),char(13)+char(10)) <>  CAST(C.SCREENIMAGE as NVARCHAR(MAX)) OR (I.SCREENIMAGE is null and C.SCREENIMAGE is not null) 
OR (I.SCREENIMAGE is not null and C.SCREENIMAGE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_SCREENS]') and xtype='U')
begin
	drop table CCImport_SCREENS 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_SCREENS  to public
go
