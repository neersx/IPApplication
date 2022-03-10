-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertLink
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertLink]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertLink.'
	Drop procedure [dbo].[ipw_InsertLink]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertLink...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_InsertLink
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psLinkKey		nvarchar(30)	= null,	-- Included to provide a standard interface
	@pnCategoryKey		int,
	@psTitle		nvarchar(100)	= null,	
	@psDescription		nvarchar(254)	= null,
	@psURL			nvarchar(254)	= null,
	@pbIsPersonal		bit		= null,
	@pnDisplaySequence	smallint	= null,
	@pnAccessAccountKey	int		= null,
	@pbIsExternal 		bit		= null
)
as
-- PROCEDURE:	ipw_InsertLink
-- VERSION:	3
-- DESCRIPTION:	Add a new Link, returning the generated Link key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Oct 2004	TM	RFC391	1	Procedure created
-- 01 Nov 2004	TM	RFC391	2	Change the @psAccessAccountKey name to @pnAccessAccountKey.
-- 13 Sep 2007	PG	RFC4921	3	Change '@pnLinkKey int' to '@psLinkKey nvarchar(30)'

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
Set @nIdentitKey	= CASE WHEN @pbIsPersonal = 1 THEN @pnUserIdentityId ELSE NULL END

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into LINK
		(URL, 
		 TITLE, 		 
		 DESCRIPTION,
		 DISPLAYSEQUENCE,
		 CATEGORYID,
		 IDENTITYID,
		 ACCESSACCOUNTID,
		 ISEXTERNAL)
	values	(@psURL,
		 @psTitle, 		
		 @psDescription,
		 @pnDisplaySequence,
		 @pnCategoryKey,
		 @nIdentitKey,
		 @pnAccessAccountKey,
		 @pbIsExternal)

	Set @psLinkKey = cast(SCOPE_IDENTITY() as nvarchar(30))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psLinkKey		nvarchar(30)	OUTPUT,
					  @psURL		nvarchar(254),
					  @psTitle		nvarchar(100),					 
					  @psDescription	nvarchar(254),
					  @pnDisplaySequence	smallint,
					  @pnCategoryKey	int,
					  @pbIsPersonal		bit,
					  @nIdentitKey		int,
					  @pnAccessAccountKey	int,
					  @pbIsExternal		bit',
					  @psLinkKey		= @psLinkKey	OUTPUT,
					  @psURL		= @psURL,
					  @psTitle		= @psTitle,					 
					  @psDescription	= @psDescription,
					  @pnDisplaySequence	= @pnDisplaySequence,
					  @pnCategoryKey	= @pnCategoryKey,
					  @pbIsPersonal		= @pbIsPersonal,
					  @nIdentitKey		= @nIdentitKey,
					  @pnAccessAccountKey	= @pnAccessAccountKey,
					  @pbIsExternal		= @pbIsExternal	

	-- Publish the key so that the dataset is updated
	Select @psLinkKey as LinkKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertLink to public
GO