-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateAddressTelecom
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateAddressTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateAddressTelecom.'
	Drop procedure [dbo].[naw_UpdateAddressTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateAddressTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_UpdateAddressTelecom
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnAddressKey			int,
	@pnTelecomKey			int,
	@pnTelecomTypeKey		int,
	@psISD					nvarchar(5),
	@psAreaCode				nvarchar(5),
	@psNumber				nvarchar(100),
	@psExtension			nvarchar(5),	
	@pnOldTelecomKey		int,
	@pnOldTelecomTypeKey	int,
	@psOldISD				nvarchar(5),
	@psOldAreaCode			nvarchar(5),
	@psOldNumber			nvarchar(100),
	@psOldExtension			nvarchar(5)	
)
as
-- PROCEDURE:	naw_UpdateAddressTelecom
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Dec 2007	PG	RFC3497	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nUpdateString nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0 and 
@pnTelecomKey is not null and
@pnOldTelecomKey is not null and
@pnTelecomKey = @pnOldTelecomKey
Begin

	exec @nErrorCode = dbo.naw_UpdateTelecommunication
				@pnUserIdentityId			=@pnUserIdentityId,
				@psCulture					=@psCulture,
				@pbCalledFromCentura		=0,
				@pnTelecomKey				=@pnTelecomKey,
				@pnTelecomTypeKey			=@pnTelecomTypeKey,
				@psIsd						=@psISD,
				@psAreaCode					=@psAreaCode,
				@psTelecomNumber			=@psNumber,
				@psExtension				=@psExtension,
				@pnCarrierKey				= null,
				@pbIsReminderAddress		= null,
				@pnOldTelecomTypeKey		=@pnOldTelecomKey,
				@psOldIsd					=@psOldISD,
				@psOldAreaCode				=@psOldAreaCode,
				@psOldTelecomNumber			=@psOldNumber,
				@psOldExtension				=@psOldExtension,
				@pnOldCarrierKey			=null,
				@pbOldIsReminderAddress		=null,
				@pbIsTelecomTypeKeyInUse	=1,
				@pbIsIsdInUse				=1,
				@pbIsAreaCodeInUse			=1,
				@pbIsTelecomNumberInUse		=1,
				@pbIsExtensionInUse			=1,
				@pbIsCarrierKeyInUse		=0,
				@pbIsIsReminderAddressInUse	=0

	
End
Else If @nErrorCode = 0 and 
@pnTelecomKey is not null and
@pnOldTelecomKey is not null and
@pnTelecomKey <> @pnOldTelecomKey

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateAddressTelecom to public
GO
