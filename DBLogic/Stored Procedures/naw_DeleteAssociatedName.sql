-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteAssociatedName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteAssociatedName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteAssociatedName.'
	Drop procedure [dbo].[naw_DeleteAssociatedName]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteAssociatedName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteAssociatedName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@psRelationshipCode		nvarchar(3),	-- Mandatory
	@pnAssociatedNameKey		int,		-- Mandatory
	@pnSequence			smallint,	-- Mandatory
	@pbIsReverse			bit		= null,
	@psOldPropertyTypeCode		nchar(1)	= null,
	@psOldCountryCode		nvarchar(3)	= null,
	@psOldActionCode		nvarchar(2)	= null,
	@pnOldAttentionKey		int		= null,
	@pnOldJobRoleKey		int		= null,
	@pbOldUseInMailing		bit		= null,
	@pdtOldCeaseDate		datetime	= null,
	@pnOldPositionCategoryKey	int		= null,
	@psOldPosition			nvarchar(60)	= null,
	@pnOldPhoneKey			int		= null,
	@pnOldFaxKey			int		= null,
	@pnOldPostalAddressKey		int		= null,
	@pnOldStreetAddressKey		int		= null,
	@pbOldUseInformalSalutation	bit		= null,
	@pnOldValedictionKey		int		= null,
	@psOldNotes			nvarchar(254)	= null,
	@pbOldIsCRMOnly			bit		= null,
	@pnOldFormatProfileKey          int             = null,
	@pbIsPropertyTypeCodeInUse	bit	 	= 0,
	@pbIsCountryCodeInUse		bit	 	= 0,
	@pbIsActionCodeInUse		bit	 	= 0,
	@pbIsAttentionKeyInUse		bit	 	= 0,
	@pbIsJobRoleKeyInUse		bit	 	= 0,
	@pbIsUseInMailingInUse		bit	 	= 0,
	@pbIsCeaseDateInUse		bit	 	= 0,
	@pbIsPositionCategoryKeyInUse	bit	 	= 0,
	@pbIsPositionInUse		bit	 	= 0,
	@pbIsPhoneKeyInUse		bit	 	= 0,
	@pbIsFaxKeyInUse		bit	 	= 0,
	@pbIsPostalAddressKeyInUse	bit	 	= 0,
	@pbIsStreetAddressKeyInUse	bit	 	= 0,
	@pbIsUseInformalSalutationInUse	bit	 	= 0,
	@pbIsValedictionKeyInUse	bit	 	= 0,
	@pbIsNotesInUse			bit	 	= 0,
	@pbIsIsCRMOnlyInUse		bit		= 0,
	@pbIsFormatProfileKeyInUse      bit             = 0
)
as
-- PROCEDURE:	naw_DeleteAssociatedName
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete AssociatedName if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Apr 2006	IB	RFC3768	1	Procedure created
-- 01 May 2006	IB	RFC3768	2	Fixed the logic of detaching RelatedNameKey as MAINCONTACT.
-- 30 Jun 2008	AT	RFC5787	3	Added IsCRMOnly flag
-- 30 Mar 2010  LP      RFC7276 4       Added FormatProfileKey field.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)
Declare @sAlertXML		nvarchar(400)
Declare @nFromNameKey		int
Declare @nRelatedNameKey	int

-- Initialise variables
Set @nErrorCode = 0

If @pbIsReverse = 1
Begin
	Set @nFromNameKey = @pnAssociatedNameKey 
	Set @nRelatedNameKey = @pnNameKey 
End
Else
Begin
	Set @nFromNameKey = @pnNameKey 
	Set @nRelatedNameKey = @pnAssociatedNameKey 
End

