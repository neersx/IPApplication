-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_UpdatePrintedFlag
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_UpdatePrintedFlag]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_UpdatePrintedFlag.'
	Drop procedure [dbo].[biw_UpdatePrintedFlag]
End
Print '**** Creating Stored Procedure dbo.biw_UpdatePrintedFlag...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.biw_UpdatePrintedFlag
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 		= null,
	@pbCalledFromCentura	bit			= 0,
	@pnItemEntityNo			int,
	@pnItemTransNo			int,
	@pbPrintedFlag			bit
)
as
-- PROCEDURE:	biw_UpdatePrintedFlag
-- VERSION:		1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Updates the specified bill format. Contains concurrency checking.

-- MODIFICATIONS :
-- Date			Who		Change			Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 08 Jan 2012	AT		RFC13059		1		Procedure created


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

if exists(select * from OPENITEM
		WHERE STATUS != 0
		AND ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO = @pnItemTransNo)

	Set @sSQLString = "UPDATE OPENITEM
				SET BILLPRINTEDFLAG =@pbPrintedFlag
				WHERE ITEMENTITYNO = @pnItemEntityNo
				AND ITEMTRANSNO = @pnItemTransNo"
			
			exec @nErrorCode=sp_executesql @sSQLString,
				N'@pbPrintedFlag		bit,
				  @pnItemEntityNo 		int,
				  @pnItemTransNo		int',
				  @pbPrintedFlag	= @pbPrintedFlag,
				  @pnItemEntityNo 	= @pnItemEntityNo,
				  @pnItemTransNo	= @pnItemTransNo
End

Return @nErrorCode
GO

Grant execute on dbo.biw_UpdatePrintedFlag to public
GO
