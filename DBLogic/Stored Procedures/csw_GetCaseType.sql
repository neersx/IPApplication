-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetCaseType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetCaseType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetCaseType.'
	Drop procedure [dbo].[csw_GetCaseType]
End
Print '**** Creating Stored Procedure dbo.csw_GetCaseType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_GetCaseType
(
	@psCaseTypeKey		nvarchar(2)		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey			int
)
as
-- PROCEDURE:	csw_GetCaseType
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the CaseTypeKey of the case

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Sep 2008	SF		7109	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select CASETYPE as CaseTypeKey
	from CASES 
	where CASEID = @pnCaseKey	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetCaseType to public
GO
