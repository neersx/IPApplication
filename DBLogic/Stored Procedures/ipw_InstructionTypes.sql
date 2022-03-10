-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InstructionTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InstructionTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InstructionTypes.'
	Drop procedure [dbo].[ipw_InstructionTypes]
End
Print '**** Creating Stored Procedure dbo.ipw_InstructionTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InstructionTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_InstructionTypes
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates data in Program PickList for Case Windows

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Jun 2010	JC	RFC6229	1	Return list of correspondence types

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString		nvarchar(500)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set	@nErrorCode      = 0
Set @pnRowCount	 = 0

-- Fetch Case Programs
If @nErrorCode = 0 
Begin	
	Set @sSQLString = "
	Select 
		I.INSTRUCTIONTYPE		as 'InstructionTypeKey',
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'InstructionTypeDescription'
	from 	INSTRUCTIONTYPE I
	order by 2 "

	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InstructionTypes to public
GO

