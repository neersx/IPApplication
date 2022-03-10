-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_DeleteActivityAttachment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_DeleteActivityAttachment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_DeleteActivityAttachment.'
	Drop procedure [dbo].[prw_DeleteActivityAttachment]
End
Print '**** Creating Stored Procedure dbo.prw_DeleteActivityAttachment...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.prw_DeleteActivityAttachment
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnActivityKey		int,	-- Mandatory
	@pnSequenceKey		int,	-- Mandatory
	@pdtLastModifiedDate	datetime = null
)
as
-- PROCEDURE:	prw_DeleteActivityAttachment
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Attachment.

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jan 2011	JCLG	RFC9624	1		Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @sSQLString 	nvarchar(4000)
Declare @nErrorCode	int
Declare @nCount		int

-- Initialise variables
Set @nErrorCode = 0
Set @nCount = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @nCount = count(*)
		from	ACTIVITYATTACHMENT AA
		join	ACTIVITY A on (A.ACTIVITYNO = AA.ACTIVITYNO)
		where	AA.ACTIVITYNO	= @pnActivityKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'
		@nCount			int OUTPUT,
		@pnActivityKey		int,
		@pnSequenceKey		int,
		@pdtLastModifiedDate	datetime',
		@nCount			= @nCount OUTPUT,
		@pnActivityKey		= @pnActivityKey,
		@pnSequenceKey		= @pnSequenceKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

If @nErrorCode = 0 and @nCount > 0 
Begin
	Set @sSQLString = "
		Delete from ACTIVITYATTACHMENT
		where	ACTIVITYNO = @pnActivityKey
		and	SEQUENCENO = @pnSequenceKey
		and	LOGDATETIMESTAMP	= @pdtLastModifiedDate"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'
		@pnActivityKey		int,
		@pnSequenceKey		int,
		@pdtLastModifiedDate	datetime',
		@pnActivityKey		= @pnActivityKey,
		@pnSequenceKey		= @pnSequenceKey,
		@pdtLastModifiedDate	= @pdtLastModifiedDate

End

If @nErrorCode = 0 and @@ROWCOUNT = 1 and @nCount = 1 
Begin
	Set @sSQLString = "
		Delete from ACTIVITY 
		where	ACTIVITYNO = @pnActivityKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'
		@pnActivityKey	int',
		@pnActivityKey	= @pnActivityKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_DeleteActivityAttachment to public
GO