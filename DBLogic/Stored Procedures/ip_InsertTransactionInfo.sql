-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_InsertTransactionInfo
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InsertTransactionInfo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_InsertTransactionInfo.'
	Drop procedure [dbo].[ip_InsertTransactionInfo]
End
Print '**** Creating Stored Procedure dbo.ip_InsertTransactionInfo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_InsertTransactionInfo
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@psProgram					nvarchar(50),	-- Mandatory
	@pnSessionKey				int = null output,	-- generated if necessary
	@pnLogTransactionKey		int = null output,
	@pnCaseKey					int = null, 
	@pnNameKey					int = null, 
	@pdtTransactionDate			datetime = null,	-- set the server time if null
	@pnTransactionMessageKey	int = null, 
	@pnTransactionReasonKey		int = null,
	@pbCalledFromCentura		bit	= 0
)
as
-- PROCEDURE:	ip_InsertTransactionInfo
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Add a transaction to a session.  If session is created if not provided.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 2 Mar 2007	SF		RFC4618	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @nSessionId		int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Get Session
If @nErrorCode = 0 and @pnSessionKey is null
Begin
	
	set @sSQLString = "		
	Select 	@nSessionId = ISNULL(max(SESSIONIDENTIFIER),0) + 1                           
	from 	SESSION 
	where 	convert( nvarchar, getdate( ), 103) = convert( nvarchar, STARTDATE, 103 )"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@nSessionId			int OUTPUT',
				@nSessionId	 		= @nSessionId OUTPUT
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Insert into SESSION (IDENTITYID, PROGRAM, SESSIONIDENTIFIER, STARTDATE) 
		values (@pnUserIdentityId, 
			@psProgram, 
			@nSessionId, 
			cast(convert( nvarchar, getdate( ), 112) as datetime))
	
		Set @pnSessionKey = SCOPE_IDENTITY()"

		exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnSessionKey			int OUTPUT,
				@pnUserIdentityId		int,
				@psProgram				nvarchar(50),
				@nSessionId				int',
				@pnSessionKey	 		= @pnSessionKey OUTPUT,
				@pnUserIdentityId		= @pnUserIdentityId,				
				@psProgram				= @psProgram,
				@nSessionId				= @nSessionId
				
				
	End	

End

If @nErrorCode = 0
Begin

	Set @sSQLString = "
		Insert into TRANSACTIONINFO (CASEID, NAMENO, SESSIONNO, TRANSACTIONDATE, TRANSACTIONMESSAGENO, TRANSACTIONREASONNO) 
		values (@pnCaseKey, 
			@pnNameKey, 
			@pnSessionKey, 
			getdate( ),
			@pnTransactionMessageKey,
			@pnTransactionReasonKey
			)
	
		Set @pnLogTransactionKey = SCOPE_IDENTITY()"

		exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnLogTransactionKey		int OUTPUT,
				@pnCaseKey					int,
				@pnNameKey					int,				
				@pnSessionKey				int,
				@pnTransactionMessageKey	int,
				@pnTransactionReasonKey		int',
				@pnLogTransactionKey		= @pnLogTransactionKey OUTPUT,
				@pnCaseKey					= @pnCaseKey,
				@pnNameKey					= @pnNameKey,
				@pnSessionKey	 			= @pnSessionKey,
				@pnTransactionMessageKey	= @pnTransactionMessageKey,
				@pnTransactionReasonKey		= @pnTransactionReasonKey
				
			
End
Return @nErrorCode
GO

Grant execute on dbo.ip_InsertTransactionInfo to public
GO
