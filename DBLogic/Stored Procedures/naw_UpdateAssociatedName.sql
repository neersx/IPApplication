-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateAssociatedName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateAssociatedName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateAssociatedName.'
	Drop procedure [dbo].[naw_UpdateAssociatedName]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateAssociatedName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateAssociatedName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@psRelationshipCode		nvarchar(3),	-- Mandatory
	@pnAssociatedNameKey		int,		-- Mandatory
	@pnSequence			smallint,	-- Mandatory
	@pbIsReverse			bit		= null,
	@psPropertyTypeCode		nchar(1)	= null,
	@psCountryCode			nvarchar(3)	= null,
	@psActionCode			nvarchar(2)	= null,
	@pnAttentionKey			int		= null,
	@pnJobRoleKey			int		= null,
	@pbUseInMailing			bit		= null,
	@pdtCeaseDate			datetime	= null,
	@pnPositionCategoryKey		int		= null,
	@psPosition			nvarchar(60)	= null,
	@pnPhoneKey			int		= null,
	@pnFaxKey			int		= null,
	@pnPostalAddressKey		int		= null,
	@pnStreetAddressKey		int		= null,
	@pbUseInformalSalutation	bit		= null,
	@pnValedictionKey		int		= null,
	@psNotes			nvarchar(254)	= null,
	@pbIsCRMOnly			bit		= null,
	@pnFormatProfileKey             int             = null,
	@psOldRelationshipCode		nvarchar(3)	= null,
	@pnOldAssociatedNameKey		int		= null,
	@pbOldIsReverse			bit		= null,
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
	@pbIsRelationshipCodeInUse	bit	 	= 0,
	@pbIsAssociatedNameKeyInUse	bit	 	= 0,
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
-- PROCEDURE:	naw_UpdateAssociatedName
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update AssociatedName if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Apr 2006	IB	RFC3768	1	Procedure created
-- 18 Oct 2007	PG	RFC3501	2	Fix IsReverse issues
-- 30 Jun 2008	AT	RFC5787	3	Added IsCRMOnly flag
-- 30 Mar 2010  LP      RFC7276 4       Added FormatProfileKey field.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)
Declare @nFromNameKey		int
Declare @nRelatedNameKey	int
Declare @nOldFromNameKey	int
Declare @nOldRelatedNameKey	int

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @pbIsReverse = 1 and @pbOldIsReverse =1
Begin
	Set @nFromNameKey 		= @pnAssociatedNameKey 
	Set @nRelatedNameKey 	= @pnNameKey 
	Set @nOldFromNameKey 	= @pnOldAssociatedNameKey 
	Set @nOldRelatedNameKey = @pnNameKey 
End
If @pbIsReverse = 0 and @pbOldIsReverse =0
Begin
	Set @nFromNameKey 		= @pnNameKey 
	Set @nRelatedNameKey 	= @pnAssociatedNameKey 
	Set @nOldFromNameKey 	= @pnNameKey 
	Set @nOldRelatedNameKey = @pnOldAssociatedNameKey 
End

