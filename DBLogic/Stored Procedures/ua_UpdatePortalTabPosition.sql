-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_UpdatePortalTabPosition
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_UpdatePortalTabPosition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_UpdatePortalTabPosition.'
	Drop procedure [dbo].[ua_UpdatePortalTabPosition]
End
Print '**** Creating Stored Procedure dbo.ua_UpdatePortalTabPosition...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_UpdatePortalTabPosition
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTabKey		int		= null,
	@pnTabKeyPrevious	int		= null,
	@pnTabKeyAfter		int		= null
)
as
-- PROCEDURE:	ua_UpdatePortalTabPosition
-- VERSION:	5
-- DESCRIPTION:	Move a tab (@pnTabKey) to its desire position (@pnTabSequence).

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 31 Aug 2007	SW	RFC5424	1	Procedure created
-- 04 Feb 2008	SW	RFC5535	2	Bug fix
-- 01 May 2008	JCLG	RFC6487	3	Use page previous and page after to change the position
-- 01 Apr 2009	MS	RFC6487	4	Bug fix - Use tab after for calculating the position of new tab when sliding from right to left.
-- 03 Sep 2012  MS      R12650  5       Bug fix - Error converting datatype int to tinyint

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @nNewTabKey	int
declare @nPreviousTabSequence	tinyint
declare @nAfterTabSequence	tinyint
declare @nCurrentTabSequence	tinyint
declare @nNewTabSequence	tinyint
declare @nRowCount	int

-- Initialise variables
Set @nErrorCode 	= 0
Set @nPreviousTabSequence = 0
Set @nNewTabSequence = 1

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

-- Find out tab sequence of the previous tab
-- If previous tab is null, then the TabSequence = 1 (first tab)
If @nErrorCode = 0 and @pnTabKeyPrevious is not null
Begin
	Set @nNewTabKey	=	null
	-- Check if the pnTabKeyPrevious has been modified by the CopyPortalTab
	Set @sSQLString = "
		Select	@nNewTabKey = TABID
		from	PORTALTAB
		where	PARENTTABID = @pnTabKeyPrevious
		  and IDENTITYID = @pnUserIdentityId"
		  
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nNewTabKey	                int		output,
					  @pnTabKeyPrevious		int,
					  @pnUserIdentityId             int',
					  @nNewTabKey	                = @nNewTabKey	output,
					  @pnTabKeyPrevious		= @pnTabKeyPrevious,
					  @pnUserIdentityId 	        = @pnUserIdentityId
	
	If @nErrorCode = 0
	Begin
		If @nNewTabKey is not null
		Begin
			Set @pnTabKeyPrevious = @nNewTabKey
		End

		--Get the TabSequence of the previous tab
		Set @sSQLString = "
			Select	@nPreviousTabSequence = TABSEQUENCE
			from	PORTALTAB
			where	TABID = @pnTabKeyPrevious
			"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nPreviousTabSequence	tinyint			output,
						  @pnTabKeyPrevious		int',
						  @nPreviousTabSequence	= @nPreviousTabSequence	output,
						  @pnTabKeyPrevious		= @pnTabKeyPrevious

	End						

End

-- Find out tab sequence of the tab after
If @nErrorCode = 0 and @pnTabKeyAfter is not null
Begin
	Set @nNewTabKey	=	null
	-- Check if the pnTabKeyAfter has been modified by the CopyPortalTab
	Set @sSQLString = "
		Select	@nNewTabKey = TABID
		from	PORTALTAB
		where	PARENTTABID = @pnTabKeyAfter
		  and IDENTITYID = @pnUserIdentityId"
		  
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nNewTabKey	                int		output,
					  @pnTabKeyAfter		int,
					  @pnUserIdentityId             int',
					  @nNewTabKey	                = @nNewTabKey	output,
					  @pnTabKeyAfter		= @pnTabKeyAfter,
					  @pnUserIdentityId 	        = @pnUserIdentityId
	
	If @nErrorCode = 0
	Begin
		If @nNewTabKey is not null
		Begin
			Set @pnTabKeyAfter = @nNewTabKey
		End

		--Get the TabSequence of the previous tab
		Set @sSQLString = "
			Select	@nAfterTabSequence = TABSEQUENCE
			from	PORTALTAB
			where	TABID = @pnTabKeyAfter"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nAfterTabSequence	tinyint			output,
						  @pnTabKeyAfter	int',
						  @nAfterTabSequence	= @nAfterTabSequence	output,
						  @pnTabKeyAfter	= @pnTabKeyAfter

	End						
