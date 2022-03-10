-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_InsertStatementFailureReason
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_InsertStatementFailureReason]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_InsertStatementFailureReason.'
	Drop procedure [dbo].[acw_InsertStatementFailureReason]
End
Print '**** Creating Stored Procedure dbo.acw_InsertStatementFailureReason...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_InsertStatementFailureReason
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,			
	@pnFilterID				int,	        -- Mandatory
	@pnDebtorNo				int,	        -- Mandatory
	@psFailureReason			nvarchar(1000) 	-- Mandatory
)
as
-- PROCEDURE:	acw_InsertStatementFailureReason
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to insert failure reason on running debtor statements
-- MODIFICATIONS :
-- Date		Who		Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 16 Jun 2014  DV		R35246	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
		Set @sSQLString = "Insert into STATEMENTFAILUREREASON (FILTERID, DEBTORNO, FAILUREREASON)
				   values (@pnFilterID, @pnDebtorNo, @psFailureReason)"	

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnFilterID			int,
						@pnDebtorNo			int,
						@psFailureReason		nvarchar(1000)',	
						@pnFilterID			= @pnFilterID,				
						@pnDebtorNo	 		= @pnDebtorNo,
						@psFailureReason	 	= @psFailureReason		

End

Return @nErrorCode
go

Grant exec on dbo.acw_InsertStatementFailureReason to Public
go