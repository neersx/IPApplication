-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_DeleteUnusedDraftWIP									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_DeleteUnusedDraftWIP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_DeleteUnusedDraftWIP.'
	Drop procedure [dbo].[biw_DeleteUnusedDraftWIP]
End
Print '**** Creating Stored Procedure dbo.biw_DeleteUnusedDraftWIP...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_DeleteUnusedDraftWIP
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnEntityNo		int,	-- Mandatory.
	@pnTransNo		int	-- Mandatory.
)
as
-- PROCEDURE:	biw_DeleteUnusedDraftWIP
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Remove Draft WIP no longer in use when updating a bill.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 05 Apr 2010	AT	RFC3605	1	Procedure created.
-- 23 Aug 2010	AT	RFC9589	2	Remove related Work History

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin
	-- update the WIP Balances on Draft WIP
	Set @sSQLString = "
			Delete WIP
			from WORKINPROGRESS WIP
			Left join BILLEDITEM BI on (WIP.ENTITYNO = BI.WIPENTITYNO
						and WIP.TRANSNO = BI.WIPTRANSNO
						and WIP.WIPSEQNO = BI.WIPSEQNO)
			WHERE WIP.ENTITYNO = @pnEntityNo
			and WIP.TRANSNO = @pnTransNo
			and BI.ITEMTRANSNO IS NULL"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

If (@nErrorCode = 0)
Begin
	-- delete work history
	Set @sSQLString = "
			Delete WIP
			from WORKHISTORY WIP
			Left join BILLEDITEM BI on (WIP.ENTITYNO = BI.WIPENTITYNO
						and WIP.TRANSNO = BI.WIPTRANSNO
						and WIP.WIPSEQNO = BI.WIPSEQNO)
			WHERE WIP.ENTITYNO = @pnEntityNo
			and WIP.TRANSNO = @pnTransNo
			and BI.ITEMTRANSNO IS NULL"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

Return @nErrorCode
GO

Grant execute on dbo.biw_DeleteUnusedDraftWIP to public
GO