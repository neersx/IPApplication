-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_FEATUREMODULE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_FEATUREMODULE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_FEATUREMODULE.'
	drop function dbo.fn_cc_FEATUREMODULE
	print '**** Creating function dbo.fn_cc_FEATUREMODULE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_FEATUREMODULE]') and xtype='U')
begin
	select * 
	into CCImport_FEATUREMODULE 
	from FEATUREMODULE
	where 1=0
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_FEATUREMODULE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_FEATUREMODULE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the FEATUREMODULE table
-- CALLED BY :	ip_CopyConfigFEATUREMODULE
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
	 null as 'Imported Moduleid',
'D' as '-',
	 C.FEATUREID as 'Featureid',
	 C.MODULEID as 'Moduleid'
from CCImport_FEATUREMODULE I 
	right join FEATUREMODULE C on( C.FEATUREID=I.FEATUREID
and  C.MODULEID=I.MODULEID)
where I.FEATUREID is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.FEATUREID,
	 I.MODULEID,
'I',
	 null ,
	 null
from CCImport_FEATUREMODULE I 
	left join FEATUREMODULE C on( C.FEATUREID=I.FEATUREID
and  C.MODULEID=I.MODULEID)
where C.FEATUREID is null

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_FEATUREMODULE]') and xtype='U')
begin
	drop table CCImport_FEATUREMODULE 
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_FEATUREMODULE  to public
go
