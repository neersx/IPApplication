-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteAddress									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteAddress.'
	Drop procedure [dbo].[naw_DeleteAddress]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteAddress
(
	@pnUserIdentityId	int,		 -- Mandatory
	@psCulture		nvarchar(10) 	 = null,
	@pbCalledFromCentura	bit		 = 0,
	@pnAddressKey		int,		 -- Mandatory

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
-- PROCEDURE:	naw_DeleteAddress
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Address if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Jun 2006	SW	RFC3787	1	Procedure created
-- 17 Dec 2007	PG	RFC3497	2	Delete Address telecoms
-- 10 Dec 2008	AT	RFC7388	3	Delete Telecoms after Address to avoid ref integ error.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from ADDRESS where ADDRESSCODE = @pnAddressKey"

	If @pbIsStreetInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"STREET1 = @psOldStreet"
	End

	If @pbIsCityInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CITY = @psOldCity"
	End

	If @pbIsStateCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"STATE = @psOldStateCode"
	End

	If @pbIsPostCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"POSTCODE = @psOldPostCode"
	End

	If @pbIsCountryCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"COUNTRYCODE = @psOldCountryCode"
	End

	If @pbIsTelephoneKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"TELEPHONE = @pnOldTelephoneKey"
	End

	If @pbIsFaxKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"FAX = @pnOldFaxKey"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
				N'
				@pnAddressKey		int,
				@psOldStreet		nvarchar(254),
				@psOldCity			nvarchar(30),
				@psOldStateCode		nvarchar(20),
				@psOldPostCode		nvarchar(10),
				@psOldCountryCode	nvarchar(3),
				@pnOldTelephoneKey	int,
				@pnOldFaxKey		int',
				@pnAddressKey		= @pnAddressKey,
				@psOldStreet	 	= @psOldStreet,
				@psOldCity	 		= @psOldCity,
				@psOldStateCode	 	= @psOldStateCode,
				@psOldPostCode	 	= @psOldPostCode,
				@psOldCountryCode	= @psOldCountryCode,
				@pnOldTelephoneKey	= @pnOldTelephoneKey,
				@pnOldFaxKey	 	= @pnOldFaxKey


End

--Delete Address telecoms
If @nErrorCode = 0 and @pnOldTelephoneKey is not null
Begin
	exec @nErrorCode = dbo.naw_DeleteAddressTelecom
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture				= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnTelecomKey			= @pnOldTelephoneKey,
		@pnAddressKey			= @pnAddressKey
End
--Delete Fax
If @nErrorCode = 0 and @pnOldFaxKey is not null
Begin
	exec @nErrorCode = dbo.naw_DeleteAddressTelecom
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture				= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnTelecomKey			= @pnOldFaxKey,
		@pnAddressKey			= @pnAddressKey	
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteAddress to public
GO

