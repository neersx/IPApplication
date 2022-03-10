-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_UpdatePortal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_UpdatePortal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_UpdatePortal.'
	Drop procedure [dbo].[ua_UpdatePortal]
End
Print '**** Creating Stored Procedure dbo.ua_UpdatePortal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_UpdatePortal
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnPortalKey		int,		-- Mandatory	
	@psPortalName		nvarchar(50)	= null,	
	@psDescription		nvarchar(254)	= null,	
	@pbIsExternal 		bit		= null,
	@psOldPortalName	nvarchar(50)	= null,	
	@psOldDescription	nvarchar(254) 	= null,		
	@pbOldIsExternal 	bit		= null	
)
as
-- PROCEDURE:	ua_UpdatePortal
-- VERSION:	1
-- DESCRIPTION:	Update a portal if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2004	TM	RFC915	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	update 	PORTAL
	set	NAME 	 	 = @psPortalName, 
		DESCRIPTION 	 = @psDescription, 		
		ISEXTERNAL 	 = @pbIsExternal
	where	PORTALID	 = @pnPortalKey
	and	NAME 	 	 = @psOldPortalName	
	and     DESCRIPTION	 = @psOldDescription
	and	ISEXTERNAL	 = @pbOldIsExternal"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPortalKey		int,
					  @psPortalName		nvarchar(50),
					  @psDescription	nvarchar(254),					 
					  @pbIsExternal 	bit,
					  @psOldPortalName	nvarchar(50),					
					  @psOldDescription	nvarchar(254),
					  @pbOldIsExternal	bit',
					  @pnPortalKey		= @pnPortalKey,
					  @psPortalName		= @psPortalName,
					  @psDescription	= @psDescription,					
					  @pbIsExternal		= @pbIsExternal,
					  @psOldPortalName 	= @psOldPortalName,					 
					  @psOldDescription	= @psOldDescription,
					  @pbOldIsExternal	= @pbOldIsExternal
End

Return @nErrorCode
GO

Grant execute on dbo.ua_UpdatePortal to public
GO
