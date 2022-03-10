-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_DeleteNameInstructions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_DeleteNameInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_DeleteNameInstructions.'
	Drop procedure [dbo].[na_DeleteNameInstructions]
	print '**** Creating Stored Procedure dbo.na_DeleteNameInstructions...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE procedure dbo.na_DeleteNameInstructions
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameNo			int,		-- Mandatory
	@pnInstructionCode		smallint	= null
)

-- PROCEDURE :	na_DeleteNameInstructions
-- VERSION :	3
-- DESCRIPTION:	Deletes a row to NAMEINSTRUCTIONS
-- CALLED BY :	na_UpdateName

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 18/07/2002	JB	Procedure created


AS
Begin

	Delete
		From [NAMEINSTRUCTIONS] 
		Where 	[NAMENO] = @pnNameNo
		and 	[INSTRUCTIONCODE] = case @pnInstructionCode
			when null then [INSTRUCTIONCODE] 
			else @pnInstructionCode 
			end

	return @@ERROR

End
go

grant exec on dbo.na_DeleteNameInstructions to public
go
