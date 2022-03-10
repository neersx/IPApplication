-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertAddressTelecom
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertAddressTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertAddressTelecom.'
	Drop procedure [dbo].[naw_InsertAddressTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_InsertAddressTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertAddressTelecom
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnTelecomKey			int		output,
	@pnAddressKey			int		= null,
	@pnTelecomTypeKey		int		= null,
	@psIsd					nvarchar(5)	= null,
	@psAreaCode				nvarchar(5)	= null,
	@psTelecomNumber		nvarchar(100)	= null,
	@psExtension			nvarchar(5)	= null,
	@pnCarrierKey			int		= null,
	@pbIsReminderAddress	bit		= null,
	@pbIsMain				bit		= 0
)
as
-- PROCEDURE:	naw_InsertAddressTelecom
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts a telecommunication row for an address (Minimal implementation)

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Dec 2007	PG	RFC3497 1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF



Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)



-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Exec @nErrorCode = dbo.naw_InsertTelecommunication
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbCalledFromCentura = 0,
		@pnTelecomTypeKey	= @pnTelecomTypeKey,
		@psIsd				= @psIsd,
		@psAreaCode			= @psAreaCode,
		@psTelecomNumber	= @psTelecomNumber,
		@psExtension		= @psExtension,
		@pnCarrierKey		= @pnCarrierKey,
		@pbIsReminderAddress		= @pbIsReminderAddress,
		@pbIsTelecomTypeKeyInUse	= 1,
		@pbIsIsdInUse				= 1,
		@pbIsAreaCodeInUse			= 1,
		@pbIsTelecomNumberInUse		= 1,
		@pbIsExtensionInUse			= 1,
		@pbIsCarrierKeyInUse		= 0,
		@pbIsIsReminderAddressInUse	= 0,
		@pnTelecomKey				= @pnTelecomKey	OUTPUT
	
End

If @nErrorCode = 0
Begin
			Set @sInsertString = "Insert into ADDRESSTELECOM
				(ADDRESSCODE, TELECODE,TELECOMDESC) "
			Set @sValuesString = @sValuesString+CHAR(10)+ 
				"@pnAddressKey, @pnTelecomKey, null)"

			Set @sSQLString = @sInsertString + @sValuesString


			exec @nErrorCode=sp_executesql @sSQLString,
			      				N'@pnAddressKey		int,
								@pnTelecomKey		int',
								@pnAddressKey	 = @pnAddressKey,
								@pnTelecomKey	 = @pnTelecomKey

End


If @nErrorCode=0 and @pbIsMain =1 
Begin
	Set @sUpdateString = "Update ADDRESS SET "
	If @pnTelecomTypeKey='1901'
	Begin
		Set @sUpdateString = @sUpdateString+ " TELEPHONE = "
	End
	If @pnTelecomTypeKey='1902'
	Begin
		Set @sUpdateString = @sUpdateString+ " FAX = "
	End
	Set @sUpdateString = @sUpdateString+ " @pnTelecomKey Where ADDRESSCODE = @pnAddressKey"
		
	Print @sUpdateString
	exec @nErrorCode=sp_executesql @sUpdateString,
			      				N'@pnTelecomKey		int,
								@pnAddressKey		int',
								@pnTelecomKey	 = @pnTelecomKey,
								@pnAddressKey	 = @pnAddressKey

End



Return @nErrorCode
GO

Grant execute on dbo.naw_InsertAddressTelecom to public
GO
