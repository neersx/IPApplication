-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteTelecommunication									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteTelecommunication]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteTelecommunication.'
	Drop procedure [dbo].[naw_DeleteTelecommunication]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteTelecommunication...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteTelecommunication
(
	@pnUserIdentityId		int,		 -- Mandatory
	@psCulture			nvarchar(10) 	 = null,
	@pbCalledFromCentura		bit		 = 0,
	@pnTelecomKey			int,		 -- Mandatory
	@pnOldTelecomTypeKey		int		 = null,
	@psOldIsd			nvarchar(5)	 = null,
	@psOldAreaCode			nvarchar(5)	 = null,
	@psOldTelecomNumber		nvarchar(100)	 = null,
	@psOldExtension			nvarchar(5)	 = null,
	@pnOldCarrierKey		int		 = null,
	@pbOldIsReminderAddress		bit		 = null,
	@pbIsTelecomTypeKeyInUse	bit		 = 0,
	@pbIsIsdInUse			bit		 = 0,
	@pbIsAreaCodeInUse		bit		 = 0,
	@pbIsTelecomNumberInUse		bit		 = 0,
	@pbIsExtensionInUse		bit		 = 0,
	@pbIsCarrierKeyInUse		bit		 = 0,
	@pbIsIsReminderAddressInUse	bit		 = 0
)
as
-- PROCEDURE:	naw_DeleteTelecommunication
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Telecommunication if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 30 Mar 2006	SW	RFC3721	1	Procedure created
-- 22 Nov 2007	SW	RFC5967	2	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = " and "

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from TELECOMMUNICATION where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"TELECODE = @pnTelecomKey"

	If @pbIsTelecomTypeKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"TELECOMTYPE = @pnOldTelecomTypeKey"
	End

	If @pbIsIsdInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ISD = @psOldIsd"
	End

	If @pbIsAreaCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"AREACODE = @psOldAreaCode"
	End

	If @pbIsTelecomNumberInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"TELECOMNUMBER = @psOldTelecomNumber"
	End

	If @pbIsExtensionInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"EXTENSION = @psOldExtension"
	End

	If @pbIsCarrierKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CARRIER = @pnOldCarrierKey"
	End

	If @pbIsIsReminderAddressInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"REMINDEREMAILS = @pbOldIsReminderAddress"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			N'
			@pnTelecomKey			int,
			@pnOldTelecomTypeKey		int,
			@psOldIsd			nvarchar(5),
			@psOldAreaCode			nvarchar(5),
			@psOldTelecomNumber		nvarchar(100),
			@psOldExtension			nvarchar(5),
			@pnOldCarrierKey		int,
			@pbOldIsReminderAddress		bit',
			@pnTelecomKey			= @pnTelecomKey,
			@pnOldTelecomTypeKey		= @pnOldTelecomTypeKey,
			@psOldIsd			= @psOldIsd,
			@psOldAreaCode			= @psOldAreaCode,
			@psOldTelecomNumber		= @psOldTelecomNumber,
			@psOldExtension			= @psOldExtension,
			@pnOldCarrierKey		= @pnOldCarrierKey,
			@pbOldIsReminderAddress		= @pbOldIsReminderAddress
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteTelecommunication to public
GO

