-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_UpdatePortalTabName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_UpdatePortalTabName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_UpdatePortalTabName.'
	Drop procedure [dbo].[ua_UpdatePortalTabName]
End
Print '**** Creating Stored Procedure dbo.ua_UpdatePortalTabName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_UpdatePortalTabName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTabKey		int,		-- Mandatory	
	@psTabName		nvarchar(50)	= null,
	@psOldTabName		nvarchar(50)	= null
)
as
-- PROCEDURE:	ua_UpdatePortalTabName
-- VERSION:	2
-- DESCRIPTION:	Update a portal tab name

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Aug 2007	SW	RFC5424	1	Procedure created
-- 02 May 2008	JC	RFC6487	2	Get TabID from ParentTabID

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
	set	TABNAME 	 = @psTabName
	where	TABID		 = @pnTabKey
	and	TABNAME		 = @psOldTabName"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @psTabName		nvarchar(50),
					  @psOldTabName		nvarchar(50)',
					  @pnTabKey		= @pnTabKey,
					  @psTabName		= @psTabName,
					  @psOldTabName		= @psOldTabName
End

Return @nErrorCode
GO

Grant execute on dbo.ua_UpdatePortalTabName to public
GO
