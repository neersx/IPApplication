-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeleteSetting
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeleteSetting]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeleteSetting.'
	Drop procedure [dbo].[ua_DeleteSetting]
End
Print '**** Creating Stored Procedure dbo.ua_DeleteSetting...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_DeleteSetting
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnSettingValueKey	int,		-- Mandatory	
	@pnOldSettingKey	int		= null,
	@pnOldIdentityKey	int		= null,
	@psOldStringValue	nvarchar(254)	= null,
	@pnOldIntegerValue	int		= null,
	@pnOldDecimalValue	decimal(12,2)	= null,
	@pbOldBooleanValue	bit		= null
)
as
-- PROCEDURE:	ua_DeleteSetting
-- VERSION:	1
-- DESCRIPTION:	Delete a setting if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Sep 2005	TM	RFC2953	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

If  @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete 
	from SETTINGVALUES	
	where	SETTINGVALUEID	= @pnSettingValueKey
	and 	SETTINGID	= @pnOldSettingKey
	and	IDENTITYID 	= @pnOldIdentityKey	
	and     COLCHARACTER	= @psOldStringValue
	and	COLINTEGER	= @pnOldIntegerValue
	and 	COLDECIMAL	= @pnOldDecimalValue
	and 	COLBOOLEAN	= @pbOldBooleanValue"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnSettingValueKey	int,
				  @pnOldSettingKey	int,
				  @pnOldIdentityKey	int,
				  @psOldStringValue	nvarchar(254),
				  @pnOldIntegerValue	int,
				  @pnOldDecimalValue	decimal(12,2),
				  @pbOldBooleanValue	bit',
				  @pnSettingValueKey	= @pnSettingValueKey,
				  @pnOldSettingKey	= @pnOldSettingKey,
				  @pnOldIdentityKey	= @pnOldIdentityKey,
				  @psOldStringValue	= @psOldStringValue,
				  @pnOldIntegerValue	= @pnOldIntegerValue,
				  @pnOldDecimalValue	= @pnOldDecimalValue,
				  @pbOldBooleanValue	= @pbOldBooleanValue
End

Return @nErrorCode
GO

Grant execute on dbo.ua_DeleteSetting to public
GO
