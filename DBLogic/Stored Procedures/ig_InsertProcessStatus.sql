-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_InsertProcessStatus
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_InsertProcessStatus]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_InsertProcessStatus.'
	Drop procedure [dbo].[ig_InsertProcessStatus]
End
Print '**** Creating Stored Procedure dbo.ig_InsertProcessStatus...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ig_InsertProcessStatus
(
	@pnIntegrationItemID	int,		-- Mandatory
	@psSystem		int,		-- Mandatory
	@psStatusCode		int,		-- Mandatory
	@psStatusDescription	nvarchar(254)	-- Mandatory
)
as
-- PROCEDURE:	ig_InsertProcessStatus
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts integration process statuses in the Integration Status table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Nov 2005	TM	11022	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into INTEGRATIONSTATUS
		(INTEGRATIONID, 
		 STATUSDATE,
		 INTSYSTEM,
		 STATUSCODE,
		 STATUSDESCRIPTION)
	values	(@pnIntegrationItemID,
		 getdate(),
		 @psSystem, 		
		 @psStatusCode,
		 @psStatusDescription)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIntegrationItemID	int,
					  @psSystem		int,
					  @psStatusCode		int,					 
					  @psStatusDescription	nvarchar(254)',
					  @pnIntegrationItemID	= @pnIntegrationItemID,
					  @psSystem		= @psSystem,
					  @psStatusCode		= @psStatusCode,					 
					  @psStatusDescription	= @psStatusDescription	

End

Return @nErrorCode
GO

Grant execute on dbo.ig_InsertProcessStatus to public
GO
