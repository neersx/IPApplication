-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertNameAddress									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertNameAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertNameAddress.'
	Drop procedure [dbo].[naw_InsertNameAddress]
End
Print '**** Creating Stored Procedure dbo.naw_InsertNameAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertNameAddress
(
	@pnUserIdentityId		int,		 			-- Mandatory
	@psCulture			nvarchar(10) 	 = null,
	@pbCalledFromCentura		bit		 = 0,
	@pnNameKey			int,					-- Mandatory.
	@pnAddressKey			int		 = null	OUTPUT,		-- Mandatory.
	@pnAddressTypeKey		int,					-- Mandatory.

	@pbIsOwner			bit		 = null,
	@psStreet			nvarchar(254)	 = null,
	@psCity				nvarchar(30)	 = null,
	@psStateCode		nvarchar(20)	 = null,
	@psPostCode			nvarchar(10)	 = null,
	@psCountryCode		nvarchar(3)	 = null,
	@pnTelephoneKey		int		 = null	output,
	@pnFaxKey			int		 = null output,
	@pnAddressStatusKey		int		 = null,
	@pdtDateCeased			datetime	 = null,
	@pbIsIsOwnerInUse		bit		 = 0,
	@pbIsStreetInUse		bit		 = 0,
	@pbIsCityInUse			bit		 = 0,
	@pbIsStateCodeInUse		bit		 = 0,
	@pbIsPostCodeInUse		bit		 = 0,
	@pbIsCountryCodeInUse		bit		 = 0,
	@pbIsTelephoneKeyInUse		bit		 = 0,
	@pbIsFaxKeyInUse		bit		 = 0,
	@pbIsAddressStatusKeyInUse	bit		 = 0,
	@pbIsDateCeasedInUse		bit		 = 0,
	@psTelephoneISD				nvarchar(5)	= null,		
	@psTelephoneAreaCode		nvarchar(5)	= null,
	@psTelephoneNumber			nvarchar(100) = null,
	@psTelephoneExt				nvarchar(5)	= null,
	@psFaxISD					nvarchar(5)	= null,
	@psFaxAreaCode				nvarchar(5)	= null,
	@psFaxNumber				nvarchar(100) = null --InUse flags not extremely useful for telecoms. Hence not supported
)
as
-- PROCEDURE:	naw_InsertNameAddress
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert NameAddress.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 09 Jun 2006	SW	RFC3787	1	Procedure created
-- 14 Dec 2007	PG	RFC3497	2	Support address telecom

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

-- Create AddressKey if not provided
If @pnAddressKey is null
Begin

	Exec @nErrorCode = dbo.naw_InsertAddress
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture, 
		@pbCalledFromCentura	= @pbCalledFromCentura, 
		@pnAddressKey 		= @pnAddressKey OUTPUT, 
		@psStreet		= @psStreet, 
		@psCity			= @psCity, 
		@psStateCode		= @psStateCode, 
		@psPostCode			= @psPostCode, 
		@psCountryCode		= @psCountryCode, 
		@pnTelephoneKey		= @pnTelephoneKey,
		@pnFaxKey			= @pnFaxKey, 
		@pbIsStreetInUse	= @pbIsStreetInUse, 
		@pbIsCityInUse		= @pbIsCityInUse, 
		@pbIsStateCodeInUse	= @pbIsStateCodeInUse, 
		@pbIsPostCodeInUse	= @pbIsPostCodeInUse, 
		@pbIsCountryCodeInUse	= @pbIsCountryCodeInUse, 
		@pbIsTelephoneKeyInUse	= @pbIsTelephoneKeyInUse, 
		@pbIsFaxKeyInUse	= @pbIsFaxKeyInUse
End

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into NAMEADDRESS ("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"NAMENO,ADDRESSTYPE,ADDRESSCODE"

	Set @sValuesString = @sValuesString+CHAR(10)+"@pnNameKey,@pnAddressTypeKey,@pnAddressKey"

	If @pbIsAddressStatusKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ADDRESSSTATUS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAddressStatusKey"
		Set @sComma = ","
	End

	If @pbIsDateCeasedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DATECEASED"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtDateCeased"
		Set @sComma = ","
	End

	If @pbIsIsOwnerInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"OWNEDBY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbIsOwner"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnNameKey		int,
				@pnAddressKey		int,
				@pnAddressTypeKey	int,
				@pbIsOwner		bit,
				@pnAddressStatusKey	int,
				@pdtDateCeased		datetime',
				@pnNameKey	 	= @pnNameKey,
				@pnAddressKey	 	= @pnAddressKey,
				@pnAddressTypeKey	= @pnAddressTypeKey,
				@pbIsOwner	 	= @pbIsOwner,
				@pnAddressStatusKey	= @pnAddressStatusKey,
				@pdtDateCeased	 	= @pdtDateCeased

End

If @nErrorCode = 0 and @psTelephoneNumber is not null
Begin
	Exec @nErrorCode = dbo.naw_InsertAddressTelecom
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura = 0,
		@pnTelecomKey		= @pnTelephoneKey OUTPUT,
		@pnAddressKey		= @pnAddressKey,
		@pnTelecomTypeKey	= '1901',
		@psIsd				= @psTelephoneISD,
		@psAreaCode			= @psTelephoneAreaCode,
		@psTelecomNumber	= @psTelephoneNumber,
		@psExtension		= @psTelephoneExt,
		@pbIsReminderAddress = null,
		@pbIsMain			=1
End
If @nErrorCode = 0 and @psFaxNumber is not null
Begin
	Exec @nErrorCode = dbo.naw_InsertAddressTelecom
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura = 0,
		@pnTelecomKey		= @pnTelephoneKey OUTPUT,
		@pnAddressKey		= @pnAddressKey,
		@pnTelecomTypeKey	= '1902',
		@psIsd				= @psFaxISD,
		@psAreaCode			= @psFaxAreaCode,
		@psTelecomNumber	= @psFaxNumber,
		@psExtension		= null,
		@pbIsReminderAddress = null,
		@pbIsMain			=1
End


Return @nErrorCode
GO

Grant execute on dbo.naw_InsertNameAddress to public
GO