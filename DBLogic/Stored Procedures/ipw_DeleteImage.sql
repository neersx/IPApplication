-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteImage									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteImage.'
	Drop procedure [dbo].[ipw_DeleteImage]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteImage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

create PROCEDURE [dbo].[ipw_DeleteImage]
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnImageKey	int,	-- Mandatory
	@pdtImageTimeStamp	datetime = null,
	@pdtImageDetailTimeStamp datetime = null
)
as
-- PROCEDURE:	ipw_DeleteImage
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Image and Image Detail.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 12 Mar 2010	PS	RFC6139	1	Procedure created
-- 14 Apr 2010	SF	RFC9157 2	ImageTimeStamp and ImageDetailTimeStamp may be null
-- 24 Oct 2017	AK	R72645	3	Make compatible with case sensitive server with case insensitive database.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @TransactionCountStart	int
Declare @sAlertXML 		nvarchar(400)
Declare @sSqlString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = @@ERROR



-- Are Cases and Names associated with the Image.
If (((Select count(*) from CASEIMAGE where IMAGEID = @pnImageKey) > 0)  or ( (Select count(*) from NAMEIMAGE where IMAGEID = @pnImageKey)>0))
Begin	
	-- Raise an alert	
	Set @sAlertXML = dbo.fn_GetAlertXML('IP105', 'Image cannot be deleted as it is assigned to one or more Cases or Names. 
Please ensure that there are no Cases or Names using a Image before attempting to delete it.',
						'%s', null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1, null)
		Set @nErrorCode = @@ERROR
End


If @nErrorCode = 0
Begin
   Select @TransactionCountStart = @@TranCount
   BEGIN TRANSACTION
End

If @nErrorCode = 0
Begin
	Set @sSqlString = 
	"Delete from IMAGEDETAIL 
	where 
	IMAGEID = @pnImageKey and
	LOGDATETIMESTAMP = @pdtImageDetailTimeStamp"
	
	exec @nErrorCode=sp_executesql @sSqlString,
					N'@pnImageKey			int,
					  @pdtImageDetailTimeStamp	datetime',
					  @pnImageKey		= @pnImageKey,
					  @pdtImageDetailTimeStamp		= @pdtImageDetailTimeStamp	
End

If @nErrorCode = 0  
Begin
	Set @sSqlString =
	"Delete from IMAGE
	where 
	IMAGEID	= @pnImageKey and
	LOGDATETIMESTAMP = @pdtImageTimeStamp"
	
	exec @nErrorCode=sp_executesql @sSqlString,
					N'@pnImageKey			int,
					  @pdtImageTimeStamp	datetime',
					  @pnImageKey		= @pnImageKey,
					  @pdtImageTimeStamp		= @pdtImageTimeStamp	
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

Grant execute on dbo.ipw_DeleteImage to public
GO

