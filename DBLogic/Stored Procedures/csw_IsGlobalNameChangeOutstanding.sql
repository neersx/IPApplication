-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_IsGlobalNameChangeOutstanding
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_IsGlobalNameChangeOutstanding]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_IsGlobalNameChangeOutstanding.'
	Drop procedure [dbo].[csw_IsGlobalNameChangeOutstanding]
End
Print '**** Creating Stored Procedure dbo.csw_IsGlobalNameChangeOutstanding...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[csw_IsGlobalNameChangeOutstanding]
(	
	@pnUserIdentityId	int	-- Mandatory	
)
as
-- PROCEDURE:	csw_IsGlobalNameChangeOutstanding
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return a result set containing list of outstanding global name change requests 
--		for the currently logged in user. Called by WorkBenches.

-- MODIFICATIONS :
-- Date		Who  Change	Version	  Change
-- -----------	---- -------	--------  ------------------------------------------------------ 
-- 23 OCT 2008	MS   RFC5698	1	  Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode=0
Begin	
	-------------------------------------
	-- List the pending Global Name Change Requests 
	-------------------------------------
	Set @sSQLString = "Select REQUESTNO as RequestId,
				ONHOLDFLAG as Status
			From CASENAMEREQUEST as Requests WITH(NOLOCK)
			Where IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnUserIdentityId	int',				  
			@pnUserIdentityId = @pnUserIdentityId	

End

Return @nErrorCode
GO

Grant execute on dbo.csw_IsGlobalNameChangeOutstanding to public
GO


