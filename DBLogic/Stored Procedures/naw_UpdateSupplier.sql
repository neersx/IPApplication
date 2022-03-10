-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateSupplier
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateSupplier]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateSupplier.'
	Drop procedure [dbo].[naw_UpdateSupplier]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateSupplier...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateSupplier
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@pnSupplierTypeKey		int             = null, 
	@pdLogDateTimeStamp		datetime        = null
)
as
-- PROCEDURE:	naw_UpdateSupplier
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Supplier Details

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 May 2011	MS	RFC7998	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode			int
Declare @sSQLString 			nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "Update CREDITOR
			set 	SUPPLIERTYPE = @pnSupplierTypeKey				
			where   NAMENO		 = @pnNameKey 
				and ((LOGDATETIMESTAMP = @pdLogDateTimeStamp) or
                                     (@pdLogDateTimeStamp is null and LOGDATETIMESTAMP is null))"				

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnNameKey			int,
			  @pnSupplierTypeKey		int,			
			  @pdLogDateTimeStamp		datetime',
			  @pnNameKey	 		= @pnNameKey,
			  @pnSupplierTypeKey		= @pnSupplierTypeKey,
			  @pdLogDateTimeStamp           = @pdLogDateTimeStamp		
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateSupplier to public
GO
