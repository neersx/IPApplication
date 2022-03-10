-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipo_FormatReturnAddress
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipo_FormatReturnAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipo_FormatReturnAddress.'
	drop procedure dbo.ipo_FormatReturnAddress
end
print '**** Creating procedure dbo.ipo_FormatReturnAddress...'
print ''
go

create procedure dbo.ipo_FormatReturnAddress
	@pnAddressCode int,
	@prsFormattedAddress varchar(255) = NULL OUTPUT
as
-- PROCEDURE :	ipo_FormatReturnAddress
-- VERSION :	2.1.0
-- DESCRIPTION:	Format the address into a single string field with the postal code inserted in the correct sequence and 
-- 		the lines separated by carriage returns. A Return address always contains the country as the recipient
-- 		may not be in the home country.
-- CALLED BY :	ipr_ReturnNameAddress

-- Date		USER	MODIFICTION HISTORY
-- ====         ====	===================
-- 28/06/01 	AvdA 	SQA6730	NameAddress formatting
-- 07/10/03	AB	Add dbo user to create procedure
-- 29/09/04	TM	RFC1806	Implement using fn_FormatAddress

IF @pnAddressCode IS NULL
	RETURN
ELSE
	BEGIN

	Select  @prsFormattedAddress = 
			dbo.fn_FormatAddress(
			A.STREET1, 
			A.STREET2, 
			A.CITY, 
			A.STATE, 
			S.STATENAME, 
			A.POSTCODE, 
			C.POSTALNAME,
			C.POSTCODEFIRST, 
			C.STATEABBREVIATED, 
			C.POSTCODELITERAL, 
			C.ADDRESSSTYLE)
		from ADDRESS A 		
		left join COUNTRY C		on (C.COUNTRYCODE = A.COUNTRYCODE)
		left Join STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE
						and S.STATE = A.STATE)		
		where A.ADDRESSCODE = @pnAddressCode 

	END

Return 0
GO

grant execute on dbo.ipo_FormatReturnAddress TO public
GO
