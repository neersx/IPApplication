-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeleteModuleConfigSetting
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeleteModuleConfigSetting]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeleteModuleConfigSetting.'
	Drop procedure [dbo].[ua_DeleteModuleConfigSetting]
End
Print '**** Creating Stored Procedure dbo.ua_DeleteModuleConfigSetting...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_DeleteModuleConfigSetting
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnSettingKey		int,		-- Mandatory
	@pnOldConfigurationKey	int		= null,		
	@psOldSettingName	nvarchar(50)	= null,
	@ptOldSettingValue 	ntext		= null
)
as
-- PROCEDURE:	ua_DeleteModuleConfigSetting
-- VERSION:	1
-- DESCRIPTION:	Delete a module configuration setting if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2004	TM	RFC915	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete PORTALSETTING
	where	SETTINGID	= @pnSettingKey
	and	MODULECONFIGID 	= @pnOldConfigurationKey		
	and	SETTINGNAME 	= @psOldSettingName
	-- Use the fn_IsNtextEqual() function to compare ntext strings
	and 	dbo.fn_IsNtextEqual(SETTINGVALUE, @ptOldSettingValue) = 1"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnSettingKey		 int,
					  @pnOldConfigurationKey int,					
					  @psOldSettingName	 nvarchar(50),
					  @ptOldSettingValue	 ntext',
					  @pnSettingKey		 = @pnSettingKey,
					  @pnOldConfigurationKey = @pnOldConfigurationKey,	
					  @psOldSettingName	 = @psOldSettingName,					  
					  @ptOldSettingValue	 = @ptOldSettingValue
End

Return @nErrorCode
GO

Grant execute on dbo.ua_DeleteModuleConfigSetting to public
GO
