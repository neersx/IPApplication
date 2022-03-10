-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteLink
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteLink]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteLink.'
	Drop procedure [dbo].[ipw_DeleteLink]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteLink...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteLink
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnLinkKey		int,		-- Mandatory
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
-- PROCEDURE:	ipw_DeleteLink
-- VERSION:	2
-- DESCRIPTION:	Delete a Link if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Oct 2004	TM	RFC391	1	Procedure created
-- 01 Nov 2004	TM	RFC391	2	Change the @psOldAccessAccountKey name to @pnOldAccessAccountKey. 	

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

declare @nIdentitKey	int

-- Initialise variables
Set @nErrorCode 	= 0
Set @nIdentitKey	= CASE WHEN @pbOldIsPersonal = 1 THEN @pnUserIdentityId ELSE NULL END

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete
	from    LINK
	where   LINKID 		= @pnLinkKey
	and     URL		= @psOldURL
	and	TITLE		= @psOldTitle
	and 	DESCRIPTION	= @psOldDescription
	and     DISPLAYSEQUENCE	= @pnOldDisplaySequence
	and	CATEGORYID	= @pnOldCategoryKey
	and 	IDENTITYID	= @nIdentitKey
	and 	ACCESSACCOUNTID	= @pnOldAccessAccountKey
	and 	ISEXTERNAL	= @pbOldIsExternal"	

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnLinkKey		int,
					  @nIdentitKey		int,
					  @psOldURL		nvarchar(254),
					  @psOldTitle		nvarchar(100),					 
					  @psOldDescription	nvarchar(254),
					  @pnOldDisplaySequence	smallint,
					  @pnOldCategoryKey	int,
					  @pbOldIsPersonal	bit,
					  @pnOldAccessAccountKey int,
					  @pbOldIsExternal	bit',
					  @pnLinkKey		= @pnLinkKey,
					  @nIdentitKey		= @nIdentitKey,
					  @psOldURL		= @psOldURL,
					  @psOldTitle		= @psOldTitle,					 
					  @psOldDescription	= @psOldDescription,
					  @pnOldDisplaySequence	= @pnOldDisplaySequence,
					  @pnOldCategoryKey	= @pnOldCategoryKey,
					  @pbOldIsPersonal	= @pbOldIsPersonal,
					  @pnOldAccessAccountKey= @pnOldAccessAccountKey,
					  @pbOldIsExternal	= @pbOldIsExternal		
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteLink to public
GO