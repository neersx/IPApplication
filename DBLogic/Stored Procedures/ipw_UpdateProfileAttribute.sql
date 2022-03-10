-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateProfileAttribute
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateProfileAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateProfileAttribute.'
	Drop procedure [dbo].[ipw_UpdateProfileAttribute]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateProfileAttribute...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_UpdateProfileAttribute
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnProfileKey		int,
	@pnAttributeKey		int,
	@psAttributeValue	nvarchar(254),
	@psOldAttributeValue	nvarchar(254),	
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_UpdateProfileAttribute
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Modify an existing attribute against a user profile.

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
and @psAttributeValue <> @psOldAttributeValue
Begin
	Set @sSQLString = "
	update PROFILEATTRIBUTES
	set ATTRIBUTEVALUE = @psAttributeValue
	where PROFILEID = @pnProfileKey
	and ATTRIBUTEID = @pnAttributeKey
	and ATTRIBUTEVALUE = @psOldAttributeValue		
	"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnProfileKey		int,
		  @pnAttributeKey	int,
		  @psAttributeValue	nvarchar(254),
		  @psOldAttributeValue	nvarchar(254)',
		  @pnProfileKey		= @pnProfileKey,
		  @pnAttributeKey	= @pnAttributeKey,
		  @psAttributeValue	= @psAttributeValue,
		  @psOldAttributeValue	= @psOldAttributeValue
		
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateProfileAttribute to public
GO
