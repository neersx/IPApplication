-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertBackgroundProcess
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertBackgroundProcess]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertBackgroundProcess.'
	Drop procedure [dbo].[ipw_InsertBackgroundProcess]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertBackgroundProcess...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE [dbo].[ipw_InsertBackgroundProcess]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,	
	@psProcessType				nvarchar(50),	-- Mandatory
	@pnStatus				int,	        -- Mandatory
	@psUserIdentityKeys			nvarchar(400),	-- Mandatory	
	@psMessage				nvarchar(400),	-- Mandatory
	@pnProcessID				int = null	OUTPUT
)
as
-- PROCEDURE :	ipw_InsertBackgroundProcess
-- VERSION :	2
-- DESCRIPTION:	Procedure to insert message into the BACKGROUNDPROCESS table
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 27 Feb 2013	DV	RFC8016	1	Procedure created 
-- 17 Jun 2014	DV	R35246	2	Return @pnProcessID for the new inserted record.


Declare @nErrorCode		int

-- Initialise variables
Set @nErrorCode = 0
Declare @sSQLString nvarchar(4000)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
			Insert into BACKGROUNDPROCESS 
					(IDENTITYID,
					PROCESSTYPE,
					STATUS,
					STATUSDATE,
					STATUSINFO)
				SELECT 
					Parameter,
					@psProcessType,
					@pnStatus,
					getdate(),
					@psMessage
				FROM dbo.fn_Tokenise(@psUserIdentityKeys,',')"
				
	Set @sSQLString = @sSQLString + CHAR(10)
			+ "Set @pnProcessID = SCOPE_IDENTITY()"		

		
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psProcessType		nvarchar(50),
					@pnStatus			int,
					@psMessage			nvarchar(400),
					@psUserIdentityKeys		nvarchar(400),
					@pnProcessID			int OUTPUT',					
					@psProcessType	 		= @psProcessType,
					@pnStatus			= @pnStatus,
					@psMessage	 		= @psMessage,
					@psUserIdentityKeys		= @psUserIdentityKeys,
					@pnProcessID			= @pnProcessID OUTPUT		

End

Return @nErrorCode
GO

grant execute on dbo.ipw_InsertBackgroundProcess to public
GO


