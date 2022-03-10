-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateFileRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateFileRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateFileRequest.'
	Drop procedure [dbo].[csw_UpdateFileRequest]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateFileRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateFileRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnFileLocationKey		int,		-- Mandatory
        @pnSequenceNo                   int,            -- Mandatory
	@pnFilePartKey			smallint	= null,
	@pnEmployeeKey			int		= null,
	@psRemarks			nvarchar(254)	= null,
        @pnResourceNo                   int             = null,
	@pdtDateRequested		datetime	= null,
        @pdtDateRequired		datetime	= null,
        @psRowKey                       nvarchar(50)    = null,
	@pdtLogDateTimeStamp            datetime        = null,
        @pnPriority                     int             = null
)
as
-- PROCEDURE:	csw_UpdateFileRequest
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update File Request if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jan 2011  MS  RFC8363		1   Procedure created
-- 30 Mar 2011  MS  RFC100502	2   Added parameters for Priority
-- 24 Oct 2011	ASH	R11460		3	Cast integer columns as nvarchar(11) data type.  
-- 15 Apr 2013	DV	R13270		4	Increase the length of nvarchar to 11 when casting or declaring integer 

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nRowCount              int
Declare @nSequenceNo		smallint

-- Initialise variables
Set @nErrorCode = 0
Set @nSequenceNo = 0

If @nErrorCode = 0
Begin
        If (Select FILELOCATION from FILEREQUEST where CAST(CASEID as nvarchar(11))+'^'+CAST(FILELOCATION as nvarchar(11)) +'^'+CAST(SEQUENCENO as nvarchar(10)) = @psRowKey) 
                <> @pnFileLocationKey
        Begin
                Set @sSQLString = "
		SELECT @nSequenceNo = Max (SEQUENCENO) + 1  
                FROM FILEREQUEST 
                WHERE FILELOCATION = @pnFileLocationKey 
                AND CASEID = @pnCaseKey"

	        exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@nSequenceNo	        smallint		OUTPUT,
                                  @pnFileLocationKey    int,
                                  @pnCaseKey            int',
				  @nSequenceNo	        = @nSequenceNo	        OUTPUT,
                                  @pnFileLocationKey    = @pnFileLocationKey,
                                  @pnCaseKey            = @pnCaseKey                 
        End
        Else
        Begin
                Set @nSequenceNo = @pnSequenceNo
        End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Update FILEREQUEST   
            Set FILEPARTID      = @pnFilePartKey,
                FILELOCATION    = @pnFileLocationKey,
		DATEOFREQUEST   = @pdtDateRequested,
		DATEREQUIRED    = @pdtDateRequired,
		EMPLOYEENO      = @pnEmployeeKey,
                REMARKS         = @psRemarks,
                SEQUENCENO      = ISNULL(@nSequenceNo,0),
                PRIORITY        = @pnPriority
        where CASEID = @pnCaseKey
        and LOGDATETIMESTAMP = @pdtLogDateTimeStamp
        and CAST(CASEID as nvarchar(11))+'^'+CAST(FILELOCATION as nvarchar(11)) +'^'+CAST(SEQUENCENO as nvarchar(10)) = @psRowKey"        

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnCaseKey		int,
				@pnFileLocationKey	int,
                                @nSequenceNo            int,
                                @pnSequenceNo           int,
				@pnFilePartKey		smallint,
				@pnEmployeeKey		int,
				@psRemarks		nvarchar(254),
				@pdtDateRequested	datetime,
                                @pdtDateRequired        datetime,
                                @psRowKey               nvarchar(50),
				@pdtLogDateTimeStamp	datetime,
                                @pnPriority             int',
				@pnCaseKey	 	= @pnCaseKey,
				@pnFileLocationKey	= @pnFileLocationKey,
                                @nSequenceNo            = @nSequenceNo,
                                @pnSequenceNo           = @pnSequenceNo,
				@pnFilePartKey	 	= @pnFilePartKey,
				@pnEmployeeKey	 	= @pnEmployeeKey,
				@psRemarks              = @psRemarks,
				@pdtDateRequested	= @pdtDateRequested,	
                                @pdtDateRequired        = @pdtDateRequired,	
                                @psRowKey               = @psRowKey,		
				@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp,
                                @pnPriority             = @pnPriority

        Set @nRowCount = @@rowcount 
End

IF @nRowCount > 0 and @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	LOGDATETIMESTAMP
		from	FILEREQUEST
		where	CASEID  = @pnCaseKey
                and     FILELOCATION = @pnFileLocationKey
                and     SEQUENCENO = @pnSequenceNo"
		
	exec @nErrorCode=sp_executesql @sSQLString,
                N'@pnCaseKey		int,
		  @pnFileLocationKey	int,
                  @pnSequenceNo         smallint',
		  @pnCaseKey		= @pnCaseKey,
		  @pnFileLocationKey	= @pnFileLocationKey,
                  @pnSequenceNo         = @pnSequenceNo		
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateFileRequest to public
GO