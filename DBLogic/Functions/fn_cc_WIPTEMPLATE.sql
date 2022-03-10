-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_cc_WIPTEMPLATE
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[fn_cc_WIPTEMPLATE]') and xtype='IF')
begin
	print '**** Drop function dbo.fn_cc_WIPTEMPLATE.'
	drop function dbo.fn_cc_WIPTEMPLATE
	print '**** Creating function dbo.fn_cc_WIPTEMPLATE...'
	print ''
end
go

SET NOCOUNT ON
go

-- Table must exist in COPYCONFIG user space at time of function creation.
if not exists (select * from sysobjects where id = object_id(N'[CCImport_WIPTEMPLATE]') and xtype='U')
begin
	select * 
	into CCImport_WIPTEMPLATE 
	from WIPTEMPLATE
	where 1=0
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE FUNCTION dbo.fn_cc_WIPTEMPLATE
(
@psUserName			nvarchar(40)	= 'dbo' -- the current user name which will have created the 'CCImport_' tables dbo used as default for security error instead of crash
)
RETURNS TABLE

-- FUNCTION :	fn_cc_WIPTEMPLATE
-- VERSION :	1
-- DESCRIPTION:	The SELECT to display of imported data for the WIPTEMPLATE table
-- CALLED BY :	ip_CopyConfigWIPTEMPLATE
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
	 null as 'Imported Wipcode',
	 null as 'Imported Casetype',
	 null as 'Imported Countrycode',
	 null as 'Imported Propertytype',
	 null as 'Imported Action',
	 null as 'Imported Wiptypeid',
	 null as 'Imported Description',
	 null as 'Imported Wipattribute',
	 null as 'Imported Consolidate',
	 null as 'Imported Taxcode',
	 null as 'Imported Entercreditwip',
	 null as 'Imported Reinstatewip',
	 null as 'Imported Narrativeno',
	 null as 'Imported Wipcodesort',
	 null as 'Imported Usedby',
	 null as 'Imported Tolerancepercent',
	 null as 'Imported Toleranceamt',
	 null as 'Imported Creditwipcode',
	 null as 'Imported Renewalflag',
	 null as 'Imported Statetaxcode',
	 null as 'Imported Notinuseflag',
	 null as 'Imported Enforcewipattrflag',
	 null as 'Imported Preventwritedownflag',
'D' as '-',
	 C.WIPCODE as 'Wipcode',
	 C.CASETYPE as 'Casetype',
	 C.COUNTRYCODE as 'Countrycode',
	 C.PROPERTYTYPE as 'Propertytype',
	 C.ACTION as 'Action',
	 C.WIPTYPEID as 'Wiptypeid',
	 C.DESCRIPTION as 'Description',
	 C.WIPATTRIBUTE as 'Wipattribute',
	 C.CONSOLIDATE as 'Consolidate',
	 C.TAXCODE as 'Taxcode',
	 C.ENTERCREDITWIP as 'Entercreditwip',
	 C.REINSTATEWIP as 'Reinstatewip',
	 C.NARRATIVENO as 'Narrativeno',
	 C.WIPCODESORT as 'Wipcodesort',
	 C.USEDBY as 'Usedby',
	 C.TOLERANCEPERCENT as 'Tolerancepercent',
	 C.TOLERANCEAMT as 'Toleranceamt',
	 C.CREDITWIPCODE as 'Creditwipcode',
	 C.RENEWALFLAG as 'Renewalflag',
	 C.STATETAXCODE as 'Statetaxcode',
	 C.NOTINUSEFLAG as 'Notinuseflag',
	 C.ENFORCEWIPATTRFLAG as 'Enforcewipattrflag',
	 C.PREVENTWRITEDOWNFLAG as 'Preventwritedownflag'
from CCImport_WIPTEMPLATE I 
	right join WIPTEMPLATE C on( C.WIPCODE=I.WIPCODE)
