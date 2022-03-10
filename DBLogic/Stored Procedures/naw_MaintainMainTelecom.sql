-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_MaintainMainTelecom
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_MaintainMainTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_MaintainMainTelecom.'
	Drop procedure [dbo].[naw_MaintainMainTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_MaintainMainTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_MaintainMainTelecom
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@pnTelecomTypeKey	int,		-- Mandatory
	@psTelecomISD		nvarchar(5) 	= null,
	@psTelecomAreaCode	nvarchar(5) 	= null,
	@psTelecomNumber	nvarchar(100) 	= null,                         
	@psTelecomExtension	nvarchar(5) 	= null,
	@psOldTelecomISD	nvarchar(5) 	= null,
	@psOldTelecomAreaCode	nvarchar(5) 	= null,
	@psOldTelecomNumber	nvarchar(100) 	= null,                         
	@psOldTelecomExtension	nvarchar(5) 	= null
)
as
-- PROCEDURE:	naw_MaintainMainTelecom
-- VERSION:	5
-- DESCRIPTION:	Insert/update/delete the main telecom against a name

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Dec 2003	JEK	RFC408	1	Procedure created
-- 10 Mar 2004	TM	RFC868	2	For the insert/update/delete the main telecom against a name extend the logic 
--					to insert/update/delete Name.MainEmail using similar approach as Name.MainPhone 
--					and Name.Fax columns.
-- 30 May 2006	JEK	RFC3907	3	Modify processing to use new name maintenance procedures.
-- 22 Nov 2007	SW	RFC5967	4	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 26 Jul 2010	SF	RFC9563	5	Ensure IsOwner flag is returned as either a 0 or a 1.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @nRowCount		int
declare @sSQLString 		nvarchar(4000)
declare @nTelecomKey		int
declare @nOldTelecomKey		int
declare	@bIsTelecomShared	bit
declare @bReminderEmails	bit
declare	@bIsOwner		bit
declare	@bOldIsOwner		bit
declare @bIsLinked		bit
declare @bOldIsLinked		bit

-- Initialise variables
Set @nErrorCode 		= 0
Set @bIsTelecomShared		= 0
Set @nRowCount			= 0
Set @bIsLinked			= 0
Set @bOldIsLinked		= 0
Set @bOldIsOwner		= 0

-- Insert
If @nErrorCode = 0
and (@psTelecomISD is not null or
     @psTelecomAreaCode is not null or
     @psTelecomNumber is not null or
     @psTelecomExtension is not null)
and @psOldTelecomISD is null
and @psOldTelecomAreaCode is null
and @psOldTelecomNumber is null
and @psOldTelecomExtension is null
Begin
	Set @bReminderEmails = case when @pnTelecomTypeKey = 1903 
				    then 1 else null end

	exec @nErrorCode = naw_InsertNameTelecom
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura		= 0,
		@pnNameKey			= @pnNameKey,
		@pnTelecomKey			= @nTelecomKey		output,
		@pbIsOwner			= 1,
		@pnTelecomTypeKey		= @pnTelecomTypeKey,
		@psIsd				= @psTelecomISD,
		@psAreaCode			= @psTelecomAreaCode,
		@psTelecomNumber		= @psTelecomNumber,
		@psExtension			= @psTelecomExtension,
		@pbIsReminderAddress		= @bReminderEmails,
		@pbIsTelecomNotesInUse		= 0,
		@pbIsIsOwnerInUse		= 1,
		@pbIsTelecomTypeKeyInUse	= 1,
		@pbIsIsdInUse			= 1,
		@pbIsAreaCodeInUse		= 1,
		@pbIsTelecomNumberInUse		= 1,
		@pbIsExtensionInUse		= 1,
		@pbIsCarrierKeyInUse		= 0,
		@pbIsIsReminderAddressInUse	= 1

	Set @nRowCount = @@ROWCOUNT

	-- Update the name to indicate that it has changed.
	-- Adjust the Main phone/fax/Main email if necessary. 
	If @nErrorCode = 0
	AND @nRowCount > 0
	Begin
		Set @sSQLString = " 
		update 	NAME
		set	DATECHANGED	= getdate(), 
			MAINPHONE	= case when @pnTelecomTypeKey = 1901
					  then @nTelecomKey
					  else MAINPHONE end,
			FAX		= case when @pnTelecomTypeKey = 1902
					  then @nTelecomKey
					  else FAX end,
			MAINEMAIL	= case when @pnTelecomTypeKey = 1903
					  then @nTelecomKey
					  else MAINEMAIL end 
		where	NAMENO		= @pnNameKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey		int,
						  @pnTelecomTypeKey	int,
						  @nTelecomKey		int',
						  @pnNameKey		= @pnNameKey,
						  @pnTelecomTypeKey	= @pnTelecomTypeKey,
						  @nTelecomKey		= @nTelecomKey
	
	End
