-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_UpdateOpportunity									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_UpdateOpportunity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_UpdateOpportunity.'
	Drop procedure [dbo].[crm_UpdateOpportunity]
End
Print '**** Creating Stored Procedure dbo.crm_UpdateOpportunity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.crm_UpdateOpportunity
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnPotentialValueLocal		decimal(11,2)	= null,
	@pnPotentialValue		decimal(11,2)	= null,
	@pnSource			int		= null,
	@pdtExpCloseDate		datetime	= null,
	@psRemarks			nvarchar(254)	= null,
	@pnPotentialWin			decimal(5,2)	= null,
	@psNextStep			nvarchar(254)	= null,
	@pnStage			int		= null,
	@psPotentialValCurrency		nvarchar(3)	= null,
	@pnNumberOfStaff		int		= null,
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
	@pbIsPotentialValueLocalInUse	bit		= 0,
	@pbIsPotentialValueInUse	bit		= 0,
	@pbIsSourceInUse		bit		= 0,
	@pbIsExpCloseDateInUse		bit		= 0,
	@pbIsRemarksInUse		bit		= 0,
	@pbIsPotentialWinInUse		bit		= 0,
	@pbIsNextStepInUse		bit		= 0,
	@pbIsStageInUse			bit		= 0,
	@pbIsPotentialValCurrencyInUse	bit		= 0,
	@pbIsNumberOfStaffInUse		bit		= 0
)
as
-- PROCEDURE:	crm_UpdateOpportunity
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Opportunity if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 17 Jun 2008	AT	RFC5748	1	Procedure created
-- 20 Aug 2008	AT	RFC6894	2	Added Potential Value Local.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update OPPORTUNITY
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		CASEID = @pnCaseKey
"

	If @pbIsPotentialValueLocalInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POTENTIALVALUELOCAL = @pnPotentialValueLocal"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"POTENTIALVALUELOCAL = @pnOldPotentialValueLocal"
		Set @sComma = ","
	End

	If @pbIsPotentialValueInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POTENTIALVALUE = @pnPotentialValue"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"POTENTIALVALUE = @pnOldPotentialValue"
		Set @sComma = ","
	End

	If @pbIsSourceInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SOURCE = @pnSource"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"SOURCE = @pnOldSource"
		Set @sComma = ","
	End

	If @pbIsExpCloseDateInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EXPCLOSEDATE = @pdtExpCloseDate"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"EXPCLOSEDATE = @pdtOldExpCloseDate"
		Set @sComma = ","
	End

	If @pbIsRemarksInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REMARKS = @psRemarks"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"REMARKS = @psOldRemarks"
		Set @sComma = ","
	End

	If @pbIsPotentialWinInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POTENTIALWIN = @pnPotentialWin"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"POTENTIALWIN = @pnOldPotentialWin"
		Set @sComma = ","
	End

	If @pbIsNextStepInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NEXTSTEP = @psNextStep"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NEXTSTEP = @psOldNextStep"
		Set @sComma = ","
	End

	If @pbIsStageInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STAGE = @pnStage"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"STAGE = @pnOldStage"
		Set @sComma = ","
	End

	If @pbIsPotentialValCurrencyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POTENTIALVALCURRENCY = @psPotentialValCurrency"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"POTENTIALVALCURRENCY = @psOldPotentialValCurrency"
		Set @sComma = ","
	End

	If @pbIsNumberOfStaffInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NUMBEROFSTAFF = @pnNumberOfStaff"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NUMBEROFSTAFF = @pnOldNumberOfStaff"
		Set @sComma = ","
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnCaseKey		int,
			@pnPotentialValueLocal	decimal(11,2),
			@pnPotentialValue	decimal(11,2),
			@pnSource		int,
			@pdtExpCloseDate	datetime,
			@psRemarks		nvarchar(254),
			@pnPotentialWin		decimal(5,2),
			@psNextStep		nvarchar(254),
			@pnStage		int,
			@psPotentialValCurrency	nvarchar(3),
			@pnNumberOfStaff	int,
			@pnOldPotentialValueLocal	decimal(11,2),
			@pnOldPotentialValue	decimal(11,2),
			@pnOldSource		int,
			@pdtOldExpCloseDate	datetime,
			@psOldRemarks		nvarchar(254),
			@pnOldPotentialWin	decimal(5,2),
			@psOldNextStep		nvarchar(254),
			@pnOldStage		int,
			@psOldPotentialValCurrency	nvarchar(3),
			@pnOldNumberOfStaff	int',
			@pnCaseKey	 = @pnCaseKey,
			@pnPotentialValueLocal	 = @pnPotentialValueLocal,
			@pnPotentialValue	 = @pnPotentialValue,
			@pnSource	 = @pnSource,
			@pdtExpCloseDate	 = @pdtExpCloseDate,
			@psRemarks	 = @psRemarks,
			@pnPotentialWin	 = @pnPotentialWin,
			@psNextStep	 = @psNextStep,
			@pnStage	 = @pnStage,
			@psPotentialValCurrency	 = @psPotentialValCurrency,
			@pnNumberOfStaff	= @pnNumberOfStaff,
			@pnOldPotentialValueLocal = @pnOldPotentialValueLocal,
			@pnOldPotentialValue	 = @pnOldPotentialValue,
			@pnOldSource	 = @pnOldSource,
			@pdtOldExpCloseDate	 = @pdtOldExpCloseDate,
			@psOldRemarks	 = @psOldRemarks,
			@pnOldPotentialWin	 = @pnOldPotentialWin,
			@psOldNextStep	 = @psOldNextStep,
			@pnOldStage	 = @pnOldStage,
			@psOldPotentialValCurrency	 = @psOldPotentialValCurrency,
			@pnOldNumberOfStaff	= @pnOldNumberOfStaff


End

Return @nErrorCode
GO

Grant execute on dbo.crm_UpdateOpportunity to public
GO