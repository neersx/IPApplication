-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetFamilyHasDependency
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetFamilyHasDependency]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetFamilyHasDependency.'
	Drop procedure [dbo].[csw_GetFamilyHasDependency]
End
Print '**** Creating Stored Procedure dbo.csw_GetFamilyHasDependency...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetFamilyHasDependency
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psFamilyKey		nvarchar(40)
)
as
-- PROCEDURE:	csw_GetFamilyHasDependency
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Validates that the question has dependency

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 FEB 2011	KR		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables 
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	If exists (Select 1 from CASES where FAMILY = @psFamilyKey)
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

Grant execute on dbo.csw_GetFamilyHasDependency to public
GO
