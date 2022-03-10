-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_AddToFeeList
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_AddToFeeList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_AddToFeeList.'
	Drop procedure [dbo].[wp_AddToFeeList]
End
Print '**** Creating Stored Procedure dbo.wp_AddToFeeList...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.wp_AddToFeeList
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture			nvarchar(10) 	=null,
 	@psFeeType			nvarchar(6),	-- Mandatory	Indicates the type of fee being paid
 	@pnCaseId			int				=null,			-- The Case being paid (optional entry because Official Number may be used)
 	@pnBaseFeeAmount	decimal(11,2)	=0,				-- Base fee being paid
 	@pnAdditionalFee	decimal(11,2)	=0,				-- Component of fee calculated from @pnQuantityInCalc
	@pnLocalAmount		decimal(11,2)	=0,				-- The total fee in local currency it is to be paid in
 	@pnForeignAmount	decimal(11,2)	=null,			-- Total Fee in foreign currency it is to be paid in
 	@psCurrency			nvarchar(3)	    =null,			-- The foreign currency the fee is being paid in. Null assumes local currency.
 	@pnQuantityInCalc	int		=0,						-- Quantity used to caculate @pnAdditionalFee
 	@psTaxCode			nvarchar(3)		=null,			-- Tax code associated with Fee.
 	@pnTaxAmount		decimal(11,2)	=0,				-- Tax amount of the Fee 	
 	@pnAgeOfCase		smallint		=null,			-- The annuity number of the Case being paid.
	@pnEntityKey		int,			-- Mandatory	   Entity WIP is recorded against
	@pdtTransDate		datetime,		-- Mandatory	   Date of transaction
 	@pdtWhenRequested	datetime		= null			-- This is current date/time which will be passed from wp_PostWIP so that the 
														--same date can be passed to fl_InsertFeeListCase
)
as
-- PROCEDURE:	wp_AddToFeeList
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure calls fl_InsertFeeListCase and wpw_PerformBankWithdrawal on wip posting

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Dec 2016	MS		R47798	1		Procedure created
-- 30 May 2018  AK	R74222		2		Added logic to catch errorcode from wpw_PerformBankWithdrawal

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(max)
Declare @nTotalFee		decimal(12,2)
Declare @bFeeListAutoCreate	bit

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	If @psCurrency is null
		Set @nTotalFee = isnull(@pnLocalAmount, 0) + isnull(@pnTaxAmount, 0)
	Else
		Set @nTotalFee = isnull(@pnForeignAmount, 0) + isnull(@pnTaxAmount, 0)

	-- Some code here
	If  @nErrorCode=0
	and @psFeeType is not null
	and @pnCaseId is not null
	and (isnull(@pnBaseFeeAmount,0)<>0 OR isnull(@pnAdditionalFee,0)<>0 OR isnull(@nTotalFee,0)<>0)
	Begin
		Exec @nErrorCode=dbo.fl_InsertFeeListCase
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture			= @psCulture,
 					@psFeeType			= @psFeeType,
 					@pnCaseId			= @pnCaseId,
 					@pnBaseFeeAmount	= @pnBaseFeeAmount,
 					@pnAdditionalFee	= @pnAdditionalFee,
 					@pnForeignFeeAmount	= @pnForeignAmount,
 					@psCurrency			= @psCurrency,
 					@pnQuantityInCalc	= @pnQuantityInCalc,
 					@pbToBePaid			= 1,
 					@psTaxCode			= @psTaxCode,
 					@pnTaxAmount		= @pnTaxAmount,
 					@pnTotalFee			= @nTotalFee,
 					@pnAgeOfCase		= @pnAgeOfCase,
 					@pdtWhenRequested	= @pdtWhenRequested
 	End	

	if (@nErrorCode = 0)
	Begin	
		Set @sSQLString = "Select @bFeeListAutoCreate = isnull(COLBOOLEAN,0)
		From SITECONTROL
		Where CONTROLID = 'FeesList Autocreate & Finalise'"

		exec	@nErrorCode = sp_executesql @sSQLString,
		N'@bFeeListAutoCreate	bit 			OUTPUT',
		@bFeeListAutoCreate = @bFeeListAutoCreate	OUTPUT
	End
		
	if (@nErrorCode = 0 and @psFeeType is not null and @bFeeListAutoCreate = 1)
	Begin
		Exec @nErrorCode= dbo.wpw_PerformBankWithdrawal
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture				= @psCulture,
			@pbCalledFromCentura	= 0,
			@psFeeType				= @psFeeType,
			@pnCaseKey				= @pnCaseId,
			@pdtTransDate			= @pdtTransDate,
			@pnEntityKey			= @pnEntityKey,
			@pdtWhenRequested		= @pdtWhenRequested
	End
End

Return @nErrorCode
GO

Grant execute on dbo.wp_AddToFeeList to public
GO
