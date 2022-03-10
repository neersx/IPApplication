-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateLink
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateLink]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateLink.'
	Drop procedure [dbo].[ipw_UpdateLink]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateLink...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateLink
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnLinkKey		int,		-- Mandatory
	@pnCategoryKey		int,
	@psTitle		nvarchar(100)	= null,	
	@psDescription		nvarchar(254)	= null,
	@psURL			nvarchar(254)	= null,
	@pbIsPersonal		bit		= null,
	@pnDisplaySequence	smallint	= null,
	@pnAccessAccountKey	int		= null,
	@pbIsExternal 		bit		= null,
	@pnOldCategoryKey	int,
	@psOldTitle		nvarchar(100)	= null,	
	@psOldDescription	nvarchar(254)	= null,
	@psOldURL		nvarchar(254)	= null,
	@pbOldIsPersonal	bit		= null,
	@pnOldDisplaySequence	smallint	= null,
	@pnOldAccessAccountKey	int		= null,
	@pbOldIsExternal 	bit		= null
)
as
-- PROCEDURE:	ipw_UpdateLink
-- VERSION:	2
-- DESCRIPTION:	Update a Link if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Oct 2004	TM	RFC391	1	Procedure created
-- 01 Nov 204 	TM	RFC391	2	Change the @psAccessAccountKey name to @pnAccessAccountKey and
--					@psOldAccessAccountKey to be @pnOldAccessAccountKey.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

declare @nIdentityKey		int
declare @nOldIdentityKey 	int

-- Initialise variables
Set @nErrorCode 	= 0
Set @nIdentityKey	= CASE WHEN @pbIsPersonal = 1 THEN @pnUserIdentityId ELSE NULL END
Set @nOldIdentityKey	= CASE WHEN @pbOldIsPersonal = 1 THEN @pnUserIdentityId ELSE NULL END

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Update  LINK
	set	URL		= @psURL,
		TITLE		= @psTitle,
		DESCRIPTION	= @psDescription,
		DISPLAYSEQUENCE	= @pnDisplaySequence,
		CATEGORYID	= @pnCategoryKey,
		IDENTITYID	= @nIdentityKey,		
		ACCESSACCOUNTID	= @pnAccessAccountKey,
		ISEXTERNAL	= @pbIsExternal
	where   LINKID 		= @pnLinkKey
	and     URL		= @psOldURL
	and	TITLE		= @psOldTitle
	and 	DESCRIPTION	= @psOldDescription
	and     DISPLAYSEQUENCE	= @pnOldDisplaySequence
	and	CATEGORYID	= @pnOldCategoryKey
	and 	IDENTITYID	= @nOldIdentityKey
	and 	ACCESSACCOUNTID	= @pnOldAccessAccountKey
	and 	ISEXTERNAL	= @pbOldIsExternal"	

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnLinkKey		int,
					  @psURL		nvarchar(254),
					  @psTitle		nvarchar(100),					 
					  @psDescription	nvarchar(254),
					  @pnDisplaySequence	smallint,
					  @pnCategoryKey	int,
					  @pbIsPersonal		bit,
					  @nIdentityKey		int,
					  @pnAccessAccountKey	int,
					  @pbIsExternal		bit,
					  @psOldURL		nvarchar(254),
					  @psOldTitle		nvarchar(100),					 
					  @psOldDescription	nvarchar(254),
					  @pnOldDisplaySequence	smallint,
					  @pnOldCategoryKey	int,
					  @nOldIdentityKey	int,
					  @pbOldIsPersonal	bit,
					  @pnOldAccessAccountKey int,
					  @pbOldIsExternal	bit',
					  @pnLinkKey		= @pnLinkKey,
					  @psURL		= @psURL,
					  @psTitle		= @psTitle,					 
					  @psDescription	= @psDescription,
					  @pnDisplaySequence	= @pnDisplaySequence,
					  @pnCategoryKey	= @pnCategoryKey,
					  @pbIsPersonal		= @pbIsPersonal,
					  @nIdentityKey		= @nIdentityKey,
					  @pnAccessAccountKey	= @pnAccessAccountKey,
					  @pbIsExternal		= @pbIsExternal,
					  @psOldURL		= @psOldURL,
					  @psOldTitle		= @psOldTitle,					 
					  @psOldDescription	= @psOldDescription,
					  @pnOldDisplaySequence	= @pnOldDisplaySequence,
					  @pnOldCategoryKey	= @pnOldCategoryKey,
					  @nOldIdentityKey	= @nOldIdentityKey,
					  @pbOldIsPersonal	= @pbOldIsPersonal,
					  @pnOldAccessAccountKey= @pnOldAccessAccountKey,
					  @pbOldIsExternal	= @pbOldIsExternal		
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateLink to public
GO