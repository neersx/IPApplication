-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_DETAILLETTERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_DETAILLETTERS]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_DETAILLETTERS.'
	drop function dbo.fn_cc_DETAILLETTERS
	print '**** Creating function dbo.fn_cc_DETAILLETTERS...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_DETAILLETTERS]') and xtype='U')
begin
	select * 
	into CCImport_DETAILLETTERS 
	from DETAILLETTERS
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_DETAILLETTERS
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_DETAILLETTERS
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the DETAILLETTERS table
-- CALLED BY :	ip_CopyConfigDETAILLETTERS
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
	 null as 'Imported Criteriano',
	 null as 'Imported Entrynumber',
	 null as 'Imported Letterno',
	 null as 'Imported Mandatoryflag',
	 null as 'Imported Deliverymethodflag',
	 null as 'Imported Inherited',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.ENTRYNUMBER as 'Entrynumber',
	 C.LETTERNO as 'Letterno',
	 C.MANDATORYFLAG as 'Mandatoryflag',
	 C.DELIVERYMETHODFLAG as 'Deliverymethodflag',
	 C.INHERITED as 'Inherited'
from CCImport_DETAILLETTERS I 
	right join DETAILLETTERS C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER
and  C.LETTERNO=I.LETTERNO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.ENTRYNUMBER,
	 I.LETTERNO,
	 I.MANDATORYFLAG,
	 I.DELIVERYMETHODFLAG,
	 I.INHERITED,
'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_DETAILLETTERS I 
	left join DETAILLETTERS C on( C.CRITERIANO=I.CRITERIANO
and  C.ENTRYNUMBER=I.ENTRYNUMBER
and  C.LETTERNO=I.LETTERNO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.ENTRYNUMBER,
	 I.LETTERNO,
	 I.MANDATORYFLAG,
	 I.DELIVERYMETHODFLAG,
	 I.INHERITED,
'U',
	 C.CRITERIANO,
	 C.ENTRYNUMBER,
	 C.LETTERNO,
	 C.MANDATORYFLAG,
	 C.DELIVERYMETHODFLAG,
	 C.INHERITED
from CCImport_DETAILLETTERS I 
	join DETAILLETTERS C	on ( C.CRITERIANO=I.CRITERIANO
	and C.ENTRYNUMBER=I.ENTRYNUMBER
	and C.LETTERNO=I.LETTERNO)
where 	( I.MANDATORYFLAG <>  C.MANDATORYFLAG OR (I.MANDATORYFLAG is null and C.MANDATORYFLAG is not null) 
OR (I.MANDATORYFLAG is not null and C.MANDATORYFLAG is null))
	OR 	( I.DELIVERYMETHODFLAG <>  C.DELIVERYMETHODFLAG OR (I.DELIVERYMETHODFLAG is null and C.DELIVERYMETHODFLAG is not null) 
OR (I.DELIVERYMETHODFLAG is not null and C.DELIVERYMETHODFLAG is null))
	OR 	( I.INHERITED <>  C.INHERITED OR (I.INHERITED is null and C.INHERITED is not null) 
OR (I.INHERITED is not null and C.INHERITED is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_DETAILLETTERS]') and xtype='U')
begin
	drop table CCImport_DETAILLETTERS 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_DETAILLETTERS  to public
go
