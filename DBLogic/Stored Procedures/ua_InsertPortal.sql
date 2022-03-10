-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_InsertPortal
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_InsertPortal]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_InsertPortal.'
	Drop procedure [dbo].[ua_InsertPortal]
End
Print '**** Creating Stored Procedure dbo.ua_InsertPortal...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_InsertPortal
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPortalKey		int		= null,	-- Included to provide a standard interface
	@psPortalName		nvarchar(50)	= null,
	@psDescription		nvarchar(254)	= null,	
	@pbIsExternal 		bit		= null
)
as
-- PROCEDURE:	ua_InsertPortal
-- VERSION:	3
-- DESCRIPTION:	Add a new Portal, returning the generated Portal key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2004	TM	RFC915	1	Procedure created
-- 15 Sep 2004	TM	RFC1822	2	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 20 Sep 2004 	TM	RFC1822	3	Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
--					SQL string executed by sp_executesql.

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
	insert 	into PORTAL
		(NAME, 
		 DESCRIPTION, 		 
		 ISEXTERNAL)
	values	(@psPortalName,
		 @psDescription, 		
		 @pbIsExternal)

	Set @pnPortalKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPortalKey		int		OUTPUT,
					  @psPortalName		nvarchar(50),
					  @psDescription	nvarchar(254),					 
					  @pbIsExternal		bit',
					  @pnPortalKey		= @pnPortalKey	OUTPUT,
					  @psPortalName		= @psPortalName,
					  @psDescription	= @psDescription,					 
					  @pbIsExternal		= @pbIsExternal	

	-- Publish the key so that the dataset is updated
	Select @pnPortalKey as PortalKey
End

Return @nErrorCode
GO

Grant execute on dbo.ua_InsertPortal to public
GO