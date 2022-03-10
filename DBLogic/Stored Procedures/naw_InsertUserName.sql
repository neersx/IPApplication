-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertUserName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertUserName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertUserName.'
	Drop procedure [dbo].[naw_InsertUserName]
End
Print '**** Creating Stored Procedure dbo.naw_InsertUserName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_InsertUserName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int		= null,	-- Included to provide a standard interface
	@psNameCode		nvarchar(10)	= null,
	@psName			nvarchar(254)	= null,
	@psGivenNames		nvarchar(50)	= null,
	@psTitle		nvarchar(20)	= null,
	@pnOrganisationKey	int		= null,
	@pnNamePresentationKey	int		= null,
	@psEmailAddress		nvarchar(100)	= null
)
as
-- PROCEDURE:	naw_InsertUserName
-- VERSION:	3
-- DESCRIPTION:	Add a minimal name for use as a UserIdentity, returning the generated key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC408	1	Procedure created
-- 22 Nov 2007	SW	RFC5967	2	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 11 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer



SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)
declare	@sNameKey		nvarchar(11)

-- Initialise variables
Set @nErrorCode 		= 0

-- Add the name
-- Note: this is using the CPA Inprostart procedure until a better version is developed.
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.na_InsertName
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@psNameKey		= @sNameKey	output,
		@psNameCode		= @psNameCode,
		@pnEntityType		= 2,		-- Individual	
		@psName			= @psName,
		@psGivenNames		= @psGivenNames,
		@psTitleKey		= @psTitle,
		@pnNameStyle		= @pnNamePresentationKey

	Set @pnNameKey = cast(@sNameKey as int)

	-- Publish generated key to update dataset
	Select @pnNameKey as NameKey

End

-- Store the email address as a name telecom.
If @nErrorCode = 0
and @psEmailAddress is not null
Begin

	exec @nErrorCode = naw_InsertTelecommunication
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnNameKey		= @pnNameKey,
		@pnTelecomTypeKey	= 1903,			-- Email
		@psTelecomNumber	= @psEmailAddress,
		@pbReminderEmails	= 1
End

-- Add the Organisation
-- Note: this is using the CPA Inprostart procedure until a better version is developed.
If @nErrorCode = 0
and @pnOrganisationKey is not null
Begin
	exec @nErrorCode = na_InsertAssociatedName
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@psNameKey		= @pnNameKey,
		@pnRelationshipTypeId	= 1,			-- Organisation
		@psRelatedNameKey	= @pnOrganisationKey,
		@pbIsReverseRelationship = 1			-- Required for Organisation

End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertUserName to public
GO