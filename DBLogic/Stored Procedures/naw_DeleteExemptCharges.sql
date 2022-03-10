-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteExemptCharges
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteExemptCharges]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteExemptCharges.'
	Drop procedure [dbo].[naw_DeleteExemptCharges]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteExemptCharges...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteExemptCharges
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@pnRateNo			int,		-- Mandatory
	@psNotes			nvarchar(254)	= null,
	@pbIsNotesInUse			bit	 	= 0
)
as
-- PROCEDURE:	naw_DeleteExemptCharges
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Name Exempt Charges from NAMEEXEMPTCHARGES table.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Feb 2010	MS	RFC7281	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from NAMEEXEMPTCHARGES 
			where NAMENO = @pnNameKey 
			and RATENO = @pnRateNo" 

	Set @sAnd = " and "

	If @pbIsNotesInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"NOTES = @psNotes"
	End
			

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
				@pnNameKey	int,
				@pnRateNo	int,
				@psNotes	nvarchar(254)',
				@pnNameKey	 = @pnNameKey,
				@pnRateNo	 = @pnRateNo,
				@psNotes	 = @psNotes
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteExemptCharges to public
GO
