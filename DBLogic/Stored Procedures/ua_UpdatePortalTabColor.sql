-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_UpdatePortalTabColor
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_UpdatePortalTabColor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_UpdatePortalTabColor.'
	Drop procedure [dbo].[ua_UpdatePortalTabColor]
End
Print '**** Creating Stored Procedure dbo.ua_UpdatePortalTabColor...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_UpdatePortalTabColor
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTabKey		int,		-- Mandatory	
	@psCssClassName		nvarchar(50)	= null,
	@psOldCssClassName		nvarchar(50)	= null
)
as
-- PROCEDURE:	ua_UpdatePortalTabColor
-- VERSION:	2
-- DESCRIPTION:	Update a portal tab color

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Aug 2007	JCLG	RFC5664	1	Procedure created
-- 02 May 2008	JCLG	RFC6487	2	Get TabID from ParentTabID

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
declare @nRowCount	int
Declare	@nNewTabKey		int

-- Initialise variables
Set @nErrorCode 		= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Select @nRowCount = count(*) from PORTALTAB
		where IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nRowCount		int			OUTPUT,
					  @pnUserIdentityId	int',
					  @nRowCount		= @nRowCount		OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId
End

-- Make a duplicate set of tabs if necessary
If @nRowCount = 0 and @nErrorCode = 0
Begin
	exec @nErrorCode = ua_CopyPortalTab @pnUserIdentityId, @psCulture
End

-- Check if the pnTabKey has been modified by the CopyPortalTab
If @nErrorCode = 0
Begin
	Set @nNewTabKey	=	null
	-- Check if the pnTabKey has been modified by the CopyPortalTab
	Set @sSQLString = "
		Select	@nNewTabKey = TABID
		from	PORTALTAB
		where	PARENTTABID = @pnTabKey
		  and IDENTITYID = @pnUserIdentityId
		"
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nNewTabKey	int			output,
					  @pnTabKey		int,
						@pnUserIdentityId int',
					  @nNewTabKey	= @nNewTabKey	output,
					  @pnTabKey		= @pnTabKey,
						@pnUserIdentityId 	=	@pnUserIdentityId

	If @nErrorCode = 0 and @nNewTabKey is not null
	Begin
		Set @pnTabKey = @nNewTabKey
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	update 	PORTALTAB
	set	CSSCLASSNAME 	 = @psCssClassName
	where	TABID		 = @pnTabKey
	and	(CSSCLASSNAME		 = @psOldCssClassName OR CSSCLASSNAME IS NULL)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @psCssClassName		nvarchar(50),
					  @psOldCssClassName		nvarchar(50)',
					  @pnTabKey		= @pnTabKey,
					  @psCssClassName		= @psCssClassName,
					  @psOldCssClassName		= @psOldCssClassName
End

Return @nErrorCode
GO

Grant execute on dbo.ua_UpdatePortalTabColor to public
GO
