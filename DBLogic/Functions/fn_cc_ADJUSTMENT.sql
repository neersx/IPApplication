-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_ADJUSTMENT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_ADJUSTMENT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_ADJUSTMENT.'
	drop function dbo.fn_cc_ADJUSTMENT
	print '**** Creating function dbo.fn_cc_ADJUSTMENT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_ADJUSTMENT]') and xtype='U')
begin
	select * 
	into CCImport_ADJUSTMENT 
	from ADJUSTMENT
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_ADJUSTMENT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_ADJUSTMENT
-- VERSION :	2
-- DESCRIPTION:	The SELECT to display of imported data for the ADJUSTMENT table
-- CALLED BY :	ip_CopyConfigADJUSTMENT
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
	 null as 'Imported Adjustment',
	 null as 'Imported Adjustmentdesc',
	 null as 'Imported Adjustday',
	 null as 'Imported Adjustmonth',
	 null as 'Imported Adjustyear',
	 null as 'Imported Adjustamount',
	 null as 'Imported Periodtype',
	'D' as '-',
	 C.ADJUSTMENT as 'Adjustment',
	 C.ADJUSTMENTDESC as 'Adjustmentdesc',
	 C.ADJUSTDAY as 'Adjustday',
	 C.ADJUSTMONTH as 'Adjustmonth',
	 C.ADJUSTYEAR as 'Adjustyear',
	 C.ADJUSTAMOUNT as 'Adjustamount',
	 C.PERIODTYPE as 'Periodtype'
from CCImport_ADJUSTMENT I 
	right join ADJUSTMENT C on( C.ADJUSTMENT=I.ADJUSTMENT)
where I.ADJUSTMENT is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.ADJUSTMENT,
	 I.ADJUSTMENTDESC,
	 I.ADJUSTDAY,
	 I.ADJUSTMONTH,
	 I.ADJUSTYEAR,
	 I.ADJUSTAMOUNT,
	 I.PERIODTYPE,
	'I',
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null ,
	 null
from CCImport_ADJUSTMENT I 
	left join ADJUSTMENT C on( C.ADJUSTMENT=I.ADJUSTMENT)
where C.ADJUSTMENT is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.ADJUSTMENT,
	 I.ADJUSTMENTDESC,
	 I.ADJUSTDAY,
	 I.ADJUSTMONTH,
	 I.ADJUSTYEAR,
	 I.ADJUSTAMOUNT,
	 I.PERIODTYPE,
	'U',
	 C.ADJUSTMENT,
	 C.ADJUSTMENTDESC,
	 C.ADJUSTDAY,
	 C.ADJUSTMONTH,
	 C.ADJUSTYEAR,
	 C.ADJUSTAMOUNT,
	 C.PERIODTYPE
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
	OR 	( I.ADJUSTAMOUNT <>  C.ADJUSTAMOUNT OR (I.ADJUSTAMOUNT is null and C.ADJUSTAMOUNT is not null) 
OR (I.ADJUSTAMOUNT is not null and C.ADJUSTAMOUNT is null))
	OR 	( I.PERIODTYPE <>  C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) 
OR (I.PERIODTYPE is not null and C.PERIODTYPE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_ADJUSTMENT]') and xtype='U')
begin
	drop table CCImport_ADJUSTMENT 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_ADJUSTMENT  to public
go

