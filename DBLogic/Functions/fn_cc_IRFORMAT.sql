-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_IRFORMAT
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_IRFORMAT]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_IRFORMAT.'
	drop function dbo.fn_cc_IRFORMAT
	print '**** Creating function dbo.fn_cc_IRFORMAT...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_IRFORMAT]') and xtype='U')
begin
	select * 
	into CCImport_IRFORMAT 
	from IRFORMAT
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_IRFORMAT
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_IRFORMAT
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the IRFORMAT table
-- CALLED BY :	ip_CopyConfigIRFORMAT
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
	 null as 'Imported Segment1',
	 null as 'Imported Segment2',
	 null as 'Imported Segment3',
	 null as 'Imported Segment4',
	 null as 'Imported Segment5',
	 null as 'Imported Instructorflag',
	 null as 'Imported Ownerflag',
	 null as 'Imported Staffflag',
	 null as 'Imported Familyflag',
	 null as 'Imported Segment6',
	 null as 'Imported Segment7',
	 null as 'Imported Segment8',
	 null as 'Imported Segment9',
	 null as 'Imported Segment1code',
	 null as 'Imported Segment2code',
	 null as 'Imported Segment3code',
	 null as 'Imported Segment4code',
	 null as 'Imported Segment5code',
	 null as 'Imported Segment6code',
	 null as 'Imported Segment7code',
	 null as 'Imported Segment8code',
	 null as 'Imported Segment9code',
'D' as '-',
	 C.CRITERIANO as 'Criteriano',
	 C.SEGMENT1 as 'Segment1',
	 C.SEGMENT2 as 'Segment2',
	 C.SEGMENT3 as 'Segment3',
	 C.SEGMENT4 as 'Segment4',
	 C.SEGMENT5 as 'Segment5',
	 C.INSTRUCTORFLAG as 'Instructorflag',
	 C.OWNERFLAG as 'Ownerflag',
	 C.STAFFFLAG as 'Staffflag',
	 C.FAMILYFLAG as 'Familyflag',
	 C.SEGMENT6 as 'Segment6',
	 C.SEGMENT7 as 'Segment7',
	 C.SEGMENT8 as 'Segment8',
	 C.SEGMENT9 as 'Segment9',
	 C.SEGMENT1CODE as 'Segment1code',
	 C.SEGMENT2CODE as 'Segment2code',
	 C.SEGMENT3CODE as 'Segment3code',
	 C.SEGMENT4CODE as 'Segment4code',
	 C.SEGMENT5CODE as 'Segment5code',
	 C.SEGMENT6CODE as 'Segment6code',
	 C.SEGMENT7CODE as 'Segment7code',
	 C.SEGMENT8CODE as 'Segment8code',
	 C.SEGMENT9CODE as 'Segment9code'
from CCImport_IRFORMAT I 
	right join IRFORMAT C on( C.CRITERIANO=I.CRITERIANO)
where I.CRITERIANO is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.CRITERIANO,
	 I.SEGMENT1,
	 I.SEGMENT2,
	 I.SEGMENT3,
	 I.SEGMENT4,
	 I.SEGMENT5,
	 I.INSTRUCTORFLAG,
	 I.OWNERFLAG,
	 I.STAFFFLAG,
	 I.FAMILYFLAG,
	 I.SEGMENT6,
	 I.SEGMENT7,
	 I.SEGMENT8,
	 I.SEGMENT9,
	 I.SEGMENT1CODE,
	 I.SEGMENT2CODE,
	 I.SEGMENT3CODE,
	 I.SEGMENT4CODE,
	 I.SEGMENT5CODE,
	 I.SEGMENT6CODE,
	 I.SEGMENT7CODE,
	 I.SEGMENT8CODE,
	 I.SEGMENT9CODE,
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
	 null ,
	 null ,
	 null
from CCImport_IRFORMAT I 
	left join IRFORMAT C on( C.CRITERIANO=I.CRITERIANO)
where C.CRITERIANO is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.CRITERIANO,
	 I.SEGMENT1,
	 I.SEGMENT2,
	 I.SEGMENT3,
	 I.SEGMENT4,
	 I.SEGMENT5,
	 I.INSTRUCTORFLAG,
	 I.OWNERFLAG,
	 I.STAFFFLAG,
	 I.FAMILYFLAG,
	 I.SEGMENT6,
	 I.SEGMENT7,
	 I.SEGMENT8,
	 I.SEGMENT9,
	 I.SEGMENT1CODE,
	 I.SEGMENT2CODE,
	 I.SEGMENT3CODE,
	 I.SEGMENT4CODE,
	 I.SEGMENT5CODE,
	 I.SEGMENT6CODE,
	 I.SEGMENT7CODE,
	 I.SEGMENT8CODE,
	 I.SEGMENT9CODE,
'U',
	 C.CRITERIANO,
	 C.SEGMENT1,
	 C.SEGMENT2,
	 C.SEGMENT3,
	 C.SEGMENT4,
	 C.SEGMENT5,
	 C.INSTRUCTORFLAG,
	 C.OWNERFLAG,
	 C.STAFFFLAG,
	 C.FAMILYFLAG,
	 C.SEGMENT6,
	 C.SEGMENT7,
	 C.SEGMENT8,
	 C.SEGMENT9,
	 C.SEGMENT1CODE,
	 C.SEGMENT2CODE,
	 C.SEGMENT3CODE,
	 C.SEGMENT4CODE,
	 C.SEGMENT5CODE,
	 C.SEGMENT6CODE,
	 C.SEGMENT7CODE,
	 C.SEGMENT8CODE,
	 C.SEGMENT9CODE
