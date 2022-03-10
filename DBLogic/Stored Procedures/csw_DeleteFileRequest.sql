-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteFileRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteFileRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteFileRequest.'
	Drop procedure [dbo].[csw_DeleteFileRequest]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteFileRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteFileRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnFileLocationKey		int,	        -- Mandatory
        @pnSequenceNo                   smallint,       -- Mandatory	
	@pdtLogDateTimeStamp		datetime	= null
)
as
-- PROCEDURE:	csw_DeleteFileRequest
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete FileLocation if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jun 2011  MS      RFC8363	1	Procedure created

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
	Set @sSQLString = "Delete from FILEREQUEST
		where CASEID = @pnCaseKey  
		and SEQUENCENO = @pnSequenceNo
                and FILELOCATION = @pnFileLocationKey
                and LOGDATETIMESTAMP = @pdtLogDateTimeStamp"	

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnCaseKey		int,
				@pnSequenceNo		smallint,
                                @pnFileLocationKey      int,
				@pdtLogDateTimeStamp	datetime',
				@pnCaseKey	 	= @pnCaseKey,
				@pnSequenceNo	 	= @pnSequenceNo,	
                                @pnFileLocationKey      = @pnFileLocationKey,			
				@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteFileRequest to public
GO
