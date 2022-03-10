-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateFileLocation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateFileLocation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateFileLocation.'
	Drop procedure [dbo].[csw_UpdateFileLocation]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateFileLocation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateFileLocation
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pdtWhenMoved			datetime,	-- Mandatory
	@pnFileLocationKey		int		= null,
	@pnFilePartKey			smallint	= null,
	@pnMovedByKey			int		= null,
	@psBayNo			nvarchar(20)	= null,        
	@pdtDateScanned			datetime	= null,
        @psRowKey                       nvarchar(50)    = null output,
	@pdtLogDateTimeStamp            datetime        = null output
)
as
-- PROCEDURE:	csw_UpdateFileLocation
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update FileLocation if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jul 2006	SW	RFC2307	1	Procedure created
-- 24 Jan 2011  MS      RFC8363 2       Removed old and in use parameters and add LogDateTimeStamp
-- 24 Oct 2011	ASH	R11460  3	Cast integer columns as nvarchar(11) data type.     
-- 11 Apr 2012	SF	R11164	4	Output new date time stamp and row key

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nRowCount              int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Update CASELOCATION
                SET WHENMOVED           = @pdtWhenMoved,
                    FILEPARTID          = @pnFilePartKey,
                    FILELOCATION        = @pnFileLocationKey,
		    BAYNO               = @psBayNo,
		    ISSUEDBY            = @pnMovedByKey,                   
		    DATESCANNED         = @pdtDateScanned
        where CASEID = @pnCaseKey
        and LOGDATETIMESTAMP = @pdtLogDateTimeStamp
        and CAST(CASEID as nvarchar(11))+'^'+CONVERT(varchar,WHENMOVED,121) = @psRowKey"        
        
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnCaseKey		int,
				@pdtWhenMoved		datetime,
				@pnFileLocationKey	int,
				@pnFilePartKey		smallint,
				@pnMovedByKey		int,
				@psBayNo		nvarchar(20),
				@pdtDateScanned		datetime,                               
				@pdtLogDateTimeStamp	datetime,
                                @psRowKey               nvarchar(50)',
				@pnCaseKey	 	= @pnCaseKey,
				@pdtWhenMoved	 	= @pdtWhenMoved,
				@pnFileLocationKey	= @pnFileLocationKey,
				@pnFilePartKey	 	= @pnFilePartKey,
				@pnMovedByKey	 	= @pnMovedByKey,
				@psBayNo	 	= @psBayNo,
				@pdtDateScanned	 	= @pdtDateScanned,                               		
				@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp,
                                @psRowKey               = @psRowKey

        Set @nRowCount = @@rowcount 
End

IF @nRowCount > 0 and @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@pdtLogDateTimeStamp = LOGDATETIMESTAMP,
			@psRowKey = CAST(CASEID as nvarchar(11))+'^'+CONVERT(varchar,WHENMOVED,121) 
		from	CASELOCATION
		where	CASEID = @pnCaseKey
                and     FILELOCATION = @pnFileLocationKey
                and     WHENMOVED = @pdtWhenMoved
                
                
                Select @pdtLogDateTimeStamp
                "
		
	exec @nErrorCode=sp_executesql @sSQLString,
                N'@pdtLogDateTimeStamp	datetime output,
		  @psRowKey		nvarchar(50) output,
		  @pnCaseKey		int,
		  @pnFileLocationKey	int,
                  @pdtWhenMoved         datetime',
                  @pdtLogDateTimeStamp	= @pdtLogDateTimeStamp output,
                  @psRowKey             = @psRowKey output,
		  @pnCaseKey		= @pnCaseKey,
		  @pnFileLocationKey	= @pnFileLocationKey,
                  @pdtWhenMoved         = @pdtWhenMoved	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateFileLocation to public
GO