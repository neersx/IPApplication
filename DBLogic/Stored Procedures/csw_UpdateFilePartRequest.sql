-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateFilePartRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateFilePartRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateFilePartRequest.'
	Drop procedure [dbo].[csw_UpdateFilePartRequest]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateFilePartRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_UpdateFilePartRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnRequestID                    int,            -- Mandatory
	@pnCaseKey			int,            -- Mandatory	
	@pnFilePartKey			int,		-- Mandatory
	@pnSearchStatus                 int             = null,
        @pdtLogDateTimeStamp            datetime        = null
)
as
-- PROCEDURE:	csw_UpdateFilePartRequest
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update File Parts of a file request if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	-----------------------------------------------
-- 07 Dec 2011  MS      R11208    1             Procedure created
-- 24 Oct 2017	AK	R72645	  2	Make compatible with case sensitive server with case insensitive database.

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
	Set @sSQLString = "Update FILEPARTREQUEST   
            Set SEARCHSTATUS    = @pnSearchStatus
        where LOGDATETIMESTAMP = @pdtLogDateTimeStamp
        and REQUESTID = @pnRequestID
        and CASEID = @pnCaseKey
        and FILEPART = @pnFilePartKey"        

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnRequestID		int,
				@pnCaseKey              int,
				@pnFilePartKey	        int,
				@pnSearchStatus         int,
				@pdtLogDateTimeStamp    datetime',
				@pnRequestID	 	= @pnRequestID,
				@pnCaseKey              = @pnCaseKey,
				@pnFilePartKey	        = @pnFilePartKey,
				@pnSearchStatus         = @pnSearchStatus,
				@pdtLogDateTimeStamp    = @pdtLogDateTimeStamp
End

If @nErrorCode = 0 and @pnSearchStatus = 1 -- Search Status Picked
Begin
        Set @sSQLString = "Update FILEPARTREQUEST   
        Set SEARCHSTATUS = 1
        where CASEID = @pnCaseKey
        and FILEPART = @pnFilePartKey
        and SEARCHSTATUS in (0,3)
        and REQUESTID in (Select REQUESTID from RFIDFILEREQUEST where STATUS in (0,1))"        

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnRequestID		int,
				@pnCaseKey              int,
				@pnFilePartKey	        int,
				@pnSearchStatus         int,
				@pdtLogDateTimeStamp    datetime',
				@pnRequestID	 	= @pnRequestID,
				@pnCaseKey              = @pnCaseKey,
				@pnFilePartKey	        = @pnFilePartKey,
				@pnSearchStatus         = @pnSearchStatus,
				@pdtLogDateTimeStamp    = @pdtLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateFilePartRequest to public
GO