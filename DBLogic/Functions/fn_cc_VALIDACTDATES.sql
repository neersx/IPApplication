-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDACTDATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDACTDATES]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDACTDATES.'
	drop function dbo.fn_cc_VALIDACTDATES
	print '**** Creating function dbo.fn_cc_VALIDACTDATES...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDACTDATES]') and xtype='U')
begin
	select * 
	into CCImport_VALIDACTDATES 
	from VALIDACTDATES
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDACTDATES
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDACTDATES
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDACTDATES table
-- CALLED BY :	ip_CopyConfigVALIDACTDATES
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
	 null as 'Imported Countrycode',
	 null as 'Imported Propertytype',
	 null as 'Imported Dateofact',
	 null as 'Imported Sequenceno',
	 null as 'Imported Retrospectiveactio',
	 null as 'Imported Acteventno',
	 null as 'Imported Retroeventno',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.DATEOFACT as 'Dateofact',
	 C.SEQUENCENO as 'Sequenceno',
	 C.RETROSPECTIVEACTIO as 'Retrospectiveactio',
	 C.ACTEVENTNO as 'Acteventno',
	 C.RETROEVENTNO as 'Retroeventno'
from CCImport_VALIDACTDATES I 
	right join VALIDACTDATES C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.DATEOFACT=I.DATEOFACT
and  C.SEQUENCENO=I.SEQUENCENO)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.DATEOFACT,
	 I.SEQUENCENO,
	 I.RETROSPECTIVEACTIO,
	 I.ACTEVENTNO,
	 I.RETROEVENTNO,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDACTDATES I 
	left join VALIDACTDATES C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.DATEOFACT=I.DATEOFACT
and  C.SEQUENCENO=I.SEQUENCENO)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.DATEOFACT,
	 I.SEQUENCENO,
	 I.RETROSPECTIVEACTIO,
	 I.ACTEVENTNO,
	 I.RETROEVENTNO,
'U',
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.DATEOFACT,
	 C.SEQUENCENO,
	 C.RETROSPECTIVEACTIO,
	 C.ACTEVENTNO,
	 C.RETROEVENTNO
from CCImport_VALIDACTDATES I 
	join VALIDACTDATES C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.DATEOFACT=I.DATEOFACT
	and C.SEQUENCENO=I.SEQUENCENO)
where 	( I.RETROSPECTIVEACTIO <>  C.RETROSPECTIVEACTIO OR (I.RETROSPECTIVEACTIO is null and C.RETROSPECTIVEACTIO is not null) 
OR (I.RETROSPECTIVEACTIO is not null and C.RETROSPECTIVEACTIO is null))
	OR 	( I.ACTEVENTNO <>  C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is not null) 
OR (I.ACTEVENTNO is not null and C.ACTEVENTNO is null))
	OR 	( I.RETROEVENTNO <>  C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) 
OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDACTDATES]') and xtype='U')
begin
	drop table CCImport_VALIDACTDATES 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDACTDATES  to public
go
