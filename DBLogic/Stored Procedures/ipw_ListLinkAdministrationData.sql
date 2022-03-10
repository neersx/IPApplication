-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListLinkAdministrationData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListLinkAdministrationData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListLinkAdministrationData.'
	Drop procedure [dbo].[ipw_ListLinkAdministrationData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListLinkAdministrationData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListLinkAdministrationData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCategoryKey 		int,		-- Mandatory
	@pbIsPersonal 		bit,		-- Mandatory
	@pnAccessAccountKey	int		= null,
	@pbIsExternal		bit		= null	
)
as
-- PROCEDURE:	ipw_ListLinkAdministrationData
-- VERSION:	4
-- DESCRIPTION:	Populates the LinkAdministrationData dataset

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Oct 2004	TM	RFC391	1	Procedure created
-- 19 Nov 2004	TM	RFC869	2	In the Category result set change the Description column to be CategoryName.
-- 07 Mar 2007 	PG	RFC4921	3	Return AccessAccount data in a seperate table	
-- 15 Dec 2009	LP	RFC8690	4	Remove left join to ACCESSACCOUNT as it is no longer required.
--					Only return links without AccessAccount if none specified.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @nAccessAccountID	int
Declare @bIsExternalUser	bit

-- Initialise variables
Set @nErrorCode = 0

-- Populating Category result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  TC.TABLECODE		as CategoryKey,
		TC.DESCRIPTION		as CategoryName
	from TABLECODES TC
	where TC.TABLECODE = @pnCategoryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCategoryKey 	int',
					  @pnCategoryKey	= @pnCategoryKey

End

-- Populating Link result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  L.LINKID		as LinkKey,
		L.CATEGORYID		as CategoryKey,
		L.TITLE			as Title,
		DESCRIPTION		as Description,
		L.URL			as URL,
		CASE 	WHEN L.IDENTITYID is not null
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END			as IsPersonal,
		L.DISPLAYSEQUENCE	as DisplaySequence,
		L.ACCESSACCOUNTID	as AccessAccountKey,
		L.ISEXTERNAL		as IsExternal
	from LINK L
	where L.CATEGORYID = @pnCategoryKey"+CHAR(10)+
	CASE 	WHEN @pbIsPersonal = 1
		THEN "and L.IDENTITYID = @pnUserIdentityId"
	END+CHAR(10)+
	CASE	WHEN @pnAccessAccountKey is not null
		THEN "and L.ACCESSACCOUNTID = @pnAccessAccountKey"
		ELSE "and L.ACCESSACCOUNTID IS NULL"
	END+CHAR(10)+
	CASE	WHEN @pbIsExternal IS NOT NULL
		THEN "and L.ISEXTERNAL = @pbIsExternal"
	END+CHAR(10)+
	"order by L.DISPLAYSEQUENCE"		    

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCategoryKey	int,
					  @pnUserIdentityId 	int,
					  @pnAccessAccountKey	int,
					  @pbIsExternal		bit',
					  @pnCategoryKey	= @pnCategoryKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnAccessAccountKey	= @pnAccessAccountKey,
					  @pbIsExternal		= @pbIsExternal

	Set @pnRowCount = @@RowCount 
End

--Populate AccessAccount result set
If @nErrorCode =0 and @pnAccessAccountKey!=0
Begin
Set @sSQLString = " 
	Select  A.ACCOUNTID		as AccessAccountKey,
		A.ACCOUNTNAME		as AccessAccount,
		@pnCategoryKey		as CategoryKey
	from ACCESSACCOUNT A
	where A.ACCOUNTID = @pnAccessAccountKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnAccessAccountKey 	int,
					  @pnCategoryKey 	int',
					  @pnAccessAccountKey	= @pnAccessAccountKey,
					  @pnCategoryKey	= @pnCategoryKey
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListLinkAdministrationData to public
GO
