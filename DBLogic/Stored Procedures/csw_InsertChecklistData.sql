-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertChecklistData									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertChecklistData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertChecklistData.'
	Drop procedure [dbo].[csw_InsertChecklistData]
End
Print '**** Creating Stored Procedure dbo.csw_InsertChecklistData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertChecklistData
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey					int,	-- Mandatory.
	@pnQuestionKey				smallint,	-- Mandatory.
	@pnChecklistTypeKey			smallint		 = null,
	@pnChecklistCriteriaKey		int		 = null,
	@pnListSelectionKey			int		 = null,
	@pbYesNoAnswer				bit		 = null,
	@pnCountValue				int		 = null,
	@pnAmountValue				decimal(11,2)		 = null,
	@ptTextValue				ntext		 = null,
	@pnStaffNameKey				int		 = null,
	@pbIsProcessed				bit		 = null,
	@pnProductCode				int		 = null,
	@pbIsListSelectionKeyInUse	bit	 = 0,
	@pbIsYesNoAnswerInUse		bit	 = 0,
	@pbIsCountValueInUse		bit	 = 0,
	@pbIsAmountValueInUse		bit	 = 0,
	@pbIsTextValueInUse			bit	 = 0,
	@pbIsStaffNameKeyInUse		bit	 = 0,
	@pbIsIsProcessedInUse		bit	 = 0,
	@pbIsProductCodeInUse		bit	 = 0
)
as
-- PROCEDURE:	csw_InsertChecklistData
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert CaseChecklist.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 27 Nov 2007	SF		RFC5776	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma		nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into CASECHECKLIST
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
						CASEID,QUESTIONNO,CHECKLISTTYPE,CRITERIANO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
						@pnCaseKey,@pnQuestionKey,@pnChecklistTypeKey,@pnChecklistCriteriaKey
			"

	If @pbIsListSelectionKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TABLECODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnListSelectionKey"
		Set @sComma = ","
	End

	If @pbIsYesNoAnswerInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"YESNOANSWER"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbYesNoAnswer"
		Set @sComma = ","
	End

	If @pbIsCountValueInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"COUNTANSWER"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCountValue"
		Set @sComma = ","
	End

	If @pbIsAmountValueInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"VALUEANSWER"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAmountValue"
		Set @sComma = ","
	End

	If @pbIsTextValueInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CHECKLISTTEXT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@ptTextValue"
		Set @sComma = ","
	End

	If @pbIsStaffNameKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EMPLOYEENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnStaffNameKey"
		Set @sComma = ","
	End

	If @pbIsIsProcessedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PROCESSEDFLAG"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbIsProcessed"
		Set @sComma = ","
	End

	If @pbIsProductCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PRODUCTCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnProductCode"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

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
			@pnProductCode		int',
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
			@pnProductCode	 = @pnProductCode

End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertChecklistData to public
GO