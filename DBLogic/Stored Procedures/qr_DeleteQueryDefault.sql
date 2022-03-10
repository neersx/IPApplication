-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_DeleteQueryDefault
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_DeleteQueryDefault]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_DeleteQueryDefault.'
	Drop procedure [dbo].[qr_DeleteQueryDefault]
End
Print '**** Creating Stored Procedure dbo.qr_DeleteQueryDefault...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.qr_DeleteQueryDefault
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryKey		int,		-- Mandatory
	@pnIdentityKey 		int		= null	-- the key of the user for whom the default search needs to be removed.	
)
as
-- PROCEDURE:	qr_DeleteQueryDefault
-- VERSION:	3
-- DESCRIPTION:	Removes any existing default search for a supplied parameters.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 19 Jul 2004	TM	RFC1543		1	Procedure created
-- 03 Jan 2006	TM	RFC3221		2	Implement default searches by access account.
-- 05 Jan 2006	TM	RFC3221		3	Correct the filtering logic.
-- 26 Jun 2014  SS	RFC27691	4	Modified to allow default public query checkbox editable on screen. If user removes default public search manually created fall back to original default search for the context

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nAccessAccountID	int
Declare @bIsExternal		bit
Declare @pnRowCount	int
Declare @pnContextKey int
Declare @pnQueryDefaultKey int

-- Initialise variables
Set @nErrorCode 		= 0
Set @nAccessAccountID	= null
Set @pnRowCount		= 0
Set @pnContextKey	= null
Set @pnQueryDefaultKey = null

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select	@nAccessAccountID = ACCOUNTID,
		@bIsExternal = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@nAccessAccountID		int			output,
				  @bIsExternal			bit			output,
				  @pnUserIdentityId		int',
				  @nAccessAccountID		= @nAccessAccountID	output,
				  @bIsExternal			= @bIsExternal		output,
				  @pnUserIdentityId		= @pnUserIdentityId
End


-- Select the context key for the query being deleted, only if the update is being made for public default
If @nErrorCode = 0 and @pnIdentityKey is null
Begin
	Set @sSQLString = " 
	Select top 1 @pnContextKey = CONTEXTID
	from QUERYDEFAULT
	where QUERYID = @pnQueryKey  and IDENTITYID is null "+			
	CASE	
		WHEN @bIsExternal = 0 	-- Public internal search
		THEN char(10)+"and ACCESSACCOUNTID is null"
		WHEN @bIsExternal = 1   -- Public external search 
		THEN char(10)+"and ACCESSACCOUNTID = @nAccessAccountID"
	END

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnContextKey		int output,
					  @pnQueryKey		int,
					  @nAccessAccountID	int',
					  @pnContextKey		= @pnContextKey output,
					  @pnQueryKey		= @pnQueryKey,
					  @nAccessAccountID	= @nAccessAccountID	

End

-- Delete any existing default 
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete
	from QUERYDEFAULT
	where QUERYID 		= @pnQueryKey"+			
	CASE	WHEN @pnIdentityKey is not null 			-- Personal search
		THEN char(10)+"and IDENTITYID = @pnIdentityKey"
		WHEN @bIsExternal = 0 and @pnIdentityKey is null 	-- Public internal search
		THEN char(10)+"and ACCESSACCOUNTID is null and IDENTITYID is null"
		WHEN @bIsExternal = 1 and @pnIdentityKey is null	-- Public external search 
		THEN char(10)+"and IDENTITYID is null and ACCESSACCOUNTID = @nAccessAccountID"
	END

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnQueryKey		int,
					  @nAccessAccountID	int',
					  @pnIdentityKey	= @pnIdentityKey,
					  @pnQueryKey		= @pnQueryKey,
					  @nAccessAccountID	= @nAccessAccountID	
End

--Check if the deleted query was public default, check if the context has any other default record left
If  @nErrorCode = 0 and @pnIdentityKey is null and @pnContextKey is not null
Begin
	Set @sSQLString = " 
	Select @pnRowCount = Count( QUERYID )
	from QUERYDEFAULT 
	where CONTEXTID = @pnContextKey and IDENTITYID is null "+
	CASE 
		WHEN @bIsExternal = 0  	-- Public internal search
		THEN char(10)+"and ACCESSACCOUNTID is null"
		WHEN @bIsExternal = 1	-- Public external search 
		THEN char(10)+"and ACCESSACCOUNTID = @nAccessAccountID"
	END

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRowCount int output,
					  @pnContextKey	int,
					  @nAccessAccountID	int',
					  @pnRowCount  = @pnRowCount output, 
					  @pnContextKey	= @pnContextKey,
					  @nAccessAccountID	= @nAccessAccountID	

	--If no records found insert the original default query
	if @nErrorCode = 0 and @pnRowCount = 0
	Begin
		Set @sSQLString = " 
		Select top 1 @pnQueryDefaultKey = QueryID 
		from QUERY 
		where ISCLIENTSERVER = 0 and ISPROTECTED = 1
		and IDENTITYID is null
		and contextID = @pnContextKey "+
		CASE 
			WHEN @bIsExternal = 0 	-- Public internal search
			THEN char(10)+"and ACCESSACCOUNTID is null"
			WHEN @bIsExternal = 1 -- Public external search 
			THEN char(10)+"and ACCESSACCOUNTID = @nAccessAccountID"
		END
		
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnQueryDefaultKey int output,
					  @pnContextKey	int,
					  @nAccessAccountID int',
					  @pnQueryDefaultKey = @pnQueryDefaultKey output,
					  @pnContextKey = @pnContextKey,
					  @nAccessAccountID = @nAccessAccountID
					
		if ( @bIsExternal = 0) 
			set @nAccessAccountID = null
			
		if ( @nErrorCode = 0 and @pnQueryDefaultKey is not null )
		Begin
			exec @nErrorCode = qr_InsertQueryDefault
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnQueryKey		= @pnQueryDefaultKey,
				@pnContextKey		= @pnContextKey,
				@pnIdentityKey		= NULL,
				@pnAccessAccountKey	= @nAccessAccountID
		End	  
	End
End

Return @nErrorCode
GO

Grant execute on dbo.qr_DeleteQueryDefault to public
GO
