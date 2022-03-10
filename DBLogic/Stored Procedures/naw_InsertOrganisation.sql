-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertOrganisation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertOrganisation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertOrganisation.'
	Drop procedure [dbo].[naw_InsertOrganisation]
End
Print '**** Creating Stored Procedure dbo.naw_InsertOrganisation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertOrganisation
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@psRegistrationNo		nvarchar(30)	= null,
	@psIncorporated			nvarchar(254)	= null,
	@pnParentNameKey		int		= null,
	@pbIsRegistrationNoInUse	bit	 	= 0,
	@pbIsIncorporatedInUse		bit	 	= 0,
	@pbIsParentNameKeyInUse		bit	 	= 0
)
as
-- PROCEDURE:	naw_InsertOrganisation
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Organisation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 10 Apr 2006	AU	RFC3505	1	Procedure created
-- 25 Mar 2008	Ash	RFC5438	2	Maintain data in different culture
-- 15 Apr 2008	SF	RFC6454	3	Backout changes made in RFC5438 temporarily
-- 10 May 2010	PA	RFC9097	4	Remove the insertion of VATNO as the TAXNO will be inserted from the NAME table

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapte
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sDBCulture		nvarchar(10)
-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into ORGANISATION
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			NAMENO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
			@pnNameKey
			"

	If @pbIsRegistrationNoInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REGISTRATIONNO"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psRegistrationNo"
		Set @sComma = ","
	End

	If @pbIsIncorporatedInUse = 1 
	-- Only insert to base table if culture matches
	--and @psCulture = @sDBCulture
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"INCORPORATED"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psIncorporated"
		Set @sComma = ","
	End

	If @pbIsParentNameKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"PARENT"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnParentNameKey"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@psRegistrationNo	nvarchar(30),
			@psIncorporated		nvarchar(254),
			@pnParentNameKey	int',
			@pnNameKey	 	= @pnNameKey,
			@psRegistrationNo	= @psRegistrationNo,
			@psIncorporated	 	= @psIncorporated,
			@pnParentNameKey	= @pnParentNameKey
End
	
	-- If culture doesn't match the database main culture, we need to maintain the translated data.
	/*
	If @nErrorCode = 0
	and @psCulture <> @sDBCulture
	Begin

		Set @sSQLString = "
			Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT)
			select INCORPORATED_TID, @psCulture, @psIncorporated
			from ORGANISATION
			where NAMENO=@pnNameKey "

		exec @nErrorCode=sp_executesql @sSQLString,
					N'
					@pnNameKey		int,
					@psCulture		nvarchar(10),
					@psIncorporated		nvarchar(254)',
					@pnNameKey		= @pnNameKey,
					@psCulture		= @psCulture,
					@psIncorporated= @psIncorporated
	End
	*/
Return @nErrorCode
GO

Grant execute on dbo.naw_InsertOrganisation to public
GO