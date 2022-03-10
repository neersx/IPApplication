-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertFilePartRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertFilePartRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertFilePartRequest.'
	Drop procedure [dbo].[csw_InsertFilePartRequest]
End
Print '**** Creating Stored Procedure dbo.csw_InsertFilePartRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertFilePartRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnRequestId                    int,            -- Mandatory   
	@pnCaseKey                      int,            -- Mandatory 
	@pnFilePartKey			int,		-- Mandatory
	@pnSearchStatus                 int             = null,
	@pbIsSelfSearch                 bit             = null
)
as
-- PROCEDURE:	csw_InsertFilePartRequest
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert File part for request

-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	-----------------------------------------------
-- 07 Dec 2011	MS	R11208    1             Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nSearchStatus          int

-- Initialise variables
Set @nErrorCode = 0

If @pbIsSelfSearch is null
Begin
        Set @sSQLString = "Select @pbIsSelfSearch = ISSELFSEARCH
        From RFIDFILEREQUEST
        Where REQUESTID = @pnRequestId"
        
        exec sp_executesql @sSQLString,
                N'@pbIsSelfSearch       bit                     output,
                @pnRequestId            int',
                @pbIsSelfSearch         = @pbIsSelfSearch       output,
                @pnRequestId            = @pnRequestId
End

If @nErrorCode = 0 and ISNULL(@pnSearchStatus,0) = 0
Begin
        If exists(Select 1 from FILEPARTREQUEST FP
                join RFIDFILEREQUEST RF on (RF.REQUESTID = FP.REQUESTID)
                where FP.CASEID = @pnCaseKey and FP.FILEPART = @pnFilePartKey
                and RF.STATUS in (0,1))
        Begin
                If ISNULL(@pbIsSelfSearch,0) = 0
                Begin
                        Set @nSearchStatus = 2 -- In Other search
                End
                Else 
                Begin
                       Set @nSearchStatus = 0 -- Not Found
                       
                       -- For Self Search file request, update Search Status of all the other 
                       -- file request's file parts which have status of ALLOCATE or TRANSFER
                       Set @sSQLString = "UPDATE  FILEPARTREQUEST
                       SET SEARCHSTATUS = 2
                       WHERE CASEID = @pnCaseKey and FILEPART = @pnFilePartKey
                       and REQUESTID in (SELECT REQUESTID FROM RFIDFILEREQUEST where STATUS in (0,1))
                       and SEARCHSTATUS = 0"
                       
                       exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnCaseKey              int,
				@pnFilePartKey	        int',
				@pnCaseKey              = @pnCaseKey,
				@pnFilePartKey	        = @pnFilePartKey
                       
                End
        End 
        Else
        Begin
                Set @nSearchStatus = 0 -- Not Found
        End        
End
ELSE
Begin
        Set @nSearchStatus = @pnSearchStatus
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Insert into FILEPARTREQUEST
			      (
                                REQUESTID,
                                CASEID,
                                FILEPART,
                                SEARCHSTATUS
                              )
                              VALUES
                              (
                                @pnRequestId,
                                @pnCaseKey,
                                @pnFilePartKey,
                                @nSearchStatus
                              )"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnRequestId		int,
				@pnCaseKey              int,
				@pnFilePartKey	        int,
				@nSearchStatus          int',
				@pnRequestId	 	= @pnRequestId,
				@pnCaseKey              = @pnCaseKey,
				@pnFilePartKey	        = @pnFilePartKey,
				@nSearchStatus          = @nSearchStatus
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertFilePartRequest to public
GO