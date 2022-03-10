-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetFormattedAddress
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetFormattedAddress') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetFormattedAddress.'
	drop function dbo.fn_GetFormattedAddress
	print '**** Creating function dbo.fn_GetFormattedAddress...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_GetFormattedAddress
			(
			@pnAddressKey		int,		-- Mandatory
			@psCulture		nvarchar(10)	= null,	-- The language in which output is to be expressed. Either @psCulture or @pnLangaugeKey should be provided, not both.  
			@pnLanguageKey		int		= null,	-- The key of the client/server language in which the output is to be expressed.  
			@pnAddressStyle		int		= null, -- The style to use when formatting the address. If not provided, defaults to an appropriate style.
			@pbCalledFromCentura	bit		= 1	-- Indicates whether the output from the function will be used by Centura code.  			
			)
Returns nvarchar(254)

-- FUNCTION :	fn_GetFormattedAddress
-- VERSION :	2
-- DESCRIPTION:	This function accepts the components of an address and returns
--		it as formatted text string.  

-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2004	TM	RFC1806	Function created
-- 15 Jan 2009	AT	17136 	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

as
Begin
	Declare @sFormattedAddress 	nvarchar(254)
	Declare @sLookupCulture		nvarchar(10)
	
	If @psCulture is not null
	Begin
		Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
	End 
	Else If @pnLanguageKey is not null
	Begin
		Set @sLookupCulture = dbo.fn_GetLookupCulture(null, @pnLanguageKey, @pbCalledFromCentura)
	End 	

	-- Is a translation required?
	If @sLookupCulture is not null
	Begin
		Select  @sFormattedAddress = 
			dbo.fn_FormatAddress(
			dbo.fn_GetTranslation(A.STREET1,null,A.STREET1_TID,@sLookupCulture),
			A.STREET2, 
			dbo.fn_GetTranslation(A.CITY,null,A.CITY_TID,@sLookupCulture),
			A.STATE, 
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
			coalesce(@pnAddressStyle, SC.COLINTEGER, C.ADDRESSSTYLE))
		from ADDRESS A 		
		left join COUNTRY C		on (C.COUNTRYCODE = A.COUNTRYCODE)
		left Join STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE
						and S.STATE = A.STATE)
		left join SITECONTROL SC	on (SC.CONTROLID = 'Address Style '+@sLookupCulture)
		left join SITECONTROL HC	on (HC.CONTROLID = 'HOMECOUNTRY')
		where A.ADDRESSCODE = @pnAddressKey 		
	End
	-- No translation is required
	Else
	Begin
		Select  @sFormattedAddress = 
			dbo.fn_FormatAddress(
			A.STREET1, 
			A.STREET2, 
			A.CITY, 
			A.STATE, 
			S.STATENAME, 
			A.POSTCODE, 
			-- The country name is included in the formatted address 
			-- if the address in not in the home country
			CASE WHEN HC.COLCHARACTER = C.COUNTRYCODE
			     THEN NULL
			     ELSE C.POSTALNAME END,
			C.POSTCODEFIRST, 
			C.STATEABBREVIATED, 
			C.POSTCODELITERAL, 
			isnull(@pnAddressStyle, C.ADDRESSSTYLE))
		from ADDRESS A 		
		left join COUNTRY C		on (C.COUNTRYCODE = A.COUNTRYCODE)
		left Join STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE
						and S.STATE = A.STATE)
		left join SITECONTROL HC	on (HC.CONTROLID = 'HOMECOUNTRY')
		where A.ADDRESSCODE = @pnAddressKey 
	End	
	
	Return @sFormattedAddress
End
go

grant execute on dbo.fn_GetFormattedAddress to public
GO
