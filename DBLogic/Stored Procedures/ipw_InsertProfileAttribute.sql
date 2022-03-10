-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertProfileAttribute
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertProfileAttribute]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertProfileAttribute.'
	Drop procedure [dbo].[ipw_InsertProfileAttribute]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertProfileAttribute...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertProfileAttribute
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnProfileKey		int,
	@pnAttributeKey		int,
	@psAttributeValue	nvarchar(254),	
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_InsertProfileAttribute
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Assign a new attribute against a user profile.

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
	insert into PROFILEATTRIBUTES(
		PROFILEID,
		ATTRIBUTEID,
		ATTRIBUTEVALUE)
	values (@pnProfileKey,
		@pnAttributeKey,
		@psAttributeValue)		
	"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnProfileKey		int,
		  @pnAttributeKey	int,
		  @psAttributeValue	nvarchar(254)',
		  @pnProfileKey		= @pnProfileKey,
		  @pnAttributeKey	= @pnAttributeKey,
		  @psAttributeValue	= @psAttributeValue
		
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertProfileAttribute to public
GO
