-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_IsNameAuthorized
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_IsNameAuthorized]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_IsNameAuthorized.'
	Drop procedure [dbo].[ipw_IsNameAuthorized]
End
Print '**** Creating Stored Procedure dbo.ipw_IsNameAuthorized...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_IsNameAuthorized
(
	@pbYes						bit		= null output,	
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		 = 0,
	@pnNameKey		int		 -- Mandatory
)
as
-- PROCEDURE:	ipw_IsNameAuthorized
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Check to see if the User has access to the Name 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 AUG 2010	DV	RFC9695	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @bIsExternalUser bit
declare @bCanSelect		bit	
declare	@bCanDelete		bit	
declare	@bCanInsert		bit	
declare	@bCanUpdate		bit	

-- Initialise variables
Set @nErrorCode = 0

If  @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit	Output,
				  @pnUserIdentityId		int',
				  @bIsExternalUser = @bIsExternalUser	Output,
				  @pnUserIdentityId = @pnUserIdentityId
End

If @nErrorCode=0
Begin
	If @bIsExternalUser = 1 
	Begin
		Set @pbYes = 0
		Set @sSQLString = "
			Select @pbYes = 1
			from dbo.fn_FilterUserViewNames(convert(varchar,@pnUserIdentityId))
			where NAMENO = @pnNameKey"
			
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					@pnUserIdentityId	int,
					@pbYes				bit output',
					@pnNameKey			= @pnNameKey,
					@pnUserIdentityId   = @pnUserIdentityId,
					@pbYes				= @pbYes output	
	End
	Else
	Begin
		Exec @nErrorCode=dbo.naw_GetSecurityForName
						@pnUserIdentityId=@pnUserIdentityId,
						@psCulture=@psCulture,
						@pnNameKey=@pnNameKey,
						@pbCanSelect=@bCanSelect 	output,
						@pbCanDelete=@bCanDelete	output,
						@pbCanInsert=@bCanInsert	output,
						@pbCanUpdate=@bCanUpdate	output

		if (@bCanSelect=1 or  @bCanDelete =1 or @bCanInsert =1 or @bCanUpdate =1)
		Begin
			Set @pbYes = 1
		End
	End
End

If @nErrorCode = 0
and @pbCalledFromCentura = 0
Begin
	-- publish to .net dataaccess
	Select isnull(@pbYes,0)
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_IsNameAuthorized to public
GO
