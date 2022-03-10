-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListRoleData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListRoleData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListRoleData.'
	Drop procedure [dbo].[ua_ListRoleData]
End
Print '**** Creating Stored Procedure dbo.ua_ListRoleData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_ListRoleData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnRoleKey		int	-- Mandatory
)
as
-- PROCEDURE:	ua_ListRoleData
-- VERSION:	8
-- DESCRIPTION:	Populate the RoleData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Apr 2004	TM	RFC917	1	Procedure created
-- 27 Apr 2004	TM	RFC917	2	The SelectedTopic result set should be empty if there are no topics 
--					selected for the role; i.e. select the data from ROLETOPICS not ROLE.
-- 18 Jun 2004	TM	RFC1499	3	Add new IsProtected column to the Role result set. Remove PortalKey,
--					PortalName, and PortalDescription columns.
-- 18 Aug 2004	TM	RFC1500	4	Add new SelectedModule and SelectedTask result sets. Implement Permissions 
--					in the SelectedTopic result set.
-- 01 Dec 2004	TM	RFC2083	5	Include a full join to dbo.fn_ValidObjects for DATATOPICREQUIRES in the
--					SelectedTopic result set.
-- 01 Dec 2004	JEK	RFC2079	6	Limit result sets to those including valid objects.
-- 01 Dec 2004	JEK	RFC2079	6	Move InternalUse/ExternalUse checking to fn_PermissionData.
-- 12 Jul 2006	SW	RFC3828	7	Pass getdate() to fn_Permission..
-- 03 Dec 2007	vql	RFC5909	8	Change RoleKey and DocumentDefId from smallint to int.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @dtToday	datetime

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

-- Populating Role result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  R.ROLEID 	  as RoleKey, 
		R.ROLENAME 	  as RoleName, 
		R.DESCRIPTION 	  as Description, 
		R.ISEXTERNAL 	  as IsExternal, 
		R.ISPROTECTED	  as IsProtected		
	from ROLE R
	where R.ROLEID = @pnRoleKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRoleKey	int',
					  @pnRoleKey	= @pnRoleKey

End

-- Populating SelectedModule result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  FP.LevelKey 	  	as RoleKey, 
		FP.ObjectIntegerKey	as ModuleKey, 
		M.TITLE 	 	as ModuleTitle, 
		M.DESCRIPTION 	  	as Description, 
		FP.SelectPermission	as SelectPermission,
		FP.MandatoryPermission	as MandatoryPermission		
	from dbo.fn_PermissionData('ROLE', @pnRoleKey, 'MODULE', NULL, NULL, @dtToday) FP
	join MODULE M			on (M.MODULEID = FP.ObjectIntegerKey)
	order by ModuleTitle"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRoleKey	int,
					  @dtToday	datetime',
					  @pnRoleKey	= @pnRoleKey,
					  @dtToday	= @dtToday

End

-- Populating SelectedTask result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  FP.LevelKey 	  	as RoleKey, 
		FP.ObjectIntegerKey	as TaskKey, 
		T.TASKNAME 	 	as TaskName, 
		T.DESCRIPTION 	  	as Description, 
		FP.InsertPermission	as InsertPermission,
		FP.UpdatePermission	as UpdatePermission,	
		FP.DeletePermission	as DeletePermission,
		FP.ExecutePermission	as ExecutePermission		
	from dbo.fn_PermissionData('ROLE', @pnRoleKey, 'TASK', NULL, NULL, @dtToday) FP
	join TASK T			on (T.TASKID = FP.ObjectIntegerKey)
	order by TaskName"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRoleKey	int,
					  @dtToday	datetime',
					  @pnRoleKey	= @pnRoleKey,
					  @dtToday	= @dtToday

End

-- Populating SelectedTopic result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  FP.LevelKey 		as RoleKey, 		 
		FP.ObjectIntegerKey 	as TopicKey, 
		DT.TOPICNAME 		as TopicName, 
		DT.DESCRIPTION 		as Description,
		FP.SelectPermission	as SelectPermission	
	from dbo.fn_PermissionData('ROLE', @pnRoleKey, 'DATATOPIC', NULL, NULL, @dtToday) FP
	join DATATOPIC DT	on (DT.TOPICID = FP.ObjectIntegerKey)
	join dbo.fn_ValidObjects(NULL, 'DATATOPICREQUIRES', @dtToday) VOR
				on (VOR.ObjectIntegerKey = FP.ObjectIntegerKey)
	order by TopicName"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRoleKey	int,
					  @dtToday	datetime',
					  @pnRoleKey	= @pnRoleKey,
					  @dtToday	= @dtToday

	Set @pnRowCount = @@ROWCOUNT
End

Return @nErrorCode
GO

Grant execute on dbo.ua_ListRoleData to public
GO
