-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertFileRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertFileRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertFileRequest.'
	Drop procedure [dbo].[csw_InsertFileRequest]
End
Print '**** Creating Stored Procedure dbo.csw_InsertFileRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertFileRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnFileLocationKey		int,            -- Mandatory
	@pnFilePartKey			smallint	= null,
	@pnEmployeeKey			int		= null,
        @psRemarks			nvarchar(254)	= null,
	@pdtDateRequested		datetime	= null,
        @pdtDateRequired		datetime	= null,
        @pnPriority                     int             = null,
        @pdtLogDateTimeStamp		datetime	= null output,
	@psRowKey			nvarchar(50)	= null output
)
as
-- PROCEDURE:	csw_InsertFileRequest
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert FileRequest

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jan 2011	MS	RFC8363	1	Procedure created
-- 30 Mar 2011  MS  R100502 2   Added parameters for Priority
-- 01 Nov 2011	ASH	R11460	3	Converted int CASEID column to nvarchar(11)
-- 04 May 2012  MS  R100634 4   Added LogDateTimeStamp and RowKey output parameters
-- 15 Apr 2013	DV	R13270	5	Increase the length of nvarchar to 11 when casting or declaring integer


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nSequenceNo		smallint
Declare @nRowCount		int

-- Initialise variables
Set @nErrorCode = 0
Set @nSequenceNo = 0

-- Assign MAXLOCATIONS site control to variable
If @nErrorCode = 0
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

If @nErrorCode = 0
Begin
	Set @sSQLString = "Insert into FILEREQUEST
			      (
                                CASEID,
                                FILELOCATION,
                                SEQUENCENO,
                                FILEPARTID,
                                DATEOFREQUEST,
                                DATEREQUIRED,
                                EMPLOYEENO,                                
                                REMARKS,
                                PRIORITY,
                                STATUS
                              )
                              VALUES
                              (
                                @pnCaseKey,
                                @pnFileLocationKey,
                                ISNULL(@nSequenceNo,0),
                                @pnFilePartKey,
                                @pdtDateRequested,
                                @pdtDateRequired,
                                @pnEmployeeKey,                                
                                @psRemarks,
                                @pnPriority,
                                0
                              )"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnCaseKey		int,
				@nSequenceNo		smallint,
				@pnFileLocationKey	int,
				@pnFilePartKey		smallint,
				@pdtDateRequested	datetime,
				@pdtDateRequired	datetime,
				@pnEmployeeKey		int,                                
                                @pnPriority             int,
                                @psRemarks              nvarchar(254)',
				@pnCaseKey	 	= @pnCaseKey,
				@nSequenceNo	 	= @nSequenceNo,
				@pnFileLocationKey	= @pnFileLocationKey,
				@pnFilePartKey	 	= @pnFilePartKey,
				@pdtDateRequested	= @pdtDateRequested,
				@pdtDateRequired	= @pdtDateRequired,
				@pnEmployeeKey	 	= @pnEmployeeKey,                                
                                @pnPriority             = @pnPriority,
                                @psRemarks              = @psRemarks

	Set @nRowCount = @@rowcount
End

IF @nRowCount > 0 and @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@psRowKey = CAST(CASEID as nvarchar(11))+'^'+CAST(FILELOCATION as nvarchar(11)) +'^'+CAST(SEQUENCENO as nvarchar(10)),				 
			@pdtLogDateTimeStamp = LOGDATETIMESTAMP
		from	FILEREQUEST
		where	CASEID = @pnCaseKey
                and     FILELOCATION = @pnFileLocationKey
                and     SEQUENCENO = @nSequenceNo"
		
	exec @nErrorCode=sp_executesql @sSQLString,
                N'@psRowKey             nvarchar(50)    output,
                  @pdtLogDateTimeStamp  datetime        output,
                  @pnCaseKey		int,
		  @pnFileLocationKey	int,
                  @nSequenceNo          smallint',
                  @psRowKey             = @psRowKey     output,
                  @pdtLogDateTimeStamp  = @pdtLogDateTimeStamp  output,
		  @pnCaseKey		= @pnCaseKey,
		  @pnFileLocationKey	= @pnFileLocationKey,
                  @nSequenceNo          = @nSequenceNo	
	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertFileRequest to public
GO