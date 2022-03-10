-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertSingleActivityAttachment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertSingleActivityAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertSingleActivityAttachment.'
	Drop procedure [dbo].[ipw_InsertSingleActivityAttachment]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertSingleActivityAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_InsertSingleActivityAttachment
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	@pnNameKey		int		= null,
	@pnActivityTypeKey	int,
	@pnActivityCategoryKey	int,
	@pdActivityDate		datetime,	-- Mandatory
	@psActivitySummary	nvarchar(254),	-- Mandatory
	@psAttachmentName	nvarchar(254),	-- Mandatory
	@psFileName		nvarchar(254),	-- Mandatory
	@pbIsPublic		bit		= 0
)
as
-- PROCEDURE:	ipw_InsertSingleActivityAttachment
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Activity Attachment 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Sep 2011	JC	R10201	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nActivityKey		int
Declare @nSequenceKey		int

-- Initialise variables
Set @nErrorCode = 0
Set @nActivityKey = null
Set @nSequenceKey = null
	
if @nErrorCode = 0
Begin
	
	--Check if there is already an activity and activity attachment
	Set @sSQLString = "SELECT @nActivityKey	= A.ACTIVITYNO,
				  @nSequenceKey = AA.SEQUENCENO
			FROM ACTIVITY A
			LEFT JOIN ACTIVITYATTACHMENT AA on (AA.ACTIVITYNO = A.ACTIVITYNO AND AA.FILENAME = @psFileName)
			WHERE A.ACTIVITYDATE = @pdActivityDate
			AND A.ACTIVITYCATEGORY = @pnActivityCategoryKey 
			AND A.ACTIVITYTYPE = @pnActivityTypeKey"
	if @pnCaseKey is not null
		Set @sSQLString = @sSQLString+char(10)+"AND A.CASEID = @pnCaseKey"
	else
		Set @sSQLString = @sSQLString+char(10)+"AND A.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		      		N'
			@nActivityKey		int output,
			@nSequenceKey		int output,
			@pdActivityDate		datetime,
			@pnCaseKey		int,
			@pnNameKey		int,
			@pnActivityTypeKey	int,
			@pnActivityCategoryKey	int,
			@psFileName		nvarchar(254)',
			@nActivityKey		= @nActivityKey output,
			@nSequenceKey		= @nSequenceKey output,
			@pdActivityDate		= @pdActivityDate,
			@pnCaseKey		= @pnCaseKey,
			@pnNameKey		= @pnNameKey,
			@pnActivityTypeKey	= @pnActivityTypeKey,
			@pnActivityCategoryKey	= @pnActivityCategoryKey,
			@psFileName		= @psFileName
End

if @nErrorCode = 0 and @nActivityKey is null
Begin
	-- Create new Activity
	exec @nErrorCode = mk_InsertContactActivity 
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pnActivityKey			= @nActivityKey output,
			@pnCaseKey			= @pnCaseKey,
			@pnContactKey			= @pnNameKey,
			@pdtActivityDate		= @pdActivityDate,
			@psSummary			= @psActivitySummary,
			@pnActivityCategoryKey		= @pnActivityCategoryKey,
			@pnActivityTypeKey		= @pnActivityTypeKey,
			@pbIsIncomplete			= 0
End

if @nErrorCode =0 and @nSequenceKey is null
Begin
	Set @sSQLString = "SELECT @nSequenceKey = isnull(Max(SEQUENCENO)+1,0)
						FROM ACTIVITYATTACHMENT 
						WHERE ACTIVITYNO = @nActivityKey"
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@nActivityKey	int,
			@nSequenceKey	int output',
			@nActivityKey	 = @nActivityKey,
			@nSequenceKey	 = @nSequenceKey output
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Insert into ACTIVITYATTACHMENT
					(ACTIVITYNO,
					SEQUENCENO,
					ATTACHMENTNAME,
					FILENAME,
					PUBLICFLAG)
				values (
					@nActivityKey,
					@nSequenceKey,
					@psAttachmentName,
					@psFileName,
					@pbIsPublic)
				"

		exec @nErrorCode=sp_executesql @sSQLString,
			      		N'
				@nActivityKey		int,
				@nSequenceKey		int,
				@psAttachmentName	nvarchar(254),
				@psFileName		nvarchar(254),
				@pbIsPublic		bit',
				@nActivityKey		= @nActivityKey,
				@nSequenceKey		= @nSequenceKey,
				@psAttachmentName	= @psAttachmentName,
				@psFileName		= @psFileName,
				@pbIsPublic		= @pbIsPublic
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertSingleActivityAttachment to public
GO