-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertStaff									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertStaff]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertStaff.'
	Drop procedure [dbo].[naw_InsertStaff]
End
Print '**** Creating Stored Procedure dbo.naw_InsertStaff...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertStaff
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnNameKey				int,		-- Mandatory.
	@psAbbreviatedName			nvarchar(10)	= null,
	@pnStaffClassificationKey		int		= null,
	@psSignOffTitle				nvarchar(50)	= null,
	@psSignOffName				nvarchar(50)	= null,
	@pdtDateCommenced			datetime	= null,
	@pdtDateCeased				datetime	= null,
	@pnCapacityToSignKey			int		= null,
	@psProfitCentreCode			nvarchar(6)	= null,
	@pnDefaultEntityKey			int		= null,
	@pnDefaultPrinterKey			int		= null,
	@pbIsAbbreviatedNameInUse		bit	 	= 0,
	@pbIsStaffClassificationKeyInUse	bit	 	= 0,
	@pbIsSignOffTitleInUse			bit		= 0,
	@pbIsSignOffNameInUse			bit	 	= 0,
	@pbIsDateCommencedInUse			bit	 	= 0,
	@pbIsDateCeasedInUse			bit	 	= 0,
	@pbIsCapacityToSignKeyInUse		bit	 	= 0,
	@pbIsProfitCentreCodeInUse		bit	 	= 0,
	@pbIsDefaultEntityKeyInUse		bit	 	= 0,
	@pbIsDefaultPrinterKeyInUse		bit	 	= 0
)
as
-- PROCEDURE:	naw_InsertStaff
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Staff.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 03 Apr 2006	AU	RFC3504	1	Procedure created
-- 15 Jun 2006	IB	RFC3978	2	Rename CapacityToSign to CapacityToSignKey.
-- 13 Oct 2008	PA	RFC5866	3	To Insert new Field WIP Entity for Staff Member.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString	nvarchar(4000)
Declare @sComma		nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into EMPLOYEE
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			EMPLOYEENO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
			@pnNameKey
			"

	If @pbIsAbbreviatedNameInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ABBREVIATEDNAME"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psAbbreviatedName"
		Set @sComma = ","
	End

	If @pbIsStaffClassificationKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STAFFCLASS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnStaffClassificationKey"
		Set @sComma = ","
	End

	If @pbIsSignOffTitleInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SIGNOFFTITLE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psSignOffTitle"
		Set @sComma = ","
	End

	If @pbIsSignOffNameInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SIGNOFFNAME"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psSignOffName"
		Set @sComma = ","
	End

	If @pbIsDateCommencedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STARTDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtDateCommenced"
		Set @sComma = ","
	End

	If @pbIsDateCeasedInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ENDDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtDateCeased"
		Set @sComma = ","
	End

	If @pbIsCapacityToSignKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CAPACITYTOSIGN"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCapacityToSignKey"
		Set @sComma = ","
	End

	If @pbIsProfitCentreCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PROFITCENTRECODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psProfitCentreCode"
		Set @sComma = ","
	End

	If @pbIsDefaultEntityKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"DEFAULTENTITYNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDefaultEntityKey"
		Set @sComma = ","
	End
	
	If @pbIsDefaultPrinterKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"RESOURCENO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnDefaultPrinterKey"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

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
			@pnDefaultPrinterKey		int',
			@pnNameKey	 		= @pnNameKey,
			@psAbbreviatedName	 	= @psAbbreviatedName,
			@pnStaffClassificationKey	= @pnStaffClassificationKey,
			@psSignOffTitle	 		= @psSignOffTitle,
			@psSignOffName	 		= @psSignOffName,
			@pdtDateCommenced	 	= @pdtDateCommenced,
			@pdtDateCeased	 		= @pdtDateCeased,
			@pnCapacityToSignKey		= @pnCapacityToSignKey,
			@psProfitCentreCode		= @psProfitCentreCode,
			@pnDefaultEntityKey	 	= @pnDefaultEntityKey,			
			@pnDefaultPrinterKey	 	= @pnDefaultPrinterKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertStaff to public
GO