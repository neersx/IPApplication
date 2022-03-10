-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pi_UpdateInstructionResponse									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pi_UpdateInstructionResponse]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pi_UpdateInstructionResponse.'
	Drop procedure [dbo].[pi_UpdateInstructionResponse]
End
Print '**** Creating Stored Procedure dbo.pi_UpdateInstructionResponse...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.pi_UpdateInstructionResponse
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDefinitionKey		int,		-- Mandatory
	@pnSequenceNo			tinyint,	-- Mandatory
	@psResponseLabel		nvarchar(30)	= null,
	@pnFireEventKey			int		= null,
	@psResponseExplanation		nvarchar(100)	= null,
	@pnDisplayEventKey		int		= null,
	@pnHideEventKey			int		= null,
	@psNotesPrompt			nvarchar(254)	= null,
	@pnOldSequenceNo		tinyint,	-- Mandatory
	@psOldResponseLabel		nvarchar(30)	= null,
	@pnOldFireEventKey		int		= null,
	@psOldResponseExplanation	nvarchar(100)	= null,
	@pnOldDisplayEventKey		int		= null,
	@pnOldHideEventKey		int		= null,
	@psOldNotesPrompt		nvarchar(254)	= null,
	@pbIsSequenceNoInUse		bit		= 1,
	@pbIsResponseLabelInUse		bit	 	= 1,
	@pbIsFireEventKeyInUse		bit	 	= 1,
	@pbIsResponseExplanationInUse	bit	 	= 1,
	@pbIsDisplayEventKeyInUse	bit	 	= 1,
	@pbIsHideEventKeyInUse		bit	 	= 1,
	@pbIsNotesPromptInUse		bit	 	= 1,
	@pbIsDebugMode			bit	 	= 0
)
as
-- PROCEDURE:	pi_UpdateInstructionResponse
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update InstructionResponse if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 01 Dec 2006	AU	RFC4634	1	Procedure created
-- 20 Dec 2006	AU	RFC4634	2	Removed duplicate SEQUENCENO condition in where
--					clause.

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

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update INSTRUCTIONRESPONSE
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		DEFINITIONID = @pnDefinitionKey and
		SEQUENCENO = @pnOldSequenceNo
	"

	If @pbIsSequenceNoInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SEQUENCENO = @pnSequenceNo"
		Set @sComma = ","
	End

	If @pbIsResponseLabelInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LABEL = @psResponseLabel"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"LABEL = @psOldResponseLabel"
		Set @sComma = ","
	End

	If @pbIsFireEventKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FIREEVENTNO = @pnFireEventKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FIREEVENTNO = @pnOldFireEventKey"
		Set @sComma = ","
	End

	If @pbIsResponseExplanationInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EXPLANATION = @psResponseExplanation"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"EXPLANATION = @psOldResponseExplanation"
		Set @sComma = ","
	End

	If @pbIsDisplayEventKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DISPLAYEVENTNO = @pnDisplayEventKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"DISPLAYEVENTNO = @pnOldDisplayEventKey"
		Set @sComma = ","
	End

	If @pbIsHideEventKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"HIDEEVENTNO = @pnHideEventKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"HIDEEVENTNO = @pnOldHideEventKey"
		Set @sComma = ","
	End

	If @pbIsNotesPromptInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NOTESPROMPT = @psNotesPrompt"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NOTESPROMPT = @psOldNotesPrompt"
		Set @sComma = ","
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	If @pbIsDebugMode = 1
	Begin
		print @sSQLString
	End
	Else
	Begin
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnDefinitionKey		int,
			@pnSequenceNo			tinyint,
			@psResponseLabel		nvarchar(30),
			@pnFireEventKey			int,
			@psResponseExplanation		nvarchar(100),
			@pnDisplayEventKey		int,
			@pnHideEventKey			int,
			@psNotesPrompt			nvarchar(254),
			@pnOldSequenceNo		tinyint,
			@psOldResponseLabel		nvarchar(30),
			@pnOldFireEventKey		int,
			@psOldResponseExplanation	nvarchar(100),
			@pnOldDisplayEventKey		int,
			@pnOldHideEventKey		int,
			@psOldNotesPrompt		nvarchar(254)',
			@pnDefinitionKey	 	= @pnDefinitionKey,
			@pnSequenceNo	 		= @pnSequenceNo,
			@psResponseLabel	 	= @psResponseLabel,
			@pnFireEventKey	 		= @pnFireEventKey,
			@psResponseExplanation	 	= @psResponseExplanation,
			@pnDisplayEventKey	 	= @pnDisplayEventKey,
			@pnHideEventKey	 		= @pnHideEventKey,
			@psNotesPrompt	 		= @psNotesPrompt,
			@pnOldSequenceNo		= @pnOldSequenceNo,
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

Grant execute on dbo.pi_UpdateInstructionResponse to public
GO