-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_DeriveNameSnap									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_DeriveNameSnap]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_DeriveNameSnap.'
	Drop procedure [dbo].[biw_DeriveNameSnap]
End
Print '**** Creating Stored Procedure dbo.biw_DeriveNameSnap...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS off
GO

CREATE PROCEDURE dbo.biw_DeriveNameSnap
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnAcctDebtorNo		int,
	@psFormattedName	nvarchar(254)	= null, -- formatted name/address details for NameSnapNo.
	@pnAddressKey		int		= null,
	@psFormattedAddress	nvarchar(254)	= null,
	@pnAttnNameKey		int		= null,
	@psFormattedAttention	nvarchar(254)	= null,
	@pnAddressChangeReason	int		= null,
	@psFormattedReference	nvarchar(MAX)	= null,
	@pnNameSnapNo		int		= null OUTPUT
)
as
-- PROCEDURE:	biw_DeriveNameSnap
-- VERSION:		4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Derive NameSnap from name/address details.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08-Mar-2010	AT	RFC3605	1	Procedure created.
-- 15-Jul-2010	AT	RFC7271	2	Add name address reason.
-- 25-Apr-2013	MS	R11732	3	Added Formatted References.
-- 24-Sep-2015	AT	R51616	4	Use case and accent sensitive collation when comparing text.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)
Declare @sCollation		nvarchar(100)

Set @sCollation = dbo.fn_GetCaseSensitiveCollation()

Set @nErrorCode = 0
Set @psFormattedName = CASE WHEN @psFormattedName = '' THEN null ELSE @psFormattedName END
Set @psFormattedAddress = CASE WHEN @psFormattedAddress = '' THEN null ELSE @psFormattedAddress END
Set @psFormattedAttention = CASE WHEN @psFormattedAttention = '' THEN null ELSE @psFormattedAttention END
Set @psFormattedReference = CASE WHEN @psFormattedReference = '' THEN null ELSE @psFormattedReference END

-- Generate or Get the appropriate Name Snap details
If (@nErrorCode = 0 and @psFormattedName is not null and @pnNameSnapNo is null)
Begin
	Set @sSQLString = "
			Select TOP 1 @pnNameSnapNo = NAMESNAPNO
			From NAMEADDRESSSNAP
			Where ADDRESSCODE = @pnAddressKey
			and ATTNNAMENO = @pnAttnNameKey" + char(10)

	if (@psFormattedName is null)
	Begin
		Set @sSQLString = @sSQLString + "and FORMATTEDNAME is null"+char(10)
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + "and FORMATTEDNAME collate " + @sCollation + " = @psFormattedName collate " + @sCollation + char(10)
	End

	if (@psFormattedAddress is null)
	Begin
		Set @sSQLString = @sSQLString + "and FORMATTEDADDRESS is null"+char(10)
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + "and FORMATTEDADDRESS collate " + @sCollation + " = @psFormattedAddress collate " + @sCollation + char(10)
	End

	if (@psFormattedAttention is null)
	Begin
		Set @sSQLString = @sSQLString + "and FORMATTEDATTENTION is null"+char(10)
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + "and FORMATTEDATTENTION collate " + @sCollation + " = @psFormattedAttention collate " + @sCollation + char(10)
	End

	if (@pnAddressChangeReason is null)
	Begin
		Set @sSQLString = @sSQLString + "and REASONCODE is null"+char(10)
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + "and REASONCODE = @pnAddressChangeReason"+char(10)
	End
	
	if (@psFormattedReference is null)
	Begin
		Set @sSQLString = @sSQLString + "and FORMATTEDREFERENCE is null"+char(10)
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + "and FORMATTEDREFERENCE collate " + @sCollation + " = @psFormattedReference collate " + @sCollation + char(10)
	End	

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'	@pnNameSnapNo		int		OUTPUT,
					@psFormattedName	nvarchar(254),
					@psFormattedAddress	nvarchar(254),
					@psFormattedAttention	nvarchar(254),
					@psFormattedReference	nvarchar(MAX),
					@pnAddressKey int,
					@pnAttnNameKey int,
					@pnAddressChangeReason	int',
					@pnNameSnapNo		= @pnNameSnapNo OUTPUT,
					@psFormattedName	= @psFormattedName,
					@psFormattedAddress	= @psFormattedAddress,
					@psFormattedAttention	= @psFormattedAttention,
					@psFormattedReference	= @psFormattedReference,
					@pnAddressKey		= @pnAddressKey,
					@pnAttnNameKey		= @pnAttnNameKey,
					@pnAddressChangeReason	= @pnAddressChangeReason
