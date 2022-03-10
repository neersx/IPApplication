-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateStandingInstruction									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateStandingInstruction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateStandingInstruction.'
	Drop procedure [dbo].[ipw_UpdateStandingInstruction]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateStandingInstruction...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ipw_UpdateStandingInstruction
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnNameKey				int,		-- Mandatory
	@pnSequence				int,		-- Mandatory
	@pnCaseKey				int		= null,
	@pnRestrictedToNameKey			int		= null,
	@pnInstructionCode			int		= null,
	@psCountryCode				nvarchar(3)	= null,
	@psPropertyTypeCode			nchar(1)	= null,
	@pnPeriod1Amount			int	= null,
	@psPeriod1Type				nchar(1)	= null,
	@pnPeriod2Amount			int	= null,
	@psPeriod2Type				nchar(1)	= null,
	@pnPeriod3Amount			int	= null,
	@psPeriod3Type				nchar(1)	= null,
	@psAdjustmentTypeKey			nvarchar(4)	= null,
	@pnAdjustmentDayOfMonth			int		= null,
	@pnAdjustmentStartMonthKey		int		= null,
	@pnAdjustmentDayOfWeekKey		int		= null,
	@pdtAdjustToDate			datetime	= null,
	@pnPolicingBatchNo			int		= null,
	@psStandingInstrText			nvarchar(max)	= null,
	@pnOldCaseKey				int		= null,
	@pnOldRestrictedToNameKey		int		= null,
	@pnOldInstructionCode			int	= null,
	@psOldCountryCode			nvarchar(3)	= null,
	@psOldPropertyTypeCode			nchar(1) 	= null,
	@pnOldPeriod1Amount			int 	= null,
	@psOldPeriod1Type			nchar(1) 	= null,
	@pnOldPeriod2Amount			int 	= null,
	@psOldPeriod2Type			nchar(1) 	= null,
	@pnOldPeriod3Amount			int 	= null,
	@psOldPeriod3Type			nchar(1) 	= null,
	@psOldAdjustmentTypeKey			nvarchar(4)	= null,
	@pnOldAdjustmentDayOfMonth		int		= null,
	@pnOldAdjustmentStartMonthKey		int		= null,
	@pnOldAdjustmentDayOfWeekKey		int		= null,
	@pdtOldAdjustToDate			datetime	= null,
	@psOldStandingInstrText			nvarchar(max)	= null,
	@pbIsCaseKeyInUse			bit		= 0,
	@pbIsRestrictedToNameKeyInUse		bit	 	= 0,
	@pbIsInstructionCodeInUse		bit	 	= 0,
	@pbIsCountryCodeInUse			bit	 	= 0,
	@pbIsPropertyTypeCodeInUse		bit	 	= 0,
	@pbIsPeriod1AmountInUse			bit		= 0,
	@pbIsPeriod1TypeInUse			bit	 	= 0,
	@pbIsPeriod2AmountInUse			bit		= 0,
	@pbIsPeriod2TypeInUse			bit	 	= 0,
	@pbIsPeriod3AmountInUse			bit	 	= 0,
	@pbIsPeriod3TypeInUse			bit	 	= 0,
	@pbIsAdjustmentTypeKeyInUse		bit		= 0,
	@pbIsAdjustmentDayOfMonthInUse		bit		= 0,
	@pbIsAdjustmentStartMonthKeyInUse	bit		= 0,
	@pbIsAdjustmentDayOfWeekKeyInUse	bit		= 0,
	@pbIsAdjustToDateInUse			bit		= 0,
	@pbIsStandingInstrTextInUse		bit		= 0
)
as
-- PROCEDURE:	ipw_UpdateStandingInstruction
-- VERSION:	10
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update StandingInstruction if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 20 Feb 2006	AU	RFC3209	1	Procedure created
-- 24 May 2006 	IB	RFC3678	2	Update adjustments
-- 22 Oct 2008	AT	RFC7179	3	Change all tiny/smallints to int
-- 04 Oct 2010  DV      RFC7914		 4       	Update the STANDINGINSTRTEXT 
-- 12 May 2011  LP        RFC10628 	5     	 Recalculate standing instructions if necessary.
-- 18 Aug 2011	LP       RFC11051 	7	Pass Policing Batch No. to recalculation if specified.
-- 08 Sep 2011	ASH     R10723 		8	Change the logic to update ADJUSTDAYOFWEEK.
-- 12 Sep 2011	LP      R11280 		9	Change the logic to update ADJUSTDAYOFWEEK.
-- 05 Feb 2011	LP	R11538	10	Reinstate updating of STANDINGINSTRTEXT.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString	nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd		nchar(5)
Declare @nRowCount      int
Declare @sInstructionType nvarchar(3)
Declare @bExistingEventsOnly	bit
Declare @bCountryNotChanged	bit
Declare	@bPropertyNotChanged	bit
Declare @bNameNotChanged	bit

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
        Select @sInstructionType = INSTRUCTIONTYPE
        from INSTRUCTIONS
        where INSTRUCTIONCODE = @pnOldInstructionCode
