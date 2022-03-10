-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeletePortal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeletePortal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeletePortal.'
	Drop procedure [dbo].[ua_DeletePortal]
End
Print '**** Creating Stored Procedure dbo.ua_DeletePortal...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_DeletePortal
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPortalKey		int,		-- Mandatory
	@psOldPortalName	nvarchar(50)	= null,		
	@psOldDescription	nvarchar(254)	= null,
	@pbOldIsExternal 	bit		= null
)
as
-- PROCEDURE:	ua_DeletePortal
-- VERSION:	2
-- DESCRIPTION:	Delete a portal if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2004	TM	RFC915	1	Procedure created
-- 26 Nov 2004	TM	RFC2052	2	If there are any tabs remaining for the portal, call ua_DeletePortalTab 
--					for each of them.
-- 18 Sep 2008	MS	RFC6779 3 Check if the users are present for the portal configuration. If yes, 
--														then raise an XML Alert


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

declare @nTabKey		int
declare @sOldTabName		nvarchar(50)
declare @nOldTabSequence	tinyint
declare @nOldIdentityKey	int
Declare @nRowCount		int
Declare @sAlertXML 		nvarchar(400)
Declare @sTranslatedPortalName    nvarchar(50)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode 		= 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0) 

-- Are users associated with this Portal Configuration?
If ((Select count(*) from USERIDENTITY where DEFAULTPORTALID = @pnPortalKey) > 0)
Begin
		-- Get the translated Portal Name
	  Set @sSQLString = "
		SELECT @sTranslatedPortalName = "+dbo.fn_SqlTranslatedColumn('PORTAL','NAME',null,null,@sLookupCulture,0)+
		" from PORTAL 
		where PORTALID = @pnPortalKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sTranslatedPortalName  nvarchar(50)		OUTPUT,
						@pnPortalKey		int',
						@sTranslatedPortalName = @sTranslatedPortalName OUTPUT,
					  @pnPortalKey	= @pnPortalKey

		-- Raise an alert	
		Set @sAlertXML = dbo.fn_GetAlertXML('IP86', 'Portal Configuration "{0}" cannot be deleted as it is assigned to one or more users. 
Please ensure that there are no users assigned to a Portal Configuration before attempting to delete it.',
						'%s', null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1, @sTranslatedPortalName)
		Set @nErrorCode = @@ERROR
End

-- Delete hidden tabs
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @nTabKey = min(TABID)
	from PORTALTAB
	where PORTALID = @pnPortalKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTabKey		int		output,
					  @pnPortalKey		int',					
					  @nTabKey		= @nTabKey	output,
					  @pnPortalKey		= @pnPortalKey

	-- If there are any tabs remaining for the portal configuration, 
	-- call ua_DeletePortalTab for each of them.	
	While @nTabKey is not null
	and @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select  @sOldTabName 		= TABNAME,
			@nOldTabSequence	= TABSEQUENCE,
			@nOldIdentityKey	= IDENTITYID
		from PORTALTAB
		where TABID = @nTabKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sOldTabName		nvarchar(50)		output,					
					  @nOldTabSequence	tinyint			output,
					  @nOldIdentityKey	int			output,
					  @nTabKey		int',					
					  @sOldTabName		= @sOldTabName		output,	
					  @nOldTabSequence	= @nOldTabSequence	output,
					  @nOldIdentityKey	= @nOldIdentityKey	output,
					  @nTabKey		= @nTabKey
		
		exec @nErrorCode = dbo.ua_DeletePortalTab
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnTabKey		= @nTabKey,
				@psOldTabName		= @sOldTabName, 
				@pnOldIdentityKey	= @nOldIdentityKey,
				@pnOldTabSequence 	= @nOldTabSequence,
				@pnOldPortalKey		= @nOldIdentityKey
	
		-- Extract the next remaining tab if there are any left
		Set @sSQLString = "
		Select @nTabKey = min(TABID)
		from PORTALTAB
		where PORTALID = @pnPortalKey
		and   TABID > @nTabKey"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nTabKey		int		output,
						  @pnPortalKey		int',					
						  @nTabKey		= @nTabKey	output,
						  @pnPortalKey		= @pnPortalKey	
	End				
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete PORTAL
	where	PORTALID 	= @pnPortalKey
	and	NAME	 	= @psOldPortalName		
	and	ISEXTERNAL 	= @pbOldIsExternal
	and 	DESCRIPTION	= @psOldDescription"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPortalKey		int,
					  @psOldPortalName	nvarchar(50),					
					  @psOldDescription	nvarchar(254),
					  @pbOldIsExternal	bit',
					  @pnPortalKey		= @pnPortalKey,
					  @psOldPortalName	= @psOldPortalName,	
					  @psOldDescription	= @psOldDescription,					  
					  @pbOldIsExternal	= @pbOldIsExternal
End

Return @nErrorCode
GO

Grant execute on dbo.ua_DeletePortal to public
GO
