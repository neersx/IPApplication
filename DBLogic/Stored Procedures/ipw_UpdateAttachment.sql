-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateAttachment									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateAttachment.'
	Drop procedure [dbo].[ipw_UpdateAttachment]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateAttachment
(
	@pnUserIdentityId					int,		-- Mandatory
	@psCulture							nvarchar(10) 	= null,
	@pbCalledFromCentura				bit		= 0,
	@pnActivityKey						int,	-- Mandatory
	@pnSequenceKey						int,	-- Mandatory
	@pnCaseKey							int = null,
	@pnNameKey							int = null,
	@pnActivityTypeKey					int = null,
	@pnActivityCategoryKey				int = null,
	@pdtActivityDate					datetime = null,
	@psActivitySummary					nvarchar(200)		 = null,
	@psAttachmentName					nvarchar(508)		 = null,
	@psLocation							nvarchar(508)		 = null,
	@psAttachmentDescription			nvarchar(508)		 = null,
	@pbIsPublic							bit		 = null,
	@pnAttachmentTypeKey				int		 = null,
	@pnLanguageKey						int		 = null,
	@pnPageCount						int		 = null,
	@pnOldCaseKey						int = null,
	@pnOldNameKey						int = null,
	@pnOldActivityTypeKey				int = null,
	@pnOldActivityCategoryKey			int = null,
	@pdtOldActivityDate					datetime = null,
	@psOldActivitySummary				nvarchar(200)		 = null,
	@psOldAttachmentName				nvarchar(508)		 = null,
	@psOldLocation						nvarchar(254)		 = null,
	@psOldAttachmentDescription			nvarchar(508)		 = null,
	@pbOldIsPublic						bit		 = null,
	@pnOldAttachmentTypeKey				int		 = null,
	@pnOldLanguageKey					int		 = null,
	@pnOldPageCount						int		 = null
)
as
-- PROCEDURE:	ipw_UpdateAttachment
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Attachment if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Sep 2008	SF		RFC5745	1		Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0


-- Update the Activity
If @nErrorCode = 0
and ((@pnCaseKey <> @pnOldCaseKey) or
	 (@pnNameKey <> @pnOldNameKey) or
	 (@pnActivityTypeKey <> @pnOldActivityTypeKey) or
	 (@pnActivityCategoryKey <> @pnOldActivityCategoryKey) or
	 (@pdtActivityDate <> @pdtOldActivityDate) or
	 (@psActivitySummary <> @psOldActivitySummary))
Begin

	Set @sSQLString = "	
	Update ACTIVITY 
	set	NAMENO				= @pnNameKey,
		ACTIVITYDATE		= @pdtActivityDate,
		CASEID				= @pnCaseKey,
		SUMMARY				= @psActivitySummary,
		ACTIVITYCATEGORY	= @pnActivityCategoryKey,
		ACTIVITYTYPE		= @pnActivityTypeKey	
	where   ACTIVITYNO		= @pnActivityKey
	and	NAMENO				= @pnOldNameKey
	and	ACTIVITYDATE		= @pdtOldActivityDate
	and	CASEID				= @pnOldCaseKey
	and	SUMMARY				= @psOldActivitySummary
	and	ACTIVITYCATEGORY	= @pnOldActivityCategoryKey
	and	ACTIVITYTYPE		= @pnOldActivityTypeKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@pnActivityKey				int,
						@pnCaseKey					int,
						@pnNameKey					int,
						@pnActivityTypeKey			int,
						@pnActivityCategoryKey		int,
						@pdtActivityDate			datetime,
						@psActivitySummary			nvarchar(200),
						@pnOldCaseKey				int,
						@pnOldNameKey				int,
						@pnOldActivityTypeKey		int,
						@pnOldActivityCategoryKey	int,
						@pdtOldActivityDate			datetime,
						@psOldActivitySummary		nvarchar(200)',					  
						@pnActivityKey				= @pnActivityKey,
						@pnCaseKey					= @pnCaseKey,
						@pnNameKey					= @pnNameKey,
						@pnActivityTypeKey			= @pnActivityTypeKey,
						@pnActivityCategoryKey		= @pnActivityCategoryKey,
						@pdtActivityDate			= @pdtActivityDate,
						@psActivitySummary			= @psActivitySummary,
						@pnOldCaseKey				= @pnOldCaseKey,
						@pnOldNameKey				= @pnOldNameKey,
						@pnOldActivityTypeKey		= @pnOldActivityTypeKey,
						@pnOldActivityCategoryKey	= @pnOldActivityCategoryKey,
						@pdtOldActivityDate			= @pdtOldActivityDate,
						@psOldActivitySummary		= @psOldActivitySummary
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
			Update ACTIVITYATTACHMENT
			   set	ATTACHMENTNAME	= @psAttachmentName,
					FILENAME		= @psLocation,
					ATTACHMENTDESC	= @psAttachmentDescription,
					PUBLICFLAG		= @pbIsPublic,
					ATTACHMENTTYPE	= @pnAttachmentTypeKey,
					LANGUAGENO		= @pnLanguageKey,
					PAGECOUNT		= @pnPageCount
			where	ACTIVITYNO		= @pnActivityKey 
			and		SEQUENCENO		= @pnSequenceKey 
			and		ATTACHMENTNAME	= @psOldAttachmentName
			and		FILENAME		= @psOldLocation
			and		ATTACHMENTDESC	= @psOldAttachmentDescription
			and		PUBLICFLAG		= @pbOldIsPublic
			and		ATTACHMENTTYPE	= @pnOldAttachmentTypeKey
			and		LANGUAGENO		= @pnOldLanguageKey
			and		PAGECOUNT		= @pnOldPageCount
	"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnActivityKey		int,
			@pnSequenceKey		int,
			@psAttachmentName		nvarchar(254),
			@psLocation		nvarchar(254),
			@psAttachmentDescription		nvarchar(254),
			@pbIsPublic		bit,
			@pnAttachmentTypeKey		int,
			@pnLanguageKey		int,
			@pnPageCount		int,
			@psOldAttachmentName		nvarchar(254),
			@psOldLocation		nvarchar(254),
			@psOldAttachmentDescription		nvarchar(254),
			@pbOldIsPublic		bit,
			@pnOldAttachmentTypeKey		int,
			@pnOldLanguageKey		int,
			@pnOldPageCount		int',
			@pnActivityKey	 = @pnActivityKey,
			@pnSequenceKey	 = @pnSequenceKey,
			@psAttachmentName	 = @psAttachmentName,
			@psLocation	 = @psLocation,
			@psAttachmentDescription	 = @psAttachmentDescription,
			@pbIsPublic	 = @pbIsPublic,
			@pnAttachmentTypeKey	 = @pnAttachmentTypeKey,
			@pnLanguageKey	 = @pnLanguageKey,
			@pnPageCount	 = @pnPageCount,
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

Grant execute on dbo.ipw_UpdateAttachment to public
GO