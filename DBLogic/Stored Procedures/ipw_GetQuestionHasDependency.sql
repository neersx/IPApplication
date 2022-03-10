-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetQuestionHasDependency
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetQuestionHasDependency]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetQuestionHasDependency.'
	Drop procedure [dbo].[ipw_GetQuestionHasDependency]
End
Print '**** Creating Stored Procedure dbo.ipw_GetQuestionHasDependency...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetQuestionHasDependency
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnQuestionKey		int
)
as
-- PROCEDURE:	ipw_GetQuestionHasDependency
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Validates that the question has dependency

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 JAN 2011	SF		RFC9193	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	If exists (Select 1 from CHECKLISTITEM where QUESTIONNO = @pnQuestionKey)
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

Grant execute on dbo.ipw_GetQuestionHasDependency to public
GO
