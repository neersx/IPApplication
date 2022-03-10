-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertAssociatedName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertAssociatedName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertAssociatedName.'
	Drop procedure [dbo].[naw_InsertAssociatedName]
End
Print '**** Creating Stored Procedure dbo.naw_InsertAssociatedName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertAssociatedName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory.
	@psRelationshipCode		nvarchar(3),	-- Mandatory.
	@pnAssociatedNameKey		int,		-- Mandatory.
	@pnSequence			smallint	output,
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
-- PROCEDURE:	naw_InsertAssociatedName
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert AssociatedName.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Apr 2006	IB	RFC3768	1	Procedure created
-- 25 Mar 2008	Ash	RFC5438	2	Maintain data in different culture
-- 15 Apr 2008	SF	RFC6454	3	Backout changes made in RFC5438 temporarily
-- 30 Jun 2008	AT	RFC5787	4	Added IsCRMOnly flag
-- 29 Oct 2009	AT	RFC8467 5	Do not add emp name if it has been added by the picklist.
-- 30 Mar 2010  LP      RFC7276 6       Added FormatProfileKey column.
-- 24 Dec 2014	DV	R37681	7	Remove position check when checking if association has already been added.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sDBCulture		nvarchar(10)
Declare @bCancelInsert	bit

-- Initialise variables
Set @nErrorCode = 0
Set @bCancelInsert = 0

Set @sValuesString = CHAR(10)+" values ("

IF (@psRelationshipCode = 'EMP')
Begin
	-- Check if the relationship was already added with the new name
	if exists (
		Select * from ASSOCIATEDNAME AN
		join NAME N on (N.NAMENO = case when @pbIsReverse = 1 then @pnNameKey else @pnAssociatedNameKey end
						and N.LOGTRANSACTIONNO = AN.LOGTRANSACTIONNO
						and N.LOGIDENTITYID = AN.LOGIDENTITYID)
		Where AN.NAMENO = case when @pbIsReverse = 1 then @pnAssociatedNameKey else @pnNameKey end
		and AN.RELATIONSHIP = 'EMP'
		and AN.RELATEDNAME = case when @pbIsReverse = 1 then @pnNameKey else @pnAssociatedNameKey end
		and AN.SEQUENCE = 0
		and AN.PROPERTYTYPE IS NULL 
		and AN.COUNTRYCODE IS NULL 
		and AN.ACTION IS NULL 
		and AN.CONTACT IS NULL
		and AN.USEINMAILING is null
		and AN.CEASEDDATE IS NULL
		and AN.POSITIONCATEGORY IS NULL
		and AN.TELEPHONE IS NULL
		and AN.FAX IS NULL
		and AN.POSTALADDRESS IS NULL
		and AN.STREETADDRESS IS NULL
		and AN.USEINFORMAL IS NULL
		and AN.VALEDICTION IS NULL
		and AN.NOTES IS NULL
	)
	Begin
		if @psPosition is null
		Begin
			Select @psPosition = POSITION from ASSOCIATEDNAME Where NAMENO = case when @pbIsReverse = 1 then @pnAssociatedNameKey else @pnNameKey end
				and RELATIONSHIP = 'EMP'
				and RELATEDNAME = Case when @pbIsReverse = 1 then @pnNameKey else @pnAssociatedNameKey end
				and SEQUENCE = 0
		End
		-- Emp relationship already added by name picklist
		-- We need an update, not an insert.
		Set @sSQLString = "Update ASSOCIATEDNAME
			Set	PROPERTYTYPE = @psPropertyTypeCode,
				COUNTRYCODE = @psCountryCode,
				ACTION = @psActionCode,
				CONTACT = @pnAttentionKey,
				JOBROLE = @pnJobRoleKey,
				USEINMAILING = @pbUseInMailing,
				CEASEDDATE = @pdtCeaseDate,
				POSITIONCATEGORY = @pnPositionCategoryKey,
				POSITION = @psPosition,
				TELEPHONE = @pnPhoneKey,
				FAX = @pnFaxKey,
				POSTALADDRESS = @pnPostalAddressKey,
				STREETADDRESS = @pnStreetAddressKey,
				USEINFORMAL = @pbUseInformalSalutation,
				VALEDICTION = @pnValedictionKey,
				NOTES = @psNotes,
				CRMONLY = @pbIsCRMOnly
				Where NAMENO = case when @pbIsReverse = 1 then @pnAssociatedNameKey else @pnNameKey end
				and RELATIONSHIP = 'EMP'
				and RELATEDNAME = Case when @pbIsReverse = 1 then @pnNameKey else @pnAssociatedNameKey end
				and SEQUENCE = 0"
		
		Set @bCancelInsert = 1	
	End
