-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetAttachmentFilePath
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetAttachmentFilePath]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetAttachmentFilePath.'
	Drop procedure [dbo].[ipw_GetAttachmentFilePath]
End
Print '**** Creating Stored Procedure dbo.ipw_GetAttachmentFilePath...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetAttachmentFilePath
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) = null,
	@pnActivityKey			int,		-- Mandatory
	@pnSequenceKey			int	= null,
	@pbCalledFromCentura	bit	= 0
)
as
-- PROCEDURE:	ipw_GetAttachmentFilePath
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get the file path of an attachment

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 26 Nov 2010	JCLG		RFC9304	1		Procedure created
-- 19 May 2015	DV		R47600	2		Remove check for WorkBench Attachments site control 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @bIsExternalUser	bit
Declare @dtToday			datetime
Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
set @dtToday = getdate()

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit		  OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
		AA.FILENAME	as FilePath
		from ACTIVITYATTACHMENT AA
		join ACTIVITY A				on (A.ACTIVITYNO = AA.ACTIVITYNO)
		-- Is Attachments topic available?
		join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 2, @pbCalledFromCentura, @dtToday) TS
						on (TS.IsAvailable=1)	
		where AA.ACTIVITYNO = @pnActivityKey"

	Set @sSQLString = @sSQLString +
	CASE WHEN @pnSequenceKey is not NULL
		THEN char(10) + "and AA.SEQUENCENO = @pnSequenceKey"
		ELSE char(10) + "and AA.SEQUENCENO = (Select min(AA2.SEQUENCENO) from ACTIVITYATTACHMENT AA2 where AA2.ACTIVITYNO = AA.ACTIVITYNO)"
	END
	
	If @bIsExternalUser = 1
	Begin
		Set @sSQLString = @sSQLString + char(10) + "and AA.PUBLICFLAG = 1"	
	END

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura bit,
			@dtToday			datetime,
			@pnActivityKey		int,
			@pnSequenceKey		int',
			@pnUserIdentityId   = @pnUserIdentityId,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@dtToday			= @dtToday,
			@pnActivityKey		= @pnActivityKey,
			@pnSequenceKey		= @pnSequenceKey

End


Return @nErrorCode
GO

Grant execute on dbo.ipw_GetAttachmentFilePath to public
GO