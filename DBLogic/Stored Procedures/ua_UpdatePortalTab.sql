-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_UpdatePortalTab
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_UpdatePortalTab]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_UpdatePortalTab.'
	Drop procedure [dbo].[ua_UpdatePortalTab]
End
Print '**** Creating Stored Procedure dbo.ua_UpdatePortalTab...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_UpdatePortalTab
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnTabKey		int,		-- Mandatory	
	@psTabName		nvarchar(50)	= null,	
	@pnIdentityKey		int		= null,	
	@pnTabSequence 		tinyint		= null,
	@pnPortalKey		int		= null,	
	@psOldTabName		nvarchar(50)	= null,	
	@pnOldIdentityKey	int 		= null,		
	@pnOldTabSequence	tinyint		= null,
	@pnOldPortalKey		int		= null	
)
as
-- PROCEDURE:	ua_UpdatePortalTab
-- VERSION:	1
-- DESCRIPTION:	Update a portal tab if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2004	TM	RFC915	1	Procedure created

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
	update 	PORTALTAB
	set	TABNAME 	 = @psTabName, 
		IDENTITYID 	 = @pnIdentityKey, 		
		TABSEQUENCE 	 = @pnTabSequence,
		PORTALID	 = @pnPortalKey
	where	TABID		 = @pnTabKey
	and	TABNAME	 	 = @psOldTabName	
	and     IDENTITYID	 = @pnOldIdentityKey
	and 	TABSEQUENCE	 = @pnOldTabSequence
	and 	PORTALID	 = @pnOldPortalKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @psTabName		nvarchar(50),
					  @pnIdentityKey	int,
					  @pnTabSequence	tinyint,					 
					  @pnPortalKey 		int,
					  @psOldTabName		nvarchar(50),					
					  @pnOldIdentityKey	int,
					  @pnOldTabSequence	tinyint,
					  @pnOldPortalKey	int',
					  @pnTabKey		= @pnTabKey,
					  @psTabName		= @psTabName,
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnTabSequence	= @pnTabSequence,					
					  @pnPortalKey		= @pnPortalKey,
					  @psOldTabName 	= @psOldTabName,					 
					  @pnOldIdentityKey	= @pnOldIdentityKey,
					  @pnOldTabSequence	= @pnOldTabSequence,
					  @pnOldPortalKey	= @pnOldPortalKey
End

Return @nErrorCode
GO

Grant execute on dbo.ua_UpdatePortalTab to public
GO