End

If @nErrorCode = 0 and @bCancelInsert = 0
Begin
	If @pbIsReverse = 1
	Begin
		Select @pnSequence = isnull(max(A.SEQUENCE), -1) + 1
		from ASSOCIATEDNAME A
		where A.NAMENO = @pnAssociatedNameKey
		and A.RELATIONSHIP = @psRelationshipCode
		and A.RELATEDNAME = @pnNameKey
	End
	Else
	Begin
		Select @pnSequence = isnull(max(A.SEQUENCE), -1) + 1
		from ASSOCIATEDNAME A
		where A.NAMENO = @pnNameKey
		and A.RELATIONSHIP = @psRelationshipCode
		and A.RELATEDNAME = @pnAssociatedNameKey
	End

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0 and @bCancelInsert = 0
Begin
	Set @sInsertString = "Insert into ASSOCIATEDNAME
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			NAMENO,RELATIONSHIP,RELATEDNAME,SEQUENCE
			"

	If @pbIsReverse = 1
	Begin
		Set @sValuesString = @sValuesString+CHAR(10)+"
				@pnAssociatedNameKey,@psRelationshipCode,@pnNameKey,@pnSequence
				"
	End
	Else
	Begin
		Set @sValuesString = @sValuesString+CHAR(10)+"
				@pnNameKey,@psRelationshipCode,@pnAssociatedNameKey,@pnSequence
				"
	End

	If @pbIsPropertyTypeCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PROPERTYTYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPropertyTypeCode"
	End

	If @pbIsCountryCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"COUNTRYCODE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCountryCode"
	End

	If @pbIsActionCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ACTION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psActionCode"
	End

	If @pbIsAttentionKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CONTACT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnAttentionKey"
	End

	If @pbIsJobRoleKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"JOBROLE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnJobRoleKey"
	End

	If @pbIsUseInMailingInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"USEINMAILING"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbUseInMailing"
	End

	If @pbIsCeaseDateInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CEASEDDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtCeaseDate"
	End

	If @pbIsPositionCategoryKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POSITIONCATEGORY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPositionCategoryKey"
	End

	If @pbIsPositionInUse = 1
	-- Only insert to base table if culture matches
	--and @psCulture = @sDBCulture
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POSITION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPosition"
	End

	If @pbIsPhoneKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"TELEPHONE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPhoneKey"
	End

	If @pbIsFaxKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FAX"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnFaxKey"
	End

	If @pbIsPostalAddressKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POSTALADDRESS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPostalAddressKey"
	End

	If @pbIsStreetAddressKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STREETADDRESS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnStreetAddressKey"
	End

	If @pbIsUseInformalSalutationInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"USEINFORMAL"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbUseInformalSalutation"
	End

	If @pbIsValedictionKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"VALEDICTION"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnValedictionKey"
	End

	If @pbIsNotesInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NOTES"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psNotes"
	End

	If @pbIsIsCRMOnlyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CRMONLY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pbIsCRMOnly"
	End
	
	If @pbIsFormatProfileKeyInUse = 1
	Begin
	        Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FORMATPROFILEID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnFormatProfileKey"
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString
		
End

If @nErrorCode = 0
Begin

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnNameKey			int,
			@psRelationshipCode		nvarchar(3),
			@pnAssociatedNameKey		int,
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
			@pbIsReverse		        bit,
			@pnFormatProfileKey             int',
			@pnNameKey	 		= @pnNameKey,
			@psRelationshipCode	 	= @psRelationshipCode,
			@pnAssociatedNameKey	 	= @pnAssociatedNameKey,
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
			@pbIsReverse		        = @pbIsReverse,
			@pnFormatProfileKey             = @pnFormatProfileKey

	-- Publish Sequence
	Select @pnSequence	as Sequence

End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertAssociatedName to public
GO