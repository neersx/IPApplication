-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertStandingInstruction									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertStandingInstruction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertStandingInstruction.'
	Drop procedure [dbo].[ipw_InsertStandingInstruction]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertStandingInstruction...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertStandingInstruction
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnNameKey				int,		-- Mandatory
	@pnSequence				int		= null,
	@pnCaseKey				int		= null,
	@pnRestrictedToNameKey			int		= null,
	@pnInstructionCode			int	= null,
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
	@psStandingInstrText                    nvarchar(max)   = null,
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
	@pbIsAdjustToDateInUse			bit		= 0,
	@pbIsStandingInstrTextInUse		bit		= 0
)
as
-- PROCEDURE:	ipw_InsertStandingInstruction
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert StandingInstruction.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 20 Feb 2006	AU	RFC3209	1	Procedure created
-- 24 May 2006 	IB	RFC3678	2	Insert adjustments
-- 22 Oct 2008	AT	RFC7179	3	Change all tiny/smallints to int
-- 01 Jul 2010	MF	18758	4	Increase the column size of Instruction Type to allow for expanded list.
-- 04 Oct 2010  DV      RFC7915 5       Insert the STANDINGINSTRTEXT column values in the table
-- 12 May 2011  LP      RFC10568 	6            Recalculate standing instructions if necessary.
-- 18 Aug 2011	LP	RFC11051	7	Pass Policing Batch No. to recalculation if specified.
-- 09 Feb 2012	LP	R11538	8	Reinstate insert logic of STANDINGINSTRTEXT

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sSQLString2		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sLocateNameNoSQL 	nvarchar(4000)
Declare @sInstructionType 	nvarchar(3)
Declare @sNameTypeDescription	nvarchar(50)
Declare @sAlertXML		nvarchar(400)
Declare @sComma			nchar(1)
Declare @sLookupCulture		nvarchar(10)
Declare @nRowCount              int

