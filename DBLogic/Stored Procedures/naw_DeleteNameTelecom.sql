-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteNameTelecom									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteNameTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteNameTelecom.'
	Drop procedure [dbo].[naw_DeleteNameTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteNameTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteNameTelecom
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	
	@pnTelecomKey			int,		-- Mandatory
	@psTelecomNotes			nvarchar(254)	= null,
	@pbIsOwner			bit		= null,
	@pnTelecomTypeKey		int		= null,
	@psIsd				nvarchar(5)	= null,
	@psAreaCode			nvarchar(5)	= null,
	@psTelecomNumber		nvarchar(100)	= null,
	@psExtension			nvarchar(5)	= null,
	@pnCarrierKey			int		= null,
	@pbIsReminderAddress		bit		= null,
	
	@psOldTelecomNotes		nvarchar(254)	= null,
	@pbOldIsOwner			bit		= null,
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
-- PROCEDURE:	naw_DeleteNameTelecom
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete NameTelecom if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 31 Mar 2006	SW	RFC3721	1	Procedure created
-- 22 Nov 2007	SW	RFC5967	2	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 26 Jul 2010	SF	RFC9563	3	Ensure IsOwner flag is returned as either a 0 or a 1.
-- 02 Mar 2012  DV      R11994  		4       Set the OWNEDBY flag to other Name if the @pbOldIsOwner = 1

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)
Declare @nRowCount		int
Declare @bIsOrphan		bit

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount = 0
Set @sAnd = " and "

Set @pbOldIsOwner = ISNULL(@pbOldIsOwner, 0)

-- Find out if @pnTelecomKey orphan
-- if > 1 then not orphan
-- if 1 then orphan
-- if 0 then not exists (hopefully not exists in TELECOMMUNICATION too)
Set @sSQLString = '
	Select	@bIsOrphan = 
		case 	count(TELECODE)
			when 1 then 	cast(1 as bit)
			else 		cast(0 as bit)
		end
	from	NAMETELECOM
	where	TELECODE = @pnTelecomKey'

exec @nErrorCode = sp_executesql @sSQLString,
		N'
		@bIsOrphan		int		OUTPUT,
		@pnTelecomKey		int',
		@bIsOrphan		= @bIsOrphan	OUTPUT,
		@pnTelecomKey	 	= @pnTelecomKey

-- detach from NAME if belongs to main of any records
If (@nErrorCode = 0)
Begin

	If @pnTelecomTypeKey = 1901
	Begin
		Set @sSQLString = '
			Update [NAME]
			set	MAINPHONE = null
			where	MAINPHONE = @pnTelecomKey
			and	NAMENO = @pnNameKey'
	End
	Else If @pnTelecomTypeKey = 1902
	Begin
		Set @sSQLString = '
			Update [NAME]
			set	FAX = null
			where	FAX = @pnTelecomKey
			and	NAMENO = @pnNameKey'
	End
	Else
	Begin
		Set @sSQLString = '
			Update [NAME]
			set	MAINEMAIL = null
			where	MAINEMAIL = @pnTelecomKey
			and	NAMENO = @pnNameKey'
	End

	Exec @nErrorCode = sp_executesql @sSQLString,
		N'
		@pnTelecomKey		int,
		@pnNameKey		int',
		@pnTelecomKey	 	= @pnTelecomKey,
		@pnNameKey		= @pnNameKey

End

-- delete from NAMETELECOM
If @nErrorCode = 0
Begin

	Set @sDeleteString = "Delete from NAMETELECOM
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		NAMENO = @pnNameKey and
		TELECODE = @pnTelecomKey
		"

	If @pbIsTelecomNotesInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"TELECOMDESC = @psOldTelecomNotes"
	End

	If @pbIsIsOwnerInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ISNULL(OWNEDBY,0) = @pbOldIsOwner"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			N'
			@pnNameKey		int,
			@pnTelecomKey		int,
			@psOldTelecomNotes	nvarchar(254),
			@pbOldIsOwner		bit',
			@pnNameKey		= @pnNameKey,
			@pnTelecomKey	 	= @pnTelecomKey,
			@psOldTelecomNotes	= @psOldTelecomNotes,
			@pbOldIsOwner	 	= @pbOldIsOwner

	-- for concurrency checking
	Set @nRowCount = @@rowcount

End

--Set the new owner
If (@nErrorCode = 0 and @nRowCount <> 0 and @pbOldIsOwner = 1)
Begin
	If exists (select 1 from NAMETELECOM where TELECODE = @pnTelecomKey)
	Begin
		Set @sSQLString = '
		Update NAMETELECOM 
		set OWNEDBY = 1 
		where TELECODE = @pnTelecomKey 
		and NAMENO = (select top 1 NAMENO from NAMETELECOM 
				where TELECODE = @pnTelecomKey
				order By NAMENO ASC)'
				
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnTelecomKey		int',
			@pnTelecomKey	 	= @pnTelecomKey
	End
End

-- delete orphan @pnTelecomKey from TELECOMMUNICATION
If (@nErrorCode = 0 and @nRowCount <> 0 and @bIsOrphan = 1)
Begin

	exec @nErrorCode = dbo.naw_DeleteTelecommunication
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura		= @pbCalledFromCentura,
		@pnTelecomKey			= @pnTelecomKey,

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

End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteNameTelecom to public
GO