-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_InsertPortalTab
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_InsertPortalTab]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_InsertPortalTab.'
	Drop procedure [dbo].[ua_InsertPortalTab]
End
Print '**** Creating Stored Procedure dbo.ua_InsertPortalTab...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_InsertPortalTab
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTabKey		int		= null	output,	-- Included to provide a standard interface
	@psTabName		nvarchar(50)	= null,
	@pnIdentityKey		int		= null,	
	@pnTabSequence 		tinyint		= null,
	@pnPortalKey		int		= null,
	@pbPublishKey		bit 		= 1		-- If @pbPublishKey = 0 then the @pnTabKey will not be published.      
)
as
-- PROCEDURE:	ua_InsertPortalTab
-- VERSION:	4
-- DESCRIPTION:	Add a new Portal Tab, returning the generated Portal Tab key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2004	TM	RFC915	1	Procedure created
-- 18 Aug 2004  TM	RFC1500	2	Make the @pnTabKey an output parameter. Add new optional @pbPublishKey
--					parameter and default it to 1. If @pbPublishKey = 0 then the @pnTabKey
--					will not be published.      
-- 15 Sep 2004	TM	RFC1822	3	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 20 Sep 2004 	TM	RFC1822	4	Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
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
	insert 	into PORTALTAB
		(TABNAME, 
		 IDENTITYID, 		 
		 TABSEQUENCE,
		 PORTALID)
	values	(@psTabName,
		 @pnIdentityKey, 		
		 @pnTabSequence,
		 @pnPortalKey)

	Set @pnTabKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int		OUTPUT,
					  @psTabName		nvarchar(50),
					  @pnIdentityKey	int,					 
					  @pnTabSequence	tinyint,
					  @pnPortalKey		int',
					  @pnTabKey		= @pnTabKey	OUTPUT,
					  @psTabName		= @psTabName,
					  @pnIdentityKey	= @pnIdentityKey,					 
					  @pnTabSequence	= @pnTabSequence,
					  @pnPortalKey		= @pnPortalKey	

	If @pbPublishKey = 1
	Begin
		-- Publish the key so that the dataset is updated
		Select @pnTabKey as TabKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ua_InsertPortalTab to public
GO