-- Initialise variables
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into NAMEINSTRUCTIONS
				("

	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"NAMENO,INTERNALSEQUENCE"

	If @pnNameKey is null
	Begin	
		Set @sLocateNameNoSQL = "
		Select	@pnNameKey 		= CN.NAMENO,
			@sInstructionType 	= IT.INSTRUCTIONTYPE,
			@sNameTypeDescription 	= " + dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura) + "
		from INSTRUCTIONS I
		join INSTRUCTIONTYPE IT		on (IT.INSTRUCTIONTYPE = I.INSTRUCTIONTYPE)
		join NAMETYPE NT 		on (NT.NAMETYPE = IT.NAMETYPE)
		left join CASENAME CN		on (CN.CASEID 	= @pnCaseKey)
						and (CN.NAMETYPE = IT.NAMETYPE)
						and(CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate())
						and CN.SEQUENCE =(	Select MIN(CN.SEQUENCE)
									from CASENAME CN
									where 	CN.CASEID	= @pnCaseKey
									and 	CN.NAMETYPE	= IT.NAMETYPE
									and	(CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate()))
		where I.INSTRUCTIONCODE = @pnInstructionCode"
			
		exec @nErrorCode=sp_executesql @sLocateNameNoSQL,
			      	N'@pnNameKey		int		OUTPUT,
				@sInstructionType	nvarchar(3)	OUTPUT,
				@sNameTypeDescription	nvarchar(50)	OUTPUT,
				@pnCaseKey		int,
				@pnInstructionCode	int,
				@sLookupCulture		nvarchar(10),
				@pbCalledFromCentura	bit',
				@pnNameKey		= @pnNameKey		OUTPUT,
				@sInstructionType	= @sInstructionType 	OUTPUT,
				@sNameTypeDescription	= @sNameTypeDescription	OUTPUT,
				@sLookupCulture		= @sLookupCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@pnCaseKey	 	= @pnCaseKey,
				@pnInstructionCode	= @pnInstructionCode

		If @pnNameKey is null
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('CS59', 'Cannot save Standing Instruction Type: {0}. No entry exists for {1} in the Case Names. Please make an entry for this Name Type.',
    								@sInstructionType, @sNameTypeDescription, null, null, null)
  			RAISERROR(@sAlertXML, 12, 1)
  			Set @nErrorCode = @@ERROR
		End
	End
	
	-- Get InstructionType if not yet available
	If @nErrorCode = 0
	and @sInstructionType is null
        Begin
                Select @sInstructionType = INSTRUCTIONTYPE
                from INSTRUCTIONS
                where INSTRUCTIONCODE = @pnInstructionCode
        End
	
	Set @sValuesString = @sValuesString+CHAR(10)+"@pnNameKey,@pnSequence"

	If @pbIsRestrictedToNameKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"RESTRICTEDTONAME"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnRestrictedToNameKey"
		Set @sComma = ","
	End

	If @pbIsInstructionCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INSTRUCTIONCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnInstructionCode"
		Set @sComma = ","
	End

	If @pbIsCaseKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CASEID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCaseKey"
		Set @sComma = ","
	End

	If @pbIsCountryCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"COUNTRYCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCountryCode"
		Set @sComma = ","
	End

	If @pbIsPropertyTypeCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PROPERTYTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPropertyTypeCode"
		Set @sComma = ","
	End

	If @pbIsPeriod1AmountInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PERIOD1AMT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPeriod1Amount"
		Set @sComma = ","
	End

	If @pbIsPeriod1TypeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PERIOD1TYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPeriod1Type"
		Set @sComma = ","
	End

	If @pbIsPeriod2AmountInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PERIOD2AMT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPeriod2Amount"
		Set @sComma = ","
	End

	If @pbIsPeriod2TypeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PERIOD2TYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPeriod2Type"
		Set @sComma = ","
	End

	If @pbIsPeriod3AmountInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PERIOD3AMT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPeriod3Amount"
		Set @sComma = ","
	End

	If @pbIsPeriod3TypeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PERIOD3TYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPeriod3Type"
		Set @sComma = ","
	End

	If @pbIsAdjustmentTypeKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ADJUSTMENT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psAdjustmentTypeKey"
		Set @sComma = ","
	End

	If @pbIsAdjustmentDayOfMonthInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ADJUSTDAY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAdjustmentDayOfMonth"
		Set @sComma = ","
	End

	If @pbIsAdjustmentStartMonthKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ADJUSTSTARTMONTH"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAdjustmentStartMonthKey"
		Set @sComma = ","
	End

	If @pbIsAdjustmentDayOfWeekKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ADJUSTDAYOFWEEK"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAdjustmentDayOfWeekKey"
		Set @sComma = ","
	End

	If @pbIsAdjustToDateInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ADJUSTTODATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtAdjustToDate"
		Set @sComma = ","
	End
	
	If @pbIsStandingInstrTextInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STANDINGINSTRTEXT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psStandingInstrText"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	-- Get the next sequence no
	If @nErrorCode = 0
	Begin
		Set @sSQLString2 = "
		Select @pnSequence = isnull(MAX(INTERNALSEQUENCE)+1, 0)
		from NAMEINSTRUCTIONS
		where NAMENO = @pnNameKey"
	
		exec @nErrorCode=sp_executesql @sSQLString2,	
					      N'@pnSequence	int		output,
						@pnNameKey	int',
						@pnSequence	= @pnSequence	output,
						@pnNameKey	= @pnNameKey
	End

	If @nErrorCode = 0
	Begin
		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@pnNameKey 			int,
				@pnSequence			int,
				@pnCaseKey			int,
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
				@psStandingInstrText            nvarchar(max)',
				@pnNameKey	 		= @pnNameKey,
				@pnSequence	 		= @pnSequence,
				@pnCaseKey	 		= @pnCaseKey,
				@pnRestrictedToNameKey		= @pnRestrictedToNameKey,
				@pnInstructionCode		= @pnInstructionCode,
				@psCountryCode	 		= @psCountryCode,
				@psPropertyTypeCode		= @psPropertyTypeCode,
				@pnPeriod1Amount		= @pnPeriod1Amount,
				@psPeriod1Type	 		= @psPeriod1Type,
				@pnPeriod2Amount		= @pnPeriod2Amount,
				@psPeriod2Type	 		= @psPeriod2Type,
				@pnPeriod3Amount		= @pnPeriod3Amount,
				@psPeriod3Type	 		= @psPeriod3Type,
				@psAdjustmentTypeKey		= @psAdjustmentTypeKey,
				@pnAdjustmentDayOfMonth		= @pnAdjustmentDayOfMonth,
				@pnAdjustmentStartMonthKey	= @pnAdjustmentStartMonthKey,
				@pnAdjustmentDayOfWeekKey	= @pnAdjustmentDayOfWeekKey,
				@pdtAdjustToDate		= @pdtAdjustToDate,
				@psStandingInstrText            = @psStandingInstrText
				
		Set @nRowCount = @@ROWCOUNT		
	End
End

If @nErrorCode = 0
Begin
	Select @pnSequence as 'Sequence'
End

-- Generate Policing requests for the Case Events that should be recalculated as a result
-- inserted standing instructions
If @nErrorCode = 0
and @nRowCount > 0
Begin
        exec @nErrorCode=dbo.ip_RecalculateInstructionType
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= 0,
			@psInstructionType 	= @sInstructionType,
			@psAction		= 'I',
			@pnCaseKey 		= @pnCaseKey,        -- If the standing instruction has been modified against the Case then only recalculate Events for that specific Case.
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

Grant execute on dbo.ipw_InsertStandingInstruction to public
GO