-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pi_InsertInstructionDefinition									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[pi_InsertInstructionDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.pi_InsertInstructionDefinition.'
	Drop procedure [dbo].[pi_InsertInstructionDefinition]
End
Print '**** Creating Stored Procedure dbo.pi_InsertInstructionDefinition...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.pi_InsertInstructionDefinition
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnDefinitionKey			int		= null,
	@psInstructionName			nvarchar(50)	= null,
	@pbIsForMultipleCases			bit		= null,
	@pbIsForSingleCase			bit		= null,
	@pbIsAgainstDueEvent			bit		= null,
	@psInstructionExplanation		nvarchar(100) 	= null,
	@psActionKey				nvarchar(2)	= null,
	@pbUseMaxCycle				bit		= null,
	@pnDueEventKey				int		= null,
	@pnPrerequisiteEventKey			int		= null,
	@psInstructionNameTypeKey		nvarchar(3)	= null,
	@pnChargeTypeKey			int		= null,
	@pbIsInstructionExplanationInUse	bit	 	= 1,
	@pbIsActionKeyInUse			bit	 	= 1,
	@pbIsUseMaxCycleInUse			bit	 	= 1,
	@pbIsDueEventKeyInUse			bit	 	= 1,
	@pbIsPrerequisiteEventKeyInUse		bit	 	= 1,
	@pbIsInstructionNameTypeKeyInUse	bit	 	= 1,
	@pbIsChargeTypeKeyInUse			bit	 	= 1
)
as
-- PROCEDURE:	pi_InsertInstructionDefinition
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert InstructionDefinition.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 29 Nov 2006	AU	RFC4634	1	Procedure created
-- 20 Dec 2006	AU	RFC4634	2	Removed unnecessary passed of arguments to exec

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString	nvarchar(4000)
Declare @sComma		nchar(1)

Declare @nAvailabilityFlags int

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @nAvailabilityFlags = isnull(@pbIsForMultipleCases, 0) * 1
		| isnull(@pbIsForSingleCase, 0) * 2
		| isnull(@pbIsAgainstDueEvent, 0)  * 4

	Set @sInsertString = "Insert into INSTRUCTIONDEFINITION
				("

	Set @sInsertString = @sInsertString+CHAR(10)+"INSTRUCTIONNAME,AVAILABILITYFLAGS"
	Set @sValuesString = @sValuesString+CHAR(10)+"@psInstructionName,@nAvailabilityFlags"
	Set @sComma = ","


	If @pbIsInstructionExplanationInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXPLANATION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psInstructionExplanation"
		Set @sComma = ","
	End

	If @pbIsActionKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ACTION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psActionKey"
		Set @sComma = ","
	End

	If @pbIsUseMaxCycleInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"USEMAXCYCLE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbUseMaxCycle"
		Set @sComma = ","
	End

	If @pbIsDueEventKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DUEEVENTNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDueEventKey"
		Set @sComma = ","
	End

	If @pbIsPrerequisiteEventKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PREREQUISITEEVENTNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPrerequisiteEventKey"
		Set @sComma = ","
	End

	If @pbIsInstructionNameTypeKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INSTRUCTNAMETYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psInstructionNameTypeKey"
		Set @sComma = ","
	End

	If @pbIsChargeTypeKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CHARGETYPENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnChargeTypeKey"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString+char(10)+
		"Set @pnDefinitionKey = SCOPE_IDENTITY()"


	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnDefinitionKey		int	output,
			@psInstructionName		nvarchar(50),
			@nAvailabilityFlags		int,
			@psInstructionExplanation	nvarchar(100),
			@psActionKey			nvarchar(2),
			@pbUseMaxCycle			bit,
			@pnDueEventKey			int,
			@pnPrerequisiteEventKey		int,
			@psInstructionNameTypeKey	nvarchar(3),
			@pnChargeTypeKey		int',
			@pnDefinitionKey		= @pnDefinitionKey	output,
			@psInstructionName	 	= @psInstructionName,
			@nAvailabilityFlags		= @nAvailabilityFlags,
			@psInstructionExplanation	= @psInstructionExplanation,
			@psActionKey	 		= @psActionKey,
			@pbUseMaxCycle	 		= @pbUseMaxCycle,
			@pnDueEventKey	 		= @pnDueEventKey,
			@pnPrerequisiteEventKey	 	= @pnPrerequisiteEventKey,
			@psInstructionNameTypeKey	= @psInstructionNameTypeKey,
			@pnChargeTypeKey	 	= @pnChargeTypeKey


Select @pnDefinitionKey as DefinitionKey

End

Return @nErrorCode
GO

Grant execute on dbo.pi_InsertInstructionDefinition to public
GO