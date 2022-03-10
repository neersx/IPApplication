-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_MaintainSetting
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_MaintainSetting]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_MaintainSetting.'
	Drop procedure [dbo].[ua_MaintainSetting]
End
Print '**** Creating Stored Procedure dbo.ua_MaintainSetting...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_MaintainSetting
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnSettingValueKey	int		= null,	
	@pnSettingKey		int		= null,
	@pnIdentityKey		int		= null,
	@psStringValue		nvarchar(254)	= null,
	@pnIntegerValue		int		= null,
	@pnDecimalValue		decimal(12,2)	= null,
	@pbBooleanValue		bit		= null,
	@pnOldSettingKey	int		= null,
	@pnOldIdentityKey	int		= null,
	@psOldStringValue	nvarchar(254)	= null,
	@pnOldIntegerValue	int		= null,
	@pnOldDecimalValue	decimal(12,2)	= null,
	@pbOldBooleanValue	bit		= null
)
as
-- PROCEDURE:	ua_MaintainSetting
-- VERSION:	2
-- DESCRIPTION:	Update or insert a setting if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Sep 2005	TM	RFC2953	1	Procedure created
-- 02 Nov 2007	SW	RFC5857	2	Implement security checks

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @bIsExternalUser	bit
Declare @bCanMaintain		bit
Declare @nFilterNameKey		int

-- Initialise variables
Set @nErrorCode 		= 0

If @nErrorCode = 0
Begin		
	Set @sSQLString="
	Select @bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit			OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

-- Security check to see if user has access to maintain setting
If @nErrorCode = 0
and @bIsExternalUser = 1
Begin
	Set @sSQLString = "
		Select	@bCanMaintain		= 1
		from	dbo.fn_FilterUserViewNames(@pnUserIdentityId) FU
		join	NAME N on (N.NAMENO = FU.NAMENO)
		left join dbo.fn_FilterUserViewNames(@pnIdentityKey) FU2 on (1 = 1)
		left join NAME N2 on (N2.NAMENO = FU2.NAMENO)
		where N.NAMENO = N2.NAMENO"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @pnIdentityKey		int,
					  @bCanMaintain			bit			OUTPUT',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnIdentityKey		= @pnIdentityKey,
					  @bCanMaintain			= @bCanMaintain		OUTPUT
	
End
Else
Begin
	Set @bCanMaintain = 1
End

If  @nErrorCode = 0
and @bCanMaintain = 1
Begin
	-- If the @pnSettingValueKey was supplied then update SettingValues row:
	If @pnSettingValueKey is not null
	Begin
		Set @sSQLString = " 
		Update 	SETTINGVALUES
		set	SETTINGID  	= @pnSettingKey, 
			IDENTITYID 	= @pnIdentityKey, 		
			COLCHARACTER 	= @psStringValue,
			COLINTEGER	= @pnIntegerValue,
			COLDECIMAL 	= @pnDecimalValue,
			COLBOOLEAN	= @pbBooleanValue
		where	SETTINGVALUEID	= @pnSettingValueKey
		and 	SETTINGID	= @pnOldSettingKey
		and	IDENTITYID 	= @pnOldIdentityKey	
		and     COLCHARACTER	= @psOldStringValue
		and	COLINTEGER	= @pnOldIntegerValue
		and 	COLDECIMAL	= @pnOldDecimalValue
		and 	COLBOOLEAN	= @pbOldBooleanValue"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnSettingValueKey	int,
					  @pnSettingKey		int,
					  @pnIdentityKey	int,					 
					  @psStringValue 	nvarchar(254),
					  @pnIntegerValue	int,					
					  @pnDecimalValue	decimal(12,2),
					  @pbBooleanValue	bit,
					  @pnOldSettingKey	int,
					  @pnOldIdentityKey	int,
					  @psOldStringValue	nvarchar(254),
					  @pnOldIntegerValue	int,
					  @pnOldDecimalValue	decimal(12,2),
					  @pbOldBooleanValue	bit',
					  @pnSettingValueKey	= @pnSettingValueKey,
					  @pnSettingKey		= @pnSettingKey,
					  @pnIdentityKey	= @pnIdentityKey,					
					  @psStringValue	= @psStringValue,
					  @pnIntegerValue 	= @pnIntegerValue,					 
					  @pnDecimalValue	= @pnDecimalValue,
					  @pbBooleanValue	= @pbBooleanValue,
					  @pnOldSettingKey	= @pnOldSettingKey,
					  @pnOldIdentityKey	= @pnOldIdentityKey,
					  @psOldStringValue	= @psOldStringValue,
					  @pnOldIntegerValue	= @pnOldIntegerValue,
					  @pnOldDecimalValue	= @pnOldDecimalValue,
					  @pbOldBooleanValue	= @pbOldBooleanValue
	End
	-- If the @pnSettingValueKey was supplied then insert SettingValues row:
	Else Begin
		Set @sSQLString = " 
		Insert into SETTINGVALUES
				       (SETTINGID, 
					IDENTITYID, 		
					COLCHARACTER,
					COLINTEGER,
					COLDECIMAL,
					COLBOOLEAN)
				values (@pnSettingKey,
					@pnIdentityKey,					 
					@psStringValue,
					@pnIntegerValue,					
					@pnDecimalValue,
					@pbBooleanValue)

		Set @pnSettingValueKey = SCOPE_IDENTITY()"	

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnSettingValueKey	int			OUTPUT,
					  @pnSettingKey		int,
					  @pnIdentityKey	int,					 
					  @psStringValue 	nvarchar(254),
					  @pnIntegerValue	int,					
					  @pnDecimalValue	decimal(12,2),
					  @pbBooleanValue	bit',
					  @pnSettingValueKey	= @pnSettingValueKey	OUTPUT,
					  @pnSettingKey		= @pnSettingKey,
					  @pnIdentityKey	= @pnIdentityKey,					
					  @psStringValue	= @psStringValue,
					  @pnIntegerValue 	= @pnIntegerValue,					 
					  @pnDecimalValue	= @pnDecimalValue,
					  @pbBooleanValue	= @pbBooleanValue

		-- Publish the key so that the dataset is updated
		Select @pnSettingValueKey as SettingValueKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ua_MaintainSetting to public
GO
