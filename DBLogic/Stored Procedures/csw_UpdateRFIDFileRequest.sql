-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateRFIDFileRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateRFIDFileRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateRFIDFileRequest.'
	Drop procedure [dbo].[csw_UpdateRFIDFileRequest]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateRFIDFileRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_UpdateRFIDFileRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int		= null,
	@pnFileLocationKey		int,		-- Mandatory        
        @pnRequestID                    int,            -- Mandatory	
	@pnEmployeeKey			int		= null,
	@psRemarks			nvarchar(254)	= null,
        @pnResourceNo                   int             = null,
	@pdtDateRequested		datetime	= null,
        @pdtDateRequired		datetime	= null,        
	@pdtLogDateTimeStamp            datetime        = null,
        @pnPriority                     int             = null,
        @pbIsSelfSearch                 bit             = null,
        @psFilePartsXML                 ntext           = null
)
as
-- PROCEDURE:	csw_UpdateRFIDFileRequest
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update File Request if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	-----------------------------------------------
-- 31 Mar 2011  MS      RFC100502 1             Procedure created
-- 21 Nov 2011  MS      RFC11208  2             Remove Case key reference from Update statements

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
        -- Get Old value of IsSelfSearch
        Set @sSQLString = "Select @bIsSelfSearchOld = ISSELFSEARCH 
                        from RFIDFILEREQUEST
                        where REQUESTID = @pnRequestID"

        exec @nErrorCode=sp_executesql @sSQLString,
			         N'@bIsSelfSearchOld    bit     output,
                                   @pnRequestID         int',
                                   @bIsSelfSearchOld    = @bIsSelfSearchOld     output,
			           @pnRequestID	        = @pnRequestID          
        
        -- Delete all existing File parts from request for RFID System
        If @nErrorCode = 0
        Begin
                Set @sSQLString = "DELETE FROM FILEPARTREQUEST where REQUESTID = @pnRequestID"
                        
                exec @nErrorCode=sp_executesql @sSQLString,
			        N'@pnRequestID          int',
			        @pnRequestID	        = @pnRequestID  
        End
End


If @nErrorCode = 0
Begin
	Set @sSQLString = "Update RFIDFILEREQUEST   
            Set FILELOCATION    = @pnFileLocationKey,
		DATEOFREQUEST   = @pdtDateRequested,
		DATEREQUIRED    = @pdtDateRequired,
		EMPLOYEENO      = @pnEmployeeKey,
                REMARKS         = @psRemarks,                
                PRIORITY        = @pnPriority,
                ISSELFSEARCH    = @pbIsSelfSearch
        where LOGDATETIMESTAMP = @pdtLogDateTimeStamp
        and REQUESTID = @pnRequestID"        

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnFileLocationKey	int,
                                @pnEmployeeKey		int,
                                @psRemarks		nvarchar(254),
				@pdtDateRequested	datetime,
                                @pdtDateRequired        datetime,
                                @pnRequestID            int,
                                @pnPriority             int,
                                @pbIsSelfSearch         bit,                                
				@pdtLogDateTimeStamp	datetime',
				@pnFileLocationKey	= @pnFileLocationKey,                                
				@pnEmployeeKey	 	= @pnEmployeeKey,
                                @psRemarks              = @psRemarks,
				@pdtDateRequested	= @pdtDateRequested,	
                                @pdtDateRequired        = @pdtDateRequired,	
                                @pnRequestID            = @pnRequestID,	
                                @pnPriority             = @pnPriority,
                                @pbIsSelfSearch         = @pbIsSelfSearch,
				@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp

        Set @nRowCount = @@rowcount 
End

-- Devices and Assigned Employees
IF @nErrorCode = 0
Begin
        If @bIsSelfSearchOld = 0 and @pbIsSelfSearch = 1         
        Begin
                If @nErrorCode = 0
                Begin
                        Set @sSQLString = "DELETE FROM FILEREQASSIGNEDDEVICE where REQUESTID = @pnRequestID"
                        exec @nErrorCode=sp_executesql @sSQLString,
                                                N'@pnRequestID          int',
                                                @pnRequestID            = @pnRequestID
                End        
               
                IF @nErrorCode = 0
                Begin   
                        Set @sSQLString = "INSERT INTO FILEREQASSIGNEDDEVICE (REQUESTID, RESOURCENO)
                                VALUES (@pnRequestID, @pnResourceNo)"
                
                        exec @nErrorCode=sp_executesql @sSQLString,
                                N'@pnRequestID          int,
                                @pnResourceNo           int',
                                @pnRequestID            = @pnRequestID,
                                @pnResourceNo           = @pnResourceNo
                End               
                
        End 
        ELSE IF @bIsSelfSearchOld = 1 and @pbIsSelfSearch = 0
        Begin
                If @nErrorCode = 0
                Begin
                        Set @sSQLString = "DELETE FROM FILEREQASSIGNEDDEVICE where REQUESTID = @pnRequestID"
                        exec @nErrorCode=sp_executesql @sSQLString,
                                                N'@pnRequestID          int',
                                                @pnRequestID            = @pnRequestID
                End
        
                If @nErrorCode = 0
                Begin
                        Set @sSQLString = "DELETE FROM FILEREQASSIGNEDEMP where REQUESTID = @pnRequestID"
                        exec @nErrorCode=sp_executesql @sSQLString,
                                                N'@pnRequestID          int',
                                                @pnRequestID            = @pnRequestID
                End
        End
        ELSE IF @pbIsSelfSearch = 1 and @bIsSelfSearchOld = 1
        BEGIN
                If @nErrorCode = 0
                Begin
                        Set @sSQLString = "UPDATE FILEREQASSIGNEDDEVICE
                        SET RESOURCENO  = @pnResourceNo
                        WHERE REQUESTID = @pnRequestID"
                        
                        exec @nErrorCode=sp_executesql @sSQLString,
                                        N'@pnRequestID          int,
                                        @pnResourceNo           int',
                                        @pnRequestID            = @pnRequestID,
                                        @pnResourceNo           = @pnResourceNo
                End
        END
End

-- File Parts for Request
IF @nErrorCode = 0 and (datalength(@psFilePartsXML) > 0) 
Begin
        Declare @FilePartstable table (CaseKey int, FilePartKey int)

        -- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @psFilePartsXML

        INSERT INTO @FilePartstable
        SELECT CaseKey, FilePartKey
        from	OPENXML (@idoc, '/FileParts/FilePart',2)      
        WITH (
                CaseKey         int     'CaseKey',
                FilePartKey     int     'FilePartKey')

        Set @nErrorCode=@@Error

        -- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc      

        -- Add Selected file parts in request
        IF @nErrorCode = 0 and exists (Select 1 from @FilePartstable)
        Begin                
                INSERT INTO FILEPARTREQUEST (REQUESTID, CASEID, FILEPART, SEARCHSTATUS)
                SELECT @pnRequestID, CaseKey, FilePartKey, 0
                FROM @FilePartstable

                Set @nErrorCode=@@Error  
        End          
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateRFIDFileRequest to public
GO