End

If @nErrorCode=0
Begin
	--------------------------------------------------------------------
	-- Check which Case characteristics against the Standing Instruction 
	-- have changed.  This will be used to determine which Cases will
	-- require repolicing.
	--------------------------------------------------------------------
	Set @sSQLString=
	"Select @bCountryNotChanged =CASE WHEN(isnull(NI.COUNTRYCODE,     '')=isnull(@psCountryCode,     '')) THEN 1 ELSE 0 END,"+char(10)+
	"	@bPropertyNotChanged=CASE WHEN(isnull(NI.PROPERTYTYPE,    '')=isnull(@psPropertyType,    '')) THEN 1 ELSE 0 END,"+char(10)+
	"	@bNameNotChanged    =CASE WHEN(isnull(NI.RESTRICTEDTONAME,'')=isnull(@pnRestrictedToName,'')) THEN 1 ELSE 0 END," +char(10)+
	"	@bExistingEventsOnly=CASE WHEN(NI.INSTRUCTIONCODE            =@pnInstructionCode"+char(10)+
	"				   and isnull(NI.COUNTRYCODE,     '')=isnull(@psCountryCode,     '')"+char(10)+
	"				   and isnull(NI.PROPERTYTYPE,    '')=isnull(@psPropertyType,    '')"+char(10)+
	"				   and isnull(NI.RESTRICTEDTONAME,'')=isnull(@pnRestrictedToName,'')) THEN 1 ELSE 0 END" +char(10)+
	"From NAMEINSTRUCTIONS NI"+char(10)+ 
	"join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)"+char(10)+
	"where NI.NAMENO=@pnNameNo"+char(10)+
	"and NI.INTERNALSEQUENCE=@pnInternalSequence"+char(10)+
	"and I.INSTRUCTIONTYPE=@psInstructionType"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bCountryNotChanged	bit	OUTPUT,
				  @bPropertyNotChanged	bit	OUTPUT,
				  @bNameNotChanged	bit	OUTPUT,
				  @bExistingEventsOnly	bit	OUTPUT,
				  @pnNameNo		int,
				  @pnInternalSequence	int,
				  @psInstructionType	nvarchar(3),
				  @pnInstructionCode	smallint,
				  @psCountryCode	nvarchar(3),
				  @psPropertyType	nchar(1),
				  @pnRestrictedToName	int',
				  @bCountryNotChanged	=@bCountryNotChanged	OUTPUT,
				  @bPropertyNotChanged	=@bPropertyNotChanged	OUTPUT,
				  @bNameNotChanged	=@bNameNotChanged	OUTPUT,
				  @bExistingEventsOnly	=@bExistingEventsOnly	OUTPUT,
				  @pnNameNo		=@pnNameKey,
				  @pnInternalSequence	=@pnSequence,
				  @psInstructionType	=@sInstructionType,
				  @pnInstructionCode	=@pnInstructionCode,
				  @psCountryCode	=@psCountryCode,
				  @psPropertyType	=@psPropertyTypeCode,
				  @pnRestrictedToName	=@pnRestrictedToNameKey
