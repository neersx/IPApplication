----------------------------------------------------------------------------------------------
-- Creation of dbo.na_InsertNameInstructions
----------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_InsertNameInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_InsertNameInstructions.'
	Drop procedure [dbo].[na_InsertNameInstructions]
	print '**** Creating Stored Procedure dbo.na_InsertNameInstructions...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE procedure dbo.na_InsertNameInstructions
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameNo			int,		-- Mandatory
	@pnInstructionCode		smallint	= null,
	@pnCaseId			int		= null,
	@pdCoutryCode			nvarchar(3)	= null,
	@psPropertyType			nvarchar(1)	= null,
	@pnRestrictedToName		int		= null
)

-- PROCEDURE :	na_InsertNameInstructions
-- VERSION :	3
-- DESCRIPTION:	Add a row to NAMEINSTRUCTIONS
-- CALLED BY :	na_InsertName, na_UpdateName

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 18/07/2002	JB	Procedure created


AS
Begin
	-- Get the last next sequence no
	Declare @nInternalSequence int
	Select @nInternalSequence = MAX(INTERNALSEQUENCE) + 1
		From [NAMEINSTRUCTIONS]
		Where [NAMENO] = @pnNameNo

	-- There may not be one to add one to!
	If @nInternalSequence is null
		Set @nInternalSequence = 0

	Insert into [NAMEINSTRUCTIONS] 
		(	[NAMENO],
			[INTERNALSEQUENCE],
			[INSTRUCTIONCODE]
		)
	Values
		(	@pnNameNo,
			@nInternalSequence,
			@pnInstructionCode
		)	

	return @@ERROR
End
go

grant exec on dbo.na_InsertNameInstructions to public
go
