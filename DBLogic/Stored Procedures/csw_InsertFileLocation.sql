-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertFileLocation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertFileLocation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertFileLocation.'
	Drop procedure [dbo].[csw_InsertFileLocation]
End
Print '**** Creating Stored Procedure dbo.csw_InsertFileLocation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertFileLocation
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory.
	@pdtWhenMoved			datetime,	-- Mandatory.
	@pnFileLocationKey		int		= null,
	@pnFilePartKey			smallint	= null,
	@pnMovedByKey			int		= null,
	@psBayNo			nvarchar(20)	= null,        
	@pdtDateScanned			datetime	= null,
	@pdtLogDateTimeStamp		datetime	= null output,
	@psRowKey			nvarchar(50)	= null output
)
as
-- PROCEDURE:	csw_InsertFileLocation
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert FileLocation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jul 2006	SW	RFC2307	1	Procedure created
-- 28 Feb 2007	PY	14425	2	Reserved word [old]
-- 11 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Jan 2011  MS      R8363	4       Remove InUse parameters
-- 15 Mar 2011  MS      R100485 5	Added brackets in check for file Part for deleting File Request
-- 01 Apr 2011  MS      R100502 6	Change Status of File Request      
-- 01 Nov 2011	ASH	R11460	7	Converted int CASEID column to nvarchar(11)
-- 11 Apr 2012	SF	R11164	8	Output new date time stamp and row key


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nMaxLocations		int
Declare @nCaseLocation		int
Declare @nRowCount		int
Declare @bIsRFIDSystem          bit
Declare @bIsMaintainFileReqHistory  bit


-- Initialise variables
Set @nErrorCode = 0

-- Assign MAXLOCATIONS site control to variable
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @nMaxLocations = COLINTEGER 
		from SITECONTROL 
		where CONTROLID = 'MAXLOCATIONS'"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@nMaxLocations	int			OUTPUT',
				  @nMaxLocations	= @nMaxLocations	OUTPUT
End

-- Site control RFID System
If @nErrorCode = 0
Begin
        Set @sSQLString = "SELECT @bIsRFIDSystem = COLBOOLEAN                        
                        FROM SITECONTROL
                        WHERE CONTROLID = 'RFID System'"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@bIsRFIDSystem		bit                     output',
			@bIsRFIDSystem		= @bIsRFIDSystem        output  
End

-- Site control Maintain File Request History System
If @nErrorCode = 0
Begin
        Set @sSQLString = "SELECT @bIsMaintainFileReqHistory = COLBOOLEAN                        
                        FROM SITECONTROL
                        WHERE CONTROLID = 'Maintain File Request History'"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@bIsMaintainFileReqHistory	bit                             output',
			@bIsMaintainFileReqHistory	= @bIsMaintainFileReqHistory    output  
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Insert into CASELOCATION
			      (
                                CASEID,
                                WHENMOVED,
                                FILEPARTID,
                                FILELOCATION,
                                BAYNO,
                                ISSUEDBY,                               
                                DATESCANNED
                              )
                              VALUES
                              (
                                @pnCaseKey,
                                @pdtWhenMoved,
                                @pnFilePartKey,
                                @pnFileLocationKey,
                                @psBayNo,
                                @pnMovedByKey,
                                @pdtDateScanned
                              )"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnCaseKey		int,
				@pdtWhenMoved		datetime,
				@pnFileLocationKey	int,
				@pnFilePartKey		smallint,
				@pnMovedByKey		int,
				@psBayNo		nvarchar(20),                               
				@pdtDateScanned		datetime',
				@pnCaseKey	 	= @pnCaseKey,
				@pdtWhenMoved	 	= @pdtWhenMoved,
				@pnFileLocationKey	= @pnFileLocationKey,
				@pnFilePartKey	 	= @pnFilePartKey,
				@pnMovedByKey	 	= @pnMovedByKey,
				@psBayNo	 	= @psBayNo,                                
				@pdtDateScanned	 	= @pdtDateScanned

	Set @nRowCount = @@rowcount
