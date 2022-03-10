-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnVALIDACTION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnVALIDACTION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnVALIDACTION.'
	drop function dbo.fn_ccnVALIDACTION
	print '**** Creating function dbo.fn_ccnVALIDACTION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDACTION]') and xtype='U')
begin
	select * 
	into CCImport_VALIDACTION 
	from VALIDACTION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnVALIDACTION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnVALIDACTION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the VALIDACTION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	3 as TRIPNO, 'VALIDACTION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_VALIDACTION I 
	right join VALIDACTION C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.ACTION=I.ACTION)
where I.COUNTRYCODE is null
UNION ALL 
select	3, 'VALIDACTION', 0, count(*), 0, 0
from CCImport_VALIDACTION I 
	left join VALIDACTION C on( C.COUNTRYCODE=I.COUNTRYCODE
and  C.PROPERTYTYPE=I.PROPERTYTYPE
and  C.CASETYPE=I.CASETYPE
and  C.ACTION=I.ACTION)
where C.COUNTRYCODE is null
UNION ALL 
 select	3, 'VALIDACTION', 0, 0, count(*), 0
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
UNION ALL 
 select	3, 'VALIDACTION', 0, 0, 0, count(*)
from CCImport_VALIDACTION I 
join VALIDACTION C	on( C.COUNTRYCODE=I.COUNTRYCODE
and C.PROPERTYTYPE=I.PROPERTYTYPE
and C.CASETYPE=I.CASETYPE
and C.ACTION=I.ACTION)
where ( I.ACTIONNAME =  C.ACTIONNAME OR (I.ACTIONNAME is null and C.ACTIONNAME is null))
and ( I.ACTEVENTNO =  C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is null))
and ( I.RETROEVENTNO =  C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is null))
and ( I.DISPLAYSEQUENCE =  C.DISPLAYSEQUENCE OR (I.DISPLAYSEQUENCE is null and C.DISPLAYSEQUENCE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_VALIDACTION]') and xtype='U')
begin
	drop table CCImport_VALIDACTION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnVALIDACTION  to public
go
