-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListLinkData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListLinkData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListLinkData.'
	Drop procedure [dbo].[ipw_ListLinkData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListLinkData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListLinkData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCategoryKey 		int,		-- Mandatory
	@pbIsPersonal 		bit,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListLinkData
-- VERSION:	6
-- DESCRIPTION:	Populates the LinkData dataset

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Oct 2004	TM	RFC390	1	Procedure created
-- 28 Oct 2004	TM	RFC390	2	Sort Link result set by the Display Sequence.
-- 24 Nov 2004	TM	RFC390	3	Correct the filtering logic in the link result set.
-- 29 Nov 2004	TM	RFC390	4	Correct the logic in the Link result set to eliminate duplicated rows.
-- 15 May 2005	JEK	RFC2508	5	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 24 Jun 2014	SF	R35928	6	When there are no links set for a specific account 
--                                      return only those links which have not been setup specifically for an access account


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @nAccessAccountID	int
Declare @bIsExternalUser	bit
Declare @bHasAccessAcntLinks	bit

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0

-- Populating Category result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  TC.TABLECODE		as CategoryKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				    + " as Description
	from TABLECODES TC
	where TC.TABLECODE = @pnCategoryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCategoryKey 	int',
					  @pnCategoryKey	= @pnCategoryKey

End

-- Populating Link result set
If @nErrorCode = 0
-- When @pbIsPersonal = 1, only links for the IdentityId of the current user are returned.
and @pbIsPersonal = 1
Begin
	Set @sSQLString = " 
	Select  L.CATEGORYID		as CategoryKey,
		"+dbo.fn_SqlTranslatedColumn('LINK','TITLE',null,'L',@sLookupCulture,@pbCalledFromCentura)
				    + " as Title,
		"+dbo.fn_SqlTranslatedColumn('LINK','DESCRIPTION',null,'L',@sLookupCulture,@pbCalledFromCentura)
				    + " as Description,
		L.URL			as URL
	from LINK L
	where L.CATEGORYID = @pnCategoryKey
	and   L.IDENTITYID = @pnUserIdentityId
	order by L.DISPLAYSEQUENCE"		    

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCategoryKey	int,
					  @pnUserIdentityId 	int',
					  @pnCategoryKey	= @pnCategoryKey,
					  @pnUserIdentityId	= @pnUserIdentityId

	Set @pnRowCount = @@RowCount 
End
Else
If @nErrorCode = 0
-- When @pbIsPersonal = 0, links are returned for the current user's AccessAccountID.  
-- If none are found, the links are returned based on the user's IsExternalUser flag.
and @pbIsPersonal = 0
Begin
	Set @sSQLString = " 
	Select  @nAccessAccountID 	= UI.ACCOUNTID,
		@bIsExternalUser  	= UI.ISEXTERNALUSER,
		-- Are there any links for the userr's access account? 
		@bHasAccessAcntLinks 	= CASE 	WHEN L.ACCESSACCOUNTID IS NOT NULL 
						THEN 1
						ELSE 0
					  END
	from    USERIDENTITY UI
	left join LINK L	on (L.ACCESSACCOUNTID = UI.ACCOUNTID)
	where   UI.IDENTITYID = @pnUserIdentityId"		    

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nAccessAccountID	int			output,
					  @bIsExternalUser	bit			output,
					  @bHasAccessAcntLinks	bit			output,
					  @pnUserIdentityId 	int',
					  @nAccessAccountID	= @nAccessAccountID	output,
					  @bIsExternalUser	= @bIsExternalUser	output,
					  @bHasAccessAcntLinks	= @bHasAccessAcntLinks	output,
					  @pnUserIdentityId	= @pnUserIdentityId

	-- If there are links for the user's access account then use the user's
	-- access account as filter criteria:
	If @nErrorCode = 0
	and @bHasAccessAcntLinks = 1
	Begin		
		Set @sSQLString = " 
		Select  L.CATEGORYID	as CategoryKey,
			"+dbo.fn_SqlTranslatedColumn('LINK','TITLE',null,'L',@sLookupCulture,@pbCalledFromCentura)+"
			    	        as Title,
			"+dbo.fn_SqlTranslatedColumn('LINK','DESCRIPTION',null,'L',@sLookupCulture,@pbCalledFromCentura)+"
					as Description,
			L.URL		as URL
		from LINK L
		where L.CATEGORYID = @pnCategoryKey
		and L.ACCESSACCOUNTID = @nAccessAccountID    	    
		order by L.DISPLAYSEQUENCE"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nAccessAccountID	int,
						  @pnCategoryKey 	int',
						  @nAccessAccountID	= @nAccessAccountID,
						  @pnCategoryKey	= @pnCategoryKey		

		Set @pnRowCount = @@RowCount		
	End
	-- If there are no links for the user's access account then
	-- return all internal/external links as required:
	Else
	If @nErrorCode = 0
	and @bHasAccessAcntLinks = 0
	Begin		
		Set @sSQLString = " 
		Select  L.CATEGORYID	as CategoryKey,
			"+dbo.fn_SqlTranslatedColumn('LINK','TITLE',null,'L',@sLookupCulture,@pbCalledFromCentura)+"
			    	        as Title,
			"+dbo.fn_SqlTranslatedColumn('LINK','DESCRIPTION',null,'L',@sLookupCulture,@pbCalledFromCentura)+"
					as Description,
			L.URL		as URL
		from LINK L
		where L.CATEGORYID = @pnCategoryKey
		and   L.ISEXTERNAL = @bIsExternalUser
		and   L.ACCESSACCOUNTID is null  	    
		order by L.DISPLAYSEQUENCE"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnCategoryKey 	int,
						  @bIsExternalUser	bit',
						  @pnCategoryKey	= @pnCategoryKey,
						  @bIsExternalUser	= @bIsExternalUser		

		Set @pnRowCount = @@RowCount		
	End
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListLinkData to public
GO
