-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateCaseImage									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateCaseImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateCaseImage.'
	Drop procedure [dbo].[csw_UpdateCaseImage]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateCaseImage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateCaseImage
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnImageKey			int,		-- Mandatory
	@pnImageTypeKey			int		 = null,
	@pnImageSequence		smallint	= null,
	@psCaseImageDescription		nvarchar(254)	= null,
	@psDesignElementID		nvarchar(20)	= null,
	@pnOldImageKey			int,		-- Mandatory
	@pnOldImageTypeKey		int		= null,
	@pnOldImageSequence		smallint	= null,
	@psOldCaseImageDescription	nvarchar(254)	= null,
	@psOldDesignElementID		nvarchar(20)	= null,
	@pbIsImageKeyInUse		bit	 	= 0,
	@pbIsImageTypeKeyInUse		bit	 	= 0,
	@pbIsImageSequenceInUse		bit	 	= 0,
	@pbIsCaseImageDescriptionInUse	bit	 	= 0,
	@pbIsDesignElementIDInUse	bit	 	= 0
)
as
-- PROCEDURE:	csw_UpdateCaseImage
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update CaseImage if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 11 Nov 2005	TM	RFC3203	1	Procedure created
-- 18 Apr 2006	AU	RFC3203	2	Made IMAGEID modifiable
-- 25 Mar 2008	AT	RFC6079	3	Added PK violation check.
-- 13 May 2008	AT	RFC6590	4	Fixed PK violation check.

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
Declare @sAlertXML		nvarchar(400)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	if exists(select 1 from CASEIMAGE WHERE CASEID = @pnCaseKey and IMAGEID = @pnImageKey) and (@pnOldImageKey != @pnImageKey and @pbIsImageKeyInUse = 1)
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS84', 'The selected image is already attached to the case. Please select a different image or upload a new image and try again.',
								null, null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = 1
	End
End

If @nErrorCode = 0
Begin

	

	Set @sUpdateString = "Update CASEIMAGE
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		CASEID = @pnCaseKey and
		IMAGEID = @pnOldImageKey and"

	If @pbIsImageKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"IMAGEID = @pnImageKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"IMAGEID = @pnOldImageKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsImageTypeKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"IMAGETYPE = @pnImageTypeKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"IMAGETYPE = @pnOldImageTypeKey"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsImageSequenceInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"IMAGESEQUENCE = @pnImageSequence"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"IMAGESEQUENCE = @pnOldImageSequence"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsCaseImageDescriptionInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CASEIMAGEDESC = @psCaseImageDescription"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CASEIMAGEDESC = @psOldCaseImageDescription"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	If @pbIsDesignElementIDInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FIRMELEMENTID = @psDesignElementID"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FIRMELEMENTID = @psOldDesignElementID"
		Set @sComma = ","
		Set @sAnd = " and "
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnCaseKey			int,
			@pnImageKey			int,
			@pnImageTypeKey			int,
			@pnImageSequence		smallint,
			@psCaseImageDescription		nvarchar(254),
			@psDesignElementID		nvarchar(20),
			@pnOldImageKey			int,
			@pnOldImageTypeKey		int,
			@pnOldImageSequence		smallint,
			@psOldCaseImageDescription	nvarchar(254),
			@psOldDesignElementID		nvarchar(20)',
			@pnCaseKey	 		= @pnCaseKey,
			@pnImageKey	 		= @pnImageKey,
			@pnImageTypeKey	 		= @pnImageTypeKey,
			@pnImageSequence	 	= @pnImageSequence,
			@psCaseImageDescription	 	= @psCaseImageDescription,
			@psDesignElementID	 	= @psDesignElementID,
			@pnOldImageKey			= @pnOldImageKey,
			@pnOldImageTypeKey		= @pnOldImageTypeKey,
			@pnOldImageSequence	 	= @pnOldImageSequence,
			@psOldCaseImageDescription	= @psOldCaseImageDescription,
			@psOldDesignElementID		= @psOldDesignElementID
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateCaseImage to public
GO