where I.WIPCODE is null
UNION ALL 
select	1,
	'X',
	'I',
	 I.WIPCODE,
	 I.CASETYPE,
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.ACTION,
	 I.WIPTYPEID,
	 I.DESCRIPTION,
	 I.WIPATTRIBUTE,
	 I.CONSOLIDATE,
	 I.TAXCODE,
	 I.ENTERCREDITWIP,
	 I.REINSTATEWIP,
	 I.NARRATIVENO,
	 I.WIPCODESORT,
	 I.USEDBY,
	 I.TOLERANCEPERCENT,
	 I.TOLERANCEAMT,
	 I.CREDITWIPCODE,
	 I.RENEWALFLAG,
	 I.STATETAXCODE,
	 I.NOTINUSEFLAG,
	 I.ENFORCEWIPATTRFLAG,
	 I.PREVENTWRITEDOWNFLAG,
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
from CCImport_WIPTEMPLATE I 
	left join WIPTEMPLATE C on( C.WIPCODE=I.WIPCODE)
where C.WIPCODE is null
UNION ALL 
select	2,
	'O',
	'U',
	 I.WIPCODE,
	 I.CASETYPE,
	 I.COUNTRYCODE,
	 I.PROPERTYTYPE,
	 I.ACTION,
	 I.WIPTYPEID,
	 I.DESCRIPTION,
	 I.WIPATTRIBUTE,
	 I.CONSOLIDATE,
	 I.TAXCODE,
	 I.ENTERCREDITWIP,
	 I.REINSTATEWIP,
	 I.NARRATIVENO,
	 I.WIPCODESORT,
	 I.USEDBY,
	 I.TOLERANCEPERCENT,
	 I.TOLERANCEAMT,
	 I.CREDITWIPCODE,
	 I.RENEWALFLAG,
	 I.STATETAXCODE,
	 I.NOTINUSEFLAG,
	 I.ENFORCEWIPATTRFLAG,
	 I.PREVENTWRITEDOWNFLAG,
'U',
	 C.WIPCODE,
	 C.CASETYPE,
	 C.COUNTRYCODE,
	 C.PROPERTYTYPE,
	 C.ACTION,
	 C.WIPTYPEID,
	 C.DESCRIPTION,
	 C.WIPATTRIBUTE,
	 C.CONSOLIDATE,
	 C.TAXCODE,
	 C.ENTERCREDITWIP,
	 C.REINSTATEWIP,
	 C.NARRATIVENO,
	 C.WIPCODESORT,
	 C.USEDBY,
	 C.TOLERANCEPERCENT,
	 C.TOLERANCEAMT,
	 C.CREDITWIPCODE,
	 C.RENEWALFLAG,
	 C.STATETAXCODE,
	 C.NOTINUSEFLAG,
	 C.ENFORCEWIPATTRFLAG,
	 C.PREVENTWRITEDOWNFLAG
from CCImport_WIPTEMPLATE I 
	join WIPTEMPLATE C	on ( C.WIPCODE=I.WIPCODE)
