-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_DeleteDefaultPresentation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_DeleteDefaultPresentation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_DeleteDefaultPresentation.'
	Drop procedure [dbo].[qr_DeleteDefaultPresentation]
End
Print '**** Creating Stored Procedure dbo.qr_DeleteDefaultPresentation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_DeleteDefaultPresentation
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnContextKey			int,		-- Mandatory
	@pbIsPublic			bit,		-- Mandatory
	@psPresentationType	nvarchar(30)	= null
)
as
-- PROCEDURE:	qr_DeleteDefaultPresentation
-- VERSION:	3
-- DESCRIPTION:	Deletes default query presentation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Jul 2004	TM	RFC578	1	Procedure created
-- 21 Jul 2004	TM	RFC578	2	Remove concurrency checking.
-- 29 Jan 2010	SF	RFC8483	3	Add Presentation Type

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nIdentityKey		int

-- Initialise variables
Set @nErrorCode 		= 0
					
-- Delete any existing default presentation
If @nErrorCode = 0 
Begin
	-- If IsPublic = 0, set IdentityID to current user’s identity, otherwise null.		
	Set @nIdentityKey = CASE WHEN @pbIsPublic = 0 THEN @pnUserIdentityId ELSE null END

	Set @sSQLString = " 
	Delete
	from	QUERYPRESENTATION
	where	IDENTITYID 	= @nIdentityKey
	and	ISDEFAULT 	= 1
	and	CONTEXTID	= @pnContextKey
	and ((PRESENTATIONTYPE is null and @psPresentationType is null)
		or (PRESENTATIONTYPE = @psPresentationType))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nIdentityKey			int,
					  @pnContextKey			int,
					  @psPresentationType	nvarchar(30)',
					  @nIdentityKey			= @nIdentityKey,
					  @pnContextKey			= @pnContextKey,
					  @psPresentationType	= @psPresentationType
End

Return @nErrorCode
GO

Grant execute on dbo.qr_DeleteDefaultPresentation to public
GO
