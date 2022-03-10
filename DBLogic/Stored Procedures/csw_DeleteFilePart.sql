-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteFilePart
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteFilePart]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteFilePart.'
	Drop procedure [dbo].[csw_DeleteFilePart]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteFilePart...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[csw_DeleteFilePart]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
        @pbCalledFromCentura	bit		= 0,
        @pnCaseKey              int,
	@pnFilePartKey		smallint,
	@pdtLogDateTimeStamp	datetime
)
as
-- PROCEDURE:	csw_DeleteFilePart
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete a file part for the CaseKey

-- MODIFICATIONS :
-- Date		Who	Change	   Version   Description
-- -----------	------	-------	   -------   --------------------------------------- 
-- 27 Oct 2010	PA	RFC9021	   1	     Procedure created
-- 16 May 2011  MS      RFC10030   2         Added CASEID in where condition of Delete

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nRowCount	int
declare @sSQLString	nvarchar(max)
declare @sAlertXML      nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If exists(SELECT * FROM CASELOCATION WHERE FILEPARTID = @pnFilePartKey and CASEID = @pnCaseKey)
        or exists(SELECT * FROM FILEREQUEST WHERE FILEPARTID = @pnFilePartKey and CASEID = @pnCaseKey)				
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS105', 'File Part cannot be removed because there had been movements recorded against it.', null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	
	Set @sSQLString = "
	Delete from FILEPART
	where FILEPART.FILEPART = @pnFilePartKey
        and CASEID = @pnCaseKey 
	and (LOGDATETIMESTAMP = @pdtLogDateTimeStamp or 
                (@pdtLogDateTimeStamp is null and LOGDATETIMESTAMP is null))"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnFilePartKey	smallint,
                                  @pnCaseKey            int,
				  @pdtLogDateTimeStamp	datetime',
				  @pnFilePartKey	= @pnFilePartKey,
                                  @pnCaseKey            = @pnCaseKey,
				  @pdtLogDateTimeStamp	= @pdtLogDateTimeStamp	
				  
	Set @nRowCount = @@rowcount
	
End

If (@nRowCount = 0)
Begin	
	Set @sAlertXML = dbo.fn_GetAlertXML('SF29', 'Concurrency violation. File Part may have been updated or deleted. Please reload and try again.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteFilePart to public
GO
