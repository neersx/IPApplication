-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnCASERELATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnCASERELATION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnCASERELATION.'
	drop function dbo.fn_ccnCASERELATION
	print '**** Creating function dbo.fn_ccnCASERELATION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_CASERELATION]') and xtype='U')
begin
	select * 
	into CCImport_CASERELATION 
	from CASERELATION
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnCASERELATION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnCASERELATION
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the CASERELATION table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'CASERELATION' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_CASERELATION I 
	right join CASERELATION C on( C.RELATIONSHIP=I.RELATIONSHIP)
where I.RELATIONSHIP is null
UNION ALL 
select	2, 'CASERELATION', 0, count(*), 0, 0
from CCImport_CASERELATION I 
	left join CASERELATION C on( C.RELATIONSHIP=I.RELATIONSHIP)
where C.RELATIONSHIP is null
UNION ALL 
 select	2, 'CASERELATION', 0, 0, count(*), 0
from CCImport_CASERELATION I 
	join CASERELATION C	on ( C.RELATIONSHIP=I.RELATIONSHIP)
where 	( I.EVENTNO <>  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is not null) 
OR (I.EVENTNO is not null and C.EVENTNO is null))
	OR 	( I.EARLIESTDATEFLAG <>  C.EARLIESTDATEFLAG OR (I.EARLIESTDATEFLAG is null and C.EARLIESTDATEFLAG is not null) 
OR (I.EARLIESTDATEFLAG is not null and C.EARLIESTDATEFLAG is null))
	OR 	( I.SHOWFLAG <>  C.SHOWFLAG OR (I.SHOWFLAG is null and C.SHOWFLAG is not null) 
OR (I.SHOWFLAG is not null and C.SHOWFLAG is null))
	OR 	( I.RELATIONSHIPDESC <>  C.RELATIONSHIPDESC OR (I.RELATIONSHIPDESC is null and C.RELATIONSHIPDESC is not null) 
OR (I.RELATIONSHIPDESC is not null and C.RELATIONSHIPDESC is null))
	OR 	( I.POINTERTOPARENT <>  C.POINTERTOPARENT OR (I.POINTERTOPARENT is null and C.POINTERTOPARENT is not null) 
OR (I.POINTERTOPARENT is not null and C.POINTERTOPARENT is null))
	OR 	( I.DISPLAYEVENTONLY <>  C.DISPLAYEVENTONLY OR (I.DISPLAYEVENTONLY is null and C.DISPLAYEVENTONLY is not null) 
OR (I.DISPLAYEVENTONLY is not null and C.DISPLAYEVENTONLY is null))
	OR 	( I.FROMEVENTNO <>  C.FROMEVENTNO OR (I.FROMEVENTNO is null and C.FROMEVENTNO is not null) 
OR (I.FROMEVENTNO is not null and C.FROMEVENTNO is null))
	OR 	( I.DISPLAYEVENTNO <>  C.DISPLAYEVENTNO OR (I.DISPLAYEVENTNO is null and C.DISPLAYEVENTNO is not null) 
OR (I.DISPLAYEVENTNO is not null and C.DISPLAYEVENTNO is null))
	OR 	( I.PRIORARTFLAG <>  C.PRIORARTFLAG OR (I.PRIORARTFLAG is null and C.PRIORARTFLAG is not null) 
OR (I.PRIORARTFLAG is not null and C.PRIORARTFLAG is null))
UNION ALL 
 select	2, 'CASERELATION', 0, 0, 0, count(*)
from CCImport_CASERELATION I 
join CASERELATION C	on( C.RELATIONSHIP=I.RELATIONSHIP)
where ( I.EVENTNO =  C.EVENTNO OR (I.EVENTNO is null and C.EVENTNO is null))
and ( I.EARLIESTDATEFLAG =  C.EARLIESTDATEFLAG OR (I.EARLIESTDATEFLAG is null and C.EARLIESTDATEFLAG is null))
and ( I.SHOWFLAG =  C.SHOWFLAG OR (I.SHOWFLAG is null and C.SHOWFLAG is null))
and ( I.RELATIONSHIPDESC =  C.RELATIONSHIPDESC OR (I.RELATIONSHIPDESC is null and C.RELATIONSHIPDESC is null))
and ( I.POINTERTOPARENT =  C.POINTERTOPARENT OR (I.POINTERTOPARENT is null and C.POINTERTOPARENT is null))
and ( I.DISPLAYEVENTONLY =  C.DISPLAYEVENTONLY OR (I.DISPLAYEVENTONLY is null and C.DISPLAYEVENTONLY is null))
and ( I.FROMEVENTNO =  C.FROMEVENTNO OR (I.FROMEVENTNO is null and C.FROMEVENTNO is null))
and ( I.DISPLAYEVENTNO =  C.DISPLAYEVENTNO OR (I.DISPLAYEVENTNO is null and C.DISPLAYEVENTNO is null))
and ( I.PRIORARTFLAG =  C.PRIORARTFLAG OR (I.PRIORARTFLAG is null and C.PRIORARTFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CASERELATION]') and xtype='U')
begin
	drop table CCImport_CASERELATION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnCASERELATION  to public
go

