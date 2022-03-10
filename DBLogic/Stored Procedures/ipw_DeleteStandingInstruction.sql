-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteStandingInstruction									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteStandingInstruction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteStandingInstruction.'
	Drop procedure [dbo].[ipw_DeleteStandingInstruction]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteStandingInstruction...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ipw_DeleteStandingInstruction
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnNameKey				int,		-- Mandatory
	@pnSequence				int,		-- Mandatory
	@pnCaseKey				int		= null,
	@pnPolicingBatchNo			int		= null,
	@pnOldCaseKey				int		= null,
	@pnOldRestrictedToNameKey		int		= null,
	@pnOldInstructionCode			int	= null,
	@psOldCountryCode			nvarchar(3)	= null,
	@psOldPropertyTypeCode			nchar(1)	= null,
	@pnOldPeriod1Amount			int	= null,
	@psOldPeriod1Type			nchar(1)	= null,
	@pnOldPeriod2Amount			int	= null,
	@psOldPeriod2Type			nchar(1)	= null,
	@pnOldPeriod3Amount			int	= null,
	@psOldPeriod3Type			nchar(1)	= null,
	@psOldAdjustmentTypeKey			nvarchar(4)	= null,
	@pnOldAdjustmentDayOfMonth		int		= null,
	@pnOldAdjustmentStartMonthKey		int		= null,
	@pnOldAdjustmentDayOfWeekKey		int		= null,
	@pdtOldAdjustToDate			datetime	= null,
	@pbIsCaseKeyInUse			bit		= 0,
	@pbIsRestrictedToNameKeyInUse		bit	 	= 0,
	@pbIsInstructionCodeInUse		bit	 	= 0,
	@pbIsCountryCodeInUse			bit	 	= 0,
	@pbIsPropertyTypeCodeInUse		bit	 	= 0,
	@pbIsPeriod1AmountInUse			bit	 	= 0,
	@pbIsPeriod1TypeInUse			bit	 	= 0,
	@pbIsPeriod2AmountInUse			bit	 	= 0,
	@pbIsPeriod2TypeInUse			bit	 	= 0,
	@pbIsPeriod3AmountInUse			bit	 	= 0,
	@pbIsPeriod3TypeInUse			bit	 	= 0,
	@pbIsAdjustmentTypeKeyInUse		bit		= 0,
	@pbIsAdjustmentDayOfMonthInUse		bit		= 0,
	@pbIsAdjustmentStartMonthKeyInUse	bit		= 0,
	@pbIsAdjustmentDayOfWeekKeyInUse	bit		= 0,
	@pbIsAdjustToDateInUse			bit		= 0
)
as
-- PROCEDURE:	ipw_DeleteStandingInstruction
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete StandingInstruction if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 20 Feb 2006	AU	RFC3209	1	Procedure created
-- 24 May 2006 	IB	RFC3678	2	Delete adjustments
-- 22 Oct 2008	AT	RFC7179	3	Change all tiny/smallints to int
-- 16 Dec 2008	SF	RFC7357	4	Remove AdjustmentStartMonth from concurrency checking 
--						- the start month is dynamically derived from the getter. (see cs_GetStandingInstructions)
-- 12 May 2011  LP      RFC10628 	5      	Recalculate standing instructions if necessary.
-- 18 Aug 2011	LP	RFC11051 	6	Pass Policing Batch No. to recalculation if specified.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)
Declare @nRowCount              int
Declare @sInstructionType 	nvarchar(3)

-- Initialise variables
Set @nErrorCode = 0

-- Get InstructionType if not yet available
If @nErrorCode = 0
and @sInstructionType is null
Begin
        Select @sInstructionType = INSTRUCTIONTYPE
        from INSTRUCTIONS
        where INSTRUCTIONCODE = @pnOldInstructionCode
End
        
If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from NAMEINSTRUCTIONS
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		NAMENO = @pnNameKey and
		INTERNALSEQUENCE = @pnSequence and"

	If @pbIsRestrictedToNameKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"RESTRICTEDTONAME = @pnOldRestrictedToNameKey"
		Set @sAnd = " and "
	End

	If @pbIsInstructionCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"INSTRUCTIONCODE = @pnOldInstructionCode"
		Set @sAnd = " and "
	End

	If @pbIsCaseKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CASEID = @pnOldCaseKey"
		Set @sAnd = " and "
	End

	If @pbIsCountryCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"COUNTRYCODE = @psOldCountryCode"
		Set @sAnd = " and "
	End

	If @pbIsPropertyTypeCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PROPERTYTYPE = @psOldPropertyTypeCode"
		Set @sAnd = " and "
	End

	If @pbIsPeriod1AmountInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PERIOD1AMT = @pnOldPeriod1Amount"
		Set @sAnd = " and "
	End

	If @pbIsPeriod1TypeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PERIOD1TYPE = @psOldPeriod1Type"
		Set @sAnd = " and "
	End

	If @pbIsPeriod2AmountInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PERIOD2AMT = @pnOldPeriod2Amount"
		Set @sAnd = " and "
	End

	If @pbIsPeriod2TypeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PERIOD2TYPE = @psOldPeriod2Type"
		Set @sAnd = " and "
	End

	If @pbIsPeriod3AmountInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PERIOD3AMT = @pnOldPeriod3Amount"
		Set @sAnd = " and "
	End

	If @pbIsPeriod3TypeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PERIOD3TYPE = @psOldPeriod3Type"
		Set @sAnd = " and "
	End

	If @pbIsAdjustmentTypeKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ADJUSTMENT = @psOldAdjustmentTypeKey"
		Set @sAnd = " and "
	End

	If @pbIsAdjustmentDayOfMonthInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ADJUSTDAY = @pnOldAdjustmentDayOfMonth"
		Set @sAnd = " and "
	End

