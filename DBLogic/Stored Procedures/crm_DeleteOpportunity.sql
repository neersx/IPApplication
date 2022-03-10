
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_DeleteOpportunity									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_DeleteOpportunity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_DeleteOpportunity.'
	Drop procedure [dbo].[crm_DeleteOpportunity]
End
Print '**** Creating Stored Procedure dbo.crm_DeleteOpportunity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.crm_DeleteOpportunity
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnOldPotentialValueLocal	decimal(11,2)	= null,
	@pnOldPotentialValue		decimal(11,2)	= null,
	@pnOldSource			int		= null,
	@pdtOldExpCloseDate		datetime	= null,
	@psOldRemarks			nvarchar(254)	= null,
	@pnOldPotentialWin		decimal(5,2)	= null,
	@psOldNextStep			nvarchar(254)	= null,
	@pnOldStage			int		= null,
	@psOldPotentialValCurrency	nvarchar(3)	= null,
	@pnOldNumberOfStaff		int		= null,
	@pbIsPotentialValueLocalInUse	bit	 	= 0,
	@pbIsPotentialValueInUse	bit	 	= 0,
	@pbIsSourceInUse		bit	 	= 0,
	@pbIsExpCloseDateInUse		bit	 	= 0,
	@pbIsRemarksInUse		bit	 	= 0,
	@pbIsPotentialWinInUse		bit	 	= 0,
	@pbIsNextStepInUse		bit	 	= 0,
	@pbIsStageInUse			bit	 	= 0,
	@pbIsPotentialValCurrencyInUse	bit	 	= 0,
	@pbIsNumberOfStaffInUse		bit	 	= 0
)
as
-- PROCEDURE:	crm_DeleteOpportunity
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Opportunity if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 17 Jun 2008	AT	RFC5748	1	Procedure created
-- 20 Aug 2008	AT	RFC6894	2	Add Potential value Local.

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
	Set @sDeleteString = "Delete from OPPORTUNITY
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		CASEID = @pnCaseKey
"

	If @pbIsPotentialValueLocalInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"POTENTIALVALUELOCAL = @pnOldPotentialValueLocal"
	End

	If @pbIsPotentialValueInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"POTENTIALVALUE = @pnOldPotentialValue"
	End

	If @pbIsSourceInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"SOURCE = @pnOldSource"
	End

	If @pbIsExpCloseDateInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"EXPCLOSEDATE = @pdtOldExpCloseDate"
	End

	If @pbIsRemarksInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"REMARKS = @psOldRemarks"
	End

	If @pbIsPotentialWinInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"POTENTIALWIN = @pnOldPotentialWin"
	End

	If @pbIsNextStepInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"NEXTSTEP = @psOldNextStep"
	End

	If @pbIsStageInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"STAGE = @pnOldStage"
	End

	If @pbIsPotentialValCurrencyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"POTENTIALVALCURRENCY = @psOldPotentialValCurrency"
	End

	If @pbIsNumberOfStaffInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"NUMBEROFSTAFF = @pnOldNumberOfStaff"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
			@pnCaseKey			int,
			@pnOldPotentialValueLocal	decimal(11,2),
			@pnOldPotentialValue		decimal(11,2),
			@pnOldSource			int,
			@pdtOldExpCloseDate		datetime,
			@psOldRemarks			nvarchar(254),
			@pnOldPotentialWin		decimal(5,2),
			@psOldNextStep			nvarchar(254),
			@pnOldStage			int,
			@psOldPotentialValCurrency	nvarchar(3),
			@pnOldNumberOfStaff		int',
			@pnCaseKey	 		= @pnCaseKey,
			@pnOldPotentialValueLocal 	= @pnOldPotentialValueLocal,
			@pnOldPotentialValue	 	= @pnOldPotentialValue,
			@pnOldSource	 		= @pnOldSource,
			@pdtOldExpCloseDate	 	= @pdtOldExpCloseDate,
			@psOldRemarks	 		= @psOldRemarks,
			@pnOldPotentialWin	 	= @pnOldPotentialWin,
			@psOldNextStep	 		= @psOldNextStep,
			@pnOldStage	 		= @pnOldStage,
			@psOldPotentialValCurrency	= @psOldPotentialValCurrency,
			@pnOldNumberOfStaff		= @pnOldNumberOfStaff


End

Return @nErrorCode
GO

Grant execute on dbo.crm_DeleteOpportunity to public
GO