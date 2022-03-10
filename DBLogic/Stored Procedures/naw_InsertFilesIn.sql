
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertFilesIn									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertFilesIn]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertFilesIn.'
	Drop procedure [dbo].[naw_InsertFilesIn]
End
Print '**** Creating Stored Procedure dbo.naw_InsertFilesIn...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertFilesIn
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory.
	@psCountryCode		nvarchar(3),	-- Mandatory.
	@psNotes		nvarchar(254)	= null,
	@pbIsNotesInUse		bit	 	= 0
)
as
-- PROCEDURE:	naw_InsertFilesIn
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert FilesIn.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 11 Apr 2006	IB	RFC3762	1	Procedure created
-- 25 Mar 2008	Ash	RFC5438	2	Maintain data in different culture
-- 15 Apr 2008	SF	RFC6454	3	Backout changes made in RFC5438 temporarily

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString	nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sDBCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0

Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into FILESIN
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
						NAMENO,COUNTRYCODE
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
						@pnNameKey,@psCountryCode
			"

	If @pbIsNotesInUse = 1
	-- Only insert to base table if culture matches
	--and @psCulture = @sDBCulture
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NOTES"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psNotes"
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnNameKey	int,
			@psCountryCode	nvarchar(3),
			@psNotes	nvarchar(254)',
			@pnNameKey	 = @pnNameKey,
			@psCountryCode	 = @psCountryCode,
			@psNotes	 = @psNotes

End
-- If culture doesn't match the database main culture, we need to maintain the translated data.
/*
If @nErrorCode = 0
and @psCulture <> @sDBCulture
Begin

	Set @sSQLString = "
		Insert into TRANSLATEDTEXT (TID, CULTURE, SHORTTEXT)
		select NOTES_TID, @psCulture, @psNotes
		from FILESIN
		where NAMENO=@pnNameKey and COUNTRYCODE=@psCountryCode"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnNameKey		int,
				@psCulture		nvarchar(10),
				@psCountryCode	nvarchar(3),
				@psNotes		nvarchar(254)',
				@pnNameKey		= @pnNameKey,
				@psCulture		= @psCulture,
				@psCountryCode	= @psCountryCode,
				@psNotes= @psNotes
End
*/

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertFilesIn to public
GO