End

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
					N'@nNewTabKey	        int		output,
					@pnTabKey		int,
					@pnUserIdentityId       int',
					@nNewTabKey	        = @nNewTabKey	output,
					@pnTabKey		= @pnTabKey,
					@pnUserIdentityId 	= @pnUserIdentityId

	If @nErrorCode = 0 and @nNewTabKey is not null
	Begin
		Set @pnTabKey = @nNewTabKey
	End
End

-- Get the current tab sequence for the tab to move
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@nCurrentTabSequence = TABSEQUENCE
		from	PORTALTAB
		where	TABID = @pnTabKey
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCurrentTabSequence	tinyint			output,
					  @pnTabKey		int',
					  @nCurrentTabSequence	= @nCurrentTabSequence	output,
					  @pnTabKey		= @pnTabKey
End

-- Mov tabs
If @nErrorCode = 0
Begin
	If @nAfterTabSequence is not null
	Begin
		If @nPreviousTabSequence > @nCurrentTabSequence
		Begin
			-- Slide tabs from right to left
			Set @sSQLString = "
					Update PORTALTAB
					Set TABSEQUENCE = TABSEQUENCE - 1
					where TABSEQUENCE > @nCurrentTabSequence
					and TABSEQUENCE < @nAfterTabSequence
					and TABID <> @pnTabKey
					and IDENTITYID = @pnUserIdentityId"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nCurrentTabSequence	        tinyint,
							@nAfterTabSequence	        tinyint,
							@pnTabKey	                int,
							@pnUserIdentityId	        int',
							@nCurrentTabSequence	        = @nCurrentTabSequence,
							@nAfterTabSequence	        = @nAfterTabSequence,
							@pnTabKey	                = @pnTabKey,
							@pnUserIdentityId	        = @pnUserIdentityId

			If @nErrorCode = 0
			Begin
				Set @nNewTabSequence = @nAfterTabSequence - 1
			End						
		End
		Else
		Begin
			-- Slide tabs from left to rigth
			Set @sSQLString = "
						Update PORTALTAB
						Set TABSEQUENCE = TABSEQUENCE + 1
						where TABSEQUENCE > @nPreviousTabSequence
						and TABSEQUENCE < @nCurrentTabSequence
						and TABID <> @pnTabKey
						and IDENTITYID = @pnUserIdentityId 
						"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nPreviousTabSequence	        tinyint,
							@nCurrentTabSequence	        tinyint,
							@pnTabKey	                int,
							@pnUserIdentityId	        int',
							@nPreviousTabSequence	        = @nPreviousTabSequence,
							@nCurrentTabSequence	        = @nCurrentTabSequence,
							@pnTabKey	                = @pnTabKey,
							@pnUserIdentityId	        = @pnUserIdentityId
					
			If @nErrorCode = 0
			Begin
				Set @nNewTabSequence = @nPreviousTabSequence + 1
			End						
		End
	End
	Else
	Begin
		-- Slide tabs from left to rigth
		Set @sSQLString = "
					Update PORTALTAB
					Set TABSEQUENCE = TABSEQUENCE - 1
					where TABSEQUENCE > @nCurrentTabSequence
					and TABSEQUENCE <= @nPreviousTabSequence
					and TABID <> @pnTabKey
					and IDENTITYID = @pnUserIdentityId"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nCurrentTabSequence	        tinyint,
						@nPreviousTabSequence	        tinyint,
						@pnTabKey	                int,
						@pnUserIdentityId	        int',
						@nCurrentTabSequence	        = @nCurrentTabSequence,
						@nPreviousTabSequence	        = @nPreviousTabSequence,
						@pnTabKey	                = @pnTabKey,
						@pnUserIdentityId	        = @pnUserIdentityId

		If @nErrorCode = 0
		Begin
			Set @nNewTabSequence = @nPreviousTabSequence
		End						
	
	End
End

-- Update the tab with new position.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Update PORTALTAB
		Set TABSEQUENCE = @nNewTabSequence
		where TABID = @pnTabKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int,
					  @nNewTabSequence	tinyint',
					  @pnTabKey		= @pnTabKey,
					  @nNewTabSequence	= @nNewTabSequence
End

Return @nErrorCode
GO

Grant execute on dbo.ua_UpdatePortalTabPosition to public
GO