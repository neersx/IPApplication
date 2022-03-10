-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSTATUSCASETYPE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSTATUSCASETYPE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSTATUSCASETYPE.'
	drop function dbo.fn_ccnSTATUSCASETYPE
	print '**** Creating function dbo.fn_ccnSTATUSCASETYPE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_STATUSCASETYPE]') and xtype='U')
begin
	select * 
	into CCImport_STATUSCASETYPE 
	from STATUSCASETYPE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSTATUSCASETYPE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSTATUSCASETYPE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the STATUSCASETYPE table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	5 as TRIPNO, 'STATUSCASETYPE' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_STATUSCASETYPE I 
	right join STATUSCASETYPE C on( C.CASETYPE=I.CASETYPE
and  C.STATUSCODE=I.STATUSCODE)
where I.CASETYPE is null
UNION ALL 
select	5, 'STATUSCASETYPE', 0, count(*), 0, 0
from CCImport_STATUSCASETYPE I 
	left join STATUSCASETYPE C on( C.CASETYPE=I.CASETYPE
and  C.STATUSCODE=I.STATUSCODE)
where C.CASETYPE is null
UNION ALL 
 select	5, 'STATUSCASETYPE', 0, 0, 0, count(*)
from CCImport_STATUSCASETYPE I 
join STATUSCASETYPE C	on( C.CASETYPE=I.CASETYPE
and C.STATUSCODE=I.STATUSCODE)

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_STATUSCASETYPE]') and xtype='U')
begin
	drop table CCImport_STATUSCASETYPE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSTATUSCASETYPE  to public
go
