-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteCorrespondenceInstructions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteCorrespondenceInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteCorrespondenceInstructions.'
	Drop procedure [dbo].[naw_DeleteCorrespondenceInstructions]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteCorrespondenceInstructions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_DeleteCorrespondenceInstructions
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@psTextTypeKey		nvarchar(2),	-- Mandatory
	@pdtLastModified	datetime	= null	
)
as
-- PROCEDURE:	naw_DeleteCorrespondenceInstructions
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete the Correspondence Instructions from the database

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Aug 2009	MS	RFC8288	1	Procedure created
-- 12 Sep 2013  MS      DR913   2       Check LogDateTimeStamp rather than old text

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If @psTextTypeKey = "-1"
	Begin
		Set @sSQLString = " 
		Update IPNAME
		SET CORRESPONDENCE = null
		Where NAMENO	 = @pnNameKey
		and (LOGDATETIMESTAMP = @pdtLastModified or (LOGDATETIMESTAMP is null and @pdtLastModified is null))"		
	End
	Else 
	Begin	
		Set @sSQLString = " 
		delete NAMETEXT
		where	NAMENO	 = @pnNameKey
		and	TEXTTYPE = @psTextTypeKey	
		and (LOGDATETIMESTAMP = @pdtLastModified or (LOGDATETIMESTAMP is null and @pdtLastModified is null))"		
	End
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnNameKey		int,
			  @psTextTypeKey	nvarchar(2),
			  @pdtLastModified 	datetime',
			  @pnNameKey		= @pnNameKey,
			  @psTextTypeKey	= @psTextTypeKey,
			  @pdtLastModified	= @pdtLastModified
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteCorrespondenceInstructions to public
GO
