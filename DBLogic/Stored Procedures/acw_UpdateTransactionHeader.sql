-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_UpdateTransactionHeader									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_UpdateTransactionHeader]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_UpdateTransactionHeader.'
	Drop procedure [dbo].[acw_UpdateTransactionHeader]
End
Print '**** Creating Stored Procedure dbo.acw_UpdateTransactionHeader...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.acw_UpdateTransactionHeader
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnEntityNo		int,	-- Mandatory
	@pnTransNo		int,	-- Mandatory
	@pdtTransDate	datetime		 = null,
	@psBatchNo	nvarchar(10)		 = null,
	@pnEmployeeNo	int		 = null,
	--@psUserId	nvarchar(30)		 = null, -- defaults to system_user
	@pdtEntryDate	datetime		 = null,
	@pnSource	int		 = null,
	@pnTranStatus	smallint		 = null,
	@pnGLStatus	tinyint		 = null,
	@pnTranPostPeriod	int		 = null,
	@pdtTranPostDate	datetime		 = null,
	@pnIdentityId	int		 = null,
	@pdtLogDateTimeStamp	datetime	= null
)
as
-- PROCEDURE:	acw_UpdateTransactionHeader
-- VERSION:		1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update TransactionHeader if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Mar 2010	AT		RFC3605	1		Procedure created.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update TRANSACTIONHEADER
			   set USERID = system_user"

	Set @sWhereString = @sWhereString+CHAR(10)+"
		ENTITYNO = @pnEntityNo
		and	TRANSNO = @pnTransNo
		and LOGDATETIMESTAMP = @pdtLogDateTimeStamp"

	Set @sComma = ","

	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TRANSDATE = @pdtTransDate"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"BATCHNO = @psBatchNo"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EMPLOYEENO = @pnEmployeeNo"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ENTRYDATE = @pdtEntryDate"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SOURCE = @pnSource"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TRANSTATUS = @pnTranStatus"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"GLSTATUS = @pnGLStatus"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TRANPOSTPERIOD = @pnTranPostPeriod"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TRANPOSTDATE = @pdtTranPostDate"
	
	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"IDENTITYID = @pnIdentityId"

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnEntityNo		int,
			@pnTransNo		int,
			@pdtTransDate		datetime,
			@psBatchNo		nvarchar(10),
			@pnEmployeeNo		int,
			@pdtEntryDate		datetime,
			@pnSource		int,
			@pnTranStatus		smallint,
			@pnGLStatus		tinyint,
			@pnTranPostPeriod		int,
			@pdtTranPostDate		datetime,
			@pnIdentityId		int,
			@pdtLogDateTimeStamp	datetime',
			@pnEntityNo	 = @pnEntityNo,
			@pnTransNo	 = @pnTransNo,
			@pdtTransDate	 = @pdtTransDate,
			@psBatchNo	 = @psBatchNo,
			@pnEmployeeNo	 = @pnEmployeeNo,
			@pdtEntryDate	 = @pdtEntryDate,
			@pnSource	 = @pnSource,
			@pnTranStatus	 = @pnTranStatus,
			@pnGLStatus	 = @pnGLStatus,
			@pnTranPostPeriod	 = @pnTranPostPeriod,
			@pdtTranPostDate	 = @pdtTranPostDate,
			@pnIdentityId	 = @pnIdentityId,
			@pdtLogDateTimeStamp = @pdtLogDateTimeStamp
End

-- Publish new LOGDATETIMESTAMP
If (@nErrorCode = 0)
Begin
	Select @pnTransNo as 'TransNo',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from TRANSACTIONHEADER
	Where ENTITYNO = @pnEntityNo
	and TRANSNO = @pnTransNo
End

Return @nErrorCode
GO

Grant execute on dbo.acw_UpdateTransactionHeader to public
GO