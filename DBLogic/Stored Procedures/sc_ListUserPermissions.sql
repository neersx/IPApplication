-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_ListUserPermissions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_ListUserPermissions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_ListUserPermissions.'
	Drop procedure [dbo].[sc_ListUserPermissions]
End
Print '**** Creating Stored Procedure dbo.sc_ListUserPermissions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.sc_ListUserPermissions
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey 		int		= null	-- the key of the user who's permissions are required
)
as
-- PROCEDURE:	sc_ListUserPermissions
-- VERSION:	6
-- DESCRIPTION:	A single stored procedure to return all the permissions for the user.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Aug 2004	TM	RFC1500	1	Procedure created
-- 16 Nov 2004	TM	RFC869	2	Provide a list of modules the current user is licensed for, by calling
--					sc_ListUserLicenses for WorkBench modules (@pnModuleFlag = 4).
-- 15 Aug 2006	LP	RFC4237	3	Add RowKey column in the UserName result set.
-- 15 Apr 2013	DV	R13270	4	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).
-- 09 May 2018	MS	R74071	6	Restrict access to user permissions info

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode			int
declare @sSQLString 		nvarchar(4000)
declare @bIsExternalUser	bit
declare @dtToday			datetime
Declare	@sAlertXML			nvarchar(400)

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

-- If the @pnIdentityKey was not supplied then find out tasks 
-- for the current user (@pnUserIdentityId)
Set @pnIdentityKey = ISNULL(@pnIdentityKey, @pnUserIdentityId)

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bIsExternalUser=UI.ISEXTERNALUSER
	from	USERIDENTITY UI
	where	UI.IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit			OUTPUT,
				  @pnUserIdentityId		int',
				  @bIsExternalUser		=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId		=@pnUserIdentityId

	If @bIsExternalUser is null
	Begin
		Set @bIsExternalUser=1
	End
End

If @nErrorCode=0 and (@bIsExternalUser = 1 
					or not exists(select 1 from dbo.fn_PermissionsGranted(@pnUserIdentityId, 'MODULE', null, null, @dtToday) PF where PF.ObjectIntegerKey = -9 and PF.CanSelect = 1))

Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('SF43', 'This record is not available. This may be because you are accessing an entry that has been deleted recently, or you may not have the required security permission to access this.',
										null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR

End

-- Return the name of the requested user in the first result set formatted for display; i.e. UserName.
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'UserName',
	CAST(UI.IDENTITYID as nvarchar(11)) as 'RowKey'	
	from USERIDENTITY UI
	join NAME N	on (N.NAMENO = UI.NAMENO)
	where UI.IDENTITYID = @pnIdentityKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int',
					  @pnIdentityKey	= @pnIdentityKey
End

If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.sc_ListUserModules
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,			
			@pnIdentityKey		= @pnIdentityKey
End

If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.sc_ListUserTasks
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,			
			@pnIdentityKey		= @pnIdentityKey
End

If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.sc_ListUserTopics
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,			
			@pnIdentityKey		= @pnIdentityKey
End	

-- Provide a list of modules the current user is licensed for, by calling 
-- sc_ListUserLicenses for WorkBench modules (@pnModuleFlag = 4).
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.sc_ListUserLicenses
			@pnIdentityKey		= @pnIdentityKey,
			@pnModuleFlag		= 4
			
End	


Return @nErrorCode
GO

Grant execute on dbo.sc_ListUserPermissions to public
GO
