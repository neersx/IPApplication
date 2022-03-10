-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListInstructionDefinition
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListInstructionDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListInstructionDefinition.'
	Drop procedure [dbo].[ipw_ListInstructionDefinition]
	Print '**** Creating Stored Procedure dbo.ipw_ListInstructionDefinition...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_ListInstructionDefinition
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListInstructionDefinition
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Instruction Definitions.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 02 Apr 2008  AT	RFC6369	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
		Select DEFINITIONID as InstructionDefinitionKey, 
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONDEFINITION','INSTRUCTIONNAME',null,'D',@sLookupCulture,@pbCalledFromCentura)
			+ " as InstructionDefinitionName, 
		AVAILABILITYFLAGS as AvailabilityFlags FROM INSTRUCTIONDEFINITION D
		order by 2"

	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListInstructionDefinition to public
GO
