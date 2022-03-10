-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertCaseImage									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertCaseImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertCaseImage.'
	Drop procedure [dbo].[csw_InsertCaseImage]
End
Print '**** Creating Stored Procedure dbo.csw_InsertCaseImage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_InsertCaseImage
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory.
	@pnImageKey			int,		-- Mandatory.
	@pnImageTypeKey			int		= null,
	@pnImageSequence		smallint	= null,
	@psCaseImageDescription		nvarchar(254)	= null,
	@psDesignElementID		nvarchar(20)	= null,
	@pbIsImageTypeKeyInUse		bit	 	= 0,
	@pbIsImageSequenceInUse		bit	 	= 0,
	@pbIsCaseImageDescriptionInUse	bit	 	= 0,
	@pbIsDesignElementIDInUse	bit	 	= 0
)
as
-- PROCEDURE:	csw_InsertCaseImage
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert CaseImage.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 11 Nov 2005	TM	RFC3203	1	Procedure created
-- 25 Mar 2008	AT	RFC6079	2	Added PK violation check.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAlertXML		nvarchar(400)


-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	if exists(select 1 from CASEIMAGE WHERE CASEID = @pnCaseKey and IMAGEID = @pnImageKey)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS84', 'The selected image is already attached to the case. Please select a different image or upload a new image and try again.',
								null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = 1
	End
End

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into CASEIMAGE
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
						CASEID,IMAGEID
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
						@pnCaseKey,@pnImageKey
			"

	If @pbIsImageTypeKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"IMAGETYPE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnImageTypeKey"
		Set @sComma = ","
	End

	If @pbIsImageSequenceInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"IMAGESEQUENCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnImageSequence"
		Set @sComma = ","
	End

	If @pbIsCaseImageDescriptionInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"CASEIMAGEDESC"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psCaseImageDescription"
		Set @sComma = ","
	End

	If @pbIsDesignElementIDInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"FIRMELEMENTID"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psDesignElementID"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnCaseKey		int,
			@pnImageKey		int,
			@pnImageTypeKey		int,
			@pnImageSequence	smallint,
			@psCaseImageDescription	nvarchar(254),
			@psDesignElementID	nvarchar(20)',
			@pnCaseKey	 	= @pnCaseKey,
			@pnImageKey		= @pnImageKey,
			@pnImageTypeKey	 	= @pnImageTypeKey,
			@pnImageSequence	= @pnImageSequence,
			@psCaseImageDescription	= @psCaseImageDescription,
			@psDesignElementID	= @psDesignElementID
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertCaseImage to public
GO