-- Restrict delete if a name appears as attention on a case
If @nErrorCode = 0
Begin
	If exists (select * 
			from CASENAME 
			where NAMENO = @nFromNameKey and CORRESPONDNAME = @nRelatedNameKey and DERIVEDCORRNAME = 0)
	Begin
		-- produce a user error
		Set @sAlertXML = dbo.fn_GetAlertXML('NA20', 'Associated name row cannot be deleted because the individual' +
					     ' is used as attention name on a case.',null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	If exists (select * 
			from CASENAME 
			where NAMENO = @nRelatedNameKey and CORRESPONDNAME = @nFromNameKey and DERIVEDCORRNAME = 0)
	Begin
		-- produce a user error
		Set @sAlertXML = dbo.fn_GetAlertXML('NA20', 'Associated name row cannot be deleted because the individual' +
					     ' is used as attention name on a case.',null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	Update 	NAME 
	set 	MAINCONTACT = null
	where 	NAMENO = @pnNameKey 
		and MAINCONTACT = @nRelatedNameKey

	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from ASSOCIATEDNAME
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		NAMENO = @nFromNameKey and
		RELATIONSHIP = @psRelationshipCode and
		RELATEDNAME = @nRelatedNameKey and
		SEQUENCE = @pnSequence
	"
		
	Set @sAnd = " and "

	If @pbIsPropertyTypeCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"PROPERTYTYPE = @psOldPropertyTypeCode"
	End

	If @pbIsCountryCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"COUNTRYCODE = @psOldCountryCode"
	End

	If @pbIsActionCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ACTION = @psOldActionCode"
	End

	If @pbIsAttentionKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CONTACT = @pnOldAttentionKey"
	End

	If @pbIsJobRoleKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"JOBROLE = @pnOldJobRoleKey"
	End

	If @pbIsUseInMailingInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"USEINMAILING = @pbOldUseInMailing"
	End

	If @pbIsCeaseDateInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CEASEDDATE = @pdtOldCeaseDate"
	End

	If @pbIsPositionCategoryKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"POSITIONCATEGORY = @pnOldPositionCategoryKey"
	End

	If @pbIsPositionInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"POSITION = @psOldPosition"
	End

	If @pbIsPhoneKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"TELEPHONE = @pnOldPhoneKey"
	End

	If @pbIsFaxKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"FAX = @pnOldFaxKey"
	End

	If @pbIsPostalAddressKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"POSTALADDRESS = @pnOldPostalAddressKey"
	End

	If @pbIsStreetAddressKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"STREETADDRESS = @pnOldStreetAddressKey"
	End

	If @pbIsUseInformalSalutationInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"USEINFORMAL = @pbOldUseInformalSalutation"
	End

	If @pbIsValedictionKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"VALEDICTION = @pnOldValedictionKey"
	End

	If @pbIsNotesInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"NOTES = @psOldNotes"
	End

	If @pbIsIsCRMOnlyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CRMONLY = @pbOldIsCRMOnly"
	End
	
	If @pbIsFormatProfileKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"FORMATPROFILEID = @pnOldFormatProfileKey"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
			@nFromNameKey			int,
			@psRelationshipCode		nvarchar(3),
			@nRelatedNameKey		int,
			@pnSequence			smallint,
			@psOldPropertyTypeCode		nchar(1),
			@psOldCountryCode		nvarchar(3),
			@psOldActionCode		nvarchar(2),
			@pnOldAttentionKey		int,
			@pnOldJobRoleKey		int,
			@pbOldUseInMailing		bit,
			@pdtOldCeaseDate		datetime,
			@pnOldPositionCategoryKey	int,
			@psOldPosition			nvarchar(60),
			@pnOldPhoneKey			int,
			@pnOldFaxKey			int,
			@pnOldPostalAddressKey		int,
			@pnOldStreetAddressKey		int,
			@pbOldUseInformalSalutation	bit,
			@pnOldValedictionKey		int,
			@psOldNotes			nvarchar(254),
			@pbOldIsCRMOnly			bit,
			@pnOldFormatProfileKey          int',
			@nFromNameKey	 		= @nFromNameKey,
			@psRelationshipCode	 	= @psRelationshipCode,
			@nRelatedNameKey	 	= @nRelatedNameKey,
			@pnSequence	 		= @pnSequence,
			@psOldPropertyTypeCode	 	= @psOldPropertyTypeCode,
			@psOldCountryCode	 	= @psOldCountryCode,
			@psOldActionCode	 	= @psOldActionCode,
			@pnOldAttentionKey	 	= @pnOldAttentionKey,
			@pnOldJobRoleKey	 	= @pnOldJobRoleKey,
			@pbOldUseInMailing	 	= @pbOldUseInMailing,
			@pdtOldCeaseDate	 	= @pdtOldCeaseDate,
			@pnOldPositionCategoryKey	= @pnOldPositionCategoryKey,
			@psOldPosition	 		= @psOldPosition,
			@pnOldPhoneKey	 		= @pnOldPhoneKey,
			@pnOldFaxKey	 		= @pnOldFaxKey,
			@pnOldPostalAddressKey	 	= @pnOldPostalAddressKey,
			@pnOldStreetAddressKey	 	= @pnOldStreetAddressKey,
			@pbOldUseInformalSalutation	= @pbOldUseInformalSalutation,
			@pnOldValedictionKey	 	= @pnOldValedictionKey,
			@psOldNotes	 		= @psOldNotes,
			@pbOldIsCRMOnly			= @pbOldIsCRMOnly,
			@pnOldFormatProfileKey          = @pnOldFormatProfileKey

End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteAssociatedName to public
GO
