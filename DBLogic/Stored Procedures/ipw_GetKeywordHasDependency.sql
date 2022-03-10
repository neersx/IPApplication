-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetKeywordHasDependency 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetKeywordHasDependency]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetKeywordHasDependency.'
	Drop procedure [dbo].[ipw_GetKeywordHasDependency]
End
Print '**** Creating Stored Procedure dbo.ipw_GetKeywordHasDependency...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetKeywordHasDependency
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnKeywordKey		int
)
as
-- PROCEDURE:	ipw_GetKeywordHasDependency
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Validates that the question has dependency

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 MAR 2011	KR		R8562	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables 
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	If exists (Select 1 from SYNONYMS where KEYWORDNO = @pnKeywordKey)
	begin 
		Select 1 as tinyint
	end
	else
	begin 
		Select 0 as tinyint
	end	
	
	Set @nErrorCode = @@Error
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetKeywordHasDependency to public
GO
