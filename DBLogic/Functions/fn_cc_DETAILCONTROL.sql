-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DETAILCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DETAILCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DETAILCONTROL.'
	drop function dbo.fn_cc_DETAILCONTROL
	print '**** Creating function dbo.fn_cc_DETAILCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DETAILCONTROL]') and xtype='U')
begin
	select * 
	into CCImport_DETAILCONTROL 
	from DETAILCONTROL
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DETAILCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DETAILCONTROL
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the DETAILCONTROL table
-- CALLED BY :	ip_CopyConfigDETAILCONTROL
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 01 May 2017	MF	71205	2	Add new column ISSEPERATOR
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Criteriano',
	 null as 'Imported Entrynumber',
	 null as 'Imported Entrydesc',
	 null as 'Imported Takeoverflag',
	 null as 'Imported Displaysequence',
	 null as 'Imported Statuscode',
	 null as 'Imported Renewalstatus',
	 null as 'Imported Filelocation',
	 null as 'Imported Numbertype',
	 null as 'Imported Atleast1flag',
	 null as 'Imported Userinstruction',
	 null as 'Imported Inherited',
	 null as 'Imported Entrycode',
	 null as 'Imported Chargegeneration',
	 null as 'Imported Displayeventno',
	 null as 'Imported Hideeventno',
	 null as 'Imported Dimeventno',
	 null as 'Imported Showtabs',
	 null as 'Imported Showmenus',
	 null as 'Imported Showtoolbar',
	 null as 'Imported Parentcriteriano',
	 null as 'Imported Parententrynumber',
	 null as 'Imported Policingimmediate',
	 null as 'Imported Isseparator',
	'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.ENTRYNUMBER as 'Entrynumber',
	 C.ENTRYDESC as 'Entrydesc',
	 C.TAKEOVERFLAG as 'Takeoverflag',
	 C.DISPLAYSEQUENCE as 'Displaysequence',
	 C.STATUSCODE as 'Statuscode',
	 C.RENEWALSTATUS as 'Renewalstatus',
	 C.FILELOCATION as 'Filelocation',
	 C.NUMBERTYPE as 'Numbertype',
	 C.ATLEAST1FLAG as 'Atleast1flag',
	 C.USERINSTRUCTION as 'Userinstruction',
	 C.INHERITED as 'Inherited',
	 C.ENTRYCODE as 'Entrycode',
	 C.CHARGEGENERATION as 'Chargegeneration',
	 C.DISPLAYEVENTNO as 'Displayeventno',
	 C.HIDEEVENTNO as 'Hideeventno',
	 C.DIMEVENTNO as 'Dimeventno',
	 C.SHOWTABS as 'Showtabs',
	 C.SHOWMENUS as 'Showmenus',
	 C.SHOWTOOLBAR as 'Showtoolbar',
	 C.PARENTCRITERIANO as 'Parentcriteriano',
	 C.PARENTENTRYNUMBER as 'Parententrynumber',
	 C.POLICINGIMMEDIATE as 'Policingimmediate',
	 C.ISSEPARATOR as 'Isseparator'
from CCImport_DETAILCONTROL I 
	right join DETAILCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.ENTRYNUMBER,
	 I.ENTRYDESC,
	 I.TAKEOVERFLAG,
	 I.DISPLAYSEQUENCE,
	 I.STATUSCODE,
	 I.RENEWALSTATUS,
	 I.FILELOCATION,
	 I.NUMBERTYPE,
	 I.ATLEAST1FLAG,
	 I.USERINSTRUCTION,
	 I.INHERITED,
	 I.ENTRYCODE,
	 I.CHARGEGENERATION,
	 I.DISPLAYEVENTNO,
	 I.HIDEEVENTNO,
	 I.DIMEVENTNO,
	 I.SHOWTABS,
	 I.SHOWMENUS,
	 I.SHOWTOOLBAR,
	 I.PARENTCRITERIANO,
	 I.PARENTENTRYNUMBER,
	 I.POLICINGIMMEDIATE,
	 I.ISSEPARATOR,
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
	 null ,
	 null
from CCImport_DETAILCONTROL I 
	left join DETAILCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.ENTRYNUMBER,
	 I.ENTRYDESC,
	 I.TAKEOVERFLAG,
	 I.DISPLAYSEQUENCE,
	 I.STATUSCODE,
	 I.RENEWALSTATUS,
	 I.FILELOCATION,
	 I.NUMBERTYPE,
	 I.ATLEAST1FLAG,
	 I.USERINSTRUCTION,
	 I.INHERITED,
	 I.ENTRYCODE,
	 I.CHARGEGENERATION,
	 I.DISPLAYEVENTNO,
	 I.HIDEEVENTNO,
	 I.DIMEVENTNO,
	 I.SHOWTABS,
	 I.SHOWMENUS,
	 I.SHOWTOOLBAR,
	 I.PARENTCRITERIANO,
	 I.PARENTENTRYNUMBER,
	 I.POLICINGIMMEDIATE,
	 I.ISSEPARATOR,
	'U',
	 C.CRITERIANO,
	 C.ENTRYNUMBER,
	 C.ENTRYDESC,
	 C.TAKEOVERFLAG,
	 C.DISPLAYSEQUENCE,
	 C.STATUSCODE,
	 C.RENEWALSTATUS,
	 C.FILELOCATION,
	 C.NUMBERTYPE,
	 C.ATLEAST1FLAG,
	 C.USERINSTRUCTION,
	 C.INHERITED,
	 C.ENTRYCODE,
	 C.CHARGEGENERATION,
	 C.DISPLAYEVENTNO,
	 C.HIDEEVENTNO,
	 C.DIMEVENTNO,
	 C.SHOWTABS,
	 C.SHOWMENUS,
	 C.SHOWTOOLBAR,
	 C.PARENTCRITERIANO,
	 C.PARENTENTRYNUMBER,
	 C.POLICINGIMMEDIATE,
	 C.ISSEPARATOR
