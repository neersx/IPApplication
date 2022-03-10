-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_CaseInstructionLoadManager
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_CaseInstructionLoadManager]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_CaseInstructionLoadManager.'
	Drop procedure [dbo].[ip_CaseInstructionLoadManager]
End
Print '**** Creating Stored Procedure dbo.ip_CaseInstructionLoadManager...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_CaseInstructionLoadManager
(
	@pnUserIdentityId		int,	-- mandatory
	@pnDefinitionKey		int,	-- mandatory
	@pbBlock				bit		--	mandatory
)
as
-- PROCEDURE:	ip_CaseInstructionLoadManager
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Executing the ip_LoadCaseInstructAllowed sp is a potentially lenghty operation.
--			This sp manages the flag which indicate to the caller (UI) that the operation is completed or otherwise.
--			In Block mode, definition key is added to the hardcoded SettingValue as comma delimited string
--			In Unblock mode, definition key is removed from the said SettingValue.
--			The SettingID is hardcoded, delivered via install/upgrade script.
--			Use with ip_LoadCaseInstructAllowed.
--			Called by WorkBenches only.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Mar 2007	SF	5191	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sOldValue			nvarchar(254)
Declare @sNewValue			nvarchar(254)
Declare @sCheckValue		nvarchar(15)
Declare @nSettingValueKey	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode=0
Begin
	Set @sCheckValue = ","+cast(@pnDefinitionKey as nvarchar(13)) + ","
	Set @sSQLString = "
	Select"+char(10)+
	"	@nSettingValueKey = SETTINGVALUEID, "+char(10)+
	"	@sOldValue = COLCHARACTER, "+char(10)+
	"	@sNewValue = case "+char(10)+
	"		when @pbBlock=1 then "+char(10)+
	"			case "+char(10)+
	"				when COLCHARACTER is null then @sCheckValue "+char(10)+
	"				when charindex(@sCheckValue, ',' + COLCHARACTER + ',')>0 then ','+COLCHARACTER+','"+char(10)+ /* no change */
	"				when charindex(COLCHARACTER, ',')=0 then ','+COLCHARACTER+@sCheckValue"+char(10)+ /* single value */
	"				else COLCHARACTER+@sCheckValue"+char(10)+ /* add value to COLCHARACTER */
	"			end"+char(10)+
	"		else "+char(10)+ /* remove definition key from COLCHARACTER*/
	"			replace(',' + isnull(COLCHARACTER,'') + ',',"+char(10)+
	"				@sCheckValue,',')"+char(10)+ /* strip value from COLCHARACTER */
	"		end"+char(10)+
	"from SETTINGVALUES"+char(10)+
	/* the value is hardcoded and delivered.  
		It is the setting used for determining the status of the loading of case instruct allowed. */
	"where SETTINGID = 8"+char(10)+
	"and IDENTITYID is null"

	

	exec @nErrorCode = sp_executesql @sSQLString,
			N'	@nSettingValueKey	int				output,
				@sNewValue			nvarchar(256)	output,
				@sOldValue			nvarchar(256)	output,
				@sCheckValue		nvarchar(15),
				@pbBlock			bit',
				@nSettingValueKey	= @nSettingValueKey output,
				@sNewValue			= @sNewValue output,
				@sOldValue			= @sOldValue output,
				@sCheckValue		= @sCheckValue,
				@pbBlock			= @pbBlock

	if @nErrorCode = 0
	Begin
		set @sNewValue = 
			case 
				when @sNewValue=',' or @sNewValue=',,' then null 
				else  substring(isnull(@sNewValue,''),2, len(@sNewValue)-2)			
			end

		exec @nErrorCode = dbo.ua_MaintainSetting
				@pnUserIdentityId	= @pnUserIdentityId,
				@pnSettingValueKey	= @nSettingValueKey,
				@pnSettingKey		= 8,
				@pnOldSettingKey	= 8,
				@psStringValue		= @sNewValue,
				@psOldStringValue	= @sOldValue
				
	End			
End

Return @nErrorCode
GO

Grant execute on dbo.ip_CaseInstructionLoadManager to public
GO