End

If @nErrorCode = 0 and @bIsRFIDSystem = 0
Begin
        If @bIsMaintainFileReqHistory = 0
Begin
        Set @sSQLString = "DELETE from FILEREQUEST
                                where CASEID = @pnCaseKey
                                and FILELOCATION =@pnFileLocationKey
                                and (FILEPARTID = @pnFilePartKey or (FILEPARTID is null and @pnFilePartKey is null))"
       
        exec @nErrorCode=sp_executesql @sSQLString,
                                N'@pnCaseKey		int,
                                @pnFileLocationKey	int,
                                @pnFilePartKey          int',
                                @pnCaseKey	 	= @pnCaseKey,
                                @pnFileLocationKey	= @pnFileLocationKey,
                                @pnFilePartKey          = @pnFilePartKey
                        
End
        Else 
        Begin
                Set @sSQLString = "UPDATE FILEREQUEST
                                        SET STATUS = 2
                                        where CASEID = @pnCaseKey
                                        and FILELOCATION =@pnFileLocationKey
                                        and (FILEPARTID = @pnFilePartKey or (FILEPARTID is null and @pnFilePartKey is null))"
               
                exec @nErrorCode=sp_executesql @sSQLString,
                                        N'@pnCaseKey		int,
                                        @pnFileLocationKey	int,
                                        @pnFilePartKey          int',
                                        @pnCaseKey	 	= @pnCaseKey,
                                        @pnFileLocationKey	= @pnFileLocationKey,
                                        @pnFilePartKey          = @pnFilePartKey
        End
End

-- If no concurrency error, @nMaxLocations is not null and > 0
-- do checking and deleting outdated CASELOCATION record 
	
IF @nRowCount <> 0 and @nMaxLocations > 0
Begin
	If @nErrorCode = 0
	Begin
		-- Count CASELOCATION records of a CASE
		Set @sSQLString = "
			Select	@nCaseLocation = count(*)
			from	CASELOCATION
			where	CASEID = @pnCaseKey"
		
		exec @nErrorCode=sp_executesql @sSQLString,
					      	N'
						@pnCaseKey		int,
						@nCaseLocation		int			OUTPUT',
						@pnCaseKey		= @pnCaseKey,
						@nCaseLocation		= @nCaseLocation	OUTPUT
	End
	
	If @nErrorCode = 0
	and @nCaseLocation > @nMaxLocations
	Begin
		Set @sSQLString = "
			Delete	CASELOCATION
			from	(Select top " + Cast(@nCaseLocation - @nMaxLocations as nvarchar(10)) + " WHENMOVED 
				 from CASELOCATION
				 where CASEID = @pnCaseKey
				 order by WHENMOVED) AS [OLD]
			where	CASELOCATION.CASEID = @pnCaseKey
			and	CASELOCATION.WHENMOVED = [OLD].WHENMOVED"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					      	N'
						@pnCaseKey		int,
						@nCaseLocation		int,
						@nMaxLocations		int',
						@pnCaseKey		= @pnCaseKey,
						@nCaseLocation		= @nCaseLocation,
						@nMaxLocations		= @nMaxLocations
	End
End

IF @nRowCount > 0 and @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@psRowKey = CAST(CASEID as nvarchar(11))+'^'+CONVERT(varchar,WHENMOVED,121), 
			@pdtLogDateTimeStamp = LOGDATETIMESTAMP
		from	CASELOCATION
		where	CASEID = @pnCaseKey
                and     FILELOCATION = @pnFileLocationKey
                and     WHENMOVED = @pdtWhenMoved
                
                Select @psRowKey as RowKey, @pdtLogDateTimeStamp as LOGDATETIMESTAMP
                "
		
	exec @nErrorCode=sp_executesql @sSQLString,
                N'
		  @pdtLogDateTimeStamp	datetime output,
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

Grant execute on dbo.csw_InsertFileLocation to public
GO