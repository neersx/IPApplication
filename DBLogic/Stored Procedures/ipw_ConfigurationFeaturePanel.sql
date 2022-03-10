-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ConfigurationFeaturePanel
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ConfigurationFeaturePanel]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ConfigurationFeaturePanel.'
	Drop procedure [dbo].[ipw_ConfigurationFeaturePanel]
End
Print '**** Creating Stored Procedure dbo.ipw_ConfigurationFeaturePanel...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_ConfigurationFeaturePanel]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null
)
as
-- PROCEDURE:	ipw_ConfigurationFeaturePanel
-- VERSION:	5
-- DESCRIPTION:	Populate the Configuration portal tab.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 OCT 2008	SF		RFC6510		1	Procedure created
-- 13 OCT 2014	DV		R26412		2	Added a check for IsExternal
-- 03 FEB 2015	AT		R37376		3	Implement configuration item grouping for PTO Data Download.
-- 03 JUN 2015	AT		R47513		4	Return new URL column.
-- 13 OCT 2017	SS		DR-34707	5   Return ConfigurationItemid - used for deep linking in Inprotech

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @dtToday	datetime
Declare @sLookupCulture		nvarchar(10)
Declare @bIsExternalUser	bit

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

declare @tblFeature  	table  (FEATUREID		smallint					NOT NULL,
			  	FEATURENAME		nvarchar(50)	collate database_default	NOT NULL,
				CATEGORYID		int						NULL,
				TASKID			int						NULL
				 )

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit		  OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode = 0
Begin
	-- Get all the required features in the CONFIGURATIONCONTEXT that the user has permission to edit or execute
	Insert into @tblFeature (FEATUREID, FEATURENAME, CATEGORYID, TASKID)
	Select F.FEATUREID, 
		dbo.fn_GetTranslation(F.FEATURENAME, null, F.FEATURENAME_TID, @sLookupCulture), 
		F.CATEGORYID, 
		CI.TASKID
	from FEATURE F
	left join FEATURETASK FT	on (FT.FEATUREID = F.FEATUREID 
						and F.ISEXTERNAL = @bIsExternalUser)
	join CONFIGURATIONITEM CI on (CI.TASKID = FT.TASKID)
	join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', null, null, @dtToday) P
			on (P.ObjectIntegerKey = CI.TASKID
			and (P.CanInsert = 1
			 or  P.CanUpdate = 1
			 or  P.CanDelete = 1
			 or  P.CanExecute = 1))

	Set @nErrorCode = @@Error
End

-- Populating Category result set
If @nErrorCode = 0
Begin
	Select  		
		TC.TABLECODE 	as CategoryKey,
		dbo.fn_GetTranslation(TC.DESCRIPTION, null, TC.DESCRIPTION_TID, @sLookupCulture)
			as CategoryName
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
	Select  
		F.FEATUREID	as FeatureKey,
		F.CATEGORYID	as CategoryKey,
		F.FEATURENAME	as FeatureName
	from @tblFeature F	
	group by F.FEATUREID, F.CATEGORYID, F.FEATURENAME
	order by CategoryKey, FeatureName

	Set @nErrorCode = @@Error
End

-- Populating Task / Context result set
If @nErrorCode = 0
Begin
	Select  DISTINCT
		CI.CONFIGITEMID as ConfigurationItemId,
		F.TASKID 	as TaskKey,
		F.FEATUREID	as FeatureKey,
		Q.CONTEXTID as ListKey,
		coalesce(
					dbo.fn_GetTranslation(CI.TITLE, null, CI.TITLE_TID, @sLookupCulture), 
					dbo.fn_GetTranslation(T.TASKNAME, null, T.TASKNAME_TID, @sLookupCulture)) 				as TaskName,
		coalesce(
					dbo.fn_GetTranslation(CI.DESCRIPTION, null, CI.DESCRIPTION_TID, @sLookupCulture), 
					dbo.fn_GetTranslation(T.DESCRIPTION, null, T.DESCRIPTION_TID, @sLookupCulture)) 		as TaskDescription,
		dbo.fn_GetTranslation(Q.CONTEXTNAME, null, Q.CONTEXTNAME_TID, @sLookupCulture) 	as ListName,
		dbo.fn_GetTranslation(Q.NOTES, null, Q.NOTES_TID, @sLookupCulture) 				as ListNotes,		
		CI.GENERICPARAM as GenericParam,
		CI.URL as Url
	from @tblFeature F
	join CONFIGURATIONITEM CI		on (CI.TASKID = F.TASKID)
	join TASK T		on (T.TASKID = CI.TASKID)
	left join QUERYCONTEXT Q on (Q.CONTEXTID = CI.CONTEXTID)
	WHERE CI.GROUPID IS NULL
	union
	Select  DISTINCT
		CI.CONFIGITEMID as ConfigurationItemId,
		F.TASKID 	as TaskKey,
		F.FEATUREID	as FeatureKey,
		null as ListKey,
		coalesce(
					dbo.fn_GetTranslation(CI.TITLE, null, CI.TITLE_TID, @sLookupCulture), 
					dbo.fn_GetTranslation(T.TASKNAME, null, T.TASKNAME_TID, @sLookupCulture)) 				as TaskName,
		coalesce(
					dbo.fn_GetTranslation(CI.DESCRIPTION, null, CI.DESCRIPTION_TID, @sLookupCulture), 
					dbo.fn_GetTranslation(T.DESCRIPTION, null, T.DESCRIPTION_TID, @sLookupCulture)) 		as TaskDescription,
		null	as ListName,
		null			as ListNotes,
		CI.GENERICPARAM as GenericParam,
		CI.URL as Url
	from @tblFeature F
	join CONFIGURATIONITEM CI		on (CI.TASKID = F.TASKID)
	join TASK T		on (T.TASKID = CI.TASKID and CI.CONTEXTID is null)
	WHERE CI.GROUPID IS NULL
	union
	Select  DISTINCT
		CI.CONFIGITEMID as ConfigurationItemId,
		F.TASKID as TaskKey,
		F.FEATUREID	as FeatureKey,
		null as ListKey,
		dbo.fn_GetTranslation(CIG.TITLE, null, CIG.TITLE_TID, @sLookupCulture)	as TaskName,
		dbo.fn_GetTranslation(CIG.DESCRIPTION, null, CIG.DESCRIPTION_TID, @sLookupCulture)	as TaskDescription,
		null	as ListName,
		null	as ListNotes,
		null	as GenericParam,
		CIG.URL as Url
	from CONFIGURATIONITEMGROUP CIG
	join	(SELECT F.FEATUREID, MAX(CIM.CONFIGITEMID) AS CONFIGITEMID, CIM.GROUPID
				FROM @tblFeature F
				JOIN CONFIGURATIONITEM CIM ON (CIM.TASKID = F.TASKID)
				WHERE CIM.GROUPID IS NOT NULL 
				GROUP BY CIM.GROUPID, F.FEATUREID) 
				AS MAXCI ON (MAXCI.GROUPID = CIG.ID)
	join CONFIGURATIONITEM CI ON (CI.CONFIGITEMID = MAXCI.CONFIGITEMID)
	join @tblFeature F ON (F.TASKID = CI.TASKID)
	order by FeatureKey, TaskName

	Set @nErrorCode = @@Error
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ConfigurationFeaturePanel to public
GO

