-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateAddress									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateAddress.'
	Drop procedure [dbo].[naw_UpdateAddress]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateAddress
(
	@pnUserIdentityId	int,		 -- Mandatory
	@psCulture		nvarchar(10) 	 = null,
	@pbCalledFromCentura	bit		 = 0,
	@pnAddressKey		int,		 -- Mandatory

	@psStreet		nvarchar(254)	 = null,
	@psCity			nvarchar(30)	 = null,
	@psStateCode		nvarchar(20)	 = null,
	@psPostCode		nvarchar(10)	 = null,
	@psCountryCode		nvarchar(3)	 = null,
	@pnTelephoneKey		int		 = null,
	@pnFaxKey		int		 = null,

	@psOldStreet		nvarchar(254)	 = null,
	@psOldCity		nvarchar(30)	 = null,
	@psOldStateCode		nvarchar(20)	 = null,
	@psOldPostCode		nvarchar(10)	 = null,
	@psOldCountryCode	nvarchar(3)	 = null,
	@pnOldTelephoneKey	int		 = null,
	@pnOldFaxKey		int		 = null,

	@pbIsStreetInUse	bit		 = 0,
	@pbIsCityInUse		bit		 = 0,
	@pbIsStateCodeInUse	bit		 = 0,
	@pbIsPostCodeInUse	bit		 = 0,
	@pbIsCountryCodeInUse	bit		 = 0,
	@pbIsTelephoneKeyInUse	bit		 = 0,
	@pbIsFaxKeyInUse	bit		 = 0
)
as
-- PROCEDURE:	naw_UpdateAddress
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Address if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Jun 2006	SW	RFC3787	1	Procedure created
-- 17 Dec 2007	PG	RFC3497	2	Delete Address Telecoms if empty
-- 10 Dec 2008	AT	RFC7388	3	Delete orphaned telecom was referencing wrong telecom.
-- 24 Apr 2017	MF	71165	4	Commenting out STREET1 from the WHERE clause on ADDRESS update. Embedded line feeds were causing data mismatch for old client/server data.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update ADDRESS
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"ADDRESSCODE = @pnAddressKey"

	If @pbIsStreetInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STREET1 = @psStreet"
		--Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"STREET1 = @psOldStreet"	-- RFC71165 Commented out because line feed differences with client/server causing a mismatch
		Set @sComma = ","
	End

	If @pbIsCityInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CITY = @psCity"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CITY = @psOldCity"
		Set @sComma = ","
	End

	If @pbIsStateCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STATE = @psStateCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"STATE = @psOldStateCode"
		Set @sComma = ","
	End

	If @pbIsPostCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POSTCODE = @psPostCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"POSTCODE = @psOldPostCode"
		Set @sComma = ","
	End

	If @pbIsCountryCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"COUNTRYCODE = @psCountryCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"COUNTRYCODE = @psOldCountryCode"
		Set @sComma = ","
	End

	If @pbIsTelephoneKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TELEPHONE = @pnTelephoneKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TELEPHONE = @pnOldTelephoneKey"
		Set @sComma = ","
	End

	If @pbIsFaxKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FAX = @pnFaxKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FAX = @pnOldFaxKey"
		Set @sComma = ","
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnAddressKey		int,
				@psStreet		nvarchar(254),
				@psCity			nvarchar(30),
				@psStateCode		nvarchar(20),
				@psPostCode		nvarchar(10),
				@psCountryCode		nvarchar(3),
				@pnTelephoneKey		int,
				@pnFaxKey		int,
				@psOldStreet		nvarchar(254),
				@psOldCity		nvarchar(30),
				@psOldStateCode		nvarchar(20),
				@psOldPostCode		nvarchar(10),
				@psOldCountryCode	nvarchar(3),
				@pnOldTelephoneKey	int,
				@pnOldFaxKey		int',
				@pnAddressKey		= @pnAddressKey,
				@psStreet		= @psStreet,
				@psCity			= @psCity,
				@psStateCode	 	= @psStateCode,
				@psPostCode	 	= @psPostCode,
				@psCountryCode	 	= @psCountryCode,
				@pnTelephoneKey	 	= @pnTelephoneKey,
				@pnFaxKey	 	= @pnFaxKey,
				@psOldStreet	 	= @psOldStreet,
				@psOldCity	 	= @psOldCity,
				@psOldStateCode	 	= @psOldStateCode,
				@psOldPostCode	 	= @psOldPostCode,
				@psOldCountryCode	= @psOldCountryCode,
				@pnOldTelephoneKey	= @pnOldTelephoneKey,
				@pnOldFaxKey	 	= @pnOldFaxKey
End

--Delete Address telecoms
--Delete Old Telephone
If @nErrorCode = 0 and 
@pnOldTelephoneKey is not null and
@pnTelephoneKey is null
Begin
	exec @nErrorCode = dbo.naw_DeleteAddressTelecom
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnTelecomKey		= @pnOldTelephoneKey,
		@pnAddressKey		= @pnAddressKey
End

--Delete Old Fax
If @nErrorCode = 0 and 
@pnOldFaxKey is not null and
@pnFaxKey is null
Begin
	exec @nErrorCode = dbo.naw_DeleteAddressTelecom
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnTelecomKey		= @pnOldFaxKey,
		@pnAddressKey		= @pnAddressKey	
End


Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateAddress to public
GO