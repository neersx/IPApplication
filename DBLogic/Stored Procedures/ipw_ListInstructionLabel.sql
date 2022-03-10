-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListInstructionLabel
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListInstructionLabel]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListInstructionLabel.'
	Drop procedure [dbo].[ipw_ListInstructionLabel]
	Print '**** Creating Stored Procedure dbo.ipw_ListInstructionLabel...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListInstructionLabel
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListInstructionLabel
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Return InstructionKey,FlagNumber, InstructionDescription from InstructionLabel table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Jan-2011	DV	RFC9387 	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If  @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	I.FLAGNUMBER	as 'FlagKey', 
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONLABEL','FLAGLITERAL',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " 	as 'InstructionDescription',
		I.INSTRUCTIONTYPE	as 'InstructionTypeKey'		
	from INSTRUCTIONLABEL I
	order by InstructionDescription"
	
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListInstructionLabel to public
GO
