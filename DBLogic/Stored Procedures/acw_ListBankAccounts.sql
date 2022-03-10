-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListBankAccounts
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListBankAccounts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListBankAccounts.'
	Drop procedure [dbo].[acw_ListBankAccounts]
End
Print '**** Creating Stored Procedure dbo.acw_ListBankAccounts...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListBankAccounts
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	acw_ListBankAccounts
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Return AccountKey, AccountDescription from BankAccount table.
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 13-May-2011	MS	RFC7998	1	Procedure created
-- 15 Apr 2013	DV	R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	SELECT  cast(ACCOUNTOWNER as nvarchar(11)) + '^' + cast(BANKNAMENO as nvarchar(11)) + '^' + cast(SEQUENCENO as nvarchar(11)) 
                            as AccountKey, 
	        DESCRIPTION as AccountDescription,
                ACCOUNTOWNER as OwnerKey
	FROM BANKACCOUNT 
        WHERE (TRUSTACCTFLAG= 0 OR TRUSTACCTFLAG IS NULL)
	ORDER BY AccountDescription"
		
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.acw_ListBankAccounts to public
GO
