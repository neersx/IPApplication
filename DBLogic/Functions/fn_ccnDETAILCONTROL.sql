-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnDETAILCONTROL
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnDETAILCONTROL]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnDETAILCONTROL.'
	drop function dbo.fn_ccnDETAILCONTROL
	print '**** Creating function dbo.fn_ccnDETAILCONTROL...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
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


CREATE FUNCTION dbo.fn_ccnDETAILCONTROL
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnDETAILCONTROL
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the DETAILCONTROL table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 01 May 2017	MF	71205	2	Add new column ISSEPERATOR
--
As 
Return
select	5 as TRIPNO, 'DETAILCONTROL' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_DETAILCONTROL I 
	right join DETAILCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER)
where I.CRITERIANO is null
UNION ALL 
select	5, 'DETAILCONTROL', 0, count(*), 0, 0
from CCImport_DETAILCONTROL I 
	left join DETAILCONTROL C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER)
where C.CRITERIANO is null
UNION ALL 
 select	5, 'DETAILCONTROL', 0, 0, count(*), 0
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
UNION ALL 
 select	5, 'DETAILCONTROL', 0, 0, 0, count(*)
from CCImport_DETAILCONTROL I 
join DETAILCONTROL C	on( C.CRITERIANO=I.CRITERIANO
and C.ENTRYNUMBER=I.ENTRYNUMBER)
where ( I.ENTRYDESC =  C.ENTRYDESC OR (I.ENTRYDESC is null and C.ENTRYDESC is null))
and ( I.TAKEOVERFLAG =  C.TAKEOVERFLAG OR (I.TAKEOVERFLAG is null and C.TAKEOVERFLAG is null))
and ( I.DISPLAYSEQUENCE =  C.DISPLAYSEQUENCE)
and ( I.STATUSCODE =  C.STATUSCODE OR (I.STATUSCODE is null and C.STATUSCODE is null))
and ( I.RENEWALSTATUS =  C.RENEWALSTATUS OR (I.RENEWALSTATUS is null and C.RENEWALSTATUS is null))
and ( I.FILELOCATION =  C.FILELOCATION OR (I.FILELOCATION is null and C.FILELOCATION is null))
and ( I.NUMBERTYPE =  C.NUMBERTYPE OR (I.NUMBERTYPE is null and C.NUMBERTYPE is null))
and ( I.ATLEAST1FLAG =  C.ATLEAST1FLAG OR (I.ATLEAST1FLAG is null and C.ATLEAST1FLAG is null))
and (replace( I.USERINSTRUCTION,char(10),char(13)+char(10)) =  C.USERINSTRUCTION OR (I.USERINSTRUCTION is null and C.USERINSTRUCTION is null))
and ( I.INHERITED =  C.INHERITED OR (I.INHERITED is null and C.INHERITED is null))
and ( I.ENTRYCODE =  C.ENTRYCODE OR (I.ENTRYCODE is null and C.ENTRYCODE is null))
and ( I.CHARGEGENERATION =  C.CHARGEGENERATION OR (I.CHARGEGENERATION is null and C.CHARGEGENERATION is null))
and ( I.DISPLAYEVENTNO =  C.DISPLAYEVENTNO OR (I.DISPLAYEVENTNO is null and C.DISPLAYEVENTNO is null))
and ( I.HIDEEVENTNO =  C.HIDEEVENTNO OR (I.HIDEEVENTNO is null and C.HIDEEVENTNO is null))
and ( I.DIMEVENTNO =  C.DIMEVENTNO OR (I.DIMEVENTNO is null and C.DIMEVENTNO is null))
and ( I.SHOWTABS =  C.SHOWTABS OR (I.SHOWTABS is null and C.SHOWTABS is null))
and ( I.SHOWMENUS =  C.SHOWMENUS OR (I.SHOWMENUS is null and C.SHOWMENUS is null))
and ( I.SHOWTOOLBAR =  C.SHOWTOOLBAR OR (I.SHOWTOOLBAR is null and C.SHOWTOOLBAR is null))
and ( I.PARENTCRITERIANO =  C.PARENTCRITERIANO OR (I.PARENTCRITERIANO is null and C.PARENTCRITERIANO is null))
and ( I.PARENTENTRYNUMBER =  C.PARENTENTRYNUMBER OR (I.PARENTENTRYNUMBER is null and C.PARENTENTRYNUMBER is null))
and ( I.POLICINGIMMEDIATE =  C.POLICINGIMMEDIATE)
and ( I.ISSEPARATOR       =  C.ISSEPARATOR)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DETAILCONTROL]') and xtype='U')
begin
	drop table CCImport_DETAILCONTROL 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnDETAILCONTROL  to public
go
