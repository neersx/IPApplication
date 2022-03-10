-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_InsertQueryDefault
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_InsertQueryDefault]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_InsertQueryDefault.'
	Drop procedure [dbo].[qr_InsertQueryDefault]
End
Print '**** Creating Stored Procedure dbo.qr_InsertQueryDefault...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_InsertQueryDefault
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryKey		int,		-- Mandatory
	@pnContextKey		int,		-- Mandatory
	@pnIdentityKey 		int		= null,	-- the key of the user for whom the default search needs to be inserted.	
	@pnAccessAccountKey 	int		= null
)
as
-- PROCEDURE:	qr_InsertQueryDefault
-- VERSION:	9
-- DESCRIPTION:	Attaches a search as the current user’s default.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 19 Jul 2004	TM	RFC1543		1	Procedure created
-- 16 Mar 2005	TM	RFC980		2	Check whether the query is already the public default. If so, 
--						do not create a personal default. Set nocount of as no
--						concurrency checking required.
-- 21 Dec 2005	TM	RFC3221		7	Implement default searches by access account.
-- 01 Feb 2006	TM	RFC3546		8	Correct population of the @bIsPublicDefault.
-- 23 Jun 2014     SS	RF26285		9	 User choices should be explictly recorded or kept even if it aligns with the public default preference

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

-- Delete any existing default for the identity
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete
	from QUERYDEFAULT
	where CONTEXTID 	= @pnContextKey
	and   IDENTITYID 	= @pnIdentityKey
	and   ACCESSACCOUNTID	= @pnAccessAccountKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnContextKey		int,
					  @pnAccessAccountKey	int',
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnContextKey		= @pnContextKey,
					  @pnAccessAccountKey	= @pnAccessAccountKey
End

-- Insert new default
If @nErrorCode = 0
Begin	
	Set @sSQLString = " 
	insert	QUERYDEFAULT
		(CONTEXTID,
		 IDENTITYID,
		 QUERYID,
		 ACCESSACCOUNTID)
	values	(@pnContextKey,
		 @pnIdentityKey,
		 @pnQueryKey,
		 @pnAccessAccountKey)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnContextKey		int,
					  @pnQueryKey		int,
					  @pnAccessAccountKey	int',
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnContextKey		= @pnContextKey,
					  @pnQueryKey		= @pnQueryKey,
					  @pnAccessAccountKey	= @pnAccessAccountKey
	
End

Return @nErrorCode
GO

Grant execute on dbo.qr_InsertQueryDefault to public
GO
