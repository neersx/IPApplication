-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteNameAddress									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteNameAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteNameAddress.'
	Drop procedure [dbo].[naw_DeleteNameAddress]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteNameAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteNameAddress
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@pnAddressKey			int,		-- Mandatory
	@pnAddressTypeKey		int,		-- Mandatory

	@pbOldIsOwner			bit		= null,
	@psOldStreet			nvarchar(254)	= null,
	@psOldCity			nvarchar(30)	= null,
	@psOldStateCode			nvarchar(20)	= null,
	@psOldPostCode			nvarchar(10)	= null,
	@psOldCountryCode		nvarchar(3)	= null,
	@pnOldTelephoneKey		int		= null,
	@pnOldFaxKey			int		= null,
	@pnOldAddressStatusKey		int		= null,
	@pdtOldDateCeased		datetime	= null,

	@pbIsIsOwnerInUse		bit		= 0,
	@pbIsStreetInUse		bit		= 0,
	@pbIsCityInUse			bit		= 0,
	@pbIsStateCodeInUse		bit		= 0,
	@pbIsPostCodeInUse		bit		= 0,
	@pbIsCountryCodeInUse		bit		= 0,
	@pbIsTelephoneKeyInUse		bit		= 0,
	@pbIsFaxKeyInUse		bit		= 0,
	@pbIsAddressStatusKeyInUse	bit		= 0,
	@pbIsDateCeasedInUse		bit		= 0
)
as
-- PROCEDURE:	naw_DeleteNameAddress
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete NameAddress if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 13 Jun 2006	SW	RFC3787	1	Procedure created
-- 26 Jul 2010	SF	RFC9563	2	Ensure IsOwner flag is returned as either a 0 or a 1.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)
Declare @bIsOrphan		bit
Declare @nRowCount		int

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 

Set @pbOldIsOwner = ISNULL(@pbOldIsOwner, 0)


-- Find out if @pnAddressKey orphan
-- if > 1 then not orphan
-- if 1 then orphan
-- if 0 then not exists (hopefully not exists in ADDRESS too)
If @nErrorCode = 0
Begin
	Set @sSQLString = '
		Select	@bIsOrphan = 
			case 	count(ADDRESSCODE)
				when 1 then 	cast(1 as bit)
				else 		cast(0 as bit)
			end
		from	NAMEADDRESS
		where	ADDRESSCODE = @pnAddressKey'
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'
			@bIsOrphan		int		OUTPUT,
			@pnAddressKey		int',
			@bIsOrphan		= @bIsOrphan	OUTPUT,
			@pnAddressKey	 	= @pnAddressKey
End

-- detach from NAME if belongs to main
If @nErrorCode = 0
Begin

	If @pnAddressTypeKey = 301
	Begin
		Set @sSQLString = '
			Update [NAME]
			set	POSTALADDRESS = null
			where	POSTALADDRESS = @pnAddressKey
			and	NAMENO = @pnNameKey'
	End
	Else
	Begin
		Set @sSQLString = '
			Update [NAME]
			set	STREETADDRESS = null
			where	STREETADDRESS = @pnAddressKey
			and	NAMENO = @pnNameKey'
	End

	Exec @nErrorCode = sp_executesql @sSQLString,
		N'
		@pnAddressKey		int,
		@pnNameKey		int',
		@pnAddressKey		= @pnAddressKey,
		@pnNameKey		= @pnNameKey

End

-- Delete record from NAMEADDRESS
If @nErrorCode = 0
Begin

	Set @sDeleteString = "Delete from NAMEADDRESS
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		NAMENO = @pnNameKey and 
		ADDRESSCODE = @pnAddressKey and
		ADDRESSTYPE = @pnAddressTypeKey"

	If @pbIsAddressStatusKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ADDRESSSTATUS = @pnOldAddressStatusKey"
	End

	If @pbIsDateCeasedInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"DATECEASED = @pdtOldDateCeased"
	End

	If @pbIsIsOwnerInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ISNULL(OWNEDBY,0) = @pbOldIsOwner"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
				N'
				@pnNameKey		int,
				@pnAddressKey		int,
				@pnAddressTypeKey	int,
				@pbOldIsOwner		bit,
				@pnOldAddressStatusKey	int,
				@pdtOldDateCeased	datetime',
				@pnNameKey	 	= @pnNameKey,
				@pnAddressKey	 	= @pnAddressKey,
				@pnAddressTypeKey	= @pnAddressTypeKey,
				@pbOldIsOwner	 	= @pbOldIsOwner,
				@pnOldAddressStatusKey	= @pnOldAddressStatusKey,
				@pdtOldDateCeased	= @pdtOldDateCeased

	-- for concurrency checking
	Set @nRowCount = @@rowcount
	
End

-- delete orphan @pnAddressKey from ADDRESS
If (@nErrorCode = 0 and @nRowCount <> 0 and @bIsOrphan = 1)
Begin

	exec @nErrorCode = dbo.naw_DeleteAddress
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura		= @pbCalledFromCentura,
		@pnAddressKey			= @pnAddressKey,

		@psOldStreet			= @psOldStreet,
		@psOldCity			= @psOldCity,
		@psOldStateCode			= @psOldStateCode,
		@psOldPostCode			= @psOldPostCode,
		@psOldCountryCode		= @psOldCountryCode,
		@pnOldTelephoneKey		= @pnOldTelephoneKey,
		@pnOldFaxKey			= @pnOldFaxKey,
	
		@pbIsStreetInUse		= @pbIsStreetInUse,
		@pbIsCityInUse			= @pbIsCityInUse,
		@pbIsStateCodeInUse		= @pbIsStateCodeInUse,
		@pbIsPostCodeInUse		= @pbIsPostCodeInUse,
		@pbIsCountryCodeInUse		= @pbIsCountryCodeInUse,
		@pbIsTelephoneKeyInUse		= @pbIsTelephoneKeyInUse,
		@pbIsFaxKeyInUse		= @pbIsFaxKeyInUse

End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteNameAddress to public
GO