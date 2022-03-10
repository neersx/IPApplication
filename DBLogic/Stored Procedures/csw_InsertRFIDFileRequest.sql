-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertRFIDFileRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertRFIDFileRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertRFIDFileRequest.'
	Drop procedure [dbo].[csw_InsertRFIDFileRequest]
End
Print '**** Creating Stored Procedure dbo.csw_InsertRFIDFileRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertRFIDFileRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int             = null,
	@psCaseKeys                     nvarchar(max)   = null,
	@pnFileLocationKey		int,            -- Mandatory
	@pnEmployeeKey			int		= null,
        @pnResourceNo                   int             = null,
	@psRemarks			nvarchar(254)	= null,
	@pdtDateRequested		datetime	= null,
        @pdtDateRequired		datetime	= null,
        @pnPriority                     int             = null,
        @pbIsSelfSearch                 bit             = null,
        @pdtLogDateTimeStamp		datetime	= null output,
	@psRowKey			nvarchar(50)	= null output
)
as
-- PROCEDURE:	csw_InsertRFIDFileRequest
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert FileRequest

-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	-----------------------------------------------
-- 30 Mar 2011	MS	RFC100502 1             Procedure created
-- 21 Nov 2011  MS      RFC11208  2             Removed FilePartRequest Insert  
-- 09 May 2012  MS      R100634   3             Added RowKey and LogDateTimeStamp output parameters               

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nRowCount		int
Declare @idoc 			int -- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.	
Declare @nRequestId             int	

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Insert into RFIDFILEREQUEST
			      (
                                CASEID,
                                FILELOCATION, 
                                DATEOFREQUEST,
                                DATEREQUIRED,
                                EMPLOYEENO,
                                REMARKS,
                                PRIORITY,
                                ISSELFSEARCH,
                                STATUS
                              )
                              VALUES
                              (
                                @pnCaseKey,
                                @pnFileLocationKey,  
                                @pdtDateRequested,
                                @pdtDateRequired,
                                @pnEmployeeKey,                                
                                @psRemarks,
                                @pnPriority,
                                @pbIsSelfSearch,
                                0
                              )"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnCaseKey		int,
				@pnFileLocationKey	int,
				@pdtDateRequested	datetime,
				@pdtDateRequired	datetime,
				@pnEmployeeKey		int,
                                @psRemarks              nvarchar(254),
                                @pnPriority             int,
                                @pbIsSelfSearch         bit',
				@pnCaseKey	 	= @pnCaseKey,
				@pnFileLocationKey	= @pnFileLocationKey,
				@pdtDateRequested	= @pdtDateRequested,
				@pdtDateRequired	= @pdtDateRequired,
				@pnEmployeeKey	 	= @pnEmployeeKey,
                                @psRemarks              = @psRemarks,                                	
                                @pnPriority             = @pnPriority,
                                @pbIsSelfSearch         = @pbIsSelfSearch

	Set @nRowCount = @@rowcount
        Set @nRequestId = IDENT_CURRENT('RFIDFILEREQUEST')
End

-- Insert Case Keys
If @nErrorCode = 0 and @nRequestId is not null and @psCaseKeys is not null and RTRIM(@psCaseKeys) <> ''
Begin
        Set @sSQLString = "INSERT INTO RFIDFILEREQUESTCASES (REQUESTID, CASEID)
                        SELECT @nRequestId, PARAMETER from 
                        fn_Tokenise (@psCaseKeys, ',')"
        
        exec @nErrorCode=sp_executesql @sSQLString,
                        N'@nRequestId           int,
                        @psCaseKeys             nvarchar(max)',
                        @nRequestId             = @nRequestId,
                        @psCaseKeys             = @psCaseKeys

End

IF @nErrorCode = 0 and @nRequestId is not null and @pbIsSelfSearch = 1
Begin
       If  @pnResourceNo is not null
       Begin
                Set @sSQLString = "INSERT INTO FILEREQASSIGNEDDEVICE (REQUESTID, RESOURCENO)
                        VALUES (@nRequestId, @pnResourceNo)"
        
                exec @nErrorCode=sp_executesql @sSQLString,
                        N'@nRequestId           int,
                        @pnResourceNo           int',
                        @nRequestId             = @nRequestId,
                        @pnResourceNo           = @pnResourceNo
       End
End

IF @nRowCount > 0 and @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@psRowKey = @nRequestId,				 
			@pdtLogDateTimeStamp = LOGDATETIMESTAMP
		from	RFIDFILEREQUEST
		where	REQUESTID = @nRequestId"
		
	exec @nErrorCode=sp_executesql @sSQLString,
                N'@psRowKey             nvarchar(50)            output,
                  @pdtLogDateTimeStamp  datetime                output,
                  @nRequestId           int',
                  @psRowKey             = @psRowKey             output,
                  @pdtLogDateTimeStamp  = @pdtLogDateTimeStamp  output,	
                  @nRequestId           = @nRequestId
                  
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertRFIDFileRequest to public
GO