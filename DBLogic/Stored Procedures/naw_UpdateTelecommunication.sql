-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateTelecommunication									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateTelecommunication]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateTelecommunication.'
	Drop procedure [dbo].[naw_UpdateTelecommunication]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateTelecommunication...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateTelecommunication
(
	@pnUserIdentityId		int,		 -- Mandatory
	@psCulture			nvarchar(10) 	 = null,
	@pbCalledFromCentura		bit		 = 0,
	@pnTelecomKey			int,		 -- Mandatory
	@pnTelecomTypeKey		int		 = null,
	@psIsd				nvarchar(5)	 = null,
	@psAreaCode			nvarchar(5)	 = null,
	@psTelecomNumber		nvarchar(100)	 = null,
	@psExtension			nvarchar(5)	 = null,
	@pnCarrierKey			int		 = null,
	@pbIsReminderAddress		bit		 = null,
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
-- PROCEDURE:	naw_UpdateTelecommunication
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Telecommunication if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 30 Mar 2006	SW	RFC3721	1	Procedure created
-- 22 Nov 2007	SW	RFC5967	2	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 08 Jun 2015	DV	R47577	3	Ignore concurrency check if REMINDEREMAILS is null

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update TELECOMMUNICATION
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		TELECODE = @pnTelecomKey and
		"

	If @pbIsTelecomTypeKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TELECOMTYPE = @pnTelecomTypeKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TELECOMTYPE = @pnOldTelecomTypeKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsIsdInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ISD = @psIsd"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ISD = @psOldIsd"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsAreaCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"AREACODE = @psAreaCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"AREACODE = @psOldAreaCode"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsTelecomNumberInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TELECOMNUMBER = @psTelecomNumber"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TELECOMNUMBER = @psOldTelecomNumber"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsExtensionInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"EXTENSION = @psExtension"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"EXTENSION = @psOldExtension"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsCarrierKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CARRIER = @pnCarrierKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CARRIER = @pnOldCarrierKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsIsReminderAddressInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"REMINDEREMAILS = @pbIsReminderAddress"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"(REMINDEREMAILS = @pbOldIsReminderAddress or REMINDEREMAILS is null)"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnTelecomKey			int,
			@pnTelecomTypeKey		int,
			@psIsd				nvarchar(5),
			@psAreaCode			nvarchar(5),
			@psTelecomNumber		nvarchar(100),
			@psExtension			nvarchar(5),
			@pnCarrierKey			int,
			@pbIsReminderAddress		bit,
			@pnOldTelecomTypeKey		int,
			@psOldIsd			nvarchar(5),
			@psOldAreaCode			nvarchar(5),
			@psOldTelecomNumber		nvarchar(100),
			@psOldExtension			nvarchar(5),
			@pnOldCarrierKey		int,
			@pbOldIsReminderAddress		bit',
			@pnTelecomKey	 		= @pnTelecomKey,
			@pnTelecomTypeKey	 	= @pnTelecomTypeKey,
			@psIsd	 			= @psIsd,
			@psAreaCode	 		= @psAreaCode,
			@psTelecomNumber	 	= @psTelecomNumber,
			@psExtension	 		= @psExtension,
			@pnCarrierKey	 		= @pnCarrierKey,
			@pbIsReminderAddress	 	= @pbIsReminderAddress,
			@pnOldTelecomTypeKey	 	= @pnOldTelecomTypeKey,
			@psOldIsd	 		= @psOldIsd,
			@psOldAreaCode	 		= @psOldAreaCode,
			@psOldTelecomNumber	 	= @psOldTelecomNumber,
			@psOldExtension	 		= @psOldExtension,
			@pnOldCarrierKey	 	= @pnOldCarrierKey,
			@pbOldIsReminderAddress	 	= @pbOldIsReminderAddress


End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateTelecommunication to public
GO