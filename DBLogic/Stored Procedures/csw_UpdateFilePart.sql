-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateFilePart
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateFilePart]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateFilePart.'
	Drop procedure [dbo].[csw_UpdateFilePart]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateFilePart...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[csw_UpdateFilePart]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey              int,            -- Mandatory
        @pnFilePartKey	        int,            -- Mandatory
	@psFilePartTitle	nvarchar(200)	= null,
        @psRFIDCode             nvarchar(32)    = null,	        
	@pdtLogDateTimeStamp	datetime,
        @pnFilePartType         int             = null,
        @pnFileRecordStatus     int             = null,
        @pbIsMainFile           bit             = 0	       
)
as
-- PROCEDURE:	csw_UpdateFilePart
-- VERSION:	5
-- DESCRIPTION:	Update a file part for the Case.

-- MODIFICATIONS :
-- Date		Who	Change	   Version	Description
-- -----------	-------	------	   -------	----------------------------------------------- 
-- 27 Oct 2010	PA	RFC9021	   1	        Procedure created.
-- 10 Feb 2010  MS      RFC8363    	2            Added RFID Code
-- 24 Mar 2011  MS      RFC100502 	3     Added FILEPARTTYPE, FILERECORDSTATUS, ISMAINFILE
-- 16 May 2011  MS      RFC100530  	4            Added CASEID in Where condition for UPDATE
-- 24 Oct 2017	AK	R72645	        5	Make compatible with case sensitive server with case insensitive database.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sAlertXML	nvarchar(1000)

Set @nErrorCode = 0

-- Check for File Part existence
If @nErrorCode = 0
Begin
	if exists(Select 1 from FILEPART WHERE CASEID = @pnCaseKey and FILEPARTTITLE = @psFilePartTitle and FILEPART <> @pnFilePartKey)				
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS106', 'The File Part Title already exists.', null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
	End
End

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "UPDATE FILEPART
			Set FILEPARTTITLE       = @psFilePartTitle,
                        RFID                    = @psRFIDCode,
                        FILEPARTTYPE            = @pnFilePartType, 
                        FILERECORDSTATUS        = @pnFileRecordStatus, 
                        ISMAINFILE              = @pbIsMainFile	
			WHERE FILEPART = @pnFilePartKey
                        and CASEID = @pnCaseKey
			AND (LOGDATETIMESTAMP = @pdtLogDateTimeStamp or 
                                (@pdtLogDateTimeStamp is null and LOGDATETIMESTAMP is null))"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@psFilePartTitle      nvarchar(200),
			@pnFilePartKey	        int,
                        @pnCaseKey              int,
                        @psRFIDCode             nvarchar(32),
			@pdtLogDateTimeStamp	datetime,
                        @pnFilePartType         int,
                        @pnFileRecordStatus     int,
                        @pbIsMainFile           bit',
			@psFilePartTitle        = @psFilePartTitle,
			@pnFilePartKey          = @pnFilePartKey,
                        @pnCaseKey              = @pnCaseKey,
                        @psRFIDCode             = @psRFIDCode,
			@pdtLogDateTimeStamp    = @pdtLogDateTimeStamp,
                        @pnFilePartType         = @pnFilePartType,
                        @pnFileRecordStatus     = @pnFileRecordStatus,
                        @pbIsMainFile           = @pbIsMainFile		
	
        If (@@ROWCOUNT = 0)
	Begin
		-- File Part not found
		Set @sAlertXML = dbo.fn_GetAlertXML('BI2', 'Concurrency error. File Part has been changed or deleted. Please reload and try again.',
							null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = 1
	End
End

If (@nErrorCode = 0)
Begin
	Select @pnFilePartKey as 'FilePartKey',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from FILEPART 
	WHERE FILEPART.FILEPART = @pnFilePartKey
        and CASEID = @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateFilePart to public
GO
