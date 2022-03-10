-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertTelecommunication									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertTelecommunication]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertTelecommunication.'
	Drop procedure [dbo].[naw_InsertTelecommunication]
End
Print '**** Creating Stored Procedure dbo.naw_InsertTelecommunication...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertTelecommunication
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnTelecomTypeKey		int		= null,
	@psIsd				nvarchar(5)	= null,
	@psAreaCode			nvarchar(5)	= null,
	@psTelecomNumber		nvarchar(100)	= null,
	@psExtension			nvarchar(5)	= null,
	@pnCarrierKey			int		= null,
	@pbIsReminderAddress		bit		= null,
	@pbIsTelecomTypeKeyInUse	bit		= 0,
	@pbIsIsdInUse			bit		= 0,
	@pbIsAreaCodeInUse		bit	 	= 0,
	@pbIsTelecomNumberInUse		bit	 	= 0,
	@pbIsExtensionInUse		bit	 	= 0,
	@pbIsCarrierKeyInUse		bit	 	= 0,
	@pbIsIsReminderAddressInUse	bit	 	= 0,
	@pnTelecomKey			int		OUTPUT
)
as
-- PROCEDURE:	naw_InsertTelecommunication
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Telecommunication.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 30 Mar 2006	SW	RFC3721	1	Procedure created
-- 22 Nov 2007	SW	RFC5967	2	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into TELECOMMUNICATION
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			TELECODE
			"

	-- Find out TelecomKey by ip_GetLastInternalCode
	exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'TELECOMMUNICATION',
			@pnLastInternalCode	= @pnTelecomKey OUTPUT

	If @nErrorCode = 0
	Begin
	
		Set @sValuesString = @sValuesString+CHAR(10)+"@pnTelecomKey"
	
		If @pbIsTelecomTypeKeyInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TELECOMTYPE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnTelecomTypeKey"
			Set @sComma = ","
		End
	
		If @pbIsIsdInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ISD"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psIsd"
			Set @sComma = ","
		End
	
		If @pbIsAreaCodeInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"AREACODE"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psAreaCode"
			Set @sComma = ","
		End
	
		If @pbIsTelecomNumberInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TELECOMNUMBER"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psTelecomNumber"
			Set @sComma = ","
		End
	
		If @pbIsExtensionInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXTENSION"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psExtension"
			Set @sComma = ","
		End
	
		If @pbIsCarrierKeyInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CARRIER"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnCarrierKey"
			Set @sComma = ","
		End
	
		If @pbIsIsReminderAddressInUse = 1
		Begin
			Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REMINDEREMAILS"
			Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbIsReminderAddress"
			Set @sComma = ","
		End
	
		Set @sInsertString = @sInsertString+CHAR(10)+")"
		Set @sValuesString = @sValuesString+CHAR(10)+")"
	
		Set @sSQLString = @sInsertString + @sValuesString
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnTelecomKey		int,
				@pnTelecomTypeKey	int,
				@psIsd			nvarchar(5),
				@psAreaCode		nvarchar(5),
				@psTelecomNumber	nvarchar(100),
				@psExtension		nvarchar(5),
				@pnCarrierKey		int,
				@pbIsReminderAddress	bit',
				@pnTelecomKey		= @pnTelecomKey,
				@pnTelecomTypeKey	= @pnTelecomTypeKey,
				@psIsd			= @psIsd,
				@psAreaCode		= @psAreaCode,
				@psTelecomNumber	= @psTelecomNumber,
				@psExtension		= @psExtension,
				@pnCarrierKey		= @pnCarrierKey,
				@pbIsReminderAddress	= @pbIsReminderAddress
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertTelecommunication to public
GO