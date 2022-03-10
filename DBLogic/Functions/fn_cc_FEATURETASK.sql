-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FEATURETASK
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FEATURETASK]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FEATURETASK.'
	drop function dbo.fn_cc_FEATURETASK
	print '**** Creating function dbo.fn_cc_FEATURETASK...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEATURETASK]') and xtype='U')
begin
	select * 
	into CCImport_FEATURETASK 
	from FEATURETASK
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_FEATURETASK
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FEATURETASK
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEATURETASK table
-- CALLED BY :	ip_CopyConfigFEATURETASK
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
	 null as 'Imported Featureid',
	 null as 'Imported Taskid',
'D' as '-',
	 C.FEATUREID as 'Featureid',
	 C.TASKID as 'Taskid'
from CCImport_FEATURETASK I 
	right join FEATURETASK C on( C.FEATUREID=I.FEATUREID
and  C.TASKID=I.TASKID)
where I.FEATUREID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.FEATUREID,
	 I.TASKID,
'I',
	 null ,
	 null
from CCImport_FEATURETASK I 
	left join FEATURETASK C on( C.FEATUREID=I.FEATUREID
and  C.TASKID=I.TASKID)
where C.FEATUREID is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEATURETASK]') and xtype='U')
begin
	drop table CCImport_FEATURETASK 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FEATURETASK  to public
go

