-----------------------------------------------------------------------------------------------------------------------------
-- Creation of bi_ListDebtorItemTypes 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_ListDebtorItemTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_ListDebtorItemTypes.'
	Drop procedure [dbo].[bi_ListDebtorItemTypes ]
End
Print '**** Creating Stored Procedure dbo.bi_ListDebtorItemTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.bi_ListDebtorItemTypes 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	bi_ListDebtorItemTypes 
-- VERSION:	3
-- DESCRIPTION:	Lists Debtor Item Types.
-- MODIFICATIONS :
-- Date		Who	Change	 Version Description
-- -----------	-------	-------- ------- ----------------------------------------------- 
-- 08 Feb 2010	LP	RFC8289	 1	 Procedure created
-- 12 July 2011	ASH	RFC100535 	2	 Add column I.USEDBYBILLING as UsedByBilling 
-- 1 AUG 2012	SW	RFC100232	 3	 Modified select statement to return UsedByBilling information 



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
	select  I.ITEM_TYPE_ID	as ItemTypeKey,
	"+dbo.fn_SqlTranslatedColumn('DEBTOR_ITEM_TYPE','DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " as ItemTypeDescription, 
	I.ABBREVIATION as ItemTypeCode,
	I.USEDBYBILLING as UsedByBilling			
	from DEBTOR_ITEM_TYPE I	
	order  by ItemTypeDescription"
		
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.bi_ListDebtorItemTypes to public
GO