--	If @pbIsAdjustmentStartMonthKeyInUse = 1
--	Begin
--		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ADJUSTSTARTMONTH = @pnOldAdjustmentStartMonthKey"
--		Set @sAnd = " and "
--	End

	If @pbIsAdjustmentDayOfWeekKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ADJUSTDAYOFWEEK = @pnOldAdjustmentDayOfWeekKey"
		Set @sAnd = " and "
	End

	If @pbIsAdjustToDateInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ADJUSTTODATE = @pdtOldAdjustToDate"
		Set @sAnd = " and "
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
		      N'@pnNameKey			int,
			@pnSequence			int,
			@pnCaseKey			int,
			@pnOldCaseKey			int,
			@pnOldRestrictedToNameKey	int,
			@pnOldInstructionCode		int,
			@psOldCountryCode		nvarchar(3),
			@psOldPropertyTypeCode		nchar(1),
			@pnOldPeriod1Amount		int,
			@psOldPeriod1Type		nchar(1),
			@pnOldPeriod2Amount		int,
			@psOldPeriod2Type		nchar(1),
			@pnOldPeriod3Amount		int,
			@psOldPeriod3Type		nchar(1),
			@psOldAdjustmentTypeKey		nvarchar(4),
			@pnOldAdjustmentDayOfMonth	int,
			@pnOldAdjustmentStartMonthKey	int,
			@pnOldAdjustmentDayOfWeekKey	int,
			@pdtOldAdjustToDate		datetime',
			@pnNameKey			= @pnNameKey,
			@pnSequence	 		= @pnSequence,
			@pnCaseKey	 		= @pnCaseKey,
			@pnOldCaseKey			= @pnOldCaseKey,
			@pnOldRestrictedToNameKey	= @pnOldRestrictedToNameKey,
			@pnOldInstructionCode	 	= @pnOldInstructionCode,
			@psOldCountryCode	 	= @psOldCountryCode,
			@psOldPropertyTypeCode	 	= @psOldPropertyTypeCode,
			@pnOldPeriod1Amount	 	= @pnOldPeriod1Amount,
			@psOldPeriod1Type	 	= @psOldPeriod1Type,
			@pnOldPeriod2Amount	 	= @pnOldPeriod2Amount,
			@psOldPeriod2Type	 	= @psOldPeriod2Type,
			@pnOldPeriod3Amount	 	= @pnOldPeriod3Amount,
			@psOldPeriod3Type	 	= @psOldPeriod3Type,
			@psOldAdjustmentTypeKey		= @psOldAdjustmentTypeKey,
			@pnOldAdjustmentDayOfMonth	= @pnOldAdjustmentDayOfMonth,
			@pnOldAdjustmentStartMonthKey	= @pnOldAdjustmentStartMonthKey,
			@pnOldAdjustmentDayOfWeekKey	= @pnOldAdjustmentDayOfWeekKey,
			@pdtOldAdjustToDate		= @pdtOldAdjustToDate
			
	Set @nRowCount = @@ROWCOUNT		
End

-- Generate Policing requests for the Case Events that should be recalculated as a result
-- deleted standing instructions
If @nErrorCode = 0
and @nRowCount > 0
Begin
        exec @nErrorCode=dbo.ip_RecalculateInstructionType
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= 0,
			@psInstructionType 	= @sInstructionType,
			@psAction		= 'D',
			@pnCaseKey 		= @pnOldCaseKey,        -- If the standing instruction has been modified against the Case then only recalculate Events for that specific Case.
			@pnNameKey 		= @pnNameKey,		-- If the standing instruction has been modified at the Name level then recalculate the CaseEvent rows for Cases linked to that name via the relevant NameType
			@pnInternalSequence	= @pnSequence,
			@pbExistingEventsOnly	= 0,
			@pbCountryNotChanged	= 0,
			@pbPropertyNotChanged	= 0,
			@pbNameNotChanged	= 0,
			@pnPolicingBatchNo	= @pnPolicingBatchNo
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteStandingInstruction to public
GO