End
Else If (@pnNameSnapNo is not null)
Begin
	Declare @nNameSnapCount int
	select @nNameSnapCount = COUNT(NAMESNAPNO) from OPENITEM WHERE NAMESNAPNO = @pnNameSnapNo GROUP BY NAMESNAPNO

	If (@nNameSnapCount = 1)
	and exists (select * from NAMEADDRESSSNAP WHERE NAMESNAPNO = @pnNameSnapNo)
	Begin
		-- Update the existing NameSnap
		Update NAMEADDRESSSNAP
		Set  NAMENO = @pnAcctDebtorNo, 
			FORMATTEDNAME = @psFormattedName,
			FORMATTEDADDRESS = @psFormattedAddress, 
			FORMATTEDATTENTION = @psFormattedAttention, 
			FORMATTEDREFERENCE = @psFormattedReference,
			ATTNNAMENO = @pnAttnNameKey, 
			ADDRESSCODE = @pnAddressKey,
			REASONCODE = @pnAddressChangeReason
			where NAMESNAPNO = @pnNameSnapNo
	End
	Else
	Begin
		-- clear the name snap so one is inserted in the next step.
		Set @pnNameSnapNo = null
	End
End


If (@pnNameSnapNo is null)
Begin
	-- Generate a NameAddressSnap Entry

	Exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'NAMEADDRESSSNAP',
			@pnLastInternalCode	= @pnNameSnapNo OUTPUT

	Set @sSQLString = "
			Insert INTO NAMEADDRESSSNAP (NAMESNAPNO, NAMENO, FORMATTEDNAME, FORMATTEDADDRESS, FORMATTEDATTENTION, ATTNNAMENO, 
					ADDRESSCODE, REASONCODE, FORMATTEDREFERENCE)
			VALUES ( @pnNameSnapNo, @pnAcctDebtorNo, 
						@psFormattedName,
						@psFormattedAddress,
						@psFormattedAttention,
						@pnAttnNameKey, 
						@pnAddressKey,
						@pnAddressChangeReason,
						@psFormattedReference)"

		exec @nErrorCode=sp_executesql @sSQLString, 
			N'	@pnNameSnapNo		int,
				@pnAcctDebtorNo		int,
				@psFormattedName	nvarchar(254),
				@psFormattedAddress	nvarchar(254),
				@psFormattedAttention	nvarchar(254),
				@psFormattedReference	nvarchar(MAX),
				@pnAddressKey		int,
				@pnAttnNameKey		int,
				@pnAddressChangeReason	int',
				@pnNameSnapNo		= @pnNameSnapNo,
				@pnAcctDebtorNo		= @pnAcctDebtorNo,
				@psFormattedName	= @psFormattedName,
				@psFormattedAddress	= @psFormattedAddress,
				@psFormattedAttention	= @psFormattedAttention,
				@psFormattedReference	= @psFormattedReference,
				@pnAttnNameKey		= @pnAttnNameKey,
				@pnAddressKey		= @pnAddressKey,
				@pnAddressChangeReason	= @pnAddressChangeReason
End


Return @nErrorCode
GO

Grant execute on dbo.biw_DeriveNameSnap to public
GO