-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeletePortalTabName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeletePortalTabName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeletePortalTabName.'
	Drop procedure [dbo].[ua_DeletePortalTabName]
End
Print '**** Creating Stored Procedure dbo.ua_DeletePortalTabName...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_DeletePortalTabName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTabKey		int		
)
as
-- PROCEDURE:	ua_DeletePortalTabName
-- VERSION:	2
-- DESCRIPTION:	Delete a new Portal Tab.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 31 Aug 2007	SW	RFC5424	1	Procedure created
-- 19 Mar 2018	LP	R70612	2	Correction when user-specific portal tab is deleted.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @nTabSequence	tinyint
declare @nRowCount	int

-- Initialise variables
Set @nErrorCode 	= 0

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

-- Find out the new TABID if it is copied from default.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select @pnTabKey = T.TABID
		from PORTALTAB T
		join PORTALTAB D on (D.TABNAME = T.TABNAME)
		where D.TABID = @pnTabKey
		and T.IDENTITYID = @pnUserIdentityId 
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int			OUTPUT,
					  @pnUserIdentityId	int',
					  @pnTabKey		= @pnTabKey		OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId
End

-- Remove modules that are associated to a tab
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Delete MODULECONFIGURATION
		where TABID = @pnTabKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int',
					  @pnTabKey		= @pnTabKey
End

-- Record the tab sequence before removing the tab
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@nTabSequence = TABSEQUENCE
		from	PORTALTAB
		where	TABID = @pnTabKey
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTabSequence		tinyint			output,
					  @pnTabKey		int',
					  @nTabSequence		= @nTabSequence	output,
					  @pnTabKey		= @pnTabKey
End

-- Remove tab
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Delete PORTALTAB
		where TABID = @pnTabKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int',
					  @pnTabKey		= @pnTabKey
End

-- Change the tab sequence
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Update PORTALTAB
		Set TABSEQUENCE = TABSEQUENCE - 1
		where TABSEQUENCE > @nTabSequence
		and IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTabSequence		tinyint,
					@pnUserIdentityId	int',
					  @nTabSequence		= @nTabSequence,
					  @pnUserIdentityId	= @pnUserIdentityId
End


Return @nErrorCode
GO

Grant execute on dbo.ua_DeletePortalTabName to public
GO