-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertExemptCharges
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertExemptCharges]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertExemptCharges.'
	Drop procedure [dbo].[naw_InsertExemptCharges]
End
Print '**** Creating Stored Procedure dbo.naw_InsertExemptCharges...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertExemptCharges
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@pnRateNo			int,		-- Mandatory
	@psNotes			nvarchar(254)	= null
)
as
-- PROCEDURE:	naw_InsertExemptCharges
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Name Exempt Charges.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Feb 2010	MS	RFC7281	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0


If @nErrorCode = 0
Begin
		Set @sSQLString = "Insert into NAMEEXEMPTCHARGES (NAMENO, RATENO, NOTES) 
				   values (@pnNameKey, @pnRateNo, @psNotes)" 
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey		int,
				@pnRateNo		int,
				@psNotes		nvarchar(254)',
				@pnNameKey	 	= @pnNameKey,
				@pnRateNo	 	= @pnRateNo,
				@psNotes	 	= @psNotes
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertExemptCharges to public
GO
