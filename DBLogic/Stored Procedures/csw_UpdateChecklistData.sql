-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateChecklistData									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateChecklistData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateChecklistData.'
	Drop procedure [dbo].[csw_UpdateChecklistData]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateChecklistData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateChecklistData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,	-- Mandatory
	@pnQuestionKey		smallint,	-- Mandatory
	@pnChecklistTypeKey	smallint		 = null,
	@pnChecklistCriteriaKey	int		 = null,
	@pnListSelectionKey	int		 = null,
	@pbYesNoAnswer	bit		 = null,
	@pnCountValue	int		 = null,
	@pnAmountValue	decimal(11,2)		 = null,
	@ptTextValue	ntext		 = null,
	@pnStaffNameKey	int		 = null,
	@pbIsProcessed	bit		 = null,
	@pnProductCode	int		 = null,
	@pnOldListSelectionKey	int		 = null,
	@pbOldYesNoAnswer	bit		 = null,
	@pnOldCountValue	int		 = null,
	@pnOldAmountValue	decimal(11,2)		 = null,
	@ptOldTextValue	ntext		 = null,
	@pnOldStaffNameKey	int		 = null,
	@pbOldIsProcessed	bit		 = null,
	@pnOldProductCode	int		 = null,
	@pbIsChecklistTypeKeyInUse		bit	 = 0,
	@pbIsChecklistCriteriaKeyInUse		bit	 = 0,
	@pbIsListSelectionKeyInUse		bit	 = 0,
	@pbIsYesNoAnswerInUse		bit	 = 0,
	@pbIsCountValueInUse		bit	 = 0,
	@pbIsAmountValueInUse		bit	 = 0,
	@pbIsTextValueInUse		bit	 = 0,
	@pbIsStaffNameKeyInUse		bit	 = 0,
	@pbIsIsProcessedInUse		bit	 = 0,
	@pbIsProductCodeInUse		bit	 = 0,
	@pbIsBypassConcurrencyChecking bit = 0
)
as
-- PROCEDURE:	csw_UpdateChecklistData
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update CaseChecklist if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 27 Nov 2007	RFC5776	1		Procedure created
-- 23 Jul 2010	RFC9568	2		Implement @pbIsBypassConcurrencyChecking to by pass data concurrency check on 
--								to cater for a specific use case in workflow

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT OFF
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
Set @sComma = ','

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update CASECHECKLIST
			   set	CHECKLISTTYPE = @pnChecklistTypeKey,
					CRITERIANO = @pnChecklistCriteriaKey "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		CASEID = @pnCaseKey and
		QUESTIONNO = @pnQuestionKey
"
	If @pbIsListSelectionKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TABLECODE = @pnListSelectionKey"
		Set @sComma = ","
		
		If @pbIsBypassConcurrencyChecking = 0
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TABLECODE = @pnOldListSelectionKey"
		End
	End

	If @pbIsYesNoAnswerInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"YESNOANSWER = @pbYesNoAnswer"
		Set @sComma = ","
		
		If @pbIsBypassConcurrencyChecking = 0
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"YESNOANSWER = @pbOldYesNoAnswer"
		End
	End

	If @pbIsCountValueInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"COUNTANSWER = @pnCountValue"
		Set @sComma = ","
		
		If @pbIsBypassConcurrencyChecking = 0
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"COUNTANSWER = @pnOldCountValue"
		End
	End

	If @pbIsAmountValueInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"VALUEANSWER = @pnAmountValue"
		Set @sComma = ","
		
		If @pbIsBypassConcurrencyChecking = 0
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"VALUEANSWER = @pnOldAmountValue"
		End
	End

	If @pbIsTextValueInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CHECKLISTTEXT = @ptTextValue"
		Set @sComma = ","
		
		If @pbIsBypassConcurrencyChecking = 0
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"dbo.fn_IsNtextEqual(CHECKLISTTEXT, @ptOldTextValue) = 1"
		End
	End

	If @pbIsStaffNameKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EMPLOYEENO = @pnStaffNameKey"
		Set @sComma = ","
		
		If @pbIsBypassConcurrencyChecking = 0
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"EMPLOYEENO = @pnOldStaffNameKey"
		End
	End

	If @pbIsIsProcessedInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PROCESSEDFLAG = @pbIsProcessed"
		Set @sComma = ","
		
		If @pbIsBypassConcurrencyChecking = 0
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PROCESSEDFLAG = @pbOldIsProcessed"
		End
	End

	If @pbIsProductCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PRODUCTCODE = @pnProductCode"
		Set @sComma = ","
		
		If @pbIsBypassConcurrencyChecking = 0
		Begin
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PRODUCTCODE = @pnOldProductCode"
		End
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnCaseKey		int,
			@pnQuestionKey		smallint,
			@pnChecklistTypeKey		smallint,
			@pnChecklistCriteriaKey		int,
			@pnListSelectionKey		int,
			@pbYesNoAnswer		bit,
			@pnCountValue		int,
			@pnAmountValue		decimal(11,2),
			@ptTextValue		ntext,
			@pnStaffNameKey		int,
			@pbIsProcessed		bit,
			@pnProductCode		int,
			@pnOldListSelectionKey		int,
			@pbOldYesNoAnswer		bit,
			@pnOldCountValue		int,
			@pnOldAmountValue		decimal(11,2),
			@ptOldTextValue		ntext,
			@pnOldStaffNameKey		int,
			@pbOldIsProcessed		bit,
			@pnOldProductCode		int',
			@pnCaseKey	 = @pnCaseKey,
			@pnQuestionKey	 = @pnQuestionKey,
			@pnChecklistTypeKey	 = @pnChecklistTypeKey,
			@pnChecklistCriteriaKey	 = @pnChecklistCriteriaKey,
			@pnListSelectionKey	 = @pnListSelectionKey,
			@pbYesNoAnswer	 = @pbYesNoAnswer,
			@pnCountValue	 = @pnCountValue,
			@pnAmountValue	 = @pnAmountValue,
			@ptTextValue	 = @ptTextValue,
			@pnStaffNameKey	 = @pnStaffNameKey,
			@pbIsProcessed	 = @pbIsProcessed,
			@pnProductCode	 = @pnProductCode,
			@pnOldListSelectionKey	 = @pnOldListSelectionKey,
			@pbOldYesNoAnswer	 = @pbOldYesNoAnswer,
			@pnOldCountValue	 = @pnOldCountValue,
			@pnOldAmountValue	 = @pnOldAmountValue,
			@ptOldTextValue	 = @ptOldTextValue,
			@pnOldStaffNameKey	 = @pnOldStaffNameKey,
			@pbOldIsProcessed	 = @pbOldIsProcessed,
			@pnOldProductCode	 = @pnOldProductCode


End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateChecklistData to public
GO