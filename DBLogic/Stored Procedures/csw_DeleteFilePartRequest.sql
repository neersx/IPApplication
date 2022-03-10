-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteFilePartRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteFilePartRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteFilePartRequest.'
	Drop procedure [dbo].[csw_DeleteFilePartRequest]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteFilePartRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_DeleteFilePartRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnRequestID                    int,            -- Mandatory
	@pnCaseKey			int,            -- Mandatory	
	@pnFilePartKey			int,		-- Mandatory
        @pdtLogDateTimeStamp            datetime        = null
)
as
-- PROCEDURE:	csw_DeleteFilePartRequest
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete File Part associated with the File Request

-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	-----------------------------------------------
-- 07 Dec 2011  MS      R11208    1             Procedure created
-- 24 Oct 2017	AK	R72645	  2     	Make compatible with case sensitive server with case insensitive database.

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
	Set @sSQLString = "DELETE FROM FILEPARTREQUEST   
        where LOGDATETIMESTAMP = @pdtLogDateTimeStamp
        and REQUESTID = @pnRequestID
        and CASEID = @pnCaseKey
        and FILEPART = @pnFilePartKey"        

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnRequestID		int,
				@pnCaseKey              int,
				@pnFilePartKey	        int,
				@pdtLogDateTimeStamp    datetime',
				@pnRequestID	 	= @pnRequestID,
				@pnCaseKey              = @pnCaseKey,
				@pnFilePartKey	        = @pnFilePartKey,
				@pdtLogDateTimeStamp    = @pdtLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteFilePartRequest to public
GO