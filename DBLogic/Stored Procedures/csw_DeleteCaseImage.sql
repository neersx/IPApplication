-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteCaseImage									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteCaseImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteCaseImage.'
	Drop procedure [dbo].[csw_DeleteCaseImage]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteCaseImage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteCaseImage
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@pnImageKey			int,		-- Mandatory
	@pnOldImageTypeKey		int		= null,
	@pnOldImageSequence		smallint	= null,
	@psOldCaseImageDescription	nvarchar(254)	= null,
	@psOldDesignElementID		nvarchar(20)	= null,
	@pbIsImageTypeKeyInUse		bit	 	= 0,
	@pbIsImageSequenceInUse		bit	 	= 0,
	@pbIsCaseImageDescriptionInUse	bit	 	= 0,
	@pbIsDesignElementIDInUse	bit	 	= 0
)
as
-- PROCEDURE:	csw_DeleteCaseImage
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete CaseImage if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 11 Nov 2005	TM	RFC3203	1	Procedure created

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

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from CASEIMAGE
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		CASEID = @pnCaseKey and
		IMAGEID = @pnImageKey and"

	If @pbIsImageTypeKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"IMAGETYPE = @pnOldImageTypeKey"
		Set @sAnd = " and "
	End

	If @pbIsImageSequenceInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"IMAGESEQUENCE = @pnOldImageSequence"
		Set @sAnd = " and "
	End

	If @pbIsCaseImageDescriptionInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CASEIMAGEDESC = @psOldCaseImageDescription"
		Set @sAnd = " and "
	End

	If @pbIsDesignElementIDInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"FIRMELEMENTID = @psOldDesignElementID"
		Set @sAnd = " and "
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
		      N'@pnCaseKey			int,
			@pnImageKey			int,
			@pnOldImageTypeKey		int,
			@pnOldImageSequence		smallint,
			@psOldCaseImageDescription	nvarchar(254),
			@psOldDesignElementID		nvarchar(20)',
			@pnCaseKey	 		= @pnCaseKey,
			@pnImageKey	 		= @pnImageKey,
			@pnOldImageTypeKey	 	= @pnOldImageTypeKey,
			@pnOldImageSequence	 	= @pnOldImageSequence,
			@psOldCaseImageDescription	= @psOldCaseImageDescription,
			@psOldDesignElementID	 	= @psOldDesignElementID
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteCaseImage to public
GO

