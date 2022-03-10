-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_MaintainExchangeInitialised
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_MaintainExchangeInitialised]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_MaintainExchangeInitialised.'
	Drop procedure [dbo].[ig_MaintainExchangeInitialised]
End
Print '**** Creating Stored Procedure dbo.ig_MaintainExchangeInitialised...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ig_MaintainExchangeInitialised
(
	@pnUserIdentityId	int,	-- Mandatory. The user identity to update.
	@pbExchangeInitialised	bit	-- Mandatory. The value to set into the Personal Preference "Exchange Initialised"

)
as
-- PROCEDURE:	ig_MaintainExchangeInitialised
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Stored procedure to update the Personal Preference called "Exchange Initialised". 
--		Note this is a system Personal Preference which cannot be maintained by the user.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 31 AUG 2005	TM	RFC2952	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @nRowCount		int

-- Initialise variables
Set @nErrorCode 		= 0
Set @nRowCount			= 0

-- If the row exists for the user for the personal preference called 
-- "Exchange Initialised" (i.e. SettingID = 1) then update it: 
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Update SETTINGVALUES
	Set  COLBOOLEAN = @pbExchangeInitialised
	where IDENTITYID = @pnUserIdentityId 
	and   SETTINGID = 1"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pbExchangeInitialised	bit,
					  @pnUserIdentityId		int',
					  @pbExchangeInitialised	= @pbExchangeInitialised,
					  @pnUserIdentityId		= @pnUserIdentityId

	Set @nRowCount = @@RowCount
End

-- If NO row exists for the user for the personal preference called 
-- "Exchange Initialised" (i.e. SettingID = 1) then insert it:
If  @nErrorCode = 0
and @nRowCount = 0
Begin
	Set @sSQLString = "
	Insert into SETTINGVALUES (SETTINGID, IDENTITYID, COLBOOLEAN)
	values (1, @pnUserIdentityId, @pbExchangeInitialised)"	

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pbExchangeInitialised	bit,
					  @pnUserIdentityId		int',
					  @pbExchangeInitialised	= @pbExchangeInitialised,
					  @pnUserIdentityId		= @pnUserIdentityId
End

Return @nErrorCode
GO

Grant execute on dbo.ig_MaintainExchangeInitialised to public
GO
