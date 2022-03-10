-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ccnADJUSTMENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_ccnADJUSTMENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_ccnADJUSTMENT.'
	drop function dbo.fn_ccnADJUSTMENT
	print '**** Creating function dbo.fn_ccnADJUSTMENT...'
	print ''
end
go

SET NOCOUNT ON
GO

-- Table must exist at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ADJUSTMENT]') and xtype='U')
begin
	select * 
	into CCImport_ADJUSTMENT 
	from ADJUSTMENT
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_ccnADJUSTMENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_ccnADJUSTMENT
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the ADJUSTMENT table
-- CALLED BY :	xml_CopyConfigImport
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Feb 2013	System		1	Function generated
-- 11 Apr 2017	MF	71020	2	New columns added.
--
As 
Return
select	2 as TRIPNO, 'ADJUSTMENT' as TABLENAME, count(*) as 'MISSING', 0 as 'NEW', 0 as 'CHANGE', 0 as 'MATCH'
from CCImport_ADJUSTMENT I 
	right join ADJUSTMENT C on( C.ADJUSTMENT=I.ADJUSTMENT)
where I.ADJUSTMENT is null
UNION ALL 
select	2, 'ADJUSTMENT', 0, count(*), 0, 0
from CCImport_ADJUSTMENT I 
	left join ADJUSTMENT C on( C.ADJUSTMENT=I.ADJUSTMENT)
where C.ADJUSTMENT is null
UNION ALL 
 select	2, 'ADJUSTMENT', 0, 0, count(*), 0
from CCImport_ADJUSTMENT I 
	join ADJUSTMENT C	on ( C.ADJUSTMENT=I.ADJUSTMENT)
where 	( I.ADJUSTMENTDESC <>  C.ADJUSTMENTDESC OR (I.ADJUSTMENTDESC is null and C.ADJUSTMENTDESC is not null) 
OR (I.ADJUSTMENTDESC is not null and C.ADJUSTMENTDESC is null))
	OR 	( I.ADJUSTDAY <>  C.ADJUSTDAY OR (I.ADJUSTDAY is null and C.ADJUSTDAY is not null) 
OR (I.ADJUSTDAY is not null and C.ADJUSTDAY is null))
	OR 	( I.ADJUSTMONTH <>  C.ADJUSTMONTH OR (I.ADJUSTMONTH is null and C.ADJUSTMONTH is not null) 
OR (I.ADJUSTMONTH is not null and C.ADJUSTMONTH is null))
	OR 	( I.ADJUSTYEAR <>  C.ADJUSTYEAR OR (I.ADJUSTYEAR is null and C.ADJUSTYEAR is not null) 
OR (I.ADJUSTYEAR is not null and C.ADJUSTYEAR is null))
	OR	( I.ADJUSTAMOUNT <>  C.ADJUSTAMOUNT OR (I.ADJUSTAMOUNT is null and C.ADJUSTAMOUNT is not null) 
OR  (I.ADJUSTAMOUNT is not null and C.ADJUSTAMOUNT is null))
	OR 	( I.PERIODTYPE <>  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) 
OR  (I.PERIODTYPE is not null and C.PERIODTYPE is null))
UNION ALL 
 select	2, 'ADJUSTMENT', 0, 0, 0, count(*)
from CCImport_ADJUSTMENT I 
join ADJUSTMENT C	on( C.ADJUSTMENT=I.ADJUSTMENT)
where ( I.ADJUSTMENTDESC =  C.ADJUSTMENTDESC OR (I.ADJUSTMENTDESC is null and C.ADJUSTMENTDESC is null))
and ( I.ADJUSTDAY        =  C.ADJUSTDAY      OR (I.ADJUSTDAY      is null and C.ADJUSTDAY      is null))
and ( I.ADJUSTMONTH      =  C.ADJUSTMONTH    OR (I.ADJUSTMONTH    is null and C.ADJUSTMONTH    is null))
and ( I.ADJUSTYEAR       =  C.ADJUSTYEAR     OR (I.ADJUSTYEAR     is null and C.ADJUSTYEAR     is null))
and ( I.ADJUSTAMOUNT     =  C.ADJUSTAMOUNT   OR (I.ADJUSTAMOUNT   is null and C.ADJUSTAMOUNT   is null))
and ( I.PERIODTYPE       =  C.PERIODTYPE     OR (I.PERIODTYPE     is null and C.PERIODTYPE     is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ADJUSTMENT]') and xtype='U')
begin
	drop table CCImport_ADJUSTMENT 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_ccnADJUSTMENT  to public
go