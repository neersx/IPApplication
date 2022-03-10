-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pi_UpdateInstructionDefinition									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pi_UpdateInstructionDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pi_UpdateInstructionDefinition.'
	Drop procedure [dbo].[pi_UpdateInstructionDefinition]
End
Print '**** Creating Stored Procedure dbo.pi_UpdateInstructionDefinition...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.pi_UpdateInstructionDefinition
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnDefinitionKey			int,		-- Mandatory
	@psInstructionName			nvarchar(50)	= null,
	@pbIsForMultipleCases			bit		= null,
	@pbIsForSingleCase			bit		= null,
	@pbIsAgainstDueEvent			bit		= null,
	@psInstructionExplanation		nvarchar(100)	= null,
	@psActionKey				nvarchar(2)	= null,
	@pbUseMaxCycle				bit		= null,
	@pnDueEventKey				int		= null,
	@pnPrerequisiteEventKey			int		= null,
	@psInstructionNameTypeKey		nvarchar(3)	= null,
	@pnChargeTypeKey			int		= null,
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
-- PROCEDURE:	pi_UpdateInstructionDefinition
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update InstructionDefinition if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 29 Nov 2006	AU	RFC4634	1	Procedure created

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

Declare @nUsedAsFlag		int
Declare @nUsedBit		int

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

Set @nUsedAsFlag = 0
Set @nUsedBit = 0

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update INSTRUCTIONDEFINITION
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		DEFINITIONID = @pnDefinitionKey"

	If @pbIsInstructionNameInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INSTRUCTIONNAME = @psInstructionName"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"INSTRUCTIONNAME = @psOldInstructionName"
		Set @sComma = ","
	End

	-- assumption, if xxxInUse = 1, then we assume xxx flag always there, and use isnull(xxx, 0)
	-- @nUsedBit defines the bits that are used for @nUsedAsFlag
	-- @nUsedAsFlag is an aggregation of all the flags that are used in the update.
	If (@pbIsIsForMultipleCasesInUse = 1 or @pbIsIsForSingleCaseInUse = 1 or @pbIsIsAgainstDueEventInUse = 1)
	Begin
		If @pbIsIsForMultipleCasesInUse = 1
		Begin
			Set @nUsedBit = @nUsedBit | 1
			Set @nUsedAsFlag = @nUsedAsFlag | isnull(@pbIsForMultipleCases, 0) * 1
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"isnull(AVAILABILITYFLAGS, 0) & 1 = isnull(@pbOldIsForMultipleCases, 0) * 1"
		End
	
		If @pbIsIsForSingleCaseInUse = 1
		Begin
			Set @nUsedBit = @nUsedBit | 2
			Set @nUsedAsFlag = @nUsedAsFlag | isnull(@pbIsForSingleCase, 0) * 2
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"isnull(AVAILABILITYFLAGS, 0) & 2 = isnull(@pbOldIsForSingleCase, 0) * 2"
		End
	
		If @pbIsIsAgainstDueEventInUse = 1
		Begin
			Set @nUsedBit = @nUsedBit | 4
			Set @nUsedAsFlag = @nUsedAsFlag | isnull(@pbIsAgainstDueEvent, 0) * 4
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"isnull(AVAILABILITYFLAGS, 0) & 4 = isnull(@pbOldIsAgainstDueEvent, 0) * 4"
		End

		-- (USEDASFLAG & ~@nUsedBit) will reset the bits that are used in the update
		-- (@nUsedBit & @pnUsedAsFlag) will set the bits that are used in the update, and skip bits that are not used in update
		
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"AVAILABILITYFLAGS = (isnull(AVAILABILITYFLAGS, 0) & ~@nUsedBit) | (@nUsedBit & @pnUsedAsFlag)"
		Set @sComma = ","
	End

	If @pbIsInstructionExplanationInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EXPLANATION = @psInstructionExplanation"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"EXPLANATION = @psOldInstructionExplanation"
		Set @sComma = ","
	End

	If @pbIsActionKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ACTION = @psActionKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ACTION = @psOldActionKey"
		Set @sComma = ","
	End

	If @pbIsUseMaxCycleInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"USEMAXCYCLE = @pbUseMaxCycle"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"USEMAXCYCLE = @pbOldUseMaxCycle"
		Set @sComma = ","
	End

	If @pbIsDueEventKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DUEEVENTNO = @pnDueEventKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"DUEEVENTNO = @pnOldDueEventKey"
		Set @sComma = ","
	End

	If @pbIsPrerequisiteEventKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PREREQUISITEEVENTNO = @pnPrerequisiteEventKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PREREQUISITEEVENTNO = @pnOldPrerequisiteEventKey"
		Set @sComma = ","
	End

	If @pbIsInstructionNameTypeKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"INSTRUCTNAMETYPE = @psInstructionNameTypeKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"INSTRUCTNAMETYPE = @psOldInstructionNameTypeKey"
		Set @sComma = ","
	End

	If @pbIsChargeTypeKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CHARGETYPENO = @pnChargeTypeKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CHARGETYPENO = @pnOldChargeTypeKey"
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
			@psInstructionName		nvarchar(50),
			@pbIsForMultipleCases		bit,
			@pbIsForSingleCase		bit,
			@pbIsAgainstDueEvent		bit,
			@pnUsedAsFlag 			int,
			@nUsedBit			int,
			@psInstructionExplanation	nvarchar(100),
			@psActionKey			nvarchar(2),
			@pbUseMaxCycle			bit,
			@pnDueEventKey			int,
			@pnPrerequisiteEventKey		int,
			@psInstructionNameTypeKey	nvarchar(3),
			@pnChargeTypeKey		int,
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
			@pnDefinitionKey		= @pnDefinitionKey,
			@psInstructionName		= @psInstructionName,
			@pbIsForMultipleCases		= @pbIsForMultipleCases,
			@pbIsForSingleCase		= @pbIsForSingleCase,
			@pbIsAgainstDueEvent		= @pbIsAgainstDueEvent,
			@pnUsedAsFlag			= @nUsedAsFlag,
			@nUsedBit			= @nUsedBit,
			@psInstructionExplanation	= @psInstructionExplanation,
			@psActionKey	 		= @psActionKey,
			@pbUseMaxCycle	 		= @pbUseMaxCycle,
			@pnDueEventKey	 		= @pnDueEventKey,
			@pnPrerequisiteEventKey	 	= @pnPrerequisiteEventKey,
			@psInstructionNameTypeKey	= @psInstructionNameTypeKey,
			@pnChargeTypeKey	 	= @pnChargeTypeKey,
			@psOldInstructionName	 	= @psOldInstructionName,
			@pbOldIsForMultipleCases 	= @pbOldIsForMultipleCases,
			@pbOldIsForSingleCase	 	= @pbOldIsForSingleCase,
			@pbOldIsAgainstDueEvent	 	= @pbOldIsAgainstDueEvent,
			@psOldInstructionExplanation	= @psOldInstructionExplanation,
			@psOldActionKey	 		= @psOldActionKey,
			@pbOldUseMaxCycle		= @pbOldUseMaxCycle,
			@pnOldDueEventKey	 	= @pnOldDueEventKey,
			@pnOldPrerequisiteEventKey	= @pnOldPrerequisiteEventKey,
			@psOldInstructionNameTypeKey	= @psOldInstructionNameTypeKey,
			@pnOldChargeTypeKey	 	= @pnOldChargeTypeKey
	End

End

Return @nErrorCode
GO

Grant execute on dbo.pi_UpdateInstructionDefinition to public
GO