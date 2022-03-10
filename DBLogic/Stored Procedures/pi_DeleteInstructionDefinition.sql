-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pi_DeleteInstructionDefinition									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pi_DeleteInstructionDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pi_DeleteInstructionDefinition.'
	Drop procedure [dbo].[pi_DeleteInstructionDefinition]
End
Print '**** Creating Stored Procedure dbo.pi_DeleteInstructionDefinition...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.pi_DeleteInstructionDefinition
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnDefinitionKey			int,		-- Mandatory
	@psOldInstructionName			nvarchar(50)	= null,
	@pbOldIsForMultipleCases		bit		= null,
	@pbOldIsForSingleCase			bit		= null,
	@pbOldIsAgainstDueEvent			bit		= null,
	@psOldInstructionExplanation		nvarchar(100)	= null,
	@psOldActionKey				nvarchar(2)	= null,
	@pbOldUseMaxCycle			bit		= null,
	@pnOldDueEventKey			int		= null,
	@pnOldPrerequisiteEventKey		int		= null,
	@psOldInstructionNameTypeKey		nvarchar(3)	= null,
	@pnOldChargeTypeKey			int		= null,
	@pbIsInstructionNameInUse		bit		= 1,
	@pbIsIsForMultipleCasesInUse		bit		= 1,
	@pbIsIsForSingleCaseInUse		bit		= 1,
	@pbIsIsAgainstDueEventInUse		bit		= 1,
	@pbIsInstructionExplanationInUse	bit		= 1,
	@pbIsActionKeyInUse			bit		= 1,
	@pbIsUseMaxCycleInUse			bit		= 1,
	@pbIsDueEventKeyInUse			bit		= 1,
	@pbIsPrerequisiteEventKeyInUse		bit		= 1,
	@pbIsInstructionNameTypeKeyInUse	bit		= 1,
	@pbIsChargeTypeKeyInUse			bit		= 1,
	@pbIsDebugMode				bit		= 0
)
as
-- PROCEDURE:	pi_DeleteInstructionDefinition
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete InstructionDefinition if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 29 Nov 2006	AU	RFC4634	1	Procedure created
-- 20 Dec 2006	AU	RFC4634	2	Removed redundant logic

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
	Set @sDeleteString = "Delete from INSTRUCTIONDEFINITION
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		DEFINITIONID = @pnDefinitionKey
		"

	If @pbIsInstructionNameInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"INSTRUCTIONNAME = @psOldInstructionName"
	End

	If @pbIsIsForMultipleCasesInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"AVAILABILITYFLAGS & 1 = isnull(@pbOldIsForMultipleCases, 0) * 1"
	End
	
	If @pbIsIsForSingleCaseInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"AVAILABILITYFLAGS & 2 = isnull(@pbOldIsForSingleCase, 0) * 2"
	End
	
	If @pbIsIsAgainstDueEventInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"AVAILABILITYFLAGS & 4 = isnull(@pbOldIsAgainstDueEvent, 0) * 4"
	End
		
	If @pbIsInstructionExplanationInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"EXPLANATION = @psOldInstructionExplanation"
	End

	If @pbIsActionKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ACTION = @psOldActionKey"
	End

	If @pbIsUseMaxCycleInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"USEMAXCYCLE = @pbOldUseMaxCycle"
	End

	If @pbIsDueEventKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"DUEEVENTNO = @pnOldDueEventKey"
	End

	If @pbIsPrerequisiteEventKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PREREQUISITEEVENTNO = @pnOldPrerequisiteEventKey"
	End

	If @pbIsInstructionNameTypeKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"INSTRUCTNAMETYPE = @psOldInstructionNameTypeKey"
	End

	If @pbIsChargeTypeKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CHARGETYPENO = @pnOldChargeTypeKey"
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
			@psOldInstructionName		nvarchar(50),
			@pbOldIsForMultipleCases	bit,
			@pbOldIsForSingleCase		bit,
			@pbOldIsAgainstDueEvent		bit,
			@psOldInstructionExplanation	nvarchar(100),
			@psOldActionKey			nvarchar(2),
			@pbOldUseMaxCycle		bit,
			@pnOldDueEventKey		int,
			@pnOldPrerequisiteEventKey	int,
			@psOldInstructionNameTypeKey	nvarchar(3),
			@pnOldChargeTypeKey		int',
			@pnDefinitionKey	 	= @pnDefinitionKey,
			@psOldInstructionName	 	= @psOldInstructionName,
			@pbOldIsForMultipleCases	= @pbOldIsForMultipleCases,
			@pbOldIsForSingleCase		= @pbOldIsForSingleCase,
			@pbOldIsAgainstDueEvent		= @pbOldIsAgainstDueEvent,
			@psOldInstructionExplanation	= @psOldInstructionExplanation,
			@psOldActionKey	 		= @psOldActionKey,
			@pbOldUseMaxCycle	 	= @pbOldUseMaxCycle,
			@pnOldDueEventKey	 	= @pnOldDueEventKey,
			@pnOldPrerequisiteEventKey	= @pnOldPrerequisiteEventKey,
			@psOldInstructionNameTypeKey	= @psOldInstructionNameTypeKey,
			@pnOldChargeTypeKey	 	= @pnOldChargeTypeKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.pi_DeleteInstructionDefinition to public
GO