from CCImport_DETAILCONTROL I 
	join DETAILCONTROL C	on ( C.CRITERIANO=I.CRITERIANO
	and C.ENTRYNUMBER=I.ENTRYNUMBER)
where 	( I.ENTRYDESC <>  C.ENTRYDESC OR (I.ENTRYDESC is null and C.ENTRYDESC is not null) 
OR (I.ENTRYDESC is not null and C.ENTRYDESC is null))
	OR 	( I.TAKEOVERFLAG <>  C.TAKEOVERFLAG OR (I.TAKEOVERFLAG is null and C.TAKEOVERFLAG is not null) 
OR (I.TAKEOVERFLAG is not null and C.TAKEOVERFLAG is null))
	OR 	( I.DISPLAYSEQUENCE <>  C.DISPLAYSEQUENCE)
	OR 	( I.STATUSCODE <>  C.STATUSCODE OR (I.STATUSCODE is null and C.STATUSCODE is not null) 
OR (I.STATUSCODE is not null and C.STATUSCODE is null))
	OR 	( I.RENEWALSTATUS <>  C.RENEWALSTATUS OR (I.RENEWALSTATUS is null and C.RENEWALSTATUS is not null) 
OR (I.RENEWALSTATUS is not null and C.RENEWALSTATUS is null))
	OR 	( I.FILELOCATION <>  C.FILELOCATION OR (I.FILELOCATION is null and C.FILELOCATION is not null) 
OR (I.FILELOCATION is not null and C.FILELOCATION is null))
	OR 	( I.NUMBERTYPE <>  C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is not null) 
OR (I.NUMBERTYPE is not null and C.NUMBERTYPE is null))
	OR 	( I.ATLEAST1FLAG <>  C.ATLEAST1FLAG OR (I.ATLEAST1FLAG is null and C.ATLEAST1FLAG is not null) 
OR (I.ATLEAST1FLAG is not null and C.ATLEAST1FLAG is null))
	OR 	(replace( I.USERINSTRUCTION,char(10),char(13)+char(10)) <>  C.USERINSTRUCTION OR (I.USERINSTRUCTION is null and C.USERINSTRUCTION is not null) 
OR (I.USERINSTRUCTION is not null and C.USERINSTRUCTION is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))
	OR 	( I.ENTRYCODE <>  C.ENTRYCODE OR (I.ENTRYCODE is null and C.ENTRYCODE is not null) 
OR (I.ENTRYCODE is not null and C.ENTRYCODE is null))
	OR 	( I.CHARGEGENERATION <>  C.CHARGEGENERATION OR (I.CHARGEGENERATION is null and C.CHARGEGENERATION is not null) 
OR (I.CHARGEGENERATION is not null and C.CHARGEGENERATION is null))
	OR 	( I.DISPLAYEVENTNO <>  C.DISPLAYEVENTNO OR (I.DISPLAYEVENTNO is null and C.DISPLAYEVENTNO is not null) 
OR (I.DISPLAYEVENTNO is not null and C.DISPLAYEVENTNO is null))
	OR 	( I.HIDEEVENTNO <>  C.HIDEEVENTNO OR (I.HIDEEVENTNO is null and C.HIDEEVENTNO is not null) 
OR (I.HIDEEVENTNO is not null and C.HIDEEVENTNO is null))
	OR 	( I.DIMEVENTNO <>  C.DIMEVENTNO OR (I.DIMEVENTNO is null and C.DIMEVENTNO is not null) 
OR (I.DIMEVENTNO is not null and C.DIMEVENTNO is null))
	OR 	( I.SHOWTABS <>  C.SHOWTABS OR (I.SHOWTABS is null and C.SHOWTABS is not null) 
OR (I.SHOWTABS is not null and C.SHOWTABS is null))
	OR 	( I.SHOWMENUS <>  C.SHOWMENUS OR (I.SHOWMENUS is null and C.SHOWMENUS is not null) 
OR (I.SHOWMENUS is not null and C.SHOWMENUS is null))
	OR 	( I.SHOWTOOLBAR <>  C.SHOWTOOLBAR OR (I.SHOWTOOLBAR is null and C.SHOWTOOLBAR is not null) 
OR (I.SHOWTOOLBAR is not null and C.SHOWTOOLBAR is null))
	OR 	( I.PARENTCRITERIANO <>  C.PARENTCRITERIANO OR (I.PARENTCRITERIANO is null and C.PARENTCRITERIANO is not null) 
OR (I.PARENTCRITERIANO is not null and C.PARENTCRITERIANO is null))
	OR 	( I.PARENTENTRYNUMBER <>  C.PARENTENTRYNUMBER OR (I.PARENTENTRYNUMBER is null and C.PARENTENTRYNUMBER is not null) 
OR (I.PARENTENTRYNUMBER is not null and C.PARENTENTRYNUMBER is null))
	OR 	( I.POLICINGIMMEDIATE <>  C.POLICINGIMMEDIATE)
	OR 	( I.ISSEPARATOR       <>  C.ISSEPARATOR)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DETAILCONTROL]') and xtype='U')
begin
	drop table CCImport_DETAILCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DETAILCONTROL  to public
go
