-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteAssignedDevice									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteAssignedDevice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteAssignedDevice.'
	Drop procedure [dbo].[csw_DeleteAssignedDevice]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteAssignedDevice...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_DeleteAssignedDevice
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnRequestID                    int,            -- Mandatory
	@pnResourceKey			int,		-- Mandatory
        @pdtLogDateTimeStamp            datetime        = null
)
as
-- PROCEDURE:	csw_DeleteAssignedDevice
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete device associated with the File Request

-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	-----------------------------------------------
-- 07 Dec 2011  MS      R11208    1             Procedure created
-- 24 Oct 2017	AK	R72645	  2	        Make compatible with case sensitive server with case insensitive database.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "DELETE FROM FILEREQASSIGNEDDEVICE   
        where LOGDATETIMESTAMP = @pdtLogDateTimeStamp
        and REQUESTID = @pnRequestID
        and RESOURCENO = @pnResourceKey"        

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnRequestID		int,
				@pnResourceKey          int,
				@pdtLogDateTimeStamp    datetime',
				@pnRequestID	 	= @pnRequestID,
				@pnResourceKey          = @pnResourceKey,
				@pdtLogDateTimeStamp    = @pdtLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteAssignedDevice to public
GO