-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_AcquireDailySession
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_AcquireDailySession]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_AcquireDailySession.'
	Drop procedure [dbo].[ip_AcquireDailySession]
End
Print '**** Creating Stored Procedure dbo.ip_AcquireDailySession...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_AcquireDailySession
(
	@pnUserIdentityId			int,			-- Mandatory
	@psProgram					nvarchar(50)
)
as
-- PROCEDURE:	ip_AcquireDailySession
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	------		----------------------------------------------- 
-- 25 JAN 2013	SF		R100593		1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @nSessionId		int
declare @nDailySessionKey	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Get Session
If @nErrorCode = 0
Begin

	Set @sSQLString = "	
	select	@nDailySessionKey = max(S1.SESSIONNO)
	from	[SESSION] S1
	where	S1.IDENTITYID = @pnUserIdentityId
	and		S1.PROGRAM = @psProgram
	and		convert( nvarchar, getdate( ), 103) = convert( nvarchar, S1.STARTDATE, 103 )"
	
	Exec @nErrorCode=sp_executesql @sSQLString,
		      N'@nDailySessionKey			int OUTPUT,
				@psProgram					nvarchar(50),
				@pnUserIdentityId			int',
				@nDailySessionKey			= @nDailySessionKey OUTPUT,
				@psProgram					= @psProgram,
				@pnUserIdentityId	 		= @pnUserIdentityId
End


If @nErrorCode = 0 and @nDailySessionKey is null
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
	
		Set @nDailySessionKey = SCOPE_IDENTITY()"

		exec @nErrorCode=sp_executesql @sSQLString,
		      N'@nDailySessionKey			int OUTPUT,
				@pnUserIdentityId		int,
				@psProgram				nvarchar(50),
				@nSessionId				int',
				@nDailySessionKey	 	= @nDailySessionKey OUTPUT,
				@pnUserIdentityId		= @pnUserIdentityId,				
				@psProgram				= @psProgram,
				@nSessionId				= @nSessionId
	End	
End

If @nErrorCode = 0
Begin
	Select @nDailySessionKey
End

Return @nErrorCode
GO

Grant execute on dbo.ip_AcquireDailySession to public
GO
