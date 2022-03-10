-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteCaseControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteCaseControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteCaseControlCriteria.'
	Drop procedure [dbo].[ipw_DeleteCaseControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteCaseControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteCaseControlCriteria
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCriteriaNo			int	-- Mandatory
)
as
-- PROCEDURE:	ipw_DeleteCaseControlCriteria
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Deletes records from CRITERIA and INHERITS to break the inheritance

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Nov 2008	NG	RFC6921	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 		nvarchar(4000)
Declare @nErrorCode			int
Declare @bHasChildCriteria	bit
Declare @bHasParentCriteria	bit

-- Initialise variables
Set @nErrorCode = 0
Set @bHasChildCriteria = 0
Set @bHasParentCriteria = 0

If @nErrorCode = 0
Begin
If exists (select * from INHERITS where FROMCRITERIA = @pnCriteriaNo)
	Set @bHasChildCriteria = 1
End

If @nErrorCode = 0
Begin
If exists (select * from INHERITS where CRITERIANO = @pnCriteriaNo)
	Set @bHasParentCriteria = 1
End


If @nErrorCode = 0 and @bHasChildCriteria = 1
Begin
	Set @sSQLString = "Delete from INHERITS
					where FROMCRITERIA = @pnCriteriaNo"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCriteriaNo			int',
					@pnCriteriaNo = @pnCriteriaNo
End

If @nErrorCode = 0 and @bHasParentCriteria = 1
Begin
	Set @sSQLString = "Delete from INHERITS
					where CRITERIANO = @pnCriteriaNo"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCriteriaNo			int',
					@pnCriteriaNo = @pnCriteriaNo
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
				Delete from CRITERIA
				where CRITERIANO = @pnCriteriaNo"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCriteriaNo			int',
					@pnCriteriaNo = @pnCriteriaNo

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteCaseControlCriteria to public
GO
