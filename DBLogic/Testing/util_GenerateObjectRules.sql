-----------------------------------------------------------------------------------------------------------------------------
-- Creation of util_GenerateObjectRules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[util_GenerateObjectRules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.util_GenerateObjectRules.'
	Drop procedure [dbo].[util_GenerateObjectRules]
End
Print '**** Creating Stored Procedure dbo.util_GenerateObjectRules...'
Print ''
GO


SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.util_GenerateObjectRules
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLRules		ntext
)
as
-- PROCEDURE:	util_GenerateObjectRules
-- VERSION:	6
-- DESCRIPTION:	An internal stored procedure to generate scripting for object database
--		table rules from XML input.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02-Jul-2004	JEK		1	Procedure created
-- 23 Nov 2004	JEK		2	Adjust print statement for ValidObjects that already exist.
-- 15 May 2005	JEK	RFC2594		Replace fn_Obfuscate with fn_Obfuscate.
-- 					RFC2549	3	Remove checksum from TYPE
-- 16-Jan-2007	MLE		4	Changed use of CHAR(10) to CHAR(13) + CHAR(10)
-- 18-Jul-2008	SF		5	Change if statement to be stricter when inserting object rule
-- 30-Sep-2011  DV      R100615 6       Remove hardcoded values of VALIDOBJECT.OBJECTID

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
Declare @sRFC 			nvarchar(10)
Declare @sComment		nvarchar(254)
Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		
Declare @CRLF			char(2)		-- Declare standard string 


-- Holds unencrypted ValidObjects
declare @tblInternal table(
	OBJECTID	int identity(1,1),
	TYPE		int,
	OBJECTDATA	nvarchar(254) collate database_default
	)

-- Initialise variables
Set @nErrorCode = 0
Set @CRLF = char(13) + char(10)

If @nErrorCode = 0
Begin

	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLRules
	
	Select 	@sRFC 			= ChangeReference,
		@sComment		= Comment
	from	OPENXML (@idoc, '/Rules',2)
		WITH (
		      ChangeReference		nvarchar(10)	'ChangeReference/text()',
		      Comment			nvarchar(254)	'Comment/text()'
		     )

	set @nErrorCode = @@ERROR

	-- print 'RFC = '+@sRFC
	-- print 'Comment = '+@sComment

End


