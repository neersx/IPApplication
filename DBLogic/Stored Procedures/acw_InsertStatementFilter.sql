-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_InsertStatementFilter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_InsertStatementFilter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_InsertStatementFilter.'
	Drop procedure [dbo].[acw_InsertStatementFilter]
End
Print '**** Creating Stored Procedure dbo.acw_InsertStatementFilter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_InsertStatementFilter
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,	
	@pnFilterKey				int             = null OUTPUT,		
	@pnProcessID				int,	        -- Mandatory
	@pnPeriod				int             = null,			
	@pnEntityNo				int,	        -- Mandatory
	@pnSortBy				int	        = 0,	
	@pbPrintPositiveBal			bit	        = 0,
	@pbPrintNegativeBal			bit	        = 0,
	@pbPrintZeroBal				bit	        = 0,
	@pbPrintZeroBalWOAct			bit	        = 0
)
as
-- PROCEDURE:	acw_InsertStatementFilter
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to insert Statement Filter for re running the failed debtor statements
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
		Set @sSQLString = "Insert into STATEMENTFILTER (PROCESSID, PERIOD, ENTITYNO,
					SORTBY, PRINTPOSITIVEBAL, PRINTNEGATIVEBAL, 
					PRINTZEROBAL,PRINTZEROBALWOACT)
				   values (@pnProcessID, @pnPeriod, @pnEntityNo,
					@pnSortBy, @pbPrintPositiveBal, @pbPrintNegativeBal,
					@pbPrintZeroBal, @pbPrintZeroBalWOAct)"
		
		Set @sSQLString = @sSQLString + CHAR(10)
				 + "Set @pnFilterKey = SCOPE_IDENTITY()"		

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnFilterKey			int OUTPUT,
						@pnProcessID			int,
						@pnPeriod			int,
						@pnEntityNo			int,
						@pnSortBy			int,
						@pbPrintPositiveBal		bit,
						@pbPrintNegativeBal		bit,
						@pbPrintZeroBal			bit,
						@pbPrintZeroBalWOAct		bit',	
						@pnFilterKey			= @pnFilterKey	OUTPUT,				
						@pnProcessID	 		= @pnProcessID,
						@pnPeriod	 		= @pnPeriod,
						@pnEntityNo			= @pnEntityNo,
						@pnSortBy			= @pnSortBy,
						@pbPrintPositiveBal		= @pbPrintPositiveBal,
						@pbPrintNegativeBal		= @pbPrintNegativeBal,
						@pbPrintZeroBal			= @pbPrintZeroBal,
						@pbPrintZeroBalWOAct		= @pbPrintZeroBalWOAct							

End

Return @nErrorCode
go

Grant exec on dbo.acw_InsertStatementFilter to Public
go