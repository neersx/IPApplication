-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_InsertModuleConfigSetting
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_InsertModuleConfigSetting]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_InsertModuleConfigSetting.'
	Drop procedure [dbo].[ua_InsertModuleConfigSetting]
End
Print '**** Creating Stored Procedure dbo.ua_InsertModuleConfigSetting...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_InsertModuleConfigSetting
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnSettingKey		int		= null,	-- Included to provide a standard interface
	@pnConfigurationKey	int		= null,
	@psSettingName		nvarchar(50)	= null,	
	@ptSettingValue 	ntext		= null
)
as
-- PROCEDURE:	ua_InsertModuleConfigSetting
-- VERSION:	4
-- DESCRIPTION:	Add a new module configuration setting, returning the generated setting key.

-- MODIFICATIONS :
-- Date		Who	Change	    Version	Description
-- -----------	-------	------	    -------	----------------------------------------------- 
-- 22 Jun 2004	TM	RFC915	    1		Procedure created
-- 15 Sep 2004	TM	RFC1822	    2		Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 20 Sep 2004 	TM	RFC1822	    3		Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
--						SQL string executed by sp_executesql.
-- 14 Jul 2008	vql	SQA16940    4		SCOPE_IDENT( ) to retrieve an identity value cannot be used with tables that have an INSTEAD OF trigger present.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into PORTALSETTING 
		(MODULECONFIGID, 
		 SETTINGNAME, 		 
		 SETTINGVALUE)
	values	(@pnConfigurationKey,
		 @psSettingName, 		
		 @ptSettingValue)

	Set @pnSettingKey = IDENT_CURRENT('PORTALSETTING')"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnSettingKey		int		OUTPUT,
					  @pnConfigurationKey	int,
					  @psSettingName	nvarchar(50),					 
					  @ptSettingValue	ntext',
					  @pnSettingKey		=@pnSettingKey	OUTPUT,
					  @pnConfigurationKey	= @pnConfigurationKey,
					  @psSettingName	= @psSettingName,					 
					  @ptSettingValue	= @ptSettingValue	

	-- Publish the key so that the dataset is updated
	Select @pnSettingKey as SettingKey
End

Return @nErrorCode
GO

Grant execute on dbo.ua_InsertModuleConfigSetting to public
GO