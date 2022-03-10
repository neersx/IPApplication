-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_UpdateSearches
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_UpdateSearches]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_UpdateSearches.'
	Drop procedure [dbo].[ip_UpdateSearches]
	Print '**** Creating Stored Procedure dbo.ip_UpdateSearches...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_UpdateSearches
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryKey		int 		= null,
	@pbIsDefault		bit 		= null,
	@psDescription		nvarchar(256)	= null,
	@psCriteria		nvarchar(max)	= null,
	@psColumns		nvarchar(max)	= null,
	@psCategory		nvarchar(50) 	= null,
	@pnOrigin		int		= null,
	@pbIsDefaultModified	bit 		= null
)
-- PROCEDURE:	ip_UpdateSearches
-- VERSION :	6
-- DESCRIPTION:	This stored procedure updates an existing saved query.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 02-OCT-2002  SF	1	Procedure created
-- 03-OCT-2002	SF	2	Changed some parameter names
-- 11-OCT-2002	SF	3	Changed name
-- 22 Aug 2019	vql	6	DR-40133 Change all NTEXT columns for all other miscellaneous Inprotech tables.
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If 	@nErrorCode = 0
and	@pbIsDefaultModified	= 1
and	@pbIsDefault = 1
Begin
	Update	[SEARCHES]
	Set	[USEASDEFAULT] = 0
	where	[IDENTITYID] = @pnUserIdentityId
	and	[CATEGORY] = @psCategory

	Set @nErrorCode = @@ERROR
End

If	@nErrorCode = 0
Begin
	If @pnOrigin is null
		Set @pnOrigin = 0

	If @pbIsDefault is null
		Set @pbIsDefault = 0

	Update	[SEARCHES]
	Set	[USEASDEFAULT] = @pbIsDefault,
		[DESCRIPTION] = @psDescription,
		[CATEGORY] = @psCategory,
		[ORIGIN] = @pnOrigin,
		[CRITERIA] = @psCriteria, 
		[COLUMNS] = @psColumns
	where	SEARCHID = @pnQueryKey

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_UpdateSearches to public
GO
