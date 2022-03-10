-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_ValidateBatchHeader
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_ValidateBatchHeader]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_ValidateBatchHeader.'
	Drop procedure [dbo].[ede_ValidateBatchHeader]
End
Print '**** Creating Stored Procedure dbo.ede_ValidateBatchHeader...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_ValidateBatchHeader
(
	@pnBatchNo		int
)
as
-- PROCEDURE:	ede_ValidateBatchHeader
-- VERSION:	13
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Validate the EDE header details in the EDE Batch tables.

-- MODIFICATIONS:
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 05 June 2006	AT	12296	1	Procedure created.
-- 18 July 2006	AT	12296	2	Shortened duplicate Sender ID Error message.
-- 19 July 2006 AT	12296	3	Fixed validation to check for NULLs. 
-- 11 Oct  2006 vql	12995	4	Write sender nameno.
-- 09 May 2007	DL	12320	5	allow importing batches with request type ‘AGENT RESPONSE’
-- 12 May 2008	PK	16378	6	Check that only one name alias exists with the sender details
-- 12 Mar 2009	DL	17018	7	Duplicate batch error message is not showing the Sender
-- 04 Jun 2010	MF	18703	8	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null.
-- 24 Jul 2012	MF	16184	9	Allow the data that has been retrieved from PTO Access to be imported into Inprotech by allowing
--					a RequestType of 'Extract Cases Response'.
-- 21 Aug 2014	AT	R37920	10	Only validate file name if IMPORTQUEUE row exists.
-- 09 Sep 2014	MF	R37922	11	Allow new RequestType of 'Case Import'
-- 02 Nov 2015	vql	R53910	12	Adjust formatted names logic (DR-15543).
-- 16 Aug 2017	MF	72191	13	Introduce new Request Type "Agent Input" .

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sSQLString nvarchar(4000)
Declare @nValidNameNo int
Declare @sRequestType nvarchar(50)
Declare @sErrorDesc nvarchar(128)
Declare @sSenderID nvarchar(50)
Declare @sSenderReqID nvarchar(254)
Declare @nSenderIDCount int
Declare @sSenderFileName nvarchar(128)
Declare @nCount int
Declare @sSender nvarchar(28)

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- Set the sender variables first.
	Set @sSQLString ="SELECT @sSenderID = SENDER, @sSenderReqID = SENDERREQUESTIDENTIFIER,
				@sSenderFileName = upper(SENDERFILENAME)
			from EDESENDERDETAILS ES
			WHERE ES.BATCHNO = @pnBatchNo"
	
	Exec @nErrorCode = sp_executesql @sSQLString,
				      N'@sSenderID		nvarchar(50)  OUTPUT,
					@sSenderReqID		nvarchar(254) OUTPUT,
					@sSenderFileName	nvarchar(128) OUTPUT,
					@pnBatchNo		int',
					@sSenderID		OUTPUT,
					@sSenderReqID		OUTPUT,
					@sSenderFileName	OUTPUT,
					@pnBatchNo=@pnBatchNo
End

