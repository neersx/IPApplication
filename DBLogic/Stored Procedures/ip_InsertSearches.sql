-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_InsertSearches
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InsertSearches]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_InsertSearches.'
	Drop procedure [dbo].[ip_InsertSearches]
	Print '**** Creating Stored Procedure dbo.ip_InsertSearches...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_InsertSearches
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryKey		int 		= null output,
	@pbIsDefault		bit 		= null,
	@psDescription		nvarchar(256)	= null,
	@psCriteria		nvarchar(max)	= null,
	@psColumns		nvarchar(max)	= null,
	@psCategory		nvarchar(50) 	= null,
	@pnOrigin		int		= null
)
-- PROCEDURE:	ip_InsertSearches
-- VERSION :	9
-- DESCRIPTION:	This stored procedure insert a query into the Searches table.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 02-OCT-2002  SF	1	Procedure created
-- 03-OCT-2002	SF	2	Changed some parameter names
-- 10-OCT-2002	SF	3	Wrong Param Assignmennt
-- 15-Sep-2004	TM	6	RFC1822	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 17 Sep 2004	TM	7	RFC1822 Implement SCOPE_IDENTITY() IDENT_CURRENT.
-- 14 Jul 2008	vql	8	SCOPE_IDENT( ) to retrieve an identity value cannot be used with tables that have an INSTEAD OF trigger present.
-- 22 Aug 2019	vql	9	DR-40133 Change all NTEXT columns for all other miscellaneous Inprotech tables.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If 	@nErrorCode = 0
and 	@pbIsDefault = 1
Begin
	Update	[SEARCHES]
	set	[USEASDEFAULT] = 0
	where	[IDENTITYID] = @pnUserIdentityId
	and	[CATEGORY] = @psCategory

	Set @nErrorCode = @@ERROR
End

If	@nErrorCode = 0
begin
	Insert 	[SEARCHES] (
		[IDENTITYID],
	 	[DESCRIPTION],
		[USEASDEFAULT],
		[CATEGORY],
		[COLUMNS],
		[CRITERIA],
		[ORIGIN]
	)
	values
	(
		@pnUserIdentityId,
		@psDescription,
		@pbIsDefault,
		@psCategory,
		@psColumns,
		@psCriteria,
		@pnOrigin	
	)

	Set @nErrorCode = @@ERROR

	Set @pnQueryKey = IDENT_CURRENT('SEARCHES')
End

Return @nErrorCode
GO

Grant execute on dbo.ip_InsertSearches to public
GO
