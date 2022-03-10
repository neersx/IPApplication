-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteRFIDFileRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteRFIDFileRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteRFIDFileRequest.'
	Drop procedure [dbo].[csw_DeleteRFIDFileRequest]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteRFIDFileRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteRFIDFileRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnRequestID                    int,	        -- Mandatory
	@pdtLogDateTimeStamp		datetime	= null
)
as
-- PROCEDURE:	csw_DeleteRFIDFileRequest
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete RFID File request if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	-----------------------------------------------
-- 30 Mar 2011  MS      RFC100502 1             Procedure created
-- 21 Nov 2011  MS      RFC11208  2             Remove Case key reference from Delete statements

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
        Set @sSQLString = "DELETE FROM FILEPARTREQUEST where REQUESTID = @pnRequestID"	

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnRequestID		int',
				@pnRequestID	 	= @pnRequestID        
End

If @nErrorCode = 0
Begin
        Set @sSQLString = "DELETE FROM FILEREQASSIGNEDDEVICE where REQUESTID = @pnRequestID"
        exec @nErrorCode=sp_executesql @sSQLString,
                                N'@pnRequestID          int',
                                @pnRequestID            = @pnRequestID
End
        
If @nErrorCode = 0
Begin
        Set @sSQLString = "DELETE FROM FILEREQASSIGNEDEMP where REQUESTID = @pnRequestID"
        exec @nErrorCode=sp_executesql @sSQLString,
                                 N'@pnRequestID          int',
                                 @pnRequestID            = @pnRequestID
End

If @nErrorCode = 0
Begin
        Set @sSQLString = "DELETE FROM RFIDFILEREQUESTCASES where REQUESTID = @pnRequestID"
        exec @nErrorCode=sp_executesql @sSQLString,
                                 N'@pnRequestID          int',
                                 @pnRequestID            = @pnRequestID 
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "DELETE FROM RFIDFILEREQUEST
		WHERE REQUESTID = @pnRequestID
                AND LOGDATETIMESTAMP = @pdtLogDateTimeStamp"	

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnRequestID		int,
				@pdtLogDateTimeStamp	datetime',
				@pnRequestID	 	= @pnRequestID,			
				@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteRFIDFileRequest to public
GO