End
-- Existing Telecom
Else
Begin
	-- Locate the key of the existing entry
	If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
		select	@nTelecomKey=NT.TELECODE,
			@bIsOwner=cast(ISNULL(OWNEDBY,0) as bit)
		from	NAMETELECOM NT
		join	TELECOMMUNICATION T 	on (T.TELECODE=NT.TELECODE)
		where	NT.NAMENO 	= @pnNameKey
		and	T.TELECOMTYPE	= @pnTelecomTypeKey
		and	T.ISD 		= @psOldTelecomISD
		and	T.AREACODE	= @psOldTelecomAreaCode
		and	T.TELECOMNUMBER	= @psOldTelecomNumber
		and	T.EXTENSION	= @psOldTelecomExtension"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTelecomKey		int	output,
						  @bIsOwner		bit	output,
						  @pnNameKey		int,
						  @pnTelecomTypeKey	int,
						  @psOldTelecomISD	nvarchar(5),
						  @psOldTelecomAreaCode	nvarchar(5),
						  @psOldTelecomNumber	nvarchar(50),
						  @psOldTelecomExtension nvarchar(5)',
						  @nTelecomKey		= @nOldTelecomKey output,
						  @bIsOwner		= @bOldIsOwner output,
						  @pnNameKey		= @pnNameKey,
						  @pnTelecomTypeKey	= @pnTelecomTypeKey,
						  @psOldTelecomISD	= @psOldTelecomISD,
						  @psOldTelecomAreaCode	= @psOldTelecomAreaCode,
						  @psOldTelecomNumber	= @psOldTelecomNumber,
						  @psOldTelecomExtension = @psOldTelecomExtension

	End

	-- Check whether the telcom is shared with other names
	If @nErrorCode = 0
	and @nOldTelecomKey is not null
	Begin
		Set @sSQLString = " 
		select	@bIsLinked=1
		from	NAMETELECOM NT
		where	NT.TELECODE=@nTelecomKey
		and	NT.NAMENO<>@pnNameKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@bIsLinked		bit	output,
						  @nTelecomKey		int,
						  @pnNameKey		int',
						  @bIsLinked		= @bOldIsLinked output,
						  @nTelecomKey		= @nOldTelecomKey,
						  @pnNameKey		= @pnNameKey
	End

	-- Delete
	If @nErrorCode = 0
	and @nOldTelecomKey is not null
	and (@psOldTelecomISD is not null or
	     @psOldTelecomAreaCode is not null or
	     @psOldTelecomNumber is not null or
	     @psOldTelecomExtension is not null)
	-- If both of these are cleared, the ISD and Area are not relevant
	and @psTelecomNumber is null
	and @psTelecomExtension is null
	Begin
		exec @nErrorCode = dbo.naw_DeleteNameTelecom
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= 0,
			@pnNameKey			= @pnNameKey,
			@pnTelecomKey			= @nOldTelecomKey,
			@pbIsOwner			= @bIsOwner,
			@pnTelecomTypeKey		= @pnTelecomTypeKey,
			@psIsd				= @psTelecomISD,
			@psAreaCode			= @psTelecomAreaCode,
			@psTelecomNumber		= @psTelecomNumber,
			@psExtension			= @psTelecomExtension,

			@pbOldIsOwner			= @bOldIsOwner,
			@pnOldTelecomTypeKey		= @pnTelecomTypeKey,
			@psOldIsd			= @psOldTelecomISD,
			@psOldAreaCode			= @psOldTelecomAreaCode,
			@psOldTelecomNumber		= @psOldTelecomNumber,
			@psOldExtension			= @psOldTelecomExtension,

			@pbIsTelecomNotesInUse		= 0,
			@pbIsIsOwnerInUse		= 1,
			@pbIsTelecomTypeKeyInUse	= 1,
			@pbIsIsdInUse			= 1,
			@pbIsAreaCodeInUse		= 1,
			@pbIsTelecomNumberInUse		= 1,
			@pbIsExtensionInUse		= 1,
			@pbIsCarrierKeyInUse		= 0,
			@pbIsIsReminderAddressInUse	= 0	

		Set @nRowCount = @@ROWCOUNT

		-- Update the name to indicate that it has changed.
		If @nErrorCode = 0
		AND @nRowCount > 0
		Begin
			Set @sSQLString = " 
			update 	NAME
			set	DATECHANGED	= getdate()
			where	NAMENO		= @pnNameKey"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameKey		int',
							  @pnNameKey		= @pnNameKey
		End
	End
	-- Update
	Else If @nErrorCode = 0
	and @nOldTelecomKey is not null
	and (@psOldTelecomISD 		<> @psTelecomISD or
	     @psOldTelecomAreaCode 	<> @psTelecomAreaCode or
	     @psOldTelecomNumber 	<> @psTelecomNumber or
	     @psOldTelecomExtension	<> @psTelecomExtension)
	Begin
		-- If the old telecom is shared, we need to create a new
		-- unlinked telecom for the new value.
		If @bOldIsOwner=0 and @bOldIsLinked=1
		Begin
			Set @bIsLinked=0
			Set @bIsOwner=1
			Set @nTelecomKey=null
		End
		Else
		Begin
			Set @bIsLinked=@bOldIsLinked
			Set @bIsOwner=@bOldIsOwner
			Set @nTelecomKey=@nOldTelecomKey
		End

		exec @nErrorCode = dbo.naw_UpdateNameTelecom
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= 0,
			@pnNameKey			= @pnNameKey,
			@pbIsLinked			= @bIsLinked,
			@pbIsOwner			= @bIsOwner,
			@pnTelecomKey			= @nTelecomKey output,
			@pnTelecomTypeKey		= @pnTelecomTypeKey,
			@psIsd				= @psTelecomISD,
			@psAreaCode			= @psTelecomAreaCode,
			@psTelecomNumber		= @psTelecomNumber,
			@psExtension			= @psTelecomExtension,

			@pbOldIsOwner			= @bOldIsOwner,
			@pbOldIsLinked			= @bOldIsLinked,
			@pnOldTelecomKey		= @nOldTelecomKey,
			@pnOldTelecomTypeKey		= @pnTelecomTypeKey,
			@psOldIsd			= @psOldTelecomISD,
			@psOldAreaCode			= @psOldTelecomAreaCode,
			@psOldTelecomNumber		= @psOldTelecomNumber,
			@psOldExtension			= @psOldTelecomExtension,

			@pbIsTelecomNotesInUse		= 0,
			@pbIsIsOwnerInUse		= 1,
			@pbIsTelecomTypeKeyInUse	= 1,
			@pbIsIsdInUse			= 1,
			@pbIsAreaCodeInUse		= 1,
			@pbIsTelecomNumberInUse		= 1,
			@pbIsExtensionInUse		= 1,
			@pbIsCarrierKeyInUse		= 0,
			@pbIsIsReminderAddressInUse	= 0	

		Set @nRowCount = @@ROWCOUNT

		-- Update the name to indicate that it has changed.
		-- Adjust the Main phone/fax/Main email if necessary. 
		If @nErrorCode = 0
		AND @nRowCount > 0
		Begin
			Set @sSQLString = " 
			update 	NAME
			set	DATECHANGED	= getdate(), 
				MAINPHONE	= case when @pnTelecomTypeKey = 1901
						  then @nTelecomKey
						  else MAINPHONE end,
				FAX		= case when @pnTelecomTypeKey = 1902
						  then @nTelecomKey
						  else FAX end,
				MAINEMAIL	= case when @pnTelecomTypeKey = 1903
						  then @nTelecomKey
						  else MAINEMAIL end 
			where	NAMENO		= @pnNameKey"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnNameKey		int,
							  @pnTelecomTypeKey	int,
							  @nTelecomKey		int',
							  @pnNameKey		= @pnNameKey,
							  @pnTelecomTypeKey	= @pnTelecomTypeKey,
							  @nTelecomKey		= @nTelecomKey
		
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_MaintainMainTelecom to public
GO
