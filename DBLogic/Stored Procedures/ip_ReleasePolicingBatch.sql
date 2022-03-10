-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ReleasePolicingBatch
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ReleasePolicingBatch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ReleasePolicingBatch.'
	Drop procedure [dbo].[ip_ReleasePolicingBatch]
End
Print '**** Creating Stored Procedure dbo.ip_ReleasePolicingBatch...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_ReleasePolicingBatch
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,		-- The language in which output is to be expressed.
	@pbCalledFromCentura	bit		= 0,
	@pnPolicingBatchNo 	int		-- Mandatory
)
as
-- PROCEDURE:	ip_ReleasePolicingBatch
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Releases the batch of policing requests so policing server can process it.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Dec 2005	TM	RFC3200	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Update POLICING
	set    ONHOLDFLAG = 0
	where  BATCHNO = @pnPolicingBatchNo"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnPolicingBatchNo	int',
				@pnPolicingBatchNo	= @pnPolicingBatchNo	
End

Return @nErrorCode
GO

Grant execute on dbo.ip_ReleasePolicingBatch to public
GO
