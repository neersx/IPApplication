-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertNameTelecom									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertNameTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertNameTelecom.'
	Drop procedure [dbo].[naw_InsertNameTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_InsertNameTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertNameTelecom
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory.
	@pnTelecomKey			int		= null output,
	@psTelecomNotes			nvarchar(254)	= null,
	@pbIsOwner			bit		= null,
	@pnTelecomTypeKey		int		= null,
	@psIsd				nvarchar(5)	= null,
	@psAreaCode			nvarchar(5)	= null,
	@psTelecomNumber		nvarchar(100)	= null,
	@psExtension			nvarchar(5)	= null,
	@pnCarrierKey			int		= null,
	@pbIsReminderAddress		bit		= null,
	@pbIsTelecomNotesInUse		bit		= 0,
	@pbIsIsOwnerInUse		bit		= 0,
	@pbIsTelecomTypeKeyInUse	bit		= 0,
	@pbIsIsdInUse			bit		= 0,
	@pbIsAreaCodeInUse		bit		= 0,
	@pbIsTelecomNumberInUse		bit		= 0,
	@pbIsExtensionInUse		bit		= 0,
	@pbIsCarrierKeyInUse		bit		= 0,
	@pbIsIsReminderAddressInUse	bit		= 0
)
as
-- PROCEDURE:	naw_InsertNameTelecom
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert NameTelecom.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 31 Mar 2006	SW	RFC3721	1	Procedure created
-- 05 May 2006	PG	RFC3721	2	Return @pnTelecomKey as output
-- 30 May 2006	JEK	RFC3907	3	Do not publish TelecomKey.
-- 22 Nov 2007	SW	RFC5967	4	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 25 Mar 2008	Ash	RFC5438	5	Maintain data in different culture
-- 15 Apr 2008	SF	RFC6454	6	Backout changes made in RFC5438 temporarily
-- 05 Oct 2010	ASH	RFC9510	7	If telecom is linked to other name, Set @pbIsOwner =0 for new telecom owner.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sDBCulture		nvarchar(10)
Declare @pbIsLinkedTelecom      bit
-- Initialise variables
Set @pbIsLinkedTelecom = 0
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

-- if @pnTelecomKey not supplied, get one.
If @nErrorCode = 0 and @pnTelecomKey is null
Begin

	exec @nErrorCode = dbo.naw_InsertTelecommunication
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pnTelecomKey			= @pnTelecomKey OUTPUT,
		@pbCalledFromCentura		= @pbCalledFromCentura,

		@pnTelecomTypeKey		= @pnTelecomTypeKey,
		@psIsd				= @psIsd,
		@psAreaCode			= @psAreaCode,
		@psTelecomNumber		= @psTelecomNumber,
		@psExtension			= @psExtension,
		@pnCarrierKey			= @pnCarrierKey,
		@pbIsReminderAddress		= @pbIsReminderAddress,

		@pbIsTelecomTypeKeyInUse	= @pbIsTelecomTypeKeyInUse,
		@pbIsIsdInUse			= @pbIsTelecomTypeKeyInUse,
		@pbIsAreaCodeInUse		= @pbIsAreaCodeInUse,
		@pbIsTelecomNumberInUse		= @pbIsTelecomNumberInUse,
		@pbIsExtensionInUse		= @pbIsExtensionInUse,
		@pbIsCarrierKeyInUse		= @pbIsCarrierKeyInUse,
		@pbIsIsReminderAddressInUse	= @pbIsIsReminderAddressInUse

End

if @nErrorCode = 0 and @pnTelecomKey is not null
Begin
	Set @sSQLString= "Select @pbIsLinkedTelecom = OWNEDBY from NAMETELECOM where TELECODE=@pnTelecomKey and OWNEDBY =1"
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnTelecomKey 	int,
			  @pbIsLinkedTelecom    bit OUTPUT',
			  @pnTelecomKey		= @pnTelecomKey,
			  @pbIsLinkedTelecom	= @pbIsLinkedTelecom OUTPUT
End

If @nErrorCode = 0 and @pbIsLinkedTelecom =1
Begin
	Set @pbIsOwner = 0
End

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into NAMETELECOM
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
				NAMENO,TELECODE
				"

	Set @sValuesString = @sValuesString+CHAR(10)+"
				@pnNameKey,@pnTelecomKey
				"

	If @pbIsTelecomNotesInUse = 1 
	-- Only insert to base table if culture matches
	--and @psCulture = @sDBCulture
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TELECOMDESC"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psTelecomNotes"
		Set @sComma = ","
	End

	If @pbIsIsOwnerInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"OWNEDBY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbIsOwner"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@pnTelecomKey		int,
			@psTelecomNotes		nvarchar(254),
			@pbIsOwner		bit',
			@pnNameKey	 = @pnNameKey,
			@pnTelecomKey	 = @pnTelecomKey,
			@psTelecomNotes	 = @psTelecomNotes,
			@pbIsOwner	 = @pbIsOwner
End

	-- If culture doesn't match the database main culture, we need to maintain the translated data.
	/*
	If @nErrorCode = 0
	and @psCulture <> @sDBCulture
	Begin

		Set @sSQLString = "
			Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT)
			select TELECOMDESC_TID, @psCulture, @psTelecomNotes
			from NAMETELECOM
			where NAMENO=@pnNameKey and TELECODE=@pnTelecomKey "

		exec @nErrorCode=sp_executesql @sSQLString,
					N'
					@pnNameKey		int,
					@pnTelecomKey   int,
					@psCulture		nvarchar(10),
					@psTelecomNotes		nvarchar(254)',
					@pnNameKey		= @pnNameKey,
					@psCulture		= @psCulture,
					@pnTelecomKey	=@pnTelecomKey,
					@psTelecomNotes= @psTelecomNotes
	End
	*/

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertNameTelecom to public
GO
