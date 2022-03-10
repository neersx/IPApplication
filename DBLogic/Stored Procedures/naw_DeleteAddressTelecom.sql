-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteAddressTelecom
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteAddressTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteAddressTelecom.'
	Drop procedure [dbo].[naw_DeleteAddressTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteAddressTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_DeleteAddressTelecom
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnTelecomKey			int		= null,
	@pnAddressKey			int		= null

)
as
-- PROCEDURE:	naw_DeleteAddressTelecom
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Dec 2007	PG	RFC3497	1	Procedure created
-- 10 Dec 2008	AT	RFC7388	2	Modify definition of orphaned row.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sDeleteString		nvarchar(4000)
Declare @sSQLString			nvarchar(4000)
Declare @bIsOrphan	bit
Declare @nNameTelecomCnt	int

-- Initialise variables
Set @nErrorCode = 0

--Count NAMES still using TELECODE
If @nErrorCode = 0
Begin
Set @sSQLString = '
	Select	@nNameTelecomCnt = 
			count(TELECODE)
	from	NAMETELECOM
	where	TELECODE = @pnTelecomKey'

exec @nErrorCode = sp_executesql @sSQLString,
		N'
		@nNameTelecomCnt		int		OUTPUT,
		@pnTelecomKey			int',
		@nNameTelecomCnt		= @nNameTelecomCnt	OUTPUT,
		@pnTelecomKey	 		= @pnTelecomKey
End

-- Find out if @pnTelecomKey orphan
-- Assumes address using this TeleCode has already been updated/deleted in naw_DeleteAddress.
If @nErrorCode = 0
Begin
	-- Is the telecode used on any address telecoms?
	Set @sSQLString = '
	Select	@bIsOrphan = 
		case 	(count(AT.TELECODE) + @nNameTelecomCnt)
			when 0 then 	cast(1 as bit)
			else 		cast(0 as bit)
		end
	from	ADDRESSTELECOM AT
	join 	ADDRESS A on (A.TELEPHONE = AT.TELECODE or A.FAX = AT.TELECODE)
	where	AT.TELECODE = @pnTelecomKey'

exec @nErrorCode = sp_executesql @sSQLString,
		N'
		@nNameTelecomCnt		int,
		@bIsOrphan		int		OUTPUT,
		@pnTelecomKey		int',
		@nNameTelecomCnt		= @nNameTelecomCnt,
		@bIsOrphan				= @bIsOrphan	OUTPUT,
		@pnTelecomKey	 		= @pnTelecomKey
End

--Detach from Address
If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from ADDRESSTELECOM where ADDRESSCODE = @pnAddressKey and TELECODE= @pnTelecomKey"
	
	exec @nErrorCode=sp_executesql @sDeleteString,
				N'
				@pnAddressKey		int,
				@pnTelecomKey		int',
				@pnAddressKey		= @pnAddressKey,
				@pnTelecomKey		= @pnTelecomKey
End

--Delete ophan telecom
If (@nErrorCode = 0 and @bIsOrphan = 1)
Begin
	exec @nErrorCode = dbo.naw_DeleteTelecommunication
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture				= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnTelecomKey			= @pnTelecomKey,
		@pnOldTelecomTypeKey	= null,
		@psOldIsd				= null,
		@psOldAreaCode			= null,
		@psOldTelecomNumber		= null,
		@psOldExtension			= null,
		@pnOldCarrierKey		= null,
		@pbOldIsReminderAddress	= null,
		@pbIsTelecomTypeKeyInUse	= 0,
		@pbIsIsdInUse				= 0,
		@pbIsAreaCodeInUse			= 0,
		@pbIsTelecomNumberInUse		= 0,
		@pbIsExtensionInUse			= 0,
		@pbIsCarrierKeyInUse		= 0,
		@pbIsIsReminderAddressInUse	= 0
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteAddressTelecom to public
GO
