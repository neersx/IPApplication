-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ua_InsertPortalTabName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ua_InsertPortalTabName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ua_InsertPortalTabName.'
	Drop procedure [dbo].[ua_InsertPortalTabName]
End
Print '**** Creating Stored Procedure dbo.ua_InsertPortalTabName...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ua_InsertPortalTabName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnTabKey		int		= null	output,
	@psTabName		nvarchar(50)	
)
as
-- PROCEDURE:	ua_InsertPortalTabName
-- VERSION:	1
-- DESCRIPTION:	Add a new Portal Tab, returning the generated Portal Tab key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Aug 2007	SW	RFC5424	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @nPortalKey	int
declare @nTabSequence	tinyint
declare @nRowCount	int

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
		Select @nRowCount = count(*) from PORTALTAB
		where IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nRowCount		int			OUTPUT,
					  @pnUserIdentityId	int',
					  @nRowCount		= @nRowCount		OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId
End

-- Make a duplicate set of tabs if necessary
If @nRowCount = 0 and @nErrorCode = 0
Begin
	exec @nErrorCode = ua_CopyPortalTab @pnUserIdentityId, @psCulture
End

If @nErrorCode = 0
Begin

	select	@nTabSequence = MAX(TABSEQUENCE) + 1,
		@nPortalKey = PORTALID 
	from	PORTALTAB
	where	IDENTITYID = @pnUserIdentityId
	group by PORTALID

End

If @nErrorCode = 0
Begin

	Set @sSQLString = " 
	insert 	into PORTALTAB
		(TABNAME, 
		 IDENTITYID, 		 
		 TABSEQUENCE,
		 PORTALID)
	values	(@psTabName,
		 @pnUserIdentityId, 		
		 @nTabSequence,
		 @nPortalKey)

	Set @pnTabKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnTabKey		int		OUTPUT,
					  @psTabName		nvarchar(50),
					  @pnUserIdentityId	int,		 
					  @nTabSequence		tinyint,
					  @nPortalKey		int',
					  @pnTabKey		= @pnTabKey	OUTPUT,
					  @psTabName		= @psTabName,	
					  @pnUserIdentityId	= @pnUserIdentityId,						 
					  @nTabSequence		= @nTabSequence,
					  @nPortalKey		= @nPortalKey	
End

Return @nErrorCode
GO

Grant execute on dbo.ua_InsertPortalTabName to public
GO