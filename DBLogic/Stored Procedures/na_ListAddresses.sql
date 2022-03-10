---------------------------------------------------------------------------------------------
-- Creation of dbo.na_ListAddresses
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListAddresses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_ListAddresses.'
	drop procedure [dbo].[na_ListAddresses]
	print '**** Creating Stored Procedure dbo.na_ListAddresses...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create PROCEDURE dbo.na_ListAddresses
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnNameNo			int
)
AS

-- PROCEDURE :	na_ListAddresses
-- VERSION :	7
-- DESCRIPTON:	Populate the Address table in the NameDetails typed dataset.
-- CALLED BY :	

-- Date		Who	RFC	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 18/06/2002	SF			Procedure created	
-- 29/09/2004	TM	RFC1806		Replace the existing hard coded address formatting with a call to fn_FormatAddress.
-- 11 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 Mar 2017	MF	70924	7	Postal address is not taking the users culture into consideration.	

set nocount on
set concat_null_yields_null off

-- declare variables
declare	@ErrorCode	int
declare @sLookupCulture		nvarchar(10)

set @ErrorCode=0

If @psCulture is not null
Begin
	Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 
	
If @ErrorCode=0
begin

	select
	ADDTYPE.DESCRIPTION	as 'AddressTypeDescription',
	dbo.fn_FormatAddress(
		dbo.fn_GetTranslation(A.STREET1,null,A.STREET1_TID,@sLookupCulture), 
		null,
		dbo.fn_GetTranslation(A.CITY,null,A.CITY_TID,@sLookupCulture),
		dbo.fn_GetTranslation(A.STATE,null,A.STATE_TID,@sLookupCulture),
		dbo.fn_GetTranslation(S.STATENAME,null,S.STATENAME_TID,@sLookupCulture),
		A.POSTCODE,
		-- The country name is included in the formatted address 
		-- if the address in not in the home country
		CASE WHEN HC.COLCHARACTER = C.COUNTRYCODE
			THEN NULL
			ELSE dbo.fn_GetTranslation(C.POSTALNAME,null,C.POSTALNAME_TID,@sLookupCulture) END,
		C.POSTCODEFIRST,
		C.STATEABBREVIATED,
		dbo.fn_GetTranslation(C.POSTCODELITERAL,null,C.POSTCODELITERAL_TID,@sLookupCulture),
		C.ADDRESSSTYLE) as 'DisplayAddress',
	CASE 
		WHEN NA.ADDRESSCODE = N.POSTALADDRESS
		THEN 1	/* Main Postal Address */
--			WHEN NA.ADDRESSCODE = N.STREETADDRESS
--			THEN 2	/* Main Street Address */
	ELSE
		null	/* Undefined */
	END 			as 'AddressTypeId'	/* Is this what it is? */
	from NAMEADDRESS NA
	left join TABLECODES ADDTYPE 	on (NA.ADDRESSTYPE	= ADDTYPE.TABLECODE
					and ADDTYPE.TABLETYPE 	= 3)
	left join ADDRESS A		on (NA.ADDRESSCODE	= A.ADDRESSCODE)
	left join STATE S		on (A.COUNTRYCODE	= S.COUNTRYCODE
					and A.STATE		= S.STATE)

	left join COUNTRY C		on (A.COUNTRYCODE	= C.COUNTRYCODE)
	left join NAME N		on (NA.NAMENO  		= N.NAMENO)
	left join SITECONTROL HC	on (HC.CONTROLID = 'HOMECOUNTRY')

	where 	NA.NAMENO 		= @pnNameNo 	
				
End

	
RETURN @ErrorCode
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_ListAddresses to public
go
