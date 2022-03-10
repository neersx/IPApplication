-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListFeatureData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListFeatureData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListFeatureData.'
	Drop procedure [dbo].[ua_ListFeatureData]
End
Print '**** Creating Stored Procedure dbo.ua_ListFeatureData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_ListFeatureData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnRoleKey		int	= null	-- The @pnRoleKey is null for a new Role
)
as
-- PROCEDURE:	ua_ListFeatureData
-- VERSION:	13
-- DESCRIPTION:	Populates the FeatureData dataset

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Aug 2004	TM	RFC1500	1	Procedure created
-- 07 Sep 2004  TM	RFC1500	2	Add a Description column to each of the Moduel and Task result sets.
-- 15 Sep 2004	TM	RFC1500	3	Add the following new columns to the Task datatable: IsInsertApplicable,
--					IsUpdateApplicable, IsDeleteApplicable, IsExecuteApplicable
-- 21 Sep 2004	JEK	RFC1500	4	For the User role, only features that are applicable for both internal and
--					external use should be shown.
-- 21 Sep 2004	JEK	RFC1500	5	Features that are both internal and external are not being returned for
--					roles that are one or the other.
-- 15 Nov 2004	TM	RFC869	6	Implement a full join to fn_ValidObjects to suppress any web parts, tasks 
--					or topics that are not licensed to the firm.
-- 18 Nov 2004	TM	RFC869	7	Improve performance.
-- 19 Nov 2004	TM	RFC869	8	Correct the Feature result set.
-- 01 Dec 2004	JEK	RFC2079	9	Include InternalUse/External use in join to fn_ValidObjects.
-- 16 Dec 2004	TM	RFC2100	10	Remove the flags against the Feature and implement them instead against
--					the Module and Task data tables.
-- 22 Dec 2004	TM	RFC2100	11	Re-implement the IsInternal and IsExternal flags on the Feature result set.
-- 12 Jul 2006	SW	RFC3828	12	Pass getdate() to fn_Permission.., fn_ValidObjects
-- 03 Dec 2007	vql	RFC5909	13	Change RoleKey and DocumentDefId from smallint to int.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

declare @tblFeature  	table  (FEATUREID		smallint					NOT NULL,
			  	FEATURENAME		nvarchar(50)	collate database_default	NOT NULL,
				CATEGORYID		int						NULL,
				MODULEID		int						NULL,
				TASKID			int						NULL,
				INUSE			bit						NOT NULL,
				ISMODULEEXTERNAL 	bit						NULL,
				ISMODULEINTERNAL 	bit						NULL,
				ISTASKEXTERNAL   	bit						NULL,
				ISTASKINTERNAL	 	bit						NULL,
				ISFEATUREEXTERNAL	bit						NOT NULL,
				ISFEATUREINTERNAL	bit						NOT NULL
				 )

declare @dtToday	datetime

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

If @nErrorCode = 0
Begin
	-- Get all the required features that contain licensed web parts and/or tasks
	Insert into @tblFeature (FEATUREID, FEATURENAME, CATEGORYID, MODULEID, TASKID, INUSE, ISMODULEEXTERNAL,
				 ISMODULEINTERNAL, ISTASKEXTERNAL, ISTASKINTERNAL, ISFEATUREEXTERNAL, ISFEATUREINTERNAL)
	Select F.FEATUREID, F.FEATURENAME, F.CATEGORYID, VOM.ObjectIntegerKey, VOT.ObjectIntegerKey, 
	       -- The Feature.InUse flag indicates whether any modules or topics attached 
	       -- to the feature have permissions defined for the @pnRoleKey provided.
	       CASE 	WHEN @pnRoleKey is null THEN 0
			WHEN FPT.ObjectIntegerKey is not null or
			     FPM.ObjectIntegerKey is not null
			THEN 1 
			ELSE 0
	       END,
	       VOM.ExternalUse, VOM.InternalUse, VOT.ExternalUse, VOT.InternalUse, F.ISEXTERNAL, F.ISINTERNAL			 	
	from FEATURE F
	left join FEATURETASK FT	on (FT.FEATUREID = F.FEATUREID)
	left join ROLE R		on (R.ROLEID = @pnRoleKey)	
	left join dbo.fn_ValidObjects(null, 'TASK', @dtToday) VOT 
					on (VOT.ObjectIntegerKey = FT.TASKID
					and (VOT.ExternalUse = R.ISEXTERNAL or
					     VOT.InternalUse = ~R.ISEXTERNAL or
					     R.ISEXTERNAL IS NULL))
	left join FEATUREMODULE FM	on (FM.FEATUREID = F.FEATUREID)
	left join dbo.fn_ValidObjects(null, 'MODULE', @dtToday) VOM
					on (VOM.ObjectIntegerKey = FM.MODULEID
					and (VOM.ExternalUse = R.ISEXTERNAL or
					     VOM.InternalUse = ~R.ISEXTERNAL or
					     R.ISEXTERNAL IS NULL))
	-- To calculate the value of the InUse column:
	-- 1) Check if there are permissions for any of the feature tasks for the role
	left join dbo.fn_PermissionData('ROLE', @pnRoleKey, 'TASK', NULL, NULL, @dtToday) FPT	
			 		on (FT.TASKID = FPT.ObjectIntegerKey)				  
 	-- 2) Check if there are permissions for any of the feature modules for the role
	left join dbo.fn_PermissionData('ROLE', @pnRoleKey, 'MODULE', NULL, NULL, @dtToday) FPM
					on (FM.MODULEID = FPM.ObjectIntegerKey)	
	where(
	      (F.ISEXTERNAL = R.ISEXTERNAL or
	       F.ISINTERNAL = ~R.ISEXTERNAL)
	-- No role requested
	 or   (R.ROLEID is null)
	-- User role is both internal and external
	 or   (R.ROLEID is not null and
	       R.ISEXTERNAL is null and
	       F.ISINTERNAL = 1 and
	       F.ISEXTERNAL = 1)
	      )
	 -- Suppress any web parts or tasks that are not licensed to the firm.
	and (VOT.ObjectIntegerKey is not null
	 or  VOM.ObjectIntegerKey is not null)	

	Set @nErrorCode = @@Error
