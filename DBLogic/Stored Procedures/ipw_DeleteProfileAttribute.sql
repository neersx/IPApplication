-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteProfileAttribute
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteProfileAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteProfileAttribute.'
	Drop procedure [dbo].[ipw_DeleteProfileAttribute]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteProfileAttribute...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteProfileAttribute
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnProfileKey		int,
	@pnAttributeKey		int,
	@psOldAttributeValue	nvarchar(254),	
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_DeleteProfileAttribute
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete an existing attribute against a user profile.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Sep 2009	LP	RFC8047	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	delete from PROFILEATTRIBUTES
	where PROFILEID = @pnProfileKey
	and ATTRIBUTEID = @pnAttributeKey
	and ATTRIBUTEVALUE = @psOldAttributeValue		
	"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnProfileKey		int,
		  @pnAttributeKey	int,
		  @psOldAttributeValue	nvarchar(254)',
		  @pnProfileKey		= @pnProfileKey,
		  @pnAttributeKey	= @pnAttributeKey,
		  @psOldAttributeValue	= @psOldAttributeValue
		
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteProfileAttribute to public
GO
