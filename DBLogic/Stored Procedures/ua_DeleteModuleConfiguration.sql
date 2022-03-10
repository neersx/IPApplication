-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_DeleteModuleConfiguration
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_DeleteModuleConfiguration]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_DeleteModuleConfiguration.'
	Drop procedure [dbo].[ua_DeleteModuleConfiguration]
End
Print '**** Creating Stored Procedure dbo.ua_DeleteModuleConfiguration...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_DeleteModuleConfiguration
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnConfigurationKey	int,		-- Mandatory
	@pnOldTabKey		int		= null,		
	@pnOldModuleKey		int		= null,
	@pnOldModuleSequence 	int		= null,
	@pnOldPannelLocation	nvarchar(50)	= null
)
as
-- PROCEDURE:	ua_DeleteModuleConfiguration
-- VERSION:	1
-- DESCRIPTION:	Delete a Module Configuration if the underlying values are as expected.

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
	delete MODULECONFIGURATION
	where	CONFIGURATIONID = @pnConfigurationKey
	and	TABID	 	= @pnOldTabKey		
	and	MODULEID 	= @pnOldModuleKey
	and 	MODULESEQUENCE	= @pnOldModuleSequence
	and 	PANELLOCATION	= @pnOldPannelLocation"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnConfigurationKey	int,
					  @pnOldTabKey		int,					
					  @pnOldModuleKey	int,
					  @pnOldModuleSequence	int,
					  @pnOldPannelLocation	nvarchar(50)',
					  @pnConfigurationKey	= @pnConfigurationKey,
					  @pnOldTabKey		= @pnOldTabKey,	
					  @pnOldModuleKey	= @pnOldModuleKey,					  
					  @pnOldModuleSequence	= @pnOldModuleSequence,
					  @pnOldPannelLocation	= @pnOldPannelLocation
End

Return @nErrorCode
GO

Grant execute on dbo.ua_DeleteModuleConfiguration to public
GO
