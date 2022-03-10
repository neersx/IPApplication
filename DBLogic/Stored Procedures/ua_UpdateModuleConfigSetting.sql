-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_UpdateModuleConfigSetting
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_UpdateModuleConfigSetting]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_UpdateModuleConfigSetting.'
	Drop procedure [dbo].[ua_UpdateModuleConfigSetting]
End
Print '**** Creating Stored Procedure dbo.ua_UpdateModuleConfigSetting...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_UpdateModuleConfigSetting
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnSettingKey		int,	-- Mandatory	
	@pnConfigurationKey	int		= null,
	@psSettingName		nvarchar(50)	= null,	
	@ptSettingValue 	ntext		= null,
	@pnOldConfigurationKey	int		= null,		
	@psOldSettingName	nvarchar(50)	= null,
	@ptOldSettingValue 	ntext		= null	
)
as
-- PROCEDURE:	ua_UpdateModuleConfigSetting
-- VERSION:	2
-- DESCRIPTION:	Update a module configuration setting if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2004	TM	RFC915	1	Procedure created
-- 15 Oct 2009	PS  RFC8346 2   Change the type of the parameter @pnSettingKey from smallint to int.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	update 	PORTALSETTING 
	set	MODULECONFIGID 	 = @pnConfigurationKey, 
		SETTINGNAME 	 = @psSettingName, 		
		SETTINGVALUE 	 = @ptSettingValue
	where	SETTINGID 	 = @pnSettingKey
	and	MODULECONFIGID 	 = @pnOldConfigurationKey
	and     SETTINGNAME	 = @psOldSettingName	
	-- Use the fn_IsNtextEqual() function to compare ntext strings
	and 	dbo.fn_IsNtextEqual(SETTINGVALUE, @ptOldSettingValue) = 1"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnSettingKey		 int,
					  @pnConfigurationKey	 int,
					  @psSettingName	 nvarchar(50),					 
					  @ptSettingValue	 ntext,
					  @pnOldConfigurationKey int,					
					  @psOldSettingName	 nvarchar(50),
					  @ptOldSettingValue	 ntext',
					  @pnSettingKey		 = @pnSettingKey,
					  @pnConfigurationKey	 = @pnConfigurationKey,
					  @psSettingName	 = @psSettingName,					 
					  @ptSettingValue	 = @ptSettingValue,
					  @pnOldConfigurationKey = @pnOldConfigurationKey,	
					  @psOldSettingName	 = @psOldSettingName,					  
					  @ptOldSettingValue	 = @ptOldSettingValue		
					
End

Return @nErrorCode
GO

Grant execute on dbo.ua_UpdateModuleConfigSetting to public
GO
