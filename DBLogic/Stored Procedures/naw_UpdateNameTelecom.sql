-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateNameTelecom									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateNameTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateNameTelecom.'
	Drop procedure [dbo].[naw_UpdateNameTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateNameTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateNameTelecom
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory

	@pnTelecomKey			int		output, -- Mandatory
	@psTelecomNotes			nvarchar(254)	= null,
	@pbIsOwner			bit		= null,
	@pbIsLinked			bit		= null,
	@pnTelecomTypeKey		int		= null,
	@psIsd				nvarchar(5)	= null,
	@psAreaCode			nvarchar(5)	= null,
	@psTelecomNumber		nvarchar(100)	= null,
	@psExtension			nvarchar(5)	= null,
	@pnCarrierKey			int		= null,
	@pbIsReminderAddress		bit		= null,
	
	@pnOldTelecomKey		int,		-- Mandatory
	@psOldTelecomNotes		nvarchar(254)	= null,
	@pbOldIsOwner			bit		= null,
	@pbOldIsLinked			bit		= null,
	@pnOldTelecomTypeKey		int		= null,
	@psOldIsd			nvarchar(5)	= null,
	@psOldAreaCode			nvarchar(5)	= null,
	@psOldTelecomNumber		nvarchar(100)	= null,
	@psOldExtension			nvarchar(5)	= null,
	@pnOldCarrierKey		int		= null,
	@pbOldIsReminderAddress		bit		= null,

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
-- PROCEDURE:	naw_UpdateNameTelecom
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update NameTelecom if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 31 Mar 2006	SW	RFC3721	1	Procedure created
-- 31 May 200	JEK	RFC3907	2	When a telecom becomes unlinked, insert not being performed.
--					Procedure can generate a telecom key.  It needs to be returned.
--					Should be passing @pnOldTelecomKey to delete.
-- 22 Nov 2007	SW	RFC5967	3	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nRowCount = 1 -- anything not zero
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "
Set @sAnd = " and "

-- Delete NAMETELECOM for old value
If (@nErrorCode = 0
and @pbOldIsLinked = 1
and @pbIsLinked = 0
and @pbOldIsOwner = 0)
Begin
	exec @nErrorCode = dbo.naw_DeleteNameTelecom
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura		= @pbCalledFromCentura,
		@pnNameKey			= @pnNameKey,
		@pnTelecomKey			= @pnOldTelecomKey,
	
		@psOldTelecomNotes		= @psOldTelecomNotes, 
		@pbOldIsOwner			= @pbOldIsOwner,
		@pnOldTelecomTypeKey		= @pnOldTelecomTypeKey,
		@psOldIsd			= @psOldIsd,
		@psOldAreaCode			= @psOldAreaCode,
		@psOldTelecomNumber		= @psOldTelecomNumber,
		@psOldExtension			= @psOldExtension,
		@pnOldCarrierKey		= @pnOldCarrierKey,
		@pbOldIsReminderAddress		= @pbOldIsReminderAddress,
	
		@pbIsTelecomNotesInUse		= @pbIsTelecomNotesInUse, 
		@pbIsIsOwnerInUse		= @pbIsIsOwnerInUse, 
		@pbIsTelecomTypeKeyInUse	= @pbIsTelecomTypeKeyInUse,
		@pbIsIsdInUse			= @pbIsIsdInUse,
		@pbIsAreaCodeInUse		= @pbIsAreaCodeInUse,
		@pbIsTelecomNumberInUse		= @pbIsTelecomNumberInUse,
		@pbIsExtensionInUse		= @pbIsExtensionInUse,
		@pbIsCarrierKeyInUse		= @pbIsCarrierKeyInUse,
		@pbIsIsReminderAddressInUse	= @pbIsIsReminderAddressInUse

	Set @nRowCount = @@rowcount
End
-- Insert NAMETELECOM for current value
If (@nErrorCode = 0
and @nRowCount <> 0
and @pbOldIsLinked = 1
and @pbIsLinked = 0)
Begin

	exec @nErrorCode = dbo.naw_InsertNameTelecom
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura		= @pbCalledFromCentura,
		@pnNameKey			= @pnNameKey,
		@pnTelecomKey			= @pnTelecomKey output,
	
		@psTelecomNotes			= @psTelecomNotes, 
		@pbIsOwner			= @pbIsOwner,
		@pnTelecomTypeKey		= @pnTelecomTypeKey,
		@psIsd				= @psIsd,
		@psAreaCode			= @psAreaCode,
		@psTelecomNumber		= @psTelecomNumber,
		@psExtension			= @psExtension,
		@pnCarrierKey			= @pnCarrierKey,
		@pbIsReminderAddress		= @pbIsReminderAddress,
	
		@pbIsTelecomNotesInUse		= @pbIsTelecomNotesInUse, 
		@pbIsIsOwnerInUse		= @pbIsIsOwnerInUse, 
		@pbIsTelecomTypeKeyInUse	= @pbIsTelecomTypeKeyInUse,
		@pbIsIsdInUse			= @pbIsIsdInUse,
		@pbIsAreaCodeInUse		= @pbIsAreaCodeInUse,
		@pbIsTelecomNumberInUse		= @pbIsTelecomNumberInUse,
		@pbIsExtensionInUse		= @pbIsExtensionInUse,
		@pbIsCarrierKeyInUse		= @pbIsCarrierKeyInUse,
		@pbIsIsReminderAddressInUse	= @pbIsIsReminderAddressInUse

	Set @nRowCount = @@rowcount
End

-- Check if update is required
If (@nErrorCode = 0
and @nRowCount <> 0
and @pbIsLinked = @pbOldIsLinked 
and @pbIsOwner = 1 
and @pnTelecomKey = @pnOldTelecomKey)
Begin

	/* If any of the following have changed:
	   TelecomTypeKey
	   Isd
	   AreaCode
	   TelecomNumber
	   Extension
	   CarrierKey
	   IsReminderAddress
	   then update TELECOMMUNICATION
	*/
	If ( (@pbIsTelecomTypeKeyInUse = 1 and @pnTelecomTypeKey <> @pnOldTelecomTypeKey)
	  or (@pbIsIsdInUse = 1 and @psIsd <> @psOldIsd)
	  or (@pbIsAreaCodeInUse = 1 and @psAreaCode <> @psOldAreaCode)
	  or (@pbIsTelecomNumberInUse = 1 and @psTelecomNumber <> @psOldTelecomNumber)
	  or (@pbIsExtensionInUse = 1 and @psExtension <> @psOldExtension)
	  or (@pbIsCarrierKeyInUse = 1 and @pnCarrierKey <> @pnOldCarrierKey)
	  or (@pbIsIsReminderAddressInUse = 1 and @pbIsReminderAddress <> @pbOldIsReminderAddress))
	Begin
		exec @nErrorCode = dbo.naw_UpdateTelecommunication
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= @pbCalledFromCentura,
			@pnTelecomKey			= @pnTelecomKey,
	
			@pnTelecomTypeKey		= @pnTelecomTypeKey,
			@psIsd				= @psIsd,
			@psAreaCode			= @psAreaCode,
			@psTelecomNumber		= @psTelecomNumber,
			@psExtension			= @psExtension,
			@pnCarrierKey			= @pnCarrierKey,
			@pbIsReminderAddress		= @pbIsReminderAddress,
	
			@pnOldTelecomTypeKey		= @pnOldTelecomTypeKey,
			@psOldIsd			= @psOldIsd,
			@psOldAreaCode			= @psOldAreaCode,
			@psOldTelecomNumber		= @psOldTelecomNumber,
			@psOldExtension			= @psOldExtension,
			@pnOldCarrierKey		= @pnOldCarrierKey,
			@pbOldIsReminderAddress		= @pbOldIsReminderAddress,
	
			@pbIsTelecomTypeKeyInUse	= @pbIsTelecomTypeKeyInUse,
			@pbIsIsdInUse			= @pbIsIsdInUse,
			@pbIsAreaCodeInUse		= @pbIsAreaCodeInUse,
			@pbIsTelecomNumberInUse		= @pbIsTelecomNumberInUse,
			@pbIsExtensionInUse		= @pbIsExtensionInUse,
			@pbIsCarrierKeyInUse		= @pbIsCarrierKeyInUse,
			@pbIsIsReminderAddressInUse	= @pbIsIsReminderAddressInUse

		Set @nRowCount = @@rowcount
	End

	-- If TelecomNotes have changed, update NAMETELECOM
	If (@nErrorCode = 0
	and @nRowCount <> 0
	and @pbIsTelecomNotesInUse = 1 
	and @psTelecomNotes <> @psOldTelecomNotes)
	Begin			
		Set @sSQLString = "
			Update	NAMETELECOM
			set	TELECOMDESC = @psTelecomNotes
			where	NAMENO = @pnNameKey
			and	TELECODE = @pnTelecomKey
			and	TELECOMDESC = @psOldTelecomNotes"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnNameKey		int,
				@pnTelecomKey		int,
				@psTelecomNotes		nvarchar(254),
				@psOldTelecomNotes	nvarchar(254)',
				@pnNameKey		= @pnNameKey,
				@pnTelecomKey		= @pnTelecomKey,
				@psTelecomNotes		= @psTelecomNotes,
				@psOldTelecomNotes	= @psOldTelecomNotes
	
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateNameTelecom to public
GO