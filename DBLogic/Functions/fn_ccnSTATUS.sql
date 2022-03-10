-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnSTATUS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnSTATUS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnSTATUS.'
	drop function dbo.fn_ccnSTATUS
	print '**** Creating function dbo.fn_ccnSTATUS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_STATUS]') and xtype='U')
begin
	select * 
	into CCImport_STATUS 
	from STATUS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnSTATUS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnSTATUS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the STATUS table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
--
As 
Return
select	2 as TRIPNO, 'STATUS' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_STATUS I 
	right join STATUS C on( C.STATUSCODE=I.STATUSCODE)
where I.STATUSCODE is null
UNION ALL 
select	2, 'STATUS', 0, count(*), 0, 0
from CCImport_STATUS I 
	left join STATUS C on( C.STATUSCODE=I.STATUSCODE)
where C.STATUSCODE is null
UNION ALL 
 select	2, 'STATUS', 0, 0, count(*), 0
from CCImport_STATUS I 
	join STATUS C	on ( C.STATUSCODE=I.STATUSCODE)
where 	( I.USERSTATUSCODE <>  C.USERSTATUSCODE OR (I.USERSTATUSCODE is null and C.USERSTATUSCODE is not null) 
OR (I.USERSTATUSCODE is not null and C.USERSTATUSCODE is null))
	OR 	( I.INTERNALDESC <>  C.INTERNALDESC OR (I.INTERNALDESC is null and C.INTERNALDESC is not null) 
OR (I.INTERNALDESC is not null and C.INTERNALDESC is null))
	OR 	( I.EXTERNALDESC <>  C.EXTERNALDESC OR (I.EXTERNALDESC is null and C.EXTERNALDESC is not null) 
OR (I.EXTERNALDESC is not null and C.EXTERNALDESC is null))
	OR 	( I.LIVEFLAG <>  C.LIVEFLAG OR (I.LIVEFLAG is null and C.LIVEFLAG is not null) 
OR (I.LIVEFLAG is not null and C.LIVEFLAG is null))
	OR 	( I.REGISTEREDFLAG <>  C.REGISTEREDFLAG OR (I.REGISTEREDFLAG is null and C.REGISTEREDFLAG is not null) 
OR (I.REGISTEREDFLAG is not null and C.REGISTEREDFLAG is null))
	OR 	( I.RENEWALFLAG <>  C.RENEWALFLAG OR (I.RENEWALFLAG is null and C.RENEWALFLAG is not null) 
OR (I.RENEWALFLAG is not null and C.RENEWALFLAG is null))
	OR 	( I.POLICERENEWALS <>  C.POLICERENEWALS OR (I.POLICERENEWALS is null and C.POLICERENEWALS is not null) 
OR (I.POLICERENEWALS is not null and C.POLICERENEWALS is null))
	OR 	( I.POLICEEXAM <>  C.POLICEEXAM OR (I.POLICEEXAM is null and C.POLICEEXAM is not null) 
OR (I.POLICEEXAM is not null and C.POLICEEXAM is null))
	OR 	( I.POLICEOTHERACTIONS <>  C.POLICEOTHERACTIONS OR (I.POLICEOTHERACTIONS is null and C.POLICEOTHERACTIONS is not null) 
OR (I.POLICEOTHERACTIONS is not null and C.POLICEOTHERACTIONS is null))
	OR 	( I.LETTERSALLOWED <>  C.LETTERSALLOWED OR (I.LETTERSALLOWED is null and C.LETTERSALLOWED is not null) 
OR (I.LETTERSALLOWED is not null and C.LETTERSALLOWED is null))
	OR 	( I.CHARGESALLOWED <>  C.CHARGESALLOWED OR (I.CHARGESALLOWED is null and C.CHARGESALLOWED is not null) 
OR (I.CHARGESALLOWED is not null and C.CHARGESALLOWED is null))
	OR 	( I.REMINDERSALLOWED <>  C.REMINDERSALLOWED OR (I.REMINDERSALLOWED is null and C.REMINDERSALLOWED is not null) 
OR (I.REMINDERSALLOWED is not null and C.REMINDERSALLOWED is null))
	OR 	( I.CONFIRMATIONREQ <>  C.CONFIRMATIONREQ)
	OR 	( I.STOPPAYREASON <>  C.STOPPAYREASON OR (I.STOPPAYREASON is null and C.STOPPAYREASON is not null) 
OR (I.STOPPAYREASON is not null and C.STOPPAYREASON is null))
	OR 	( I.PREVENTWIP <>  C.PREVENTWIP OR (I.PREVENTWIP is null and C.PREVENTWIP is not null) 
OR (I.PREVENTWIP is not null and C.PREVENTWIP is null))
	OR 	( I.PREVENTBILLING <>  C.PREVENTBILLING OR (I.PREVENTBILLING is null and C.PREVENTBILLING is not null) 
OR (I.PREVENTBILLING is not null and C.PREVENTBILLING is null))
	OR 	( I.PREVENTPREPAYMENT <>  C.PREVENTPREPAYMENT OR (I.PREVENTPREPAYMENT is null and C.PREVENTPREPAYMENT is not null) 
OR (I.PREVENTPREPAYMENT is not null and C.PREVENTPREPAYMENT is null))
	OR 	( I.PRIORARTFLAG <>  C.PRIORARTFLAG OR (I.PRIORARTFLAG is null and C.PRIORARTFLAG is not null) 
OR (I.PRIORARTFLAG is not null and C.PRIORARTFLAG is null))
/* DISPLAYSEQUENCE : column intentionally excluded from comparison display but will be updated if different. */
UNION ALL 
 select	2, 'STATUS', 0, 0, 0, count(*)
