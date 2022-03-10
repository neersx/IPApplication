-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteStaff									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteStaff]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteStaff.'
	Drop procedure [dbo].[naw_DeleteStaff]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteStaff...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteStaff
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnNameKey				int,		-- Mandatory
	@psOldAbbreviatedName			nvarchar(10)	= null,
	@pnOldStaffClassificationKey		int		= null,
	@psOldSignOffTitle			nvarchar(50)	= null,
	@psOldSignOffName			nvarchar(50)	= null,
	@pdtOldDateCommenced			datetime	= null,
	@pdtOldDateCeased			datetime	= null,
	@pnOldCapacityToSignKey			int		= null,
	@psOldProfitCentreCode			nvarchar(6)	= null,
	@pnOldDefaultPrinterKey			int		= null,
	@pbIsAbbreviatedNameInUse		bit		= 0,
	@pbIsStaffClassificationKeyInUse	bit		= 0,
	@pbIsSignOffTitleInUse			bit		= 0,
	@pbIsSignOffNameInUse			bit		= 0,
	@pbIsDateCommencedInUse			bit		= 0,
	@pbIsDateCeasedInUse			bit		= 0,
	@pbIsCapacityToSignKeyInUse		bit		= 0,
	@pbIsProfitCentreCodeInUse		bit		= 0,
	@pbIsDefaultPrinterKeyInUse		bit		= 0
)
as
-- PROCEDURE:	naw_DeleteStaff
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Staff if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 03 Apr 2006	AU	RFC3504	1	Procedure created
-- 15 Jun 2006	IB	RFC3978	2	Rename CapacityToSign to CapacityToSignKey.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from EMPLOYEE
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
				EMPLOYEENO = @pnNameKey and
				"

	If @pbIsAbbreviatedNameInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ABBREVIATEDNAME = @psOldAbbreviatedName"
		Set @sAnd = " and "
	End

	If @pbIsStaffClassificationKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"STAFFCLASS = @pnOldStaffClassificationKey"
		Set @sAnd = " and "
	End

	If @pbIsSignOffTitleInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"SIGNOFFTITLE = @psOldSignOffTitle"
		Set @sAnd = " and "
	End

	If @pbIsSignOffNameInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"SIGNOFFNAME = @psOldSignOffName"
		Set @sAnd = " and "
	End

	If @pbIsDateCommencedInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"STARTDATE = @pdtOldDateCommenced"
		Set @sAnd = " and "
	End

	If @pbIsDateCeasedInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ENDDATE = @pdtOldDateCeased"
		Set @sAnd = " and "
	End

	If @pbIsCapacityToSignKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CAPACITYTOSIGN = @pnOldCapacityToSignKey"
		Set @sAnd = " and "
	End

	If @pbIsProfitCentreCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PROFITCENTRECODE = @psOldProfitCentreCode"
		Set @sAnd = " and "
	End

	If @pbIsDefaultPrinterKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"RESOURCENO = @pnOldDefaultPrinterKey"
		Set @sAnd = " and "
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			N'
			@pnNameKey			int,
			@psOldAbbreviatedName		nvarchar(10),
			@pnOldStaffClassificationKey	int,
			@psOldSignOffTitle		nvarchar(50),
			@psOldSignOffName		nvarchar(50),
			@pdtOldDateCommenced		datetime,
			@pdtOldDateCeased		datetime,
			@pnOldCapacityToSignKey		int,
			@psOldProfitCentreCode		nvarchar(6),
			@pnOldDefaultPrinterKey		int',
			@pnNameKey	 		= @pnNameKey,
			@psOldAbbreviatedName	 	= @psOldAbbreviatedName,
			@pnOldStaffClassificationKey	= @pnOldStaffClassificationKey,
			@psOldSignOffTitle	 	= @psOldSignOffTitle,
			@psOldSignOffName		= @psOldSignOffName,
			@pdtOldDateCommenced	 	= @pdtOldDateCommenced,
			@pdtOldDateCeased	 	= @pdtOldDateCeased,
			@pnOldCapacityToSignKey	 	= @pnOldCapacityToSignKey,
			@psOldProfitCentreCode	 	= @psOldProfitCentreCode,
			@pnOldDefaultPrinterKey	 	= @pnOldDefaultPrinterKey


End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteStaff to public
GO