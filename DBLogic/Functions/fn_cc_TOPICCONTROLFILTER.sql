-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_TOPICCONTROLFILTER
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_TOPICCONTROLFILTER]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_TOPICCONTROLFILTER.'
	drop function dbo.fn_cc_TOPICCONTROLFILTER
	print '**** Creating function dbo.fn_cc_TOPICCONTROLFILTER...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICCONTROLFILTER]') and xtype='U')
begin
	select * 
	into CCImport_TOPICCONTROLFILTER 
	from TOPICCONTROLFILTER
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_TOPICCONTROLFILTER
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_TOPICCONTROLFILTER
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the TOPICCONTROL table
-- CALLED BY :	ip_CopyConfigTOPICCONTROL
-- MODIFICATIONS
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 02 Oct 2014	MF	32711	1 	Procedure created
--
As 
Return
select	1 as 'Switch',
	'X' as 'Match',
	'D' as 'Imported -',
	 null as 'Imported Topiccontrolno',
	 null as 'Imported Filtername',
	 null as 'Imported Filtervalue',
	'D' as '-',
	 C.TOPICCONTROLNO as 'Topiccontrolno',
	 C.FILTERNAME as 'Filtername',
	 C.FILTERVALUE as 'Filtervalue'
from CCImport_TOPICCONTROLFILTER I 
	right join TOPICCONTROLFILTER C on( C.TOPICCONTROLFILTERNO=I.TOPICCONTROLFILTERNO)
where I.TOPICCONTROLNO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.TOPICCONTROLNO,
	 I.FILTERNAME,
	 I.FILTERVALUE,
'I',
	 null ,
	 null ,
	 null
from CCImport_TOPICCONTROLFILTER I 
	left join TOPICCONTROLFILTER C on( C.TOPICCONTROLFILTERNO=I.TOPICCONTROLFILTERNO)
where C.TOPICCONTROLFILTERNO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.TOPICCONTROLNO,
	 I.FILTERNAME,
	 I.FILTERVALUE,
'U',
	 C.TOPICCONTROLNO,
	 C.FILTERNAME,
	 C.FILTERVALUE
from CCImport_TOPICCONTROLFILTER I 
	join TOPICCONTROLFILTER C on ( C.TOPICCONTROLFILTERNO=I.TOPICCONTROLFILTERNO)
where 	( I.TOPICCONTROLNO <>  C.TOPICCONTROLNO)
OR 	( I.FILTERNAME <>  C.FILTERNAME OR (I.FILTERNAME is null     and C.FILTERNAME is not null) 
				        OR (I.FILTERNAME is not null and C.FILTERNAME is null))
OR 	(replace( I.FILTERVALUE,char(10),char(13)+char(10)) <>  C.FILTERVALUE OR (I.FILTERVALUE is null     and C.FILTERVALUE is not null) 
									      OR (I.FILTERVALUE is not null and C.FILTERVALUE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_TOPICCONTROLFILTER]') and xtype='U')
begin
	drop table CCImport_TOPICCONTROLFILTER 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_TOPICCONTROLFILTER  to public
go
