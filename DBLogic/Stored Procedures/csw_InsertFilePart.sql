-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertFilePart
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertFilePart]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertFilePart.'
	Drop procedure [dbo].[csw_InsertFilePart]
End
Print '**** Creating Stored Procedure dbo.csw_InsertFilePart...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[csw_InsertFilePart]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
        @pnCaseKey              int,
        @psFilepartTitle        nvarchar(200),
        @psRFIDCode             nvarchar(32)    = null,
        @pnFilePartType         int             = null,
        @pnFileRecordStatus     int             = null,
        @pbIsMainFile           bit             = 0,
        @pnNameKey              int             = null	
)
as
-- PROCEDURE:	csw_InsertFilePart
-- VERSION:	5
-- DESCRIPTION:	Insert a file part for the Case.
        
-- MODIFICATIONS :
-- Date		Who	Change	        Version	Description
-- -----------	-------	------	        -------	----------------------------------------------- 
-- 27 Oct 2010	PA	RFC9021	        1	Procedure created.
-- 10 Feb 2010  MS      RFC8363         2       Added RFID Code
-- 11 Apr 2011  MS      RFC100502 	3       Added FILEPARTTYPE, FILERECORDSTATUS, ISMAINFILE
-- 16 May 2011  MS      RFC100530      	4       Get FilePartKey as maximum sequence based on CaseKey
-- 29 Jul 2011  MS      RFC100503       5       Insert File Location for File Part if current location for name is present

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @nOutputFilePartKey	int
Declare @sAlertXML		nvarchar(1000)
Declare @nLocationKey           int
Declare @dCurrentDate           datetime

Set @nErrorCode = 0
Set @nOutputFilePartKey = 0
Set @dCurrentDate = GETDATE()

-- Check for File Part existence
If @nErrorCode = 0
Begin
	if exists(Select 1 from FILEPART WHERE CASEID = @pnCaseKey and FILEPARTTITLE = @psFilepartTitle)				
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS106', 'The File Part Title already exists.', null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
	End
End

If (@nErrorCode = 0)
Begin
        If exists (Select 1 from FILEPART where CASEID = @pnCaseKey)
        Begin
                Set @sSQLString = "Select @nOutputFilePartKey = max(FILEPART) + 1 
                                  from FILEPART 
                                  where CASEID = @pnCaseKey"

                exec @nErrorCode = sp_executesql @sSQLString,
                                N'@nOutputFilePartKey   int     output,
                                @pnCaseKey              int',
                                @nOutputFilePartKey     = @nOutputFilePartKey   output,
                                @pnCaseKey              = @pnCaseKey
        End

        If @nErrorCode = 0
        Begin 

                Set @sSQLString = "INSERT INTO FILEPART(CASEID, FILEPART, FILEPARTTITLE, RFID, FILEPARTTYPE, FILERECORDSTATUS, ISMAINFILE)
			   VALUES (@pnCaseKey,@nOutputFilePartKey, @psFilepartTitle, @psRFIDCode, @pnFilePartType, @pnFileRecordStatus, @pbIsMainFile)"
	
	        exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCaseKey            int,
                          @nOutputFilePartKey   int,
                          @psRFIDCode           nvarchar(32),
                          @psFilepartTitle      nvarchar(200),
                          @pnFilePartType       int,
                          @pnFileRecordStatus   int,
                          @pbIsMainFile         bit',
			@pnCaseKey              = @pnCaseKey,
                        @nOutputFilePartKey     = @nOutputFilePartKey,
                        @psRFIDCode             = @psRFIDCode,
			@psFilepartTitle        = @psFilepartTitle,
                        @pnFilePartType         = @pnFilePartType,
                        @pnFileRecordStatus     = @pnFileRecordStatus,
                        @pbIsMainFile           = @pbIsMainFile		
        End	
End

If (@nErrorCode = 0)
Begin
	Select @nOutputFilePartKey as 'FilePartKey',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from FILEPART 
	WHERE FILEPART = @nOutputFilePartKey
        and CASEID = @pnCaseKey
End

-- Inserts Case Location with Current Location for the logged in user for newly created File Part
If @nErrorCode = 0 and @pnNameKey is not null and @nOutputFilePartKey is not null
Begin
        Set @sSQLString = "Select @nLocationKey = FILELOCATION
                           from NAMELOCATION
                           where NAMENO = @pnNameKey and ISCURRENTLOCATION = 1"

        exec @nErrorCode = sp_executesql @sSQLString,
                               N'@nLocationKey         int     output,
                                @pnNameKey             int',
                                @nLocationKey          = @nLocationKey   output,
                                @pnNameKey             = @pnNameKey
                                
        If @nErrorCode = 0 and @nLocationKey is not null
        Begin
                exec @nErrorCode = dbo.csw_InsertFileLocation 
                        @pnUserIdentityId       = @pnUserIdentityId,
                        @psCulture              = @psCulture,
                        @pbCalledFromCentura    = @pbCalledFromCentura,
                        @pnCaseKey              = @pnCaseKey,
                        @pdtWhenMoved           = @dCurrentDate,
                        @pnFileLocationKey      = @nLocationKey,
                        @pnFilePartKey          = @nOutputFilePartKey,
                        @pnMovedByKey           = @pnNameKey      
        End
End



Return @nErrorCode
GO

Grant execute on dbo.csw_InsertFilePart to public
GO