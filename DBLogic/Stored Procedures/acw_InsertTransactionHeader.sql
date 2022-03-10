-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_InsertTransactionHeader									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_InsertTransactionHeader]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_InsertTransactionHeader.'
	Drop procedure [dbo].[acw_InsertTransactionHeader]
End
Print '**** Creating Stored Procedure dbo.acw_InsertTransactionHeader...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_InsertTransactionHeader
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnTransNo					int OUTPUT,	-- Mandatory
	@pnEntityNo					int,		-- Mandatory
	@pdtTransDate				datetime,	-- Mandtaory
	@pnTransType				smallint,	-- Mandatory
	@psBatchNo					nvarchar(10)	= null,
	@pnEmployeeNo				int				= null,
	--@psUserId					nvarchar(30)	= null,
	@pdtEntryDate				datetime		= null,
	@pnSource					int				= null,
	@pnTranStatus				smallint		= null,
	@pnGLStatus					tinyint			= null,
	@pnTranPostPeriod			int				= null,
	@pdtTranPostDate			datetime		= null,
	@pnIdentityId				int				= null
)
as
-- PROCEDURE:	acw_InsertTransactionHeader
-- VERSION:		1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert TransactionHeader.

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	------		-------	-----------------------------------------------
-- 16 Nov 2009	AT		RFC3605		1		Procedure created.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma				nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into TRANSACTIONHEADER
				("

	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
						ENTITYNO, TRANSNO, TRANSDATE, TRANSTYPE
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
						@pnEntityNo, @pnTransNo, @pdtTransDate, @pnTransType
			"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"BATCHNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psBatchNo"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EMPLOYEENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnEmployeeNo"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"USERID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"system_user"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ENTRYDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtEntryDate"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SOURCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnSource"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TRANSTATUS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnTranStatus"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"GLSTATUS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnGLStatus"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TRANPOSTPERIOD"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnTranPostPeriod"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TRANPOSTDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtTranPostDate"

		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"IDENTITYID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnIdentityId"


	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	-- Get the next TransNo
	Exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'TRANSACTIONHEADER',
			@pnLastInternalCode	= @pnTransNo OUTPUT

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnEntityNo		int,
			@pnTransNo		int,
			@pdtTransDate		datetime,
			@pnTransType		smallint,
			@psBatchNo		nvarchar(10),
			@pnEmployeeNo		int,
			@pdtEntryDate		datetime,
			@pnSource		int,
			@pnTranStatus		smallint,
			@pnGLStatus		tinyint,
			@pnTranPostPeriod		int,
			@pdtTranPostDate		datetime,
			@pnIdentityId		int',
			@pnEntityNo	 = @pnEntityNo,
			@pnTransNo		= @pnTransNo,
			@pdtTransDate	 = @pdtTransDate,
			@pnTransType	 = @pnTransType,
			@psBatchNo	 = @psBatchNo,
			@pnEmployeeNo	 = @pnEmployeeNo,
			@pdtEntryDate	 = @pdtEntryDate,
			@pnSource	 = @pnSource,
			@pnTranStatus	 = @pnTranStatus,
			@pnGLStatus	 = @pnGLStatus,
			@pnTranPostPeriod	 = @pnTranPostPeriod,
			@pdtTranPostDate	 = @pdtTranPostDate,
			@pnIdentityId	 = @pnIdentityId

			-- Publish TransNo
			If @nErrorCode = 0
			Begin
				Select @pnTransNo as 'TransNo',
				LOGDATETIMESTAMP as 'LogDateTimeStamp'
				from TRANSACTIONHEADER
				Where ENTITYNO = @pnEntityNo
				and TRANSNO = @pnTransNo
			End
End

Return @nErrorCode
GO

Grant execute on dbo.acw_InsertTransactionHeader to public
GO