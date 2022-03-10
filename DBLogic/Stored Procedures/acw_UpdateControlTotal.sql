-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_UpdateControlTotal									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_UpdateControlTotal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_UpdateControlTotal.'
	Drop procedure [dbo].[acw_UpdateControlTotal]
End
Print '**** Creating Stored Procedure dbo.acw_UpdateControlTotal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.acw_UpdateControlTotal
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnLedger		int,	-- Mandatory
	@pnCategory		int,	-- Mandatory
	@pnType		int,	-- Mandatory
	@pnPeriodId		int,	-- Mandatory
	@pnEntityNo		int,	-- Mandatory
	@pnAmountToAdd	decimal(13,2)	-- Mandatory
)
as
-- PROCEDURE:	acw_UpdateControlTotal
-- VERSION:		2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update ControlTotal from a particular transaction.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	-----------------------------------------------
-- 16 Nov 2009	AT	RFC3605		1	Procedure created.
-- 15 Jul 2011	DL	SQA19791	2	Extend variable referencing CONTROLTOTAL.TOTAL to dec(13,2) instead of dec(11,2)


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Update for WIP Ledger:
if exists(select * from CONTROLTOTAL
		WHERE LEDGER = @pnLedger AND PERIODID  = @pnPeriodId and ENTITYNO = @pnEntityNo
		and CATEGORY = @pnCategory -- MOVEMENTCLASS
		and TYPE = @pnType)
Begin
	-- Update the row
	Set @sSQLString = "UPDATE CONTROLTOTAL SET TOTAL = TOTAL + @pnAmountToAdd
						WHERE LEDGER = @pnLedger AND PERIODID  = @pnPeriodId and ENTITYNO = @pnEntityNo
							and CATEGORY = @pnCategory -- MOVEMENTCLASS
							and TYPE = @pnType"
End
Else
Begin
	-- Insert a new row
	Set @sSQLString = "INSERT INTO CONTROLTOTAL (LEDGER, PERIODID, ENTITYNO, CATEGORY, TYPE, TOTAL)
					values (@pnLedger, @pnPeriodId, @pnEntityNo, @pnCategory, @pnType, @pnAmountToAdd)"
End

exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnLedger		int,	
					@pnCategory		int,	
					@pnType		int,
					@pnPeriodId		int,	
					@pnEntityNo		int,
					@pnAmountToAdd	decimal(13,2)',
					@pnLedger = @pnLedger,
					@pnCategory	= @pnCategory,
					@pnType	= @pnType,
					@pnPeriodId	= @pnPeriodId,
					@pnEntityNo	= @pnEntityNo,
					@pnAmountToAdd = @pnAmountToAdd

Return @nErrorCode
GO

Grant execute on dbo.acw_UpdateControlTotal to public
GO