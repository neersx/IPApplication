-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_UpdateTransactionInfo
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_UpdateTransactionInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_UpdateTransactionInfo.'
	Drop procedure [dbo].[ip_UpdateTransactionInfo]
End
Print '**** Creating Stored Procedure dbo.ip_UpdateTransactionInfo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_UpdateTransactionInfo
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,	
	@pnLogTransactionKey		int,		-- Mandatory
	@pnSessionKey				int,		-- Mandatory
	@pnCaseKey					int =null, 
	@pnNameKey					int =null, 
	@pdtTransactionDate			datetime =null,
	@pnTransactionMessageKey	int =null, 
	@pnTransactionReasonKey		int =null,
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	ip_UpdateTransactionInfo
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update an existing transaction

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 2 Mar 2007	SF		RFC4618	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "
		Update TRANSACTIONINFO 
		set CASEID = @pnCaseKey, 
			NAMENO = @pnNameKey,
			SESSIONNO = @pnSessionKey, 
			TRANSACTIONDATE = ISNULL(@pdtTransactionDate, getdate()),
			TRANSACTIONMESSAGENO = @pnTransactionMessageKey,
			TRANSACTIONREASONNO = @pnTransactionReasonKey
		where LOGTRANSACTIONNO = @pnLogTransactionKey"

		exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnCaseKey					int,
				@pnNameKey					int,				
				@pnSessionKey				int,
				@pdtTransactionDate			datetime,
				@pnTransactionMessageKey	int,
				@pnTransactionReasonKey		int,
				@pnLogTransactionKey		int',
				@pnCaseKey					= @pnCaseKey,
				@pnNameKey					= @pnNameKey,
				@pnSessionKey	 			= @pnSessionKey,
				@pdtTransactionDate			= @pdtTransactionDate,
				@pnTransactionMessageKey	= @pnTransactionMessageKey,
				@pnTransactionReasonKey		= @pnTransactionReasonKey,
				@pnLogTransactionKey		= @pnLogTransactionKey
			
End

Return @nErrorCode
GO

Grant execute on dbo.ip_UpdateTransactionInfo to public
GO
