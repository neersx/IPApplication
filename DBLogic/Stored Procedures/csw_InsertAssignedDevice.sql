-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertAssignedDevice									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertAssignedDevice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertAssignedDevice.'
	Drop procedure [dbo].[csw_InsertAssignedDevice]
End
Print '**** Creating Stored Procedure dbo.csw_InsertAssignedDevice...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertAssignedDevice
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnRequestId                    int,            -- Mandatory             
	@pnResourceNo			int		-- Mandatory
)
as
-- PROCEDURE:	csw_InsertAssignedDevice
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Assigned Device for a file request

-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	-----------------------------------------------
-- 07 Dec 2011	MS	R11208    1             Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Insert into FILEREQASSIGNEDDEVICE
			      (
                                REQUESTID,
                                RESOURCENO
                              )
                              VALUES
                              (
                                @pnRequestId,
                                @pnResourceNo
                              )"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnRequestId		int,
				@pnResourceNo	        int',
				@pnRequestId	 	= @pnRequestId,
				@pnResourceNo	        = @pnResourceNo
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertAssignedDevice to public
GO