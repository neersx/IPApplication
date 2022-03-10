-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListValidProperty
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListValidProperty]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListValidProperty'
	drop procedure [dbo].[wa_ListValidProperty]
	print '**** Creating procedure dbo.wa_ListValidProperty...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

CREATE PROCEDURE [dbo].[wa_ListValidProperty]
	@sCountry	 	varchar(20) = NULL

-- PROCEDURE :	wa_ListValidProperty
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns a list of all properties for a given country code
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 01/07/2001	AF	Procedure created
-- 27/08/2001	MF	If CountryCode is not passed as a parameter then use the PropertyType table.
-- 25/09/2001	MF	Restrict the list of property types if the user has limited access

AS
begin
	-- disable row counts
	set nocount on
	
	-- declare variables
	declare	@ErrorCode	int
	declare @sSql		nvarchar(4000)	-- to allow a dynamically constructed select

	-- initialise variables
	set @ErrorCode=0

	if  @sCountry is not null
	begin
		set @sSql=		"Select P.PROPERTYTYPE, P.PROPERTYNAME"
			 +char(10)+	"From  USERROWACCESS U"
			 +char(10)+	"join ROWACCESSDETAIL R	on (R.ACCESSNAME= U.ACCESSNAME)"
			 +char(10)+	"join VALIDPROPERTY P	on (P.PROPERTYTYPE=R.PROPERTYTYPE"
			 +char(10)+	"			and P.COUNTRYCODE=(	select min(P1.COUNTRYCODE)"
			 +char(10)+	"						from VALIDPROPERTY P1"
			 +char(10)+	"						where P1.COUNTRYCODE in ('"+@sCountry+"','ZZZ')))"
			 +char(10)+	"Where U.USERID = user"
			 +char(10)+	"And R.RECORDTYPE = 'C'"  
			 +char(10)+	"And R.SECURITYFLAG   IN ( 1,3,5,7,9,11,13,15 )"
			 +char(10)+	"And R.PROPERTYTYPE IS NOT NULL"
			 +char(10)+	"UNION"
			 +char(10)+	"Select P.PROPERTYTYPE, P.PROPERTYNAME"
			 +char(10)+	"From VALIDPROPERTY P"
			 +char(10)+	"Where P.COUNTRYCODE=(	select min(P1.COUNTRYCODE)"
			 +char(10)+	"			from VALIDPROPERTY P1"
			 +char(10)+	"			where P1.COUNTRYCODE in ('"+@sCountry+"','ZZZ'))"
			 +char(10)+	"and ( exists"
			 +char(10)+	"(select * from USERROWACCESS U"
			 +char(10)+	" join ROWACCESSDETAIL R	on (R.ACCESSNAME= U.ACCESSNAME)"
			 +char(10)+	" Where U.USERID = user"
			 +char(10)+	" And R.RECORDTYPE = 'C'" 
			 +char(10)+	" And R.SECURITYFLAG  IN ( 1,3,5,7,9,11,13,15 )"
			 +char(10)+	" And R.PROPERTYTYPE  is  NULL)"
			 +char(10)+	"OR not exists"
			 +char(10)+	"(select * from USERROWACCESS U"
			 +char(10)+	" join ROWACCESSDETAIL R	on (R.ACCESSNAME= U.ACCESSNAME)"
			 +char(10)+	" Where R.RECORDTYPE = 'C') )"
			 +char(10)+	"and not exists"
			 +char(10)+	"(select * from USERROWACCESS U"
			 +char(10)+	" join ROWACCESSDETAIL R	on (R.ACCESSNAME= U.ACCESSNAME)"
			 +char(10)+	" Where U.USERID = user"
			 +char(10)+	" And R.RECORDTYPE = 'C'" 
			 +char(10)+	" And R.SECURITYFLAG  IN (0,2,4,6,8,10,12,14 )"
			 +char(10)+	" And R.OFFICE   is null"
			 +char(10)+	" And R.CASETYPE is null"
			 +char(10)+	" And R.PROPERTYTYPE  =P.PROPERTYTYPE)"
			 +char(10)+	"Order by P.PROPERTYNAME"
	end
	else begin
		set @sSql=		"Select P.PROPERTYTYPE, P.PROPERTYNAME"
			 +char(10)+	"From  USERROWACCESS U"
			 +char(10)+	"join ROWACCESSDETAIL R	on (R.ACCESSNAME= U.ACCESSNAME)"
			 +char(10)+	"join PROPERTYTYPE P	on (P.PROPERTYTYPE=R.PROPERTYTYPE)"
			 +char(10)+	"Where U.USERID = user"
			 +char(10)+	"And R.RECORDTYPE = 'C'"
			 +char(10)+	"And R.SECURITYFLAG   IN ( 1,3,5,7,9,11,13,15 )"
			 +char(10)+	"And R.PROPERTYTYPE IS NOT NULL"
			 +char(10)+	"UNION"
			 +char(10)+	"Select P.PROPERTYTYPE, P.PROPERTYNAME"
			 +char(10)+	"From PROPERTYTYPE P"
			 +char(10)+	"Where (exists"
			 +char(10)+	"(select * from USERROWACCESS U"
			 +char(10)+	" join ROWACCESSDETAIL R	on (R.ACCESSNAME= U.ACCESSNAME)"
			 +char(10)+	" Where U.USERID = user"
			 +char(10)+	" And R.RECORDTYPE = 'C'" 
			 +char(10)+	" And R.SECURITYFLAG  IN ( 1,3,5,7,9,11,13,15 )"
			 +char(10)+	" And R.PROPERTYTYPE  is  NULL)"
			 +char(10)+	"OR not exists"
			 +char(10)+	"(select * from USERROWACCESS U"
			 +char(10)+	" join ROWACCESSDETAIL R	on (R.ACCESSNAME= U.ACCESSNAME)"
			 +char(10)+	" Where R.RECORDTYPE = 'C'))"  
			 +char(10)+	"and not exists"
			 +char(10)+	"(select * from USERROWACCESS U"
			 +char(10)+	" join ROWACCESSDETAIL R	on (R.ACCESSNAME= U.ACCESSNAME)"
			 +char(10)+	" Where U.USERID = user"
			 +char(10)+	" And R.RECORDTYPE = 'C'" 
			 +char(10)+	" And R.SECURITYFLAG  IN (0,2,4,6,8,10,12,14 )"
			 +char(10)+	" And R.OFFICE   is null"
			 +char(10)+	" And R.CASETYPE is null"
			 +char(10)+	" And R.PROPERTYTYPE  =P.PROPERTYTYPE)"
			 +char(10)+	"Order by P.PROPERTYNAME"
	end

	Execute @ErrorCode=sp_executesql @sSql

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_ListValidProperty] to public
go
