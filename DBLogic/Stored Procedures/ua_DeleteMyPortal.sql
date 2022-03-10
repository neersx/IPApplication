-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeleteMyPortal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeleteMyPortal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeleteMyPortal.'
	Drop procedure [dbo].[ua_DeleteMyPortal]
End
Print '**** Creating Stored Procedure dbo.ua_DeleteMyPortal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_DeleteMyPortal
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int		-- Mandatory
)
as
-- PROCEDURE:	ua_DeleteMyPortal
-- VERSION:	2
-- DESCRIPTION:	Delete any tabs remaining for the user-specific configuration.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Nov 2004	TM	RFC2052	1	Procedure created
-- 26 Nov 2004	TM	RFC2052	2	Modify the ua_DeleteMyPortal.sql to alwayt return RowCount = 1 so even if no rows
--					where deleted Data Adapter will not produce a concurrency error.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

declare @nTabKey		int
declare @sOldTabName		nvarchar(50)
declare @nOldTabSequence	tinyint
declare @nOldPortalKey		int

declare @tbl table		(col1 bit)

-- Initialise variables
Set @nErrorCode 		= 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "
	Select @nTabKey = min(TABID)
	from PORTALTAB
	where IDENTITYID = @pnIdentityKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTabKey		int		output,
					  @pnIdentityKey	int',					
					  @nTabKey		= @nTabKey	output,
					  @pnIdentityKey	= @pnIdentityKey

	-- If there are any tabs remaining for the user-specific configuration, 
	-- call ua_DeletePortalTab for each of them.	
	While @nTabKey is not null
	and @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select  @sOldTabName 		= TABNAME,
			@nOldTabSequence	= TABSEQUENCE,
			@nOldPortalKey		= PORTALID
		from PORTALTAB
		where TABID = @nTabKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sOldTabName		nvarchar(50)		output,					
					  @nOldTabSequence	tinyint			output,
					  @nOldPortalKey	int			output,
					  @nTabKey		int',					
					  @sOldTabName		= @sOldTabName		output,	
					  @nOldTabSequence	= @nOldTabSequence	output,
					  @nOldPortalKey	= @nOldPortalKey	output,
					  @nTabKey		= @nTabKey
		
		exec @nErrorCode = dbo.ua_DeletePortalTab
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnTabKey		= @nTabKey,
				@psOldTabName		= @sOldTabName, 
				@pnOldIdentityKey	= @pnIdentityKey,
				@pnOldTabSequence 	= @nOldTabSequence,
				@pnOldPortalKey		= @nOldPortalKey
	
		-- Extract the next remaining tab if there are any left
		Set @sSQLString = "
		Select @nTabKey = min(TABID)
		from PORTALTAB
		where IDENTITYID = @pnIdentityKey
		and   TABID > @nTabKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTabKey		int		output,
						  @pnIdentityKey	int',					
						  @nTabKey		= @nTabKey	output,
						  @pnIdentityKey	= @pnIdentityKey	
	End				
End

If @nErrorCode = 0
Begin
	-- Make sure that the RowCount is always set to 1 
	-- even if no rows where deleted so Data Adapter 
	-- will not produce a concurrency error.
	Insert into @tbl values (1)
End

Return @nErrorCode
GO

Grant execute on dbo.ua_DeleteMyPortal to public
GO