from CCImport_STATUS I 
join STATUS C	on( C.STATUSCODE=I.STATUSCODE)
where ( I.USERSTATUSCODE =  C.USERSTATUSCODE OR (I.USERSTATUSCODE is null and C.USERSTATUSCODE is null))
and ( I.INTERNALDESC =  C.INTERNALDESC OR (I.INTERNALDESC is null and C.INTERNALDESC is null))
and ( I.EXTERNALDESC =  C.EXTERNALDESC OR (I.EXTERNALDESC is null and C.EXTERNALDESC is null))
and ( I.LIVEFLAG =  C.LIVEFLAG OR (I.LIVEFLAG is null and C.LIVEFLAG is null))
and ( I.REGISTEREDFLAG =  C.REGISTEREDFLAG OR (I.REGISTEREDFLAG is null and C.REGISTEREDFLAG is null))
and ( I.RENEWALFLAG =  C.RENEWALFLAG OR (I.RENEWALFLAG is null and C.RENEWALFLAG is null))
and ( I.POLICERENEWALS =  C.POLICERENEWALS OR (I.POLICERENEWALS is null and C.POLICERENEWALS is null))
and ( I.POLICEEXAM =  C.POLICEEXAM OR (I.POLICEEXAM is null and C.POLICEEXAM is null))
and ( I.POLICEOTHERACTIONS =  C.POLICEOTHERACTIONS OR (I.POLICEOTHERACTIONS is null and C.POLICEOTHERACTIONS is null))
and ( I.LETTERSALLOWED =  C.LETTERSALLOWED OR (I.LETTERSALLOWED is null and C.LETTERSALLOWED is null))
and ( I.CHARGESALLOWED =  C.CHARGESALLOWED OR (I.CHARGESALLOWED is null and C.CHARGESALLOWED is null))
and ( I.REMINDERSALLOWED =  C.REMINDERSALLOWED OR (I.REMINDERSALLOWED is null and C.REMINDERSALLOWED is null))
and ( I.CONFIRMATIONREQ =  C.CONFIRMATIONREQ)
and ( I.STOPPAYREASON =  C.STOPPAYREASON OR (I.STOPPAYREASON is null and C.STOPPAYREASON is null))
and ( I.PREVENTWIP =  C.PREVENTWIP OR (I.PREVENTWIP is null and C.PREVENTWIP is null))
and ( I.PREVENTBILLING =  C.PREVENTBILLING OR (I.PREVENTBILLING is null and C.PREVENTBILLING is null))
and ( I.PREVENTPREPAYMENT =  C.PREVENTPREPAYMENT OR (I.PREVENTPREPAYMENT is null and C.PREVENTPREPAYMENT is null))
and ( I.PRIORARTFLAG =  C.PRIORARTFLAG OR (I.PRIORARTFLAG is null and C.PRIORARTFLAG is null))
/* DISPLAYSEQUENCE : column intentionally excluded from comparison display but will be updated if different. */

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_STATUS]') and xtype='U')
begin
	drop table CCImport_STATUS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnSTATUS  to public
go

