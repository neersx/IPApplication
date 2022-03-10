-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_InsertModuleConfiguration
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_InsertModuleConfiguration]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_InsertModuleConfiguration.'
	Drop procedure [dbo].[ua_InsertModuleConfiguration]
End
Print '**** Creating Stored Procedure dbo.ua_InsertModuleConfiguration...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_InsertModuleConfiguration
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnConfigurationKey	int		= null	output,	-- Included to provide a standard interface	
	@pnTabKey		int		= null,
	@pnModuleKey		int		= null,	
	@pnModuleSequence 	int		= null,
	@psPanelLocation	nvarchar(50)	= null,
	@pbPublishKey		bit		= 1,		-- If @pbPublishKey = 0 then the @pnConfigurationKey will not be published. 
	@pnIdentityKey          int             = null
)
as
-- PROCEDURE:	ua_InsertModuleConfiguration
-- VERSION:	5
-- DESCRIPTION:	Add a new Module Configuration, returning the generated Configuration key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2004	TM	RFC915	1	Procedure created
-- 18 Aug 2004  TM	RFC1500	2	Make the @pnConfigurationKey an output parameter. Add new optional @pbPublishKey
--					parameter and default it to 1. If @pbPublishKey = 0 then the @pnConfigurationKey
--					will not be published.   
-- 15 Sep 2004	TM	RFC1822	3	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 20 Sep 2004 	TM	RFC1822	4	Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
--					SQL string executed by sp_executesql.
-- 31 Jan 2012  MS      R11786  5       Added parameter @pnIdentityKey for adding IDENTITYID in MODULECONFIGURATION table.


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
	insert 	into MODULECONFIGURATION
		(TABID, 
		 MODULEID, 		 
		 MODULESEQUENCE,
		 PANELLOCATION,
		 IDENTITYID)
	values	(@pnTabKey,
		 @pnModuleKey, 		
		 @pnModuleSequence,
		 @psPanelLocation,
		 @pnIdentityKey)

	Set @pnConfigurationKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnConfigurationKey	int			OUTPUT,
					  @pnTabKey		int,
					  @pnModuleKey		int,					 
					  @pnModuleSequence	int,
					  @psPanelLocation	nvarchar(50),
					  @pnIdentityKey        int',
					  @pnConfigurationKey	=@pnConfigurationKey 	OUTPUT,
					  @pnTabKey		= @pnTabKey,
					  @pnModuleKey		= @pnModuleKey,					 
					  @pnModuleSequence	= @pnModuleSequence,
					  @psPanelLocation	= @psPanelLocation,
					  @pnIdentityKey        = @pnIdentityKey
	
	If @pbPublishKey = 1
	Begin
		-- Publish the key so that the dataset is updated
		Select @pnConfigurationKey as ConfigurationKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ua_InsertModuleConfiguration to public
GO