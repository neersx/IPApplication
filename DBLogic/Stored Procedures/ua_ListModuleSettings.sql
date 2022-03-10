-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListModuleSettings
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListModuleSettings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListModuleSettings.'
	Drop procedure [dbo].[ua_ListModuleSettings]
End
Print '**** Creating Stored Procedure dbo.ua_ListModuleSettings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_ListModuleSettings
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null	
)
as
-- PROCEDURE:	ua_ListModuleSettings
-- VERSION:	2
-- DESCRIPTION:	Returns a list of all the portal settings that have been defined for a Module

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Jul 2004	TM	RFC1085	1	Procedure created
-- 29 Dec 2017  DV	R73211	2	Return IsReadOnly for Module settings based on Maintain Custom Content Access task security

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @bCanMaintainCustomContentAccess bit

SET @bCanMaintainCustomContentAccess = 0

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
Set @sSQLString = "Select @bCanMaintainCustomContentAccess = 1
	from dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', 273, null, getdate()) PG
	where PG.CanExecute = 1"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bCanMaintainCustomContentAccess	bit				OUTPUT,
					  @pnUserIdentityId		int',
					  @bCanMaintainCustomContentAccess	= @bCanMaintainCustomContentAccess	OUTPUT,
					  @pnUserIdentityId		= @pnUserIdentityId
End
-- Populating Role result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  MODULEID	as 'ModuleKey',
		SETTINGNAME 	as 'SettingName',
		SETTINGVALUE	as 'SettingValue',
		cast((CASE WHEN SETTINGNAME = 'ParentAccessAllowed' and @bCanMaintainCustomContentAccess = 0 THEN  1 ELSE 0 END) as bit) as 'IsReadOnly'
	from PORTALSETTING 
	where MODULEID is not null 
	and   IDENTITYID is null
	order by MODULEID, SETTINGNAME"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@bCanMaintainCustomContentAccess	bit',
					  @bCanMaintainCustomContentAccess	= @bCanMaintainCustomContentAccess


	Set @pnRowCount = @@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.ua_ListModuleSettings to public
GO
