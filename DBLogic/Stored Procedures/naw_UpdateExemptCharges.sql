-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateExemptCharges
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateExemptCharges]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateExemptCharges.'
	Drop procedure [dbo].[naw_UpdateExemptCharges]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateExemptCharges...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateExemptCharges
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@pnRateNo			int,		-- Mandatory
	@psNotes			nvarchar(254)	= null,
	@pnOldRateNo			int,		-- Mandatory
	@psOldNotes			nvarchar(254)	= null,
	@pbIsRateNoInUse		bit	 	= 0,
	@pbIsNotesInUse			bit	 	= 0  
)
as
-- PROCEDURE:	naw_UpdateExemptCharges
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Name Exempt Charges if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Feb 2010	MS	RFC7281	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin

	Set @sUpdateString = "Update NAMEEXEMPTCHARGES set "
	
	Set @sWhereString = @sWhereString+CHAR(10)+"
		NAMENO = @pnNameKey"
		
	Set @sAnd = " and "
	
	If @pbIsRateNoInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RATENO = @pnRateNo"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"RATENO = @pnOldRateNo"
		Set @sComma = ","
	End
	
	If @pbIsNotesInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NOTES = @psNotes"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NOTES = @psOldNotes"
		Set @sComma = ","
	End
	
	Set @sSQLString = @sUpdateString + @sWhereString
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@pnRateNo		int,
			@psNotes		nvarchar(254),
			@pnOldRateNo		int,
			@psOldNotes		nvarchar(254)',
			@pnNameKey	 	= @pnNameKey,
			@pnRateNo	 	= @pnRateNo,
			@psNotes	 	= @psNotes,
			@pnOldRateNo		= @pnOldRateNo,
			@psOldNotes	 	= @psOldNotes
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateExemptCharges to public
GO
