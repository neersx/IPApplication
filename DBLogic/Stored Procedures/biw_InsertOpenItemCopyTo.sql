-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertOpenItemCopyTo									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertOpenItemCopyTo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertOpenItemCopyTo.'
	Drop procedure [dbo].[biw_InsertOpenItemCopyTo]
End
Print '**** Creating Stored Procedure dbo.biw_InsertOpenItemCopyTo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_InsertOpenItemCopyTo
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityKey	int,		-- OpenItemKey
	@pnItemTransKey		int,		-- OpenItemKey
	@pnAcctEntityKey	int,		-- OpenItemKey
	@pnAcctDebtorKey	int,		-- OpenItemKey
	@pnCopyToNameKey	int,
	@psFormattedCopyToName	nvarchar(254),
	@pnAttentionNameKey	int		= null,
	@psFormattedAttention	nvarchar(254)	= null,
	@pnAddressKey		int		= null,
	@psFormattedAddress	nvarchar(254)	= null,
	@pnAddressChangeReason	int	= null
)
as
-- PROCEDURE:	biw_InsertOpenItemCopyTo
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert OpenItemCopyTo.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 13 Oct 2010	AT	RFC8982	1	Procedure created.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @nNameSnapNo		int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	exec @nErrorCode = biw_DeriveNameSnap		
		@pnUserIdentityId =@pnUserIdentityId,
		@psCulture = @psCulture,
		@pbCalledFromCentura = @pbCalledFromCentura,
		@pnAcctDebtorNo = @pnCopyToNameKey,
		@psFormattedName = @psFormattedCopyToName, -- formatted name/address details for NameSnapNo.
		@pnAddressKey	= @pnAddressKey,
		@psFormattedAddress = @psFormattedAddress,
		@pnAttnNameKey = @pnAttentionNameKey,
		@psFormattedAttention = @psFormattedAttention,
		@pnAddressChangeReason	= @pnAddressChangeReason,
		@pnNameSnapNo = @nNameSnapNo OUTPUT
End

If (@nErrorCode = 0
and not exists(select * from OPENITEMCOPYTO 
		WHERE ITEMENTITYNO = @pnItemEntityKey 
		AND ITEMTRANSNO = @pnItemTransKey 
		AND ACCTENTITYNO = @pnAcctEntityKey 
		AND ACCTDEBTORNO = @pnAcctDebtorKey
		AND NAMESNAPNO = @nNameSnapNo))
Begin
	Set @sSQLString = "Insert into OPENITEMCOPYTO(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, NAMESNAPNO)
	VALUES (@pnItemEntityKey, @pnItemTransKey, @pnAcctEntityKey, @pnAcctDebtorKey, @nNameSnapNo)"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnItemEntityKey int,
				@pnItemTransKey int,
				@pnAcctEntityKey int, 
				@pnAcctDebtorKey int,
				@nNameSnapNo int',
				@pnItemEntityKey = @pnItemEntityKey,
				@pnItemTransKey = @pnItemTransKey,
				@pnAcctEntityKey = @pnAcctEntityKey,
				@pnAcctDebtorKey = @pnAcctDebtorKey,
				@nNameSnapNo = @nNameSnapNo
End

-- Remove unused snaps for this name.
If (@nErrorCode = 0)
Begin
	Set @sSQLString = "DELETE from NAMEADDRESSSNAP
			WHERE NAMENO = @pnCopyToNameKey
			AND NAMESNAPNO NOT IN (SELECT NAMESNAPNO FROM OPENITEM WHERE NAMESNAPNO IS NOT NULL
						UNION SELECT NAMESNAPNO FROM OPENITEMCOPYTO)"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCopyToNameKey int',
				@pnCopyToNameKey = @pnCopyToNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.biw_InsertOpenItemCopyTo to public