End

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update NAMEINSTRUCTIONS
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		NAMENO = @pnNameKey and
		INTERNALSEQUENCE = @pnSequence and"

	If @pbIsRestrictedToNameKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RESTRICTEDTONAME = @pnRestrictedToNameKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"RESTRICTEDTONAME = @pnOldRestrictedToNameKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsInstructionCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INSTRUCTIONCODE = @pnInstructionCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"INSTRUCTIONCODE = @pnOldInstructionCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsCaseKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CASEID = @pnCaseKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CASEID = @pnOldCaseKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsCountryCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"COUNTRYCODE = @psCountryCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"COUNTRYCODE = @psOldCountryCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsPropertyTypeCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PROPERTYTYPE = @psPropertyTypeCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PROPERTYTYPE = @psOldPropertyTypeCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsPeriod1AmountInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PERIOD1AMT = @pnPeriod1Amount"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PERIOD1AMT = @pnOldPeriod1Amount"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsPeriod1TypeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PERIOD1TYPE = @psPeriod1Type"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PERIOD1TYPE = @psOldPeriod1Type"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsPeriod2AmountInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PERIOD2AMT = @pnPeriod2Amount"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PERIOD2AMT = @pnOldPeriod2Amount"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsPeriod2TypeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PERIOD2TYPE = @psPeriod2Type"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PERIOD2TYPE = @psOldPeriod2Type"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsPeriod3AmountInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PERIOD3AMT = @pnPeriod3Amount"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PERIOD3AMT = @pnOldPeriod3Amount"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsPeriod3TypeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PERIOD3TYPE = @psPeriod3Type"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PERIOD3TYPE = @psOldPeriod3Type"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsAdjustmentTypeKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ADJUSTMENT = @psAdjustmentTypeKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ADJUSTMENT = @psOldAdjustmentTypeKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsAdjustmentDayOfMonthInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ADJUSTDAY = @pnAdjustmentDayOfMonth"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ADJUSTDAY = @pnOldAdjustmentDayOfMonth"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsAdjustmentStartMonthKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ADJUSTSTARTMONTH = @pnAdjustmentStartMonthKey"
		-- This value is defaulted from the GET so the concurrency may be incorrect.
		--Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ADJUSTSTARTMONTH = @pnOldAdjustmentStartMonthKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsAdjustmentDayOfWeekKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ADJUSTDAYOFWEEK = @pnAdjustmentDayOfWeekKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"(ADJUSTDAYOFWEEK = @pnOldAdjustmentDayOfWeekKey or ADJUSTDAYOFWEEK=0)"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsAdjustToDateInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ADJUSTTODATE = @pdtAdjustToDate"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ADJUSTTODATE = @pdtOldAdjustToDate"
		Set @sComma = ","
		Set @sAnd = " and "
	End
	
	If @pbIsStandingInstrTextInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STANDINGINSTRTEXT = @psStandingInstrText"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"STANDINGINSTRTEXT = @psOldStandingInstrText"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
		       N'@pnNameKey			int,
			@pnSequence			int,
			@pnCaseKey			int,
			@pnOldCaseKey			int,
			@pnRestrictedToNameKey		int,
			@pnInstructionCode		int,
			@psCountryCode			nvarchar(3),
			@psPropertyTypeCode		nchar(1),
			@pnPeriod1Amount		int,
			@psPeriod1Type			nchar(1),
			@pnPeriod2Amount		int,
			@psPeriod2Type			nchar(1),
			@pnPeriod3Amount		int,
			@psPeriod3Type			nchar(1),
			@psAdjustmentTypeKey		nvarchar(4),
			@pnAdjustmentDayOfMonth		int,
			@pnAdjustmentStartMonthKey	int,
			@pnAdjustmentDayOfWeekKey	int,
			@pdtAdjustToDate		datetime,
			@psStandingInstrText            nvarchar(max),
			@pnOldRestrictedToNameKey 	int,
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
			@pdtOldAdjustToDate		datetime,
			@psOldStandingInstrText         nvarchar(max)',
			@pnNameKey	 		= @pnNameKey,
			@pnSequence	 		= @pnSequence,
			@pnCaseKey	 		= @pnCaseKey,
			@pnOldCaseKey	 		= @pnOldCaseKey,
			@pnRestrictedToNameKey		= @pnRestrictedToNameKey,
			@pnInstructionCode		= @pnInstructionCode,
			@psCountryCode	 		= @psCountryCode,
			@psPropertyTypeCode		= @psPropertyTypeCode,
			@pnPeriod1Amount		= @pnPeriod1Amount,
			@psPeriod1Type	 		= @psPeriod1Type,
			@pnPeriod2Amount		= @pnPeriod2Amount,
			@psPeriod2Type			= @psPeriod2Type,
			@pnPeriod3Amount		= @pnPeriod3Amount,
			@psPeriod3Type	 		= @psPeriod3Type,
			@psAdjustmentTypeKey		= @psAdjustmentTypeKey,
			@pnAdjustmentDayOfMonth		= @pnAdjustmentDayOfMonth,
			@pnAdjustmentStartMonthKey	= @pnAdjustmentStartMonthKey,
			@pnAdjustmentDayOfWeekKey	= @pnAdjustmentDayOfWeekKey,
			@pdtAdjustToDate		= @pdtAdjustToDate,
			@psStandingInstrText            = @psStandingInstrText,
			@pnOldRestrictedToNameKey 	= @pnOldRestrictedToNameKey,
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
			@pdtOldAdjustToDate		= @pdtOldAdjustToDate,
			@psOldStandingInstrText         = @psOldStandingInstrText
			
	Set @nRowCount = @@RowCount
End

-- Generate Policing requests for the Case Events that should be recalculated as a result
-- updated standing instructions
If @nErrorCode = 0
and @nRowCount > 0
Begin
        exec @nErrorCode=dbo.ip_RecalculateInstructionType
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= 0,
			@psInstructionType 	= @sInstructionType,
			@psAction		= 'U',
			@pnCaseKey 		= @pnOldCaseKey,        -- If the standing instruction has been modified against the Case then only recalculate Events for that specific Case.
			@pnNameKey 		= @pnNameKey,		-- If the standing instruction has been modified at the Name level then recalculate the CaseEvent rows for Cases linked to that name via the relevant NameType
			@pnInternalSequence	= @pnSequence,
			@pbExistingEventsOnly	= @bExistingEventsOnly,
			@pbCountryNotChanged	= @bCountryNotChanged,
			@pbPropertyNotChanged	= @bPropertyNotChanged,
			@pbNameNotChanged	= @bNameNotChanged,
			@pnPolicingBatchNo	= @pnPolicingBatchNo		
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateStandingInstruction to public
GO