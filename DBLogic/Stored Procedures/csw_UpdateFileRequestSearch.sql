-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateFileRequestSearch									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateFileRequestSearch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateFileRequestSearch.'
	Drop procedure [dbo].[csw_UpdateFileRequestSearch]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateFileRequestSearch...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_UpdateFileRequestSearch
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnRequestID                    int,            -- Mandatory
	@pnFileLocationKey		int,		-- Mandatory 
	@pnCaseKey			int             = null,	
	@pnEmployeeKey			int		= null,
	@psRemarks			nvarchar(254)	= null,
        @pdtDateRequired		datetime	= null, 
        @pnPriority                     int             = null,
        @pnStatus                       int             = null,
        @pdtLogDateTimeStamp            datetime        = null
)
as
-- PROCEDURE:	csw_UpdateFileRequestSearch
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update File Request if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	-----------------------------------------------
-- 07 Dec 2011  MS      R11208    1             Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nRowCount              int
Declare @nSequenceNo		smallint
Declare @bIsRFIDSystem          bit
Declare @bIsSelfSearchOld       bit
Declare @idoc 			int -- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

-- Initialise variables
Set @nErrorCode = 0
Set @nSequenceNo = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Update RFIDFILEREQUEST   
            Set FILELOCATION    = @pnFileLocationKey,
		DATEREQUIRED    = @pdtDateRequired,
		EMPLOYEENO      = @pnEmployeeKey,
                REMARKS         = @psRemarks,                
                PRIORITY        = @pnPriority,
                STATUS          = @pnStatus
        where LOGDATETIMESTAMP = @pdtLogDateTimeStamp
        and REQUESTID = @pnRequestID"        

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnFileLocationKey	int,
                                @pnEmployeeKey		int,
                                @psRemarks		nvarchar(254),
				@pdtDateRequired        datetime,
                                @pnRequestID            int,
                                @pnPriority             int,
                                @pnStatus               int,                                
				@pdtLogDateTimeStamp	datetime',
				@pnFileLocationKey	= @pnFileLocationKey,                                
				@pnEmployeeKey	 	= @pnEmployeeKey,
                                @psRemarks              = @psRemarks,	
                                @pdtDateRequired        = @pdtDateRequired,	
                                @pnRequestID            = @pnRequestID,	
                                @pnPriority             = @pnPriority,
                                @pnStatus               = @pnStatus,
				@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp

        Set @nRowCount = @@rowcount 
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateFileRequestSearch to public
GO