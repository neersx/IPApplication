-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertAddress									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertAddress.'
	Drop procedure [dbo].[naw_InsertAddress]
End
Print '**** Creating Stored Procedure dbo.naw_InsertAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO  


CREATE PROCEDURE dbo.naw_InsertAddress
(
	@pnUserIdentityId		int,		 -- Mandatory
	@psCulture			nvarchar(10) 	 = null,
	@pbCalledFromCentura		bit		 = 0,
	@pnAddressKey			int		 = null		OUTPUT,

	@psStreet			nvarchar(254)	 = null,
	@psCity				nvarchar(30)	 = null,
	@psStateCode			nvarchar(20)	 = null,
	@psPostCode			nvarchar(10)	 = null,
	@psCountryCode			nvarchar(3)	 = null,
	@pnTelephoneKey			int		 = null,
	@pnFaxKey			int		 = null,

	@pbIsStreetInUse		bit		 = 0,
	@pbIsCityInUse			bit		 = 0,
	@pbIsStateCodeInUse		bit		 = 0,
	@pbIsPostCodeInUse		bit		 = 0,
	@pbIsCountryCodeInUse		bit		 = 0,
	@pbIsTelephoneKeyInUse		bit		 = 0,
	@pbIsFaxKeyInUse		bit		 = 0
)
as
-- PROCEDURE:	naw_InsertAddress
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Address.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Jun 2006	SW	RFC3787	1	Procedure created
-- 25 Mar 2008	Ash	RFC5438	2	Maintain data in different culture
-- 15 Apr 2008	SF	RFC6454	3	Backout changes made in RFC5438 temporarily
-- 11 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sDBCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sComma = ","
/*
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @sDBCulture = COLCHARACTER
		from SITECONTROL
		where CONTROLID = 'Database Culture'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sDBCulture		nvarchar(10)	OUTPUT',
					  @sDBCulture		= @sDBCulture	OUTPUT

End
*/

-- Generate @pnAddressKey from ip_GetLastInternalCode
If @nErrorCode = 0
Begin
	-- Generate ADDRESS primary key
	Exec @nErrorCode = dbo.ip_GetLastInternalCode
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@psTable		= 'ADDRESS',
		@pnLastInternalCode	= @pnAddressKey		OUTPUT
End

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into ADDRESS (ADDRESSCODE"
	Set @sValuesString = CHAR(10)+" values (@pnAddressKey"

	If @pbIsStreetInUse = 1
	-- Only insert to base table if culture matches
	--and @psCulture = @sDBCulture
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STREET1"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psStreet"
	End

	If @pbIsCityInUse = 1
	--and @psCulture = @sDBCulture
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CITY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCity"
	End

	If @pbIsStateCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psStateCode"
	End

	If @pbIsPostCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POSTCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPostCode"
	End

	If @pbIsCountryCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"COUNTRYCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCountryCode"
	End

	If @pbIsTelephoneKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TELEPHONE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnTelephoneKey"
	End

	If @pbIsFaxKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FAX"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnFaxKey"
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnAddressKey		int,
				@psStreet		nvarchar(254),
				@psCity			nvarchar(30),
				@psStateCode		nvarchar(20),
				@psPostCode		nvarchar(10),
				@psCountryCode		nvarchar(3),
				@pnTelephoneKey		int,
				@pnFaxKey		int',
				@pnAddressKey		= @pnAddressKey,
				@psStreet		= @psStreet,
				@psCity			= @psCity,
				@psStateCode		= @psStateCode,
				@psPostCode		= @psPostCode,
				@psCountryCode		= @psCountryCode,
				@pnTelephoneKey		= @pnTelephoneKey,
				@pnFaxKey		= @pnFaxKey

End

-- If culture doesn't match the database main culture, we need to maintain the translated data.
/*
	If @nErrorCode = 0
	and @psCulture <> @sDBCulture
	Begin

		Set @sSQLString = "
			Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT)
			select STREET1_TID, @psCulture, @psStreet
			from ADDRESS
			where ADDRESSCODE = @pnAddressKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'
					@pnAddressKey		int,
					@psCulture		nvarchar(10),
					@psStreet		nvarchar(254)',
					@pnAddressKey		= @pnAddressKey,
					@psCulture		= @psCulture,
					@psStreet		= @psStreet
	End

	If @nErrorCode = 0
	and @psCulture <> @sDBCulture
	Begin

		Set @sSQLString = "
			Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT)
			select CITY_TID, @psCulture, @psCity
			from ADDRESS
			where ADDRESSCODE = @pnAddressKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'
					@pnAddressKey		int,
					@psCulture		nvarchar(10),
					@psCity			nvarchar(30)',
					@pnAddressKey		= @pnAddressKey,
					@psCulture		= @psCulture,
					@psCity			= @psCity
	End
*/
Return @nErrorCode
GO

Grant execute on dbo.naw_InsertAddress to public
GO