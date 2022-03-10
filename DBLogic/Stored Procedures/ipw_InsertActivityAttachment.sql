-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertActivityAttachment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertActivityAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertActivityAttachment.'
	Drop procedure [dbo].[ipw_InsertActivityAttachment]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertActivityAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_InsertActivityAttachment
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pnActivityKey				int = null	OUTPUT,
	@pnSequenceKey				int = null	OUTPUT,	
	@pnCaseKey				int = null,
	@pnNameKey				int = null,
	@pnPriorArtKey				int = null,
	@pnEventKey				int = null,
	@pnEventCycle				int = null,
	@pnActivityTypeKey			int = null,
	@pnActivityCategoryKey			int = null,
	@pdtActivityDate			datetime = null,
	@psActivitySummary			nvarchar(254)		 = null,
	@psAttachmentName			nvarchar(254)		 = null,
	@psFileName				nvarchar(254)		 = null,	
	@psAttachmentDescription		nvarchar(254)		 = null,
	@pbIsPublic				bit		 = 0,
	@pnAttachmentTypeKey			int		 = null,
	@pnLanguageKey				int		 = null,
	@pnPageCount				int		 = null
)
as
-- PROCEDURE:	ipw_InsertActivityAttachment
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Activity Attachment.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 7 Dec 2010	JC	RFC9624	1	Procedure created
-- 23 Feb 2011	JC	RFC6563	2	Add PriorArtKey
-- 12 Oct 2011	LP	RFC6896	3	Add EventKey and EventCycle parameters

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

if @nErrorCode = 0 and @pnActivityKey is null
Begin
	exec @nErrorCode = mk_InsertContactActivity 
			@pnUserIdentityId			= @pnUserIdentityId,
			@psCulture				= @psCulture,
			@pnActivityKey				= @pnActivityKey output,
			@pnContactKey				= @pnNameKey,
			@pdtActivityDate			= @pdtActivityDate,
			@pnCaseKey				= @pnCaseKey,
			@psSummary				= @psActivitySummary,
			@pnActivityCategoryKey			= @pnActivityCategoryKey,
			@pnActivityTypeKey			= @pnActivityTypeKey,
			@pbIsIncomplete				= 0,
			@pnPriorArtKey				= @pnPriorArtKey,
			@pnEventKey				= @pnEventKey,
			@pnEventCycle				= @pnEventCycle

End

If @nErrorCode = 0
Begin

	Set @sSQLString = "SELECT @pnSequenceKey = isnull(Max(SEQUENCENO)+1,0)
						FROM ACTIVITYATTACHMENT 
						WHERE ACTIVITYNO = @pnActivityKey"
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnActivityKey		int,
			@pnSequenceKey		int output',
			@pnActivityKey	 = @pnActivityKey,
			@pnSequenceKey	 = @pnSequenceKey output
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Insert into ACTIVITYATTACHMENT
					(ACTIVITYNO,
					SEQUENCENO,
					ATTACHMENTNAME,
					FILENAME,
					ATTACHMENTDESC,
					PUBLICFLAG,
					ATTACHMENTTYPE,
					LANGUAGENO,
					PAGECOUNT)
				values (
					@pnActivityKey,
					@pnSequenceKey,
					@psAttachmentName,
					@psFileName,
					@psAttachmentDescription,
					@pbIsPublic,
					@pnAttachmentTypeKey,
					@pnLanguageKey,
					@pnPageCount)
				"

		exec @nErrorCode=sp_executesql @sSQLString,
			      		N'
				@pnActivityKey		int,
				@pnSequenceKey		int,
				@psAttachmentName		nvarchar(254),
				@psFileName		nvarchar(254),
				@psAttachmentDescription		nvarchar(254),
				@pbIsPublic		bit,
				@pnAttachmentTypeKey		int,
				@pnLanguageKey		int,
				@pnPageCount		int',
				@pnActivityKey	 = @pnActivityKey,
				@pnSequenceKey	 = @pnSequenceKey,
				@psAttachmentName	 = @psAttachmentName,
				@psFileName	 = @psFileName,
				@psAttachmentDescription	 = @psAttachmentDescription,
				@pbIsPublic	 = @pbIsPublic,
				@pnAttachmentTypeKey	 = @pnAttachmentTypeKey,
				@pnLanguageKey	 = @pnLanguageKey,
				@pnPageCount	 = @pnPageCount


		Select @pnActivityKey as ActivityKey,
			   @pnSequenceKey as SequenceKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertActivityAttachment to public
GO