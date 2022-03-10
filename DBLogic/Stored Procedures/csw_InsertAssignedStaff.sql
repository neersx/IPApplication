-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertAssignedStaff									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertAssignedStaff]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertAssignedStaff.'
	Drop procedure [dbo].[csw_InsertAssignedStaff]
End
Print '**** Creating Stored Procedure dbo.csw_InsertAssignedStaff...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertAssignedStaff
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnRequestId                    int,            -- Mandatory             
	@pnStaffKey			int		= null
)
as
-- PROCEDURE:	csw_InsertAssignedStaff
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert assigned staff for a file request

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
	Set @sSQLString = "Insert into FILEREQASSIGNEDEMP
			      (
                                REQUESTID,
                                NAMENO
                              )
                              VALUES
                              (
                                @pnRequestId,
                                @pnStaffKey
                              )"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnRequestId		int,
				@pnStaffKey	        int',
				@pnRequestId	 	= @pnRequestId,
				@pnStaffKey	        = @pnStaffKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertAssignedStaff to public
GO