--	FeatureCategory

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/FeatureCategory[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Feature Category						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

select
"	If NOT exists (select * from TABLECODES WHERE TABLECODE="+CategoryKey+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data TABLECODES.TABLECODE = "+CategoryKey+"'"+@CRLF+
"		 INSERT INTO TABLECODES (TABLECODE, TABLETYPE, [DESCRIPTION], USERCODE)"+@CRLF+
"		 VALUES ("+CategoryKey+", 98, "+dbo.fn_WrapQuotes(CategoryName,0,0)+",null)"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to TABLECODES table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" TABLECODES.TABLECODE = "+CategoryKey+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF


	from	OPENXML (@idoc, '/Rules/FeatureCategory',2)
		WITH (
		      CategoryKey		nvarchar(10)	'Key/text()',
		      CategoryName		nvarchar(100)	'Name/text()'
		     )

	set @nErrorCode = @@ERROR
End

-- Feature

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Feature[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Feature						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

select
"	IF NOT exists (select * from FEATURE where FEATUREID = "+FeatureKey+")"+@CRLF+
"		begin"+@CRLF+
"		PRINT '**** "+@sRFC+" Inserting FEATURE.FEATUREID = "+FeatureKey+"'"+@CRLF+
"		INSERT INTO FEATURE (FEATUREID, FEATURENAME, CATEGORYID, ISEXTERNAL, ISINTERNAL)"+@CRLF+
"		VALUES ("+FeatureKey+", "+dbo.fn_WrapQuotes(Name,0,0)+", "+isnull(CategoryKey,DefaultCategoryKey)+", "+isnull(IsExternal,0)+", "+isnull(IsInternal,0)+")"+@CRLF+
"		PRINT '**** "+@sRFC+" Data has been successfully added to FEATURE table.'"+@CRLF+
"		PRINT ''"+@CRLF+
"		END"+@CRLF+
"	ELSE"+@CRLF+
"		PRINT '**** "+@sRFC+" FEATURE.FEATUREID = "+FeatureKey+" already exists.'"+@CRLF+
"		PRINT ''"+@CRLF+
" 	go"+@CRLF

--	select	FeatureKey, Name, CategoryKey, IsInternal, IsExternal, DefaultCategoryKey
	from	OPENXML (@idoc, '/Rules/Feature',2)
		WITH (
		      FeatureKey		nvarchar(10)	'Key/text()',
		      Name			nvarchar(50)	'Name/text()',
		      CategoryKey		nvarchar(10)	'CategoryKey/text()',
		      IsInternal		nchar(1)	'IsInternal/text()',
		      IsExternal		nchar(1)	'IsExternal/text()',
		      DefaultCategoryKey	nvarchar(10)	'../FeatureCategory/Key/text()'
		     )

	set @nErrorCode = @@ERROR
End

-- ModuleDefinition

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Module/Definition[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - ModuleDefinition						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF+
"	SET IDENTITY_INSERT MODULEDEFINITION ON"+@CRLF+
"	GO"+@CRLF

select
"	If NOT exists(SELECT * FROM MODULEDEFINITION WHERE MODULEDEFID = "+ModuleDefID+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data MODULEDEFINITION.MODULEDEFID = "+ModuleDefID+"'"+@CRLF+
"		 INSERT	MODULEDEFINITION (MODULEDEFID, NAME, DESKTOPSRC, MOBILESRC) "+@CRLF+
"		 VALUES ("+ModuleDefID+", "+dbo.fn_WrapQuotes(Name,0,0)+", '"+DeskTopSrc+"', "+
			case when MobileSrc is null then 'NULL' else dbo.fn_WrapQuotes(MobileSrc,0,0) end+
			")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to MODULEDEFINITION table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" MODULEDEFINITION.MODULEDEFID = "+ModuleDefID+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	select	ModuleDefID, Name, DeskTopSrc, MobileSrc
	from	OPENXML (@idoc, '/Rules/Module/Definition',2)
		WITH (
		      ModuleDefID		nvarchar(10)	'ModuleDefID/text()',
		      Name			nvarchar(128)	'Name/text()',
		      DeskTopSrc		nvarchar(256)	'DeskTopSrc/text()',
		      MobileSrc			nvarchar(256)	'MobileSrc/text()'
		     )

	set @nErrorCode = @@ERROR

select
"	SET IDENTITY_INSERT MODULEDEFINITION OFF"+@CRLF+
"	GO"+@CRLF

End

-- Module

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Module/WebPart[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Module						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF+
"	SET IDENTITY_INSERT MODULE ON"+@CRLF+
"	GO"+@CRLF

select
"	If NOT exists(SELECT * FROM MODULE WHERE MODULEID = "+ModuleKey+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data MODULE.MODULEID = "+ModuleKey+"'"+@CRLF+
"		 INSERT	MODULE (MODULEID, MODULEDEFID, TITLE, CACHETIME, DESCRIPTION)"+@CRLF+
"		 VALUES ("+ModuleKey+", "+isnull(ModuleDefID,DefaultModuleDefID)+", "+
			dbo.fn_WrapQuotes(Title,0,0)+" , "+isnull(CacheTime,0)+", "+
			dbo.fn_WrapQuotes(Description,0,0)+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to MODULE table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" MODULE.MODULEID = "+ModuleKey+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	select	DefaultModuleDefID, ModuleDefID, ModuleKey, Title, Description, CacheTime
	from	OPENXML (@idoc, '/Rules/Module/WebPart',2)
		WITH (
		      DefaultModuleDefID	nvarchar(10)	'../Definition/ModuleDefID/text()',
		      ModuleKey			nvarchar(10)	'Key/text()',
		      ModuleDefID		nvarchar(10)	'ModuleDefID/text()',
		      Title			nvarchar(256)	'Title/text()',
		      Description		nvarchar(254)	'Description/text()',
		      CacheTime			nvarchar(10)	'CacheTime/text()'
		     )

	set @nErrorCode = @@ERROR

select
"	SET IDENTITY_INSERT MODULE OFF"+@CRLF+
"	GO"+@CRLF

End

-- PortalSetting

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Module/PortalSetting[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - PortalSetting						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

select
"	If NOT exists (SELECT * FROM PORTALSETTING WHERE MODULEID = "+ModuleKey+" and MODULECONFIGID IS NULL"+@CRLF+
"			AND IDENTITYID IS NULL AND SETTINGNAME = '"+SettingName+"')"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data PORTALSETTING.MODULEID = "+ModuleKey+" for "+SettingName+"'"+@CRLF+
"		 INSERT INTO PORTALSETTING (MODULEID, MODULECONFIGID, IDENTITYID, SETTINGNAME, SETTINGVALUE)"+@CRLF+
"		 VALUES ("+ModuleKey+", NULL, NULL, '"+SettingName+"','<Value>"+SettingValue+"</Value>')"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to PORTALSETTING table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" PORTALSETTING.MODULEID = "+ModuleKey+" for "+SettingName+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	select	SettingName, SettingValue
	from	OPENXML (@idoc, '/Rules/Module/PortalSetting',2)
		WITH (
		      SettingName		nvarchar(50)	'SettingName/text()',
		      SettingValue		nvarchar(254)	'SettingValue/text()',
		      ModuleKey			nvarchar(10)	'../WebPart/Key/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- FeatureModule

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Module/Feature[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Feature Module						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

select
"	IF NOT exists (select * from FEATUREMODULE where FEATUREID = "+FeatureKey+" AND MODULEID = "+ModuleKey+")"+@CRLF+
"		begin"+@CRLF+
"		PRINT '**** "+@sRFC+" Inserting FEATUREMODULE.FEATUREID = "+FeatureKey+", MODULEID = "+ModuleKey+"'"+@CRLF+
"		INSERT INTO FEATUREMODULE (FEATUREID, MODULEID)"+@CRLF+
"		VALUES ("+FeatureKey+", "+ModuleKey+")"+@CRLF+
"		PRINT '**** "+@sRFC+" Data has been successfully added to FEATUREMODULE table.'"+@CRLF+
"		PRINT ''	"+@CRLF+
"		END"+@CRLF+
"	ELSE"+@CRLF+
"		PRINT '**** "+@sRFC+" FEATUREMODULE.FEATUREID = "+FeatureKey+" MODULEID = "+ModuleKey+" already exists.'"+@CRLF+
"		PRINT ''"+@CRLF+
"	go"+@CRLF

--	select	FeatureKey, ModuleKey
	from	OPENXML (@idoc, '/Rules/Module/Feature',2)
		WITH (
		      FeatureKey		nvarchar(10)	'FeatureKey/text()',
		      ModuleKey			nvarchar(10)	'../WebPart/Key/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Module - Role Permissions

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Module/RolePermissions[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Module Permissions						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

SELECT 
"	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'MODULE'"+@CRLF+
"				and OBJECTINTEGERKEY = "+ModuleKey+@CRLF+
"				and LEVELTABLE = 'ROLE'"+@CRLF+
"				and LEVELKEY = "+RoleKey+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding MODULE data PERMISSIONS.OBJECTKEY = "+ModuleKey+"'"+@CRLF+
"		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) "+@CRLF+
"		 VALUES ('MODULE', "+ModuleKey+", NULL, 'ROLE', "+RoleKey+", "+
			cast(
				case when GrantSelect = 1 then 1 else 0 end |
				case when GrantMandatory = 1 then 64 else 0 end
			as nvarchar)+
			", 0)"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to PERMISSIONS table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" MODULE data PERMISSIONS.OBJECTKEY = "+ModuleKey+" already exists'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	go"+@CRLF

--	select	RoleKey,ModuleKey, GrantSelect, GrantMandatory
	from	OPENXML (@idoc, '/Rules/Module/RolePermissions',2)
		WITH (
		      ModuleKey			nvarchar(10)	'../WebPart/Key/text()',
		      RoleKey			nvarchar(10)	'RoleKey/text()',
		      GrantSelect		bit		'GrantSelect/text()',
		      GrantMandatory		bit		'GrantMandatory/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Task

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Task[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Task						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

select
"	If NOT exists (select * from TASK where TASKID = "+TaskKey+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data TASK.TASKID = "+TaskKey+"'"+@CRLF+
"		 INSERT INTO TASK (TASKID, TASKNAME, DESCRIPTION)"+@CRLF+
"		 VALUES ("+TaskKey+", "+dbo.fn_WrapQuotes(Name,0,0)+","+
			dbo.fn_WrapQuotes(Description,0,0)+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to TASK table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" TASK.TASKID = "+TaskKey+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF

--	select	TaskKey, Name, Description
	from	OPENXML (@idoc, '/Rules/Task',2)
		WITH (
		      TaskKey			nvarchar(10)	'Key/text()',
		      Name			nvarchar(254)	'Name/text()',
		      Description		nvarchar(1000)	'Description/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- FeatureTask

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Task/Feature[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - FeatureTask						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

select
"	IF NOT exists (select * from FEATURETASK where FEATUREID = "+FeatureKey+" AND TASKID = "+TaskKey+")"+@CRLF+
"		begin"+@CRLF+
"		PRINT '**** "+@sRFC+" Inserting FEATURETASK.FEATUREID = "+FeatureKey+", TASKID = "+TaskKey+"'"+@CRLF+
"		INSERT INTO FEATURETASK (FEATUREID, TASKID)"+@CRLF+
"		VALUES ("+FeatureKey+", "+TaskKey+")"+@CRLF+
"		PRINT '**** "+@sRFC+" Data has been successfully added to FEATURETASK table.'"+@CRLF+
"		PRINT ''"+@CRLF+
"		END"+@CRLF+
"	ELSE"+@CRLF+
"		PRINT '**** "+@sRFC+" FEATURETASK.FEATUREID = "+FeatureKey+", TASKID = "+TaskKey+" already exists.'"+@CRLF+
"		PRINT ''"+@CRLF+
" 	go"+@CRLF

--	select	*
	from	OPENXML (@idoc, '/Rules/Task/Feature',2)
		WITH (
		      FeatureKey		nvarchar(10)	'FeatureKey/text()',
		      TaskKey			nvarchar(10)	'../Key/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Task - Permission Definition

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Task/PermissionDefinition[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Permission Definition						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

SELECT 
"	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'"+@CRLF+
"				and OBJECTINTEGERKEY = "+TaskKey+@CRLF+
"				and LEVELTABLE is null"+@CRLF+
"				and LEVELKEY is null)"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding TASK definition data PERMISSIONS.OBJECTKEY = "+TaskKey+"'"+@CRLF+
"		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) "+@CRLF+
"		 VALUES ('TASK', "+TaskKey+", NULL, NULL, NULL, "+
			cast(
				case when GrantInsert = 1 then 8 else 0 end |
				case when GrantUpdate = 1 then 2 else 0 end |
				case when GrantDelete = 1 then 16 else 0 end |
				case when GrantExecute = 1 then 32 else 0 end
			as nvarchar)+
			", 0)"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to PERMISSIONS table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" TASK definition data PERMISSIONS.OBJECTKEY = "+TaskKey+" already exists'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	go"+@CRLF

--	select	RoleKey,TaskKey, GrantExecute, GrantInsert, GrantUpdate, GrantDelete
	from	OPENXML (@idoc, '/Rules/Task/PermissionDefinition',2)
		WITH (
		      TaskKey			nvarchar(10)	'../Key/text()',
		      GrantExecute		bit		'GrantExecute/text()',
		      GrantInsert		bit		'GrantInsert/text()',
		      GrantUpdate		bit		'GrantUpdate/text()',
		      GrantDelete		bit		'GrantDelete/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Task - Role Permissions

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Task/RolePermissions[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Task Permissions						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

SELECT 
"	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'TASK'"+@CRLF+
"				and OBJECTINTEGERKEY = "+TaskKey+@CRLF+
"				and LEVELTABLE = 'ROLE'"+@CRLF+
"				and LEVELKEY = "+RoleKey+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding TASK data PERMISSIONS.OBJECTKEY = "+TaskKey+"'"+@CRLF+
"		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) "+@CRLF+
"		 VALUES ('TASK', "+TaskKey+", NULL, 'ROLE', "+RoleKey+", "+
			cast(
				case when GrantInsert = 1 then 8 else 0 end |
				case when GrantUpdate = 1 then 2 else 0 end |
				case when GrantDelete = 1 then 16 else 0 end |
				case when GrantExecute = 1 then 32 else 0 end
			as nvarchar)+
			", 0)"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to PERMISSIONS table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" TASK data PERMISSIONS.OBJECTKEY = "+TaskKey+" already exists'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	go"+@CRLF

--	select	RoleKey,TaskKey, GrantExecute, GrantInsert, GrantUpdate, GrantDelete
	from	OPENXML (@idoc, '/Rules/Task/RolePermissions',2)
		WITH (
		      TaskKey			nvarchar(10)	'../Key/text()',
		      RoleKey			nvarchar(10)	'RoleKey/text()',
		      GrantExecute		bit		'GrantExecute/text()',
		      GrantInsert		bit		'GrantInsert/text()',
		      GrantUpdate		bit		'GrantUpdate/text()',
		      GrantDelete		bit		'GrantDelete/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Data Topic

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/DataTopic[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - DataTopic						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

select
"	If NOT exists(SELECT * FROM DATATOPIC WHERE TOPICID = "+TopicKey+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding DATATOPIC.TOPICID = "+TopicKey+"'"+@CRLF+
"		 INSERT	DATATOPIC (TOPICID, TOPICNAME, DESCRIPTION, ISEXTERNAL, ISINTERNAL) "+@CRLF+
"		 VALUES ("+TopicKey+", "+dbo.fn_WrapQuotes(Name,0,0)+", "+dbo.fn_WrapQuotes(Description,0,0)+", "+
			isnull(IsExternal,0)+", "+isnull(IsInternal,0)+")"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to DATATOPIC table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" DATATOPIC.TOPICID = "+TopicKey+" already exists'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	go"+@CRLF

--	select	TopicKey, Name, Description, IsInternal, IsExternal
	from	OPENXML (@idoc, '/Rules/DataTopic',2)
		WITH (
		      TopicKey			nvarchar(10)	'Key/text()',
		      Name			nvarchar(50)	'Name/text()',
		      Description		nvarchar(1000)	'Description/text()',
		      IsInternal		nchar(1)	'IsInternal/text()',
		      IsExternal		nchar(1)	'IsExternal/text()'
		     )

	set @nErrorCode = @@ERROR
End

-- Topic Data Items
If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/DataTopic/DataItems[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - TopicDataItem						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

select
"	If NOT exists(SELECT * FROM TOPICDATAITEMS T"+@CRLF+
"			JOIN QUERYDATAITEM DI ON (DI.DATAITEMID=T.DATAITEMID)"+@CRLF+
"			WHERE TOPICID = "+TopicKey+@CRLF+
"			AND PROCEDURENAME='"+ProcedureName+"'"+@CRLF+
"			AND PROCEDUREITEMID='"+ProcedureItemID+"')"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding TOPICDATAITEM for TOPICID="+TopicKey+" AND PROCEDUREITEMID="+ProcedureItemID+"'"+@CRLF+
"		 INSERT	TOPICDATAITEMS (TOPICID, DATAITEMID)"+@CRLF+
"		 SELECT "+TopicKey+", DATAITEMID"+@CRLF+
"		 FROM QUERYDATAITEM"+@CRLF+
"		 WHERE PROCEDURENAME='"+ProcedureName+"'"+@CRLF+
"		 and PROCEDUREITEMID= '"+ProcedureItemID+"'"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to TOPICDATAITEM for TOPICID="+TopicKey+" AND PROCEDUREITEMID="+ProcedureItemID+"'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" TOPICDATAITEM for TOPICID="+TopicKey+" AND PROCEDUREITEMID="+ProcedureItemID+" already exists'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	go"+@CRLF

--	select	TopicKey, ProcedureName, ProcedureItemID
	from	OPENXML (@idoc, '/Rules/DataTopic/DataItems/DataItem',2)
		WITH (
		      TopicKey			nvarchar(10)	'../../Key/text()',
		      ProcedureName		nvarchar(50)	'ProcedureName/text()',
		      ProcedureItemID		nvarchar(50)	'ProcedureItemID/text()'
		     )

	set @nErrorCode = @@ERROR
End

-- DataTopic - Role Permissions

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/DataTopic/RolePermissions[descendant::text()]',2))
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - DataTopic Permissions						***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

SELECT 
"	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = 'DATATOPIC'"+@CRLF+
"				and OBJECTINTEGERKEY = "+TopicKey+@CRLF+
"				and LEVELTABLE = 'ROLE'"+@CRLF+
"				and LEVELKEY = "+RoleKey+")"+@CRLF+
"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding DATATOPIC data PERMISSIONS.OBJECTKEY = "+TopicKey+"'"+@CRLF+
"		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) "+@CRLF+
"		 VALUES ('DATATOPIC', "+TopicKey+", NULL, 'ROLE', "+RoleKey+", "+
			cast(
				case when GrantSelect = 1 then 1 else 0 end
			as nvarchar)+
			", 0)"+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to PERMISSIONS table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" DATATOPIC data PERMISSIONS.OBJECTKEY = "+TopicKey+" already exists'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	go"+@CRLF

	from	OPENXML (@idoc, '/Rules/DataTopic/RolePermissions',2)
		WITH (
		      TopicKey			nvarchar(10)	'../Key/text()',
		      RoleKey			nvarchar(10)	'RoleKey/text()',
		      GrantSelect		bit		'GrantSelect/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Valid Objects - Web Parts
If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Module/LicensedModule[descendant::text()]',2))
Begin
	insert into @tblInternal(TYPE,OBJECTDATA)
	select 10, -- MODULE
	cast(ModuleKey as nchar(3))+cast(WebPartKey as nchar(10))
--	select	ModuleKey, WebPartKey
	from	OPENXML (@idoc, '/Rules/Module/LicensedModule',2)
		WITH (
		      ModuleKey				nvarchar(10)	'ModuleKey/text()',
		      WebPartKey			nvarchar(10)	'../WebPart/Key/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Valid Objects - Tasks
If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Task/LicensedModule[descendant::text()]',2))
Begin

	insert into @tblInternal(TYPE,OBJECTDATA)
	select 20, --TASK
	cast(ModuleKey as nchar(3))+cast(TaskKey as nchar(10))
	from	OPENXML (@idoc, '/Rules/Task/LicensedModule',2)
		WITH (
		      ModuleKey				nvarchar(10)	'ModuleKey/text()',
		      TaskKey			nvarchar(10)	'..//Key/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Valid Objects - Subjects
If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/DataTopic/LicensedModule[descendant::text()]',2))
Begin

	insert into @tblInternal(TYPE,OBJECTDATA)
	select 30, --DATATOPIC
	cast(ModuleKey as nchar(3))+cast(TopicKey as nchar(10))
	from	OPENXML (@idoc, '/Rules/DataTopic/LicensedModule',2)
		WITH (
		      ModuleKey				nvarchar(10)	'ModuleKey/text()',
		      TopicKey				nvarchar(10)	'../Key/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Valid Objects - Subjects Prerequisites
If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/DataTopic/PrerequisiteModule[descendant::text()]',2))
Begin

	insert into @tblInternal(TYPE,OBJECTDATA)
	select 35, --DATATOPICREQUIRES
	cast(ModuleKey as nchar(3))+cast(TopicKey as nchar(10))
	from	OPENXML (@idoc, '/Rules/DataTopic/PrerequisiteModule',2)
		WITH (
		      ModuleKey				nvarchar(10)	'ModuleKey/text()',
		      TopicKey				nvarchar(10)	'../Key/text()'
		     )

	set @nErrorCode = @@ERROR

End

-- Valid Objects - obscured

If exists (select * from @tblInternal)
Begin
	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" - ValidObject								***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF

	SELECT
	"	If NOT exists (SELECT * FROM VALIDOBJECT WHERE TYPE = "+cast(TYPE as nvarchar)+@CRLF+
	"                                  and OBJECTDATA = '"+dbo.fn_Obfuscate(OBJECTDATA)+"')"+@CRLF+
	"        	BEGIN"+@CRLF+
	"         	 PRINT '**** "+@sRFC+" Adding data VALIDOBJECT.OBJECTDATA = "+dbo.fn_Obfuscate(OBJECTDATA)+"'"+@CRLF+
	"		 declare @validObject int"+@CRLF+
        "      	         Select @validObject = (max(OBJECTID) + 1) from VALIDOBJECT"+@CRLF+		 
	"                INSERT INTO VALIDOBJECT (OBJECTID, TYPE, OBJECTDATA)"+@CRLF+
	"		 VALUES (@validObject, "+cast(TYPE as nvarchar)+", '"+dbo.fn_Obfuscate(OBJECTDATA)+"')"+@CRLF+
	"        	 PRINT '**** "+@sRFC+" Data successfully added to VALIDOBJECT table.'"+@CRLF+
	"		 PRINT ''"+@CRLF+
	"         	END"+@CRLF+
	"    	ELSE"+@CRLF+
	"         	PRINT '**** "+@sRFC+" VALIDOBJECT.OBJECTDATA = "+dbo.fn_Obfuscate(OBJECTDATA)+" already exists'"+@CRLF+
	"         	PRINT ''"+@CRLF+
	"    	go"+@CRLF
	from @tblInternal	
	ORDER BY OBJECTID

End

Return @nErrorCode
GO

Grant execute on dbo.util_GenerateObjectRules to public
GO