If @nErrorCode = 0
Begin

	-- Check that it's a valid name.
	Set @sSQLString ="
	Select @nValidNameNo = N.NAMENO
	from NAMEALIAS N 
	join EDESENDERDETAILS ES ON (ES.SENDER = N.ALIAS)
	where ES.BATCHNO = @pnBatchNo
	and N.ALIASTYPE = '_E'
	and N.COUNTRYCODE  is null
	and N.PROPERTYTYPE is null"

	Exec @nErrorCode = sp_executesql @sSQLString,
				      N'@nValidNameNo		int OUTPUT,
					@pnBatchNo	int',
					@nValidNameNo	OUTPUT,
					@pnBatchNo	=@pnBatchNo

	-- Check that only one name alias exists with the sender details.
	Set @sSQLString ="
	Select @nCount = count(N.NAMENO)
	from NAMEALIAS N 
	join EDESENDERDETAILS ES ON (ES.SENDER = N.ALIAS)
	where ES.BATCHNO = @pnBatchNo
	and N.ALIASTYPE = '_E'
	and N.COUNTRYCODE  is null
	and N.PROPERTYTYPE is null"

	Exec @nErrorCode = sp_executesql @sSQLString,
				      N'@nCount		int OUTPUT,
					@pnBatchNo	int',
					@nCount		OUTPUT,
					@pnBatchNo	=@pnBatchNo

	If @nValidNameNo is null
	Begin
		-- Sender is not valid.
		DELETE FROM EDETRANSACTIONHEADER WHERE BATCHNO = @pnBatchNo
		Set @sErrorDesc = 'UNKNOWN SENDER: The Sender ''' + @sSenderID + ''' could not be mapped to a valid name alias.'
		RAISERROR(@sErrorDesc,16,1)
		Set @nErrorCode = 1
	End
	Else If @nCount > 1
	Begin
		-- More than one name alias with the same sender details.
		DELETE FROM EDETRANSACTIONHEADER WHERE BATCHNO = @pnBatchNo
		Set @sErrorDesc = 'SENDER ERROR: The Sender ''' + @sSenderID + ''' is mapped to more than one name alias.'
		RAISERROR(@sErrorDesc,16,1)
		Set @nErrorCode = 1
	End
	Else
	Begin
		Set @sSQLString ="
		Update EDESENDERDETAILS
		Set SENDERNAMENO = @nValidNameNo
		where BATCHNO = @pnBatchNo"
	
		Exec @nErrorCode = sp_executesql @sSQLString,
					      N'@nValidNameNo	int,
						@pnBatchNo	int',
						@nValidNameNo,
						@pnBatchNo	=@pnBatchNo
	End
End

If @nErrorCode = 0
Begin
	--Validate the Request Type. 
	Set @sSQLString = "SELECT @sRequestType = UPPER(SENDERREQUESTTYPE)
			FROM EDESENDERDETAILS
			WHERE BATCHNO = @pnBatchNo"

	Exec @nErrorCode = sp_executesql @sSQLString,
				      N'@sRequestType		nvarchar(50) OUTPUT,
					@pnBatchNo		int',
					@sRequestType OUTPUT,
					@pnBatchNo = @pnBatchNo

	If (@sRequestType != 'Data Input' 
	AND @sRequestType != 'Data Verification'
	AND @sRequestType != 'Agent Response'
	AND @sRequestType != 'Agent Input'
	AND @sRequestType != 'Case Import'	-- RFC37922
	and @sRequestType != 'Extract Cases Response') or @sRequestType is null
	Begin
		-- Request type unknown. Reject the batch.
		DELETE FROM EDETRANSACTIONHEADER WHERE BATCHNO = @pnBatchNo
		Set @sErrorDesc = 'Unknown Sender Request Type ''' + @sRequestType + '''.'
		RAISERROR(@sErrorDesc,16,1)
		Set @nErrorCode = 1
	End
End

If @nErrorCode = 0
Begin
	--Check that the sender's requestID is unique.
	Select @nSenderIDCount = count(*)
	FROM EDESENDERDETAILS
	WHERE SENDER = @sSenderID
	and  SENDERREQUESTIDENTIFIER = @sSenderReqID

	If @nSenderIDCount > 1
	Begin

		-- get the sender for displaying error message
		SELECT  DISTINCT @sSender = dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
		FROM EDETRANSACTIONHEADER TH   
		JOIN EDESENDERDETAILS SD ON (SD.BATCHNO = TH.BATCHNO) 
		JOIN NAMEALIAS NA ON (NA.ALIAS = SD.SENDER)
		JOIN NAME N ON (N.NAMENO = NA.NAMENO)
		WHERE TH.BATCHNO = @pnBatchNo
		and NA.ALIASTYPE = '_E'
		and NA.COUNTRYCODE  is null
		and NA.PROPERTYTYPE is null

		-- Duplicate Sender/SenderRequestIdentifier
		DELETE FROM EDETRANSACTIONHEADER WHERE BATCHNO = @pnBatchNo

		Set @sErrorDesc = 'Batch file from Sender ''' + @sSender + ''' with Sender Request Identifier, ''' + @sSenderReqID + ''' has already been processed.'
		RAISERROR(@sErrorDesc,16,1)

		Set @nErrorCode = 1
	End
End

If @nErrorCode = 0 and exists (select * from EDETRANSACTIONHEADER WHERE BATCHNO = @pnBatchNo and IMPORTQUEUENO IS NOT NULL)
Begin
	-- Check the File Name
	If NOT exists(
	SELECT 1
	FROM IMPORTQUEUE I
	JOIN EDETRANSACTIONHEADER T ON T.IMPORTQUEUENO = I.IMPORTQUEUENO
	JOIN EDESENDERDETAILS ES ON ES.BATCHNO = T.BATCHNO
					AND UPPER(I.IMPORTFILELOCATION) LIKE '%' + UPPER(ES.SENDERFILENAME)
	WHERE T.BATCHNO = @pnBatchNo
	AND UPPER(I.IMPORTFILELOCATION) LIKE '%' + @sSenderFileName
	)
	Begin
		-- File name inconsistent.
		DELETE FROM EDETRANSACTIONHEADER WHERE BATCHNO = @pnBatchNo
		Set @sErrorDesc = 'The file name ''' + @sSenderFileName + ''' specified by the sender does not match the actual file name.'
		RAISERROR(@sErrorDesc,16,1)
		Set @nErrorCode = 1
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ede_ValidateBatchHeader to public
GO
