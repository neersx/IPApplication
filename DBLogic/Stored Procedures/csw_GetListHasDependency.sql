-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetListHasDependency 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetListHasDependency]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetListHasDependency.'
	Drop procedure [dbo].[csw_GetListHasDependency]
End
Print '**** Creating Stored Procedure dbo.csw_GetListHasDependency...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetListHasDependency
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnListKey		int
)
as
-- PROCEDURE:	csw_GetListHasDependency
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Validates that the question has dependency

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 MAR 2011	KR		RFC6563	1		Procedure created
-- 27 APR 2011	KR		RFC100511	2	dependency to ignore prime case

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables 
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	If exists (Select 1 from CASELISTMEMBER where CASELISTNO = @pnListKey and PRIMECASE = 0)
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

Grant execute on dbo.csw_GetListHasDependency to public
GO