End

-- Populating Category result set
If @nErrorCode = 0
Begin
	Select  TC.TABLECODE 	as CategoryKey,
		TC.DESCRIPTION	as CategoryName
	from TABLECODES TC
	join TABLETYPE TP	on (TP.TABLETYPE = TC.TABLETYPE)
	join (  Select DISTINCT CATEGORYID
		from @tblFeature) F on (F.CATEGORYID = TC.TABLECODE)
	where TC.TABLETYPE = 98
	order by CategoryName

	Set @nErrorCode = @@Error
End

-- Populating Feature result set
If @nErrorCode = 0
Begin
	Select  F.FEATUREID	as FeatureKey,
		F.CATEGORYID	as CategoryKey,
		F.FEATURENAME	as FeatureName,
		CAST(SUM(cast(F.INUSE as tinyint)) as bit)
			 	as InUse,
		F.ISFEATUREINTERNAL
				as IsInternal,
		F.ISFEATUREEXTERNAL
			 	as IsExternal

	from @tblFeature F	
	group by F.FEATUREID, F.CATEGORYID, F.FEATURENAME, F.ISFEATUREINTERNAL, F.ISFEATUREEXTERNAL
	order by CategoryKey, FeatureName

	Set @nErrorCode = @@Error
End

-- Populating Module result set
If @nErrorCode = 0
Begin
	Select  DISTINCT
		F.MODULEID 	as ModuleKey,
		F.FEATUREID	as FeatureKey,
		M.TITLE		as ModuleTitle,
		M.DESCRIPTION	as Description,
		F.ISMODULEINTERNAL
				as IsInternal,
		F.ISMODULEEXTERNAL
				as IsExternal
	from @tblFeature F
	join MODULE M		on (M.MODULEID = F.MODULEID)
	order by FeatureKey, ModuleTitle

	Set @nErrorCode = @@Error

End

-- Populating Task result set
If @nErrorCode = 0
Begin
	Select  DISTINCT
		F.TASKID 	as TaskKey,
		F.FEATUREID	as FeatureKey,
		T.TASKNAME	as TaskName,
		T.DESCRIPTION	as Description,
		CAST(PR.InsertPermission as bit)
				as IsInsertApplicable,
		CAST(PR.UpdatePermission as bit)
				as IsUpdateApplicable,
		CAST(PR.DeletePermission as bit)
				as IsDeleteApplicable,
		CAST(PR.ExecutePermission as bit)
				as IsExecuteApplicable,
		F.ISTASKINTERNAL
				as IsInternal,
		F.ISTASKEXTERNAL 
				as IsExternal
	from @tblFeature F
	join TASK T		on (T.TASKID = F.TASKID)
	join dbo.fn_PermissionRule('TASK', NULL, NULL) PR
				on (PR.ObjectIntegerKey = T.TASKID)	
	order by FeatureKey, TaskName

	Set @nErrorCode = @@Error
End

Return @nErrorCode
GO

Grant execute on dbo.ua_ListFeatureData to public
GO