from CCImport_IRFORMAT I 
	join IRFORMAT C	on ( C.CRITERIANO=I.CRITERIANO)
where 	( I.SEGMENT1 <>  C.SEGMENT1 OR (I.SEGMENT1 is null and C.SEGMENT1 is not null) 
OR (I.SEGMENT1 is not null and C.SEGMENT1 is null))
	OR 	( I.SEGMENT2 <>  C.SEGMENT2 OR (I.SEGMENT2 is null and C.SEGMENT2 is not null) 
OR (I.SEGMENT2 is not null and C.SEGMENT2 is null))
	OR 	( I.SEGMENT3 <>  C.SEGMENT3 OR (I.SEGMENT3 is null and C.SEGMENT3 is not null) 
OR (I.SEGMENT3 is not null and C.SEGMENT3 is null))
	OR 	( I.SEGMENT4 <>  C.SEGMENT4 OR (I.SEGMENT4 is null and C.SEGMENT4 is not null) 
OR (I.SEGMENT4 is not null and C.SEGMENT4 is null))
	OR 	( I.SEGMENT5 <>  C.SEGMENT5 OR (I.SEGMENT5 is null and C.SEGMENT5 is not null) 
OR (I.SEGMENT5 is not null and C.SEGMENT5 is null))
	OR 	( I.INSTRUCTORFLAG <>  C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is not null) 
OR (I.INSTRUCTORFLAG is not null and C.INSTRUCTORFLAG is null))
	OR 	( I.OWNERFLAG <>  C.OWNERFLAG OR (I.OWNERFLAG is null and C.OWNERFLAG is not null) 
OR (I.OWNERFLAG is not null and C.OWNERFLAG is null))
	OR 	( I.STAFFFLAG <>  C.STAFFFLAG OR (I.STAFFFLAG is null and C.STAFFFLAG is not null) 
OR (I.STAFFFLAG is not null and C.STAFFFLAG is null))
	OR 	( I.FAMILYFLAG <>  C.FAMILYFLAG OR (I.FAMILYFLAG is null and C.FAMILYFLAG is not null) 
OR (I.FAMILYFLAG is not null and C.FAMILYFLAG is null))
	OR 	( I.SEGMENT6 <>  C.SEGMENT6 OR (I.SEGMENT6 is null and C.SEGMENT6 is not null) 
OR (I.SEGMENT6 is not null and C.SEGMENT6 is null))
	OR 	( I.SEGMENT7 <>  C.SEGMENT7 OR (I.SEGMENT7 is null and C.SEGMENT7 is not null) 
OR (I.SEGMENT7 is not null and C.SEGMENT7 is null))
	OR 	( I.SEGMENT8 <>  C.SEGMENT8 OR (I.SEGMENT8 is null and C.SEGMENT8 is not null) 
OR (I.SEGMENT8 is not null and C.SEGMENT8 is null))
	OR 	( I.SEGMENT9 <>  C.SEGMENT9 OR (I.SEGMENT9 is null and C.SEGMENT9 is not null) 
OR (I.SEGMENT9 is not null and C.SEGMENT9 is null))
	OR 	( I.SEGMENT1CODE <>  C.SEGMENT1CODE OR (I.SEGMENT1CODE is null and C.SEGMENT1CODE is not null) 
OR (I.SEGMENT1CODE is not null and C.SEGMENT1CODE is null))
	OR 	( I.SEGMENT2CODE <>  C.SEGMENT2CODE OR (I.SEGMENT2CODE is null and C.SEGMENT2CODE is not null) 
OR (I.SEGMENT2CODE is not null and C.SEGMENT2CODE is null))
	OR 	( I.SEGMENT3CODE <>  C.SEGMENT3CODE OR (I.SEGMENT3CODE is null and C.SEGMENT3CODE is not null) 
OR (I.SEGMENT3CODE is not null and C.SEGMENT3CODE is null))
	OR 	( I.SEGMENT4CODE <>  C.SEGMENT4CODE OR (I.SEGMENT4CODE is null and C.SEGMENT4CODE is not null) 
OR (I.SEGMENT4CODE is not null and C.SEGMENT4CODE is null))
	OR 	( I.SEGMENT5CODE <>  C.SEGMENT5CODE OR (I.SEGMENT5CODE is null and C.SEGMENT5CODE is not null) 
OR (I.SEGMENT5CODE is not null and C.SEGMENT5CODE is null))
	OR 	( I.SEGMENT6CODE <>  C.SEGMENT6CODE OR (I.SEGMENT6CODE is null and C.SEGMENT6CODE is not null) 
OR (I.SEGMENT6CODE is not null and C.SEGMENT6CODE is null))
	OR 	( I.SEGMENT7CODE <>  C.SEGMENT7CODE OR (I.SEGMENT7CODE is null and C.SEGMENT7CODE is not null) 
OR (I.SEGMENT7CODE is not null and C.SEGMENT7CODE is null))
	OR 	( I.SEGMENT8CODE <>  C.SEGMENT8CODE OR (I.SEGMENT8CODE is null and C.SEGMENT8CODE is not null) 
OR (I.SEGMENT8CODE is not null and C.SEGMENT8CODE is null))
	OR 	( I.SEGMENT9CODE <>  C.SEGMENT9CODE OR (I.SEGMENT9CODE is null and C.SEGMENT9CODE is not null) 
OR (I.SEGMENT9CODE is not null and C.SEGMENT9CODE is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_IRFORMAT]') and xtype='U')
begin
	drop table CCImport_IRFORMAT 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_IRFORMAT  to public
go
