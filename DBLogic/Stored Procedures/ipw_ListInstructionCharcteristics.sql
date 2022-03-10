-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListInstructionCharcteristics
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListInstructionCharcteristics]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure dbo.ipw_ListInstructionCharcteristics.'
	drop procedure [dbo].[ipw_ListInstructionCharcteristics]
	print '**** Creating Stored Procedure dbo.ipw_ListInstructionCharcteristics...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListInstructionCharcteristics
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListInstructionCharcteristics
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate a drop down list of instruction characteristics.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 04 Jan 2006	TM	RFC2483	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set 	@sLookupCulture  = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  FLAGNUMBER 	as 'CharacteristicKey', 	
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONLABEL','FLAGLITERAL',null,'IL',@sLookupCulture,@pbCalledFromCentura)+"
				as 'CharacteristicDescription'
	from INSTRUCTIONLABEL IL
	order by 'CharacteristicDescription'"

	
	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListInstructionCharcteristics to public
GO
