-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteSupplier									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteSupplier]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteSupplier.'
	Drop procedure [dbo].[naw_DeleteSupplier]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteSupplier...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_DeleteSupplier
(
	@pnUserIdentityId		        int,		        -- Mandatory
	@psCulture			        nvarchar(10) 	        = null,
	@pbCalledFromCentura		        bit		        = 0,
	@pnNameKey			        int,		        -- Mandatory.
	@pdLogDateTimeStamp		        datetime                = null             
        
)
as
-- PROCEDURE:	naw_DeleteSupplier
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Supplier.

-- MODIFICATIONS :
-- Date		Who   Change   Version   Description
-- ---------	----- -------  --------  --------------------------------------
-- 12 May 2011	MS    RFC7998  1	 Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "DELETE from CREDITOR
                          WHERE NAMENO = @pnNameKey
                          and ((LOGDATETIMESTAMP = @pdLogDateTimeStamp) or
                                     (@pdLogDateTimeStamp is null and LOGDATETIMESTAMP is null))"	

	exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnNameKey		        int,				
                                @pdLogDateTimeStamp             datetime',
				@pnNameKey		        = @pnNameKey,
				@pdLogDateTimeStamp	        = @pdLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteSupplier to public
GO