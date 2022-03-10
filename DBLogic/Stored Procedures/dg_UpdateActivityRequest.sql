-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_UpdateActivityRequest
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dg_UpdateActivityRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dg_UpdateActivityRequest.'
	Drop procedure [dbo].[dg_UpdateActivityRequest]
End
Print '**** Creating Stored Procedure dbo.dg_UpdateActivityRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create	procedure dbo.dg_UpdateActivityRequest
	@psSQLUser		nvarchar(40),
	@pdtWhenRequested	datetime,
	@pnCaseID		int,
	@pnActivityID		int,
	@pnLetterNo		smallint	= null,
	@pnHoldFlag		decimal(1,0)	= null,
	@psFilename		nvarchar(254)	= null,
	@psSystemMessage	nvarchar(254)	= null,
	@pdtWhenOccurred	datetime	= null,
	@pbProcessed		bit		= null
AS
-- Procedure :	dg_UpdateActivityRequest
-- VERSION :	1
-- DESCRIPTION:	This stored procedure will update an ActivityRequest row
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 08 Aug 2011	PK	RFC10708	1	Initial creation

-- Declare variables
Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise
-- Prevent row counts
Set	NOCOUNT on
Set	CONCAT_NULL_YIELDS_NULL off
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Initialize internal variables
Set	@nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "
			Update ACTIVITYREQUEST
			Set 
				LETTERNO	= @pnLetterNo,
				HOLDFLAG	= @pnHoldFlag,
				FILENAME	= @psFilename,
				SYSTEMMESSAGE	= @psSystemMessage,
				WHENOCCURRED	= @pdtWhenOccurred,
				PROCESSED	= @pbProcessed
			Where ACTIVITYID = @pnActivityID
			"
			
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnActivityID		int,
			@pnLetterNo		smallint,
			@pnHoldFlag		decimal(1,0),
			@psFilename		nvarchar(254),
			@psSystemMessage	nvarchar(254),
			@pdtWhenOccurred	datetime,
			@pbProcessed		bit',
			@pnActivityID		= @pnActivityID,
			@pnLetterNo		= @pnLetterNo,
			@pnHoldFlag		= @pnHoldFlag,
			@psFilename		= @psFilename,
			@psSystemMessage	= @psSystemMessage,
			@pdtWhenOccurred	= @pdtWhenOccurred,
			@pbProcessed		= @pbProcessed

End

Return @nErrorCode
go

Grant execute on dbo.dg_UpdateActivityRequest to Public
go
