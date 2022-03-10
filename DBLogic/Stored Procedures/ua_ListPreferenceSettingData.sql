-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_ListPreferenceSettingData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_ListPreferenceSettingData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_ListPreferenceSettingData.'
	Drop procedure [dbo].[ua_ListPreferenceSettingData]
End
Print '**** Creating Stored Procedure dbo.ua_ListPreferenceSettingData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ua_ListPreferenceSettingData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey		int
)
as
-- PROCEDURE:	ua_ListPreferenceSettingData
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the PreferenceSettingData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Sep 2005	JEK	RFC2953	1	Procedure created
-- 12 Jul 2006	SW	RFC3828	2	Pass getdate() to fn_Permission..
-- 22 Sep 2006  PG      RFC4338 3       Add RowKey to GroupedSetting
-- 26 Feb 2015	DV	R43201	4	Return new VALUESPROVIDER column

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

declare @tblSetting	table  (GROUPID			smallint,
			  	DESCRIPTION		nvarchar(254)	collate database_default,
			  	OBJECTTABLE		nvarchar(30)	collate database_default,
				OBJECTINTEGERKEY	int,
				OBJECTSTRINGKEY		nvarchar(30)	collate database_default,
				SETTINGID		int
				)
declare @nGroupID		smallint
declare @sObjectTable		nvarchar(30)
declare @sObjectStringKey 	nvarchar(30)
declare @nObjectIntegerKey	int

declare @bIsExternalUser	bit
Declare @dtToday		datetime


-- Initialise variables
Set @nErrorCode = 0
Set @bIsExternalUser = null
Set @dtToday = getdate()

-- Is the user external?
If @nErrorCode = 0
and @pnIdentityKey is not null
Begin
	Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnIdentityKey

	Set @nErrorCode = @@ERROR

End

-- Decide which groups should be included
If @nErrorCode = 0
Begin
	-- Permissions functions can only be called a row at a time using
	-- local variables.  Populate a table variable to work from.
	insert into @tblSetting
		(GROUPID,DESCRIPTION,OBJECTTABLE,OBJECTINTEGERKEY,OBJECTSTRINGKEY,SETTINGID)
	select  distinct G.GROUPID,G.DESCRIPTION,G.OBJECTTABLE,G.OBJECTINTEGERKEY,
		G.OBJECTSTRINGKEY,D.SETTINGID
	from	SETTINGGROUP G
	join	GROUPEDSETTINGS GS	on (GS.GROUPID=G.GROUPID)
	join SETTINGDEFINITION D 	on (D.SETTINGID=GS.SETTINGID)
	-- Default value
	left join SETTINGVALUES V	on (V.SETTINGID=D.SETTINGID
					and V.IDENTITYID is null)
	where (@bIsExternalUser is null or
	      D.ISEXTERNAL = @bIsExternalUser or
	      D.ISINTERNAL = ~@bIsExternalUser)
	-- Check whether there is a firm-wide default
	and  (@pnIdentityKey is not null or V.SETTINGID is not null)

	Set @nErrorCode = @@ERROR

	If @nErrorCode = 0
	Begin
		Set @nGroupID = null

		-- Loop through table
		select 	@nGroupID = min(GROUPID)
		from @tblSetting
		where OBJECTTABLE IS NOT NULL

		Set @nErrorCode = @@ERROR

		While @nErrorCode = 0
		and @nGroupID is not null
		Begin
			select 	@sObjectTable = OBJECTTABLE,
				@nObjectIntegerKey = OBJECTINTEGERKEY,
				@sObjectStringKey = OBJECTSTRINGKEY
			from @tblSetting
			where GROUPID = @nGroupID

			-- Delete any rows the user does not have permission for
			If @pnIdentityKey is not null
			Begin
				delete @tblSetting
				from @tblSetting
				left join dbo.fn_PermissionsGranted(@pnIdentityKey, @sObjectTable, @nObjectIntegerKey, @sObjectStringKey, @dtToday) P
							on	(P.CanInsert = 1
								or  P.CanUpdate = 1
								or  P.CanDelete = 1
								or  P.CanExecute = 1)
				where 	GROUPID = @nGroupID
				and	P.ObjectIntegerKey is null
				and	P.ObjectStringKey is null

				Set @nErrorCode = @@ERROR

			End
			-- Delete any rows the firm is not licensed for
			Else
			Begin
				delete @tblSetting
				from @tblSetting
				left join dbo.fn_ValidObjects(null, @sObjectTable, @dtToday) VO
							on (VO.ObjectIntegerKey = @nObjectIntegerKey
							or  VO.ObjectStringKey = @sObjectStringKey)
				where 	GROUPID = @nGroupID
				and	VO.ObjectIntegerKey is null
				and	VO.ObjectStringKey is null

				Set @nErrorCode = @@ERROR
			End

			select 	@nGroupID = min(GROUPID)
			from 	@tblSetting
			where 	GROUPID > @nGroupID
			and	OBJECTTABLE IS NOT NULL

		End
	End
End

-- Group result set
If @nErrorCode = 0
Begin
	select 	distinct
		GROUPID 	as GroupKey,
		DESCRIPTION	as Name
	from 	@tblSetting
	order by DESCRIPTION
End

-- Setting result set
If @nErrorCode = 0
Begin
	select	distinct
		D.SETTINGID		as SettingKey,
		D.SETTINGNAME		as SettingName,
		D.COMMENT		as Comment,
		D.DATATYPE		as DataType,
		D.VALUESPROVIDER	as ValuesProvider,
		@pnIdentityKey	as IdentityKey,
		case when @pnIdentityKey is null then DV.SETTINGVALUEID else V.SETTINGVALUEID end
				as SettingValueKey,
		isnull(V.COLINTEGER,DV.COLINTEGER)
				as IntegerValue,
		isnull(V.COLCHARACTER,DV.COLCHARACTER)
				as StringValue,
		isnull(V.COLDECIMAL,DV.COLDECIMAL)
				as DecimalValue,
		isnull(V.COLBOOLEAN,DV.COLBOOLEAN)
				as BooleanValue,
		cast(case when V.IDENTITYID is not null and DV.SETTINGID is not null
			 then 1 else 0 end as bit)
				as IsOverridden
	from	@tblSetting S
	join SETTINGDEFINITION D 	on (D.SETTINGID=S.SETTINGID)
	left join SETTINGVALUES V	on (V.SETTINGID=D.SETTINGID
					and V.IDENTITYID=@pnIdentityKey)
	-- Firm-wide default
	left join SETTINGVALUES DV	on (DV.SETTINGID=D.SETTINGID
					and DV.IDENTITYID is null)

End

-- GroupedSetting result set
If @nErrorCode = 0
Begin
	select  cast(GS.GROUPID as nvarchar(10))+'^'+
		cast(GS.SETTINGID as nvarchar(10))
				as RowKey,
		GS.GROUPID	as GroupKey,
		GS.SETTINGID	as SettingKey
	from	@tblSetting S
	join	GROUPEDSETTINGS GS		on (GS.GROUPID=S.GROUPID
						AND GS.SETTINGID=S.SETTINGID)

End


Return @nErrorCode
GO

Grant execute on dbo.ua_ListPreferenceSettingData to public
GO
