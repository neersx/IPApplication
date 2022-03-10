-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListSearchData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListSearchData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListSearchData.'
	Drop procedure [dbo].[ip_ListSearchData]
	Print '**** Creating Stored Procedure dbo.ip_ListSearchData...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_ListSearchData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnQueryKey		int
)
-- PROCEDURE:	ip_ListSearchData
-- VERSION :	4
-- DESCRIPTION:	This stored procedure returns a single query detail to be transformed into useable format in the Data Access.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 02-OCT-2002  SF	1	Procedure created
-- 03-OCT-2002	SF	2	Changed some parameter names
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select 	[DESCRIPTION]	as 'QueryDescription',
		[USEASDEFAULT] 	as 'IsDefaultQuery',
		[CATEGORY]	as 'QueryCategory',
		[ORIGIN]	as 'QueryOrigin',
		[CRITERIA]	as 'Criteria',
		[COLUMNS]	as 'Columns'
	from	[SEARCHES]
	where	SEARCHID = @pnQueryKey		

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_ListSearchData to public
GO
