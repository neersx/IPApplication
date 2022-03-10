-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_CheckCriteriaName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_CheckCriteriaName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_CheckCriteriaName.'
	Drop procedure [dbo].[ipw_CheckCriteriaName]
End
Print '**** Creating Stored Procedure dbo.ipw_CheckCriteriaName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_CheckCriteriaName
(
	@pbDuplicateCriteriaNameExists	decimal(1,0)		= 0 output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psCriteriaName			nvarchar(254)  -- Mandatory
)
as
-- PROCEDURE:	ipw_CheckCriteriaName
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Checks the existence of duplicate criteria name.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Dec 2008	NG		RFC6921	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If exists (select * from CRITERIA C where C.DESCRIPTION = @psCriteriaName)
		Set  @pbDuplicateCriteriaNameExists = 1
	Else
		Set @pbDuplicateCriteriaNameExists = 0
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_CheckCriteriaName to public
GO
