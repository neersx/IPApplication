-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_GetReportParams
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dg_GetReportParams]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dg_GetReportParams.'
	Drop procedure [dbo].[dg_GetReportParams]
End
Print '**** Creating Stored Procedure dbo.dg_GetReportParams...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create	procedure dbo.dg_GetReportParams
	@pnLetterNo		int
AS
-- Procedure :	dg_GetReportParams
-- VERSION :	1
-- DESCRIPTION:	This stored procedure will return a set of  Activity Requests on the queue
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 29 July 2011	PK	RFC10708	1	Initial creation

-- Declare variables
Declare	@nErrorCode			int
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
		Select	rp.PARAMNAME as ParamName,
			rp.LETTERNO as LetterNo,
			rp.ITEM_ID as ItemID
		From	REPORTPARAM rp
		Where	rp.LETTERNO = @pnLetterNo
		"
		
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnLetterNo		int',
			@pnLetterNo		= @pnLetterNo

	Set @nErrorCode = @@error
End

Return @nErrorCode
go

Grant execute on dbo.dg_GetReportParams to Public
go
