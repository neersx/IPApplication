-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pi_DeleteInstructionResponse									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pi_DeleteInstructionResponse]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pi_DeleteInstructionResponse.'
	Drop procedure [dbo].[pi_DeleteInstructionResponse]
End
Print '**** Creating Stored Procedure dbo.pi_DeleteInstructionResponse...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.pi_DeleteInstructionResponse
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDefinitionKey		int,		-- Mandatory
	@pnSequenceNo			tinyint,	-- Mandatory
	@psOldResponseLabel		nvarchar(30)	= null,
	@pnOldFireEventKey		int		= null,
	@psOldResponseExplanation	nvarchar(100)	= null,
	@pnOldDisplayEventKey		int		= null,
	@pnOldHideEventKey		int		= null,
	@psOldNotesPrompt		nvarchar(254)	= null,
	@pbIsResponseLabelInUse		bit	 	= 1,
	@pbIsFireEventKeyInUse		bit	 	= 1,
	@pbIsResponseExplanationInUse	bit	 	= 1,
	@pbIsDisplayEventKeyInUse	bit	 	= 1,
	@pbIsHideEventKeyInUse		bit	 	= 1,
	@pbIsNotesPromptInUse		bit	 	= 1,
	@pbIsDebugMode			bit		= 0
)
as
-- PROCEDURE:	pi_DeleteInstructionResponse
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete InstructionResponse if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 01 Dec 2006	AU	RFC4634	1	Procedure created

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
	Set @sDeleteString = "Delete from INSTRUCTIONRESPONSE
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		DEFINITIONID = @pnDefinitionKey and 
		SEQUENCENO = @pnSequenceNo
		"

	If @pbIsResponseLabelInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"LABEL = @psOldResponseLabel"
	End

	If @pbIsFireEventKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"FIREEVENTNO = @pnOldFireEventKey"
	End

	If @pbIsResponseExplanationInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"EXPLANATION = @psOldResponseExplanation"
	End

	If @pbIsDisplayEventKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"DISPLAYEVENTNO = @pnOldDisplayEventKey"
	End

	If @pbIsHideEventKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"HIDEEVENTNO = @pnOldHideEventKey"
	End

	If @pbIsNotesPromptInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"NOTESPROMPT = @psOldNotesPrompt"
	End

	If @pbIsDebugMode = 1
	Begin
		print @sDeleteString
	End
	Else
	Begin
	exec @nErrorCode=sp_executesql @sDeleteString,
			N'
			@pnDefinitionKey		int,
			@pnSequenceNo			tinyint,
			@psOldResponseLabel		nvarchar(30),
			@pnOldFireEventKey		int,
			@psOldResponseExplanation	nvarchar(100),
			@pnOldDisplayEventKey		int,
			@pnOldHideEventKey		int,
			@psOldNotesPrompt		nvarchar(254)',
			@pnDefinitionKey	 	= @pnDefinitionKey,
			@pnSequenceNo	 		= @pnSequenceNo,
			@psOldResponseLabel	 	= @psOldResponseLabel,
			@pnOldFireEventKey	 	= @pnOldFireEventKey,
			@psOldResponseExplanation	= @psOldResponseExplanation,
			@pnOldDisplayEventKey	 	= @pnOldDisplayEventKey,
			@pnOldHideEventKey	 	= @pnOldHideEventKey,
			@psOldNotesPrompt	 	= @psOldNotesPrompt
	End
End

Return @nErrorCode
GO

Grant execute on dbo.pi_DeleteInstructionResponse to public
GO