-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_ListTransactionTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ListTransactionTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ListTransactionTypes.'
	Drop procedure [dbo].[ac_ListTransactionTypes]
End
Print '**** Creating Stored Procedure dbo.ac_ListTransactionTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ac_ListTransactionTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null
)
AS
-- PROCEDURE:	ac_ListTransactionTypes
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns a list of Transaction Types.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Jul 2013  vql	DR-138	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(4000)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	select  TRANS_TYPE_ID	as TransactionTypeKey,
		DESCRIPTION	as TransactionTypeDescription
	from	ACCT_TRANS_TYPE
	where	USED_BY = 3
	order by TransactionTypeDescription"

	exec @nErrorCode = sp_executesql @sSQLString	
End

Return @nErrorCode

GO

Grant execute on dbo.ac_ListTransactionTypes to public
GO