If @nErrorCode = 0 AND (@pbIsReverse = @pbOldIsReverse)
Begin
	Set @sUpdateString = "Update ASSOCIATEDNAME
			   set NAMENO = @nFromNameKey"

	Set @sWhereString = @sWhereString+CHAR(10)+"
		NAMENO = @nOldFromNameKey and
		SEQUENCE = @pnSequence
	"

	Set @sComma = ","
	Set @sAnd = " and "

	If @pbIsRelationshipCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RELATIONSHIP = @psRelationshipCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"RELATIONSHIP = @psOldRelationshipCode"
	End

	If @pbIsAssociatedNameKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"RELATEDNAME = @nRelatedNameKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"RELATEDNAME = @nOldRelatedNameKey"
	End

	If @pbIsPropertyTypeCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"PROPERTYTYPE = @psPropertyTypeCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"PROPERTYTYPE = @psOldPropertyTypeCode"
	End

	If @pbIsCountryCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"COUNTRYCODE = @psCountryCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"COUNTRYCODE = @psOldCountryCode"
	End

	If @pbIsActionCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ACTION = @psActionCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ACTION = @psOldActionCode"
	End

	If @pbIsAttentionKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CONTACT = @pnAttentionKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CONTACT = @pnOldAttentionKey"
	End

	If @pbIsJobRoleKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"JOBROLE = @pnJobRoleKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"JOBROLE = @pnOldJobRoleKey"
	End

	If @pbIsUseInMailingInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"USEINMAILING = @pbUseInMailing"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"USEINMAILING = @pbOldUseInMailing"
	End

	If @pbIsCeaseDateInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CEASEDDATE = @pdtCeaseDate"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CEASEDDATE = @pdtOldCeaseDate"
	End

	If @pbIsPositionCategoryKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POSITIONCATEGORY = @pnPositionCategoryKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"POSITIONCATEGORY = @pnOldPositionCategoryKey"
	End

	If @pbIsPositionInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POSITION = @psPosition"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"POSITION = @psOldPosition"
	End

	If @pbIsPhoneKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"TELEPHONE = @pnPhoneKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"TELEPHONE = @pnOldPhoneKey"
	End

	If @pbIsFaxKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FAX = @pnFaxKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FAX = @pnOldFaxKey"
	End

	If @pbIsPostalAddressKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"POSTALADDRESS = @pnPostalAddressKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"POSTALADDRESS = @pnOldPostalAddressKey"
	End

	If @pbIsStreetAddressKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STREETADDRESS = @pnStreetAddressKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"STREETADDRESS = @pnOldStreetAddressKey"
	End

	If @pbIsUseInformalSalutationInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"USEINFORMAL = @pbUseInformalSalutation"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"USEINFORMAL = @pbOldUseInformalSalutation"
	End

	If @pbIsValedictionKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"VALEDICTION = @pnValedictionKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"VALEDICTION = @pnOldValedictionKey"
	End

	If @pbIsNotesInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NOTES = @psNotes"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NOTES = @psOldNotes"
	End

	If @pbIsIsCRMOnlyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CRMONLY = @pbIsCRMOnly"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CRMONLY = @pbOldIsCRMOnly"
	End
	
	If @pbIsFormatProfileKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FORMATPROFILEID = @pnFormatProfileKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FORMATPROFILEID = @pnOldFormatProfileKey"
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@nFromNameKey			int,
			@psRelationshipCode		nvarchar(3),
			@nRelatedNameKey		int,
			@pnSequence			smallint,
			@psPropertyTypeCode		nchar(1),
			@psCountryCode			nvarchar(3),
			@psActionCode			nvarchar(2),
			@pnAttentionKey			int,
			@pnJobRoleKey			int,
			@pbUseInMailing			bit,
			@pdtCeaseDate			datetime,
			@pnPositionCategoryKey		int,
			@psPosition			nvarchar(60),
			@pnPhoneKey			int,
			@pnFaxKey			int,
			@pnPostalAddressKey		int,
			@pnStreetAddressKey		int,
			@pbUseInformalSalutation	bit,
			@pnValedictionKey		int,
			@psNotes			nvarchar(254),
			@pbIsCRMOnly			bit,
			@pnFormatProfileKey             int,
			@nOldFromNameKey		int,
			@psOldRelationshipCode		nvarchar(3),
			@nOldRelatedNameKey		int,
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
			@psPropertyTypeCode	 	= @psPropertyTypeCode,
			@psCountryCode	 		= @psCountryCode,
			@psActionCode	 		= @psActionCode,
			@pnAttentionKey	 		= @pnAttentionKey,
			@pnJobRoleKey	 		= @pnJobRoleKey,
			@pbUseInMailing	 		= @pbUseInMailing,
			@pdtCeaseDate	 		= @pdtCeaseDate,
			@pnPositionCategoryKey	 	= @pnPositionCategoryKey,
			@psPosition	 		= @psPosition,
			@pnPhoneKey	 		= @pnPhoneKey,
			@pnFaxKey	 		= @pnFaxKey,
			@pnPostalAddressKey	 	= @pnPostalAddressKey,
			@pnStreetAddressKey	 	= @pnStreetAddressKey,
			@pbUseInformalSalutation	= @pbUseInformalSalutation,
			@pnValedictionKey	 	= @pnValedictionKey,
			@psNotes	 		= @psNotes,
			@pbIsCRMOnly			= @pbIsCRMOnly,
			@pnFormatProfileKey             = @pnFormatProfileKey,
			@nOldFromNameKey	 	= @nOldFromNameKey,
			@psOldRelationshipCode		= @psOldRelationshipCode,
			@psOldPropertyTypeCode	 	= @psOldPropertyTypeCode,
			@nOldRelatedNameKey		= @nOldRelatedNameKey,
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

Grant execute on dbo.naw_UpdateAssociatedName to public
GO