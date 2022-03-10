-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_VALIDACTION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_VALIDACTION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_VALIDACTION.'
	drop function dbo.fn_cc_VALIDACTION
	print '**** Creating function dbo.fn_cc_VALIDACTION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDACTION]') and xtype='U')
begin
	select * 
	into CCImport_VALIDACTION 
	from VALIDACTION
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_VALIDACTION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_VALIDACTION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDACTION table
-- CALLED BY :	ip_CopyConfigVALIDACTION
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
	 null as 'Imported Casetype',
	 null as 'Imported Action',
	 null as 'Imported Actionname',
	 null as 'Imported Acteventno',
	 null as 'Imported Retroeventno',
	 null as 'Imported Displaysequence',
'D' as '-',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.CASETYPE as 'Casetype',
	 C.ACTION as 'Action',
	 C.ACTIONNAME as 'Actionname',
	 C.ACTEVENTNO as 'Acteventno',
	 C.RETROEVENTNO as 'Retroeventno',
	 C.DISPLAYSEQUENCE as 'Displaysequence'
from CCImport_VALIDACTION I 
	right join VALIDACTION C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.ACTION=I.ACTION)
where I.COUNTRYCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASETYPE,
	 I.ACTION,
	 I.ACTIONNAME,
	 I.ACTEVENTNO,
	 I.RETROEVENTNO,
	 I.DISPLAYSEQUENCE,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_VALIDACTION I 
	left join VALIDACTION C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.ACTION=I.ACTION)
where C.COUNTRYCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.CASETYPE,
	 I.ACTION,
	 I.ACTIONNAME,
	 I.ACTEVENTNO,
	 I.RETROEVENTNO,
	 I.DISPLAYSEQUENCE,
'U',
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.CASETYPE,
	 C.ACTION,
	 C.ACTIONNAME,
	 C.ACTEVENTNO,
	 C.RETROEVENTNO,
	 C.DISPLAYSEQUENCE
from CCImport_VALIDACTION I 
	join VALIDACTION C	on ( C.COUNTRYCODE=I.COUNTRYCODE
	and C.PROPERTYTYPE=I.PROPERTYTYPE
	and C.CASETYPE=I.CASETYPE
	and C.ACTION=I.ACTION)
where 	( I.ACTIONNAME <>  C.ACTIONNAME OR (I.ACTIONNAME is null and C.ACTIONNAME is not null) 
OR (I.ACTIONNAME is not null and C.ACTIONNAME is null))
	OR 	( I.ACTEVENTNO <>  C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is not null) 
OR (I.ACTEVENTNO is not null and C.ACTEVENTNO is null))
	OR 	( I.RETROEVENTNO <>  C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) 
OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null))
	OR 	( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is not null) 
OR (I.DISPLAYSEQUENCE is not null and C.DISPLAYSEQUENCE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDACTION]') and xtype='U')
begin
	drop table CCImport_VALIDACTION 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_VALIDACTION  to public
go
