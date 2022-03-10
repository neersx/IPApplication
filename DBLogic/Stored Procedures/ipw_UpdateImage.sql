-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateImage									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateImage.'
	Drop procedure [dbo].[ipw_UpdateImage]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateImage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE procedure [dbo].[ipw_UpdateImage]
(		
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnImageKey			int,			--Mandatory
	@psImageDescription		nvarchar(254),
	@psContentType			nvarchar(100) = null,
	@piImgData			varbinary(max) = null,
	@pnImageStatusKey		int,
	@pdtImageTimeStamp		datetime = null,
	@pdtImageDetailTimeStamp	datetime = null
)
-- PROCEDURE: 	ipw_UpdateImage
-- VERSION:	3
-- DESCRIPTION:	Updates the Image and Image Details.

-- MODIFICATIONS :
-- Date		Who	Version	Change	Description
-- ------------	-------	-------	----------------------------------------------- 
-- 12-Mar-2010	PS	1	RFC6159	Procedure Created
-- 14-Apr-2010	SF	2	RFC9157 ImageTimestamp and ImageDetailTimeStamp may be null
-- 26 Aug 2019	vql	3	Change 'image' columns to a supported data type

AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @TransactionCountStart	int
declare @sSQLString 		nvarchar(4000)

set @nErrorCode = @@ERROR

If @nErrorCode = 0
Begin
   Select @TransactionCountStart = @@TranCount
   BEGIN TRANSACTION
End

if (@nErrorCode = 0) and (@piImgData is not null)
Begin
	Set @sSQLString = "Update IMAGE set IMAGEDATA = @piImgData
	where IMAGE.IMAGEID = @pnImageKey and IMAGE.LOGDATETIMESTAMP = @pdtImageTimeStamp"
	
	exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnImageKey		int,
					  @pdtImageTimeStamp		datetime,
					  @piImgData		image',
					  @pnImageKey		= @pnImageKey,
					  @pdtImageTimeStamp		= @pdtImageTimeStamp,
					  @piImgData		= @piImgData
End

If @nErrorCode = 0 
Begin
	Set @sSQLString = "UPDATE IMAGEDETAIL 
	Set IMAGEDESC = @psImageDescription,
	IMAGESTATUS = @pnImageStatusKey,
	CONTENTTYPE = @psContentType
	where IMAGEDETAIL.IMAGEID = @pnImageKey and IMAGEDETAIL.LOGDATETIMESTAMP = @pdtImageDetailTimeStamp"
    
	exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnImageKey		int,
					  @pdtImageDetailTimeStamp	datetime,
					  @psImageDescription		nvarchar(254),
					  @pnImageStatusKey		int,
					  @psContentType		nvarchar(100)',
					  @pnImageKey			= @pnImageKey,
					  @pdtImageDetailTimeStamp	= @pdtImageDetailTimeStamp,
					  @psImageDescription		= @psImageDescription,
					  @pnImageStatusKey		= @pnImageStatusKey,
					  @psContentType		= @psContentType
End

If @@TranCount > @TransactionCountStart
Begin
	if (@nErrorCode =0)
		COMMIT TRANSACTION
	else
		ROLLBACK TRANSACTION
End


Return @nErrorCode

GO

Grant execute on dbo.ipw_UpdateImage to public
GO