where 	( I.CASETYPE <>  C.CASETYPE OR (I.CASETYPE is null and C.CASETYPE is not null) 
OR (I.CASETYPE is not null and C.CASETYPE is null))
	OR 	( I.COUNTRYCODE <>  C.COUNTRYCODE OR (I.COUNTRYCODE is null and C.COUNTRYCODE is not null) 
OR (I.COUNTRYCODE is not null and C.COUNTRYCODE is null))
	OR 	( I.PROPERTYTYPE <>  C.PROPERTYTYPE OR (I.PROPERTYTYPE is null and C.PROPERTYTYPE is not null) 
OR (I.PROPERTYTYPE is not null and C.PROPERTYTYPE is null))
	OR 	( I.ACTION <>  C.ACTION OR (I.ACTION is null and C.ACTION is not null) 
OR (I.ACTION is not null and C.ACTION is null))
	OR 	( I.WIPTYPEID <>  C.WIPTYPEID OR (I.WIPTYPEID is null and C.WIPTYPEID is not null) 
OR (I.WIPTYPEID is not null and C.WIPTYPEID is null))
	OR 	( I.DESCRIPTION <>  C.DESCRIPTION OR (I.DESCRIPTION is null and C.DESCRIPTION is not null) 
OR (I.DESCRIPTION is not null and C.DESCRIPTION is null))
	OR 	( I.WIPATTRIBUTE <>  C.WIPATTRIBUTE OR (I.WIPATTRIBUTE is null and C.WIPATTRIBUTE is not null) 
OR (I.WIPATTRIBUTE is not null and C.WIPATTRIBUTE is null))
	OR 	( I.CONSOLIDATE <>  C.CONSOLIDATE OR (I.CONSOLIDATE is null and C.CONSOLIDATE is not null) 
OR (I.CONSOLIDATE is not null and C.CONSOLIDATE is null))
	OR 	( I.TAXCODE <>  C.TAXCODE OR (I.TAXCODE is null and C.TAXCODE is not null) 
OR (I.TAXCODE is not null and C.TAXCODE is null))
	OR 	( I.ENTERCREDITWIP <>  C.ENTERCREDITWIP OR (I.ENTERCREDITWIP is null and C.ENTERCREDITWIP is not null) 
OR (I.ENTERCREDITWIP is not null and C.ENTERCREDITWIP is null))
	OR 	( I.REINSTATEWIP <>  C.REINSTATEWIP OR (I.REINSTATEWIP is null and C.REINSTATEWIP is not null) 
OR (I.REINSTATEWIP is not null and C.REINSTATEWIP is null))
	OR 	( I.NARRATIVENO <>  C.NARRATIVENO OR (I.NARRATIVENO is null and C.NARRATIVENO is not null) 
OR (I.NARRATIVENO is not null and C.NARRATIVENO is null))
	OR 	( I.WIPCODESORT <>  C.WIPCODESORT OR (I.WIPCODESORT is null and C.WIPCODESORT is not null) 
OR (I.WIPCODESORT is not null and C.WIPCODESORT is null))
	OR 	( I.USEDBY <>  C.USEDBY OR (I.USEDBY is null and C.USEDBY is not null) 
OR (I.USEDBY is not null and C.USEDBY is null))
	OR 	( I.TOLERANCEPERCENT <>  C.TOLERANCEPERCENT OR (I.TOLERANCEPERCENT is null and C.TOLERANCEPERCENT is not null) 
OR (I.TOLERANCEPERCENT is not null and C.TOLERANCEPERCENT is null))
	OR 	( I.TOLERANCEAMT <>  C.TOLERANCEAMT OR (I.TOLERANCEAMT is null and C.TOLERANCEAMT is not null) 
OR (I.TOLERANCEAMT is not null and C.TOLERANCEAMT is null))
	OR 	( I.CREDITWIPCODE <>  C.CREDITWIPCODE OR (I.CREDITWIPCODE is null and C.CREDITWIPCODE is not null) 
OR (I.CREDITWIPCODE is not null and C.CREDITWIPCODE is null))
	OR 	( I.RENEWALFLAG <>  C.RENEWALFLAG OR (I.RENEWALFLAG is null and C.RENEWALFLAG is not null) 
OR (I.RENEWALFLAG is not null and C.RENEWALFLAG is null))
	OR 	( I.STATETAXCODE <>  C.STATETAXCODE OR (I.STATETAXCODE is null and C.STATETAXCODE is not null) 
OR (I.STATETAXCODE is not null and C.STATETAXCODE is null))
	OR 	( I.NOTINUSEFLAG <>  C.NOTINUSEFLAG)
	OR 	( I.ENFORCEWIPATTRFLAG <>  C.ENFORCEWIPATTRFLAG OR (I.ENFORCEWIPATTRFLAG is null and C.ENFORCEWIPATTRFLAG is not null) 
OR (I.ENFORCEWIPATTRFLAG is not null and C.ENFORCEWIPATTRFLAG is null))
	OR 	( I.PREVENTWRITEDOWNFLAG <>  C.PREVENTWRITEDOWNFLAG OR (I.PREVENTWRITEDOWNFLAG is null and C.PREVENTWRITEDOWNFLAG is not null) 
OR (I.PREVENTWRITEDOWNFLAG is not null and C.PREVENTWRITEDOWNFLAG is null))

go

-- Remove table now that function is created.
if  exists (select * from sysobjects where id = object_id(N'[CCImport_WIPTEMPLATE]') and xtype='U')
begin
	drop table CCImport_WIPTEMPLATE 
	print ''
end
go
grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_cc_WIPTEMPLATE  to public
go
