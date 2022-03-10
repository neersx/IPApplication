-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteAttachment									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteAttachment.'
	Drop procedure [dbo].[ipw_DeleteAttachment]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteAttachment
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnActivityKey		int,	-- Mandatory
	@pnSequenceKey		int,	-- Mandatory
	@psOldAttachmentName	nvarchar(508)		 = null,
	@psOldLocation	nvarchar(508)		 = null,
	@psOldAttachmentDescription	nvarchar(508)		 = null,
	@pbOldIsPublic	bit		 = null,
	@pnOldAttachmentTypeKey	int		 = null,
	@pnOldLanguageKey	int		 = null,
	@pnOldPageCount	int		 = null
)
as
-- PROCEDURE:	ipw_DeleteAttachment
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Attachment if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Sep 2008	SF		RFC5745	1		Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @sSQLString 		nvarchar(4000)
Declare @nErrorCode			int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
			Delete from ACTIVITYATTACHMENT
			   where	ACTIVITYNO = @pnActivityKey
				and		SEQUENCENO = @pnSequenceKey
				and		ATTACHMENTNAME = @psOldAttachmentName
				and		FILENAME = @psOldLocation
				and		ATTACHMENTDESC = @psOldAttachmentDescription
				and		PUBLICFLAG = @pbOldIsPublic
				and		ATTACHMENTTYPE = @pnOldAttachmentTypeKey
				and		LANGUAGENO = @pnOldLanguageKey
				and		PAGECOUNT = @pnOldPageCount
"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnActivityKey		int,
			@pnSequenceKey		int,
			@psOldAttachmentName		nvarchar(254),
			@psOldLocation		nvarchar(254),
			@psOldAttachmentDescription		nvarchar(254),
			@pbOldIsPublic		bit,
			@pnOldAttachmentTypeKey		int,
			@pnOldLanguageKey		int,
			@pnOldPageCount		int',
			@pnActivityKey	 = @pnActivityKey,
			@pnSequenceKey	 = @pnSequenceKey,
			@psOldAttachmentName	 = @psOldAttachmentName,
			@psOldLocation	 = @psOldLocation,
			@psOldAttachmentDescription	 = @psOldAttachmentDescription,
			@pbOldIsPublic	 = @pbOldIsPublic,
			@pnOldAttachmentTypeKey	 = @pnOldAttachmentTypeKey,
			@pnOldLanguageKey	 = @pnOldLanguageKey,
			@pnOldPageCount	 = @pnOldPageCount


End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteAttachment to public
GO