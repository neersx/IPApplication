-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateStaff									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateStaff]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateStaff.'
	Drop procedure [dbo].[naw_UpdateStaff]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateStaff...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateStaff
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnNameKey				int,		-- Mandatory
	@psAbbreviatedName			nvarchar(10)	= null,
	@pnStaffClassificationKey		int		= null,
	@psSignOffTitle				nvarchar(50)	= null,
	@psSignOffName				nvarchar(50)	= null,
	@pdtDateCommenced			datetime	= null,
	@pdtDateCeased				datetime	= null,
	@pnCapacityToSignKey			int		= null,
	@psProfitCentreCode			nvarchar(6)	= null,
	@pnDefaultEntityKey				int		= null,
	@pnDefaultPrinterKey			int		= null,
	@psOldAbbreviatedName			nvarchar(10)	= null,
	@pnOldStaffClassificationKey		int		= null,
	@psOldSignOffTitle			nvarchar(50)	= null,
	@psOldSignOffName			nvarchar(50)	= null,
	@pdtOldDateCommenced			datetime	= null,
	@pdtOldDateCeased			datetime	= null,
	@pnOldCapacityToSignKey			int		= null,
	@psOldProfitCentreCode			nvarchar(6)	= null,
	@pnOldDefaultEntityKey			int		= null,
	@pnOldDefaultPrinterKey			int		= null,
	@pbIsAbbreviatedNameInUse		bit		= 0,
	@pbIsStaffClassificationKeyInUse	bit		= 0,
	@pbIsSignOffTitleInUse			bit		= 0,
	@pbIsSignOffNameInUse			bit		= 0,
	@pbIsDateCommencedInUse			bit		= 0,
	@pbIsDateCeasedInUse			bit		= 0,
	@pbIsCapacityToSignKeyInUse		bit		= 0,
	@pbIsProfitCentreCodeInUse		bit		= 0,
	@pbIsDefaultEntityKeyInUse		bit		= 0,
	@pbIsDefaultPrinterKeyInUse		bit		= 0
)
as
-- PROCEDURE:	naw_UpdateStaff
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Staff if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 03 Apr 2006	AU	RFC3504	1	Procedure created
-- 15 Jun 2006	IB	RFC3978	2	Rename CapacityToSign to CapacityToSignKey.
-- 13 Oct 2008	PA	RFC5866	3	To Update Staff Details with new field WIP Entity.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString	nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd		nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update EMPLOYEE
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
				EMPLOYEENO = @pnNameKey and
				"

	If @pbIsAbbreviatedNameInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ABBREVIATEDNAME = @psAbbreviatedName"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ABBREVIATEDNAME = @psOldAbbreviatedName"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsStaffClassificationKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STAFFCLASS = @pnStaffClassificationKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"STAFFCLASS = @pnOldStaffClassificationKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsSignOffTitleInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SIGNOFFTITLE = @psSignOffTitle"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"SIGNOFFTITLE = @psOldSignOffTitle"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsSignOffNameInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"SIGNOFFNAME = @psSignOffName"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"SIGNOFFNAME = @psOldSignOffName"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsDateCommencedInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STARTDATE = @pdtDateCommenced"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"STARTDATE = @pdtOldDateCommenced"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsDateCeasedInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ENDDATE = @pdtDateCeased"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ENDDATE = @pdtOldDateCeased"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsCapacityToSignKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CAPACITYTOSIGN = @pnCapacityToSignKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CAPACITYTOSIGN = @pnOldCapacityToSignKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsProfitCentreCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PROFITCENTRECODE = @psProfitCentreCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PROFITCENTRECODE = @psOldProfitCentreCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsDefaultEntityKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DEFAULTENTITYNO = @pnDefaultEntityKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"DEFAULTENTITYNO = @pnOldDefaultEntityKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End
	
	If @pbIsDefaultPrinterKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RESOURCENO = @pnDefaultPrinterKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"RESOURCENO = @pnOldDefaultPrinterKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey			int,
			@psAbbreviatedName		nvarchar(10),
			@pnStaffClassificationKey	int,
			@psSignOffTitle			nvarchar(50),
			@psSignOffName			nvarchar(50),
			@pdtDateCommenced		datetime,
			@pdtDateCeased			datetime,
			@pnCapacityToSignKey		int,
			@psProfitCentreCode		nvarchar(6),
			@pnDefaultEntityKey		int,
			@pnDefaultPrinterKey		int,
			@psOldAbbreviatedName		nvarchar(10),
			@pnOldStaffClassificationKey	int,
			@psOldSignOffTitle		nvarchar(50),
			@psOldSignOffName		nvarchar(50),
			@pdtOldDateCommenced		datetime,
			@pdtOldDateCeased		datetime,
			@pnOldCapacityToSignKey		int,
			@psOldProfitCentreCode		nvarchar(6),
			@pnOldDefaultEntityKey		int,
			@pnOldDefaultPrinterKey		int',
			@pnNameKey	 		= @pnNameKey,
			@psAbbreviatedName	 	= @psAbbreviatedName,
			@pnStaffClassificationKey	= @pnStaffClassificationKey,
			@psSignOffTitle	 		= @psSignOffTitle,
			@psSignOffName	 		= @psSignOffName,
			@pdtDateCommenced	 	= @pdtDateCommenced,
			@pdtDateCeased	 		= @pdtDateCeased,
			@pnCapacityToSignKey	 	= @pnCapacityToSignKey,
			@psProfitCentreCode	 	= @psProfitCentreCode,
			@pnDefaultEntityKey	 	= @pnDefaultEntityKey,
			@pnDefaultPrinterKey	 	= @pnDefaultPrinterKey,
			@psOldAbbreviatedName	 	= @psOldAbbreviatedName,
			@pnOldStaffClassificationKey	= @pnOldStaffClassificationKey,
			@psOldSignOffTitle	 	= @psOldSignOffTitle,
			@psOldSignOffName	 	= @psOldSignOffName,
			@pdtOldDateCommenced	 	= @pdtOldDateCommenced,
			@pdtOldDateCeased	 	= @pdtOldDateCeased,
			@pnOldCapacityToSignKey	 	= @pnOldCapacityToSignKey,
			@psOldProfitCentreCode	 	= @psOldProfitCentreCode,
			@pnOldDefaultEntityKey	 	= @pnOldDefaultEntityKey,
			@pnOldDefaultPrinterKey	 	= @pnOldDefaultPrinterKey


End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateStaff to public
GO