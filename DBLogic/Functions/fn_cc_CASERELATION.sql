-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_CASERELATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_CASERELATION]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_CASERELATION.'
	drop function dbo.fn_cc_CASERELATION
	print '**** Creating function dbo.fn_cc_CASERELATION...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
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


CREATE FUNCTION dbo.fn_cc_CASERELATION
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_CASERELATION
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the CASERELATION table
-- CALLED BY :	ip_CopyConfigCASERELATION
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 03 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Relationship',
	 null as 'Imported Eventno',
	 null as 'Imported Earliestdateflag',
	 null as 'Imported Showflag',
	 null as 'Imported Relationshipdesc',
	 null as 'Imported Pointertoparent',
	 null as 'Imported Displayeventonly',
	 null as 'Imported Fromeventno',
	 null as 'Imported Displayeventno',
	 null as 'Imported Priorartflag',
	 null as 'Imported Notes',
	'D' as '-',
	 C.RELATIONSHIP as 'Relationship',
	 C.EVENTNO as 'Eventno',
	 C.EARLIESTDATEFLAG as 'Earliestdateflag',
	 C.SHOWFLAG as 'Showflag',
	 C.RELATIONSHIPDESC as 'Relationshipdesc',
	 C.POINTERTOPARENT as 'Pointertoparent',
	 C.DISPLAYEVENTONLY as 'Displayeventonly',
	 C.FROMEVENTNO as 'Fromeventno',
	 C.DISPLAYEVENTNO as 'Displayeventno',
	 C.PRIORARTFLAG as 'Priorartflag',
	 C.NOTES as 'Notes'
from CCImport_CASERELATION I 
	right join CASERELATION C on( C.RELATIONSHIP=I.RELATIONSHIP)
where I.RELATIONSHIP is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.RELATIONSHIP,
	 I.EVENTNO,
	 I.EARLIESTDATEFLAG,
	 I.SHOWFLAG,
	 I.RELATIONSHIPDESC,
	 I.POINTERTOPARENT,
	 I.DISPLAYEVENTONLY,
	 I.FROMEVENTNO,
	 I.DISPLAYEVENTNO,
	 I.PRIORARTFLAG,
	 I.NOTES,
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
	 null
from CCImport_CASERELATION I 
	left join CASERELATION C on( C.RELATIONSHIP=I.RELATIONSHIP)
where C.RELATIONSHIP is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.RELATIONSHIP,
	 I.EVENTNO,
	 I.EARLIESTDATEFLAG,
	 I.SHOWFLAG,
	 I.RELATIONSHIPDESC,
	 I.POINTERTOPARENT,
	 I.DISPLAYEVENTONLY,
	 I.FROMEVENTNO,
	 I.DISPLAYEVENTNO,
	 I.PRIORARTFLAG,
	 I.NOTES,
	'U',
	 C.RELATIONSHIP,
	 C.EVENTNO,
	 C.EARLIESTDATEFLAG,
	 C.SHOWFLAG,
	 C.RELATIONSHIPDESC,
	 C.POINTERTOPARENT,
	 C.DISPLAYEVENTONLY,
	 C.FROMEVENTNO,
	 C.DISPLAYEVENTNO,
	 C.PRIORARTFLAG,
	 C.NOTES
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
	OR 	( I.NOTES <>  C.NOTES OR (I.NOTES is null and C.NOTES is not null) 
OR (I.NOTES is not null and C.NOTES is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_CASERELATION]') and xtype='U')
begin
	drop table CCImport_CASERELATION 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_CASERELATION  to public
go
