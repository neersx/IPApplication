-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_CheckDuplicateCriteriaName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_CheckDuplicateCriteriaName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_CheckDuplicateCriteriaName.'
	Drop procedure [dbo].[ipw_CheckDuplicateCriteriaName]
End
Print '**** Creating Stored Procedure dbo.ipw_CheckDuplicateCriteriaName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_CheckDuplicateCriteriaName]
(
	@pbDuplicateCriteriaNameExists	bit		= 0	output,	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCriteriaNo			int,		-- Mandatory
	@psCriteriaName			nvarchar(254)   -- Mandatory
)
as
-- PROCEDURE:	ipw_CheckDuplicateCriteriaName
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Checks the existence of duplicate criteria name.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 04 Sept 2009	MS	RFC7085	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If exists (select * from NAMECRITERIA C where C.DESCRIPTION = @psCriteriaName and NAMECRITERIANO <> @pnCriteriaNo)
		Set  @pbDuplicateCriteriaNameExists = 1
	Else
		Set @pbDuplicateCriteriaNameExists = 0
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_CheckDuplicateCriteriaName to public
GO