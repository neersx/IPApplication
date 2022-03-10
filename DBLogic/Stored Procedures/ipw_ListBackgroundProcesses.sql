-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListBackgroundProcesses
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListBackgroundProcesses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListBackgroundProcesses.'
	Drop procedure [dbo].[ipw_ListBackgroundProcesses]
End
Print '**** Creating Stored Procedure dbo.ipw_ListBackgroundProcesses...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListBackgroundProcesses
(	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListBackgroundProcesses
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the list of background processes whose status is either
--		completed or error for the logged in user.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Feb 2009	MS		RFC5703		1	Procedure created
-- 28 Feb 2013  DV		RFC7398		2	Return messages for STATUS = 4(Information)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "Select PROCESSID as ProcessKey, 
				PROCESSTYPE as ProcessType, 
				STATUS as Status, 
				STATUSDATE as StatusDate, 
				STATUSINFO as StatusInfo
			From BACKGROUNDPROCESS
			Where IDENTITYID = @pnUserIdentityId
			AND STATUS in (2,3,4)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnUserIdentityId	int',
			@pnUserIdentityId = @pnUserIdentityId
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListBackgroundProcesses to public
GO
