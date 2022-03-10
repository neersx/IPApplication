-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pi_InsertInstructionResponse									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pi_InsertInstructionResponse]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pi_InsertInstructionResponse.'
	Drop procedure [dbo].[pi_InsertInstructionResponse]
End
Print '**** Creating Stored Procedure dbo.pi_InsertInstructionResponse...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.pi_InsertInstructionResponse
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDefinitionKey		int,		-- Mandatory.
	@pnSequenceNo			tinyint,	-- Mandatory
	@psResponseLabel		nvarchar(30)	= null,
	@pnFireEventKey			int		= null,
	@psResponseExplanation		nvarchar(100)	= null,
	@pnDisplayEventKey		int		= null,
	@pnHideEventKey			int		= null,
	@psNotesPrompt			nvarchar(254)	= null,
	@pbIsFireEventKeyInUse		bit	 	= 1,
	@pbIsResponseExplanationInUse	bit	 	= 1,
	@pbIsDisplayEventKeyInUse	bit	 	= 1,
	@pbIsHideEventKeyInUse		bit	 	= 1,
	@pbIsNotesPromptInUse		bit	 	= 1,
	@IsDebugMode			bit		= 0
)
as
-- PROCEDURE:	pi_InsertInstructionResponse
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert InstructionResponse.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 01 Dec 2006	AU	RFC4634	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sSQLString2 	nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString	nvarchar(4000)
Declare @sComma		nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into INSTRUCTIONRESPONSE
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
						DEFINITIONID,SEQUENCENO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
						@pnDefinitionKey,@pnSequenceNo
			"

	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LABEL"
	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psResponseLabel"
	Set @sComma = ","

	If @pbIsFireEventKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FIREEVENTNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnFireEventKey"
		Set @sComma = ","
	End

	If @pbIsResponseExplanationInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXPLANATION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psResponseExplanation"
		Set @sComma = ","
	End

	If @pbIsDisplayEventKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DISPLAYEVENTNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDisplayEventKey"
		Set @sComma = ","
	End

	If @pbIsHideEventKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"HIDEEVENTNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnHideEventKey"
		Set @sComma = ","
	End

	If @pbIsNotesPromptInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NOTESPROMPT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psNotesPrompt"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	If @IsDebugMode = 1
	Begin
		print @sSQLString
	End
	Else
	Begin
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnDefinitionKey	int,
			@pnSequenceNo		tinyint,
			@psResponseLabel	nvarchar(30),
			@pnFireEventKey		int,
			@psResponseExplanation	nvarchar(100),
			@pnDisplayEventKey	int,
			@pnHideEventKey		int,
			@psNotesPrompt		nvarchar(254)',
			@pnDefinitionKey	= @pnDefinitionKey,
			@pnSequenceNo	 	= @pnSequenceNo,
			@psResponseLabel	= @psResponseLabel,
			@pnFireEventKey	 	= @pnFireEventKey,
			@psResponseExplanation	= @psResponseExplanation,
			@pnDisplayEventKey	= @pnDisplayEventKey,
			@pnHideEventKey	 	= @pnHideEventKey,
			@psNotesPrompt	 	= @psNotesPrompt
	End
End

Return @nErrorCode
GO

Grant execute on dbo.pi_InsertInstructionResponse to public
GO