-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipo_FormatAddress
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipo_FormatAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipo_FormatAddress.'
	drop procedure dbo.ipo_FormatAddress
end
print '**** Creating procedure dbo.ipo_FormatAddress...'
print ''
go

create procedure dbo.ipo_FormatAddress
	@pnAddressCode int,
	@prsFormattedAddress varchar(255) = NULL OUTPUT
as
-- PROCEDURE :	ipo_FormatAddress
-- VERSION :	2.1.0
-- DESCRIPTION:	A procedure to return an output string containing the supplied AddressNo formatted with carriage returns separating 
--		the lines, and county included if it is different to the home country.
-- 		Modified 28/6/01 AvdA #6730 NameAddress formatting
-- CALLED BY :	ipo_MailingLabel

-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07/03/2003	AB			Add dbo owner to create procedure
-- 29/09/2004	TM	RFC1806	8	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.	

IF @pnAddressCode IS NULL
	RETURN
ELSE
	BEGIN

	Set @prsFormattedAddress = dbo.fn_GetFormattedAddress
							( 							
							@pnAddressCode,	-- Mandatory
							null,		-- The language in which output is to be expressed. Either @psCulture or @pnLangaugeKey should be provided, not both.  
							null,		-- The key of the client/server language in which the output is to be expressed.  
							null, 		-- The style to use when formatting the address. 
							null		-- Indicates whether the output from the function will be used by Centura code.  			
							)
END

return 0
go

grant execute on ipo_FormatAddress to public
go
